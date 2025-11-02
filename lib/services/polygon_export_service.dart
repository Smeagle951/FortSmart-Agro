import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import '../database/daos/polygon_dao.dart';

class PolygonExportService {
  final PolygonDao _polygonDao;

  PolygonExportService(this._polygonDao);

  /// Exporta polígonos para GeoJSON
  Future<String> exportToGeoJSON(List<int> polygonIds) async {
    try {
      final features = <Map<String, dynamic>>[];

      for (final id in polygonIds) {
        final polygon = await _polygonDao.getPolygonById(id);
        if (polygon != null) {
          final geojson = jsonDecode(polygon.coordinates);
          final feature = {
            "type": "Feature",
            "geometry": geojson,
            "properties": {
              "id": polygon.id,
              "name": polygon.name,
              "method": polygon.method,
              "area_ha": polygon.areaHa,
              "perimeter_m": polygon.perimeterM,
              "distance_m": polygon.distanceM,
              "created_at": polygon.createdAt,
              "fazenda_id": polygon.fazendaId,
              "cultura_id": polygon.culturaId,
              "safra_id": polygon.safraId,
            }
          };
          features.add(feature);
        }
      }

      final featureCollection = {
        "type": "FeatureCollection",
        "features": features,
      };

      return jsonEncode(featureCollection);
    } catch (e) {
      print('❌ Erro ao exportar GeoJSON: $e');
      rethrow;
    }
  }

