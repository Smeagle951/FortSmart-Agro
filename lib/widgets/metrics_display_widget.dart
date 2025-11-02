import 'package:flutter/material.dart';

/// Widget para exibir métricas do talhão em tempo real
class MetricsDisplayWidget extends StatelessWidget {
  final double area;
  final double perimeter;
  final double distance;
  final int pointCount;
  final bool isVisible;

  const MetricsDisplayWidget({
    Key? key,
    required this.area,
    required this.perimeter,
    required this.distance,
    required this.pointCount,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Métricas do Talhão',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.area_chart,
                      label: 'Área',
                      value: _formatArea(area),
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.straighten,
                      label: 'Perímetro',
                      value: _formatDistance(perimeter),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.route,
                      label: 'Distância',
                      value: _formatDistance(distance),
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.location_on,
                      label: 'Pontos',
                      value: pointCount.toString(),
                      color: Colors.purple,
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

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatArea(double hectares) {
    if (hectares == 0) return '0,00 ha';
    return '${hectares.toStringAsFixed(2).replaceAll('.', ',')} ha';
  }

  String _formatDistance(double meters) {
    if (meters == 0) return '0 m';
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';
    }
  }
}
