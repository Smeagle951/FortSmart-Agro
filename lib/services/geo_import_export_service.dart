import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'geo_calculator_service.dart';

/// Serviço unificado para importação e exportação de polígonos
class GeoImportExportService {
  static final GeoImportExportService _instance = GeoImportExportService._internal();
  factory GeoImportExportService() => _instance;
  GeoImportExportService._internal();

  final GeoCalculatorService _geoCalculator = GeoCalculatorService();

  /// Importa polígonos de arquivos
  Future<ImportResult> importPolygons() async {
    try {
      // Mostrar seletor de arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz', 'geojson', 'json', 'gpx', 'shp'],
        allowMultiple: false,
      );

      if (result == null) {
        return ImportResult(
          success: false,
          error: 'Nenhum arquivo selecionado',
        );
      }

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension!.toLowerCase();

      // Processar arquivo baseado na extensão
      switch (extension) {
        case 'kml':
        case 'kmz':
          return await _importKml(file);
        case 'geojson':
        case 'json':
          return await _importGeoJson(file);
        case 'gpx':
          return await _importGpx(file);
        case 'shp':
          return await _importShapefile(file);
        default:
          return ImportResult(
            success: false,
            error: 'Formato de arquivo não suportado: $extension',
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
  Future<ImportResult> _importKml(File file) async {
    try {
      final content = await file.readAsString();
      
      // Parse básico de KML (simplificado)
      final polygons = <ImportedPolygon>[];
      
      // Extrair coordenadas do KML
      final coordinateRegex = RegExp(r'<coordinates>(.*?)</coordinates>', dotAll: true);
      final matches = coordinateRegex.allMatches(content);
      
      for (final match in matches) {
        final coordString = match.group(1)!.trim();
        final points = _parseCoordinates(coordString);
        
        if (points.length >= 3) {
          final area = _geoCalculator.calculateAreaHectares(points);
          final perimeter = _geoCalculator.calculatePerimeter(points);
          
          polygons.add(ImportedPolygon(
            points: points,
            areaHa: area,
            perimeterM: perimeter,
            sourceFormat: 'KML',
            properties: {},
          ));
        }
      }
      
      return ImportResult(
        success: true,
        polygons: polygons,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erro ao processar KML: $e',
      );
    }
  }

  /// Importa arquivo GeoJSON
  Future<ImportResult> _importGeoJson(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      
      final polygons = <ImportedPolygon>[];
      
      if (json['type'] == 'FeatureCollection') {
        final features = json['features'] as List;
        
        for (final feature in features) {
          if (feature['geometry']['type'] == 'Polygon') {
            final coordinates = feature['geometry']['coordinates'][0] as List;
            final points = coordinates.map((coord) => 
              LatLng(coord[1] as double, coord[0] as double)
            ).toList();
            
            if (points.length >= 3) {
              final area = _geoCalculator.calculateAreaHectares(points);
              final perimeter = _geoCalculator.calculatePerimeter(points);
              
              polygons.add(ImportedPolygon(
                points: points,
                areaHa: area,
                perimeterM: perimeter,
                sourceFormat: 'GeoJSON',
                properties: feature['properties'] ?? {},
              ));
            }
          }
        }
      }
      
      return ImportResult(
        success: true,
        polygons: polygons,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erro ao processar GeoJSON: $e',
      );
    }
  }

  /// Importa arquivo GPX
  Future<ImportResult> _importGpx(File file) async {
    try {
      final content = await file.readAsString();
      
      // Parse básico de GPX (simplificado)
      final polygons = <ImportedPolygon>[];
      
      // Extrair pontos de track
      final trackPointRegex = RegExp(r'<trkpt lat="([^"]*)" lon="([^"]*)">', dotAll: true);
      final matches = trackPointRegex.allMatches(content);
      
      final points = <LatLng>[];
      for (final match in matches) {
        final lat = double.parse(match.group(1)!);
        final lon = double.parse(match.group(2)!);
        points.add(LatLng(lat, lon));
      }
      
      if (points.length >= 3) {
        final area = _geoCalculator.calculateAreaHectares(points);
        final perimeter = _geoCalculator.calculatePerimeter(points);
        
        polygons.add(ImportedPolygon(
          points: points,
          areaHa: area,
          perimeterM: perimeter,
          sourceFormat: 'GPX',
          properties: {},
        ));
      }
      
      return ImportResult(
        success: true,
        polygons: polygons,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erro ao processar GPX: $e',
      );
    }
  }

  /// Importa arquivo Shapefile (simplificado)
  Future<ImportResult> _importShapefile(File file) async {
    // Shapefile é complexo, retornar erro por enquanto
    return ImportResult(
      success: false,
      error: 'Importação de Shapefile não implementada ainda',
    );
  }

  /// Exporta polígonos para arquivo
  Future<ExportResult> exportPolygons(
    List<LatLng> points,
    String format,
    String filename,
  ) async {
    try {
      switch (format.toLowerCase()) {
        case 'kml':
          return await _exportKml(points, filename);
        case 'geojson':
          return await _exportGeoJson(points, filename);
        case 'gpx':
          return await _exportGpx(points, filename);
        default:
          return ExportResult(
            success: false,
            error: 'Formato de exportação não suportado: $format',
          );
      }
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Erro ao exportar: $e',
      );
    }
  }

  /// Exporta para KML
  Future<ExportResult> _exportKml(List<LatLng> points, String filename) async {
    try {
      final coordinates = points.map((p) => '${p.longitude},${p.latitude},0').join(' ');
      
      final kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$filename</name>
    <Placemark>
      <name>Talhão</name>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$coordinates</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';

      final file = await _saveToFile(kmlContent, '$filename.kml');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        format: 'KML',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Erro ao exportar KML: $e',
      );
    }
  }

