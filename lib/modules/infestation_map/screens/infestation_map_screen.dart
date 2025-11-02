import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../utils/logger.dart';
import '../../../services/talhao_unified_service.dart';
import '../../../models/talhao_model.dart';
import '../../../repositories/organism_catalog_repository.dart';
import '../../../models/organism_catalog.dart';
import '../../../repositories/infestacao_repository.dart';
import '../../../models/infestacao_model.dart';
import '../../../models/monitoring_point.dart' as monitoring;
import '../../../models/monitoring.dart';
import '../../../database/app_database.dart';
import '../../../utils/enums.dart';
import '../../../routes.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/infestation_calculation_service.dart';
import '../repositories/repositories.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';
import 'infestation_details_screen.dart';
import 'alert_details_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/infestation_data_diagnostic_service.dart';
import '../../../services/dashboard_data_service.dart';
import '../../../services/monitoring_infestation_integration_service.dart';
import '../../../services/infestation_map_debug_service.dart';
import '../../../services/ai_monitoring_integration_service.dart';
import '../../../services/intelligent_heatmap_service.dart';
import '../../../services/intelligent_hexagon_service.dart';
import '../../../services/intelligent_alerts_service.dart';
import '../../../services/advanced_ai_prediction_service.dart';
import '../../../services/intelligent_reports_service.dart';
import '../../../services/complete_integration_service.dart';
import '../../../services/diagnosis_feedback_service.dart';

// Nova API MapTiler centralizada
import '../../../utils/api_config.dart';
import '../../../services/maptiler_service.dart';

/// Tela principal do mapa de infestação
class InfestationMapScreen extends StatefulWidget {
  const InfestationMapScreen({Key? key}) : super(key: key);

  @override
  State<InfestationMapScreen> createState() => _InfestationMapScreenState();
}

class _InfestationMapScreenState extends State<InfestationMapScreen> {
  late final MapController _mapController;
  final TalhaoUnifiedService _talhaoUnifiedService = TalhaoUnifiedService();
  final AIMonitoringIntegrationService _aiService = AIMonitoringIntegrationService();
  final OrganismCatalogRepository _organismRepository = OrganismCatalogRepository();
  final IntelligentHeatmapService _heatmapService = IntelligentHeatmapService();
  final IntelligentHexagonService _hexagonService = IntelligentHexagonService();
  final IntelligentAlertsService _alertsService = IntelligentAlertsService();
  final AdvancedAIPredictionService _predictionService = AdvancedAIPredictionService();
  final IntelligentReportsService _reportsService = IntelligentReportsService();
  final CompleteIntegrationService _integrationService = CompleteIntegrationService();
  final DiagnosisFeedbackService _feedbackService = DiagnosisFeedbackService();
  InfestacaoRepository? _infestacaoRepository;
  
  // Estado da tela
  bool _isLoading = true;
  String _currentMapType = 'satellite';
  LatLng? _currentLocation;
  String? _errorMessage;
  
  // Sistema de Aprendizado - OFFLINE
  double _systemConfidence = 0.75; // Confiança geral do sistema (atualizada por feedback)
  Map<String, double> _cropConfidenceMap = {}; // Confiança por cultura
  Map<String, Map<String, double>> _farmOrganismPatterns = {}; // Padrões locais
  
  // Dados do mapa
  List<InfestationSummary> _infestationSummaries = [];
  List<InfestationAlert> _activeAlerts = [];
  List<TalhaoModel> _talhoes = [];
  List<OrganismCatalog> _organisms = [];
  
  // Dados inteligentes
  List<IntelligentHeatmapPoint> _intelligentHeatmapPoints = [];
  List<IntelligentHexagon> _intelligentHexagons = [];
  List<IntelligentAlert> _intelligentAlerts = [];
  
  // Dados de IA avançada
  List<AIPointPrediction> _aiPointPredictions = [];
  List<TalhaoAIPrediction> _aiTalhaoPredictions = [];
  EconomicAnalysis? _economicAnalysis;
  ExecutiveReport? _executiveReport;
  
  // Dados de integração completa
  CompleteIntegrationResult? _integrationResult;
  
  // Filtros
  late InfestationFilters _filters;
  
  // Controles de visualização
  bool _showHeatmap = true;
  bool _showPoints = true;
  bool _showPolygons = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeScreen();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Inicializa a tela de forma completamente segura
  Future<void> _initializeScreen() async {
    try {
      Logger.info('🔄 [INFESTACAO] Iniciando inicialização segura da tela...');
      
      // 1. Inicializar repositório de infestação
      await _initializeInfestationRepository();
      
      // 2. Inicializar filtros
      await _initializeFilters();
      
      // 3. Carregar organismos do catálogo
      await _loadOrganisms();
      
      // 4. Carregar talhões
      await _loadTalhoes();
      
      // 5. Obter localização atual
      await _getCurrentLocation();
      
      // 6. Inicializar mapa
      _initializeMap();
      
      // 7. Carregar dados de infestação
      await _loadInfestationData();
      
      // 8. NOVO: Carregar dados de feedback para ajustar confiança (OFFLINE)
      await _loadFeedbackData();
      
      // 9. Garantir que há dados para exibir
      await _ensureInfestationDataAvailable();
      
      Logger.info('✅ [INFESTACAO] Tela inicializada com sucesso');
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro na inicialização: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao inicializar: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Inicializa o repositório de infestação
  Future<void> _initializeInfestationRepository() async {
    try {
      final database = await AppDatabase.instance.database;
      _infestacaoRepository = InfestacaoRepository(database);
      await _infestacaoRepository!.createTable();
      Logger.info('✅ [INFESTACAO] Repositório de infestação inicializado');
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao inicializar repositório: $e');
      _infestacaoRepository = null;
    }
  }

  /// Inicializa filtros de forma segura
  Future<void> _initializeFilters() async {
    try {
      _filters = InfestationFilters.defaultFilters();
      Logger.info('✅ [INFESTACAO] Filtros inicializados');
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao inicializar filtros: $e');
      _filters = InfestationFilters.defaultFilters();
    }
  }

  /// Carrega organismos do catálogo (validados)
  Future<void> _loadOrganisms() async {
    try {
      Logger.info('🔄 [INFESTACAO] Carregando organismos validados do catálogo...');
      
      // Usar o serviço de integração para obter organismos validados
      final integrationService = OrganismCatalogIntegrationService();
      final organisms = await integrationService.getValidatedOrganisms();
      
      if (mounted) {
        setState(() {
          _organisms = organisms;
        });
      }
      Logger.info('✅ [INFESTACAO] ${organisms.length} organismos validados carregados');
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao carregar organismos: $e');
      _organisms = [];
    }
  }

  /// Carrega talhões
  Future<void> _loadTalhoes() async {
    try {
      final talhoes = await _talhaoUnifiedService.getAllTalhoes();
      if (mounted) {
        setState(() {
          _talhoes = talhoes;
        });
      }
      Logger.info('✅ [INFESTACAO] ${talhoes.length} talhões carregados');
      } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao carregar talhões: $e');
      _talhoes = [];
    }
  }

  /// Inicializa o mapa
  void _initializeMap() {
    try {
      // Configurações básicas do mapa
      Logger.info('✅ [INFESTACAO] Mapa inicializado');
        } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao inicializar mapa: $e');
    }
  }

  /// Calcula a média de infestação usando dados do catálogo
  Future<double> _calculateAverageInfestation(List<InfestacaoModel> occurrences, String organismoId) async {
    try {
      final calculationService = InfestationCalculationService();
      double totalInfestation = 0.0;
      int validOccurrences = 0;
      
      for (final occurrence in occurrences) {
        // Buscar organismo no catálogo para obter unidade
        OrganismCatalog? organism;
        try {
          organism = _organisms.firstWhere(
            (org) => org.id == organismoId || org.name.toLowerCase().contains(organismoId.toLowerCase()),
          );
        } catch (e) {
          organism = _organisms.isNotEmpty ? _organisms.first : null;
        }
        
        if (organism != null) {
          // Calcular percentual usando dados do catálogo
          final pct = calculationService.pctFromQuantity(
            quantity: occurrence.percentual,
            unidade: organism.unit,
            org: organism,
            totalPlantas: 100, // Valor padrão, pode ser ajustado conforme necessário
          );
          
          totalInfestation += pct;
          validOccurrences++;
        } else {
          // Fallback: usar percentual direto
          totalInfestation += occurrence.percentual;
          validOccurrences++;
        }
      }
      
      return validOccurrences > 0 ? totalInfestation / validOccurrences : 0.0;
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao calcular média de infestação: $e');
      // Fallback: média simples dos percentuais
      return occurrences.map((o) => o.percentual).reduce((a, b) => a + b) / occurrences.length;
    }
  }

