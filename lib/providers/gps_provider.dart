import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Provider para gerenciar o estado do GPS e rastreamento de localização
class GpsProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isLocationServiceEnabled = false;
  LocationPermission? _permission;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final List<LatLng> _trackPoints = [];
  
  // Configurações de rastreamento
  int _minDistanciaMetros = 2; // Distância mínima entre pontos em metros
  int _intervalAtualizacaoMs = 5000; // Intervalo entre atualizações em milissegundos
  bool _rastreamentoEmSegundoPlano = false; // Indica se o rastreamento está em segundo plano
  
  /// Indica se o rastreamento GPS está ativo
  bool get isTracking => _isTracking;
  
  /// Indica se o serviço de localização está habilitado
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  
  /// Permissão atual de localização
  LocationPermission? get permission => _permission;
  
  /// Posição atual do GPS
  Position? get currentPosition => _currentPosition;
  
  /// Localização atual em formato LatLng para uso com flutter_map
  LatLng? get currentLocation => _currentPosition != null 
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;
  
  /// Atualiza a posição atual manualmente
  void updateCurrentPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }
  
  /// Lista de pontos rastreados
  List<LatLng> get trackPoints => List.unmodifiable(_trackPoints);

  bool get isLocationEnabled => _isLocationServiceEnabled;
  
  /// Inicializa o provider verificando permissões e status do serviço
  Future<void> initialize() async {
    await _checkLocationService();
    await _checkPermission();
    notifyListeners();
  }
  
  /// Verifica se o serviço de localização está habilitado
  Future<void> _checkLocationService() async {
    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
  }
  
  /// Verifica a permissão de localização
  Future<void> _checkPermission() async {
    if (!_isLocationServiceEnabled) {
      _permission = LocationPermission.denied;
      return;
    }
    
    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }
  }
  
  /// Solicita permissão de localização
  Future<bool> requestPermission() async {
    _permission = await Geolocator.requestPermission();
    notifyListeners();
    return _permission == LocationPermission.always || 
           _permission == LocationPermission.whileInUse;
  }
  
  /// Define as configurações de rastreamento
  void configurarRastreamento({
    int? minDistanciaMetros,
    int? intervalAtualizacaoMs,
    bool? rastreamentoEmSegundoPlano,
  }) {
    if (minDistanciaMetros != null) _minDistanciaMetros = minDistanciaMetros;
    if (intervalAtualizacaoMs != null) _intervalAtualizacaoMs = intervalAtualizacaoMs;
    if (rastreamentoEmSegundoPlano != null) _rastreamentoEmSegundoPlano = rastreamentoEmSegundoPlano;
    
    // Se o rastreamento já estiver ativo, reinicia com as novas configurações
    if (_isTracking) {
      stopTracking();
      startTracking();
    }
  }

  /// Inicia o rastreamento GPS
  Future<bool> startTracking() async {
    if (!_isLocationServiceEnabled) {
      await _checkLocationService();
      if (!_isLocationServiceEnabled) {
        return false;
      }
    }
    
    // Para rastreamento em segundo plano, precisamos de permissão always
    if (_rastreamentoEmSegundoPlano && 
        (_permission != LocationPermission.always)) {
      // Solicita permissão always para rastreamento em segundo plano
      _permission = await Geolocator.requestPermission();
      if (_permission != LocationPermission.always) {
        // Fallback para whileInUse se o usuário não conceder always
        _rastreamentoEmSegundoPlano = false;
      }
    } else if (_permission == null || 
        _permission == LocationPermission.denied || 
        _permission == LocationPermission.deniedForever) {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        return false;
      }
    }
    
    // Limpa pontos anteriores se houver
    _trackPoints.clear();
    
    // Configura o stream de posição com base nas configurações
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _minDistanciaMetros,
        timeLimit: Duration(milliseconds: _intervalAtualizacaoMs),
      ),
    ).listen(_onPositionUpdate);
    
    _isTracking = true;
    notifyListeners();
    return true;
  }
  
  /// Para o rastreamento GPS
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }
  
  /// Callback para atualização de posição
  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    
    // Converte Position para LatLng - leitura direta do GPS sem suavização
    final newPoint = LatLng(position.latitude, position.longitude);
    
    // Adiciona o ponto se estiver a uma distância mínima do último ponto
    if (_trackPoints.isNotEmpty) {
      final lastPoint = _trackPoints.last;
      final distance = _calculateDistance(lastPoint, newPoint);
      
      // Usa a configuração de distância mínima definida pelo usuário
      if (distance >= _minDistanciaMetros) {
        // Verifica se o usuário está se movendo em velocidade razoável
        // para evitar pontos errados quando parado
        if (position.speed > 0.5) { // em m/s (aproximadamente 1.8 km/h)
          _trackPoints.add(newPoint);
        }
      }
    } else {
      // Primeiro ponto
      _trackPoints.add(newPoint);
    }
    
    notifyListeners();
  }
  
  /// Calcula a distância entre dois pontos em metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
  
  /// Obtém a posição atual uma única vez
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Verificar se o serviço de localização está habilitado
      if (!_isLocationServiceEnabled) {
        await _checkLocationService();
        if (!_isLocationServiceEnabled) {
          return null;
        }
      }
      
      // Verificar permissão
      if (_permission == null || 
          _permission == LocationPermission.denied || 
          _permission == LocationPermission.deniedForever) {
        await _checkPermission();
        if (_permission != LocationPermission.always && 
            _permission != LocationPermission.whileInUse) {
          return null;
        }
      }
      
      // Tentar obter a posição atual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Atualizar a posição atual
      _currentPosition = position;
      
      // Retornar como LatLng
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }
  
  /// Limpa os pontos rastreados
  void clearTrackPoints() {
    _trackPoints.clear();
    notifyListeners();
  }
  
  /// Adiciona pontos rastreados ao desenho
  List<LatLng> getTrackPointsForDrawing() {
    return List.from(_trackPoints);
  }
  
  /// Verifica se um ponto está dentro de um polígono (algoritmo ray-casting)
  bool pontoEstaDentroDoPoligono(LatLng ponto, List<LatLng> poligono) {
    if (poligono.length < 3) return false;
    
    bool dentro = false;
    int j = poligono.length - 1;
    
    for (int i = 0; i < poligono.length; i++) {
      if ((poligono[i].latitude > ponto.latitude) != (poligono[j].latitude > ponto.latitude) &&
          (ponto.longitude < (poligono[j].longitude - poligono[i].longitude) * 
          (ponto.latitude - poligono[i].latitude) / 
          (poligono[j].latitude - poligono[i].latitude) + poligono[i].longitude)) {
        dentro = !dentro;
      }
      j = i;
    }
    
    return dentro;
  }
  
  /// Detecta se o usuário atravessou um polígono (entrou ou saiu)
  bool detectarTravessiaPoligono(List<LatLng> poligono) {
    if (_trackPoints.length < 2 || poligono.length < 3) return false;
    
    // Verifica se o último ponto e o penúltimo ponto estão em lados diferentes do polígono
    final ultimoPonto = _trackPoints.last;
    final penultimoPonto = _trackPoints[_trackPoints.length - 2];
    
    final ultimoDentro = pontoEstaDentroDoPoligono(ultimoPonto, poligono);
    final penultimoDentro = pontoEstaDentroDoPoligono(penultimoPonto, poligono);
    
    // Se um ponto está dentro e outro fora, houve travessia
    return ultimoDentro != penultimoDentro;
  }
  
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void openLocationSettings() {}

  getCurrentPosition() {}
}
