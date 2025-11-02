import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeodeticUtils {
  // Raio da Terra em metros
  static const double earthRadius = 6371000.0;

  // Calcular área de polígono usando fórmula de Shoelace com projeção Web Mercator
  static Future<double> calculatePolygonArea(List<LatLng> vertices) async {
    if (vertices.length < 3) return 0.0;

    try {
      // Converter para coordenadas Web Mercator (EPSG:3857)
      List<Point<double>> mercatorPoints = vertices.map((vertex) {
        return Point<double>(
          longitudeToX(vertex.longitude),
          latitudeToY(vertex.latitude),
        );
      }).toList();

      // Aplicar fórmula de Shoelace
      double area = 0.0;
      for (int i = 0; i < mercatorPoints.length; i++) {
        int j = (i + 1) % mercatorPoints.length;
        area += mercatorPoints[i].x * mercatorPoints[j].y;
        area -= mercatorPoints[j].x * mercatorPoints[i].y;
      }

      // Área em metros quadrados (valor absoluto)
      area = (area.abs() / 2.0);

      return area;
    } catch (e) {
      // Fallback para método simples
      return _calculateAreaSimple(vertices);
    }
  }

  // Calcular perímetro de polígono
  static Future<double> calculatePolygonPerimeter(List<LatLng> vertices) async {
    if (vertices.length < 2) return 0.0;

    try {
      double perimeter = 0.0;
      for (int i = 0; i < vertices.length; i++) {
        int j = (i + 1) % vertices.length;
        perimeter += calculateDistance(vertices[i], vertices[j]);
      }
      return perimeter;
    } catch (e) {
      return 0.0;
    }
  }

  // Calcular distância entre dois pontos usando fórmula de Haversine
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000.0; // Raio da Terra em metros

    final double lat1Rad = point1.latitude * (pi / 180);
    final double lat2Rad = point2.latitude * (pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Converter longitude para coordenada X do Web Mercator
  static double longitudeToX(double longitude) {
    return longitude * (pi / 180) * earthRadius;
  }

  // Converter latitude para coordenada Y do Web Mercator
  static double latitudeToY(double latitude) {
    final double latRad = latitude * (pi / 180);
    return earthRadius * log(tan(pi / 4 + latRad / 2));
  }

  // Método simples de cálculo de área (fallback)
  static double _calculateAreaSimple(List<LatLng> vertices) {
    if (vertices.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      int j = (i + 1) % vertices.length;
      area += vertices[i].longitude * vertices[j].latitude;
      area -= vertices[j].longitude * vertices[i].latitude;
    }
    area = (area.abs() / 2) * 111000 * 111000; // Aproximação para metros quadrados
    return area;
  }

  // Calcular centroide de polígono
  static LatLng calculateCentroid(List<LatLng> vertices) {
    if (vertices.isEmpty) return const LatLng(0, 0);

    double latSum = 0;
    double lngSum = 0;
    for (final vertex in vertices) {
      latSum += vertex.latitude;
      lngSum += vertex.longitude;
    }

    return LatLng(latSum / vertices.length, lngSum / vertices.length);
  }

  /// Calcula área em hectares usando projeção planar e fórmula de Shoelace
  /// CORRIGIDO: Agora usa TODOS os pontos inseridos, não apenas 3 ou 4
  static Future<double> calculateAreaHectares(List<LatLng> points) async {
    if (points.length < 3) return 0.0;
    
    try {
      print('🔄 GeodeticUtils: Calculando área com ${points.length} pontos (TODOS os pontos)');
      
      // Calcular latitude média para projeção
      final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      
      // Fatores de conversão para metros baseados na latitude
      final metersPerDegLat = 111132.954 - 559.822 * cos(2 * avgLat * pi / 180) + 
                             1.175 * cos(4 * avgLat * pi / 180);
      final metersPerDegLng = (pi / 180) * 6378137.0 * cos(avgLat * pi / 180);
      
      // Converter para coordenadas em metros
      final xy = points.map((p) => MapEntry(
        (p.longitude - points.first.longitude) * metersPerDegLng,
        (p.latitude - points.first.latitude) * metersPerDegLat,
      )).toList();
      
      // Aplicar fórmula de Shoelace usando TODOS os pontos
      double sum = 0.0;
      for (int i = 0; i < xy.length - 1; i++) {
        final x1 = xy[i].key;
        final y1 = xy[i].value;
        final x2 = xy[i + 1].key;
        final y2 = xy[i + 1].value;
        sum += (x1 * y2) - (x2 * y1);
      }
      
      // Fechar o polígono
      final x1 = xy.last.key;
      final y1 = xy.last.value;
      final x2 = xy.first.key;
      final y2 = xy.first.value;
      sum += (x1 * y2) - (x2 * y1);
      
      final areaM2 = sum.abs() / 2.0;
      final areaHectares = areaM2 / 10000.0; // Converter para hectares
      
      print('✅ GeodeticUtils: Área calculada: ${areaHectares.toStringAsFixed(2)} ha usando ${points.length} pontos');
      return areaHectares;
    } catch (e) {
      print('❌ GeodeticUtils: Erro ao calcular área: $e');
      return 0.0;
    }
  }

  // Verificar se ponto está dentro do polígono
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) *
                  (point.latitude - polygon[i].latitude) /
                  (polygon[j].latitude - polygon[i].latitude) +
              polygon[i].longitude)) {
        inside = !inside;
      }
    }
    return inside;
  }

  // Simplificar polígono usando algoritmo de Ramer-Douglas-Peucker
  static List<LatLng> simplifyPolygon(List<LatLng> vertices, double tolerance) {
    if (vertices.length <= 2) return vertices;

    // Encontrar o ponto mais distante da linha entre primeiro e último ponto
    double maxDistance = 0;
    int maxIndex = 0;
    LatLng start = vertices.first;
    LatLng end = vertices.last;

    for (int i = 1; i < vertices.length - 1; i++) {
      double distance = _pointToLineDistance(vertices[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // Se a distância máxima é maior que a tolerância, recursivamente simplificar
    if (maxDistance > tolerance) {
      List<LatLng> left = simplifyPolygon(vertices.sublist(0, maxIndex + 1), tolerance);
      List<LatLng> right = simplifyPolygon(vertices.sublist(maxIndex), tolerance);
      
      // Combinar resultados (remover duplicata do meio)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // Retornar apenas os pontos extremos
      return [start, end];
    }
  }

  // Calcular distância de ponto para linha
  static double _pointToLineDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final double A = point.latitude - lineStart.latitude;
    final double B = point.longitude - lineStart.longitude;
    final double C = lineEnd.latitude - lineStart.latitude;
    final double D = lineEnd.longitude - lineStart.longitude;

    final double dot = A * C + B * D;
    final double lenSq = C * C + D * D;
    
    if (lenSq == 0) return calculateDistance(point, lineStart);
    
    final double param = dot / lenSq;
    
    LatLng closestPoint;
    if (param < 0) {
      closestPoint = lineStart;
    } else if (param > 1) {
      closestPoint = lineEnd;
    } else {
      closestPoint = LatLng(
        lineStart.latitude + param * C,
        lineStart.longitude + param * D,
      );
    }
    
    return calculateDistance(point, closestPoint);
  }
}