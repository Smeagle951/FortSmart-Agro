import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart' as latlong2;

class GeoJsonParser {
  /// Parseia um arquivo GeoJSON e retorna uma lista de coordenadas
  Future<List<latlong2.LatLng>> parseGeoJsonFile(String filePath) async {
    try {
      // Verifica se o arquivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }

      // Lê o conteúdo do arquivo
      final content = await file.readAsString();
      
      // Decodifica o JSON
      final Map<String, dynamic> jsonData = jsonDecode(content);
      
      // Lista para armazenar as coordenadas
      final List<latlong2.LatLng> coordinates = [];
      
      // Verifica se é um GeoJSON válido
      if (jsonData['type'] != 'FeatureCollection' && 
          jsonData['type'] != 'Feature' && 
          jsonData['type'] != 'Geometry') {
        throw Exception('Formato GeoJSON inválido');
      }
      
      // Função para processar coordenadas de um recurso
      void processCoordinates(List<dynamic> coords) {
        // Verifica se é um polígono (array de anéis de coordenadas)
        if (coords.isNotEmpty && coords[0] is List) {
          // Para polígonos, pega apenas o anel externo
          final List<dynamic> ring = coords[0];
          for (final coord in ring) {
            if (coord is List && coord.length >= 2) {
              final lng = coord[0]?.toDouble() ?? 0.0;
              final lat = coord[1]?.toDouble() ?? 0.0;
              coordinates.add(latlong2.LatLng(lat, lng));
            }
          }
        } 
        // Verifica se é uma linha ou ponto
        else if (coords.length >= 2) {
          final lng = coords[0]?.toDouble() ?? 0.0;
          final lat = coords[1]?.toDouble() ?? 0.0;
          coordinates.add(latlong2.LatLng(lat, lng));
        }
      }
      
      // Processa os recursos do GeoJSON
      if (jsonData['type'] == 'FeatureCollection') {
        final features = jsonData['features'] as List? ?? [];
        for (final feature in features) {
          final geometry = feature['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            _processGeometry(geometry, processCoordinates);
          }
        }
      } 
      // Processa um único recurso
      else if (jsonData['type'] == 'Feature') {
        final geometry = jsonData['geometry'];
        if (geometry != null && geometry['coordinates'] != null) {
          _processGeometry(geometry, processCoordinates);
        }
      } 
      // Processa uma geometria direta
      else if (jsonData['coordinates'] != null) {
        _processGeometry(jsonData, processCoordinates);
      }
      
      return coordinates;
    } catch (e) {
      throw Exception('Erro ao processar arquivo GeoJSON: $e');
    }
  }
  
  // Função auxiliar para processar diferentes tipos de geometria
  void _processGeometry(Map<String, dynamic> geometry, Function(List<dynamic>) processCoords) {
    final type = geometry['type'] as String? ?? '';
    final coords = geometry['coordinates'];
    
    if (coords == null) return;
    
    switch (type) {
      case 'Polygon':
      case 'MultiPolygon':
      case 'LineString':
      case 'MultiLineString':
        if (coords is List) {
          // Para MultiPolygon e MultiLineString, processa cada geometria
          if (type.startsWith('Multi')) {
            for (final subCoords in coords) {
              if (subCoords is List) {
                processCoords(subCoords);
              }
            }
          } else {
            processCoords(coords);
          }
        }
        break;
      case 'Point':
        if (coords is List && coords.length >= 2) {
          final lng = coords[0]?.toDouble() ?? 0.0;
          final lat = coords[1]?.toDouble() ?? 0.0;
          processCoords([lng, lat]);
        }
        break;
      case 'MultiPoint':
        if (coords is List) {
          for (final point in coords) {
            if (point is List && point.length >= 2) {
              final lng = point[0]?.toDouble() ?? 0.0;
              final lat = point[1]?.toDouble() ?? 0.0;
              processCoords([lng, lat]);
            }
          }
        }
        break;
    }
  }
}
