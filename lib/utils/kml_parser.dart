import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
// Importar o adaptador global para usar suas classes
import 'map_imports.dart' as maps;

/// Classe utilitária para analisar arquivos KML e extrair coordenadas
class KmlParser {
  /// Analisa o conteúdo de uma string KML e retorna uma lista de coordenadas
  ///
  /// Usado para converter um conteúdo KML diretamente em uma lista de pontos LatLng
  static List<maps.LatLng> parseCoordinates(String kmlContent) {
    try {
      final result = parseKmlWithMetadata(kmlContent);
      return result['coordinates'] ?? [];
    } catch (e) {
      print('Erro ao analisar conteúdo KML: $e');
      return [];
    }
  }
  
  /// Analisa um arquivo KML ou KMZ e retorna uma lista de coordenadas
  /// 
  /// Extrai as coordenadas dos polígonos definidos no arquivo KML/KMZ.
  /// Suporta elementos <Polygon>, <LineString>, <MultiGeometry> e <Placemark>
  static Future<List<maps.LatLng>> parseKmlFile(String filePath) async {
    try {
      final result = await parseKmlFileWithMetadata(filePath);
      return result['coordinates'] ?? [];
    } catch (e) {
      print('Erro ao analisar arquivo KML/KMZ: $e');
      return [];
    }
  }

  /// Analisa um arquivo KML/KMZ e retorna coordenadas com metadados
  static Future<Map<String, dynamic>> parseKmlFileWithMetadata(String filePath) async {
    try {
      final fileExtension = path.extension(filePath).toLowerCase();
      String content;
      
      if (fileExtension == '.kmz') {
        // KMZ é um arquivo ZIP que contém um KML
        content = await _extractKmlFromKmz(filePath);
      } else {
        // Ler o arquivo KML
        final file = File(filePath);
        content = await file.readAsString();
      }
      
      if (content.isEmpty) {
        print('Arquivo KML/KMZ vazio ou inválido');
        return {};
      }
      
      return parseKmlWithMetadata(content);
    } catch (e) {
      print('Erro ao analisar arquivo KML/KMZ: $e');
      return {};
    }
  }
  
  /// Extrai o conteúdo KML de um arquivo KMZ (ZIP)
  static Future<String> _extractKmlFromKmz(String kmzFilePath) async {
    try {
      // Ler o arquivo KMZ como bytes
      final bytes = await File(kmzFilePath).readAsBytes();
      
      // Descompactar o arquivo ZIP
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Procurar pelo arquivo KML principal (geralmente doc.kml)
      for (final file in archive) {
        if (file.isFile && file.name.toLowerCase().endsWith('.kml')) {
          // Encontrou o arquivo KML, retornar seu conteúdo como string
          return utf8.decode(file.content as List<int>);
        }
      }
      
      // Não encontrou KML no arquivo KMZ
      print('Nenhum arquivo KML encontrado dentro do KMZ');
      return '';
    } catch (e) {
      print('Erro ao extrair KML do arquivo KMZ: $e');
      return '';
    }
  }
  
  /// Analisa um arquivo KML e retorna uma lista de coordenadas como mapas
  /// 
  /// Extrai as coordenadas dos polígonos definidos no arquivo KML.
  /// Retorna uma lista de mapas com 'latitude' e 'longitude'.
  Future<List<Map<String, double>>> parseKmlFileAsMap(String filePath) async {
    try {
      // Ler o arquivo
      final file = File(filePath);
      final content = await file.readAsString();
      
      // Obter coordenadas como maps.LatLng
      final result = KmlParser.parseKmlWithMetadata(content);
      final latLngPoints = result['coordinates'] ?? [];
      
      // Converter para lista de mapas
      return latLngPoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList();
    } catch (e) {
      print('Erro ao analisar arquivo KML: $e');
      return [];
    }
  }
  
  /// Analisa o conteúdo de um KML e retorna coordenadas com metadados
  /// 
  /// Extrai as coordenadas dos polígonos definidos no conteúdo KML.
  /// Suporta vários formatos de KML (Google Earth, GIS, etc.)
  /// Retorna um mapa com coordenadas e metadados extraídos
  static Map<String, dynamic> parseKmlWithMetadata(String content) {
    try {
      // Analisar o XML
      final document = XmlDocument.parse(content);
      
      // Extrair metadados globais
      final metadata = _extractGlobalMetadata(document);
      
      // 1. Procurar por elementos <Polygon> diretamente
      final polygons = document.findAllElements('Polygon');
      for (final polygon in polygons) {
        final result = _parsePolygonWithMetadata(polygon, metadata);
        if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
          return result;
        }
      }
      
      // 2. Procurar por elementos <LineString> diretamente
      final lineStrings = document.findAllElements('LineString');
      for (final lineString in lineStrings) {
        final result = _parseLineStringWithMetadata(lineString, metadata);
        if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
          return result;
        }
      }
      
