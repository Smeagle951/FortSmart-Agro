import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/dashboard_data_service.dart';
import '../../services/module_sync_service.dart';
import '../../models/dashboard/dashboard_data.dart';
import '../../widgets/dashboard/module_card_widget.dart';
import '../../widgets/dashboard/farm_banner.dart';
import '../../widgets/dashboard/info_cards_grid.dart';
import '../../widgets/dashboard/activity_distribution_chart.dart';
import '../../widgets/dashboard/quick_actions_widget.dart';
import '../../widgets/app_drawer.dart';

/// Tela de dashboard premium - versão otimizada para performance
class PremiumDashboardScreen extends StatefulWidget {
  const PremiumDashboardScreen({super.key});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> with WidgetsBindingObserver {
  final DashboardDataService _dashboardService = DashboardDataService();
  final ModuleSyncService _moduleSyncService = ModuleSyncService();
  DashboardData? _dashboardData;
  Map<String, ModuleSyncResult> _moduleSyncResults = {};
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DashboardData>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDashboard();
    _setupDataSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Atualizar dados quando o app volta ao foco
      _refreshData();
    }
  }

  /// Inicializa o dashboard com dados reais
  Future<void> _initializeDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar dados do dashboard
      await _dashboardService.initialize();
      final data = await _dashboardService.loadDashboardData();
      
      // Sincronizar todos os módulos
      final syncResults = await _moduleSyncService.syncAllModules();
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _moduleSyncResults = syncResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Configura subscription para atualizações em tempo real
  void _setupDataSubscription() {
    _dataSubscription = _dashboardService.dataStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _dashboardData = data;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
          });
        }
      },
    );
  }

  /// Atualização manual rápida
  Future<void> _refreshData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Forçar recarregamento dos dados
      final data = await _dashboardService.loadDashboardData();
      
      // Sincronizar todos os módulos novamente
      final syncResults = await _moduleSyncService.syncAllModules();
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _moduleSyncResults = syncResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Sincroniza um módulo específico
  Future<void> _syncModule(String moduleName) async {
    try {
      setState(() {
        // Marcar módulo como carregando
        _moduleSyncResults[moduleName] = ModuleSyncResult(
          moduleName: moduleName,
          status: ModuleStatus.neutral,
          message: 'Sincronizando...',
          dataCount: 0,
          lastSync: DateTime.now(),
        );
      });

      ModuleSyncResult result;
      switch (moduleName) {
        case 'fazenda':
          result = await _moduleSyncService.syncFazenda();
          break;
        case 'alertas':
          result = await _moduleSyncService.syncAlertas();
          break;
        case 'talhoes':
          result = await _moduleSyncService.syncTalhoes();
          break;
        case 'plantios':
          result = await _moduleSyncService.syncPlantios();
          break;
        case 'monitoramentos':
          result = await _moduleSyncService.syncMonitoramentos();
          break;
        case 'estoque':
          result = await _moduleSyncService.syncEstoque();
          break;
        default:
          return;
      }

      if (mounted) {
        setState(() {
          _moduleSyncResults[moduleName] = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moduleSyncResults[moduleName] = ModuleSyncResult(
            moduleName: moduleName,
            status: ModuleStatus.error,
            message: 'Erro na sincronização',
            dataCount: 0,
            lastSync: DateTime.now(),
            error: e.toString(),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        color: const Color(0xFFF8F9FA), // Fundo claro como na imagem original
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho original
              _buildHeader(),
              
              // Conteúdo principal com scroll
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação do botão flutuante
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.grey),
              tooltip: 'Menu',
            ),
          ),
          const Expanded(
            child: Text(
              'FortSmart Agro',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: Colors.grey),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          strokeWidth: 4,
        ),
      );
    }

    if (_error != null) {
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
            const Text(
              'Erro ao carregar dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Banner da fazenda
            FarmBanner(
              farmProfile: _dashboardData?.farmProfile,
              onRefresh: _refreshData,
              onSettings: () {
                // Navegar para configurações
              },
            ),
            
            const SizedBox(height: 16),
            
            // Grid de cards informativos
            InfoCardsGrid(
              dashboardData: _dashboardData,
            ),
            
            const SizedBox(height: 16),
            
            // Gráfico de distribuição de atividades
            ActivityDistributionChart(
              dashboardData: _dashboardData,
            ),
            
            const SizedBox(height: 16),
            
            // Ações Rápidas
            const QuickActionsWidget(),
            
            const SizedBox(height: 16),
            
            // Grid de módulos com sincronização individual
            _buildModuleCards(),
            
            const SizedBox(height: 80), // Espaço para o FAB
          ],
        ),
      ),
    );
  }

  /// Constrói os cards dos módulos com sincronização individual
  Widget _buildModuleCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Módulos do Sistema',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid de módulos
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              // Card Fazenda
              ModuleCardWidget(
                moduleName: 'fazenda',
                title: 'Fazenda',
                icon: Icons.agriculture,
                syncResult: _moduleSyncResults['fazenda'],
                onTap: () => _syncModule('fazenda'),
              ),
              
              // Card Alertas
              ModuleCardWidget(
                moduleName: 'alertas',
                title: 'Alertas',
                icon: Icons.warning,
                syncResult: _moduleSyncResults['alertas'],
                onTap: () => _syncModule('alertas'),
              ),
              
              // Card Talhões
              ModuleCardWidget(
                moduleName: 'talhoes',
                title: 'Talhões',
                icon: Icons.grid_view,
                syncResult: _moduleSyncResults['talhoes'],
                onTap: () => _syncModule('talhoes'),
              ),
              
              // Card Plantios
              ModuleCardWidget(
                moduleName: 'plantios',
                title: 'Plantios',
                icon: Icons.eco,
                syncResult: _moduleSyncResults['plantios'],
                onTap: () => _syncModule('plantios'),
              ),
              
              // Card Monitoramentos
              ModuleCardWidget(
                moduleName: 'monitoramentos',
                title: 'Monitoramentos',
                icon: Icons.analytics,
                syncResult: _moduleSyncResults['monitoramentos'],
                onTap: () => _syncModule('monitoramentos'),
              ),
              
              // Card Estoque
              ModuleCardWidget(
                moduleName: 'estoque',
                title: 'Estoque',
                icon: Icons.inventory,
                syncResult: _moduleSyncResults['estoque'],
                onTap: () => _syncModule('estoque'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}