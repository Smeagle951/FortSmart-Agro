import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import '../models/experiment.dart';
import '../models/talhao_model.dart';
import '../utils/logger.dart';

/// Opções de exportação de experimentos
class ExperimentExportOptions {
  final bool includeGeometry;
  final bool includeResults;
  final bool includeMetadata;
  final bool includeStyles;
  final String? customName;
  final Map<String, dynamic>? additionalProperties;

  const ExperimentExportOptions({
    this.includeGeometry = true,
    this.includeResults = true,
    this.includeMetadata = true,
    this.includeStyles = true,
    this.customName,
    this.additionalProperties,
  });
}

/// Serviço para exportação de experimentos
/// Suporta KML e GeoJSON com dados de experimentação
class ExperimentExportService {
  
  /// Exporta experimento individual para KML
  Future<String?> exportExperimentToKML(
    Experiment experiment,
    TalhaoModel? talhao, {
    ExperimentExportOptions options = const ExperimentExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando experimento para KML: ${experiment.plotName}');
      
      final kml = _generateExperimentKML(
        experiments: [experiment],
        talhoes: talhao != null ? [talhao] : [],
        options: options,
      );
      
      final fileName = _generateFileName(
        'experimento_${experiment.plotName.replaceAll(' ', '_')}',
        'kml',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, kml);
      
      Logger.info('✅ Experimento exportado para KML: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar experimento para KML: $e');
      return null;
    }
  }
  
  /// Exporta experimento individual para GeoJSON
  Future<String?> exportExperimentToGeoJSON(
    Experiment experiment,
    TalhaoModel? talhao, {
    ExperimentExportOptions options = const ExperimentExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando experimento para GeoJSON: ${experiment.plotName}');
      
      final geojson = _generateExperimentGeoJSON(
        experiments: [experiment],
        talhoes: talhao != null ? [talhao] : [],
        options: options,
      );
      
      final fileName = _generateFileName(
        'experimento_${experiment.plotName.replaceAll(' ', '_')}',
        'geojson',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, jsonEncode(geojson));
      
      Logger.info('✅ Experimento exportado para GeoJSON: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar experimento para GeoJSON: $e');
      return null;
    }
  }
  
  /// Exporta múltiplos experimentos para KML
  Future<String?> exportExperimentsToKML(
    List<Experiment> experiments,
    List<TalhaoModel> talhoes, {
    ExperimentExportOptions options = const ExperimentExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando ${experiments.length} experimentos para KML');
      
      final kml = _generateExperimentKML(
        experiments: experiments,
        talhoes: talhoes,
        options: options,
      );
      
      final fileName = _generateFileName(
        'experimentos_${experiments.length}',
        'kml',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, kml);
      
      Logger.info('✅ ${experiments.length} experimentos exportados para KML: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar experimentos para KML: $e');
      return null;
    }
  }
  
  /// Exporta múltiplos experimentos para GeoJSON
  Future<String?> exportExperimentsToGeoJSON(
    List<Experiment> experiments,
    List<TalhaoModel> talhoes, {
    ExperimentExportOptions options = const ExperimentExportOptions(),
  }) async {
    try {
      Logger.info('🔄 Exportando ${experiments.length} experimentos para GeoJSON');
      
      final geojson = _generateExperimentGeoJSON(
        experiments: experiments,
        talhoes: talhoes,
        options: options,
      );
      
      final fileName = _generateFileName(
        'experimentos_${experiments.length}',
        'geojson',
        options.customName,
      );
      
      final file = await _saveToFile(fileName, jsonEncode(geojson));
      
      Logger.info('✅ ${experiments.length} experimentos exportados para GeoJSON: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao exportar experimentos para GeoJSON: $e');
      return null;
    }
  }
  
  /// Gera conteúdo KML para experimentos
  String _generateExperimentKML({
    required List<Experiment> experiments,
    required List<TalhaoModel> talhoes,
    required ExperimentExportOptions options,
  }) {
    final builder = XmlBuilder();
    builder.declaration(version: '1.0', encoding: 'UTF-8');
    
    builder.element('kml', nest: () {
      builder.attribute('xmlns', 'http://www.opengis.net/kml/2.2');
      
      builder.element('Document', nest: () {
        // Nome do documento
        builder.element('name', nest: options.customName ?? 'Experimentos FortSmart Agro');
        builder.element('description', nest: 'Exportado em ${DateTime.now().toIso8601String()}');
        
        // Estilos personalizados
        if (options.includeStyles) {
          _addExperimentKMLStyles(builder);
        }
        
        // Adicionar cada experimento
        for (final experiment in experiments) {
          final talhao = _findTalhaoForExperiment(experiment, talhoes);
          _addExperimentToKML(builder, experiment, talhao, options);
        }
        
        // Metadados adicionais
        if (options.includeMetadata) {
          _addExperimentKMLMetadata(builder, experiments, options);
        }
      });
    });
    
    final document = builder.buildDocument();
    return document.toXmlString(pretty: true);
  }
  
