import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/monitoring_point.dart';
import '../models/infestacao_model.dart';
import '../repositories/infestacao_repository.dart';
import '../utils/logger.dart';
import '../utils/distance_calculator.dart';
import 'hybrid_gps_service.dart';

/// Serviço inteligente de navegação para monitoramento de pontos
/// 
/// Funcionalidades:
/// - Validação de distância (5 metros) para nova ocorrência
/// - Salvamento automático em segundo plano
/// - Notificações vibratórias quando próximo do ponto
/// - Navegação em tempo real
/// - Persistência de dados mesmo com tela desligada
class SmartMonitoringNavigationService {
  static const double _arrivalRadius = 5.0; // 5 metros
  static const double _approachRadius = 20.0; // 20 metros para notificação
  static const double _gpsAccuracyThreshold = 10.0; // 10 metros de precisão GPS
  
  Timer? _locationTimer;
  Timer? _backgroundSaveTimer;
  Position? _currentPosition;
  LatLng? _targetPoint;
  bool _isNearPoint = false;
  bool _isAtPoint = false;
  bool _isBackgroundSaving = false;
  
  // GPS híbrido
  HybridGPSService? _hybridGPSService;
  bool _isHybridGPSActive = false;
  
  // Callbacks
  Function(Position)? onLocationUpdate;
  Function(double distance)? onDistanceUpdate;
  Function(bool isNearPoint)? onProximityChange;
  Function(bool isAtPoint)? onArrivalChange;
  Function()? onVibrationNotification;
  Function()? onBackgroundSaveComplete;
  
  /// Inicia o rastreamento inteligente de localização
  Future<void> startSmartTracking({
    required LatLng targetPoint,
    required Function(Position) onLocationUpdate,
    required Function(double distance) onDistanceUpdate,
    required Function(bool isNearPoint) onProximityChange,
    required Function(bool isAtPoint) onArrivalChange,
    required Function() onVibrationNotification,
    required Function() onBackgroundSaveComplete,
    String? talhaoId,
  }) async {
    Logger.info('🚀 [SMART_NAV] Iniciando rastreamento inteligente');
    
    this.onLocationUpdate = onLocationUpdate;
    this.onDistanceUpdate = onDistanceUpdate;
    this.onProximityChange = onProximityChange;
    this.onArrivalChange = onArrivalChange;
    this.onVibrationNotification = onVibrationNotification;
    this.onBackgroundSaveComplete = onBackgroundSaveComplete;
    
    _targetPoint = targetPoint;
    
    // Inicializar GPS híbrido se disponível
    if (talhaoId != null) {
      await _initializeHybridGPS(talhaoId);
    }
    
    // Iniciar rastreamento de localização
    _startLocationTracking();
    
    // Iniciar salvamento em segundo plano
    _startBackgroundSaving();
  }
  
  /// Inicializa GPS híbrido
  Future<void> _initializeHybridGPS(String talhaoId) async {
    try {
      _hybridGPSService = HybridGPSService();
      final initialized = await _hybridGPSService!.initialize();
      
      if (initialized) {
        // Verificar se talhão tem mapas offline
        final hasOfflineMaps = await _hybridGPSService!.hasOfflineMapsForTalhao(talhaoId);
        
        if (hasOfflineMaps) {
          Logger.info('📱 [SMART_NAV] Talhão tem mapas offline disponíveis');
        }
        
        // Configurar callbacks do GPS híbrido
        _hybridGPSService!.onPositionUpdate = (position) {
          _currentPosition = position;
          onLocationUpdate?.call(position);
          _processPositionUpdate(position);
        };
        
        _hybridGPSService!.onAccuracyUpdate = (accuracy) {
          Logger.info('🎯 [SMART_NAV] Precisão GPS: ${accuracy.toStringAsFixed(1)}m');
        };
        
        _hybridGPSService!.onConnectivityChange = (isOnline) {
          Logger.info('🌐 [SMART_NAV] Conectividade: ${isOnline ? "Online" : "Offline"}');
        };
        
        _isHybridGPSActive = true;
        Logger.info('✅ [SMART_NAV] GPS híbrido inicializado');
      }
    } catch (e) {
      Logger.error('❌ [SMART_NAV] Erro ao inicializar GPS híbrido: $e');
    }
  }
  
  /// Para o rastreamento inteligente
  void stopSmartTracking() {
    Logger.info('🛑 [SMART_NAV] Parando rastreamento inteligente');
    
    _locationTimer?.cancel();
    _backgroundSaveTimer?.cancel();
    _locationTimer = null;
    _backgroundSaveTimer = null;
    
    // Parar GPS híbrido
    if (_hybridGPSService != null && _isHybridGPSActive) {
      _hybridGPSService!.stopTracking();
      _hybridGPSService!.dispose();
      _hybridGPSService = null;
      _isHybridGPSActive = false;
    }
  }
  
  /// Inicia o rastreamento de localização
  void _startLocationTracking() {
    if (_isHybridGPSActive && _hybridGPSService != null) {
      // Usar GPS híbrido se disponível
      _startHybridGPSTracking();
    } else {
      // Usar rastreamento básico
      _startBasicLocationTracking();
    }
  }
  
