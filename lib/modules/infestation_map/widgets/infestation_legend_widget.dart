import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget para exibir a legenda dos níveis de infestação
class InfestationLegendWidget extends StatelessWidget {
  const InfestationLegendWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.legend_toggle, color: Color(0xFF2A4F3D)),
                const SizedBox(width: 8),
                const Text(
                  'Níveis de Infestação',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2A4F3D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...InfestationLevel.values.map((level) => _buildLegendItem(level)),
            const SizedBox(height: 16),
            _buildLegendInfo(),
          ],
        ),
      ),
    );
  }

  /// Constrói item da legenda
  Widget _buildLegendItem(InfestationLevel level) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Indicador de cor
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          
          // Nome do nível
          Expanded(
            child: Text(
              level.label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: level.color,
              ),
            ),
          ),
          
          // Faixa de valores
          Text(
            '${level.minValue.toStringAsFixed(0)}-${level.maxValue.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói informações adicionais da legenda
  Widget _buildLegendInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Informações',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Os níveis são calculados automaticamente com base na porcentagem de infestação detectada.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}
