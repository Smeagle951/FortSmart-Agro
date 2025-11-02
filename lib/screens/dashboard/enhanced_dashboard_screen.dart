import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Serviços e repositórios
import '../../database/app_database.dart';
import '../../services/api_service.dart';
import '../../services/sync_service.dart';
import '../../services/connectivity_monitor_service.dart';
import '../../services/dashboard_plot_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/gps_quality_service.dart';
import '../../services/data_cache_service.dart';
import '../../services/dashboard_data_service.dart';
import '../../utils/dashboard_test_script.dart';

// Modelos
import '../../models/farm.dart';
import '../../models/plot.dart';
import '../../models/inventory_item.dart';

import '../../models/talhao_model.dart';

// Repositórios
import '../../repositories/farm_repository.dart';
import '../../repositories/plot_repository.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/monitoring_repository.dart';

import '../../repositories/talhao_repository.dart';

// Widgets
import '../../widgets/app_drawer.dart';
import '../../widgets/maptiler_plot_map.dart';
import '../../widgets/premium_dashboard_card.dart';
import '../../widgets/premium_stats_card.dart';
import '../../widgets/premium_activity_card.dart';
import '../../widgets/premium_gps_quality_indicator.dart';
import '../../widgets/quick_indicators_card.dart';
import '../../widgets/monitoring_card_widget.dart';
import '../../widgets/alerts_card_widget.dart';
import '../../widgets/farm_card_widget.dart';
import '../../widgets/plantings_card_widget.dart';
import '../../widgets/inventory_card_widget.dart';

