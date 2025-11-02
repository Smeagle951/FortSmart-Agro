import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';

import '../services/geo_calculator_service.dart';
import '../services/culture_manager.dart';
import '../services/location_service.dart';
import '../services/advanced_gps_tracking_service.dart';
import '../repositories/talhao_repository.dart';
import '../models/cultura_model.dart';
import '../models/talhao_model.dart';
import '../config/maptiler_config.dart';

/// Controller para gerenciar estado e lógica dos talhões
class TalhaoController extends ChangeNotifier {
  // Serviços
  final GeoCalculatorService _geoCalculator = GeoCalculatorService();
  final CultureManager _cultureManager = CultureManager();
  final LocationService _locationService = LocationService();
  final AdvancedGpsTrackingService _gpsService = AdvancedGpsTrackingService();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();

  // Estado do mapa
  LatLng? _userLocation;
  MapController? _mapController;
  
  // Estado da UI
  bool _showPopup = false;
  TalhaoModel? _selectedTalhao;
  bool _isDrawing = false;
  bool _showActionButtons = false;
  
  // Estado do GPS
  bool _isGpsTracking = false;
  List<LatLng> _gpsPoints = [];
  
  // Estado dos polígonos
  List<LatLng> _currentPoints = [];
  List<Map<String, dynamic>> _polygons = [];
  
  // Estado das culturas
  List<CulturaModel> _cultures = [];
  String _safraSelecionada = '2024/2025';
  
  // Métricas atuais
  double _currentArea = 0.0;
  double _currentPerimeter = 0.0;
  double _currentDistance = 0.0;

  // Getters
  LatLng? get userLocation => _userLocation;
  MapController? get mapController => _mapController;
  bool get showPopup => _showPopup;
  TalhaoModel? get selectedTalhao => _selectedTalhao;
  bool get isDrawing => _isDrawing;
  bool get showActionButtons => _showActionButtons;
  bool get isGpsTracking => _isGpsTracking;
  List<LatLng> get gpsPoints => _gpsPoints;
  List<LatLng> get currentPoints => _currentPoints;
  List<Map<String, dynamic>> get polygons => _polygons;
  List<CulturaModel> get cultures => _cultures;
  String get safraSelecionada => _safraSelecionada;
  double get currentArea => _currentArea;
  double get currentPerimeter => _currentPerimeter;
  double get currentDistance => _currentDistance;

  /// Inicializa o controller
  Future<void> initialize() async {
    await _loadCultures();
    await _getUserLocation();
    _setupMapController();
    await _loadExistingTalhoes();
  }

  /// Carrega culturas disponíveis
  Future<void> _loadCultures() async {
    try {
      _cultures = await _cultureManager.loadCultures();
      notifyListeners();
    } catch (e) {
      // Log error but don't crash
    }
  }

  /// Obtém localização do usuário
  Future<void> _getUserLocation() async {
    try {
      // Sempre tentar obter a localização atual do GPS
      _userLocation = await _locationService.getCurrentLocation();
      
      // Centralizar o mapa na localização atual
      if (_mapController != null && _userLocation != null) {
        _mapController!.move(_userLocation!, MapTilerConfig.defaultZoom);
      }
      
      notifyListeners();
    } catch (e) {
      // Se não conseguir obter GPS, usar localização padrão
      _userLocation = const LatLng(MapTilerConfig.defaultLat, MapTilerConfig.defaultLng);
      notifyListeners();
    }
  }

  /// Configura o controlador do mapa
  void _setupMapController() {
    _mapController = MapController();
  }

  /// Inicia desenho manual
  void startDrawing() {
    _isDrawing = true;
    _currentPoints.clear();
    _showActionButtons = false;
    notifyListeners();
  }

  /// Adiciona ponto ao desenho
  void addPoint(LatLng point) {
    if (!_isDrawing) return;
    
    _currentPoints.add(point);
    _calculateCurrentMetrics();
    notifyListeners();
  }

  /// Finaliza desenho
  void finishDrawing() {
    if (_currentPoints.length < 3) return;
    
    _isDrawing = false;
    _showActionButtons = true;
    _calculateCurrentMetrics();
    notifyListeners();
  }

  /// Limpa desenho atual
  void clearDrawing() {
    _currentPoints.clear();
    _isDrawing = false;
    _showActionButtons = false;
    _currentArea = 0.0;
    _currentPerimeter = 0.0;
    _currentDistance = 0.0;
    notifyListeners();
  }

  /// Calcula métricas do polígono atual
  void _calculateCurrentMetrics() {
    if (_currentPoints.length < 3) {
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
      _currentDistance = 0.0;
      return;
    }

    _currentArea = _geoCalculator.calculateAreaHectares(_currentPoints);
    _currentPerimeter = _geoCalculator.calculatePerimeter(_currentPoints);
    _currentDistance = _geoCalculator.calculateTotalDistance(_currentPoints);
  }

