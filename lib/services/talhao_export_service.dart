import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geodesy/geodesy.dart';
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';
import '../models/talhao_model.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../utils/precise_geo_calculator.dart';

/// Serviço para exportação de talhões para máquinas agrícolas
/// Suporta exportação para Shapefile e ISOXML (ISO 11783-10 Taskdata)
class TalhaoExportService {
  static final TalhaoExportService _instance = TalhaoExportService._internal();
  factory TalhaoExportService() => _instance;
  TalhaoExportService._internal();

  /// Exporta uma lista de talhões para Shapefile
  /// Retorna um arquivo ZIP contendo todos os arquivos do Shapefile
  Future<File> exportToShapefile(
    List<TalhaoModel> talhoes, 
    String outputPath, {
    String? nomeArquivo,
  }) async {
    if (talhoes.isEmpty) {
      throw Exception('Lista de talhões não pode estar vazia');
    }

    final nome = nomeArquivo ?? 'talhoes_export_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final shapefileDir = Directory(path.join(tempDir.path, 'shapefile_$nome'));
    
    try {
      await shapefileDir.create(recursive: true);

      // Criar arquivos do Shapefile
      await _createShapefileFiles(talhoes, shapefileDir.path, nome);

      // Comprimir em ZIP
      final zipFile = await _createZipFile(shapefileDir, outputPath, '$nome.zip');
      
      // Limpar diretório temporário
      await shapefileDir.delete(recursive: true);
      
      return zipFile;
    } catch (e) {
      // Limpar em caso de erro
      if (await shapefileDir.exists()) {
        await shapefileDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Exporta uma lista de talhões para ISOXML (ISO 11783-10 Taskdata)
  /// Retorna um arquivo ZIP contendo a estrutura TASKDATA
  Future<File> exportToISOXML(
    List<TalhaoModel> talhoes, 
    String outputPath, {
    String? nomeArquivo,
  }) async {
    if (talhoes.isEmpty) {
      throw Exception('Lista de talhões não pode estar vazia');
    }

    final nome = nomeArquivo ?? 'taskdata_${DateTime.now().millisecondsSinceEpoch}';
    final tempDir = await getTemporaryDirectory();
    final taskdataDir = Directory(path.join(tempDir.path, 'taskdata_$nome'));
    
    try {
      await taskdataDir.create(recursive: true);

      // Criar estrutura ISOXML
      await _createISOXMLStructure(talhoes, taskdataDir.path);

      // Comprimir em ZIP
      final zipFile = await _createZipFile(taskdataDir, outputPath, '$nome.zip');
      
      // Limpar diretório temporário
      await taskdataDir.delete(recursive: true);
      
      return zipFile;
    } catch (e) {
      // Limpar em caso de erro
      if (await taskdataDir.exists()) {
        await taskdataDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Cria os arquivos do Shapefile (.shp, .shx, .dbf, .prj)
  Future<void> _createShapefileFiles(
    List<TalhaoModel> talhoes, 
    String outputDir, 
    String baseName
  ) async {
    // Determinar zona UTM baseada no centroide dos talhões
    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);
    final utmEpsg = _getEpsgCode(utmZone, centroide.latitude >= 0);

    // Criar arquivo .prj (projeção)
    await _createPrjFile(outputDir, baseName, utmEpsg);

    // Criar arquivo .dbf (atributos)
    await _createDbfFile(talhoes, outputDir, baseName);

    // Criar arquivos .shp e .shx (geometria)
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
    // Implementação simplificada do DBF
    // Em uma implementação completa, seria necessário usar uma biblioteca específica
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
    
    int recordOffset = 100; // Offset inicial do Shapefile
    
    // Header do Shapefile
    _writeShapefileHeader(shpData, talhoes.length);
    
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      
      // Converter coordenadas para UTM
      final utmPoints = talhao.points.map((point) => 
        _convertToUTM(point, utmZone)
      ).toList();
      
      // Calcular área em hectares com precisão geodésica
      final areaHa = PreciseGeoCalculator.calculatePolygonArea(talhao.points);
      
      // Escrever record no .shp
      final recordData = _writePolygonRecord(utmPoints, i + 1);
      shpData.addAll(recordData);
      
      // Escrever entry no .shx
      _writeShxEntry(shxData, recordOffset, recordData.length);
      recordOffset += recordData.length;
    }
    
    // Escrever arquivos
    final shpFile = File(path.join(outputDir, '$baseName.shp'));
    final shxFile = File(path.join(outputDir, '$baseName.shx'));
    
    await shpFile.writeAsBytes(Uint8List.fromList(shpData));
    await shxFile.writeAsBytes(Uint8List.fromList(shxData));
  }

  /// Cria estrutura ISOXML completa
  Future<void> _createISOXMLStructure(
    List<TalhaoModel> talhoes, 
    String outputDir
  ) async {
    // Criar diretório TASKDATA
    final taskdataDir = Directory(path.join(outputDir, 'TASKDATA'));
    await taskdataDir.create(recursive: true);

    // Criar diretório POLY para geometrias
    final polyDir = Directory(path.join(taskdataDir.path, 'POLY'));
    await polyDir.create(recursive: true);

    // Determinar zona UTM
    final centroide = _calcularCentroideGeral(talhoes);
    final utmZone = _determinarZonaUTM(centroide.longitude);

    // Criar arquivo TASKDATA.XML principal
    await _createTaskdataXml(talhoes, taskdataDir.path, utmZone);

    // Criar arquivos de geometria POLY
    await _createPolyFiles(talhoes, polyDir.path, utmZone);
  }

  /// Cria arquivo TASKDATA.XML principal
  Future<void> _createTaskdataXml(
    List<TalhaoModel> talhoes, 
    String taskdataDir,
    int utmZone
  ) async {
    final builder = XmlBuilder();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ISO11783_TaskData', attributes: {
      'VersionMajor': '4',
      'VersionMinor': '3',
      'ManagementSoftwareManufacturer': 'FortSmart',
      'ManagementSoftwareVersion': '2.2.31',
      'DataTransferOrigin': '1',
      'TaskControllerManufacturer': 'FortSmart',
      'TaskControllerVersion': '1.0',
    }, nest: () {
      // Header
      builder.element('CTP', attributes: {
        'CTPId': '1',
        'CTPName': 'FortSmart Task Controller',
        'CTPVersion': '1.0',
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
            // Pontos do polígono
            for (int j = 0; j < talhao.points.length; j++) {
              final point = talhao.points[j];
              final utmPoint = _convertToUTM(point, utmZone);
              
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
      
      // Pontos do polígono em UTM
      for (final point in talhao.points) {
        final utmPoint = _convertToUTM(point, utmZone);
        polyContent.writeln('${utmPoint.x} ${utmPoint.y}');
      }
      
      // Fechar polígono
      final firstPoint = talhao.points.first;
      final firstUtmPoint = _convertToUTM(firstPoint, utmZone);
      polyContent.writeln('${firstUtmPoint.x} ${firstUtmPoint.y}');
      polyContent.writeln('END');
      
      await polyFile.writeAsString(polyContent.toString());
    }
  }

  /// Converte coordenadas WGS84 para UTM
  UTMCoordinate _convertToUTM(LatLng point, int zone) {
    final geodesy = Geodesy();
    final utm = geodesy.latLngToUtm(point.latitude, point.longitude, zone);
    return UTMCoordinate(utm.x, utm.y, zone, point.latitude >= 0);
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

  /// Gera conteúdo do arquivo .prj
  String _generatePrjContent(int epsgCode) {
    return '''PROJCS["WGS_1984_UTM_Zone_${epsgCode % 100}S",
    GEOGCS["GCS_WGS_1984",
        DATUM["D_WGS_1984",
            SPHEROID["WGS_1984",6378137,298.257223563]],
        PRIMEM["Greenwich",0],
        UNIT["Degree",0.0174532925199433]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["False_Easting",500000],
    PARAMETER["False_Northing",10000000],
    PARAMETER["Central_Meridian",${(epsgCode % 100 - 1) * 6 - 180 + 3}],
    PARAMETER["Scale_Factor",0.9996],
    PARAMETER["Latitude_Of_Origin",0],
    UNIT["Meter",1]]''';
  }

  /// Gera conteúdo do arquivo .dbf (implementação simplificada)
  List<int> _generateDbfContent(List<TalhaoModel> talhoes) {
    // Implementação simplificada - em produção seria necessário usar biblioteca específica
    final dbfData = <int>[];
    
    // Header DBF
    dbfData.addAll([0x03, 0x00, 0x00, 0x00]); // Versão e data
    dbfData.addAll([0x00, 0x00, 0x00, 0x00]); // Número de registros
    dbfData.addAll([0x00, 0x00, 0x00, 0x00]); // Tamanho do header
    dbfData.addAll([0x00, 0x00, 0x00, 0x00]); // Tamanho do record
    
    // Campos
    _addDbfField(dbfData, 'ID', 'N', 10, 0);
    _addDbfField(dbfData, 'NOME', 'C', 50, 0);
    _addDbfField(dbfData, 'CULTURA', 'C', 30, 0);
    _addDbfField(dbfData, 'SAFRA', 'C', 20, 0);
    _addDbfField(dbfData, 'AREA_HA', 'N', 10, 2);
    dbfData.add(0x0D); // Terminador de campos
    
    // Registros
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      final areaHa = PreciseGeoCalculator.calculatePolygonArea(talhao.points);
      
      dbfData.add(0x20); // Marcador de registro ativo
      _addDbfValue(dbfData, (i + 1).toString(), 10);
      _addDbfValue(dbfData, talhao.name, 50);
      _addDbfValue(dbfData, talhao.safraAtual?.culturaNome ?? 'N/A', 30);
      _addDbfValue(dbfData, talhao.safraAtual?.periodo ?? 'N/A', 20);
      _addDbfValue(dbfData, areaHa.toStringAsFixed(2), 10);
    }
    
    return dbfData;
  }

  /// Adiciona campo ao DBF
  void _addDbfField(List<int> data, String name, String type, int length, int decimals) {
    // Nome do campo (11 bytes)
    final nameBytes = utf8.encode(name.padRight(11, '\x00'));
    data.addAll(nameBytes.take(11));
    
    // Tipo do campo
    data.add(utf8.encode(type)[0]);
    
    // Deslocamento do campo
    data.addAll([0x00, 0x00, 0x00, 0x00]);
    
    // Tamanho do campo
    data.add(length);
    
    // Decimais
    data.add(decimals);
    
    // Reservado
    data.addAll([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    
    // Work area ID
    data.addAll([0x00, 0x00]);
    
    // Multi-user
    data.addAll([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
  }

  /// Adiciona valor ao DBF
  void _addDbfValue(List<int> data, String value, int length) {
    final valueBytes = utf8.encode(value.padRight(length, ' '));
    data.addAll(valueBytes.take(length));
  }

  /// Escreve header do Shapefile
  void _writeShapefileHeader(List<int> data, int recordCount) {
    // File code (big endian)
    data.addAll([0x00, 0x00, 0x27, 0x0A]);
    
    // Unused fields
    data.addAll(List.filled(20, 0x00));
    
    // File length (big endian) - será atualizado depois
    data.addAll([0x00, 0x00, 0x00, 0x00]);
    
    // Version
    data.addAll([0x00, 0x00, 0x00, 0x03]);
    
    // Shape type (Polygon = 5)
    data.addAll([0x00, 0x00, 0x00, 0x05]);
    
    // Bounding box (será calculado)
    data.addAll(List.filled(64, 0x00));
    
    // Z range
    data.addAll(List.filled(16, 0x00));
    
    // M range
    data.addAll(List.filled(16, 0x00));
  }

  /// Escreve record de polígono no Shapefile
  List<int> _writePolygonRecord(List<UTMCoordinate> points, int recordNumber) {
    final data = <int>[];
    
    // Record header
    _writeInt32(data, recordNumber, true); // Record number (big endian)
    _writeInt32(data, 0, true); // Content length (será atualizado)
    
    // Shape type (Polygon = 5)
    _writeInt32(data, 5, false);
    
    // Bounding box
    final bounds = _calculateBounds(points);
    _writeDouble(data, bounds.minX);
    _writeDouble(data, bounds.minY);
    _writeDouble(data, bounds.maxX);
    _writeDouble(data, bounds.maxY);
    
    // Number of parts
    _writeInt32(data, 1, false);
    
    // Number of points
    _writeInt32(data, points.length, false);
    
    // Parts array
    _writeInt32(data, 0, false);
    
    // Points array
    for (final point in points) {
      _writeDouble(data, point.x);
      _writeDouble(data, point.y);
    }
    
    return data;
  }

  /// Escreve entry no arquivo .shx
  void _writeShxEntry(List<int> data, int offset, int length) {
    _writeInt32(data, offset ~/ 2, true); // Offset em words (big endian)
    _writeInt32(data, length ~/ 2, true); // Length em words (big endian)
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
    
    // Adicionar todos os arquivos do diretório ao archive
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: sourceDir.path);
        final fileData = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, fileData.length, fileData);
        archive.addFile(archiveFile);
      }
    }
    
    // Comprimir archive
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Erro ao comprimir arquivo ZIP');
    }
    
    // Salvar arquivo ZIP
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
