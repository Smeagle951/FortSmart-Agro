import 'dart:async';
import '../utils/logger.dart';
import 'hybrid_gps_service.dart';
import 'enhanced_offline_map_service.dart';
import 'hybrid_offline_integration_service.dart';

/// Serviço de integração entre o sistema híbrido e os módulos de mapas offline
class HybridMapsIntegrationService {
  static final HybridMapsIntegrationService _instance = HybridMapsIntegrationService._internal();
  factory HybridMapsIntegrationService() => _instance;
  HybridMapsIntegrationService._internal();

  // Serviços
  HybridGPSService? _hybridGPS;
  EnhancedOfflineMapService? _offlineMapService;
  HybridOfflineIntegrationService? _integrationService;
  
  // Estado
  bool _isInitialized = false;
  bool _isOnline = true;
  Map<String, dynamic> _currentStatus = {};
  
  // Streams
  final StreamController<Map<String, dynamic>> _statusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Callbacks
  Function(Map<String, dynamic>)? onStatusUpdate;
  Function(bool)? onConnectivityChange;
  Function(String)? onError;

  /// Inicializa o serviço de integração
  Future<bool> initialize() async {
    try {
      Logger.info('🚀 [HYBRID_MAPS] Inicializando integração híbrida de mapas');
      
      // Inicializar serviços
      _hybridGPS = HybridGPSService();
      _offlineMapService = EnhancedOfflineMapService();
      _integrationService = HybridOfflineIntegrationService();
      
      // Inicializar serviços
      await _hybridGPS!.initialize();
      await _offlineMapService!.initialize();
      await _integrationService!.initialize();
      
      // Configurar callbacks
      _setupCallbacks();
      
      _isInitialized = true;
      Logger.info('✅ [HYBRID_MAPS] Integração híbrida inicializada');
      
      return true;
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao inicializar: $e');
      onError?.call('Erro ao inicializar integração: $e');
      return false;
    }
  }

  /// Configura callbacks dos serviços
  void _setupCallbacks() {
    // Callbacks do GPS híbrido
    _hybridGPS!.onConnectivityChange = (isOnline) {
      _isOnline = isOnline;
      onConnectivityChange?.call(isOnline);
      _updateStatus();
    };
    
    _hybridGPS!.onPositionUpdate = (position) {
      _updateStatus();
    };
    
    _hybridGPS!.onAccuracyUpdate = (accuracy) {
      _updateStatus();
    };
    
    // Callbacks da integração offline
    _integrationService!.onDataUpdate = (data) {
      _updateStatus();
    };
  }

  /// Atualiza status do sistema
  void _updateStatus() {
    if (!_isInitialized) return;
    
    try {
      final gpsStats = _hybridGPS?.getTrackingStats() ?? {};
      final mapStats = _offlineMapService?.getCacheStats() ?? {};
      final integrationStats = _integrationService?.getIntegrationStats() ?? {};
      
      _currentStatus = {
        'isOnline': _isOnline,
        'isInitialized': _isInitialized,
        'gps': gpsStats,
        'maps': mapStats,
        'integration': integrationStats,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      onStatusUpdate?.call(_currentStatus);
      _statusController.add(_currentStatus);
      
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao atualizar status: $e');
    }
  }

  /// Inicia rastreamento híbrido para um talhão
  Future<bool> startHybridTracking({
    required String talhaoId,
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    if (!_isInitialized) {
      Logger.error('❌ [HYBRID_MAPS] Serviço não inicializado');
      return false;
    }
    
    try {
      Logger.info('🚀 [HYBRID_MAPS] Iniciando rastreamento híbrido para talhão: $talhaoId');
      
      // Verificar se talhão tem mapas offline
      final hasOfflineMaps = await _hybridGPS!.hasOfflineMapsForTalhao(talhaoId);
      
      if (hasOfflineMaps) {
        Logger.info('📱 [HYBRID_MAPS] Talhão tem mapas offline disponíveis');
      }
      
      // Iniciar rastreamento GPS híbrido
      final gpsStarted = await _hybridGPS!.startTracking(
        talhaoId: talhaoId,
        maxAccuracy: _isOnline ? 10.0 : 15.0,
        minDistance: 0.5,
      );
      
      if (gpsStarted) {
        // Iniciar integração offline
        await _integrationService!.startHybridSession(
          talhaoId: talhaoId,
          southwest: southwest,
          northeast: northeast,
        );
        
        Logger.info('✅ [HYBRID_MAPS] Rastreamento híbrido iniciado');
        _updateStatus();
        return true;
      }
      
      return false;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao iniciar rastreamento: $e');
      onError?.call('Erro ao iniciar rastreamento: $e');
      return false;
    }
  }

  /// Para rastreamento híbrido
  Future<void> stopHybridTracking() async {
    try {
      Logger.info('🛑 [HYBRID_MAPS] Parando rastreamento híbrido');
      
      await _hybridGPS?.stopTracking();
      await _integrationService?.endHybridSession();
      
      _updateStatus();
      
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao parar rastreamento: $e');
    }
  }

  /// Adiciona dados de monitoramento
  Future<bool> addMonitoringData({
    required String talhaoId,
    required LatLng position,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) return false;
    
    try {
      return await _integrationService!.addMonitoringData(
        talhaoId: talhaoId,
        position: position,
        data: data,
      );
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao adicionar dados de monitoramento: $e');
      return false;
    }
  }

  /// Adiciona dados de infestação
  Future<bool> addInfestationData({
    required String talhaoId,
    required LatLng position,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) return false;
    
    try {
      return await _integrationService!.addInfestationData(
        talhaoId: talhaoId,
        position: position,
        data: data,
      );
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao adicionar dados de infestação: $e');
      return false;
    }
  }

  /// Sincroniza dados quando online
  Future<void> syncDataWhenOnline() async {
    if (!_isOnline || !_isInitialized) return;
    
    try {
      Logger.info('🔄 [HYBRID_MAPS] Sincronizando dados quando online');
      
      await _hybridGPS?.syncWhenOnline();
      await _integrationService?.syncDataWhenOnline();
      
      _updateStatus();
      
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro na sincronização: $e');
    }
  }

  /// Obtém status atual do sistema
  Map<String, dynamic> getCurrentStatus() {
    return Map.from(_currentStatus);
  }

  /// Stream de atualizações de status
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  /// Verifica se está online
  bool get isOnline => _isOnline;

  /// Verifica se está inicializado
  bool get isInitialized => _isInitialized;

  /// Libera recursos
  Future<void> dispose() async {
    try {
      Logger.info('🗑️ [HYBRID_MAPS] Liberando recursos');
      
      await stopHybridTracking();
      await _hybridGPS?.dispose();
      await _offlineMapService?.dispose();
      await _integrationService?.dispose();
      
      await _statusController.close();
      
      _isInitialized = false;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS] Erro ao liberar recursos: $e');
    }
  }
}