  /// Adiciona estilos KML para experimentos
  void _addExperimentKMLStyles(XmlBuilder builder) {
    // Estilo para experimentos ativos
    builder.element('Style', nest: () {
      builder.attribute('id', 'experimentActiveStyle');
      
      builder.element('LineStyle', nest: () {
        builder.element('color', nest: 'ff0000ff'); // Azul
        builder.element('width', nest: '3');
      });
      
      builder.element('PolyStyle', nest: () {
        builder.element('color', nest: '7f0000ff'); // Azul semi-transparente
        builder.element('fill', nest: '1');
        builder.element('outline', nest: '1');
      });
    });
    
    // Estilo para experimentos concluídos
    builder.element('Style', nest: () {
      builder.attribute('id', 'experimentCompletedStyle');
      
      builder.element('LineStyle', nest: () {
        builder.element('color', nest: 'ff00ff00'); // Verde
        builder.element('width', nest: '2');
      });
      
      builder.element('PolyStyle', nest: () {
        builder.element('color', nest: '7f00ff00'); // Verde semi-transparente
        builder.element('fill', nest: '1');
        builder.element('outline', nest: '1');
      });
    });
    
    // Estilo para experimentos cancelados
    builder.element('Style', nest: () {
      builder.attribute('id', 'experimentCanceledStyle');
      
      builder.element('LineStyle', nest: () {
        builder.element('color', nest: 'ffff0000'); // Vermelho
        builder.element('width', nest: '2');
      });
      
      builder.element('PolyStyle', nest: () {
        builder.element('color', nest: '7fff0000'); // Vermelho semi-transparente
        builder.element('fill', nest: '1');
        builder.element('outline', nest: '1');
      });
    });
  }
  
