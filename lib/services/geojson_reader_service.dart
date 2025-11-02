import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../utils/logger.dart';

/// Tipos de dados GeoJSON suportados
enum GeoJSONDataType {
  talhao,
  machineWork,
  planting,
  harvest,
  soilSample,
  irrigation,
  unknown
}

/// Dados GeoJSON processados
class GeoJSONData {
  final GeoJSONDataType dataType;
  final List<GeoJSONFeature> features;
  final Map<String, dynamic> metadata;
  final DateTime importDate;

  GeoJSONData({
    required this.dataType,
    required this.features,
    required this.metadata,
    required this.importDate,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.toString(),
      'features': features.map((f) => {
        'id': f.id,
        'type': f.type,
        'geometry': f.geometry,
        'properties': f.properties,
      }).toList(),
      'metadata': metadata,
      'importDate': importDate.toIso8601String(),
    };
  }

  /// Converte features para talhões
  List<TalhaoModel> toTalhoes() {
    if (dataType != GeoJSONDataType.talhao) return [];
    
    return features.map((feature) {
      return TalhaoModel(
        id: feature.id ?? 'talhao_${DateTime.now().millisecondsSinceEpoch}',
        name: feature.properties['nome'] ?? 
              feature.properties['name'] ?? 
              feature.properties['NOME'] ?? 
              'Talhão ${feature.id}',
        area: _parseArea(feature.properties),
        culturaId: feature.properties['cultura_id']?.toString() ?? 
                   feature.properties['culturaId']?.toString() ?? 
                   feature.properties['CULTURA_ID']?.toString() ?? 
                   '1',
        fazendaId: feature.properties['fazenda_id']?.toString() ?? 
                   feature.properties['fazendaId']?.toString() ?? 
                   feature.properties['FAZENDA_ID']?.toString() ?? 
                   '1',
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        poligonos: _createPolygonsFromFeature(feature),
        safras: [],
      );
    }).toList();
  }

  /// Cria polígonos a partir de uma feature
  List<PoligonoModel> _createPolygonsFromFeature(GeoJSONFeature feature) {
    if (feature.geometry == null) return [];
    
    final geometry = feature.geometry!;
    List<LatLng> points = [];
    
    switch (geometry['type']) {
      case 'Polygon':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final ring = coordinates[0] as List;
          points = ring.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
        break;
      case 'MultiPolygon':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.isNotEmpty && coordinates[0].isNotEmpty) {
          final ring = coordinates[0][0] as List;
          points = ring.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
        break;
      case 'Point':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.length >= 2) {
          points = [LatLng(coordinates[1], coordinates[0])];
        }
        break;
    }
    
    if (points.isEmpty) return [];
    
    return [
      PoligonoModel(
        id: '${feature.id}_polygon',
        pontos: points,
        area: _parseArea(feature.properties),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        perimetro: 0.0,
        talhaoId: feature.id ?? 'talhao_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ];
  }

  /// Extrai área das propriedades
  double _parseArea(Map<String, dynamic> properties) {
    final area = properties['area'] ?? 
                 properties['AREA'] ?? 
                 properties['hectares'] ?? 
                 properties['HECTARES'] ?? 
                 properties['area_ha'] ?? 
                 properties['AREA_HA'];
    
    if (area != null) {
      return double.tryParse(area.toString()) ?? 0.0;
    }
    
    return 0.0;
  }
}

/// Feature GeoJSON
class GeoJSONFeature {
  final String? id;
  final String? type;
  final Map<String, dynamic>? geometry;
  final Map<String, dynamic> properties;

  GeoJSONFeature({
    this.id,
    this.type,
    this.geometry,
    required this.properties,
  });

  factory GeoJSONFeature.fromJson(Map<String, dynamic> json) {
    return GeoJSONFeature(
      id: json['id']?.toString(),
      type: json['type'],
      geometry: json['geometry'],
      properties: json['properties'] ?? {},
    );
  }
}

/// Serviço para leitura e processamento de arquivos GeoJSON
class GeoJSONReaderService {
  
