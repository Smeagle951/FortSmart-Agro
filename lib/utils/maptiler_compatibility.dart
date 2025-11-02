import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:math' as math;

/// Extensão para adicionar a classe LatLngBounds ao pacote latlong2
extension LatLngBoundsExtension on latlong2.LatLng {
  static latlong2.LatLng fromPoint(Point point) {
    return latlong2.LatLng(point.latitude, point.longitude);
  }
}

/// Classe para representar limites geográficos (retangulares)
class LatLngBounds {
  final latlong2.LatLng southwest;
  final latlong2.LatLng northeast;
  
  const LatLngBounds(this.southwest, this.northeast);
  
  /// Construtor a partir de dois pontos, ordenando-os automaticamente
  factory LatLngBounds.fromPoints(List<latlong2.LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('A lista de pontos não pode estar vazia');
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    return LatLngBounds(
      latlong2.LatLng(minLat, minLng),
      latlong2.LatLng(maxLat, maxLng),
    );
  }
  
  /// Verifica se um ponto está contido nos limites
  bool contains(latlong2.LatLng point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
  
  /// Expande os limites para incluir o ponto especificado
  LatLngBounds extend(latlong2.LatLng point) {
    final swLat = southwest.latitude < point.latitude ? southwest.latitude : point.latitude;
    final swLng = southwest.longitude < point.longitude ? southwest.longitude : point.longitude;
    final neLat = northeast.latitude > point.latitude ? northeast.latitude : point.latitude;
    final neLng = northeast.longitude > point.longitude ? northeast.longitude : point.longitude;
    
    return LatLngBounds(
      latlong2.LatLng(swLat, swLng),
      latlong2.LatLng(neLat, neLng),
    );
  }
}

/// Classe para representar um ponto no mapa
class Point {
  final double latitude;
  final double longitude;
  
  const Point(this.latitude, this.longitude);
  
  /// Converte para o formato LatLng do pacote latlong2
  latlong2.LatLng toLatLng() {
    return latlong2.LatLng(latitude, longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do pacote latlong2
  static Point fromLatLng(latlong2.LatLng latLng) {
    return Point(latLng.latitude, latLng.longitude);
  }
}

/// Enum para unidades de comprimento
enum LengthUnit {
  Meter,
  Kilometer,
  Mile,
}

/// Classe para cálculo de distância entre pontos geográficos
class Distance {
  const Distance();
  
  /// Calcula a distância entre dois pontos em uma unidade específica
  double as(LengthUnit unit, latlong2.LatLng p1, latlong2.LatLng p2) {
    // Implementação da fórmula de Haversine para cálculo de distância
    const double earthRadius = 6378137.0; // Raio da Terra em metros
    
    final double lat1 = p1.latitude * math.pi / 180;
    final double lon1 = p1.longitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lon2 = p2.longitude * math.pi / 180;
    
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                     math.cos(lat1) * math.cos(lat2) *
                     math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c; // Distância em metros
    
    switch (unit) {
      case LengthUnit.Meter:
        return distance;
      case LengthUnit.Kilometer:
        return distance / 1000;
      case LengthUnit.Mile:
        return distance / 1609.344;
      default:
        return distance;
    }
  }
}

/// Extensão para adicionar métodos úteis ao LatLng do pacote latlong2
extension LatLngExtension on latlong2.LatLng {
  /// Calcula a distância entre dois pontos em metros
  double distanceTo(latlong2.LatLng other) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, this, other);
  }
}

