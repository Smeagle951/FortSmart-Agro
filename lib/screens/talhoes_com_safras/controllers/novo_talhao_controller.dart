import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../models/cultura_model.dart';
import '../../../models/talhao_model.dart';
import '../../../models/poligono_model.dart';
import '../../../services/location_service.dart';
import '../../../services/advanced_gps_tracking_service.dart';
import '../../../services/background_gps_service.dart';
import '../../../providers/enhanced_gps_provider.dart';
import '../../../services/talhao_notification_service.dart';
import '../../../services/talhao_unified_service.dart';
import '../../../services/talhao_module_service.dart';
import '../../../services/device_location_service.dart';
import '../../../services/culture_import_service.dart';
import '../../../repositories/crop_repository.dart';
import '../../../utils/logger.dart';
import '../../../utils/geo_calculator.dart';
import '../../../utils/precise_geo_calculator.dart';
import '../../../utils/talhao_calculator.dart';

/// Controller para gerenciar a lógica de negócio da tela de talhões
class NovoTalhaoController extends ChangeNotifier {
  // ===== CONSTANTES =====
  static const double _zoomDefault = 15.0;
  static const Duration _timeoutGps = Duration(seconds: 10);
  
  // ===== ESTADO DO MAPA =====
  LatLng? _userLocation;
  MapController? _mapController;
  
  // ===== ESTADO DA UI =====
  bool _showPopup = false;
  bool _isDrawing = false;
  bool _showActionButtons = false;
  
  // ===== SERVIÇOS =====
  final LocationService _locationService = LocationService();
  final AdvancedGpsTrackingService _advancedGpsService = AdvancedGpsTrackingService();
  final EnhancedGpsProvider _enhancedGpsProvider = EnhancedGpsProvider();
  final TalhaoNotificationService _talhaoNotificationService = TalhaoNotificationService();
  final TalhaoUnifiedService _talhaoUnifiedService = TalhaoUnifiedService();
  final TalhaoModuleService _talhaoModuleService = TalhaoModuleService();
  
  // ===== ESTADO DE CULTURA =====
  List<CulturaModel> _culturas = [];
  CulturaModel? _selectedCultura;
  bool _isLoadingCulturas = false;
  
  // ===== ESTADO DE DESENHO =====
  List<LatLng> _currentPoints = [];
  List<Map<String, dynamic>> _polygons = [];
  List<TalhaoModel> _existingTalhoes = [];
  
  // ===== ESTADO DE SAFRA =====
  String? _safraSelecionada; // Sem valor padrão - usuário deve selecionar
  
  // ===== ESTADO DE RASTREAMENTO GPS =====
  bool _isAdvancedGpsTracking = false;
  bool _isAdvancedGpsPaused = false;
  double _advancedGpsDistance = 0.0;
  double _totalDistance = 0.0; // Distância total percorrida
  LatLng? _lastPointBeforePause; // Último ponto antes da pausa
  
  // ===== ESTADO DE GPS SIMPLES =====
  bool _isGpsRecording = false;
  bool _isGpsPaused = false;
  double _advancedGpsAccuracy = 0.0;
  String _advancedGpsStatus = ''; 
  DateTime? _gpsStartTime;
  DateTime? _lastGpsUpdate;
  List<double> _gpsAccuracies = [];
  
  // ===== ESTADO DE CÁLCULO EM TEMPO REAL =====
  double _currentAreaHa = 0.0;
  double _currentPerimeterM = 0.0;
  double _currentSpeedKmh = 0.0;
  Duration _elapsedTime = Duration.zero;
  DateTime? _trackingStartTime;
  DateTime? _trackingEndTime;
  
  // ===== CÁLCULOS EM TEMPO REAL =====
  double _currentArea = 0.0;
  double _currentPerimeter = 0.0;
  double _currentDistance = 0.0;
  
  // ===== LISTA DE TALHÕES =====
  List<TalhaoModel> _talhoes = [];
  double _drawnArea = 0.0;
  
  // ===== ESTADO DE SALVAMENTO =====
  bool _isSaving = false;
  String _polygonName = '';

  // ===== GETTERS =====
  LatLng? get userLocation => _userLocation;
  MapController? get mapController => _mapController;
  bool get showPopup => _showPopup;
  bool get isDrawing => _isDrawing;
  bool get showActionButtons => _showActionButtons;
  List<CulturaModel> get culturas => _culturas;
  CulturaModel? get selectedCultura => _selectedCultura;
  bool get isLoadingCulturas => _isLoadingCulturas;
  List<LatLng> get currentPoints => _currentPoints;
  List<Map<String, dynamic>> get polygons => _polygons;
  
  // Getters para cálculos em tempo real
  double get currentAreaHa => _currentAreaHa;
  double get currentPerimeterM => _currentPerimeterM;
  double get currentSpeedKmh => _currentSpeedKmh;
  Duration get elapsedTime => _elapsedTime;
  double get gpsAccuracy => _advancedGpsAccuracy;
  double get currentSpeed => _currentSpeedKmh;
  bool get isGpsPaused => _isAdvancedGpsPaused;
  String get safraSelecionada => _safraSelecionada ?? '';
  bool get isAdvancedGpsTracking => _isAdvancedGpsTracking;
  List<TalhaoModel> get existingTalhoes => _existingTalhoes;
  bool get isAdvancedGpsPaused => _isAdvancedGpsPaused;
  double get advancedGpsDistance => _advancedGpsDistance;
  double get advancedGpsAccuracy => _advancedGpsAccuracy;
  String get advancedGpsStatus => _advancedGpsStatus;
  
