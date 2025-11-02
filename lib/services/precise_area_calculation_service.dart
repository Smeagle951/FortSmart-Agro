import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'advanced_gps_service.dart';
import 'gps_filter_service.dart';

/// Serviço para cálculos precisos de área e perímetro usando pontos GPS filtrados
class PreciseAreaCalculationService {
  static const String _tag = 'PreciseAreaCalculationService';
  
  // Constantes para cálculos geodésicos
  static const double _earthRadius = 6378137.0; // Raio da Terra em metros (WGS84)
  static const double _metersPerDegreeLat = 111132.954; // Metros por grau de latitude
  static const double _hectaresPerSquareMeter = 0.0001; // Conversão m² → ha
  
  /// Calcula área de um polígono usando pontos GPS filtrados
  double calculatePolygonArea(List<LatLng> points, {bool useHighPrecision = true}) {
    try {
      if (points.length < 3) {
        print('$_tag: Polígono deve ter pelo menos 3 pontos');
        return 0.0;
      }
      
      // Validar qualidade dos pontos
      final filterService = GPSFilterService();
      if (!filterService.validatePolygonQuality(points)) {
        print('$_tag: Qualidade do polígono insuficiente para cálculo preciso');
        return 0.0;
      }
      
      double area;
      
      if (useHighPrecision) {
        // Usar fórmula de Shoelace com correção geodésica
        area = _calculateAreaShoelaceGeodetic(points);
      } else {
        // Usar fórmula de Shoelace simples (mais rápida)
        area = _calculateAreaShoelaceSimple(points);
      }
      
      // Converter para hectares
      final areaHectares = area * _hectaresPerSquareMeter;
      
      print('$_tag: Área calculada: ${areaHectares.toStringAsFixed(4)} hectares');
      return areaHectares;
      
    } catch (e) {
      print('$_tag: Erro ao calcular área: $e');
      return 0.0;
    }
  }
  
  /// Calcula perímetro de um polígono usando pontos GPS filtrados
  double calculatePolygonPerimeter(List<LatLng> points) {
    try {
      if (points.length < 3) {
        print('$_tag: Polígono deve ter pelo menos 3 pontos');
        return 0.0;
      }
      
      double perimeter = 0.0;
      const Distance distance = Distance();
      
      // Calcular distâncias entre pontos consecutivos
      for (int i = 0; i < points.length - 1; i++) {
        final dist = distance.as(LengthUnit.Meter, points[i], points[i + 1]);
        perimeter += dist;
      }
      
      // Fechar o polígono (distância do último ponto ao primeiro)
      final closingDist = distance.as(LengthUnit.Meter, points.last, points.first);
      perimeter += closingDist;
      
      print('$_tag: Perímetro calculado: ${perimeter.toStringAsFixed(2)} metros');
      return perimeter;
      
    } catch (e) {
      print('$_tag: Erro ao calcular perímetro: $e');
      return 0.0;
    }
  }
  
  /// Calcula área usando fórmula de Shoelace com correção geodésica
  double _calculateAreaShoelaceGeodetic(List<LatLng> points) {
    double area = 0.0;
    
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      
      // Aplicar correção geodésica para latitude
      final lat1Rad = points[i].latitude * pi / 180;
      final lat2Rad = points[j].latitude * pi / 180;
      
      // Calcular metros por grau de longitude para esta latitude
      final metersPerDegreeLng = (pi / 180) * _earthRadius * cos(lat1Rad);
      
      // Aplicar fórmula de Shoelace com correção
      area += points[i].latitude * points[j].longitude * _metersPerDegreeLat * metersPerDegreeLng;
      area -= points[j].latitude * points[i].longitude * _metersPerDegreeLat * metersPerDegreeLng;
    }
    
