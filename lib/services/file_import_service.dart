import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

/// Serviço para importação de arquivos KML e GeoJSON
class FileImportService {
  
  /// Importa um arquivo e retorna os polígonos extraídos
  Future<ImportResult> importFile() async {
    try {
      // Selecionar arquivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz', 'geojson', 'json'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          error: 'Nenhum arquivo selecionado',
        );
      }
      
      final file = result.files.first;
      final filePath = file.path;
      
      if (filePath == null) {
        return ImportResult(
          success: false,
          error: 'Caminho do arquivo inválido',
        );
      }
      
      // Determinar tipo de arquivo
      final extension = file.extension?.toLowerCase();
      
      switch (extension) {
        case 'kml':
        case 'kmz':
          return await _importKmlFile(filePath);
        case 'geojson':
        case 'json':
          return await _importGeoJsonFile(filePath);
        default:
          return ImportResult(
            success: false,
            error: 'Formato de arquivo não suportado',
          );
      }
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erro ao importar arquivo: $e',
      );
    }
  }
  
  /// Importa arquivo KML
  Future<ImportResult> _importKmlFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          success: false,
          error: 'Arquivo não encontrado',
        );
      }
      
      final content = await file.readAsString();
      final document = XmlDocument.parse(content);
      
      final List<List<LatLng>> polygons = [];
      
      // Procurar por Placemarks com Polygon
      final placemarks = document.findAllElements('Placemark');
      
      for (final placemark in placemarks) {
        final polygon = placemark.findElements('Polygon').firstOrNull;
        if (polygon != null) {
          final coordinates = _extractKmlCoordinates(polygon);
          if (coordinates.isNotEmpty) {
            polygons.add(coordinates);
          }
        }
        
        // Procurar por MultiGeometry
        final multiGeometry = placemark.findElements('MultiGeometry').firstOrNull;
        if (multiGeometry != null) {
          final polygonElements = multiGeometry.findElements('Polygon');
          for (final polygon in polygonElements) {
            final coordinates = _extractKmlCoordinates(polygon);
            if (coordinates.isNotEmpty) {
              polygons.add(coordinates);
            }
          }
        }
      }
      
      if (polygons.isEmpty) {
        return ImportResult(
          success: false,
          error: 'Nenhum polígono encontrado no arquivo KML',
        );
      }
      
      return ImportResult(
        success: true,
        polygons: polygons,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erro ao processar arquivo KML: $e',
      );
    }
  }
  
  /// Extrai coordenadas de um elemento Polygon do KML
  List<LatLng> _extractKmlCoordinates(XmlElement polygon) {
    try {
      final outerBoundary = polygon.findElements('outerBoundaryIs').firstOrNull;
      if (outerBoundary == null) return [];
      
      final linearRing = outerBoundary.findElements('LinearRing').firstOrNull;
      if (linearRing == null) return [];
      
      final coordinates = linearRing.findElements('coordinates').firstOrNull;
      if (coordinates == null) return [];
      
      final coordsText = coordinates.text.trim();
      final List<LatLng> points = [];
      
      // KML usa formato: longitude,latitude,altitude
      final coordPairs = coordsText.split(RegExp(r'\s+'));
      
      for (final pair in coordPairs) {
        if (pair.trim().isEmpty) continue;
        
        final parts = pair.split(',');
        if (parts.length >= 2) {
          final lng = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          
          if (lng != null && lat != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
      
      return points;
    } catch (e) {
      debugPrint('Erro ao extrair coordenadas KML: $e');
      return [];
    }
  }
  
  /// Importa arquivo GeoJSON
  Future<ImportResult> _importGeoJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          success: false,
          error: 'Arquivo não encontrado',
        );
      }
      
      final content = await file.readAsString();
      final Map<String, dynamic> geoJson = jsonDecode(content);
      
      final List<List<LatLng>> polygons = [];
      
      if (geoJson['type'] == 'FeatureCollection') {
        // FeatureCollection
        final features = geoJson['features'] as List?;
        if (features != null) {
          for (final feature in features) {
            final geometry = feature['geometry'];
            final extractedPolygons = _extractGeoJsonPolygons(geometry);
            polygons.addAll(extractedPolygons);
          }
        }
      } else if (geoJson['type'] == 'Feature') {
        // Single Feature
        final geometry = geoJson['geometry'];
        final extractedPolygons = _extractGeoJsonPolygons(geometry);
        polygons.addAll(extractedPolygons);
      } else if (geoJson['type'] == 'Polygon') {
        // Single Polygon
        final extractedPolygons = _extractGeoJsonPolygons(geoJson);
        polygons.addAll(extractedPolygons);
      } else if (geoJson['type'] == 'MultiPolygon') {
        // MultiPolygon
        final extractedPolygons = _extractGeoJsonPolygons(geoJson);
        polygons.addAll(extractedPolygons);
      }
      
      if (polygons.isEmpty) {
        return ImportResult(
          success: false,
          error: 'Nenhum polígono encontrado no arquivo GeoJSON',
        );
      }
      
      return ImportResult(
        success: true,
        polygons: polygons,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erro ao processar arquivo GeoJSON: $e',
      );
    }
  }
  
  /// Extrai polígonos de um elemento geometry do GeoJSON
  List<List<LatLng>> _extractGeoJsonPolygons(Map<String, dynamic> geometry) {
    final List<List<LatLng>> polygons = [];
    
    try {
      final type = geometry['type'] as String?;
      final coordinates = geometry['coordinates'];
      
      if (type == 'Polygon' && coordinates is List) {
        // Single Polygon
        final polygon = _coordinatesToLatLngList(coordinates[0]);
        if (polygon.isNotEmpty) {
          polygons.add(polygon);
        }
      } else if (type == 'MultiPolygon' && coordinates is List) {
        // MultiPolygon
        for (final polygonCoords in coordinates) {
          if (polygonCoords is List && polygonCoords.isNotEmpty) {
            final polygon = _coordinatesToLatLngList(polygonCoords[0]);
            if (polygon.isNotEmpty) {
              polygons.add(polygon);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao extrair polígonos GeoJSON: $e');
    }
    
    return polygons;
  }
  
  /// Converte coordenadas GeoJSON para lista de LatLng
  List<LatLng> _coordinatesToLatLngList(List coordinates) {
    final List<LatLng> points = [];
    
    try {
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lng = coord[0] is num ? coord[0].toDouble() : double.tryParse(coord[0].toString());
          final lat = coord[1] is num ? coord[1].toDouble() : double.tryParse(coord[1].toString());
          
          if (lng != null && lat != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao converter coordenadas: $e');
    }
    
    return points;
  }
  
  /// Valida se os polígonos são válidos
  bool _validatePolygons(List<List<LatLng>> polygons) {
    for (final polygon in polygons) {
      if (polygon.length < 3) {
        return false;
      }
      
      // Verificar se as coordenadas estão dentro de limites razoáveis
      for (final point in polygon) {
        if (point.latitude < -90 || point.latitude > 90 ||
            point.longitude < -180 || point.longitude > 180) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Calcula a área total dos polígonos importados
  double calculateTotalArea(List<List<LatLng>> polygons) {
    double totalArea = 0.0;
    
    for (final polygon in polygons) {
      if (polygon.length >= 3) {
        totalArea += _calculatePolygonArea(polygon);
      }
    }
    
    return totalArea;
  }
  
  /// Calcula a área de um polígono usando fórmula de Gauss
  double _calculatePolygonArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      
      final p1 = polygon[i];
      final p2 = polygon[j];
      
      // Converter para radianos
      final lat1 = p1.latitude * pi / 180;
      final lat2 = p2.latitude * pi / 180;
      final lng1 = p1.longitude * pi / 180;
      final lng2 = p2.longitude * pi / 180;
      
      area += (lng2 - lng1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area.abs() * earthRadius * earthRadius / 2.0;
    
    // Converter para hectares
    return area / 10000;
  }
  
  /// Formata a área para exibição
  String formatArea(double area) {
    if (area < 1) {
      return '${(area * 10000).toStringAsFixed(1)} m²';
    } else {
      return '${area.toStringAsFixed(2)} ha';
    }
  }
}

/// Resultado da importação
class ImportResult {
  final bool success;
  final String? error;
  final List<List<LatLng>>? polygons;
  final String? fileName;
  
  ImportResult({
    required this.success,
    this.error,
    this.polygons,
    this.fileName,
  });
  
  /// Obtém a área total dos polígonos importados
  double get totalArea {
    if (!success || polygons == null) return 0.0;
    
    double total = 0.0;
    for (final polygon in polygons!) {
      if (polygon.length >= 3) {
        total += _calculatePolygonArea(polygon);
      }
    }
    return total;
  }
  
  /// Calcula a área de um polígono
  double _calculatePolygonArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      
      final p1 = polygon[i];
      final p2 = polygon[j];
      
      // Converter para radianos
      final lat1 = p1.latitude * pi / 180;
      final lat2 = p2.latitude * pi / 180;
      final lng1 = p1.longitude * pi / 180;
      final lng2 = p2.longitude * pi / 180;
      
      area += (lng2 - lng1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area.abs() * earthRadius * earthRadius / 2.0;
    
    // Converter para hectares
    return area / 10000;
  }
} 