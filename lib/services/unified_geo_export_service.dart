import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../utils/logger.dart';

/// Opções de exportação
class ExportOptions {
  final bool includeMetadata;
  final bool includeStyles;
  final String? customName;
  final Map<String, dynamic>? additionalProperties;

  const ExportOptions({
    this.includeMetadata = true,
    this.includeStyles = true,
    this.customName,
    this.additionalProperties,
  });
}

/// Serviço unificado para exportação de dados geográficos
/// Suporta KML, GeoJSON com metadados completos e estilos personalizáveis
class UnifiedGeoExportService {
  
  /// Exporta talhão individual para KML
  Future<String?> exportTalhaoToKML(
    TalhaoModel talhao, {
    ExportOptions options = const ExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando talhão para KML: ${talhao.nome}');
      
      final kml = _generateKML(
        talhoes: [talhao],
        options: options,
      );
      
      final fileName = _generateFileName(
        'talhao_${talhao.nome.replaceAll(' ', '_')}',
        'kml',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, kml);
      
      Logger.info('✅ Talhão exportado para KML: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar talhão para KML: $e');
      return null;
    }
  }
  
  /// Exporta talhão individual para GeoJSON
  Future<String?> exportTalhaoToGeoJSON(
    TalhaoModel talhao, {
    ExportOptions options = const ExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando talhão para GeoJSON: ${talhao.nome}');
      
      final geojson = _generateGeoJSON(
        talhoes: [talhao],
        options: options,
      );
      
      final fileName = _generateFileName(
        'talhao_${talhao.nome.replaceAll(' ', '_')}',
        'geojson',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, jsonEncode(geojson));
      
      Logger.info('✅ Talhão exportado para GeoJSON: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar talhão para GeoJSON: $e');
      return null;
    }
  }
  
  /// Exporta múltiplos talhões para KML
  Future<String?> exportTalhoesToKML(
    List<TalhaoModel> talhoes, {
    ExportOptions options = const ExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando ${talhoes.length} talhões para KML');
      
      final kml = _generateKML(
        talhoes: talhoes,
        options: options,
      );
      
      final fileName = _generateFileName(
        'talhoes_${talhoes.length}',
        'kml',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, kml);
      
      Logger.info('✅ ${talhoes.length} talhões exportados para KML: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar talhões para KML: $e');
      return null;
    }
  }
  
  /// Exporta múltiplos talhões para GeoJSON
  Future<String?> exportTalhoesToGeoJSON(
    List<TalhaoModel> talhoes, {
    ExportOptions options = const ExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando ${talhoes.length} talhões para GeoJSON');
      
      final geojson = _generateGeoJSON(
        talhoes: talhoes,
        options: options,
      );
      
      final fileName = _generateFileName(
        'talhoes_${talhoes.length}',
        'geojson',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, jsonEncode(geojson));
      
      Logger.info('✅ ${talhoes.length} talhões exportados para GeoJSON: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar talhões para GeoJSON: $e');
      return null;
    }
  }
  
  /// Gera conteúdo KML
  String _generateKML({
    required List<TalhaoModel> talhoes,
    required ExportOptions options,
  }) {
    final builder = XmlBuilder();
    builder.declaration(version: '1.0', encoding: 'UTF-8');
    
    builder.element('kml', nest: () {
      builder.attribute('xmlns', 'http://www.opengis.net/kml/2.2');
      
      builder.element('Document', nest: () {
        // Nome do documento
        builder.element('name', nest: options.customName ?? 'Talhões FortSmart Agro');
        builder.element('description', nest: 'Exportado em ${DateTime.now().toIso8601String()}');
        
        // Estilos personalizados
        if (options.includeStyles) {
          _addKMLStyles(builder);
        }
        
        // Adicionar cada talhão
        for (final talhao in talhoes) {
          _addTalhaoToKML(builder, talhao, options);
        }
        
        // Metadados adicionais
        if (options.includeMetadata) {
          _addKMLMetadata(builder, talhoes, options);
        }
      });
    });
    
    final document = builder.buildDocument();
    return document.toXmlString(pretty: true);
  }
  
  /// Adiciona estilos KML
  void _addKMLStyles(XmlBuilder builder) {
    // Estilo padrão
    builder.element('Style', nest: () {
      builder.attribute('id', 'defaultStyle');
      
      builder.element('LineStyle', nest: () {
        builder.element('color', nest: 'ff0000ff'); // Vermelho
        builder.element('width', nest: '2');
      });
      
      builder.element('PolyStyle', nest: () {
        builder.element('color', nest: '7f0000ff'); // Vermelho semi-transparente
        builder.element('fill', nest: '1');
        builder.element('outline', nest: '1');
      });
    });
    
    // Estilo para talhões ativos
    builder.element('Style', nest: () {
      builder.attribute('id', 'activeStyle');
      
      builder.element('LineStyle', nest: () {
        builder.element('color', nest: 'ff00ff00'); // Verde
        builder.element('width', nest: '3');
      });
      
      builder.element('PolyStyle', nest: () {
        builder.element('color', nest: '7f00ff00'); // Verde semi-transparente
        builder.element('fill', nest: '1');
        builder.element('outline', nest: '1');
      });
    });
  }
  
