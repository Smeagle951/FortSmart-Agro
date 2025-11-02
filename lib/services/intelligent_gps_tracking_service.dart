import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/geo_calculator.dart';
import '../utils/logger.dart';

/// Serviço de rastreamento GPS inteligente com pausa/retomada avançada
class IntelligentGpsTrackingService {
  static final IntelligentGpsTrackingService _instance = IntelligentGpsTrackingService._internal();
  factory IntelligentGpsTrackingService() => _instance;
  IntelligentGpsTrackingService._internal();
  
  // Streams de localização
  StreamSubscription<Position>? _positionStream;
  Timer? _accuracyTimer;
  Timer? _distanceTimer;
  
  // Estado do rastreamento
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isResuming = false;
  
  // Pontos e métricas
  List<LatLng> _trackedPoints = [];
  List<double> _accuracies = [];
  List<DateTime> _timestamps = [];
  
  // Estado de pausa/retomada
  LatLng? _lastPointBeforePause;
  DateTime? _pauseStartTime;
  DateTime? _resumeStartTime;
  double _pauseDistance = 0.0;
  
  // Configurações
  static const double _minAccuracy = 5.0; // Precisão mínima em metros
  static const double _maxAccuracy = 50.0; // Precisão máxima aceitável
  static const double _minDistance = 1.0; // Distância mínima entre pontos
  static const double _maxDistance = 100.0; // Distância máxima para linha reta
  static const Duration _accuracyCheckInterval = Duration(seconds: 5);
  static const Duration _distanceCheckInterval = Duration(seconds: 2);
  
  // Callbacks
  Function(List<LatLng>)? _onPointsChanged;
  Function(double)? _onDistanceChanged;
  Function(double)? _onAccuracyChanged;
  Function(String)? _onStatusChanged;
  Function(bool)? _onTrackingStateChanged;
  Function(double)? _onAreaChanged;
  Function(double)? _onPerimeterChanged;
  Function(Duration)? _onTimeChanged;
  