  /// Exporta polígonos para KML
  Future<String> exportToKML(List<int> polygonIds) async {
    try {
      final placemarks = <String>[];

      for (final id in polygonIds) {
        final polygon = await _polygonDao.getPolygonById(id);
        if (polygon != null) {
          final placemark = _createKMLPlacemark(polygon);
          placemarks.add(placemark);
        }
      }

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>FortSmart Polígonos</name>
    <description>Polígonos exportados do FortSmart Agro</description>
    ${placemarks.join('\n')}
  </Document>
</kml>''';

      return kml;
    } catch (e) {
      print('❌ Erro ao exportar KML: $e');
      rethrow;
    }
  }

  /// Exporta polígonos para CSV
  Future<String> exportToCSV(List<int> polygonIds) async {
    try {
      final csvLines = <String>[];
      
      // Cabeçalho
      csvLines.add('ID,Nome,Método,Área (ha),Perímetro (m),Distância (m),Data Criação,Fazenda,Cultura,Safra');
      
      for (final id in polygonIds) {
        final polygon = await _polygonDao.getPolygonById(id);
        if (polygon != null) {
          final line = [
            polygon.id.toString(),
            '"${polygon.name}"',
            polygon.method,
            polygon.areaHa.toStringAsFixed(2),
            polygon.perimeterM.toStringAsFixed(2),
            polygon.distanceM.toStringAsFixed(2),
            polygon.createdAt,
            polygon.fazendaId ?? '',
            polygon.culturaId ?? '',
            polygon.safraId ?? '',
          ].join(',');
          
          csvLines.add(line);
        }
      }
      
      return csvLines.join('\n');
    } catch (e) {
      print('❌ Erro ao exportar CSV: $e');
      rethrow;
    }
  }

  /// Salva arquivo e compartilha
  Future<void> saveAndShare(String content, String filename, String mimeType) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      
      await file.writeAsString(content);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Polígonos exportados do FortSmart Agro',
      );
      
      print('✅ Arquivo salvo e compartilhado: $filename');
    } catch (e) {
      print('❌ Erro ao salvar/compartilhar arquivo: $e');
      rethrow;
    }
  }

  /// Exporta todos os polígonos
  Future<void> exportAllPolygons(String format) async {
    try {
      final allPolygons = await _polygonDao.getAllPolygons();
      final polygonIds = allPolygons.map((p) => p.id!).toList();
      
      await exportPolygons(polygonIds, format);
    } catch (e) {
      print('❌ Erro ao exportar todos os polígonos: $e');
      rethrow;
    }
  }

  /// Exporta polígonos por fazenda
  Future<void> exportPolygonsByFazenda(String fazendaId, String format) async {
    try {
      final polygons = await _polygonDao.getPolygonsByFazenda(fazendaId);
      final polygonIds = polygons.map((p) => p.id!).toList();
      
      await exportPolygons(polygonIds, format);
    } catch (e) {
      print('❌ Erro ao exportar polígonos da fazenda: $e');
      rethrow;
    }
  }

  /// Exporta polígonos por método
  Future<void> exportPolygonsByMethod(String method, String format) async {
    try {
      final polygons = await _polygonDao.getPolygonsByMethod(method);
      final polygonIds = polygons.map((p) => p.id!).toList();
      
      await exportPolygons(polygonIds, format);
    } catch (e) {
      print('❌ Erro ao exportar polígonos por método: $e');
      rethrow;
    }
  }

  /// Exporta polígonos específicos
  Future<void> exportPolygons(List<int> polygonIds, String format) async {
    try {
      String content;
      String filename;
      String mimeType;
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      
      switch (format.toLowerCase()) {
        case 'geojson':
          content = await exportToGeoJSON(polygonIds);
          filename = 'fortsmart_polygons_$timestamp.geojson';
          mimeType = 'application/geo+json';
          break;
          
        case 'kml':
          content = await exportToKML(polygonIds);
          filename = 'fortsmart_polygons_$timestamp.kml';
          mimeType = 'application/vnd.google-earth.kml+xml';
          break;
          
        case 'csv':
          content = await exportToCSV(polygonIds);
          filename = 'fortsmart_polygons_$timestamp.csv';
          mimeType = 'text/csv';
          break;
          
        default:
          throw Exception('Formato não suportado: $format');
      }
      
      await saveAndShare(content, filename, mimeType);
      
    } catch (e) {
      print('❌ Erro ao exportar polígonos: $e');
      rethrow;
    }
  }

  /// Cria Placemark KML
  String _createKMLPlacemark(dynamic polygon) {
    final geojson = jsonDecode(polygon.coordinates);
    final coordinates = geojson['coordinates'][0] as List;
    
    final kmlCoordinates = coordinates.map((coord) {
      final lon = coord[0] as double;
      final lat = coord[1] as double;
      return '$lon,$lat,0';
    }).join(' ');
    
    return '''    <Placemark>
      <name>${polygon.name}</name>
      <description>
        Área: ${polygon.areaHa.toStringAsFixed(2)} ha
        Perímetro: ${polygon.perimeterM.toStringAsFixed(2)} m
        Método: ${polygon.method}
        Criado em: ${polygon.createdAt}
      </description>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$kmlCoordinates</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''';
  }

  /// Gera relatório de estatísticas
  Future<Map<String, dynamic>> generateStatistics(List<int> polygonIds) async {
    try {
      double totalArea = 0.0;
      double totalPerimeter = 0.0;
      double totalDistance = 0.0;
      int manualCount = 0;
      int gpsCount = 0;
      int importedCount = 0;
      
      for (final id in polygonIds) {
        final polygon = await _polygonDao.getPolygonById(id);
        if (polygon != null) {
          totalArea += polygon.areaHa;
          totalPerimeter += polygon.perimeterM;
          totalDistance += polygon.distanceM;
          
          switch (polygon.method) {
            case 'manual':
              manualCount++;
              break;
            case 'caminhada':
              gpsCount++;
              break;
            case 'importado':
              importedCount++;
              break;
          }
        }
      }
      
      return {
        'total_polygons': polygonIds.length,
        'total_area_ha': totalArea,
        'total_perimeter_m': totalPerimeter,
        'total_distance_m': totalDistance,
        'manual_count': manualCount,
        'gps_count': gpsCount,
        'imported_count': importedCount,
        'average_area_ha': polygonIds.isNotEmpty ? totalArea / polygonIds.length : 0.0,
        'average_perimeter_m': polygonIds.isNotEmpty ? totalPerimeter / polygonIds.length : 0.0,
      };
    } catch (e) {
      print('❌ Erro ao gerar estatísticas: $e');
      rethrow;
    }
  }
}
