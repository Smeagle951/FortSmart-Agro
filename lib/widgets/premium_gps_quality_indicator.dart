import 'package:flutter/material.dart';

/// Indicador de qualidade GPS premium
class PremiumGpsQualityIndicator extends StatelessWidget {
  final double accuracy;
  final int satellites;
  final bool isConnected;
  final VoidCallback? onTap;

  const PremiumGpsQualityIndicator({
    Key? key,
    required this.accuracy,
    required this.satellites,
    required this.isConnected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getQualityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gps_fixed,
                      color: _getQualityColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qualidade GPS',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getQualityText(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getQualityColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Precisão',
                      '${accuracy.toStringAsFixed(1)} m',
                      Icons.center_focus_strong,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Satélites',
                      '$satellites',
                      Icons.satellite,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Status',
                      isConnected ? 'Conectado' : 'Desconectado',
                      isConnected ? Icons.check_circle : Icons.cancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor() {
    if (accuracy <= 3.0) return Colors.green;
    if (accuracy <= 10.0) return Colors.orange;
    return Colors.red;
  }

  String _getQualityText() {
    if (accuracy <= 3.0) return 'Excelente';
    if (accuracy <= 10.0) return 'Boa';
    return 'Ruim';
  }
}