    return area.abs() / 2.0;
  }
  
  /// Calcula área usando fórmula de Shoelace simples
  double _calculateAreaShoelaceSimple(List<LatLng> points) {
    double area = 0.0;
    
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para metros quadrados usando latitude média
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final latRad = avgLat * pi / 180;
    final metersPerDegLat = 111132.954 - 559.822 * cos(2 * latRad) + 1.175 * cos(4 * latRad);
    final metersPerDegLng = (pi / 180) * _earthRadius * cos(latRad);
    
    return area * metersPerDegLat * metersPerDegLng;
  }
  
  /// Calcula área usando pontos GPS filtrados do AdvancedGPSService
  double calculateAreaFromGPSPositions(AdvancedGPSService gpsService, {bool useHighPrecision = true}) {
    try {
      // Obter pontos filtrados adequados para cálculo de área
      final filteredPoints = gpsService.getFilteredPolygonPoints(maxAccuracy: 5.0);
      
      if (filteredPoints.length < 3) {
        print('$_tag: Pontos GPS insuficientes para cálculo de área (${filteredPoints.length} pontos)');
        return 0.0;
      }
      
      print('$_tag: Calculando área com ${filteredPoints.length} pontos GPS filtrados');
      
      // Calcular área usando pontos filtrados
      return calculatePolygonArea(filteredPoints, useHighPrecision: useHighPrecision);
      
    } catch (e) {
      print('$_tag: Erro ao calcular área a partir de posições GPS: $e');
      return 0.0;
    }
  }
  
  /// Calcula perímetro usando pontos GPS filtrados do AdvancedGPSService
  double calculatePerimeterFromGPSPositions(AdvancedGPSService gpsService) {
    try {
      // Obter pontos filtrados adequados para cálculo de área
      final filteredPoints = gpsService.getFilteredPolygonPoints(maxAccuracy: 5.0);
      
      if (filteredPoints.length < 3) {
        print('$_tag: Pontos GPS insuficientes para cálculo de perímetro (${filteredPoints.length} pontos)');
        return 0.0;
      }
      
      print('$_tag: Calculando perímetro com ${filteredPoints.length} pontos GPS filtrados');
      
      // Calcular perímetro usando pontos filtrados
      return calculatePolygonPerimeter(filteredPoints);
      
    } catch (e) {
      print('$_tag: Erro ao calcular perímetro a partir de posições GPS: $e');
      return 0.0;
    }
  }
  
  /// Valida se os pontos são adequados para cálculo preciso
  bool validatePointsForPreciseCalculation(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Verificar se não há pontos muito próximos
    for (int i = 0; i < points.length - 1; i++) {
      final distance = _calculateDistance(points[i], points[i + 1]);
      if (distance < 1.0) return false; // Pontos muito próximos
    }
    
    // Verificar se não há pontos muito distantes (possível erro)
    for (int i = 0; i < points.length - 1; i++) {
      final distance = _calculateDistance(points[i], points[i + 1]);
      if (distance > 1000.0) return false; // Pontos muito distantes
    }
    
    // Verificar se a área não é muito pequena
    final area = _calculateAreaShoelaceSimple(points);
    if (area < 100.0) return false; // Menos de 100 m²
    
    return true;
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
  
  /// Obtém estatísticas de qualidade dos cálculos
  Map<String, dynamic> getCalculationStatistics(List<LatLng> points) {
    if (points.length < 3) {
      return {
        'valid': false,
        'reason': 'Pontos insuficientes',
        'area_hectares': 0.0,
        'perimeter_meters': 0.0,
        'point_count': points.length,
      };
    }
    
    final isValid = validatePointsForPreciseCalculation(points);
    final area = calculatePolygonArea(points);
    final perimeter = calculatePolygonPerimeter(points);
    
    return {
      'valid': isValid,
      'reason': isValid ? 'Pontos adequados' : 'Qualidade insuficiente',
      'area_hectares': area,
      'perimeter_meters': perimeter,
      'point_count': points.length,
      'average_distance_between_points': _calculateAverageDistanceBetweenPoints(points),
      'area_square_meters': area / _hectaresPerSquareMeter,
    };
  }
  
  /// Calcula distância média entre pontos consecutivos
  double _calculateAverageDistanceBetweenPoints(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }
    
    return totalDistance / (points.length - 1);
  }
  
  /// Converte área de hectares para outras unidades
  Map<String, double> convertArea(double hectares) {
    return {
      'hectares': hectares,
      'square_meters': hectares / _hectaresPerSquareMeter,
      'acres': hectares * 2.47105,
      'square_feet': hectares / _hectaresPerSquareMeter * 10.764,
    };
  }
  
  /// Converte perímetro de metros para outras unidades
  Map<String, double> convertPerimeter(double meters) {
    return {
      'meters': meters,
      'kilometers': meters / 1000.0,
      'feet': meters * 3.28084,
      'yards': meters * 1.09361,
    };
  }
}

/// Extensões para facilitar o uso
extension PreciseAreaCalculationServiceExtensions on PreciseAreaCalculationService {
  /// Obtém qualidade do cálculo baseada nos pontos
  String getCalculationQuality(List<LatLng> points) {
    final stats = getCalculationStatistics(points);
    
    if (!stats['valid']) return 'Inválido';
    
    final pointCount = stats['point_count'] as int;
    final avgDistance = stats['average_distance_between_points'] as double;
    
    if (pointCount >= 10 && avgDistance <= 5.0) return 'Excelente';
    if (pointCount >= 6 && avgDistance <= 10.0) return 'Muito Boa';
    if (pointCount >= 4 && avgDistance <= 20.0) return 'Boa';
    if (pointCount >= 3 && avgDistance <= 50.0) return 'Regular';
    return 'Baixa';
  }
  
  /// Verifica se o cálculo é confiável
  bool isCalculationReliable(List<LatLng> points) {
    final stats = getCalculationStatistics(points);
    return stats['valid'] && (stats['point_count'] as int) >= 4;
  }
}
