import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/infestation_timeline_model.dart';
import '../repositories/infestation_timeline_repository.dart';
import '../../../utils/logger.dart';

/// Resultado da análise de aplicação
class ApplicationAnalysisResult {
  final String talhaoId;
  final String organismoId;
  final String nivel;
  final double percentual;
  final bool aplicar;
  final String recomendacao;
  final String justificativa;
  final double prioridade;
  final DateTime dataAnalise;

  ApplicationAnalysisResult({
    required this.talhaoId,
    required this.organismoId,
    required this.nivel,
    required this.percentual,
    required this.aplicar,
    required this.recomendacao,
    required this.justificativa,
    required this.prioridade,
    required this.dataAnalise,
  });

  Map<String, dynamic> toMap() {
    return {
      'talhao_id': talhaoId,
      'organismo_id': organismoId,
      'nivel': nivel,
      'percentual': percentual,
      'aplicar': aplicar,
      'recomendacao': recomendacao,
      'justificativa': justificativa,
      'prioridade': prioridade,
      'data_analise': dataAnalise.toIso8601String(),
    };
  }
}

/// Dados para exportação GeoJSON
class GeoJsonExportData {
  final String type = 'FeatureCollection';
  final List<GeoJsonFeature> features;

  GeoJsonExportData({required this.features});

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'features': features.map((f) => f.toMap()).toList(),
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }
}

/// Feature GeoJSON
class GeoJsonFeature {
  final String type = 'Feature';
  final Map<String, dynamic> properties;
  final Map<String, dynamic> geometry;

  GeoJsonFeature({
    required this.properties,
    required this.geometry,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'properties': properties,
      'geometry': geometry,
    };
  }
}

/// Dados para exportação CSV
class CsvExportData {
  final List<Map<String, dynamic>> rows;

  CsvExportData({required this.rows});

  String toCsv() {
    if (rows.isEmpty) return '';

    final headers = rows.first.keys.toList();
    final csvRows = <String>[];

    // Adicionar cabeçalho
    csvRows.add(headers.join(','));

    // Adicionar dados
    for (final row in rows) {
      final values = headers.map((header) {
        final value = row[header];
        if (value is String && value.contains(',')) {
          return '"$value"';
        }
        return value.toString();
      }).toList();
      csvRows.add(values.join(','));
    }

    return csvRows.join('\n');
  }
}

/// Serviço para integração com módulo de aplicação
class ApplicationIntegrationService {
  final InfestationTimelineRepository _timelineRepository;

  ApplicationIntegrationService(this._timelineRepository);

  /// Analisa se deve aplicar tratamento baseado nos dados de infestação
  Future<List<ApplicationAnalysisResult>> analyzeApplicationNeeds({
    String? talhaoId,
    String? organismoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Logger.info('🔍 Analisando necessidades de aplicação...');

      List<InfestationTimelineModel> timelineData;

      if (talhaoId != null && organismoId != null) {
        timelineData = await _timelineRepository.getByTalhaoAndOrganismo(
          talhaoId,
          organismoId,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );
      } else if (talhaoId != null) {
        timelineData = await _timelineRepository.getByTalhao(talhaoId);
      } else if (organismoId != null) {
        timelineData = await _timelineRepository.getByOrganismo(organismoId);
      } else {
        timelineData = await _timelineRepository.getAll();
      }

      // Agrupar por talhão e organismo
      final Map<String, List<InfestationTimelineModel>> groupedData = {};
      for (final entry in timelineData) {
        final key = '${entry.talhaoId}_${entry.organismoId}';
        groupedData.putIfAbsent(key, () => []).add(entry);
      }

      final results = <ApplicationAnalysisResult>[];

      for (final entry in groupedData.entries) {
        final entries = entry.value;
        if (entries.isEmpty) continue;

        // Pegar a entrada mais recente
        final latestEntry = entries.reduce((a, b) => 
          a.dataOcorrencia.isAfter(b.dataOcorrencia) ? a : b);

        // Analisar se deve aplicar
        final analysis = _analyzeApplicationNeed(latestEntry, entries);
        results.add(analysis);
      }

      // Ordenar por prioridade (maior primeiro)
      results.sort((a, b) => b.prioridade.compareTo(a.prioridade));

      Logger.info('✅ Análise concluída: ${results.length} resultados');
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao analisar necessidades de aplicação: $e');
      return [];
    }
  }

  /// Analisa necessidade de aplicação para um conjunto de entradas
  ApplicationAnalysisResult _analyzeApplicationNeed(
    InfestationTimelineModel latestEntry,
    List<InfestationTimelineModel> allEntries,
  ) {
    final nivel = latestEntry.nivel.toUpperCase();
    final percentual = latestEntry.percentual;
    
    bool aplicar;
    String recomendacao;
    String justificativa;
    double prioridade;

    // Lógica de decisão baseada no nível e tendência
    switch (nivel) {
      case 'CRÍTICO':
        aplicar = true;
        recomendacao = 'APLICAR IMEDIATAMENTE';
        justificativa = 'Nível crítico detectado - ação urgente necessária';
        prioridade = 10.0;
        break;
      
      case 'ALTO':
        aplicar = true;
        recomendacao = 'APLICAR EM BREVE';
        justificativa = 'Nível alto - tratamento recomendado';
        prioridade = 8.0;
        break;
      
      case 'MODERADO':
        // Para moderado, analisar tendência
        final tendencia = _analyzeTendency(allEntries);
        if (tendencia == 'CRESCENTE') {
          aplicar = true;
          recomendacao = 'APLICAR PREVENTIVAMENTE';
          justificativa = 'Nível moderado com tendência crescente';
          prioridade = 6.0;
        } else {
          aplicar = false;
          recomendacao = 'MONITORAR';
          justificativa = 'Nível moderado estável - continuar monitoramento';
          prioridade = 4.0;
        }
        break;
      
      case 'BAIXO':
        aplicar = false;
        recomendacao = 'NÃO APLICAR';
        justificativa = 'Nível baixo - situação controlada';
        prioridade = 2.0;
        break;
      
      default:
        aplicar = false;
        recomendacao = 'AVALIAR MANUALMENTE';
        justificativa = 'Nível não identificado - requer análise manual';
        prioridade = 1.0;
    }

    return ApplicationAnalysisResult(
      talhaoId: latestEntry.talhaoId,
      organismoId: latestEntry.organismoId,
      nivel: latestEntry.nivel,
      percentual: percentual,
      aplicar: aplicar,
      recomendacao: recomendacao,
      justificativa: justificativa,
      prioridade: prioridade,
      dataAnalise: DateTime.now(),
    );
  }

