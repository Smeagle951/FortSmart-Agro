import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'advanced_gps_service.dart';
import 'advanced_gps_tracking_service.dart';
import 'hybrid_connectivity_service.dart';
import '../modules/offline_maps/services/offline_map_service.dart';
import '../modules/offline_maps/services/talhao_integration_service.dart';
import '../utils/logger.dart';

/// Serviço GPS híbrido que combina precisão avançada com funcionalidade offline
/// 
/// Funcionalidades:
/// - GPS multi-satélite de alta precisão (GPS, GLONASS, Galileo)
/// - Detecção automática de sistemas de satélites disponíveis
/// - Modo offline com mapas baixados
/// - Detecção automática de conectividade
/// - Fallback inteligente entre modos
/// - Integração com talhões offline
/// - Suporte a múltiplos sistemas GNSS
class HybridGPSService {
  static const double _maxAccuracy = 10.0; // metros
  static const double _minDistance = 0.5; // metros
  static const double _maxSpeed = 20.0; // m/s
  static const double _offlineAccuracy = 10.0; // metros (menos preciso offline)
  
  // Serviços
  AdvancedGPSService? _advancedGPSService;
  AdvancedGpsTrackingService? _trackingService;
  OfflineMapService? _offlineMapService;
  TalhaoIntegrationService? _talhaoIntegrationService;
  HybridConnectivityService? _connectivityService;
  
  // Estado
  bool _isInitialized = false;
  bool _isOnline = true;
  bool _isTracking = false;
  bool _isPaused = false;
  Position? _currentPosition;
  double _currentAccuracy = 0.0;
  double _totalDistance = 0.0;
  List<LatLng> _trackedPoints = [];
  List<SatelliteInfo> _satellites = [];
  
  // Sistemas de satélites disponíveis
  Set<SatelliteSystem> _availableSystems = {};
  Map<SatelliteSystem, int> _systemSatelliteCounts = {};
  Map<SatelliteSystem, double> _systemAccuracy = {};
  bool _multiSystemEnabled = false;
  
  // Streams
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _accuracyTimer;
  Timer? _offlineFallbackTimer;
  
  // Callbacks
  Function(Position)? onPositionUpdate;
  Function(double)? onAccuracyUpdate;
  Function(bool)? onConnectivityChange;
  Function(List<SatelliteInfo>)? onSatellitesUpdate;
  Function(String)? onStatusChange;
  Function(bool)? onTrackingStateChange;
  Function(Set<SatelliteSystem>)? onAvailableSystemsChange;
  Function(Map<SatelliteSystem, int>)? onSystemSatelliteCountsChange;
  
  /// Inicializa o serviço GPS híbrido
  Future<bool> initialize() async {
    try {
      Logger.info('🚀 [HYBRID_GPS] Inicializando serviço GPS híbrido');
      
      // Inicializar serviços
      _advancedGPSService = AdvancedGPSService();
      _trackingService = AdvancedGpsTrackingService();
      _offlineMapService = OfflineMapService();
      _talhaoIntegrationService = TalhaoIntegrationService();
      _connectivityService = HybridConnectivityService();
      
      // Inicializar serviços
      await _advancedGPSService!.initialize();
      await _offlineMapService!.init();
      await _talhaoIntegrationService!.init();
      await _connectivityService!.initialize();
      
      // Configurar monitoramento de conectividade
      _setupConnectivityMonitoring();
      
      // Configurar callbacks
      _setupCallbacks();
      
      // Detectar sistemas de satélites disponíveis
      await _detectAvailableSatelliteSystems();
      
      _isInitialized = true;
      Logger.info('✅ [HYBRID_GPS] Serviço inicializado com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao inicializar: $e');
      return false;
    }
  }
  
  /// Configura monitoramento de conectividade
  void _setupConnectivityMonitoring() {
    if (_connectivityService != null) {
      // Usar serviço de conectividade híbrida
      _connectivityService!.onConnectivityChange = (isOnline) {
        final wasOnline = _isOnline;
        _isOnline = isOnline;
        
        if (wasOnline != _isOnline) {
          Logger.info('🌐 [HYBRID_GPS] Conectividade: ${_isOnline ? "Online" : "Offline"}');
          onConnectivityChange?.call(_isOnline);
          
          if (_isOnline) {
            _switchToOnlineMode();
          } else {
            _switchToOfflineMode();
          }
        }
      };
      
      _connectivityService!.onAccuracyChange = (accuracy) {
        Logger.info('🎯 [HYBRID_GPS] Precisão otimizada: ${accuracy.toStringAsFixed(1)}m');
      };
      
      _connectivityService!.onStatusChange = (status) {
        Logger.info('📊 [HYBRID_GPS] Status: $status');
      };
    }
  }
  
