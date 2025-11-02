import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../models/sync/sync_metadata.dart';
import '../models/sync/sync_conflict.dart';
import '../models/sync/sync_batch.dart';
import '../models/sync/sync_module.dart';

/// Enum que representa o status de sincronização
enum SyncStatus {
  notStarted,
  pending,
  syncing,
  completed,
  error,
  partialError,
  permanentError,
  conflict,
  offline,
  paused
}

/// Enum que representa o tipo de operação de sincronização
enum SyncOperation {
  create,
  update,
  delete,
  upsert
}


/// Classe que representa o status detalhado de sincronização
class SyncStatusInfo {
  final SyncStatus status;
  final String message;
  final int syncedCount;
  final int pendingCount;
  final int errorCount;
  final int conflictCount;
  final double progress;
  final DateTime? lastSync;
  final List<SyncConflict> conflicts;
  final Map<SyncModule, bool> moduleStatus;
  final String? errorDetails;

  SyncStatusInfo({
    required this.status,
    required this.message,
    this.syncedCount = 0,
    this.pendingCount = 0,
    this.errorCount = 0,
    this.conflictCount = 0,
    this.progress = 0.0,
    this.lastSync,
    this.conflicts = const [],
    this.moduleStatus = const {},
    this.errorDetails,
  });

  SyncStatusInfo copyWith({
    SyncStatus? status,
    String? message,
    int? syncedCount,
    int? pendingCount,
    int? errorCount,
    int? conflictCount,
    double? progress,
    DateTime? lastSync,
    List<SyncConflict>? conflicts,
    Map<SyncModule, bool>? moduleStatus,
    String? errorDetails,
  }) {
    return SyncStatusInfo(
      status: status ?? this.status,
      message: message ?? this.message,
      syncedCount: syncedCount ?? this.syncedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      errorCount: errorCount ?? this.errorCount,
      conflictCount: conflictCount ?? this.conflictCount,
      progress: progress ?? this.progress,
      lastSync: lastSync ?? this.lastSync,
      conflicts: conflicts ?? this.conflicts,
      moduleStatus: moduleStatus ?? this.moduleStatus,
      errorDetails: errorDetails ?? this.errorDetails,
    );
  }

  // Status pré-definidos
  static SyncStatusInfo get notStarted => SyncStatusInfo(
    status: SyncStatus.notStarted,
    message: 'Sincronização não iniciada',
  );

  static SyncStatusInfo get syncing => SyncStatusInfo(
    status: SyncStatus.syncing,
    message: 'Sincronização em andamento...',
  );

  static SyncStatusInfo get completed => SyncStatusInfo(
    status: SyncStatus.completed,
    message: 'Sincronização concluída com sucesso',
    progress: 1.0,
  );

  static SyncStatusInfo error(String details) => SyncStatusInfo(
    status: SyncStatus.error,
    message: 'Erro durante a sincronização',
    errorDetails: details,
  );

  static SyncStatusInfo conflict(List<SyncConflict> conflicts) => SyncStatusInfo(
    status: SyncStatus.conflict,
    message: 'Conflitos detectados - resolução necessária',
    conflicts: conflicts,
    conflictCount: conflicts.length,
  );

  static SyncStatusInfo offline() => SyncStatusInfo(
    status: SyncStatus.offline,
    message: 'Dispositivo offline - sincronização pausada',
  );
}

/// Configurações de sincronização
class SyncConfig {
  final String serverUrl;
  final String apiKey;
  final Duration timeout;
  final int maxRetries;
  final int batchSize;
  final bool autoSync;
  final Duration autoSyncInterval;
  final bool conflictResolution;
  final bool offlineMode;

  const SyncConfig({
    required this.serverUrl,
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.batchSize = 100,
    this.autoSync = true,
    this.autoSyncInterval = const Duration(minutes: 15),
    this.conflictResolution = true,
    this.offlineMode = true,
  });
}

