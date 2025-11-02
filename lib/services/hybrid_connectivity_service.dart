import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

/// Serviço de conectividade híbrida que gerencia GPS online e offline
/// 
/// Funcionalidades:
/// - Detecção automática de conectividade
/// - Otimização de precisão baseada na conectividade
/// - Fallback inteligente entre modos
/// - Suporte a GPS, GLONASS, Galileo em ambos os modos
class HybridConnectivityService {
  static const double _onlineAccuracy = 5.0; // metros (com assistência de rede)
  static const double _offlineAccuracy = 10.0; // metros (sem assistência de rede)
  static const double _multiSystemBonus = 0.7; // 30% mais preciso com múltiplos sistemas
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _hasInternet = false;
  bool _hasCellular = false;
  bool _hasWifi = false;
  
  // Callbacks
  Function(bool isOnline)? onConnectivityChange;
  Function(double accuracy)? onAccuracyChange;
  Function(String status)? onStatusChange;
  
  /// Inicializa o serviço de conectividade
  Future<void> initialize() async {
    try {
      Logger.info('🌐 [HYBRID_CONNECTIVITY] Inicializando serviço de conectividade');
      
      // Verificar conectividade inicial
      await _checkInitialConnectivity();
      
      // Configurar monitoramento
      _setupConnectivityMonitoring();
      
      Logger.info('✅ [HYBRID_CONNECTIVITY] Serviço inicializado');
    } catch (e) {
      Logger.error('❌ [HYBRID_CONNECTIVITY] Erro ao inicializar: $e');
    }
  }
  
  /// Verifica conectividade inicial
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      await _processConnectivityChange(connectivityResult);
    } catch (e) {
      Logger.error('❌ [HYBRID_CONNECTIVITY] Erro ao verificar conectividade inicial: $e');
    }
  }
  
  /// Configura monitoramento de conectividade
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _processConnectivityChange,
      onError: (error) {
        Logger.error('❌ [HYBRID_CONNECTIVITY] Erro no monitoramento: $error');
      },
    );
  }
  
  /// Processa mudança de conectividade
  Future<void> _processConnectivityChange(ConnectivityResult result) async {
    try {
      final wasOnline = _isOnline;
      
      // Analisar tipo de conectividade
      _hasInternet = result != ConnectivityResult.none;
      _hasCellular = result == ConnectivityResult.mobile;
      _hasWifi = result == ConnectivityResult.wifi;
      _isOnline = _hasInternet;
      
      // Log de mudança
      if (wasOnline != _isOnline) {
        Logger.info('🌐 [HYBRID_CONNECTIVITY] Conectividade: ${_isOnline ? "Online" : "Offline"}');
        
        if (_isOnline) {
          Logger.info('📶 [HYBRID_CONNECTIVITY] Tipo: ${_hasWifi ? "WiFi" : "Cellular"}');
        }
        
        // Notificar mudança
        onConnectivityChange?.call(_isOnline);
        onStatusChange?.call(_getStatusText());
      }
      
      // Atualizar precisão baseada na conectividade
      final accuracy = _calculateOptimalAccuracy();
      onAccuracyChange?.call(accuracy);
      
    } catch (e) {
      Logger.error('❌ [HYBRID_CONNECTIVITY] Erro ao processar mudança: $e');
    }
  }
  
  /// Calcula precisão ótima baseada na conectividade
  double _calculateOptimalAccuracy() {
    if (_isOnline) {
      // Online: usar assistência de rede para máxima precisão
      return _onlineAccuracy;
    } else {
      // Offline: precisão reduzida mas ainda boa
      return _offlineAccuracy;
    }
  }
  
  /// Obtém texto de status
  String _getStatusText() {
    if (_isOnline) {
      if (_hasWifi) return 'Online (WiFi)';
      if (_hasCellular) return 'Online (Cellular)';
      return 'Online';
    } else {
      return 'Offline';
    }
  }
  
  /// Obtém configuração de precisão para GPS
  LocationAccuracy getLocationAccuracy() {
    if (_isOnline) {
      return LocationAccuracy.high; // Máxima precisão online
    } else {
      return LocationAccuracy.medium; // Precisão média offline
    }
  }
  
  /// Obtém configuração de distância para filtro
  double getDistanceFilter() {
    if (_isOnline) {
      return 1.0; // 1 metro online
    } else {
      return 2.0; // 2 metros offline
    }
  }
  
  /// Obtém timeout para obtenção de posição
  Duration getLocationTimeout() {
    if (_isOnline) {
      return const Duration(seconds: 10); // Timeout menor online
    } else {
      return const Duration(seconds: 15); // Timeout maior offline
    }
  }
  
  /// Verifica se deve usar assistência de rede
  bool shouldUseNetworkAssistance() {
    return _isOnline && _hasInternet;
  }
  
  /// Obtém configuração otimizada para rastreamento
  Map<String, dynamic> getTrackingConfiguration() {
    return {
      'isOnline': _isOnline,
      'hasInternet': _hasInternet,
      'hasWifi': _hasWifi,
      'hasCellular': _hasCellular,
      'locationAccuracy': getLocationAccuracy(),
      'distanceFilter': getDistanceFilter(),
      'timeout': getLocationTimeout(),
      'useNetworkAssistance': shouldUseNetworkAssistance(),
      'optimalAccuracy': _calculateOptimalAccuracy(),
      'status': _getStatusText(),
    };
  }
  
  /// Obtém estatísticas de conectividade
  Map<String, dynamic> getConnectivityStats() {
    return {
      'isOnline': _isOnline,
      'hasInternet': _hasInternet,
      'hasWifi': _hasWifi,
      'hasCellular': _hasCellular,
      'status': _getStatusText(),
      'optimalAccuracy': _calculateOptimalAccuracy(),
      'locationAccuracy': getLocationAccuracy().toString(),
      'distanceFilter': getDistanceFilter(),
      'timeout': getLocationTimeout().inSeconds,
    };
  }
  
  /// Força verificação de conectividade
  Future<void> forceConnectivityCheck() async {
    try {
      Logger.info('🔄 [HYBRID_CONNECTIVITY] Forçando verificação de conectividade');
      await _checkInitialConnectivity();
    } catch (e) {
      Logger.error('❌ [HYBRID_CONNECTIVITY] Erro na verificação forçada: $e');
    }
  }
  
  /// Verifica se está online
  bool get isOnline => _isOnline;
  
  /// Verifica se tem internet
  bool get hasInternet => _hasInternet;
  
  /// Verifica se tem WiFi
  bool get hasWifi => _hasWifi;
  
  /// Verifica se tem dados móveis
  bool get hasCellular => _hasCellular;
  
  /// Obtém status atual
  String get status => _getStatusText();
  
  /// Libera recursos
  void dispose() {
    try {
      Logger.info('🗑️ [HYBRID_CONNECTIVITY] Liberando recursos');
      _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
    } catch (e) {
      Logger.error('❌ [HYBRID_CONNECTIVITY] Erro ao liberar recursos: $e');
    }
  }
}
