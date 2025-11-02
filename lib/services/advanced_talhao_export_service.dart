import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geodesy/geodesy.dart';
import 'package:proj4dart/proj4dart.dart';
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';
import '../models/talhao_model.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../utils/precise_geo_calculator.dart';

/// Enum para fabricantes de monitores agrícolas
enum MonitorManufacturer {
  johnDeere,
  trimble,
  agLeader,
  topcon,
  stara,
  horsch,
  caseIH,
  amazone,
  generic,
}

/// Enum para versões ISOXML
enum ISOXMLVersion {
  v3,
  v4,
  v5,
}

/// Serviço avançado para exportação de talhões com máxima compatibilidade
/// Suporta exportação para Shapefile e ISOXML com metadados completos
class AdvancedTalhaoExportService {
  static final AdvancedTalhaoExportService _instance = AdvancedTalhaoExportService._internal();
  factory AdvancedTalhaoExportService() => _instance;
  AdvancedTalhaoExportService._internal();

  final Uuid _uuid = const Uuid();

  /// Exporta talhões para formato específico do fabricante
  Future<File> exportForManufacturer(
    List<TalhaoModel> talhoes,
    MonitorManufacturer manufacturer,
    String outputPath, {
    String? nomeArquivo,
    ISOXMLVersion? isoxmlVersion,
  }) async {
    switch (manufacturer) {
      case MonitorManufacturer.johnDeere:
        return _exportForJohnDeere(talhoes, outputPath, nomeArquivo, isoxmlVersion);
      case MonitorManufacturer.trimble:
        return _exportForTrimble(talhoes, outputPath, nomeArquivo, isoxmlVersion);
      case MonitorManufacturer.agLeader:
        return _exportForAGLeader(talhoes, outputPath, nomeArquivo);
      case MonitorManufacturer.topcon:
        return _exportForTopcon(talhoes, outputPath, nomeArquivo);
      case MonitorManufacturer.stara:
      case MonitorManufacturer.horsch:
      case MonitorManufacturer.caseIH:
      case MonitorManufacturer.amazone:
        return _exportForISOBUSCompatible(talhoes, outputPath, nomeArquivo, isoxmlVersion);
      case MonitorManufacturer.generic:
        return _exportDualFormat(talhoes, outputPath, nomeArquivo);
    }
  }