  /// Exporta para GeoJSON
  Future<ExportResult> _exportGeoJson(List<LatLng> points, String filename) async {
    try {
      final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
      
      final geoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [coordinates]
            },
            'properties': {
              'name': filename,
              'area_ha': _geoCalculator.calculateAreaHectares(points),
              'perimeter_m': _geoCalculator.calculatePerimeter(points),
            }
          }
        ]
      };

      final file = await _saveToFile(jsonEncode(geoJson), '$filename.geojson');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        format: 'GeoJSON',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Erro ao exportar GeoJSON: $e',
      );
    }
  }

  /// Exporta para GPX
  Future<ExportResult> _exportGpx(List<LatLng> points, String filename) async {
    try {
      final trackPoints = points.map((p) => 
        '    <trkpt lat="${p.latitude}" lon="${p.longitude}">\n      <ele>0</ele>\n    </trkpt>'
      ).join('\n');
      
      final gpxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="FortSmart Agro">
  <trk>
    <name>$filename</name>
    <trkseg>
$trackPoints
    </trkseg>
  </trk>
</gpx>''';

      final file = await _saveToFile(gpxContent, '$filename.gpx');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        format: 'GPX',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Erro ao exportar GPX: $e',
      );
    }
  }

  /// Salva conteúdo em arquivo
  Future<File> _saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  /// Compartilha arquivo
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  /// Parse coordenadas de string
  List<LatLng> _parseCoordinates(String coordString) {
    final coords = coordString.split(RegExp(r'\s+'));
    final points = <LatLng>[];
    
    for (final coord in coords) {
      if (coord.trim().isEmpty) continue;
      
      final parts = coord.split(',');
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
}

/// Resultado da importação
class ImportResult {
  final bool success;
  final String? error;
  final List<ImportedPolygon>? polygons;

  ImportResult({
    required this.success,
    this.error,
    this.polygons,
  });
}

/// Resultado da exportação
class ExportResult {
  final bool success;
  final String? error;
  final String? filePath;
  final String? format;

  ExportResult({
    required this.success,
    this.error,
    this.filePath,
    this.format,
  });
}

/// Polígono importado
class ImportedPolygon {
  final List<LatLng> points;
  final double areaHa;
  final double perimeterM;
  final String sourceFormat;
  final Map<String, dynamic> properties;

  ImportedPolygon({
    required this.points,
    required this.areaHa,
    required this.perimeterM,
    required this.sourceFormat,
    required this.properties,
  });
}