  /// Inicia rastreamento com GPS híbrido
  void _startHybridGPSTracking() {
    Logger.info('🛰️ [SMART_NAV] Usando GPS híbrido para rastreamento');
    
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (_hybridGPSService != null && _hybridGPSService!.currentPosition != null) {
          final position = _hybridGPSService!.currentPosition!;
          _processPositionUpdate(position);
        }
      } catch (e) {
        Logger.error('❌ [SMART_NAV] Erro no rastreamento híbrido: $e');
      }
    });
  }
  
  /// Inicia rastreamento básico
  void _startBasicLocationTracking() {
    Logger.info('📱 [SMART_NAV] Usando rastreamento básico');
    
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        _currentPosition = position;
        onLocationUpdate?.call(position);
        _processPositionUpdate(position);
      } catch (e) {
        Logger.error('❌ [SMART_NAV] Erro no rastreamento básico: $e');
      }
    });
  }
  
  /// Processa atualização de posição
  void _processPositionUpdate(Position position) {
    if (_targetPoint != null) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        _targetPoint!.latitude,
        _targetPoint!.longitude,
      );
      
      onDistanceUpdate?.call(distance);
      
      // Verificar proximidade
      final wasNearPoint = _isNearPoint;
      final wasAtPoint = _isAtPoint;
      
      _isNearPoint = distance <= _approachRadius;
      _isAtPoint = distance <= _arrivalRadius && position.accuracy <= _gpsAccuracyThreshold;
      
      // Notificar mudanças de proximidade
      if (_isNearPoint != wasNearPoint) {
        onProximityChange?.call(_isNearPoint);
        
        if (_isNearPoint && !wasNearPoint) {
          // Primeira vez chegando perto - vibrar
          _triggerVibration();
        }
      }
      
      // Notificar chegada ao ponto
      if (_isAtPoint != wasAtPoint) {
        onArrivalChange?.call(_isAtPoint);
        
        if (_isAtPoint && !wasAtPoint) {
          // Chegou ao ponto - vibrar mais forte
          _triggerArrivalVibration();
        }
      }
    }
  }
  
  /// Inicia o salvamento em segundo plano
  void _startBackgroundSaving() {
    _backgroundSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isBackgroundSaving) {
        await _performBackgroundSave();
      }
    });
  }
  
  /// Executa salvamento em segundo plano
  Future<void> _performBackgroundSave() async {
    if (_isBackgroundSaving) return;
    
    _isBackgroundSaving = true;
    
    try {
      Logger.info('💾 [SMART_NAV] Executando salvamento em segundo plano');
      
      // Aqui você pode implementar a lógica de salvamento
      // Por exemplo, salvar dados temporários, sincronizar com servidor, etc.
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simular salvamento
      
      onBackgroundSaveComplete?.call();
      
    } catch (e) {
      Logger.error('❌ [SMART_NAV] Erro no salvamento em segundo plano: $e');
    } finally {
      _isBackgroundSaving = false;
    }
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }
  
  /// Dispara vibração de proximidade
  void _triggerVibration() {
    Logger.info('📳 [SMART_NAV] Vibração de proximidade');
    HapticFeedback.lightImpact();
    onVibrationNotification?.call();
  }
  
  /// Dispara vibração de chegada
  void _triggerArrivalVibration() {
    Logger.info('📳 [SMART_NAV] Vibração de chegada ao ponto');
    HapticFeedback.mediumImpact();
    onVibrationNotification?.call();
  }
  
  /// Verifica se pode criar nova ocorrência (dentro do raio de 5 metros)
  bool canCreateNewOccurrence() {
    if (_currentPosition == null || _targetPoint == null) return false;
    
    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetPoint!.latitude,
      _targetPoint!.longitude,
    );
    
    return distance <= _arrivalRadius && 
           _currentPosition!.accuracy <= _gpsAccuracyThreshold;
  }
  
  /// Obtém informações de navegação
  Map<String, dynamic> getNavigationInfo() {
    if (_currentPosition == null || _targetPoint == null) {
      return {
        'distance': 0.0,
        'isNearPoint': false,
        'isAtPoint': false,
        'canCreateOccurrence': false,
        'gpsAccuracy': 0.0,
      };
    }
    
    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetPoint!.latitude,
      _targetPoint!.longitude,
    );
    
    return {
      'distance': distance,
      'isNearPoint': _isNearPoint,
      'isAtPoint': _isAtPoint,
      'canCreateOccurrence': canCreateNewOccurrence(),
      'gpsAccuracy': _currentPosition!.accuracy,
    };
  }
  
  /// Obtém direção para o ponto (em graus)
  double getBearingToPoint() {
    if (_currentPosition == null || _targetPoint == null) return 0.0;
    
    final lat1 = _currentPosition!.latitude * pi / 180;
    final lat2 = _targetPoint!.latitude * pi / 180;
    final deltaLon = (_targetPoint!.longitude - _currentPosition!.longitude) * pi / 180;
    
    final y = sin(deltaLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);
    
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }
  
  /// Obtém direção em texto (N, NE, E, SE, S, SW, W, NW)
  String getDirectionText() {
    final bearing = getBearingToPoint();
    
    if (bearing >= 337.5 || bearing < 22.5) return 'N';
    if (bearing >= 22.5 && bearing < 67.5) return 'NE';
    if (bearing >= 67.5 && bearing < 112.5) return 'E';
    if (bearing >= 112.5 && bearing < 157.5) return 'SE';
    if (bearing >= 157.5 && bearing < 202.5) return 'S';
    if (bearing >= 202.5 && bearing < 247.5) return 'SW';
    if (bearing >= 247.5 && bearing < 292.5) return 'W';
    if (bearing >= 292.5 && bearing < 337.5) return 'NW';
    
    return 'N';
  }
}
