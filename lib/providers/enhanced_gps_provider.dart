import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/background_gps_service.dart';

/// Provider aprimorado para GPS com suporte a background e suavização
class EnhancedGpsProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isLocationServiceEnabled = false;
  LocationPermission? _permission;
  Position? _currentPosition;
  final List<LatLng> _trackPoints = [];
  final List<LatLng> _smoothedTrackPoints = [];
  
  // Configurações avançadas
  int _minDistanciaMetros = 2;
  int _intervalAtualizacaoMs = 1000;
  bool _enableSmoothing = true;
  bool _enableBackgroundTracking = true;
  String? _currentTalhaoId;
  String? _currentTalhaoNome;
  
  // Streams e subscriptions
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<LatLng>>? _trackPointsStream;
  StreamSubscription<Position>? _backgroundPositionStream;
  
  // Getters
  bool get isTracking => _isTracking;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  LocationPermission? get permission => _permission;
  Position? get currentPosition => _currentPosition;
  List<LatLng> get trackPoints => List.unmodifiable(_trackPoints);
  List<LatLng> get smoothedTrackPoints => List.unmodifiable(_smoothedTrackPoints);
  bool get enableSmoothing => _enableSmoothing;
  bool get enableBackgroundTracking => _enableBackgroundTracking;
  String? get currentTalhaoId => _currentTalhaoId;
  String? get currentTalhaoNome => _currentTalhaoNome;
  
  /// Localização atual em formato LatLng
  LatLng? get currentLocation => _currentPosition != null 
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;
  
  /// Inicializa o provider
  Future<void> initialize() async {
    await _checkLocationService();
    await _checkPermission();
    notifyListeners();
  }
  
  /// Verifica se o serviço de localização está habilitado
  Future<void> _checkLocationService() async {
    try {
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Erro ao verificar serviço de localização: $e');
      _isLocationServiceEnabled = false;
    }
  }
  
  /// Verifica e solicita permissões de localização
  Future<void> _checkPermission() async {
    try {
      _permission = await Geolocator.checkPermission();
      
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
      }
      
      if (_permission == LocationPermission.deniedForever) {
        // Permissão negada permanentemente
        debugPrint('Permissão de localização negada permanentemente');
      }
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
    }
  }
  
  /// Inicia o rastreamento GPS
  Future<bool> startTracking({
    required String talhaoId,
    required String talhaoNome,
    int minDistanceMeters = 2,
    int updateIntervalMs = 1000,
    bool enableSmoothing = true,
    bool enableBackground = true,
  }) async {
    if (_isTracking) {
      return true;
    }
    
    try {
      // Verificar permissões
      if (_permission != LocationPermission.always && 
          _permission != LocationPermission.whileInUse) {
        await _checkPermission();
        if (_permission != LocationPermission.always && 
            _permission != LocationPermission.whileInUse) {
          throw Exception('Permissão de localização necessária');
        }
      }
      
      // Verificar serviço de localização
      if (!_isLocationServiceEnabled) {
        await _checkLocationService();
        if (!_isLocationServiceEnabled) {
          throw Exception('Serviço de localização desabilitado');
        }
      }
      
      // Configurar parâmetros
      _currentTalhaoId = talhaoId;
      _currentTalhaoNome = talhaoNome;
      _minDistanciaMetros = minDistanceMeters;
      _intervalAtualizacaoMs = updateIntervalMs;
      _enableSmoothing = enableSmoothing;
      _enableBackgroundTracking = enableBackground;
      
      // Limpar pontos anteriores
      _trackPoints.clear();
      _smoothedTrackPoints.clear();
      
      if (enableBackground) {
        // Usar serviço de background
        final success = await BackgroundGpsService.startService(
          talhaoId: talhaoId,
          talhaoNome: talhaoNome,
          minDistanceMeters: minDistanceMeters,
          updateIntervalMs: updateIntervalMs,
          enableSmoothing: enableSmoothing,
        );
        
        if (success) {
          _setupBackgroundStreams();
        } else {
          throw Exception('Falha ao iniciar serviço de background');
        }
      } else {
        // Usar rastreamento em foreground
        await _startForegroundTracking();
      }
      
      _isTracking = true;
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Erro ao iniciar rastreamento: $e');
      await stopTracking();
      return false;
    }
  }
  
  /// Para o rastreamento GPS
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    try {
      if (_enableBackgroundTracking) {
        await BackgroundGpsService.stopService();
      } else {
        await _positionStream?.cancel();
      }
      
      // Cancelar streams
      await _trackPointsStream?.cancel();
      await _backgroundPositionStream?.cancel();
      
      _isTracking = false;
      _currentTalhaoId = null;
      _currentTalhaoNome = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao parar rastreamento: $e');
    }
  }
  
  /// Configura streams do serviço de background
  void _setupBackgroundStreams() {
    _backgroundPositionStream = BackgroundGpsService.positionStream.listen(
      (position) {
        _currentPosition = position;
        notifyListeners();
      },
      onError: (error) => debugPrint('Erro no stream de posição: $error'),
    );
    
    _trackPointsStream = BackgroundGpsService.trackPointsStream.listen(
      (points) {
        _trackPoints.clear();
        _trackPoints.addAll(points);
        
        if (_enableSmoothing) {
          _applySmoothingToPoints(points);
        }
        
        notifyListeners();
      },
      onError: (error) => debugPrint('Erro no stream de pontos: $error'),
    );
  }
  
  /// Inicia rastreamento em foreground
  Future<void> _startForegroundTracking() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _minDistanciaMetros,
    );
    
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          _onPositionUpdate,
          onError: (error) => debugPrint('Erro GPS: $error'),
        );
  }
  
  /// Processa nova posição GPS
  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    
    // Verificar se está se movendo
    if (position.speed < 0.5 && _trackPoints.isNotEmpty) {
      return; // Ignorar quando parado
    }
    
    final newPoint = LatLng(position.latitude, position.longitude);
    
    // Verificar distância mínima
    if (_trackPoints.isNotEmpty) {
      final lastPoint = _trackPoints.last;
      final distance = _calculateDistance(lastPoint, newPoint);
      
      if (distance < _minDistanciaMetros) {
        return;
      }
    }
    
    // Adicionar ponto
    _trackPoints.add(newPoint);
    
    // Aplicar suavização se habilitada
    if (_enableSmoothing) {
      _applySmoothingToNewPoint(newPoint);
    }
    
    notifyListeners();
  }
  
  /// Aplica suavização aos pontos
  void _applySmoothingToPoints(List<LatLng> points) {
    _smoothedTrackPoints.clear();
    
    if (points.length < 3) {
      _smoothedTrackPoints.addAll(points);
      return;
    }
    
    // Aplicar média móvel
    for (int i = 0; i < points.length; i++) {
      if (i < 2) {
        _smoothedTrackPoints.add(points[i]);
      } else {
        final smoothedPoint = _calculateMovingAverage(points, i, 3);
        _smoothedTrackPoints.add(smoothedPoint);
      }
    }
  }
  
  /// Aplica suavização a um novo ponto
  void _applySmoothingToNewPoint(LatLng newPoint) {
    if (_trackPoints.length < 3) {
      _smoothedTrackPoints.add(newPoint);
      return;
    }
    
    // Usar últimos 3 pontos para média móvel
    final recentPoints = _trackPoints.length >= 3 
        ? _trackPoints.sublist(_trackPoints.length - 3)
        : _trackPoints;
    final smoothedPoint = _calculateMovingAverage(recentPoints, 2, 3);
    _smoothedTrackPoints.add(smoothedPoint);
  }
  
  /// Calcula média móvel
  LatLng _calculateMovingAverage(List<LatLng> points, int index, int windowSize) {
    final startIndex = (index - windowSize + 1).clamp(0, points.length);
    final endIndex = (index + 1).clamp(0, points.length);
    final windowPoints = points.sublist(startIndex, endIndex);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final point in windowPoints) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(
      latSum / windowPoints.length,
      lngSum / windowPoints.length,
    );
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
  
  /// Obtém a posição atual uma única vez
  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!_isLocationServiceEnabled) {
        await _checkLocationService();
        if (!_isLocationServiceEnabled) {
          return null;
        }
      }
      
      if (_permission != LocationPermission.always && 
          _permission != LocationPermission.whileInUse) {
        await _checkPermission();
        if (_permission != LocationPermission.always && 
            _permission != LocationPermission.whileInUse) {
          return null;
        }
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      notifyListeners();
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return null;
    }
  }
  
  /// Limpa os pontos rastreados
  void clearTrackPoints() {
    _trackPoints.clear();
    _smoothedTrackPoints.clear();
    notifyListeners();
  }
  
  /// Obtém pontos para desenho (suavizados ou originais)
  List<LatLng> getTrackPointsForDrawing() {
    return _enableSmoothing && _smoothedTrackPoints.isNotEmpty
        ? List.from(_smoothedTrackPoints)
        : List.from(_trackPoints);
  }
  
  /// Configurações de rastreamento
  void updateTrackingSettings({
    int? minDistanceMeters,
    int? updateIntervalMs,
    bool? enableSmoothing,
    bool? enableBackground,
  }) {
    if (minDistanceMeters != null) _minDistanciaMetros = minDistanceMeters;
    if (updateIntervalMs != null) _intervalAtualizacaoMs = updateIntervalMs;
    if (enableSmoothing != null) _enableSmoothing = enableSmoothing;
    if (enableBackground != null) _enableBackgroundTracking = enableBackground;
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
