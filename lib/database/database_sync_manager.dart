import 'dart:async';
import 'dart:io';
import '../services/connectivity_monitor_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../repositories/machine_repository.dart';
import '../models/machine.dart';
import 'database_helper.dart';

/// Gerenciador de sincronização do banco de dados
/// Responsável por sincronizar dados locais com o servidor em segundo plano
class DatabaseSyncManager {
  static final DatabaseSyncManager _instance = DatabaseSyncManager._internal();
  factory DatabaseSyncManager() => _instance;
  DatabaseSyncManager._internal();

  // Repositórios
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Controle de sincronização
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;
  int _consecutiveFailures = 0;
  final int _maxConsecutiveFailures = 5;
  
  // Configurações
  bool _autoSyncEnabled = true;
  Duration _syncInterval = const Duration(minutes: 30);
  
  // Listeners
  final List<Function(SyncStatus)> _syncListeners = [];
  
  // Timer para sincronização automática
  Timer? _syncTimer;
  
  // Status atual
  SyncStatus _currentStatus = SyncStatus(
    status: SyncState.idle,
    lastSyncAttempt: null,
    lastSuccessfulSync: null,
    pendingItems: 0,
    consecutiveFailures: 0,
  );

  /// Inicializa o gerenciador de sincronização
  Future<void> initialize() async {
    // Carrega configurações salvas
    await _loadSettings();
    
    // Inicia o timer de sincronização automática
    _startSyncTimer();
    
    // Configura listener de conectividade usando o serviço interno
    final connectivityService = ConnectivityMonitorService();
    
    // Configura um listener na mudança de status de conectividade
    connectivityService.connectivityStream.listen((status) {
      // Verifica se a conexão está ativa
      if (status == ConnectivityStatus.connected) {
        // Quando a conectividade é restaurada, tenta sincronizar
        syncNow();
      }
    });
  }
  
  /// Carrega as configurações salvas
  Future<void> _loadSettings() async {
    try {
      final db = await _databaseHelper.getDatabase();
      final settings = await db.query('app_settings', where: 'key LIKE ?', whereArgs: ['sync_%']);
      
      for (final setting in settings) {
        final key = setting['key'] as String;
        final value = setting['value'] as String;
        
        switch (key) {
          case 'sync_auto_enabled':
            _autoSyncEnabled = value == '1';
            break;
          case 'sync_interval_minutes':
            final minutes = int.tryParse(value) ?? 30;
            _syncInterval = Duration(minutes: minutes);
            break;
          case 'sync_last_attempt':
            _lastSyncAttempt = DateTime.tryParse(value);
            break;
          case 'sync_last_success':
            _lastSuccessfulSync = DateTime.tryParse(value);
            break;
          case 'sync_consecutive_failures':
            _consecutiveFailures = int.tryParse(value) ?? 0;
            break;
        }
      }
      
      // Atualiza o status atual
      _updateStatus();
    } catch (e) {
      debugPrint('Erro ao carregar configurações de sincronização: $e');
    }
  }
  
