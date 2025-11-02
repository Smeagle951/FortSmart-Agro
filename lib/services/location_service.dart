import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Estados do serviço de localização
enum LocationStatus {
  idle,      // Parado
  recording, // Gravando
  paused,    // Pausado
  finished   // Finalizado
}

class LocationService extends ChangeNotifier {
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Estado da gravação GPS
  LocationStatus _status = LocationStatus.idle;
  List<LatLng> _points = [];
  LatLng? _lastValidPoint;
  DateTime? _lastValidTimestamp;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  double _currentAccuracy = 0.0;
  Timer? _accuracyTimer;
  
  // Callbacks para notificar mudanças
  Function(Position)? onLocationUpdate;
  Function(String)? onError;
  
  // Getters
  LocationStatus get status => _status;
  List<LatLng> get points => List.unmodifiable(_points);
  List<LatLng> get validPoints => _points.where((point) => point.latitude != 0 && point.longitude != 0).toList();
  double get totalDistance => _totalDistance;
  double get currentSpeed => _currentSpeed;
  double get currentAccuracy => _currentAccuracy;
  bool get isRecording => _status == LocationStatus.recording;
  bool get isPaused => _status == LocationStatus.paused;

  /// Inicializa o serviço de localização
  Future<void> initialize() async {
    // Verificar se o GPS está habilitado
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      throw Exception('Serviço de localização desabilitado');
    }

