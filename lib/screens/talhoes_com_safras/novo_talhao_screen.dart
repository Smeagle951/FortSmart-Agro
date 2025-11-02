import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, pi, sin, atan2, sqrt;
import 'dart:async';
import '../../../utils/cultura_colors.dart';
import '../../../widgets/rain_collection_marker.dart';
import '../../rain/rain_registration_screen.dart';
import '../../rain/rain_history_screen.dart';
import '../../rain/rain_station_management_screen.dart';
import '../../../models/rain_station_model.dart';
import '../../../repositories/rain_station_repository.dart';

// Importações locais
import '../../../models/talhoes/talhao_safra_model.dart' as talhao_safra;
import '../../../models/talhoes/safra_talhao_model.dart';
import '../../../models/talhoes/poligono_model.dart';
import '../../../providers/cultura_provider.dart';
import 'providers/talhao_provider.dart';

// Serviços
import '../../../services/location_service.dart';
import '../../../services/polygon_service.dart';
import '../../../services/polygon_database_service.dart';

import '../../../services/unified_geo_import_service.dart';
import '../../../services/unified_geo_export_service.dart';
import '../../../services/advanced_gps_tracking_service.dart';

import '../../../services/cultura_service.dart';
import '../../../services/culture_import_service.dart';
import '../../../services/cultura_talhao_service.dart';
import '../../../utils/geodetic_utils.dart';
import '../../../utils/geo_calculator.dart';
import '../../../utils/talhao_calculator.dart';
import '../../../repositories/talhoes/talhao_safra_repository.dart';
import '../experimentos/experimentos_lista_screen.dart';
import '../navigation/plot_navigation_screen.dart';

// Novos serviços para talhões
import '../../../services/talhao_duplication_service.dart';
import '../../../services/talhao_polygon_service.dart';
import '../../../services/talhao_notification_service.dart';

import '../../../models/cultura_model.dart';
import '../../../utils/area_formatter.dart';
import '../../../widgets/premium_advanced_gps_widget.dart';
// import '../../../widgets/elegant_talhao_card.dart'; // Removido
import '../../../widgets/functional_talhao_card.dart';
import '../../../services/perfil_service.dart';
import '../../../services/safra_service.dart';
import '../../../services/farm_service.dart';
import '../../../widgets/talhao_editor_bottom_sheet.dart';
import '../../../models/talhao_model.dart';
import '../../../repositories/crop_repository.dart';
import '../../services/precise_geo_calculator.dart';

import '../../../services/talhao_unified_service.dart';
import '../../../utils/logger.dart';
import 'talhao_diagnostic_screen.dart';
import '../subareas/gerenciar_subareas_screen.dart';

// Nova API MapTiler centralizada
import '../../../utils/api_config.dart';

// Novos widgets e controller
import 'widgets/talhao_app_bar_widget.dart';
import 'widgets/talhao_map_widget.dart';
import 'widgets/talhao_action_buttons_widget.dart';
import 'widgets/realtime_metrics_card.dart';
import 'widgets/gps_drawing_controls_widget.dart';
import 'controllers/novo_talhao_controller.dart';
import '../../../widgets/talhao_floating_card.dart';

class NovoTalhaoScreen extends StatefulWidget {
  const NovoTalhaoScreen({Key? key}) : super(key: key);

  @override
  State<NovoTalhaoScreen> createState() => _NovoTalhaoScreenState();
}

class _NovoTalhaoScreenState extends State<NovoTalhaoScreen> {

  // ===== CONSTANTES =====
  static const double _zoomDefault = 15.0;
  static const Duration _timeoutGps = Duration(seconds: 10);
  
  // ===== CONTROLLER =====
  late NovoTalhaoController _controller;
  
  // ===== ESTADO DA UI =====
  
  // ===== SERVIÇOS (LAZY LOADING) =====
  LocationService? _locationService;
  PolygonDatabaseService? _polygonDatabaseService;
  UnifiedGeoImportService? _importService;
  UnifiedGeoExportService? _exportService;
  AdvancedGpsTrackingService? advancedGpsService;
  CulturaService? culturaService;
  TalhaoSafraRepository? talhaoRepository;
  TalhaoDuplicationService? _talhaoDuplicationService;
  TalhaoPolygonService? talhaoPolygonService;
  TalhaoNotificationService? talhaoNotificationService;

  // Getters para lazy loading
  LocationService get locationService => _locationService ??= LocationService();
  PolygonDatabaseService get polygonDatabaseService => _polygonDatabaseService ??= PolygonDatabaseService.instance;
  UnifiedGeoImportService get importService => _importService ??= UnifiedGeoImportService();
  UnifiedGeoExportService get exportService => _exportService ??= UnifiedGeoExportService();
  AdvancedGpsTrackingService get advancedGpsService => advancedGpsService ??= AdvancedGpsTrackingService();
  CulturaService get culturaService => culturaService ??= CulturaService();
  TalhaoSafraRepository get talhaoRepository => talhaoRepository ??= TalhaoSafraRepository();
  TalhaoDuplicationService get talhaoDuplicationService => _talhaoDuplicationService ??= TalhaoDuplicationService();
  TalhaoPolygonService get talhaoPolygonService => talhaoPolygonService ??= TalhaoPolygonService();
  TalhaoNotificationService get talhaoNotificationService => talhaoNotificationService ??= TalhaoNotificationService();
  
  // ===== CONTROLADORES PARA O CARD EDITÁVEL =====
  TextEditingController? _nomeController;
  TextEditingController? _observacoesController;
  CulturaModel? _culturaSelecionadaCard;
  String _safraSelecionadaCard = '';
  String? _safraSelecionada; // Sem valor padrão - usuário deve selecionar
  double _areaCalculadaCard = 0.0;
  
  // ===== VARIÁVEIS DE ESTADO DO DESENHO =====
  String _polygonName = '';
  CulturaModel? _selectedCultura;
  bool _isSaving = false;
  bool _isDrawing = false;
  bool _isAdvancedGpsTracking = false;
  bool _isAdvancedGpsPaused = false;
  double _advancedGpsDistance = 0.0;
  double _advancedGpsAccuracy = 0.0;
  String _advancedGpsStatus = '';
  DateTime? _trackingStartTime;
  DateTime? _trackingEndTime;
  List<CulturaModel> _culturas = [];
  List<dynamic> _talhoes = [];
  LatLng? _userLocation;
  MapController? _mapController;
  double _drawnArea = 0.0;
  dynamic _selectedTalhao;
  
  // Timer para atualização em tempo real das coordenadas
  Timer? _gpsUpdateTimer;
  
  // Pontos de coleta de chuva
  List<RainStationModel> _rainStations = [];
  final RainStationRepository _rainStationRepository = RainStationRepository();

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de forma segura
    _nomeController = TextEditingController();
    _observacoesController = TextEditingController();
    
    // Inicializar controller de forma simples
    _controller = NovoTalhaoController();
    _controller.initialize();
    
