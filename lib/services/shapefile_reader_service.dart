import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../utils/logger.dart';

/// Tipos de dados suportados pelo Shapefile
enum ShapefileDataType {
    talhao,           // Talhões agrícolas
    maquina,          // Trabalhos de máquina
    plantio,          // Áreas de plantio
    colheita,         // Áreas de colheita
    aplicacao,        // Aplicações de defensivos/fertilizantes
    solo,             // Amostras de solo
    irrigacao,        // Sistemas de irrigação
    estrada,          // Estradas e caminhos
    construcao,       // Construções rurais
    desconhecido      // Tipo não identificado
  }

/// Estrutura de dados extraída do Shapefile
class ShapefileData {
    final String fileName;
    final ShapefileDataType dataType;
    final List<ShapefileFeature> features;
    final Map<String, dynamic> metadata;
    final DateTime importDate;

    ShapefileData({
      required this.fileName,
      required this.dataType,
      required this.features,
      required this.metadata,
      required this.importDate,
    });

    /// Converte para lista de talhões
    List<TalhaoModel> toTalhoes() {
      if (dataType != ShapefileDataType.talhao) return [];
      
      return features.map((feature) {
        return TalhaoModel(
          id: feature.attributes['id']?.toString() ?? 
              feature.attributes['ID']?.toString() ?? 
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: feature.attributes['nome']?.toString() ?? 
                feature.attributes['NOME']?.toString() ?? 
                feature.attributes['name']?.toString() ?? 
                'Talhão ${features.indexOf(feature) + 1}',
          area: _parseArea(feature.attributes),
          culturaId: _parseCulturaId(feature.attributes),
          fazendaId: '1', // Default
          poligonos: [
            PoligonoModel(
              id: '${feature.id}_polygon',
              pontos: feature.geometry,
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              ativo: true,
              area: _parseArea(feature.attributes),
              perimetro: 0.0,
              talhaoId: '${feature.id}_talhao',
            ),
          ],
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          safras: [],
        );
      }).toList();
    }

    double _parseArea(Map<String, dynamic> attributes) {
      // Tentar diferentes campos de área
      final areaFields = ['area', 'AREA', 'hectares', 'HECTARES', 'ha', 'HA'];
      
      for (final field in areaFields) {
        final value = attributes[field];
        if (value != null) {
          final area = double.tryParse(value.toString());
          if (area != null && area > 0) {
            return area;
          }
        }
      }
      
      // Se não encontrar área, calcular pela geometria
      return _calculateAreaFromGeometry(features.first.geometry);
    }

    String? _parseCulturaId(Map<String, dynamic> attributes) {
      final culturaFields = ['cultura', 'CULTURA', 'crop', 'CROP', 'plantio', 'PLANTIO'];
      
      for (final field in culturaFields) {
        final value = attributes[field];
        if (value != null) {
          return value.toString();
        }
      }
      
      return null;
    }

    double _calculateAreaFromGeometry(List<LatLng> points) {
      if (points.length < 3) return 0.0;
      
      // Usar fórmula de Shoelace para calcular área
      double area = 0.0;
      for (int i = 0; i < points.length; i++) {
        int j = (i + 1) % points.length;
        area += points[i].latitude * points[j].longitude;
        area -= points[j].latitude * points[i].longitude;
      }
      
      area = area.abs() / 2.0;
      
      // Converter para hectares (aproximação)
      final latMedia = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final latRad = latMedia * pi / 180;
      final metersPerDegLat = 111132.954 - 559.822 * cos(2 * latRad) + 1.175 * cos(4 * latRad);
      final metersPerDegLng = (pi / 180) * 6378137.0 * cos(latRad);
      
      final areaMetersSquared = area * metersPerDegLat * metersPerDegLng;
      return areaMetersSquared / 10000.0; // m² para hectares
    }
  }

/// Feature individual do Shapefile
class ShapefileFeature {
    final String id;
    final List<LatLng> geometry;
    final Map<String, dynamic> attributes;

    ShapefileFeature({
      required this.id,
      required this.geometry,
      required this.attributes,
    });
}