  // Getters
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get isResuming => _isResuming;
  List<LatLng> get trackedPoints => List.unmodifiable(_trackedPoints);
  double get totalDistance => _calculateTotalDistance();
  double get currentAccuracy => _accuracies.isNotEmpty ? _accuracies.last : 0.0;
  double get averageAccuracy => _accuracies.isNotEmpty 
      ? _accuracies.reduce((a, b) => a + b) / _accuracies.length 
      : 0.0;
  Duration get elapsedTime => _calculateElapsedTime();
  double get currentArea => _trackedPoints.length >= 3 
      ? GeoCalculator.calculateAreaHectares(_trackedPoints) 
      : 0.0;
  double get currentPerimeter => _trackedPoints.length >= 3 
      ? GeoCalculator.calculatePerimeterMeters(_trackedPoints) 
      : 0.0;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      Logger.info('🔄 [GPS] Inicializando serviço de rastreamento inteligente...');
      
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }
      
      // Verificar se o GPS está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }
      
      Logger.info('✅ [GPS] Serviço inicializado com sucesso');
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro na inicialização: $e');
      rethrow;
    }
  }
  
  /// Inicia o rastreamento
  Future<bool> startTracking({
    Function(List<LatLng>)? onPointsChanged,
    Function(double)? onDistanceChanged,
    Function(double)? onAccuracyChanged,
    Function(String)? onStatusChanged,
    Function(bool)? onTrackingStateChanged,
    Function(double)? onAreaChanged,
    Function(double)? onPerimeterChanged,
    Function(Duration)? onTimeChanged,
  }) async {
    try {
      if (_isTracking) {
        Logger.warning('⚠️ [GPS] Rastreamento já está ativo');
        return false;
      }
      
      // Configurar callbacks
      _onPointsChanged = onPointsChanged;
      _onDistanceChanged = onDistanceChanged;
      _onAccuracyChanged = onAccuracyChanged;
      _onStatusChanged = onStatusChanged;
      _onTrackingStateChanged = onTrackingStateChanged;
      _onAreaChanged = onAreaChanged;
      _onPerimeterChanged = onPerimeterChanged;
      _onTimeChanged = onTimeChanged;
      
      // Limpar dados anteriores
      _clearData();
      
      // Configurar stream de localização
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // 1 metro
      );
      
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: _onPositionError,
      );
      
      // Iniciar timers
      _startTimers();
      
      _isTracking = true;
      _isPaused = false;
      _isResuming = false;
      
      _onStatusChanged?.call('Rastreamento iniciado');
      _onTrackingStateChanged?.call(true);
      
      Logger.info('✅ [GPS] Rastreamento iniciado');
      return true;
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao iniciar rastreamento: $e');
      _onStatusChanged?.call('Erro ao iniciar rastreamento: $e');
      return false;
    }
  }
  
  /// Pausa o rastreamento
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    
    try {
      _isPaused = true;
      _pauseStartTime = DateTime.now();
      
      // Salvar último ponto antes da pausa
      if (_trackedPoints.isNotEmpty) {
        _lastPointBeforePause = _trackedPoints.last;
      }
      
      // Pausar stream de localização
      _positionStream?.pause();
      
      _onStatusChanged?.call('Rastreamento pausado');
      Logger.info('⏸️ [GPS] Rastreamento pausado');
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao pausar rastreamento: $e');
    }
  }
  
  /// Retoma o rastreamento
  Future<void> resumeTracking() async {
    if (!_isTracking || !_isPaused) return;
    
    try {
      _isResuming = true;
      _resumeStartTime = DateTime.now();
      
      // Retomar stream de localização
      _positionStream?.resume();
      
      _onStatusChanged?.call('Rastreamento retomado');
      Logger.info('▶️ [GPS] Rastreamento retomado');
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao retomar rastreamento: $e');
    } finally {
      _isResuming = false;
    }
  }
  
  /// Para o rastreamento
  Future<void> stopTracking() async {
    try {
      if (!_isTracking) return;
      
      // Parar stream de localização
      await _positionStream?.cancel();
      _positionStream = null;
      
      // Parar timers
      _stopTimers();
      
      _isTracking = false;
      _isPaused = false;
      _isResuming = false;
      
      _onStatusChanged?.call('Rastreamento finalizado');
      _onTrackingStateChanged?.call(false);
      
      Logger.info('⏹️ [GPS] Rastreamento finalizado');
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao parar rastreamento: $e');
    }
  }
  
  /// Processa atualização de posição
  void _onPositionUpdate(Position position) {
    try {
      final newPoint = LatLng(position.latitude, position.longitude);
      final accuracy = position.accuracy;
      final timestamp = DateTime.now();
      
      // Verificar precisão
      if (accuracy > _maxAccuracy) {
        Logger.warning('⚠️ [GPS] Precisão baixa: ${accuracy.toStringAsFixed(1)}m');
        return;
      }
      
      // Verificar se é retomada após pausa
      if (_isResuming && _lastPointBeforePause != null) {
        _handleResumeAfterPause(newPoint, accuracy, timestamp);
        return;
      }
      
      // Verificar distância mínima
      if (_trackedPoints.isNotEmpty) {
        final lastPoint = _trackedPoints.last;
        final distance = GeoCalculator.haversineDistance(lastPoint, newPoint);
        
        if (distance < _minDistance) {
          return; // Ignorar ponto muito próximo
        }
      }
      
      // Adicionar ponto
      _addPoint(newPoint, accuracy, timestamp);
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao processar posição: $e');
    }
  }
  
  /// Trata retomada após pausa
  void _handleResumeAfterPause(LatLng newPoint, double accuracy, DateTime timestamp) {
    try {
      final distance = GeoCalculator.haversineDistance(_lastPointBeforePause!, newPoint);
      
      if (distance > _maxDistance) {
        // Distância muito grande - criar linha reta
        _createStraightLine(_lastPointBeforePause!, newPoint);
        _onStatusChanged?.call('Linha reta criada (${distance.toStringAsFixed(1)}m)');
      }
      
      // Adicionar ponto normal
      _addPoint(newPoint, accuracy, timestamp);
      
      // Resetar estado de retomada
      _lastPointBeforePause = null;
      _pauseStartTime = null;
      _resumeStartTime = null;
      _pauseDistance = 0.0;
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao tratar retomada: $e');
    }
  }
  
  /// Cria linha reta entre dois pontos
  void _createStraightLine(LatLng startPoint, LatLng endPoint) {
    try {
      final distance = GeoCalculator.haversineDistance(startPoint, endPoint);
      final numPoints = math.max(2, (distance / 10).ceil()); // Um ponto a cada 10 metros
      
      for (int i = 1; i < numPoints; i++) {
        final ratio = i / numPoints;
        final lat = startPoint.latitude + (endPoint.latitude - startPoint.latitude) * ratio;
        final lng = startPoint.longitude + (endPoint.longitude - startPoint.longitude) * ratio;
        
        final interpolatedPoint = LatLng(lat, lng);
        _addPoint(interpolatedPoint, _minAccuracy, DateTime.now());
      }
      
    } catch (e) {
      Logger.error('❌ [GPS] Erro ao criar linha reta: $e');
    }
  }
  
  /// Adiciona ponto ao rastreamento
  void _addPoint(LatLng point, double accuracy, DateTime timestamp) {
    _trackedPoints.add(point);
    _accuracies.add(accuracy);
    _timestamps.add(timestamp);
    
    // Notificar mudanças
    _onPointsChanged?.call(_trackedPoints);
    _onDistanceChanged?.call(_calculateTotalDistance());
    _onAccuracyChanged?.call(accuracy);
    _onAreaChanged?.call(currentArea);
    _onPerimeterChanged?.call(currentPerimeter);
    _onTimeChanged?.call(elapsedTime);
  }
  
  /// Calcula distância total
  double _calculateTotalDistance() {
    if (_trackedPoints.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < _trackedPoints.length; i++) {
      totalDistance += GeoCalculator.haversineDistance(
        _trackedPoints[i - 1],
        _trackedPoints[i],
      );
    }
    
    return totalDistance;
  }
  
  /// Calcula tempo decorrido
  Duration _calculateElapsedTime() {
    if (_timestamps.isEmpty) return Duration.zero;
    
    final startTime = _timestamps.first;
    final endTime = _timestamps.last;
    
    return endTime.difference(startTime);
  }
  
  /// Inicia timers
  void _startTimers() {
    // Timer para verificar precisão
    _accuracyTimer = Timer.periodic(_accuracyCheckInterval, (timer) {
      if (_isTracking && !_isPaused) {
        _onAccuracyChanged?.call(currentAccuracy);
      }
    });
    
    // Timer para verificar distância
    _distanceTimer = Timer.periodic(_distanceCheckInterval, (timer) {
      if (_isTracking && !_isPaused) {
        _onDistanceChanged?.call(_calculateTotalDistance());
      }
    });
  }
  
  /// Para timers
  void _stopTimers() {
    _accuracyTimer?.cancel();
    _distanceTimer?.cancel();
    _accuracyTimer = null;
    _distanceTimer = null;
  }
  
  /// Trata erro de posição
  void _onPositionError(dynamic error) {
    Logger.error('❌ [GPS] Erro de posição: $error');
    _onStatusChanged?.call('Erro de GPS: $error');
  }
  
  /// Limpa dados
  void _clearData() {
    _trackedPoints.clear();
    _accuracies.clear();
    _timestamps.clear();
    _lastPointBeforePause = null;
    _pauseStartTime = null;
    _resumeStartTime = null;
    _pauseDistance = 0.0;
  }
  
  /// Obtém estatísticas do rastreamento
  Map<String, dynamic> getTrackingStats() {
    return {
      'is_tracking': _isTracking,
      'is_paused': _isPaused,
      'total_points': _trackedPoints.length,
      'total_distance': _calculateTotalDistance(),
      'current_accuracy': currentAccuracy,
      'average_accuracy': averageAccuracy,
      'elapsed_time': elapsedTime,
      'current_area': currentArea,
      'current_perimeter': currentPerimeter,
      'pause_count': _pauseStartTime != null ? 1 : 0,
    };
  }
  
  /// Suaviza pontos GPS
  List<LatLng> getSmoothedPoints({int windowSize = 3}) {
    return GeoCalculator.smoothPoints(_trackedPoints, windowSize: windowSize);
  }
  
  /// Filtra pontos por precisão
  List<LatLng> getFilteredPoints({double maxAccuracy = 10.0}) {
    return GeoCalculator.filterByAccuracy(_trackedPoints, _accuracies, maxAccuracy: maxAccuracy);
  }
  
  /// Para o serviço
  void dispose() {
    stopTracking();
  }
}
