import 'package:flutter/material.dart';
import '../../models/organism_catalog.dart';
import '../../services/organism_v3_integration_service.dart';
import '../../repositories/organism_catalog_repository.dart';
import '../../services/complete_integration_service.dart';
import '../../utils/enums.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../organism_detail_screen.dart';
import '../organism_form_screen.dart';

/// Tela aprimorada do catálogo de organismos com integração completa
/// Inclui funcionalidades de conectividade com módulos de Monitoramento e Mapa de Infestação
class OrganismCatalogEnhancedScreen extends StatefulWidget {
  const OrganismCatalogEnhancedScreen({Key? key}) : super(key: key);

  @override
  State<OrganismCatalogEnhancedScreen> createState() => _OrganismCatalogEnhancedScreenState();
}

class _OrganismCatalogEnhancedScreenState extends State<OrganismCatalogEnhancedScreen>
    with TickerProviderStateMixin {
  final OrganismCatalogRepository _repository = OrganismCatalogRepository();
  final CompleteIntegrationService _integrationService = CompleteIntegrationService();
  final OrganismV3IntegrationService _v3Service = OrganismV3IntegrationService();
  
  List<OrganismCatalog> _organisms = [];
  List<OrganismCatalog> _filteredOrganisms = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, bool> _hasV3Data = {}; // Cache de organismos com v3.0
  
  // Dados de integração
  Map<String, dynamic> _organismStatistics = {};
  List<Map<String, dynamic>> _problematicOrganisms = [];
  Map<String, dynamic> _trendsByCrop = {};
  bool _showIntegrationData = false;
  
  // Filtros
  OccurrenceType _selectedType = OccurrenceType.pest;
  String _selectedCrop = 'Todas';
  String _searchQuery = '';
  
  // Controladores para o formulário
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowLimitController = TextEditingController();
  final _mediumLimitController = TextEditingController();
  final _highLimitController = TextEditingController();
  final _unitController = TextEditingController();
  
  OccurrenceType _formType = OccurrenceType.pest;
  String _formCropId = 'soja';
  String _formCropName = 'Soja';

  // Controllers para tabs
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _lowLimitController.dispose();
    _mediumLimitController.dispose();
    _highLimitController.dispose();
    _unitController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Inicializa os serviços
  Future<void> _initializeServices() async {
    try {
      await _integrationService.initialize();
      await _loadOrganisms();
      await _loadIntegrationData();
    } catch (e) {
      Logger.error('❌ Erro ao inicializar serviços: $e');
      _showErrorMessage('Erro ao inicializar serviços: $e');
    }
  }

  /// Carrega os organismos do banco de dados
  Future<void> _loadOrganisms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.initialize();
      
      if (await _repository.isEmpty()) {
        await _repository.insertDefaultData();
      }
      
      final organisms = await _repository.getAll();
      
      setState(() {
        _organisms = organisms;
        _filteredOrganisms = organisms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Erro ao carregar organismos: $e');
    }
  }

  /// Carrega dados de integração
  Future<void> _loadIntegrationData() async {
    try {
      final statistics = await _integrationService.getOrganismStatistics();
      final problematic = await _integrationService.getMostProblematicOrganisms();
      final trends = await _integrationService.getTrendsByCrop();
      
      setState(() {
        _organismStatistics = statistics;
        _problematicOrganisms = problematic;
        _trendsByCrop = trends;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de integração: $e');
    }
  }

  /// Aplica filtros na lista de organismos
  void _applyFilters() {
    setState(() {
      _filteredOrganisms = _organisms.where((organism) {
        if (organism.type != _selectedType) return false;
        if (_selectedCrop != 'Todas' && organism.cropName != _selectedCrop) return false;
        
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return organism.name.toLowerCase().contains(query) ||
                 organism.scientificName.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Organismos - Integrado'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Catálogo'),
            Tab(icon: Icon(Icons.analytics), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.warning), text: 'Alertas'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showIntegrationData ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showIntegrationData = !_showIntegrationData;
              });
            },
            tooltip: _showIntegrationData ? 'Ocultar dados de integração' : 'Mostrar dados de integração',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIntegrationData,
            tooltip: 'Atualizar dados de integração',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCatalogTab(),
          _buildStatisticsTab(),
          _buildAlertsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrganismForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Constrói a aba do catálogo
  Widget _buildCatalogTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _filteredOrganisms.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum organismo encontrado',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredOrganisms.length,
                  itemBuilder: (context, index) {
                    final organism = _filteredOrganisms[index];
                    return _buildOrganismCard(organism);
                  },
                ),
        ),
      ],
    );
  }

  /// Constrói a aba de estatísticas
  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCard(),
          const SizedBox(height: 16),
          _buildTrendsCard(),
          const SizedBox(height: 16),
          _buildOrganismsStatisticsCard(),
        ],
      ),
    );
  }

  /// Constrói a aba de alertas
  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProblematicOrganismsCard(),
          const SizedBox(height: 16),
          _buildIntegrationStatusCard(),
        ],
      ),
    );
  }

  /// Constrói os filtros
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<OccurrenceType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: OccurrenceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCrop,
                  decoration: const InputDecoration(
                    labelText: 'Cultura',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Todas', 'Soja', 'Milho', 'Algodão', 'Feijão', 'Trigo', 'Girassol', 'Sorgo', 'Gergelim']
                      .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCrop = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar organismo',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  /// Verifica se organismo tem dados v3.0 (com cache)
  Future<void> _checkV3Data(OrganismCatalog organism) async {
    if (!_hasV3Data.containsKey(organism.id)) {
      final v3Org = await _v3Service.findOrganism(
        nomeOrganismo: organism.name,
        cultura: organism.cropName,
      );
      _hasV3Data[organism.id] = v3Org != null;
    }
  }

  /// Constrói card de organismo
  Widget _buildOrganismCard(OrganismCatalog organism) {
    final statistics = _organismStatistics;
    
    // Verificar v3.0 em background
    _checkV3Data(organism).then((_) {
      if (mounted) setState(() {});
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(organism.type),
          child: Text(
            _getTypeIcon(organism.type),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        title: Text(
          organism.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(organism.scientificName),
            Text('Cultura: ${organism.cropName}'),
            if (_showIntegrationData && statistics.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ocorrências: ${statistics['total_ocorrencias'] ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge v3.0
            if (_hasV3Data[organism.id] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.stars, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'v3.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (_hasV3Data[organism.id] == true) const SizedBox(width: 8),
            if (_showIntegrationData && statistics.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(statistics['nivel_mais_comum'] ?? 'BAIXO'),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statistics['nivel_mais_comum'] ?? 'BAIXO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_showIntegrationData && statistics.isNotEmpty) const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showOrganismForm(organism);
                    break;
                  case 'delete':
                    _deleteOrganism(organism);
                    break;
                  case 'view_stats':
                    _showOrganismStatistics(organism);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_stats',
                  child: ListTile(
                    leading: Icon(Icons.analytics),
                    title: Text('Ver Estatísticas'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Excluir', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showOrganismForm(organism),
      ),
    );
  }

  /// Constrói card de estatísticas gerais
  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas Gerais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total de Organismos',
                    _organisms.length.toString(),
                    Icons.bug_report,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Com Dados de Campo',
                    _organismStatistics['totalOrganisms']?.toString() ?? '0',
                    Icons.analytics,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Organismos Problemáticos',
                    _problematicOrganisms.length.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Culturas Monitoradas',
                    (_trendsByCrop['total_culturas'] ?? 0).toString(),
                    Icons.agriculture,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item de estatística
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói card de tendências
  Widget _buildTrendsCard() {
    final trends = _trendsByCrop['tendencias_por_cultura'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendências por Cultura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (trends.isEmpty)
              const Text('Nenhuma tendência disponível')
            else
              ...trends.map((trend) => _buildTrendItem(trend)).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói item de tendência
  Widget _buildTrendItem(Map<String, dynamic> trend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              trend['cultura_nome'] ?? 'Cultura Desconhecida',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${trend['total_organismos']} organismos'),
              Text('Média: ${(trend['media_geral_infestacao'] ?? 0).toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de estatísticas de organismos
  Widget _buildOrganismsStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organismos com Dados de Campo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_organismStatistics.isEmpty)
              const Text('Nenhum dado de campo disponível')
            else
              _buildOrganismStatItem(_organismStatistics),
          ],
        ),
      ),
    );
  }

  /// Constrói item de estatística de organismo
  Widget _buildOrganismStatItem(Map<String, dynamic> stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['organismo_nome'] ?? 'Organismo Desconhecido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Cultura: ${stat['cultura_nome'] ?? 'N/A'}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stat['total_ocorrencias']} ocorrências'),
              Text('Média: ${(stat['media_infestacao'] ?? 0).toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de organismos problemáticos
  Widget _buildProblematicOrganismsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organismos Mais Problemáticos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_problematicOrganisms.isEmpty)
              const Text('Nenhum organismo problemático identificado')
            else
              ..._problematicOrganisms.map((organism) => _buildProblematicOrganismItem(organism)).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói item de organismo problemático
  Widget _buildProblematicOrganismItem(Map<String, dynamic> organism) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getLevelColor(organism['nivel_mais_comum'] ?? 'BAIXO').withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getLevelColor(organism['nivel_mais_comum'] ?? 'BAIXO').withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organism['organismo_nome'] ?? 'Organismo Desconhecido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Cultura: ${organism['cultura_nome'] ?? 'N/A'}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(organism['nivel_mais_comum'] ?? 'BAIXO'),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  organism['nivel_mais_comum'] ?? 'BAIXO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${organism['total_ocorrencias']} ocorrências'),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de status de integração
  Widget _buildIntegrationStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status da Integração',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIntegrationStatusItem(
                    'Monitoramento',
                    'Conectado',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildIntegrationStatusItem(
                    'Mapa de Infestação',
                    'Conectado',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIntegrationStatusItem(
                    'Catálogo',
                    'Atualizado',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildIntegrationStatusItem(
                    'Alertas',
                    'Ativo',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item de status de integração
  Widget _buildIntegrationStatusItem(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Mostra formulário de organismo
  void _showOrganismForm([OrganismCatalog? organism]) {
    if (organism != null) {
      // Navegar para detalhes do organismo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrganismDetailScreen(organism: organism),
        ),
      );
    } else {
      // Navegar para formulário de novo organismo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrganismFormScreen(),
        ),
      );
    }
  }

  /// Mostra estatísticas de organismo
  void _showOrganismStatistics(OrganismCatalog organism) {
    // Implementar visualização de estatísticas
    _showInfoMessage('Estatísticas de ${organism.name} serão implementadas');
  }

  /// Exclui organismo
  void _deleteOrganism(OrganismCatalog organism) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o organismo "${organism.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.delete(organism.id);
              _loadOrganisms();
              _showSuccessMessage('Organismo excluído com sucesso');
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Obtém nome de exibição do tipo
  String _getTypeDisplayName(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      case OccurrenceType.deficiency:
        return 'Deficiência';
      case OccurrenceType.other:
        return 'Outro';
    }
  }

  /// Obtém cor do tipo
  Color _getTypeColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Colors.red;
      case OccurrenceType.disease:
        return Colors.orange;
      case OccurrenceType.weed:
        return Colors.green;
      case OccurrenceType.deficiency:
        return Colors.blue;
      case OccurrenceType.other:
        return Colors.grey;
    }
  }

  /// Obtém ícone do tipo
  String _getTypeIcon(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return '🐛';
      case OccurrenceType.disease:
        return '🍄';
      case OccurrenceType.weed:
        return '🌱';
      case OccurrenceType.deficiency:
        return '⚠️';
      case OccurrenceType.other:
        return '❓';
    }
  }

  /// Obtém cor do nível
  Color _getLevelColor(String level) {
    switch (level) {
      case 'BAIXO':
        return Colors.green;
      case 'MODERADO':
        return Colors.yellow;
      case 'ALTO':
        return Colors.orange;
      case 'CRITICO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Mostra mensagem de erro
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra mensagem de sucesso
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Mostra mensagem informativa
  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