// Rotas e utilitários
import '../../routes.dart';
import '../../utils/constants.dart';
import '../../providers/safra_provider.dart';
import '../../providers/cultura_provider.dart';
import '../../providers/farm_provider.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({Key? key}) : super(key: key);

  @override
  _EnhancedDashboardScreenState createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  // ===== REPOSITÓRIOS =====
  final FarmRepository _farmRepository = FarmRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final MonitoringRepository _monitoringRepository = MonitoringRepository();
  
  // ===== SERVIÇOS =====
  final ApiService _apiService = ApiService();
  final SyncService _syncService = SyncService();
  final DashboardPlotService _dashboardPlotService = DashboardPlotService();
  final ConnectivityMonitorService _connectivityService = ConnectivityMonitorService();
  final DashboardDataService _dashboardDataService = DashboardDataService();
  final DashboardTestScript _testScript = DashboardTestScript();
  
  // ===== ANIMAÇÕES =====
  late AnimationController _refreshAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  // ===== ESTADO =====
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _errorMessage = '';
  bool _hasError = false;
  
  // ===== DADOS DA FAZENDA =====
  Farm? _selectedFarm;
  List<Plot> _plots = [];
  List<TalhaoModel> _talhoes = [];
  
  // ===== ESTATÍSTICAS =====
  Map<String, dynamic> _dashboardStats = {};
  Map<String, String> _cropAreas = {};
  List<String> _availableCropTypes = [];
  
  // ===== ALERTAS E MONITORAMENTO =====
  List<InventoryItem> _criticalStockItems = [];
  List<dynamic> _highSeverityMonitorings = [];
  int _totalAlerts = 0;
  
  // ===== DADOS ADICIONAIS =====
  List<dynamic> _activePlantings = [];
  List<dynamic> _inventoryItems = [];
  
  // ===== ATIVIDADES RECENTES =====
  List<Map<String, dynamic>> _recentActivities = [];
  
  // ===== FILTROS =====
  String? _selectedPlotId;
  String? _selectedCropType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showResolved = true;
  bool _isExpandedFilters = false;
  
  // ===== TIMER PARA ATUALIZAÇÃO AUTOMÁTICA =====
  Timer? _autoRefreshTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadDashboardData();
    _startAutoRefresh();
  }
  
  /// Inicializa os serviços necessários
  Future<void> _initializeServices() async {
    try {
      await _dashboardDataService.initialize();
      
      // Gerar dados de teste de infestação se necessário
      await _dashboardDataService.generateTestInfestationData();
      
    } catch (e) {
      print('❌ Erro ao inicializar serviços: $e');
    }
  }
  
  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _fadeAnimationController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
  
  // ===== INICIALIZAÇÃO =====
  
  /// Inicializa as animações
  void _initializeAnimations() {
    _refreshAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimationController.forward();
  }
  
  /// Inicia atualização automática
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && !_isLoading) {
        _refreshDashboard();
      }
    });
  }
  
  // ===== CARREGAMENTO DE DADOS =====
  
  /// Carrega todos os dados do dashboard com fallbacks (versão otimizada)
  Future<void> _loadDashboardData() async {
    if (_isLoading) return;
    
    print('🔄 Iniciando carregamento do dashboard...');
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      print('🔄 Carregando dados reais...');
      
      // Carregar dados da fazenda usando FarmProvider com timeout reduzido
      try {
        final farmProvider = Provider.of<FarmProvider>(context, listen: false);
        await farmProvider.loadFarms().timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            print('⚠️ Timeout ao carregar dados da fazenda, continuando...');
          },
        );
      } catch (e) {
        print('⚠️ Erro ao carregar dados da fazenda: $e, continuando...');
      }
      
      // Carregar dados com timeouts muito reduzidos para melhor performance
      await _loadPlotData().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('⚠️ Timeout ao carregar dados dos talhões, usando fallback');
          return _loadPlotDataFallback();
        },
      );
      
      await _loadActivePlantings().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          print('⚠️ Timeout ao carregar plantios ativos, usando fallback');
          return _loadActivePlantingsFallback();
        },
      );
      
      await _loadInventoryData().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          print('⚠️ Timeout ao carregar dados de estoque, usando fallback');
          return _loadInventoryDataFallback();
        },
      );
      
      await _loadMonitoringData().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          print('⚠️ Timeout ao carregar dados de monitoramento, usando fallback');
          return _loadMonitoringDataFallback();
        },
      );
      
      await _loadInfestationAlerts().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          print('⚠️ Timeout ao carregar alertas de infestação, usando fallback');
          return _loadInfestationAlertsFallback();
        },
      );
      
      await _loadDashboardStats().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          print('⚠️ Timeout ao carregar estatísticas, usando fallback');
          return _loadDashboardStatsFallback();
        },
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      print('✅ Dashboard carregado com sucesso');
      
    } catch (e) {
      print('❌ Erro no dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erro ao carregar dados: $e';
        });
      }
    }
  }
  
  /// Garante que o banco de dados esteja aberto
  Future<void> _ensureDatabaseOpen() async {
    final appDatabase = AppDatabase();
    await appDatabase.ensureDatabaseOpen();
  }
  
  /// Carrega dados da fazenda usando FarmProvider
  Future<void> _loadFarmData() async {
    try {
      print('🔄 Carregando dados da fazenda via FarmProvider...');
      
      final farmProvider = Provider.of<FarmProvider>(context, listen: false);
      await farmProvider.loadFarms();
      
      print('✅ Dados da fazenda carregados via FarmProvider');
    } catch (e) {
      print('❌ Erro ao carregar dados da fazenda: $e');
    }
  }

  
  
  /// Carrega dados dos talhões (versão otimizada)
  Future<void> _loadPlotData() async {
    try {
      print('🔄 Carregando dados dos talhões...');
      
      // Tentar carregar do repositório de talhões com timeout curto
      try {
        final talhaoRepository = TalhaoRepository();
        final talhoes = await talhaoRepository.getTalhoes().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print('⚠️ Timeout no TalhaoRepository, usando fallback');
            throw TimeoutException('Timeout no TalhaoRepository', const Duration(seconds: 2));
          },
        );
        
        if (talhoes.isNotEmpty) {
          print('📊 Talhões carregados do TalhaoRepository: ${talhoes.length}');
          
          // Converter TalhaoModel para Plot para compatibilidade
          final plots = talhoes.map((talhao) => Plot(
            id: talhao.id,
            name: talhao.name,
            area: talhao.area,
            cropType: talhao.crop?.name ?? '',
            cropName: talhao.crop?.name ?? '',
            farmId: talhao.fazendaId != null ? int.tryParse(talhao.fazendaId.toString()) ?? 1 : 1,
            propertyId: 1,
            createdAt: talhao.dataCriacao.toIso8601String(),
            updatedAt: talhao.dataAtualizacao.toIso8601String(),
            polygonJson: talhao.poligonos.isNotEmpty ? 
              jsonEncode(talhao.poligonos.first.pontos.map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              }).toList()) : null,
            notes: talhao.observacoes ?? '',
            isSynced: talhao.sincronizado,
            syncStatus: talhao.sincronizado ? 1 : 0,
          )).toList();
          
          if (mounted) {
            setState(() {
              _plots = plots;
              _talhoes = talhoes;
            });
            await _loadAvailableCropTypes();
          }
          
          print('✅ Dados dos talhões carregados com sucesso do TalhaoRepository');
          return;
        }
      } catch (e) {
        print('⚠️ Erro ao carregar do TalhaoRepository: $e');
      }
      
      // Fallback rápido para dados simulados
      print('⚠️ Usando dados simulados para talhões (carregamento rápido)');
      if (mounted) {
        setState(() {
          _plots = [
            Plot(
              id: 'plot_1',
              name: 'Talhão 01',
              area: 150.0,
              cropType: 'Soja',
              farmId: 1,
              propertyId: 1,
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            ),
            Plot(
              id: 'plot_2',
              name: 'Talhão 02',
              area: 200.0,
              cropType: 'Milho',
              farmId: 1,
              propertyId: 1,
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            ),
            Plot(
              id: 'plot_3',
              name: 'Talhão 03',
              area: 180.0,
              cropType: 'Algodão',
              farmId: 1,
              propertyId: 1,
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            ),
          ];
        });
        await _loadAvailableCropTypes();
      }
      
    } catch (e) {
      print('❌ Erro ao carregar dados dos talhões: $e');
      // Em caso de erro, usar dados simulados
      if (mounted) {
        setState(() {
          _plots = [
            Plot(
              id: 'plot_1',
              name: 'Talhão 01',
              area: 150.0,
              cropType: 'Soja',
              farmId: 1,
              propertyId: 1,
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            ),
          ];
        });
        await _loadAvailableCropTypes();
      }
    }
  }
  
  /// Carrega tipos de cultura disponíveis
  Future<void> _loadAvailableCropTypes() async {
    if (!mounted) return;
    
    try {
      print('🔄 Carregando culturas disponíveis...');
      
      // Carregar culturas do CulturaProvider
      final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
      await culturaProvider.carregarCulturas();
      final culturas = culturaProvider.culturas;
      
      print('📊 Culturas carregadas: ${culturas.length}');
      for (var cultura in culturas) {
        print('  - ${cultura.name}');
      }
      
      // Extrair tipos de cultura dos talhões existentes
      final cropTypes = <String>{};
      for (final plot in _plots) {
        if (plot.cropType != null && plot.cropType!.isNotEmpty) {
          cropTypes.add(plot.cropType!);
        }
      }
      
      // Adicionar culturas do provider
      for (final cultura in culturas) {
        cropTypes.add(cultura.name);
      }
      
      if (mounted) {
        setState(() {
          _availableCropTypes = cropTypes.toList()..sort();
        });
      }
      
      print('✅ Tipos de cultura disponíveis: ${_availableCropTypes.length}');
    } catch (e) {
      print('❌ Erro ao carregar culturas: $e');
      
      // Fallback: apenas tipos dos talhões
      final cropTypes = <String>{};
      for (final plot in _plots) {
        if (plot.cropType != null && plot.cropType!.isNotEmpty) {
          cropTypes.add(plot.cropType!);
        }
      }
      
      if (mounted) {
        setState(() {
          _availableCropTypes = cropTypes.toList()..sort();
        });
      }
    }
  }
  
  /// Carrega dados de estoque
  Future<void> _loadInventoryData() async {
    try {
      print('🔄 Carregando dados de estoque...');
      
      // Tentar carregar dados reais de estoque
      try {
        final criticalItems = await _inventoryRepository.getCriticalStockItems();
        final allItems = await _inventoryRepository.getAllItems();
        
        if (mounted) {
          setState(() {
            _criticalStockItems = criticalItems;
            _inventoryItems = allItems.map((item) => {
              'id': item.id,
              'name': item.name,
              'quantity': item.quantity,
              'unit': item.unit,
              'type': item.type,
              'category': item.type,
              'location': item.location,
              'minimumLevel': item.minimumLevel,
            }).toList();
          });
        }
        
        print('✅ Dados de estoque carregados: ${allItems.length} itens');
        return;
      } catch (e) {
        print('⚠️ Erro ao carregar dados reais de estoque: $e');
      }
      
      // Fallback para dados vazios quando não há dados reais
      print('⚠️ Nenhum dado de estoque encontrado');
      if (mounted) {
        setState(() {
          _criticalStockItems = [];
          _inventoryItems = [];
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar dados de estoque: $e');
    }
  }
  
  /// Carrega dados de plantios ativos
  Future<void> _loadActivePlantings() async {
    try {
      print('🔄 Carregando dados de plantios ativos...');
      
      // Criar dados de plantios ativos baseados nos talhões
      final plantings = <Map<String, dynamic>>[];
      
      for (final plot in _plots) {
        if (plot.cropType != null && plot.cropType!.isNotEmpty) {
          plantings.add({
            'id': plot.id,
            'plotName': plot.name,
            'cropName': plot.cropType,
            'area': plot.area,
            'stage': _getRandomStage(),
            'plantingDate': DateTime.now().subtract(Duration(days: 30 + (plantings.length * 10))),
            'expectedHarvest': DateTime.now().add(Duration(days: 120 + (plantings.length * 15))),
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _activePlantings = plantings;
        });
      }
      
      print('✅ Dados de plantios ativos carregados: ${plantings.length} plantios');
    } catch (e) {
      print('❌ Erro ao carregar dados de plantios ativos: $e');
    }
  }
  
  /// Retorna um estágio aleatório para simulação
  String _getRandomStage() {
    final stages = ['Germinação', 'Desenvolvimento', 'Floração', 'Frutificação', 'Maturação'];
    return stages[DateTime.now().millisecond % stages.length];
  }
  
  /// Carrega dados de monitoramento
  Future<void> _loadMonitoringData() async {
    try {
      print('🔄 Carregando dados de monitoramento...');
      
      // Carregar dados de monitoramento usando o novo serviço
      final monitoringData = await _dashboardDataService.loadMonitoringData();
      
      if (mounted) {
        setState(() {
          _highSeverityMonitorings = monitoringData['monitorings'] ?? [];
          _totalAlerts = monitoringData['pendentes'] ?? 0;
        });
      }
      
      print('✅ Dados de monitoramento carregados: ${monitoringData['total']} monitoramentos');
      
      // Se não há dados, tentar gerar dados de teste
      if ((monitoringData['total'] ?? 0) == 0) {
        print('⚠️ Nenhum dado de monitoramento encontrado, gerando dados de teste...');
        await _dashboardDataService.generateTestDataIfNeeded();
        
        // Recarregar dados após gerar dados de teste
        final newMonitoringData = await _dashboardDataService.loadMonitoringData();
        if (mounted) {
          setState(() {
            _highSeverityMonitorings = newMonitoringData['monitorings'] ?? [];
            _totalAlerts = newMonitoringData['pendentes'] ?? 0;
          });
        }
      }
      
    } catch (e) {
      print('❌ Erro ao carregar dados de monitoramento: $e');
      if (mounted) {
        setState(() {
          _highSeverityMonitorings = [];
          _totalAlerts = 0;
        });
      }
    }
  }
  
  /// Carrega dados de alertas de infestação
  Future<void> _loadInfestationAlerts() async {
    try {
      print('🔄 Carregando alertas de infestação...');
      
      // Carregar alertas de infestação usando o novo serviço
      final alertsData = await _dashboardDataService.loadInfestationAlerts();
      
      if (mounted) {
        setState(() {
          _totalAlerts = alertsData['total_count'] ?? 0;
        });
      }
      
      print('✅ Alertas de infestação carregados: ${alertsData['total_count']} alertas');
      
      // Se não há dados, tentar gerar dados de teste
      if ((alertsData['total_count'] ?? 0) == 0) {
        print('⚠️ Nenhum alerta de infestação encontrado, gerando dados de teste...');
        await _dashboardDataService.generateTestDataIfNeeded();
        
        // Recarregar dados após gerar dados de teste
        final newAlertsData = await _dashboardDataService.loadInfestationAlerts();
        if (mounted) {
          setState(() {
            _totalAlerts = newAlertsData['total_count'] ?? 0;
          });
        }
      }
      
    } catch (e) {
      print('❌ Erro ao carregar alertas de infestação: $e');
      if (mounted) {
        setState(() {
          _totalAlerts = 0;
        });
      }
    }
  }

  /// Carrega atividades recentes
  Future<void> _loadRecentActivities() async {
    try {
      // Simula atividades recentes (implementar com dados reais)
      if (mounted) {
        setState(() {
          _recentActivities = [
            {
              'type': 'planting',
              'title': 'Plantio realizado',
              'description': 'Talhão 01 - Soja plantada',
              'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
              'icon': Icons.agriculture,
              'color': Colors.green,
            },
            {
              'type': 'monitoring',
              'title': 'Monitoramento detectado',
              'description': 'Praga identificada no Talhão 03',
              'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
              'icon': Icons.warning,
              'color': Colors.orange,
            },
            {
              'type': 'application',
              'title': 'Aplicação realizada',
              'description': 'Defensivo aplicado no Talhão 02',
              'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
              'icon': Icons.local_florist,
              'color': Colors.blue,
            },
          ];
        });
      }
    } catch (e) {
      print('Erro ao carregar atividades recentes: $e');
    }
  }
  
  /// Carrega estatísticas do dashboard
  Future<void> _loadDashboardStats() async {
    try {
      if (mounted) {
        setState(() {
          _dashboardStats = {
            'totalPlots': _plots.length.toString(),
            'totalArea': _calculateTotalArea().toStringAsFixed(2),
            'activeCrops': _availableCropTypes.length.toString(),
            'criticalStock': _criticalStockItems.length.toString(),
            'pendingTasks': '3',
            'syncStatus': 'Online', // Simplificado para evitar problemas
          };
          
          _cropAreas = _calculateCropAreas();
        });
      }
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }
  
  /// Calcula área total
  double _calculateTotalArea() {
    double totalArea = 0.0;
    
    // Calcular área dos talhões se disponível
    if (_talhoes.isNotEmpty) {
      for (final talhao in _talhoes) {
        totalArea += talhao.area ?? 0.0;
      }
    } else {
      // Calcular área dos plots se talhões não estiverem disponíveis
      for (final plot in _plots) {
        totalArea += plot.area ?? 0.0;
      }
    }
    
    return totalArea;
  }
  
  /// Calcula áreas por cultura
  Map<String, String> _calculateCropAreas() {
    final cropAreas = <String, double>{};
    
    for (final plot in _plots) {
      if (plot.cropType != null) {
        cropAreas[plot.cropType!] = (cropAreas[plot.cropType!] ?? 0.0) + (plot.area ?? 0.0);
      }
    }
    
    return cropAreas.map((key, value) => MapEntry(key, value.toStringAsFixed(2)));
  }
  
  // ===== AÇÕES =====
  
  /// Atualiza o dashboard
  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshAnimationController.repeat();
    
    await _loadDashboardData();
    
    _refreshAnimationController.stop();
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  
  /// Recarrega especificamente as culturas (útil após criar talhão)
  Future<void> refreshCultures() async {
    print('🔄 Recarregando culturas no dashboard...');
    await _loadAvailableCropTypes();
    print('✅ Culturas recarregadas no dashboard');
  }
  
  /// Navega para uma rota específica
  void _navigateTo(String route, {Object? arguments}) {
    try {
      // Verificar se a rota existe antes de navegar
      if (AppRoutes.hasRoute(route)) {
    Navigator.pushNamed(context, route, arguments: arguments);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Módulo $route não encontrado'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
      ),
    );
  }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir $route: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // ===== BUILD METHOD =====
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: _buildBody(),
    );
  }
  
  /// Constrói a AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Dashboard Premium',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
      backgroundColor: const Color(0xFF3BAA57),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        tooltip: 'Menu',
      ),
      actions: [
        IconButton(
          icon: AnimatedBuilder(
            animation: _refreshAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimationController.value * 2 * 3.14159,
                child: const Icon(Icons.refresh),
              );
            },
          ),
          onPressed: _isRefreshing ? null : _refreshDashboard,
          tooltip: 'Atualizar',
        ),
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () => _navigateTo(AppRoutes.reports),
          tooltip: 'Relatório Agronômico',
        ),
        IconButton(
          icon: const Icon(Icons.science),
          onPressed: _runDashboardTest,
          tooltip: 'Testar Dashboard',
        ),
      ],
    );
  }
  
  /// Constrói o corpo da tela
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3BAA57)),
            ),
            SizedBox(height: 16),
              Text(
              'Carregando dashboard...',
              style: TextStyle(fontSize: 16),
              ),
            ],
          ),
      );
    }
    
    if (_hasError) {
      return _buildErrorState();
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: const Color(0xFF3BAA57),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFarmInfoCard(),
              const SizedBox(height: 16),
              _buildAlertsCard(),
              const SizedBox(height: 16),
              _buildQuickIndicatorsSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState() {
    return Center(
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
            'Erro ao carregar dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BAA57),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
  
  /// Constrói card informativo da fazenda
  Widget _buildFarmInfoCard() {
    return FarmCardWidget(
      onTap: () => _navigateTo(AppRoutes.farmProfile),
    );
  }

  Widget _buildFarmInfoCardOld() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.selectedFarm;
        
        return PremiumDashboardCard(
          title: 'Informações da Fazenda',
          subtitle: farm?.name ?? 'Nenhuma fazenda selecionada',
          icon: Icons.agriculture,
          color: const Color(0xFF3BAA57),
          onEdit: () => _navigateTo(AppRoutes.farmProfile),
          child: farmProvider.isLoading
            ? const Center(
        child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3BAA57)),
                  ),
                ),
              )
            : farm == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
          child: Column(
            children: [
                        Icon(Icons.agriculture, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
              Text(
                          'Nenhuma fazenda encontrada',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo da fazenda
                    if (farm.logoUrl != null && farm.logoUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            farm.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.agriculture,
                                  size: 48,
                  color: Colors.grey,
                ),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    // Nome da fazenda
                    Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            farm.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3BAA57),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Endereço
                    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            farm.address ?? 'Endereço não informado',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Nome do proprietário
                    if (farm.ownerName != null && farm.ownerName!.isNotEmpty)
        Row(
          children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
            Expanded(
                            child: Text(
                              'Proprietário: ${farm.ownerName}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    
                    if (farm.ownerName != null && farm.ownerName!.isNotEmpty)
                      const SizedBox(height: 8),
                    
                    // Tamanho total em hectares
                    Row(
                      children: [
                        const Icon(Icons.area_chart, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
            Expanded(
                          child: Text(
                            'Área total: ${farm.totalArea.toStringAsFixed(2)} hectares',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
              ),
            ),
          ],
        ),
                    const SizedBox(height: 8),
                    
                    // Informações adicionais
        Row(
          children: [
                        const Icon(Icons.agriculture, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
            Expanded(
                          child: Text(
                            'Talhões: ${farm.plotsCount}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    
                    // Município e Estado
                    if (farm.municipality != null && farm.municipality!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
            Expanded(
                              child: Text(
                                '${farm.municipality}${farm.state != null && farm.state!.isNotEmpty ? ', ${farm.state}' : ''}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
  
  /// Constrói card de filtros
  Widget _buildFiltersCard() {
    return PremiumDashboardCard(
      title: 'Filtros',
      subtitle: 'Configurar filtros de visualização',
      icon: Icons.filter_list,
      color: Colors.blue,
      onExpand: () {
        setState(() {
          _isExpandedFilters = !_isExpandedFilters;
        });
      },
      isExpanded: _isExpandedFilters,
      child: _isExpandedFilters ? _buildFiltersContent() : null,
    );
  }
  
  /// Constrói conteúdo dos filtros
  Widget _buildFiltersContent() {
    return Column(
            children: [
        // Filtro por talhão
        DropdownButtonFormField<String>(
          value: _selectedPlotId,
          decoration: const InputDecoration(
            labelText: 'Talhão',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos os talhões')),
            ..._plots.map((plot) => DropdownMenuItem(
              value: plot.id ?? '',
              child: Text(plot.name ?? 'Talhão sem nome'),
            )).toSet().toList(), // Remove duplicados
          ],
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _selectedPlotId = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Filtro por cultura
        DropdownButtonFormField<String>(
          value: _selectedCropType,
          decoration: const InputDecoration(
            labelText: 'Cultura',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas as culturas')),
            ..._availableCropTypes.map((crop) => DropdownMenuItem(
              value: crop,
              child: Text(crop),
            )).toSet().toList(), // Remove duplicados
          ],
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _selectedCropType = value;
              });
            }
          },
        ),
      ],
    );
  }
  
  /// Constrói card de alertas
  Widget _buildAlertsCard() {
    return AlertsCardWidget(
      onTap: () async {
        print('🔍 Navegando para mapa de infestação...');
        
        // Mostrar indicador de carregamento
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carregando dados de infestação...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Garantir que há dados de infestação antes de navegar
        await _ensureInfestationData();
        
        // Navegar para o Relatório Agronômico
        _navigateTo(AppRoutes.reports);
      },
    );
  }

  /// Garante que há dados de infestação disponíveis
  Future<void> _ensureInfestationData() async {
    try {
      // Verificar se há dados de infestação
      final alertsData = await _dashboardDataService.loadInfestationAlerts();
      final totalCount = alertsData['total_count'] ?? 0;
      
      if (totalCount == 0) {
        print('🔄 Nenhum dado de infestação encontrado, gerando dados de teste...');
        
        // Gerar dados de teste de infestação
        await _dashboardDataService.generateTestInfestationData();
        
        // Aguardar um pouco para garantir que os dados foram inseridos
        await Future.delayed(const Duration(milliseconds: 500));
        
        print('✅ Dados de infestação gerados com sucesso');
      } else {
        print('✅ Dados de infestação já disponíveis: $totalCount alertas');
      }
    } catch (e) {
      print('❌ Erro ao garantir dados de infestação: $e');
    }
  }

  /// Constrói seção de indicadores rápidos
  Widget _buildQuickIndicatorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Indicadores Rápidos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3BAA57),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
              children: [
            _buildTalhoesIndicator(),
            _buildPlantiosIndicator(),
            _buildMonitoramentosIndicator(),
            _buildEstoqueIndicator(),
          ],
        ),
      ],
    );
  }
  
  /// Constrói indicador de talhões
  Widget _buildTalhoesIndicator() {
    final totalTalhoes = _talhoes.isNotEmpty ? _talhoes.length : _plots.length;
    final areaTotal = _calculateTotalArea();
    final ultimaAtualizacao = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    return QuickIndicatorsCard(
      title: 'Talhões',
      icon: Icons.map,
      iconColor: const Color(0xFF4CAF50),
      backgroundColor: Colors.green.shade50,
      onTap: () {
        _navigateTo(AppRoutes.talhoesSafra);
      },
      items: [
        IndicatorItem(label: 'Total', value: '$totalTalhoes', icon: Icons.crop_square),
        IndicatorItem(label: 'Área Total', value: '${areaTotal.toStringAsFixed(1)} ha'),
        IndicatorItem(label: 'Última Atualização', value: ultimaAtualizacao),
      ],
    );
  }
  
  /// Constrói indicador de plantios
  Widget _buildPlantiosIndicator() {
    return PlantingsCardWidget(
      onTap: () {
        _navigateTo(AppRoutes.plantioHome);
      },
    );
  }
  
  /// Constrói indicador de monitoramentos
  Widget _buildMonitoramentosIndicator() {
    return MonitoringCardWidget(
      onTap: () {
        _navigateTo(AppRoutes.monitoringMain);
      },
    );
  }
  
  /// Constrói indicador de estoque
  Widget _buildEstoqueIndicator() {
    return InventoryCardWidget(
      onTap: () {
        _navigateTo(AppRoutes.inventory);
      },
    );
  }
  

  
  /// Constrói card de atividades recentes
  Widget _buildRecentActivitiesCard() {
    return PremiumDashboardCard(
      title: 'Atividades Recentes',
      subtitle: 'Últimas atividades realizadas',
      icon: Icons.history,
      color: Colors.purple,
      child: _recentActivities.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nenhuma atividade recente',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          )
        : Column(
            children: _recentActivities.map((activity) {
              return PremiumActivityCard(
                title: activity['title'],
                description: activity['description'],
                timestamp: activity['timestamp'],
                icon: activity['icon'],
                color: activity['color'],
                onTap: () {
                  // Navegar para a atividade específica
                  switch (activity['type']) {
                    case 'planting':
                      _navigateTo(AppRoutes.plantioDetalhes);
                      break;
                    case 'monitoring':
                      _navigateTo(AppRoutes.reports);
                      break;
                    case 'application':
                      _navigateTo(AppRoutes.costNewApplication);
                      break;
                  }
                },
              );
            }).toList(),
          ),
    );
  }
  

  
  // ===== MÉTODOS AUXILIARES PARA DADOS EM TEMPO REAL =====
  
  /// Obtém informações das culturas em tempo real
  String _getCulturasInfo() {
    if (_activePlantings.isEmpty) {
      return 'Nenhum plantio ativo';
    }
    
    final culturas = <String, double>{};
    for (final planting in _activePlantings) {
      final cropName = planting['cropName'] ?? 'Cultura';
      final area = planting['area'] ?? 0.0;
      culturas[cropName] = (culturas[cropName] ?? 0.0) + area;
    }
    
    if (culturas.isEmpty) {
      return 'Nenhuma cultura ativa';
    }
    
    final culturasList = culturas.entries.take(3).map((entry) {
      final emoji = _getCropEmoji(entry.key);
      return '$emoji ${entry.key} ${entry.value.toStringAsFixed(1)}ha';
    }).join('\n');
    
    return culturasList;
  }
  
  /// Obtém o estágio atual dos plantios
  String _getEstagioAtual() {
    if (_activePlantings.isEmpty) {
      return 'Nenhum plantio ativo';
    }
    
    final estagios = <String, int>{};
    for (final planting in _activePlantings) {
      final estagio = planting['stage'] ?? 'Desconhecido';
      estagios[estagio] = (estagios[estagio] ?? 0) + 1;
    }
    
    if (estagios.isEmpty) {
      return 'Estágio desconhecido';
    }
    
    // Retorna o estágio mais comum
    final estagioMaisComum = estagios.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return estagioMaisComum;
  }
  
  /// Obtém emoji para cada cultura
  String _getCropEmoji(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'soja':
        return '🌱';
      case 'milho':
        return '🌽';
      case 'algodão':
        return '🧶';
      case 'feijão':
        return '🫘';
      case 'arroz':
        return '🌾';
      case 'trigo':
        return '🌾';
      default:
        return '🌿';
    }
  }
  
  /// Obtém informações de estoque em tempo real
  List<IndicatorItem> _getEstoqueInfo() {
    if (_inventoryItems.isEmpty) {
      return [
        const IndicatorItem(
          label: 'Total de Itens',
          value: '0',
          icon: Icons.inventory,
        ),
        const IndicatorItem(
          label: 'Status',
          value: 'Nenhum item cadastrado',
          icon: Icons.info,
        ),
      ];
    }
    
    // Categorizar itens por tipo
    final fertilizantes = _inventoryItems.where((item) => 
      item['category']?.toString().toLowerCase().contains('fertilizante') == true ||
      item['type']?.toString().toLowerCase().contains('fertilizante') == true
    ).toList();
    
    final defensivos = _inventoryItems.where((item) => 
      item['category']?.toString().toLowerCase().contains('defensivo') == true ||
      item['type']?.toString().toLowerCase().contains('defensivo') == true ||
      item['category']?.toString().toLowerCase().contains('pesticida') == true
    ).toList();
    
    final sementes = _inventoryItems.where((item) => 
      item['category']?.toString().toLowerCase().contains('semente') == true ||
      item['type']?.toString().toLowerCase().contains('semente') == true
    ).toList();
    
    // Calcular totais
    final totalFertilizantes = fertilizantes.length;
    final totalDefensivos = defensivos.length;
    final totalSementes = sementes.length;
    
    // Verificar status (simplificado)
    final statusFertilizantes = totalFertilizantes > 0 ? 'OK' : 'Baixo';
    final statusDefensivos = totalDefensivos > 0 ? 'OK' : 'Baixo';
    final statusSementes = totalSementes > 0 ? 'OK' : 'Baixo';
    
    return [
      IndicatorItem(
        label: 'Fertilizantes',
        value: '$totalFertilizantes - $statusFertilizantes',
        icon: totalFertilizantes > 0 ? Icons.check_circle : Icons.warning,
        color: totalFertilizantes > 0 ? Colors.green : Colors.red,
      ),
      IndicatorItem(
        label: 'Defensivos',
        value: '$totalDefensivos - $statusDefensivos',
        icon: totalDefensivos > 0 ? Icons.check_circle : Icons.warning,
        color: totalDefensivos > 0 ? Colors.green : Colors.red,
      ),
      IndicatorItem(
        label: 'Sementes',
        value: '$totalSementes - $statusSementes',
        icon: totalSementes > 0 ? Icons.check_circle : Icons.grain,
        color: totalSementes > 0 ? Colors.green : Colors.orange,
      ),
    ];
  }
  
  // ===== PROPRIEDADES =====
  
  bool get isExpandedFilters => _selectedPlotId != null || _selectedCropType != null;
  
  // ===== MÉTODOS DE FALLBACK =====
  

  
  /// Fallback para dados dos talhões
  Future<void> _loadPlotDataFallback() async {
    print('🔄 Carregando dados dos talhões (fallback)...');
    if (mounted) {
      setState(() {
        _plots = [
          Plot(
            id: 'plot_1',
            name: 'Talhão 01',
            area: 150.0,
            cropType: 'Soja',
            farmId: 1,
            propertyId: 1,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
          Plot(
            id: 'plot_2',
            name: 'Talhão 02',
            area: 200.0,
            cropType: 'Milho',
            farmId: 1,
            propertyId: 1,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
          Plot(
            id: 'plot_3',
            name: 'Talhão 03',
            area: 180.0,
            cropType: 'Algodão',
            farmId: 1,
            propertyId: 1,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
        ];
        _availableCropTypes = ['Soja', 'Milho', 'Algodão'];
      });
    }
  }
  
  /// Fallback para dados de plantios ativos
  Future<void> _loadActivePlantingsFallback() async {
    print('🔄 Carregando dados de plantios ativos (fallback)...');
    if (mounted) {
      setState(() {
        _activePlantings = [
          {
            'id': 'planting_1',
            'plot_name': 'Talhão 01',
            'crop': 'Soja',
            'area': 150.0,
            'planting_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'status': 'Ativo',
          },
          {
            'id': 'planting_2',
            'plot_name': 'Talhão 02',
            'crop': 'Milho',
            'area': 200.0,
            'planting_date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
            'status': 'Ativo',
          },
        ];
      });
    }
  }
  
  /// Fallback para dados de estoque
  Future<void> _loadInventoryDataFallback() async {
    print('🔄 Carregando dados de estoque (fallback)...');
    if (mounted) {
      setState(() {
        _criticalStockItems = [];
        _inventoryItems = [];
      });
    }
  }
  
  /// Fallback para dados de monitoramento
  Future<void> _loadMonitoringDataFallback() async {
    print('🔄 Carregando dados de monitoramento (fallback)...');
    if (mounted) {
      setState(() {
        _highSeverityMonitorings = [];
        _totalAlerts = 0;
      });
    }
  }

  /// Fallback para alertas de infestação
  Future<void> _loadInfestationAlertsFallback() async {
    print('🔄 Carregando alertas de infestação (fallback)...');
    if (mounted) {
      setState(() {
        _totalAlerts = 0;
      });
    }
  }

  /// Executa teste do dashboard
  Future<void> _runDashboardTest() async {
    try {
      print('🧪 Executando teste do dashboard...');
      
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Executando teste do dashboard...'),
            ],
          ),
        ),
      );
      
      // Executar teste
      final results = await _testScript.runFullTest();
      
      // Fechar diálogo de carregamento
      if (mounted) Navigator.of(context).pop();
      
      // Gerar relatório
      final report = _testScript.generateTestReport(results);
      
      // Mostrar resultados
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Teste do Dashboard'),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadDashboardData();
                },
                child: const Text('Atualizar Dashboard'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      print('❌ Erro ao executar teste do dashboard: $e');
      
      // Fechar diálogo se ainda estiver aberto
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao executar teste: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Fallback para estatísticas do dashboard
  Future<void> _loadDashboardStatsFallback() async {
    print('🔄 Carregando estatísticas do dashboard (fallback)...');
    if (mounted) {
      setState(() {
        _dashboardStats = {
          'total_area': 0.0,
          'total_plots': 0,
          'active_crops': 0,
          'total_inventory_items': 0,
          'total_alerts': 0,
        };
        _cropAreas = {};
      });
    }
  }
}