    // Verificar permissões
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }
  }

  Stream<Position> getPositionStream({
    LocationAccuracy desiredAccuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 1,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        distanceFilter: distanceFilter,
        timeLimit: const Duration(seconds: 30),
      ),
    );
  }

  Future<Position?> getCurrentPosition() async {
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }

      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização permanentemente negada');
      }

      // Obter posição atual
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      print('Erro ao solicitar permissão: $e');
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Inicia gravação GPS
  Future<bool> startRecording() async {
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permissão de localização negada');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError('Permissão de localização negada permanentemente');
        return false;
      }
      
      // Verificar se GPS está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('GPS desabilitado. Ative o GPS nas configurações.');
        return false;
      }
      
      // Tentar obter posição inicial para verificar se GPS está funcionando
      try {
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('⚠️ GPS pode estar lento: $e');
        // Não falhar aqui, apenas avisar
      }
      
      // Limpar dados anteriores
      _points.clear();
      _lastValidPoint = null;
      _lastValidTimestamp = null;
      _totalDistance = 0.0;
      _currentSpeed = 0.0;
      
        // Configurar stream de localização com configurações mais robustas para background
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1, // 1 metro
            timeLimit: const Duration(seconds: 60), // Aumentado para 60 segundos
          ),
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          print('Erro no stream GPS: $error');
          if (error.toString().contains('TimeoutException')) {
            _showError('Timeout GPS: Aguardando sinal do GPS. Verifique se está em área aberta.');
          } else {
            _showError('Erro na captura GPS: $error');
          }
        },
      );
      
      _status = LocationStatus.recording;
      notifyListeners();
      
      print('✅ Gravação GPS iniciada');
      return true;
      
    } catch (e) {
      print('❌ Erro ao iniciar gravação GPS: $e');
      _showError('Erro ao iniciar GPS: $e');
      return false;
    }
  }
  
  /// Pausa gravação
  void pauseRecording() {
    if (_status == LocationStatus.recording) {
      _status = LocationStatus.paused;
      _positionStreamSubscription?.cancel();
      _accuracyTimer?.cancel();
      notifyListeners();
      print('⏸️ Gravação pausada');
    }
  }
  
  /// Retoma gravação
  Future<bool> resumeRecording() async {
    if (_status == LocationStatus.paused) {
      try {
        print('▶️ LocationService: Retomando gravação GPS...');
        
        // CORREÇÃO: Não chamar startRecording() novamente para não perder pontos
        // Apenas reativar o stream de localização
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1, // 1 metro
            timeLimit: const Duration(seconds: 60),
          ),
        ).listen(
          _onLocationUpdate,
          onError: (error) {
            print('Erro no stream GPS: $error');
            if (error.toString().contains('TimeoutException')) {
              _showError('Timeout GPS: Aguardando sinal do GPS. Verifique se está em área aberta.');
            } else {
              _showError('Erro na captura GPS: $error');
            }
          },
        );
        
        _status = LocationStatus.recording;
        notifyListeners();
        
        print('✅ LocationService: Gravação retomada com sucesso');
        return true;
      } catch (e) {
        print('❌ LocationService: Erro ao retomar gravação: $e');
        _showError('Erro ao retomar GPS: $e');
        return false;
      }
    }
    return false;
  }
  
  /// Para gravação
  void stopRecording() {
    _status = LocationStatus.finished;
    _positionStreamSubscription?.cancel();
    _accuracyTimer?.cancel();
    notifyListeners();
    print('⏹️ Gravação finalizada');
  }

  // ===== MÉTODOS ALIAS PARA COMPATIBILIDADE =====
  
  /// Alias para startRecording
  Future<bool> startLocationTracking() async => await startRecording();
  
  /// Alias para pauseRecording
  void pauseLocationTracking() => pauseRecording();
  
  /// Alias para resumeRecording
  Future<bool> resumeLocationTracking() async => await resumeRecording();
  
  /// Alias para stopRecording
  void stopLocationTracking() => stopRecording();
  
  /// Processa atualização de localização
  void _onLocationUpdate(Position position) {
    final now = DateTime.now();
    final newPoint = LatLng(position.latitude, position.longitude);
    
    print('📍 LocationService: Nova posição GPS - Lat: ${position.latitude}, Lng: ${position.longitude}, Accuracy: ${position.accuracy}m, Speed: ${position.speed}m/s');
    
    // Atualizar precisão atual
    _currentAccuracy = position.accuracy;
    
    // Chamar callback se definido
    onLocationUpdate?.call(position);
    
    // Verificar se a posição é válida (reduzido para 15m para melhor precisão)
    if (position.accuracy > 15.0) {
      print('⚠️ LocationService: Precisão GPS baixa: ${position.accuracy}m');
      onError?.call('Precisão GPS baixa: ${position.accuracy}m');
      return;
    }
    
    // Verificar se é o primeiro ponto ou se a distância é suficiente
    bool shouldAddPoint = false;
    
    if (_lastValidPoint == null) {
      // Primeiro ponto
      shouldAddPoint = true;
    } else {
      // Calcular distância do último ponto válido
      final distance = Geolocator.distanceBetween(
        _lastValidPoint!.latitude,
        _lastValidPoint!.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );
      
      // Adicionar ponto se distância for maior que 2 metros
      if (distance >= 2.0) {
        shouldAddPoint = true;
        _totalDistance += distance;
        
        // Calcular velocidade se temos timestamp anterior
        if (_lastValidTimestamp != null) {
          final timeDiff = now.difference(_lastValidTimestamp!).inSeconds;
          if (timeDiff > 0) {
            _currentSpeed = (distance / timeDiff) * 3.6; // Converter para km/h
          }
        }
      }
    }
    
    if (shouldAddPoint) {
      _points.add(newPoint);
      _lastValidPoint = newPoint;
      _lastValidTimestamp = now;
      
      print('📍 Ponto GPS adicionado: ${_points.length} pontos, distância: ${_totalDistance.toStringAsFixed(1)}m');
      notifyListeners();
    }
  }
  
  /// Obtém pontos válidos
  List<LatLng> getValidPoints() {
    return validPoints;
  }
  
  /// Mostra erro
  void _showError(String message) {
    print('❌ LocationService Error: $message');
    // Aqui você pode implementar um sistema de notificação se necessário
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _accuracyTimer?.cancel();
    super.dispose();
  }
}