  /// Exportação específica para John Deere (Gen4/Gen5)
  Future<File> _exportForJohnDeere(
    List<TalhaoModel> talhoes,
    String outputPath,
    String? nomeArquivo,
    ISOXMLVersion? version,
  ) async {
    final nome = nomeArquivo ?? 'john_deere_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(path.join(tempDir.path, 'jd_export_$nome'));
    
    try {
      await exportDir.create(recursive: true);

      // John Deere prefere ISOXML v4 com GUIDs obrigatórios
      await _createJohnDeereISOXML(talhoes, exportDir.path, version ?? ISOXMLVersion.v4);

      // Também incluir Shapefile para compatibilidade
      await _createShapefileFiles(talhoes, exportDir.path, '${nome}_shapefile');

      // Comprimir tudo em ZIP
      final zipFile = await _createZipFile(exportDir, outputPath, '$nome.zip');
      
      await exportDir.delete(recursive: true);
      return zipFile;
    } catch (e) {
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Exportação específica para Trimble (GFX, TMX)
  Future<File> _exportForTrimble(
    List<TalhaoModel> talhoes,
    String outputPath,
    String? nomeArquivo,
    ISOXMLVersion? version,
  ) async {
    final nome = nomeArquivo ?? 'trimble_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(path.join(tempDir.path, 'trimble_export_$nome'));
    
    try {
      await exportDir.create(recursive: true);

      // Trimble suporta ISOXML v3/v4
      await _createTrimbleISOXML(talhoes, exportDir.path, version ?? ISOXMLVersion.v4);

      // Shapefile com projeção específica
      await _createShapefileFiles(talhoes, exportDir.path, '${nome}_shapefile');

      final zipFile = await _createZipFile(exportDir, outputPath, '$nome.zip');
      
      await exportDir.delete(recursive: true);
      return zipFile;
    } catch (e) {
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Exportação específica para AG Leader (SMS Software, InCommand)
  Future<File> _exportForAGLeader(
    List<TalhaoModel> talhoes,
    String outputPath,
    String? nomeArquivo,
  ) async {
    final nome = nomeArquivo ?? 'agleader_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(path.join(tempDir.path, 'agleader_export_$nome'));
    
    try {
      await exportDir.create(recursive: true);

      // AG Leader prefere Shapefile com EPSG específico
      await _createAGLeaderShapefile(talhoes, exportDir.path, nome);

      final zipFile = await _createZipFile(exportDir, outputPath, '$nome.zip');
      
      await exportDir.delete(recursive: true);
      return zipFile;
    } catch (e) {
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Exportação específica para Topcon (FC-500, X30)
  Future<File> _exportForTopcon(
    List<TalhaoModel> talhoes,
    String outputPath,
    String? nomeArquivo,
  ) async {
    final nome = nomeArquivo ?? 'topcon_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(path.join(tempDir.path, 'topcon_export_$nome'));
    
    try {
      await exportDir.create(recursive: true);

      // Topcon prefere Shapefile UTM
      await _createTopconShapefile(talhoes, exportDir.path, nome);

      final zipFile = await _createZipFile(exportDir, outputPath, '$nome.zip');
      
      await exportDir.delete(recursive: true);
      return zipFile;
    } catch (e) {
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Exportação para equipamentos ISOBUS compatíveis
  Future<File> _exportForISOBUSCompatible(
    List<TalhaoModel> talhoes,
    String outputPath,
    String? nomeArquivo,
    ISOXMLVersion? version,
  ) async {
    final nome = nomeArquivo ?? 'isobus_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(path.join(tempDir.path, 'isobus_export_$nome'));
    
    try {
      await exportDir.create(recursive: true);

      // ISOXML padrão ISOBUS
      await _createISOBUSISOXML(talhoes, exportDir.path, version ?? ISOXMLVersion.v4);

      final zipFile = await _createZipFile(exportDir, outputPath, '$nome.zip');
      
      await exportDir.delete(recursive: true);
      return zipFile;
    } catch (e) {
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Exportação dual (Shapefile + ISOXML)
  Future<File> _exportDualFormat(
    List<TalhaoModel> talhoes,
    String outputPath,
    String? nomeArquivo,
  ) async {
    final nome = nomeArquivo ?? 'dual_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(path.join(tempDir.path, 'dual_export_$nome'));
    
    try {
      await exportDir.create(recursive: true);

      // Criar ambos os formatos
      await _createShapefileFiles(talhoes, exportDir.path, '${nome}_shapefile');
      await _createGenericISOXML(talhoes, exportDir.path, ISOXMLVersion.v4);

      final zipFile = await _createZipFile(exportDir, outputPath, '$nome.zip');
      
      await exportDir.delete(recursive: true);
      return zipFile;
    } catch (e) {
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Cria ISOXML específico para John Deere
  Future<void> _createJohnDeereISOXML(
    List<TalhaoModel> talhoes,
    String outputDir,
    ISOXMLVersion version,
  ) async {
    final taskdataDir = Directory(path.join(outputDir, 'TASKDATA'));
    await taskdataDir.create(recursive: true);

    final polyDir = Directory(path.join(taskdataDir.path, 'POLY'));
    await polyDir.create(recursive: true);

    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);

    // TaskData.xml com metadados John Deere
    await _createJohnDeereTaskdataXml(talhoes, taskdataDir.path, utmZone, version);
    await _createPolyFiles(talhoes, polyDir.path, utmZone);
  }

  /// Cria TaskData.xml específico para John Deere
  Future<void> _createJohnDeereTaskdataXml(
    List<TalhaoModel> talhoes,
    String taskdataDir,
    int utmZone,
    ISOXMLVersion version,
  ) async {
    final builder = XmlBuilder();
    final now = DateTime.now();
    final taskDataId = _uuid.v4();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ISO11783_TaskData', attributes: {
      'VersionMajor': version == ISOXMLVersion.v4 ? '4' : '3',
      'VersionMinor': version == ISOXMLVersion.v4 ? '3' : '0',
      'ManagementSoftwareManufacturer': 'FortSmart',
      'ManagementSoftwareVersion': '2.2.31',
      'DataTransferOrigin': '1',
      'TaskControllerManufacturer': 'FortSmart',
      'TaskControllerVersion': '1.0',
      'TaskDataId': taskDataId,
      'TaskDataCreationDate': now.toIso8601String(),
    }, nest: () {
      // TaskDataHeader com GUID obrigatório para John Deere
      builder.element('TKH', attributes: {
        'TKHId': '1',
        'TKHName': 'FortSmart Task Data',
        'TKHDate': now.toIso8601String(),
        'TKHProducer': 'FortSmart Agro',
        'TKHVersion': '1.0',
        'TKHGuid': _uuid.v4(),
      });

      // Customer
      builder.element('CTR', attributes: {
        'CTRId': '1',
        'CTRName': 'Fazenda FortSmart',
        'CTRAddress': 'Brasil',
        'CTRGuid': _uuid.v4(),
      });

      // Farm
      builder.element('FRM', attributes: {
        'FRMId': '1',
        'FRMName': 'Fazenda Principal',
        'FRMAddress': 'Brasil',
        'FRMGuid': _uuid.v4(),
      });

      // Partfield (Talhões) com GUIDs únicos
      for (int i = 0; i < talhoes.length; i++) {
        final talhao = talhoes[i];
        final areaHa = PreciseGeoCalculator.calculatePolygonArea(talhao.points);
        final fieldGuid = _uuid.v4();
        
        builder.element('PFD', attributes: {
          'PFDId': '${i + 1}',
          'PFDName': talhao.name,
          'PFDFarmId': '1',
          'PFDArea': areaHa.toStringAsFixed(2),
          'PFDLength': '0',
          'PFDWidth': '0',
          'PFDGuid': fieldGuid,
        });
        
        // Plan (Geometria) com GUID
        builder.element('PLN', attributes: {
          'PLNId': '${i + 1}',
          'PLNPartfieldId': '${i + 1}',
          'PLNName': '${talhao.name}_PLAN',
          'PLNGuid': _uuid.v4(),
        }, nest: () {
          // Geometry Group com GUID
          builder.element('GGP', attributes: {
            'GGPId': '${i + 1}',
            'GGPName': '${talhao.name}_GEOMETRY',
            'GGPGuid': _uuid.v4(),
          }, nest: () {
            // Pontos do polígono em UTM
            for (int j = 0; j < talhao.points.length; j++) {
              final point = talhao.points[j];
              final utmPoint = _convertToUTMPrecise(point, utmZone);
              
              builder.element('PNT', attributes: {
                'PNTId': '${i + 1}_${j + 1}',
                'PNTX': utmPoint.x.toStringAsFixed(2),
                'PNTY': utmPoint.y.toStringAsFixed(2),
                'PNTZ': '0.00',
                'PNTGuid': _uuid.v4(),
              });
            }
          });
        });
      }
    });

    final document = builder.buildDocument();
    final xmlFile = File(path.join(taskdataDir, 'TASKDATA.XML'));
    await xmlFile.writeAsString(document.toXmlString(pretty: true));
  }

  /// Cria ISOXML específico para Trimble
  Future<void> _createTrimbleISOXML(
    List<TalhaoModel> talhoes,
    String outputDir,
    ISOXMLVersion version,
  ) async {
    final taskdataDir = Directory(path.join(outputDir, 'TASKDATA'));
    await taskdataDir.create(recursive: true);

    final polyDir = Directory(path.join(taskdataDir.path, 'POLY'));
    await polyDir.create(recursive: true);

    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);

    // TaskData.xml otimizado para Trimble
    await _createTrimbleTaskdataXml(talhoes, taskdataDir.path, utmZone, version);
    await _createPolyFiles(talhoes, polyDir.path, utmZone);
  }

  /// Cria TaskData.xml específico para Trimble
  Future<void> _createTrimbleTaskdataXml(
    List<TalhaoModel> talhoes,
    String taskdataDir,
    int utmZone,
    ISOXMLVersion version,
  ) async {
    final builder = XmlBuilder();
    final now = DateTime.now();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ISO11783_TaskData', attributes: {
      'VersionMajor': version == ISOXMLVersion.v4 ? '4' : '3',
      'VersionMinor': version == ISOXMLVersion.v4 ? '3' : '0',
      'ManagementSoftwareManufacturer': 'FortSmart',
      'ManagementSoftwareVersion': '2.2.31',
      'DataTransferOrigin': '1',
      'TaskControllerManufacturer': 'FortSmart',
      'TaskControllerVersion': '1.0',
    }, nest: () {
      // Header específico para Trimble
      builder.element('TKH', attributes: {
        'TKHId': '1',
        'TKHName': 'FortSmart Task Data',
        'TKHDate': now.toIso8601String(),
        'TKHProducer': 'FortSmart Agro',
        'TKHVersion': '1.0',
      });

      // Customer
      builder.element('CTR', attributes: {
        'CTRId': '1',
        'CTRName': 'Fazenda FortSmart',
        'CTRAddress': 'Brasil',
      });

      // Farm
      builder.element('FRM', attributes: {
        'FRMId': '1',
        'FRMName': 'Fazenda Principal',
        'FRMAddress': 'Brasil',
      });

      // Partfield (Talhões)
      for (int i = 0; i < talhoes.length; i++) {
        final talhao = talhoes[i];
        final areaHa = PreciseGeoCalculator.calculatePolygonArea(talhao.points);
        
        builder.element('PFD', attributes: {
          'PFDId': '${i + 1}',
          'PFDName': talhao.name,
          'PFDFarmId': '1',
          'PFDArea': areaHa.toStringAsFixed(2),
          'PFDLength': '0',
          'PFDWidth': '0',
        });
        
        // Plan (Geometria)
        builder.element('PLN', attributes: {
          'PLNId': '${i + 1}',
          'PLNPartfieldId': '${i + 1}',
          'PLNName': '${talhao.name}_PLAN',
        }, nest: () {
          // Geometry Group
          builder.element('GGP', attributes: {
            'GGPId': '${i + 1}',
            'GGPName': '${talhao.name}_GEOMETRY',
          }, nest: () {
            // Pontos do polígono em UTM
            for (int j = 0; j < talhao.points.length; j++) {
              final point = talhao.points[j];
              final utmPoint = _convertToUTMPrecise(point, utmZone);
              
              builder.element('PNT', attributes: {
                'PNTId': '${i + 1}_${j + 1}',
                'PNTX': utmPoint.x.toStringAsFixed(2),
                'PNTY': utmPoint.y.toStringAsFixed(2),
                'PNTZ': '0.00',
              });
            }
          });
        });
      }
    });

    final document = builder.buildDocument();
    final xmlFile = File(path.join(taskdataDir, 'TASKDATA.XML'));
    await xmlFile.writeAsString(document.toXmlString(pretty: true));
  }

  /// Cria Shapefile específico para AG Leader
  Future<void> _createAGLeaderShapefile(
    List<TalhaoModel> talhoes,
    String outputDir,
    String baseName,
  ) async {
    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);
    final utmEpsg = _getEpsgCode(utmZone, centroide.latitude >= 0);

    // AG Leader prefere EPSG específico
    await _createPrjFile(outputDir, baseName, utmEpsg);
    await _createDbfFile(talhoes, outputDir, baseName);
    await _createShpFiles(talhoes, outputDir, baseName, utmZone);
  }

  /// Cria Shapefile específico para Topcon
  Future<void> _createTopconShapefile(
    List<TalhaoModel> talhoes,
    String outputDir,
    String baseName,
  ) async {
    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);
    final utmEpsg = _getEpsgCode(utmZone, centroide.latitude >= 0);

    // Topcon prefere UTM com precisão específica
    await _createPrjFile(outputDir, baseName, utmEpsg);
    await _createDbfFile(talhoes, outputDir, baseName);
    await _createShpFiles(talhoes, outputDir, baseName, utmZone);
  }

  /// Cria ISOXML genérico ISOBUS
  Future<void> _createISOBUSISOXML(
    List<TalhaoModel> talhoes,
    String outputDir,
    ISOXMLVersion version,
  ) async {
    final taskdataDir = Directory(path.join(outputDir, 'TASKDATA'));
    await taskdataDir.create(recursive: true);

    final polyDir = Directory(path.join(taskdataDir.path, 'POLY'));
    await polyDir.create(recursive: true);

    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);

    await _createGenericTaskdataXml(talhoes, taskdataDir.path, utmZone, version);
    await _createPolyFiles(talhoes, polyDir.path, utmZone);
  }

  /// Cria TaskData.xml genérico
  Future<void> _createGenericTaskdataXml(
    List<TalhaoModel> talhoes,
    String taskdataDir,
    int utmZone,
    ISOXMLVersion version,
  ) async {
    final builder = XmlBuilder();
    final now = DateTime.now();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ISO11783_TaskData', attributes: {
      'VersionMajor': version == ISOXMLVersion.v4 ? '4' : '3',
      'VersionMinor': version == ISOXMLVersion.v4 ? '3' : '0',
      'ManagementSoftwareManufacturer': 'FortSmart',
      'ManagementSoftwareVersion': '2.2.31',
      'DataTransferOrigin': '1',
      'TaskControllerManufacturer': 'FortSmart',
      'TaskControllerVersion': '1.0',
    }, nest: () {
      // Header
      builder.element('TKH', attributes: {
        'TKHId': '1',
        'TKHName': 'FortSmart Task Data',
        'TKHDate': now.toIso8601String(),
        'TKHProducer': 'FortSmart Agro',
        'TKHVersion': '1.0',
      });

      // Customer
      builder.element('CTR', attributes: {
        'CTRId': '1',
        'CTRName': 'Fazenda FortSmart',
        'CTRAddress': 'Brasil',
      });

      // Farm
      builder.element('FRM', attributes: {
        'FRMId': '1',
        'FRMName': 'Fazenda Principal',
        'FRMAddress': 'Brasil',
      });

      // Partfield (Talhões)
      for (int i = 0; i < talhoes.length; i++) {
        final talhao = talhoes[i];
        final areaHa = PreciseGeoCalculator.calculatePolygonArea(talhao.points);
        
        builder.element('PFD', attributes: {
          'PFDId': '${i + 1}',
          'PFDName': talhao.name,
          'PFDFarmId': '1',
          'PFDArea': areaHa.toStringAsFixed(2),
          'PFDLength': '0',
          'PFDWidth': '0',
        });
        
        // Plan (Geometria)
        builder.element('PLN', attributes: {
          'PLNId': '${i + 1}',
          'PLNPartfieldId': '${i + 1}',
          'PLNName': '${talhao.name}_PLAN',
        }, nest: () {
          // Geometry Group
          builder.element('GGP', attributes: {
            'GGPId': '${i + 1}',
            'GGPName': '${talhao.name}_GEOMETRY',
          }, nest: () {
            // Pontos do polígono em UTM
            for (int j = 0; j < talhao.points.length; j++) {
              final point = talhao.points[j];
              final utmPoint = _convertToUTMPrecise(point, utmZone);
              
              builder.element('PNT', attributes: {
                'PNTId': '${i + 1}_${j + 1}',
                'PNTX': utmPoint.x.toStringAsFixed(2),
                'PNTY': utmPoint.y.toStringAsFixed(2),
                'PNTZ': '0.00',
              });
            }
          });
        });
      }
    });

    final document = builder.buildDocument();
    final xmlFile = File(path.join(taskdataDir, 'TASKDATA.XML'));
    await xmlFile.writeAsString(document.toXmlString(pretty: true));
  }

  /// Converte coordenadas WGS84 para UTM com precisão usando proj4dart
  UTMCoordinate _convertToUTMPrecise(LatLng point, int zone) {
    try {
      // Usar proj4dart para conversão mais precisa
      final sourceCRS = Projection.get('EPSG:4326'); // WGS84
      final targetCRS = Projection.get('EPSG:${_getEpsgCode(zone, point.latitude >= 0)}');
      
      // TODO: Implementar conversão com proj4dart
      // final transformer = Transform(sourceCRS, targetCRS);
      // final result = transformer.transform(Point(x: point.longitude, y: point.latitude));
      
      // return UTMCoordinate(result.x, result.y, zone, point.latitude >= 0);
      throw Exception('Conversão com proj4dart não implementada');
    } catch (e) {
      // Fallback para geodesy se proj4dart falhar
      final geodesy = Geodesy();
      // TODO: Implementar conversão com geodesy
      // final utm = geodesy.latLngToUtm(point.latitude, point.longitude, zone);
      // return UTMCoordinate(utm.x, utm.y, zone, point.latitude >= 0);
      throw Exception('Conversão com geodesy não implementada');
    }
  }

  /// Determina a zona UTM baseada na longitude
  int _determinarZonaUTM(double longitude) {
    return ((longitude + 180) / 6).floor() + 1;
  }

  /// Obtém código EPSG para zona UTM
  int _getEpsgCode(int zone, bool isNorthern) {
    return isNorthern ? 32600 + zone : 32700 + zone;
  }

  /// Calcula centroide geral de todos os talhões
  LatLng _calcularCentroideGeral(List<TalhaoModel> talhoes) {
    if (talhoes.isEmpty) return LatLng(0, 0);
    
    double totalLat = 0;
    double totalLng = 0;
    int totalPoints = 0;
    
    for (final talhao in talhoes) {
      for (final point in talhao.points) {
        totalLat += point.latitude;
        totalLng += point.longitude;
        totalPoints++;
      }
    }
    
    return LatLng(totalLat / totalPoints, totalLng / totalPoints);
  }

  /// Cria arquivos do Shapefile (.shp, .shx, .dbf, .prj)
  Future<void> _createShapefileFiles(
    List<TalhaoModel> talhoes, 
    String outputDir, 
    String baseName
  ) async {
    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);
    final utmEpsg = _getEpsgCode(utmZone, centroide.latitude >= 0);

    await _createPrjFile(outputDir, baseName, utmEpsg);
    await _createDbfFile(talhoes, outputDir, baseName);
    await _createShpFiles(talhoes, outputDir, baseName, utmZone);
  }

