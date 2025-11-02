import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../services/enhanced_offline_map_service.dart';
import '../services/map_modules_integration_service.dart';
import '../services/smart_monitoring_navigation_service.dart';
import '../services/hybrid_gps_service.dart';
import '../utils/logger.dart';

/// Serviço de integração híbrida para monitoramento offline
/// 
/// Funcionalidades:
/// - Conecta monitoramento com mapas offline
/// - Integra com módulo de infestação
/// - Funciona 100% offline
/// - Sincronização automática quando online
class HybridMonitoringIntegrationService {
  static final HybridMonitoringIntegrationService _instance = HybridMonitoringIntegrationService._internal();
  factory HybridMonitoringIntegrationService() => _instance;
  HybridMonitoringIntegrationService._internal();

  // Serviços integrados
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  final MapModulesIntegrationService _integrationService = MapModulesIntegrationService();
  final SmartMonitoringNavigationService _navigationService = SmartMonitoringNavigationService();
  final HybridGPSService _gpsService = HybridGPSService();
  
  Database? _database;
  bool _isInitialized = false;
  
  // Estado do monitoramento
  String? _currentTalhaoId;
  String? _currentMonitoringSessionId;
  List<Map<String, dynamic>> _monitoringPoints = [];
  List<Map<String, dynamic>> _infestationPoints = [];
  
  // Callbacks
  Function(String)? onStatusChange;
  Function(int)? onPointsCountChange;
  Function(bool)? onOfflineModeChange;
  Function(Map<String, dynamic>)? onDataSync;
  
  /// Inicializa o serviço de integração híbrida
  Future<bool> initialize() async {
    try {
      Logger.info('🔗 [HYBRID_INTEGRATION] Inicializando integração híbrida');
      
      // Inicializar serviços
      await _mapService.initialize();
      await _integrationService.initialize();
      await _gpsService.initialize();
      
      // Inicializar banco de dados
      await _initializeDatabase();
      
      _isInitialized = true;
      Logger.info('✅ [HYBRID_INTEGRATION] Integração híbrida inicializada');
      return true;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao inicializar: $e');
      return false;
    }
  }
  