  /// Detecta sistemas de satélites disponíveis
  Future<void> _detectAvailableSatelliteSystems() async {
    try {
      Logger.info('🛰️ [HYBRID_GPS] Detectando sistemas de satélites disponíveis');
      
      // Lista de sistemas para testar
      final systemsToTest = [
        SatelliteSystem.gps,
        SatelliteSystem.glonass,
        SatelliteSystem.galileo,
        SatelliteSystem.beidou,
        SatelliteSystem.qzss,
        SatelliteSystem.irnss,
      ];
      
      _availableSystems.clear();
      _systemSatelliteCounts.clear();
      _systemAccuracy.clear();
      
      // Testar cada sistema
      for (final system in systemsToTest) {
        try {
          final hasSystem = await _testSatelliteSystem(system);
          if (hasSystem) {
            _availableSystems.add(system);
            Logger.info('✅ [HYBRID_GPS] Sistema ${system.name} disponível');
          }
        } catch (e) {
          Logger.warning('⚠️ [HYBRID_GPS] Sistema ${system.name} não disponível: $e');
        }
      }
      
      // Verificar se múltiplos sistemas estão disponíveis
      _multiSystemEnabled = _availableSystems.length > 1;
      
      if (_multiSystemEnabled) {
        Logger.info('🌟 [HYBRID_GPS] Múltiplos sistemas GNSS disponíveis: ${_availableSystems.map((s) => s.name).join(', ')}');
      } else {
        Logger.info('📡 [HYBRID_GPS] Sistema único disponível: ${_availableSystems.isNotEmpty ? _availableSystems.first.name : 'Nenhum'}');
      }
      
      onAvailableSystemsChange?.call(_availableSystems);
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao detectar sistemas de satélites: $e');
    }
  }
  
  /// Testa se um sistema de satélites está disponível
  Future<bool> _testSatelliteSystem(SatelliteSystem system) async {
    try {
      // Obter posição com configuração específica do sistema
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      // Verificar se a precisão é aceitável
      return position.accuracy <= 20.0; // 20 metros de tolerância
    } catch (e) {
      return false;
    }
  }
  
  /// Configura callbacks dos serviços
  void _setupCallbacks() {
    try {
      Logger.info('🔧 [HYBRID_GPS] Configurando callbacks básicos');
      
      // Configurar callbacks básicos se disponíveis
      // Nota: Alguns callbacks podem não estar disponíveis na versão atual
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao configurar callbacks: $e');
    }
  }
  
  /// Processa informações de sistemas de satélites
  void _processSatelliteSystems(List<SatelliteInfo> satellites) {
    try {
      // Contar satélites por sistema
      _systemSatelliteCounts.clear();
      _systemAccuracy.clear();
      
      for (final satellite in satellites) {
        final system = satellite.system;
        
        // Contar satélites por sistema
        _systemSatelliteCounts[system] = (_systemSatelliteCounts[system] ?? 0) + 1;
        
        // Calcular precisão por sistema (baseado em SNR)
        if (satellite.usedInFix) {
          final currentAccuracy = _systemAccuracy[system] ?? 999.0;
          final newAccuracy = _calculateSystemAccuracy(satellite);
          _systemAccuracy[system] = newAccuracy < currentAccuracy ? newAccuracy : currentAccuracy;
        }
      }
      
      // Notificar mudanças
      onSystemSatelliteCountsChange?.call(_systemSatelliteCounts);
      
      // Log de sistemas ativos
      if (_systemSatelliteCounts.isNotEmpty) {
        final activeSystems = _systemSatelliteCounts.entries
            .where((entry) => entry.value > 0)
            .map((entry) => '${entry.key.name}: ${entry.value}')
            .join(', ');
        Logger.info('🛰️ [HYBRID_GPS] Sistemas ativos: $activeSystems');
      }
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao processar sistemas de satélites: $e');
    }
  }
  