  /// Inicia rastreamento GPS
  Future<void> startGpsTracking() async {
    try {
      await _gpsService.startTracking();
      _isGpsTracking = true;
      _gpsPoints.clear();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Pausa rastreamento GPS
  Future<void> pauseGpsTracking() async {
    try {
      await _gpsService.pauseTracking();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Resume rastreamento GPS
  Future<void> resumeGpsTracking() async {
    try {
      await _gpsService.resumeTracking();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Finaliza rastreamento GPS
  Future<void> finishGpsTracking() async {
    try {
      _gpsPoints = await _gpsService.finishTracking();
      _isGpsTracking = false;
      
      if (_gpsPoints.length >= 3) {
        _currentPoints = List.from(_gpsPoints);
        _showActionButtons = true;
        _calculateCurrentMetrics();
      }
      
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Salva talhão atual
  Future<bool> saveCurrentTalhao({
    required String name,
    required String culturaId,
    String? observacoes,
  }) async {
    if (_currentPoints.length < 3) return false;

    try {
      final talhao = TalhaoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        poligonos: [], // TODO: Converter pontos para polígonos
        area: _currentArea,
        observacoes: observacoes ?? '',
        culturaId: culturaId,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false,
        safras: [],
      );

      await _talhaoRepository.saveTalhao(talhao);
      
      // Adicionar ao polígono atual
      _polygons.add({
        'id': talhao.id,
        'name': talhao.nome,
        'points': _currentPoints,
        'areaHa': _currentArea,
        'perimeterM': _currentPerimeter,
        'culturaId': culturaId,
        'safra': _safraSelecionada,
      });

      clearDrawing();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Seleciona talhão
  void selectTalhao(TalhaoModel? talhao) {
    _selectedTalhao = talhao;
    _showPopup = talhao != null;
    notifyListeners();
  }

  /// Fecha popup
  void closePopup() {
    _showPopup = false;
    _selectedTalhao = null;
    notifyListeners();
  }

  /// Atualiza safra selecionada
  void updateSafra(String safra) {
    _safraSelecionada = safra;
    notifyListeners();
  }

  /// Obtém cor por nome da cultura
  Color getColorForCulture(String cultureName) {
    final culture = _cultures.firstWhere(
      (c) => c.nome == cultureName,
      orElse: () => CulturaModel(id: '', nome: cultureName, cor: '#4CAF50', icone: '🌱'),
    );
    
    return Color(int.parse(culture.cor.replaceAll('#', '0xFF')));
  }

  /// Formata área em hectares
  String formatArea(double hectares) {
    return _geoCalculator.formatArea(hectares);
  }

  /// Formata distância
  String formatDistance(double meters) {
    return _geoCalculator.formatDistance(meters);
  }


  /// Atualiza métricas
  void _updateMetrics() {
    if (_currentPoints.length >= 3) {
      _currentArea = _geoCalculator.calculateAreaHectares(_currentPoints);
      _currentPerimeter = _geoCalculator.calculatePerimeter(_currentPoints);
    } else {
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
    }
  }

  /// Lista de talhões existentes
  List<TalhaoModel> _existingTalhoes = [];
  List<TalhaoModel> get existingTalhoes => _existingTalhoes;

  /// Lista de safras
  List<String> _safras = ['2024/2025', '2025/2026'];
  List<String> get safras => _safras;

  /// Atualiza um talhão
  Future<bool> updateTalhao(TalhaoModel talhao) async {
    try {
      await _talhaoRepository.updateTalhao(talhao);
      await _loadExistingTalhoes();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove um talhão
  Future<bool> deleteTalhao(String id) async {
    try {
      await _talhaoRepository.deleteTalhao(id);
      await _loadExistingTalhoes();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Carrega talhões existentes
  Future<void> _loadExistingTalhoes() async {
    try {
      _existingTalhoes = await _talhaoRepository.getAllTalhoes();
    } catch (e) {
      _existingTalhoes = [];
    }
  }

  /// Atualiza a localização atual do GPS
  Future<void> updateCurrentLocation() async {
    try {
      final newLocation = await _locationService.getCurrentLocation();
      if (newLocation != null) {
        _userLocation = newLocation;
        
        // Centralizar o mapa na nova localização
        if (_mapController != null) {
          _mapController!.move(_userLocation!, MapTilerConfig.defaultZoom);
        }
        
        notifyListeners();
      }
    } catch (e) {
      // Erro ao obter localização, manter a atual
    }
  }

  /// Centraliza o mapa na localização atual
  void centerMapOnCurrentLocation() {
    if (_mapController != null && _userLocation != null) {
      _mapController!.move(_userLocation!, MapTilerConfig.defaultZoom);
    }
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}
