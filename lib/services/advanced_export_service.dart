import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

/// Serviço avançado de exportação de polígonos
/// Suporta KML, GeoJSON e Shapefile com propriedades completas
class AdvancedExportService {
  
  /// Exporta polígono para KML
  Future<String> exportToKML({
    required String name,
    required List<LatLng> points,
    required double areaHa,
    required double perimeterM,
    required String method,
    String? description,
    Map<String, dynamic>? additionalProperties,
  }) async {
    try {
      final kml = _generateKML(
        name: name,
        points: points,
        areaHa: areaHa,
        perimeterM: perimeterM,
        method: method,
        description: description,
        additionalProperties: additionalProperties,
      );
      
      final fileName = '${_sanitizeFileName(name)}_${DateTime.now().millisecondsSinceEpoch}.kml';
      final file = await _saveToFile(fileName, kml);
      
      Logger.info('✅ Polígono exportado para KML: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar para KML: $e');
      rethrow;
    }
  }
  
  /// Exporta polígono para GeoJSON
  Future<String> exportToGeoJSON({
    required String name,
    required List<LatLng> points,
    required double areaHa,
    required double perimeterM,
    required String method,
    String? description,
    Map<String, dynamic>? additionalProperties,
  }) async {
    try {
      final geojson = _generateGeoJSON(
        name: name,
        points: points,
        areaHa: areaHa,
        perimeterM: perimeterM,
        method: method,
        description: description,
        additionalProperties: additionalProperties,
      );
      
      final fileName = '${_sanitizeFileName(name)}_${DateTime.now().millisecondsSinceEpoch}.geojson';
      final file = await _saveToFile(fileName, jsonEncode(geojson));
      
      Logger.info('✅ Polígono exportado para GeoJSON: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar para GeoJSON: $e');
      rethrow;
    }
  }
  
  /// Exporta polígono para Shapefile (ZIP)
  Future<String> exportToShapefile({
    required String name,
    required List<LatLng> points,
    required double areaHa,
    required double perimeterM,
    required String method,
    String? description,
    Map<String, dynamic>? additionalProperties,
  }) async {
    try {
      // Por enquanto, retornar erro informando que precisa de biblioteca específica
      // TODO: Implementar com shapefile_writer ou similar
      throw Exception('Exportação para Shapefile requer biblioteca específica. Use formato KML ou GeoJSON.');
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar para Shapefile: $e');
      rethrow;
    }
  }
  
