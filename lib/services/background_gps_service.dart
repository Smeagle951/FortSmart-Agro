import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Serviço de GPS em background para coleta contínua de coordenadas
/// Usa flutter_foreground_task para manter o serviço ativo
class BackgroundGpsService {
  static const String _taskName = 'background_gps_task';
  static const String _notificationTitle = 'FortSmart Agro';
  static const String _notificationText = 'Coletando GPS para talhão...';
  
  static bool _isRunning = false;
  static StreamController<List<LatLng>>? _trackPointsController;
  static StreamController<Position>? _positionController;
  
  /// Stream de pontos rastreados
  static Stream<List<LatLng>> get trackPointsStream => 
      _trackPointsController?.stream ?? const Stream.empty();
  
  /// Stream de posições atuais
  static Stream<Position> get positionStream => 
      _positionController?.stream ?? const Stream.empty();
  
  /// Verifica se o serviço está rodando
  static bool get isRunning => _isRunning;
  
  /// Inicia o serviço de GPS em background
  static Future<bool> startService({
    required String talhaoId,
    required String talhaoNome,
    int minDistanceMeters = 2,
    int updateIntervalMs = 1000,
    bool enableSmoothing = true,
  }) async {
    if (_isRunning) {
      return true;
    }
    
    try {
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission != LocationPermission.always) {
          throw Exception('Permissão de localização negada');
        }
      }
      
      // Verificar se o serviço de localização está ativo
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }
      
      // Inicializar controladores
      _trackPointsController = StreamController<List<LatLng>>.broadcast();
      _positionController = StreamController<Position>.broadcast();
      
      // Ativar wakelock para manter CPU ativa
      await WakelockPlus.enable();
      
      // Iniciar foreground task
      await FlutterForegroundTask.startService(
        notificationTitle: _notificationTitle,
        notificationText: 'Coletando GPS para: $talhaoNome',
        callback: _gpsTaskCallback,
      );
      
      _isRunning = true;
        return true;
      
    } catch (e) {
      debugPrint('Erro ao iniciar serviço de GPS: $e');
      await stopService();
      return false;
    }
  }
  
  /// Para o serviço de GPS
  static Future<void> stopService() async {
    if (!_isRunning) return;
    
    try {
      await FlutterForegroundTask.stopService();
      await WakelockPlus.disable();
      
      _trackPointsController?.close();
      _positionController?.close();
      _trackPointsController = null;
      _positionController = null;
      
      _isRunning = false;
    } catch (e) {
      debugPrint('Erro ao parar serviço de GPS: $e');
    }
  }
  
  /// Callback executado no isolate do foreground task
  static void _gpsTaskCallback() {
    FlutterForegroundTask.setTaskHandler(BackgroundGpsTaskHandler());
  }
}

/// Handler para o foreground task de GPS
class BackgroundGpsTaskHandler extends TaskHandler {
  static final List<LatLng> _trackPoints = [];
  static final List<LatLng> _smoothedPoints = [];
  static Position? _lastPosition;
  static DateTime? _lastUpdate;
  
  // Configurações
  static const int _minDistanceMeters = 2;
  static const int _smoothingWindowSize = 5;
  static const double _minSpeedMs = 0.5; // m/s
  
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Background GPS Task iniciado');
    
    // Configurar stream de posições
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _minDistanceMeters,
    );
    
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          _onPositionUpdate,
          onError: (error) => debugPrint('Erro GPS: $error'),
        );
  }
  
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Verificar se há posição atual
    if (_lastPosition != null) {
      // Enviar dados para o app principal
      // Comentado temporariamente devido a problemas de compatibilidade
      // sendPort?.send({
      //   'type': 'position_update',
      //   'position': {
      //     'latitude': _lastPosition!.latitude,
      //     'longitude': _lastPosition!.longitude,
      //     'accuracy': _lastPosition!.accuracy,
      //     'speed': _lastPosition!.speed,
      //     'timestamp': _lastPosition!.timestamp?.millisecondsSinceEpoch,
      //   },
      //   'track_points': _trackPoints.map((p) => {
      //     'latitude': p.latitude,
      //     'longitude': p.longitude,
      //   }).toList(),
      // });
    }
  }
  
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('Background GPS Task finalizado');
  }
  
  /// Processa nova posição GPS
  void _onPositionUpdate(Position position) {
    _lastPosition = position;
    _lastUpdate = DateTime.now();
    
    // Verificar se está se movendo
    if (position.speed < _minSpeedMs && _trackPoints.isNotEmpty) {
      return; // Ignorar pontos quando parado
    }
    
    final newPoint = LatLng(position.latitude, position.longitude);
    
    // Verificar distância mínima
    if (_trackPoints.isNotEmpty) {
      final lastPoint = _trackPoints.last;
      final distance = _calculateDistance(lastPoint, newPoint);
      
      if (distance < _minDistanceMeters) {
        return; // Muito próximo do último ponto
      }
    }
    
    // Adicionar ponto
    _trackPoints.add(newPoint);
    
    // Aplicar suavização se habilitada
    if (_smoothedPoints.length >= _smoothingWindowSize) {
      _smoothedPoints.removeAt(0);
    }
    _smoothedPoints.add(newPoint);
    
    // Calcular ponto suavizado (média móvel)
    if (_smoothedPoints.length >= 3) {
      final smoothedPoint = _calculateSmoothedPoint(_smoothedPoints);
      debugPrint('Ponto suavizado: ${smoothedPoint.latitude}, ${smoothedPoint.longitude}');
    }
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
  
  /// Calcula ponto suavizado usando média móvel
  LatLng _calculateSmoothedPoint(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    if (points.length == 1) return points.first;
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(
      latSum / points.length,
      lngSum / points.length,
    );
  }
}

/// Serviço de suavização GPS usando filtro de Kalman
class GpsSmoothingService {
  static final List<LatLng> _positionHistory = [];
  static const int _maxHistorySize = 10;
  
  /// Aplica suavização de Kalman a um ponto GPS
  static LatLng smoothPosition(LatLng newPoint, {double processNoise = 0.1, double measurementNoise = 1.0}) {
    if (_positionHistory.isEmpty) {
      _positionHistory.add(newPoint);
      return newPoint;
    }
    
    final lastPoint = _positionHistory.last;
    
    // Filtro de Kalman simples para latitude
    final latKalman = _applyKalmanFilter(
      lastPoint.latitude,
      newPoint.latitude,
      processNoise,
      measurementNoise,
    );
    
    // Filtro de Kalman simples para longitude
    final lngKalman = _applyKalmanFilter(
      lastPoint.longitude,
      newPoint.longitude,
      processNoise,
      measurementNoise,
    );
    
    final smoothedPoint = LatLng(latKalman, lngKalman);
    
    // Manter histórico limitado
    _positionHistory.add(smoothedPoint);
    if (_positionHistory.length > _maxHistorySize) {
      _positionHistory.removeAt(0);
    }
    
    return smoothedPoint;
  }
  
  /// Aplica filtro de Kalman simples
  static double _applyKalmanFilter(double lastValue, double newValue, double processNoise, double measurementNoise) {
    // Implementação simplificada do filtro de Kalman
    final prediction = lastValue;
    final predictionError = processNoise;
    final kalmanGain = predictionError / (predictionError + measurementNoise);
    
    return prediction + kalmanGain * (newValue - prediction);
  }
  
  /// Limpa o histórico de posições
  static void clearHistory() {
    _positionHistory.clear();
  }
}