/// Serviço completo de sincronização de dados
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Streams e controladores
  final StreamController<SyncStatusInfo> _statusController = StreamController<SyncStatusInfo>.broadcast();
  final StreamController<SyncBatch> _batchController = StreamController<SyncBatch>.broadcast();
  
  // Configuração e estado
  SyncConfig? _config;
  SyncStatusInfo _currentStatus = SyncStatusInfo.notStarted;
  Timer? _autoSyncTimer;
  bool _isInitialized = false;
  bool _isOnline = true;
  
  // Dependências
  final Connectivity _connectivity = Connectivity();
  final AppDatabase _database = AppDatabase();
  late SharedPreferences _prefs;
  
  // Getters
  Stream<SyncStatusInfo> get statusStream => _statusController.stream;
  Stream<SyncBatch> get batchStream => _batchController.stream;
  SyncStatusInfo get currentStatus => _currentStatus;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  /// Inicializa o serviço de sincronização
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('🔧 Inicializando sistema de sincronização completo...');
      
      // Inicializar dependências
      _prefs = await SharedPreferences.getInstance();
      
      // Configurar conectividade
      await _setupConnectivity();
      
      // Carregar configuração
      await _loadConfig();
      
      // Banco de dados já inicializado automaticamente
      
      // Configurar auto-sync se habilitado
      if (_config?.autoSync == true) {
        _setupAutoSync();
      }
      
      _isInitialized = true;
      _updateStatus(SyncStatusInfo.notStarted);
      
      Logger.info('✅ Sistema de sincronização inicializado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar sistema de sincronização: $e');
      _updateStatus(SyncStatusInfo.error('Falha na inicialização: $e'));
      rethrow;
    }
  }

  /// Configura monitoramento de conectividade
  Future<void> _setupConnectivity() async {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      
      if (_isOnline) {
        Logger.info('🌐 Conectividade restaurada');
        if (_currentStatus.status == SyncStatus.offline) {
          _updateStatus(SyncStatusInfo.notStarted);
        }
      } else {
        Logger.warning('📵 Dispositivo offline');
        _updateStatus(SyncStatusInfo.offline());
      }
    });
    
    // Verificar conectividade inicial
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  /// Carrega configuração de sincronização
  Future<void> _loadConfig() async {
    final serverUrl = _prefs.getString('sync_server_url') ?? 'https://api.fortsmart.com';
    final apiKey = _prefs.getString('sync_api_key') ?? 'default_api_key';
    final autoSync = _prefs.getBool('sync_auto_sync') ?? true;
    final batchSize = _prefs.getInt('sync_batch_size') ?? 100;
    final timeout = _prefs.getInt('sync_timeout') ?? 30;
    
    _config = SyncConfig(
      serverUrl: serverUrl,
      apiKey: apiKey,
      autoSync: autoSync,
      batchSize: batchSize,
      timeout: Duration(seconds: timeout),
    );
    
    Logger.info('📋 Configuração de sincronização carregada');
  }

  /// Configura auto-sincronização
  void _setupAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_config!.autoSyncInterval, (timer) {
      if (_isOnline && _currentStatus.status != SyncStatus.syncing) {
        startSync();
      }
    });
  }

  /// Atualiza o status da sincronização
  void _updateStatus(SyncStatusInfo status) {
    _currentStatus = status;
    _statusController.add(status);
    
    // Salvar último status
    _prefs.setString('last_sync_status', status.status.name);
    _prefs.setString('last_sync_message', status.message);
    if (status.lastSync != null) {
      _prefs.setInt('last_sync_timestamp', status.lastSync!.millisecondsSinceEpoch);
    }
  }

  /// Inicia sincronização completa
  Future<void> startSync() async {
    if (!_isInitialized) {
      throw Exception('Serviço não inicializado');
    }
    
    if (!_isOnline) {
      _updateStatus(SyncStatusInfo.offline());
      return;
    }
    
    if (_currentStatus.status == SyncStatus.syncing) {
      Logger.warning('⚠️ Sincronização já em andamento');
      return;
    }

    try {
      Logger.info('🔄 Iniciando sincronização completa...');
      _updateStatus(SyncStatusInfo.syncing);
      
      // 1. Preparar dados para sincronização
      final syncBatches = await _prepareSyncBatches();
      
      // 2. Sincronizar cada módulo
      int totalSynced = 0;
      int totalErrors = 0;
      List<SyncConflict> conflicts = [];
      
      for (final batch in syncBatches) {
        try {
          final result = await _syncBatch(batch);
          totalSynced += result.syncedCount;
          totalErrors += result.errorCount;
          conflicts.addAll(result.conflicts);
          
          // Atualizar progresso
          final progress = (totalSynced + totalErrors) / (totalSynced + totalErrors + batch.pendingCount);
          _updateStatus(_currentStatus.copyWith(
            progress: progress,
            syncedCount: totalSynced,
            errorCount: totalErrors,
            conflicts: conflicts,
          ));
          
    } catch (e) {
          Logger.error('❌ Erro ao sincronizar módulo ${batch.module}: $e');
          totalErrors++;
        }
      }
      
      // 3. Finalizar sincronização
      if (conflicts.isNotEmpty) {
        _updateStatus(SyncStatusInfo.conflict(conflicts));
      } else if (totalErrors > 0) {
        _updateStatus(SyncStatusInfo(
          status: SyncStatus.partialError,
          message: 'Sincronização parcial com erros',
          syncedCount: totalSynced,
          errorCount: totalErrors,
          progress: 1.0,
          lastSync: DateTime.now(),
        ));
          } else {
        _updateStatus(SyncStatusInfo.completed.copyWith(
          syncedCount: totalSynced,
          lastSync: DateTime.now(),
        ));
      }
      
      Logger.info('✅ Sincronização concluída: $totalSynced sincronizados, $totalErrors erros');
      
        } catch (e) {
      Logger.error('❌ Erro durante sincronização: $e');
      _updateStatus(SyncStatusInfo.error('Erro crítico: $e'));
    }
  }

  /// Prepara lotes de sincronização para cada módulo
  Future<List<SyncBatch>> _prepareSyncBatches() async {
    final batches = <SyncBatch>[];
    
    // Sincronizar cada módulo
    for (final module in SyncModule.values) {
      final batch = await _createSyncBatch(module);
      if (batch.pendingCount > 0) {
        batches.add(batch);
      }
    }
    
    return batches;
  }

  /// Cria lote de sincronização para um módulo específico
  Future<SyncBatch> _createSyncBatch(SyncModule module) async {
    // Implementar lógica específica para cada módulo
    // Por enquanto, retornar lote vazio
    return SyncBatch(
      id: const Uuid().v4(),
      module: module,
      operations: [],
      pendingCount: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Sincroniza um lote específico
  Future<SyncBatchResult> _syncBatch(SyncBatch batch) async {
    // Implementar lógica de sincronização do lote
    // Por enquanto, retornar resultado vazio
    return SyncBatchResult(
      syncedCount: 0,
      errorCount: 0,
      conflicts: [],
    );
  }

  /// Para a sincronização
  void stopSync() {
    Logger.info('⏹️ Parando sincronização...');
    _autoSyncTimer?.cancel();
    _updateStatus(SyncStatusInfo.notStarted);
  }

  /// Pausa a sincronização
  void pauseSync() {
    Logger.info('⏸️ Pausando sincronização...');
    _updateStatus(_currentStatus.copyWith(
      status: SyncStatus.paused,
      message: 'Sincronização pausada',
    ));
  }

  /// Resolve conflitos de sincronização
  Future<void> resolveConflicts(List<SyncConflict> conflicts) async {
    // Implementar resolução de conflitos
    Logger.info('🔧 Resolvendo ${conflicts.length} conflitos...');
  }

  /// Configura o serviço
  Future<void> configure(SyncConfig config) async {
    _config = config;
    
    // Salvar configuração
    await _prefs.setString('sync_server_url', config.serverUrl);
    await _prefs.setString('sync_api_key', config.apiKey);
    await _prefs.setBool('sync_auto_sync', config.autoSync);
    await _prefs.setInt('sync_batch_size', config.batchSize);
    await _prefs.setInt('sync_timeout', config.timeout.inSeconds);
    
    // Reconfigurar auto-sync se necessário
    if (config.autoSync) {
      _setupAutoSync();
      } else {
      _autoSyncTimer?.cancel();
    }
    
    Logger.info('⚙️ Configuração de sincronização atualizada');
  }

  /// Obtém o tempo da última sincronização
  Future<DateTime?> getLastSyncTime() async {
    try {
      final lastSyncString = _prefs.getString('last_sync_time');
      if (lastSyncString != null) {
        return DateTime.parse(lastSyncString);
      }
        return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter tempo da última sincronização: $e');
      return null;
    }
  }
  
  /// Limpa recursos
  void dispose() {
    _autoSyncTimer?.cancel();
    _statusController.close();
    _batchController.close();
  }
}

/// Resultado da sincronização de um lote
class SyncBatchResult {
  final int syncedCount;
  final int errorCount;
  final List<SyncConflict> conflicts;

  SyncBatchResult({
    required this.syncedCount,
    required this.errorCount,
    required this.conflicts,
  });
}