  /// Cria arquivo .prj com informações de projeção
  Future<void> _createPrjFile(String outputDir, String baseName, int epsgCode) async {
    final prjContent = _generatePrjContent(epsgCode);
    final prjFile = File(path.join(outputDir, '$baseName.prj'));
    await prjFile.writeAsString(prjContent);
  }

  /// Cria arquivo .dbf com atributos dos talhões
  Future<void> _createDbfFile(
    List<TalhaoModel> talhoes, 
    String outputDir, 
    String baseName
  ) async {
    final dbfContent = _generateDbfContent(talhoes);
    final dbfFile = File(path.join(outputDir, '$baseName.dbf'));
    await dbfFile.writeAsBytes(dbfContent);
  }

  /// Cria arquivos .shp e .shx com geometrias
  Future<void> _createShpFiles(
    List<TalhaoModel> talhoes, 
    String outputDir, 
    String baseName,
    int utmZone
  ) async {
    final shpData = <int>[];
    final shxData = <int>[];
    
    int recordOffset = 100;
    
    _writeShapefileHeader(shpData, talhoes.length);
    
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      
      final utmPoints = talhao.points.map((point) => 
        _convertToUTMPrecise(point, utmZone)
      ).toList();
      
      final recordData = _writePolygonRecord(utmPoints, i + 1);
      shpData.addAll(recordData);
      
      _writeShxEntry(shxData, recordOffset, recordData.length);
      recordOffset += recordData.length;
    }
    
