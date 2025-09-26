import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Estados do GPS Tracking
enum GpsTrackingState {
  idle,      // Parado
  recording, // Gravando
  paused,    // Pausado
  finalized  // Finalizado
}

/// Serviço para rastreamento GPS com persistência
class GpsTrackingService extends ChangeNotifier {
  // Configurações
  static const double _minDistance = 5.0; // Distância mínima em metros
  static const double _desiredAccuracy = 5.0; // Precisão desejada em metros
  static const Duration _timeLimit = Duration(seconds: 30); // Timeout para obter posição
  
  // Estado
  GpsTrackingState _state = GpsTrackingState.idle;
  List<LatLng> _trackedPoints = [];
  LatLng? _currentPosition;
  double _totalDistance = 0.0;
  Duration _totalDuration = Duration.zero;
  DateTime? _startTime;
  DateTime? _pauseTime;
  
  // Streams e timers
  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTimer;
  
  // Filtros para melhorar precisão
  final List<LatLng> _recentPositions = [];
  static const int _filterWindowSize = 5;
  
  // Getters
  GpsTrackingState get state => _state;
  List<LatLng> get trackedPoints => List.unmodifiable(_trackedPoints);
  LatLng? get currentPosition => _currentPosition;
  double get totalDistance => _totalDistance;
  Duration get totalDuration => _totalDuration;
  bool get isRecording => _state == GpsTrackingState.recording;
  bool get isPaused => _state == GpsTrackingState.paused;
  bool get hasPoints => _trackedPoints.isNotEmpty;
  