  // ===== GETTERS GPS SIMPLES =====
  bool get isGpsRecording => _isGpsRecording;
  DateTime? get trackingStartTime => _trackingStartTime;
  DateTime? get trackingEndTime => _trackingEndTime;
  double get currentArea => _currentArea;
  double get currentPerimeter => _currentPerimeter;
  double get currentDistance => _currentDistance;
  List<TalhaoModel> get talhoes => _talhoes;
  double get drawnArea => _drawnArea;
  bool get isSaving => _isSaving;
  String get polygonName => _polygonName;

  // ===== MÉTODOS DE INICIALIZAÇÃO =====
  
  /// Inicializa o controller de forma simples
  Future<void> initialize() async {
    print('Controller: Inicializando MapController...');
    _mapController = MapController();
    print('Controller: MapController criado: $_mapController');
    
    // REMOVIDO: Inicializações que causam loops infinitos
    // await _initializeAdvancedGpsService();
    // await _carregarCulturas();
    // await _carregarTalhoesExistentes();
    
    print('Controller: Inicialização simplificada completa');
  }

  /// Inicializa serviço de rastreamento GPS avançado
  Future<void> _initializeAdvancedGpsService() async {
    try {
      await _advancedGpsService.initialize();
      await _enhancedGpsProvider.initialize();
    } catch (e) {
      // Erro ao inicializar serviço de rastreamento GPS avançado
    }
  }


  // ===== MÉTODOS DE GPS =====
  
  /// Inicia gravação GPS
  Future<bool> startGpsRecording() async {
    try {
      print('🎯 Controller: Iniciando gravação GPS...');
      
      // Verificar se já está gravando
      if (_isAdvancedGpsTracking) {
        _talhaoNotificationService.showInfoMessage('GPS já está ativo');
        return true;
      }
      
      // Limpar pontos anteriores
      _currentPoints.clear();
      _totalDistance = 0.0;
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
      
      // Iniciar o serviço de localização
      await _locationService.startRecording();
      
      // Configurar callbacks
      _locationService.onLocationUpdate = (position) {
        final newPoint = LatLng(position.latitude, position.longitude);
        
        print('📍 Controller: Nova posição GPS recebida: ${newPoint.latitude}, ${newPoint.longitude} (accuracy: ${position.accuracy}m)');
        
        // Verificar precisão
        if (position.accuracy > 15.0) {
          print('⚠️ Controller: Precisão GPS baixa: ${position.accuracy}m');
          return;
        }
        
        // Adicionar ponto se não for muito próximo do último
        bool shouldAddPoint = false;
        if (_currentPoints.isEmpty) {
          shouldAddPoint = true;
          print('📍 Controller: Primeiro ponto GPS adicionado');
        } else if (_currentPoints.isNotEmpty) {
          final distance = GeoCalculator.haversineDistance(_currentPoints.last, newPoint);
          if (distance >= 1.0) { // Reduzido para 1 metro para mais pontos
            shouldAddPoint = true;
            _totalDistance += distance;
            print('📍 Controller: Ponto GPS adicionado - distância: ${distance.toStringAsFixed(1)}m');
          } else {
            print('📍 Controller: Ponto muito próximo, ignorando (${distance.toStringAsFixed(1)}m)');
          }
        }
        
        if (shouldAddPoint) {
          _currentPoints.add(newPoint);
          _lastGpsUpdate = DateTime.now();
          _updateCurrentMetrics();
          
          // Atualizar localização do usuário para o mapa
          _userLocation = newPoint;
          
          // CORREÇÃO: Centralizar mapa na posição atual do GPS
          if (_mapController != null) {
            _mapController!.move(newPoint, _mapController!.zoom);
            print('📍 Controller: Mapa centralizado na posição GPS atual');
          }
          
          notifyListeners();
          print('📍 Controller: Total de pontos: ${_currentPoints.length}, Distância total: ${_totalDistance.toStringAsFixed(1)}m');
        }
      };
      
      _locationService.onError = (error) {
        print('❌ Controller: Erro GPS: $error');
        _talhaoNotificationService.showErrorMessage('Erro GPS: $error');
      };
      
      // Ativar modo de desenho
      _isDrawing = true;
      _isAdvancedGpsTracking = true;
      _trackingStartTime = DateTime.now();
      _lastGpsUpdate = DateTime.now();
      
      notifyListeners();
      _talhaoNotificationService.showSuccessMessage('🎯 GPS iniciado! Comece a caminhar pelo perímetro do talhão.');
      
      return true;
    } catch (e) {
      print('❌ Controller: Erro ao iniciar GPS: $e');
      _talhaoNotificationService.showErrorMessage('Erro ao iniciar GPS: $e');
      return false;
    }
  }
  