    final shpFile = File(path.join(outputDir, '$baseName.shp'));
    final shxFile = File(path.join(outputDir, '$baseName.shx'));
    
    await shpFile.writeAsBytes(Uint8List.fromList(shpData));
    await shxFile.writeAsBytes(Uint8List.fromList(shxData));
  }

  /// Cria arquivos POLY para geometrias
  Future<void> _createPolyFiles(
    List<TalhaoModel> talhoes, 
    String polyDir,
    int utmZone
  ) async {
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      final polyFile = File(path.join(polyDir, '${i + 1}.poly'));
      
      final polyContent = StringBuffer();
      polyContent.writeln('${talhao.name}');
      polyContent.writeln('1');
      
      for (final point in talhao.points) {
        final utmPoint = _convertToUTMPrecise(point, utmZone);
        polyContent.writeln('${utmPoint.x} ${utmPoint.y}');
      }
      
      final firstPoint = talhao.points.first;
      final firstUtmPoint = _convertToUTMPrecise(firstPoint, utmZone);
      polyContent.writeln('${firstUtmPoint.x} ${firstUtmPoint.y}');
      polyContent.writeln('END');
      
      await polyFile.writeAsString(polyContent.toString());
    }
  }

  /// Gera conteúdo do arquivo .prj
  String _generatePrjContent(int epsgCode) {
    final zone = epsgCode % 100;
    final isNorthern = epsgCode < 32700;
    final hemisphere = isNorthern ? 'N' : 'S';
    final falseNorthing = isNorthern ? '0' : '10000000';
    
    return '''PROJCS["WGS_1984_UTM_Zone_${zone}${hemisphere}",
    GEOGCS["GCS_WGS_1984",
        DATUM["D_WGS_1984",
            SPHEROID["WGS_1984",6378137,298.257223563]],
        PRIMEM["Greenwich",0],
        UNIT["Degree",0.0174532925199433]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["False_Easting",500000],
    PARAMETER["False_Northing",$falseNorthing],
    PARAMETER["Central_Meridian",${(zone - 1) * 6 - 180 + 3}],
    PARAMETER["Scale_Factor",0.9996],
    PARAMETER["Latitude_Of_Origin",0],
    UNIT["Meter",1]]''';
  }

  /// Gera conteúdo do arquivo .dbf
  List<int> _generateDbfContent(List<TalhaoModel> talhoes) {
    final dbfData = <int>[];
    
    // Header DBF
    dbfData.addAll([0x03, 0x00, 0x00, 0x00]);
    dbfData.addAll([0x00, 0x00, 0x00, 0x00]);
    dbfData.addAll([0x00, 0x00, 0x00, 0x00]);
    dbfData.addAll([0x00, 0x00, 0x00, 0x00]);
    
    // Campos
    _addDbfField(dbfData, 'ID', 'N', 10, 0);
    _addDbfField(dbfData, 'NOME', 'C', 50, 0);
    _addDbfField(dbfData, 'CULTURA', 'C', 30, 0);
    _addDbfField(dbfData, 'SAFRA', 'C', 20, 0);
    _addDbfField(dbfData, 'AREA_HA', 'N', 10, 2);
    _addDbfField(dbfData, 'GUID', 'C', 36, 0);
    dbfData.add(0x0D);
    
    // Registros
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      final areaHa = PreciseGeoCalculator.calculatePolygonArea(talhao.points);
      
      dbfData.add(0x20);
      _addDbfValue(dbfData, (i + 1).toString(), 10);
      _addDbfValue(dbfData, talhao.name, 50);
      _addDbfValue(dbfData, talhao.safraAtual?.culturaNome ?? 'N/A', 30);
      _addDbfValue(dbfData, talhao.safraAtual?.periodo ?? 'N/A', 20);
      _addDbfValue(dbfData, areaHa.toStringAsFixed(2), 10);
      _addDbfValue(dbfData, _uuid.v4(), 36);
    }
    
    return dbfData;
  }

  /// Adiciona campo ao DBF
  void _addDbfField(List<int> data, String name, String type, int length, int decimals) {
    final nameBytes = utf8.encode(name.padRight(11, '\x00'));
    data.addAll(nameBytes.take(11));
    data.add(utf8.encode(type)[0]);
    data.addAll([0x00, 0x00, 0x00, 0x00]);
    data.add(length);
    data.add(decimals);
    data.addAll([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    data.addAll([0x00, 0x00]);
    data.addAll([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
  }

  /// Adiciona valor ao DBF
  void _addDbfValue(List<int> data, String value, int length) {
    final valueBytes = utf8.encode(value.padRight(length, ' '));
    data.addAll(valueBytes.take(length));
  }

  /// Escreve header do Shapefile
  void _writeShapefileHeader(List<int> data, int recordCount) {
    data.addAll([0x00, 0x00, 0x27, 0x0A]);
    data.addAll(List.filled(20, 0x00));
    data.addAll([0x00, 0x00, 0x00, 0x00]);
    data.addAll([0x00, 0x00, 0x00, 0x03]);
    data.addAll([0x00, 0x00, 0x00, 0x05]);
    data.addAll(List.filled(64, 0x00));
    data.addAll(List.filled(16, 0x00));
    data.addAll(List.filled(16, 0x00));
  }

  /// Escreve record de polígono no Shapefile
  List<int> _writePolygonRecord(List<UTMCoordinate> points, int recordNumber) {
    final data = <int>[];
    
    _writeInt32(data, recordNumber, true);
    _writeInt32(data, 0, true);
    
    _writeInt32(data, 5, false);
    
    final bounds = _calculateBounds(points);
    _writeDouble(data, bounds.minX);
    _writeDouble(data, bounds.minY);
    _writeDouble(data, bounds.maxX);
    _writeDouble(data, bounds.maxY);
    
    _writeInt32(data, 1, false);
    _writeInt32(data, points.length, false);
    _writeInt32(data, 0, false);
    
    for (final point in points) {
      _writeDouble(data, point.x);
      _writeDouble(data, point.y);
    }
    
    return data;
  }

  /// Escreve entry no arquivo .shx
  void _writeShxEntry(List<int> data, int offset, int length) {
    _writeInt32(data, offset ~/ 2, true);
    _writeInt32(data, length ~/ 2, true);
  }

  /// Escreve inteiro de 32 bits
  void _writeInt32(List<int> data, int value, bool bigEndian) {
    if (bigEndian) {
      data.addAll([
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ]);
    } else {
      data.addAll([
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ]);
    }
  }

  /// Escreve double de 64 bits
  void _writeDouble(List<int> data, double value) {
    final bytes = ByteData(8);
    bytes.setFloat64(0, value, Endian.little);
    data.addAll(bytes.buffer.asUint8List());
  }

  /// Calcula bounds de uma lista de pontos UTM
  Bounds _calculateBounds(List<UTMCoordinate> points) {
    if (points.isEmpty) {
      return Bounds(0, 0, 0, 0);
    }
    
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    
    for (final point in points) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }
    
    return Bounds(minX, minY, maxX, maxY);
  }

  /// Cria arquivo ZIP a partir de um diretório
  Future<File> _createZipFile(
    Directory sourceDir, 
    String outputPath, 
    String zipFileName
  ) async {
    final archive = Archive();
    
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: sourceDir.path);
        final fileData = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, fileData.length, fileData);
        archive.addFile(archiveFile);
      }
    }
    
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Erro ao comprimir arquivo ZIP');
    }
    
    final zipFile = File(path.join(outputPath, zipFileName));
    await zipFile.writeAsBytes(zipData);
    
    return zipFile;
  }
}

/// Classe para representar coordenadas UTM
class UTMCoordinate {
  final double x;
  final double y;
  final int zone;
  final bool isNorthern;

  UTMCoordinate(this.x, this.y, this.zone, this.isNorthern);
}

/// Classe para representar bounds
class Bounds {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  Bounds(this.minX, this.minY, this.maxX, this.maxY);
}

/// Método para criar ISOXML genérico
Future<void> _createGenericISOXML(List<TalhaoModel> talhoes, String outputPath, ISOXMLVersion version) async {
  // Implementação básica do ISOXML genérico
  final xml = XmlDocument([
    XmlElement(XmlName('ISO11783_TaskData'), [], [
      XmlElement(XmlName('VersionMajor'), [], [XmlText(version == ISOXMLVersion.v4 ? '4' : '3')]),
      XmlElement(XmlName('VersionMinor'), [], [XmlText(version == ISOXMLVersion.v4 ? '3' : '0')]),
    ])
  ]);
  
  final file = File('$outputPath/generic_export.xml');
  await file.writeAsString(xml.toXmlString(pretty: true));
}
