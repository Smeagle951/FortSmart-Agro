import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/talhao_model.dart';
import '../../models/cultura_model.dart';
import '../../models/monitoring.dart';
import '../../models/monitoring_point.dart';

/// Classe que gerencia o estado do módulo de monitoramento
/// Centraliza todas as variáveis e dados para evitar conflitos
class MonitoringState extends ChangeNotifier {
  // Estados de carregamento
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  // Estados de interface
  bool _isDrawingMode = false;
  bool _modoSatelite = true;
  bool _mostrarLocalizacaoAtual = false;
  bool _isLoadingLocation = false;
  
  // Dados principais
  List<TalhaoModel> _availableTalhoes = [];
  List<CulturaModel> _availableCulturas = [];
  TalhaoModel? _selectedTalhao;
  CulturaModel? _selectedCultura;
  DateTime _selectedDate = DateTime.now();
  
  // Dados de localização e mapa
  LatLng? _currentPosition;
  LatLng? _localizacaoAtual;
  
  // Dados de monitoramento
  List<Map<String, dynamic>> _historicalAlerts = [];
  List<Map<String, dynamic>> _recentMonitorings = [];
  Map<String, dynamic> _monitoringStats = {};
  
  // Dados de rota e pontos
  final List<LatLng> _routePoints = [];
  final List<Marker> _pointMarkers = [];
  final List<Polyline> _routeLines = [];
  
  // Filtros
  String _selectedFilter = 'all'; // all, critical, recent, pending
  DateTime? _selectedDateFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSeverity;
  final List<String> _availableSeverities = ['Baixa', 'Média', 'Alta', 'Crítica'];
  
  // Dados importados
  List<CulturaModel> _culturas = [];
  List<TalhaoModel> _talhoesImportados = [];
  bool _isLoadingCulturas = false;
  bool _isLoadingTalhoes = false;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get isDrawingMode => _isDrawingMode;
  bool get modoSatelite => _modoSatelite;
  bool get mostrarLocalizacaoAtual => _mostrarLocalizacaoAtual;
  bool get isLoadingLocation => _isLoadingLocation;
  
  List<TalhaoModel> get availableTalhoes => _availableTalhoes;
  List<CulturaModel> get availableCulturas => _availableCulturas;
  TalhaoModel? get selectedTalhao => _selectedTalhao;
  CulturaModel? get selectedCultura => _selectedCultura;
  DateTime get selectedDate => _selectedDate;
  
  LatLng? get currentPosition => _currentPosition;
  LatLng? get localizacaoAtual => _localizacaoAtual;
  
  List<Map<String, dynamic>> get historicalAlerts => _historicalAlerts;
  List<Map<String, dynamic>> get recentMonitorings => _recentMonitorings;
  Map<String, dynamic> get monitoringStats => _monitoringStats;
  
  List<LatLng> get routePoints => _routePoints;
  List<Marker> get pointMarkers => _pointMarkers;
  List<Polyline> get routeLines => _routeLines;
  
  String get selectedFilter => _selectedFilter;
  DateTime? get selectedDateFilter => _selectedDateFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedSeverity => _selectedSeverity;
  List<String> get availableSeverities => _availableSeverities;
  
  List<CulturaModel> get culturas => _culturas;
  List<TalhaoModel> get talhoesImportados => _talhoesImportados;
  bool get isLoadingCulturas => _isLoadingCulturas;
  bool get isLoadingTalhoes => _isLoadingTalhoes;
  
