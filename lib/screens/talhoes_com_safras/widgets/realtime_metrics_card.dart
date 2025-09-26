import 'package:flutter/material.dart';
import '../../../utils/geo_calculator.dart';

/// Widget para exibir métricas em tempo real durante desenho ou GPS
class RealtimeMetricsCard extends StatelessWidget {
  final double areaHa;
  final double perimeterM;
  final double speedKmh;
  final Duration elapsedTime;
  final double? gpsAccuracy;
  final bool isGpsMode;
  final bool isPaused;
  final int vertices;

  const RealtimeMetricsCard({
    Key? key,
    required this.areaHa,
    required this.perimeterM,
    required this.speedKmh,
    required this.elapsedTime,
    this.gpsAccuracy,
    this.isGpsMode = false,
    this.isPaused = false,
    this.vertices = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  isGpsMode ? Icons.gps_fixed : Icons.edit,
                  color: isGpsMode ? Colors.blue : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isGpsMode ? 'Caminhada GPS' : 'Desenho Manual',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isGpsMode && isPaused)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PAUSADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Métricas principais
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Área',
                    GeoCalculator.formatArea(areaHa),
                    Icons.area_chart,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Perímetro',
                    GeoCalculator.formatPerimeter(perimeterM),
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Métricas secundárias
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Vértices',
                    '$vertices',
                    Icons.place,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Tempo',
                    _formatDuration(elapsedTime),
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Métricas secundárias (GPS)
            if (isGpsMode) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Velocidade',
                      '${speedKmh.toStringAsFixed(1)} km/h',
                      Icons.speed,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Tempo',
                      _formatDuration(elapsedTime),
                      Icons.timer,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Indicador de precisão GPS
              if (gpsAccuracy != null)
                _buildAccuracyIndicator(gpsAccuracy!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyIndicator(double accuracy) {
    Color accuracyColor;
    String accuracyText;
    IconData accuracyIcon;

    if (accuracy <= 3.0) {
      accuracyColor = Colors.green;
      accuracyText = 'Excelente';
      accuracyIcon = Icons.check_circle;
    } else if (accuracy <= 5.0) {
      accuracyColor = Colors.orange;
      accuracyText = 'Bom';
      accuracyIcon = Icons.warning;
    } else {
      accuracyColor = Colors.red;
      accuracyText = 'Ruim';
      accuracyIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accuracyColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(accuracyIcon, color: accuracyColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precisão GPS',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${accuracy.toStringAsFixed(1)}m - $accuracyText',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accuracyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
