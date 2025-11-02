import 'package:flutter/material.dart';
import '../../models/new_culture_model.dart';
import '../../models/crop_variety.dart';
import '../../repositories/crop_variety_repository.dart';
import '../../services/weed_data_service.dart';
import 'dialogs/add_organism_dialog.dart';
import 'dialogs/add_variety_dialog.dart';
import 'dialogs/edit_organism_dialog.dart';
import 'dialogs/edit_variety_dialog.dart';

/// Tela de detalhes completa da cultura
class CultureDetailsScreen extends StatefulWidget {
  final NewCulture culture;

  const CultureDetailsScreen({
    super.key,
    required this.culture,
  });

  @override
  State<CultureDetailsScreen> createState() => _CultureDetailsScreenState();
}

class _CultureDetailsScreenState extends State<CultureDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _varietyRepository = CropVarietyRepository();
  final _weedDataService = WeedDataService();
  List<CropVariety> _varieties = [];
  List<Organism> _weeds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVarieties();
    _loadWeeds();
  }

  Future<void> _loadVarieties() async {
    try {
      final varieties = await _varietyRepository.getByCropId(widget.culture.id);
      setState(() {
        _varieties = varieties;
      });
    } catch (e) {
      print('Erro ao carregar variedades: $e');
    }
  }

  Future<void> _loadWeeds() async {
    try {
      final weeds = await _weedDataService.loadWeedsForCrop(widget.culture.id);
      setState(() {
        _weeds = weeds;
      });
      print('✅ ${weeds.length} plantas daninhas carregadas para ${widget.culture.name}');
    } catch (e) {
      print('Erro ao carregar plantas daninhas: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.culture.name),
        backgroundColor: widget.culture.color,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Geral', icon: Icon(Icons.info)),
            Tab(text: 'Pragas', icon: Icon(Icons.bug_report)),
            Tab(text: 'Doenças', icon: Icon(Icons.health_and_safety)),
            Tab(text: 'Plantas Daninhas', icon: Icon(Icons.grass)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrganismDialog(),
            tooltip: 'Adicionar organismo',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildOrganismsTab(widget.culture.pests, 'Pragas'),
          _buildOrganismsTab(widget.culture.diseases, 'Doenças'),
          _buildOrganismsTab(_weeds, 'Plantas Daninhas'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('🔍 DEBUG: FloatingActionButton (ícone folha) pressionado!');
          _showAddVarietyDialog();
        },
        backgroundColor: widget.culture.color,
        child: const Icon(Icons.eco, color: Colors.white),
        tooltip: 'Adicionar variedade',
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informações básicas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações Básicas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nome Científico', widget.culture.scientificName),
                  _buildInfoRow('Descrição', widget.culture.description),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estatísticas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estatísticas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard('Pragas', widget.culture.pests.length, Colors.red, Icons.bug_report),
                  _buildStatCard('Doenças', widget.culture.diseases.length, Colors.orange, Icons.health_and_safety),
                  _buildStatCard('Plantas Daninhas', _weeds.length, Colors.green, Icons.grass),
                  _buildStatCard('Variedades', _varieties.length, Colors.blue, Icons.eco),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Variedades
          if (_varieties.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Variedades',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showAddVarietyDialog(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._varieties.map((variety) => 
                      _buildVarietyCard(variety)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganismsTab(List<Organism> organisms, String title) {
    return Column(
      children: [
        // Header com botão de adicionar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${organisms.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOrganismDialog(category: title),
                icon: const Icon(Icons.add),
                label: Text(
                  _getShortAddLabel(title),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.culture.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de organismos
        Expanded(
          child: organisms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(title),
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma $title encontrada',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione uma nova $title para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: organisms.length,
                  itemBuilder: (context, index) {
                    final organism = organisms[index];
                    return _buildOrganismCard(organism);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            child: Text(value.isEmpty ? 'Não informado' : value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarietyCard(CropVariety variety) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.eco, color: Colors.blue),
        title: Text(variety.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variety.description != null && variety.description!.isNotEmpty)
              Text(variety.description!),
            if (variety.company != null && variety.company!.isNotEmpty)
              Text('Empresa: ${variety.company!}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (variety.cycleDays != null)
              Text('Ciclo: ${variety.cycleDays} dias', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (variety.recommendedPopulation != null)
              Text('População: ${variety.recommendedPopulation!.toStringAsFixed(0)} plantas/ha', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Editar'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditVarietyDialog(variety);
            } else if (value == 'delete') {
              _showDeleteVarietyDialog(variety);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOrganismCard(Organism organism) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          _getCategoryIcon(organism.category),
          color: _getCategoryColor(organism.category),
        ),
        title: Text(organism.name),
        subtitle: Text(organism.scientificName),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (organism.description.isNotEmpty) ...[
                  _buildInfoRow('Descrição', organism.description),
                  const SizedBox(height: 8),
                ],
                if (organism.economicDamage.isNotEmpty) ...[
                  _buildInfoRow('Dano Econômico', organism.economicDamage),
                  const SizedBox(height: 8),
                ],
                if (organism.symptoms.isNotEmpty) ...[
                  _buildInfoRow('Sintomas', organism.symptoms.join(', ')),
                  const SizedBox(height: 8),
                ],
                if (organism.affectedParts.isNotEmpty) ...[
                  _buildInfoRow('Partes Afetadas', organism.affectedParts.join(', ')),
                  const SizedBox(height: 8),
                ],
                if (organism.lifeCycle.isNotEmpty) ...[
                  _buildInfoRow('Ciclo de Vida', organism.lifeCycle),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditOrganismDialog(organism),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showDeleteOrganismDialog(organism),
                      icon: const Icon(Icons.delete),
                      label: const Text('Excluir'),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'praga':
        return Icons.bug_report;
      case 'doença':
        return Icons.health_and_safety;
      case 'planta daninha':
        return Icons.grass;
      default:
        return Icons.eco;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'praga':
        return Colors.red;
      case 'doença':
        return Colors.orange;
      case 'planta daninha':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _showAddOrganismDialog({String? category}) {
    showDialog(
      context: context,
      builder: (context) => AddOrganismDialog(
        culture: widget.culture,
        category: category,
        onOrganismAdded: () {
          setState(() {});
        },
      ),
    );
  }

  void _showAddVarietyDialog() {
    print('🔍 DEBUG: _showAddVarietyDialog() chamado!');
    print('🔍 DEBUG: culture.id = ${widget.culture.id}');
    print('🔍 DEBUG: culture.name = ${widget.culture.name}');
    
    showDialog(
      context: context,
      builder: (context) {
        print('🔍 DEBUG: Criando AddVarietyDialog...');
        return AddVarietyDialog(
          culture: widget.culture,
          onVarietyAdded: () {
            print('✅ DEBUG: onVarietyAdded() chamado!');
            _loadVarieties();
          },
        );
      },
    );
  }

  void _showEditOrganismDialog(Organism organism) {
    showDialog(
      context: context,
      builder: (context) => EditOrganismDialog(
        organism: organism,
        onOrganismUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  void _showDeleteOrganismDialog(Organism organism) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${organism.name}'),
        content: const Text('Tem certeza que deseja excluir este organismo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar exclusão
              setState(() {});
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showEditVarietyDialog(CropVariety variety) {
    // Converter CropVariety para Variety
    final varietyForDialog = Variety(
      id: variety.id,
      name: variety.name,
      description: variety.description ?? '',
      cycleDays: variety.cycleDays,
      notes: variety.notes ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => EditVarietyDialog(
        variety: varietyForDialog,
        onVarietyUpdated: () {
          _loadVarieties();
        },
      ),
    );
  }

  void _showDeleteVarietyDialog(CropVariety variety) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${variety.name}'),
        content: const Text('Tem certeza que deseja excluir esta variedade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _varietyRepository.delete(variety.id);
                _loadVarieties();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Variedade "${variety.name}" excluída com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir variedade: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Retorna um label curto para o botão de adicionar
  String _getShortAddLabel(String title) {
    switch (title) {
      case 'Plantas Daninhas':
        return 'Adicionar';
      case 'Pragas':
        return 'Adicionar';
      case 'Doenças':
        return 'Adicionar';
      default:
        return 'Adicionar $title';
    }
  }
}