  /// Compartilha arquivo exportado
  Future<void> shareExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Polígono exportado do FortSmart Agro');
        Logger.info('✅ Arquivo compartilhado: $filePath');
      } else {
        throw Exception('Arquivo não encontrado: $filePath');
      }
    } catch (e) {
      Logger.error('❌ Erro ao compartilhar arquivo: $e');
      rethrow;
    }
  }
  
  /// Gera conteúdo KML
  String _generateKML({
    required String name,
    required List<LatLng> points,
    required double areaHa,
    required double perimeterM,
    required String method,
    String? description,
    Map<String, dynamic>? additionalProperties,
  }) {
    final coordinates = points.map((point) => '${point.longitude},${point.latitude},0').join(' ');
    
    final extendedData = _generateExtendedData(
      areaHa: areaHa,
      perimeterM: perimeterM,
      method: method,
      additionalProperties: additionalProperties,
    );
    
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>${_escapeXml(name)}</name>
    <description>${_escapeXml(description ?? 'Polígono exportado do FortSmart Agro')}</description>
    <Placemark>
      <name>${_escapeXml(name)}</name>
      <description>${_escapeXml(description ?? 'Polígono agrícola')}</description>
      <ExtendedData>
        $extendedData
      </ExtendedData>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$coordinates</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
      <Style>
        <PolyStyle>
          <color>7F00FF00</color>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>FF0000FF</color>
          <width>2</width>
        </LineStyle>
      </Style>
    </Placemark>
  </Document>
</kml>''';
  }
  
  /// Gera conteúdo GeoJSON
  Map<String, dynamic> _generateGeoJSON({
    required String name,
    required List<LatLng> points,
    required double areaHa,
    required double perimeterM,
    required String method,
    String? description,
    Map<String, dynamic>? additionalProperties,
  }) {
    final coordinates = points.map((point) => [point.longitude, point.latitude]).toList();
    
    final properties = {
      'id': const Uuid().v4(),
      'name': name,
      'description': description ?? 'Polígono agrícola',
      'method': method,
      'area_ha': areaHa,
      'perimeter_m': perimeterM,
      'created_at': DateTime.now().toIso8601String(),
      'points_count': points.length,
      'source': 'FortSmart Agro',
      ...?additionalProperties,
    };
    
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coordinates],
      },
      'properties': properties,
    };
  }
  
  /// Gera dados estendidos para KML
  String _generateExtendedData({
    required double areaHa,
    required double perimeterM,
    required String method,
    Map<String, dynamic>? additionalProperties,
  }) {
    final data = [
      '<Data name="area_ha"><value>${areaHa.toStringAsFixed(2)}</value></Data>',
      '<Data name="perimeter_m"><value>${perimeterM.toStringAsFixed(2)}</value></Data>',
      '<Data name="method"><value>$method</value></Data>',
      '<Data name="created_at"><value>${DateTime.now().toIso8601String()}</value></Data>',
      '<Data name="source"><value>FortSmart Agro</value></Data>',
    ];
    
    if (additionalProperties != null) {
      for (final entry in additionalProperties.entries) {
        data.add('<Data name="${entry.key}"><value>${entry.value}</value></Data>');
      }
    }
    
    return data.join('\n        ');
  }
  
  /// Salva conteúdo em arquivo
  Future<File> _saveToFile(String fileName, String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      
      return file;
    } catch (e) {
      Logger.error('❌ Erro ao salvar arquivo: $e');
      rethrow;
    }
  }
  
  /// Sanitiza nome do arquivo
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
  
  /// Escapa caracteres XML
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
  
  /// Exporta múltiplos polígonos para GeoJSON FeatureCollection
  Future<String> exportMultipleToGeoJSON({
    required List<Map<String, dynamic>> polygons,
  }) async {
    try {
      final features = <Map<String, dynamic>>[];
      
      for (final polygon in polygons) {
        final feature = _generateGeoJSON(
          name: polygon['name'] ?? 'Polígono',
          points: polygon['points'] ?? [],
          areaHa: polygon['areaHa'] ?? 0.0,
          perimeterM: polygon['perimeterM'] ?? 0.0,
          method: polygon['method'] ?? 'importado',
          description: polygon['description'],
          additionalProperties: polygon['additionalProperties'],
        );
        
        features.add(feature);
      }
      
      final featureCollection = {
        'type': 'FeatureCollection',
        'features': features,
        'properties': {
          'created_at': DateTime.now().toIso8601String(),
          'source': 'FortSmart Agro',
          'total_polygons': features.length,
        },
      };
      
      final fileName = 'poligonos_${DateTime.now().millisecondsSinceEpoch}.geojson';
      final file = await _saveToFile(fileName, jsonEncode(featureCollection));
      
      Logger.info('✅ ${features.length} polígonos exportados para GeoJSON: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar múltiplos polígonos: $e');
      rethrow;
    }
  }
  
  /// Exporta múltiplos polígonos para KML
  Future<String> exportMultipleToKML({
    required List<Map<String, dynamic>> polygons,
  }) async {
    try {
      final placemarks = <String>[];
      
      for (int i = 0; i < polygons.length; i++) {
        final polygon = polygons[i];
        final name = polygon['name'] ?? 'Polígono ${i + 1}';
        final points = polygon['points'] ?? [];
        final coordinates = points.map((point) => '${point.longitude},${point.latitude},0').join(' ');
        
        final extendedData = _generateExtendedData(
          areaHa: polygon['areaHa'] ?? 0.0,
          perimeterM: polygon['perimeterM'] ?? 0.0,
          method: polygon['method'] ?? 'importado',
          additionalProperties: polygon['additionalProperties'],
        );
        
        final placemark = '''    <Placemark>
      <name>${_escapeXml(name)}</name>
      <description>${_escapeXml(polygon['description'] ?? 'Polígono agrícola')}</description>
      <ExtendedData>
        $extendedData
      </ExtendedData>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$coordinates</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
      <Style>
        <PolyStyle>
          <color>7F00FF00</color>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>FF0000FF</color>
          <width>2</width>
        </LineStyle>
      </Style>
    </Placemark>''';
        
        placemarks.add(placemark);
      }
      
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Polígonos FortSmart Agro</name>
    <description>Polígonos agrícolas exportados do FortSmart Agro</description>
${placemarks.join('\n')}
  </Document>
</kml>''';
      
      final fileName = 'poligonos_${DateTime.now().millisecondsSinceEpoch}.kml';
      final file = await _saveToFile(fileName, kml);
      
      Logger.info('✅ ${polygons.length} polígonos exportados para KML: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar múltiplos polígonos para KML: $e');
      rethrow;
    }
  }
  
  /// Lista arquivos exportados
  Future<List<File>> listExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      
      if (!await exportDir.exists()) {
        return [];
      }
      
      final files = await exportDir.list().where((entity) => entity is File).cast<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      Logger.error('❌ Erro ao listar arquivos exportados: $e');
      return [];
    }
  }
  
  /// Remove arquivo exportado
  Future<bool> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.info('✅ Arquivo removido: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao remover arquivo: $e');
      return false;
    }
  }
}