  // Setters com notificação
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void setInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }
  
  void setRefreshing(bool value) {
    _isRefreshing = value;
    notifyListeners();
  }
  
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void setDrawingMode(bool value) {
    _isDrawingMode = value;
    notifyListeners();
  }
  
  void setModoSatelite(bool value) {
    _modoSatelite = value;
    notifyListeners();
  }
  
  void setMostrarLocalizacaoAtual(bool value) {
    _mostrarLocalizacaoAtual = value;
    notifyListeners();
  }
  
  void setLoadingLocation(bool value) {
    _isLoadingLocation = value;
    notifyListeners();
  }
  
  void setAvailableTalhoes(List<TalhaoModel> talhoes) {
    _availableTalhoes = talhoes;
    notifyListeners();
  }
  
  void setAvailableCulturas(List<CulturaModel> culturas) {
    _availableCulturas = culturas;
    notifyListeners();
  }
  
  void setSelectedTalhao(TalhaoModel? talhao) {
    _selectedTalhao = talhao;
    notifyListeners();
  }
  
  void setSelectedCultura(CulturaModel? cultura) {
    _selectedCultura = cultura;
    notifyListeners();
  }
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  void setCurrentPosition(LatLng? position) {
    _currentPosition = position;
    notifyListeners();
  }
  
  void setLocalizacaoAtual(LatLng? position) {
    _localizacaoAtual = position;
    notifyListeners();
  }
  
  void setHistoricalAlerts(List<Map<String, dynamic>> alerts) {
    _historicalAlerts = alerts;
    notifyListeners();
  }
  
  void setRecentMonitorings(List<Map<String, dynamic>> monitorings) {
    _recentMonitorings = monitorings;
    notifyListeners();
  }
  
  void setMonitoringStats(Map<String, dynamic> stats) {
    _monitoringStats = stats;
    notifyListeners();
  }
  
  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
  
  void setSelectedDateFilter(DateTime? date) {
    _selectedDateFilter = date;
    notifyListeners();
  }
  
  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }
  
  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }
  
  void setSelectedSeverity(String? severity) {
    _selectedSeverity = severity;
    notifyListeners();
  }
  
  void setCulturas(List<CulturaModel> culturas) {
    _culturas = culturas;
    notifyListeners();
  }
  
  void setTalhoesImportados(List<TalhaoModel> talhoes) {
    _talhoesImportados = talhoes;
    notifyListeners();
  }
  
  void setLoadingCulturas(bool value) {
    _isLoadingCulturas = value;
    notifyListeners();
  }
  
  void setLoadingTalhoes(bool value) {
    _isLoadingTalhoes = value;
    notifyListeners();
  }
  
  // Métodos para manipular listas
  void addRoutePoint(LatLng point) {
    _routePoints.add(point);
    notifyListeners();
  }
  
  void addPointMarker(Marker marker) {
    _pointMarkers.add(marker);
    notifyListeners();
  }
  
  void addRouteLine(Polyline line) {
    _routeLines.add(line);
    notifyListeners();
  }
  
  void clearRoute() {
    _routePoints.clear();
    _pointMarkers.clear();
    _routeLines.clear();
    notifyListeners();
  }
  
  void addHistoricalAlert(Map<String, dynamic> alert) {
    _historicalAlerts.add(alert);
    notifyListeners();
  }
  
  void addRecentMonitoring(Map<String, dynamic> monitoring) {
    _recentMonitorings.add(monitoring);
    notifyListeners();
  }
  
  // Métodos de utilidade
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void resetState() {
    _isLoading = false;
    _isInitialized = false;
    _isRefreshing = false;
    _errorMessage = null;
    _isDrawingMode = false;
    _mostrarLocalizacaoAtual = false;
    _isLoadingLocation = false;
    
    _availableTalhoes.clear();
    _availableCulturas.clear();
    _selectedTalhao = null;
    _selectedCultura = null;
    _selectedDate = DateTime.now();
    
    _currentPosition = null;
    _localizacaoAtual = null;
    
    _historicalAlerts.clear();
    _recentMonitorings.clear();
    _monitoringStats.clear();
    
    _routePoints.clear();
    _pointMarkers.clear();
    _routeLines.clear();
    
    _selectedFilter = 'all';
    _selectedDateFilter = null;
    _startDate = null;
    _endDate = null;
    _selectedSeverity = null;
    
    _culturas.clear();
    _talhoesImportados.clear();
    _isLoadingCulturas = false;
    _isLoadingTalhoes = false;
    
    notifyListeners();
  }
  
  // Verificações de estado
  bool get hasData => _availableTalhoes.isNotEmpty && _availableCulturas.isNotEmpty;
  bool get hasError => _errorMessage != null;
  bool get hasLocation => _currentPosition != null;
  bool get hasRoute => _routePoints.isNotEmpty;
  bool get hasHistoricalData => _historicalAlerts.isNotEmpty || _recentMonitorings.isNotEmpty;
  
  @override
  void dispose() {
    // Limpar recursos se necessário
    super.dispose();
  }
}
