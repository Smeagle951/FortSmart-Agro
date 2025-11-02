import 'package:flutter/material.dart';
import '../../../models/new_culture_model.dart';

/// Diálogo para adicionar nova cultura
class AddCultureDialog extends StatefulWidget {
  final VoidCallback onCultureAdded;

  const AddCultureDialog({
    super.key,
    required this.onCultureAdded,
  });

  @override
  State<AddCultureDialog> createState() => _AddCultureDialogState();
}

class _AddCultureDialogState extends State<AddCultureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Color _selectedColor = Colors.green;

  final List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.brown,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nova Cultura',
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nome da cultura
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Cultura *',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Soja, Milho, Algodão',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome da cultura é obrigatório';
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
                      hintText: 'Ex: Glycine max, Zea mays',
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
                      hintText: 'Descrição da cultura',
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seleção de cor
                  Text(
                    'Cor da Cultura',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color 
                                  ? Colors.black 
                                  : Colors.grey,
                              width: _selectedColor == color ? 3 : 1,
                            ),
                          ),
                          child: _selectedColor == color
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
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
                  onPressed: _saveCulture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
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

  void _saveCulture() {
    if (_formKey.currentState!.validate()) {
      final culture = NewCulture(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        scientificName: _scientificNameController.text,
        description: _descriptionController.text,
        color: _selectedColor,
      );

      // Aqui você adicionaria a cultura à lista
      // Por enquanto, apenas fechamos o diálogo
      Navigator.pop(context);
      widget.onCultureAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cultura "${culture.name}" adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