/// Serviço completo para leitura e interpretação de arquivos Shapefile
/// Suporta diferentes tipos de dados: talhões, trabalhos de máquina, etc.
class ShapefileReaderService {
  static const String _tag = 'ShapefileReader';

  /// Lê arquivo Shapefile e retorna dados interpretados
  static Future<ShapefileData?> readShapefile() async {
    try {
      Logger.info('$_tag: Iniciando leitura de Shapefile...');
      
      // Permitir seleção de arquivo .shp
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['shp'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        Logger.info('$_tag: Nenhum arquivo selecionado');
        return null;
      }

      final file = File(result.files.first.path!);
      final fileName = path.basenameWithoutExtension(file.path);
      
      Logger.info('$_tag: Arquivo selecionado: $fileName');

      // Ler arquivo Shapefile
      final shapefileData = await _parseShapefile(file, fileName);
      
      if (shapefileData != null) {
        Logger.info('$_tag: Shapefile lido com sucesso - ${shapefileData.features.length} features');
        Logger.info('$_tag: Tipo detectado: ${shapefileData.dataType}');
      }
      
      return shapefileData;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao ler Shapefile: $e');
      return null;
    }
  }

  /// Lê Shapefile de um arquivo específico
  static Future<ShapefileData?> readShapefileFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = path.basenameWithoutExtension(file.path);
      
      Logger.info('$_tag: Lendo Shapefile: $fileName');
      
