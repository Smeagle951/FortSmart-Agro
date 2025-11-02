import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:shapefile/shapefile.dart' as shapefile_lib;
import 'package:archive/archive_io.dart';
import '../utils/logger.dart';
import '../utils/coordinate_normalizer.dart';
import '../utils/geometry_validator.dart';

/// Resultado da importação com dados normalizados
class ImportResult {
  final List<List<LatLng>> polygons;
  final Map<String, dynamic> properties;
  final String sourceFormat;
  final String? error;
  final bool success;

  const ImportResult({
    required this.polygons,
    required this.properties,
    required this.sourceFormat,
    this.error,
    required this.success,
  });
}

/// Estrutura do header do Shapefile
class ShapefileHeader {
  final int fileCode;
  final int fileLength;
  final int version;
  final int shapeType;
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;
  final double zMin;
  final double zMax;
  final double mMin;
  final double mMax;

  ShapefileHeader({
    required this.fileCode,
    required this.fileLength,
    required this.version,
    required this.shapeType,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    required this.zMin,
    required this.zMax,
    required this.mMin,
    required this.mMax,
  });
}

/// Estrutura de um registro do Shapefile
class ShapefileRecord {
  final int recordNumber;
  final int contentLength;
  final int shapeType;
  final List<LatLng> coordinates;
  final Map<String, dynamic> attributes;

  ShapefileRecord({
    required this.recordNumber,
    required this.contentLength,
    required this.shapeType,
    required this.coordinates,
    required this.attributes,
  });
}

/// Estrutura do header do DBF
class DbfHeader {
  final int version;
  final DateTime lastUpdate;
  final int recordCount;
  final int headerLength;
  final int recordLength;
  final List<DbfField> fields;

  DbfHeader({
    required this.version,
    required this.lastUpdate,
    required this.recordCount,
    required this.headerLength,
    required this.recordLength,
    required this.fields,
  });
}

/// Estrutura de um campo do DBF
class DbfField {
  final String name;
  final String type;
  final int length;
  final int decimalCount;

  DbfField({
    required this.name,
    required this.type,
    required this.length,
    required this.decimalCount,
  });
}

/// Estrutura de projeção do arquivo PRJ
class ProjectionInfo {
  final String wkt;
  final String? name;
  final String? authority;
  final String? code;
  final Map<String, dynamic> parameters;

  ProjectionInfo({
    required this.wkt,
    this.name,
    this.authority,
    this.code,
    required this.parameters,
  });
}

/// Serviço unificado para importação de arquivos geográficos
/// Suporta KML, GeoJSON e Shapefile com normalização automática
class UnifiedGeoImportService {
  final CoordinateNormalizer _normalizer = CoordinateNormalizer();
  final GeometryValidator _validator = GeometryValidator();

  /// Tipos de arquivo suportados
  static const List<String> supportedExtensions = [
    'kml', 'kmz', 'geojson', 'json', 'shp', 'zip'
  ];