  /// Lê e processa arquivo GeoJSON
  static Future<GeoJSONData> readGeoJSONFile(File file) async {
    try {
      Logger.info('🔄 [GEOJSON] Iniciando leitura do arquivo: ${file.path}');
      
      // Verificar se o arquivo existe
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: ${file.path}');
      }
      
      // Ler conteúdo do arquivo
      final content = await file.readAsString();
      Logger.info('📄 [GEOJSON] Arquivo lido com sucesso (${content.length} caracteres)');
      
      // Parsear JSON
      final jsonData = json.decode(content);
      Logger.info('✅ [GEOJSON] JSON parseado com sucesso');
      
      // Processar dados GeoJSON
      final geoJSONData = _processGeoJSON(jsonData, file.path);
      Logger.info('🎯 [GEOJSON] Dados processados: ${geoJSONData.features.length} features, tipo: ${geoJSONData.dataType}');
      
      return geoJSONData;
      
    } catch (e) {
      Logger.error('❌ [GEOJSON] Erro ao ler arquivo: $e');
      rethrow;
    }
  }

  /// Processa dados GeoJSON
  static GeoJSONData _processGeoJSON(Map<String, dynamic> jsonData, String filePath) {
    try {
      // Verificar estrutura GeoJSON
      if (jsonData['type'] != 'FeatureCollection') {
        throw Exception('Formato GeoJSON inválido. Esperado FeatureCollection, recebido: ${jsonData['type']}');
      }
      
      final features = jsonData['features'] as List? ?? [];
      if (features.isEmpty) {
        throw Exception('Nenhuma feature encontrada no arquivo GeoJSON');
      }
      
      // Processar features
      final processedFeatures = features.map((feature) {
        return GeoJSONFeature.fromJson(feature as Map<String, dynamic>);
      }).toList();
      
      // Detectar tipo de dados
      final dataType = _detectDataType(processedFeatures);
      
      // Extrair metadados
      final metadata = _extractMetadata(jsonData, filePath);
      
      return GeoJSONData(
        dataType: dataType,
        features: processedFeatures,
        metadata: metadata,
        importDate: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON] Erro ao processar dados: $e');
      rethrow;
    }
  }

  /// Detecta o tipo de dados baseado nas propriedades das features
  static GeoJSONDataType _detectDataType(List<GeoJSONFeature> features) {
    if (features.isEmpty) return GeoJSONDataType.unknown;
    
    // Analisar propriedades da primeira feature
    final firstFeature = features.first;
    final properties = firstFeature.properties;
    
    // Verificar campos específicos para cada tipo
    final propertyKeys = properties.keys.map((k) => k.toLowerCase()).toSet();
    
    // Talhão
    if (propertyKeys.any((key) => ['talhao', 'talhão', 'parcel', 'field'].contains(key)) ||
        propertyKeys.any((key) => ['cultura', 'crop', 'cultivo'].contains(key)) ||
        propertyKeys.any((key) => ['area', 'área', 'hectares'].contains(key))) {
      return GeoJSONDataType.talhao;
    }
    
    // Trabalho de máquina
    if (propertyKeys.any((key) => ['maquina', 'máquina', 'machine', 'equipment'].contains(key)) ||
        propertyKeys.any((key) => ['aplicacao', 'aplicação', 'application'].contains(key)) ||
        propertyKeys.any((key) => ['dose', 'rate', 'vazao', 'vazão'].contains(key))) {
      return GeoJSONDataType.machineWork;
    }
    
    // Plantio
    if (propertyKeys.any((key) => ['plantio', 'planting', 'semente', 'seed'].contains(key)) ||
        propertyKeys.any((key) => ['variedade', 'variety', 'cultivar'].contains(key))) {
      return GeoJSONDataType.planting;
    }
    
    // Colheita
    if (propertyKeys.any((key) => ['colheita', 'harvest', 'producao', 'produção'].contains(key)) ||
        propertyKeys.any((key) => ['rendimento', 'yield', 'produtividade'].contains(key))) {
      return GeoJSONDataType.harvest;
    }
    
    // Amostra de solo
    if (propertyKeys.any((key) => ['solo', 'soil', 'ph', 'nutriente', 'nutrient'].contains(key)) ||
        propertyKeys.any((key) => ['analise', 'análise', 'analysis'].contains(key))) {
      return GeoJSONDataType.soilSample;
    }
    
    // Irrigação
    if (propertyKeys.any((key) => ['irrigacao', 'irrigação', 'irrigation', 'agua', 'água'].contains(key)) ||
        propertyKeys.any((key) => ['pivo', 'pivot', 'gotejamento', 'drip'].contains(key))) {
      return GeoJSONDataType.irrigation;
    }
    
    return GeoJSONDataType.unknown;
  }

