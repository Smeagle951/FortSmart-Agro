import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Serviço avançado de importação de arquivos geográficos
class AdvancedImportService {
  
  /// Tipos de arquivo suportados
  static const List<String> supportedExtensions = ['kml', 'geojson', 'json', 'shp', 'zip'];
  
  /// Importa arquivo com detecção automática de formato
  Future<List<Map<String, dynamic>>> importFile(File file) async {
    try {
      Logger.info('🔄 Iniciando importação do arquivo: ${file.path}');
      
      // Validar arquivo
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }
      
      final extension = _getFileExtension(file.path);
      Logger.info('📁 Extensão detectada: $extension');
      
      // Importar baseado na extensão
      List<Map<String, dynamic>> polygons = [];
      
      switch (extension.toLowerCase()) {
        case 'kml':
          polygons = await _importKMLAdvanced(file);
          break;
        case 'geojson':
        case 'json':
          polygons = await _importGeoJSONAdvanced(file);
          break;
        case 'shp':
        case 'zip':
          polygons = await _importShapefileAdvanced(file);
          break;
        default:
          throw Exception('Formato de arquivo não suportado: $extension');
      }
      
      // Validar resultados com mais detalhes
      if (polygons.isEmpty) {
        // Tentar diagnosticar o problema
        final diagnosis = await _diagnoseImportProblem(file, extension);
                 throw Exception('Nenhum polígono, MultiPolygon ou LineString válido encontrado no arquivo. $diagnosis');
      }
      
      Logger.info('✅ Importação concluída: ${polygons.length} polígonos encontrados');
      return polygons;
      
    } catch (e) {
      Logger.error('❌ Erro na importação: $e');
      rethrow;
    }
  }
  
  /// Diagnostica problemas na importação
  Future<String> _diagnoseImportProblem(File file, String extension) async {
    try {
      final content = await file.readAsString();
      
      if (extension == 'kml') {
        return _diagnoseKMLProblem(content);
      } else if (extension == 'geojson' || extension == 'json') {
        return _diagnoseGeoJSONProblem(content);
      }
      
      return 'Verifique se o arquivo contém geometrias do tipo Polygon ou MultiPolygon.';
    } catch (e) {
      return 'Erro ao analisar arquivo: $e';
    }
  }
  
  /// Diagnostica problemas em arquivos KML
  String _diagnoseKMLProblem(String content) {
    final issues = <String>[];
    final suggestions = <String>[];
    
    if (!content.contains('<kml')) {
      issues.add('Arquivo não parece ser um KML válido (falta tag <kml>)');
    }
    
    if (!content.contains('<Placemark')) {
      issues.add('Nenhum Placemark encontrado no arquivo');
    }
    
    // Verificar diferentes tipos de geometrias
    final hasPolygon = content.contains('<Polygon');
    final hasMultiGeometry = content.contains('<MultiGeometry');
    final hasLineString = content.contains('<LineString');
    final hasPoint = content.contains('<Point');
    final hasLinearRing = content.contains('<LinearRing');
    
    if (!hasPolygon && !hasMultiGeometry && !hasLineString) {
      issues.add('Nenhuma geometria Polygon, MultiGeometry ou LineString encontrada');
      
      if (hasPoint) {
        suggestions.add('Arquivo contém apenas pontos - não é possível criar polígono');
      }
      if (hasLinearRing) {
        suggestions.add('Arquivo contém LinearRing - deve estar dentro de um Polygon');
      }
    } else if (hasLineString && !hasPolygon && !hasMultiGeometry) {
      suggestions.add('LineString encontrado - será convertido automaticamente para Polygon');
    }
    
    if (!content.contains('<coordinates')) {
      issues.add('Nenhuma coordenada encontrada no arquivo');
    }
    
    // Verificar estrutura específica
    if (content.contains('<Placemark') && !content.contains('<Polygon') && !content.contains('<MultiGeometry')) {
      suggestions.add('Placemarks encontrados mas sem geometrias Polygon - verifique a estrutura do KML');
    }
    
    if (issues.isEmpty) {
      return 'Arquivo KML parece válido, mas nenhum polígono foi extraído. Verifique se as coordenadas estão no formato correto (longitude,latitude,altitude).';
    }
    
    String result = issues.join('. ');
    if (suggestions.isNotEmpty) {
      result += '\n\n💡 Sugestões:';
      for (final suggestion in suggestions) {
        result += '\n• $suggestion';
      }
    }
    
    return result;
  }
  
  /// Diagnostica problemas em arquivos GeoJSON
  String _diagnoseGeoJSONProblem(String content) {
    try {
      final json = jsonDecode(content);
      final issues = <String>[];
      final suggestions = <String>[];
      
      if (json['type'] == null) {
        issues.add('Campo "type" não encontrado no GeoJSON');
      } else {
        final type = json['type'] as String;
        if (!['FeatureCollection', 'Feature', 'Polygon', 'MultiPolygon'].contains(type)) {
          issues.add('Tipo de geometria não suportado: $type');
          suggestions.add('Tipos suportados: FeatureCollection, Feature, Polygon, MultiPolygon');
        }
      }
      
      if (json['type'] == 'FeatureCollection') {
        final features = json['features'] as List?;
        if (features == null || features.isEmpty) {
          issues.add('FeatureCollection vazio ou sem features');
        } else {
          int polygonCount = 0;
          int lineStringCount = 0;
          int pointCount = 0;
          
          for (final feature in features) {
            final geometryType = feature['geometry']?['type'] as String?;
            if (geometryType == 'Polygon' || geometryType == 'MultiPolygon') {
              polygonCount++;
            } else if (geometryType == 'LineString') {
              lineStringCount++;
            } else if (geometryType == 'Point') {
              pointCount++;
            }
          }
          
          if (polygonCount == 0 && lineStringCount == 0) {
            issues.add('Nenhuma feature com geometria Polygon, MultiPolygon ou LineString encontrada');
            
            if (pointCount > 0) {
              suggestions.add('Encontrados $pointCount Points - não é possível criar polígono a partir de pontos');
            }
          } else if (lineStringCount > 0 && polygonCount == 0) {
            suggestions.add('Encontrados $lineStringCount LineStrings - serão convertidos automaticamente para Polygon');
          }
        }
      } else if (json['type'] == 'Feature') {
        final geometryType = json['geometry']?['type'] as String?;
        if (geometryType != 'Polygon' && geometryType != 'MultiPolygon') {
          issues.add('Feature com geometria não suportada: $geometryType');
          if (geometryType == 'LineString') {
            suggestions.add('Converta LineString para Polygon fechando a linha');
          }
        }
      }
      
      if (issues.isEmpty) {
        return 'Arquivo GeoJSON parece válido, mas nenhum polígono foi extraído. Verifique se as coordenadas estão no formato correto [longitude, latitude].';
      }
      
      String result = issues.join('. ');
      if (suggestions.isNotEmpty) {
        result += '\n\n💡 Sugestões:';
        for (final suggestion in suggestions) {
          result += '\n• $suggestion';
        }
      }
      
      return result;
    } catch (e) {
      return 'Erro ao analisar GeoJSON: $e';
    }
  }
  
  /// Importação avançada de KML
  Future<List<Map<String, dynamic>>> _importKMLAdvanced(File file) async {
    try {
      final content = await file.readAsString();
      Logger.info('📄 Conteúdo KML carregado: ${content.length} caracteres');
      
      final document = XmlDocument.parse(content);
      
      final polygons = <Map<String, dynamic>>[];
      
      // Buscar diferentes tipos de geometrias
      final placemarks = document.findAllElements('Placemark');
      Logger.info('📍 Placemarks encontrados: ${placemarks.length}');
      
      for (int i = 0; i < placemarks.length; i++) {
        final placemark = placemarks.elementAt(i);
        try {
          Logger.info('🔍 Processando Placemark ${i + 1}/${placemarks.length}');
          
          // Verificar se tem Polygon
          final polygonElement = placemark.findElements('Polygon').firstOrNull;
          if (polygonElement != null) {
            Logger.info('📐 Polygon encontrado no Placemark ${i + 1}');
            final polygon = await _parseKMLPolygon(placemark, polygonElement);
            if (polygon != null) {
              polygons.add(polygon);
              Logger.info('✅ Polygon ${i + 1} processado com sucesso');
            } else {
              Logger.warning('⚠️ Polygon ${i + 1} não pôde ser processado');
            }
          }
          
          // Verificar se tem LineString (pode ser convertido para Polygon)
          final lineStringElement = placemark.findElements('LineString').firstOrNull;
          if (lineStringElement != null) {
            Logger.info('📏 LineString encontrado no Placemark ${i + 1} - convertendo para Polygon');
            final polygon = await _parseKMLLineStringAsPolygon(placemark, lineStringElement);
            if (polygon != null) {
              polygons.add(polygon);
              Logger.info('✅ LineString ${i + 1} convertido para Polygon com sucesso');
            } else {
              Logger.warning('⚠️ LineString ${i + 1} não pôde ser convertido');
            }
          }
          
          // Verificar se tem MultiGeometry
          final multiGeometryElement = placemark.findElements('MultiGeometry').firstOrNull;
          if (multiGeometryElement != null) {
            Logger.info('🔗 MultiGeometry encontrado no Placemark ${i + 1}');
            final multiPolygons = await _parseKMLMultiGeometry(placemark, multiGeometryElement);
            polygons.addAll(multiPolygons);
            Logger.info('✅ MultiGeometry ${i + 1} processado: ${multiPolygons.length} polígonos');
          }
          
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar Placemark ${i + 1}: $e');
          continue;
        }
      }
      
      Logger.info('📊 Total de polígonos extraídos do KML: ${polygons.length}');
      return polygons;
      
    } catch (e) {
      Logger.error('❌ Erro ao importar KML: $e');
      rethrow;
    }
  }
  
  /// Parse Polygon do KML
  Future<Map<String, dynamic>?> _parseKMLPolygon(XmlElement placemark, XmlElement polygonElement) async {
    try {
      // Nome e descrição
      final name = placemark.findElements('name').firstOrNull?.text ?? 'Polígono Importado';
      final description = placemark.findElements('description').firstOrNull?.text ?? '';
      
      Logger.info('📝 Processando polígono: $name');
      
      // Coordenadas
      final outerBoundaryElement = polygonElement.findElements('outerBoundaryIs').firstOrNull;
      if (outerBoundaryElement == null) {
        Logger.warning('⚠️ outerBoundaryIs não encontrado');
        return null;
      }
      
      final coordinatesElement = outerBoundaryElement.findElements('coordinates').firstOrNull;
      if (coordinatesElement == null) {
        Logger.warning('⚠️ coordinates não encontrado');
        return null;
      }
      
      final coordinatesText = coordinatesElement.text.trim();
      Logger.info('📍 Coordenadas encontradas: ${coordinatesText.length} caracteres');
      
      final points = _parseKMLCoordinates(coordinatesText);
      Logger.info('📍 Pontos extraídos: ${points.length}');
      
      if (points.length < 3) {
        Logger.warning('⚠️ Polígono com menos de 3 pontos: ${points.length}');
        return null;
      }
      
      // Calcular métricas
      final area = _calculateArea(points);
      final perimeter = _calculatePerimeter(points);
      
      Logger.info('📊 Métricas calculadas: ${area.toStringAsFixed(2)} ha, ${perimeter.toStringAsFixed(1)} m');
      
      return {
        'name': name,
        'description': description,
        'points': points,
        'areaHa': area,
        'perimeterM': perimeter,
        'method': 'importado',
        'source': 'kml',
        'geometryType': 'Polygon',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear Polygon KML: $e');
      return null;
    }
  }
  
  /// Parse LineString do KML e converte para Polygon
  Future<Map<String, dynamic>?> _parseKMLLineStringAsPolygon(XmlElement placemark, XmlElement lineStringElement) async {
    try {
      // Nome e descrição
      final name = placemark.findElements('name').firstOrNull?.text ?? 'Polígono Importado (LineString)';
      final description = placemark.findElements('description').firstOrNull?.text ?? '';
      
      Logger.info('📝 Processando LineString: $name');
      
      // Coordenadas
      final coordinatesElement = lineStringElement.findElements('coordinates').firstOrNull;
      if (coordinatesElement == null) {
        Logger.warning('⚠️ coordinates não encontrado no LineString');
        return null;
      }
      
      final coordinatesText = coordinatesElement.text.trim();
      Logger.info('📍 Coordenadas encontradas: ${coordinatesText.length} caracteres');
      
      final points = _parseKMLCoordinates(coordinatesText);
      Logger.info('📍 Pontos extraídos: ${points.length}');
      
      if (points.length < 3) {
        Logger.warning('⚠️ LineString com menos de 3 pontos: ${points.length}');
        return null;
      }
      
      // Fechar o LineString para formar um Polygon
      if (points.first.latitude != points.last.latitude || points.first.longitude != points.last.longitude) {
        points.add(points.first); // Adicionar o primeiro ponto no final para fechar
        Logger.info('🔗 LineString fechado para formar Polygon');
      }
      
      // Calcular métricas
      final area = _calculateArea(points);
      final perimeter = _calculatePerimeter(points);
      
      Logger.info('📊 Métricas calculadas: ${area.toStringAsFixed(2)} ha, ${perimeter.toStringAsFixed(1)} m');
      
      return {
        'name': name,
        'description': description,
        'points': points,
        'areaHa': area,
        'perimeterM': perimeter,
        'method': 'importado',
        'source': 'kml',
        'geometryType': 'Polygon',
        'originalType': 'LineString',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear LineString KML: $e');
      return null;
    }
  }

  /// Parse MultiGeometry do KML
  Future<List<Map<String, dynamic>>> _parseKMLMultiGeometry(XmlElement placemark, XmlElement multiGeometryElement) async {
    final polygons = <Map<String, dynamic>>[];
    
    try {
      final polygonElements = multiGeometryElement.findElements('Polygon');
      final lineStringElements = multiGeometryElement.findElements('LineString');
      
      Logger.info('🔗 MultiGeometry com ${polygonElements.length} polígonos e ${lineStringElements.length} linhas');
      
      // Processar polígonos
      final polygonElementsList = polygonElements.toList();
      for (int i = 0; i < polygonElementsList.length; i++) {
        final polygon = await _parseKMLPolygon(placemark, polygonElementsList[i]);
        if (polygon != null) {
          // Adicionar índice ao nome se houver múltiplos
          if (polygonElementsList.length > 1 || lineStringElements.isNotEmpty) {
            polygon['name'] = '${polygon['name']} (${i + 1})';
          }
          polygons.add(polygon);
        }
      }
      
      // Processar LineStrings
      final lineStringElementsList = lineStringElements.toList();
      for (int i = 0; i < lineStringElementsList.length; i++) {
        final polygon = await _parseKMLLineStringAsPolygon(placemark, lineStringElementsList[i]);
        if (polygon != null) {
          // Adicionar índice ao nome se houver múltiplos
          if (lineStringElementsList.length > 1 || polygonElements.isNotEmpty) {
            polygon['name'] = '${polygon['name']} (${i + 1})';
          }
          polygons.add(polygon);
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear MultiGeometry: $e');
    }
    
    return polygons;
  }
  
  /// Parse coordenadas KML com melhor tratamento de erros
  List<LatLng> _parseKMLCoordinates(String coordinates) {
    final points = <LatLng>[];
    final lines = coordinates.split('\n');
    
    Logger.info('📍 Processando ${lines.length} linhas de coordenadas');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      try {
        final parts = trimmed.split(RegExp(r'\s+'));
        
        for (final part in parts) {
          if (part.trim().isEmpty) continue;
          
          final coordParts = part.split(',');
          if (coordParts.length >= 2) {
            final lon = double.tryParse(coordParts[0].trim());
            final lat = double.tryParse(coordParts[1].trim());
            
            if (lon != null && lat != null) {
              // Validar coordenadas
              if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
                points.add(LatLng(lat, lon));
              } else {
                Logger.warning('⚠️ Coordenadas inválidas na linha ${i + 1}: $part');
              }
            } else {
              Logger.warning('⚠️ Não foi possível converter coordenadas na linha ${i + 1}: $part');
            }
          }
        }
      } catch (e) {
        Logger.warning('⚠️ Erro ao processar linha ${i + 1}: $e');
      }
    }
    
    Logger.info('📍 Total de pontos válidos extraídos: ${points.length}');
    return points;
  }
  
  /// Importação avançada de GeoJSON
  Future<List<Map<String, dynamic>>> _importGeoJSONAdvanced(File file) async {
    try {
      final content = await file.readAsString();
      Logger.info('📄 Conteúdo GeoJSON carregado: ${content.length} caracteres');
      
      final json = jsonDecode(content);
      
      final polygons = <Map<String, dynamic>>[];
      
      Logger.info('📊 Tipo GeoJSON: ${json['type']}');
      
      if (json['type'] == 'FeatureCollection') {
        // FeatureCollection
        final features = json['features'] as List;
        Logger.info('📋 Features encontradas: ${features.length}');
        
        for (int i = 0; i < features.length; i++) {
          final feature = features[i];
          Logger.info('🔍 Processando Feature ${i + 1}/${features.length}');
          
          final featurePolygons = await _parseGeoJSONFeature(feature);
          polygons.addAll(featurePolygons);
          
          Logger.info('✅ Feature ${i + 1} processada: ${featurePolygons.length} polígonos');
        }
      } else if (json['type'] == 'Feature') {
        // Feature única
        Logger.info('🔍 Processando Feature única');
        final featurePolygons = await _parseGeoJSONFeature(json);
        polygons.addAll(featurePolygons);
      } else if (json['type'] == 'Polygon') {
        // Polygon direto
        Logger.info('📐 Processando Polygon direto');
        final polygon = await _parseGeoJSONPolygon(json);
        if (polygon != null) {
          polygons.add(polygon);
        }
      } else if (json['type'] == 'MultiPolygon') {
        // MultiPolygon direto
        Logger.info('🔗 Processando MultiPolygon direto');
        final multiPolygons = await _parseGeoJSONMultiPolygon(json);
        polygons.addAll(multiPolygons);
      }
      
      Logger.info('📊 Total de polígonos extraídos do GeoJSON: ${polygons.length}');
      return polygons;
      
    } catch (e) {
      Logger.error('❌ Erro ao importar GeoJSON: $e');
      rethrow;
    }
  }
  
  /// Parse Feature do GeoJSON
  Future<List<Map<String, dynamic>>> _parseGeoJSONFeature(Map<String, dynamic> feature) async {
    final polygons = <Map<String, dynamic>>[];
    
    try {
      final geometry = feature['geometry'];
      final properties = feature['properties'] ?? {};
      
      if (geometry == null) {
        Logger.warning('⚠️ Feature sem geometria');
        return polygons;
      }
      
      final geometryType = geometry['type'] as String?;
      Logger.info('📐 Tipo de geometria: $geometryType');
      
             if (geometryType == 'Polygon') {
         final polygon = await _parseGeoJSONPolygon(geometry, properties);
         if (polygon != null) {
           polygons.add(polygon);
         }
       } else if (geometryType == 'MultiPolygon') {
         final multiPolygons = await _parseGeoJSONMultiPolygon(geometry, properties);
         polygons.addAll(multiPolygons);
       } else if (geometryType == 'LineString') {
         Logger.info('📏 LineString encontrado - convertendo para Polygon');
         final polygon = await _parseGeoJSONLineStringAsPolygon(geometry, properties);
         if (polygon != null) {
           polygons.add(polygon);
         }
       } else {
         Logger.warning('⚠️ Tipo de geometria não suportado: $geometryType');
       }
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear Feature: $e');
    }
    
    return polygons;
  }
  
  /// Parse Polygon do GeoJSON
  Future<Map<String, dynamic>?> _parseGeoJSONPolygon(
    Map<String, dynamic> geometry, 
    [Map<String, dynamic> properties = const {}]
  ) async {
    try {
      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        Logger.warning('⚠️ Polygon sem coordenadas');
        return null;
      }
      
      // Primeiro anel (exterior)
      final exteriorRing = coordinates[0] as List?;
      if (exteriorRing == null) {
        Logger.warning('⚠️ Polygon sem anel exterior');
        return null;
      }
      
      final points = <LatLng>[];
      
      for (int i = 0; i < exteriorRing.length; i++) {
        final coord = exteriorRing[i];
        if (coord is List && coord.length >= 2) {
          final lon = coord[0] as double;
          final lat = coord[1] as double;
          
          // Validar coordenadas
          if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
            points.add(LatLng(lat, lon));
          } else {
            Logger.warning('⚠️ Coordenadas inválidas no ponto $i: [$lon, $lat]');
          }
        }
      }
      
      Logger.info('📍 Pontos extraídos do Polygon: ${points.length}');
      
      if (points.length < 3) {
        Logger.warning('⚠️ Polygon com menos de 3 pontos: ${points.length}');
        return null;
      }
      
      // Calcular métricas
      final area = _calculateArea(points);
      final perimeter = _calculatePerimeter(points);
      
      final name = properties['name'] ?? properties['NAME'] ?? 'Polígono Importado';
      Logger.info('📝 Polygon processado: $name (${area.toStringAsFixed(2)} ha)');
      
      return {
        'name': name,
        'description': properties['description'] ?? properties['DESCRIPTION'] ?? '',
        'points': points,
        'areaHa': area,
        'perimeterM': perimeter,
        'method': 'importado',
        'source': 'geojson',
        'properties': properties,
        'geometryType': 'Polygon',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear Polygon: $e');
      return null;
    }
  }
  
  /// Parse LineString do GeoJSON e converte para Polygon
  Future<Map<String, dynamic>?> _parseGeoJSONLineStringAsPolygon(
    Map<String, dynamic> geometry,
    [Map<String, dynamic> properties = const {}]
  ) async {
    try {
      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        Logger.warning('⚠️ LineString sem coordenadas');
        return null;
      }
      
      final points = <LatLng>[];
      
      for (int i = 0; i < coordinates.length; i++) {
        final coord = coordinates[i];
        if (coord is List && coord.length >= 2) {
          final lon = coord[0] as double;
          final lat = coord[1] as double;
          
          // Validar coordenadas
          if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
            points.add(LatLng(lat, lon));
          } else {
            Logger.warning('⚠️ Coordenadas inválidas no ponto $i: [$lon, $lat]');
          }
        }
      }
      
      Logger.info('📍 Pontos extraídos do LineString: ${points.length}');
      
      if (points.length < 3) {
        Logger.warning('⚠️ LineString com menos de 3 pontos: ${points.length}');
        return null;
      }
      
      // Fechar o LineString para formar um Polygon
      if (points.first.latitude != points.last.latitude || points.first.longitude != points.last.longitude) {
        points.add(points.first); // Adicionar o primeiro ponto no final para fechar
        Logger.info('🔗 LineString fechado para formar Polygon');
      }
      
      // Calcular métricas
      final area = _calculateArea(points);
      final perimeter = _calculatePerimeter(points);
      
      final name = properties['name'] ?? properties['NAME'] ?? 'Polígono Importado (LineString)';
      Logger.info('📝 LineString processado: $name (${area.toStringAsFixed(2)} ha)');
      
      return {
        'name': name,
        'description': properties['description'] ?? properties['DESCRIPTION'] ?? '',
        'points': points,
        'areaHa': area,
        'perimeterM': perimeter,
        'method': 'importado',
        'source': 'geojson',
        'properties': properties,
        'geometryType': 'Polygon',
        'originalType': 'LineString',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear LineString: $e');
      return null;
    }
  }

  /// Parse MultiPolygon do GeoJSON
  Future<List<Map<String, dynamic>>> _parseGeoJSONMultiPolygon(
    Map<String, dynamic> geometry,
    [Map<String, dynamic> properties = const {}]
  ) async {
    final polygons = <Map<String, dynamic>>[];
    
    try {
      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null) {
        Logger.warning('⚠️ MultiPolygon sem coordenadas');
        return polygons;
      }
      
      Logger.info('🔗 MultiPolygon com ${coordinates.length} polígonos');
      
      for (int i = 0; i < coordinates.length; i++) {
        final polygonCoords = coordinates[i] as List?;
        if (polygonCoords == null) {
          Logger.warning('⚠️ Polígono $i sem coordenadas');
          continue;
        }
        
        final polygonGeometry = {
          'type': 'Polygon',
          'coordinates': polygonCoords,
        };
        
        final polygon = await _parseGeoJSONPolygon(polygonGeometry, properties);
        if (polygon != null) {
          // Adicionar índice ao nome se houver múltiplos
          if (coordinates.length > 1) {
            polygon['name'] = '${polygon['name']} (${i + 1})';
          }
          polygons.add(polygon);
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao parsear MultiPolygon: $e');
    }
    
    return polygons;
  }
  
  /// Importação de Shapefile (simulada - requer biblioteca específica)
  Future<List<Map<String, dynamic>>> _importShapefileAdvanced(File file) async {
    // Por enquanto, retornar erro informando que precisa de biblioteca específica
    throw Exception('Importação de Shapefile requer biblioteca específica. Use formato KML ou GeoJSON.');
  }
  
  /// Calcula área em hectares usando fórmula de Gauss
  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximação)
    // 1 grau² ≈ 111.32 km² na latitude média do Brasil
    const km2PerDegree2 = 111.32 * 111.32;
    const haPerKm2 = 100.0;
    
    return area * km2PerDegree2 * haPerKm2;
  }
  
  /// Calcula perímetro em metros
  double _calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      perimeter += _calculateDistance(points[i], points[j]);
    }
    
    return perimeter;
  }
  
  /// Calcula distância entre dois pontos em metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Obtém extensão do arquivo
  String _getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }
  
  /// Valida arquivo antes da importação
  Future<bool> validateFile(File file) async {
    try {
      if (!await file.exists()) return false;
      
      final extension = _getFileExtension(file.path);
      
      if (!supportedExtensions.contains(extension)) {
        return false;
      }
      
      final content = await file.readAsString();
      
      if (extension == 'kml') {
        return content.contains('<kml') && content.contains('<Placemark');
      } else if (extension == 'geojson' || extension == 'json') {
        final json = jsonDecode(content);
        return json['type'] != null;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Seleciona arquivo para importação
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          if (await validateFile(file)) {
            return file;
          } else {
            throw Exception('Arquivo inválido ou formato não suportado');
          }
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao selecionar arquivo: $e');
      rethrow;
    }
  }
}

