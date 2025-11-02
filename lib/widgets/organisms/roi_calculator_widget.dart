import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/organism_catalog_v3.dart';
import '../../services/fortsmart_ai_v3_integration.dart';

/// Widget para exibir cálculo de ROI de controle
class ROICalculatorWidget extends StatelessWidget {
  final OrganismCatalogV3 organismo;
  final double areaHa;
  final bool compact;

  const ROICalculatorWidget({
    Key? key,
    required this.organismo,
    required this.areaHa,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roiData = FortSmartAIV3Integration.calcularROIControle(
      organismo: organismo,
      areaHa: areaHa,
    );

    final roi = roiData['roi'] as double;
    final economia = roiData['economia'] as double;
    final custoControle = roiData['custo_controle'] as double;
    final custoNaoControle = roiData['custo_nao_controle'] as double;

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (compact) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROI: ${roi.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    'Economia: ${currencyFormat.format(economia)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              Icon(Icons.trending_up, color: Colors.green[800], size: 32),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Análise Econômica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ROI
            _buildMetricRow(
              'ROI',
              '${roi.toStringAsFixed(1)}x',
              Colors.green,
              Icons.trending_up,
            ),
            
            const Divider(),
            
            // Custo sem controle
            _buildMetricRow(
              'Custo sem Controle',
              currencyFormat.format(custoNaoControle),
              Colors.red,
              Icons.warning,
            ),
            
            // Custo com controle
            _buildMetricRow(
              'Custo com Controle',
              currencyFormat.format(custoControle),
              Colors.orange,
              Icons.savings,
            ),
            
            const Divider(),
            
            // Economia potencial
            _buildMetricRow(
              'Economia Potencial',
              currencyFormat.format(economia),
              Colors.green,
              Icons.attach_money,
            ),
            
            if (roiData['momento_otimo'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Momento ótimo: ${roiData['momento_otimo']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700]!,
            ),
          ),
        ],
      ),
    );
  }
}

