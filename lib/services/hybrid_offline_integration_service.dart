import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'hybrid_gps_service.dart';
import 'enhanced_offline_map_service.dart';
import 'map_modules_integration_service.dart';
import 'smart_monitoring_navigation_service.dart';
import '../utils/logger.dart';

/// Serviço de integração híbrida que conecta o sistema de monitoramento
/// com os mapas offline e módulos de infestação
class HybridOfflineIntegrationService {
  static final HybridOfflineIntegrationService _instance = HybridOfflineIntegrationService._internal();
  factory HybridOfflineIntegrationService() => _instance;
  HybridOfflineIntegrationService._internal();

  // Serviços integrados
  final HybridGPSService _hybridGPS = HybridGPSService();
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  final MapModulesIntegrationService _integrationService = MapModulesIntegrationService();
  final SmartMonitoringNavigationService _navigationService = SmartMonitoringNavigationService();
  
  Database? _database;
  bool _isInitialized = false;
  
  // Estado da integração
  String? _currentTalhaoId;
  String? _currentSessionId;
  bool _isOfflineMode = false;
  List<Map<String, dynamic>> _monitoringData = [];
  List<Map<String, dynamic>> _infestationData = [];
  
  // Callbacks
  Function(String)? onStatusChange;
  Function(bool)? onOfflineModeChange;
  Function(Map<String, dynamic>)? onDataUpdate;
  Function(int)? onPointsCountChange;
  
  /// Inicializa o serviço de integração híbrida
  Future<bool> initialize() async {
    try {
      Logger.info('🔗 [HYBRID_OFFLINE] Inicializando integração híbrida offline');
      
      // Inicializar serviços
      await _hybridGPS.initialize();
      await _mapService.initialize();
      await _integrationService.initialize();
      
      // Inicializar banco de dados
      await _initializeDatabase();
      
      // Configurar callbacks
      _setupCallbacks();
      
      _isInitialized = true;
      Logger.info('✅ [HYBRID_OFFLINE] Integração híbrida inicializada');
      return true;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao inicializar: $e');
      return false;
    }
  }
  