  /// Adiciona talhão ao KML
  void _addTalhaoToKML(
    XmlBuilder builder,
    TalhaoModel talhao,
    ExportOptions options,
  ) {
    for (final poligono in talhao.poligonos) {
      builder.element('Placemark', nest: () {
        // Nome do talhão
        builder.element('name', nest: talhao.nome);
        
        // Descrição detalhada
        final description = _generateTalhaoDescription(talhao, options);
        builder.element('description', nest: description);
        
        // Estilo baseado no status
        final styleId = 'defaultStyle';
        builder.element('styleUrl', nest: '#$styleId');
        
        // Geometria
        builder.element('Polygon', nest: () {
          builder.element('extrude', nest: '1');
          builder.element('altitudeMode', nest: 'clampToGround');
          
          builder.element('outerBoundaryIs', nest: () {
            builder.element('LinearRing', nest: () {
              // Formatar coordenadas: longitude,latitude,altitude
              final coordsText = poligono.map((point) => 
                  '${point.longitude},${point.latitude},0').join(' ');
              
              builder.element('coordinates', nest: coordsText);
            });
          });
        });
        
        // Propriedades estendidas
        if (options.includeMetadata) {
          _addExtendedData(builder, talhao, options);
        }
      });
    }
  }
  
  /// Gera descrição do talhão
  String _generateTalhaoDescription(TalhaoModel talhao, ExportOptions options) {
    final buffer = StringBuffer();
    
    buffer.writeln('<![CDATA[');
    buffer.writeln('<h3>${talhao.nome}</h3>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><td><b>Cultura:</b></td><td>${talhao.culturaId ?? 'Não definida'}</td></tr>');
    buffer.writeln('<tr><td><b>Área:</b></td><td>${talhao.area.toStringAsFixed(2)} ha</td></tr>');
    buffer.writeln('<tr><td><b>Perímetro:</b></td><td>N/A</td></tr>');
    buffer.writeln('<tr><td><b>Status:</b></td><td>Ativo</td></tr>');
    buffer.writeln('<tr><td><b>Criado em:</b></td><td>${talhao.dataCriacao}</td></tr>');
    
    if (talhao.observacoes?.isNotEmpty == true) {
      buffer.writeln('<tr><td><b>Observações:</b></td><td>${talhao.observacoes}</td></tr>');
    }
    
    buffer.writeln('</table>');
    buffer.writeln(']]>');
    
    return buffer.toString();
  }
  
  /// Adiciona dados estendidos ao KML
  void _addExtendedData(
    XmlBuilder builder,
    TalhaoModel talhao,
    ExportOptions options,
  ) {
    builder.element('ExtendedData', nest: () {
      _addDataElement(builder, 'id', talhao.id);
      _addDataElement(builder, 'cultura', talhao.culturaId ?? '');
      _addDataElement(builder, 'area_ha', talhao.area.toString());
      _addDataElement(builder, 'perimetro_m', '0');
      _addDataElement(builder, 'status', 'Ativo');
      _addDataElement(builder, 'data_criacao', talhao.dataCriacao.toIso8601String());
      _addDataElement(builder, 'data_atualizacao', talhao.dataAtualizacao.toIso8601String());
      
      if (talhao.observacoes?.isNotEmpty == true) {
        _addDataElement(builder, 'observacoes', talhao.observacoes!);
      }
      
      // Propriedades adicionais
      if (options.additionalProperties != null) {
        for (final entry in options.additionalProperties!.entries) {
          _addDataElement(builder, entry.key, entry.value.toString());
        }
      }
    });
  }
  
  /// Adiciona elemento de dados
  void _addDataElement(XmlBuilder builder, String name, String value) {
    builder.element('Data', nest: () {
      builder.attribute('name', name);
      builder.element('value', nest: value);
    });
  }
  
  /// Adiciona metadados ao KML
  void _addKMLMetadata(
    XmlBuilder builder,
    List<TalhaoModel> talhoes,
    ExportOptions options,
  ) {
    builder.element('ExtendedData', nest: () {
      _addDataElement(builder, 'total_talhoes', talhoes.length.toString());
      _addDataElement(builder, 'data_exportacao', DateTime.now().toIso8601String());
      _addDataElement(builder, 'software', 'FortSmart Agro');
      _addDataElement(builder, 'versao', '1.0');
      
      // Estatísticas
      final totalArea = talhoes.fold(0.0, (sum, t) => sum + t.area);
      _addDataElement(builder, 'area_total_ha', totalArea.toStringAsFixed(2));
      
      final culturas = talhoes.map((t) => t.culturaId).where((c) => c != null).toSet();
      _addDataElement(builder, 'culturas', culturas.join(', '));
    });
  }
  