  /// Determina o nível de infestação usando thresholds do catálogo
  Future<String> _determineInfestationLevel(String organismoId, double infestationValue) async {
    try {
      // Usar o InfestationCalculationService para determinar o nível
      final calculationService = InfestationCalculationService();
      final level = await calculationService.levelFromPct(infestationValue, organismoId: organismoId);
      
      Logger.info('✅ [INFESTACAO] Nível determinado: $level para organismo $organismoId (valor: $infestationValue)');
      return level;
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao determinar nível de infestação: $e');
      
      // Fallback: buscar organismo no catálogo local
      try {
        OrganismCatalog? organism;
        try {
          organism = _organisms.firstWhere(
            (org) => org.id == organismoId || org.name.toLowerCase().contains(organismoId.toLowerCase()),
          );
        } catch (e) {
          organism = _organisms.isNotEmpty ? _organisms.first : null;
        }
        
        if (organism != null) {
          final alertLevel = organism.getAlertLevel((infestationValue ?? 0.0).toInt());
          switch (alertLevel) {
            case monitoring.AlertLevel.low:
              return 'BAIXO';
            case monitoring.AlertLevel.medium:
              return 'MODERADO';
            case monitoring.AlertLevel.high:
              return 'ALTO';
            case monitoring.AlertLevel.critical:
              return 'CRÍTICO';
            default:
              return 'BAIXO';
          }
        }
      } catch (fallbackError) {
        Logger.error('❌ [INFESTACAO] Erro no fallback: $fallbackError');
      }
      
      // Último fallback: valores fixos
      if (infestationValue >= 10) return 'CRÍTICO';
      if (infestationValue >= 6) return 'ALTO';
      if (infestationValue >= 3) return 'MODERADO';
      return 'BAIXO';
    }
  }

  /// Garante que há dados de infestação disponíveis
  Future<void> _ensureInfestationDataAvailable() async {
    try {
      if (_infestationSummaries.isEmpty) {
        Logger.info('🔄 [INFESTACAO] Nenhum dado encontrado, gerando dados de teste...');
        
        // Usar o DashboardDataService para gerar dados de teste
        final dashboardService = DashboardDataService();
        await dashboardService.initialize();
        await dashboardService.generateTestInfestationData();
        
        // Recarregar dados após gerar
        await _loadInfestationData();
        
        Logger.info('✅ [INFESTACAO] Dados de teste gerados e carregados');
      } else {
        Logger.info('✅ [INFESTACAO] Dados já disponíveis: ${_infestationSummaries.length} resumos');
      }
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao garantir dados: $e');
    }
  }