  /// Analisa tendência simples dos dados
  String _analyzeTendency(List<InfestationTimelineModel> entries) {
    if (entries.length < 2) return 'ESTAVEL';

    // Ordenar por data
    final sortedEntries = List<InfestationTimelineModel>.from(entries)
      ..sort((a, b) => a.dataOcorrencia.compareTo(b.dataOcorrencia));

    final first = sortedEntries.first.percentual;
    final last = sortedEntries.last.percentual;
    final diff = last - first;

    if (diff > 5.0) return 'CRESCENTE';
    if (diff < -5.0) return 'DECRESCENTE';
    return 'ESTAVEL';
  }

  /// Exporta dados para GeoJSON
  Future<File> exportToGeoJson({
    String? talhaoId,
    String? organismoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Logger.info('📤 Exportando dados para GeoJSON...');

      final analysisResults = await analyzeApplicationNeeds(
        talhaoId: talhaoId,
        organismoId: organismoId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      final features = <GeoJsonFeature>[];

      for (final result in analysisResults) {
        // Buscar coordenadas do talhão (simplificado)
        final timelineData = await _timelineRepository.getByTalhaoAndOrganismo(
          result.talhaoId,
          result.organismoId,
        );

        if (timelineData.isNotEmpty) {
          final entry = timelineData.first;
          
          final feature = GeoJsonFeature(
            properties: {
              'talhao_id': result.talhaoId,
              'organismo_id': result.organismoId,
              'nivel': result.nivel,
              'percentual': result.percentual,
              'aplicar': result.aplicar,
              'recomendacao': result.recomendacao,
              'justificativa': result.justificativa,
              'prioridade': result.prioridade,
              'data_analise': result.dataAnalise.toIso8601String(),
            },
            geometry: {
              'type': 'Point',
              'coordinates': [entry.longitude, entry.latitude],
            },
          );

          features.add(feature);
        }
      }

      final geoJsonData = GeoJsonExportData(features: features);
      final jsonString = geoJsonData.toJson();

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'infestation_export_$timestamp.geojson';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      Logger.info('✅ GeoJSON exportado: ${file.path}');
      return file;
    } catch (e) {
      Logger.error('❌ Erro ao exportar GeoJSON: $e');
      rethrow;
    }
  }

  /// Exporta dados para CSV
  Future<File> exportToCsv({
    String? talhaoId,
    String? organismoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Logger.info('📤 Exportando dados para CSV...');

      final analysisResults = await analyzeApplicationNeeds(
        talhaoId: talhaoId,
        organismoId: organismoId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      final rows = analysisResults.map((result) => {
        'talhao_id': result.talhaoId,
        'organismo_id': result.organismoId,
        'nivel': result.nivel,
        'percentual': result.percentual,
        'aplicar': result.aplicar ? 'SIM' : 'NÃO',
        'recomendacao': result.recomendacao,
        'justificativa': result.justificativa,
        'prioridade': result.prioridade,
        'data_analise': result.dataAnalise.toIso8601String(),
      }).toList();

      final csvData = CsvExportData(rows: rows);
      final csvString = csvData.toCsv();

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'infestation_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvString);

      Logger.info('✅ CSV exportado: ${file.path}');
      return file;
    } catch (e) {
      Logger.error('❌ Erro ao exportar CSV: $e');
      rethrow;
    }
  }

  /// Obtém estatísticas de aplicação
  Future<Map<String, dynamic>> getApplicationStats() async {
    try {
      final allResults = await analyzeApplicationNeeds();
      
      final total = allResults.length;
      final aplicar = allResults.where((r) => r.aplicar).length;
      final naoAplicar = total - aplicar;
      
      final porNivel = <String, int>{};
      final porPrioridade = <String, int>{};

      for (final result in allResults) {
        porNivel[result.nivel] = (porNivel[result.nivel] ?? 0) + 1;
        
        if (result.prioridade >= 8.0) {
          porPrioridade['ALTA'] = (porPrioridade['ALTA'] ?? 0) + 1;
        } else if (result.prioridade >= 5.0) {
          porPrioridade['MEDIA'] = (porPrioridade['MEDIA'] ?? 0) + 1;
        } else {
          porPrioridade['BAIXA'] = (porPrioridade['BAIXA'] ?? 0) + 1;
        }
      }

      return {
        'total_analises': total,
        'aplicar': aplicar,
        'nao_aplicar': naoAplicar,
        'por_nivel': porNivel,
        'por_prioridade': porPrioridade,
        'percentual_aplicar': total > 0 ? (aplicar / total * 100).round() : 0,
        'ultima_analise': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de aplicação: $e');
      return {};
    }
  }
}