      return await _parseShapefile(file, fileName);
      
    } catch (e) {
      Logger.error('$_tag: Erro ao ler Shapefile de arquivo: $e');
      return null;
    }
  }

  /// Parse do arquivo Shapefile
  static Future<ShapefileData?> _parseShapefile(File shpFile, String fileName) async {
    try {
      // Verificar se arquivo existe
      if (!await shpFile.exists()) {
        Logger.error('$_tag: Arquivo não encontrado: ${shpFile.path}');
        return null;
      }

      // Ler bytes do arquivo
      final bytes = await shpFile.readAsBytes();
      
      // Parse do header do Shapefile
      final header = _parseShapefileHeader(bytes);
      if (header == null) {
        Logger.error('$_tag: Erro ao parsear header do Shapefile');
        return null;
      }

      // Parse das features
      final features = _parseShapefileFeatures(bytes, header);
      
      // Detectar tipo de dados
      final dataType = _detectDataType(features, fileName);
      
      // Extrair metadados
      final metadata = _extractMetadata(header, features);
      
      return ShapefileData(
        fileName: fileName,
        dataType: dataType,
        features: features,
        metadata: metadata,
        importDate: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear Shapefile: $e');
      return null;
    }
  }

  /// Parse do header do Shapefile
  static Map<String, dynamic>? _parseShapefileHeader(Uint8List bytes) {
    try {
      if (bytes.length < 100) return null;
      
      final header = <String, dynamic>{};
      
      // File code (bytes 0-3) - deve ser 9994
      final fileCode = _readInt32(bytes, 0, Endian.big);
      if (fileCode != 9994) {
        Logger.error('$_tag: Código de arquivo inválido: $fileCode');
        return null;
      }
      
      // File length (bytes 24-27)
      header['fileLength'] = _readInt32(bytes, 24, Endian.big) * 2;
      
      // Version (bytes 28-31)
      header['version'] = _readInt32(bytes, 28, Endian.little);
      
      // Shape type (bytes 32-35)
      header['shapeType'] = _readInt32(bytes, 32, Endian.little);
      
      // Bounding box (bytes 36-99)
      header['xMin'] = _readDouble(bytes, 36, Endian.little);
      header['yMin'] = _readDouble(bytes, 44, Endian.little);
      header['xMax'] = _readDouble(bytes, 52, Endian.little);
      header['yMax'] = _readDouble(bytes, 60, Endian.little);
      
      Logger.info('$_tag: Header parseado - Tipo: ${header['shapeType']}, Features: ${header['fileLength']}');
      
      return header;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear header: $e');
      return null;
    }
  }

  /// Parse das features do Shapefile
  static List<ShapefileFeature> _parseShapefileFeatures(Uint8List bytes, Map<String, dynamic> header) {
    final features = <ShapefileFeature>[];
    
    try {
      int offset = 100; // Header tem 100 bytes
      
      while (offset < bytes.length - 8) {
        // Record header (8 bytes)
        final recordNumber = _readInt32(bytes, offset, Endian.big);
        final contentLength = _readInt32(bytes, offset + 4, Endian.big) * 2;
        
        if (recordNumber == 0 || contentLength <= 0) break;
        
        offset += 8;
        
        // Record content
        final recordBytes = bytes.sublist(offset, offset + contentLength);
        final feature = _parseFeature(recordBytes, recordNumber.toString());
        
        if (feature != null) {
          features.add(feature);
        }
        
        offset += contentLength;
      }
      
      Logger.info('$_tag: ${features.length} features parseadas');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear features: $e');
    }
    
    return features;
  }

  /// Parse de uma feature individual
  static ShapefileFeature? _parseFeature(Uint8List recordBytes, String id) {
    try {
      if (recordBytes.length < 4) return null;
      
      // Shape type (primeiros 4 bytes)
      final shapeType = _readInt32(recordBytes, 0, Endian.little);
      
      // Parse baseado no tipo de shape
      switch (shapeType) {
        case 5: // Polygon
          return _parsePolygonFeature(recordBytes, id);
        case 3: // Polyline
          return _parsePolylineFeature(recordBytes, id);
        case 1: // Point
          return _parsePointFeature(recordBytes, id);
        default:
          Logger.warning('$_tag: Tipo de shape não suportado: $shapeType');
          return null;
      }
      
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear feature: $e');
      return null;
    }
  }

  /// Parse de feature do tipo Polygon
  static ShapefileFeature? _parsePolygonFeature(Uint8List bytes, String id) {
    try {
      if (bytes.length < 44) return null;
      
      // Bounding box
      final xMin = _readDouble(bytes, 4, Endian.little);
      final yMin = _readDouble(bytes, 12, Endian.little);
      final xMax = _readDouble(bytes, 20, Endian.little);
      final yMax = _readDouble(bytes, 28, Endian.little);
      
      // Número de partes e pontos
      final numParts = _readInt32(bytes, 36, Endian.little);
      final numPoints = _readInt32(bytes, 40, Endian.little);
      
      if (numParts <= 0 || numPoints <= 0) return null;
      
      // Partes (índices dos pontos)
      final parts = <int>[];
      int offset = 44;
      
      for (int i = 0; i < numParts; i++) {
        parts.add(_readInt32(bytes, offset, Endian.little));
        offset += 4;
      }
      
      // Pontos
      final points = <LatLng>[];
      
      for (int i = 0; i < numPoints; i++) {
        final x = _readDouble(bytes, offset, Endian.little);
        final y = _readDouble(bytes, offset + 8, Endian.little);
        
        // Converter para LatLng (assumindo coordenadas geográficas)
        points.add(LatLng(y, x));
        offset += 16;
      }
      
      // Atributos (simulados por enquanto)
      final attributes = <String, dynamic>{
        'id': id,
        'area': _calculatePolygonArea(points),
        'perimeter': _calculatePolygonPerimeter(points),
        'numParts': numParts,
        'numPoints': numPoints,
      };
      
      return ShapefileFeature(
        id: id,
        geometry: points,
        attributes: attributes,
      );
      
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear polygon: $e');
      return null;
    }
  }

  /// Parse de feature do tipo Polyline
  static ShapefileFeature? _parsePolylineFeature(Uint8List bytes, String id) {
    // Implementação similar ao polygon, mas para linhas
    return _parsePolygonFeature(bytes, id); // Reutilizar por enquanto
  }

  /// Parse de feature do tipo Point
  static ShapefileFeature? _parsePointFeature(Uint8List bytes, String id) {
    try {
      if (bytes.length < 20) return null;
      
      final x = _readDouble(bytes, 4, Endian.little);
      final y = _readDouble(bytes, 12, Endian.little);
      
      final attributes = <String, dynamic>{
        'id': id,
        'x': x,
        'y': y,
      };
      
      return ShapefileFeature(
        id: id,
        geometry: [LatLng(y, x)],
        attributes: attributes,
      );
      
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear point: $e');
      return null;
    }
  }

  /// Detecta o tipo de dados baseado nas features e nome do arquivo
  static ShapefileDataType _detectDataType(List<ShapefileFeature> features, String fileName) {
    final fileNameLower = fileName.toLowerCase();
    
    // Detectar por nome do arquivo
    if (fileNameLower.contains('talhao') || fileNameLower.contains('talhão')) {
      return ShapefileDataType.talhao;
    } else if (fileNameLower.contains('maquina') || fileNameLower.contains('máquina')) {
      return ShapefileDataType.maquina;
    } else if (fileNameLower.contains('plantio')) {
      return ShapefileDataType.plantio;
    } else if (fileNameLower.contains('colheita')) {
      return ShapefileDataType.colheita;
    } else if (fileNameLower.contains('aplicacao') || fileNameLower.contains('aplicação')) {
      return ShapefileDataType.aplicacao;
    } else if (fileNameLower.contains('solo')) {
      return ShapefileDataType.solo;
    } else if (fileNameLower.contains('irrigacao') || fileNameLower.contains('irrigação')) {
      return ShapefileDataType.irrigacao;
    } else if (fileNameLower.contains('estrada')) {
      return ShapefileDataType.estrada;
    } else if (fileNameLower.contains('construcao') || fileNameLower.contains('construção')) {
      return ShapefileDataType.construcao;
    }
    
    // Detectar por atributos das features
    if (features.isNotEmpty) {
      final firstFeature = features.first;
      final attributes = firstFeature.attributes;
      
      // Verificar campos típicos de talhão
      if (attributes.containsKey('area') || attributes.containsKey('hectares') || 
          attributes.containsKey('cultura') || attributes.containsKey('safra')) {
        return ShapefileDataType.talhao;
      }
      
      // Verificar campos típicos de máquina
      if (attributes.containsKey('velocidade') || attributes.containsKey('potencia') || 
          attributes.containsKey('tipo_maquina')) {
        return ShapefileDataType.maquina;
      }
    }
    
    return ShapefileDataType.desconhecido;
  }

  /// Extrai metadados do Shapefile
  static Map<String, dynamic> _extractMetadata(Map<String, dynamic> header, List<ShapefileFeature> features) {
    return {
      'shapeType': header['shapeType'],
      'numFeatures': features.length,
      'boundingBox': {
        'xMin': header['xMin'],
        'yMin': header['yMin'],
        'xMax': header['xMax'],
        'yMax': header['yMax'],
      },
      'totalArea': features.fold(0.0, (sum, feature) => sum + (feature.attributes['area'] ?? 0.0)),
      'attributes': features.isNotEmpty ? features.first.attributes.keys.toList() : [],
    };
  }

  /// Calcula área de um polígono
  static double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximação)
    final latMedia = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final latRad = latMedia * pi / 180;
    final metersPerDegLat = 111132.954 - 559.822 * cos(2 * latRad) + 1.175 * cos(4 * latRad);
    final metersPerDegLng = (pi / 180) * 6378137.0 * cos(latRad);
    
    final areaMetersSquared = area * metersPerDegLat * metersPerDegLng;
    return areaMetersSquared / 10000.0;
  }

  /// Calcula perímetro de um polígono
  static double _calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      perimeter += _calculateDistance(points[i], points[j]);
    }
    
    return perimeter;
  }

  /// Calcula distância entre dois pontos
  static double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // metros
    
    final lat1 = p1.latitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1) * cos(lat2) *
              sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Lê inteiro de 32 bits
  static int _readInt32(Uint8List bytes, int offset, Endian endian) {
    final byteData = ByteData.sublistView(bytes, offset, offset + 4);
    return byteData.getInt32(0, endian);
  }

  /// Lê double de 64 bits
  static double _readDouble(Uint8List bytes, int offset, Endian endian) {
    final byteData = ByteData.sublistView(bytes, offset, offset + 8);
    return byteData.getFloat64(0, endian);
  }
}