  /// Salva as configurações atuais
  Future<void> _saveSettings() async {
    try {
      final db = await _databaseHelper.getDatabase();
      
      await _databaseHelper.executeInTransaction((txn) async {
        // Auto sync
        await txn.insert(
          'app_settings',
          {
            'key': 'sync_auto_enabled',
            'value': _autoSyncEnabled ? '1' : '0',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Sync interval
        await txn.insert(
          'app_settings',
          {
            'key': 'sync_interval_minutes',
            'value': (_syncInterval.inMinutes).toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Last sync attempt
        if (_lastSyncAttempt != null) {
          await txn.insert(
            'app_settings',
            {
              'key': 'sync_last_attempt',
              'value': _lastSyncAttempt!.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        // Last successful sync
        if (_lastSuccessfulSync != null) {
          await txn.insert(
            'app_settings',
            {
              'key': 'sync_last_success',
              'value': _lastSuccessfulSync!.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        // Consecutive failures
        await txn.insert(
          'app_settings',
          {
            'key': 'sync_consecutive_failures',
            'value': _consecutiveFailures.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      debugPrint('Erro ao salvar configurações de sincronização: $e');
    }
  }
  
  /// Inicia o timer de sincronização automática
  void _startSyncTimer() {
    _syncTimer?.cancel();
    
    if (_autoSyncEnabled) {
      _syncTimer = Timer.periodic(_syncInterval, (timer) {
        syncNow();
      });
    }
  }
  
  /// Atualiza o status atual e notifica os listeners
  void _updateStatus() {
    _currentStatus = SyncStatus(
      status: _isSyncing ? SyncState.syncing : SyncState.idle,
      lastSyncAttempt: _lastSyncAttempt,
      lastSuccessfulSync: _lastSuccessfulSync,
      pendingItems: 0, // Será atualizado durante a sincronização
      consecutiveFailures: _consecutiveFailures,
    );
    
    // Notifica os listeners
    for (final listener in _syncListeners) {
      listener(_currentStatus);
    }
  }
  
  /// Adiciona um listener para receber atualizações de status
  void addListener(Function(SyncStatus) listener) {
    if (!_syncListeners.contains(listener)) {
      _syncListeners.add(listener);
      
      // Notifica o novo listener com o status atual
      listener(_currentStatus);
    }
  }
  
  /// Remove um listener
  void removeListener(Function(SyncStatus) listener) {
    _syncListeners.remove(listener);
  }
  
  /// Inicia a sincronização imediatamente
  Future<bool> syncNow() async {
    // Verifica se já está sincronizando
    if (_isSyncing) return false;
    
    // Verifica se há conectividade usando o serviço interno
    final connectivityService = ConnectivityMonitorService();
    if (!connectivityService.isOnline()) {
      debugPrint('Sincronização cancelada: sem conectividade');
      return false;
    }
    
    // Atualiza o status
    _isSyncing = true;
    _lastSyncAttempt = DateTime.now();
    _updateStatus();
    
    bool success = false;
    
    try {
      // Sincroniza cada tipo de entidade
      await _syncMachines();
      
      // Se chegou aqui, a sincronização foi bem-sucedida
      success = true;
      _lastSuccessfulSync = DateTime.now();
      _consecutiveFailures = 0;
    } catch (e) {
      debugPrint('Erro durante a sincronização: $e');
      _consecutiveFailures++;
      
      // Se houver muitas falhas consecutivas, desativa a sincronização automática
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _autoSyncEnabled = false;
        _startSyncTimer();
      }
    } finally {
      _isSyncing = false;
      await _saveSettings();
      _updateStatus();
    }
    
    return success;
  }
  
  /// Sincroniza as máquinas agrícolas
  Future<void> _syncMachines() async {
    try {
      // Obtém máquinas pendentes de sincronização
      final pendingMachines = await _machineRepository.getPendingSync();
      
      if (pendingMachines.isEmpty) {
        debugPrint('Nenhuma máquina pendente de sincronização');
        return;
      }
      
      // Atualiza o status com o número de itens pendentes
      _currentStatus = _currentStatus.copyWith(
        pendingItems: pendingMachines.length,
      );
      
      // Notifica os listeners
      for (final listener in _syncListeners) {
        listener(_currentStatus);
      }
      
      // Simula o envio para o servidor (em um app real, isso seria uma chamada de API)
      for (final machine in pendingMachines) {
        // Simula uma operação de rede
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Simula sucesso na sincronização
        await _machineRepository.markAsSynced(machine.id);
        
        // Atualiza o contador de itens pendentes
        _currentStatus = _currentStatus.copyWith(
          pendingItems: _currentStatus.pendingItems - 1,
        );
        
        // Notifica os listeners
        for (final listener in _syncListeners) {
          listener(_currentStatus);
        }
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar máquinas: $e');
      rethrow;
    }
  }
  
  /// Ativa ou desativa a sincronização automática
  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    _startSyncTimer();
    await _saveSettings();
    _updateStatus();
  }
  
  /// Define o intervalo de sincronização automática
  Future<void> setSyncInterval(Duration interval) async {
    _syncInterval = interval;
    _startSyncTimer();
    await _saveSettings();
  }
  
  /// Obtém o status atual de sincronização
  SyncStatus get status => _currentStatus;
  
  /// Verifica se a sincronização automática está ativada
  bool get isAutoSyncEnabled => _autoSyncEnabled;
  
  /// Obtém o intervalo de sincronização automática
  Duration get syncInterval => _syncInterval;
}

/// Estado de sincronização
enum SyncState {
  idle,
  syncing,
}

/// Status de sincronização
class SyncStatus {
  final SyncState status;
  final DateTime? lastSyncAttempt;
  final DateTime? lastSuccessfulSync;
  final int pendingItems;
  final int consecutiveFailures;
  
  SyncStatus({
    required this.status,
    this.lastSyncAttempt,
    this.lastSuccessfulSync,
    required this.pendingItems,
    required this.consecutiveFailures,
  });
  
  /// Cria uma cópia com os campos especificados alterados
  SyncStatus copyWith({
    SyncState? status,
    DateTime? lastSyncAttempt,
    DateTime? lastSuccessfulSync,
    int? pendingItems,
    int? consecutiveFailures,
  }) {
    return SyncStatus(
      status: status ?? this.status,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      pendingItems: pendingItems ?? this.pendingItems,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }
}