  /// Carrega dados de infestação do módulo de monitoramento
  Future<void> _loadInfestationData() async {
    try {
      Logger.info('🔄 [INFESTACAO] Carregando dados reais do monitoramento...');
      
      // Usar o novo serviço de integração para obter dados
      final integrationService = MonitoringInfestationIntegrationService();
      
      // Carregar dados de todos os talhões
      final allSummaries = <InfestationSummary>[];
      final allAlerts = <InfestationAlert>[];
      
      for (final talhao in _talhoes) {
        // Obter dados de infestação do talhão
        final talhaoSummaries = await integrationService.getInfestationDataForTalhao(talhao.id);
        allSummaries.addAll(talhaoSummaries);
        
        // Obter alertas do talhão
        final talhaoAlerts = await integrationService.getActiveAlerts(talhaoId: talhao.id);
        allAlerts.addAll(talhaoAlerts);
      }
      
      Logger.info('📊 [INFESTACAO] ${allSummaries.length} resumos de infestação encontrados');
      Logger.info('🚨 [INFESTACAO] ${allAlerts.length} alertas ativos encontrados');
      
      // Aplicar filtros
      List<InfestationSummary> filteredSummaries = allSummaries;
      
      // Filtrar por categoria de organismo se especificado
      if (_filters.organismTypes != null && _filters.organismTypes!.isNotEmpty) {
        filteredSummaries = filteredSummaries.where((summary) {
          // Buscar organismo no catálogo para verificar o tipo
          try {
            final organism = _organisms.firstWhere(
              (org) => org.id == summary.organismoId,
            );
            final organismType = organism.type.toString().toLowerCase();
            return _filters.organismTypes!.any((selectedType) => 
              organismType.contains(selectedType.toLowerCase()));
          } catch (e) {
            // Se não encontrar o organismo, não incluir no filtro
            return false;
          }
        }).toList();
      }
      
      // Filtrar por talhão se especificado
      if (_filters.talhaoId != null && _filters.talhaoId!.isNotEmpty) {
        filteredSummaries = filteredSummaries.where((summary) => 
          summary.talhaoId == _filters.talhaoId).toList();
      }
      
      // Filtrar por nível se especificado
      if (_filters.niveis != null && _filters.niveis!.isNotEmpty) {
        filteredSummaries = filteredSummaries.where((summary) => 
          _filters.niveis!.contains(summary.level)).toList();
      }
      
      // Filtrar por período se especificado
      if (_filters.dataInicio != null || _filters.dataFim != null) {
        filteredSummaries = filteredSummaries.where((summary) {
          if (_filters.dataInicio != null && summary.lastUpdate.isBefore(_filters.dataInicio!)) {
            return false;
          }
          if (_filters.dataFim != null && summary.lastUpdate.isAfter(_filters.dataFim!)) {
            return false;
          }
          return true;
        }).toList();
      }
      
      Logger.info('🔍 [INFESTACAO] ${filteredSummaries.length} resumos filtrados carregados');
      
      if (mounted) {
        setState(() {
          _infestationSummaries = filteredSummaries;
          _activeAlerts = allAlerts;
          _isLoading = false;
        });
      }
      
      // Gerar heatmap inteligente após carregar dados
      await _generateIntelligentHeatmap();
      
      Logger.info('✅ [INFESTACAO] ${filteredSummaries.length} resumos e ${allAlerts.length} alertas carregados');
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: $e';
        });
      }
    }
  }

  /// Atualiza filtros
  void _updateFilters(InfestationFilters newFilters) {
    final oldTalhaoId = _filters.talhaoId;
    final newTalhaoId = newFilters.talhaoId;
    
    setState(() {
      _filters = newFilters;
    });
    
    // Se o talhão foi alterado, centralizar no novo talhão selecionado
    if (oldTalhaoId != newTalhaoId && newTalhaoId != null && newTalhaoId.isNotEmpty) {
      _centerOnSelectedTalhao(newTalhaoId);
    }
    
    _applyFilters();
  }

  /// Aplica filtros aos dados
  void _applyFilters() {
    _loadInfestationData();
  }

  /// Limpa filtros
  void _clearFilters() {
    setState(() {
      _filters = InfestationFilters.defaultFilters();
    });
    _applyFilters();
  }

  /// Converte percentual para nível de infestação
  String _getLevelFromPercentual(int percentual) {
    if (percentual <= 25) return 'BAIXO';
    if (percentual <= 50) return 'MODERADO';
    if (percentual <= 75) return 'ALTO';
    return 'CRÍTICO';
  }

  /// Obtém organismos filtrados por tipo
  List<OrganismCatalog> _getFilteredOrganisms() {
    List<OrganismCatalog> filtered = _organisms;
    
    // Filtrar por tipo de organismo se especificado
    if (_filters.organismTypes != null && _filters.organismTypes!.isNotEmpty) {
      filtered = filtered.where((organism) {
        final organismType = organism.type.toString().toLowerCase();
        return _filters.organismTypes!.any((selectedType) => 
          organismType.contains(selectedType.toLowerCase()));
      }).toList();
    }
    
    // Remover duplicatas por nome (caso ainda existam)
    final uniqueOrganisms = <String, OrganismCatalog>{};
    for (final organism in filtered) {
      final key = organism.name.toLowerCase().trim();
      if (!uniqueOrganisms.containsKey(key)) {
        uniqueOrganisms[key] = organism;
      }
    }
    
    // Ordenar por tipo e depois por nome
    final sortedOrganisms = uniqueOrganisms.values.toList();
    sortedOrganisms.sort((a, b) {
      final typeComparison = a.type.toString().compareTo(b.type.toString());
      if (typeComparison != 0) return typeComparison;
      return a.name.compareTo(b.name);
    });
    
    return sortedOrganisms;
  }

  /// Obtém ícone para tipo de organismo
  IconData _getOrganismTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'occurrencetype.pest':
        return Icons.bug_report;
      case 'occurrencetype.disease':
        return Icons.healing;
      case 'occurrencetype.weed':
        return Icons.eco;
      default:
        return Icons.bug_report;
    }
  }

  /// Aplica filtro por tipo de organismo
  List<InfestacaoModel> _applyOrganismTypeFilter(List<InfestacaoModel> occurrences) {
    if (_filters.organismTypes == null || _filters.organismTypes!.isEmpty) {
      return occurrences;
    }

    return occurrences.where((occurrence) {
      // Mapear tipos de ocorrência para tipos de filtro
      String organismType = '';
      switch (occurrence.tipo.toLowerCase()) {
        case 'pest':
        case 'praga':
          organismType = 'pest';
          break;
        case 'disease':
        case 'doenca':
          organismType = 'disease';
          break;
        case 'weed':
        case 'planta_daninha':
          organismType = 'weed';
          break;
      }

      return _filters.organismTypes!.contains(organismType);
    }).toList();
  }

  /// Alterna visualização de satélite
  void _toggleSatellite() {
    setState(() {
      _currentMapType = _currentMapType == 'satellite' ? 'streets' : 'satellite';
    });
    Logger.info('🗺️ Tipo de mapa alterado para: $_currentMapType');
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Centraliza o mapa no talhão selecionado
  void _centerOnSelectedTalhao(String talhaoId) {
    try {
      final selectedTalhao = _talhoes.firstWhere(
        (talhao) => talhao.id == talhaoId,
      );
      
      Logger.info('🔄 [INFESTACAO] Centralizando mapa no talhão: ${selectedTalhao.name}');
      
      // Calcular centro do talhão
      LatLng center;
      if (selectedTalhao.poligonos.isNotEmpty && selectedTalhao.poligonos.first.pontos.isNotEmpty) {
        // Usar centro dos polígonos se disponível
        final pontos = selectedTalhao.poligonos.first.pontos;
        if (pontos.isNotEmpty) {
          double latSum = 0;
          double lngSum = 0;
          int count = 0;
          
          for (final ponto in pontos) {
            if (ponto is LatLng) {
              latSum += ponto.latitude;
              lngSum += ponto.longitude;
              count++;
            }
          }
          
          if (count > 0) {
            center = LatLng(latSum / count, lngSum / count);
          } else {
            center = const LatLng(-23.5505, -46.6333); // Fallback para São Paulo
          }
        } else {
          center = const LatLng(-23.5505, -46.6333); // Fallback para São Paulo
        }
      } else {
        center = const LatLng(-23.5505, -46.6333); // Fallback para São Paulo
      }
      
      // Centralizar mapa no talhão com zoom apropriado
      _mapController.move(center, 14.0);
      
      Logger.info('✅ [INFESTACAO] Mapa centralizado no talhão: ${selectedTalhao.name}');
      _showSuccessSnackBar('Mapa centralizado no talhão: ${selectedTalhao.name}');
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao centralizar no talhão: $e');
    }
  }

  /// Obtém a localização atual do dispositivo
  Future<void> _getCurrentLocation() async {
    try {
      Logger.info('📍 [INFESTACAO] Obtendo localização atual...');
      
      // Verificar se o GPS está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.warning('⚠️ [INFESTACAO] GPS desabilitado');
        _showErrorMessage('GPS está desabilitado. Habilite nas configurações.');
        return;
      }
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.warning('⚠️ [INFESTACAO] Permissão de localização negada');
          _showErrorMessage('Permissão de localização negada');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Logger.warning('⚠️ [INFESTACAO] Permissão de localização negada permanentemente');
        _showErrorMessage('Permissão de localização negada permanentemente. Configure nas configurações.');
        return;
      }
      
      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      final userLocation = LatLng(position.latitude, position.longitude);
      Logger.info('📍 [INFESTACAO] Localização obtida: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _currentLocation = userLocation;
        });
        
        // Centralizar mapa na localização atual
        _centerMapOnLocation(userLocation);
      }
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao obter localização: $e');
      _showErrorMessage('Erro ao obter localização: $e');
    }
  }
  
  /// Centraliza o mapa em uma localização específica
  void _centerMapOnLocation(LatLng location) {
    try {
      _mapController.move(location, 16.0);
      Logger.info('✅ [INFESTACAO] Mapa centralizado em: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao centralizar mapa: $e');
    }
  }
  
  /// Centraliza o mapa no talhão selecionado
  void _centerMapOnSelectedTalhao() {
    if (_filters.talhaoId != null && _filters.talhaoId!.isNotEmpty) {
      final selectedTalhao = _talhoes.firstWhere(
        (talhao) => talhao.id == _filters.talhaoId,
        orElse: () => _talhoes.first,
      );
      
      if (selectedTalhao.poligonos.isNotEmpty) {
        final poligono = selectedTalhao.poligonos.first;
        if (poligono.pontos.isNotEmpty) {
          // Calcular centro do polígono
          double centerLat = 0.0;
          double centerLng = 0.0;
          
          for (final ponto in poligono.pontos) {
            centerLat += ponto.latitude;
            centerLng += ponto.longitude;
          }
          
          centerLat /= poligono.pontos.length;
          centerLng /= poligono.pontos.length;
          
          final centerLocation = LatLng(centerLat, centerLng);
          _centerMapOnLocation(centerLocation);
          
          Logger.info('✅ [INFESTACAO] Mapa centralizado no talhão: ${selectedTalhao.name}');
        }
      }
    } else {
      Logger.warning('⚠️ [INFESTACAO] Nenhum talhão selecionado para centralizar');
    }
  }
  
  /// Mostra mensagem de erro
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se há erro na inicialização
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Infestação'),
          backgroundColor: const Color(0xFF2A4F3D),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro de Inicialização',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _initializeScreen();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando mapa de infestação...'),
                ],
              ),
            )
          : _buildBody(),
    );
  }

  /// Constrói a AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mapa de Infestação'),
      backgroundColor: const Color(0xFF2A4F3D),
      foregroundColor: Colors.white,
      actions: [
        // NOVO: Botão para dashboard de aprendizado
        IconButton(
          icon: Badge(
            label: Text('${((_systemConfidence ?? 0.0) * 100).toInt()}%'),
            backgroundColor: _getConfidenceColor(_systemConfidence ?? 0.0),
            child: const Icon(Icons.school),
          ),
          onPressed: _navigateToLearningDashboard,
          tooltip: 'Aprendizado do Sistema (${((_systemConfidence ?? 0.0) * 100).toStringAsFixed(0)}%)',
        ),
        IconButton(
          icon: Icon(_currentMapType == 'satellite' ? Icons.map : Icons.satellite),
          onPressed: _toggleSatellite,
          tooltip: 'Alternar visualização',
        ),
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: _runInfestationDiagnostic,
          tooltip: 'Análise de dados de infestação',
        ),
        IconButton(
          icon: const Icon(Icons.agriculture),
          onPressed: _navigateToAgronomistReports,
          tooltip: 'Relatórios Agronômicos',
        ),
        IconButton(
          icon: const Icon(Icons.psychology),
          onPressed: _processDataWithAI,
          tooltip: 'Processar com IA',
        ),
      ],
    );
  }

  /// Constrói o corpo da tela com LayoutBuilder responsivo para mobile
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Detectar tamanho da tela
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 400; // < 6 polegadas
        final isMediumScreen = screenWidth >= 400 && screenWidth < 600; // 6-7 polegadas
        final isLargeScreen = screenWidth >= 600; // > 7 polegadas
        
        // Calcular larguras responsivas
        double leftPanelWidth, rightPanelWidth, mapWidth;
        
        if (isSmallScreen) {
          // Tela pequena: painéis empilhados verticalmente
          leftPanelWidth = screenWidth;
          rightPanelWidth = screenWidth;
          mapWidth = screenWidth;
        } else if (isMediumScreen) {
          // Tela média: painéis laterais menores
          leftPanelWidth = screenWidth * 0.28;
          rightPanelWidth = screenWidth * 0.22;
          mapWidth = screenWidth - leftPanelWidth - rightPanelWidth;
        } else {
          // Tela grande: painéis laterais maiores
          leftPanelWidth = screenWidth * 0.25;
          rightPanelWidth = screenWidth * 0.25;
          mapWidth = screenWidth - leftPanelWidth - rightPanelWidth;
        }
        
        // Layout responsivo baseado no tamanho da tela
        if (isSmallScreen) {
          return _buildSmallScreenLayout();
        } else {
    return Row(
      children: [
        // Painel lateral esquerdo
        SizedBox(
                width: leftPanelWidth,
          child: _buildLeftPanel(),
        ),
        
        // Mapa principal
              SizedBox(
                width: mapWidth,
          child: _buildMap(),
        ),
        
        // Painel lateral direito
        SizedBox(
                width: rightPanelWidth,
          child: _buildRightPanel(),
        ),
      ],
          );
        }
      },
    );
  }

  /// Layout para telas pequenas (< 6 polegadas)
  Widget _buildSmallScreenLayout() {
    return Column(
      children: [
        // Painel de filtros compacto (reduzido)
        Container(
          width: double.infinity,
          height: 220, // Reduzido de 280 para 220
          child: _buildCompactFiltersPanel(),
        ),
        
        // Mapa principal (maior espaço)
        Expanded(
          child: _buildMap(),
        ),
        
        // Painel de controles compacto (reduzido)
        Container(
          width: double.infinity,
          height: 160, // Reduzido de 200 para 160
          child: _buildCompactControlsPanel(),
        ),
      ],
    );
  }

  /// Painel de filtros compacto para telas pequenas
  Widget _buildCompactFiltersPanel() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Cabeçalho compacto
            Row(
              children: [
                const Icon(Icons.filter_list, size: 20, color: Colors.blue),
                const SizedBox(width: 6),
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Filtros em grid 2x2
            Row(
              children: [
                // Coluna esquerda
          Expanded(
                child: Column(
                  children: [
                      _buildCompactDateFilter(),
                      const SizedBox(height: 8),
                      _buildCompactTalhaoFilter(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Coluna direita
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactOrganismFilter(),
                      const SizedBox(height: 8),
                      _buildCompactLevelFilter(),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botões de ação compactos
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Aplicar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Painel de controles compacto para telas pequenas
  Widget _buildCompactControlsPanel() {
    return Container(
      decoration: BoxDecoration(
        // Efeito de vidro transparente
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Cabeçalho compacto
            Row(
              children: [
                const Icon(Icons.legend_toggle, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  'Controles',
                      style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 12),
            
            // Controles em grid 2x2
            Row(
              children: [
                // Coluna esquerda
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactLegendItem('CRÍTICO', Colors.red),
                      const SizedBox(height: 6),
                      _buildCompactLegendItem('ALTO', Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Coluna direita
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactLegendItem('MODERADO', Colors.yellow),
                      const SizedBox(height: 6),
                      _buildCompactLegendItem('BAIXO', Colors.green),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Controles de visualização compactos
            Row(
              children: [
          Expanded(
                  child: _buildCompactControlButton(
                    label: 'Polígonos',
                    icon: Icons.polyline,
                    isActive: _showPolygons,
                    onTap: () => setState(() => _showPolygons = !_showPolygons),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactControlButton(
                    label: 'Pontos',
                    icon: Icons.location_on,
                    isActive: _showPoints,
                    onTap: () => setState(() => _showPoints = !_showPoints),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactControlButton(
                    label: 'Heatmap',
                    icon: Icons.heat_pump,
                    isActive: _showHeatmap,
                    onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Filtro de data compacto
  Widget _buildCompactDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        _buildCompactDateField(
          label: 'Início',
          value: _filters.dataInicio,
          onChanged: (date) => _updateFilters(_filters.copyWith(dataInicio: date)),
        ),
      ],
    );
  }

  /// Filtro de talhão compacto
  Widget _buildCompactTalhaoFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Talhão',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          child: DropdownButtonFormField<String>(
            value: _filters.talhaoId?.isEmpty == true ? null : _filters.talhaoId,
            decoration: const InputDecoration(
              hintText: 'Selecione',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Todos')),
              ..._talhoes.map((talhao) => DropdownMenuItem(
                value: talhao.id,
                child: Text(talhao.name, style: const TextStyle(fontSize: 11)),
              )),
            ],
            onChanged: (value) => _updateFilters(_filters.copyWith(talhaoId: value ?? '')),
          ),
        ),
      ],
    );
  }

  /// Filtro de categoria de organismo compacto
  Widget _buildCompactOrganismFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoria',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildCompactOrganismTypeChip('pest', 'Pragas', Icons.bug_report, Colors.red),
            _buildCompactOrganismTypeChip('disease', 'Doenças', Icons.healing, Colors.orange),
            _buildCompactOrganismTypeChip('weed', 'Plantas Daninhas', Icons.eco, Colors.green),
          ],
        ),
      ],
    );
  }

  /// Chip de tipo de organismo compacto
  Widget _buildCompactOrganismTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _filters.organismTypes?.contains(type) ?? false;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        final types = List<String>.from(_filters.organismTypes ?? []);
        if (selected) {
          types.add(type);
        } else {
          types.remove(type);
        }
        _updateFilters(_filters.copyWith(organismTypes: types));
      },
      backgroundColor: isSelected ? color : Colors.white,
      selectedColor: color,
      side: BorderSide(color: color, width: 1),
      checkmarkColor: Colors.white,
      elevation: isSelected ? 2 : 0,
      pressElevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// Filtro de nível compacto
  Widget _buildCompactLevelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nível',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildCompactLevelChip('CRÍTICO', Colors.red),
            _buildCompactLevelChip('ALTO', Colors.orange),
            _buildCompactLevelChip('MOD', Colors.yellow),
            _buildCompactLevelChip('BAIXO', Colors.green),
          ],
        ),
      ],
    );
  }

  /// Chip de nível compacto
  Widget _buildCompactLevelChip(String level, Color color) {
    final isSelected = _filters.niveis?.contains(level) == true;
    
    return FilterChip(
      label: Text(
        level,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        final niveis = List<String>.from(_filters.niveis ?? []);
        if (selected) {
          niveis.add(level);
        } else {
          niveis.remove(level);
        }
        _updateFilters(_filters.copyWith(niveis: niveis));
      },
      backgroundColor: isSelected ? color : Colors.white,
      selectedColor: color,
      side: BorderSide(color: color),
      checkmarkColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Item da legenda compacto
  Widget _buildCompactLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Botão de controle compacto
  Widget _buildCompactControlButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
            child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey[300]!,
          ),
        ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
              icon,
              size: 14,
              color: isActive ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(height: 2),
                    Text(
              label,
                      style: TextStyle(
                fontSize: 9,
                color: isActive ? Colors.blue : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de data compacto
  Widget _buildCompactDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value != null 
                  ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}'
                  : label,
                      style: TextStyle(
                  color: value != null ? Colors.black : Colors.grey[600],
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  /// Constrói o painel esquerdo otimizado
  Widget _buildLeftPanel() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Filtros com design elegante
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildElegantFiltersPanel(),
            ),
            
            // Estatísticas com design elegante
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildElegantStatisticsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  /// Painel de filtros elegante para telas médias e grandes
  Widget _buildElegantFiltersPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Cabeçalho elegante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filtros de Infestação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo dos filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtro de período elegante
                _buildElegantDateRangeFilter(),
                const SizedBox(height: 20),
                
                // Filtro de talhão elegante
                _buildElegantTalhaoFilter(),
                const SizedBox(height: 20),
                
                // Filtro por tipo de organismo elegante
                _buildElegantOrganismTypeFilter(),
                const SizedBox(height: 20),
                
                // Filtro de nível elegante
                _buildElegantLevelFilter(),
                const SizedBox(height: 24),
                
                // Botões de ação elegantes
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Aplicar Filtros'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Limpar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filtro de período elegante
  Widget _buildElegantDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              'Período de Análise',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildElegantDateField(
                label: 'Data Início',
                value: _filters.dataInicio,
                onChanged: (date) => _updateFilters(_filters.copyWith(dataInicio: date)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildElegantDateField(
                label: 'Data Fim',
                value: _filters.dataFim,
                onChanged: (date) => _updateFilters(_filters.copyWith(dataFim: date)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Campo de data elegante
  Widget _buildElegantDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null 
                  ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                  : label,
                style: TextStyle(
                  color: value != null ? Colors.grey[800] : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filtro de talhão elegante
  Widget _buildElegantTalhaoFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.map, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              'Seleção de Talhão',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: _filters.talhaoId?.isEmpty == true ? null : _filters.talhaoId,
            decoration: const InputDecoration(
              hintText: 'Selecione um talhão específico',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todos os talhões', style: TextStyle(color: Colors.grey)),
              ),
              ..._talhoes.map((talhao) => DropdownMenuItem(
                value: talhao.id,
                child: Text(talhao.name),
              )),
            ],
            onChanged: (value) => _updateFilters(_filters.copyWith(talhaoId: value ?? '')),
          ),
        ),
      ],
    );
  }

  /// Filtro por tipo de organismo elegante
  Widget _buildElegantOrganismTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              'Categoria de Organismo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildElegantOrganismTypeChip('pest', 'Pragas', Icons.bug_report, Colors.red),
            _buildElegantOrganismTypeChip('disease', 'Doenças', Icons.healing, Colors.orange),
            _buildElegantOrganismTypeChip('weed', 'Plantas Daninhas', Icons.eco, Colors.green),
          ],
        ),
      ],
    );
  }

  /// Chip de tipo de organismo elegante
  Widget _buildElegantOrganismTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _filters.organismTypes?.contains(type) ?? false;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        final currentTypes = List<String>.from(_filters.organismTypes ?? []);
        if (selected) {
          currentTypes.add(type);
        } else {
          currentTypes.remove(type);
        }
        _updateFilters(_filters.copyWith(organismTypes: currentTypes));
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withOpacity(0.5)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Filtro de organismo elegante
  Widget _buildElegantOrganismFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bug_report, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              'Tipo de Organismo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: _filters.organismoId?.isEmpty == true ? null : _filters.organismoId,
            decoration: const InputDecoration(
              hintText: 'Selecione um organismo específico',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
              helperText: 'Filtre por categoria acima ou selecione um organismo específico',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todos os organismos', style: TextStyle(color: Colors.grey)),
              ),
              ..._getFilteredOrganisms().map((organism) => DropdownMenuItem(
                value: organism.id,
                child: Row(
                  children: [
                    Icon(_getOrganismTypeIcon(organism.type.toString()), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${organism.name} (${organism.cropName})'),
                    ),
                  ],
                ),
              )),
            ],
            onChanged: (value) => _updateFilters(_filters.copyWith(organismoId: value ?? '')),
          ),
        ),
      ],
    );
  }

  /// Filtro de nível elegante
  Widget _buildElegantLevelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.signal_cellular_alt, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              'Nível de Infestação',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildElegantLevelChip('CRÍTICO', Colors.red),
            _buildElegantLevelChip('ALTO', Colors.orange),
            _buildElegantLevelChip('MODERADO', Colors.yellow),
            _buildElegantLevelChip('BAIXO', Colors.green),
          ],
        ),
      ],
    );
  }

  /// Chip de nível elegante
  Widget _buildElegantLevelChip(String level, Color color) {
    final isSelected = _filters.niveis?.contains(level) == true;
    
    return FilterChip(
      label: Text(
        level,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        final niveis = List<String>.from(_filters.niveis ?? []);
        if (selected) {
          niveis.add(level);
        } else {
          niveis.remove(level);
        }
        _updateFilters(_filters.copyWith(niveis: niveis));
      },
      backgroundColor: isSelected ? color : Colors.white,
      selectedColor: color,
      side: BorderSide(color: color, width: 1.5),
      checkmarkColor: Colors.white,
      elevation: isSelected ? 2 : 0,
      pressElevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// Executa diagnóstico de dados de infestação
  Future<void> _runInfestationDiagnostic() async {
    try {
      Logger.info('🔍 [INFESTACAO] Executando diagnóstico de dados...');
      
      // Usar o novo serviço de diagnóstico
      final debugService = InfestationMapDebugService();
      
      // Executar diagnóstico completo
      final results = await debugService.runFullDiagnostic();
      
      // Gerar dados de teste se necessário
      // final testDataResults = await debugService.generateTestDataIfNeeded();
      
      if (mounted) {
        // Mostrar resultados em um dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Diagnóstico de Dados'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📊 Estrutura das Tabelas:'),
                  Text('   - infestacoes_monitoramento: ${results['table_structure']?['infestacoes_monitoramento']?['exists'] == true ? '✅' : '❌'}'),
                  Text('   - organism_catalog: ${results['table_structure']?['organism_catalog']?['exists'] == true ? '✅' : '❌'}'),
                  Text('   - talhoes: ${results['table_structure']?['talhoes']?['exists'] == true ? '✅' : '❌'}'),
                  
                  const SizedBox(height: 16),
                  Text('📈 Contagem de Dados:'),
                  Text('   - Infestações: ${results['data_counts']?['infestacoes_monitoramento']?['count'] ?? 0}'),
                  Text('   - Organismos: ${results['data_counts']?['organism_catalog']?['count'] ?? 0}'),
                  Text('   - Talhões: ${results['data_counts']?['talhoes']?['count'] ?? 0}'),
                  
                  const SizedBox(height: 16),
                  Text('🔥 Dados para Heatmap:'),
                  Text('   - Total de pontos: ${results['heatmap_data']?['heatmap_stats']?['total_points'] ?? 0}'),
                  Text('   - Talhões distintos: ${results['heatmap_data']?['heatmap_stats']?['talhoes_distintos'] ?? 0}'),
                  Text('   - Média percentual: ${results['heatmap_data']?['heatmap_stats']?['media_percentual']?.toStringAsFixed(1) ?? '0.0'}%'),
                  
                  const SizedBox(height: 16),
                  const Text('✅ Dados de teste criados!'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
              // if (testDataResults['test_data_created'] == true)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadInfestationData(); // Recarregar dados
                  },
                  child: const Text('Atualizar'),
                ),
            ],
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro no diagnóstico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no diagnóstico: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Força o processamento de todos os dados
  Future<void> _forceProcessAllData() async {
    try {
      Logger.info('🔄 [INFESTACAO] Forçando processamento de todos os dados...');
      
      final debugService = InfestationMapDebugService();
      final results = await debugService.forceProcessAllMonitorings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processamento concluído: ${results['processed']} sucessos, ${results['errors']} erros'),
            backgroundColor: results['success'] ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Recarregar dados após processamento
        await _loadInfestationData();
      }
      
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro no processamento forçado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no processamento: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Constrói seção de diagnóstico
  Widget _buildDiagnosticSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...data.entries.map((entry) => 
          Text('  ${entry.key}: ${entry.value}')
        ),
      ],
    );
  }

  /// Constrói o painel de estatísticas elegante
  Widget _buildElegantStatisticsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho elegante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estatísticas de Infestação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo das estatísticas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Métricas principais
                _buildElegantMetricCards(),
                const SizedBox(height: 20),
                
                // Gráfico de tendência
                _buildElegantTrendChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cards de métricas elegantes
  Widget _buildElegantMetricCards() {
    return Column(
      children: [
        // Total de infestações
        _buildElegantMetricCard(
          title: 'Total de Infestações',
          value: _infestationSummaries.length.toString(),
          icon: Icons.bug_report,
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        
        // Alertas ativos
        _buildElegantMetricCard(
          title: 'Alertas Ativos',
          value: _activeAlerts.length.toString(),
          icon: Icons.warning,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        
        // Talhões afetados
        _buildElegantMetricCard(
          title: 'Talhões Afetados',
          value: _getAffectedTalhoesCount().toString(),
          icon: Icons.map,
          color: Colors.blue,
        ),
      ],
    );
  }

  /// Card de métrica elegante
  Widget _buildElegantMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                  fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gráfico de tendência elegante
  Widget _buildElegantTrendChart() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Tendência (Últimos 7 dias)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildElegantSimpleChart(),
          ),
        ],
      ),
    );
  }

  /// Gráfico simples elegante
  Widget _buildElegantSimpleChart() {
    final dailyData = _getDailyInfestationData();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailyData.asMap().entries.map((entry) {
        final index = entry.key;
        final count = entry.value;
        final maxCount = dailyData.reduce((a, b) => a > b ? a : b);
        final height = maxCount > 0 ? (count / maxCount) * 60 : 0.0;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Constrói o painel de estatísticas funcional
  Widget _buildStatisticsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho das estatísticas
        Row(
          children: [
            const Icon(
              Icons.analytics,
              size: 24,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Métricas principais
        _buildMetricCards(),
        const SizedBox(height: 16),
        
        // Gráfico de tendência
        _buildTrendChart(),
      ],
    );
  }

  /// Constrói os cards de métricas
  Widget _buildMetricCards() {
    return Column(
      children: [
        // Total de infestações
        _buildMetricCard(
          title: 'Total de Infestações',
          value: _infestationSummaries.length.toString(),
          icon: Icons.bug_report,
          color: Colors.red,
        ),
        const SizedBox(height: 8),
        
        // Alertas ativos
        _buildMetricCard(
          title: 'Alertas Ativos',
          value: _activeAlerts.length.toString(),
          icon: Icons.warning,
          color: Colors.orange,
        ),
        const SizedBox(height: 8),
        
        // Talhões afetados
        _buildMetricCard(
          title: 'Talhões Afetados',
          value: _getAffectedTalhoesCount().toString(),
          icon: Icons.map,
          color: Colors.blue,
        ),
      ],
    );
  }

  /// Card de métrica individual
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gráfico de tendência
  Widget _buildTrendChart() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendência (Últimos 7 dias)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildSimpleChart(),
          ),
        ],
      ),
    );
  }

  /// Gráfico simples de barras
  Widget _buildSimpleChart() {
    final dailyData = _getDailyInfestationData();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailyData.asMap().entries.map((entry) {
        final index = entry.key;
        final count = entry.value;
        final maxCount = dailyData.reduce((a, b) => a > b ? a : b);
        final height = maxCount > 0 ? (count / maxCount) * 60 : 0.0;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Obtém dados diários de infestação (simulado)
  List<int> _getDailyInfestationData() {
    // TODO: Implementar dados reais do banco
    return [5, 8, 12, 7, 15, 9, 11];
  }

  /// Conta talhões afetados
  int _getAffectedTalhoesCount() {
    final affectedTalhoes = <String>{};
    for (final summary in _infestationSummaries) {
      affectedTalhoes.add(summary.talhaoId);
    }
    return affectedTalhoes.length;
  }

  /// Constrói o painel direito funcional
  Widget _buildRightPanel() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
      child: Column(
        children: [
          // Legenda
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildLegendPanel(),
            ),
            
            // Alertas ativos
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildAlertsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói painel de legenda funcional
  Widget _buildLegendPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
        Row(
          children: [
            const Icon(
                      Icons.legend_toggle,
              size: 24,
                      color: Colors.purple,
                    ),
            const SizedBox(width: 8),
            const Text(
              'Legenda',
                      style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Níveis de infestação
        _buildLegendItem('CRÍTICO', Colors.red, 'Nível crítico de infestação'),
        _buildLegendItem('ALTO', Colors.orange, 'Nível alto de infestação'),
        _buildLegendItem('MODERADO', Colors.yellow, 'Nível moderado de infestação'),
        _buildLegendItem('BAIXO', Colors.green, 'Nível baixo de infestação'),
        
        const SizedBox(height: 16),
        
        // Controles de visualização
        _buildMapControls(),
      ],
    );
  }

  /// Item da legenda
  Widget _buildLegendItem(String label, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                  description,
                      style: TextStyle(
                        fontSize: 12,
                    color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// Controles de visualização do mapa
  Widget _buildMapControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visualização',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Toggle de polígonos
        _buildControlButton(
          label: 'Polígonos',
          icon: Icons.polyline,
          isActive: _showPolygons,
          onTap: () => setState(() => _showPolygons = !_showPolygons),
        ),
        
        // Toggle de pontos
        _buildControlButton(
          label: 'Pontos',
          icon: Icons.location_on,
          isActive: _showPoints,
          onTap: () => setState(() => _showPoints = !_showPoints),
        ),
        
        // Toggle de heatmap
        _buildControlButton(
          label: 'Heatmap',
          icon: Icons.heat_pump,
          isActive: _showHeatmap,
          onTap: () => setState(() => _showHeatmap = !_showHeatmap),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'Localização',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Botão para centralizar na localização atual
        _buildControlButton(
          label: 'Minha Localização',
          icon: Icons.my_location,
          isActive: false,
          onTap: _getCurrentLocation,
        ),
        
        // Botão para centralizar no talhão selecionado
        _buildControlButton(
          label: 'Talhão Selecionado',
          icon: Icons.center_focus_strong,
          isActive: false,
          onTap: _centerMapOnSelectedTalhao,
        ),
      ],
    );
  }

  /// Botão de controle
  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.blue : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói painel de alertas funcional
  Widget _buildAlertsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 24,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text(
              'Alertas Ativos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_activeAlerts.isEmpty)
          const Center(
        child: Column(
          children: [
            Icon(
                  Icons.check_circle,
              size: 48,
                  color: Colors.green,
            ),
                SizedBox(height: 8),
            Text(
                  'Nenhum alerta ativo',
              style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._activeAlerts.map((alert) => _buildAlertItem(alert)),
      ],
    );
  }

  /// Item de alerta
  Widget _buildAlertItem(InfestationAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.message,
                  style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
              ),
            ],
          ),
          const SizedBox(height: 4),
            Text(
            alert.description,
              style: TextStyle(
                fontSize: 12,
              color: Colors.grey[700],
              ),
            ),
          ],
        ),
    );
  }

  /// Constrói o mapa
  Widget _buildMap() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation ?? const LatLng(-23.5505, -46.6333), // São Paulo ou localização atual
          initialZoom: 10,
          onMapReady: () {
            Logger.info('✅ [INFESTACAO] Mapa carregado com sucesso');
            // Centralizar na localização atual se disponível
            if (_currentLocation != null) {
              _centerMapOnLocation(_currentLocation!);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: APIConfig.getMapTilerUrl(_currentMapType),
            userAgentPackageName: 'com.fortsmart.agro',
            fallbackUrl: APIConfig.getFallbackUrl(),
          ),
          
          // Camada de polígonos dos talhões
          if (_showPolygons)
            PolygonLayer(
              polygons: _buildTalhaoPolygons(),
            ),
          
          // Camada de marcadores
          if (_showPoints)
            MarkerLayer(
              markers: _buildAllMarkers(),
            ),
          
          // Camada de heatmap inteligente
          if (_showHeatmap)
            _buildHeatmapLayer(),
        ],
      ),
    );
  }

  /// Constrói polígonos dos talhões
  List<Polygon> _buildTalhaoPolygons() {
    final polygons = <Polygon>[];
    
    for (final talhao in _talhoes) {
      if (talhao.poligonos.isNotEmpty) {
        final poligono = talhao.poligonos.first;
        if (poligono.pontos.length >= 3) {
          final isSelected = _filters.talhaoId == talhao.id;
          
          // Cor do polígono baseada na cultura ou seleção
          Color corPoligono = isSelected ? Colors.blue : Colors.green;
          if (talhao.safras.isNotEmpty && talhao.safras.first.culturaCor.isNotEmpty) {
            try {
              corPoligono = _parseColor(talhao.safras.first.culturaCor);
            } catch (e) {
              corPoligono = isSelected ? Colors.blue : Colors.grey;
            }
          }
          
          polygons.add(Polygon(
            points: poligono.pontos,
            color: corPoligono.withOpacity(0.3),
            borderColor: corPoligono,
            borderStrokeWidth: isSelected ? 3.0 : 2.0,
          ));
        }
      }
    }
    
    return polygons;
  }
  
  /// Constrói todos os marcadores
  List<Marker> _buildAllMarkers() {
    final markers = <Marker>[];
    
    // Marcador de localização atual (elegante e menor)
    if (_currentLocation != null) {
      markers.add(Marker(
        point: _currentLocation!,
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3), // Azul mais elegante
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation, // Ícone mais elegante
            color: Colors.white,
            size: 16,
          ),
        ),
      ));
    }
    
    // Marcadores das ocorrências de infestação
    if (_infestacaoRepository != null) {
      _addInfestationMarkers(markers);
    }
    
    // Marcadores dos talhões (centro)
    for (final talhao in _talhoes) {
      if (talhao.poligonos.isNotEmpty) {
        final poligono = talhao.poligonos.first;
        if (poligono.pontos.isNotEmpty) {
          // Calcular centro do talhão
          double centerLat = 0.0;
          double centerLng = 0.0;
          
          for (final ponto in poligono.pontos) {
            centerLat += ponto.latitude;
            centerLng += ponto.longitude;
          }
          
          centerLat /= poligono.pontos.length;
          centerLng /= poligono.pontos.length;
          
          final centerLocation = LatLng(centerLat, centerLng);
          final isSelected = _filters.talhaoId == talhao.id;
          
          markers.add(Marker(
            point: centerLocation,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Selecionar talhão ao tocar no marcador
                setState(() {
                  _filters = _filters.copyWith(talhaoId: talhao.id);
                });
                _centerMapOnSelectedTalhao();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isSelected ? Icons.location_on : Icons.location_on_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ));
        }
      }
    }
    
    return markers;
  }

  /// Constrói camada de heatmap inteligente
  Widget _buildHeatmapLayer() {
    if (_intelligentHeatmapPoints.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return MarkerLayer(
      markers: _intelligentHeatmapPoints.map((point) => Marker(
        point: LatLng(point.latitude, point.longitude),
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: _getHeatmapColor(point.intensity),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: _getHeatmapColor(point.intensity).withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${((point.intensity ?? 0.0) * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  /// Obtém cor baseada na intensidade do heatmap
  Color _getHeatmapColor(double intensity) {
    if (intensity >= 0.8) return Colors.red;      // Crítico
    if (intensity >= 0.6) return Colors.orange;   // Alto
    if (intensity >= 0.4) return Colors.yellow;    // Moderado
    if (intensity >= 0.2) return Colors.lightGreen; // Baixo
    return Colors.green;                          // Muito baixo
  }

  /// Adiciona marcadores das ocorrências de infestação
  void _addInfestationMarkers(List<Marker> markers) {
    // Buscar ocorrências de forma assíncrona e adicionar ao estado
    _loadOccurrencesForMarkers().then((occurrences) {
      for (final occurrence in occurrences) {
        // Verificar se a ocorrência está dentro dos filtros
        if (_isOccurrenceInFilters(occurrence)) {
          markers.add(_buildInfestationMarker(occurrence));
        }
      }
    });
  }

  /// Carrega ocorrências para exibição no mapa
  Future<List<InfestacaoModel>> _loadOccurrencesForMarkers() async {
    if (_infestacaoRepository == null) return [];
    
    try {
      return await _infestacaoRepository!.getAll();
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao carregar ocorrências para markers: $e');
      return [];
    }
  }

  /// Verifica se uma ocorrência está dentro dos filtros aplicados
  bool _isOccurrenceInFilters(InfestacaoModel occurrence) {
    // Filtro por talhão
    if (_filters.talhaoId != null && _filters.talhaoId!.isNotEmpty) {
      if (occurrence.talhaoId.toString() != (_filters.talhaoId ?? '')) {
        return false;
      }
    }

    // Filtro por organismo
    if (_filters.organismoId != null && _filters.organismoId!.isNotEmpty) {
      if (occurrence.tipo != _filters.organismoId) {
        return false;
      }
    }

    // Filtro por nível
    if (_filters.niveis != null && _filters.niveis!.isNotEmpty) {
      if (!_filters.niveis!.contains(occurrence.nivel)) {
        return false;
      }
    }

    // Filtro por período
    if (_filters.dataInicio != null && _filters.dataFim != null) {
      final occurrenceDate = occurrence.dataHora;
      if (occurrenceDate.isBefore(_filters.dataInicio!) || 
          occurrenceDate.isAfter(_filters.dataFim!)) {
        return false;
      }
    }

    return true;
  }

  /// Constrói marcador para uma ocorrência de infestação
  /// NOVO: Cores ajustadas baseadas em feedback OFFLINE
  Marker _buildInfestationMarker(InfestacaoModel occurrence) {
    Color markerColor = Colors.green;
    IconData markerIcon = Icons.bug_report;

    // Definir cor e ícone baseado no tipo e nível
    switch (occurrence.tipo) {
      case 'Praga':
        markerIcon = Icons.bug_report;
        break;
      case 'Doença':
        markerIcon = Icons.coronavirus;
        break;
      case 'Daninha':
        markerIcon = Icons.local_florist;
        break;
      default:
        markerIcon = Icons.warning;
    }

    // NOVO: Ajustar cor baseada em feedback histórico da fazenda
    markerColor = _getAdjustedColorByFeedback(
      originalLevel: occurrence.nivel,
      organismName: occurrence.subtipo,
      percentual: occurrence.percentual.toDouble(),
    );

    /* CÓDIGO ORIGINAL (mantido como fallback se não houver feedback):
    switch (occurrence.nivel) {
      case 'Crítico':
        markerColor = Colors.red;
        break;
      case 'Alto':
        markerColor = Colors.orange;
        break;
      case 'Médio':
        markerColor = Colors.yellow;
        break;
      case 'Baixo':
        markerColor = Colors.green;
        break;
      default:
        markerColor = Colors.grey;
    }
    */

    return Marker(
      point: LatLng(occurrence.latitude, occurrence.longitude),
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: markerColor.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          markerIcon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
  
  /// Converte string de cor para Color
  Color _parseColor(String colorString) {
    try {
      if (colorString.isEmpty) return Colors.grey;
      
      colorString = colorString.trim();
      
      if (colorString.startsWith('#')) {
        String hex = colorString.substring(1);
        if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
          return Color(int.parse('0xFF$hex'));
        } else if (RegExp(r'^[0-9A-Fa-f]{3}$').hasMatch(hex)) {
          hex = hex.split('').map((c) => c + c).join();
          return Color(int.parse('0xFF$hex'));
        }
      } else if (colorString.startsWith('0x')) {
        if (RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(colorString)) {
          return Color(int.parse(colorString));
        }
      } else if (RegExp(r'^[0-9]+$').hasMatch(colorString)) {
        return Color(int.parse(colorString));
      }
      
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }


  /// Mostra detalhes da infestação
  void _showInfestationDetails(InfestationSummary summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfestationDetailsScreen(summary: summary),
      ),
    );
  }

  /// Mostra detalhes do alerta
  void _showAlertDetails(InfestationAlert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertDetailsScreen(alert: alert),
      ),
    );
  }


  /// Mostra novo monitoramento
  void _showNewMonitoring() {
    try {
      Logger.info('🔄 [INFESTACAO] Navegando para tela de monitoramento avançado...');
      Navigator.pushNamed(context, AppRoutes.advancedMonitoring);
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao navegar para monitoramento: $e');
      _showErrorSnackBar('Erro ao abrir tela de monitoramento: $e');
    }
  }

  /// Navega para relatórios agronômicos
  void _navigateToAgronomistReports() {
    try {
      Logger.info('🔄 [INFESTACAO] Navegando para relatórios agronômicos...');
      Navigator.pushNamed(context, AppRoutes.agronomistReports);
    } catch (e) {
      Logger.error('❌ [INFESTACAO] Erro ao navegar para relatórios agronômicos: $e');
      _showErrorSnackBar('Erro ao abrir relatórios agronômicos: $e');
    }
  }

  /// Processa dados com IA para melhorar precisão
  Future<void> _processDataWithAI() async {
    try {
      Logger.info('🤖 [IA] Processando dados com IA...');
      
      setState(() => _isLoading = true);
      
      // Gerar heatmap inteligente
      await _generateIntelligentHeatmap();
      
      // Gerar hexágonos inteligentes
      await _generateIntelligentHexagons();
      
      // Gerar alertas inteligentes
      await _generateIntelligentAlerts();
      
      // Gerar predições de IA avançada
      await _generateAIPredictions();
      
      // Gerar análise econômica
      await _generateEconomicAnalysis();
      
      // Gerar relatório executivo
      await _generateExecutiveReport();
      
      // Executar integração completa
      await _executeCompleteIntegration();
      
      setState(() => _isLoading = false);
      
      Logger.info('✅ [IA] Dados processados com IA com sucesso');
    } catch (e) {
      Logger.error('❌ [IA] Erro ao processar dados com IA: $e');
      setState(() => _isLoading = false);
    }
  }
  
  /// Gera heatmap inteligente
  Future<void> _generateIntelligentHeatmap() async {
    try {
      Logger.info('🔥 [HEATMAP] Gerando heatmap inteligente com dados reais...');
      
      // Carregar dados reais de monitoramento
      final integrationService = MonitoringInfestationIntegrationService();
      final monitorings = await integrationService.getAllMonitorings();
      
      if (monitorings.isEmpty) {
        Logger.warning('⚠️ [HEATMAP] Nenhum monitoramento encontrado');
        return;
      }
      
      Logger.info('📊 [HEATMAP] ${monitorings.length} monitoramentos carregados');
      
      // Processar dados de monitoramento para heatmap
      final heatmapPoints = <IntelligentHeatmapPoint>[];
      
      for (final monitoring in monitorings) {
        // Aplicar filtro de talhão se especificado
        if (_filters.talhaoId != null && _filters.talhaoId!.isNotEmpty) {
          if (monitoring.farmId != (_filters.talhaoId ?? '')) {
            continue; // Pular monitoramento se não for do talhão selecionado
          }
        }
        
        for (final point in monitoring.points) {
          if (point.occurrences.isNotEmpty) {
            final occurrence = point.occurrences.first;
            
            // Aplicar filtros de severidade/nível
            if (_filters.niveis != null && _filters.niveis!.isNotEmpty) {
              final severityLevel = _getSeverityLevel(occurrence.severity);
              if (!_filters.niveis!.contains(severityLevel)) {
                continue; // Pular ponto se não atender ao filtro de nível
              }
            }
            
            // Aplicar filtro de período
            if (_filters.dataInicio != null && point.date.isBefore(_filters.dataInicio!)) {
              continue;
            }
            if (_filters.dataFim != null && point.date.isAfter(_filters.dataFim!)) {
              continue;
            }
            
            // Calcular intensidade baseada na severidade
            final severity = occurrence.severity;
            final intensity = _calculateHeatmapIntensity(severity);
            
            heatmapPoints.add(IntelligentHeatmapPoint(
              lat: point.latitude,
              lng: point.longitude,
              intensity: intensity,
              color: _getSeverityColor(severity),
              radius: 50.0,
              organismId: occurrence.organismId?.toString() ?? '',
              organismName: occurrence.organismName ?? occurrence.name ?? 'Organismo não identificado',
              phase: 'adulto',
              severity: severity.round(),
              confidence: 0.8,
              temperature: 25.0,
              humidity: 60.0,
              riskLevel: 'medium',
              timestamp: point.date,
              // cultura: monitoring.cropName, // Parâmetro não existe no construtor
            ));
          }
        }
      }
      
      setState(() {
        _intelligentHeatmapPoints = heatmapPoints;
      });
      
      Logger.info('✅ [HEATMAP] ${heatmapPoints.length} pontos de heatmap inteligente gerados');
      
      // Gerar relatório agronômico com dados reais
      await _gerarRelatorioAgronomicoComDadosReais(monitorings);
      
    } catch (e) {
      Logger.error('❌ [HEATMAP] Erro ao gerar heatmap inteligente: $e');
    }
  }

  /// Gera relatório agronômico com dados reais
  Future<void> _gerarRelatorioAgronomicoComDadosReais(List<Monitoring> monitorings) async {
    try {
      Logger.info('📊 [RELATÓRIO] Gerando relatório agronômico com dados reais...');
      
      // Agrupar dados por talhão para análise
      final dadosPorTalhao = <String, Map<String, dynamic>>{};
      
      for (final monitoring in monitorings) {
        final talhaoId = monitoring.farmId;
        
        if (!dadosPorTalhao.containsKey(talhaoId)) {
          dadosPorTalhao[talhaoId] = {
            'talhaoId': talhaoId,
            'talhaoNome': 'Talhão $talhaoId',
            'cultura': monitoring.cropName,
            'variedade': monitoring.cropVariety ?? 'Não informada',
            'pontos': <Map<String, dynamic>>[],
            'dadosAgronomicos': monitoring.weatherData ?? {},
            'totalPontos': 0,
            'severidadeMedia': 0.0,
            'organismos': <String>[],
            'nivelRisco': 'BAIXO',
          };
        }
        
        // Processar pontos de monitoramento
        for (final point in monitoring.points) {
          if (point.occurrences.isNotEmpty) {
            final occurrence = point.occurrences.first;
            
            dadosPorTalhao[talhaoId]!['pontos'].add({
              'latitude': point.latitude,
              'longitude': point.longitude,
              'organismo': occurrence.organismName,
              'severidade': occurrence.severity,
              'sintomas': occurrence.symptoms.join(', '),
              'data': point.date.toIso8601String(),
            });
            
            // Atualizar estatísticas
            final pontos = dadosPorTalhao[talhaoId]!['pontos'] as List<Map<String, dynamic>>;
            dadosPorTalhao[talhaoId]!['totalPontos'] = pontos.length;
            
            // Calcular severidade média
            final severidades = pontos.map((p) => p['severidade'] as double).toList();
            dadosPorTalhao[talhaoId]!['severidadeMedia'] = severidades.isNotEmpty 
                ? severidades.reduce((a, b) => a + b) / severidades.length 
                : 0.0;
            
            // Coletar organismos únicos
            final organismos = dadosPorTalhao[talhaoId]!['organismos'] as List<String>;
            if (!organismos.contains(occurrence.organismName)) {
              organismos.add(occurrence.organismName ?? occurrence.name);
            }
            
            // Determinar nível de risco
            final severidadeMedia = dadosPorTalhao[talhaoId]!['severidadeMedia'] as double;
            if (severidadeMedia >= 0.8) {
              dadosPorTalhao[talhaoId]!['nivelRisco'] = 'CRÍTICO';
            } else if (severidadeMedia >= 0.6) {
              dadosPorTalhao[talhaoId]!['nivelRisco'] = 'ALTO';
            } else if (severidadeMedia >= 0.4) {
              dadosPorTalhao[talhaoId]!['nivelRisco'] = 'MODERADO';
            } else {
              dadosPorTalhao[talhaoId]!['nivelRisco'] = 'BAIXO';
            }
          }
        }
      }
      
      // Log dos dados processados
      for (final entry in dadosPorTalhao.entries) {
        final talhaoId = entry.key;
        final dados = entry.value;
        
        Logger.info('📊 [RELATÓRIO] Talhão $talhaoId:');
        Logger.info('   - Cultura: ${dados['cultura']}');
        Logger.info('   - Total de pontos: ${dados['totalPontos']}');
        Logger.info('   - Severidade média: ${(dados['severidadeMedia'] as double).toStringAsFixed(2)}');
        Logger.info('   - Organismos: ${(dados['organismos'] as List<String>).join(', ')}');
        Logger.info('   - Nível de risco: ${dados['nivelRisco']}');
      }
      
      Logger.info('✅ [RELATÓRIO] Relatório agronômico gerado com sucesso');
      
    } catch (e) {
      Logger.error('❌ [RELATÓRIO] Erro ao gerar relatório agronômico: $e');
    }
  }

  /// Calcula intensidade do heatmap baseada na severidade (0-100)
  double _calculateHeatmapIntensity(double severity) {
    // Normalizar severidade (0-100) para intensidade do heatmap (0-1)
    if (severity >= 75) return 1.0;      // Crítico
    if (severity >= 50) return 0.8;      // Alto
    if (severity >= 25) return 0.6;      // Moderado
    if (severity >= 10) return 0.4;      // Baixo
    return 0.2;                          // Muito baixo
  }

  /// Converte severidade numérica (0-100) em nível textual
  String _getSeverityLevel(double severity) {
    if (severity >= 75) return 'CRÍTICO';
    if (severity >= 50) return 'ALTO';
    if (severity >= 25) return 'MODERADO';
    if (severity >= 10) return 'BAIXO';
    return 'MUITO_BAIXO';
  }

  /// Retorna cor baseada em severidade (0-100)
  Color _getSeverityColor(double severity) {
    if (severity >= 75) return Colors.red;        // Crítico: 75-100%
    if (severity >= 50) return Colors.orange;     // Alto: 50-75%
    if (severity >= 25) return Colors.yellow;     // Moderado: 25-50%
    if (severity >= 10) return Colors.lightGreen; // Baixo: 10-25%
    return Colors.green;                          // Muito baixo: 0-10%
  }
  
  /// Gera hexágonos inteligentes
  Future<void> _generateIntelligentHexagons() async {
    try {
      Logger.info('🔷 [HEXAGON] Gerando hexágonos inteligentes...');
      
      // Carregar ocorrências
      final occurrences = await _infestacaoRepository?.getAll() ?? [];
      
      // Carregar pontos de monitoramento
      final monitoringPoints = await _getMonitoringPoints();
      
      // Gerar hexágonos inteligentes
      final hexagons = await _hexagonService.generateIntelligentHexagons(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
        hexagonSize: 100.0, // 100 metros
      );
      
      setState(() {
        _intelligentHexagons = hexagons;
      });
      
      Logger.info('✅ [HEXAGON] ${hexagons.length} hexágonos inteligentes gerados');
    } catch (e) {
      Logger.error('❌ [HEXAGON] Erro ao gerar hexágonos inteligentes: $e');
    }
  }
  
  /// Gera alertas inteligentes
  Future<void> _generateIntelligentAlerts() async {
    try {
      Logger.info('🚨 [ALERTS] Gerando alertas inteligentes...');
      
      // Carregar ocorrências
      final occurrences = await _infestacaoRepository?.getAll() ?? [];
      
      // Carregar pontos de monitoramento
      final monitoringPoints = await _getMonitoringPoints();
      
      // Gerar alertas inteligentes
      final alerts = await _alertsService.generateIntelligentAlerts(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      setState(() {
        _intelligentAlerts = alerts;
      });
      
      Logger.info('✅ [ALERTS] ${alerts.length} alertas inteligentes gerados');
    } catch (e) {
      Logger.error('❌ [ALERTS] Erro ao gerar alertas inteligentes: $e');
    }
  }
  
  /// Gera predições de IA avançada
  Future<void> _generateAIPredictions() async {
    try {
      Logger.info('🤖 [AI-PREDICTIONS] Gerando predições de IA avançada...');
      
      // Carregar ocorrências
      final occurrences = await _infestacaoRepository?.getAll() ?? [];
      
      // Carregar pontos de monitoramento
      final monitoringPoints = await _getMonitoringPoints();
      
      // Gerar predições ponto a ponto
      final pointPredictions = await _predictionService.generatePointPredictions(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      // Gerar predições por talhão
      final talhaoPredictions = await _predictionService.generateTalhaoPredictions(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      setState(() {
        _aiPointPredictions = pointPredictions;
        _aiTalhaoPredictions = talhaoPredictions;
      });
      
      Logger.info('✅ [AI-PREDICTIONS] ${pointPredictions.length} predições ponto a ponto e ${talhaoPredictions.length} predições por talhão geradas');
    } catch (e) {
      Logger.error('❌ [AI-PREDICTIONS] Erro ao gerar predições de IA: $e');
    }
  }
  
  /// Gera análise econômica
  Future<void> _generateEconomicAnalysis() async {
    try {
      Logger.info('💰 [AI-ECONOMIC] Gerando análise econômica...');
      
      // Carregar ocorrências
      final occurrences = await _infestacaoRepository?.getAll() ?? [];
      
      // Carregar pontos de monitoramento
      final monitoringPoints = await _getMonitoringPoints();
      
      // Gerar análise econômica
      final economicAnalysis = await _predictionService.generateEconomicAnalysis(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      setState(() {
        _economicAnalysis = economicAnalysis;
      });
      
      Logger.info('✅ [AI-ECONOMIC] Análise econômica gerada com sucesso');
    } catch (e) {
      Logger.error('❌ [AI-ECONOMIC] Erro ao gerar análise econômica: $e');
    }
  }
  
  /// Gera relatório executivo
  Future<void> _generateExecutiveReport() async {
    try {
      Logger.info('📊 [AI-REPORTS] Gerando relatório executivo...');
      
      // Carregar ocorrências
      final occurrences = await _infestacaoRepository?.getAll() ?? [];
      
      // Carregar pontos de monitoramento
      final monitoringPoints = await _getMonitoringPoints();
      
      // Gerar relatório executivo
      final executiveReport = await _reportsService.generateExecutiveReport(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      setState(() {
        _executiveReport = executiveReport;
      });
      
      Logger.info('✅ [AI-REPORTS] Relatório executivo gerado com sucesso');
    } catch (e) {
      Logger.error('❌ [AI-REPORTS] Erro ao gerar relatório executivo: $e');
    }
  }
  
  /// Executa integração completa entre todos os módulos
  Future<void> _executeCompleteIntegration() async {
    try {
      Logger.info('🔄 [INTEGRATION] Executando integração completa...');
      
      // Carregar ocorrências
      final occurrences = await _infestacaoRepository?.getAll() ?? [];
      
      // Carregar pontos de monitoramento
      final monitoringPoints = await _getMonitoringPoints();
      
      // Executar integração completa
      final integrationResult = await _integrationService.executeCompleteIntegration(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      setState(() {
        _integrationResult = integrationResult;
      });
      
      Logger.info('✅ [INTEGRATION] Integração completa finalizada com sucesso');
      
      // Gerar relatório de integração
      final report = await _integrationService.generateIntegrationReport(integrationResult);
      Logger.info('📋 [INTEGRATION] Relatório de integração: ${report.recommendations.length} recomendações');
      
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro na integração completa: $e');
    }
  }
  
  // ========== SISTEMA DE APRENDIZADO COM FEEDBACK (OFFLINE) ==========
  
  /// Carrega dados de feedback para ajustar confiança do sistema
  /// Funciona 100% OFFLINE usando dados locais do SQLite
  Future<void> _loadFeedbackData() async {
    try {
      Logger.info('🎓 Carregando dados de feedback para ajustar confiança...');
      
      // Buscar estatísticas gerais (OFFLINE)
      final stats = await _feedbackService.getAccuracyStats('default_farm'); // TODO: Usar farmId real
      
      if (stats['totalDiagnoses'] > 0) {
        final overallAccuracy = stats['overallAccuracy'] as double;
        _systemConfidence = overallAccuracy / 100;
        
        Logger.info('   Confiança geral ajustada: ${(_systemConfidence * 100).toStringAsFixed(1)}%');
        
        // Buscar confiança por cultura
        final byCrop = stats['byCrop'] as List<dynamic>;
        for (final crop in byCrop) {
          final cropName = crop['crop_name'] as String;
          final accuracyRate = crop['accuracy_rate'] as double;
          _cropConfidenceMap[cropName] = accuracyRate / 100;
          
          Logger.info('   $cropName: ${accuracyRate.toStringAsFixed(1)}%');
        }
        
        Logger.info('✅ Dados de feedback carregados com sucesso');
      } else {
        Logger.info('ℹ️ Nenhum feedback ainda - usando confiança padrão');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de feedback: $e');
      // Manter valores padrão em caso de erro
    }
  }
  
  /// Ajusta cor do marcador baseada em feedback histórico da fazenda
  /// FUNCIONA 100% OFFLINE com dados locais
  /// Severidade em escala 0-100
  Color _getAdjustedColorByFeedback({
    required String originalLevel,
    required String organismName,
    required double percentual, // 0-100
  }) {
    // Cor original do sistema
    Color systemColor = _getOriginalColor(originalLevel);
    
    // Se temos padrões para este organismo, ajustar cor
    if (_farmOrganismPatterns.containsKey(organismName)) {
      final pattern = _farmOrganismPatterns[organismName]!;
      
      if (pattern.containsKey('avg_severity')) {
        final avgRealSeverity = pattern['avg_severity']!; // 0-100
        final occurrenceCount = pattern['occurrence_count'] ?? 1;
        
        // Quanto mais dados temos, mais confiamos no ajuste (máx 50%)
        final weight = (occurrenceCount / 10).clamp(0.0, 0.5);
        
        // Calcular severidade ajustada (0-100)
        final adjustedSeverity = percentual * (1 - weight) + avgRealSeverity * weight;
        
        // Retornar cor baseada na severidade ajustada (0-100)
        return _getSeverityColor(adjustedSeverity);
      }
    }
    
    // Se não há dados de feedback, usar cor original
    return systemColor;
  }
  
  /// Retorna cor original baseada no nível (sistema padrão)
  Color _getOriginalColor(String level) {
    switch (level.toLowerCase()) {
      case 'crítico':
      case 'critico':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'médio':
      case 'medio':
      case 'moderado':
        return Colors.yellow.shade700;
      case 'baixo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// Retorna cor baseada em percentual de severidade
  /// NOTA: Método já existe na linha 3478, usando aquele
  // Color _getSeverityColor(double severity) {
  //   if (severity <= 25) return Colors.green;
  //   if (severity <= 50) return Colors.yellow.shade700;
  //   if (severity <= 75) return Colors.orange;
  //   return Colors.red;
  // }
  
  /// Retorna cor para badge de confiança
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.75) return Colors.lightGreen;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  /// Navega para dashboard de aprendizado
  void _navigateToLearningDashboard() {
    Navigator.pushNamed(
      context,
      AppRoutes.learningDashboard,
      arguments: {
        'farmId': 'default_farm', // TODO: Usar farmId real
        'farmName': 'Minha Fazenda', // TODO: Usar nome real
      },
    );
  }
  
  /// Obtém pontos de monitoramento
  Future<List<monitoring.MonitoringPoint>> _getMonitoringPoints() async {
    // Implementar busca de pontos de monitoramento
    // Por enquanto, retornar lista vazia
    return [];
  }

}