  /// Obtém a extensão do arquivo
  String _getFileExtension(String path) {
    final parts = path.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Lê inteiro de 32 bits em big endian
  int _readInt32BigEndian(List<int> bytes, int offset) {
    if (offset + 4 > bytes.length) return 0;
    return (bytes[offset] << 24) |
           (bytes[offset + 1] << 16) |
           (bytes[offset + 2] << 8) |
           bytes[offset + 3];
  }

  /// Lê inteiro de 32 bits em little endian
  int _readInt32LittleEndian(List<int> bytes, int offset) {
    if (offset + 4 > bytes.length) return 0;
    return bytes[offset] |
           (bytes[offset + 1] << 8) |
           (bytes[offset + 2] << 16) |
           (bytes[offset + 3] << 24);
  }

  /// Lê inteiro de 16 bits em little endian
  int _readInt16LittleEndian(List<int> bytes, int offset) {
    if (offset + 2 > bytes.length) return 0;
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  /// Lê arquivo DBF para extrair atributos
  Future<Map<String, dynamic>> _readDbfFile(File dbfFile) async {
    try {
      Logger.info('🔄 Lendo arquivo DBF: ${dbfFile.path}');
      
      // Verificar se o arquivo existe
      if (!await dbfFile.exists()) {
        throw Exception('Arquivo DBF não encontrado: ${dbfFile.path}');
      }
      
      // Ler bytes do arquivo
      final bytes = await dbfFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Arquivo DBF está vazio');
      }
      
      // Parse do DBF
      final dbfData = await _parseDbfBytes(bytes);
      
      Logger.info('✅ DBF processado: ${dbfData['totalRecords']} registros');
      return dbfData;
      
    } catch (e) {
      Logger.error('❌ Erro ao ler DBF: $e');
      return {};
    }
  }

  /// Lê arquivo PRJ para extrair informações de projeção
  Future<ProjectionInfo?> _readPrjFile(File prjFile) async {
    try {
      Logger.info('🔄 Lendo arquivo PRJ: ${prjFile.path}');
      
      // Verificar se o arquivo existe
      if (!await prjFile.exists()) {
        Logger.info('Arquivo PRJ não encontrado: ${prjFile.path}');
        return null;
      }
      
      // Ler conteúdo do arquivo
      final content = await prjFile.readAsString();
      if (content.trim().isEmpty) {
        Logger.warning('Arquivo PRJ está vazio');
        return null;
      }
      
      // Parse do PRJ
      final projectionInfo = _parsePrjContent(content);
      
      Logger.info('✅ PRJ processado: ${projectionInfo.name ?? 'Projeção desconhecida'}');
      return projectionInfo;
      
    } catch (e) {
      Logger.error('❌ Erro ao ler PRJ: $e');
      return null;
    }
  }

  /// Parse do conteúdo do arquivo PRJ (WKT - Well-Known Text)
  ProjectionInfo _parsePrjContent(String content) {
    final wkt = content.trim();
    final parameters = <String, dynamic>{};
    String? name;
    String? authority;
    String? code;
    
    // Extrair informações básicas do WKT
    if (wkt.contains('GEOGCS')) {
      // Sistema de coordenadas geográficas
      final nameMatch = RegExp(r'GEOGCS\["([^"]+)"').firstMatch(wkt);
      name = nameMatch?.group(1);
      
      // Extrair AUTHORITY se presente
      final authorityMatch = RegExp(r'AUTHORITY\["([^"]+)","([^"]+)"\]').firstMatch(wkt);
      if (authorityMatch != null) {
        authority = authorityMatch.group(1);
        code = authorityMatch.group(2);
      }
      
      // Extrair DATUM
      final datumMatch = RegExp(r'DATUM\["([^"]+)"').firstMatch(wkt);
      if (datumMatch != null) {
        parameters['datum'] = datumMatch.group(1);
      }
      
      // Extrair SPHEROID
      final spheroidMatch = RegExp(r'SPHEROID\["([^"]+)",([0-9.]+),([0-9.]+)').firstMatch(wkt);
      if (spheroidMatch != null) {
        parameters['spheroid'] = spheroidMatch.group(1);
        parameters['semiMajorAxis'] = double.tryParse(spheroidMatch.group(2) ?? '');
        parameters['inverseFlattening'] = double.tryParse(spheroidMatch.group(3) ?? '');
      }
      
      // Extrair PRIMEM
      final primemMatch = RegExp(r'PRIMEM\["([^"]+)",([0-9.-]+)').firstMatch(wkt);
      if (primemMatch != null) {
        parameters['primeMeridian'] = primemMatch.group(1);
        parameters['primeMeridianValue'] = double.tryParse(primemMatch.group(2) ?? '');
      }
      
      // Extrair UNIT
      final unitMatch = RegExp(r'UNIT\["([^"]+)",([0-9.]+)').firstMatch(wkt);
      if (unitMatch != null) {
        parameters['unit'] = unitMatch.group(1);
        parameters['unitValue'] = double.tryParse(unitMatch.group(2) ?? '');
      }
      
    } else if (wkt.contains('PROJCS')) {
      // Sistema de coordenadas projetadas
      final nameMatch = RegExp(r'PROJCS\["([^"]+)"').firstMatch(wkt);
      name = nameMatch?.group(1);
      
      // Extrair AUTHORITY se presente
      final authorityMatch = RegExp(r'AUTHORITY\["([^"]+)","([^"]+)"\]').firstMatch(wkt);
      if (authorityMatch != null) {
        authority = authorityMatch.group(1);
        code = authorityMatch.group(2);
      }
      
      // Extrair PROJECTION
      final projectionMatch = RegExp(r'PROJECTION\["([^"]+)"').firstMatch(wkt);
      if (projectionMatch != null) {
        parameters['projection'] = projectionMatch.group(1);
      }
      
      // Extrair PARAMETER
      final parameterMatches = RegExp(r'PARAMETER\["([^"]+)",([0-9.-]+)\]').allMatches(wkt);
      for (final match in parameterMatches) {
        final paramName = match.group(1);
        final paramValue = double.tryParse(match.group(2) ?? '');
        if (paramName != null && paramValue != null) {
          parameters[paramName.toLowerCase()] = paramValue;
        }
      }
      
      // Extrair GEOGCS aninhado
      final geogcsMatch = RegExp(r'GEOGCS\["([^"]+)"').firstMatch(wkt);
      if (geogcsMatch != null) {
        parameters['geographicCoordinateSystem'] = geogcsMatch.group(1);
      }
    }
    
    return ProjectionInfo(
      wkt: wkt,
      name: name,
      authority: authority,
      code: code,
      parameters: parameters,
    );
  }

  /// Parse completo do arquivo DBF
  Future<Map<String, dynamic>> _parseDbfBytes(List<int> bytes) async {
    try {
      Logger.info('🔄 Iniciando parse completo do DBF...');
      
      if (bytes.length < 32) {
        throw Exception('Arquivo DBF muito pequeno');
      }
      
      final data = Uint8List.fromList(bytes);
      final header = _parseDbfHeader(data);
      
      Logger.info('📊 DBF Header:');
      Logger.info('  - Versão: ${header.version}');
      Logger.info('  - Última atualização: ${header.lastUpdate}');
      Logger.info('  - Registros: ${header.recordCount}');
      Logger.info('  - Tamanho do header: ${header.headerLength} bytes');
      Logger.info('  - Tamanho do registro: ${header.recordLength} bytes');
      Logger.info('  - Campos: ${header.fields.length}');
      
      // Parse dos registros
      final records = _parseDbfRecords(data, header);
      
      Logger.info('✅ DBF parseado com sucesso: ${records.length} registros');
      
      return {
        'header': header,
        'records': records,
        'totalRecords': records.length,
        'fields': header.fields.map((f) => {
          'name': f.name,
          'type': f.type,
          'length': f.length,
          'decimalCount': f.decimalCount,
        }).toList(),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao fazer parse do DBF: $e');
      rethrow;
    }
  }

  /// Parse do header do DBF
  DbfHeader _parseDbfHeader(Uint8List data) {
    // Ler informações básicas do header
    final version = data[0];
    final lastUpdateYear = 1900 + data[1];
    final lastUpdateMonth = data[2];
    final lastUpdateDay = data[3];
    final recordCount = _readInt32LittleEndian(data, 4);
    final headerLength = _readInt16LittleEndian(data, 8);
    final recordLength = _readInt16LittleEndian(data, 10);
    
    final lastUpdate = DateTime(lastUpdateYear, lastUpdateMonth, lastUpdateDay);
    
    // Parse dos campos
    final fields = <DbfField>[];
    int offset = 32; // Início da descrição dos campos
    
    while (offset < headerLength - 1) {
      if (data[offset] == 0x0D) break; // Terminador do header
      
      final fieldName = String.fromCharCodes(data.sublist(offset, offset + 11)).trim();
      final fieldType = String.fromCharCode(data[offset + 11]);
      final fieldLength = data[offset + 16];
      final decimalCount = data[offset + 17];
      
      if (fieldName.isNotEmpty) {
        fields.add(DbfField(
          name: fieldName,
          type: fieldType,
          length: fieldLength,
          decimalCount: decimalCount,
        ));
      }
      
      offset += 32; // Cada descrição de campo tem 32 bytes
    }
    
    return DbfHeader(
      version: version,
      lastUpdate: lastUpdate,
      recordCount: recordCount,
      headerLength: headerLength,
      recordLength: recordLength,
      fields: fields,
    );
  }

  /// Parse dos registros do DBF
  List<Map<String, dynamic>> _parseDbfRecords(Uint8List data, DbfHeader header) {
    final records = <Map<String, dynamic>>[];
    int offset = header.headerLength;
    
    for (int i = 0; i < header.recordCount; i++) {
      if (offset + header.recordLength > data.length) break;
      
      // Verificar se o registro não está deletado (primeiro byte = 0x2A)
      if (data[offset] == 0x2A) {
        offset += header.recordLength;
        continue;
      }
      
      final record = <String, dynamic>{};
      int fieldOffset = offset + 1; // Pular o byte de status
      
      for (final field in header.fields) {
        if (fieldOffset + field.length > data.length) break;
        
        final fieldData = data.sublist(fieldOffset, fieldOffset + field.length);
        final value = _parseDbfFieldValue(fieldData, field);
        
        record[field.name] = value;
        fieldOffset += field.length;
      }
      
      records.add(record);
      offset += header.recordLength;
    }
    
    return records;
  }

  /// Parse do valor de um campo DBF
  dynamic _parseDbfFieldValue(Uint8List data, DbfField field) {
    final stringValue = String.fromCharCodes(data).trim();
    
    if (stringValue.isEmpty) return null;
    
    switch (field.type.toUpperCase()) {
      case 'C': // Character
        return stringValue;
      case 'N': // Numeric
        if (field.decimalCount > 0) {
          return double.tryParse(stringValue);
        } else {
          return int.tryParse(stringValue);
        }
      case 'F': // Float
        return double.tryParse(stringValue);
      case 'L': // Logical
        return stringValue.toUpperCase() == 'T' || stringValue.toUpperCase() == 'Y';
      case 'D': // Date (YYYYMMDD)
        if (stringValue.length == 8) {
          try {
            final year = int.parse(stringValue.substring(0, 4));
            final month = int.parse(stringValue.substring(4, 6));
            final day = int.parse(stringValue.substring(6, 8));
            return DateTime(year, month, day);
          } catch (e) {
            return stringValue;
          }
        }
        return stringValue;
      case 'M': // Memo
        return stringValue;
      default:
        return stringValue;
    }
  }

  /// Parse completo do Shapefile
  Future<Map<String, dynamic>> _parseShapefileBytes(List<int> bytes) async {
    try {
      Logger.info('🔄 Iniciando parse completo do Shapefile...');
      
      if (bytes.length < 100) {
        throw Exception('Arquivo Shapefile muito pequeno');
      }
      
      final data = Uint8List.fromList(bytes);
      final header = _parseShapefileHeader(data);
      
      Logger.info('📊 Shapefile Header:');
      Logger.info('  - Código: ${header.fileCode}');
      Logger.info('  - Versão: ${header.version}');
      Logger.info('  - Tipo: ${header.shapeType} (${_getShapeTypeName(header.shapeType)})');
      Logger.info('  - Tamanho: ${header.fileLength} bytes');
      Logger.info('  - Bounds: (${header.xMin}, ${header.yMin}) a (${header.xMax}, ${header.yMax})');
      
      // Verificar se é um tipo suportado
      if (!_isSupportedShapeType(header.shapeType)) {
        throw Exception('Tipo de Shapefile não suportado: ${header.shapeType} (${_getShapeTypeName(header.shapeType)}). Tipos suportados: Polygon (5), Polyline (3), Point (1)');
      }
      
      // Parse dos registros
      final records = await _parseShapefileRecords(data, header);
      
      Logger.info('✅ Shapefile parseado com sucesso: ${records.length} registros');
      
      return {
        'header': header,
        'records': records,
        'totalRecords': records.length,
        'shapeType': header.shapeType,
        'shapeTypeName': _getShapeTypeName(header.shapeType),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao fazer parse do Shapefile: $e');
      rethrow;
    }
  }

  /// Parse do header do Shapefile
  ShapefileHeader _parseShapefileHeader(Uint8List data) {
    // Verificar código do arquivo (big endian)
    final fileCode = _readInt32BigEndian(data, 0);
    if (fileCode != 9994) {
      throw Exception('Código de arquivo Shapefile inválido: $fileCode (esperado: 9994)');
    }
    
    // Ler comprimento do arquivo (big endian)
    final fileLength = _readInt32BigEndian(data, 24);
    
    // Ler versão (little endian)
    final version = _readInt32LittleEndian(data, 28);
    if (version != 1000) {
      throw Exception('Versão do Shapefile não suportada: $version (esperado: 1000)');
    }
    
    // Ler tipo de shape (little endian)
    final shapeType = _readInt32LittleEndian(data, 32);
    
    // Ler bounding box (little endian, double)
    final xMin = _readDoubleLittleEndian(data, 36);
    final yMin = _readDoubleLittleEndian(data, 44);
    final xMax = _readDoubleLittleEndian(data, 52);
    final yMax = _readDoubleLittleEndian(data, 60);
    final zMin = _readDoubleLittleEndian(data, 68);
    final zMax = _readDoubleLittleEndian(data, 76);
    final mMin = _readDoubleLittleEndian(data, 84);
    final mMax = _readDoubleLittleEndian(data, 92);
    
    return ShapefileHeader(
      fileCode: fileCode,
      fileLength: fileLength,
      version: version,
      shapeType: shapeType,
      xMin: xMin,
      yMin: yMin,
      xMax: xMax,
      yMax: yMax,
      zMin: zMin,
      zMax: zMax,
      mMin: mMin,
      mMax: mMax,
    );
  }

  /// Parse dos registros do Shapefile
  Future<List<ShapefileRecord>> _parseShapefileRecords(Uint8List data, ShapefileHeader header) async {
    final records = <ShapefileRecord>[];
    int offset = 100; // Header tem 100 bytes
    
    while (offset < data.length - 8) {
      try {
        // Ler número do registro (big endian)
        final recordNumber = _readInt32BigEndian(data, offset);
        offset += 4;
        
        // Ler comprimento do conteúdo (big endian, em words de 16 bits)
        final contentLength = _readInt32BigEndian(data, offset) * 2; // Converter para bytes
        offset += 4;
        
        if (offset + contentLength > data.length) {
          Logger.warning('⚠️ Registro $recordNumber: comprimento excede o arquivo');
          break;
        }
        
        // Ler tipo de shape do registro (little endian)
        final recordShapeType = _readInt32LittleEndian(data, offset);
        offset += 4;
        
        // Se o tipo for 0 (Null Shape), pular
        if (recordShapeType == 0) {
          offset += contentLength - 4;
          continue;
        }
        
        // Verificar se o tipo do registro corresponde ao header
        if (recordShapeType != header.shapeType) {
          Logger.warning('⚠️ Registro $recordNumber: tipo ${recordShapeType} não corresponde ao header ${header.shapeType}');
          offset += contentLength - 4;
          continue;
        }
        
        // Extrair coordenadas baseado no tipo
        final coordinates = _extractCoordinatesFromRecord(data, offset, recordShapeType, contentLength - 4);
        
        if (coordinates.isNotEmpty) {
          records.add(ShapefileRecord(
            recordNumber: recordNumber,
            contentLength: contentLength,
            shapeType: recordShapeType,
            coordinates: coordinates,
            attributes: {}, // Será preenchido pelo DBF
          ));
          
          Logger.info('✅ Registro $recordNumber: ${coordinates.length} pontos extraídos');
        }
        
        offset += contentLength - 4;
        
      } catch (e) {
        Logger.warning('⚠️ Erro ao processar registro em offset $offset: $e');
        break;
      }
    }
    
    return records;
  }

  /// Extrai coordenadas de um registro baseado no tipo
  List<LatLng> _extractCoordinatesFromRecord(Uint8List data, int offset, int shapeType, int contentLength) {
    switch (shapeType) {
      case 1: // Point
        return _extractPointCoordinates(data, offset);
      case 3: // Polyline
        return _extractPolylineCoordinates(data, offset);
      case 5: // Polygon
        return _extractPolygonCoordinates(data, offset);
      case 8: // MultiPoint
        return _extractMultiPointCoordinates(data, offset);
      default:
        Logger.warning('⚠️ Tipo de shape não suportado para extração: $shapeType');
        return [];
    }
  }

  /// Extrai coordenadas de um Point
  List<LatLng> _extractPointCoordinates(Uint8List data, int offset) {
    if (offset + 16 > data.length) return [];
    
    final x = _readDoubleLittleEndian(data, offset);
    final y = _readDoubleLittleEndian(data, offset + 8);
    
    return [LatLng(y, x)]; // LatLng usa (lat, lng)
  }

  /// Extrai coordenadas de um MultiPoint
  List<LatLng> _extractMultiPointCoordinates(Uint8List data, int offset) {
    if (offset + 36 > data.length) return [];
    
    // Ler bounding box
    final xMin = _readDoubleLittleEndian(data, offset);
    final yMin = _readDoubleLittleEndian(data, offset + 8);
    final xMax = _readDoubleLittleEndian(data, offset + 16);
    final yMax = _readDoubleLittleEndian(data, offset + 24);
    
    // Ler número de pontos
    final numPoints = _readInt32LittleEndian(data, offset + 32);
    offset += 36;
    
    final points = <LatLng>[];
    for (int i = 0; i < numPoints; i++) {
      if (offset + 16 > data.length) break;
      
      final x = _readDoubleLittleEndian(data, offset);
      final y = _readDoubleLittleEndian(data, offset + 8);
      points.add(LatLng(y, x));
      offset += 16;
    }
    
    return points;
  }

  /// Extrai coordenadas de um Polyline
  List<LatLng> _extractPolylineCoordinates(Uint8List data, int offset) {
    if (offset + 44 > data.length) return [];
    
    // Ler bounding box
    final xMin = _readDoubleLittleEndian(data, offset);
    final yMin = _readDoubleLittleEndian(data, offset + 8);
    final xMax = _readDoubleLittleEndian(data, offset + 16);
    final yMax = _readDoubleLittleEndian(data, offset + 24);
    
    // Ler número de partes e pontos
    final numParts = _readInt32LittleEndian(data, offset + 32);
    final numPoints = _readInt32LittleEndian(data, offset + 36);
    offset += 40;
    
    if (offset + numParts * 4 + numPoints * 16 > data.length) return [];
    
    // Ler índices das partes
    final partIndices = <int>[];
    for (int i = 0; i < numParts; i++) {
      partIndices.add(_readInt32LittleEndian(data, offset));
      offset += 4;
    }
    
    // Ler todos os pontos
    final allPoints = <LatLng>[];
    for (int i = 0; i < numPoints; i++) {
      final x = _readDoubleLittleEndian(data, offset);
      final y = _readDoubleLittleEndian(data, offset + 8);
      allPoints.add(LatLng(y, x));
      offset += 16;
    }
    
    // Para Polyline, retornar todos os pontos como uma linha contínua
    return allPoints;
  }

  /// Extrai coordenadas de um Polygon
  List<LatLng> _extractPolygonCoordinates(Uint8List data, int offset) {
    if (offset + 44 > data.length) return [];
    
    // Ler bounding box
    final xMin = _readDoubleLittleEndian(data, offset);
    final yMin = _readDoubleLittleEndian(data, offset + 8);
    final xMax = _readDoubleLittleEndian(data, offset + 16);
    final yMax = _readDoubleLittleEndian(data, offset + 24);
    
    // Ler número de partes e pontos
    final numParts = _readInt32LittleEndian(data, offset + 32);
    final numPoints = _readInt32LittleEndian(data, offset + 36);
    offset += 40;
    
    if (offset + numParts * 4 + numPoints * 16 > data.length) return [];
    
    // Ler índices das partes
    final partIndices = <int>[];
    for (int i = 0; i < numParts; i++) {
      partIndices.add(_readInt32LittleEndian(data, offset));
      offset += 4;
    }
    
    // Ler todos os pontos
    final allPoints = <LatLng>[];
    for (int i = 0; i < numPoints; i++) {
      final x = _readDoubleLittleEndian(data, offset);
      final y = _readDoubleLittleEndian(data, offset + 8);
      allPoints.add(LatLng(y, x));
      offset += 16;
    }
    
    // Para Polygon, retornar o primeiro anel (exterior ring)
    if (partIndices.isNotEmpty && allPoints.isNotEmpty) {
      final startIndex = partIndices[0];
      final endIndex = partIndices.length > 1 ? partIndices[1] : allPoints.length;
      
      if (startIndex < allPoints.length && endIndex <= allPoints.length) {
        return allPoints.sublist(startIndex, endIndex);
      }
    }
    
    return allPoints;
  }

  /// Lê double em little endian
  double _readDoubleLittleEndian(Uint8List data, int offset) {
    if (offset + 8 > data.length) return 0.0;
    
    final bytes = data.sublist(offset, offset + 8);
    final byteData = ByteData.sublistView(bytes);
    return byteData.getFloat64(0, Endian.little);
  }

  /// Verifica se o tipo de shape é suportado
  bool _isSupportedShapeType(int shapeType) {
    return [1, 3, 5, 8].contains(shapeType); // Point, Polyline, Polygon, MultiPoint
  }

  /// Obtém nome do tipo de shape
  String _getShapeTypeName(int shapeType) {
    switch (shapeType) {
      case 0: return 'Null Shape';
      case 1: return 'Point';
      case 3: return 'Polyline';
      case 5: return 'Polygon';
      case 8: return 'MultiPoint';
      case 11: return 'PointZ';
      case 13: return 'PolylineZ';
      case 15: return 'PolygonZ';
      case 18: return 'MultiPointZ';
      case 21: return 'PointM';
      case 23: return 'PolylineM';
      case 25: return 'PolygonM';
      case 28: return 'MultiPointM';
      case 31: return 'MultiPatch';
      default: return 'Unknown ($shapeType)';
    }
  }


  /// Extrai coordenadas de um elemento KML
  List<LatLng> _extractKMLCoordinates(XmlElement element) {
    try {
      final coordinates = element
          .findAllElements('coordinates')
          .firstOrNull
          ?.text
          .trim();

      if (coordinates == null || coordinates.isEmpty) {
        return [];
      }

      final points = <LatLng>[];
      final coordStrings = coordinates.split(RegExp(r'\s+'));

      for (final coordString in coordStrings) {
        if (coordString.trim().isEmpty) continue;

        final parts = coordString.split(',');
        if (parts.length >= 2) {
          try {
            final lng = double.parse(parts[0]);
            final lat = double.parse(parts[1]);
            
            // Validar coordenadas
            if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
              points.add(LatLng(lat, lng));
            } else {
              Logger.warning('⚠️ Coordenada KML inválida ignorada: lat=$lat, lng=$lng');
            }
          } catch (e) {
            Logger.warning('⚠️ Erro ao converter coordenada KML: $coordString - $e');
          }
        }
      }

      return points;
    } catch (e) {
      Logger.error('❌ Erro ao extrair coordenadas KML: $e');
      return [];
    }
  }

  /// Lê arquivo Shapefile e retorna lista de polígonos
  Future<List<Map<String, dynamic>>> _readShapefile(File shpFile) async {
    try {
      Logger.info('🔄 Lendo arquivo Shapefile: ${shpFile.path}');
      
      // Verificar se o arquivo existe
      if (!await shpFile.exists()) {
        throw Exception('Arquivo Shapefile não encontrado: ${shpFile.path}');
      }
      
      // Ler bytes do arquivo
      final bytes = await shpFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Arquivo Shapefile está vazio');
      }
      
      // Parse do Shapefile usando parser completo
      final shapefileData = await _parseShapefileBytes(bytes);
      final records = shapefileData['records'] as List<ShapefileRecord>;
      
      final polygons = <Map<String, dynamic>>[];
      
      // Processar cada registro
      for (int i = 0; i < records.length; i++) {
        try {
          final record = records[i];
          
          if (record.coordinates.isNotEmpty) {
            polygons.add({
              'coordinates': record.coordinates,
              'record_index': i,
              'record_number': record.recordNumber,
              'shape_type': record.shapeType,
              'shape_type_name': _getShapeTypeName(record.shapeType),
              'attributes': record.attributes,
            });
          }
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar registro $i: $e');
        }
      }
      
      Logger.info('✅ Shapefile processado: ${polygons.length} registros válidos');
      return polygons;
      
    } catch (e) {
      Logger.error('❌ Erro ao ler Shapefile: $e');
      return [];
    }
  }

  /// Seleciona arquivo para importação
  Future<File?> pickFile() async {
    try {
      Logger.info('🔄 Abrindo seletor de arquivos...');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
        withData: true, // Garantir que os bytes sejam carregados
        dialogTitle: 'Selecione um arquivo KML, GeoJSON ou Shapefile',
      );

      if (result == null || result.files.isEmpty) {
        Logger.info('Nenhum arquivo selecionado');
        return null;
      }

      final file = result.files.first;
      Logger.info('📁 Arquivo selecionado: ${file.name}');
      Logger.info('📊 Tamanho: ${file.size} bytes');
      Logger.info('📂 Caminho: ${file.path}');

      // Validar se o arquivo tem dados
      if (file.bytes == null || file.bytes!.isEmpty) {
        Logger.error('Arquivo sem dados: ${file.name}');
        throw Exception('O arquivo "${file.name}" está vazio ou corrompido. Selecione um arquivo válido.');
      }

      // Se temos caminho, criar File object
      if (file.path != null) {
        final fileObj = File(file.path!);
        if (await fileObj.exists()) {
          Logger.info('✅ Arquivo encontrado no sistema de arquivos');
          return fileObj;
        }
      }

      // Se não temos caminho ou arquivo não existe, criar arquivo temporário
      Logger.info('🔄 Criando arquivo temporário...');
      final tempDir = await Directory.systemTemp.createTemp('fortsmart_import_');
      final tempFile = File('${tempDir.path}/${file.name}');
      await tempFile.writeAsBytes(file.bytes!);
      
      Logger.info('✅ Arquivo temporário criado: ${tempFile.path}');
      return tempFile;

    } catch (e) {
      Logger.error('❌ Erro ao selecionar arquivo: $e');
      rethrow;
    }
  }

