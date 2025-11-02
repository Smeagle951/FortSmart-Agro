import 'package:flutter/material.dart';
import '../models/ai_organism_data.dart';
import '../repositories/ai_organism_repository.dart';
import '../../../utils/logger.dart';
import '../../../screens/organism_form_screen.dart';
import '../../../models/organism_catalog.dart';
import '../../../repositories/organism_catalog_repository.dart';
import '../../../utils/enums.dart';

class OrganismCatalogScreen extends StatefulWidget {
  const OrganismCatalogScreen({super.key});

  @override
  State<OrganismCatalogScreen> createState() => _OrganismCatalogScreenState();
}

class _OrganismCatalogScreenState extends State<OrganismCatalogScreen> {
  final AIOrganismRepository _organismRepository = AIOrganismRepository();
  final OrganismCatalogRepository _catalogRepository = OrganismCatalogRepository();
  final TextEditingController _searchController = TextEditingController();

  List<AIOrganismData> _organisms = [];
  List<AIOrganismData> _filteredOrganisms = [];
  List<OrganismCatalog> _catalogOrganisms = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'pest', 'disease'
  String _selectedCrop = 'all';

  final List<String> _availableCrops = ['all', 'Soja', 'Milho', 'Algodão', 'Café', 'Cana-de-açúcar'];