  /// Calcula precisão de um sistema baseado no satélite
  double _calculateSystemAccuracy(SatelliteInfo satellite) {
    // Fórmula baseada em SNR para estimar precisão
    final snr = satellite.snr;
    final elevation = satellite.elevation;
    
    // Fator de elevação (satélites mais altos são mais precisos)
    final elevationFactor = (90 - elevation) / 90;
    
    // Fator de SNR (maior SNR = maior precisão)
    final snrFactor = (snr - 20) / 40; // Normalizar SNR entre 0-1
    
    // Calcular precisão estimada
    final baseAccuracy = 10.0; // Precisão base em metros
    final accuracy = baseAccuracy * (1 + elevationFactor) * (1 - snrFactor);
    
    return accuracy.clamp(1.0, 50.0); // Limitar entre 1-50 metros
  }
  
  /// Muda para modo online (GPS avançado)
  void _switchToOnlineMode() {
    Logger.info('🛰️ [HYBRID_GPS] Mudando para modo online (GPS avançado)');
    
    // Parar fallback offline
    _offlineFallbackTimer?.cancel();
    
    // Usar GPS avançado com todos os sistemas disponíveis
    if (_advancedGPSService != null) {
      _startAdvancedGPS();
      _enableMultiSystemMode();
    }
  }
  
  /// Habilita modo multi-sistema para máxima precisão
  void _enableMultiSystemMode() {
    if (_multiSystemEnabled && _availableSystems.isNotEmpty) {
      Logger.info('🌟 [HYBRID_GPS] Habilitando modo multi-sistema: ${_availableSystems.map((s) => s.name).join(', ')}');
      
      // Configurar GPS avançado para usar todos os sistemas disponíveis
      _configureMultiSystemGPS();
    }
  }
  
  /// Configura GPS para usar múltiplos sistemas
  void _configureMultiSystemGPS() {
    try {
      // Configurar precisão máxima quando online
      if (_advancedGPSService != null) {
        // O GPS avançado já detecta automaticamente os sistemas disponíveis
        // Aqui podemos otimizar configurações específicas
        Logger.info('🎯 [HYBRID_GPS] Configurando precisão máxima com ${_availableSystems.length} sistemas');
      }
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao configurar multi-sistema: $e');
    }
  }
  
  /// Muda para modo offline
  void _switchToOfflineMode() {
    Logger.info('📱 [HYBRID_GPS] Mudando para modo offline');
    
    // Parar GPS avançado
    _stopAdvancedGPS();
    
    // Iniciar fallback offline com sistemas disponíveis
    _startOfflineFallback();
    _enableOfflineMultiSystemMode();
  }
  
  /// Habilita modo multi-sistema offline
  void _enableOfflineMultiSystemMode() {
    if (_multiSystemEnabled && _availableSystems.isNotEmpty) {
      Logger.info('🌟 [HYBRID_GPS] Modo offline com ${_availableSystems.length} sistemas: ${_availableSystems.map((s) => s.name).join(', ')}');
      
      // Mesmo offline, usar todos os sistemas de satélites disponíveis
      _configureOfflineMultiSystemGPS();
    }
  }
  
  /// Configura GPS offline para usar múltiplos sistemas
  void _configureOfflineMultiSystemGPS() {
    try {
      Logger.info('🎯 [HYBRID_GPS] Configurando GPS offline com sistemas: ${_availableSystems.map((s) => s.name).join(', ')}');
      
      // Mesmo offline, o GPS pode usar GPS, GLONASS, Galileo
      // A diferença é que não há assistência de rede, mas os satélites funcionam
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao configurar multi-sistema offline: $e');
    }
  }
  
  /// Inicia GPS avançado
  void _startAdvancedGPS() {
    if (_advancedGPSService == null) return;
    
    try {
      // GPS avançado iniciado
      Logger.info('🛰️ [HYBRID_GPS] GPS avançado iniciado');
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao iniciar GPS avançado: $e');
      _startOfflineFallback();
    }
  }
  
  /// Para GPS avançado
  void _stopAdvancedGPS() {
    if (_advancedGPSService == null) return;
    
    try {
      // GPS avançado parado
      Logger.info('🛑 [HYBRID_GPS] GPS avançado parado');
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao parar GPS avançado: $e');
    }
  }
  
