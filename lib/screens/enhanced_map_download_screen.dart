import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../services/enhanced_offline_map_service.dart';
import '../services/map_modules_integration_service.dart';
import '../widgets/enhanced_map_download_widget.dart';
import '../widgets/offline_map_preview_widget.dart';
import '../widgets/storage_usage_widget.dart';
import '../widgets/connectivity_status_widget.dart';

/// Tela aprimorada para download de mapas offline
class EnhancedMapDownloadScreen extends StatefulWidget {
  const EnhancedMapDownloadScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedMapDownloadScreen> createState() => _EnhancedMapDownloadScreenState();
}

class _EnhancedMapDownloadScreenState extends State<EnhancedMapDownloadScreen>
    with TickerProviderStateMixin {
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  final MapModulesIntegrationService _integrationService = MapModulesIntegrationService();
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Estado da tela
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;
  
  // Dados
  List<Map<String, dynamic>> _availableAreas = [];
  List<Map<String, dynamic>> _downloadQueue = [];
  List<Map<String, dynamic>> _downloadHistory = [];
  Map<String, dynamic> _storageStats = {};
  
  // Configurações de download
  String _selectedMapType = 'satellite';
  String _selectedZoomLevel = '13-18';
  bool _downloadOnlyWifi = true;
  bool _autoDownload = false;
  
  // Filtros
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _showOnlyTalhoes = false;
  bool _showOnlyMonitoring = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
  
  /// Inicializa serviços
  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await Future.wait([
        _mapService.initialize(),
        _integrationService.initialize(),
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
  
  /// Carrega todos os dados
  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        Future.value(_integrationService.getAvailableAreas()),
        Future.value(_mapService.getDownloadQueue()),
        Future.value(_mapService.getDownloadHistory()),
        Future.value(_mapService.getStorageStats()),
      ]);
      
      setState(() {
        _availableAreas = results[0] as List<Map<String, dynamic>>;
        _downloadQueue = results[1] as List<Map<String, dynamic>>;
        _downloadHistory = results[2] as List<Map<String, dynamic>>;
        _storageStats = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
      _showErrorSnackBar(_errorMessage!);
    }
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
        'Download de Mapas - DEV',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        // Botão de configurações
        IconButton(
          onPressed: _showSettingsDialog,
          icon: const Icon(Icons.settings),
          tooltip: 'Configurações',
        ),
        // Botão de filtros
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtros',
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
            Tab(icon: Icon(Icons.list), text: 'Disponíveis'),
            Tab(icon: Icon(Icons.queue), text: 'Fila'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Carregando áreas disponíveis...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
              'Erro ao carregar dados',
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
            ElevatedButton.icon(
              onPressed: _initializeServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
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
        _buildAvailableTab(),
        _buildQueueTab(),
        _buildHistoryTab(),
      ],
    );
  }
  
  /// Tab de áreas disponíveis
  Widget _buildAvailableTab() {
    final filteredAreas = _filterAreas(_availableAreas);
    
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros e busca
            _buildSearchAndFilters(),
            
            const SizedBox(height: 16),
            
            // Estatísticas rápidas
            _buildQuickStats(),
            
            const SizedBox(height: 16),
            
            // Lista de áreas
            if (filteredAreas.isEmpty)
              _buildEmptyState()
            else
              ...filteredAreas.map((area) => _buildAreaCard(area)),
          ],
        ),
      ),
    );
  }
  
  /// Tab de fila de download
  Widget _buildQueueTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status da fila
            _buildQueueStatus(),
            
            const SizedBox(height: 16),
            
            // Lista da fila
            if (_downloadQueue.isEmpty)
              _buildEmptyQueueState()
            else
              ..._downloadQueue.map((item) => _buildQueueItem(item)),
          ],
        ),
      ),
    );
  }
  
  /// Tab de histórico
  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estatísticas do histórico
            _buildHistoryStats(),
            
            const SizedBox(height: 16),
            
            // Lista do histórico
            if (_downloadHistory.isEmpty)
              _buildEmptyHistoryState()
            else
              ..._downloadHistory.map((item) => _buildHistoryItem(item)),
          ],
        ),
      ),
    );
  }
  
  /// Busca e filtros
  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de busca
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar áreas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            // Filtros rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Talhões'),
                  selected: _showOnlyTalhoes,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyTalhoes = selected;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Monitoramento'),
                  selected: _showOnlyMonitoring,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyMonitoring = selected;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Estatísticas rápidas
  Widget _buildQuickStats() {
    final totalAreas = _availableAreas.length;
    final downloadedAreas = _availableAreas.where((a) => a['downloaded'] == true).length;
    final pendingAreas = _availableAreas.where((a) => a['downloaded'] == false).length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('Total', totalAreas, Colors.blue),
            ),
            Expanded(
              child: _buildStatItem('Baixados', downloadedAreas, Colors.green),
            ),
            Expanded(
              child: _buildStatItem('Pendentes', pendingAreas, Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Item de estatística
  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
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
  
  /// Estado vazio
  Widget _buildEmptyState() {
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
              'Nenhuma área encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie talhões ou áreas de monitoramento para ver opções de download',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Card de área
  Widget _buildAreaCard(Map<String, dynamic> area) {
    final isDownloaded = area['downloaded'] == true;
    final hasError = area['error'] != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
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
                        'Tipo: ${area['type']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isDownloaded, hasError),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações da área
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Área: ${area['area']?.toStringAsFixed(2) ?? 'N/A'} hectares',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.zoom_in, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Zoom: ${_selectedZoomLevel}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            
            if (area['lastUpdate'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.update, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Última atualização: ${area['lastUpdate']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAreaDetails(area),
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
                    onPressed: () => _handleAreaAction(area),
                    icon: Icon(_getActionIcon(area), size: 16),
                    label: Text(_getActionLabel(area)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getActionColor(area),
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
  Widget _buildStatusChip(bool isDownloaded, bool hasError) {
    Color color;
    String label;
    IconData icon;
    
    if (hasError) {
      color = Colors.red;
      label = 'Erro';
      icon = Icons.error;
    } else if (isDownloaded) {
      color = Colors.green;
      label = 'Baixado';
      icon = Icons.check_circle;
    } else {
      color = Colors.orange;
      label = 'Pendente';
      icon = Icons.cloud_download;
    }
    
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
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
  
  /// Status da fila
  Widget _buildQueueStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.queue, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Status da Fila',
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
                  child: _buildStatItem('Na Fila', _downloadQueue.length, Colors.blue),
                ),
                Expanded(
                  child: _buildStatItem('Baixando', _isDownloading ? 1 : 0, Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('Pausados', 0, Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Estado vazio da fila
  Widget _buildEmptyQueueState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.queue_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Fila vazia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhum download na fila',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Item da fila
  Widget _buildQueueItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Icon(Icons.download, color: Colors.blue, size: 20),
        ),
        title: Text(
          item['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${item['status']}'),
            if (item['progress'] != null)
              LinearProgressIndicator(
                value: item['progress'],
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _pauseDownload(item['id']),
              icon: const Icon(Icons.pause),
              tooltip: 'Pausar',
            ),
            IconButton(
              onPressed: () => _removeFromQueue(item['id']),
              icon: const Icon(Icons.cancel),
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }
  
  /// Estatísticas do histórico
  Widget _buildHistoryStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total', _downloadHistory.length, Colors.blue),
                ),
                Expanded(
                  child: _buildStatItem('Sucessos', 
                    _downloadHistory.where((h) => h['success'] == true).length, 
                    Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('Falhas', 
                    _downloadHistory.where((h) => h['success'] == false).length, 
                    Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Estado vazio do histórico
  Widget _buildEmptyHistoryState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum download no histórico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os downloads aparecerão aqui após serem concluídos',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Item do histórico
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final isSuccess = item['success'] == true;
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          item['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${isSuccess ? 'Sucesso' : 'Falha'}'),
            Text('Data: ${item['date']}'),
            if (item['size'] != null)
              Text('Tamanho: ${item['size']}'),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showHistoryDetails(item),
          icon: const Icon(Icons.info_outline),
          tooltip: 'Detalhes',
        ),
      ),
    );
  }
  
  /// Botão flutuante
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showBulkDownloadDialog,
      icon: const Icon(Icons.download),
      label: const Text('Download em Lote'),
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
    );
  }
  
  /// Filtra áreas
  List<Map<String, dynamic>> _filterAreas(List<Map<String, dynamic>> areas) {
    return areas.where((area) {
      // Filtro de busca
      if (_searchQuery.isNotEmpty) {
        if (!area['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Filtro de tipo
      if (_showOnlyTalhoes && area['type'] != 'talhao') return false;
      if (_showOnlyMonitoring && area['type'] != 'monitoring') return false;
      
      return true;
    }).toList();
  }
  
  /// Lida com ação da área
  void _handleAreaAction(Map<String, dynamic> area) {
    if (area['downloaded'] == true) {
      _updateArea(area);
    } else {
      _downloadArea(area);
    }
  }
  
  /// Baixa área
  Future<void> _downloadArea(Map<String, dynamic> area) async {
    try {
      await _mapService.addToDownloadQueue(area['id'], {
        'mapType': _selectedMapType,
        'zoomLevel': _selectedZoomLevel,
        'wifiOnly': _downloadOnlyWifi,
      });
      
      _showSuccessSnackBar('Área adicionada à fila de download');
      await _loadAllData();
    } catch (e) {
      _showErrorSnackBar('Erro ao adicionar à fila: $e');
    }
  }
  
  /// Atualiza área
  Future<void> _updateArea(Map<String, dynamic> area) async {
    try {
      await _mapService.updateArea(area['id']);
      _showSuccessSnackBar('Área atualizada com sucesso');
      await _loadAllData();
    } catch (e) {
      _showErrorSnackBar('Erro ao atualizar área: $e');
    }
  }
  
  /// Pausa download
  void _pauseDownload(String id) {
    // Implementar pausa
  }
  
  /// Remove da fila
  void _removeFromQueue(String id) {
    // Implementar remoção
  }
  
  /// Mostra detalhes da área
  void _showAreaDetails(Map<String, dynamic> area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipo', area['type']),
            _buildDetailRow('Área', '${area['area']?.toStringAsFixed(2) ?? 'N/A'} hectares'),
            _buildDetailRow('Status', area['downloaded'] == true ? 'Baixado' : 'Pendente'),
            if (area['lastUpdate'] != null)
              _buildDetailRow('Última atualização', area['lastUpdate']),
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
  
  /// Linha de detalhe
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  /// Mostra detalhes do histórico
  void _showHistoryDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', item['success'] == true ? 'Sucesso' : 'Falha'),
            _buildDetailRow('Data', item['date']),
            if (item['size'] != null)
              _buildDetailRow('Tamanho', item['size']),
            if (item['error'] != null)
              _buildDetailRow('Erro', item['error']),
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
  
  /// Mostra diálogo de configurações
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações de Download'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tipo de Mapa'),
              subtitle: Text(_selectedMapType),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showMapTypeSelector(),
            ),
            ListTile(
              title: const Text('Nível de Zoom'),
              subtitle: Text(_selectedZoomLevel),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showZoomSelector(),
            ),
            SwitchListTile(
              title: const Text('Apenas Wi-Fi'),
              subtitle: const Text('Baixar apenas quando conectado ao Wi-Fi'),
              value: _downloadOnlyWifi,
              onChanged: (value) {
                setState(() {
                  _downloadOnlyWifi = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Download Automático'),
              subtitle: const Text('Baixar automaticamente novas áreas'),
              value: _autoDownload,
              onChanged: (value) {
                setState(() {
                  _autoDownload = value;
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
  
  /// Mostra seletor de tipo de mapa
  void _showMapTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tipo de Mapa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Satélite'),
              subtitle: const Text('Imagens de satélite'),
              value: 'satellite',
              groupValue: _selectedMapType,
              onChanged: (value) {
                setState(() {
                  _selectedMapType = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Híbrido'),
              subtitle: const Text('Satélite com ruas'),
              value: 'hybrid',
              groupValue: _selectedMapType,
              onChanged: (value) {
                setState(() {
                  _selectedMapType = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Ruas'),
              subtitle: const Text('Mapa de ruas'),
              value: 'streets',
              groupValue: _selectedMapType,
              onChanged: (value) {
                setState(() {
                  _selectedMapType = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Mostra seletor de zoom
  void _showZoomSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nível de Zoom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Econômico (12-16)'),
              subtitle: const Text('Menor qualidade, menos dados'),
              value: '12-16',
              groupValue: _selectedZoomLevel,
              onChanged: (value) {
                setState(() {
                  _selectedZoomLevel = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Padrão (13-18)'),
              subtitle: const Text('Boa qualidade, tamanho moderado'),
              value: '13-18',
              groupValue: _selectedZoomLevel,
              onChanged: (value) {
                setState(() {
                  _selectedZoomLevel = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Alta Qualidade (15-20)'),
              subtitle: const Text('Máxima qualidade, mais dados'),
              value: '15-20',
              groupValue: _selectedZoomLevel,
              onChanged: (value) {
                setState(() {
                  _selectedZoomLevel = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
              title: const Text('Apenas Talhões'),
              value: _showOnlyTalhoes,
              onChanged: (value) {
                setState(() {
                  _showOnlyTalhoes = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Apenas Monitoramento'),
              value: _showOnlyMonitoring,
              onChanged: (value) {
                setState(() {
                  _showOnlyMonitoring = value ?? false;
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
  
  /// Mostra diálogo de download em lote
  void _showBulkDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download em Lote'),
        content: const Text(
          'Selecionar múltiplas áreas para download simultâneo. '
          'Esta operação pode consumir bastante dados e espaço de armazenamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar download em lote
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
  
  /// Obtém ícone da ação
  IconData _getActionIcon(Map<String, dynamic> area) {
    if (area['downloaded'] == true) {
      return Icons.refresh;
    } else {
      return Icons.download;
    }
  }
  
  /// Obtém label da ação
  String _getActionLabel(Map<String, dynamic> area) {
    if (area['downloaded'] == true) {
      return 'Atualizar';
    } else {
      return 'Baixar';
    }
  }
  
  /// Obtém cor da ação
  Color _getActionColor(Map<String, dynamic> area) {
    if (area['downloaded'] == true) {
      return Colors.blue;
    } else {
      return Colors.green;
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
              'O módulo "Download de Mapas" está em desenvolvimento ativo.',
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
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.download, 'Download em lote de mapas'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.queue, 'Fila de downloads inteligente'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.settings, 'Configurações avançadas'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.history, 'Histórico detalhado de downloads'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
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
        Icon(icon, color: Colors.green[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