  /// Gera conteúdo GeoJSON
  Map<String, dynamic> _generateGeoJSON({
    required List<TalhaoModel> talhoes,
    required ExportOptions options,
  }) {
    final features = <Map<String, dynamic>>[];
    
    for (final talhao in talhoes) {
      for (final poligono in talhao.poligonos) {
        if (poligono.length < 3) continue;
        
        // Garantir que o polígono está fechado
        final coordinates = _ensureClosedPolygon(poligono.pontos);
        
        final feature = {
          'type': 'Feature',
          'properties': _generateGeoJSONProperties(talhao, options),
          'geometry': {
            'type': 'Polygon',
            'coordinates': [coordinates],
          },
        };
        
        features.add(feature);
      }
    }
    
    final geojson = {
      'type': 'FeatureCollection',
      'features': features,
    };
    
    // Adicionar metadados se solicitado
    if (options.includeMetadata) {
      geojson['properties'] = _generateGeoJSONMetadata(talhoes, options);
    }
    
    return geojson;
  }
  
  /// Gera propriedades do GeoJSON
  Map<String, dynamic> _generateGeoJSONProperties(
    TalhaoModel talhao,
    ExportOptions options,
  ) {
    final properties = {
      'id': talhao.id,
      'nome': talhao.nome,
      'cultura': talhao.culturaId,
      'area_ha': talhao.area,
      'perimetro_m': 0,
      'status': 'Ativo',
      'data_criacao': talhao.dataCriacao,
      'data_atualizacao': talhao.dataAtualizacao,
      'origem': 'fortsmart_agro',
      'software': 'FortSmart Agro',
      'versao': '1.0',
    };
    
    if (talhao.observacoes?.isNotEmpty == true) {
      properties['observacoes'] = talhao.observacoes;
    }
    
    // Propriedades adicionais
    if (options.additionalProperties != null) {
      properties.addAll(options.additionalProperties!);
    }
    
    return properties;
  }
  
  /// Gera metadados do GeoJSON
  Map<String, dynamic> _generateGeoJSONMetadata(
    List<TalhaoModel> talhoes,
    ExportOptions options,
  ) {
    final totalArea = talhoes.fold(0.0, (sum, t) => sum + t.area);
    final culturas = talhoes.map((t) => t.culturaId).where((c) => c != null).toSet();
    
    return {
      'total_talhoes': talhoes.length,
      'area_total_ha': totalArea,
      'culturas': culturas.toList(),
      'data_exportacao': DateTime.now().toIso8601String(),
      'software': 'FortSmart Agro',
      'versao': '1.0',
      'formato': 'GeoJSON',
      'srid': 4326,
    };
  }
  
  /// Garante que o polígono está fechado
  List<List<double>> _ensureClosedPolygon(List<LatLng> points) {
    final coordinates = points.map((point) => [point.longitude, point.latitude]).toList();
    
    // Se primeiro e último ponto são diferentes, adiciona o primeiro no final
    if (coordinates.isNotEmpty) {
      final first = coordinates.first;
      final last = coordinates.last;
      
      if (first[0] != last[0] || first[1] != last[1]) {
        coordinates.add(first);
      }
    }
    
    return coordinates;
  }
  
  /// Gera nome do arquivo
  String _generateFileName(String base, String extension, String? customName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = customName ?? base;
    return '${name}_$timestamp.$extension';
  }
  
  /// Salva arquivo e retorna o caminho
  Future<File> _saveToFile(String fileName, String content) async {
    final directory = await getExternalStorageDirectory() ?? 
                     await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsString(content);
    
    return file;
  }
  
  /// Compartilha arquivo exportado
  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      Logger.error('❌ Erro ao compartilhar arquivo: $e');
    }
  }
  
  /// Exporta e compartilha
  Future<void> exportAndShare(
    List<TalhaoModel> talhoes,
    String format, {
    ExportOptions options = const ExportOptions(),
  }) async {
    try {
      String? filePath;
      
      switch (format.toLowerCase()) {
        case 'kml':
          filePath = await exportTalhoesToKML(talhoes, options: options);
          break;
        case 'geojson':
          filePath = await exportTalhoesToGeoJSON(talhoes, options: options);
          break;
        default:
          throw Exception('Formato não suportado: $format');
      }
      
      if (filePath != null) {
        await shareFile(filePath);
      }
    } catch (e) {
      Logger.error('❌ Erro ao exportar e compartilhar: $e');
    }
  }
}
