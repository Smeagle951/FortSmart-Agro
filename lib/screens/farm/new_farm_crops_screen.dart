import 'package:flutter/material.dart';
import '../../models/new_culture_model.dart';
import '../../services/new_culture_service.dart';
import 'culture_details_screen.dart';
import 'dialogs/add_culture_dialog.dart';

/// Novo módulo de culturas da fazenda
/// Com as 12 culturas completas e funcionalidades avançadas
class NewFarmCropsScreen extends StatefulWidget {
  const NewFarmCropsScreen({super.key});

  @override
  State<NewFarmCropsScreen> createState() => _NewFarmCropsScreenState();
}

class _NewFarmCropsScreenState extends State<NewFarmCropsScreen> {
  final NewCultureService _cultureService = NewCultureService();
  
  bool _isLoading = true;
  List<NewCulture> _cultures = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCultures();
  }

  Future<void> _loadCultures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🌱 [NEW_FARM_CROPS] Carregando as 12 culturas...');
      final cultures = await _cultureService.loadAllCultures();
      
      print('📊 [NEW_FARM_CROPS] ${cultures.length} culturas retornadas');
      for (final culture in cultures) {
        print('  📋 ${culture.name}: ${culture.varieties.length} variedades, ${culture.weeds.length} plantas daninhas');
      }
      
      setState(() {
        _cultures = cultures;
        _isLoading = false;
      });
      
      print('✅ [NEW_FARM_CROPS] ${cultures.length} culturas carregadas com sucesso!');
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar culturas: $e';
        _isLoading = false;
      });
      print('❌ [NEW_FARM_CROPS] Erro ao carregar culturas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Culturas da Fazenda'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCultures,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCultureDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando culturas...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCultures,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_cultures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.agriculture,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma cultura encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione uma nova cultura para começar.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCultures,
              icon: const Icon(Icons.refresh),
              label: const Text('Carregar 12 Culturas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCultures,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _cultures.length,
        itemBuilder: (context, index) {
          final culture = _cultures[index];
          return _buildCultureCard(culture);
        },
      ),
    );
  }

  Widget _buildCultureCard(NewCulture culture) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCultureDetails(culture),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com cor da cultura
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: culture.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  culture.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Conteúdo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nome científico
                      Text(
                        culture.scientificName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Estatísticas
                      _buildStatRow(Icons.bug_report, 'Pragas', culture.pests.length, Colors.red),
                      _buildStatRow(Icons.health_and_safety, 'Doenças', culture.diseases.length, Colors.orange),
                      _buildStatRow(Icons.grass, 'Plantas Daninhas', culture.weeds.length, Colors.green),
                      _buildStatRow(Icons.eco, 'Variedades', culture.varieties.length, Colors.blue),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botões de ação
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _showCultureDetails(culture),
                    tooltip: 'Ver detalhes',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditCultureDialog(culture),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _showDeleteCultureDialog(culture),
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showCultureDetails(NewCulture culture) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CultureDetailsScreen(culture: culture),
      ),
    );
  }

  void _showAddCultureDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCultureDialog(
        onCultureAdded: () {
          _loadCultures();
        },
      ),
    );
  }

  void _showEditCultureDialog(NewCulture culture) {
    final nameController = TextEditingController(text: culture.name);
    final scientificNameController = TextEditingController(text: culture.scientificName);
    final descriptionController = TextEditingController(text: culture.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${culture.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Cultura',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scientificNameController,
              decoration: const InputDecoration(
                labelText: 'Nome Científico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  // Atualizar cultura
                  final updatedCulture = NewCulture(
                    id: culture.id,
                    name: nameController.text,
                    scientificName: scientificNameController.text,
                    description: descriptionController.text,
                    color: culture.color,
                    pests: culture.pests,
                    diseases: culture.diseases,
                    weeds: culture.weeds,
                    varieties: culture.varieties,
                  );
                  
                  await _cultureService.updateCulture(updatedCulture);
                  await _loadCultures();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${culture.name} atualizada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao atualizar cultura: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCultureDialog(NewCulture culture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${culture.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Tem certeza que deseja excluir a cultura "${culture.name}"?'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _cultureService.deleteCulture(culture.id);
                await _loadCultures();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${culture.name} excluída com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir cultura: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
}