      // 3. Procurar <Placemark> com geometria
      final placemarks = document.findAllElements('Placemark');
      for (final placemark in placemarks) {
        final result = _parsePlacemarkWithMetadata(placemark, metadata);
        if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
          return result;
        }
      }
      
      return {'coordinates': [], 'metadata': metadata};
    } catch (e) {
      print('Erro ao analisar KML: $e');
      return {'coordinates': [], 'metadata': {}};
    }
  }
  
  /// Extrai metadados globais do documento KML
  static Map<String, dynamic> _extractGlobalMetadata(XmlDocument document) {
    final metadata = <String, dynamic>{};
    
    try {
      // Extrair nome do documento
      final nameElement = document.findAllElements('name').firstOrNull;
      if (nameElement != null) {
        metadata['documentName'] = nameElement.text;
      }
      
      // Extrair descrição do documento
      final descriptionElement = document.findAllElements('description').firstOrNull;
      if (descriptionElement != null) {
        metadata['documentDescription'] = descriptionElement.text;
      }
      
      // Extrair informações de área da descrição se disponível
      if (metadata['documentDescription'] != null) {
        final areaInfo = _extractAreaFromDescription(metadata['documentDescription']);
        if (areaInfo != null) {
          metadata['originalArea'] = areaInfo;
        }
      }
      
    } catch (e) {
      print('Erro ao extrair metadados globais: $e');
    }
    
    return metadata;
  }
  
  /// Extrai informações de área da descrição do KML
  static Map<String, dynamic>? _extractAreaFromDescription(String description) {
    try {
      // Padrões comuns para área em descrições KML
      final patterns = [
        RegExp(r'área[:\s]*([\d,]+\.?\d*)\s*(ha|hectares|hectare)', caseSensitive: false),
        RegExp(r'area[:\s]*([\d,]+\.?\d*)\s*(ha|hectares|hectare)', caseSensitive: false),
        RegExp(r'([\d,]+\.?\d*)\s*(ha|hectares|hectare)', caseSensitive: false),
        RegExp(r'área[:\s]*([\d,]+\.?\d*)\s*(km²|km2)', caseSensitive: false),
        RegExp(r'area[:\s]*([\d,]+\.?\d*)\s*(km²|km2)', caseSensitive: false),
        RegExp(r'([\d,]+\.?\d*)\s*(km²|km2)', caseSensitive: false),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(description);
        if (match != null) {
          final valueStr = match.group(1)?.replaceAll(',', '.');
          final unit = match.group(2)?.toLowerCase();
          
          if (valueStr != null && unit != null) {
            final value = double.tryParse(valueStr);
            if (value != null) {
              return {
                'value': value,
                'unit': unit,
                'valueInHectares': unit.contains('km') ? value * 100 : value,
                'source': 'description',
              };
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao extrair área da descrição: $e');
    }
    
    return null;
  }
  
  /// Analisa um Placemark com metadados
  static Map<String, dynamic> _parsePlacemarkWithMetadata(XmlElement placemark, Map<String, dynamic> globalMetadata) {
    try {
      // Extrair nome e descrição do Placemark
      final name = placemark.findElements('name').firstOrNull?.text ?? 'Polígono Importado';
      final description = placemark.findElements('description').firstOrNull?.text ?? '';
      
      // Extrair informações de área da descrição
      Map<String, dynamic>? areaInfo;
      if (description.isNotEmpty) {
        areaInfo = _extractAreaFromDescription(description);
      }
      
      // Extrair ExtendedData se disponível
      final extendedData = _extractExtendedData(placemark);
      
      // 3.1 Verificar <Polygon> dentro do <Placemark>
      final polygonsInPlacemark = placemark.findAllElements('Polygon');
      for (final polygon in polygonsInPlacemark) {
        final result = _parsePolygonWithMetadata(polygon, {
          ...globalMetadata,
          'name': name,
          'description': description,
          'originalArea': areaInfo,
          'extendedData': extendedData,
        });
        if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
          return result;
        }
      }
      
      // 3.2 Verificar <LineString> dentro do <Placemark>
      final lineStringsInPlacemark = placemark.findAllElements('LineString');
      for (final lineString in lineStringsInPlacemark) {
        final result = _parseLineStringWithMetadata(lineString, {
          ...globalMetadata,
          'name': name,
          'description': description,
          'originalArea': areaInfo,
          'extendedData': extendedData,
        });
        if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
          return result;
        }
      }
      
      // 3.3 Verificar <MultiGeometry> dentro do <Placemark>
      final multiGeometries = placemark.findAllElements('MultiGeometry');
      for (final multiGeometry in multiGeometries) {
        // Verificar polígonos dentro de <MultiGeometry>
        final polygonsInMulti = multiGeometry.findAllElements('Polygon');
        for (final polygon in polygonsInMulti) {
          final result = _parsePolygonWithMetadata(polygon, {
            ...globalMetadata,
            'name': name,
            'description': description,
            'originalArea': areaInfo,
            'extendedData': extendedData,
          });
          if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
            return result;
          }
        }
        
        // Verificar LineStrings dentro de <MultiGeometry>
        final lineStringsInMulti = multiGeometry.findAllElements('LineString');
        for (final lineString in lineStringsInMulti) {
          final result = _parseLineStringWithMetadata(lineString, {
            ...globalMetadata,
            'name': name,
            'description': description,
            'originalArea': areaInfo,
            'extendedData': extendedData,
          });
          if (result['coordinates'] != null && result['coordinates'].isNotEmpty) {
            return result;
          }
        }
      }
      
      return {'coordinates': [], 'metadata': globalMetadata};
    } catch (e) {
      print('Erro ao analisar Placemark: $e');
      return {'coordinates': [], 'metadata': globalMetadata};
    }
  }
  
  /// Extrai dados estendidos do KML
  static Map<String, dynamic> _extractExtendedData(XmlElement element) {
    final extendedData = <String, dynamic>{};
    
    try {
      final extendedDataElement = element.findElements('ExtendedData').firstOrNull;
      if (extendedDataElement != null) {
        final dataElements = extendedDataElement.findAllElements('Data');
        for (final dataElement in dataElements) {
          final name = dataElement.getAttribute('name');
          final valueElement = dataElement.findElements('value').firstOrNull;
          if (name != null && valueElement != null) {
            extendedData[name] = valueElement.text;
          }
        }
      }
    } catch (e) {
      print('Erro ao extrair ExtendedData: $e');
    }
    
    return extendedData;
  }
  
  /// Analisa um Polygon com metadados
  static Map<String, dynamic> _parsePolygonWithMetadata(XmlElement polygon, Map<String, dynamic> metadata) {
    try {
      // Procurar <outerBoundaryIs> que contém <LinearRing> com coordenadas
      final outerBoundaries = polygon.findAllElements('outerBoundaryIs');
      for (final boundary in outerBoundaries) {
        final linearRings = boundary.findAllElements('LinearRing');
        for (final ring in linearRings) {
          final coordinates = ring.findAllElements('coordinates');
          if (coordinates.isNotEmpty) {
            final coords = _parseCoordinates(coordinates.first.text);
            if (coords.isNotEmpty) {
              return {
                'coordinates': coords,
                'metadata': {
                  ...metadata,
                  'geometryType': 'Polygon',
                  'source': 'outerBoundaryIs',
                },
              };
            }
          }
        }
      }
      
      // Verificar coordenadas diretamente no <Polygon>
      final coordinates = polygon.findAllElements('coordinates');
      if (coordinates.isNotEmpty) {
        final coords = _parseCoordinates(coordinates.first.text);
        if (coords.isNotEmpty) {
          return {
            'coordinates': coords,
            'metadata': {
              ...metadata,
              'geometryType': 'Polygon',
              'source': 'direct',
            },
          };
        }
      }
      
      return {'coordinates': [], 'metadata': metadata};
    } catch (e) {
      print('Erro ao analisar Polygon: $e');
      return {'coordinates': [], 'metadata': metadata};
    }
  }
  
  /// Analisa um LineString com metadados
  static Map<String, dynamic> _parseLineStringWithMetadata(XmlElement lineString, Map<String, dynamic> metadata) {
    try {
      final coordinates = lineString.findAllElements('coordinates');
      if (coordinates.isNotEmpty) {
        final coords = _parseCoordinates(coordinates.first.text);
        if (coords.isNotEmpty) {
          return {
            'coordinates': coords,
            'metadata': {
              ...metadata,
              'geometryType': 'LineString',
              'source': 'direct',
            },
          };
        }
      }
      
      return {'coordinates': [], 'metadata': metadata};
    } catch (e) {
      print('Erro ao analisar LineString: $e');
      return {'coordinates': [], 'metadata': metadata};
    }
  }
  
  /// Analisa coordenadas KML e converte para lista de LatLng
  static List<maps.LatLng> _parseCoordinates(String coordinates) {
    final points = <maps.LatLng>[];
    
    try {
      final coordPairs = coordinates.split(' ');
      for (final pair in coordPairs) {
        final trimmedPair = pair.trim();
        if (trimmedPair.isNotEmpty) {
          final parts = trimmedPair.split(',');
          if (parts.length >= 2) {
            final lng = double.tryParse(parts[0]);
            final lat = double.tryParse(parts[1]);
            
            if (lng != null && lat != null) {
              points.add(maps.LatLng(lat, lng));
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao analisar coordenadas: $e');
    }
    
    return points;
  }
}
