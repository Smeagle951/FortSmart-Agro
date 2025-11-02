import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/app_database.dart';
import '../models/infestacao_model.dart';
import '../utils/logger.dart';
import 'monitoring_infestation_integration_service.dart';
import 'monitoring_event_service.dart';

/// Status da sincronização
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Resultado da sincronização
class SyncResult {
  final SyncStatus status;
  final int totalRecords;
  final int syncedRecords;
  final int failedRecords;
  final List<String> errors;
  final DateTime timestamp;

  SyncResult({
    required this.status,
    required this.totalRecords,
    required this.syncedRecords,
    required this.failedRecords,
    required this.errors,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == SyncStatus.success;
  bool get hasErrors => errors.isNotEmpty;
  double get successRate => totalRecords > 0 ? syncedRecords / totalRecords : 0.0;
}

/// Serviço central de sincronização
/// Gerencia sincronização offline entre módulos de monitoramento e infestação
class CentralSyncService {
  static final CentralSyncService _instance = CentralSyncService._internal();
  factory CentralSyncService() => _instance;
  CentralSyncService._internal();

  // Dependências
  final MonitoringInfestationIntegrationService _integrationService = 
      MonitoringInfestationIntegrationService();
  final MonitoringEventService _eventService = MonitoringEventService();
  final Connectivity _connectivity = Connectivity();
  
  // Estado da sincronização
  SyncStatus _currentStatus = SyncStatus.idle;
  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Stream controller para status
  final StreamController<SyncResult> _syncController = 
      StreamController<SyncResult>.broadcast();
  
  // Configurações
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 30);
  
  /// Stream público de resultados de sincronização
  Stream<SyncResult> get syncStream => _syncController.stream;
  
  /// Status atual da sincronização
  SyncStatus get currentStatus => _currentStatus;
  
  /// Inicializa o serviço de sincronização
  Future<void> initialize() async {
    try {
      await _integrationService.initialize();
      await _eventService.initialize();
      
      // Configurar listener automático
      _eventService.addListener(
        InfestationMapAutoIntegrationListener(_integrationService),
      );
      
      // Iniciar monitoramento de conectividade
      await _startConnectivityMonitoring();
      
      // Iniciar sincronização periódica
      await _startPeriodicSync();
      
      Logger.info('✅ [SYNC] Serviço central de sincronização inicializado');
    } catch (e) {
      Logger.error('❌ [SYNC] Erro ao inicializar: $e');
      _setStatus(SyncStatus.error);
    }
  }
  
  /// Inicia monitoramento de conectividade
  Future<void> _startConnectivityMonitoring() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        Logger.info('📡 [SYNC] Conectividade alterada: $result');
        
        if (result != ConnectivityResult.none) {
          // Conectividade restaurada, tentar sincronizar
          await syncPendingData();
        } else {
          _setStatus(SyncStatus.offline);
        }
      },
    );
  }
  
  /// Inicia sincronização periódica
  Future<void> _startPeriodicSync() async {
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      if (await _isOnline()) {
        await syncPendingData();
      }
    });
  }
  
  /// Verifica se está online
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      Logger.error('❌ [SYNC] Erro ao verificar conectividade: $e');
      return false;
    }
  }
  
  /// Define status da sincronização
  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    Logger.info('🔄 [SYNC] Status alterado para: $status');
  }
  
  /// Sincroniza dados pendentes
  Future<SyncResult> syncPendingData() async {
    try {
      if (_currentStatus == SyncStatus.syncing) {
        Logger.info('⏳ [SYNC] Sincronização já em andamento');
        return SyncResult(
          status: SyncStatus.syncing,
          totalRecords: 0,
          syncedRecords: 0,
          failedRecords: 0,
          errors: ['Sincronização já em andamento'],
        );
      }
      
      if (!await _isOnline()) {
        Logger.info('📡 [SYNC] Sem conectividade, aguardando...');
        _setStatus(SyncStatus.offline);
        return SyncResult(
          status: SyncStatus.offline,
          totalRecords: 0,
          syncedRecords: 0,
          failedRecords: 0,
          errors: ['Sem conectividade'],
        );
      }
      
      _setStatus(SyncStatus.syncing);
      Logger.info('🔄 [SYNC] Iniciando sincronização...');
      
      // 1. Obter dados pendentes
      final pendingData = await _getPendingData();
      final totalRecords = pendingData.length;
      
      if (totalRecords == 0) {
        Logger.info('✅ [SYNC] Nenhum dado pendente para sincronizar');
        _setStatus(SyncStatus.success);
        final result = SyncResult(
          status: SyncStatus.success,
          totalRecords: 0,
          syncedRecords: 0,
          failedRecords: 0,
          errors: [],
        );
        _syncController.add(result);
        return result;
      }
      
      Logger.info('📊 [SYNC] ${totalRecords} registros pendentes encontrados');
      
      // 2. Sincronizar dados
      int syncedRecords = 0;
      int failedRecords = 0;
      final List<String> errors = [];
      
      for (final data in pendingData) {
        try {
          await _syncSingleRecord(data);
          syncedRecords++;
          
          // Pequena pausa para não sobrecarregar
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failedRecords++;
          errors.add('Erro ao sincronizar ${data['id']}: $e');
          Logger.error('❌ [SYNC] Erro ao sincronizar registro ${data['id']}: $e');
        }
      }
      
      // 3. Marcar como sincronizados
      if (syncedRecords > 0) {
        await _markAsSynced(pendingData.take(syncedRecords).map((d) => d['id'] as String).toList());
      }
      
      // 4. Limpar duplicações
      await _integrationService.cleanDuplicateInfestationRecords();
      
      // 5. Resultado final
      final status = failedRecords == 0 ? SyncStatus.success : SyncStatus.error;
      _setStatus(status);
      
      final result = SyncResult(
        status: status,
        totalRecords: totalRecords,
        syncedRecords: syncedRecords,
        failedRecords: failedRecords,
        errors: errors,
      );
      
      _syncController.add(result);
      
      Logger.info('✅ [SYNC] Sincronização concluída: $syncedRecords/$totalRecords sucessos');
      return result;
      
    } catch (e) {
      Logger.error('❌ [SYNC] Erro na sincronização: $e');
      _setStatus(SyncStatus.error);
      
      final result = SyncResult(
        status: SyncStatus.error,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        errors: [e.toString()],
      );
      
      _syncController.add(result);
      return result;
    }
  }
  
  /// Obtém dados pendentes de sincronização
  Future<List<Map<String, dynamic>>> _getPendingData() async {
    try {
      final database = await AppDatabase().database;
      
      // Buscar dados não sincronizados
      final results = await database.rawQuery('''
        SELECT 
          m.id,
          m.talhao_id,
          m.ponto_id,
          m.cultura_id,
          m.cultura_nome,
          m.talhao_nome,
          m.latitude,
          m.longitude,
          m.tipo_ocorrencia,
          m.subtipo_ocorrencia,
          m.nivel_ocorrencia,
          m.percentual_ocorrencia,
          m.observacao,
          m.foto_paths,
          m.data_hora_ocorrencia,
          m.data_hora_monitoramento,
          m.created_at,
          m.updated_at
        FROM monitoring_history m
        WHERE m.sincronizado = 0
        ORDER BY m.created_at ASC
        LIMIT 100
      ''');
      
      return results;
    } catch (e) {
      Logger.error('❌ [SYNC] Erro ao obter dados pendentes: $e');
      return [];
    }
  }
  
  /// Sincroniza um único registro
  Future<void> _syncSingleRecord(Map<String, dynamic> data) async {
    try {
      // Converter para InfestacaoModel
      final occurrence = InfestacaoModel(
        id: data['id'] as String,
        talhaoId: data['talhao_id'] as int,
        pontoId: data['ponto_id'] as int,
        tipo: data['tipo_ocorrencia'] as String,
        subtipo: data['subtipo_ocorrencia'] as String,
        nivel: data['nivel_ocorrencia'] as String,
        percentual: data['percentual_ocorrencia'] as int,
        observacao: data['observacao'] as String? ?? '',
        fotoPaths: data['foto_paths'] as String? ?? '',
        dataHora: DateTime.parse(data['data_hora_ocorrencia'] as String),
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
      );
      
      // Enviar para integração
      await _integrationService.sendMonitoringDataToInfestationMap(
        occurrence: occurrence,
        preventDuplicates: true,
      );
      
    } catch (e) {
      Logger.error('❌ [SYNC] Erro ao sincronizar registro: $e');
      rethrow;
    }
  }
  
  /// Marca registros como sincronizados
  Future<void> _markAsSynced(List<String> occurrenceIds) async {
    try {
      final database = await AppDatabase().database;
      
      for (final id in occurrenceIds) {
        await database.update(
          'monitoring_history',
          {
            'sincronizado': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      Logger.info('✅ [SYNC] ${occurrenceIds.length} registros marcados como sincronizados');
    } catch (e) {
      Logger.error('❌ [SYNC] Erro ao marcar como sincronizado: $e');
    }
  }
  
  /// Força sincronização imediata
  Future<SyncResult> forceSync() async {
    Logger.info('🔄 [SYNC] Sincronização forçada solicitada');
    return await syncPendingData();
  }
  
  /// Obtém estatísticas de sincronização
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final database = await AppDatabase().database;
      
      // Estatísticas gerais
      final stats = await database.rawQuery('''
        SELECT 
          COUNT(*) as total_records,
          COUNT(CASE WHEN sincronizado = 1 THEN 1 END) as synced_records,
          COUNT(CASE WHEN sincronizado = 0 THEN 1 END) as pending_records,
          COUNT(CASE WHEN data_hora_ocorrencia >= datetime('now', '-7 days') THEN 1 END) as recent_records,
          COUNT(CASE WHEN data_hora_ocorrencia >= datetime('now', '-30 days') THEN 1 END) as monthly_records
        FROM monitoring_history
      ''');
      
      // Estatísticas por talhão
      final talhaoStats = await database.rawQuery('''
        SELECT 
          talhao_id,
          talhao_nome,
          COUNT(*) as total_records,
          COUNT(CASE WHEN sincronizado = 0 THEN 1 END) as pending_records,
          AVG(percentual_ocorrencia) as avg_infestation
        FROM monitoring_history
        WHERE data_hora_ocorrencia >= datetime('now', '-30 days')
        GROUP BY talhao_id, talhao_nome
        ORDER BY pending_records DESC
      ''');
      
      return {
        'general': stats.isNotEmpty ? stats.first : {},
        'by_talhao': talhaoStats,
        'status': _currentStatus.toString(),
        'last_sync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ [SYNC] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Limpa dados antigos
  Future<void> cleanupOldData({int daysToKeep = 365}) async {
    try {
      final database = await AppDatabase().database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      // Limpar dados antigos
      await database.delete(
        'monitoring_history',
        where: 'data_hora_ocorrencia < ? AND sincronizado = 1',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      await database.delete(
        'infestation_map',
        where: 'data_hora_ocorrencia < ? AND sincronizado = 1',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      Logger.info('✅ [SYNC] Limpeza de dados antigos concluída');
    } catch (e) {
      Logger.error('❌ [SYNC] Erro na limpeza: $e');
    }
  }
  
  /// Para o serviço
  Future<void> stop() async {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncController.close();
    _eventService.dispose();
    Logger.info('✅ [SYNC] Serviço central de sincronização finalizado');
  }
}
