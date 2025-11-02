import 'package:flutter/material.dart';
import '../../../models/calda/calda_recipe.dart';
import '../../../models/calda/product.dart';
import '../../../models/calda/calda_config.dart';

class SaveRecipeDialog extends StatefulWidget {
  final List<Product> products;
  final CaldaConfig config;
  final Function(String name, String description) onSave;

  const SaveRecipeDialog({
    Key? key,
    required this.products,
    required this.config,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SaveRecipeDialog> createState() => _SaveRecipeDialogState();
}

class _SaveRecipeDialogState extends State<SaveRecipeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Salvar Receita'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Receita *',
                hintText: 'Ex: Calda Soja - Glifosato + 2,4-D',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o nome da receita';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Receita para dessecação pré-colheita',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Resumo da receita
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo da Receita:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Volume: ${widget.config.volumeLiters.toStringAsFixed(0)} L'),
                  Text('Vazão: ${widget.config.flowRate.toStringAsFixed(0)} ${widget.config.isFlowPerHectare ? 'L/ha' : 'L/alqueire'}'),
                  Text('Área: ${widget.config.area.toStringAsFixed(2)} ${widget.config.isFlowPerHectare ? 'ha' : 'alqueires'}'),
                  Text('Produtos: ${widget.products.length}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Produtos:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...widget.products.take(3).map((product) => 
                    Text('• ${product.name} (${product.dose} ${product.doseUnit.symbol})')
                  ).toList(),
                  if (widget.products.length > 3)
                    Text('... e mais ${widget.products.length - 3} produtos'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveRecipe,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _saveRecipe() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }
}
