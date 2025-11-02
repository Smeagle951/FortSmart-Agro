import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class ObservationsSection extends StatelessWidget {
  final TextEditingController technicalJustificationController;
  final bool deductFromStock;
  final Function(bool) onDeductFromStockChanged;
  
  const ObservationsSection({
    Key? key,
    required this.technicalJustificationController,
    required this.deductFromStock,
    required this.onDeductFromStockChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observações e Ajustes Técnicos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Justificativa técnica
            TextFormField(
              controller: technicalJustificationController,
              decoration: const InputDecoration(
                labelText: 'Observações / Justificativa Técnica',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Opção para deduzir do estoque
            SwitchListTile(
              title: const Text(
                'Deduzir produtos do estoque',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Ao salvar, os produtos serão deduzidos automaticamente do estoque',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
              value: deductFromStock,
              onChanged: onDeductFromStockChanged,
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            
            if (deductFromStock)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verifique se há estoque suficiente para todos os produtos antes de salvar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
