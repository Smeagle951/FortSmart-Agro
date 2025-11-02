import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'precise_geo_calculator.dart';

/// Classe para pontos 3D
class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);
}

/// Serviço avançado para cálculos geodésicos de subáreas
/// Integra com o sistema de talhões do FortSmart Agro
/// Implementa cálculos precisos para modo desenho e modo GPS
class SubareaGeodeticService {
  // Constantes geodésicas (WGS84)
  static const double _earthRadiusMeters = 6378137.0;
  static const double _earthRadiusMean = 6371000.0; // Raio médio da Terra para Haversine

  /// Calcula área em hectares usando o método preciso dos talhões
  static double calculateAreaHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    try {
      // Usar o mesmo método preciso dos talhões para consistência
      return PreciseGeoCalculator.calculatePolygonAreaHectares(points);
    } catch (e) {
      debugPrint('❌ Erro no cálculo preciso de área: $e');
      return _calculateAreaFallback(points);
    }
  }

  /// Calcula área para modo DESENHO (coordenadas planas)
  /// Usa projeção Web Mercator e fórmula de Shoelace/Gauss
  static double calculateAreaDrawingMode(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    try {
      // Converter coordenadas geodésicas para coordenadas planas (Web Mercator EPSG:3857)
      final projectedPoints = _projectToWebMercator(points);
      
      // Aplicar fórmula de Shoelace/Gauss
      final areaM2 = _calculateShoelaceArea(projectedPoints);
      
      // Converter para hectares
      return areaM2 / 10000.0;
    } catch (e) {
      debugPrint('❌ Erro no cálculo de área (modo desenho): $e');
      return _calculateAreaFallback(points);
    }
  }

  /// Calcula área para modo GPS (coordenadas geodésicas)
  /// Usa fórmula de Haversine e área esférica
  static double calculateAreaGPSMode(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    try {
      // Usar método esférico para coordenadas geodésicas
      return _calculateSphericalArea(points);
    } catch (e) {
      debugPrint('❌ Erro no cálculo de área (modo GPS): $e');
      return _calculateAreaFallback(points);
    }
  }

  /// Calcula perímetro em metros usando o método preciso dos talhões
  static double calculatePerimeterMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    try {
      // Usar o mesmo método preciso dos talhões
      return PreciseGeoCalculator.calculatePolygonPerimeter(points);
    } catch (e) {
      debugPrint('❌ Erro no cálculo preciso de perímetro: $e');
      return _calculatePerimeterFallback(points);
    }
  }

  /// Calcula perímetro para modo DESENHO (coordenadas planas)
  /// Usa distância euclidiana em coordenadas projetadas
  static double calculatePerimeterDrawingMode(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    try {
      // Converter para coordenadas planas
      final projectedPoints = _projectToWebMercator(points);
      
      // Calcular perímetro usando distância euclidiana
      double perimeter = 0.0;
      for (int i = 0; i < projectedPoints.length; i++) {
        final current = projectedPoints[i];
        final next = projectedPoints[(i + 1) % projectedPoints.length];
        
        final dx = next.x - current.x;
        final dy = next.y - current.y;
        perimeter += sqrt(dx * dx + dy * dy);
      }
      
      return perimeter;
    } catch (e) {
      debugPrint('❌ Erro no cálculo de perímetro (modo desenho): $e');
      return _calculatePerimeterFallback(points);
    }
  }

  /// Calcula perímetro para modo GPS (coordenadas geodésicas)
  /// Usa fórmula de Haversine para distâncias geodésicas
  static double calculatePerimeterGPSMode(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    try {
      double perimeter = 0.0;
      for (int i = 0; i < points.length; i++) {
        final current = points[i];
        final next = points[(i + 1) % points.length];
        
        perimeter += _calculateHaversineDistance(current, next);
      }
      
      return perimeter;
    } catch (e) {
      debugPrint('❌ Erro no cálculo de perímetro (modo GPS): $e');
      return _calculatePerimeterFallback(points);
    }
  }

  /// Calcula métricas completas da subárea
  static Map<String, double> calculatePreciseMetrics(List<LatLng> points) {
    try {
      return PreciseGeoCalculator.calculatePreciseMetrics(points);
    } catch (e) {
      debugPrint('❌ Erro no cálculo de métricas precisas: $e');
      return _calculateMetricsFallback(points);
    }
  }

  /// Calcula centroide geodésico preciso
  static LatLng calculateGeodeticCentroid(List<LatLng> points) {
    try {
      return PreciseGeoCalculator.calculateGeodeticCentroid(points);
    } catch (e) {
      debugPrint('❌ Erro no cálculo de centroide: $e');
      return _calculateSimpleCentroid(points);
    }
  }

  /// Verifica se um ponto está dentro de um polígono
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    try {
      // Usar método de fallback pois PreciseGeoCalculator.isPointInPolygon pode não existir
      return _isPointInPolygonFallback(point, polygon);
    } catch (e) {
      debugPrint('❌ Erro na verificação de ponto em polígono: $e');
      return _isPointInPolygonFallback(point, polygon);
    }
  }

  /// Valida se um polígono é válido
  static bool isValidPolygon(List<LatLng> points) {
    try {
      return PreciseGeoCalculator.isValidPolygon(points);
    } catch (e) {
      debugPrint('❌ Erro na validação de polígono: $e');
      return _validatePolygonFallback(points);
    }
  }

  /// Verifica se uma subárea está completamente dentro de um talhão
  static bool isSubareaInsideTalhao(List<LatLng> subareaPoints, List<LatLng> talhaoPoints) {
    if (subareaPoints.isEmpty || talhaoPoints.isEmpty) return false;

    // Verificar se todos os pontos da subárea estão dentro do talhão
    for (final point in subareaPoints) {
      if (!isPointInPolygon(point, talhaoPoints)) {
        return false;
      }
    }

    return true;
  }

  /// Calcula distância entre dois pontos usando Haversine
  static double calculateDistance(LatLng point1, LatLng point2) {
    return _calculateHaversineDistance(point1, point2);
  }

  /// Simplifica pontos GPS para reduzir ruído
  static List<LatLng> simplifyPoints(List<LatLng> points, double toleranceMeters) {
    if (points.length <= 2) return points;

    return _douglasPeucker(points, toleranceMeters);
  }

  /// Aplica filtro de Kalman para suavizar ruídos do GPS
  /// Melhora precisão para modo GPS por caminhada/trator
  static List<LatLng> applyKalmanFilter(List<LatLng> points, {
    double processNoise = 0.01,
    double measurementNoise = 1.0,
  }) {
    if (points.length < 2) return points;

    final filteredPoints = <LatLng>[];
    
    // Estado inicial (posição e velocidade)
    double lat = points.first.latitude;
    double lng = points.first.longitude;
    double latVel = 0.0;
    double lngVel = 0.0;
    
    // Matrizes de covariância
    double pLat = 1.0;
    double pLng = 1.0;
    double pLatVel = 1.0;
    double pLngVel = 1.0;

    for (final point in points) {
      // Predição (estado anterior + velocidade)
      lat += latVel;
      lng += lngVel;
      
      // Atualização da covariância
      pLat += processNoise;
      pLng += processNoise;
      
      // Correção (Kalman gain)
      final kLat = pLat / (pLat + measurementNoise);
      final kLng = pLng / (pLng + measurementNoise);
      
      // Atualização do estado
      lat += kLat * (point.latitude - lat);
      lng += kLng * (point.longitude - lng);
      
      // Atualização da covariância
      pLat *= (1 - kLat);
      pLng *= (1 - kLng);
      
      // Atualização da velocidade
      latVel = (point.latitude - lat) * 0.1;
      lngVel = (point.longitude - lng) * 0.1;
      
      filteredPoints.add(LatLng(lat, lng));
    }
    
    return filteredPoints;
  }

  /// Aplica média móvel para suavizar pontos GPS
  static List<LatLng> applyMovingAverage(List<LatLng> points, {int windowSize = 3}) {
    if (points.length < windowSize) return points;
    
    final smoothedPoints = <LatLng>[];
    
    for (int i = 0; i < points.length; i++) {
      int start = (i - windowSize ~/ 2).clamp(0, points.length - windowSize);
      int end = (start + windowSize).clamp(windowSize, points.length);
      
      double latSum = 0.0;
      double lngSum = 0.0;
      
      for (int j = start; j < end; j++) {
        latSum += points[j].latitude;
        lngSum += points[j].longitude;
      }
      
      smoothedPoints.add(LatLng(
        latSum / (end - start),
        lngSum / (end - start),
      ));
    }
    
    return smoothedPoints;
  }

  /// Valida precisão GPS dos pontos
  /// Retorna pontos com precisão aceitável (HDOP/PDOP)
  static List<LatLng> validateGPSAccuracy(List<LatLng> points, {
    double maxAccuracyMeters = 5.0,
    double minDistanceMeters = 1.0,
  }) {
    if (points.isEmpty) return points;
    
    final validPoints = <LatLng>[points.first];
    
    for (int i = 1; i < points.length; i++) {
      final currentPoint = points[i];
      final lastValidPoint = validPoints.last;
      
      // Verificar distância mínima
      final distance = _calculateHaversineDistance(lastValidPoint, currentPoint);
      if (distance < minDistanceMeters) continue;
      
      // Verificar precisão (simulado - em implementação real, usar HDOP/PDOP)
      final accuracy = _estimateGPSAccuracy(currentPoint, lastValidPoint);
      if (accuracy <= maxAccuracyMeters) {
        validPoints.add(currentPoint);
      }
    }
    
    return validPoints;
  }

  /// Estima precisão GPS baseada na variação entre pontos
  /// Em implementação real, usar dados de HDOP/PDOP do GPS
  static double _estimateGPSAccuracy(LatLng point1, LatLng point2) {
    // Simulação de precisão baseada na distância
    final distance = _calculateHaversineDistance(point1, point2);
    
    // Precisão simulada: 1-5 metros baseado na distância
    if (distance < 10) return 1.0 + (distance * 0.4);
    return 5.0;
  }

  /// Filtra pontos GPS por precisão
  static List<LatLng> filterPointsByAccuracy(List<LatLng> points, double maxAccuracyMeters) {
    if (points.isEmpty) return points;

    final filtered = <LatLng>[points.first];

    for (int i = 1; i < points.length; i++) {
      final distance = _calculateHaversineDistance(points[i - 1], points[i]);

      // Se a distância for menor que a precisão máxima, considerar como ruído
      if (distance >= maxAccuracyMeters) {
        filtered.add(points[i]);
      }
    }

    return filtered;
  }

  /// Calcula área de sobreposição entre duas subáreas
  static double calculateOverlapArea(List<LatLng> subarea1, List<LatLng> subarea2) {
    // Implementação simplificada - verificar pontos em comum
    int pointsInside = 0;
    for (final point in subarea1) {
      if (isPointInPolygon(point, subarea2)) {
        pointsInside++;
      }
    }

    if (pointsInside == 0) return 0.0;

    // Estimativa baseada na proporção de pontos
    final ratio = pointsInside / subarea1.length;
    return calculateAreaHectares(subarea1) * ratio;
  }

  /// Verifica se duas subáreas se sobrepõem
  static bool hasOverlap(List<LatLng> subarea1, List<LatLng> subarea2) {
    // Verificar se algum ponto de uma está dentro da outra
    for (final point in subarea1) {
      if (isPointInPolygon(point, subarea2)) return true;
    }
    
    for (final point in subarea2) {
      if (isPointInPolygon(point, subarea1)) return true;
    }
    
    return false;
  }

  /// Formata área no padrão brasileiro
  static String formatAreaBrazilian(double areaHectares, {int decimals = 2}) {
    return PreciseGeoCalculator.formatAreaBrazilian(areaHectares, decimals: decimals);
  }

  /// Formata perímetro no padrão brasileiro
  static String formatPerimeterBrazilian(double perimeterMeters, {int decimals = 1}) {
    return PreciseGeoCalculator.formatPerimeterBrazilian(perimeterMeters, decimals: decimals);
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Fórmula Haversine para distância entre dois pontos geodésicos
  /// d = 2R * arcsin(sqrt(sin²(Δφ/2) + cos(φ1) * cos(φ2) * sin²(Δλ/2)))
  static double _calculateHaversineDistance(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    final sinDeltaLat = sin(deltaLatRad / 2);
    final sinDeltaLng = sin(deltaLngRad / 2);
    
    final a = sinDeltaLat * sinDeltaLat +
        cos(lat1Rad) * cos(lat2Rad) * sinDeltaLng * sinDeltaLng;

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMean * c;
  }

  /// Projeta coordenadas geodésicas para Web Mercator (EPSG:3857)
  /// Usado no modo desenho para cálculos em coordenadas planas
  static List<Point<double>> _projectToWebMercator(List<LatLng> points) {
    return points.map((point) {
      final x = point.longitude * _earthRadiusMeters * pi / 180.0;
      final y = log(tan(pi / 4.0 + point.latitude * pi / 360.0)) * _earthRadiusMeters;
      return Point<double>(x, y);
    }).toList();
  }

  /// Fórmula de Shoelace/Gauss para área em coordenadas planas
  /// A = 1/2 * |Σ(xi * yi+1 - xi+1 * yi)|
  static double _calculateShoelaceArea(List<Point<double>> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }

    return area.abs() / 2.0;
  }

  /// Calcula área esférica usando método de excesso esférico
  /// Para coordenadas geodésicas (modo GPS)
  static double _calculateSphericalArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Converter para radianos
    final radianPoints = points.map((p) => Point3D(
      p.longitude * pi / 180.0,
      p.latitude * pi / 180.0,
      0.0, // z = 0 para pontos na superfície
    )).toList();

    // Calcular excesso esférico
    double excess = 0.0;
    final n = radianPoints.length;

    for (int i = 0; i < n; i++) {
      final prev = radianPoints[(i - 1 + n) % n];
      final curr = radianPoints[i];
      final next = radianPoints[(i + 1) % n];

      // Calcular ângulo interno usando produto escalar
      final angle = _calculateSphericalAngle(prev, curr, next);
      excess += angle;
    }

    // Aplicar fórmula: A = R² * (Σθ - (n-2)π)
    excess -= (n - 2) * pi;
    return _earthRadiusMean * _earthRadiusMean * excess.abs();
  }

  /// Calcula ângulo esférico entre três pontos
  static double _calculateSphericalAngle(Point3D prev, Point3D curr, Point3D next) {
    // Vetores tangentes
    final v1 = _sphericalTangent(prev, curr);
    final v2 = _sphericalTangent(curr, next);

    // Produto escalar
    final dot = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
    
    // Produto vetorial
    final cross = Point3D(
      v1.y * v2.z - v1.z * v2.y,
      v1.z * v2.x - v1.x * v2.z,
      v1.x * v2.y - v1.y * v2.x,
    );

    final crossMagnitude = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z);
    
    return atan2(crossMagnitude, dot);
  }

  /// Calcula vetor tangente esférico entre dois pontos
  static Point3D _sphericalTangent(Point3D from, Point3D to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    
    // Normalizar
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return const Point3D(0, 0, 0);
    
    return Point3D(dx / length, dy / length, 0);
  }

  /// Método de fallback para cálculo de área
  static double _calculateAreaFallback(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }

    area = area.abs() / 2.0;

    // Conversão para hectares
    if (points.isNotEmpty) {
      final latMedia = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final latMediaRad = latMedia * pi / 180;

      final metersPerDegLat = 111132.954 - 559.822 * cos(2 * latMediaRad) +
          1.175 * cos(4 * latMediaRad);
      final metersPerDegLng = (pi / 180) * _earthRadiusMeters * cos(latMediaRad);

      final areaMetersSquared = area * metersPerDegLat * metersPerDegLng;
      return areaMetersSquared / 10000.0; // Converter para hectares
    }

    return 0.0;
  }

  /// Método de fallback para cálculo de perímetro
  static double _calculatePerimeterFallback(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      perimeter += _calculateHaversineDistance(points[i], points[j]);
    }

    return perimeter;
  }

  /// Método de fallback para métricas completas
  static Map<String, double> _calculateMetricsFallback(List<LatLng> points) {
    return {
      'area': _calculateAreaFallback(points),
      'perimeter': _calculatePerimeterFallback(points),
      'centroid_lat': _calculateSimpleCentroid(points).latitude,
      'centroid_lng': _calculateSimpleCentroid(points).longitude,
      'max_distance': 0.0,
      'compactness': 0.0,
      'area_gauss': _calculateAreaFallback(points),
      'area_lambert': _calculateAreaFallback(points),
    };
  }

  /// Calcula centroide simples (fallback)
  static LatLng _calculateSimpleCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final avgLon = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    return LatLng(avgLat, avgLon);
  }

  /// Verificação de ponto em polígono (fallback)
  static bool _isPointInPolygonFallback(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) *
               (point.latitude - polygon[i].latitude) /
               (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Validação de polígono (fallback)
  static bool _validatePolygonFallback(List<LatLng> points) {
    if (points.length < 3) return false;

    // Verificar se não há pontos duplicados consecutivos
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].latitude == points[i + 1].latitude &&
          points[i].longitude == points[i + 1].longitude) {
        return false;
      }
    }

    // Verificar se o primeiro e último ponto são diferentes
    if (points.first.latitude == points.last.latitude &&
        points.first.longitude == points.last.longitude) {
      return false;
    }

    return true;
  }

  /// Algoritmo Ramer-Douglas-Peucker para simplificação
  static List<LatLng> _douglasPeucker(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    double maxDistance = 0;
    int maxIndex = 0;
    LatLng start = points.first;
    LatLng end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _pointToLineDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance > tolerance) {
      List<LatLng> left = _douglasPeucker(points.sublist(0, maxIndex + 1), tolerance);
      List<LatLng> right = _douglasPeucker(points.sublist(maxIndex), tolerance);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  /// Calcula distância perpendicular de um ponto a um segmento de linha
  static double _pointToLineDistance(LatLng p, LatLng a, LatLng b) {
    if (a == b) return _calculateHaversineDistance(p, a);

    final double lengthSq = pow(_calculateHaversineDistance(a, b), 2).toDouble();
    final double t = ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
        (p.longitude - a.longitude) * (b.longitude - a.longitude)) / lengthSq;

    if (t < 0.0) return _calculateHaversineDistance(p, a);
    if (t > 1.0) return _calculateHaversineDistance(p, b);

    final LatLng projection = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
    return _calculateHaversineDistance(p, projection);
  }
}