  /// Pausa gravação GPS
  void pauseGpsRecording() {
    try {
      print('⏸️ Controller: Pausando gravação GPS...');
      
      if (_isAdvancedGpsTracking) {
        // Salvar último ponto antes de pausar
        if (_currentPoints.isNotEmpty) {
          _lastPointBeforePause = _currentPoints.last;
          print('📍 Controller: Último ponto salvo antes da pausa: ${_lastPointBeforePause!.latitude}, ${_lastPointBeforePause!.longitude}');
        }
        
        _locationService.pauseRecording();
        _isAdvancedGpsPaused = true;
        notifyListeners();
        _talhaoNotificationService.showInfoMessage('GPS pausado - último ponto salvo');
      }
    } catch (e) {
      print('❌ Controller: Erro ao pausar GPS: $e');
      _talhaoNotificationService.showErrorMessage('Erro ao pausar GPS: $e');
    }
  }
  
  /// Retoma gravação GPS
  Future<void> resumeGpsRecording() async {
    try {
      print('▶️ Controller: Retomando gravação GPS...');
      
      if (_isAdvancedGpsTracking && _isAdvancedGpsPaused) {
        // CORREÇÃO: Usar apenas LocationService para consistência
        final success = await _locationService.resumeRecording();
        
        if (success) {
          _isAdvancedGpsPaused = false;
          _lastPointBeforePause = null; // Limpar ponto salvo
          notifyListeners();
          _talhaoNotificationService.showSuccessMessage('GPS retomado - continuando do último ponto');
          print('✅ Controller: GPS retomado com sucesso');
        } else {
          _talhaoNotificationService.showErrorMessage('Erro ao retomar GPS');
        }
      }
    } catch (e) {
      print('❌ Controller: Erro ao retomar GPS: $e');
      _talhaoNotificationService.showErrorMessage('Erro ao retomar GPS: $e');
    }
  }
  
