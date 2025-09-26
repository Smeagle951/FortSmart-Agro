import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/precise_area_calculation_service.dart';

/// Widget para exibir indicador de qualidade dos pontos GPS
class GPSQualityIndicator extends StatelessWidget {
  final List<LatLng> points;
  final PreciseAreaCalculationService? areaService;

  const GPSQualityIndicator({
    Key? key,
    required this.points,
    this.areaService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.length < 3) {
      return _buildInsufficientPointsIndicator();
    }

    final stats = _getCalculationStatistics();
    final quality = _getQualityLevel(stats);
    final color = _getQualityColor(quality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getQualityIcon(quality),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getQualityText(quality, stats),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientPointsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            color: Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Pontos insuficientes',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCalculationStatistics() {
    if (areaService != null) {
      return areaService!.getCalculationStatistics(points);
    }
    
    // Fallback para cálculo básico
    return {
      'valid': points.length >= 3,
      'point_count': points.length,
      'area_hectares': 0.0,
      'perimeter_meters': 0.0,
    };
  }

  String _getQualityLevel(Map<String, dynamic> stats) {
    if (!stats['valid']) return 'invalid';
    
    final pointCount = stats['point_count'] as int;
    final avgDistance = stats['average_distance_between_points'] as double? ?? 0.0;
    
    if (pointCount >= 10 && avgDistance <= 5.0) return 'excellent';
    if (pointCount >= 6 && avgDistance <= 10.0) return 'very_good';
    if (pointCount >= 4 && avgDistance <= 20.0) return 'good';
    if (pointCount >= 3 && avgDistance <= 50.0) return 'regular';
    return 'poor';
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'excellent':
        return Colors.green;
      case 'very_good':
        return Colors.lightGreen;
      case 'good':
        return Colors.yellow;
      case 'regular':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getQualityIcon(String quality) {
    switch (quality) {
      case 'excellent':
        return Icons.star;
      case 'very_good':
        return Icons.check_circle;
      case 'good':
        return Icons.check;
      case 'regular':
        return Icons.warning;
      case 'poor':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getQualityText(String quality, Map<String, dynamic> stats) {
    final pointCount = stats['point_count'] as int;
    final area = stats['area_hectares'] as double;
    
    switch (quality) {
      case 'excellent':
        return 'Excelente (${pointCount} pts, ${area.toStringAsFixed(2)} ha)';
      case 'very_good':
        return 'Muito Boa (${pointCount} pts, ${area.toStringAsFixed(2)} ha)';
      case 'good':
        return 'Boa (${pointCount} pts, ${area.toStringAsFixed(2)} ha)';
      case 'regular':
        return 'Regular (${pointCount} pts, ${area.toStringAsFixed(2)} ha)';
      case 'poor':
        return 'Baixa (${pointCount} pts, ${area.toStringAsFixed(2)} ha)';
      default:
        return 'Indefinida';
    }
  }
}

/// Widget expandido para mostrar detalhes da qualidade GPS
class GPSQualityDetailsWidget extends StatelessWidget {
  final List<LatLng> points;
  final PreciseAreaCalculationService? areaService;

  const GPSQualityDetailsWidget({
    Key? key,
    required this.points,
    this.areaService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.length < 3) {
      return _buildInsufficientPointsCard();
    }

    final stats = _getCalculationStatistics();
    final quality = _getQualityLevel(stats);
    final color = _getQualityColor(quality);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  _getQualityIcon(quality),
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Qualidade dos Pontos GPS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estatísticas
            _buildStatisticRow('Classificação', _getQualityText(quality, stats), color),
            _buildStatisticRow('Pontos', '${stats['point_count']}', Colors.blue),
            _buildStatisticRow('Área', '${(stats['area_hectares'] as double).toStringAsFixed(4)} ha', Colors.green),
            _buildStatisticRow('Perímetro', '${(stats['perimeter_meters'] as double).toStringAsFixed(2)} m', Colors.orange),
            
            if (stats['average_distance_between_points'] != null)
              _buildStatisticRow(
                'Distância Média', 
                '${(stats['average_distance_between_points'] as double).toStringAsFixed(2)} m', 
                Colors.purple
              ),
            
            const SizedBox(height: 16),
            
            // Recomendações
            _buildRecommendations(quality, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientPointsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Pontos Insuficientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione pelo menos 3 pontos para criar um talhão',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
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

  Widget _buildRecommendations(String quality, Map<String, dynamic> stats) {
    List<String> recommendations = [];
    
    switch (quality) {
      case 'excellent':
        recommendations.add('✅ Qualidade excelente para agricultura de precisão');
        break;
      case 'very_good':
        recommendations.add('✅ Qualidade muito boa para mapeamento de talhões');
        break;
      case 'good':
        recommendations.add('⚠️ Qualidade boa, mas pode ser melhorada');
        recommendations.add('• Adicione mais pontos para maior precisão');
        break;
      case 'regular':
        recommendations.add('⚠️ Qualidade regular, considere refazer o mapeamento');
        recommendations.add('• Use GPS em área aberta');
        recommendations.add('• Aguarde estabilização do sinal');
        break;
      case 'poor':
        recommendations.add('❌ Qualidade baixa, recomenda-se refazer');
        recommendations.add('• Verifique se está em área aberta');
        recommendations.add('• Aguarde mais satélites');
        recommendations.add('• Considere usar GPS externo');
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recomendações:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              rec,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCalculationStatistics() {
    if (areaService != null) {
      return areaService!.getCalculationStatistics(points);
    }
    
    return {
      'valid': points.length >= 3,
      'point_count': points.length,
      'area_hectares': 0.0,
      'perimeter_meters': 0.0,
    };
  }

  String _getQualityLevel(Map<String, dynamic> stats) {
    if (!stats['valid']) return 'invalid';
    
    final pointCount = stats['point_count'] as int;
    final avgDistance = stats['average_distance_between_points'] as double? ?? 0.0;
    
    if (pointCount >= 10 && avgDistance <= 5.0) return 'excellent';
    if (pointCount >= 6 && avgDistance <= 10.0) return 'very_good';
    if (pointCount >= 4 && avgDistance <= 20.0) return 'good';
    if (pointCount >= 3 && avgDistance <= 50.0) return 'regular';
    return 'poor';
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'excellent':
        return Colors.green;
      case 'very_good':
        return Colors.lightGreen;
      case 'good':
        return Colors.yellow;
      case 'regular':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getQualityIcon(String quality) {
    switch (quality) {
      case 'excellent':
        return Icons.star;
      case 'very_good':
        return Icons.check_circle;
      case 'good':
        return Icons.check;
      case 'regular':
        return Icons.warning;
      case 'poor':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getQualityText(String quality, Map<String, dynamic> stats) {
    switch (quality) {
      case 'excellent':
        return 'Excelente';
      case 'very_good':
        return 'Muito Boa';
      case 'good':
        return 'Boa';
      case 'regular':
        return 'Regular';
      case 'poor':
        return 'Baixa';
      default:
        return 'Indefinida';
    }
  }
}
