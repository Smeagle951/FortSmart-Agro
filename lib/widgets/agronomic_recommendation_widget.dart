import 'package:flutter/material.dart';

/// Widget para exibir recomendações agronômicas inteligentes
class AgronomicRecommendationWidget extends StatelessWidget {
  final String alertLevel;
  final String recommendation;
  final double severity;
  final String organismName;

  const AgronomicRecommendationWidget({
    Key? key,
    required this.alertLevel,
    required this.recommendation,
    required this.severity,
    required this.organismName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertColor(alertLevel).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAlertColor(alertLevel).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getAlertIcon(alertLevel),
                color: _getAlertColor(alertLevel),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getAlertTitle(alertLevel),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getAlertColor(alertLevel),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAlertColor(alertLevel),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${severity.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
          if (alertLevel == 'critico' || alertLevel == 'alto') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: _getAlertColor(alertLevel),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ação imediata recomendada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getAlertColor(alertLevel),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getAlertColor(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return const Color(0xFF4CAF50); // Verde
      case 'medio':
        return const Color(0xFFFF9800); // Laranja
      case 'alto':
        return const Color(0xFFF44336); // Vermelho
      case 'critico':
        return const Color(0xFF9C27B0); // Roxo
      default:
        return const Color(0xFF757575); // Cinza
    }
  }

  IconData _getAlertIcon(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return Icons.check_circle;
      case 'medio':
        return Icons.warning;
      case 'alto':
        return Icons.error;
      case 'critico':
        return Icons.dangerous;
      default:
        return Icons.info;
    }
  }

  String _getAlertTitle(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return 'Nível Baixo';
      case 'medio':
        return 'Nível Médio';
      case 'alto':
        return 'Nível Alto';
      case 'critico':
        return 'Nível Crítico';
      default:
        return 'Nível Desconhecido';
    }
  }
}
