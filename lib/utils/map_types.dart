import 'dart:math' as math;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/src/geo/latlng_bounds.dart' as flutter_map_bounds;
// Importar o adapter para usar suas classes
import 'map_global_adapter.dart' as adapter;

/// Classe para representar um ponto de latitude e longitude
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  /// Converte para o formato LatLng do pacote latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }

  /// Cria uma instância a partir do formato LatLng do pacote latlong2
  static LatLng fromLatLong2(latlong2.LatLng latLng) {
    return LatLng(latLng.latitude, latLng.longitude);
  }

  @override
  String toString() => 'LatLng(latitude: $latitude, longitude: $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
           other.latitude == latitude &&
           other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Classe para representar limites geográficos (retangulares)
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;
  
  // Construtor padrão
  const LatLngBounds({required this.southwest, required this.northeast});
  
  // Construtor interno removido, usando apenas o construtor padrão
  
  /// Construtor a partir de dois pontos, ordenando-os automaticamente
  factory LatLngBounds.fromTwoPoints(LatLng point1, LatLng point2) {
    final swLat = math.min(point1.latitude, point2.latitude);
    final swLng = math.min(point1.longitude, point2.longitude);
    final neLat = math.max(point1.latitude, point2.latitude);
    final neLng = math.max(point1.longitude, point2.longitude);
    
    // Usar o construtor padrão
    return LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );
  }
  
  /// Cria limites a partir de dois pontos usando o adapter
  static adapter.LatLngBounds fromTwoPointsAdapter(LatLng point1, LatLng point2) {
    final swLat = math.min(point1.latitude, point2.latitude);
    final swLng = math.min(point1.longitude, point2.longitude);
    final neLat = math.max(point1.latitude, point2.latitude);
    final neLng = math.max(point1.longitude, point2.longitude);
    
    // Usar o adapter
    return adapter.LatLngBounds(
      southwest: adapter.LatLng(swLat, swLng),
      northeast: adapter.LatLng(neLat, neLng),
    );
  }
  
  /// Converte para o formato LatLngBounds do adapter
  adapter.LatLngBounds toAdapterBounds() {
    return adapter.LatLngBounds(
      southwest: adapter.LatLng(southwest.latitude, southwest.longitude),
      northeast: adapter.LatLng(northeast.latitude, northeast.longitude),
    );
  }
  
  /// Verifica se um ponto está contido nos limites
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
  
  /// Expande os limites para incluir o ponto especificado
  LatLngBounds extend(LatLng point) {
    // Criar um novo bounds que inclui o ponto
    return LatLngBounds.fromTwoPoints(
      LatLng(
        math.min(southwest.latitude, point.latitude),
        math.min(southwest.longitude, point.longitude),
      ),
      LatLng(
        math.max(northeast.latitude, point.latitude),
        math.max(northeast.longitude, point.longitude),
      ),
    );
  }

  /// Cria limites a partir de uma lista de pontos
  static LatLngBounds fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('A lista de pontos não pode estar vazia');
    }

    // Inicializa com os valores do primeiro ponto
    double minLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLat = points[0].latitude;
    double maxLng = points[0].longitude;

    // Encontra os valores mínimos e máximos
    for (var point in points) {
      minLat = math.min(minLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLat = math.max(maxLat, point.latitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Criar um novo bounds com os valores encontrados
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Retorna os pontos sudoeste e nordeste como objetos latlong2.LatLng
  /// para serem usados na criação de um latlong2.LatLngBounds
  List<latlong2.LatLng> toLatLong2Points() {
    return [
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    ];
  }
  
  /// Converte para o formato LatLngBounds do flutter_map
  flutter_map_bounds.LatLngBounds toLatLong2Bounds() {
    return flutter_map_bounds.LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }
  
  /// Cria uma instância a partir do formato LatLngBounds do flutter_map
  static LatLngBounds fromLatLong2Bounds(flutter_map_bounds.LatLngBounds bounds) {
    return LatLngBounds(
      southwest: LatLng.fromLatLong2(bounds.southWest ?? latlong2.LatLng(0, 0)),
      northeast: LatLng.fromLatLong2(bounds.northEast ?? latlong2.LatLng(0, 0)),
    );
  }

  /// Obtém o centro dos limites
  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }
}

/// Classe para representar uma posição de câmera
class CameraPosition {
  final LatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  const CameraPosition({
    required this.target,
    this.zoom = 15.0,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });
}

/// Classe abstrata para atualizações de câmera
abstract class CameraUpdate {
  /// Construtor padrão
  const CameraUpdate();
  
  /// Obtém o valor interno da atualização para compatibilidade
  dynamic get value => this;
  
  /// Cria uma atualização de câmera para uma nova posição
  static CameraUpdate newLatLng(LatLng latLng) {
    return CameraUpdateMove(latLng, 15.0);
  }
  
  /// Cria uma atualização de câmera para uma nova posição e zoom
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdateMove(latLng, zoom);
  }
  
  /// Cria uma atualização de câmera para ajustar aos limites
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, [double padding = 50.0]) {
    return CameraUpdateBounds(bounds, padding);
  }
}

/// Classe para representar uma atualização de câmera para uma nova posição
class CameraUpdateMove extends CameraUpdate {
  final LatLng latLng;
  final double zoom;
  
  const CameraUpdateMove(this.latLng, this.zoom);
  
  /// Getter para compatibilidade com código existente
  LatLng get target => latLng;
}

/// Classe para representar uma atualização de câmera para ajustar aos limites
class CameraUpdateBounds extends CameraUpdate {
  final LatLngBounds bounds;
  final double padding;
  
  const CameraUpdateBounds(this.bounds, this.padding);
}

// A classe CameraUpdateFactory foi removida pois seus métodos já estão na classe CameraUpdate

/// Classe para representar uma coordenada na tela
class ScreenCoordinate {
  final double x;
  final double y;
  
  const ScreenCoordinate({required this.x, required this.y});
}

/// Enumerador para o tipo de mapa
enum MapType {
  normal,
  satellite,
  terrain,
  hybrid,
  none,
}

/// Utilitários para cálculos geográficos
class GeoUtils {
  /// Calcula a área de um polígono em hectares
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    
    // Implementação da fórmula de Shoelace (Gauss's area formula)
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() * 0.5;
    
    // Converter para metros quadrados e depois para hectares
    // Aproximação usando o fator de conversão para graus na latitude média
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final latFactor = 111320; // metros por grau de latitude
    final lngFactor = 111320 * math.cos(avgLat * math.pi / 180); // metros por grau de longitude
    
    final areaInSquareMeters = area * latFactor * lngFactor;
    final areaInHectares = areaInSquareMeters / 10000; // 1 hectare = 10,000 m²
    
    return areaInHectares;
  }
  
  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(LatLng p1, LatLng p2) {
    // Implementação da fórmula de Haversine
    const double earthRadius = 6371000; // em metros
    
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(lat1) * math.cos(lat2) *
              math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
}

