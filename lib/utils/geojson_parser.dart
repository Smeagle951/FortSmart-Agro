import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Classe utilitária para análise de arquivos GeoJSON
class GeoJsonParser {
  /// Analisa um arquivo GeoJSON e extrai as coordenadas do primeiro polígono encontrado
  static Future<List<LatLng>> parseGeoJsonFile(String filePath) async {
    try {
      // Ler o conteúdo do arquivo
      final file = File(filePath);
      if (await file.exists()) {
        final fileContent = await file.readAsString();
        return parseGeoJsonContent(fileContent);
      } else {
        print('Arquivo não encontrado: $filePath');
        return [];
      }
    } catch (e) {
      print('Erro ao analisar arquivo GeoJSON: $e');
      return [];
    }
  }

  /// Analisa o conteúdo de uma string GeoJSON
  static List<LatLng> parseGeoJsonContent(String content) {
    try {
      final jsonData = jsonDecode(content);
      final coordinates = _extractCoordinates(jsonData);
      
      // Converter para lista de LatLng
      return coordinates.map((coord) {
        // GeoJSON usa [longitude, latitude], LatLng usa (latitude, longitude)
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();
    } catch (e) {
      print('Erro ao analisar conteúdo GeoJSON: $e');
      return [];
    }
  }

  /// Extrai coordenadas de um objeto GeoJSON
  static List<List<dynamic>> _extractCoordinates(dynamic jsonData) {
    if (jsonData is Map) {
      // Verificar se é um FeatureCollection
      if (jsonData['type'] == 'FeatureCollection') {
        final features = jsonData['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          // Retornar as coordenadas do primeiro recurso com geometria
          for (final feature in features) {
            final coordinates = _extractCoordinatesFromFeature(feature);
            if (coordinates.isNotEmpty) {
              return coordinates;
            }
          }
        }
      }
      // Verificar se é um Feature
      else if (jsonData['type'] == 'Feature') {
        return _extractCoordinatesFromFeature(jsonData);
      }
      // Verificar se é uma Geometry
      else if (jsonData['type'] != null) {
        return _extractCoordinatesFromGeometry(jsonData);
      }
    }
    return [];
  }

  /// Extrai coordenadas de um recurso (feature) GeoJSON
  static List<List<dynamic>> _extractCoordinatesFromFeature(dynamic feature) {
    if (feature is Map && feature['geometry'] != null) {
      return _extractCoordinatesFromGeometry(feature['geometry']);
    }
    return [];
  }

  /// Extrai coordenadas de uma geometria GeoJSON
  static List<List<dynamic>> _extractCoordinatesFromGeometry(dynamic geometry) {
    if (geometry is! Map) return [];
    final type = geometry['type'] as String?;
    final coordinates = geometry['coordinates'];
    
    if (coordinates == null || type == null) return [];

    switch (type) {
      case 'Point':
        return [List<dynamic>.from(coordinates as List)];
      case 'LineString':
        return List<List<dynamic>>.from(coordinates as List);
      case 'Polygon':
        // Um polígono tem uma lista de anéis, onde o primeiro é o anel externo
        final rings = coordinates as List;
        return rings.isNotEmpty ? List<List<dynamic>>.from(rings.first) : [];
      case 'MultiPoint':
      case 'MultiLineString':
      case 'MultiPolygon':
        // Para geometrias múltiplas, retornamos o primeiro elemento
        final firstElement = (coordinates as List).first;
        if (firstElement is List) {
          return _extractCoordinatesFromGeometry({
            'type': type.replaceAll('Multi', ''),
            'coordinates': firstElement,
          });
        }
        break;
      case 'GeometryCollection':
        // Para coleções de geometrias, retornamos a primeira geometria não vazia
        final geometries = geometry['geometries'] as List?;
        if (geometries != null) {
          for (final geom in geometries) {
            final coords = _extractCoordinatesFromGeometry(geom);
            if (coords.isNotEmpty) {
              return coords;
            }
          }
        }
        break;
    }
    
    return [];
  }

  /// Calcula o centroide de uma lista de coordenadas
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(0, 0);
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  /// Calcula a área de um polígono em metros quadrados (usando a fórmula de Haversine)
  static double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Fechar o polígono se necessário
    final closedPoints = List<LatLng>.from(points);
    if (closedPoints.first != closedPoints.last) {
      closedPoints.add(closedPoints.first);
    }
    
    double area = 0.0;
    final earthRadius = 6378137.0; // Raio da Terra em metros
    
    for (int i = 0; i < closedPoints.length - 1; i++) {
      final p1 = closedPoints[i];
      final p2 = closedPoints[i + 1];
      
      final lat1 = p1.latitude * math.pi / 180;
      final lng1 = p1.longitude * math.pi / 180;
      final lat2 = p2.latitude * math.pi / 180;
      final lng2 = p2.longitude * math.pi / 180;
      
      area += (lng2 - lng1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    
    area = area * earthRadius * earthRadius / 2;
    return area.abs();
  }
}
