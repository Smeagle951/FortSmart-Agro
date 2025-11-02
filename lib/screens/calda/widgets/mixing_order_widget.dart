import 'package:flutter/material.dart';
import '../../../models/calda/product.dart';

class MixingOrderWidget extends StatelessWidget {
  final List<Product> products;
  final List<String> mixingOrder;
  final List<String> compatibilityWarnings;

  const MixingOrderWidget({
    Key? key,
    required this.products,
    required this.mixingOrder,
    required this.compatibilityWarnings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sort, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Ordem de Mistura Sugerida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de produtos na ordem de mistura
            ...mixingOrder.asMap().entries.map((entry) {
              int index = entry.key;
              String productName = entry.value;
              final product = products.firstWhere((p) => p.name == productName);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getFormulationColor(product.formulation.code),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.formulation.code} - ${product.manufacturer}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dose: ${product.dose} ${product.doseUnit.symbol}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getFormulationColor(product.formulation.code),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getFormulationCategory(product.formulation.code),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Legenda das categorias
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legenda da Ordem de Mistura:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Água (base)\n'
                    '2. Sólidos (WG, WP, SP, SG)\n'
                    '3. Líquidos Solúveis (SL, EC, SC)\n'
                    '4. Adjuvantes (AD, OD, EO, EW)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            
            // Avisos de compatibilidade
            if (compatibilityWarnings.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Avisos de Compatibilidade',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ...compatibilityWarnings.map((warning) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getFormulationColor(String formulation) {
    switch (formulation) {
      case 'SL':
        return Colors.blue; // Soluções
      case 'EC':
      case 'SC':
        return Colors.green; // Líquidos solúveis
      case 'WG':
      case 'WP':
      case 'SP':
      case 'SG':
        return Colors.orange; // Sólidos
      case 'AD':
      case 'OD':
      case 'EO':
      case 'EW':
        return Colors.purple; // Adjuvantes
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _getFormulationCategory(String formulation) {
    switch (formulation) {
      case 'SL':
        return 'SOLUÇÃO';
      case 'EC':
      case 'SC':
        return 'LÍQUIDO';
      case 'WG':
      case 'WP':
      case 'SP':
      case 'SG':
        return 'SÓLIDO';
      case 'AD':
      case 'OD':
      case 'EO':
      case 'EW':
        return 'ADJUVANTE';
      default:
        return 'OUTRO';
    }
  }
}
