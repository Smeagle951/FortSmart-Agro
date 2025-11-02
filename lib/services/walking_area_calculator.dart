import 'package:latlong2/latlong.dart';
import 'precise_geo_calculator.dart';

/// Serviço para cálculo de área de caminhada e aplicação
/// Considera largura do caminho, sobreposição e eficiência
class WalkingAreaCalculator {
  
  /// Calcula área de caminhada em hectares
  /// 
  /// [path] - Lista de coordenadas do caminho percorrido
  /// [pathWidth] - Largura do caminho em metros
  /// [overlapPercentage] - Percentual de sobreposição (0-100)
  /// [efficiencyFactor] - Fator de eficiência (0-1)
  static double calculateWalkingArea({
    required List<LatLng> path,
    required double pathWidth,
    double overlapPercentage = 0.0,
    double efficiencyFactor = 1.0,
  }) {
    if (path.length < 2) return 0.0;
    
    try {
      // Largura efetiva considerando sobreposição
      final effectiveWidth = pathWidth * (1 - overlapPercentage / 100);
      
      // Calcular área usando sistema preciso
      final areaHectares = PreciseGeoCalculator.calculateWalkingArea(path, effectiveWidth);
      
      // Aplicar fator de eficiência
      final finalArea = areaHectares * efficiencyFactor;
      
      print('📊 Área de caminhada calculada:');
      print('  - Largura do caminho: ${pathWidth.toStringAsFixed(2)} m');
      print('  - Largura efetiva: ${effectiveWidth.toStringAsFixed(2)} m');
      print('  - Sobreposição: ${overlapPercentage.toStringAsFixed(1)}%');
      print('  - Eficiência: ${(efficiencyFactor * 100).toStringAsFixed(1)}%');
      print('  - Área total: ${finalArea.toStringAsFixed(4)} ha');
      
      return finalArea;
      
    } catch (e) {
      print('❌ Erro ao calcular área de caminhada: $e');
      return 0.0;
    }
  }
  
  /// Calcula área de aplicação considerando parâmetros específicos
  /// 
  /// [path] - Lista de coordenadas do caminho
  /// [swathWidth] - Largura da faixa de aplicação em metros
  /// [overlapPercentage] - Percentual de sobreposição entre faixas
  /// [efficiencyFactor] - Fator de eficiência da aplicação
  /// [turnRadius] - Raio de curva em metros (para compensar perdas nas curvas)
  static double calculateApplicationArea({
    required List<LatLng> path,
    required double swathWidth,
    double overlapPercentage = 10.0,
    double efficiencyFactor = 0.95,
    double turnRadius = 0.0,
  }) {
    if (path.length < 2) return 0.0;
    
    try {
      // Calcular área base
      final baseArea = PreciseGeoCalculator.calculateApplicationArea(
        path, 
        swathWidth, 
        overlapPercentage
      );
      
      // Calcular perdas nas curvas se especificado
      double curveLoss = 0.0;
      if (turnRadius > 0) {
        curveLoss = _calculateCurveLoss(path, swathWidth, turnRadius);
      }
      
      // Aplicar fator de eficiência e compensar perdas
      final finalArea = (baseArea - curveLoss) * efficiencyFactor;
      
      print('📊 Área de aplicação calculada:');
      print('  - Largura da faixa: ${swathWidth.toStringAsFixed(2)} m');
      print('  - Sobreposição: ${overlapPercentage.toStringAsFixed(1)}%');
      print('  - Eficiência: ${(efficiencyFactor * 100).toStringAsFixed(1)}%');
      print('  - Perdas nas curvas: ${curveLoss.toStringAsFixed(4)} ha');
      print('  - Área final: ${finalArea.toStringAsFixed(4)} ha');
      
      return finalArea;
      
    } catch (e) {
      print('❌ Erro ao calcular área de aplicação: $e');
      return 0.0;
    }
  }
  
