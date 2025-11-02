import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'package:archive/archive_io.dart';
import '../utils/logger.dart';
import '../utils/coordinate_normalizer.dart';
import '../utils/geometry_validator.dart';

/// 🚀 FORTSMART ORIGINAL - Resultado robusto da importação
class RobustImportResult {
  final List<List<LatLng>> polygons;
  final Map<String, dynamic> properties;
  final String sourceFormat;
  final String fileName;
  final int totalPoints;
  final double? totalArea;
  final String? error;
  final bool success;
  final List<String> warnings;

  const RobustImportResult({
    required this.polygons,
    required this.properties,
    required this.sourceFormat,
    required this.fileName,
    required this.totalPoints,
    this.totalArea,
    this.error,
    required this.success,
    this.warnings = const [],
  });

  /// Converte para lista simples de pontos (primeiro polígono)
  List<LatLng> get firstPolygonPoints {
    if (polygons.isNotEmpty) {
      return polygons.first;
    }
    return [];
  }

  /// Verifica se tem múltiplos polígonos
  bool get hasMultiplePolygons => polygons.length > 1;

  /// Obtém informações resumidas
  String get summary {
    if (!success) return 'Erro: $error';
    
    final polygonCount = polygons.length;
    final pointCount = totalPoints;
    final area = totalArea?.toStringAsFixed(2) ?? 'N/A';
    
    return '$polygonCount polígono(s), $pointCount pontos, ${area}ha';
  }
}

/// 🚀 FORTSMART ORIGINAL - Serviço robusto de importação geoespacial
class RobustGeoImportService {
  static final RobustGeoImportService _instance = RobustGeoImportService._internal();
  factory RobustGeoImportService() => _instance;
  RobustGeoImportService._internal();

  /// Importa arquivo geoespacial com detecção automática de formato
  Future<RobustImportResult> importGeoFile({
    required BuildContext context,
    List<String>? allowedExtensions,
  }) async {
    try {
      Logger.info('🚀 Iniciando importação robusta de arquivo geoespacial...');
      
      // Extensões permitidas (padrão)
      final extensions = allowedExtensions ?? [
        'geojson', 'json', 'kml', 'kmz', 'shp', 'zip'
      ];
      
      // Selecionar arquivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return RobustImportResult(
          polygons: [],
          properties: {},
          sourceFormat: 'none',
          fileName: '',
          totalPoints: 0,
          success: false,
          error: 'Nenhum arquivo selecionado',
        );
      }

      final file = result.files.first;
      Logger.info('📄 Arquivo selecionado: ${file.name} (${file.size} bytes)');

      // Detectar formato e processar
      final format = _detectFileFormat(file.name);
      final content = file.bytes;
      
      if (content == null) {
        return RobustImportResult(
          polygons: [],
          properties: {},
          sourceFormat: format,
          fileName: file.name,
          totalPoints: 0,
          success: false,
          error: 'Erro ao ler conteúdo do arquivo',
        );
      }

