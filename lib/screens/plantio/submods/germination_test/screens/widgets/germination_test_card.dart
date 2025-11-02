/// 🌱 Widget de Card de Teste de Germinação
/// 
/// Card elegante para exibir informações do teste
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import '../../../../../../utils/fortsmart_theme.dart';
import '../../models/germination_test_model.dart';

class GerminationTestCard extends StatelessWidget {
  final GerminationTest test;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GerminationTestCard({
    super.key,
    required this.test,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildTestInfo(),
              const SizedBox(height: 12),
              _buildResults(),
              const SizedBox(height: 12),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildStatusIndicator(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test.culture,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${test.variety} - ${test.seedLot}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildTestTypeIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;
    String label;
    
    switch (test.status) {
      case 'active':
        color = Colors.green;
        icon = Icons.play_circle;
        label = 'Ativo';
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.check_circle;
        label = 'Completo';
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Desconhecido';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTypeIndicator() {
    if (test.hasSubtests) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science, color: Colors.blue[600], size: 14),
            const SizedBox(width: 4),
            Text(
              'A, B, C',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science, color: Colors.green[600], size: 14),
          const SizedBox(width: 4),
          Text(
            'Individual',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            Icons.calendar_today,
            'Início',
            _formatDate(test.startDate),
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            Icons.science,
            'Sementes',
            '${test.totalSeeds}',
          ),
        ),
        if (test.hasSubtests)
          Expanded(
            child: _buildInfoItem(
              Icons.grid_view,
              'Subtestes',
              '3',
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (test.status != 'completed' || test.finalGerminationPercentage == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Text(
              'Teste em andamento',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getGerminationColor(test.finalGerminationPercentage!).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getGerminationColor(test.finalGerminationPercentage!).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: _getGerminationColor(test.finalGerminationPercentage!),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Germinação: ${(test.finalGerminationPercentage ?? 0.0).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getGerminationColor(test.finalGerminationPercentage ?? 0.0),
                  ),
                ),
                if (test.purityPercentage != null)
                  Text(
                    'Pureza: ${(test.purityPercentage ?? 0.0).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          _buildClassificationChip(),
        ],
      ),
    );
  }

  Widget _buildClassificationChip() {
    if (test.finalGerminationPercentage == null) return const SizedBox.shrink();
    
    final percentage = test.finalGerminationPercentage!;
    String classification;
    Color color;
    
    if (percentage >= 90) {
      classification = 'Excelente';
      color = Colors.green;
    } else if (percentage >= 80) {
      classification = 'Boa';
      color = Colors.blue;
    } else if (percentage >= 70) {
      classification = 'Regular';
      color = Colors.orange;
    } else {
      classification = 'Baixa';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        classification,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Ver Detalhes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: FortSmartTheme.primaryColor,
              side: BorderSide(color: FortSmartTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 20),
            color: Colors.orange,
            tooltip: 'Editar',
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            tooltip: 'Excluir',
          ),
      ],
    );
  }

  Color _getGerminationColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
