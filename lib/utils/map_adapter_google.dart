import 'package:latlong2/latlong.dart';

/// Classe adaptadora para o MapTiler
/// Fornece utilitários para conversão de coordenadas e criação de elementos do mapa
class MapTilerAdapter {
  
  /// Converte coordenadas genéricas para LatLng do latlong2
  static LatLng fromDynamicLatLng(dynamic coordinates) {
    double lat = 0.0;
    double lng = 0.0;
    
    if (coordinates == null) {
      return LatLng(lat, lng);
    }
    
    // Se já for do tipo correto, retorna diretamente
    if (coordinates is LatLng) {
      return coordinates;
    }
    
    try {
      // Tenta acessar as propriedades latitude e longitude
      if (coordinates.latitude != null && coordinates.longitude != null) {
        lat = coordinates.latitude.toDouble();
        lng = coordinates.longitude.toDouble();
      }
    } catch (e) {
      // Se falhar, tenta acessar como um Map
      try {
        if (coordinates is Map) {
          lat = (coordinates['latitude'] ?? 0.0).toDouble();
          lng = (coordinates['longitude'] ?? 0.0).toDouble();
        } else if (coordinates is List && coordinates.length >= 2) {
          // Formato [longitude, latitude] (GeoJSON)
          lng = coordinates[0].toDouble();
          lat = coordinates[1].toDouble();
        }
      } catch (e) {
        print('Erro ao converter coordenadas: $e');
      }
    }
    
    return LatLng(lat, lng);
  }

  /// Converte uma lista de coordenadas genéricas para lista de LatLng
  static List<LatLng> convertCoordinatesList(List<dynamic> coordinates) {
    return coordinates.map((coord) => fromDynamicLatLng(coord)).toList();
  }

  /// Converte LatLng para formato GeoJSON [longitude, latitude]
  static List<double> toGeoJsonCoordinates(LatLng point) {
    return [point.longitude, point.latitude];
  }

  /// Converte lista de LatLng para formato GeoJSON
  static List<List<double>> toGeoJsonCoordinatesList(List<LatLng> points) {
    return points.map((point) => toGeoJsonCoordinates(point)).toList();
  }

  /// Calcula a área de um polígono usando a fórmula de Shoelace
  /// Retorna a área em metros quadrados
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter de graus quadrados para hectares usando fator de conversão correto
    // 1 grau² ≈ 111 km² na latitude média do Brasil
    const double grauParaHectares = 11100000; // 111 km² = 11.100.000 hectares
    area = area * grauParaHectares;
    
    return area;
  }

  /// Calcula a área de um polígono em hectares
  static double calculatePolygonAreaInHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Implementação direta para hectares usando fator de conversão consistente
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares usando fator de conversão correto
    // 1 grau² ≈ 111 km² na latitude média do Brasil
    const double grauParaHectares = 11100000; // 111 km² = 11.100.000 hectares
    return area * grauParaHectares;
  }

  /// Calcula o centro (centróide) de um polígono
  static LatLng calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (var point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  /// Calcula os limites (bounds) de uma lista de pontos
  static MapBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return MapBounds(
        southwest: LatLng(0, 0),
        northeast: LatLng(0, 0),
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (var point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    return MapBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Verifica se um ponto está dentro de um polígono
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    
    bool inside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;
      
      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }

  /// Simplifica uma lista de pontos removendo pontos muito próximos
  static List<LatLng> simplifyPath(List<LatLng> points, {double tolerance = 10.0}) {
    if (points.length <= 2) return points;
    
    List<LatLng> simplified = [points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final distance = calculateDistance(simplified.last, points[i]);
      if (distance > tolerance) {
        simplified.add(points[i]);
      }
    }
    
    simplified.add(points.last);
    return simplified;
  }

  /// Formata área para exibição
  static String formatArea(double areaInSquareMeters) {
    if (areaInSquareMeters < 10000) {
      return '${areaInSquareMeters.toStringAsFixed(1)} m²';
    } else {
      final hectares = areaInSquareMeters / 10000;
      return '${hectares.toStringAsFixed(2)} ha';
    }
  }

  /// Formata distância para exibição
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(1)} m';
    } else {
      final kilometers = distanceInMeters / 1000;
      return '${kilometers.toStringAsFixed(2)} km';
    }
  }

  /// Valida se uma coordenada é válida
  static bool isValidCoordinate(LatLng point) {
    return point.latitude >= -90 && 
           point.latitude <= 90 && 
           point.longitude >= -180 && 
           point.longitude <= 180;
  }

  /// Valida se uma lista de coordenadas forma um polígono válido
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;
    
    return points.every((point) => isValidCoordinate(point));
  }
}

/// Classe para representar os limites de um mapa
class MapBounds {
  final LatLng southwest;
  final LatLng northeast;
  
  const MapBounds({
    required this.southwest,
    required this.northeast,
  });
  
  /// Verifica se um ponto está dentro dos limites
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
  
  /// Calcula o centro dos limites
  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }
  
  /// Expande os limites para incluir um ponto
  MapBounds expand(LatLng point) {
    return MapBounds(
      southwest: LatLng(
        southwest.latitude < point.latitude ? southwest.latitude : point.latitude,
        southwest.longitude < point.longitude ? southwest.longitude : point.longitude,
      ),
      northeast: LatLng(
        northeast.latitude > point.latitude ? northeast.latitude : point.latitude,
        northeast.longitude > point.longitude ? northeast.longitude : point.longitude,
      ),
    );
  }
}

/// Enum para tipos de mapa suportados pelo MapTiler
enum MapTilerStyle {
  /// Mapa básico com ruas
  basic,
  /// Mapa de ruas detalhado
  streets,
  /// Vista de satélite
  satellite,
  /// Vista híbrida (satélite + ruas)
  hybrid,
  /// Mapa topográfico
  topographic,
  /// Mapa em tons de cinza
  grayscale,
}

/// Extensão para converter enum em string
extension MapTilerStyleExtension on MapTilerStyle {
  String get styleId {
    switch (this) {
      case MapTilerStyle.basic:
        return 'basic';
      case MapTilerStyle.streets:
        return 'streets';
      case MapTilerStyle.satellite:
        return 'satellite';
      case MapTilerStyle.hybrid:
        return 'hybrid';
      case MapTilerStyle.topographic:
        return 'topographic';
      case MapTilerStyle.grayscale:
        return 'grayscale';
    }
  }
  
  String get displayName {
    switch (this) {
      case MapTilerStyle.basic:
        return 'Básico';
      case MapTilerStyle.streets:
        return 'Ruas';
      case MapTilerStyle.satellite:
        return 'Satélite';
      case MapTilerStyle.hybrid:
        return 'Híbrido';
      case MapTilerStyle.topographic:
        return 'Topográfico';
      case MapTilerStyle.grayscale:
        return 'Tons de Cinza';
    }
  }
}