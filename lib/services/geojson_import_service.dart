import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../widgets/error_dialog.dart';
import '../utils/logger.dart';
import 'polygon_metrics_service.dart';
import 'package:latlong2/latlong.dart' as latlong2;

/// Resultado da importação com coordenadas e propriedades
class ImportResult {
  final List<latlong2.LatLng> coordinates;
  final Map<String, dynamic> properties;
  final String geometryType;
  final int srid;

  const ImportResult({
    required this.coordinates,
    required this.properties,
    required this.geometryType,
    required this.srid,
  });
}

/// Serviço para importação e normalização de arquivos GeoJSON
/// Suporta Polygon e MultiPolygon com normalização automática
class GeoJsonImportService {

  /// Parse GeoJSON e retorna coordenadas normalizadas
  /// geojson: string JSON válida
  /// Retorna ImportResult com coordenadas e propriedades
  static ImportResult parse(String geojson) {
    try {
      final data = jsonDecode(geojson);
      
      // Verifica se é Feature ou FeatureCollection
      if (data['type'] == 'Feature') {
        return _parseFeature(data);
      } else if (data['type'] == 'FeatureCollection') {
        final features = data['features'] as List;
        if (features.isEmpty) {
          throw Exception('FeatureCollection vazio');
        }
        return _parseFeature(features.first);
      } else {
        // Assume que é uma geometria direta
        return _parseGeometry(data, {});
      }
      } catch (e) {
      throw Exception('Erro ao fazer parse do GeoJSON: $e');
    }
  }

  /// Parse uma Feature individual
  static ImportResult _parseFeature(Map<String, dynamic> feature) {
    final properties = Map<String, dynamic>.from(feature['properties'] ?? {});
    final geometry = feature['geometry'];
    
    return _parseGeometry(geometry, properties);
  }

  /// Parse uma geometria
  static ImportResult _parseGeometry(Map<String, dynamic> geometry, Map<String, dynamic> properties) {
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'] as List;
    
    List<latlong2.LatLng> points;
    int srid = 4326; // Assume WGS84 por padrão
    
    switch (type) {
      case 'Polygon':
        points = _parsePolygonCoordinates(coordinates);
        break;
      case 'MultiPolygon':
        points = _parseMultiPolygonCoordinates(coordinates);
        break;
      default:
        throw Exception('Tipo de geometria não suportado: $type');
    }
    
    // Normaliza pontos
    final normalized = PolygonMetricsService.normalizePoints(points);
    
    return ImportResult(
      coordinates: normalized,
      properties: properties,
      geometryType: type,
      srid: srid,
    );
  }

  /// Parse coordenadas de Polygon
  static List<latlong2.LatLng> _parsePolygonCoordinates(List coordinates) {
    if (coordinates.isEmpty) {
      throw Exception('Polygon sem coordenadas');
    }
    
    // Pega o primeiro anel (exterior)
    final ring = coordinates[0] as List;
    return _parseRing(ring);
  }

  /// Parse coordenadas de MultiPolygon
  static List<latlong2.LatLng> _parseMultiPolygonCoordinates(List coordinates) {
    if (coordinates.isEmpty) {
      throw Exception('MultiPolygon sem coordenadas');
    }
    
    // Pega o primeiro polígono, primeiro anel
    final polygon = coordinates[0] as List;
    if (polygon.isEmpty) {
      throw Exception('MultiPolygon sem polígonos');
    }
    
    final ring = polygon[0] as List;
    return _parseRing(ring);
  }

  /// Parse um anel de coordenadas
  static List<latlong2.LatLng> _parseRing(List ring) {
    final points = <latlong2.LatLng>[];
    
    for (final coord in ring) {
      if (coord is List && coord.length >= 2) {
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        
        // Valida coordenadas
        if (lat < -90 || lat > 90) {
          throw Exception('Latitude inválida: $lat');
        }
        if (lon < -180 || lon > 180) {
          throw Exception('Longitude inválida: $lon');
        }
        
        points.add(latlong2.LatLng(lat, lon));
      }
    }
    
    if (points.length < 3) {
      throw Exception('Anel deve ter pelo menos 3 pontos');
    }
    
    return points;
  }

  /// Converte coordenadas para GeoJSON
  /// points: lista de pontos em lat/lng
  /// properties: propriedades adicionais
  /// Retorna string GeoJSON
  static String toGeoJson(List<latlong2.LatLng> points, Map<String, dynamic> properties) {
    final normalized = PolygonMetricsService.normalizePoints(points);
    
    final coordinates = normalized.map((point) => [point.longitude, point.latitude]).toList();
    
    final feature = {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coordinates],
      },
      'properties': properties,
    };
    
    return jsonEncode(feature);
  }

  /// Valida se o GeoJSON é válido
  /// geojson: string JSON
  /// Retorna true se válido
  static bool isValid(String geojson) {
    try {
      parse(geojson);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extrai propriedades comuns de talhão do GeoJSON
  /// properties: mapa de propriedades
  /// Retorna mapa com propriedades normalizadas
  static Map<String, dynamic> extractTalhaoProperties(Map<String, dynamic> properties) {
    final normalized = <String, dynamic>{};
    
    // Mapeia propriedades comuns
    final mappings = {
      'nome': ['nome', 'name', 'NOME', 'NAME', 'talhao', 'TALHAO'],
      'cultura': ['cultura', 'crop', 'CULTURA', 'CROP', 'cultura_nome'],
      'safra': ['safra', 'harvest', 'SAFRA', 'HARVEST', 'ano_safra'],
      'area': ['area', 'area_ha', 'AREA', 'AREA_HA', 'area_hectares'],
      'perimetro': ['perimetro', 'perimeter', 'PERIMETRO', 'PERIMETER'],
    };
    
    for (final entry in mappings.entries) {
      final key = entry.key;
      final possibleNames = entry.value;
      
      for (final name in possibleNames) {
        if (properties.containsKey(name)) {
          normalized[key] = properties[name];
          break;
        }
      }
    }
    
    return normalized;
  }

  /// Converte SRID se necessário
  /// coordinates: coordenadas originais
  /// fromSrid: SRID de origem
  /// toSrid: SRID de destino
  /// Retorna coordenadas convertidas
  static List<latlong2.LatLng> convertSrid(List<latlong2.LatLng> coordinates, int fromSrid, int toSrid) {
    if (fromSrid == toSrid) {
      return coordinates;
    }
    
    // Por enquanto, só suporta conversão para WGS84 (4326)
    if (toSrid != 4326) {
      throw Exception('Conversão para SRID $toSrid não implementada');
    }
    
    // Se já está em WGS84, retorna como está
    if (fromSrid == 4326) {
      return coordinates;
    }
    
    // Para outros SRIDs, implementar conversão específica
    // Por exemplo, UTM para WGS84
    throw Exception('Conversão de SRID $fromSrid para WGS84 não implementada');
  }
} 