  /// Extrai metadados do arquivo
  static Map<String, dynamic> _extractMetadata(Map<String, dynamic> jsonData, String filePath) {
    final metadata = <String, dynamic>{
      'fileName': filePath.split('/').last,
      'filePath': filePath,
      'fileSize': File(filePath).lengthSync(),
      'featureCount': (jsonData['features'] as List?)?.length ?? 0,
      'crs': jsonData['crs'] ?? 'EPSG:4326',
      'bbox': jsonData['bbox'],
    };
    
    // Adicionar propriedades comuns se existirem
    final features = jsonData['features'] as List? ?? [];
    if (features.isNotEmpty) {
      final firstFeature = features.first as Map<String, dynamic>;
      final properties = firstFeature['properties'] as Map<String, dynamic>? ?? {};
      
      // Extrair campos comuns
      final commonFields = ['fazenda', 'fazenda_id', 'fazendaId', 'farm', 'farm_id'];
      for (final field in commonFields) {
        if (properties.containsKey(field)) {
          metadata['fazenda'] = properties[field];
          break;
        }
      }
    }
    
    return metadata;
  }

  /// Valida estrutura GeoJSON
  static bool validateGeoJSON(Map<String, dynamic> jsonData) {
    try {
      // Verificar tipo
      if (jsonData['type'] != 'FeatureCollection') {
        return false;
      }
      
      // Verificar features
      final features = jsonData['features'] as List?;
      if (features == null || features.isEmpty) {
        return false;
      }
      
      // Verificar estrutura de cada feature
      for (final feature in features) {
        if (feature is! Map<String, dynamic>) {
          return false;
        }
        
        if (feature['type'] != 'Feature') {
          return false;
        }
        
        if (feature['geometry'] == null || feature['properties'] == null) {
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      Logger.error('❌ [GEOJSON] Erro na validação: $e');
      return false;
    }
  }

  /// Calcula estatísticas do arquivo GeoJSON
  static Map<String, dynamic> calculateStatistics(GeoJSONData data) {
    final stats = <String, dynamic>{
      'totalFeatures': data.features.length,
      'dataType': data.dataType.toString(),
      'importDate': data.importDate.toIso8601String(),
      'fileSize': data.metadata['fileSize'] ?? 0,
      'fileName': data.metadata['fileName'] ?? 'unknown',
    };
    
    // Estatísticas por tipo de dados
    switch (data.dataType) {
      case GeoJSONDataType.talhao:
        stats['totalArea'] = _calculateTotalArea(data.features);
        stats['averageArea'] = _calculateAverageArea(data.features);
        break;
      case GeoJSONDataType.machineWork:
        stats['totalDose'] = _calculateTotalDose(data.features);
        stats['averageDose'] = _calculateAverageDose(data.features);
        break;
      default:
        // Estatísticas genéricas
        break;
    }
    
    return stats;
  }

  /// Calcula área total das features
  static double _calculateTotalArea(List<GeoJSONFeature> features) {
    double total = 0.0;
    for (final feature in features) {
      final area = feature.properties['area'] ?? 
                   feature.properties['AREA'] ?? 
                   feature.properties['hectares'] ?? 
                   feature.properties['HECTARES'] ?? 0.0;
      total += double.tryParse(area.toString()) ?? 0.0;
    }
    return total;
  }

  /// Calcula área média das features
  static double _calculateAverageArea(List<GeoJSONFeature> features) {
    if (features.isEmpty) return 0.0;
    return _calculateTotalArea(features) / features.length;
  }

  /// Calcula dose total das features
  static double _calculateTotalDose(List<GeoJSONFeature> features) {
    double total = 0.0;
    for (final feature in features) {
      final dose = feature.properties['dose'] ?? 
                   feature.properties['DOSE'] ?? 
                   feature.properties['rate'] ?? 
                   feature.properties['RATE'] ?? 0.0;
      total += double.tryParse(dose.toString()) ?? 0.0;
    }
    return total;
  }

  /// Calcula dose média das features
  static double _calculateAverageDose(List<GeoJSONFeature> features) {
    if (features.isEmpty) return 0.0;
    return _calculateTotalDose(features) / features.length;
  }
}