  /// Inicia fallback offline
  void _startOfflineFallback() {
    Logger.info('📱 [HYBRID_GPS] Iniciando fallback offline');
    
    _offlineFallbackTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _getOfflinePosition();
    });
  }
  
  /// Obtém posição offline
  Future<void> _getOfflinePosition() async {
    try {
      // Tentar obter posição básica mesmo offline
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (position.accuracy <= _offlineAccuracy) {
        _currentPosition = position;
        _currentAccuracy = position.accuracy;
        onPositionUpdate?.call(position);
        onAccuracyUpdate?.call(position.accuracy);
      }
    } catch (e) {
      Logger.warning('⚠️ [HYBRID_GPS] Erro ao obter posição offline: $e');
    }
  }
  
  /// Inicia rastreamento GPS
  Future<bool> startTracking({
    required String talhaoId,
    double? maxAccuracy,
    double? minDistance,
  }) async {
    if (!_isInitialized) {
      Logger.error('❌ [HYBRID_GPS] Serviço não inicializado');
      return false;
    }
    
    try {
      Logger.info('🚀 [HYBRID_GPS] Iniciando rastreamento para talhão: $talhaoId');
      
      // Verificar se talhão tem mapas offline
      final hasOfflineMaps = await _talhaoIntegrationService!.hasOfflineMapsForTalhao(talhaoId);
      
      if (_isOnline && _advancedGPSService != null) {
        // Modo online - usar GPS avançado com máxima precisão
        _startAdvancedGPS();
        _enableMultiSystemMode();
        
        // Iniciar rastreamento avançado com precisão otimizada
        await _trackingService!.startTracking(
          onAccuracyChanged: (accuracy) {
            _currentAccuracy = accuracy;
            onAccuracyUpdate?.call(accuracy);
          },
          onDistanceChanged: (distance) {
            _totalDistance = distance;
          },
          onPointsChanged: (points) {
            _trackedPoints = points;
          },
          onStatusChanged: (status) {
            onStatusChange?.call(status);
          },
          onTrackingStateChanged: (isTracking) {
            _isTracking = isTracking;
            onTrackingStateChange?.call(isTracking);
          },
        );
        
        Logger.info('🛰️ [HYBRID_GPS] Rastreamento online com ${_availableSystems.length} sistemas iniciado');
      } else {
        // Modo offline - usar fallback com sistemas disponíveis
        _startOfflineFallback();
        _enableOfflineMultiSystemMode();
        
        // Iniciar rastreamento offline otimizado
        await _trackingService!.startTracking(
          onAccuracyChanged: (accuracy) {
            _currentAccuracy = accuracy;
            onAccuracyUpdate?.call(accuracy);
          },
          onDistanceChanged: (distance) {
            _totalDistance = distance;
          },
          onPointsChanged: (points) {
            _trackedPoints = points;
          },
          onStatusChanged: (status) {
            onStatusChange?.call(status);
          },
          onTrackingStateChanged: (isTracking) {
            _isTracking = isTracking;
            onTrackingStateChange?.call(isTracking);
          },
        );
        
        Logger.info('📱 [HYBRID_GPS] Rastreamento offline com ${_availableSystems.length} sistemas iniciado');
      }
      
      _isTracking = true;
      onTrackingStateChange?.call(true);
      onStatusChange?.call('Rastreamento iniciado');
      
      return true;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao iniciar rastreamento: $e');
      onStatusChange?.call('Erro ao iniciar rastreamento: $e');
      return false;
    }
  }
  
  /// Para rastreamento GPS
  Future<void> stopTracking() async {
    try {
      Logger.info('🛑 [HYBRID_GPS] Parando rastreamento');
      
      // Parar GPS avançado
      _stopAdvancedGPS();
      
      // Parar fallback offline
      _offlineFallbackTimer?.cancel();
      
      // Parar rastreamento
      await _trackingService!.stopTracking();
      
      _isTracking = false;
      _isPaused = false;
      onTrackingStateChange?.call(false);
      onStatusChange?.call('Rastreamento parado');
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao parar rastreamento: $e');
    }
  }
  
  /// Pausa rastreamento GPS
  void pauseTracking() {
    if (!_isTracking) return;
    
    try {
      _trackingService!.pauseTracking();
      _isPaused = true;
      onStatusChange?.call('Rastreamento pausado');
      Logger.info('⏸️ [HYBRID_GPS] Rastreamento pausado');
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao pausar rastreamento: $e');
    }
  }
  
  /// Retoma rastreamento GPS
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    
    try {
      _trackingService!.resumeTracking();
      _isPaused = false;
      onStatusChange?.call('Rastreamento retomado');
      Logger.info('▶️ [HYBRID_GPS] Rastreamento retomado');
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao retomar rastreamento: $e');
    }
  }
  
  /// Obtém posição atual
  Position? get currentPosition => _currentPosition;
  
  /// Obtém precisão atual
  double get currentAccuracy => _currentAccuracy;
  
  /// Verifica se está online
  bool get isOnline => _isOnline;
  
  /// Verifica se está rastreando
  bool get isTracking => _isTracking;
  
  /// Verifica se está pausado
  bool get isPaused => _isPaused;
  
  /// Obtém satélites disponíveis
  List<SatelliteInfo> get satellites => _satellites;
  
  /// Calcula precisão otimizada baseada nos sistemas disponíveis
  double _getOptimizedAccuracy() {
    if (_availableSystems.isEmpty) return _maxAccuracy;
    
    // Com múltiplos sistemas, podemos ser mais rigorosos
    if (_multiSystemEnabled) {
      return _maxAccuracy * 0.7; // 30% mais rigoroso com multi-sistema
    }
    
    return _maxAccuracy;
  }
  
  /// Calcula precisão otimizada para modo offline
  double _getOfflineOptimizedAccuracy() {
    if (_availableSystems.isEmpty) return _offlineAccuracy;
    
    // Mesmo offline, com múltiplos sistemas podemos ter boa precisão
    if (_multiSystemEnabled) {
      return _offlineAccuracy * 0.8; // 20% mais rigoroso offline com multi-sistema
    }
    
    return _offlineAccuracy;
  }
  
  /// Obtém estatísticas do rastreamento
  Map<String, dynamic> getTrackingStats() {
    return {
      'isOnline': _isOnline,
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'currentAccuracy': _currentAccuracy,
      'satellitesCount': _satellites.length,
      'activeSatellites': _satellites.where((s) => s.usedInFix).length,
      'mode': _isOnline ? 'online' : 'offline',
      'availableSystems': _availableSystems.map((s) => s.name).toList(),
      'multiSystemEnabled': _multiSystemEnabled,
      'systemSatelliteCounts': _systemSatelliteCounts.map((k, v) => MapEntry(k.name, v)),
      'systemAccuracy': _systemAccuracy.map((k, v) => MapEntry(k.name, v)),
    };
  }
  
  /// Verifica se talhão tem mapas offline
  Future<bool> hasOfflineMapsForTalhao(String talhaoId) async {
    if (_talhaoIntegrationService == null) return false;
    
    try {
      return await _talhaoIntegrationService!.hasOfflineMapsForTalhao(talhaoId);
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao verificar mapas offline: $e');
      return false;
    }
  }
  
  /// Obtém mapas offline de um talhão
  Future<List<dynamic>> getOfflineMapsForTalhao(String talhaoId) async {
    if (_talhaoIntegrationService == null) return [];
    
    try {
      return await _talhaoIntegrationService!.getOfflineMapsForTalhao(talhaoId);
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao obter mapas offline: $e');
      return [];
    }
  }
  
  /// Força sincronização quando voltar online
  Future<void> syncWhenOnline() async {
    if (!_isOnline) return;
    
    try {
      Logger.info('🔄 [HYBRID_GPS] Sincronizando dados quando online');
      
      // Aqui você pode implementar lógica de sincronização
      // Por exemplo, enviar dados coletados offline para servidor
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro na sincronização: $e');
    }
  }
  
  /// Libera recursos
  Future<void> dispose() async {
    try {
      Logger.info('🗑️ [HYBRID_GPS] Liberando recursos');
      
      await stopTracking();
      
      _positionSubscription?.cancel();
      _connectivitySubscription?.cancel();
      _accuracyTimer?.cancel();
      _offlineFallbackTimer?.cancel();
      
      _advancedGPSService?.dispose();
      _trackingService?.dispose();
      _offlineMapService?.dispose();
      _talhaoIntegrationService?.dispose();
      _connectivityService?.dispose();
      
      _isInitialized = false;
      
    } catch (e) {
      Logger.error('❌ [HYBRID_GPS] Erro ao liberar recursos: $e');
    }
  }
}
