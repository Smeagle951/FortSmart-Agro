import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/geo_calculator_service.dart';
import '../services/advanced_gps_tracking_service.dart';

/// Widget avançado para exibir métricas detalhadas do talhão
class AdvancedMetricsWidget extends StatelessWidget {
  final List<LatLng> points;
  final GpsStats? gpsStats;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const AdvancedMetricsWidget({
    Key? key,
    required this.points,
    this.gpsStats,
    required this.isVisible,
    this.onToggleVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || points.isEmpty) {
      return const SizedBox.shrink();
    }

    final geoCalculator = GeoCalculatorService();
    final area = geoCalculator.calculateAreaHectares(points);
    final perimeter = geoCalculator.calculatePerimeter(points);
    final boundingBox = geoCalculator.calculateBoundingBox(points);
    final accuracy = geoCalculator.estimateAccuracy(points);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Métricas do Talhão',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              if (onToggleVisibility != null)
                IconButton(
                  onPressed: onToggleVisibility,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Métricas principais
          _buildMetricsGrid(area, perimeter, points.length),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Métricas avançadas
          _buildAdvancedMetrics(boundingBox, accuracy),
          
          // Estatísticas GPS se disponível
          if (gpsStats != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildGpsStats(gpsStats!),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(double area, double perimeter, int pointCount) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Área',
            geoCalculator.formatArea(area),
            'ha',
            Icons.crop_square,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Perímetro',
            geoCalculator.formatDistance(perimeter),
            '',
            Icons.straighten,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Pontos',
            pointCount.toString(),
            '',
            Icons.location_on,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedMetrics(Map<String, double> boundingBox, String accuracy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações Avançadas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        
        // Bounding Box
        _buildInfoRow('Limites Norte-Sul', 
          '${boundingBox['minLat']!.toStringAsFixed(6)}° a ${boundingBox['maxLat']!.toStringAsFixed(6)}°'),
        _buildInfoRow('Limites Leste-Oeste', 
          '${boundingBox['minLng']!.toStringAsFixed(6)}° a ${boundingBox['maxLng']!.toStringAsFixed(6)}°'),
        
        // Dimensões
        final latDiff = boundingBox['maxLat']! - boundingBox['minLat']!;
        final lngDiff = boundingBox['maxLng']! - boundingBox['minLng']!;
        _buildInfoRow('Dimensão Lat', '${(latDiff * 111320).toStringAsFixed(0)} m'),
        _buildInfoRow('Dimensão Lng', '${(lngDiff * 111320).toStringAsFixed(0)} m'),
        
        // Precisão
        _buildInfoRow('Precisão Estimada', accuracy),
      ],
    );
  }

  Widget _buildGpsStats(GpsStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas GPS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildInfoRow('Tempo de Rastreamento', stats.formattedTime),
        _buildInfoRow('Distância Percorrida', stats.formattedDistance),
        _buildInfoRow('Velocidade Média', stats.formattedAverageSpeed),
        _buildInfoRow('Velocidade Máxima', stats.formattedMaxSpeed),
        _buildInfoRow('Precisão Média', stats.formattedAccuracy),
        _buildInfoRow('Total de Pontos', stats.totalPoints.toString()),
        
        // Status
        Row(
          children: [
            Icon(
              stats.isTracking ? Icons.gps_fixed : Icons.gps_off,
              color: stats.isTracking ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              stats.isTracking 
                ? (stats.isPaused ? 'GPS Pausado' : 'GPS Ativo')
                : 'GPS Inativo',
              style: TextStyle(
                color: stats.isTracking ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
