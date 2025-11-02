import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../utils/geo_calculator.dart';

/// Controller simplificado para gerenciar estado dos talhões
class TalhaoControllerSimple extends ChangeNotifier {
  // Estado do mapa
  MapController? _mapController;
  LatLng? _userLocation;

  // Estado do desenho
  bool _isDrawing = false;
  List<LatLng> _currentPoints = [];
  double _currentArea = 0.0;
  double _currentPerimeter = 0.0;

  // Estado da UI
  bool _showPopup = false;
  TalhaoModel? _selectedTalhao;

  // Talhões existentes
  List<TalhaoModel> _existingTalhoes = [];

  // Getters
  MapController? get mapController => _mapController;
  LatLng? get userLocation => _userLocation;
  bool get isDrawing => _isDrawing;
  List<LatLng> get currentPoints => List.unmodifiable(_currentPoints);
  double get currentArea => _currentArea;
  double get currentPerimeter => _currentPerimeter;
  bool get showPopup => _showPopup;
  TalhaoModel? get selectedTalhao => _selectedTalhao;
  List<TalhaoModel> get existingTalhoes => List.unmodifiable(_existingTalhoes);

  /// Inicializa o controller
  Future<void> initialize() async {
    _setupMapController();
    await _getUserLocation();
  }

  /// Obtém localização do usuário
  Future<void> _getUserLocation() async {
    try {
      // Simular localização (São Paulo)
      _userLocation = const LatLng(-23.5505, -46.6333);
      notifyListeners();
    } catch (e) {
      _userLocation = const LatLng(-23.5505, -46.6333);
      notifyListeners();
    }
  }

  /// Configura o controlador do mapa
  void _setupMapController() {
    _mapController = MapController();
  }

  /// Inicia o desenho
  void startDrawing() {
    _isDrawing = true;
    _currentPoints.clear();
    _currentArea = 0.0;
    _currentPerimeter = 0.0;
    notifyListeners();
  }

  /// Adiciona ponto ao desenho atual
  void addPoint(LatLng point) {
    _currentPoints.add(point);
    _updateMetrics();
    notifyListeners();
  }

  /// Remove último ponto
  void undoLastPoint() {
    if (_currentPoints.isNotEmpty) {
      _currentPoints.removeLast();
      _updateMetrics();
      notifyListeners();
    }
  }

  /// Limpa o desenho atual
  void clearDrawing() {
    _currentPoints.clear();
    _currentArea = 0.0;
    _currentPerimeter = 0.0;
    _isDrawing = false;
    notifyListeners();
  }

  /// Finaliza o desenho
  void finishDrawing() {
    _isDrawing = false;
    notifyListeners();
  }

  /// Atualiza métricas usando GeoCalculator preciso
  void _updateMetrics() {
    if (_currentPoints.length >= 3) {
      _currentArea = GeoCalculator.calculateAreaHectares(_currentPoints);
      _currentPerimeter = GeoCalculator.calculatePerimeterMeters(_currentPoints);
    } else {
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
    }
  }

  // Métodos de cálculo antigos removidos - agora usando GeoCalculator

  /// Salva o talhão atual
  Future<bool> saveCurrentTalhao({
    required String name,
    required String culturaId,
    String? observacoes,
  }) async {
    if (_currentPoints.length < 3) return false;

    try {
      final poligono = PoligonoModel.criar(
        pontos: _currentPoints,
        talhaoId: const Uuid().v4(),
        area: _currentArea,
        perimetro: _currentPerimeter,
      );

      final talhao = TalhaoModel(
        id: const Uuid().v4(),
        name: name,
        poligonos: [poligono],
        area: _currentArea,
        observacoes: observacoes ?? '',
        culturaId: culturaId,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false,
        safras: [],
      );

      _existingTalhoes.add(talhao);
      clearDrawing();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Seleciona um talhão
  void selectTalhao(TalhaoModel talhao) {
    _selectedTalhao = talhao;
    _showPopup = true;
    notifyListeners();
  }

  /// Fecha o popup
  void closePopup() {
    _showPopup = false;
    _selectedTalhao = null;
    notifyListeners();
  }

  /// Atualiza a localização atual do GPS
  Future<void> updateCurrentLocation() async {
    try {
      // Simular atualização de localização
      _userLocation = const LatLng(-23.5505, -46.6333);
      
      // Centralizar o mapa na nova localização
      if (_mapController != null) {
        _mapController!.move(_userLocation!, 15.0);
      }
      
      notifyListeners();
    } catch (e) {
      // Erro ao obter localização, manter a atual
    }
  }

  /// Centraliza o mapa na localização atual
  void centerMapOnCurrentLocation() {
    if (_mapController != null && _userLocation != null) {
      _mapController!.move(_userLocation!, 15.0);
    }
  }

  // Métodos duplicados removidos - já existem acima

  /// Adiciona um talhão existente à lista
  void addExistingTalhao(TalhaoModel talhao) {
    _existingTalhoes.add(talhao);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