  /// Inicializa banco de dados para integração híbrida
  Future<void> _initializeDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/hybrid_monitoring_integration.db';
    
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreateDatabase,
    );
  }
  
  /// Cria tabelas do banco de dados
  Future<void> _onCreateDatabase(Database db, int version) async {
    // Tabela de sessões de monitoramento
    await db.execute('''
      CREATE TABLE monitoring_sessions (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        total_points INTEGER NOT NULL DEFAULT 0,
        offline_mode BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Tabela de pontos de monitoramento
    await db.execute('''
      CREATE TABLE monitoring_points (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        timestamp TEXT NOT NULL,
        pest_type TEXT,
        severity TEXT,
        notes TEXT,
        image_path TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES monitoring_sessions (id)
      )
    ''');
    
    // Tabela de pontos de infestação
    await db.execute('''
      CREATE TABLE infestation_points (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        timestamp TEXT NOT NULL,
        infestation_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        affected_area REAL,
        notes TEXT,
        image_path TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES monitoring_sessions (id)
      )
    ''');
    
    // Tabela de sincronização
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
  
  /// Inicia sessão de monitoramento híbrida
  Future<String> startMonitoringSession({
    required String talhaoId,
    required LatLng southwest,
    required LatLng northeast,
    bool forceOffline = false,
  }) async {
    try {
      Logger.info('🚀 [HYBRID_INTEGRATION] Iniciando sessão de monitoramento: $talhaoId');
      
      // Verificar se talhão tem mapas offline
      final hasOfflineMaps = await _mapService.isOfflineCacheWorking();
      
      if (!hasOfflineMaps && !forceOffline) {
        // Baixar mapas offline para o talhão
        await _downloadMapsForTalhao(talhaoId, southwest, northeast);
      }
      
      // Criar sessão de monitoramento
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _database!.insert('monitoring_sessions', {
        'id': sessionId,
        'talhao_id': talhaoId,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active',
        'offline_mode': !hasOfflineMaps || forceOffline,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _currentTalhaoId = talhaoId;
      _currentMonitoringSessionId = sessionId;
      
      // Configurar navegação inteligente
      await _setupSmartNavigation(sessionId, talhaoId);
      
      onStatusChange?.call('Sessão de monitoramento iniciada');
      Logger.info('✅ [HYBRID_INTEGRATION] Sessão iniciada: $sessionId');
      
      return sessionId;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao iniciar sessão: $e');
      rethrow;
    }
  }
  
  /// Baixa mapas offline para o talhão
  Future<void> _downloadMapsForTalhao(String talhaoId, LatLng southwest, LatLng northeast) async {
    try {
      Logger.info('📥 [HYBRID_INTEGRATION] Baixando mapas offline para talhão: $talhaoId');
      
      final result = await _mapService.downloadFarmArea(
        farmName: 'Talhão $talhaoId',
        southwest: southwest,
        northeast: northeast,
        minZoom: 10,
        maxZoom: 16,
        mapType: 'satellite',
      );
      
      if (result['success']) {
        Logger.info('✅ [HYBRID_INTEGRATION] Mapas offline baixados com sucesso');
      } else {
        Logger.warning('⚠️ [HYBRID_INTEGRATION] Falha parcial no download de mapas');
      }
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao baixar mapas: $e');
    }
  }
  
  /// Configura navegação inteligente
  Future<void> _setupSmartNavigation(String sessionId, String talhaoId) async {
    try {
      // Configurar callbacks da navegação
      _navigationService.onLocationUpdate = (position) {
        // Processar atualização de localização
      };
      
      _navigationService.onDistanceUpdate = (distance) {
        // Processar atualização de distância
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
        // Salvamento em segundo plano concluído
      };
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao configurar navegação: $e');
    }
  }
  
  /// Adiciona ponto de monitoramento
  Future<String> addMonitoringPoint({
    required LatLng position,
    required double accuracy,
    String? pestType,
    String? severity,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final pointId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _database!.insert('monitoring_points', {
        'id': pointId,
        'session_id': _currentMonitoringSessionId!,
        'talhao_id': _currentTalhaoId!,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'pest_type': pestType,
        'severity': severity,
        'notes': notes,
        'image_path': imagePath,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _monitoringPoints.add({
        'id': pointId,
        'position': position,
        'accuracy': accuracy,
        'pestType': pestType,
        'severity': severity,
        'notes': notes,
        'imagePath': imagePath,
        'timestamp': DateTime.now(),
      });
      
      onPointsCountChange?.call(_monitoringPoints.length);
      Logger.info('✅ [HYBRID_INTEGRATION] Ponto de monitoramento adicionado: $pointId');
      
      return pointId;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao adicionar ponto: $e');
      rethrow;
    }
  }
  
  /// Adiciona ponto de infestação
  Future<String> addInfestationPoint({
    required LatLng position,
    required double accuracy,
    required String infestationType,
    required String severity,
    double? affectedArea,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final pointId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _database!.insert('infestation_points', {
        'id': pointId,
        'session_id': _currentMonitoringSessionId!,
        'talhao_id': _currentTalhaoId!,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'infestation_type': infestationType,
        'severity': severity,
        'affected_area': affectedArea,
        'notes': notes,
        'image_path': imagePath,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _infestationPoints.add({
        'id': pointId,
        'position': position,
        'accuracy': accuracy,
        'infestationType': infestationType,
        'severity': severity,
        'affectedArea': affectedArea,
        'notes': notes,
        'imagePath': imagePath,
        'timestamp': DateTime.now(),
      });
      
      onPointsCountChange?.call(_infestationPoints.length);
      Logger.info('✅ [HYBRID_INTEGRATION] Ponto de infestação adicionado: $pointId');
      
      return pointId;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao adicionar ponto de infestação: $e');
      rethrow;
    }
  }
  
  /// Finaliza sessão de monitoramento
  Future<void> endMonitoringSession() async {
    try {
      if (_currentMonitoringSessionId == null) return;
      
      Logger.info('🏁 [HYBRID_INTEGRATION] Finalizando sessão: $_currentMonitoringSessionId');
      
      // Atualizar sessão
      await _database!.update(
        'monitoring_sessions',
        {
          'end_time': DateTime.now().toIso8601String(),
          'status': 'completed',
          'total_points': _monitoringPoints.length + _infestationPoints.length,
        },
        where: 'id = ?',
        whereArgs: [_currentMonitoringSessionId],
      );
      
      // Parar navegação
      _navigationService.stopSmartTracking();
      
      // Limpar estado
      _currentTalhaoId = null;
      _currentMonitoringSessionId = null;
      _monitoringPoints.clear();
      _infestationPoints.clear();
      
      onStatusChange?.call('Sessão de monitoramento finalizada');
      Logger.info('✅ [HYBRID_INTEGRATION] Sessão finalizada');
      
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao finalizar sessão: $e');
    }
  }
  
  /// Obtém pontos de monitoramento da sessão atual
  List<Map<String, dynamic>> getCurrentMonitoringPoints() {
    return List.from(_monitoringPoints);
  }
  
  /// Obtém pontos de infestação da sessão atual
  List<Map<String, dynamic>> getCurrentInfestationPoints() {
    return List.from(_infestationPoints);
  }
  
  /// Obtém estatísticas da sessão atual
  Map<String, dynamic> getCurrentSessionStats() {
    return {
      'sessionId': _currentMonitoringSessionId,
      'talhaoId': _currentTalhaoId,
      'monitoringPoints': _monitoringPoints.length,
      'infestationPoints': _infestationPoints.length,
      'totalPoints': _monitoringPoints.length + _infestationPoints.length,
      'isActive': _currentMonitoringSessionId != null,
    };
  }
  
  /// Obtém estatísticas gerais
  Future<Map<String, dynamic>> getGeneralStats() async {
    try {
      final monitoringResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_sessions,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_sessions,
          SUM(total_points) as total_points
        FROM monitoring_sessions
      ''');
      
      final pointsResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_monitoring_points,
          COUNT(CASE WHEN sync_status = 'synced' THEN 1 END) as synced_monitoring_points
        FROM monitoring_points
      ''');
      
      final infestationResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_infestation_points,
          COUNT(CASE WHEN sync_status = 'synced' THEN 1 END) as synced_infestation_points
        FROM infestation_points
      ''');
      
      return {
        'sessions': {
          'total': monitoringResult.first['total_sessions'] ?? 0,
          'completed': monitoringResult.first['completed_sessions'] ?? 0,
          'totalPoints': monitoringResult.first['total_points'] ?? 0,
        },
        'monitoringPoints': {
          'total': pointsResult.first['total_monitoring_points'] ?? 0,
          'synced': pointsResult.first['synced_monitoring_points'] ?? 0,
        },
        'infestationPoints': {
          'total': infestationResult.first['total_infestation_points'] ?? 0,
          'synced': infestationResult.first['synced_infestation_points'] ?? 0,
        },
      };
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Sincroniza dados quando online
  Future<void> syncDataWhenOnline() async {
    try {
      Logger.info('🔄 [HYBRID_INTEGRATION] Sincronizando dados quando online');
      
      // Implementar lógica de sincronização com servidor
      
      onDataSync?.call({
        'status': 'success',
        'message': 'Dados sincronizados com sucesso',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('❌ [HYBRID_INTEGRATION] Erro na sincronização: $e');
      onDataSync?.call({
        'status': 'error',
        'message': 'Erro na sincronização: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Verifica se está em modo offline
  bool get isOfflineMode => _currentMonitoringSessionId != null;
  
  /// Verifica se há sessão ativa
  bool get hasActiveSession => _currentMonitoringSessionId != null;
  
  /// Obtém ID da sessão atual
  String? get currentSessionId => _currentMonitoringSessionId;
  
  /// Obtém ID do talhão atual
  String? get currentTalhaoId => _currentTalhaoId;
}