  /// Calcula perdas de área nas curvas
  static double _calculateCurveLoss(List<LatLng> path, double swathWidth, double turnRadius) {
    if (path.length < 3) return 0.0;
    
    double totalLoss = 0.0;
    
    for (int i = 1; i < path.length - 1; i++) {
      final prev = path[i - 1];
      final current = path[i];
      final next = path[i + 1];
      
      // Calcular ângulo entre segmentos
      final angle = _calculateAngle(prev, current, next);
      
      // Se há curva significativa
      if (angle.abs() > 5.0) { // Mais de 5 graus
        // Calcular área perdida na curva
        final curveArea = _calculateCurveArea(angle, swathWidth, turnRadius);
        totalLoss += curveArea;
      }
    }
    
    return totalLoss / 10000.0; // Converter para hectares
  }
  
  /// Calcula ângulo entre três pontos
  static double _calculateAngle(LatLng p1, LatLng p2, LatLng p3) {
    final v1x = p1.longitude - p2.longitude;
    final v1y = p1.latitude - p2.latitude;
    final v2x = p3.longitude - p2.longitude;
    final v2y = p3.latitude - p2.latitude;
    
    final dot = v1x * v2x + v1y * v2y;
    final det = v1x * v2y - v1y * v2x;
    
    return atan2(det, dot) * 180 / pi;
  }
  
  /// Calcula área perdida em uma curva
  static double _calculateCurveArea(double angle, double swathWidth, double turnRadius) {
    final angleRad = angle.abs() * pi / 180;
    final curveLength = turnRadius * angleRad;
    
    // Área aproximada perdida na curva
    return curveLength * swathWidth * 0.3; // 30% de perda estimada
  }
  
  /// Calcula eficiência de campo baseada no caminho
  /// 
  /// Retorna um valor entre 0 e 1 representando a eficiência
  /// Considera fatores como:
  /// - Retas vs curvas
  /// - Sobreposições
  /// - Área efetiva vs área total
  static double calculateFieldEfficiency({
    required List<LatLng> path,
    required double swathWidth,
    required double fieldArea,
    double overlapPercentage = 10.0,
  }) {
    if (path.length < 2 || fieldArea <= 0) return 0.0;
    
    try {
      // Calcular área efetiva de aplicação
      final applicationArea = calculateApplicationArea(
        path: path,
        swathWidth: swathWidth,
        overlapPercentage: overlapPercentage,
        efficiencyFactor: 1.0, // Sem aplicar eficiência aqui
      );
      
      // Calcular eficiência
      final efficiency = applicationArea / fieldArea;
      
      // Limitar entre 0 e 1
      return efficiency.clamp(0.0, 1.0);
      
    } catch (e) {
      print('❌ Erro ao calcular eficiência de campo: $e');
      return 0.0;
    }
  }
  
  /// Calcula estatísticas do caminho
  static Map<String, double> calculatePathStatistics(List<LatLng> path) {
    if (path.length < 2) {
      return {
        'totalDistance': 0.0,
        'averageSpeed': 0.0,
        'straightSegments': 0.0,
        'curveSegments': 0.0,
        'efficiency': 0.0,
      };
    }
    
    try {
      double totalDistance = 0.0;
      int straightSegments = 0;
      int curveSegments = 0;
      
      for (int i = 0; i < path.length - 1; i++) {
        final distance = PreciseGeoCalculator._calculateGeodeticDistance(
          path[i], 
          path[i + 1]
        );
        totalDistance += distance;
        
        // Verificar se é segmento reto ou curva
        if (i > 0 && i < path.length - 1) {
          final angle = _calculateAngle(path[i - 1], path[i], path[i + 1]);
          if (angle.abs() < 5.0) {
            straightSegments++;
          } else {
            curveSegments++;
          }
        }
      }
      
      final efficiency = straightSegments / (straightSegments + curveSegments);
      
      return {
        'totalDistance': totalDistance,
        'averageSpeed': 0.0, // Seria calculado com dados de tempo
        'straightSegments': straightSegments.toDouble(),
        'curveSegments': curveSegments.toDouble(),
        'efficiency': efficiency,
      };
      
    } catch (e) {
      print('❌ Erro ao calcular estatísticas do caminho: $e');
      return {
        'totalDistance': 0.0,
        'averageSpeed': 0.0,
        'straightSegments': 0.0,
        'curveSegments': 0.0,
        'efficiency': 0.0,
      };
    }
  }
}
