import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

/// Utilitário para importação de polígonos em diferentes formatos
class PolygonImportUtils {
  /// Importa polígonos de um arquivo KML
  static List<List<LatLng>> importFromKml(String kmlContent) {
    try {
      final document = xml.XmlDocument.parse(kmlContent);
      final placemarks = document.findAllElements('Placemark');
      List<List<LatLng>> polygons = [];
      
      for (final placemark in placemarks) {
        final polygonElements = placemark.findAllElements('Polygon');
        
        for (final polygon in polygonElements) {
          final coordinates = polygon
              .findAllElements('coordinates')
              .firstOrNull
              ?.innerText
              .trim();
          
          if (coordinates != null && coordinates.isNotEmpty) {
            final points = _parseKmlCoordinates(coordinates);
            if (points.isNotEmpty) {
              polygons.add(points);
            }
          }
        }
        
        // Também verificar LinearRing (dentro de outerBoundaryIs)
        final linearRings = placemark.findAllElements('LinearRing');
        for (final ring in linearRings) {
          final coordinates = ring
              .findAllElements('coordinates')
              .firstOrNull
              ?.innerText
              .trim();
          
          if (coordinates != null && coordinates.isNotEmpty) {
            final points = _parseKmlCoordinates(coordinates);
            if (points.isNotEmpty) {
              polygons.add(points);
            }
          }
        }
      }
      
      return polygons;
    } catch (e) {
      debugPrint('Erro ao importar KML: $e');
      return [];
    }
  }
  
  /// Importa polígonos de um arquivo GeoJSON
  static List<List<LatLng>> importFromGeoJson(String geoJsonContent) {
    try {
      final Map<String, dynamic> geoJson = json.decode(geoJsonContent);
      List<List<LatLng>> polygons = [];
      
      // Verificar se é uma FeatureCollection
      if (geoJson['type'] == 'FeatureCollection' && geoJson['features'] is List) {
        final features = geoJson['features'] as List;
        
        for (final feature in features) {
          if (feature['geometry'] != null) {
            final geometry = feature['geometry'];
            final type = geometry['type'];
            
            if (type == 'Polygon') {
              final coordinates = geometry['coordinates'] as List;
              for (final ring in coordinates) {
                final points = _parseGeoJsonCoordinates(ring);
                if (points.isNotEmpty) {
                  polygons.add(points);
                }
              }
            } else if (type == 'MultiPolygon') {
              final multiCoordinates = geometry['coordinates'] as List;
              for (final polygon in multiCoordinates) {
                for (final ring in polygon) {
                  final points = _parseGeoJsonCoordinates(ring);
                  if (points.isNotEmpty) {
                    polygons.add(points);
                  }
                }
              }
            }
          }
        }
      } 
      // Verificar se é um Feature único
      else if (geoJson['type'] == 'Feature' && geoJson['geometry'] != null) {
        final geometry = geoJson['geometry'];
        final type = geometry['type'];
        
        if (type == 'Polygon') {
          final coordinates = geometry['coordinates'] as List;
          for (final ring in coordinates) {
            final points = _parseGeoJsonCoordinates(ring);
            if (points.isNotEmpty) {
              polygons.add(points);
            }
          }
        } else if (type == 'MultiPolygon') {
          final multiCoordinates = geometry['coordinates'] as List;
          for (final polygon in multiCoordinates) {
            for (final ring in polygon) {
              final points = _parseGeoJsonCoordinates(ring);
              if (points.isNotEmpty) {
                polygons.add(points);
              }
            }
          }
        }
      }
      // Verificar se é uma geometria direta
      else if (geoJson['type'] == 'Polygon') {
        final coordinates = geoJson['coordinates'] as List;
        for (final ring in coordinates) {
          final points = _parseGeoJsonCoordinates(ring);
          if (points.isNotEmpty) {
            polygons.add(points);
          }
        }
      } else if (geoJson['type'] == 'MultiPolygon') {
        final multiCoordinates = geoJson['coordinates'] as List;
        for (final polygon in multiCoordinates) {
          for (final ring in polygon) {
            final points = _parseGeoJsonCoordinates(ring);
            if (points.isNotEmpty) {
              polygons.add(points);
            }
          }
        }
      }
      
      return polygons;
    } catch (e) {
      debugPrint('Erro ao importar GeoJSON: $e');
      return [];
    }
  }
  
  /// Analisa coordenadas KML e converte para lista de LatLng
  static List<LatLng> _parseKmlCoordinates(String coordinates) {
    List<LatLng> points = [];
    
    final coordPairs = coordinates.split(' ');
    for (final pair in coordPairs) {
      final trimmedPair = pair.trim();
      if (trimmedPair.isNotEmpty) {
        final parts = trimmedPair.split(',');
        if (parts.length >= 2) {
          try {
            final lng = double.parse(parts[0]);
            final lat = double.parse(parts[1]);
            points.add(LatLng(lat, lng));
          } catch (e) {
            debugPrint('Erro ao converter coordenada KML: $e');
          }
        }
      }
    }
    
    return points;
  }
  
  /// Analisa coordenadas GeoJSON e converte para lista de LatLng
  static List<LatLng> _parseGeoJsonCoordinates(List coordinates) {
    List<LatLng> points = [];
    
    for (final coord in coordinates) {
      if (coord is List && coord.length >= 2) {
        try {
          final lng = double.parse(coord[0].toString());
          final lat = double.parse(coord[1].toString());
          points.add(LatLng(lat, lng));
        } catch (e) {
          debugPrint('Erro ao converter coordenada GeoJSON: $e');
        }
      }
    }
    
    return points;
  }
  
  /// Calcula a área de um polígono em hectares usando a fórmula de Gauss
  static double calculateAreaInHectares(List<LatLng> points) {
    if (points.length < 3) {
      return 0.0;
    }
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    // Converter para hectares usando fator de conversão correto
    area = (area.abs() / 2.0) * 11100000;
    return area;
  }
}
