import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Serviço para cálculos geodésicos precisos de polígonos
/// Usa cálculos baseados na esfera terrestre para máxima precisão
class PolygonMetricsService {
  static const double _earthRadius = 6378137.0; // Raio da Terra em metros (WGS84)
  static const double _pi = math.pi;

  /// Calcula área geodésica em metros quadrados
  /// points: lista de pontos em lat/lng (WGS84)
  /// Retorna área em m²
  static double calculateAreaM2(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    final closed = _ensureClosed(points);
    double area = 0.0;
    
    // Usar fórmula de Gauss para área de polígono
    for (int i = 0; i < closed.length - 1; i++) {
      final p1 = closed[i];
      final p2 = closed[i + 1];
      
      final lat1 = _deg2rad(p1.latitude);
      final lon1 = _deg2rad(p1.longitude);
      final lat2 = _deg2rad(p2.latitude);
      final lon2 = _deg2rad(p2.longitude);
      
      // Fórmula de Gauss para área geodésica
      area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    
    area = area * _earthRadius * _earthRadius / 2.0;
    
    // Garantir que a área seja sempre positiva
    final areaAbs = area.abs();
    
    // Validar se a área faz sentido (não muito pequena nem muito grande)
    if (areaAbs < 0.1) { // Menos de 0.1 m²
      print('⚠️ Área muito pequena calculada: ${areaAbs.toStringAsFixed(6)} m²');
      return 0.0;
    }
    
    if (areaAbs > 1000000000) { // Mais de 1000 km²
      print('⚠️ Área muito grande calculada: ${(areaAbs / 1000000).toStringAsFixed(2)} km²');
      return 0.0;
    }
    
    print('📊 Área calculada: ${(areaAbs / 10000).toStringAsFixed(4)} ha');
    return areaAbs;
  }

  /// Calcula perímetro geodésico em metros
  /// points: lista de pontos em lat/lng (WGS84)
  /// Retorna perímetro em metros
  static double calculatePerimeterM(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    final closed = _ensureClosed(points);
    double perimeter = 0.0;
    
    for (int i = 0; i < closed.length - 1; i++) {
      final p1 = closed[i];
      final p2 = closed[i + 1];
      
      perimeter += _haversineDistance(p1, p2);
    }
    
    return perimeter;
  }

  /// Calcula centroide do polígono
  /// points: lista de pontos em lat/lng (WGS84)
  /// Retorna centroide em lat/lng
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points.first;
    
    final closed = _ensureClosed(points);
    double x = 0.0, y = 0.0, z = 0.0;
    
    for (final point in closed) {
      final lat = _deg2rad(point.latitude);
      final lon = _deg2rad(point.longitude);
      
      x += math.cos(lat) * math.cos(lon);
      y += math.cos(lat) * math.sin(lon);
      z += math.sin(lat);
    }
    
    final total = closed.length.toDouble();
    final lon = math.atan2(y / total, x / total);
    final hyp = math.sqrt((x / total) * (x / total) + (y / total) * (y / total));
    final lat = math.atan2(z / total, hyp);
    
    return LatLng(_rad2deg(lat), _rad2deg(lon));
  }

  /// Calcula área em hectares
  /// points: lista de pontos em lat/lng (WGS84)
  /// Retorna área em hectares
  static double calculateAreaHectares(List<LatLng> points) {
    return calculateAreaM2(points) / 10000.0;
  }

  /// Normaliza lista de pontos (remove duplicados, fecha anel)
  /// points: lista de pontos em lat/lng
  /// Retorna lista normalizada
  static List<LatLng> normalizePoints(List<LatLng> points) {
    if (points.isEmpty) return points;
    
    final normalized = <LatLng>[];
    
    // Remove pontos duplicados consecutivos
    for (final point in points) {
      if (normalized.isEmpty || 
          normalized.last.latitude != point.latitude || 
          normalized.last.longitude != point.longitude) {
        normalized.add(point);
      }
    }
    
    // Fecha o anel se necessário
    if (normalized.length >= 3) {
      final first = normalized.first;
      final last = normalized.last;
      
      if (first.latitude != last.latitude || first.longitude != last.longitude) {
        normalized.add(LatLng(first.latitude, first.longitude));
      }
    }
    
    return normalized;
  }

  /// Valida se o polígono é válido
  /// points: lista de pontos em lat/lng
  /// Retorna true se válido
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;
    
    final normalized = normalizePoints(points);
    if (normalized.length < 3) return false;
    
    // Verifica se não há auto-interseções simples
    for (int i = 0; i < normalized.length - 2; i++) {
      for (int j = i + 2; j < normalized.length - 1; j++) {
        if (_segmentsIntersect(normalized[i], normalized[i + 1], 
                              normalized[j], normalized[j + 1])) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Calcula distância Haversine entre dois pontos
  static double _haversineDistance(LatLng p1, LatLng p2) {
    final lat1 = _deg2rad(p1.latitude);
    final lon1 = _deg2rad(p1.longitude);
    final lat2 = _deg2rad(p2.latitude);
    final lon2 = _deg2rad(p2.longitude);
    
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(lat1) * math.cos(lat2) *
              math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return _earthRadius * c;
  }

  /// Verifica se dois segmentos se intersectam
  static bool _segmentsIntersect(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
    final x1 = p1.longitude, y1 = p1.latitude;
    final x2 = p2.longitude, y2 = p2.latitude;
    final x3 = p3.longitude, y3 = p3.latitude;
    final x4 = p4.longitude, y4 = p4.latitude;
    
    final denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
    if (denom == 0) return false; // Paralelos
    
    final ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;
    final ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;
    
    return ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1;
  }

  /// Garante que a lista de pontos está fechada
  static List<LatLng> _ensureClosed(List<LatLng> points) {
    if (points.isEmpty) return points;
    
    final first = points.first;
    final last = points.last;
    
    if (first.latitude == last.latitude && first.longitude == last.longitude) {
      return points;
    }
    
    return [...points, LatLng(first.latitude, first.longitude)];
  }

  /// Converte graus para radianos
  static double _deg2rad(double degrees) {
    return degrees * _pi / 180.0;
  }

  /// Converte radianos para graus
  static double _rad2deg(double radians) {
    return radians * 180.0 / _pi;
  }

  /// Formata área para exibição
  static String formatArea(double areaM2) {
    if (areaM2 < 10000) {
      return '${areaM2.toStringAsFixed(2)} m²';
    } else {
      final hectares = areaM2 / 10000;
      return '${hectares.toStringAsFixed(2)} ha';
    }
  }

  /// Formata perímetro para exibição
  static String formatPerimeter(double perimeterM) {
    if (perimeterM < 1000) {
      return '${perimeterM.toStringAsFixed(1)} m';
    } else {
      final km = perimeterM / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }
}
