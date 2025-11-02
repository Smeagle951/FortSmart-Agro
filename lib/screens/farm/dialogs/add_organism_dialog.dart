import 'package:flutter/material.dart';
import '../../../models/new_culture_model.dart';

/// Diálogo para adicionar novo organismo (praga, doença ou planta daninha)
class AddOrganismDialog extends StatefulWidget {
  final NewCulture culture;
  final String? category;
  final VoidCallback onOrganismAdded;

  const AddOrganismDialog({
    super.key,
    required this.culture,
    this.category,
    required this.onOrganismAdded,
  });

  @override
  State<AddOrganismDialog> createState() => _AddOrganismDialogState();
}

class _AddOrganismDialogState extends State<AddOrganismDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _economicDamageController = TextEditingController();
  final _lifeCycleController = TextEditingController();
  final _growthHabitController = TextEditingController();
  final _maxHeightController = TextEditingController();
  final _leafTypeController = TextEditingController();
  final _leafColorController = TextEditingController();
  final _rootTypeController = TextEditingController();
  final _reproductionController = TextEditingController();
  final _dispersalController = TextEditingController();

  String _selectedCategory = '';
  final List<String> _symptoms = [];
  final List<String> _affectedParts = [];
  final List<String> _phenology = [];
  final Map<String, String> _favorableConditions = {};
  final Map<String, String> _specificThresholds = {};

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category ?? 'Praga';
    // Garantir que o valor inicial está na lista de opções
    if (!['Praga', 'Doença', 'Planta Daninha'].contains(_selectedCategory)) {
      _selectedCategory = 'Praga';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _economicDamageController.dispose();
    _lifeCycleController.dispose();
    _growthHabitController.dispose();
    _maxHeightController.dispose();
    _leafTypeController.dispose();
    _leafColorController.dispose();
    _rootTypeController.dispose();
    _reproductionController.dispose();
    _dispersalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(
                    'Adicionar $_selectedCategory',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            
            // Formulário
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoria
                      DropdownButtonFormField<String>(
                        value: _selectedCategory.isEmpty ? 'Praga' : _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Praga', child: Text('Praga')),
                          DropdownMenuItem(value: 'Doença', child: Text('Doença')),
                          DropdownMenuItem(value: 'Planta Daninha', child: Text('Planta Daninha')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nome
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nome científico
                      TextFormField(
                        controller: _scientificNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Científico *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome científico é obrigatório';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Dano econômico
                      TextFormField(
                        controller: _economicDamageController,
                        decoration: const InputDecoration(
                          labelText: 'Dano Econômico',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Informações específicas para plantas daninhas
                      if (_selectedCategory == 'Planta Daninha') ...[
                        Text(
                          'Informações da Planta Daninha',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        
                        TextFormField(
                          controller: _lifeCycleController,
                          decoration: const InputDecoration(
                            labelText: 'Ciclo de Vida',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _growthHabitController,
                          decoration: const InputDecoration(
                            labelText: 'Hábito de Crescimento',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _maxHeightController,
                          decoration: const InputDecoration(
                            labelText: 'Altura Máxima',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _leafTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Folha',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _leafColorController,
                          decoration: const InputDecoration(
                            labelText: 'Cor da Folha',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _rootTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Raiz',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _reproductionController,
                          decoration: const InputDecoration(
                            labelText: 'Reprodução',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _dispersalController,
                          decoration: const InputDecoration(
                            labelText: 'Dispersão',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const Divider(),
            
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveOrganism,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.culture.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveOrganism() {
    if (_formKey.currentState!.validate()) {
      final organism = Organism(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        scientificName: _scientificNameController.text,
        category: _selectedCategory,
        description: _descriptionController.text,
        economicDamage: _economicDamageController.text,
        lifeCycle: _lifeCycleController.text,
        growthHabit: _growthHabitController.text,
        maxHeight: _maxHeightController.text,
        leafType: _leafTypeController.text,
        leafColor: _leafColorController.text,
        rootType: _rootTypeController.text,
        reproduction: _reproductionController.text,
        dispersal: _dispersalController.text,
        symptoms: _symptoms,
        affectedParts: _affectedParts,
        phenology: _phenology,
        favorableConditions: _favorableConditions,
        specificThresholds: _specificThresholds,
      );

      // Aqui você adicionaria o organismo à cultura
      // Por enquanto, apenas fechamos o diálogo
      Navigator.pop(context);
      widget.onOrganismAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedCategory adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
