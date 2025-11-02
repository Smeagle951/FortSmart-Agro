import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/gps_walk_calculator.dart';
import '../utils/gps_walk_debug_helper.dart';
import '../utils/logger.dart';

/// Serviço de rastreamento GPS específico para modo caminhada
/// Implementa o fluxo completo conforme especificado
class GpsWalkTrackingService {
  // Configurações de precisão otimizadas para agricultura
  static const double _maxAccuracy = 10.0; // metros (precisão < 10m)
  static const double _minDistanceBetweenPoints = 1.0; // metros (distância mínima entre pontos)
  static const double _maxJumpDistance = 100.0; // metros (salto máximo permitido)
  static const int _maxJumpTime = 5; // segundos (tempo máximo para salto)
  
  // Estado do rastreamento
  bool _isTracking = false;
  bool _isPaused = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _metricsTimer;
  
  // Pontos e métricas
  final List<LatLng> _trackPoints = [];
  LatLng? _lastValidPoint;
  DateTime? _lastValidTime;
  double _totalDistance = 0.0;
  double _currentAccuracy = 0.0;
  double _currentSpeed = 0.0;
  DateTime? _trackingStartTime;
  
  // Callbacks
  Function(List<LatLng>)? _onPointsChanged;
  Function(double)? _onAreaChanged;
  Function(double)? _onPerimeterChanged;
  Function(double)? _onDistanceChanged;
  Function(double)? _onSpeedChanged;
  Function(double)? _onAccuracyChanged;
  Function(String)? _onStatusChanged;
  Function(bool)? _onTrackingStateChanged;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      Logger.info('✅ GpsWalkTrackingService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar GpsWalkTrackingService: $e');
      rethrow;
    }
  }
  
  /// Inicia o rastreamento GPS para modo caminhada
  Future<bool> startTracking({
    required Function(List<LatLng>) onPointsChanged,
    required Function(double) onAreaChanged,
    required Function(double) onPerimeterChanged,
    required Function(double) onDistanceChanged,
    required Function(double) onSpeedChanged,
    required Function(double) onAccuracyChanged,
    required Function(String) onStatusChanged,
    required Function(bool) onTrackingStateChanged,
  }) async {
    try {
      Logger.info('🚀 Iniciando rastreamento GPS para modo caminhada...');
      GpsWalkDebugHelper.logGpsStart();
      
      // Verificar se o GPS está habilitado
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        throw Exception('Serviço de localização desabilitado. Habilite o GPS nas configurações.');
      }
      
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }
      
      // Configurar callbacks
      _onPointsChanged = onPointsChanged;
      _onAreaChanged = onAreaChanged;
      _onPerimeterChanged = onPerimeterChanged;
      _onDistanceChanged = onDistanceChanged;
      _onSpeedChanged = onSpeedChanged;
      _onAccuracyChanged = onAccuracyChanged;
      _onStatusChanged = onStatusChanged;
      _onTrackingStateChanged = onTrackingStateChanged;
      
      // Limpar estado anterior
      _resetTracking();
      
      // Configurar localização otimizada para agricultura
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // Alta precisão para agricultura
        distanceFilter: 0, // Sem filtro de distância
        timeLimit: Duration(seconds: 15), // Timeout adequado
      );
      
      Logger.info('⚙️ Configurações: accuracy=high, distanceFilter=0m, timeLimit=15s');
      
      // Iniciar stream de localização
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate, 
        onError: _onPositionError,
        cancelOnError: false,
      );
      
      _isTracking = true;
      _trackingStartTime = DateTime.now();
      _onTrackingStateChanged?.call(true);
      _onStatusChanged?.call('Rastreamento GPS iniciado - Comece a caminhar pelo perímetro');
      GpsWalkDebugHelper.logSuccess('Rastreamento GPS iniciado com sucesso');
      
      // Configurar timer para atualizações de métricas
      _metricsTimer = Timer.periodic(const Duration(seconds: 1), _updateMetrics);
      
      Logger.info('✅ Rastreamento GPS iniciado com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao iniciar rastreamento: $e');
      GpsWalkDebugHelper.logError('Erro ao iniciar rastreamento: $e');
      _onStatusChanged?.call('Erro ao iniciar rastreamento: $e');
      return false;
    }
  }
  
  /// Pausa o rastreamento
  void pauseTracking() {
    if (!_isTracking) return;
    
    _isPaused = true;
    _onStatusChanged?.call('Rastreamento pausado');
    _onTrackingStateChanged?.call(false);
    GpsWalkDebugHelper.logControl('GPS pausado');
    
    Logger.info('⏸️ Rastreamento GPS pausado');
  }
  
  /// Retoma o rastreamento
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    
    _isPaused = false;
    _onStatusChanged?.call('Rastreamento retomado');
    _onTrackingStateChanged?.call(true);
    GpsWalkDebugHelper.logControl('GPS retomado');
    
    Logger.info('▶️ Rastreamento GPS retomado');
  }
  
  /// Para o rastreamento
  Future<void> stopTracking() async {
    try {
      _isTracking = false;
      _isPaused = false;
      
      // Cancelar subscriptions
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      // Cancelar timer
      _metricsTimer?.cancel();
      _metricsTimer = null;
      
      // Fechar polígono se tiver pontos suficientes
      if (_trackPoints.length >= 3) {
        final closedPoints = GpsWalkCalculator.closePolygon(_trackPoints);
        _trackPoints.clear();
        _trackPoints.addAll(closedPoints);
        _updateMetrics(null);
      }
      
      _onTrackingStateChanged?.call(false);
      _onStatusChanged?.call('Rastreamento finalizado');
      GpsWalkDebugHelper.logControl('GPS finalizado');
      
      Logger.info('⏹️ Rastreamento GPS finalizado');
      
    } catch (e) {
      Logger.error('❌ Erro ao parar rastreamento: $e');
    }
  }
  
  /// Processa atualização de posição
  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) return;
    
    Logger.info('📍 Nova posição: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
    
    try {
      final newPoint = LatLng(position.latitude, position.longitude);
      final isValid = _isValidPoint(newPoint, position.accuracy);
      GpsWalkDebugHelper.logGpsPoint(newPoint, position.accuracy, isValid);
      
      // Verificar se o ponto é válido
      if (!isValid) {
        Logger.info('❌ Ponto rejeitado: accuracy=${position.accuracy}m');
        return;
      }
      
      // Adicionar ponto se não for muito próximo do último
      if (_trackPoints.isEmpty || 
          GpsWalkCalculator.haversineDistance(_trackPoints.last, newPoint) >= _minDistanceBetweenPoints) {
        _addPoint(newPoint, position.accuracy);
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar posição: $e');
      GpsWalkDebugHelper.logError('Erro ao processar posição GPS: $e');
    }
  }
  
  /// Verifica se um ponto é válido
  bool _isValidPoint(LatLng point, double accuracy) {
    // Verificar accuracy
    if (accuracy > _maxAccuracy) {
      return false;
    }
    
    // Verificar salto irreal
    if (_lastValidPoint != null && _lastValidTime != null) {
      final distance = GpsWalkCalculator.haversineDistance(_lastValidPoint!, point);
      final timeDiff = DateTime.now().difference(_lastValidTime!).inSeconds;
      
      if (distance > _maxJumpDistance && timeDiff < _maxJumpTime) {
        Logger.info('❌ Salto irreal detectado: ${distance.toStringAsFixed(1)}m em ${timeDiff}s');
        GpsWalkDebugHelper.logError('Salto irreal: ${distance.toStringAsFixed(1)}m em ${timeDiff}s');
        return false;
      }
    }
    
    return true;
  }
  
  /// Adiciona um ponto válido
  void _addPoint(LatLng point, double accuracy) {
    _trackPoints.add(point);
    _lastValidPoint = point;
    _lastValidTime = DateTime.now();
    
    // Calcular distância total
    if (_trackPoints.length > 1) {
      final distance = GpsWalkCalculator.haversineDistance(
        _trackPoints[_trackPoints.length - 2], 
        _trackPoints.last
      );
      _totalDistance += distance;
    }
    
    // Notificar mudanças
    _onPointsChanged?.call(List.from(_trackPoints));
    _onDistanceChanged?.call(_totalDistance);
    _onAccuracyChanged?.call(accuracy);
    
    Logger.info('✅ Ponto adicionado: ${_trackPoints.length} pontos, distância: ${_totalDistance.toStringAsFixed(1)}m');
    
    // Log de métricas se temos pontos suficientes
    if (_trackPoints.length >= 3) {
      final area = GpsWalkCalculator.calculatePolygonAreaHectares(_trackPoints);
      final perimeter = GpsWalkCalculator.calculatePolygonPerimeter(_trackPoints);
      GpsWalkDebugHelper.logMetricsCalculation(_trackPoints, area, perimeter);
    }
  }
  
  /// Atualiza métricas em tempo real
  void _updateMetrics(Timer? timer) {
    if (_trackPoints.length < 3) {
      _onAreaChanged?.call(0.0);
      _onPerimeterChanged?.call(0.0);
      return;
    }
    
    try {
      // Calcular área usando Shoelace + UTM
      final area = GpsWalkCalculator.calculatePolygonAreaHectares(_trackPoints);
      
      // Calcular perímetro usando Haversine
      final perimeter = GpsWalkCalculator.calculatePolygonPerimeter(_trackPoints);
      
      // Calcular velocidade
      if (_trackingStartTime != null) {
        final elapsedTime = DateTime.now().difference(_trackingStartTime!);
        if (elapsedTime.inSeconds > 0) {
          final speedMs = _totalDistance / elapsedTime.inSeconds;
          _currentSpeed = speedMs * 3.6; // m/s para km/h
        }
      }
      
      // Notificar mudanças
      _onAreaChanged?.call(area);
      _onPerimeterChanged?.call(perimeter);
      _onSpeedChanged?.call(_currentSpeed);
      
    } catch (e) {
      Logger.error('❌ Erro ao atualizar métricas: $e');
    }
  }
  
  /// Trata erro de posição
  void _onPositionError(dynamic error) {
    Logger.error('❌ Erro no GPS: $error');
    
    String errorMessage = 'Erro no GPS';
    
    if (error is TimeoutException) {
      errorMessage = 'Timeout ao obter posição GPS. Verifique se o GPS está ativo.';
    } else if (error.toString().contains('permission')) {
      errorMessage = 'Permissão de localização negada. Configure nas configurações.';
    } else if (error.toString().contains('service')) {
      errorMessage = 'Serviço de localização indisponível.';
    } else {
      errorMessage = 'Erro no GPS: $error';
    }
    
    _onStatusChanged?.call(errorMessage);
  }
  
  /// Reseta o estado do rastreamento
  void _resetTracking() {
    _trackPoints.clear();
    _lastValidPoint = null;
    _lastValidTime = null;
    _totalDistance = 0.0;
    _currentAccuracy = 0.0;
    _currentSpeed = 0.0;
    _trackingStartTime = null;
  }
  
  /// Obtém estatísticas do rastreamento
  Map<String, dynamic> getTrackingStats() {
    return {
      'totalPoints': _trackPoints.length,
      'totalDistance': _totalDistance,
      'currentAccuracy': _currentAccuracy,
      'currentSpeed': _currentSpeed,
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'trackingTime': _trackingStartTime != null ? 
        DateTime.now().difference(_trackingStartTime!).inSeconds : 0,
    };
  }
  
  /// Obtém pontos do rastreamento
  List<LatLng> getTrackPoints() {
    return List.from(_trackPoints);
  }
  
  /// Limpa todos os dados de rastreamento
  void clearData() {
    _resetTracking();
    _onPointsChanged?.call([]);
    _onAreaChanged?.call(0.0);
    _onPerimeterChanged?.call(0.0);
    _onDistanceChanged?.call(0.0);
    _onSpeedChanged?.call(0.0);
    _onAccuracyChanged?.call(0.0);
    _onStatusChanged?.call('Dados limpos');
  }
  
  /// Dispose do serviço
  void dispose() {
    stopTracking();
  }
}
