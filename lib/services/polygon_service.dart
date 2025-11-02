import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class PolygonService {
  /// Calcula área de um polígono em hectares
  static double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    try {
      // Fórmula de Gauss (Shoelace) para área de polígono
      double area = 0.0;
      final n = points.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        area += points[i].longitude * points[j].latitude;
        area -= points[j].longitude * points[i].latitude;
      }
      
      area = area.abs() / 2.0;
      
      // Converter para hectares usando fator de conversão correto
      if (points.isNotEmpty) {
        final latMedia = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
        final latMediaRad = latMedia * math.pi / 180;
        
        // Fatores de conversão corretos para metros
        final metersPerDegLat = 111132.954 - 559.822 * math.cos(2 * latMediaRad) + 
                               1.175 * math.cos(4 * latMediaRad);
        final metersPerDegLng = (math.pi / 180) * 6378137.0 * math.cos(latMediaRad);
        
        // Converter graus² para metros²
        final areaMetersSquared = area * metersPerDegLat * metersPerDegLng;
        
        // Converter metros² para hectares (1 hectare = 10.000 m²)
        return areaMetersSquared / 10000.0;
      }
      
      return 0.0;
      
    } catch (e) {
      print('❌ Erro no cálculo de área: $e');
      return 0.0;
    }
  }
  
  /// Calcula perímetro de um polígono em metros
  static double calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    try {
      double perimeter = 0.0;
      
      // Calcular distância entre pontos consecutivos
      for (int i = 0; i < points.length - 1; i++) {
        perimeter += Geolocator.distanceBetween(
          points[i].latitude,
          points[i].longitude,
          points[i + 1].latitude,
          points[i + 1].longitude,
        );
      }
      
      // Fechar o polígono se necessário
      if (points.length > 2) {
        perimeter += Geolocator.distanceBetween(
          points.last.latitude,
          points.last.longitude,
          points.first.latitude,
          points.first.longitude,
        );
      }
      
      return perimeter;
      
    } catch (e) {
      print('❌ Erro no cálculo de perímetro: $e');
      return 0.0;
    }
  }
  
  /// Calcula distância total percorrida
  static double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    try {
      double total = 0.0;
      
      for (int i = 1; i < points.length; i++) {
        total += Geolocator.distanceBetween(
          points[i - 1].latitude,
          points[i - 1].longitude,
          points[i].latitude,
          points[i].longitude,
        );
      }
      
      return total;
      
    } catch (e) {
      print('❌ Erro no cálculo de distância: $e');
      return 0.0;
    }
  }
  
  /// Fecha um polígono se necessário (auto-snap de 2m)
  static List<LatLng> closePolygonIfNeeded(List<LatLng> points) {
    if (points.length < 3) return points;
    
    final first = points.first;
    final last = points.last;
    
    // Se primeiro e último ponto são diferentes
    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      // Calcular distância entre primeiro e último ponto
      final distance = Geolocator.distanceBetween(
        first.latitude,
        first.longitude,
        last.latitude,
        last.longitude,
      );
      
      // Se a distância for menor que 2 metros, fechar o polígono
      if (distance < 2.0) {
        final closedPoints = List<LatLng>.from(points);
        closedPoints.add(first);
        return closedPoints;
      }
    }
    
    return points;
  }
  
  /// Verifica se um polígono é válido
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Verificar se há pontos duplicados consecutivos
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].latitude == points[i + 1].latitude &&
          points[i].longitude == points[i + 1].longitude) {
        return false;
      }
    }
    
    // Verificar se o primeiro e último ponto são iguais (polígono fechado)
    if (points.first.latitude != points.last.latitude ||
        points.first.longitude != points.last.longitude) {
      return false;
    }
    
    return true;
  }
  
  /// Simplifica um polígono removendo pontos desnecessários
  static List<LatLng> simplifyPolygon(List<LatLng> points, double tolerance) {
    if (points.length < 4) return points;
    
    final simplified = <LatLng>[points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      
      // Calcular distância perpendicular do ponto atual à linha prev-next
      final distance = _perpendicularDistance(current, prev, next);
      
      if (distance > tolerance) {
        simplified.add(current);
      }
    }
    
    simplified.add(points.last);
    return simplified;
  }
  
  /// Calcula a distância perpendicular de um ponto a uma linha
  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final a = lineStart.latitude;
    final b = lineStart.longitude;
    final c = lineEnd.latitude;
    final d = lineEnd.longitude;
    final x = point.latitude;
    final y = point.longitude;
    
    if (c == a && d == b) {
      // Linha é um ponto
      return math.sqrt(math.pow(x - a, 2) + math.pow(y - b, 2));
    }
    
    final double numerator = ((c - a) * (b - y)) - ((a - x) * (d - b));
    final double denominator = math.sqrt(math.pow(c - a, 2) + math.pow(d - b, 2));
    
    return (numerator < 0 ? -numerator : numerator) / denominator;
  }
  
  /// Calcula o centroide de um polígono
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Lista de pontos vazia');
    }
    
    if (points.length == 1) {
      return points.first;
    }
    
    double lat = 0.0;
    double lng = 0.0;
    
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    
    return LatLng(lat / points.length, lng / points.length);
  }
  
  /// Calcula a área de um polígono em metros quadrados
  static double calculateAreaInSquareMeters(List<LatLng> points) {
    return calculateArea(points) * 10000; // Converter hectares para m²
  }
  
  /// Calcula a área de um polígono em quilômetros quadrados
  static double calculateAreaInSquareKilometers(List<LatLng> points) {
    return calculateArea(points) / 100; // Converter hectares para km²
  }
  
  /// Formata a área para exibição
  static String formatArea(double areaHectares) {
    if (areaHectares < 0.01) {
      // Converter para metros quadrados
      final areaM2 = areaHectares * 10000;
      return '${areaM2.toStringAsFixed(0)} m²';
    } else if (areaHectares < 1) {
      return '${areaHectares.toStringAsFixed(2)} ha';
    } else if (areaHectares < 10) {
      return '${areaHectares.toStringAsFixed(1)} ha';
    } else {
      return '${areaHectares.toStringAsFixed(0)} ha';
    }
  }
  
  /// Converte pontos para GeoJSON
  static Map<String, dynamic> toGeoJSON(List<LatLng> points, Map<String, dynamic> properties) {
    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    
    return {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [coordinates]
      },
      "properties": properties,
    };
  }
  
  /// Converte GeoJSON para pontos
  static List<LatLng> fromGeoJSON(Map<String, dynamic> geojson) {
    try {
      final geometry = geojson['geometry'];
      if (geometry['type'] != 'Polygon') {
        throw Exception('Apenas Polygon é suportado');
      }
      
      final coordinates = geometry['coordinates'][0] as List;
      return coordinates.map((coord) {
        return LatLng(coord[1] as double, coord[0] as double);
      }).toList();
      
    } catch (e) {
      print('❌ Erro ao converter GeoJSON: $e');
      return [];
    }
  }

  /// Calcula bounds (limites) de um conjunto de pontos
    static Map<String, LatLng> calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return {
        'southwest': LatLng(0, 0),
        'northeast': LatLng(0, 0),
      };
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return {
      'southwest': LatLng(minLat, minLng),
      'northeast': LatLng(maxLat, maxLng),
    };
  }
}