  /// Inicia o rastreamento GPS
  Future<bool> startTracking() async {
    try {
      // Verificar permissões
      if (!await _checkPermissions()) {
        return false;
      }
      
      // Obter posição inicial
      final initialPosition = await _getCurrentPosition();
      if (initialPosition == null) {
        return false;
      }
      
      // Inicializar estado
      _state = GpsTrackingState.recording;
      _startTime = DateTime.now();
      _trackedPoints = [initialPosition];
      _currentPosition = initialPosition;
      _totalDistance = 0.0;
      _totalDuration = Duration.zero;
      _recentPositions.clear();
      _recentPositions.add(initialPosition);
      
      // Iniciar stream de posições
      await _startPositionStream();
      
      // Iniciar timer para duração
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_state == GpsTrackingState.recording) {
          _totalDuration = DateTime.now().difference(_startTime!);
          notifyListeners();
        }
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao iniciar rastreamento GPS: $e');
      return false;
    }
  }
  
  /// Pausa o rastreamento
  void pauseTracking() {
    if (_state == GpsTrackingState.recording) {
      _state = GpsTrackingState.paused;
      _pauseTime = DateTime.now();
      _positionSubscription?.cancel();
      _durationTimer?.cancel();
      notifyListeners();
    }
  }
  
  /// Retoma o rastreamento
  Future<bool> resumeTracking() async {
    if (_state == GpsTrackingState.paused) {
      try {
        _state = GpsTrackingState.recording;
        
        // Obter posição atual
        final currentPosition = await _getCurrentPosition();
        if (currentPosition != null) {
          _currentPosition = currentPosition;
          _recentPositions.clear();
          _recentPositions.add(currentPosition);
        }
        
        // Retomar stream de posições
        await _startPositionStream();
        
        // Retomar timer
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_state == GpsTrackingState.recording) {
            _totalDuration = DateTime.now().difference(_startTime!);
            notifyListeners();
          }
        });
        
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Erro ao retomar rastreamento GPS: $e');
        return false;
      }
    }
    return false;
  }
  
  /// Finaliza o rastreamento
  void finalizeTracking() {
    _state = GpsTrackingState.finalized;
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    
    // Fechar o polígono se necessário
    if (_trackedPoints.length >= 3) {
      final firstPoint = _trackedPoints.first;
      final lastPoint = _trackedPoints.last;
      
      // Se o último ponto não está próximo do primeiro, adiciona o primeiro ponto
      if (_calculateDistance(firstPoint, lastPoint) > _minDistance) {
        _trackedPoints.add(firstPoint);
      }
    }
    
    notifyListeners();
  }
  
  /// Reseta o rastreamento
  void resetTracking() {
    _state = GpsTrackingState.idle;
    _trackedPoints.clear();
    _currentPosition = null;
    _totalDistance = 0.0;
    _totalDuration = Duration.zero;
    _startTime = null;
    _pauseTime = null;
    _recentPositions.clear();
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    notifyListeners();
  }
  
  /// Obtém os pontos rastreados
  List<LatLng> getTrackedPoints() {
    return List.unmodifiable(_trackedPoints);
  }
  
  /// Calcula a área do polígono rastreado
  double calculateArea() {
    if (_trackedPoints.length < 3) return 0.0;
    
    // Usar algoritmo de Gauss (Shoelace formula)
    double area = 0.0;
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    for (int i = 0; i < _trackedPoints.length; i++) {
      int j = (i + 1) % _trackedPoints.length;
      
      final p1 = _trackedPoints[i];
      final p2 = _trackedPoints[j];
      
      // Converter para radianos
      final lat1 = p1.latitude * pi / 180;
      final lat2 = p2.latitude * pi / 180;
      final lng1 = p1.longitude * pi / 180;
      final lng2 = p2.longitude * pi / 180;
      
      area += (lng2 - lng1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area.abs() * earthRadius * earthRadius / 2.0;
    
    // Converter para hectares
    return area / 10000;
  }
  
  /// Calcula o perímetro do polígono rastreado
  double calculatePerimeter() {
    if (_trackedPoints.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < _trackedPoints.length; i++) {
      int j = (i + 1) % _trackedPoints.length;
      perimeter += _calculateDistance(_trackedPoints[i], _trackedPoints[j]);
    }
    
    return perimeter;
  }
  
  /// Verifica permissões de localização
  Future<bool> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  /// Obtém posição atual
  Future<LatLng?> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _timeLimit,
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Erro ao obter posição atual: $e');
      return null;
    }
  }
  
  /// Inicia stream de posições
  Future<void> _startPositionStream() async {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (Position position) {
        if (_state == GpsTrackingState.recording) {
          _onNewPosition(position);
        }
      },
      onError: (error) {
        debugPrint('Erro no stream de posições: $error');
      },
    );
  }
  
  /// Processa nova posição
  void _onNewPosition(Position position) {
    final newPoint = LatLng(position.latitude, position.longitude);
    
    // Aplicar filtro de média móvel para melhorar precisão
    final filteredPoint = _applyFilter(newPoint);
    
    // Verificar se a nova posição é válida
    if (_isValidPosition(filteredPoint)) {
      _currentPosition = filteredPoint;
      _trackedPoints.add(filteredPoint);
      _recentPositions.add(filteredPoint);
      
      // Manter apenas as últimas posições para o filtro
      if (_recentPositions.length > _filterWindowSize) {
        _recentPositions.removeAt(0);
      }
      
      // Calcular distância total
      if (_trackedPoints.length > 1) {
        final lastPoint = _trackedPoints[_trackedPoints.length - 2];
        _totalDistance += _calculateDistance(lastPoint, filteredPoint);
      }
      
      notifyListeners();
    }
  }
  
  /// Aplica filtro de média móvel
  LatLng _applyFilter(LatLng newPoint) {
    if (_recentPositions.isEmpty) {
      return newPoint;
    }
    
    // Calcular média das posições recentes
    double avgLat = 0.0;
    double avgLng = 0.0;
    
    for (final point in _recentPositions) {
      avgLat += point.latitude;
      avgLng += point.longitude;
    }
    
    avgLat /= _recentPositions.length;
    avgLng /= _recentPositions.length;
    
    // Aplicar peso maior para a nova posição
    final weight = 0.7;
    final filteredLat = (newPoint.latitude * weight) + (avgLat * (1 - weight));
    final filteredLng = (newPoint.longitude * weight) + (avgLng * (1 - weight));
    
    return LatLng(filteredLat, filteredLng);
  }
  
  /// Verifica se a posição é válida
  bool _isValidPosition(LatLng point) {
    // Verificar se não é nula
    if (point.latitude == 0 && point.longitude == 0) {
      return false;
    }
    
    // Verificar se está dentro de limites razoáveis
    if (point.latitude < -90 || point.latitude > 90 ||
        point.longitude < -180 || point.longitude > 180) {
      return false;
    }
    
    // Verificar se não é muito diferente da última posição válida
    if (_trackedPoints.isNotEmpty) {
      final lastPoint = _trackedPoints.last;
      final distance = _calculateDistance(lastPoint, point);
      
      // Se a distância for muito grande (> 100m), pode ser um erro de GPS
      if (distance > 100) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude, p1.longitude,
      p2.latitude, p2.longitude,
    );
  }
  
  /// Formata duração
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  /// Formata distância
  String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }
  
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
} 