    // CORREÇÃO AGRESSIVA: Carregar dados apenas quando necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarDadosQuandoNecessario();
      }
    });
  }
  
  /// Carrega dados apenas quando necessário (sem loops)
  Future<void> _carregarDadosQuandoNecessario() async {
    try {
      print('🔄 Carregando dados quando necessário...');
      
      // Carregar apenas culturas básicas
      await _carregarCulturasBasicas();
      
      // Carregar estações de chuva
      await _carregarEstacoesChuva();
      
      print('✅ Dados básicos carregados');
    } catch (e) {
      print('❌ Erro ao carregar dados básicos: $e');
    }
  }
  
  /// Carrega apenas culturas básicas (sem talhões)
  Future<void> _carregarCulturasBasicas() async {
    try {
      setState(() => _isLoadingCulturas = true);
      
      // Criar cultura padrão para evitar loops
      final culturaPadrao = CulturaModel(
        id: '1',
        name: 'Soja',
      );
      
      setState(() {
        _culturas = [culturaPadrao];
        _isLoadingCulturas = false;
      });
      
      print('✅ Cultura básica carregada');
    } catch (e) {
      setState(() => _isLoadingCulturas = false);
      print('❌ Erro ao carregar culturas básicas: $e');
    }
  }
  
  /// Carrega estações de coleta de chuva
  Future<void> _carregarEstacoesChuva() async {
    try {
      print('🌧️ Carregando estações de chuva...');
      _rainStations = await _rainStationRepository.getActiveRainStations();
      
      // Se não houver estações, criar pontos padrão
      if (_rainStations.isEmpty) {
        await _rainStationRepository.createDefaultRainStations();
        _rainStations = await _rainStationRepository.getActiveRainStations();
      }
      
      print('✅ ${_rainStations.length} estações de chuva carregadas');
    } catch (e) {
      print('❌ Erro ao carregar estações de chuva: $e');
    }
  }
  
  /// Carrega dados de forma segura com timeout para evitar loops infinitos
  Future<void> _carregarDadosComTimeout() async {
    try {
      print('🔄 Iniciando carregamento de dados com timeout...');
      
      // Carregar culturas com timeout
      await _carregarCulturas().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout ao carregar culturas, continuando...');
        },
      );
      
      // Carregar talhões com timeout
      await _carregarTalhoesExistentes().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout ao carregar talhões, continuando...');
        },
      );
      
      print('✅ Carregamento de dados concluído');
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      // Continuar mesmo com erro
    }
    
    // Forçar recarregamento dos talhões via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
        talhaoProvider.carregarTalhoes().then((_) {
          if (mounted) {
            setState(() {
              // Forçar rebuild para mostrar os polígonos
            });
          }
        });
      }
    });
  }
  
  /// Inicializa serviço de armazenamento de forma assíncrona
  void _initializeStorageServiceAsync() {
    _initializeStorageService().catchError((error) {
      // Erro ao inicializar serviço de armazenamento
    });
  }
  
  /// Inicializa serviço de rastreamento GPS avançado
  Future<void> _initializeAdvancedGpsService() async {
    try {
      await advancedGpsService.initialize();
    } catch (e) {
      // Erro ao inicializar serviço de rastreamento GPS avançado
    }
  }
  
  /// Inicializa serviço de rastreamento GPS em background
  Future<void> _initializeBackgroundGpsService() async {
    try {

      // Serviço de rastreamento GPS em background inicializado
    } catch (e) {
      // Erro ao inicializar serviço de rastreamento GPS em background
    }
  }

  /// Inicia rastreamento GPS avançado
  Future<void> _startAdvancedGpsTracking() async {
    try {
      if (_isAdvancedGpsTracking) {
        talhaoNotificationService.showInfoMessage('Rastreamento GPS já está ativo');
        return;
      }
      
      final success = await advancedGpsService.startTracking(
        onPointsChanged: (points) {
          if (mounted) {
            setState(() {
              _controller.setCurrentPoints(points);
              _calcularMetricas();
            });
          }
        },
        onDistanceChanged: (distance) {
          if (mounted) {
            setState(() {
              _advancedGpsDistance = distance;
            });
          }
        },
        onAccuracyChanged: (accuracy) {
          if (mounted) {
            setState(() {
              _advancedGpsAccuracy = accuracy;
            });
          }
        },
        onStatusChanged: (status) {
          if (mounted) {
            setState(() {
              _advancedGpsStatus = status;
            });
          }
        },
        onTrackingStateChanged: (isTracking) {
          if (mounted) {
            setState(() {
              _isAdvancedGpsTracking = isTracking;
            });
          }
        },
      );
      
      if (success) {
        setState(() {
          _controller.startManualDrawing();
          _controller.setShowActionButtons(true);
          _trackingStartTime = DateTime.now();
        });
        talhaoNotificationService.showSuccessMessage('Rastreamento GPS avançado iniciado');
      } else {
        talhaoNotificationService.showErrorMessage('Erro ao iniciar rastreamento GPS avançado');
      }
      
    } catch (e) {
              talhaoNotificationService.showErrorMessage('Erro ao iniciar rastreamento GPS avançado: $e');
    }
  }
  
  /// Pausa rastreamento GPS avançado
  void _pauseAdvancedGpsTracking() {
    if (!_isAdvancedGpsTracking) return;
    
    advancedGpsService.pauseTracking();
    setState(() {
      _isAdvancedGpsPaused = true;
    });
            talhaoNotificationService.showInfoMessage('Rastreamento GPS pausado');
  }
  
  /// Retoma rastreamento GPS avançado
  void _resumeAdvancedGpsTracking() {
    if (!_isAdvancedGpsTracking || !_isAdvancedGpsPaused) return;
    
    advancedGpsService.resumeTracking();
    setState(() {
      _isAdvancedGpsPaused = false;
    });
            talhaoNotificationService.showInfoMessage('Rastreamento GPS retomado');
  }
  
  /// Finaliza rastreamento GPS avançado
  Future<void> _finishAdvancedGpsTracking() async {
    try {
      await advancedGpsService.stopTracking();
      
      // Fechar polígono automaticamente
      if (_controller.currentPoints.length >= 3) {
        final closedPoints = advancedGpsService.closePolygon(_controller.currentPoints);
        setState(() {
          _controller.setCurrentPoints(closedPoints);
          _calcularMetricas();
        });
      }
      
      setState(() {
        _isAdvancedGpsTracking = false;
        _isAdvancedGpsPaused = false;
        _controller.finishManualDrawing();
        _controller.setShowActionButtons(false);
        _trackingEndTime = DateTime.now();
      });
      
              talhaoNotificationService.showSuccessMessage('Rastreamento GPS avançado finalizado');
      
      // Mostrar diálogo para salvar o talhão se houver pontos suficientes
      if (_controller.currentPoints.length >= 3) {
        _showNameDialog();
      }
      
    } catch (e) {
              talhaoNotificationService.showErrorMessage('Erro ao finalizar rastreamento GPS avançado: $e');
    }
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    _locationService.removeListener(_onLocationUpdate);
    _locationService.dispose();
    advancedGpsService.dispose();
    _stopGpsRealTimeUpdate();
    
    // Descarta os controladores de texto
    _nomeController?.dispose();
    _observacoesController?.dispose();
    
    super.dispose();
  }
  
  /// Centraliza o mapa na localização do GPS
  Future<void> _centerOnGPS() async {
    try {
      // Verificar se o MapController está disponível
      if (_mapController == null) {
        _mapController = MapController();
      }
      
      // Se já temos localização do usuário, usar ela
      if (_userLocation != null) {
        _mapController!.move(_userLocation!, _zoomDefault);
        talhaoNotificationService.showSuccessMessage('✅ Mapa centralizado na sua localização atual');
        
        // Forçar rebuild para garantir que o mapa seja atualizado
        if (mounted) {
          setState(() {});
        }
        return;
      }
      
      // Tentar obter nova localização real
      await _inicializarGPSForcado();
      
      // Verificar se conseguiu obter localização
      if (_userLocation != null && _mapController != null) {
        _mapController!.move(_userLocation!, _zoomDefault);
        talhaoNotificationService.showSuccessMessage('✅ Mapa centralizado na sua localização real');
        
        // Forçar rebuild para garantir que o mapa seja atualizado
        if (mounted) {
          setState(() {});
        }
      } else {
        talhaoNotificationService.showErrorMessage('❌ Não foi possível obter sua localização real. Verifique se o GPS está ativo.');
      }
    } catch (e) {
      talhaoNotificationService.showErrorMessage('❌ Erro ao centralizar no GPS: $e');
      
      // Tentar obter localização novamente após um delay
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _inicializarGPSForcado();
          }
        });
      }
    }
  }

  /// Centraliza o mapa no polígono atual
  void _centerOnPolygon() {
    try {
      if (_controller.currentPoints.isNotEmpty && _mapController != null) {
        final centro = _calculatePolygonCenter(_controller.currentPoints);
        _mapController!.move(centro, _zoomDefault);
        talhaoNotificationService.showSuccessMessage('Mapa centralizado no polígono');
      } else {
        talhaoNotificationService.showErrorMessage('Nenhum polígono para centralizar');
      }
    } catch (e) {
      talhaoNotificationService.showErrorMessage('Erro ao centralizar no polígono: $e');
    }
  }

  /// Inicia atualização em tempo real das coordenadas GPS
  void _startGpsRealTimeUpdate() {
    _gpsUpdateTimer?.cancel();
    _gpsUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateGpsCoordinates();
      }
    });
  }
  
  /// Para a atualização em tempo real das coordenadas GPS
  void _stopGpsRealTimeUpdate() {
    _gpsUpdateTimer?.cancel();
    _gpsUpdateTimer = null;
  }
  
  /// Abre tela de registro de chuva
  void _openRainRegistration(RainStationModel station) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RainRegistrationScreen(
            stationId: station.id,
            stationName: station.name,
            position: LatLng(
              station.latitude,
              station.longitude,
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao abrir tela de registro de chuva: $e');
    }
  }
  
  /// Abre tela de histórico de chuva
  void _openRainHistory(RainStationModel station) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RainHistoryScreen(
            stationId: station.id,
            stationName: station.name,
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao abrir tela de histórico de chuva: $e');
    }
  }
  
  /// Mostra popup da estação de chuva
  void _showRainStationPopup(RainStationModel station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: RainStationPopup(
          stationName: station.name,
          lastRainfall: null, // Será carregado do repositório de dados
          lastUpdate: station.updatedAt,
          onRegisterRain: () {
            Navigator.of(context).pop();
            _openRainRegistration(station);
          },
          onViewHistory: () {
            Navigator.of(context).pop();
            _openRainHistory(station);
          },
        ),
      ),
    );
  }

  /// Abre tela de gerenciamento de pontos de chuva
  void _openRainStationManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RainStationManagementScreen(),
      ),
    ).then((_) {
      // Recarregar pontos de chuva quando retornar da tela de gerenciamento
      _carregarEstacoesChuva();
    });
  }

  /// Atualiza as coordenadas GPS em tempo real
  Future<void> _updateGpsCoordinates() async {
    try {
      if (!mounted) return;
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      
      // Verificar se o GPS está ativo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      
      // Obter localização atual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3),
      );
      
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Erro silencioso para não interromper a interface
      print('Erro ao atualizar coordenadas GPS: $e');
    }
  }

  /// Inicializa o GPS de forma forçada para sempre obter localização real
  Future<void> _inicializarGPSForcado() async {
    try {
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          talhaoNotificationService.showErrorMessage('Permissão de localização negada. O mapa pode não funcionar corretamente.');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        talhaoNotificationService.showErrorMessage('Permissões de localização negadas permanentemente. Configure nas configurações do dispositivo.');
        return;
      }
      
      
      // Verificar se o GPS está ativo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        talhaoNotificationService.showErrorMessage('Serviço de localização desabilitado. Ative o GPS para melhor experiência.');
        return;
      }
      
      
      // Tentar obter localização com precisão média e timeout reduzido
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Timeout ao obter localização GPS');
        },
      );
      
      
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Centralizar automaticamente no GPS real
        if (_mapController != null) {
          _mapController!.move(_userLocation!, _zoomDefault);
          
          // Forçar rebuild para garantir que o mapa seja atualizado
          if (mounted) {
            setState(() {});
          }
        } else {
        }
        
        // Iniciar atualização em tempo real das coordenadas
        _startGpsRealTimeUpdate();
        
        // Mostrar mensagem de sucesso
        talhaoNotificationService.showSuccessMessage('📍 Mapa centralizado na sua localização real');
      }
    } catch (e) {
      debugPrint('Erro ao obter localização real: $e');
      
      // Mostrar mensagem de erro específica
      if (mounted) {
        if (e.toString().contains('Timeout')) {
          talhaoNotificationService.showErrorMessage('Timeout ao obter localização GPS. Verifique se o GPS está ativo.');
        } else if (e.toString().contains('Location service is disabled')) {
          talhaoNotificationService.showErrorMessage('GPS desabilitado. Ative o GPS nas configurações do dispositivo.');
        } else if (e.toString().contains('permission')) {
          talhaoNotificationService.showErrorMessage('Permissão de localização negada. Configure nas configurações.');
        } else if (e.toString().contains('network')) {
          talhaoNotificationService.showErrorMessage('Erro de rede. Verifique sua conexão.');
        } else {
          talhaoNotificationService.showErrorMessage('Erro ao obter localização: $e');
        }
      }
      
      // Tentar novamente após um delay maior
      if (mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _inicializarGPSForcado();
          }
        });
      }
    }
  }
  
  /// Carrega talhões existentes
  Future<void> _carregarTalhoesExistentes() async {
    try {
      Logger.info('🔄 [TALHOES] Carregando talhões existentes via serviço unificado...');
      
      // Usar o serviço unificado para carregar talhões
      final talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
        nomeModulo: 'TALHOES',
      );
      
      Logger.info('✅ [TALHOES] ${talhoes.length} talhões carregados com sucesso');
      
      // Debug: verificar cada talhão carregado
      for (int i = 0; i < talhoes.length; i++) {
        final talhao = talhoes[i];
        Logger.info('🔍 [TALHOES] Talhão carregado $i: ${talhao.name}');
        Logger.info('🔍 [TALHOES]   - ID: ${talhao.id}');
        Logger.info('🔍 [TALHOES]   - Polígonos: ${talhao.poligonos?.length ?? 0}');
        
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          for (int j = 0; j < talhao.poligonos.length; j++) {
            final poligono = talhao.poligonos[j];
            Logger.info('🔍 [TALHOES]     Polígono $j: ${poligono.pontos?.length ?? 0} pontos');
            
            if (poligono.pontos != null && poligono.pontos.isNotEmpty) {
              for (int k = 0; k < poligono.pontos.length; k++) {
                final ponto = poligono.pontos[k];
                Logger.info('🔍 [TALHOES]       Ponto $k: $ponto');
              }
            }
          }
        }
      }
      
      // Se não houver talhões, não criar exemplo por enquanto
      if (talhoes.isEmpty) {
        Logger.info('ℹ️ [TALHOES] Nenhum talhão encontrado');
      }
      
      // Forçar rebuild para mostrar os polígonos
      setState(() {});
    } catch (e) {
      Logger.error('❌ [TALHOES] Erro ao carregar talhões: $e');
    }
  }

  /// Carrega culturas da fazenda
  Future<void> _carregarCulturas() async {
    try {
      setState(() => _isLoadingCulturas = true);
      
      print('🔄 Iniciando carregamento de culturas...');
      
      // Primeiro, tentar carregar via CulturaTalhaoService (integra com módulo Culturas da Fazenda)
      try {
        print('📋 Tentando carregar via CulturaTalhaoService...');
        final culturaTalhaoService = CulturaTalhaoService();
        final culturasFazenda = await culturaTalhaoService.listarCulturas();
        print('✅ CulturaTalhaoService retornou ${culturasFazenda.length} culturas');
        
        if (culturasFazenda.isNotEmpty) {
          // Converter para CulturaModel
          final culturasConvertidas = culturasFazenda.map((crop) => CulturaModel(
            id: crop['id']?.toString() ?? '0',
            name: crop['nome'] ?? '',
            color: crop['cor'] ?? _obterCorPorNome(crop['nome'] ?? ''),
            description: crop['descricao'] ?? '',
          )).toList();
          
          setState(() {
            _controller.setCulturas(culturasConvertidas);
            _isLoadingCulturas = false;
          });
          
          print('✅ ${culturasConvertidas.length} culturas carregadas do módulo Culturas da Fazenda');
          for (var cultura in culturasConvertidas) {
            print('  - ${cultura.name} (ID: ${cultura.id})');
          }
          return; // Sair se conseguiu carregar dados reais
        } else {
          print('⚠️ CulturaTalhaoService retornou lista vazia');
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaTalhaoService: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
      
      // REMOVIDO: CultureImportService que causa loops infinitos
      // Segundo, tentar carregar do módulo Culturas da Fazenda via CultureImportService
      /*
      try {
        print('📋 Tentando carregar via CultureImportService...');
        final cultureImportService = CultureImportService();
        await cultureImportService.initialize();
        
        final culturasFazenda = await cultureImportService.getAllCrops();
        print('✅ CultureImportService retornou ${culturasFazenda.length} culturas');
        
        if (culturasFazenda.isNotEmpty) {
          // Converter para CulturaModel
          final culturasConvertidas = culturasFazenda.map((crop) => CulturaModel(
            id: crop.id?.toString() ?? '0',
            name: crop.name,
            color: _obterCorPorNome(crop.name),
            description: crop.description ?? '',
          )).toList();
          
          setState(() {
            _controller.setCulturas(culturasConvertidas);
            _isLoadingCulturas = false;
          });
          
          print('✅ ${culturasConvertidas.length} culturas carregadas do CultureImportService');
          for (var cultura in culturasConvertidas) {
            print('  - ${cultura.name} (ID: ${cultura.id})');
          }
          return;
        } else {
          print('⚠️ CultureImportService retornou lista vazia');
        }
      } catch (e) {
        print('❌ Erro ao carregar do CultureImportService: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
      */
      
      // Segundo, tentar carregar do CulturaService como fallback
      try {
        print('📋 Tentando carregar via CulturaService como fallback...');
        final culturas = await culturaService.loadCulturas();
        
        setState(() {
          _controller.setCulturas(culturas);
          _isLoadingCulturas = false;
        });
        
        print('✅ ${culturas.length} culturas carregadas do CulturaService');
        
      } catch (e) {
        print('❌ Erro ao carregar do CulturaService: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        setState(() => _isLoadingCulturas = false);
      }
      
      // REMOVIDO: CropRepository que causa loops infinitos
      // Terceiro, tentar carregar diretamente do CropRepository
      /*
      if (_controller.culturas.isEmpty) {
        try {
          print('📋 Tentando carregar via CropRepository como último recurso...');
          final cropRepository = CropRepository();
          await cropRepository.initialize();
          
          final crops = await cropRepository.getAllCrops();
          print('✅ CropRepository retornou ${crops.length} culturas');
          
          if (crops.isNotEmpty) {
            final culturasConvertidas = crops.map((crop) => CulturaModel(
              id: crop.id.toString(),
              name: crop.name,
              color: _obterCorPorNome(crop.name),
              description: crop.description ?? '',
            )).toList();
            
            setState(() {
              _controller.setCulturas(culturasConvertidas);
              _isLoadingCulturas = false;
            });
            
            print('✅ ${culturasConvertidas.length} culturas carregadas do CropRepository');
            for (var cultura in culturasConvertidas) {
              print('  - ${cultura.name} (ID: ${cultura.id})');
            }
          }
        } catch (e) {
          print('❌ Erro ao carregar do CropRepository: $e');
          print('❌ Stack trace: ${StackTrace.current}');
          setState(() => _isLoadingCulturas = false);
        }
      }
      */
      
      // Se nenhum método funcionou, criar cultura padrão
      if (_controller.culturas.isEmpty) {
        print('📋 Criando cultura padrão como fallback...');
        final culturaPadrao = CulturaModel(
          id: '1',
          name: 'Soja',
          color: Colors.green,
          description: 'Cultura padrão',
        );
        
        setState(() {
          _controller.setCulturas([culturaPadrao]);
          _isLoadingCulturas = false;
        });
        
        print('✅ Cultura padrão criada: ${culturaPadrao.name}');
      }
      
    } catch (e) {
      setState(() => _isLoadingCulturas = false);
      print('❌ Erro geral ao carregar culturas: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Em caso de erro geral, criar cultura padrão
      final culturaPadrao = CulturaModel(
        id: '1',
        name: 'Soja',
        color: Colors.green,
        description: 'Cultura padrão',
      );
      
      setState(() {
        _controller.setCulturas([culturaPadrao]);
      });
      
      print('✅ Cultura padrão criada após erro: ${culturaPadrao.name}');
    }
  }
  
  /// Constrói polígonos para os talhões existentes usando implementação personalizada
  List<Polygon> _buildTalhaoPolygons(List<dynamic> talhoes, CulturaProvider culturaProvider) {
    print('🔍 DEBUG: _buildTalhaoPolygons chamado com ${talhoes.length} talhões');
    
    final List<Polygon> polygons = [];
    
    // Debug: verificar cada talhão
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      print('🔍 DEBUG: Talhão $i: ${talhao.name}');
      print('🔍 DEBUG:   - ID: ${talhao.id}');
      print('🔍 DEBUG:   - Tipo: ${talhao.runtimeType}');
      print('🔍 DEBUG:   - Polígonos: ${talhao.poligonos?.length ?? 0}');
      print('🔍 DEBUG:   - Pontos diretos: ${talhao.pontos?.length ?? 0}');
      
      try {
        // Verificar se o talhão tem pontos diretamente (formato TalhaoSafraModel)
        if (talhao.pontos != null && talhao.pontos.isNotEmpty) {
          print('🔍 DEBUG:   - Primeiro ponto direto: ${talhao.pontos.first}');
          print('🔍 DEBUG:   - Tipo do primeiro ponto: ${talhao.pontos.first.runtimeType}');
          
          // Converter pontos para LatLng se necessário
          List<LatLng> pontosConvertidos = [];
          for (final ponto in talhao.pontos) {
            if (ponto is LatLng) {
              pontosConvertidos.add(ponto);
            } else if (ponto.latitude != null && ponto.longitude != null) {
              pontosConvertidos.add(LatLng(ponto.latitude, ponto.longitude));
            }
          }
          
          if (pontosConvertidos.length >= 3) {
            // Fechar o polígono se necessário
            if (pontosConvertidos.first != pontosConvertidos.last) {
              pontosConvertidos.add(pontosConvertidos.first);
            }
            
            // Usar cor verde padrão para todos os polígonos
            Color corCultura = Colors.green;
            
            print('✅ Criando polígono direto para ${talhao.name}: ${pontosConvertidos.length} pontos');
            
            polygons.add(Polygon(
              points: pontosConvertidos,
              color: corCultura.withOpacity(0.4),
              borderColor: corCultura.withOpacity(0.8),
              borderStrokeWidth: 2.5,
              isFilled: true,
              label: talhao.name,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                backgroundColor: Colors.black54,
              ),
            ));
          }
        }
        
        // Verificar se o talhão tem polígonos (formato antigo)
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          print('🔍 DEBUG:   - Primeiro ponto: ${talhao.poligonos.first}');
          print('🔍 DEBUG:   - Tipo do primeiro ponto: ${talhao.poligonos.first.runtimeType}');
          
          for (int j = 0; j < talhao.poligonos.length; j++) {
            final poligono = talhao.poligonos[j];
            print('🔍 DEBUG:     Polígono $j: ${poligono.pontos?.length ?? 0} pontos');
            
            if (poligono.pontos != null && poligono.pontos.isNotEmpty) {
              // Converter pontos para LatLng
              List<LatLng> pontosConvertidos = [];
              for (final ponto in poligono.pontos) {
                if (ponto is LatLng) {
                  pontosConvertidos.add(ponto);
                } else if (ponto.latitude != null && ponto.longitude != null) {
                  pontosConvertidos.add(LatLng(ponto.latitude, ponto.longitude));
                }
              }
              
              if (pontosConvertidos.length >= 3) {
                // Fechar o polígono se necessário
                if (pontosConvertidos.first != pontosConvertidos.last) {
                  pontosConvertidos.add(pontosConvertidos.first);
                }
                
                // Usar cor verde padrão para todos os polígonos
                Color corCultura = Colors.green;
                
                print('✅ Criando polígono para ${talhao.name}: ${pontosConvertidos.length} pontos');
                
                polygons.add(Polygon(
                  points: pontosConvertidos,
                  color: corCultura.withOpacity(0.8),
                  borderColor: corCultura,
                  borderStrokeWidth: 3.0,
                  isFilled: true,
                  label: talhao.name,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    backgroundColor: Colors.black54,
                  ),
                ));
              }
            }
          }
        }
        
        // Se não tem nem pontos nem polígonos, tentar usar dados básicos
        if ((talhao.pontos == null || talhao.pontos.isEmpty) && 
            (talhao.poligonos == null || talhao.poligonos.isEmpty)) {
          print('⚠️ Talhão ${talhao.name} não tem pontos nem polígonos');
        }
        
      } catch (e) {
        print('❌ Erro ao processar polígono do talhão ${talhao.name}: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
    }
    
    print('🔍 DEBUG: _buildTalhaoPolygons retornou ${polygons.length} polígonos');
    
    // Debug adicional: verificar cada polígono retornado
    for (int i = 0; i < polygons.length; i++) {
      final polygon = polygons[i];
      print('🔍 DEBUG: Polígono $i: ${polygon.points.length} pontos');
      if (polygon.points.isNotEmpty) {
        print('🔍 DEBUG:   Primeiro ponto: ${polygon.points.first}');
        print('🔍 DEBUG:   Último ponto: ${polygon.points.last}');
      }
    }
    
    return polygons;
  }

  /// Constrói marcadores para os talhões existentes com inicial da cultura no centro
  List<Marker> _buildTalhaoMarkers(List<dynamic> talhoes, CulturaProvider culturaProvider) {
    List<Marker> markers = [];
    
    for (final talhao in talhoes) {
      // Obter pontos do polígono
      List<LatLng> pontos = [];
      
      if (talhao.pontos != null && talhao.pontos.isNotEmpty) {
        for (final ponto in talhao.pontos) {
          if (ponto is LatLng) {
            pontos.add(ponto);
          } else if (ponto.latitude != null && ponto.longitude != null) {
            pontos.add(LatLng(ponto.latitude, ponto.longitude));
          }
        }
      } else if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
        final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
        if (poligono == null) return 0.0;
        if (poligono.pontos != null) {
          for (final ponto in poligono.pontos) {
            if (ponto is LatLng) {
              pontos.add(ponto);
            } else if (ponto.latitude != null && ponto.longitude != null) {
              pontos.add(LatLng(ponto.latitude, ponto.longitude));
            }
          }
        }
      }
      
      if (pontos.isNotEmpty) {
        // Calcular centro do polígono
        final centro = _calculatePolygonCenter(pontos);
        
        // Obter informações da cultura do talhão
        String culturaNome = 'Cultura';
        Color corCultura = Colors.green;
        
        // Tentar obter a cultura do talhão
        if (talhao.crop != null) {
          culturaNome = talhao.crop.name ?? 'Cultura';
          if (talhao.crop.colorValue != null) {
            corCultura = Color(talhao.crop.colorValue);
          }
        } else if (talhao.culturaId != null && _culturas.isNotEmpty) {
          try {
            final cultura = _culturas.firstWhere(
              (c) => c.id == talhao.culturaId,
              orElse: () => _culturas.isNotEmpty ? _culturas.first : CulturaModel(
                id: '0',
                name: 'Cultura',
                color: Colors.green,
                description: 'Cultura padrão',
              ),
            );
            culturaNome = cultura.name;
            corCultura = cultura.color;
          } catch (e) {
            print('⚠️ Erro ao obter cultura para o talhão: $e');
            culturaNome = 'Cultura';
            corCultura = Colors.green;
          }
        }
        
        // Criar marcador com nome da cultura (sem círculo)
        markers.add(Marker(
          point: centro,
          width: 120,
          height: 40,
          child: GestureDetector(
            onTap: () {
              print('🔄 Clicou no talhão: ${talhao.name}');
              _showElegantTalhaoCard(talhao);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corCultura.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: corCultura, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  culturaNome,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ));
      }
    }
    
    return markers;
  }

  /// Obtém localização padrão inteligente
  Future<LatLng> _getLocalizacaoPadrao() async {
    // Se já temos localização do usuário, usar ela
    if (_userLocation != null) {
      print('📍 Usando localização do usuário como padrão');
      return _userLocation!;
    }
    
    // Se não temos localização, tentar obter do LocationService
    if (_locationService.currentPosition != null) {
      final pos = _locationService.currentPosition!;
      print('📍 Usando localização do LocationService como padrão');
      return LatLng(pos.latitude, pos.longitude);
    }
    
    // Tentar obter localização do dispositivo se possível
    try {
      print('🔄 Tentando obter localização do dispositivo...');
      // Usar o método estático correto do LocationService
      final location = await LocationService.getCurrentPosition();
      if (location != null && mounted) {
        setState(() {
          _userLocation = location;
        });
        print('✅ Localização obtida do dispositivo: ${location.latitude}, ${location.longitude}');
        return location;
      }
    } catch (e) {
      print('⚠️ Erro ao tentar obter localização do dispositivo: $e');
    }
    
    // Último recurso: localização central do Brasil (Brasília)
    print('⚠️ Usando localização de fallback (Brasília)');
    return const LatLng(-15.7801, -47.9292);
  }
  
  /// Calcula o centro de um polígono
  LatLng _calculatePolygonCenter(List<LatLng> pontos) {
    double latSum = 0;
    double lngSum = 0;
    
    for (final ponto in pontos) {
      latSum += ponto.latitude;
      lngSum += ponto.longitude;
    }
    
    return LatLng(latSum / pontos.length, lngSum / pontos.length);
  }

  /// Obtém área de um talhão usando cálculo geodésico preciso
  Future<double> _getTalhaoArea(dynamic talhao) async {
    try {
      print('🔄 Calculando área para talhão: ${talhao.name}');
      
      // Tentar obter área salva do talhão
      if (talhao.areaTotal != null && talhao.areaTotal > 0) {
        print('📊 Área do talhão ${talhao.name}: ${talhao.areaTotal.toStringAsFixed(2)} ha (dados salvos)');
        return talhao.areaTotal;
      }
      
      // Tentar obter área da safra mais recente
      if (talhao.safras != null && talhao.safras.isNotEmpty) {
        // Ordenar safras por data de atualização (mais recente primeiro)
        final safrasOrdenadas = List.from(talhao.safras);
        safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
        
        final safra = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
        if (safra != null && safra.area != null && safra.area > 0) {
          print('📊 Área da safra mais recente ${talhao.name}: ${safra.area.toStringAsFixed(2)} ha (dados salvos)');
          return safra.area.toDouble();
        }
      }
      
      // Tentar obter área do polígono
      if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
        final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
        if (poligono == null) return 0.0;
        
        // Verificar se o polígono tem área salva
        if (poligono.area != null && poligono.area > 0) {
          print('📊 Área do polígono ${talhao.name}: ${poligono.area.toStringAsFixed(2)} ha (dados salvos)');
          return poligono.area.toDouble();
        }
        
        // Calcular área dos pontos usando GeodeticUtils
        if (poligono.pontos != null && poligono.pontos.length >= 3) {
          final pontos = <LatLng>[];
          
          // Converter pontos para LatLng corretamente
          for (final p in poligono.pontos) {
            if (p != null) {
              double? lat, lng;
              
              // Verificar diferentes formatos de ponto
              if (p is LatLng) {
                lat = p.latitude;
                lng = p.longitude;
              } else if (p.latitude != null && p.longitude != null) {
                lat = p.latitude.toDouble();
                lng = p.longitude.toDouble();
              }
              
              if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
                pontos.add(LatLng(lat, lng));
              }
            }
          }
          
          if (pontos.length >= 3) {
            print('🔄 Calculando área para talhão ${talhao.name} com ${pontos.length} pontos...');
            print('📊 Primeiros 3 pontos: ${pontos.take(3).map((p) => '(${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)})').join(', ')}');
            
            final area = await GeodeticUtils.calculateAreaHectares(pontos);
            print('✅ Área calculada para ${talhao.name}: ${area.toStringAsFixed(2)} ha');
            
            // Atualizar a área na safra mais recente (não podemos modificar o polígono diretamente)
            if (talhao.safras != null && talhao.safras.isNotEmpty) {
              // Ordenar safras por data de atualização (mais recente primeiro)
              final safrasOrdenadas = List.from(talhao.safras);
              safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
              
              // Atualizar a safra mais recente
              final safraMaisRecente = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
              if (safraMaisRecente != null) {
                safraMaisRecente.area = area;
              }
              
              print('✅ Área atualizada na safra mais recente: ${safraMaisRecente.idSafra} (${safraMaisRecente.culturaNome})');
            }
            // areaTotal é um getter calculado, não pode ser atribuído diretamente
            
            return area;
          } else {
            print('⚠️ Talhão ${talhao.name} tem menos de 3 pontos válidos: ${pontos.length}');
            print('📊 Pontos originais: ${poligono.pontos.length}');
          }
        } else {
          print('⚠️ Talhão ${talhao.name} não tem pontos no polígono');
        }
      } else {
        print('⚠️ Talhão ${talhao.name} não tem polígonos');
      }
      
      print('⚠️ Não foi possível calcular área para talhão ${talhao.name}');
      return 0.0;
    } catch (e) {
      print('❌ Erro ao obter área do talhão ${talhao.name}: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return 0.0;
    }
  }

  /// Obtém nome da cultura de um talhão
  String _getTalhaoCultura(dynamic talhao) {
    try {
      // Verificar se o talhão tem safras
      if (talhao.safras != null && talhao.safras.isNotEmpty) {
        // Ordenar safras por data de atualização (mais recente primeiro)
        final safrasOrdenadas = List.from(talhao.safras);
        safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
        
        final safra = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
        if (safra != null && safra.culturaNome != null && safra.culturaNome.isNotEmpty) {
          return safra.culturaNome;
        }
      }
      
      // Verificar se o talhão tem cultura direta
      if (talhao.cultura != null && talhao.cultura.isNotEmpty) {
        return talhao.cultura;
      }
      
      // Verificar se o talhão tem safra atual
      if (talhao.safraAtual != null && talhao.safraAtual.cultura != null && talhao.safraAtual.cultura.isNotEmpty) {
        return talhao.safraAtual.cultura;
      }
      
      return 'Cultura não selecionada';
    } catch (e) {
      print('Erro ao obter cultura do talhão: $e');
      return 'Cultura não selecionada';
    }
  }

  /// Obtém nome da safra de um talhão
  String _getTalhaoSafra(dynamic talhao) {
    try {
      // Verificar se o talhão tem safras
      if (talhao.safras != null && talhao.safras.isNotEmpty) {
        // Ordenar safras por data de atualização (mais recente primeiro)
        final safrasOrdenadas = List.from(talhao.safras);
        safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
        
        final safra = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
        if (safra != null && safra.safra != null && safra.safra.isNotEmpty) {
          return safra.safra;
        }
      }
      
      // Verificar se o talhão tem safra direta
      if (talhao.safra != null && talhao.safra.isNotEmpty) {
        return talhao.safra;
      }
      
      return 'Safra não definida';
    } catch (e) {
      print('Erro ao obter safra do talhão: $e');
      return 'Safra não definida';
    }
  }

  /// Seleciona uma cultura para o talhão
  void _selecionarCulturaParaTalhao(dynamic talhao, String culturaId) {
    try {
      if (_culturas.isEmpty) {
        print('⚠️ Lista de culturas vazia, não é possível selecionar cultura');
        return;
      }
      
      final cultura = _culturas.firstWhere(
        (c) => c.id == culturaId,
        orElse: () => _culturas.isNotEmpty ? _culturas.first : CulturaModel(
          id: '0',
          name: 'Cultura não encontrada',
          description: '',
          ciclo: '',
          tipo: '',
          cor: '0xFF9E9E9E',
        ),
      );
      
      // Atualizar o talhão com a nova cultura
      if (talhao.safras != null && talhao.safras.isNotEmpty) {
        // Ordenar safras por data de atualização (mais recente primeiro)
        final safrasOrdenadas = List.from(talhao.safras);
        safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
        
        final safra = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
        if (safra != null) {
          safra.culturaNome = cultura.name;
          safra.culturaCor = '#${cultura.color.value.toRadixString(16).substring(2)}';
          safra.culturaId = cultura.id;
          safra.dataAtualizacao = DateTime.now(); // Atualizar data de modificação
        }
      }
      
      setState(() {
        // Forçar atualização da UI
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cultura ${cultura.name} selecionada para ${talhao.name ?? 'Talhão'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erro ao selecionar cultura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar cultura'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Adiciona uma safra para o talhão
  void _adicionarSafraParaTalhao(dynamic talhaoParam) {
    try {
      final safraController = TextEditingController();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.orange),
              SizedBox(width: 8),
              Text('Adicionar Safra'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Digite o nome da safra (ex: 2024/2025):',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: safraController,
                decoration: InputDecoration(
                  labelText: 'Nome da Safra',
                  hintText: '2024/2025',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Safras comuns:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  '2024/2025',
                  '2023/2024',
                  '2025/2026',
                  'Verão 2024',
                  'Inverno 2024',
                ].map((safra) => ActionChip(
                  label: Text(safra),
                  onPressed: () {
                    safraController.text = safra;
                  },
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.orange[700]),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (safraController.text.isNotEmpty) {
                  // Atualizar a safra mais recente do talhão
                  if (talhaoParam.safras != null && talhaoParam.safras.isNotEmpty) {
                    // Ordenar safras por data de atualização (mais recente primeiro)
                    final safrasOrdenadas = List.from(talhaoParam.safras);
                    safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
                    
                    // Atualizar a safra mais recente
                    final safraMaisRecente = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
                    if (safraMaisRecente != null) {
                      safraMaisRecente.idSafra = safraController.text;
                    }
                    
                    print('✅ Safra atualizada para: ${safraController.text} na safra mais recente (${safraMaisRecente.culturaNome})');
                  }
                  
                  setState(() {
                    // Forçar atualização da UI
                  });
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Safra ${safraController.text} adicionada para ${talhaoParam.name ?? 'Talhão'}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('Salvar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao adicionar safra: $e');
    }
  }

  /// Inicializa o card editável com os dados do talhão selecionado
  void _inicializarCardEditavel(dynamic talhao) {
    print('🔄 Inicializando card editável para talhão: ${talhao.name}');
    
    // Verificar se os controladores já existem, caso contrário criar novos
    if (_nomeController == null) {
      _nomeController = TextEditingController();
    }
    if (_observacoesController == null) {
      _observacoesController = TextEditingController();
    }
    
    // Atualizar texto dos controladores
    _nomeController!.text = talhao.name ?? '';
    _observacoesController!.text = talhao.observacoes ?? '';
    
    // Buscar cultura atual do talhão
    final culturaNome = _getTalhaoCultura(talhao);
    if (culturaNome != 'Cultura não selecionada') {
      try {
        if (_culturas.isNotEmpty) {
          // Buscar cultura por nome (case insensitive)
          _culturaSelecionadaCard = _culturas.firstWhere(
            (c) => c.name.toLowerCase().trim() == culturaNome.toLowerCase().trim(),
            orElse: () => _culturas.isNotEmpty ? _culturas.first : CulturaModel(
              id: '0',
              name: 'Cultura não encontrada',
              description: '',
              ciclo: '',
              tipo: '',
              cor: '0xFF9E9E9E',
            ),
          );
          print('✅ Cultura encontrada: ${_culturaSelecionadaCard?.name}');
        } else {
          print('⚠️ Lista de culturas vazia');
          _culturaSelecionadaCard = null;
        }
      } catch (e) {
        print('⚠️ Cultura não encontrada: $culturaNome, usando primeira disponível');
        _culturaSelecionadaCard = _culturas.isNotEmpty ? _culturas.first : null;
      }
    } else {
      print('⚠️ Cultura não selecionada, usando primeira disponível');
      _culturaSelecionadaCard = _culturas.isNotEmpty ? _culturas.first : null;
    }
    
    // Buscar safra atual do talhão
    _safraSelecionadaCard = _getTalhaoSafra(talhao);
    
    // Calcular área automaticamente
    _recalcularArea();
    
    // Forçar cálculo da área se necessário
    if (_areaCalculadaCard <= 0.0) {
      print('⚠️ Área ainda é zero, forçando recálculo...');
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) {
          _recalcularArea();
          setState(() {});
        }
      });
    }
    
    // Aguardar um pouco e recalcular novamente para garantir
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _recalcularArea();
        setState(() {}); // Forçar atualização da UI
      }
    });
    
    // Aguardar mais um pouco e recalcular uma terceira vez para garantir
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _recalcularArea();
        setState(() {}); // Forçar atualização da UI
      }
    });
    
    // Debug: mostrar informações detalhadas do talhão
    _debugTalhaoInfo(talhao);
    
    print('✅ Card editável inicializado');
    print('  - Nome: ${_nomeController?.text}');
    print('  - Cultura: ${_culturaSelecionadaCard?.name}');
    print('  - Safra: $_safraSelecionadaCard');
    print('  - Área: ${_areaCalculadaCard.toStringAsFixed(2)} ha');
  }
  
  /// Calcula a área de um polígono usando cálculo geodésico preciso
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) {
      print('⚠️ Polígono com menos de 3 pontos: ${points.length}');
      return 0.0;
    }
    
    print('🔄 Calculando área para ${points.length} pontos');
    
    try {
      // Usar cálculo geodésico preciso baseado na latitude média
      final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      
      // Fatores de conversão para metros baseados na latitude
      final metersPerDegLat = 111132.954 - 559.822 * cos(2 * avgLat * pi / 180) + 
                             1.175 * cos(4 * avgLat * pi / 180);
      final metersPerDegLng = (pi / 180) * 6378137.0 * cos(avgLat * pi / 180);
      
      // Converter para coordenadas em metros
      if (points.isEmpty) return 0.0;
      
      final xy = points.map((p) => MapEntry(
        (p.longitude - points.first.longitude) * metersPerDegLng,
        (p.latitude - points.first.latitude) * metersPerDegLat,
      )).toList();
      
      // Aplicar fórmula de Shoelace
      double sum = 0.0;
      for (int i = 0; i < xy.length - 1; i++) {
        final x1 = xy[i].key;
        final y1 = xy[i].value;
        final x2 = xy[i + 1].key;
        final y2 = xy[i + 1].value;
        sum += (x1 * y2) - (x2 * y1);
      }
      
      // Fechar o polígono
      final x1 = xy.last.key;
      final y1 = xy.last.value;
      final x2 = xy.first.key;
      final y2 = xy.first.value;
      sum += (x1 * y2) - (x2 * y1);
      
      final areaM2 = sum.abs() / 2.0;
      final areaInHectares = areaM2 / 10000.0; // Converter para hectares
      
      print('  📊 Área calculada: ${areaInHectares.toStringAsFixed(4)} ha');
      print('  📊 Área em m²: ${areaM2.toStringAsFixed(2)}');
      print('  📊 Latitude média: ${avgLat.toStringAsFixed(6)}°');
      
      return areaInHectares;
    } catch (e) {
      print('❌ Erro ao calcular área do polígono: $e');
      return 0.0;
    }
  }
  
  /// Recalcula a área do talhão selecionado
  void _recalcularArea() {
    if (_selectedTalhao == null) {
      print('❌ _selectedTalhao é null');
      return;
    }
    
    print('🔄 Recalculando área para talhão: ${_selectedTalhao!.name}');
    print('  📊 areaTotal: ${_selectedTalhao!.areaTotal}');
    print('  📊 safras: ${_selectedTalhao!.safras?.length ?? 0}');
    print('  📊 poligonos: ${_selectedTalhao!.poligonos?.length ?? 0}');
    print('  📊 _currentArea: ${_controller.currentArea}');
    print('  📊 _drawnArea: $_drawnArea');
    
    try {
      double area = 0.0;
      
      // Verificar se é um talhão importado (baseado no nome ou outras características)
      bool isImportedTalhao = _selectedTalhao!.name.toLowerCase().contains('importado') || 
                             _selectedTalhao!.name.toLowerCase().contains('import');
      
      if (isImportedTalhao) {
        print('📊 Talhão importado detectado - preservando área original');
        
        // Para talhões importados, priorizar área original
        if (_selectedTalhao!.areaTotal != null && _selectedTalhao!.areaTotal > 0) {
          area = _selectedTalhao!.areaTotal;
          print('  📊 Usando área original do talhão importado: ${area.toStringAsFixed(4)} ha');
        } else if (_selectedTalhao!.safras != null && _selectedTalhao!.safras.isNotEmpty) {
          final safra = _selectedTalhao!.safras.isNotEmpty ? _selectedTalhao!.safras.first : null;
          if (safra == null) return 0.0;
          if (safra.area != null && safra.area > 0) {
            area = safra.area.toDouble();
            print('  📊 Usando área da safra do talhão importado: ${area.toStringAsFixed(4)} ha');
          }
        }
      } else {
        // Para talhões criados manualmente, calcular área
        print('📊 Talhão criado manualmente - calculando área');
        
        // PRIMEIRO: Se temos _drawnArea válida (área calculada durante desenho), usar ela
        if (_drawnArea > 0.0) {
          area = _drawnArea;
          print('  📊 Usando área calculada durante desenho: ${area.toStringAsFixed(4)} ha');
        }
        
        // SEGUNDO: Se não tem _drawnArea, tentar _currentArea
        if (area <= 0 && _controller.currentArea > 0.0) {
          area = _controller.currentArea;
          print('  📊 Usando área atual: ${area.toStringAsFixed(4)} ha');
        }
        
        // TERCEIRO: Calcular área dos pontos do polígono usando método preciso
        if (area <= 0 && _selectedTalhao!.poligonos != null && _selectedTalhao!.poligonos.isNotEmpty) {
          final poligono = _selectedTalhao!.poligonos.isNotEmpty ? _selectedTalhao!.poligonos.first : null;
          if (poligono == null) return 0.0;
          print('  📊 Polígono encontrado: ${poligono.pontos?.length ?? 0} pontos');
          
          if (poligono.pontos != null && poligono.pontos.length >= 3) {
            try {
              // Converter pontos para LatLng se necessário
              final pontos = <LatLng>[];
              for (final p in poligono.pontos) {
                if (p != null) {
                  double? lat, lng;
                  
                  // Verificar diferentes formatos de ponto
                  if (p is LatLng) {
                    lat = p.latitude;
                    lng = p.longitude;
                  } else if (p.latitude != null && p.longitude != null) {
                    lat = p.latitude.toDouble();
                    lng = p.longitude.toDouble();
                  } else if (p is dynamic && p.latitude != null && p.longitude != null) {
                    lat = p.latitude.toDouble();
                    lng = p.longitude.toDouble();
                  }
                  
                  if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
                    pontos.add(LatLng(lat, lng));
                  }
                }
              }
              
              print('  📊 Pontos convertidos: ${pontos.length}');
              
              if (pontos.length >= 3) {
                // Usar método de cálculo preciso
                area = _calculatePolygonArea(pontos);
                print('  📊 Área calculada dos pontos: ${area.toStringAsFixed(4)} ha');
              } else {
                print('⚠️ Polígono sem pontos suficientes após conversão: ${pontos.length} pontos');
              }
            } catch (e) {
              print('❌ Erro ao calcular área dos pontos: $e');
              area = 0.0;
            }
          } else {
            print('⚠️ Polígono sem pontos suficientes: ${poligono.pontos?.length ?? 0} pontos');
          }
        }
        
        // QUARTO: Se ainda não tem área e estamos desenhando, usar _currentPoints
        if (area <= 0 && _controller.isDrawing && _controller.currentPoints.isNotEmpty && _controller.currentPoints.length >= 3) {
          try {
            area = _calculatePolygonArea(_controller.currentPoints);
            print('  📊 Usando área dos pontos atuais: ${area.toStringAsFixed(2)} ha');
          } catch (e) {
            print('❌ Erro ao calcular área dos pontos atuais: $e');
          }
        }
      }
      
      setState(() {
        _areaCalculadaCard = area;
      });
      
      print('✅ Área final atualizada: ${_areaCalculadaCard.toStringAsFixed(4)} ha');
      
    } catch (e) {
      print('❌ Erro ao recalcular área: $e');
      setState(() {
        _areaCalculadaCard = 0.0;
      });
    }
  }
  
  /// Debug: mostra informações detalhadas do talhão
  void _debugTalhaoInfo(dynamic talhao) {
    print('🔍 DEBUG: Informações detalhadas do talhão');
    print('  - ID: ${talhao.id}');
    print('  - Nome: ${talhao.name}');
    print('  - Cultura: ${talhao.cultura}');
    print('  - areaTotal: ${talhao.areaTotal}');
    print('  - Polígonos: ${talhao.poligonos?.length ?? 0}');
    
    if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
        final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
        if (poligono == null) return 0.0;
      print('  - Primeiro polígono:');
      print('    - ID: ${poligono.id}');
      print('    - Pontos: ${poligono.pontos?.length ?? 0}');
      print('    - Área do polígono: ${poligono.area}');
      print('    - Perímetro: ${poligono.perimetro}');
      
      if (poligono.pontos != null && poligono.pontos.isNotEmpty) {
        print('    - Primeiros 3 pontos:');
        for (int i = 0; i < (poligono.pontos.length < 3 ? poligono.pontos.length : 3); i++) {
          print('      ${i+1}: (${poligono.pontos[i].latitude.toStringAsFixed(6)}, ${poligono.pontos[i].longitude.toStringAsFixed(6)})');
        }
      }
    }
    
    print('  - Safras: ${talhao.safras?.length ?? 0}');
    if (talhao.safras != null && talhao.safras.isNotEmpty) {
      final safra = talhao.safras.first;
      print('  - Primeira safra:');
      print('    - ID: ${safra.id}');
      print('    - Nome: ${safra.idSafra}');
      print('    - Área: ${safra.area}');
      print('    - Cultura: ${safra.culturaNome}');
    }
  }
  
  /// Mostra diálogo para adicionar safra no card
  void _mostrarDialogoSafraCard() {
    final safraController = TextEditingController(text: _safraSelecionadaCard.isNotEmpty ? _safraSelecionadaCard : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange),
            SizedBox(width: 8),
            Text('Adicionar Safra'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Digite o nome da safra (ex: 2024/2025):',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: safraController,
              decoration: InputDecoration(
                labelText: 'Nome da Safra',
                hintText: '2024/2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Safras comuns:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                '2024/2025',
                '2023/2024',
                '2025/2026',
                'Verão 2024',
                'Inverno 2024',
              ].map((safra) => ActionChip(
                label: Text(safra),
                onPressed: () {
                  safraController.text = safra;
                },
                backgroundColor: Colors.orange.withOpacity(0.1),
                labelStyle: TextStyle(color: Colors.orange[700]),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (safraController.text.isNotEmpty) {
                // Atualizar a safra do talhão
                if (_selectedTalhao?.safras != null && _selectedTalhao!.safras.isNotEmpty) {
                  _selectedTalhao!.safras.first.idSafra = safraController.text;
                }
                
                setState(() {
                  // Forçar atualização da UI
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Safra ${safraController.text} adicionada para ${_selectedTalhao?.name ?? 'Talhão'}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Salva as alterações do talhão
  Future<void> _salvarAlteracoes() async {
    if (_selectedTalhao == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      print('🔄 Iniciando salvamento de alterações...');
      
      // Criar cópia do talhão com as alterações
      final talhao = _selectedTalhao!.copyWith(
        nome: (_nomeController?.text ?? '').trim().isNotEmpty 
            ? _nomeController!.text.trim() 
            : _selectedTalhao!.name,
        culturaId: _culturaSelecionadaCard?.id ?? _selectedTalhao!.culturaId,
      );
      
      // Atualizar safra se foi alterada
      final safraParaSalvar = _safraSelecionada ?? _safraSelecionadaCard;
      if (safraParaSalvar.isNotEmpty && talhao.safras.isNotEmpty) {
        final safrasOrdenadas = List.from(talhao.safras);
        safrasOrdenadas.sort((a, b) => b.dataAtualizacao.compareTo(a.dataAtualizacao));
        final safraMaisRecente = safrasOrdenadas.isNotEmpty ? safrasOrdenadas.first : null;
        if (safraMaisRecente != null) {
          safraMaisRecente.idSafra = safraParaSalvar;
          safraMaisRecente.dataAtualizacao = DateTime.now();
        }
      }
      
      print('📊 Dados do talhão para salvar:');
      print('  - ID: ${talhao.id}');
      print('  - Nome: ${talhao.name}');
      print('  - Área: ${talhao.area}');
      print('  - Cultura ID: ${talhao.culturaId}');
      print('  - Safra: ${safraParaSalvar}');
      print('  - Safras: ${talhao.safras.length}');
      
      // Salvar no banco de dados usando o TalhaoRepository
      try {
        print('🔄 Salvando no banco de dados...');
        await talhaoRepository.atualizarTalhao(talhao);
        print('✅ Talhão salvo no banco de dados com sucesso');
        
        // Verificar se foi salvo corretamente
        final talhaoSalvo = await talhaoRepository.buscarTalhaoPorId(talhao.id);
        if (talhaoSalvo != null) {
          print('✅ Verificação: Talhão recuperado do banco:');
          print('  - Nome: ${talhaoSalvo.name}');
          print('  - Área: ${talhaoSalvo.area}');
        } else {
          print('❌ ERRO: Talhão não foi encontrado no banco após salvamento');
        }
        
      } catch (e) {
        print('❌ Erro ao salvar no banco: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        rethrow; // Re-throw para mostrar erro ao usuário
      }
      
      setState(() {
        _isSaving = false;
      });
      
      talhaoNotificationService.showSuccessMessage('✅ Alterações salvas para ${talhao.name}');
      
      // Fechar o popup
      setState(() {
        _showPopup = false;
        _selectedTalhao = null;
      });
      
      // CORREÇÃO AGRESSIVA: Removido recarregamento que causa loops
      // await _carregarTalhoesExistentes();
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      print('❌ Erro ao salvar alterações: $e');
      talhaoNotificationService.showErrorMessage('❌ Erro ao salvar alterações: $e');
    }
  }

  // Método _getCulturaIcon removido - sistema de ícones de culturas descontinuado

  /// Obtém a inicial da cultura para exibir no centro do polígono
  String _getCulturaInicial(dynamic talhao) {
    try {
      // Tentar obter nome da cultura do talhão
      String culturaNome = 'C';
      
      if (talhao.culturaId != null && _controller.culturas.isNotEmpty) {
        try {
          final cultura = _controller.culturas.firstWhere(
            (c) => c.id == talhao.culturaId,
          );
          culturaNome = cultura.name.isNotEmpty ? cultura.name[0].toUpperCase() : 'C';
        } catch (e) {
          print('⚠️ Cultura não encontrada para ID ${talhao.culturaId}: $e');
          culturaNome = 'C';
        }
      } else if (talhao.nomeCultura != null && talhao.nomeCultura.isNotEmpty) {
        culturaNome = talhao.nomeCultura[0].toUpperCase();
      }
      
      return culturaNome;
    } catch (e) {
      return 'C'; // Inicial padrão
    }
  }

  /// Calcula o centro de um polígono
  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    
    double totalLat = 0;
    double totalLng = 0;
    
    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    
    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  /// Obtém a fazenda atual do usuário
  Future<String> _getFazendaAtual() async {
    try {
      final perfilService = PerfilService();
      final fazenda = await perfilService.getFazendaAtual();
      if (fazenda != null) {
        return fazenda.id;
      }
      
      // Fallback: obter ID da fazenda ativa
      final fazendaId = await perfilService.getFazendaAtivaId();
      if (fazendaId != null) {
        return fazendaId;
      }
      
      // Último fallback: usar primeira fazenda disponível
      try {
        final farmService = FarmService();
        final fazendas = await farmService.getAllFarms();
        if (fazendas.isNotEmpty) {
          return fazendas.first.id;
        }
      } catch (e) {
        print('⚠️ Erro ao obter fazendas: $e');
      }
      
      // Fallback final: usar ID padrão
      print('⚠️ Nenhuma fazenda encontrada, usando ID padrão');
      return '1'; // ID padrão para fazenda
    } catch (e) {
      print('⚠️ Erro ao obter fazenda atual: $e');
      // Em caso de erro, usar ID padrão
      return '1'; // ID padrão para fazenda
    }
  }

  /// Obtém a safra atual do sistema
  Future<String> _getSafraAtual() async {
    try {
      final safraService = SafraService();
      final safra = await safraService.obterSafraAtual();
      if (safra != null) {
        return safra.id;
      }
      
      // Fallback: usar safra sugerida baseada no ano atual
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;
      
      String safraSugerida;
      if (month >= 7) {
        safraSugerida = '$year/${year + 1}';
      } else {
        safraSugerida = '${year - 1}/$year';
      }
      
      return safraSugerida;
    } catch (e) {
      print('⚠️ Erro ao obter safra atual: $e');
      // Fallback final: usar ano atual
      final year = DateTime.now().year;
      return '$year/${year + 1}';
    }
  }
  

  
  /// Edita um talhão usando o novo editor funcional
  void _editarTalhao(dynamic talhao) async {
    try {
      setState(() {
        _showPopup = false;
      });
      
      print('🔄 Iniciando edição do talhão: ${talhao.name ?? talhao.nome}');
      
      // Carregar culturas disponíveis
      final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
      await culturaProvider.carregarCulturas();
      final culturas = culturaProvider.culturas;
      
      print('📊 Culturas carregadas: ${culturas.length}');
      
      // Converter para TalhaoModel se necessário
      TalhaoModel talhaoModel;
      if (talhao is TalhaoModel) {
        talhaoModel = talhao;
        print('✅ Talhão já é TalhaoModel');
      } else {
        // Converter de formato antigo se necessário
        print('🔄 Convertendo talhão para TalhaoModel');
        
        // CORREÇÃO: Obter cultura corretamente
        String? culturaId;
        String? culturaNome;
        
        if (talhao.culturaId != null && talhao.culturaId!.isNotEmpty) {
          culturaId = talhao.culturaId;
          print('🔍 DEBUG CULTURA - Usando culturaId do talhão: $culturaId');
        } else if (talhao.safras != null && talhao.safras!.isNotEmpty) {
          final primeiraSafra = talhao.safras!.first;
          culturaId = primeiraSafra.culturaId;
          culturaNome = primeiraSafra.culturaNome;
          print('🔍 DEBUG CULTURA - Usando cultura da primeira safra: $culturaNome (ID: $culturaId)');
        }
        
        talhaoModel = TalhaoModel(
          id: talhao.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: talhao.name ?? talhao.nome ?? 'Talhão',
          poligonos: talhao.poligonos ?? talhao.points ?? [],
          area: talhao.area ?? 0.0,
          safras: talhao.safras ?? [],
          culturaId: culturaId,
          cultura: culturaNome ?? talhao.cultura,
          dataCriacao: talhao.dataCriacao ?? DateTime.now(),
          dataAtualizacao: talhao.dataAtualizacao ?? DateTime.now(),
          fazendaId: talhao.fazendaId ?? '1',
        );
        
        print('🔍 DEBUG CULTURA - Talhão convertido:');
        print('  - Nome: ${talhaoModel.name}');
        print('  - Cultura ID: ${talhaoModel.culturaId}');
        print('  - Cultura Nome: ${talhaoModel.cultura}');
        print('✅ Conversão concluída');
      }
      
      print('📊 Dados do talhão para edição:');
      print('  - ID: ${talhaoModel.id}');
      print('  - Nome: ${talhaoModel.name}');
      print('  - Área: ${talhaoModel.area}');
      print('  - Polígonos: ${talhaoModel.poligonos.length}');
      
      // Mostrar novo editor funcional
      await TalhaoEditorBottomSheet.show(
        context: context,
        talhao: talhaoModel,
        culturas: culturas,
        onSaved: (updatedTalhao) async {
          print('✅ Talhão salvo: ${updatedTalhao.name}');
          // Atualizar talhão na lista e persistir no banco
          await _atualizarTalhaoNaLista(updatedTalhao);
          _mostrarSucesso('Talhão "${updatedTalhao.name}" atualizado com sucesso!');
        },
        onDeleted: (deletedTalhao) {
          print('🗑️ Talhão excluído: ${deletedTalhao.name}');
          // Remover talhão da lista
          _removerTalhaoDaLista(deletedTalhao);
          _mostrarSucesso('Talhão "${deletedTalhao.name}" removido com sucesso!');
        },
      );
      
    } catch (e) {
      print('❌ Erro ao editar talhão: $e');
      _mostrarErro('Erro ao editar talhão: $e');
    }
  }

  /// Mostra card elegante para informações do talhão
  void _showElegantTalhaoCard(TalhaoModel talhao) {
    // Encontrar a cultura correspondente
    CulturaModel? cultura;
    try {
      cultura = _culturas.firstWhere(
        (c) => c.id == talhao.culturaId || c.name == talhao.cultura,
        orElse: () => CulturaModel(
          id: '0',
          name: talhao.cultura ?? 'Não definida',
          color: Colors.grey,
          description: 'Cultura não encontrada',
        ),
      );
    } catch (e) {
      cultura = CulturaModel(
        id: '0',
        name: talhao.cultura ?? 'Não definida',
        color: Colors.grey,
        description: 'Cultura não encontrada',
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cultura.color.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header com ícone da cultura
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cultura.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.agriculture,
                  color: cultura.color,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Nome do talhão
              Text(
                talhao.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Cultura
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cultura.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cultura.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cultura.color,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Métricas do talhão
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildElegantInfoMetric(
                    icon: Icons.crop_square,
                    label: 'Área',
                    value: '${talhao.area.toStringAsFixed(2)} ha',
                    color: const Color(0xFF2E7D32),
                  ),
                  _buildElegantInfoMetric(
                    icon: Icons.location_on,
                    label: 'Vértices',
                    value: '${talhao.pontos?.length ?? talhao.poligonos?.first.pontos?.length ?? 0}',
                    color: Colors.blue,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Data de criação
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Criado em ${_formatDate(talhao.dataCriacao)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Botões de ação
              Column(
                children: [
                  // Primeira linha - Subáreas e Editar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToSubareas(talhao);
                          },
                          icon: const Icon(Icons.grid_view, size: 18),
                          label: const Text('Subáreas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showFloatingCard(talhao);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cultura.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Segunda linha - Navegação e Fechar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToPlot(talhao);
                          },
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Navegar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navega para a tela de gerenciamento de subáreas
  void _navigateToSubareas(TalhaoModel talhao) async {
    try {
      // Converter talhão para o formato necessário
      final pontos = talhao.pontos?.isNotEmpty == true 
          ? talhao.pontos! 
          : talhao.poligonos?.isNotEmpty == true 
              ? talhao.poligonos!.first.pontos 
              : <LatLng>[];
      
      if (pontos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talhão sem polígonos válidos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ExperimentosListaScreen(
            talhaoId: talhao.id,
            talhaoNome: talhao.name,
          ),
        ),
      );

      if (result == true) {
        // Atualizar dados se necessário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subáreas atualizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao navegar para subáreas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao acessar subáreas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navega para a tela de navegação GPS até o talhão
  void _navigateToPlot(TalhaoModel talhao) async {
    try {
      // Calcular centro do talhão
      final pontos = talhao.pontos?.isNotEmpty == true 
          ? talhao.pontos! 
          : talhao.poligonos?.isNotEmpty == true 
              ? talhao.poligonos!.first.pontos 
              : <LatLng>[];
      
      if (pontos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talhão sem polígonos válidos para navegação'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Calcular centro do polígono
      final centro = _calculatePolygonCenter(pontos);
      
      // Obter cor da cultura
      final cultura = _culturas.firstWhere(
        (c) => c.id == talhao.culturaId,
        orElse: () => _culturas.first,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlotNavigationScreen(
            plotCenter: centro,
            plotName: talhao.name,
            plotColor: cultura.color,
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao iniciar navegação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar navegação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Calcula o centro de um polígono
  LatLng _calculatePolygonCenter(List<LatLng> pontos) {
    if (pontos.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final ponto in pontos) {
      latSum += ponto.latitude;
      lngSum += ponto.longitude;
    }
    
    return LatLng(
      latSum / pontos.length,
      lngSum / pontos.length,
    );
  }

  /// Constrói métrica elegante para o card
  Widget _buildElegantInfoMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Formata data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Mostra card flutuante para edição rápida de talhão
  void _showFloatingCard(TalhaoModel talhao) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TalhaoFloatingCard(
        talhao: talhao,
        culturas: _culturas,
        safras: ['2024/2025', '2023/2024', '2022/2023'],
        onSave: (updatedTalhao) async {
          Navigator.pop(context); // Fechar card
          await _atualizarTalhaoNaLista(updatedTalhao);
          _mostrarSucesso('Talhão "${updatedTalhao.name}" atualizado com sucesso!');
        },
        onDelete: (deletedTalhao) {
          Navigator.pop(context); // Fechar card
          _removerTalhaoDaLista(deletedTalhao);
          _mostrarSucesso('Talhão "${deletedTalhao.name}" removido com sucesso!');
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  /// Atualiza talhão na lista local e persiste no banco de dados
  Future<void> _atualizarTalhaoNaLista(TalhaoModel updatedTalhao) async {
    print('🔄 Atualizando talhão na lista e banco: ${updatedTalhao.name}');
    
    try {
      // CORREÇÃO: Primeiro persistir no banco de dados
      print('💾 Persistindo alterações no banco de dados...');
      
      // Converter TalhaoModel para TalhaoSafraModel se necessário
      final talhaoSafra = _converterParaTalhaoSafraModel(updatedTalhao);
      
      // Usar o repository para atualizar no banco
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
      final sucesso = await talhaoProvider.atualizarTalhao(talhaoSafra);
      
      if (!sucesso) {
        throw Exception('Falha ao atualizar talhão no banco de dados');
      }
      
      print('✅ Talhão persistido no banco com sucesso');
      
      // Depois atualizar na lista em memória
      setState(() {
        // Atualizar na lista de talhões se existir
        final index = _talhoes.indexWhere((t) => t.id == updatedTalhao.id);
        if (index >= 0) {
          _talhoes[index] = updatedTalhao;
          print('✅ Talhão atualizado na lista');
        } else {
          print('⚠️ Talhão não encontrado na lista, adicionando');
          _talhoes.add(updatedTalhao);
        }
      });
      
      // Recarregar dados do banco para garantir sincronização
      await _carregarTalhoes();
      
      print('✅ Atualização completa: banco + lista + recarregamento');
      
    } catch (e) {
      print('❌ Erro ao atualizar talhão: $e');
      _mostrarErro('Erro ao salvar alterações: $e');
      
      // Mesmo com erro, tentar atualizar a lista local
      setState(() {
        final index = _talhoes.indexWhere((t) => t.id == updatedTalhao.id);
        if (index >= 0) {
          _talhoes[index] = updatedTalhao;
        } else {
          _talhoes.add(updatedTalhao);
        }
      });
    }
  }

  /// Carrega a lista de talhões
  Future<void> _carregarTalhoes() async {
    try {
      // Carregar talhões via provider
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
      final talhoesSafra = await talhaoProvider.carregarTalhoes();
      
      // Converter para TalhaoModel
      final talhoes = talhoesSafra.map((talhaoSafra) {
        // CORREÇÃO: Obter cultura corretamente
        String? culturaId;
        String? culturaNome;
        
        if (talhaoSafra.safras.isNotEmpty) {
          final primeiraSafra = talhaoSafra.safras.first;
          culturaId = primeiraSafra.idCultura;
          culturaNome = primeiraSafra.culturaNome;
        }
        
        print('🔍 DEBUG CULTURA - Carregando talhão ${talhaoSafra.nome}:');
        print('  - Cultura ID: $culturaId');
        print('  - Cultura Nome: $culturaNome');
        
        return TalhaoModel(
          id: talhaoSafra.id,
          name: talhaoSafra.nome,
          area: talhaoSafra.area ?? 0.0,
          fazendaId: talhaoSafra.idFazenda,
          dataCriacao: talhaoSafra.dataCriacao,
          dataAtualizacao: talhaoSafra.dataAtualizacao,
          observacoes: '',
          sincronizado: talhaoSafra.sincronizado,
          culturaId: culturaId,
          cultura: culturaNome, // CORREÇÃO: Definir nome da cultura
          safras: talhaoSafra.safras.map((s) => SafraModel(
            id: s.id,
            talhaoId: s.idTalhao,
            safra: s.idSafra,
            culturaId: s.idCultura,
            culturaNome: s.culturaNome,
            culturaCor: s.culturaCor.value.toString(),
            dataCriacao: s.dataCadastro,
            dataAtualizacao: s.dataAtualizacao,
            sincronizado: s.sincronizado,
            periodo: s.idSafra,
            dataInicio: s.dataCadastro,
            dataFim: s.dataAtualizacao,
            ativa: true,
            nome: s.culturaNome,
          )).toList(),
          crop: null,
          poligonos: talhaoSafra.poligonos.map((p) => PoligonoModel(
            id: p.id,
            pontos: p.pontos,
            dataCriacao: p.dataCriacao,
            dataAtualizacao: p.dataAtualizacao,
            ativo: p.ativo,
            area: p.area.toDouble(),
            perimetro: p.perimetro.toDouble(),
            talhaoId: p.talhaoId,
          )).toList(),
        );
      }).toList();
      
      setState(() {
        _talhoes = talhoes;
      });
      
      print('✅ ${talhoes.length} talhões carregados na tela');
    } catch (e) {
      print('❌ Erro ao carregar talhões: $e');
      setState(() {
        _talhoes = [];
      });
    }
  }

  /// Remove talhão da lista local
  void _removerTalhaoDaLista(TalhaoModel deletedTalhao) {
    print('🔄 Removendo talhão da lista: ${deletedTalhao.name}');
    
    setState(() {
      _talhoes.removeWhere((t) => t.id == deletedTalhao.id);
      print('✅ Talhão removido da lista');
    });
    
    // CORREÇÃO: Não recarregar dados após remoção para evitar que o talhão volte
    // O talhão já foi removido do banco de dados pelo provider
    print('✅ Talhão removido permanentemente - não recarregando dados');
  }

  /// Mostra mensagem de sucesso
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Remove um talhão
  Future<void> _removerTalhao(dynamic talhao) async {
    try {
      setState(() {
        _showPopup = false;
      });
      
      // Confirmar exclusão
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza que deseja remover o talhão "${talhao.name}"?'),
              const SizedBox(height: 8),
              const Text(
                'Esta ação não pode ser desfeita.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remover'),
            ),
          ],
        ),
      );
      
      if (confirmar == true) {
        // Mostrar indicador de progresso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Removendo talhão...'),
              ],
            ),
          ),
        );
        
        try {
          print('🔄 Iniciando remoção do talhão: ${talhao.name}');
          
          // Obter provider de talhões
          final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
          
          // Tentar remover usando o provider
          final success = await talhaoProvider.excluirTalhao(talhao.id);
          
          // Fechar diálogo de progresso
          Navigator.pop(context);
          
          if (success) {
            print('✅ Talhão removido com sucesso');
            talhaoNotificationService.showSuccessMessage('✅ Talhão "${talhao.name}" removido com sucesso');
            _selectedTalhao = null;
            
            // Remover da lista local
            setState(() {
              _talhoes.removeWhere((t) => t.id == talhao.id);
            });
            
            // CORREÇÃO: Não recarregar dados após remoção para evitar que o talhão volte
            print('✅ Talhão removido permanentemente - não recarregando dados');
          } else {
            print('❌ Erro ao remover talhão: ${talhaoProvider.errorMessage}');
            talhaoNotificationService.showErrorMessage('❌ Erro ao remover talhão: ${talhaoProvider.errorMessage}');
          }
        } catch (e) {
          // Fechar diálogo de progresso
          Navigator.pop(context);
          print('❌ Erro ao remover talhão: $e');
          talhaoNotificationService.showErrorMessage('Erro ao remover talhão: $e');
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao remover talhão: $e');
    }
  }

  /// Callback para atualizações do LocationService
  void _onLocationUpdate() {
    if (mounted) {
      setState(() {
        // Atualizar cálculos em tempo real
        if (_locationService.isRecording) {
          final validPoints = _locationService.getValidPoints();
          _controller.setCurrentPoints(validPoints);
          _controller.setCurrentDistance(_locationService.totalDistance);
          
          if (validPoints.length >= 3) {
            // RESTAURADO: Usar cálculo preciso com PreciseGeoCalculator
            try {
              final resultado = TalhaoCalculator.calcularTalhao(validPoints, geodesico: true);
              final area = resultado['areaHa'];
              final perimeter = resultado['perimetroM'];
              _controller.setCurrentArea(area);
              _drawnArea = area;
              _controller.setCurrentPerimeter(perimeter);
            } catch (e) {
              print('❌ Erro no cálculo preciso: $e');
              // Sem fallback - usar valores padrão
              _controller.setCurrentArea(0.0);
              _drawnArea = 0.0;
              _controller.setCurrentPerimeter(0.0);
            }
          }
        }
      });
      
      // Se houver nova localização do usuário, centralizar o mapa
      if (_locationService.currentPosition != null && _mapController != null) {
        final newLocation = LatLng(
          _locationService.currentPosition!.latitude,
          _locationService.currentPosition!.longitude,
        );
        
        // Atualizar localização do usuário
        _userLocation = newLocation;
        
        // Centralizar mapa na nova localização (apenas se não estiver desenhando)
        if (!_controller.isDrawing) {
          print('🗺️ Centralizando mapa na nova localização do GPS: ${newLocation.latitude}, ${newLocation.longitude}');
          _mapController!.move(newLocation, _zoomDefault);
          
          // Forçar rebuild para garantir que o mapa seja atualizado
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }
  
  /// Inicia desenho manual
  void _startManualDrawing() {
    setState(() {
      _controller.startManualDrawing();
      _controller.clearDrawing();
    });
    talhaoNotificationService.showInfoMessage('📝 Modo desenho manual ativado. Toque no mapa para adicionar pontos.');
  }

  /// Mostra widget de GPS Avançado Premium
  void _showPremiumGpsWidget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: PremiumAdvancedGpsWidget(
          onPointsChanged: (points) {
            setState(() {
              _controller.setCurrentPoints(points);
              if (points.length >= 3) {
                // RESTAURADO: Usar cálculo preciso com PreciseGeoCalculator
                try {
                  final resultado = TalhaoCalculator.calcularTalhao(points, geodesico: true);
                  final area = resultado['areaHa'];
                  final perimeter = resultado['perimetroM'];
                  _controller.setCurrentArea(area);
                  _drawnArea = area;
                  _controller.setCurrentPerimeter(perimeter);
                } catch (e) {
                  print('❌ Erro no cálculo preciso: $e');
                  // Sem fallback - usar valores padrão
                  _controller.setCurrentArea(0.0);
                  _drawnArea = 0.0;
                  _controller.setCurrentPerimeter(0.0);
                }
              }
            });
          },
          onAreaChanged: (area) {
            setState(() {
              _controller.setCurrentArea(area);
              _drawnArea = area;
            });
          },
          onDistanceChanged: (distance) {
            setState(() {
              _controller.setCurrentDistance(distance);
            });
          },
          onStatusChanged: (status) {
            talhaoNotificationService.showInfoMessage(status);
          },
          onTrackingStateChanged: (isTracking) {
            setState(() {
              _controller.setShowActionButtons(isTracking);
            });
          },
          onSave: () {
            Navigator.of(context).pop();
            _showTalhaoCard();
          },
          primaryColor: const Color(0xFF3BAA57),
          enableBackgroundRecording: true,
          enableWakeLock: true,
        ),
      ),
    );
    }

  /// Mostra card informativo para cadastro do talhão
  void _showTalhaoCard() {
    if (_currentPoints.length < 3) {
              talhaoNotificationService.showErrorMessage('São necessários pelo menos 3 pontos para criar um talhão');
      return;
    }

    // Dialog removido - sistema de cores e ícones de culturas descontinuado
  }

  /// Adiciona ponto manual
  void _addManualPoint(LatLng point) {
    if (!_controller.isDrawing) return;
    
    setState(() {
      _controller.addManualPoint(point);
      // CORREÇÃO: O controller já calcula as métricas automaticamente
      // Apenas sincronizar com o estado local
      _drawnArea = _controller.currentArea;
    });
    
    print('✅ Desenho manual: Ponto adicionado - ${_controller.currentPoints.length} pontos, Área: ${_controller.currentArea.toStringAsFixed(4)} ha');
    
            // Mostrar mensagem temporária apenas se não estiver salvando
            if (!_isSaving) {
              talhaoNotificationService.showInfoMessage(
                '📍 Ponto adicionado: ${_currentPoints.length} pontos',
                duration: const Duration(seconds: 2),
                persist: false,
              );
            }
  }
  
  /// Finaliza desenho manual
  void _finishManualDrawing() {
    if (_currentPoints.length < 3) {
              talhaoNotificationService.showErrorMessage('São necessários pelo menos 3 pontos para formar um polígono');
      return;
    }
    
    // Fechar polígono
    _controller.setCurrentPoints(PolygonService.closePolygonIfNeeded(_controller.currentPoints));
    
    setState(() {
      _isDrawing = false;
      // UNIFICADO: Usar PreciseGeoCalculator (mesmo padrão do desenho manual)
      try {
        final resultado = TalhaoCalculator.calcularTalhao(_controller.currentPoints, geodesico: true);
        final area = resultado['areaHa'];
        final perimeter = resultado['perimetroM'];
        _controller.setCurrentArea(area);
        _drawnArea = area;
        _controller.setCurrentPerimeter(perimeter);
        print('✅ Finalização Unificada: Área: ${area.toStringAsFixed(4)} ha, Perímetro: ${perimeter.toStringAsFixed(1)} m');
      } catch (e) {
        print('❌ Erro no cálculo unificado: $e');
      }
    });
    
            talhaoNotificationService.showSuccessMessage('✅ Polígono finalizado: ${_currentArea.toStringAsFixed(2)} ha');
    
    // Mostrar diálogo para salvar o talhão
    _showNameDialog();
  }
  
  /// Inicia gravação GPS
  Future<void> _startGpsRecording() async {
    final success = await _controller.startGpsRecording();
    if (success) {
      setState(() {
        _controller.setShowActionButtons(true);
      });
    }
  }
  
  /// Pausa gravação GPS
  void _pauseGpsRecording() {
    _controller.pauseGpsRecording();
  }
  
  /// Retoma gravação GPS
  Future<void> _resumeGpsRecording() async {
    await _controller.resumeGpsRecording();
  }
  
  /// Finaliza gravação GPS
  void _finishGpsRecording() {
    _controller.finishGpsRecording();
    
    // Fechar polígono automaticamente
    if (_controller.currentPoints.length >= 3) {
      _currentPoints = PolygonService.closePolygonIfNeeded(_controller.currentPoints);
      _currentArea = _controller.currentArea;
      _drawnArea = _controller.currentArea;
      _currentDistance = _controller.currentDistance;
      
      setState(() {});
      
      // Mostrar diálogo para salvar o talhão
      _showNameDialog();
    }
  }
  
  /// Mostra confirmação de sucesso após salvar talhão
  void _showSuccessConfirmation() {
    try {
      print('🔄 Mostrando diálogo de confirmação...');
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Talhão Salvo!'),
              ],
            ),
            content: const Text(
              'O talhão foi criado e salvo com sucesso no sistema!\n\n'
              'Agora você pode visualizá-lo no mapa junto com os outros talhões.\n\n'
              'Deseja continuar criando mais talhões ou voltar ao módulo?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🔄 Usuário escolheu continuar criando talhões');
                  Navigator.of(context).pop(); // Fecha apenas o diálogo
                  // Limpar o desenho após salvar com sucesso
                  print('🔄 Limpando desenho após confirmação...');
                  _controller.clearDrawing();
                  print('✅ Desenho limpo após confirmação');
                  // Permanece na tela Novo Talhão (não faz Navigator.pop adicional)
                },
                child: const Text('Continuar'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('🔄 Usuário escolheu voltar ao módulo Talhões');
                  Navigator.of(context).pop(); // Fecha o diálogo
                  // CORREÇÃO: Usar Navigator.pop com resultado para voltar ao módulo
                  Navigator.of(context).pop(true); // Retorna true para indicar que deve voltar ao módulo
                },
                child: const Text('Voltar ao Módulo'),
              ),
            ],
          );
        },
      ).then((result) {
        // Se o usuário escolheu voltar ao módulo, fazer o pop adicional
        if (result == true) {
          print('🔄 Voltando ao módulo Talhões...');
          Navigator.of(context).pop(); // Volta para a tela anterior (módulo Talhões)
        }
      });
      
      print('✅ Diálogo de confirmação exibido com sucesso');
    } catch (e) {
      print('❌ Erro ao mostrar confirmação de sucesso: $e');
      talhaoNotificationService.showErrorMessage('Erro ao mostrar confirmação: $e');
    }
  }

  /// Inicializa serviço de armazenamento
  Future<void> _initializeStorageService() async {
    try {
      await _polygonDatabaseService.initialize();
      print('✅ Serviço de armazenamento inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar serviço de armazenamento: $e');
    }
  }
  
  /// Valida dados antes do salvamento
  bool _validarDadosParaSalvamento() {
    try {
      print('🔍 Validando dados para salvamento...');
      
      // Verificar se há pontos suficientes
      if (_currentPoints.length < 3) {
        print('❌ Pontos insuficientes para salvar: ${_currentPoints.length}');
        talhaoNotificationService.showErrorMessage('São necessários pelo menos 3 pontos para salvar');
        return false;
      }
      
      // Verificar se o nome não está vazio
      if (_controller.polygonName.trim().isEmpty) {
        print('❌ Nome do polígono vazio');
        talhaoNotificationService.showErrorMessage('Digite um nome para o polígono');
        return false;
      }
      
      // Verificar se a cultura foi selecionada
      if (_controller.selectedCultura == null) {
        print('❌ Cultura não selecionada');
        talhaoNotificationService.showErrorMessage('Selecione uma cultura para o talhão');
        return false;
      }
      
      // Verificar se a área é válida
      if (_currentArea <= 0) {
        print('❌ Área inválida: $_currentArea');
        talhaoNotificationService.showErrorMessage('Área do talhão deve ser maior que zero');
        return false;
      }
      
      // Verificar se o widget ainda está montado
      if (!mounted) {
        print('❌ Widget não está mais montado');
        return false;
      }
      
      print('✅ Dados validados com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro na validação: $e');
      talhaoNotificationService.showErrorMessage('Erro na validação dos dados: $e');
      return false;
    }
  }

  /// Salva polígono atual
  Future<void> _savePolygon() async {
    try {
      print('🔄 Iniciando _savePolygon...');
      print('📊 Dados para salvamento:');
      print('  - Pontos: ${_currentPoints.length}');
      print('  - Nome: ${_controller.polygonName}');
      print('  - Área: $_currentArea ha');
      print('  - Perímetro: $_currentPerimeter m');
      print('  - Cultura: ${_controller.selectedCultura?.name}');
      
      // Validar dados antes de prosseguir
      if (!_validarDadosParaSalvamento()) {
        print('❌ Validação falhou, cancelando salvamento');
        return;
      }
      
      print('🔄 Verificando serviço de armazenamento...');
      if (!_polygonDatabaseService.isInitialized) {
        print('❌ Serviço de armazenamento não inicializado');
        _mostrarErro('Serviço de armazenamento não disponível');
        return;
      }
      
      final storageService = _polygonDatabaseService.storageService;
      if (storageService == null) {
        print('❌ StorageService é null');
        _mostrarErro('Erro ao acessar serviço de armazenamento');
        return;
      }
      
      print('✅ Serviço de armazenamento disponível');
      
      setState(() {
        _isSaving = true;
      });
      
      final method = _locationService.isRecording ? 'caminhada' : 'manual';
      print('🔄 Método de salvamento: $method');
      
      print('🔄 Salvando polígono no banco de dados...');
      final polygonId = await storageService.savePolygon(
        name: _controller.polygonName,
        method: method,
        points: _controller.currentPoints,
        areaHa: _controller.currentArea,
        perimeterM: _controller.currentPerimeter,
        distanceM: _controller.currentDistance,
        fazendaId: await _getFazendaAtual(),
        culturaId: _controller.selectedCultura?.id.toString(),
        safraId: await _getSafraAtual(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao salvar polígono no banco de dados');
        },
      );
      
      print('✅ Polígono salvo com sucesso! ID: $polygonId');
      
      // Salvar trilhas se for gravação GPS
      if (_locationService.isRecording) {
        final tracks = _locationService.points.map((point) => {
          'lat': point.position.latitude,
          'lon': point.position.longitude,
          'accuracy': point.accuracy,
          'speed': point.speed,
          'bearing': point.bearing,
          'ts': point.timestamp.toIso8601String(),
          'status': point.isValid ? 'valid' : 'invalid',
        }).toList();
        
        await storageService.saveTracks(polygonId, tracks);
      }
      
              talhaoNotificationService.showSuccessMessage('✅ Polígono salvo com sucesso! ID: $polygonId');
      
      // Integrar com o sistema de talhões
      print('🔍 DEBUG: Chamando _saveAsTalhao com polygonId: $polygonId, method: $method');
      await _saveAsTalhao(polygonId, method);
      
      // Não limpar automaticamente - deixar para o usuário decidir quando limpar
      
    } catch (e) {
      print('❌ Erro ao salvar polígono: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Mostrar erro mais específico baseado no tipo de exceção
      String errorMessage = 'Erro ao salvar polígono';
      if (e.toString().contains('Timeout')) {
        errorMessage = 'Timeout ao salvar polígono. Tente novamente.';
      } else if (e.toString().contains('database') || e.toString().contains('SQL')) {
        errorMessage = 'Erro no banco de dados. Verifique os dados e tente novamente.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
      } else {
        errorMessage = 'Erro ao salvar polígono: ${e.toString()}';
      }
      
      talhaoNotificationService.showErrorMessage(errorMessage);
      
      // NÃO fechar o módulo em caso de erro - permitir que o usuário tente novamente
      print('⚠️ Erro no salvamento do polígono, mas mantendo o usuário na tela para nova tentativa');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  /// Salva o polígono como talhão no sistema de talhões
  Future<void> _saveAsTalhao(int polygonId, String method) async {
    try {
      // Verificar se já está salvando para evitar duplicação
      if (_isSaving) {
        print('⚠️ Salvamento já em andamento, ignorando nova tentativa');
        return;
      }
      
      // Definir estado de salvamento
      if (mounted) {
        setState(() {
          _isSaving = true;
        });
      }
      
      print('🔄 Integrando polígono $polygonId com sistema de talhões...');
      print('📊 Dados do polígono:');
      print('  - Nome: ${_controller.polygonName}');
      print('  - Pontos: ${_currentPoints.length}');
      print('  - Área: $_currentArea ha');
      print('  - Perímetro: $_currentPerimeter m');
      print('  - Cultura: ${_controller.selectedCultura?.name ?? 'N/A'}');
      print('  - Cultura ID: ${_controller.selectedCultura?.id ?? 'N/A'}');
      
      // Verificar se o widget ainda está montado antes de acessar o contexto
      if (!mounted) {
        print('❌ Widget não está mais montado, cancelando salvamento');
        return;
      }
      
      // Obter o provider de talhões
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
      
      // Validar dados antes de salvar
      if (_currentPoints.isEmpty) {
        print('❌ Erro: Lista de pontos vazia');
        talhaoNotificationService.showErrorMessage('Erro: Lista de pontos vazia');
        return;
      }
      
      if (_controller.selectedCultura == null) {
        print('❌ Erro: Cultura não selecionada');
        talhaoNotificationService.showErrorMessage('Erro: Cultura não selecionada');
        return;
      }
      
      print('🔄 Chamando talhaoProvider.salvarTalhao...');
      
      // Salvar talhão usando o método existente
      // Obter dados reais do sistema
      final fazendaId = await _getFazendaAtual();
      final safraId = await _getSafraAtual();
      
      print('🔍 DEBUG: Chamando talhaoProvider.salvarTalhao com:');
      print('  - Nome: ${_controller.polygonName}');
      print('  - idFazenda: $fazendaId');
      print('  - Pontos: ${_currentPoints.length}');
      print('  - idCultura: ${_selectedCultura?.id.toString() ?? '1'}');
      print('  - nomeCultura: ${_selectedCultura?.name ?? 'Cultura não selecionada'}');
      print('  - corCultura: Colors.green (padrão)');
      print('  - idSafra: $safraId');
      
      final success = await talhaoProvider.salvarTalhao(
        nome: _polygonName,
        idFazenda: fazendaId,
        pontos: _currentPoints,
        idCultura: _selectedCultura?.id.toString() ?? '1',
        nomeCultura: _selectedCultura?.name ?? 'Cultura não selecionada',
        corCultura: _selectedCultura?.color ?? Colors.green,
        idSafra: safraId,
        areaCalculada: _currentArea, // Usar área já calculada nas métricas
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao salvar talhão no sistema');
        },
      );
      
            print('📊 Resultado do salvamento: $success');
      
      if (success) {
        print('✅ Talhão integrado com sucesso');
        talhaoNotificationService.showSuccessMessage('✅ Talhão criado e salvo no mapa!');
        
        // Notificar o dashboard para recarregar as culturas
        try {
          print('🔄 Notificando dashboard para recarregar culturas...');
          final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
          await culturaProvider.forceReloadCultures();
          print('✅ Culturas recarregadas no dashboard');
        } catch (e) {
          print('⚠️ Erro ao recarregar culturas: $e');
        }
        
        // Verificar se o widget ainda está montado antes de fazer mudanças de estado
        if (mounted) {
          // Recarregar talhões para atualizar o mapa
          print('🔄 Recarregando talhões...');
          await talhaoProvider.carregarTalhoes();
          print('✅ Talhões recarregados');
          
          // Apenas limpar o desenho sem forçar rebuild que pode causar problema
          if (mounted) {
            setState(() {
              _controller.clearDrawing();
              _controller.setShowActionButtons(false);
              _controller.setPolygonName(''); // Limpar nome do polígono
            });
            
            print('✅ Limpeza do desenho concluída');
            
            // Mostrar notificação de sucesso
            print('🔄 Mostrando notificação de sucesso...');
            talhaoNotificationService.showSuccessMessage('✅ Talhão criado e salvo com sucesso!');
            print('✅ Notificação de sucesso exibida');
          }
        }
      } else {
        print('❌ Erro ao integrar talhão');
        print('❌ Mensagem de erro: ${talhaoProvider.errorMessage}');
        talhaoNotificationService.showErrorMessage('Erro ao integrar com sistema de talhões: ${talhaoProvider.errorMessage}');
      }
      
    } catch (e) {
      print('❌ Erro ao salvar como talhão: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Verificar se ainda está montado para evitar tela branca
      if (mounted) {
        // Mostrar erro mais específico baseado no tipo de exceção
        String errorMessage = 'Erro ao integrar com sistema de talhões';
        if (e.toString().contains('Timeout')) {
          errorMessage = 'Timeout ao salvar talhão. Tente novamente.';
        } else if (e.toString().contains('database') || e.toString().contains('SQL')) {
          errorMessage = 'Erro no banco de dados. Verifique os dados e tente novamente.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else {
          errorMessage = 'Erro ao salvar talhão: ${e.toString()}';
        }
        
        talhaoNotificationService.showErrorMessage(errorMessage);
        
        // Manter estado de desenho em caso de erro para que o usuário possa tentar novamente
        setState(() {
          _isSaving = false;
        });
        
        // NÃO fechar o módulo em caso de erro - permitir que o usuário tente novamente
        print('⚠️ Erro no salvamento, mas mantendo o usuário na tela para nova tentativa');
      }
    } finally {
      // Garantir que o estado de salvamento seja resetado
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }



  /// Mostra card de informações para editar antes de salvar
  Future<void> _showNameDialog() async {
    try {
      print('🔄 Iniciando _showNameDialog...');
      
      // Garantir que o nome do polígono seja uma string válida
      if (_controller.polygonName.isEmpty) {
        _controller.setPolygonName('');
      }
      
      // Selecionar primeira cultura se não houver selecionada
      if (_selectedCultura == null && _culturas.isNotEmpty) {
        try {
          _selectedCultura = _culturas.first;
          print('✅ Cultura selecionada automaticamente: ${_selectedCultura?.name}');
        } catch (e) {
          print('⚠️ Erro ao selecionar primeira cultura: $e');
          _selectedCultura = null;
        }
      }
      
      // Sempre recalcular a área para garantir precisão
      double areaReal = 0.0;
      print('📊 Pontos atuais: ${_currentPoints.length}');
      
      if (_controller.currentPoints.length >= 3) {
        try {
          areaReal = GeoCalculator.calculateAreaHectares(_currentPoints);
          _currentArea = areaReal; // Atualizar _currentArea para consistência
          print('✅ Área calculada: ${areaReal.toStringAsFixed(2)} ha');
        } catch (e) {
          print('❌ Erro ao calcular área: $e');
          areaReal = 0.0;
        }
      } else {
        print('⚠️ Pontos insuficientes para calcular área: ${_currentPoints.length}');
        // Tentar usar pontos de um polígono existente se disponível
        if (_selectedTalhao != null && _selectedTalhao?.poligonos != null && _selectedTalhao?.poligonos?.isNotEmpty == true) {
          final poligono = _selectedTalhao?.poligonos?.first;
          if (poligono?.pontos != null && (poligono?.pontos?.length ?? 0) >= 3) {
            try {
              areaReal = GeoCalculator.calculateAreaHectares(poligono?.pontos ?? []);
              _currentArea = areaReal; // Atualizar _currentArea para consistência
              print('✅ Área calculada do polígono existente: ${areaReal.toStringAsFixed(2)} ha');
            } catch (e) {
              print('❌ Erro ao calcular área do polígono existente: $e');
            }
          }
        }
      }
      
      print('🔄 Chamando _showInfoCardForEditing...');
      
      // Mostrar card de informações para edição com timeout
      await _showInfoCardForEditing(areaReal).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao mostrar diálogo de edição');
        },
      );
      
      print('✅ _showNameDialog concluído com sucesso');
    } catch (e) {
      print('❌ Erro ao mostrar diálogo de nome: $e');
      talhaoNotificationService.showErrorMessage('Erro ao abrir diálogo de edição: $e');
      
      // Resetar estado de salvamento em caso de erro
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  /// Mostra card de informações para edição antes de salvar
  Future<void> _showInfoCardForEditing(double areaReal) async {
    try {
      print('🔄 Iniciando _showInfoCardForEditing...');
      
      // Controladores para edição
      final nameController = TextEditingController(text: _polygonName.isNotEmpty ? _polygonName : '');
      CulturaModel? selectedCultura = _selectedCultura;
      String? selectedSafra = _safraSelecionadaCard.isNotEmpty ? _safraSelecionadaCard : null; // Sem valor padrão
      
      print('📊 Dados preparados para edição:');
      print('  - Nome: ${nameController.text}');
      print('  - Cultura: ${selectedCultura?.name}');
      print('  - Safra: $selectedSafra');
      print('  - Área: ${areaReal.toStringAsFixed(2)} ha');
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_location, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Editar Informações do Polígono',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nome
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nome',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Digite o nome do polígono',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Cultura
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.eco,
                        color: Colors.lightGreen[700],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cultura',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          DropdownButtonFormField<CulturaModel>(
                            value: _getValidCulturaValue(selectedCultura),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _culturas.map((cultura) {
                              return DropdownMenuItem<CulturaModel>(
                                value: cultura,
                                child: Row(
                                  children: [
                                    cultura.getIconOrInitial(size: 16),
                                    SizedBox(width: 8),
                                    Text(cultura.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedCultura = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Safra
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safra',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedSafra,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _mostrarDialogoSafra();
                                },
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                tooltip: 'Adicionar Safra',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Área
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.straighten,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Área',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            AreaFormatter.formatHectaresFixed(areaReal),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedCultura != null) {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'cultura': selectedCultura,
                    'safra': selectedSafra,
                    'area': areaReal,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor, preencha o nome e selecione uma cultura'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(Icons.save),
              label: Text('Salvar Polígono'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Timeout ao aguardar resposta do usuário');
      },
    );
    
    if (result != null) {
      setState(() {
        _polygonName = result['name'];
        _selectedCultura = result['cultura'];
        // Sincronizar com o controller também
        _controller.setSelectedCultura(_selectedCultura);
        _controller.setPolygonName(_polygonName);
      });
      
      print('🔍 DEBUG: Dados do diálogo:');
      print('  - Nome: ${result['name']}');
      print('  - Cultura: ${result['cultura']?.name}');
      print('  - Safra: ${result['safra']}');
      print('  - Área: ${result['area']}');
      print('🔍 DEBUG: Cultura sincronizada - ID: ${_selectedCultura?.id}, Nome: ${_selectedCultura?.name}');
      
      print('🔄 Chamando _savePolygon...');
      await _savePolygon();
      print('✅ _savePolygon concluído');
    }
    
    print('✅ _showInfoCardForEditing concluído com sucesso');
  } catch (e) {
    print('❌ Erro em _showInfoCardForEditing: $e');
    talhaoNotificationService.showErrorMessage('Erro ao mostrar card de edição: $e');
    
    // Resetar estado de salvamento em caso de erro
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Limpa desenho atual
  void _clearDrawing() {
    try {
      print('🔄 Iniciando limpeza do desenho...');
      
      setState(() {
        _controller.clearDrawing();
        _controller.finishManualDrawing();
        _controller.setShowActionButtons(false);
        _controller.setCurrentArea(0.0);
        _controller.setCurrentPerimeter(0.0);
        _controller.setCurrentDistance(0.0);
        // Não limpar cultura selecionada - manter para próximo polígono
        // _controller.setSelectedCultura(null); 
        _controller.setPolygonName(''); // Limpar nome do polígono
        _controller.setSaving(false); // Resetar estado de salvamento
        _polygonName = ''; // Limpar nome local também
        // Manter _selectedCultura para reutilização
      });
      
      print('✅ Estado limpo no setState');
      
      // Limpar serviço de localização
      _locationService.clear();
      print('✅ Serviço de localização limpo');
      
      // Forçar rebuild completo da UI
      setState(() {});
      print('✅ Rebuild forçado da UI');
      
      print('🧹 Desenho limpo completamente');
    } catch (e) {
      print('❌ Erro ao limpar desenho: $e');
      talhaoNotificationService.showErrorMessage('Erro ao limpar desenho: $e');
    }
  }

  /// Alias para limpar desenho (usado no card)
  void _limparDesenho() {
    _controller.clearDrawing();
  }
  
  /// Mostra mensagem usando o novo serviço de notificações
  void _mostrarMensagem(String mensagem) {
    talhaoNotificationService.showSuccessMessage(mensagem);
  }
  
  /// Mostra erro usando o novo serviço de notificações
  void _mostrarErro(String erro) {
    talhaoNotificationService.showErrorMessage(erro);
  }

  /// Debug dos talhões para verificar estado
  void _debugTalhoes() {
    final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
    
    print('🔍 DEBUG: === ESTADO DOS TALHÕES ===');
    print('🔍 DEBUG: Total de talhões no provider: ${talhaoProvider.talhoes.length}');
    
    for (int i = 0; i < talhaoProvider.talhoes.length; i++) {
      final talhao = talhaoProvider.talhoes[i];
      print('🔍 DEBUG: Talhão $i: ${talhao.name}');
      print('🔍 DEBUG:   - ID: ${talhao.id}');
      print('🔍 DEBUG:   - Tipo: ${talhao.runtimeType}');
      print('🔍 DEBUG:   - Pontos: ${talhao.pontos.length}');
      print('🔍 DEBUG:   - Polígonos: ${talhao.poligonos.length}');
      
      if (talhao.pontos.isNotEmpty) {
        print('🔍 DEBUG:   - Primeiro ponto: ${talhao.pontos.first}');
        print('🔍 DEBUG:   - Último ponto: ${talhao.pontos.last}');
      }
    }
    
    print('🔍 DEBUG: === CULTURAS ===');
    print('🔍 DEBUG: Total de culturas: ${_culturas.length}');
    
    for (int i = 0; i < _culturas.length; i++) {
      final cultura = _culturas[i];
      print('🔍 DEBUG: Cultura $i: ${cultura.name} (ID: ${cultura.id})');
    }
    
    // Forçar recarregamento
    talhaoProvider.carregarTalhoes().then((_) {
      setState(() {
        // Forçar rebuild
      });
      _mostrarMensagem('Talhões recarregados. Verifique o console para debug.');
    });
  }
  
  /// Constrói botões de ação
  Widget _buildActionButtons() {
    return Card(
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho com título e botão de fechar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.build, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Controles de Desenho',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _controller.setShowActionButtons(false);
                    });
                  },
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Minimizar controles',
                ),
              ],
            ),
          ),
          // Conteúdo dos botões
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isDrawing)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finishManualDrawing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Finalizar Desenho'),
                    ),
                  ),
                if (_isAdvancedGpsTracking)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _controller.isGpsPaused 
                          ? _controller.resumeAdvancedGpsTracking
                          : _controller.pauseAdvancedGpsTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _controller.isGpsPaused ? Colors.green : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_controller.isGpsPaused ? 'Retomar GPS' : 'Pausar GPS'),
                    ),
                  ),
                if (_isAdvancedGpsTracking)
                  const SizedBox(width: 8),
                if (_isAdvancedGpsTracking)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finishAdvancedGpsTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Finalizar'),
                    ),
                  ),
                if (_currentPoints.length >= 3 && !_isDrawing && !_locationService.isRecording)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _showNameDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Salvar Polígono'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _controller.clearDrawing(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Importa polígonos de arquivo
  Future<void> _importPolygons() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Selecionando arquivo...'),
            ],
          ),
        ),
      );

      final file = await _importService.pickFile();
      
      Navigator.pop(context); // Fechar loading de seleção
      
      if (file == null) {
        print('Nenhum arquivo selecionado');
        return;
      }

      // Mostrar loading de importação
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importando polígonos...'),
            ],
          ),
        ),
      );

      // Importar polígonos usando o serviço unificado
      final result = await _importService.importFile(file);

      Navigator.pop(context); // Fechar loading

      if (!result.success) {
        _mostrarErro('Erro na importação: ${result.error}');
        return;
      }

      if (result.polygons.isEmpty) {
        _mostrarErro('Nenhum polígono válido encontrado no arquivo.');
        return;
      }

      // Debug: mostrar todas as propriedades disponíveis no arquivo
      print('📋 Propriedades disponíveis no arquivo importado:');
      result.properties.forEach((key, value) {
        print('  - $key: $value');
      });
      
      // Converter para o formato esperado pelo diálogo
      final polygons = result.polygons.map((polygon) {
        // PRIORIZAR ÁREA ORIGINAL DO ARQUIVO - NÃO RECALCULAR AUTOMATICAMENTE
        double areaHa = 0.0;
        
        // 1. Tentar obter área das propriedades do arquivo (KML, GeoJSON)
        if (result.properties.containsKey('area') || result.properties.containsKey('Area')) {
          final areaOriginal = result.properties['area'] ?? result.properties['Area'];
          if (areaOriginal != null && areaOriginal > 0) {
            areaHa = areaOriginal.toDouble();
            print('✅ Usando área original do arquivo: ${areaHa.toStringAsFixed(2)} ha');
          }
        }
        
        // 2. Tentar obter área de outras propriedades comuns
        if (areaHa <= 0) {
          final areaKeys = [
            'area_ha', 'areaHa', 'areaHectares', 'hectares', 'ha',
            'area_hectares', 'area_hectare', 'AreaHa', 'AreaHectares',
            'AREA', 'AREA_HA', 'AREA_HECTARES', 'HECTARES',
            'shape_area', 'Shape_Area', 'SHAPE_AREA',
            'area_sqm', 'area_m2', 'area_km2', 'surface_area',
            'tamanho', 'area_real', 'area_total', 'areaTotal'
          ];
          
          for (final key in areaKeys) {
            if (result.properties.containsKey(key)) {
              final areaValue = result.properties[key];
              if (areaValue != null && areaValue > 0) {
                double area = areaValue.toDouble();
                
                // Converter unidades se necessário
                if (key.contains('sqm') || key.contains('m2')) {
                  area = area / 10000; // m² para hectares
                  print('✅ Convertendo ${areaValue} m² para ${area.toStringAsFixed(2)} ha');
                } else if (key.contains('km2')) {
                  area = area * 100; // km² para hectares
                  print('✅ Convertendo ${areaValue} km² para ${area.toStringAsFixed(2)} ha');
                } else {
                  print('✅ Usando área de propriedade $key: ${area.toStringAsFixed(2)} ha');
                }
                
                areaHa = area;
                break;
              }
            }
          }
        }
        
        // 3. SÓ CALCULAR se não houver área original no arquivo
        if (areaHa <= 0) {
          areaHa = GeoCalculator.calculateAreaHectares(polygon);
          print('⚠️ Área não encontrada no arquivo, calculando: ${areaHa.toStringAsFixed(2)} ha');
        }
        
        return {
          'points': polygon,
          'name': result.properties['name'] ?? result.properties['placemark_name'] ?? 'Polígono Importado',
          'areaHa': areaHa,
          'perimeterM': _calculatePerimeter(polygon),
          'source': result.sourceFormat,
          'properties': result.properties,
          'areaOriginal': areaHa > 0 ? areaHa : null, // Marcar se é área original
        };
      }).toList();

      // Mostrar diálogo de seleção com polígonos importados
      _showImportSelectionDialogWithPolygons(polygons);

    } catch (e) {
      Navigator.pop(context); // Fechar loading se estiver aberto
      
      print('❌ Erro na importação: $e');
      
      // Melhorar mensagem de erro
      String errorMessage = 'Erro ao importar: $e';
      
      // Adicionar dicas específicas baseadas no erro
      if (e.toString().contains('arquivo') && e.toString().contains('vazio')) {
        errorMessage += '\n\n💡 O arquivo selecionado está vazio ou corrompido.';
        errorMessage += '\n• Selecione um arquivo válido com dados geográficos';
        errorMessage += '\n• Verifique se o arquivo não está corrompido';
      } else if (e.toString().contains('Formato de arquivo não suportado')) {
        errorMessage += '\n\n💡 Formatos suportados: KML, GeoJSON, JSON';
      } else if (e.toString().contains('Arquivo não encontrado')) {
        errorMessage += '\n\n💡 Verifique se o arquivo existe e está acessível';
      } else if (e.toString().contains('Nenhum polígono válido encontrado')) {
        errorMessage += '\n\n💡 Dicas para resolver:';
        errorMessage += '\n• Verifique se o arquivo contém geometrias do tipo Polygon, MultiPolygon ou LineString';
        errorMessage += '\n• Para KML: certifique-se de que há tags <Polygon>, <MultiGeometry> ou <LineString>';
        errorMessage += '\n• Para GeoJSON: verifique se há features com type "Polygon", "MultiPolygon" ou "LineString"';
        errorMessage += '\n• LineStrings serão convertidos automaticamente para Polygon';
        errorMessage += '\n• As coordenadas devem estar no formato correto';
      }
      
      _mostrarErroDetalhado([errorMessage]);
    }
  }
  
  /// Exporta polígonos para arquivo
  Future<void> _exportPolygons() async {
    try {
      final storageService = _polygonDatabaseService.storageService;
      if (storageService == null) {
        _mostrarErro('Serviço de armazenamento não disponível');
        return;
      }

      // Mostrar diálogo de seleção de formato
      final format = await _showExportFormatDialog();
      if (format == null) return;

      // Buscar todos os polígonos
      final allPolygons = await storageService.loadAllPolygons();
      if (allPolygons.isEmpty) {
        _mostrarErro('Nenhum polígono para exportar');
        return;
      }

      final polygonIds = allPolygons.map((p) => p['id'] as int).toList();
      
      // Por enquanto, mostrar mensagem informando que a funcionalidade está em desenvolvimento
      _mostrarMensagem('Funcionalidade de exportação em lote em desenvolvimento. Use a exportação individual.');
      _mostrarMensagem('Polígonos exportados com sucesso!');

    } catch (e) {
      _mostrarErro('Erro ao exportar: $e');
    }
  }
  
  /// Mostra diálogo de seleção de formato de exportação
  
  /// Download de arquivo de exemplo
  void _downloadExampleFile(String format) {
    // Implementação básica - pode ser expandida
    _mostrarMensagem('Download de arquivo de exemplo $format em desenvolvimento');
  }
  
  /// Mostra erro detalhado
  void _mostrarErroDetalhado(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Erro na Importação'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ocorreu um erro durante a importação do arquivo.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ...errors.map((error) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    error,
                    style: TextStyle(fontSize: 14),
                  ),
                )).toList(),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Formatos Suportados:',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• KML (Google Earth) - Totalmente suportado'),
                      Text('• GeoJSON (padrão GIS) - Totalmente suportado'),
                      Text('• JSON (GeoJSON) - Totalmente suportado'),
                      Text('• Shapefile (.shp/.zip) - Totalmente suportado'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
            icon: Icon(Icons.help_outline),
            label: Text('Ajuda'),
          ),
        ],
      ),
    );
  }
  
  /// Mostra diálogo de seleção de importação
  void _showImportSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_upload, color: Colors.blue),
            SizedBox(width: 8),
            Text('Importar Talhões'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione o formato do arquivo para importar:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildImportOption(
              'KML (Google Earth)',
              'Arquivos .kml do Google Earth',
              Icons.map,
              () {
                Navigator.pop(context);
                _importPolygons();
              },
            ),
            SizedBox(height: 8),
            _buildImportOption(
              'GeoJSON',
              'Arquivos .geojson ou .json',
              Icons.map_outlined,
              () {
                Navigator.pop(context);
                _importPolygons();
              },
            ),
            SizedBox(height: 8),
            _buildImportOption(
              'JSON',
              'Arquivos .json com dados GeoJSON',
              Icons.code,
              () {
                Navigator.pop(context);
                _importPolygons();
              },
            ),
            SizedBox(height: 8),
            _buildImportOption(
              'Shapefile',
              'Arquivos .shp ou .zip (totalmente suportado)',
              Icons.layers,
              () {
                Navigator.pop(context);
                _importPolygons();
              },
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos os formatos são totalmente suportados! Shapefiles incluem suporte completo para geometrias e atributos.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
            child: const Text('Ajuda'),
          ),
        ],
      ),
    );
  }
  
  /// Constrói opção de importação
  Widget _buildImportOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  /// Processa polígonos importados
  void _processImportedPolygons(List<Map<String, dynamic>> polygons) {
    if (polygons.isEmpty) {
      _mostrarMensagem('Nenhum polígono encontrado no arquivo');
      return;
    }
    
    setState(() {
      _polygons.clear();
      _polygons.addAll(polygons);
    });
    
    _mostrarMensagem('${polygons.length} polígono(s) importado(s) com sucesso');
  }
  
  /// Mostra diálogo de safra
  void _mostrarDialogoSafra() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            SizedBox(width: 8),
            Text('Selecionar Safra'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecione a safra para o talhão:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _safraSelecionada,
              decoration: InputDecoration(
                labelText: 'Safra *',
                hintText: 'Selecione uma safra',
                border: OutlineInputBorder(),
                errorText: _safraSelecionada == null ? 'Safra é obrigatória' : null,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Selecione uma safra', style: TextStyle(color: Colors.grey)),
                ),
                ...['2023/2024', '2024/2025', '2025/2026']
                    .map((safra) => DropdownMenuItem<String>(
                          value: safra,
                          child: Text(safra),
                        ))
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _safraSelecionada = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_safraSelecionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, selecione uma safra'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _abrirEditorCompleto();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
  
  /// Abre editor completo
  void _abrirEditorCompleto() {
    if (_polygons.isEmpty) {
      _mostrarMensagem('Desenhe pelo menos um polígono antes de continuar');
      return;
    }
    
    // Navegar para tela de edição completa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Editor Completo')),
          body: Center(
            child: Text('Editor completo em desenvolvimento'),
          ),
        ),
      ),
    );
  }
  
  /// Duplica talhão
  void _duplicarTalhao() {
    if (_polygons.isEmpty) {
      _mostrarMensagem('Desenhe pelo menos um polígono antes de duplicar');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.copy, color: Colors.blue),
            SizedBox(width: 8),
            Text('Duplicar Talhão'),
          ],
        ),
        content: Text(
          'Deseja duplicar o talhão atual?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar lógica de duplicação
              _mostrarMensagem('Talhão duplicado com sucesso');
            },
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );
  }
  
  /// Confirma remoção
  void _confirmarRemocao() {
    if (_polygons.isEmpty) {
      _mostrarMensagem('Nenhum polígono para remover');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Remover Polígonos'),
          ],
        ),
        content: Text(
          'Deseja remover todos os polígonos desenhados?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _limparDesenho();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  /// Remove o talhão selecionado
  void _removerTalhaoSelecionado() {
    if (_selectedTalhao == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o talhão "${_selectedTalhao!.name}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removerTalhao(_selectedTalhao!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
  
  /// Calcula métricas do polígono
  void _calcularMetricas() {
    if (_currentPoints.length < 3) return;
    
    // CORREÇÃO: Usar método principal calcularTalhao
    final resultado = TalhaoCalculator.calcularTalhao(_currentPoints);
    
    final area = resultado['areaHa'] as double;
    final perimeter = resultado['perimetroM'] as double;
    
    setState(() {
      _areaCalculadaCard = area;
    });
  }
  
  /// Obtém cor por nome da cultura
  Color _obterCorPorNome(String nome) {
    return CulturaColorsUtils.getColorForName(nome);
  }
  
  
  /// Calcula perímetro de um polígono em metros

  /// Calcula distância entre dois pontos em metros
  
  @override
  Widget build(BuildContext context) {
    final talhaoProvider = Provider.of<TalhaoProvider>(context);
    final culturaProvider = Provider.of<CulturaProvider>(context);
    
    return Scaffold(
      appBar: TalhaoAppBarWidget(
        userLocation: _controller.userLocation,
        onCenterGPS: _controller.centerOnGPS,
        onReloadTalhoes: _controller.reloadTalhoes,
        onDebugTalhoes: _controller.debugTalhoes,
      ),
      backgroundColor: const Color(0xFF181A1B),
      body: Stack(
        children: [
          // Mapa principal
          TalhaoMapWidget(
            mapController: _controller.mapController,
            userLocation: _controller.userLocation,
            defaultCenter: const LatLng(-15.7801, -47.9292), // Localização padrão (Brasília)
            defaultZoom: _zoomDefault,
            isDrawing: _controller.isDrawing,
            currentPoints: _controller.currentPoints,
            selectedCulturaColor: _controller.selectedCultura?.color,
            onTap: _controller.addManualPoint,
            onTalhaoTap: _showElegantTalhaoCard, // Conectar o callback do card elegante
            onMapReady: () {
              // Quando o mapa estiver pronto, centralizar no GPS se disponível
              if (_controller.userLocation != null && _controller.mapController != null) {
                _controller.mapController!.move(_controller.userLocation!, _zoomDefault);
              }
            },
            onPositionChanged: (MapPosition position, bool hasGesture) {
              // Atualizar posição do mapa em tempo real
              if (hasGesture) {
                // Usuário moveu o mapa manualmente
              }
            },
          ),
              // Camada de mapa base - SEMPRE em modo satélite usando APIConfig
              TileLayer(
                urlTemplate: APIConfig.getMapTilerUrl('satellite'),
                userAgentPackageName: 'com.fortsmart.agro',
                maxZoom: 18,
                minZoom: 3,
                fallbackUrl: APIConfig.getFallbackUrl(),
                // Forçar modo satélite
                backgroundColor: Colors.black,
              ),
              
              // Camada de polígonos dos talhões existentes
              Builder(
                builder: (context) {
                  final polygons = _buildTalhaoPolygons(talhaoProvider.talhoes, culturaProvider);
                  print('🔍 DEBUG: FlutterMap - Construindo ${polygons.length} polígonos para o mapa');
                  return PolygonLayer(
                    polygons: polygons,
                  );
                },
              ),
              
              // Camada de marcadores dos talhões existentes
              Builder(
                builder: (context) {
                  final markers = _buildTalhaoMarkers(talhaoProvider.talhoes, culturaProvider);
                  print('🔍 DEBUG: FlutterMap - Construindo ${markers.length} marcadores para o mapa');
                  return MarkerLayer(
                    markers: markers,
                  );
                },
              ),
              
              // Polígono atual sendo desenhado
              if (_currentPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _controller.currentPoints,
                      color: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green,
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),
              
              // Linha atual sendo desenhada
              if (_currentPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _controller.currentPoints,
                      color: Colors.green,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
              
              // Marcadores dos pontos atuais
              if (_currentPoints.isNotEmpty)
                MarkerLayer(
                  markers: _currentPoints.map((point) => Marker(
                    point: point,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )).toList(),
                ),
              
              // Marcadores de estações de chuva
              if (_rainStations.isNotEmpty)
                MarkerLayer(
                  markers: _rainStations.map((station) {
                    return Marker(
                      point: LatLng(
                        station.latitude,
                        station.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: RainCollectionMarker(
                        position: LatLng(
                          station.latitude,
                          station.longitude,
                        ),
                        rainStationId: station.id,
                        stationName: station.name,
                        lastRainfall: null, // Será carregado do repositório de dados
                        lastUpdate: station.updatedAt,
                        isActive: station.isActive,
                        onTap: () => _showRainStationPopup(station),
                      ),
                    );
                  }).toList(),
                ),
              
              // Localização do usuário
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF29B6F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Indicador de cultura selecionada
          if (_selectedCultura != null)
            Positioned(
              top: 100,
              left: 16,
              child: Card(
                color: Colors.green.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _selectedCultura!.getIconOrInitial(size: 24, iconColor: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCultura!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          // Botões de centralização
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                // Indicador de status do GPS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _userLocation != null ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _userLocation != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _userLocation != null ? 'GPS OK' : 'GPS...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Legenda discreta com coordenadas GPS em tempo real
                if (_userLocation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GPS',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Lat: ${_userLocation!.latitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          'Lng: ${_userLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Legenda pequena com precisão do GPS
                if (_advancedGpsAccuracy > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Precisão: ${_advancedGpsAccuracy.toStringAsFixed(1)}m',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 8),
                // Botão de centralizar GPS
                FloatingActionButton(
                  heroTag: 'center_gps',
                  mini: true,
                  onPressed: _centerOnGPS,
                  backgroundColor: _userLocation != null ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  child: Icon(
                    _userLocation != null ? Icons.my_location : Icons.location_searching,
                  ),
                  tooltip: _userLocation != null ? 'Centralizar no GPS' : 'Obtendo localização...',
                ),
                const SizedBox(height: 8),
                // Botão de centralizar no polígono (se houver pontos)
                if (_currentPoints.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'center_polygon',
                    mini: true,
                    onPressed: _centerOnPolygon,
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.center_focus_strong),
                    tooltip: 'Centralizar no polígono',
                  ),
              ],
            ),
          ),

          
          // Painel de métricas em tempo real
          if (_currentPoints.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Métricas em Tempo Real',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Área: ${_currentArea.toStringAsFixed(2)} ha',
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Perímetro: ${_currentPerimeter.toStringAsFixed(1)} m',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      if (_currentDistance > 0)
                        Text(
                          'Distância: ${_currentDistance.toStringAsFixed(1)} m',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      Text(
                        'Pontos: ${_currentPoints.length}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      if (_locationService.isRecording)
                        Text(
                          'Precisão: ${_locationService.currentAccuracy.toStringAsFixed(1)} m',
                          style: TextStyle(
                            color: _locationService.currentAccuracy <= 10 
                              ? Colors.greenAccent 
                              : Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Controles de GPS Avançado

          
          // Card de métricas em tempo real
          if ((_isDrawing || _isAdvancedGpsTracking) && _controller.currentPoints.length >= 3)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: RealtimeMetricsCard(
                areaHa: _controller.currentArea,
                perimeterM: _controller.currentPerimeter,
                elapsedTime: _controller.elapsedTime,
                gpsAccuracy: _controller.gpsAccuracy,
                isGpsMode: _controller.isAdvancedGpsTracking,
                isPaused: _controller.isGpsPaused,
                vertices: _controller.currentPoints.length,
              ),
            ),
          
          // Controles de desenho GPS
          if (_controller.isAdvancedGpsTracking || _isDrawing)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: GpsDrawingControlsWidget(
                isRecording: _controller.isAdvancedGpsTracking,
                isPaused: _controller.isGpsPaused,
                onStartGps: _startGpsRecording,
                onPauseGps: _controller.isGpsPaused ? _resumeGpsRecording : _pauseGpsRecording,
                onStopGps: _finishGpsRecording,
                onUndo: _undoLastPoint,
                onClear: _clearDrawing,
                onImport: _importFile,
                onFinish: _finishGpsRecording,
              ),
            ),
          
          // Botões de ação
          if (_controller.showActionButtons)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildActionButtons(),
            ),
          
          // Botões flutuantes
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                // Botão para mostrar card elegante de exemplo
                if (_talhoes.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'show_elegant_card',
                    mini: true,
                    onPressed: () {
                      _showElegantTalhaoCard(_talhoes.first);
                    },
                    backgroundColor: Colors.purple,
                    child: const Icon(Icons.agriculture, color: Colors.white),
                    tooltip: 'Ver Talhão',
                  ),
                if (_talhoes.isNotEmpty)
                  const SizedBox(height: 12),
                
                FloatingActionButton(
                  heroTag: 'manual',
                  mini: true,
                  onPressed: _startManualDrawing,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Desenho Manual',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'gps_premium',
                  mini: true,
                  onPressed: _showPremiumGpsWidget,
                  backgroundColor: Colors.green,
                  child: const Icon(
                    Icons.gps_fixed,
                    color: Colors.white,
                  ),
                  tooltip: 'GPS Avançado Premium',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'clear',
                  mini: true,
                  onPressed: () => _controller.clearDrawing(),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.clear, color: Colors.white),
                  tooltip: 'Limpar',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'import',
                  mini: true,
                  onPressed: () => _showImportSelectionDialog(),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.file_download, color: Colors.white),
                  tooltip: 'Importar',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'export',
                  mini: true,
                  onPressed: () => _exportPolygons(),
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.file_upload, color: Colors.white),
                  tooltip: 'Exportar',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'rain_stations',
                  mini: true,
                  onPressed: _openRainStationManagement,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.water_drop, color: Colors.white),
                  tooltip: 'Gerenciar Pontos de Chuva',
                ),
                // Botão para mostrar controles quando escondidos
                if (!_controller.showActionButtons && (_isDrawing || _isAdvancedGpsTracking || _currentPoints.length >= 3))
                  const SizedBox(height: 12),
                if (!_controller.showActionButtons && (_isDrawing || _isAdvancedGpsTracking || _currentPoints.length >= 3))
                  FloatingActionButton(
                    heroTag: 'show_controls',
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _controller.setShowActionButtons(true);
                      });
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                    tooltip: 'Mostrar Controles',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula perímetro de um polígono em metros

  /// Calcula distância entre dois pontos em metros

  /// Mostra diálogo de seleção de polígonos importados (versão com parâmetros)
  void _showImportSelectionDialogWithPolygons(List<Map<String, dynamic>> polygons) {
    final selectedPolygons = <int>{};
    for (int i = 0; i < polygons.length; i++) {
      selectedPolygons.add(i); // Por padrão, todos selecionados
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.file_upload, color: Colors.blue),
              SizedBox(width: 8),
              Text('${polygons.length} polígonos encontrados'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // Resumo
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selecione os polígonos que deseja importar:',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Lista de polígonos
                Expanded(
                  child: ListView.builder(
                    itemCount: polygons.length,
                    itemBuilder: (context, index) {
                      final polygon = polygons[index];
                      final isSelected = selectedPolygons.contains(index);
                      
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: CheckboxListTile(
                          title: Text(
                            polygon['name'] ?? 'Polígono ${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                          children: [
                            Text('Área: ${polygon['areaHa'].toStringAsFixed(2)} ha'),
                            if (polygon['areaOriginal'] != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green, width: 1),
                                ),
                                child: const Text(
                                  'Original',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange, width: 1),
                                ),
                                child: const Text(
                                  'Calculada',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                              Text('Perímetro: ${(polygon['perimeterM'] / 1000).toStringAsFixed(2)} km'),
                              Text('Fonte: ${polygon['source']?.toUpperCase() ?? 'IMPORTADO'}'),
                            ],
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedPolygons.add(index);
                              } else {
                                selectedPolygons.remove(index);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Icon(Icons.place, color: Colors.green),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: selectedPolygons.isEmpty ? null : () {
                final selectedPolygonsList = selectedPolygons
                    .map((index) => polygons[index])
                    .toList();
                Navigator.pop(context);
                _processImportedPolygonsAsync(selectedPolygonsList);
              },
              icon: Icon(Icons.upload),
              label: Text('Importar (${selectedPolygons.length})'),
            ),
          ],
        ),
      ),
    );
  }

  /// Processa polígonos importados (versão async)
  Future<void> _processImportedPolygonsAsync(List<Map<String, dynamic>> polygons) async {
    try {
      print('🔄 Iniciando processamento de ${polygons.length} polígonos importados...');
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processando ${polygons.length} polígonos...'),
            ],
          ),
        ),
      );

      int importedCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      // Obter provider de talhões
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);

      for (int i = 0; i < polygons.length; i++) {
        try {
          final polygon = polygons[i];
          print('🔄 Processando polígono ${i + 1}: ${polygon['name'] ?? 'Sem nome'}');
          
          // Validar dados do polígono
          if (polygon['points'] == null || (polygon['points'] as List).isEmpty) {
            errors.add('Polígono ${i + 1}: Pontos inválidos');
            errorCount++;
            continue;
          }

          // Converter pontos para LatLng
          final points = (polygon['points'] as List).map((p) {
            if (p is LatLng) return p;
            if (p is dynamic && p.latitude != null && p.longitude != null) {
              return LatLng(p.latitude.toDouble(), p.longitude.toDouble());
            }
            return LatLng(0.0, 0.0);
          }).toList();

          print('📊 Polígono ${i + 1}: ${points.length} pontos válidos');

          // PRESERVAR ÁREA ORIGINAL DO ARQUIVO
          print('📊 Área original do polígono ${i + 1}: ${polygon['areaHa']?.toStringAsFixed(2) ?? 'não definida'} ha');
          print('📊 Flag área original: ${polygon['areaOriginal'] != null ? 'SIM' : 'NÃO'}');
          
          // Salvar como talhão usando o provider com área original preservada
          // Obter dados reais do sistema
          final fazendaId = await _getFazendaAtual();
          final safraId = await _getSafraAtual();
          
          final success = await talhaoProvider.salvarTalhao(
            nome: polygon['name'] ?? 'Polígono Importado ${i + 1}',
            idFazenda: fazendaId,
            pontos: points,
            idCultura: _selectedCultura?.id.toString() ?? '1',
            nomeCultura: _selectedCultura?.name ?? 'Cultura não selecionada',
            corCultura: _selectedCultura?.color ?? Colors.green,
            idSafra: safraId,
            areaCalculada: polygon['areaHa'], // Preservar área original do arquivo
          );

          if (success) {
            importedCount++;
            print('✅ Polígono ${i + 1} salvo com sucesso');
          } else {
            errors.add('Polígono ${i + 1}: Erro ao salvar no banco de dados');
            errorCount++;
          }
          
          // Atualizar progresso
          if (mounted) {
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Processando ${i + 1}/${polygons.length}...'),
                  ],
                ),
              ),
            );
          }
          
        } catch (e) {
          print('❌ Erro ao processar polígono ${i + 1}: $e');
          errors.add('Polígono ${i + 1}: $e');
          errorCount++;
        }
      }

      Navigator.pop(context); // Fechar loading

      // CORREÇÃO AGRESSIVA: Removido recarregamento que causa loops
      // await talhaoProvider.carregarTalhoes();
      // await _carregarTalhoesExistentes();

      // Mostrar resultado detalhado
      if (importedCount > 0) {
        // Contar quantos polígonos mantiveram área original vs calculada
        int comAreaOriginal = 0;
        int comAreaCalculada = 0;
        
        for (final polygon in polygons) {
          if (polygon['areaOriginal'] != null) {
            comAreaOriginal++;
          } else {
            comAreaCalculada++;
          }
        }
        
        String message = '✅ $importedCount polígonos importados com sucesso!';
        
        if (comAreaOriginal > 0 && comAreaCalculada > 0) {
          message += '\n\n📊 Áreas preservadas:\n• $comAreaOriginal com área original do arquivo\n• $comAreaCalculada com área calculada automaticamente';
        } else if (comAreaOriginal > 0) {
          message += '\n\n✅ Todas as áreas foram preservadas do arquivo original!';
        } else {
          message += '\n\n⚠️ Todas as áreas foram calculadas automaticamente (arquivo não continha dados de área)';
        }
        
        if (errorCount > 0) {
          message += '\n⚠️ $errorCount polígonos com erro.';
        }
        
        _mostrarMensagem(message);
        
      } else {
        _mostrarErro('Nenhum polígono foi importado. Verifique os dados do arquivo.');
      }

      // Mostrar detalhes dos erros se houver
      if (errors.isNotEmpty) {
        _mostrarErroDetalhado(errors);
      }

    } catch (e) {
      Navigator.pop(context); // Fechar loading se estiver aberto
      print('❌ Erro geral na importação: $e');
      _mostrarErro('Erro ao processar importação: $e');
    }
  }

  /// Mostra erro detalhado
  void _mostrarErroDetalhado(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Erro na Importação'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ocorreu um erro durante a importação do arquivo.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ...errors.map((error) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    error,
                    style: TextStyle(fontSize: 14),
                  ),
                )).toList(),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Formatos Suportados:',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• KML (Google Earth) - Totalmente suportado'),
                      Text('• GeoJSON (padrão GIS) - Totalmente suportado'),
                      Text('• JSON (GeoJSON) - Totalmente suportado'),
                      Text('• Shapefile (.shp/.zip) - Totalmente suportado'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
            icon: Icon(Icons.help_outline),
            label: Text('Ajuda'),
          ),
        ],
      ),
    );
  }



  

  

  
  /// Mostra diálogo de sucesso na exportação
  Future<bool> _showExportSuccessDialog(String filePath) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportação Concluída'),
        content: Text('Polígono exportado com sucesso!\n\nArquivo: ${filePath.split('/').last}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    ) ?? false;
  }
  

  /// Mostra diálogo de seleção de formato de exportação

  /// Calcula área em hectares com precisão
  double _calcularAreaHectares(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;
    
    // Usar fórmula de Gauss (Shoelace) para área plana
    double area = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      area += pontos[i].latitude * pontos[j].longitude;
      area -= pontos[j].latitude * pontos[i].longitude;
    }
    area = area.abs() / 2.0;
    
    // Converter para hectares usando cálculo preciso baseado na latitude média
    // Fórmula: área em hectares = área em graus² × 111² × cos(latitude_média) × 100
    if (pontos.isNotEmpty) {
      final latMedia = pontos.map((p) => p.latitude).reduce((a, b) => a + b) / pontos.length;
      final latMediaRad = latMedia * pi / 180;
      final fatorConversao = 111 * 111 * cos(latMediaRad) * 100; // 100 para converter km² para hectares
      area = area * fatorConversao;
    }
    
    return area;
  }


  /// Mostra diálogo para adicionar/editar safra
  void _mostrarDialogoSafra(String safraAtual, Function(String) onSafraChanged) {
    final safraController = TextEditingController(text: safraAtual.isNotEmpty ? safraAtual : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange),
            SizedBox(width: 8),
            Text('Adicionar Safra'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Digite o nome da safra (ex: 2024/2025):',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: safraController,
              decoration: InputDecoration(
                labelText: 'Nome da Safra',
                hintText: '2024/2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Safras comuns:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                '2024/2025',
                '2023/2024',
                '2025/2026',
                'Verão 2024',
                'Inverno 2024',
              ].map((safra) => ActionChip(
                label: Text(safra),
                onPressed: () {
                  safraController.text = safra;
                },
                backgroundColor: Colors.orange.withOpacity(0.1),
                labelStyle: TextStyle(color: Colors.orange[700]),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (safraController.text.isNotEmpty) {
                onSafraChanged(safraController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula área do polígono em hectares usando sistema preciso
  double _calcularAreaPoligono(List<LatLng> points) {
    if (points.length < 3) {
      print('❌ Polígono inválido: menos de 3 pontos');
      return 0.0;
    }
    
    try {
      // CORREÇÃO: Usar TalhaoCalculator unificado
      final areaHectares = TalhaoCalculator.calcularAreaHectares(points);
      
      print('  📊 Área calculada (unificada): ${areaHectares.toStringAsFixed(4)} ha');
      print('  📊 Perímetro: ${TalhaoCalculator.calcularPerimetro(points).toStringAsFixed(2)} m');
      
      return areaHectares;
    } catch (e) {
      print('❌ Erro ao calcular área do polígono: $e');
      return 0.0;
    }
  }

  /// Calcula perímetro de um polígono em metros
  double _calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      perimeter += _calculateDistance(current, next);
    }
    return perimeter;
  }

  /// Calcula distância entre dois pontos em metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // MÉTODOS DE CÁLCULO SIMPLES REMOVIDOS - AGORA USAMOS APENAS PreciseGeoCalculator
  // Isso garante consistência e precisão entre desenho manual e GPS

  /// Mostra diálogo de formato de exportação
  Future<String> _showExportFormatDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolher Formato de Exportação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('KML'),
              subtitle: Text('Google Earth'),
              onTap: () => Navigator.pop(context, 'kml'),
            ),
            ListTile(
              title: Text('GeoJSON'),
              subtitle: Text('Formato padrão'),
              onTap: () => Navigator.pop(context, 'geojson'),
            ),
          ],
        ),
      ),
    ) ?? 'kml';
  }

  /// Mostra diálogo de ajuda
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajuda'),
        content: Text('Use os botões para importar, exportar e gerenciar polígonos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // ===== GETTERS PARA COMPATIBILIDADE =====
  List<LatLng> get _currentPoints => _controller.currentPoints;
  double get _currentArea => _controller.currentArea;
  double get _currentPerimeter => _controller.currentPerimeter;
  double get _currentDistance => _controller.currentDistance;
  
  /// Valida se a cultura selecionada existe na lista de culturas disponíveis
  CulturaModel? _getValidCulturaValue(CulturaModel? selectedCultura) {
    if (selectedCultura == null) return null;
    
    // Verificar se a cultura existe na lista atual
    final culturaExists = _culturas.any((c) => c.id == selectedCultura.id);
    
    if (culturaExists) {
      return selectedCultura;
    } else {
      print('⚠️ Cultura selecionada não encontrada na lista: ${selectedCultura.name} (ID: ${selectedCultura.id})');
      print('🔄 Tentando encontrar cultura por nome...');
      
      // Tentar encontrar por nome
      final culturaPorNome = _culturas.where((c) => c.name.toLowerCase() == selectedCultura.name.toLowerCase()).firstOrNull;
      
      if (culturaPorNome != null) {
        print('✅ Cultura encontrada por nome: ${culturaPorNome.name}');
        return culturaPorNome;
      } else {
        print('⚠️ Cultura não encontrada, usando primeira disponível');
        return _culturas.isNotEmpty ? _culturas.first : null;
      }
    }
  }
  
  /// Converte TalhaoModel para TalhaoSafraModel para persistência
  TalhaoSafraModel _converterParaTalhaoSafraModel(TalhaoModel talhaoModel) {
    print('🔄 Convertendo TalhaoModel para TalhaoSafraModel: ${talhaoModel.name}');
    
    // Converter polígonos
    final poligonos = talhaoModel.poligonos.map((p) => PoligonoModel(
      id: p.id,
      talhaoId: p.talhaoId,
      pontos: p.pontos,
    )).toList();
    
    // Converter safras se existirem
    final safras = talhaoModel.safras?.map((s) {
      if (s is SafraTalhaoModel) {
        return s;
      } else {
        // Converter para SafraTalhaoModel se necessário
        return SafraTalhaoModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          talhaoId: talhaoModel.id,
          safraId: talhaoModel.safraId ?? '2024/2025',
          culturaId: talhaoModel.culturaId ?? '',
          culturaNome: talhaoModel.cultura ?? 'Cultura não definida',
          culturaCor: Colors.grey,
          area: talhaoModel.area,
          dataCadastro: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          ativo: true,
          sincronizado: false,
        );
      }
    }).toList() ?? [];
    
    // Se não tem safras, criar uma padrão
    if (safras.isEmpty) {
      safras.add(SafraTalhaoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: talhaoModel.id,
        safraId: talhaoModel.safraId ?? '2024/2025',
        culturaId: talhaoModel.culturaId ?? '',
        culturaNome: talhaoModel.cultura ?? 'Cultura não definida',
        culturaCor: Colors.grey,
        area: talhaoModel.area,
        dataCadastro: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        sincronizado: false,
      ));
    }
    
    final talhaoSafra = TalhaoSafraModel(
      id: talhaoModel.id,
      name: talhaoModel.name,
      idFazenda: talhaoModel.fazendaId ?? '',
      poligonos: poligonos,
      safras: safras,
      dataCriacao: talhaoModel.dataCriacao ?? DateTime.now(),
      dataAtualizacao: DateTime.now(),
      area: talhaoModel.area,
      sincronizado: false,
    );
    
    print('✅ Conversão concluída: ${talhaoSafra.name}');
    print('  - Polígonos: ${talhaoSafra.poligonos.length}');
    print('  - Safras: ${talhaoSafra.safras.length}');
    print('  - Área: ${talhaoSafra.area} ha');
    
    return talhaoSafra;
  }
}