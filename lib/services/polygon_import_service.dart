import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'polygon_service.dart';

class PolygonImportService {

  /// Importa arquivo KML
  Future<List<Map<String, dynamic>>> importKML(File file) async {
    try {
      final content = await file.readAsString();
      final document = XmlDocument.parse(content);
      
      final polygons = <Map<String, dynamic>>[];
      
      // Buscar Placemarks (polígonos)
      final placemarks = document.findAllElements('Placemark');
      
      for (final placemark in placemarks) {
        final polygon = await _parseKMLPlacemark(placemark);
        if (polygon != null) {
          polygons.add(polygon);
        }
      }
      
      print('✅ Importados ${polygons.length} polígonos do KML');
      return polygons;
      
    } catch (e) {
      print('❌ Erro ao importar KML: $e');
      rethrow;
    }
  }

  /// Importa arquivo GeoJSON
  Future<List<Map<String, dynamic>>> importGeoJSON(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      
      final polygons = <Map<String, dynamic>>[];
      
      if (json['type'] == 'FeatureCollection') {
        // FeatureCollection
        final features = json['features'] as List;
        for (final feature in features) {
          final polygon = await _parseGeoJSONFeature(feature);
          if (polygon != null) {
            polygons.add(polygon);
          }
        }
      } else if (json['type'] == 'Feature') {
        // Feature única
        final polygon = await _parseGeoJSONFeature(json);
        if (polygon != null) {
          polygons.add(polygon);
        }
      } else if (json['type'] == 'Polygon') {
        // Polygon direto
        final polygon = await _parseGeoJSONPolygon(json);
        if (polygon != null) {
          polygons.add(polygon);
        }
      }
      
      print('✅ Importados ${polygons.length} polígonos do GeoJSON');
      return polygons;
      
    } catch (e) {
      print('❌ Erro ao importar GeoJSON: $e');
      rethrow;
    }
  }

  /// Seleciona arquivo para importação
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'geojson', 'json'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          return File(path);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao selecionar arquivo: $e');
      return null;
    }
  }

  /// Parse Placemark do KML
  Future<Map<String, dynamic>?> _parseKMLPlacemark(XmlElement placemark) async {
    try {
      // Nome do polígono
      final nameElement = placemark.findElements('name').firstOrNull;
      final name = nameElement?.text ?? 'Polígono Importado';
      
      // Descrição
      final descriptionElement = placemark.findElements('description').firstOrNull;
      final description = descriptionElement?.text ?? '';
      
      // Coordenadas
      final coordinatesElement = placemark.findElements('coordinates').firstOrNull;
      if (coordinatesElement == null) return null;
      
      final coordinates = coordinatesElement.text.trim();
      final points = _parseKMLCoordinates(coordinates);
      
      if (points.length < 3) return null;
      
      // Calcular métricas
      final area = PolygonService.calculateArea(points);
      final perimeter = PolygonService.calculatePerimeter(points);
      
      return {
        'name': name,
        'description': description,
        'points': points,
        'areaHa': area,
        'perimeterM': perimeter,
        'method': 'importado',
        'source': 'kml',
      };
      
    } catch (e) {
      print('❌ Erro ao parsear Placemark: $e');
      return null;
    }
  }

  /// Parse coordenadas KML
  List<LatLng> _parseKMLCoordinates(String coordinates) {
    final points = <LatLng>[];
    final lines = coordinates.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      final parts = trimmed.split(',');
      if (parts.length >= 2) {
        final lon = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        
        if (lon != null && lat != null) {
          points.add(LatLng(lat, lon));
        }
      }
    }
    
    return points;
  }

  /// Parse Feature do GeoJSON
  Future<Map<String, dynamic>?> _parseGeoJSONFeature(Map<String, dynamic> feature) async {
    try {
      final geometry = feature['geometry'];
      final properties = feature['properties'] ?? {};
      
      if (geometry['type'] == 'Polygon') {
        return await _parseGeoJSONPolygon(geometry, properties);
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao parsear Feature: $e');
      return null;
    }
  }

  /// Parse Polygon do GeoJSON
  Future<Map<String, dynamic>?> _parseGeoJSONPolygon(
    Map<String, dynamic> geometry, 
    [Map<String, dynamic> properties = const {}]
  ) async {
    try {
      final coordinates = geometry['coordinates'] as List;
      if (coordinates.isEmpty) return null;
      
      // Primeiro anel (exterior)
      final exteriorRing = coordinates[0] as List;
      final points = <LatLng>[];
      
      for (final coord in exteriorRing) {
        if (coord is List && coord.length >= 2) {
          final lon = coord[0] as double;
          final lat = coord[1] as double;
          points.add(LatLng(lat, lon));
        }
      }
      
      if (points.length < 3) return null;
      
      // Calcular métricas
      final area = PolygonService.calculateArea(points);
      final perimeter = PolygonService.calculatePerimeter(points);
      
      return {
        'name': properties['name'] ?? properties['NAME'] ?? 'Polígono Importado',
        'description': properties['description'] ?? properties['DESCRIPTION'] ?? '',
        'points': points,
        'areaHa': area,
        'perimeterM': perimeter,
        'method': 'importado',
        'source': 'geojson',
        'properties': properties,
      };
      
    } catch (e) {
      print('❌ Erro ao parsear Polygon: $e');
      return null;
    }
  }

  /// Valida arquivo antes da importação
  Future<bool> validateFile(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      
      if (extension == 'kml') {
        final content = await file.readAsString();
        return content.contains('<kml') && content.contains('<Placemark');
      } else if (extension == 'geojson' || extension == 'json') {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return json['type'] != null;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}
