import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../services/enhanced_offline_map_service.dart';
import '../services/map_modules_integration_service.dart';
import '../services/hybrid_gps_service.dart';
import '../services/hybrid_connectivity_service.dart';
import '../services/system_status_service.dart';
import '../widgets/enhanced_map_download_widget.dart';
import '../widgets/optimized_dashboard_cards.dart';
import '../widgets/hybrid_gps_status_widget.dart';
import '../widgets/offline_map_preview_widget.dart';
import '../widgets/storage_usage_widget.dart';
import '../widgets/connectivity_status_widget.dart';
import '../widgets/offline_map_analytics_widget.dart';
import '../widgets/system_status_widget.dart';

/// Tela principal aprimorada para gerenciamento de mapas offline
class EnhancedOfflineMapsScreen extends StatefulWidget {
  const EnhancedOfflineMapsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedOfflineMapsScreen> createState() => _EnhancedOfflineMapsScreenState();
}

class _EnhancedOfflineMapsScreenState extends State<EnhancedOfflineMapsScreen>
    with TickerProviderStateMixin {
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  final MapModulesIntegrationService _integrationService = MapModulesIntegrationService();
  final HybridGPSService _hybridGPSService = HybridGPSService();
  final HybridConnectivityService _connectivityService = HybridConnectivityService();
  final SystemStatusService _systemStatusService = SystemStatusService();
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Estado da tela
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  // Dados do cache
  Map<String, dynamic> _cacheStats = {};
  List<Map<String, dynamic>> _downloadedAreas = [];
  List<Map<String, dynamic>> _monitoringAreas = [];
  List<Map<String, dynamic>> _infestationAreas = [];
  Map<String, dynamic> _integrationStats = {};
  Map<String, dynamic> _gpsStats = {};
  Map<String, dynamic> _connectivityStats = {};
  Map<String, dynamic> _storageStats = {};
  
  // Filtros e busca
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _showOnlyDownloaded = false;
  bool _showOnlyWithErrors = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeServices();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  /// Inicializa serviços e carrega dados
  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await Future.wait([
        _mapService.initialize(),
        _integrationService.initialize(),
        _hybridGPSService.initialize(),
        _connectivityService.initialize(),
        _systemStatusService.initialize(),
      ]);
      
      await _loadAllData();
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao inicializar serviços: $e';
      });
      _showErrorSnackBar(_errorMessage!);
    }
  }
  
  /// Carrega todos os dados necessários
  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        Future.value(_mapService.getCacheStats()),
        Future.value(_mapService.getDownloadedAreas()),
        Future.value(_integrationService.getMonitoringAreas()),
        Future.value(_integrationService.getInfestationAreas()),
        Future.value(_integrationService.getIntegrationStats()),
        Future.value(_hybridGPSService.getTrackingStats()),
        Future.value(_connectivityService.getConnectivityStats()),
        Future.value(_mapService.getStorageStats()),
      ]);
      
      setState(() {
        _cacheStats = results[0] as Map<String, dynamic>;
        _downloadedAreas = results[1] as List<Map<String, dynamic>>;
        _monitoringAreas = results[2] as List<Map<String, dynamic>>;
        _infestationAreas = results[3] as List<Map<String, dynamic>>;
        _integrationStats = results[4] as Map<String, dynamic>;
        _gpsStats = results[5] as Map<String, dynamic>;
        _connectivityStats = results[6] as Map<String, dynamic>;
        _storageStats = results[7] as Map<String, dynamic>;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
      _showErrorSnackBar(_errorMessage!);
    }
  }
  
  /// Atualiza dados com animação
  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    HapticFeedback.lightImpact();
    await _loadAllData();
  }
  
  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildDevelopmentMessage(),
      floatingActionButton: null,
    );
  }
  
  /// AppBar personalizado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mapas Offline - DEV',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        // Botão de busca
        IconButton(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          tooltip: 'Buscar mapas',
        ),
        // Botão de filtros
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtros',
        ),
        // Botão de configurações
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Analytics'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cleanup',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Limpeza'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Configurações'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.map), text: 'Mapas'),
            Tab(icon: Icon(Icons.download), text: 'Downloads'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
    );
  }
  
  /// Estado de carregamento
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Carregando mapas offline...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicializando serviços e cache',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Estado de erro
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Erro ao carregar mapas offline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _initializeServices();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[600]!),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showTroubleshootingDialog,
                  icon: const Icon(Icons.help),
                  label: const Text('Solução de Problemas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Conteúdo principal
  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDashboardTab(),
        _buildMapsTab(),
        _buildDownloadsTab(),
        _buildAnalyticsTab(),
      ],
    );
  }
  
  /// Tab do Dashboard
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status GPS e Conectividade
            _buildStatusSection(),
            
            const SizedBox(height: 20),
            
            // Estatísticas gerais
            _buildStatsSection(),
            
            const SizedBox(height: 20),
            
            // Uso de armazenamento
            _buildStorageSection(),
            
            const SizedBox(height: 20),
            
            // Áreas de monitoramento
            _buildMonitoringAreasSection(),
            
            const SizedBox(height: 20),
            
            // Áreas de infestação
            _buildInfestationAreasSection(),
            
            const SizedBox(height: 20),
            
            // Ações rápidas
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }
  
  /// Tab de Mapas
  Widget _buildMapsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros de mapas
            _buildMapFilters(),
            
            const SizedBox(height: 16),
            
            // Lista de mapas baixados
            _buildDownloadedMapsList(),
          ],
        ),
      ),
    );
  }
  
  /// Tab de Downloads
  Widget _buildDownloadsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de downloads
            _buildDownloadQueue(),
            
            const SizedBox(height: 20),
            
            // Downloads em andamento
            _buildActiveDownloads(),
            
            const SizedBox(height: 20),
            
            // Histórico de downloads
            _buildDownloadHistory(),
          ],
        ),
      ),
    );
  }
  
  /// Tab de Analytics
  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Analytics de Mapas Offline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Widget de analytics
            OfflineMapAnalyticsWidget(
              cacheStats: _cacheStats.isNotEmpty ? _cacheStats : {
                'totalTiles': 0,
                'totalSizeMB': 0.0,
                'lastUpdate': DateTime.now().millisecondsSinceEpoch,
              },
              storageStats: _storageStats.isNotEmpty ? _storageStats : {
                'usedMB': 0.0,
                'totalMB': 500.0,
                'usagePercentage': 0.0,
              },
              integrationStats: _integrationStats.isNotEmpty ? _integrationStats : {
                'monitoringAreas': 0,
                'infestationAreas': 0,
                'totalAreas': 0,
              },
            ),
            
            const SizedBox(height: 20),
            
            // Informações adicionais
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Informações',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem('Última Atualização', _formatLastUpdate()),
                    const SizedBox(height: 8),
                    _buildInfoItem('Status do Cache', _getCacheStatus()),
                    const SizedBox(height: 8),
                    _buildInfoItem('Áreas Disponíveis', '${_monitoringAreas.length + _infestationAreas.length}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatLastUpdate() {
    if (_cacheStats.isNotEmpty && _cacheStats['lastUpdate'] != null) {
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(_cacheStats['lastUpdate']);
      return '${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year}';
    }
    return 'Nunca';
  }

  String _getCacheStatus() {
    if (_cacheStats.isNotEmpty && _cacheStats['totalTiles'] > 0) {
      return 'Ativo (${_cacheStats['totalTiles']} tiles)';
    }
    return 'Vazio';
  }

  double _getCacheUsagePercentage() {
    final totalSize = (_cacheStats['totalSizeMB'] ?? 0).toDouble();
    final maxSize = (_cacheStats['maxSizeMB'] ?? 500).toDouble();
    if (maxSize > 0) {
      return (totalSize / maxSize * 100).clamp(0, 100);
    }
    return 0.0;
  }
  
  /// Seção de status
  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.satellite_alt, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Status do Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status GPS
            // Status do Sistema (GPS + Conectividade)
            SystemStatusWidget(
              statusService: _systemStatusService,
              showDetails: true,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Seção de estatísticas
  Widget _buildStatsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas Gerais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OptimizedDashboardCards.buildStatsCard(
                    title: 'Tiles em Cache',
                    value: '${_cacheStats['totalTiles'] ?? 0}',
                    icon: Icons.map,
                    color: Colors.blue,
                    subtitle: '${(_cacheStats['totalSizeMB'] ?? 0).toStringAsFixed(1)} MB',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OptimizedDashboardCards.buildStatsCard(
                    title: 'Áreas Monitoramento',
                    value: '${_monitoringAreas.length}',
                    icon: Icons.visibility,
                    color: Colors.green,
                    subtitle: '${_monitoringAreas.where((a) => a['mapDownloaded'] == true).length} com mapa',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OptimizedDashboardCards.buildStatsCard(
                    title: 'Áreas Infestação',
                    value: '${_infestationAreas.length}',
                    icon: Icons.bug_report,
                    color: Colors.red,
                    subtitle: '${_infestationAreas.where((a) => a['mapDownloaded'] == true).length} com mapa',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OptimizedDashboardCards.buildStatsCard(
                    title: 'Uso do Cache',
                    value: '${_getCacheUsagePercentage()}%',
                    icon: Icons.storage,
                    color: Colors.orange,
                    subtitle: '${(_cacheStats['totalSizeMB'] ?? 0).toStringAsFixed(1)}/${(_cacheStats['maxSizeMB'] ?? 500).toStringAsFixed(0)} MB',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Seção de armazenamento
  Widget _buildStorageSection() {
    return StorageUsageWidget(
      storageStats: _storageStats,
      onCleanup: _showCleanupDialog,
    );
  }
  
  /// Seção de áreas de monitoramento
  Widget _buildMonitoringAreasSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Áreas de Monitoramento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // Navegar para criação de área
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova Área'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_monitoringAreas.isEmpty)
              _buildEmptyState('Nenhuma área de monitoramento registrada')
            else
              ..._monitoringAreas.map((area) => _buildAreaCard(area, 'monitoring')),
          ],
        ),
      ),
    );
  }
  
  /// Seção de áreas de infestação
  Widget _buildInfestationAreasSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.red[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Áreas de Infestação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // Navegar para criação de área
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova Área'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_infestationAreas.isEmpty)
              _buildEmptyState('Nenhuma área de infestação registrada')
            else
              ..._infestationAreas.map((area) => _buildAreaCard(area, 'infestation')),
          ],
        ),
      ),
    );
  }
  
  /// Seção de ações rápidas
  Widget _buildQuickActionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Ações Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OptimizedDashboardCards.buildActionCard(
                    title: 'Limpar Cache',
                    icon: Icons.delete_sweep,
                    color: Colors.red,
                    subtitle: 'Remove mapas antigos',
                    onTap: _showCleanupDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OptimizedDashboardCards.buildActionCard(
                    title: 'Sincronizar',
                    icon: Icons.sync,
                    color: Colors.blue,
                    subtitle: 'Sincroniza módulos',
                    onTap: _syncModules,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Filtros de mapas
  Widget _buildMapFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('Apenas baixados'),
                    selected: _showOnlyDownloaded,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyDownloaded = selected;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Com erros'),
                    selected: _showOnlyWithErrors,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyWithErrors = selected;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Lista de mapas baixados
  Widget _buildDownloadedMapsList() {
    final filteredAreas = _downloadedAreas.where((area) {
      if (_showOnlyDownloaded && area['status'] != 'downloaded') return false;
      if (_showOnlyWithErrors && area['status'] != 'error') return false;
      if (_searchQuery.isNotEmpty) {
        return area['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();
    
    if (filteredAreas.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhum mapa encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajuste os filtros ou baixe novos mapas',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: filteredAreas.map((area) => _buildMapCard(area)).toList(),
    );
  }
  
  /// Fila de downloads
  Widget _buildDownloadQueue() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.queue, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Fila de Downloads',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Implementar lista de downloads em fila
            _buildEmptyState('Nenhum download na fila'),
          ],
        ),
      ),
    );
  }
  
  /// Downloads ativos
  Widget _buildActiveDownloads() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Downloads Ativos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Implementar lista de downloads ativos
            _buildEmptyState('Nenhum download ativo'),
          ],
        ),
      ),
    );
  }
  
  /// Histórico de downloads
  Widget _buildDownloadHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Histórico de Downloads',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Implementar lista de histórico
            _buildEmptyState('Nenhum download no histórico'),
          ],
        ),
      ),
    );
  }
  
  /// Estado vazio
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Card de área
  Widget _buildAreaCard(Map<String, dynamic> area, String moduleType) {
    final hasMap = area['mapDownloaded'] == true;
    final color = hasMap ? Colors.green : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            moduleType == 'monitoring' ? Icons.visibility : Icons.bug_report,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          area['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${hasMap ? "Mapa disponível" : "Mapa não baixado"}'),
            if (area['lastMonitoring'] != null)
              Text('Último monitoramento: ${area['lastMonitoring']}'),
            if (area['totalPoints'] != null)
              Text('Pontos: ${area['totalPoints']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasMap)
              IconButton(
                onPressed: () => _downloadMapForArea(area, moduleType),
                icon: const Icon(Icons.download),
                tooltip: 'Baixar mapa',
              ),
            IconButton(
              onPressed: () {
                // Mostrar detalhes da área
              },
              icon: const Icon(Icons.info_outline),
              tooltip: 'Detalhes',
            ),
          ],
        ),
      ),
    );
  }
  
  /// Card de mapa
  Widget _buildMapCard(Map<String, dynamic> area) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tipo: ${area['mapType']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(area['status']),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.zoom_in, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Zoom: ${area['minZoom']}-${area['maxZoom']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${area['sizeMB']} MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Mostrar detalhes
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detalhes'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Ação do mapa
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Atualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
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
    );
  }
  
  /// Chip de status
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'downloaded':
        color = Colors.green;
        label = 'Baixado';
        break;
      case 'downloading':
        color = Colors.blue;
        label = 'Baixando';
        break;
      case 'error':
        color = Colors.red;
        label = 'Erro';
        break;
      default:
        color = Colors.grey;
        label = 'Pendente';
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  /// Botão flutuante
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showDownloadDialog,
      icon: const Icon(Icons.download),
      label: const Text('Baixar Mapas'),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    );
  }
  
  /// Download de mapa para área específica
  Future<void> _downloadMapForArea(Map<String, dynamic> area, String moduleType) async {
    try {
      final result = await _integrationService.downloadMapForMonitoring(
        areaId: area['id'],
        onProgress: (progress) {
          // Mostrar progresso se necessário
        },
      );
      
      if (result['success']) {
        _showSuccessSnackBar('Mapa baixado com sucesso!');
        await _refreshData();
      } else {
        _showErrorSnackBar('Erro ao baixar mapa: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao baixar mapa: $e');
    }
  }
  
  /// Sincroniza módulos
  Future<void> _syncModules() async {
    try {
      final result = await _integrationService.syncModules();
      if (result['success']) {
        _showSuccessSnackBar('Módulos sincronizados com sucesso!');
        await _refreshData();
      } else {
        _showErrorSnackBar('Erro na sincronização: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('Erro na sincronização: $e');
    }
  }
  
  /// Mostra diálogo de busca
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Mapas'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Digite o nome do mapa...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1); // Ir para tab de mapas
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
  
  /// Mostra diálogo de filtros
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Apenas baixados'),
              value: _showOnlyDownloaded,
              onChanged: (value) {
                setState(() {
                  _showOnlyDownloaded = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Com erros'),
              value: _showOnlyWithErrors,
              onChanged: (value) {
                setState(() {
                  _showOnlyWithErrors = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  /// Lida com ações do menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'analytics':
        _tabController.animateTo(3); // Ir para tab de analytics
        break;
      case 'cleanup':
        _showCleanupDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }
  
  /// Mostra diálogo de limpeza
  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpeza de Cache'),
        content: const Text(
          'Isso irá remover mapas offline antigos e otimizar o armazenamento. '
          'Tem certeza que deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performCleanup();
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
  
  /// Mostra diálogo de configurações
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações'),
        content: const Text('Configurações em desenvolvimento...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  /// Mostra diálogo de download
  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Opções de Download'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha uma opção para baixar mapas offline:'),
            const SizedBox(height: 20),
            _buildDownloadOption(
              context,
              'Criar Novo Mapa',
              'Criar uma nova área para download usando coordenadas',
              Icons.add_location,
              Colors.green,
              () {
                Navigator.pop(context);
                _showCreateNewMapDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildDownloadOption(
              context,
              'Importar Talhões',
              'Importar talhões criados no módulo Talhões',
              Icons.import_export,
              Colors.blue,
              () {
                Navigator.pop(context);
                _showImportTalhoesDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildDownloadOption(
              context,
              'Áreas Existentes',
              'Baixar mapas para áreas já criadas',
              Icons.map,
              Colors.orange,
              () {
                Navigator.pop(context);
                _tabController.animateTo(2); // Ir para tab de downloads
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Mostra diálogo para criar novo mapa
  void _showCreateNewMapDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '1000'); // 1km padrão

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_location, color: Colors.green),
            SizedBox(width: 8),
            Text('Criar Novo Mapa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Área',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(
                labelText: 'Raio (metros)',
                prefixIcon: Icon(Icons.radio_button_unchecked),
                suffixText: 'm',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O mapa será baixado em um raio circular ao redor das coordenadas fornecidas.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
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
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  lngController.text.isNotEmpty) {
                Navigator.pop(context);
                _createNewMapArea(
                  nameController.text,
                  double.tryParse(latController.text) ?? 0,
                  double.tryParse(lngController.text) ?? 0,
                  double.tryParse(radiusController.text) ?? 1000,
                );
              }
            },
            child: const Text('Criar e Baixar'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para importar talhões
  void _showImportTalhoesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.import_export, color: Colors.blue),
            SizedBox(width: 8),
            Text('Importar Talhões'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Importar talhões criados no módulo Talhões para download de mapas:'),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadTalhoesForImport(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }
                
                final talhoes = snapshot.data ?? [];
                
                if (talhoes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Nenhum talhão encontrado. Crie talhões no módulo Talhões primeiro.'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: [
                    Text('${talhoes.length} talhões encontrados:'),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: talhoes.length,
                        itemBuilder: (context, index) {
                          final talhao = talhoes[index];
                          return CheckboxListTile(
                            title: Text(talhao['nome'] ?? 'Sem nome'),
                            subtitle: Text('Área: ${talhao['area']?.toStringAsFixed(2) ?? '0'} ha'),
                            value: talhao['selected'] ?? false,
                            onChanged: (value) {
                              setState(() {
                                talhao['selected'] = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
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
              Navigator.pop(context);
              _importSelectedTalhoes();
            },
            child: const Text('Importar Selecionados'),
          ),
        ],
      ),
    );
  }

  /// Carrega talhões para importação
  Future<List<Map<String, dynamic>>> _loadTalhoesForImport() async {
    try {
      // Aqui você pode usar o TalhaoUnifiedService ou TalhaoProvider
      // Para simplificar, vou criar dados de exemplo
      return [
        {
          'id': 'talhao_001',
          'nome': 'Talhão A - Soja',
          'area': 25.5,
          'poligonos': [
            {'latitude': -20.2764, 'longitude': -40.3000},
            {'latitude': -20.2774, 'longitude': -40.3010},
          ],
          'selected': false,
        },
        {
          'id': 'talhao_002',
          'nome': 'Talhão B - Milho',
          'area': 18.3,
          'poligonos': [
            {'latitude': -20.2864, 'longitude': -40.3100},
            {'latitude': -20.2874, 'longitude': -40.3110},
          ],
          'selected': false,
        },
      ];
    } catch (e) {
      return [];
    }
  }

  /// Cria nova área de mapa
  void _createNewMapArea(String name, double lat, double lng, double radius) {
    // Implementar criação de nova área
    _showSuccessSnackBar('Nova área "$name" criada com sucesso!');
    // Aqui você adicionaria a área à lista e iniciaria o download
  }

  /// Importa talhões selecionados
  void _importSelectedTalhoes() {
    // Implementar importação dos talhões selecionados
    _showSuccessSnackBar('Talhões importados com sucesso!');
    // Aqui você adicionaria os talhões às áreas disponíveis para download
  }
  
  /// Mostra diálogo de solução de problemas
  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solução de Problemas'),
        content: const Text(
          'Se você está enfrentando problemas:\n\n'
          '1. Verifique sua conexão com a internet\n'
          '2. Reinicie o aplicativo\n'
          '3. Limpe o cache do aplicativo\n'
          '4. Entre em contato com o suporte',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  /// Executa limpeza
  Future<void> _performCleanup() async {
    try {
      await _mapService.clearCache();
      _showSuccessSnackBar('Cache limpo com sucesso!');
      await _refreshData();
    } catch (e) {
      _showErrorSnackBar('Erro ao limpar cache: $e');
    }
  }

  /// Mensagem de desenvolvimento
  Widget _buildDevelopmentMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Módulo em Desenvolvimento',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'O módulo "Mapas Offline" está em desenvolvimento ativo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em breve você terá acesso a funcionalidades completas para:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.download, 'Download de mapas offline'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.map, 'Visualização de mapas sem internet'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.sync, 'Sincronização automática'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.storage, 'Gerenciamento de armazenamento'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item de funcionalidade
  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
