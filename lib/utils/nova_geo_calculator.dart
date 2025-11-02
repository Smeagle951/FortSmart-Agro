import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Calculadora geográfica moderna e precisa para talhões
class NovaGeoCalculator {
  // ===== CONSTANTES =====
  static const double _earthRadius = 6371000.0; // Raio médio da Terra em metros
  static const double _hectareConversion = 10000.0; // Conversão m² para hectares
  static const double _pi = 3.14159265359;

  // ===== CÁLCULOS DE ÁREA =====

  /// Calcula área do polígono usando Shoelace Algorithm + UTM
  /// Retorna área em hectares
  static double calculatePolygonAreaHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    try {
      // Converter pontos para UTM
      List<UtmPoint> utmPoints = points.map((point) => _latLngToUtm(point)).toList();

      // Aplicar Shoelace Algorithm
      double area = 0.0;
      int n = utmPoints.length;
      
      for (int i = 0; i < n; i++) {
        int j = (i + 1) % n;
        area += utmPoints[i].x * utmPoints[j].y;
        area -= utmPoints[j].x * utmPoints[i].y;
      }
      
      // Área em m², converter para hectares
      area = (area.abs() / 2.0) / _hectareConversion;
      
      return area;
    } catch (e) {
      print('❌ Erro ao calcular área: $e');
      return 0.0;
    }
  }

  /// Calcula área do polígono em metros quadrados
  static double calculatePolygonAreaSquareMeters(List<LatLng> points) {
    return calculatePolygonAreaHectares(points) * _hectareConversion;
  }

  // ===== CÁLCULOS DE PERÍMETRO =====

  /// Calcula perímetro do polígono usando Haversine
  /// Retorna perímetro em metros
  static double calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    try {
      double perimeter = 0.0;
      
      for (int i = 0; i < points.length; i++) {
        int nextIndex = (i + 1) % points.length;
        perimeter += haversineDistance(points[i], points[nextIndex]);
      }
      
      return perimeter;
    } catch (e) {
      print('❌ Erro ao calcular perímetro: $e');
      return 0.0;
    }
  }

  // ===== CÁLCULOS DE DISTÂNCIA =====

  /// Calcula distância total percorrida entre pontos consecutivos
  static double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    try {
      double distance = 0.0;
      
      for (int i = 1; i < points.length; i++) {
        distance += haversineDistance(points[i - 1], points[i]);
      }
      
      return distance;
    } catch (e) {
      print('❌ Erro ao calcular distância total: $e');
      return 0.0;
    }
  }

  /// Calcula distância Haversine entre dois pontos
  static double haversineDistance(LatLng point1, LatLng point2) {
    try {
      double lat1Rad = point1.latitude * (_pi / 180.0);
      double lat2Rad = point2.latitude * (_pi / 180.0);
      double deltaLatRad = (point2.latitude - point1.latitude) * (_pi / 180.0);
      double deltaLngRad = (point2.longitude - point1.longitude) * (_pi / 180.0);

      double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
          cos(lat1Rad) * cos(lat2Rad) *
          sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
      
      double c = 2 * asin(sqrt(a));
      
      return _earthRadius * c;
    } catch (e) {
      print('❌ Erro ao calcular distância Haversine: $e');
      return 0.0;
    }
  }

  // ===== CÁLCULOS DE VELOCIDADE =====

  /// Calcula velocidade média em km/h
  static double calculateAverageSpeed(List<LatLng> points, Duration timeElapsed) {
    if (points.length < 2 || timeElapsed.inSeconds == 0) return 0.0;

    try {
      double totalDistance = calculateTotalDistance(points);
      double timeInHours = timeElapsed.inSeconds / 3600.0;
      
      return totalDistance / 1000.0 / timeInHours; // Converter m para km
    } catch (e) {
      print('❌ Erro ao calcular velocidade: $e');
      return 0.0;
    }
  }

  // ===== CÁLCULOS DE CENTRO =====

  /// Calcula centro geométrico do polígono
  static LatLng calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    try {
      double sumLat = 0;
      double sumLng = 0;
      
      for (final point in points) {
        sumLat += point.latitude;
        sumLng += point.longitude;
      }
      
      return LatLng(
        sumLat / points.length,
        sumLng / points.length,
      );
    } catch (e) {
      print('❌ Erro ao calcular centro: $e');
      return const LatLng(0, 0);
    }
  }

  // ===== VALIDAÇÕES =====

  /// Valida se o polígono é válido
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;
    
    try {
      // Verificar se não há pontos duplicados consecutivos
      for (int i = 0; i < points.length; i++) {
        int nextIndex = (i + 1) % points.length;
        if (points[i] == points[nextIndex]) return false;
      }
      
      // Verificar se não é auto-intersectante (simplificado)
      return !_isSelfIntersecting(points);
    } catch (e) {
      print('❌ Erro ao validar polígono: $e');
      return false;
    }
  }

  /// Verifica se o polígono é auto-intersectante (simplificado)
  static bool _isSelfIntersecting(List<LatLng> points) {
    // Implementação simplificada - em produção usar algoritmo mais robusto
    if (points.length < 4) return false;
    
    // Verificar se o primeiro e último pontos são muito próximos
    double distance = haversineDistance(points.first, points.last);
    return distance < 1.0; // Menos de 1 metro
  }

  // ===== CONVERSÕES =====

  /// Converte LatLng para UTM (simplificado)
  static UtmPoint _latLngToUtm(LatLng point) {
    // Implementação simplificada - em produção usar biblioteca UTM
    // Esta é uma aproximação para o Brasil (zona UTM 22S)
    
    const double k0 = 0.9996; // Fator de escala
    const double a = 6378137.0; // Semi-eixo maior do elipsoide WGS84
    const double e2 = 0.00669438; // Primeira excentricidade ao quadrado
    
    double lat = point.latitude * (_pi / 180.0);
    double lng = point.longitude * (_pi / 180.0);
    
    // Zona UTM 22S para o Brasil
    const double lon0 = -51.0 * (_pi / 180.0);
    
    double N = a / sqrt(1 - e2 * sin(lat) * sin(lat));
    double T = tan(lat) * tan(lat);
    double C = e2 * cos(lat) * cos(lat) / (1 - e2);
    double A = cos(lat) * (lng - lon0);
    
    double M = a * ((1 - e2/4 - 3*e2*e2/64 - 5*e2*e2*e2/256) * lat
        - (3*e2/8 + 3*e2*e2/32 + 45*e2*e2*e2/1024) * sin(2*lat)
        + (15*e2*e2/256 + 45*e2*e2*e2/1024) * sin(4*lat)
        - (35*e2*e2*e2/3072) * sin(6*lat));
    
    double x = k0 * N * (A + (1-T+C)*A*A*A/6 + (5-18*T+T*T+72*C-58*0.006739496742)*A*A*A*A*A/120) + 500000;
    double y = k0 * (M + N*tan(lat)*(A*A/2 + (5-T+9*C+4*C*C)*A*A*A*A/24 + (61-58*T+T*T+600*C-330*0.006739496742)*A*A*A*A*A*A/720));
    
    return UtmPoint(x, y);
  }

  // ===== FORMATAÇÃO =====

  /// Formata área em hectares com precisão brasileira
  static String formatAreaHectares(double area) {
    return '${area.toStringAsFixed(2).replaceAll('.', ',')} ha';
  }

  /// Formata perímetro em metros
  static String formatPerimeterMeters(double perimeter) {
    return '${perimeter.toStringAsFixed(0)} m';
  }

  /// Formata distância em metros
  static String formatDistanceMeters(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  /// Formata velocidade em km/h
  static String formatSpeedKmh(double speed) {
    return '${speed.toStringAsFixed(1).replaceAll('.', ',')} km/h';
  }
}

/// Classe para representar ponto UTM
class UtmPoint {
  final double x;
  final double y;

  UtmPoint(this.x, this.y);

  @override
  String toString() => 'UtmPoint(x: $x, y: $y)';
}