      // Processar baseado no formato
      switch (format) {
        case 'geojson':
          return await _processGeoJson(content, file.name);
        case 'kml':
          return await _processKml(content, file.name);
        case 'kmz':
          return await _processKmz(content, file.name);
        case 'shp':
          return await _processShapefile(content, file.name);
        case 'zip':
          return await _processZipFile(content, file.name);
        default:
          return RobustImportResult(
            polygons: [],
            properties: {},
            sourceFormat: format,
            fileName: file.name,
            totalPoints: 0,
            success: false,
            error: 'Formato não suportado: $format',
          );
      }
    } catch (e) {
      Logger.error('❌ Erro na importação robusta: $e');
      return RobustImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'unknown',
        fileName: '',
        totalPoints: 0,
        success: false,
        error: 'Erro interno: $e',
      );
    }
  }

  /// Detecta formato do arquivo baseado na extensão
  String _detectFileFormat(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'geojson':
      case 'json':
        return 'geojson';
      case 'kml':
        return 'kml';
      case 'kmz':
        return 'kmz';
      case 'shp':
        return 'shp';
      case 'zip':
        return 'zip';
      default:
        return 'unknown';
    }
  }

  /// Processa arquivo GeoJSON (versão melhorada)
  Future<RobustImportResult> _processGeoJson(Uint8List content, String fileName) async {
    try {
      final contentString = String.fromCharCodes(content);
      Logger.info('📄 Conteúdo GeoJSON: ${contentString.length} caracteres');
      
      final jsonData = json.decode(contentString);
      Logger.info('📋 Tipo de GeoJSON: ${jsonData['type']}');
      
      List<List<LatLng>> polygons = [];
      Map<String, dynamic> properties = {};
      List<String> warnings = [];
      int totalPoints = 0;

      // Processar FeatureCollection
      if (jsonData['type'] == 'FeatureCollection') {
        final features = jsonData['features'] as List;
        Logger.info('🔍 Encontradas ${features.length} features no GeoJSON');
        
        for (int i = 0; i < features.length; i++) {
          final feature = features[i];
          final geometry = feature['geometry'];
          final props = feature['properties'] ?? {};
          
          Logger.info('📋 Feature $i: tipo ${geometry['type']}');
          
          // Processar geometria
          final polygonPoints = _extractPolygonFromGeoJson(geometry);
          Logger.info('🎯 Feature $i: ${polygonPoints.length} pontos extraídos');
          
          if (polygonPoints.isNotEmpty) {
            polygons.add(polygonPoints);
            totalPoints += polygonPoints.length;
            
            // Mesclar propriedades
            properties.addAll(props);
            Logger.info('✅ Feature $i adicionada: ${polygonPoints.length} pontos');
          } else {
            warnings.add('Feature $i: geometria inválida ou vazia');
            Logger.warning('⚠️ Feature $i: geometria inválida ou vazia');
          }
        }
      }
      // Processar Feature única
      else if (jsonData['type'] == 'Feature') {
        final geometry = jsonData['geometry'];
        final props = jsonData['properties'] ?? {};
        
        Logger.info('📋 Feature única: tipo ${geometry['type']}');
        
        final polygonPoints = _extractPolygonFromGeoJson(geometry);
        Logger.info('🎯 Feature única: ${polygonPoints.length} pontos extraídos');
        
        if (polygonPoints.isNotEmpty) {
          polygons.add(polygonPoints);
          totalPoints += polygonPoints.length;
          properties.addAll(props);
          Logger.info('✅ Feature única adicionada: ${polygonPoints.length} pontos');
        } else {
          warnings.add('Geometria inválida ou vazia');
          Logger.warning('⚠️ Feature única: geometria inválida ou vazia');
        }
      }
      // Processar geometria direta
      else if (jsonData['type'] != null) {
        Logger.info('📋 Geometria direta: tipo ${jsonData['type']}');
        
        final polygonPoints = _extractPolygonFromGeoJson(jsonData);
        Logger.info('🎯 Geometria direta: ${polygonPoints.length} pontos extraídos');
        
        if (polygonPoints.isNotEmpty) {
          polygons.add(polygonPoints);
          totalPoints += polygonPoints.length;
          Logger.info('✅ Geometria direta adicionada: ${polygonPoints.length} pontos');
        } else {
          warnings.add('Geometria inválida ou vazia');
          Logger.warning('⚠️ Geometria direta: geometria inválida ou vazia');
        }
      } else {
        Logger.warning('⚠️ Tipo de GeoJSON não reconhecido');
        warnings.add('Tipo de GeoJSON não reconhecido');
      }

      Logger.info('🎯 Total de polígonos encontrados antes da validação: ${polygons.length}');
      
      // Validar e normalizar
      final validatedPolygons = _validateAndNormalizePolygons(polygons);
      
      return RobustImportResult(
        polygons: validatedPolygons,
        properties: properties,
        sourceFormat: 'geojson',
        fileName: fileName,
        totalPoints: totalPoints,
        totalArea: _calculateTotalArea(validatedPolygons),
        success: validatedPolygons.isNotEmpty,
        warnings: warnings,
        error: validatedPolygons.isEmpty ? 'Nenhum polígono válido encontrado' : null,
      );
    } catch (e) {
      Logger.error('❌ Erro ao processar GeoJSON: $e');
      return RobustImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'geojson',
        fileName: fileName,
        totalPoints: 0,
        success: false,
        error: 'Erro ao processar GeoJSON: $e',
      );
    }
  }

  /// Extrai polígono de geometria GeoJSON (versão melhorada)
  List<LatLng> _extractPolygonFromGeoJson(Map<String, dynamic> geometry) {
    final type = geometry['type'] as String?;
    Logger.info('🔍 Extraindo geometria do tipo: $type');
    
    if (type == 'Polygon') {
      final coordinates = geometry['coordinates'] as List;
      Logger.info('📐 Polygon com ${coordinates.length} anéis');
      
      if (coordinates.isNotEmpty) {
        final ring = coordinates[0] as List;
        Logger.info('📍 Primeiro anel com ${ring.length} pontos');
        
        return ring.map((coord) {
          return LatLng(
            (coord[1] as num).toDouble(), // latitude
            (coord[0] as num).toDouble(), // longitude
          );
        }).toList();
      }
    } else if (type == 'MultiPolygon') {
      final coordinates = geometry['coordinates'] as List;
      Logger.info('📐 MultiPolygon com ${coordinates.length} polígonos');
      
      if (coordinates.isNotEmpty) {
        final firstPolygon = coordinates[0] as List;
        Logger.info('📍 Primeiro polígono com ${firstPolygon.length} anéis');
        
        if (firstPolygon.isNotEmpty) {
          final ring = firstPolygon[0] as List;
          Logger.info('📍 Primeiro anel com ${ring.length} pontos');
          
          return ring.map((coord) {
            return LatLng(
              (coord[1] as num).toDouble(), // latitude
              (coord[0] as num).toDouble(), // longitude
            );
          }).toList();
        }
      }
    } else if (type == 'LineString') {
      final coordinates = geometry['coordinates'] as List;
      Logger.info('📐 LineString com ${coordinates.length} pontos');
      
      return coordinates.map((coord) {
        return LatLng(
          (coord[1] as num).toDouble(), // latitude
          (coord[0] as num).toDouble(), // longitude
        );
      }).toList();
    } else if (type == 'MultiLineString') {
      final coordinates = geometry['coordinates'] as List;
      Logger.info('📐 MultiLineString com ${coordinates.length} linestrings');
      
      if (coordinates.isNotEmpty) {
        final firstLineString = coordinates[0] as List;
        Logger.info('📍 Primeira LineString com ${firstLineString.length} pontos');
        
        return firstLineString.map((coord) {
          return LatLng(
            (coord[1] as num).toDouble(), // latitude
            (coord[0] as num).toDouble(), // longitude
          );
        }).toList();
      }
    } else if (type == 'Point') {
      final coordinates = geometry['coordinates'] as List;
      Logger.info('📐 Point com coordenadas: ${coordinates}');
      
      if (coordinates.length >= 2) {
        return [LatLng(
          (coordinates[1] as num).toDouble(), // latitude
          (coordinates[0] as num).toDouble(), // longitude
        )];
      }
    } else {
      Logger.warning('⚠️ Tipo de geometria não suportado: $type');
    }
    
    return [];
  }

  /// Processa arquivo KML (versão melhorada)
  Future<RobustImportResult> _processKml(Uint8List content, String fileName) async {
    try {
      final contentString = String.fromCharCodes(content);
      Logger.info('📄 Conteúdo KML: ${contentString.length} caracteres');
      
      final document = XmlDocument.parse(contentString);
      
      List<List<LatLng>> polygons = [];
      Map<String, dynamic> properties = {};
      List<String> warnings = [];
      int totalPoints = 0;

      // Buscar Placemarks
      final placemarks = document.findAllElements('Placemark');
      Logger.info('🔍 Encontrados ${placemarks.length} Placemarks no KML');
      
      // Se não encontrar Placemarks, tentar buscar diretamente por coordenadas
      if (placemarks.isEmpty) {
        Logger.info('🔍 Nenhum Placemark encontrado, buscando coordenadas diretamente...');
        final allCoordinates = document.findAllElements('coordinates');
        Logger.info('📍 Encontrados ${allCoordinates.length} elementos de coordenadas diretos');
        
        for (int i = 0; i < allCoordinates.length; i++) {
          final coord = allCoordinates.elementAt(i);
          final coordText = coord.innerText.trim();
          Logger.info('📐 Coordenadas diretas $i: ${coordText.length} caracteres');
          
          if (coordText.isNotEmpty) {
            final polygonPoints = _parseKmlCoordinates(coordText);
            Logger.info('🎯 Coordenadas diretas $i parseadas: ${polygonPoints.length} pontos');
            
            if (polygonPoints.isNotEmpty) {
              polygons.add(polygonPoints);
              totalPoints += polygonPoints.length;
              Logger.info('✅ Polígono direto adicionado: ${polygonPoints.length} pontos');
            }
          }
        }
      } else {
        // Processar Placemarks normalmente
        for (int i = 0; i < placemarks.length; i++) {
          final placemark = placemarks.elementAt(i);
          
          // Extrair propriedades
          final name = placemark.findElements('name').firstOrNull?.innerText ?? 'Polígono ${i + 1}';
          final description = placemark.findElements('description').firstOrNull?.innerText ?? '';
          
          Logger.info('📋 Placemark $i: $name');
          
          properties['name'] = name;
          if (description.isNotEmpty) {
            properties['description'] = description;
          }
          
          // Buscar coordenadas em diferentes elementos
          final coordinates = placemark.findElements('coordinates');
          final polygons_elements = placemark.findElements('Polygon');
          final linestrings = placemark.findElements('LineString');
          
          Logger.info('📍 Placemark $i: ${coordinates.length} coordenadas, ${polygons_elements.length} polígonos, ${linestrings.length} linestrings');
          
          // Processar coordenadas diretas
          for (int j = 0; j < coordinates.length; j++) {
            final coord = coordinates.elementAt(j);
            final coordText = coord.innerText.trim();
            Logger.info('📐 Coordenadas $j: ${coordText.length} caracteres');
            
            if (coordText.isNotEmpty) {
              final polygonPoints = _parseKmlCoordinates(coordText);
              Logger.info('🎯 Coordenadas $j parseadas: ${polygonPoints.length} pontos');
              
              if (polygonPoints.isNotEmpty) {
                polygons.add(polygonPoints);
                totalPoints += polygonPoints.length;
                Logger.info('✅ Polígono adicionado: ${polygonPoints.length} pontos');
              } else {
                warnings.add('Placemark $i: coordenadas inválidas');
                Logger.warning('⚠️ Placemark $i: coordenadas inválidas');
              }
            }
          }
          
          // Processar elementos Polygon
          for (int j = 0; j < polygons_elements.length; j++) {
            final polygonElement = polygons_elements.elementAt(j);
            final outerBoundary = polygonElement.findElements('outerBoundaryIs').firstOrNull;
            if (outerBoundary != null) {
              final linearRing = outerBoundary.findElements('LinearRing').firstOrNull;
              if (linearRing != null) {
                final coord = linearRing.findElements('coordinates').firstOrNull;
                if (coord != null) {
                  final coordText = coord.innerText.trim();
                  Logger.info('📐 Polygon $j coordenadas: ${coordText.length} caracteres');
                  
                  if (coordText.isNotEmpty) {
                    final polygonPoints = _parseKmlCoordinates(coordText);
                    Logger.info('🎯 Polygon $j parseado: ${polygonPoints.length} pontos');
                    
                    if (polygonPoints.isNotEmpty) {
                      polygons.add(polygonPoints);
                      totalPoints += polygonPoints.length;
                      Logger.info('✅ Polygon adicionado: ${polygonPoints.length} pontos');
                    }
                  }
                }
              }
            }
          }
          
          // Processar elementos LineString
          for (int j = 0; j < linestrings.length; j++) {
            final linestring = linestrings.elementAt(j);
            final coord = linestring.findElements('coordinates').firstOrNull;
            if (coord != null) {
              final coordText = coord.innerText.trim();
              Logger.info('📐 LineString $j coordenadas: ${coordText.length} caracteres');
              
              if (coordText.isNotEmpty) {
                final polygonPoints = _parseKmlCoordinates(coordText);
                Logger.info('🎯 LineString $j parseado: ${polygonPoints.length} pontos');
                
                if (polygonPoints.isNotEmpty) {
                  polygons.add(polygonPoints);
                  totalPoints += polygonPoints.length;
                  Logger.info('✅ LineString adicionado: ${polygonPoints.length} pontos');
                }
              }
            }
          }
        }
      }

      Logger.info('🎯 Total de polígonos encontrados antes da validação: ${polygons.length}');
      
      // Validar e normalizar
      final validatedPolygons = _validateAndNormalizePolygons(polygons);
      
      return RobustImportResult(
        polygons: validatedPolygons,
        properties: properties,
        sourceFormat: 'kml',
        fileName: fileName,
        totalPoints: totalPoints,
        totalArea: _calculateTotalArea(validatedPolygons),
        success: validatedPolygons.isNotEmpty,
        warnings: warnings,
        error: validatedPolygons.isEmpty ? 'Nenhum polígono válido encontrado' : null,
      );
    } catch (e) {
      Logger.error('❌ Erro ao processar KML: $e');
      return RobustImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'kml',
        fileName: fileName,
        totalPoints: 0,
        success: false,
        error: 'Erro ao processar KML: $e',
      );
    }
  }

  /// Parseia coordenadas KML
  List<LatLng> _parseKmlCoordinates(String coordText) {
    final coords = coordText.split(RegExp(r'\s+'));
    List<LatLng> points = [];
    
    for (final coord in coords) {
      if (coord.trim().isNotEmpty) {
        final parts = coord.split(',');
        if (parts.length >= 2) {
          try {
            final lng = double.parse(parts[0]);
            final lat = double.parse(parts[1]);
            points.add(LatLng(lat, lng));
          } catch (e) {
            // Ignorar coordenadas inválidas
          }
        }
      }
    }
    
    return points;
  }

  /// Processa arquivo KMZ (KML comprimido)
  Future<RobustImportResult> _processKmz(Uint8List content, String fileName) async {
    try {
      // Descomprimir KMZ
      final archive = ZipDecoder().decodeBytes(content);
      final kmlFile = archive.files.firstWhere(
        (file) => file.name.toLowerCase().endsWith('.kml'),
        orElse: () => throw Exception('Arquivo KML não encontrado no KMZ'),
      );
      
      if (kmlFile.content == null) {
        throw Exception('Conteúdo do arquivo KML vazio');
      }
      
      // Processar como KML
      return await _processKml(kmlFile.content as Uint8List, fileName);
    } catch (e) {
      Logger.error('❌ Erro ao processar KMZ: $e');
      return RobustImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'kmz',
        fileName: fileName,
        totalPoints: 0,
        success: false,
        error: 'Erro ao processar KMZ: $e',
      );
    }
  }

  /// Processa arquivo Shapefile (implementação básica)
  Future<RobustImportResult> _processShapefile(Uint8List content, String fileName) async {
    // Shapefile é um formato binário complexo
    // Esta é uma implementação básica - para produção, use biblioteca especializada
    return RobustImportResult(
      polygons: [],
      properties: {},
      sourceFormat: 'shp',
      fileName: fileName,
      totalPoints: 0,
      success: false,
      error: 'Shapefile requer implementação especializada. Use GeoJSON ou KML.',
      warnings: ['Shapefile não suportado nesta versão'],
    );
  }

  /// Processa arquivo ZIP (pode conter múltiplos formatos)
  Future<RobustImportResult> _processZipFile(Uint8List content, String fileName) async {
    try {
      final archive = ZipDecoder().decodeBytes(content);
      
      // Buscar arquivos geoespaciais
      for (final file in archive.files) {
        if (file.content != null) {
          final format = _detectFileFormat(file.name);
          
          if (format == 'geojson') {
            return await _processGeoJson(file.content as Uint8List, fileName);
          } else if (format == 'kml') {
            return await _processKml(file.content as Uint8List, fileName);
          }
        }
      }
      
      return RobustImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'zip',
        fileName: fileName,
        totalPoints: 0,
        success: false,
        error: 'Nenhum arquivo geoespacial válido encontrado no ZIP',
      );
    } catch (e) {
      Logger.error('❌ Erro ao processar ZIP: $e');
      return RobustImportResult(
        polygons: [],
        properties: {},
        sourceFormat: 'zip',
        fileName: fileName,
        totalPoints: 0,
        success: false,
        error: 'Erro ao processar ZIP: $e',
      );
    }
  }

  /// Valida e normaliza polígonos (versão mais permissiva)
  List<List<LatLng>> _validateAndNormalizePolygons(List<List<LatLng>> polygons) {
    List<List<LatLng>> validated = [];
    
    Logger.info('🔍 Validando ${polygons.length} polígonos...');
    
    for (int i = 0; i < polygons.length; i++) {
      final polygon = polygons[i];
      Logger.info('📐 Polígono $i: ${polygon.length} pontos');
      
      // Log detalhado dos primeiros pontos
      if (polygon.isNotEmpty) {
        Logger.info('📍 Primeiro ponto: ${polygon.first.latitude}, ${polygon.first.longitude}');
        if (polygon.length > 1) {
          Logger.info('📍 Segundo ponto: ${polygon[1].latitude}, ${polygon[1].longitude}');
        }
        if (polygon.length > 2) {
          Logger.info('📍 Terceiro ponto: ${polygon[2].latitude}, ${polygon[2].longitude}');
        }
      }
      
      if (polygon.length >= 3) {
        // Normalizar coordenadas
        final normalized = CoordinateNormalizer.normalize(polygon);
        Logger.info('✅ Polígono $i normalizado: ${normalized.length} pontos');
        
        // Validação mais permissiva - aceitar se tiver pelo menos 3 pontos
        bool isValid = true;
        List<String> issues = [];
        
        // Verificar coordenadas válidas
        for (int j = 0; j < normalized.length; j++) {
          final point = normalized[j];
          if (point.latitude < -90 || point.latitude > 90) {
            issues.add('Latitude inválida no ponto $j: ${point.latitude}');
            isValid = false;
          }
          if (point.longitude < -180 || point.longitude > 180) {
            issues.add('Longitude inválida no ponto $j: ${point.longitude}');
            isValid = false;
          }
        }
        
        // Verificar se não são todos pontos iguais
        bool allSame = true;
        for (int j = 1; j < normalized.length; j++) {
          if (normalized[j] != normalized[0]) {
            allSame = false;
            break;
          }
        }
        
        if (allSame) {
          issues.add('Todos os pontos são iguais');
          isValid = false;
        }
        
        if (isValid) {
          validated.add(normalized);
          Logger.info('✅ Polígono $i aceito: ${normalized.length} pontos válidos');
        } else {
          Logger.warning('⚠️ Polígono $i rejeitado: ${issues.join(", ")}');
          // Mesmo assim, tentar adicionar se tiver pelo menos 3 pontos diferentes
          if (normalized.length >= 3 && !allSame) {
            validated.add(normalized);
            Logger.info('✅ Polígono $i aceito com ressalvas: ${normalized.length} pontos');
          }
        }
      } else {
        Logger.warning('⚠️ Polígono $i ignorado: menos de 3 pontos (${polygon.length})');
      }
    }
    
    Logger.info('🎯 Total de polígonos aceitos: ${validated.length}');
    return validated;
  }

  /// Calcula área total dos polígonos
  double? _calculateTotalArea(List<List<LatLng>> polygons) {
    if (polygons.isEmpty) return null;
    
    double totalArea = 0.0;
    for (final polygon in polygons) {
      totalArea += _calculatePolygonArea(polygon);
    }
    
    return totalArea;
  }

  /// Calcula área de um polígono usando fórmula de Shoelace
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    return (area.abs() / 2.0) * 111320 * 111320 / 10000; // Aproximação para hectares
  }
}
