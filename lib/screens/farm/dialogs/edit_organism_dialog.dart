import 'package:flutter/material.dart';
import '../../../models/new_culture_model.dart';

/// Diálogo para editar organismo existente
class EditOrganismDialog extends StatefulWidget {
  final Organism organism;
  final VoidCallback onOrganismUpdated;

  const EditOrganismDialog({
    super.key,
    required this.organism,
    required this.onOrganismUpdated,
  });

  @override
  State<EditOrganismDialog> createState() => _EditOrganismDialogState();
}

class _EditOrganismDialogState extends State<EditOrganismDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _scientificNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _economicDamageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organism.name);
    _scientificNameController = TextEditingController(text: widget.organism.scientificName);
    _descriptionController = TextEditingController(text: widget.organism.description);
    _economicDamageController = TextEditingController(text: widget.organism.economicDamage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _economicDamageController.dispose();
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
                Expanded(
                  child: Text(
                    'Editar ${widget.organism.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  onPressed: _saveChanges,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Aqui você salvaria as alterações do organismo
      Navigator.pop(context);
      widget.onOrganismUpdated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organismo atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