  /// Importa arquivo com detecção automática de formato
  Future<ImportResult> importFile(File file) async {
    try {
      Logger.info('🔄 Iniciando importação: ${file.path}');
      
      if (!await file.exists()) {
        Logger.error('Arquivo não encontrado: ${file.path}');
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'unknown',
          error: 'Arquivo não encontrado: ${file.path}',
          success: false,
        );
      }

      // Verificar se o arquivo não está vazio
      final fileSize = await file.length();
      if (fileSize == 0) {
        Logger.error('Arquivo vazio: ${file.path}');
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'unknown',
          error: 'O arquivo está vazio (0 bytes). Selecione um arquivo válido.',
          success: false,
        );
      }

      final extension = _getFileExtension(file.path).toLowerCase();
      Logger.info('📁 Formato detectado: $extension');

      switch (extension) {
        case 'kml':
        case 'kmz':
          return await _importKML(file);
        case 'geojson':
        case 'json':
          return await _importGeoJSON(file);
        case 'shp':
        case 'zip':
          return await _importShapefile(file);
        default:
          return ImportResult(
            polygons: [],
            properties: {},
            sourceFormat: extension,
            error: 'Formato não suportado: $extension. Formatos suportados: KML, GeoJSON, JSON',
            success: false,
          );
      }
    } catch (e) {
      Logger.error('❌ Erro na importação: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'unknown',
        error: 'Erro interno na importação: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Importa arquivo KML com suporte completo
  Future<ImportResult> _importKML(File file) async {
    try {
      Logger.info('🔄 Importando arquivo KML: ${file.path}');
      
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'KML',
          error: 'Arquivo KML está vazio',
          success: false,
        );
      }

      final document = XmlDocument.parse(content);
      final polygons = <List<LatLng>>[];
      final properties = <String, dynamic>{};

      // Extrair nome do documento
      final nameElement = document.findAllElements('name').firstOrNull;
      if (nameElement != null) {
        properties['name'] = nameElement.text.trim();
      }

      // Buscar por Placemarks
      final placemarks = document.findAllElements('Placemark');
      Logger.info('📊 Encontrados ${placemarks.length} Placemarks');

      for (final placemark in placemarks) {
        try {
          // Extrair nome do Placemark
          final placemarkName = placemark.findAllElements('name').firstOrNull?.text.trim();
          if (placemarkName != null) {
            properties['placemark_name'] = placemarkName;
          }

          // Buscar por Polygons
          final polygonElements = placemark.findAllElements('Polygon');
          for (final polygon in polygonElements) {
            final coordinates = _extractKMLCoordinates(polygon);
            if (coordinates.length >= 3) {
              final normalized = CoordinateNormalizer.normalizeCoordinatesSync(coordinates);
              final validationResult = GeometryValidator.isValidPolygon(normalized);
              if (validationResult.isValid) {
                polygons.add(normalized);
                Logger.info('✅ Polígono válido encontrado: ${normalized.length} pontos');
              } else {
                Logger.warning('Polígono inválido ignorado: ${coordinates.length} pontos');
              }
            }
          }

          // Buscar por MultiGeometry
          final multiGeometryElements = placemark.findAllElements('MultiGeometry');
          for (final multiGeometry in multiGeometryElements) {
            final polygonElements = multiGeometry.findAllElements('Polygon');
            for (final polygon in polygonElements) {
                final coordinates = _extractKMLCoordinates(polygon);
                if (coordinates.length >= 3) {
                  final normalized = CoordinateNormalizer.normalizeCoordinatesSync(coordinates);
                  final validationResult = GeometryValidator.isValidPolygon(normalized);
                  if (validationResult.isValid) {
                    polygons.add(normalized);
                    Logger.info('✅ Polígono do MultiGeometry encontrado: ${normalized.length} pontos');
                }
              }
            }
          }

          // Buscar por LineString (convertido para Polygon)
          final lineStringElements = placemark.findAllElements('LineString');
          for (final lineString in lineStringElements) {
            final coordinates = _extractKMLCoordinates(lineString);
            if (coordinates.length >= 3) {
              // Fechar o LineString para formar um Polygon
              if (coordinates.first != coordinates.last) {
                coordinates.add(coordinates.first);
              }
              final normalized = CoordinateNormalizer.normalizeCoordinatesSync(coordinates);
              final validationResult = GeometryValidator.isValidPolygon(normalized);
              if (validationResult.isValid) {
                polygons.add(normalized);
                Logger.info('✅ LineString convertido para Polygon: ${normalized.length} pontos');
              }
            }
          }

        } catch (e) {
          Logger.warning('Erro ao processar Placemark: $e');
          continue;
        }
      }

      if (polygons.isEmpty) {
        return ImportResult(
          polygons: [],
          properties: properties,
          sourceFormat: 'KML',
          error: 'Nenhum polígono válido encontrado no arquivo KML. Verifique se o arquivo contém tags <Polygon>, <MultiGeometry> ou <LineString> com coordenadas válidas.',
          success: false,
        );
      }

      Logger.info('✅ Importação KML concluída: ${polygons.length} polígonos');
      return ImportResult(
        polygons: polygons,
        properties: properties,
        sourceFormat: 'KML',
        success: true,
      );

    } catch (e) {
      Logger.error('❌ Erro ao importar KML: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'KML',
        error: 'Erro ao processar arquivo KML: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Importa arquivo GeoJSON
  Future<ImportResult> _importGeoJSON(File file) async {
    try {
      Logger.info('🔄 Importando arquivo GeoJSON: ${file.path}');
      
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'GeoJSON',
          error: 'Arquivo GeoJSON está vazio',
          success: false,
        );
      }

      final json = jsonDecode(content);
      final polygons = <List<LatLng>>[];
      final properties = <String, dynamic>{};

      // Extrair propriedades do GeoJSON
      if (json['properties'] != null) {
        properties.addAll(Map<String, dynamic>.from(json['properties']));
      }

      switch (json['type']) {
        case 'FeatureCollection':
          final features = json['features'] as List;
          Logger.info('📊 FeatureCollection com ${features.length} features');
          
          for (final feature in features) {
            final featurePolygons = await _extractPolygonsFromFeature(feature);
            polygons.addAll(featurePolygons);
          }
          break;

        case 'Feature':
          Logger.info('📊 Feature única');
          final featurePolygons = await _extractPolygonsFromFeature(json);
          polygons.addAll(featurePolygons);
          break;

        case 'Polygon':
        case 'MultiPolygon':
          Logger.info('📊 Geometria direta: ${json['type']}');
          final geometryPolygons = await _extractPolygonsFromGeometry(json);
          polygons.addAll(geometryPolygons);
          break;

        default:
          return ImportResult(
            polygons: [],
            properties: properties,
            sourceFormat: 'GeoJSON',
            error: 'Tipo de GeoJSON não suportado: ${json['type']}. Tipos suportados: FeatureCollection, Feature, Polygon, MultiPolygon',
            success: false,
          );
      }

      if (polygons.isEmpty) {
        return ImportResult(
          polygons: [],
          properties: properties,
          sourceFormat: 'GeoJSON',
          error: 'Nenhum polígono válido encontrado no arquivo GeoJSON. Verifique se o arquivo contém geometrias do tipo Polygon ou MultiPolygon.',
          success: false,
        );
      }

      Logger.info('✅ Importação GeoJSON concluída: ${polygons.length} polígonos');
      return ImportResult(
        polygons: polygons,
        properties: properties,
        sourceFormat: 'GeoJSON',
        success: true,
      );

    } catch (e) {
      Logger.error('❌ Erro ao importar GeoJSON: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'GeoJSON',
        error: 'Erro ao processar arquivo GeoJSON: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Extrai polígonos de uma feature do GeoJSON
  Future<List<List<LatLng>>> _extractPolygonsFromFeature(Map<String, dynamic> feature) async {
    final polygons = <List<LatLng>>[];
    final geometry = feature['geometry'];
    
    if (geometry != null) {
      final geometryPolygons = await _extractPolygonsFromGeometry(geometry);
      polygons.addAll(geometryPolygons);
    }

    return polygons;
  }

  /// Extrai polígonos de uma geometria do GeoJSON
  Future<List<List<LatLng>>> _extractPolygonsFromGeometry(Map<String, dynamic> geometry) async {
    final polygons = <List<LatLng>>[];
    
    switch (geometry['type']) {
      case 'Polygon':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final exteriorRing = coordinates[0] as List;
          final points = _convertCoordinatesToLatLng(exteriorRing);
          if (points.length >= 3) {
            final normalized = CoordinateNormalizer.normalizeCoordinatesSync(points);
            final validationResult = GeometryValidator.isValidPolygon(normalized);
            if (validationResult.isValid) {
              polygons.add(normalized);
              Logger.info('✅ Polygon extraído: ${normalized.length} pontos');
            }
          }
        }
        break;

      case 'MultiPolygon':
        final coordinates = geometry['coordinates'] as List;
        for (final polygon in coordinates) {
          if (polygon is List && polygon.isNotEmpty) {
            final exteriorRing = polygon[0] as List;
            final points = _convertCoordinatesToLatLng(exteriorRing);
            if (points.length >= 3) {
              final normalized = CoordinateNormalizer.normalizeCoordinatesSync(points);
              final validationResult = GeometryValidator.isValidPolygon(normalized);
              if (validationResult.isValid) {
                polygons.add(normalized);
                Logger.info('✅ MultiPolygon extraído: ${normalized.length} pontos');
              }
            }
          }
        }
        break;

      case 'LineString':
        final coordinates = geometry['coordinates'] as List;
        final points = _convertCoordinatesToLatLng(coordinates);
        if (points.length >= 3) {
          // Fechar o LineString para formar um Polygon
          if (points.first != points.last) {
            points.add(points.first);
          }
          final normalized = CoordinateNormalizer.normalizeCoordinatesSync(points);
          final validationResult = GeometryValidator.isValidPolygon(normalized);
          if (validationResult.isValid) {
            polygons.add(normalized);
            Logger.info('✅ LineString convertido para Polygon: ${normalized.length} pontos');
          }
        }
        break;
    }

    return polygons;
  }

  /// Converte coordenadas do GeoJSON para LatLng
  List<LatLng> _convertCoordinatesToLatLng(List coordinates) {
    return coordinates.map((coord) {
      if (coord is List && coord.length >= 2) {
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }
      return LatLng(0.0, 0.0);
    }).toList();
  }

  /// Importa arquivo Shapefile
  Future<ImportResult> _importShapefile(File file) async {
    try {
      Logger.info('🔄 Importando arquivo Shapefile: ${file.path}');
      
      // Verificar se é um arquivo ZIP (Shapefile compactado)
      if (file.path.toLowerCase().endsWith('.zip')) {
        return await _importShapefileFromZip(file);
      }
      
      // Para arquivos .shp individuais
      return await _importShapefileDirect(file);
      
    } catch (e) {
      Logger.error('❌ Erro ao importar Shapefile: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'Shapefile',
        error: 'Erro ao processar arquivo Shapefile: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Importa Shapefile de um arquivo ZIP
  Future<ImportResult> _importShapefileFromZip(File zipFile) async {
    try {
      Logger.info('🔄 Processando Shapefile compactado: ${zipFile.path}');
      
      // Criar diretório temporário para extrair o ZIP
      final tempDir = await Directory.systemTemp.createTemp('shapefile_import_');
      
      try {
        // Extrair arquivo ZIP
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Extrair todos os arquivos do ZIP
        for (final file in archive) {
          final filename = file.name;
          final filePath = '${tempDir.path}/$filename';
          
          if (file.isFile) {
            final data = file.content as List<int>;
            final outputFile = File(filePath);
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(data);
            Logger.info('📁 Arquivo extraído: $filename');
          }
        }
        
        // Procurar arquivo .shp
        final shpFiles = tempDir.listSync()
            .where((file) => file.path.toLowerCase().endsWith('.shp'))
            .cast<File>();
        
        if (shpFiles.isEmpty) {
          return ImportResult(
            polygons: [],
            properties: {},
            sourceFormat: 'Shapefile',
            error: 'Nenhum arquivo .shp encontrado no ZIP',
            success: false,
          );
        }
        
        // Processar o primeiro arquivo .shp encontrado
        final shpFile = shpFiles.first;
        final result = await _processShapefile(shpFile, tempDir);
        
        // Limpar arquivos temporários
        await tempDir.delete(recursive: true);
        
        return result;
        
      } catch (e) {
        // Limpar arquivos temporários em caso de erro
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
        
        Logger.error('❌ Erro ao extrair ZIP: $e');
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'Shapefile',
          error: 'Erro ao extrair arquivo ZIP: ${e.toString()}',
          success: false,
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar Shapefile ZIP: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'Shapefile',
        error: 'Erro ao processar arquivo Shapefile compactado: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Importa Shapefile direto
  Future<ImportResult> _importShapefileDirect(File shpFile) async {
    try {
      Logger.info('🔄 Processando Shapefile direto: ${shpFile.path}');
      
      // Obter diretório do arquivo para procurar arquivos auxiliares
      final directory = shpFile.parent;
      return await _processShapefile(shpFile, directory);
      
    } catch (e) {
      Logger.error('❌ Erro ao processar Shapefile direto: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'Shapefile',
        error: 'Erro ao processar arquivo Shapefile: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Processa arquivo Shapefile completo (SHP + DBF + PRJ)
  Future<ImportResult> _processShapefile(File shpFile, Directory directory) async {
    try {
      Logger.info('🔄 Processando Shapefile completo: ${shpFile.path}');
      
      // Verificar se arquivo existe
      if (!await shpFile.exists()) {
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'Shapefile',
          error: 'Arquivo Shapefile não encontrado',
          success: false,
        );
      }
      
      // Obter nome base do arquivo
      final baseName = shpFile.path.split('/').last.split('.').first;
      final dbfFile = File('${directory.path}/$baseName.dbf');
      final prjFile = File('${directory.path}/$baseName.prj');
      
      final polygons = <List<LatLng>>[];
      final properties = <String, dynamic>{};
      
      try {
        // 1. Processar arquivo SHP (geometrias)
        Logger.info('📁 Processando arquivo SHP...');
        final shapefileData = await _readShapefile(shpFile);
        
        if (shapefileData.isEmpty) {
          return ImportResult(
            polygons: [],
            properties: {'shapefile_name': baseName},
            sourceFormat: 'Shapefile',
            error: 'Nenhum registro válido encontrado no arquivo Shapefile',
            success: false,
          );
        }
        
        // 2. Processar arquivo DBF (atributos)
        Map<String, dynamic> dbfData = {};
        List<Map<String, dynamic>> dbfRecords = [];
        
        if (await dbfFile.exists()) {
          Logger.info('📁 Processando arquivo DBF...');
          try {
            dbfData = await _readDbfFile(dbfFile);
            dbfRecords = dbfData['records'] as List<Map<String, dynamic>>? ?? [];
            Logger.info('✅ DBF processado: ${dbfRecords.length} registros');
          } catch (e) {
            Logger.warning('⚠️ Erro ao processar DBF: $e');
          }
        } else {
          Logger.info('ℹ️ Arquivo DBF não encontrado: ${dbfFile.path}');
        }
        
        // 3. Processar arquivo PRJ (projeção)
        ProjectionInfo? projectionInfo;
        
        if (await prjFile.exists()) {
          Logger.info('📁 Processando arquivo PRJ...');
          try {
            projectionInfo = await _readPrjFile(prjFile);
            if (projectionInfo != null) {
              Logger.info('✅ PRJ processado: ${projectionInfo.name ?? 'Projeção desconhecida'}');
            }
          } catch (e) {
            Logger.warning('⚠️ Erro ao processar PRJ: $e');
          }
        } else {
          Logger.info('ℹ️ Arquivo PRJ não encontrado: ${prjFile.path}');
        }
        
        // 4. Combinar geometrias com atributos
        for (int i = 0; i < shapefileData.length; i++) {
          try {
            final polygonData = shapefileData[i];
            final points = polygonData['coordinates'] as List<LatLng>;
            
            if (points.length >= 3) {
              // Normalizar coordenadas
              final normalized = CoordinateNormalizer.normalizeCoordinatesSync(points);
              
              // Validar polígono
              final validationResult = GeometryValidator.isValidPolygon(normalized);
              
              if (validationResult.isValid) {
                // Combinar com atributos do DBF se disponível
                final attributes = <String, dynamic>{};
                
                // Adicionar metadados do SHP
                attributes['record_number'] = polygonData['record_number'];
                attributes['shape_type'] = polygonData['shape_type'];
                attributes['shape_type_name'] = polygonData['shape_type_name'];
                
                // Adicionar atributos do DBF se disponível
                if (i < dbfRecords.length) {
                  attributes.addAll(dbfRecords[i]);
                }
                
                polygons.add(normalized);
                Logger.info('✅ Registro ${i + 1}: ${normalized.length} pontos, ${attributes.length} atributos');
              } else {
                Logger.warning('⚠️ Registro ${i + 1}: polígono inválido ignorado');
              }
            }
          } catch (e) {
            Logger.warning('⚠️ Erro ao processar registro ${i + 1}: $e');
          }
        }
        
        // 5. Compilar propriedades finais
        properties['shapefile_name'] = baseName;
        properties['total_records'] = shapefileData.length;
        properties['valid_polygons'] = polygons.length;
        properties['has_dbf'] = dbfData.isNotEmpty;
        properties['has_prj'] = projectionInfo != null;
        
        // Adicionar informações do DBF
        if (dbfData.isNotEmpty) {
          properties['dbf_fields'] = dbfData['fields'];
          properties['dbf_total_records'] = dbfData['totalRecords'];
        }
        
        // Adicionar informações da projeção
        if (projectionInfo != null) {
          properties['projection'] = {
            'name': projectionInfo.name,
            'authority': projectionInfo.authority,
            'code': projectionInfo.code,
            'parameters': projectionInfo.parameters,
          };
        }
        
        if (polygons.isEmpty) {
          return ImportResult(
            polygons: [],
            properties: properties,
            sourceFormat: 'Shapefile',
            error: 'Nenhum polígono válido encontrado no Shapefile',
            success: false,
          );
        }
        
        Logger.info('✅ Shapefile processado com sucesso:');
        Logger.info('  - Geometrias: ${polygons.length} polígonos válidos');
        Logger.info('  - Atributos: ${dbfData.isNotEmpty ? 'Sim' : 'Não'}');
        Logger.info('  - Projeção: ${projectionInfo != null ? 'Sim' : 'Não'}');
        
        return ImportResult(
          polygons: polygons,
          properties: properties,
          sourceFormat: 'Shapefile',
          error: null,
          success: true,
        );
        
      } catch (e) {
        Logger.error('❌ Erro ao processar Shapefile: $e');
        return ImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'Shapefile',
          error: 'Erro ao processar arquivo Shapefile: ${e.toString()}',
          success: false,
        );
      }
    } catch (e) {
      Logger.error('❌ Erro geral ao processar Shapefile: $e');
      return ImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'Shapefile',
        error: 'Erro geral ao processar arquivo Shapefile: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Calcula área de um polígono em hectares
  double calculateArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    try {
      // Usar fórmula de Gauss para calcular área
      double area = 0.0;
      for (int i = 0; i < polygon.length; i++) {
        final j = (i + 1) % polygon.length;
        area += polygon[i].longitude * polygon[j].latitude;
        area -= polygon[j].longitude * polygon[i].latitude;
      }
      area = area.abs() / 2.0;
      
      // Converter para hectares (aproximação)
      // 1 grau² ≈ 111.32 km² na latitude média do Brasil
      const km2PerDegree2 = 111.32 * 111.32;
      const hectaresPerKm2 = 100.0;
      
      return area * km2PerDegree2 * hectaresPerKm2;
    } catch (e) {
      Logger.error('Erro ao calcular área: $e');
      return 0.0;
    }
  }
}
