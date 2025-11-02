import 'package:flutter/material.dart';

/// Widget para exibir status dos modelos de IA
class AIModelsStatusWidget extends StatelessWidget {
  final Map<String, dynamic> modelsStatus;

  const AIModelsStatusWidget({
    super.key,
    required this.modelsStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status dos Modelos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...modelsStatus.entries.map((entry) => _buildModelStatusItem(
              context,
              entry.key,
              entry.value,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatusItem(
    BuildContext context,
    String modelName,
    dynamic status,
  ) {
    final statusInfo = _getStatusInfo(status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusInfo['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatModelName(modelName),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  statusInfo['label'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (statusInfo['icon'] != null)
            Icon(
              statusInfo['icon'],
              size: 16,
              color: statusInfo['color'],
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(dynamic status) {
    switch (status.toString()) {
      case 'active':
        return {
          'label': 'Ativo e funcionando',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'training':
        return {
          'label': 'Treinando...',
          'color': Colors.orange,
          'icon': Icons.hourglass_empty,
        };
      case 'error':
        return {
          'label': 'Erro no modelo',
          'color': Colors.red,
          'icon': Icons.error,
        };
      case 'offline':
        return {
          'label': 'Offline',
          'color': Colors.grey,
          'icon': Icons.cloud_off,
        };
      default:
        return {
          'label': 'Status desconhecido',
          'color': Colors.grey,
          'icon': Icons.help,
        };
    }
  }

  String _formatModelName(String modelName) {
    switch (modelName) {
      case 'pest_detection':
        return 'Detecção de Pragas';
      case 'germination_analysis':
        return 'Análise de Germinação';
      case 'weather_prediction':
        return 'Predição Climática';
      case 'disease_classification':
        return 'Classificação de Doenças';
      default:
        return modelName.replaceAll('_', ' ').split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