  /// Finaliza gravação GPS
  void finishGpsRecording() {
    try {
      print('🛑 Controller: Finalizando gravação GPS...');
      
      if (_isAdvancedGpsTracking) {
        // CORREÇÃO: Usar apenas LocationService para consistência
        _locationService.stopRecording();
        _isAdvancedGpsTracking = false;
        _isAdvancedGpsPaused = false;
        _isDrawing = false;
        _trackingEndTime = DateTime.now();
        
        // Obter pontos válidos do LocationService
        final validPoints = _locationService.getValidPoints();
        if (validPoints.length >= 3) {
          // CORREÇÃO: Usar método principal calcularTalhao com suavização
          final resultado = TalhaoCalculator.calcularTalhao(
            validPoints,
            suavizar: true, // Sempre suavizar pontos GPS
            geodesico: false, // Por enquanto usar cálculo plano
          );
          
          // Aplicar pontos processados
          _currentPoints = TalhaoCalculator.fecharPoligono(validPoints);
          
          // Atualizar métricas com resultado do calculador
          _currentAreaHa = resultado['areaHa'] as double;
          _currentPerimeterM = resultado['perimetroM'] as double;
          _currentArea = _currentAreaHa;
          _currentPerimeter = _currentPerimeterM;
          
          // Sincronizar distância GPS com o cálculo unificado
          _advancedGpsDistance = _currentDistance;
          
          _talhaoNotificationService.showSuccessMessage('✅ GPS finalizado! Área: ${_currentAreaHa.toStringAsFixed(2)} ha, Perímetro: ${_currentPerimeterM.toStringAsFixed(1)} m');
          print('✅ GPS Finalizado Unificado: ${_currentPoints.length} pontos, Área: ${_currentAreaHa.toStringAsFixed(4)} ha, Perímetro: ${_currentPerimeterM.toStringAsFixed(1)} m');
        } else {
          _talhaoNotificationService.showErrorMessage('São necessários pelo menos 3 pontos para criar um talhão');
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('❌ Controller: Erro ao finalizar GPS: $e');
      _talhaoNotificationService.showErrorMessage('Erro ao finalizar GPS: $e');
    }
  }
  
  /// Fecha o polígono automaticamente se necessário
  List<LatLng> _closePolygon(List<LatLng> points) {
    if (points.length < 3) return points;
    if (points.isEmpty) return points;
    
    final firstPoint = points.first;
    final lastPoint = points.last;
    
    // Calcular distância entre primeiro e último ponto
    final distance = GeoCalculator.haversineDistance(firstPoint, lastPoint);
    
    // Se a distância for maior que 5 metros, adicionar o primeiro ponto no final
    if (distance > 5.0) {
      final closedPoints = List<LatLng>.from(points);
      closedPoints.add(firstPoint);
      return closedPoints;
    }
    
    return points;
  }
  
  /// Callback para atualizações do LocationService
  void _onLocationServiceUpdate() {
    if (_isAdvancedGpsTracking && !_isAdvancedGpsPaused) {
      // UNIFICAÇÃO TOTAL: Usar o mesmo método do desenho manual
      _currentPoints = _locationService.points;
      _advancedGpsAccuracy = _locationService.currentAccuracy;
      
      // UNIFICADO: Usar o mesmo método _updateCurrentMetrics() do desenho manual
      _updateCurrentMetrics();
      
      // Sincronizar distância GPS com o cálculo unificado
      _advancedGpsDistance = _currentDistance;
      
      print('🔄 GPS Unificado: ${_currentPoints.length} pontos, Área: ${_currentAreaHa.toStringAsFixed(4)} ha, Perímetro: ${_currentPerimeterM.toStringAsFixed(1)} m, Velocidade: ${_currentSpeedKmh.toStringAsFixed(1)} km/h');
    }
  }
  
  /// Obtém a localização atual do dispositivo
  Future<LatLng?> getCurrentLocation() async {
    try {
      final location = await DeviceLocationService.instance.getCurrentLocation();
      if (location != null) {
        _userLocation = location;
        notifyListeners();
      }
      return location;
    } catch (e) {
      _talhaoNotificationService.showErrorMessage('❌ Erro ao obter localização: $e');
      return null;
    }
  }
  
  /// Centraliza o mapa na localização do GPS (apenas quando solicitado)
  Future<void> centerOnGPS() async {
    try {
      print('=== CONTROLLER: centerOnGPS chamado ===');
      
      // Verificar se o MapController está disponível
      if (_mapController == null) {
        _mapController = MapController();
      }
      
      // Se já temos localização do usuário, usar ela
      if (_userLocation != null) {
        print('Movendo mapa para localização existente: $_userLocation');
        _mapController!.move(_userLocation!, _zoomDefault);
        _talhaoNotificationService.showSuccessMessage('✅ Mapa centralizado na sua localização atual');
        return;
      }
      
      // Tentar obter nova localização real
      await _inicializarGPSForcado();
      
      // Verificar se conseguiu obter localização
      if (_userLocation != null && _mapController != null) {
        print('Movendo mapa para nova localização: $_userLocation');
        _mapController!.move(_userLocation!, _zoomDefault);
        _talhaoNotificationService.showSuccessMessage('✅ Mapa centralizado na sua localização real');
      } else {
        _talhaoNotificationService.showErrorMessage('❌ Não foi possível obter sua localização real. Verifique se o GPS está ativo.');
      }
    } catch (e) {
      print('Erro ao centralizar GPS: $e');
      _talhaoNotificationService.showErrorMessage('❌ Erro ao centralizar no GPS: $e');
    }
  }

  /// Inicializa o GPS de forma forçada usando DeviceLocationService
  Future<void> _inicializarGPSForcado() async {
    try {
      // Usar o DeviceLocationService para obter localização real
      final location = await DeviceLocationService.instance.getCurrentLocation();
      
      if (location != null) {
        _userLocation = location;
        notifyListeners();
        
        // NÃO centralizar automaticamente - deixar o usuário controlar
        // if (_mapController != null) {
        //   _mapController!.move(_userLocation!, _zoomDefault);
        // }
        
        _talhaoNotificationService.showSuccessMessage('✅ Localização GPS obtida com sucesso');
      } else {
        _talhaoNotificationService.showErrorMessage('❌ Não foi possível obter localização GPS');
      }
      
    } catch (e) {
      _talhaoNotificationService.showErrorMessage('❌ Erro ao obter localização GPS: $e');
    }
  }

  // ===== MÉTODOS DE CULTURA =====
  
  /// Carrega culturas disponíveis
  Future<void> _carregarCulturas() async {
    if (_isLoadingCulturas) return;
    
    setLoadingCulturas(true);
    try {
      print('🌱 Controller: Iniciando carregamento de culturas...');
      
      // Primeiro, tentar carregar do módulo Culturas da Fazenda via CultureImportService
      try {
        print('📋 Controller: Tentando carregar via CultureImportService...');
        final cultureImportService = CultureImportService();
        await cultureImportService.initialize();
        
        final culturasFazenda = await cultureImportService.getAllCrops();
        print('✅ Controller: CultureImportService retornou ${culturasFazenda.length} culturas');
        
        if (culturasFazenda.isNotEmpty) {
          // Converter para CulturaModel
          final culturasConvertidas = culturasFazenda.map((crop) => CulturaModel(
            id: crop['id']?.toString() ?? '0',
            name: crop['name'] ?? '',
            color: _obterCorPorNome(crop['name'] ?? ''),
            description: crop['description'] ?? '',
          )).toList();
          
          _culturas = culturasConvertidas;
          notifyListeners();
          
          print('✅ Controller: ${culturasConvertidas.length} culturas carregadas do CultureImportService');
          for (var cultura in culturasConvertidas) {
            print('  - ${cultura.name} (ID: ${cultura.id})');
          }
          return;
        } else {
          print('⚠️ Controller: CultureImportService retornou lista vazia');
        }
      } catch (e) {
        print('❌ Controller: Erro ao carregar do CultureImportService: $e');
      }
      
      // Segundo, tentar carregar do CropRepository como fallback
      try {
        print('📋 Controller: Tentando carregar via CropRepository como fallback...');
        final cropRepository = CropRepository();
        await cropRepository.initialize();
        
        final crops = await cropRepository.getAllCrops();
        print('✅ Controller: CropRepository retornou ${crops.length} culturas');
        
        if (crops.isNotEmpty) {
          final culturasConvertidas = crops.map((crop) => CulturaModel(
            id: crop.id.toString(),
            name: crop.name,
            color: _obterCorPorNome(crop.name),
            description: crop.description ?? '',
          )).toList();
          
          _culturas = culturasConvertidas;
          notifyListeners();
          
          print('✅ Controller: ${culturasConvertidas.length} culturas carregadas do CropRepository');
          for (var cultura in culturasConvertidas) {
            print('  - ${cultura.name} (ID: ${cultura.id})');
          }
        }
      } catch (e) {
        print('❌ Controller: Erro ao carregar do CropRepository: $e');
      }
      
      // Terceiro, usar culturas padrão se nenhuma foi carregada
      if (_culturas.isEmpty) {
        print('📋 Controller: Usando culturas padrão...');
        _culturas = _getCulturasPadrao();
        notifyListeners();
        print('✅ Controller: ${_culturas.length} culturas padrão carregadas');
      }
      
    } catch (e) {
      print('❌ Controller: Erro geral ao carregar culturas: $e');
      _talhaoNotificationService.showErrorMessage('Erro ao carregar culturas: $e');
    } finally {
      setLoadingCulturas(false);
    }
  }
  
  /// Obtém cor por nome da cultura
  Color _obterCorPorNome(String nomeCultura) {
    final cores = {
      'soja': const Color(0xFF4CAF50),
      'milho': const Color(0xFFFFC107),
      'algodão': const Color(0xFF1976D2),
      'café': const Color(0xFF8D6E63),
      'cana': const Color(0xFF795548),
      'trigo': const Color(0xFFFFEB3B),
      'arroz': const Color(0xFF2196F3),
      'feijão': const Color(0xFF8BC34A),
      'girassol': const Color(0xFFFF9800),
      'sorgo': const Color(0xFF9C27B0),
      'aveia': const Color(0xFF607D8B),
      'gergelim': const Color(0xFF3F51B5),
    };
    
    final nomeLower = nomeCultura.toLowerCase();
    return cores[nomeLower] ?? const Color(0xFF4CAF50);
  }
  
  /// Retorna lista de culturas padrão
  List<CulturaModel> _getCulturasPadrao() {
    return [
      CulturaModel(
        id: '1',
        name: 'Soja',
        color: const Color(0xFF4CAF50),
        description: 'Cultura de soja',
      ),
      CulturaModel(
        id: '2',
        name: 'Milho',
        color: const Color(0xFFFFC107),
        description: 'Cultura de milho',
      ),
      CulturaModel(
        id: '3',
        name: 'Algodão',
        color: const Color(0xFF1976D2),
        description: 'Cultura de algodão',
      ),
      CulturaModel(
        id: '4',
        name: 'Café',
        color: const Color(0xFF8D6E63),
        description: 'Cultura de café',
      ),
      CulturaModel(
        id: '5',
        name: 'Cana',
        color: const Color(0xFF795548),
        description: 'Cultura de cana',
      ),
      CulturaModel(
        id: '6',
        name: 'Trigo',
        color: const Color(0xFFFFEB3B),
        description: 'Cultura de trigo',
      ),
    ];
  }

  /// Define a cultura selecionada
  void setSelectedCultura(CulturaModel? cultura) {
    _selectedCultura = cultura;
    notifyListeners();
  }
  
  /// Recarrega as culturas (método público)
  Future<void> recarregarCulturas() async {
    await _carregarCulturas();
  }
  
  /// Define as culturas (método público)
  void setCulturas(List<CulturaModel> culturas) {
    _culturas = culturas;
    notifyListeners();
  }

  /// Define o estado de carregamento de culturas
  void setLoadingCulturas(bool loading) {
    _isLoadingCulturas = loading;
    notifyListeners();
  }

  // ===== MÉTODOS DE TALHÕES =====
  
  /// Carrega talhões existentes
  Future<void> _carregarTalhoesExistentes() async {
    try {
      Logger.info('🔄 [TALHOES] Carregando talhões existentes via serviço unificado...');
      
      // Usar o serviço unificado para carregar talhões
      final talhoes = await _talhaoUnifiedService.getAllTalhoes();
      
      Logger.info('✅ [TALHOES] ${talhoes.length} talhões carregados com sucesso');
      
      _talhoes = talhoes;
      _existingTalhoes = talhoes;
      notifyListeners();
      
    } catch (e) {
      Logger.error('❌ [TALHOES] Erro ao carregar talhões: $e');
      _talhaoNotificationService.showErrorMessage('Erro ao carregar talhões: $e');
    }
  }

  /// Recarrega talhões
  Future<void> reloadTalhoes() async {
    await _carregarTalhoesExistentes();
  }

  // ===== MÉTODOS DE DESENHO =====
  
  /// Inicia desenho manual
  void startManualDrawing() {
    _isDrawing = true;
    _showActionButtons = true;
    _currentPoints.clear();
    notifyListeners();
  }

  /// Finaliza desenho manual
  void finishManualDrawing() {
    _isDrawing = false;
    _showActionButtons = false;
    notifyListeners();
  }

  /// Adiciona ponto manual
  void addManualPoint(LatLng point) {
    // CORREÇÃO: Desabilitar desenho manual durante GPS
    if (_isAdvancedGpsTracking) {
      print('⚠️ Controller: Desenho manual desabilitado durante GPS ativo');
      _talhaoNotificationService.showInfoMessage('Desenho manual desabilitado durante GPS. Use o botão "Parar GPS" para finalizar o rastreamento.');
      return;
    }
    
    _currentPoints.add(point);
    _updateCurrentMetrics();
    notifyListeners();
  }
  
  /// Função unificada para atualizar métricas em tempo real
  /// Usada tanto para desenho manual quanto para GPS
  void _updateCurrentMetrics() {
    print('🔄 Controller: Atualizando métricas para ${_currentPoints.length} pontos');
    
    // Calcular distância total percorrida (sempre)
    _currentDistance = _calculateTotalDistance();
    
    // Calcular velocidade se temos pontos suficientes
    if (_currentPoints.length >= 2 && _trackingStartTime != null) {
      // Usar o tempo decorrido total para calcular velocidade média
      final now = DateTime.now();
      final totalTime = now.difference(_trackingStartTime!);
      if (totalTime.inSeconds > 0) {
        // Calcular distância total percorrida
        final totalDistance = _calculateTotalDistance();
        // Velocidade média = distância total / tempo total
        final speedMs = totalDistance / totalTime.inSeconds;
        _currentSpeedKmh = GeoCalculator.metersPerSecondToKmh(speedMs);
      }
    }
    
    // Atualizar tempo decorrido
    if (_trackingStartTime != null) {
      _elapsedTime = DateTime.now().difference(_trackingStartTime!);
    }
    
    // CORREÇÃO: Usar TalhaoCalculator unificado para qualquer número de pontos
    if (_currentPoints.length >= 3) {
      try {
        // Usar o novo método principal calcularTalhao
        final resultado = TalhaoCalculator.calcularTalhao(
          _currentPoints,
          suavizar: _isAdvancedGpsTracking, // Suavizar apenas para GPS
          geodesico: false, // Por enquanto usar cálculo plano
        );
        
        _currentAreaHa = resultado['areaHa'] as double;
        _currentPerimeterM = resultado['perimetroM'] as double;
        
        // Atualizar área e perímetro no controller (compatibilidade)
        _currentArea = _currentAreaHa;
        _currentPerimeter = _currentPerimeterM;
        
        print('✅ Controller: Métricas atualizadas - Área: ${_currentAreaHa.toStringAsFixed(4)} ha, Perímetro: ${_currentPerimeterM.toStringAsFixed(1)} m');
      } catch (e) {
        print('❌ Controller: Erro ao calcular métricas: $e');
        _currentAreaHa = 0.0;
        _currentPerimeterM = 0.0;
        _currentArea = 0.0;
        _currentPerimeter = 0.0;
      }
    } else {
      // Para menos de 3 pontos, zerar área e perímetro
      _currentAreaHa = 0.0;
      _currentPerimeterM = 0.0;
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
    }
    
    print('📊 Controller: Métricas atualizadas - Área: ${_currentAreaHa.toStringAsFixed(2)} ha, Perímetro: ${_currentPerimeterM.toStringAsFixed(1)} m, Velocidade: ${_currentSpeedKmh.toStringAsFixed(1)} km/h, Pontos: ${_currentPoints.length}');
    
    notifyListeners();
  }

  /// Calcula a distância total percorrida
  double _calculateTotalDistance() {
    if (_currentPoints.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < _currentPoints.length; i++) {
      totalDistance += GeoCalculator.haversineDistance(
        _currentPoints[i - 1],
        _currentPoints[i],
      );
    }
    return totalDistance;
  }


  /// Define os pontos atuais
  void setCurrentPoints(List<LatLng> points) {
    _currentPoints = List.from(points);
    _updateCurrentMetrics();
    notifyListeners();
  }

  /// Move um ponto para uma nova posição
  void movePoint(int index, LatLng newPosition) {
    if (index >= 0 && index < _currentPoints.length) {
      _currentPoints[index] = newPosition;
      _updateCurrentMetrics();
      notifyListeners();
    }
  }

  /// Define se deve mostrar os botões de ação
  void setShowActionButtons(bool show) {
    _showActionButtons = show;
    notifyListeners();
  }


  /// Define a área atual
  void setCurrentArea(double area) {
    _currentArea = area;
    notifyListeners();
  }

  /// Define a distância atual
  void setCurrentDistance(double distance) {
    _currentDistance = distance;
    notifyListeners();
  }

  /// Define o perímetro atual
  void setCurrentPerimeter(double perimeter) {
    _currentPerimeter = perimeter;
    notifyListeners();
  }


  // ===== MÉTODOS DE RASTREAMENTO GPS =====
  
  /// Inicia rastreamento GPS avançado
  Future<void> startAdvancedGpsTracking() async {
    try {
      if (!_isAdvancedGpsTracking) {
        await _advancedGpsService.startTracking(
          onAccuracyChanged: (accuracy) {
            _advancedGpsAccuracy = accuracy;
            notifyListeners();
          },
          onDistanceChanged: (distance) {
            _advancedGpsDistance = distance;
            notifyListeners();
          },
          onPointsChanged: (points) {
            // Atualizar pontos se necessário
            notifyListeners();
          },
          onStatusChanged: (status) {
            _advancedGpsStatus = status;
            notifyListeners();
          },
          onTrackingStateChanged: (isTracking) {
            _isAdvancedGpsTracking = isTracking;
            notifyListeners();
          },
        );
        _isAdvancedGpsTracking = true;
        _isAdvancedGpsPaused = false;
        _trackingStartTime = DateTime.now();
        _gpsStartTime = DateTime.now();
        _advancedGpsStatus = 'Rastreamento ativo';
        notifyListeners();
      }
    } catch (e) {
      _talhaoNotificationService.showErrorMessage('Erro ao iniciar rastreamento GPS avançado: $e');
    }
  }

  /// Inicia rastreamento GPS aprimorado com background
  Future<void> startEnhancedGpsTracking({
    required String talhaoId,
    required String talhaoNome,
    int minDistanceMeters = 2,
    int updateIntervalMs = 1000,
    bool enableSmoothing = true,
    bool enableBackground = true,
  }) async {
    try {
      if (!_isAdvancedGpsTracking) {
        final success = await _enhancedGpsProvider.startTracking(
          talhaoId: talhaoId,
          talhaoNome: talhaoNome,
          minDistanceMeters: minDistanceMeters,
          updateIntervalMs: updateIntervalMs,
          enableSmoothing: enableSmoothing,
          enableBackground: enableBackground,
        );
        
        if (success) {
          _isAdvancedGpsTracking = true;
          _isAdvancedGpsPaused = false;
          _trackingStartTime = DateTime.now();
          _gpsStartTime = DateTime.now();
          _advancedGpsStatus = 'Rastreamento aprimorado iniciado';
          _advancedGpsAccuracy = 0.0;
          _advancedGpsDistance = 0.0;
          _totalDistance = 0.0;
          _currentPoints.clear();
          _elapsedTime = Duration.zero;
          
          // Configurar listeners para atualizações em tempo real
          _setupEnhancedGpsListeners();
          
          notifyListeners();
        } else {
          _advancedGpsStatus = 'Falha ao iniciar rastreamento aprimorado';
          notifyListeners();
        }
      }
    } catch (e) {
      _advancedGpsStatus = 'Erro ao iniciar rastreamento aprimorado: $e';
      notifyListeners();
    }
  }

  /// Configura listeners para o GPS aprimorado
  void _setupEnhancedGpsListeners() {
    // Listener para posições atuais
    _enhancedGpsProvider.addListener(() {
      if (_enhancedGpsProvider.currentPosition != null) {
        final position = _enhancedGpsProvider.currentPosition!;
        _advancedGpsAccuracy = position.accuracy;
        _lastGpsUpdate = DateTime.now();
        
        // Atualizar pontos se não estiver pausado
        if (!_isAdvancedGpsPaused) {
          final newPoint = LatLng(position.latitude, position.longitude);
          _currentPoints.add(newPoint);
          _updateRealTimeCalculations();
        }
        
        notifyListeners();
      }
    });
  }

  /// Atualiza cálculos em tempo real (área, perímetro, distância)
  void _updateRealTimeCalculations() {
    if (_currentPoints.length < 3) return;
    
    try {
      // Calcular área usando TalhaoCalculator
      _currentArea = TalhaoCalculator.calcularAreaHectares(_currentPoints);
      _currentAreaHa = _currentArea;
      
      // Calcular perímetro
      _currentPerimeter = TalhaoCalculator.calcularPerimetro(_currentPoints);
      _currentPerimeterM = _currentPerimeter;
      
      // Calcular distância total percorrida
      if (_currentPoints.length > 1) {
        double totalDistance = 0.0;
        for (int i = 1; i < _currentPoints.length; i++) {
          totalDistance += _calculateDistance(_currentPoints[i-1], _currentPoints[i]);
        }
        _currentDistance = totalDistance;
        _totalDistance = totalDistance;
      }
      
      // Atualizar tempo decorrido
      if (_trackingStartTime != null) {
        _elapsedTime = DateTime.now().difference(_trackingStartTime!);
      }
      
    } catch (e) {
      debugPrint('Erro ao calcular métricas em tempo real: $e');
    }
  }

  /// Calcula distância entre dois pontos em metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Pausa rastreamento GPS avançado
  void pauseAdvancedGpsTracking() {
    if (_isAdvancedGpsTracking && !_isAdvancedGpsPaused) {
      _advancedGpsService.pauseTracking();
      _isAdvancedGpsPaused = true;
      _lastPointBeforePause = _currentPoints.isNotEmpty ? _currentPoints.last : null;
      _advancedGpsStatus = 'Rastreamento pausado';
      notifyListeners();
    }
  }
  
  /// Retoma rastreamento GPS avançado
  void resumeAdvancedGpsTracking() {
    if (_isAdvancedGpsTracking && _isAdvancedGpsPaused) {
      _advancedGpsService.resumeTracking();
      _isAdvancedGpsPaused = false;
      _advancedGpsStatus = 'Rastreamento retomado';
      notifyListeners();
    }
  }

  /// Finaliza rastreamento GPS avançado
  Future<void> finishAdvancedGpsTracking() async {
    try {
      if (_isAdvancedGpsTracking) {
        await _advancedGpsService.stopTracking();
        await _enhancedGpsProvider.stopTracking();
        _isAdvancedGpsTracking = false;
        _isAdvancedGpsPaused = false;
        _trackingEndTime = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      _talhaoNotificationService.showErrorMessage('Erro ao finalizar rastreamento GPS avançado: $e');
    }
  }

  // ===== MÉTODOS DE GPS SIMPLES =====
  

  // ===== MÉTODOS DE SALVAMENTO =====
  
  /// Define o estado de salvamento
  void setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  /// Define o nome do polígono
  void setPolygonName(String name) {
    _polygonName = name;
    notifyListeners();
  }

  // ===== MÉTODOS DE DEBUG =====
  
  /// Debug dos talhões
  void debugTalhoes() {
    Logger.info('🔍 DEBUG: === ESTADO DOS TALHÕES ===');
    Logger.info('🔍 DEBUG: Total de talhões: ${_talhoes.length}');
    
    for (int i = 0; i < _talhoes.length; i++) {
      final talhao = _talhoes[i];
      Logger.info('🔍 DEBUG: Talhão $i: ${talhao.name}');
      Logger.info('🔍 DEBUG:   - ID: ${talhao.id}');
      Logger.info('🔍 DEBUG:   - Tipo: ${talhao.runtimeType}');
      Logger.info('🔍 DEBUG:   - Polígonos: ${talhao.poligonos.length}');
    }
  }

  // ===== MÉTODOS DE DESENHO =====
  
  /// Inicia o desenho manual
  void startDrawing() {
    print('=== CONTROLLER: startDrawing ===');
    print('_isDrawing antes: $_isDrawing');
    _isDrawing = true;
    _currentPoints.clear();
    _currentAreaHa = 0.0;
    _currentPerimeterM = 0.0;
    print('_isDrawing depois: $_isDrawing');
    print('_currentPoints.length: ${_currentPoints.length}');
    notifyListeners();
    print('notifyListeners() chamado');
  }

  /// Adiciona ponto ao desenho atual
  void addPoint(LatLng point) {
    print('=== CONTROLLER: addPoint ===');
    print('Ponto recebido: $point');
    print('_isDrawing: $_isDrawing');
    print('_currentPoints.length antes: ${_currentPoints.length}');
    
    _currentPoints.add(point);
    _lastGpsUpdate = DateTime.now();
    
    print('_currentPoints.length depois: ${_currentPoints.length}');
    
    // Iniciar timer se for o primeiro ponto
    if (_currentPoints.length == 1) {
      _trackingStartTime = DateTime.now();
      print('Timer iniciado');
    }
    
    _updateCurrentMetrics();
    notifyListeners();
    print('Ponto adicionado e notifyListeners() chamado');
  }

  /// Remove último ponto
  void undoLastPoint() {
    if (_currentPoints.isNotEmpty) {
      _currentPoints.removeLast();
      _updateCurrentMetrics();
      notifyListeners();
    }
  }

  /// Limpa o desenho atual
  void clearDrawing() {
    _currentPoints.clear();
    _currentAreaHa = 0.0;
    _currentPerimeterM = 0.0;
    _isDrawing = false;
    notifyListeners();
  }

  /// Finaliza o desenho
  void finishDrawing() {
    _isDrawing = false;
    notifyListeners();
  }

  /// Atualiza localização atual
  void updateCurrentLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
  }


  /// Salva talhão atual
  Future<void> saveCurrentTalhao() async {
    try {
      if (_currentPoints.length < 3) {
        _talhaoNotificationService.showErrorMessage('Adicione pelo menos 3 pontos para criar um talhão');
        return;
      }

      if (_selectedCultura == null) {
        _talhaoNotificationService.showErrorMessage('Selecione uma cultura para o talhão');
        return;
      }

      // Criar polígono
      final poligono = PoligonoModel(
        id: const Uuid().v4(),
        pontos: _currentPoints,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: _currentAreaHa,
        perimetro: _currentPerimeterM,
        talhaoId: const Uuid().v4(), // Será substituído pelo ID do talhão
      );

      // Criar talhão
      final talhao = TalhaoModel(
        id: const Uuid().v4(),
        name: _polygonName.isNotEmpty ? _polygonName : 'Talhão ${_existingTalhoes.length + 1}',
        poligonos: [poligono],
        area: _currentAreaHa,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        safras: [],
        culturaId: _selectedCultura!.id,
      );

      // Salvar talhão
      await _talhaoModuleService.saveTalhao(talhao);
      
      // Adicionar à lista local
      _existingTalhoes.add(talhao);
      
      // Limpar desenho atual
      clearDrawing();
      _polygonName = '';
      
      _talhaoNotificationService.showSuccessMessage('✅ Talhão salvo com sucesso!');
      notifyListeners();
      
    } catch (e) {
      _talhaoNotificationService.showErrorMessage('❌ Erro ao salvar talhão: $e');
    }
  }

  /// Adiciona talhão existente
  void addExistingTalhao(TalhaoModel talhao) {
    _existingTalhoes.add(talhao);
    notifyListeners();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
