import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Calculadora de tiles para mapas offline
class TileCalculator {
  /// Implementação de asinh (arcsinh)
  static double _asinh(double x) {
    return math.log(x + math.sqrt(x * x + 1));
  }

  /// Implementação de sinh
  static double _sinh(double x) {
    return (math.exp(x) - math.exp(-x)) / 2;
  }
  /// Converte coordenadas para tile coordinates
  static Map<String, int> latLngToTile(double lat, double lng, int zoom) {
    final n = math.pow(2, zoom).toDouble();
    final x = ((lng + 180) / 360 * n).floor();
    final y = ((1 - _asinh(math.tan(lat * math.pi / 180)) / math.pi) / 2 * n).floor();
    
    return {
      'x': x,
      'y': y,
      'z': zoom,
    };
  }

  /// Converte tile coordinates para bounding box
  static Map<String, double> tileToBoundingBox(int x, int y, int z) {
    final n = math.pow(2, z).toDouble();
    final lonDeg = x / n * 360.0 - 180.0;
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * y / n)));
    final latDeg = latRad * 180.0 / math.pi;
    
    final lonDeg2 = (x + 1) / n * 360.0 - 180.0;
    final latRad2 = math.atan(_sinh(math.pi * (1 - 2 * (y + 1) / n)));
    final latDeg2 = latRad2 * 180.0 / math.pi;
    
    return {
      'minLng': lonDeg,
      'maxLng': lonDeg2,
      'minLat': latDeg2,
      'maxLat': latDeg,
    };
  }

  /// Calcula tiles necessários para um bounding box
  static List<Map<String, int>> calculateTilesForBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required int zoom,
  }) {
    final minTile = latLngToTile(maxLat, minLng, zoom);
    final maxTile = latLngToTile(minLat, maxLng, zoom);
    
    final tiles = <Map<String, int>>[];
    
    for (int x = minTile['x']!; x <= maxTile['x']!; x++) {
      for (int y = minTile['y']!; y <= maxTile['y']!; y++) {
        tiles.add({
          'x': x,
          'y': y,
          'z': zoom,
        });
      }
    }
    
    return tiles;
  }

  /// Calcula o número total de tiles para um polígono
  static int calculateTotalTiles({
    required List<LatLng> polygon,
    required int zoomMin,
    required int zoomMax,
  }) {
    if (polygon.isEmpty) return 0;
    
    // Calcular bounding box do polígono
    double minLat = polygon.first.latitude;
    double maxLat = polygon.first.latitude;
    double minLng = polygon.first.longitude;
    double maxLng = polygon.first.longitude;
    
    for (final point in polygon) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    int totalTiles = 0;
    
    for (int zoom = zoomMin; zoom <= zoomMax; zoom++) {
      final tiles = calculateTilesForBounds(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        zoom: zoom,
      );
      totalTiles += tiles.length;
    }
    
    return totalTiles;
  }

  /// Calcula o tamanho estimado do download em MB
  static double calculateEstimatedSize({
    required int totalTiles,
    double tileSizeKB = 15.0, // Tamanho médio de um tile em KB
  }) {
    return (totalTiles * tileSizeKB) / 1024; // Converter para MB
  }

  /// Calcula tiles para um polígono específico
  static List<Map<String, int>> calculateTilesForPolygon({
    required List<LatLng> polygon,
    required int zoomMin,
    required int zoomMax,
  }) {
    if (polygon.isEmpty) return [];
    
    final allTiles = <Map<String, int>>[];
    
    for (int zoom = zoomMin; zoom <= zoomMax; zoom++) {
      // Calcular bounding box do polígono
      double minLat = polygon.first.latitude;
      double maxLat = polygon.first.latitude;
      double minLng = polygon.first.longitude;
      double maxLng = polygon.first.longitude;
      
      for (final point in polygon) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
      
      final tiles = calculateTilesForBounds(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        zoom: zoom,
      );
      
      allTiles.addAll(tiles);
    }
    
    return allTiles;
  }

  /// Verifica se um ponto está dentro de um polígono
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

  /// Filtra tiles que estão dentro do polígono
  static List<Map<String, int>> filterTilesInPolygon({
    required List<Map<String, int>> tiles,
    required List<LatLng> polygon,
  }) {
    return tiles.where((tile) {
      final bbox = tileToBoundingBox(tile['x']!, tile['y']!, tile['z']!);
      final center = LatLng(
        (bbox['minLat']! + bbox['maxLat']!) / 2,
        (bbox['minLng']! + bbox['maxLng']!) / 2,
      );
      return isPointInPolygon(center, polygon);
    }).toList();
  }
}