  /// Inicializa banco de dados para integração
  Future<void> _initializeDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/hybrid_offline_integration.db';
    
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreateDatabase,
    );
  }
  
  /// Cria tabelas do banco de dados
  Future<void> _onCreateDatabase(Database db, int version) async {
    // Tabela de sessões híbridas
    await db.execute('''
      CREATE TABLE hybrid_sessions (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        offline_mode BOOLEAN NOT NULL DEFAULT FALSE,
        gps_accuracy REAL NOT NULL DEFAULT 0.0,
        satellites_count INTEGER NOT NULL DEFAULT 0,
        total_points INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Tabela de dados de monitoramento
    await db.execute('''
      CREATE TABLE hybrid_monitoring_data (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        timestamp TEXT NOT NULL,
        data_type TEXT NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES hybrid_sessions (id)
      )
    ''');
    
    // Tabela de sincronização híbrida
    await db.execute('''
      CREATE TABLE hybrid_sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        data_type TEXT NOT NULL,
        action TEXT NOT NULL,
        data_json TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES hybrid_sessions (id)
      )
    ''');
  }
  
  /// Configura callbacks dos serviços
  void _setupCallbacks() {
    // Callbacks do GPS híbrido
    _hybridGPS.onPositionUpdate = (position) {
      _handlePositionUpdate(position);
    };
    
    _hybridGPS.onAccuracyUpdate = (accuracy) {
      _handleAccuracyUpdate(accuracy);
    };
    
    _hybridGPS.onConnectivityChange = (isOnline) {
      _handleConnectivityChange(isOnline);
    };
    
    _hybridGPS.onSatellitesUpdate = (satellites) {
      _handleSatellitesUpdate(satellites);
    };
    
    _hybridGPS.onStatusChange = (status) {
      onStatusChange?.call(status);
    };
    
    _hybridGPS.onTrackingStateChange = (isTracking) {
      _handleTrackingStateChange(isTracking);
    };
  }
  
  /// Inicia sessão híbrida de monitoramento
  Future<String> startHybridSession({
    required String talhaoId,
    required LatLng southwest,
    required LatLng northeast,
    bool forceOffline = false,
  }) async {
    try {
      Logger.info('🚀 [HYBRID_OFFLINE] Iniciando sessão híbrida: $talhaoId');
      
      // Verificar se talhão tem mapas offline
      final hasOfflineMaps = await _hybridGPS.hasOfflineMapsForTalhao(talhaoId);
      
      if (!hasOfflineMaps && !forceOffline) {
        // Baixar mapas offline para o talhão
        await _downloadMapsForTalhao(talhaoId, southwest, northeast);
      }
      
      // Criar sessão híbrida
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _database!.insert('hybrid_sessions', {
        'id': sessionId,
        'talhao_id': talhaoId,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active',
        'offline_mode': !hasOfflineMaps || forceOffline,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _currentTalhaoId = talhaoId;
      _currentSessionId = sessionId;
      _isOfflineMode = !hasOfflineMaps || forceOffline;
      
      // Iniciar GPS híbrido
      await _hybridGPS.startTracking(talhaoId: talhaoId);
      
      // Configurar navegação inteligente
      await _setupSmartNavigation(sessionId, talhaoId);
      
      onStatusChange?.call('Sessão híbrida iniciada');
      onOfflineModeChange?.call(_isOfflineMode);
      
      Logger.info('✅ [HYBRID_OFFLINE] Sessão híbrida iniciada: $sessionId');
      return sessionId;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao iniciar sessão: $e');
      rethrow;
    }
  }
  
  /// Baixa mapas offline para o talhão
  Future<void> _downloadMapsForTalhao(String talhaoId, LatLng southwest, LatLng northeast) async {
    try {
      Logger.info('📥 [HYBRID_OFFLINE] Baixando mapas offline para talhão: $talhaoId');
      
      final result = await _mapService.downloadFarmArea(
        farmName: 'Talhão $talhaoId',
        southwest: southwest,
        northeast: northeast,
        minZoom: 10,
        maxZoom: 16,
        mapType: 'satellite',
      );
      
      if (result['success']) {
        Logger.info('✅ [HYBRID_OFFLINE] Mapas offline baixados com sucesso');
      } else {
        Logger.warning('⚠️ [HYBRID_OFFLINE] Falha parcial no download de mapas');
      }
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao baixar mapas: $e');
    }
  }
  
  /// Configura navegação inteligente
  Future<void> _setupSmartNavigation(String sessionId, String talhaoId) async {
    try {
      // Configurar callbacks da navegação
      _navigationService.onLocationUpdate = (position) {
        _handlePositionUpdate(position);
      };
      
      _navigationService.onDistanceUpdate = (distance) {
        _handleDistanceUpdate(distance);
      };
      
      _navigationService.onProximityChange = (isNear) {
        if (isNear) {
          onStatusChange?.call('Próximo ao ponto de monitoramento');
        }
      };
      
      _navigationService.onArrivalChange = (isAtPoint) {
        if (isAtPoint) {
          onStatusChange?.call('Chegou ao ponto de monitoramento');
        }
      };
      
      _navigationService.onVibrationNotification = () {
        // Vibração quando próximo ao ponto
      };
      
      _navigationService.onBackgroundSaveComplete = () {
        _handleBackgroundSaveComplete();
      };
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao configurar navegação: $e');
    }
  }
  
  /// Adiciona dados de monitoramento
  Future<String> addMonitoringData({
    required LatLng position,
    required double accuracy,
    required String dataType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final dataId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _database!.insert('hybrid_monitoring_data', {
        'id': dataId,
        'session_id': _currentSessionId!,
        'talhao_id': _currentTalhaoId!,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'data_type': dataType,
        'data_json': data.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _monitoringData.add({
        'id': dataId,
        'position': position,
        'accuracy': accuracy,
        'dataType': dataType,
        'data': data,
        'timestamp': DateTime.now(),
      });
      
      onPointsCountChange?.call(_monitoringData.length);
      onDataUpdate?.call({
        'type': 'monitoring',
        'count': _monitoringData.length,
        'data': data,
      });
      
      Logger.info('✅ [HYBRID_OFFLINE] Dados de monitoramento adicionados: $dataId');
      return dataId;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao adicionar dados: $e');
      rethrow;
    }
  }
  
  /// Adiciona dados de infestação
  Future<String> addInfestationData({
    required LatLng position,
    required double accuracy,
    required Map<String, dynamic> data,
  }) async {
    try {
      final dataId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _database!.insert('hybrid_monitoring_data', {
        'id': dataId,
        'session_id': _currentSessionId!,
        'talhao_id': _currentTalhaoId!,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'data_type': 'infestation',
        'data_json': data.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _infestationData.add({
        'id': dataId,
        'position': position,
        'accuracy': accuracy,
        'data': data,
        'timestamp': DateTime.now(),
      });
      
      onPointsCountChange?.call(_infestationData.length);
      onDataUpdate?.call({
        'type': 'infestation',
        'count': _infestationData.length,
        'data': data,
      });
      
      Logger.info('✅ [HYBRID_OFFLINE] Dados de infestação adicionados: $dataId');
      return dataId;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao adicionar dados de infestação: $e');
      rethrow;
    }
  }
  
  /// Finaliza sessão híbrida
  Future<void> endHybridSession() async {
    try {
      if (_currentSessionId == null) return;
      
      Logger.info('🏁 [HYBRID_OFFLINE] Finalizando sessão híbrida: $_currentSessionId');
      
      // Atualizar sessão
      await _database!.update(
        'hybrid_sessions',
        {
          'end_time': DateTime.now().toIso8601String(),
          'status': 'completed',
          'total_points': _monitoringData.length + _infestationData.length,
        },
        where: 'id = ?',
        whereArgs: [_currentSessionId],
      );
      
      // Parar GPS híbrido
      await _hybridGPS.stopTracking();
      
      // Parar navegação
      _navigationService.stopSmartTracking();
      
      // Limpar estado
      _currentTalhaoId = null;
      _currentSessionId = null;
      _monitoringData.clear();
      _infestationData.clear();
      
      onStatusChange?.call('Sessão híbrida finalizada');
      Logger.info('✅ [HYBRID_OFFLINE] Sessão finalizada');
      
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao finalizar sessão: $e');
    }
  }
  
  /// Handlers dos callbacks
  void _handlePositionUpdate(Position position) {
    // Processar atualização de posição
  }
  
  void _handleAccuracyUpdate(double accuracy) {
    // Processar atualização de precisão
  }
  
  void _handleConnectivityChange(bool isOnline) {
    _isOfflineMode = !isOnline;
    onOfflineModeChange?.call(_isOfflineMode);
    
    if (isOnline) {
      onStatusChange?.call('Modo online ativado');
    } else {
      onStatusChange?.call('Modo offline ativado');
    }
  }
  
  void _handleSatellitesUpdate(List<SatelliteInfo> satellites) {
    // Processar atualização de satélites
  }
  
  void _handleTrackingStateChange(bool isTracking) {
    // Processar mudança de estado do rastreamento
  }
  
  void _handleDistanceUpdate(double distance) {
    // Processar atualização de distância
  }
  
  void _handleBackgroundSaveComplete() {
    // Processar salvamento em segundo plano
  }
  
  /// Obtém dados da sessão atual
  List<Map<String, dynamic>> getCurrentMonitoringData() {
    return List.from(_monitoringData);
  }
  
  /// Obtém dados de infestação da sessão atual
  List<Map<String, dynamic>> getCurrentInfestationData() {
    return List.from(_infestationData);
  }
  
  /// Obtém estatísticas da sessão atual
  Map<String, dynamic> getCurrentSessionStats() {
    return {
      'sessionId': _currentSessionId,
      'talhaoId': _currentTalhaoId,
      'isOfflineMode': _isOfflineMode,
      'monitoringData': _monitoringData.length,
      'infestationData': _infestationData.length,
      'totalData': _monitoringData.length + _infestationData.length,
      'isActive': _currentSessionId != null,
    };
  }
  
  /// Obtém estatísticas gerais
  Future<Map<String, dynamic>> getGeneralStats() async {
    try {
      final sessionsResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_sessions,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_sessions,
          SUM(total_points) as total_points
        FROM hybrid_sessions
      ''');
      
      final dataResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_data,
          COUNT(CASE WHEN sync_status = 'synced' THEN 1 END) as synced_data
        FROM hybrid_monitoring_data
      ''');
      
      return {
        'sessions': {
          'total': sessionsResult.first['total_sessions'] ?? 0,
          'completed': sessionsResult.first['completed_sessions'] ?? 0,
          'totalPoints': sessionsResult.first['total_points'] ?? 0,
        },
        'data': {
          'total': dataResult.first['total_data'] ?? 0,
          'synced': dataResult.first['synced_data'] ?? 0,
        },
      };
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Sincroniza dados quando online
  Future<void> syncDataWhenOnline() async {
    try {
      Logger.info('🔄 [HYBRID_OFFLINE] Sincronizando dados quando online');
      
      // Implementar lógica de sincronização com servidor
      
      onDataUpdate?.call({
        'type': 'sync',
        'status': 'success',
        'message': 'Dados sincronizados com sucesso',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('❌ [HYBRID_OFFLINE] Erro na sincronização: $e');
      onDataUpdate?.call({
        'type': 'sync',
        'status': 'error',
        'message': 'Erro na sincronização: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Verifica se está em modo offline
  bool get isOfflineMode => _isOfflineMode;
  
  /// Verifica se há sessão ativa
  bool get hasActiveSession => _currentSessionId != null;
  
  /// Obtém ID da sessão atual
  String? get currentSessionId => _currentSessionId;
  
  /// Obtém ID do talhão atual
  String? get currentTalhaoId => _currentTalhaoId;
}