  /// Adiciona experimento ao KML
  void _addExperimentToKML(
    XmlBuilder builder,
    Experiment experiment,
    TalhaoModel? talhao,
    ExperimentExportOptions options,
  ) {
    // Se não há talhão associado, criar um ponto no centro
    if (talhao == null || talhao.poligonos.isEmpty) {
      _addExperimentPoint(builder, experiment, options);
      return;
    }
    
    // Adicionar polígonos do talhão com dados do experimento
    for (final poligono in talhao.poligonos) {
      builder.element('Placemark', nest: () {
        // Nome do experimento
        builder.element('name', nest: experiment.plotName);
        
        // Descrição detalhada
        final description = _generateExperimentDescription(experiment, talhao, options);
        builder.element('description', nest: description);
        
        // Estilo baseado no status
        final styleId = _getExperimentStyleId(experiment.status);
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
          _addExperimentExtendedData(builder, experiment, talhao, options);
        }
      });
    }
  }
  
  /// Adiciona ponto para experimento sem geometria
  void _addExperimentPoint(
    XmlBuilder builder,
    Experiment experiment,
    ExperimentExportOptions options,
  ) {
    builder.element('Placemark', nest: () {
      builder.element('name', nest: experiment.plotName);
      
      final description = _generateExperimentDescription(experiment, null, options);
      builder.element('description', nest: description);
      
      final styleId = _getExperimentStyleId(experiment.status);
      builder.element('styleUrl', nest: '#$styleId');
      
      // Ponto no centro aproximado do Brasil
      builder.element('Point', nest: () {
        builder.element('coordinates', nest: '-47.9292,-15.7801,0');
      });
      
      if (options.includeMetadata) {
        _addExperimentExtendedData(builder, experiment, null, options);
      }
    });
  }
  
  /// Gera descrição do experimento
  String _generateExperimentDescription(
    Experiment experiment,
    TalhaoModel? talhao,
    ExperimentExportOptions options,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('<![CDATA[');
    buffer.writeln('<h3>${experiment.plotName}</h3>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><td><b>Cultura:</b></td><td>${experiment.cropType}</td></tr>');
    buffer.writeln('<tr><td><b>Variedade:</b></td><td>${experiment.variety}</td></tr>');
    buffer.writeln('<tr><td><b>Status:</b></td><td>${experiment.status}</td></tr>');
    buffer.writeln('<tr><td><b>DAE:</b></td><td>${experiment.dae} dias</td></tr>');
    buffer.writeln('<tr><td><b>Início:</b></td><td>${experiment.startDate.toIso8601String()}</td></tr>');
    
    if (experiment.endDate != null) {
      buffer.writeln('<tr><td><b>Fim:</b></td><td>${experiment.endDate!.toIso8601String()}</td></tr>');
    }
    
    if (talhao != null) {
      buffer.writeln('<tr><td><b>Área:</b></td><td>${talhao.area.toStringAsFixed(2)} ha</td></tr>');
    }
    
    if (experiment.description.isNotEmpty) {
      buffer.writeln('<tr><td><b>Descrição:</b></td><td>${experiment.description}</td></tr>');
    }
    
    // Resultados se disponíveis
    if (options.includeResults && experiment.results.isNotEmpty) {
      buffer.writeln('<tr><td colspan="2"><b>Resultados:</b></td></tr>');
      for (final entry in experiment.results.entries) {
        buffer.writeln('<tr><td>${entry.key}:</td><td>${entry.value}</td></tr>');
      }
    }
    
    buffer.writeln('</table>');
    buffer.writeln(']]>');
    
    return buffer.toString();
  }
  
  /// Adiciona dados estendidos do experimento ao KML
  void _addExperimentExtendedData(
    XmlBuilder builder,
    Experiment experiment,
    TalhaoModel? talhao,
    ExperimentExportOptions options,
  ) {
    builder.element('ExtendedData', nest: () {
      _addDataElement(builder, 'id', experiment.id ?? '');
      _addDataElement(builder, 'plot_id', experiment.plotId);
      _addDataElement(builder, 'plot_name', experiment.plotName);
      _addDataElement(builder, 'crop_type', experiment.cropType);
      _addDataElement(builder, 'variety', experiment.variety);
      _addDataElement(builder, 'status', experiment.status);
      _addDataElement(builder, 'dae', experiment.dae.toString());
      _addDataElement(builder, 'start_date', experiment.startDate.toIso8601String());
      
      if (experiment.endDate != null) {
        _addDataElement(builder, 'end_date', experiment.endDate!.toIso8601String());
      }
      
      if (experiment.description.isNotEmpty) {
        _addDataElement(builder, 'description', experiment.description);
      }
      
      if (talhao != null) {
        _addDataElement(builder, 'talhao_area_ha', talhao.area.toString());
        _addDataElement(builder, 'talhao_perimetro_m', talhao.perimetro.toString());
      }
      
      // Resultados
      if (options.includeResults && experiment.results.isNotEmpty) {
        for (final entry in experiment.results.entries) {
          _addDataElement(builder, 'result_${entry.key}', entry.value.toString());
        }
      }
      
      // Propriedades adicionais
      if (options.additionalProperties != null) {
        for (final entry in options.additionalProperties!.entries) {
          _addDataElement(builder, entry.key, entry.value.toString());
        }
      }
    });
  }
  
  /// Adiciona metadados dos experimentos ao KML
  void _addExperimentKMLMetadata(
    XmlBuilder builder,
    List<Experiment> experiments,
    ExperimentExportOptions options,
  ) {
    builder.element('ExtendedData', nest: () {
      _addDataElement(builder, 'total_experimentos', experiments.length.toString());
      _addDataElement(builder, 'data_exportacao', DateTime.now().toIso8601String());
      _addDataElement(builder, 'software', 'FortSmart Agro');
      _addDataElement(builder, 'versao', '1.0');
      
      // Estatísticas
      final activeCount = experiments.where((e) => e.status == 'active').length;
      final completedCount = experiments.where((e) => e.status == 'completed').length;
      final canceledCount = experiments.where((e) => e.status == 'canceled').length;
      
      _addDataElement(builder, 'experimentos_ativos', activeCount.toString());
      _addDataElement(builder, 'experimentos_concluidos', completedCount.toString());
      _addDataElement(builder, 'experimentos_cancelados', canceledCount.toString());
      
      final cropTypes = experiments.map((e) => e.cropType).toSet();
      _addDataElement(builder, 'culturas', cropTypes.join(', '));
    });
  }
  
  /// Gera conteúdo GeoJSON para experimentos
  Map<String, dynamic> _generateExperimentGeoJSON({
    required List<Experiment> experiments,
    required List<TalhaoModel> talhoes,
    required ExperimentExportOptions options,
  }) {
    final features = <Map<String, dynamic>>[];
    
    for (final experiment in experiments) {
      final talhao = _findTalhaoForExperiment(experiment, talhoes);
      
      if (talhao != null && talhao.poligonos.isNotEmpty && options.includeGeometry) {
        // Adicionar polígonos do talhão
        for (final poligono in talhao.poligonos) {
          if (poligono.length < 3) continue;
          
          final coordinates = _ensureClosedPolygon(poligono);
          
          final feature = {
            'type': 'Feature',
            'properties': _generateExperimentGeoJSONProperties(experiment, talhao, options),
            'geometry': {
              'type': 'Polygon',
              'coordinates': [coordinates],
            },
          };
          
          features.add(feature);
        }
      } else {
        // Adicionar ponto para experimento sem geometria
        final feature = {
          'type': 'Feature',
          'properties': _generateExperimentGeoJSONProperties(experiment, null, options),
          'geometry': {
            'type': 'Point',
            'coordinates': [-47.9292, -15.7801], // Centro aproximado do Brasil
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
      geojson['properties'] = _generateExperimentGeoJSONMetadata(experiments, options);
    }
    
    return geojson;
  }
  
  /// Gera propriedades do GeoJSON para experimentos
  Map<String, dynamic> _generateExperimentGeoJSONProperties(
    Experiment experiment,
    TalhaoModel? talhao,
    ExperimentExportOptions options,
  ) {
    final properties = {
      'id': experiment.id,
      'plot_id': experiment.plotId,
      'plot_name': experiment.plotName,
      'crop_type': experiment.cropType,
      'variety': experiment.variety,
      'status': experiment.status,
      'dae': experiment.dae,
      'start_date': experiment.startDate.toIso8601String(),
      'description': experiment.description,
      'origem': 'fortsmart_agro',
      'software': 'FortSmart Agro',
      'versao': '1.0',
      'tipo': 'experimento',
    };
    
    if (experiment.endDate != null) {
      properties['end_date'] = experiment.endDate!.toIso8601String();
    }
    
    if (talhao != null) {
      properties['talhao_area_ha'] = talhao.area;
      properties['talhao_perimetro_m'] = talhao.perimetro;
      properties['talhao_nome'] = talhao.nome;
    }
    
    // Resultados
    if (options.includeResults && experiment.results.isNotEmpty) {
      properties['resultados'] = experiment.results;
    }
    
    // Propriedades adicionais
    if (options.additionalProperties != null) {
      properties.addAll(options.additionalProperties!);
    }
    
    return properties;
  }
  
  /// Gera metadados do GeoJSON para experimentos
  Map<String, dynamic> _generateExperimentGeoJSONMetadata(
    List<Experiment> experiments,
    ExperimentExportOptions options,
  ) {
    final activeCount = experiments.where((e) => e.status == 'active').length;
    final completedCount = experiments.where((e) => e.status == 'completed').length;
    final canceledCount = experiments.where((e) => e.status == 'canceled').length;
    final cropTypes = experiments.map((e) => e.cropType).toSet();
    
    return {
      'total_experimentos': experiments.length,
      'experimentos_ativos': activeCount,
      'experimentos_concluidos': completedCount,
      'experimentos_cancelados': canceledCount,
      'culturas': cropTypes.toList(),
      'data_exportacao': DateTime.now().toIso8601String(),
      'software': 'FortSmart Agro',
      'versao': '1.0',
      'formato': 'GeoJSON',
      'srid': 4326,
      'tipo': 'experimentos',
    };
  }
  
  /// Encontra talhão associado ao experimento
  TalhaoModel? _findTalhaoForExperiment(Experiment experiment, List<TalhaoModel> talhoes) {
    return talhoes.where((t) => t.id == experiment.plotId).firstOrNull;
  }
  
  /// Obtém ID do estilo baseado no status
  String _getExperimentStyleId(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'experimentActiveStyle';
      case 'completed':
        return 'experimentCompletedStyle';
      case 'canceled':
        return 'experimentCanceledStyle';
      default:
        return 'experimentActiveStyle';
    }
  }
  
  /// Adiciona elemento de dados
  void _addDataElement(XmlBuilder builder, String name, String value) {
    builder.element('Data', nest: () {
      builder.attribute('name', name);
      builder.element('value', nest: value);
    });
  }
  
  /// Garante que o polígono está fechado
  List<List<double>> _ensureClosedPolygon(List<LatLng> points) {
    final coordinates = points.map((point) => [point.longitude, point.latitude]).toList();
    
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
  
  /// Exporta e compartilha experimentos
  Future<void> exportAndShare(
    List<Experiment> experiments,
    List<TalhaoModel> talhoes,
    String format, {
    ExperimentExportOptions options = const ExperimentExportOptions(),
  }) async {
    try {
      String? filePath;
      
      switch (format.toLowerCase()) {
        case 'kml':
          filePath = await exportExperimentsToKML(experiments, talhoes, options: options);
          break;
        case 'geojson':
          filePath = await exportExperimentsToGeoJSON(experiments, talhoes, options: options);
          break;
        default:
          throw Exception('Formato não suportado: $format');
      }
      
      if (filePath != null) {
        await shareFile(filePath);
      }
    } catch (e) {
      Logger.error('❌ Erro ao exportar e compartilhar experimentos: $e');
    }
  }
}
