import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';

import '../services/organism_catalog_service.dart';
import '../utils/logger.dart';

/// Serviço de Relatórios para Monitoramento Avançado
/// Gera relatórios PDF, CSV e análises detalhadas
class MonitoringReportService {
  static const String _tag = 'MonitoringReportService';
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogService _catalogService = OrganismCatalogService();

  /// Gera relatório baseado na configuração
  Future<String> generateReport(ReportConfig config) async {
    Logger.info('$_tag: Gerando relatório ${config.type} em formato ${config.format}');
    
    try {
      final data = await _getReportData(config);
      
      switch (config.format) {
        case OutputFormat.pdf:
          return await _generatePdfReport(data, config);
        case OutputFormat.csv:
          return await _generateCsvReport(data, config);
        case OutputFormat.json:
          return await _generateJsonReport(data, config);
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Obtém dados para o relatório
  Future<Map<String, dynamic>> _getReportData(ReportConfig config) async {
    final db = await _database.database;
    
    switch (config.type) {
      case ReportType.sessionSummary:
        return await _getSessionSummaryData(config);
      case ReportType.infestationMap:
        return await _getInfestationMapData(config);
      case ReportType.trendAnalysis:
        return await _getTrendAnalysisData(config);
      case ReportType.organismComparison:
        return await _getOrganismComparisonData(config);
      case ReportType.fieldComparison:
        return await _getFieldComparisonData(config);
      case ReportType.customPeriod:
        return await _getCustomPeriodData(config);
    }
  }

  /// Dados de resumo de sessão
  Future<Map<String, dynamic>> _getSessionSummaryData(ReportConfig config) async {
    final db = await _database.database;
    final sessions = <Map<String, dynamic>>[];
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (config.sessionIds != null && config.sessionIds!.isNotEmpty) {
      whereClause += ' AND id IN (${config.sessionIds!.map((_) => '?').join(',')})';
      whereArgs.addAll(config.sessionIds!);
    }
    
    if (config.startDate != null) {
      whereClause += ' AND started_at >= ?';
      whereArgs.add(config.startDate!.toIso8601String());
    }
    
    if (config.endDate != null) {
      whereClause += ' AND finished_at <= ?';
      whereArgs.add(config.endDate!.toIso8601String());
    }
    
    final sessionData = await db.query(
      'monitoring_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'started_at DESC',
    );
    
    for (final session in sessionData) {
      final points = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [session['id']],
      );
      
      final occurrences = await db.rawQuery('''
        SELECT o.*, org.nome as organism_name, org.tipo as organism_type
        FROM monitoring_occurrences o
        INNER JOIN monitoring_points p ON o.point_id = p.id
        INNER JOIN catalog_organisms org ON o.organism_id = org.id
        WHERE p.session_id = ?
      ''', [session['id']]);
      
      sessions.add({
        'session': session,
        'points': points,
        'occurrences': occurrences,
        'summary': _calculateSessionSummary(points, occurrences),
      });
    }
    
    return {
      'type': 'session_summary',
      'sessions': sessions,
      'total_sessions': sessions.length,
      'period': {
        'start': config.startDate?.toIso8601String(),
        'end': config.endDate?.toIso8601String(),
      },
    };
  }

  /// Dados do mapa de infestação
  Future<Map<String, dynamic>> _getInfestationMapData(ReportConfig config) async {
    final db = await _database.database;
    
    final infestationData = await db.query(
      'infestation_map',
      where: config.startDate != null ? 'session_date >= ?' : null,
      whereArgs: config.startDate != null ? [config.startDate!.toIso8601String()] : null,
      orderBy: 'session_date DESC',
    );
    
    final organismStats = <String, Map<String, dynamic>>{};
    
    for (final data in infestationData) {
      final organismId = data['organism_id'] as int;
      if (!organismStats.containsKey(organismId.toString())) {
        final organism = await _catalogService.getOrganismById(organismId);
        organismStats[organismId.toString()] = {
          'organism': organism,
          'sessions': [],
          'total_points': 0,
          'average_infestation': 0.0,
          'max_infestation': 0.0,
          'critical_points': 0,
        };
      }
      
      final stats = organismStats[organismId.toString()]!;
      stats['sessions']!.add(data);
      stats['total_points'] = (stats['total_points'] as int) + (data['total_points'] as int);
      
      final avgInfestation = data['intensidade_media'] as double;
      stats['average_infestation'] = (stats['average_infestation'] as double) + avgInfestation;
      
      if (avgInfestation > (stats['max_infestation'] as double)) {
        stats['max_infestation'] = avgInfestation;
      }
      
      if (data['nivel'] == 'critico') {
        stats['critical_points'] = (stats['critical_points'] as int) + 1;
      }
    }
    
    // Calcular médias
    for (final stats in organismStats.values) {
      final sessionCount = (stats['sessions'] as List).length;
      if (sessionCount > 0) {
        stats['average_infestation'] = (stats['average_infestation'] as double) / sessionCount;
      }
    }
    
    return {
      'type': 'infestation_map',
      'organism_stats': organismStats,
      'total_sessions': infestationData.length,
      'period': {
        'start': config.startDate?.toIso8601String(),
        'end': config.endDate?.toIso8601String(),
      },
    };
  }

  /// Dados de análise de tendências
  Future<Map<String, dynamic>> _getTrendAnalysisData(ReportConfig config) async {
    final db = await _database.database;
    
    // Obter dados históricos por período
    final historicalData = await db.rawQuery('''
      SELECT 
        DATE(session_date) as date,
        organism_id,
        AVG(intensidade_media) as avg_intensity,
        COUNT(*) as session_count,
        SUM(CASE WHEN nivel = 'critico' THEN 1 ELSE 0 END) as critical_count
      FROM infestation_map
      WHERE session_date >= ?
      GROUP BY DATE(session_date), organism_id
      ORDER BY date ASC
    ''', [config.startDate?.toIso8601String() ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String()]);
    
    // Calcular tendências
    final trends = <String, Map<String, dynamic>>{};
    
    for (final data in historicalData) {
      final organismId = data['organism_id'] as int;
      if (!trends.containsKey(organismId.toString())) {
        final organism = await _catalogService.getOrganismById(organismId);
        trends[organismId.toString()] = {
          'organism': organism,
          'data_points': [],
          'trend_direction': 'stable',
          'trend_strength': 0.0,
        };
      }
      
      trends[organismId.toString()]!['data_points']!.add({
        'date': data['date'],
        'avg_intensity': data['avg_intensity'],
        'session_count': data['session_count'],
        'critical_count': data['critical_count'],
      });
    }
    
    // Calcular direção da tendência
    for (final trend in trends.values) {
      final dataPoints = trend['data_points'] as List;
      if (dataPoints.length >= 2) {
        final first = dataPoints.first['avg_intensity'] as double;
        final last = dataPoints.last['avg_intensity'] as double;
        final change = last - first;
        
        if (change > 0.1) {
          trend['trend_direction'] = 'increasing';
          trend['trend_strength'] = change.abs();
        } else if (change < -0.1) {
          trend['trend_direction'] = 'decreasing';
          trend['trend_strength'] = change.abs();
        }
      }
    }
    
    return {
      'type': 'trend_analysis',
      'trends': trends,
      'period': {
        'start': config.startDate?.toIso8601String(),
        'end': config.endDate?.toIso8601String(),
      },
    };
  }

  /// Dados de comparação de organismos
  Future<Map<String, dynamic>> _getOrganismComparisonData(ReportConfig config) async {
    final db = await _database.database;
    
    final organisms = config.organismIds ?? [];
    if (organisms.isEmpty) {
      final allOrganisms = await _catalogService.getAllOrganisms();
      for (final organism in allOrganisms) {
        if (organism['id'] != null) {
          organisms.add(organism['id'].toString());
        }
      }
    }
    
    final comparison = <String, Map<String, dynamic>>{};
    
    for (final organismId in organisms) {
      final organism = await _catalogService.getOrganismById(int.parse(organismId));
      if (organism == null) {
        continue;
      }
      
      final occurrenceData = await db.rawQuery('''
        SELECT 
          o.valor_bruto,
          o.observacao,
          p.latitude,
          p.longitude,
          p.timestamp,
          s.fazenda_id,
          s.talhao_id
        FROM monitoring_occurrences o
        INNER JOIN monitoring_points p ON o.point_id = p.id
        INNER JOIN monitoring_sessions s ON p.session_id = s.id
        WHERE o.organism_id = ?
        AND p.timestamp >= ?
        ORDER BY p.timestamp DESC
      ''', [
        organismId,
        config.startDate?.toIso8601String() ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      ]);
      
      final normalizedValues = occurrenceData.map((data) {
        final valorBruto = data['valor_bruto'] as double;
        final unidade = organism['unidade'] ?? '';
        final baseDenominador = organism['base_denominador'] ?? 1;
        
        // Normalização simples baseada na unidade
        switch (unidade) {
          case "individuos/10_plantas":
            return (valorBruto / 10) * baseDenominador;
          case "individuos/planta":
            return valorBruto;
          case "percent_folha":
          case "percent_plantas":
            return valorBruto.clamp(0.0, 100.0);
          default:
            return valorBruto;
        }
      }).toList();
      
      comparison[organismId] = {
        'organism': organism,
        'occurrences': occurrenceData,
        'normalized_values': normalizedValues,
        'statistics': _calculateOrganismStatistics(normalizedValues.cast<double>()),
        'distribution': _calculateValueDistribution(normalizedValues.cast<double>()),
      };
    }
    
    return {
      'type': 'organism_comparison',
      'comparison': comparison,
      'period': {
        'start': config.startDate?.toIso8601String(),
        'end': config.endDate?.toIso8601String(),
      },
    };
  }

  /// Dados de comparação de campos
  Future<Map<String, dynamic>> _getFieldComparisonData(ReportConfig config) async {
    final db = await _database.database;
    
    final fields = config.fieldIds ?? [];
    if (fields.isEmpty) {
      final fieldData = await db.rawQuery('''
        SELECT DISTINCT talhao_id FROM monitoring_sessions
        WHERE started_at >= ?
      ''', [config.startDate?.toIso8601String() ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String()]);
      
      fields.addAll(fieldData.map((f) => f['talhao_id'] as String));
    }
    
    final fieldComparison = <String, Map<String, dynamic>>{};
    
    for (final fieldId in fields) {
      final sessions = await db.query(
        'monitoring_sessions',
        where: 'talhao_id = ? AND started_at >= ?',
        whereArgs: [
          fieldId,
          config.startDate?.toIso8601String() ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        ],
      );
      
      final fieldStats = <String, dynamic>{
        'field_id': fieldId,
        'sessions': sessions,
        'organisms': {},
      };
      
      for (final session in sessions) {
        final occurrences = await db.rawQuery('''
          SELECT o.organism_id, o.valor_bruto, org.nome, org.tipo
          FROM monitoring_occurrences o
          INNER JOIN monitoring_points p ON o.point_id = p.id
          INNER JOIN catalog_organisms org ON o.organism_id = org.id
          WHERE p.session_id = ?
        ''', [session['id']]);
        
        for (final occurrence in occurrences) {
          final organismId = occurrence['organism_id'] as int;
          if (!fieldStats['organisms'].containsKey(organismId.toString())) {
            fieldStats['organisms'][organismId.toString()] = {
              'name': occurrence['nome'],
              'type': occurrence['tipo'],
              'values': [],
              'sessions': 0,
            };
          }
          
          fieldStats['organisms'][organismId.toString()]['values'].add(occurrence['valor_bruto']);
          fieldStats['organisms'][organismId.toString()]['sessions']++;
        }
      }
      
      // Calcular estatísticas por organismo
      for (final organism in fieldStats['organisms'].values) {
        final values = organism['values'] as List<double>;
        organism['average'] = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
        organism['max'] = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
        organism['min'] = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
      }
      
      fieldComparison[fieldId] = fieldStats;
    }
    
    return {
      'type': 'field_comparison',
      'fields': fieldComparison,
      'period': {
        'start': config.startDate?.toIso8601String(),
        'end': config.endDate?.toIso8601String(),
      },
    };
  }

  /// Dados de período customizado
  Future<Map<String, dynamic>> _getCustomPeriodData(ReportConfig config) async {
    // Combina dados de diferentes tipos de relatório
    final sessionData = await _getSessionSummaryData(config);
    final infestationData = await _getInfestationMapData(config);
    final trendData = await _getTrendAnalysisData(config);
    
    return {
      'type': 'custom_period',
      'session_summary': sessionData,
      'infestation_map': infestationData,
      'trend_analysis': trendData,
      'period': {
        'start': config.startDate?.toIso8601String(),
        'end': config.endDate?.toIso8601String(),
      },
    };
  }

  /// Calcula resumo da sessão
  Map<String, dynamic> _calculateSessionSummary(List<Map<String, dynamic>> points, List<Map<String, dynamic>> occurrences) {
    final totalPoints = points.length;
    final totalOccurrences = occurrences.length;
    
    final organisms = <String, int>{};
    final levels = <String, int>{};
    
    for (final occurrence in occurrences) {
      final organismName = occurrence['organism_name'] as String;
      organisms[organismName] = (organisms[organismName] ?? 0) + 1;
      
      // Calcular nível baseado no valor
      final valor = occurrence['valor_bruto'] as double;
      String level = 'baixo';
      if (valor > 10) {
        level = 'alto';
      } else if (valor > 5) {
        level = 'medio';
      }
      
      levels[level] = (levels[level] ?? 0) + 1;
    }
    
    return {
      'total_points': totalPoints,
      'total_occurrences': totalOccurrences,
      'organisms_found': organisms,
      'infestation_levels': levels,
      'average_occurrences_per_point': totalPoints > 0 ? totalOccurrences / totalPoints : 0.0,
    };
  }

  /// Calcula estatísticas do organismo
  Map<String, dynamic> _calculateOrganismStatistics(List<double> values) {
    if (values.isEmpty) {
      return {
        'count': 0,
        'average': 0.0,
        'max': 0.0,
        'min': 0.0,
        'std_deviation': 0.0,
      };
    }
    
    final count = values.length;
    final sum = values.reduce((a, b) => a + b);
    final average = sum / count;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    final variance = values.map((v) => (v - average) * (v - average)).reduce((a, b) => a + b) / count;
    final stdDeviation = sqrt(variance);
    
    return {
      'count': count,
      'average': average,
      'max': max,
      'min': min,
      'std_deviation': stdDeviation,
    };
  }

  /// Calcula distribuição de valores
  Map<String, int> _calculateValueDistribution(List<double> values) {
    final distribution = <String, int>{
      'baixo': 0,
      'medio': 0,
      'alto': 0,
      'critico': 0,
    };
    
    for (final value in values) {
      if (value <= 2) {
        distribution['baixo'] = (distribution['baixo'] ?? 0) + 1;
      } else if (value <= 5) {
        distribution['medio'] = (distribution['medio'] ?? 0) + 1;
      } else if (value <= 10) {
        distribution['alto'] = (distribution['alto'] ?? 0) + 1;
      } else {
        distribution['critico'] = (distribution['critico'] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  /// Gera relatório PDF
  Future<String> _generatePdfReport(Map<String, dynamic> data, ReportConfig config) async {
    // Implementação do PDF seria feita com uma biblioteca como pdf
    // Por enquanto, retorna um placeholder
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf');
    
    // Simular geração de PDF
    await file.writeAsString('PDF Report Placeholder');
    
    Logger.info('$_tag: Relatório PDF gerado: ${file.path}');
    return file.path;
  }

  /// Gera relatório CSV
  Future<String> _generateCsvReport(Map<String, dynamic> data, ReportConfig config) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    final csvContent = _convertToCsv(data, config);
    await file.writeAsString(csvContent);
    
    Logger.info('$_tag: Relatório CSV gerado: ${file.path}');
    return file.path;
  }

  /// Gera relatório JSON
  Future<String> _generateJsonReport(Map<String, dynamic> data, ReportConfig config) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.json');
    
    final jsonContent = jsonEncode(data);
    await file.writeAsString(jsonContent);
    
    Logger.info('$_tag: Relatório JSON gerado: ${file.path}');
    return file.path;
  }

  /// Converte dados para CSV
  String _convertToCsv(Map<String, dynamic> data, ReportConfig config) {
    final buffer = StringBuffer();
    
    switch (data['type']) {
      case 'session_summary':
        _convertSessionSummaryToCsv(data, buffer);
        break;
      case 'infestation_map':
        _convertInfestationMapToCsv(data, buffer);
        break;
      case 'trend_analysis':
        _convertTrendAnalysisToCsv(data, buffer);
        break;
      default:
        buffer.writeln('Tipo de relatório não suportado para CSV');
    }
    
    return buffer.toString();
  }

  /// Converte resumo de sessão para CSV
  void _convertSessionSummaryToCsv(Map<String, dynamic> data, StringBuffer buffer) {
    buffer.writeln('Sessão,Data Início,Data Fim,Pontos,Ocorrências,Organismos Encontrados');
    
    for (final sessionData in data['sessions']) {
      final session = sessionData['session'];
      final summary = sessionData['summary'];
      
      buffer.writeln('${session['id']},${session['started_at']},${session['finished_at']},'
          '${summary['total_points']},${summary['total_occurrences']},'
          '${summary['organisms_found'].keys.join(';')}');
    }
  }

  /// Converte mapa de infestação para CSV
  void _convertInfestationMapToCsv(Map<String, dynamic> data, StringBuffer buffer) {
    buffer.writeln('Organismo,Tipo,Sessões,Pontos Totais,Intensidade Média,Máxima Infestação,Pontos Críticos');
    
    for (final entry in data['organism_stats'].entries) {
      final stats = entry.value;
      final organism = stats['organism'];
      
      buffer.writeln('${organism['nome']},${organism['tipo']},${stats['sessions'].length},'
          '${stats['total_points']},${stats['average_infestation'].toStringAsFixed(2)},'
          '${stats['max_infestation'].toStringAsFixed(2)},${stats['critical_points']}');
    }
  }

  /// Converte análise de tendências para CSV
  void _convertTrendAnalysisToCsv(Map<String, dynamic> data, StringBuffer buffer) {
    buffer.writeln('Organismo,Direção Tendência,Força Tendência,Data Início,Data Fim');
    
    for (final entry in data['trends'].entries) {
      final trend = entry.value;
      final organism = trend['organism'];
      final dataPoints = trend['data_points'] as List;
      
      if (dataPoints.isNotEmpty) {
        buffer.writeln('${organism['nome']},${trend['trend_direction']},'
            '${trend['trend_strength'].toStringAsFixed(2)},'
            '${dataPoints.first['date']},${dataPoints.last['date']}');
      }
    }
  }
}

/// Tipos de relatório disponíveis
enum ReportType {
  sessionSummary,
  infestationMap,
  trendAnalysis,
  organismComparison,
  fieldComparison,
  customPeriod,
}

/// Formato de saída
enum OutputFormat {
  pdf,
  csv,
  json,
}

/// Configurações do relatório
class ReportConfig {
  final ReportType type;
  final OutputFormat format;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? sessionIds;
  final List<String>? organismIds;
  final List<String>? fieldIds;
  final bool includeCharts;
  final bool includePhotos;
  final String? customTitle;

  ReportConfig({
    required this.type,
    required this.format,
    this.startDate,
    this.endDate,
    this.sessionIds,
    this.organismIds,
    this.fieldIds,
    this.includeCharts = true,
    this.includePhotos = true,
    this.customTitle,
  });
}
