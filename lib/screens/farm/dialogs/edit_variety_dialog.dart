import 'package:flutter/material.dart';
import '../../../models/new_culture_model.dart';
import '../../../models/crop_variety.dart';
import '../../../repositories/crop_variety_repository.dart';

/// Diálogo para editar variedade existente
class EditVarietyDialog extends StatefulWidget {
  final Variety variety;
  final VoidCallback onVarietyUpdated;

  const EditVarietyDialog({
    super.key,
    required this.variety,
    required this.onVarietyUpdated,
  });

  @override
  State<EditVarietyDialog> createState() => _EditVarietyDialogState();
}

class _EditVarietyDialogState extends State<EditVarietyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _cycleDaysController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.variety.name);
    _descriptionController = TextEditingController(text: widget.variety.description);
    _cycleDaysController = TextEditingController(text: widget.variety.cycleDays?.toString() ?? '');
    _notesController = TextEditingController(text: widget.variety.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cycleDaysController.dispose();
    _notesController.dispose();
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
                  'Editar ${widget.variety.name}',
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
                  // Nome da variedade
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Variedade *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome da variedade é obrigatório';
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
                  
                  // Ciclo em dias
                  TextFormField(
                    controller: _cycleDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Ciclo (dias)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final days = int.tryParse(value);
                        if (days == null || days <= 0) {
                          return 'Digite um número válido de dias';
                        }
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Observações
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
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

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final varietyRepository = CropVarietyRepository();
        
        // Buscar a variedade completa do banco para obter todos os campos
        final existingVariety = await varietyRepository.getById(widget.variety.id);
        
        if (existingVariety == null) {
          throw Exception('Variedade não encontrada no banco de dados');
        }
        
        // Criar variedade atualizada mantendo os campos existentes
        final updatedVariety = CropVariety(
          id: existingVariety.id,
          cropId: existingVariety.cropId,
          name: _nameController.text,
          company: existingVariety.company,
          cycleDays: _cycleDaysController.text.isNotEmpty 
              ? int.tryParse(_cycleDaysController.text) 
              : existingVariety.cycleDays,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          characteristics: existingVariety.characteristics,
          yieldValue: existingVariety.yieldValue,
          recommendedPopulation: existingVariety.recommendedPopulation,
          weightOf1000Seeds: existingVariety.weightOf1000Seeds,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: existingVariety.createdAt,
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        
        // Salvar no banco de dados
        await varietyRepository.update(updatedVariety);
        
        Navigator.pop(context);
        widget.onVarietyUpdated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Variedade atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar variedade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