  @override
  void initState() {
    super.initState();
    _loadOrganisms();
    _searchController.addListener(_filterOrganisms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganisms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carregar organismos do catálogo principal
      await _catalogRepository.initialize();
      final catalogOrganisms = await _catalogRepository.getAll();
      
      // Carregar organismos do repositório AI (fallback)
      final aiOrganisms = await _organismRepository.getAllOrganisms();
      
      setState(() {
        _catalogOrganisms = catalogOrganisms;
        _organisms = aiOrganisms;
        _filteredOrganisms = aiOrganisms;
        _isLoading = false;
      });
      
      Logger.info('✅ Carregados ${catalogOrganisms.length} organismos do catálogo e ${aiOrganisms.length} do AI');
    } catch (e) {
      Logger.error('Erro ao carregar organismos: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar organismos: $e';
        _isLoading = false;
      });
    }
  }

  void _filterOrganisms() {
    final searchQuery = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredOrganisms = _organisms.where((organism) {
        // Filtro por tipo
        if (_selectedFilter != 'all' && organism.type != _selectedFilter) {
          return false;
        }
        
        // Filtro por cultura
        if (_selectedCrop != 'all' && !organism.crops.contains(_selectedCrop)) {
          return false;
        }
        
        // Filtro por busca
        if (searchQuery.isNotEmpty) {
          return organism.name.toLowerCase().contains(searchQuery) ||
                 organism.scientificName.toLowerCase().contains(searchQuery) ||
                 organism.symptoms.any((symptom) => 
                     symptom.toLowerCase().contains(searchQuery)) ||
                 organism.keywords.any((keyword) => 
                     keyword.toLowerCase().contains(searchQuery));
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Catálogo de Organismos'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrganisms,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _errorMessage != null
                    ? _buildErrorMessage()
                    : _buildOrganismsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewOrganism,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar organismos, sintomas...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Filtros
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Tipo',
                  _selectedFilter,
                  {
                    'all': 'Todos',
                    'pest': 'Pragas',
                    'disease': 'Doenças',
                  },
                  (value) {
                    setState(() {
                      _selectedFilter = value;
                      _filterOrganisms();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Cultura',
                  _selectedCrop,
                  Map.fromEntries(
                    _availableCrops.map((crop) => MapEntry(
                      crop,
                      crop == 'all' ? 'Todas' : crop,
                    )),
                  ),
                  (value) {
                    setState(() {
                      _selectedCrop = value;
                      _filterOrganisms();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, Map<String, String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.entries.map((entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          )).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando organismos...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar organismos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrganisms,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganismsList() {
    if (_filteredOrganisms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum organismo encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou a busca',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrganisms.length,
      itemBuilder: (context, index) {
        final organism = _filteredOrganisms[index];
        return _buildOrganismCard(organism);
      },
    );
  }

  Widget _buildOrganismCard(AIOrganismData organism) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrganismDetails(organism),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: organism.type == 'pest' 
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      organism.type == 'pest' ? Icons.bug_report : Icons.medical_services,
                      color: organism.type == 'pest' ? Colors.orange : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organism.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          organism.scientificName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(organism.severity),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSeverityText(organism.severity),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showOrganismOptions(organism),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                organism.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: organism.crops.map((crop) => Chip(
                  label: Text(
                    crop,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.green[100],
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${organism.symptoms.length} sintomas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.science,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${organism.managementStrategies.length} estratégias',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Color _getSeverityColor(double severity) {
    if (severity >= 0.8) return Colors.red;
    if (severity >= 0.6) return Colors.orange;
    if (severity >= 0.4) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getSeverityText(double severity) {
    if (severity >= 0.8) return 'Muito Alto';
    if (severity >= 0.6) return 'Alto';
    if (severity >= 0.4) return 'Médio';
    return 'Baixo';
  }

  void _showOrganismDetails(AIOrganismData organism) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrganismDetailsSheet(organism),
    );
  }

  Widget _buildOrganismDetailsSheet(AIOrganismData organism) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: organism.type == 'pest' 
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          organism.type == 'pest' ? Icons.bug_report : Icons.medical_services,
                          color: organism.type == 'pest' ? Colors.orange : Colors.red,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organism.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              organism.scientificName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Descrição
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    organism.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Culturas afetadas
                  const Text(
                    'Culturas Afetadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: organism.crops.map((crop) => Chip(
                      label: Text(crop),
                      backgroundColor: Colors.green[100],
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Sintomas
                  const Text(
                    'Sintomas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...organism.symptoms.map((symptom) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            symptom,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  
                  // Estratégias de manejo
                  const Text(
                    'Estratégias de Manejo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...organism.managementStrategies.map((strategy) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            strategy,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  
                  // Informações adicionais
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Severidade',
                          _getSeverityText(organism.severity),
                          _getSeverityColor(organism.severity),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Tipo',
                          organism.type == 'pest' ? 'Praga' : 'Doença',
                          organism.type == 'pest' ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Adiciona novo organismo
  Future<void> _addNewOrganism() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const OrganismFormScreen(),
      ),
    );

    if (result == true) {
      _loadOrganisms();
    }
  }

  /// Edita organismo existente
  Future<void> _editOrganism(AIOrganismData organism) async {
    // Converter AIOrganismData para OrganismCatalog
    final catalogOrganism = OrganismCatalog(
      id: organism.id.toString(),
      name: organism.name,
      scientificName: organism.scientificName,
      type: organism.type == 'pest' ? OccurrenceType.pest : OccurrenceType.disease,
      cropId: organism.crops.isNotEmpty ? organism.crops.first.toLowerCase() : 'soja',
      cropName: organism.crops.isNotEmpty ? organism.crops.first : 'Soja',
      unit: 'unidade',
      lowLimit: 0,
      mediumLimit: 0,
      highLimit: 0,
      description: organism.description,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OrganismFormScreen(organism: catalogOrganism),
      ),
    );

    if (result == true) {
      _loadOrganisms();
    }
  }

  /// Mostra menu de opções para o organismo
  void _showOrganismOptions(AIOrganismData organism) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _editOrganism(organism);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text('Ver Detalhes'),
              onTap: () {
                Navigator.pop(context);
                _showOrganismDetails(organism);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteOrganism(organism);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirma exclusão do organismo
  void _confirmDeleteOrganism(AIOrganismData organism) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o organismo "${organism.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrganism(organism);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Exclui organismo
  Future<void> _deleteOrganism(AIOrganismData organism) async {
    try {
      // Aqui você implementaria a lógica de exclusão
      // Por enquanto, apenas mostra uma mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Organismo "${organism.name}" excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir organismo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
