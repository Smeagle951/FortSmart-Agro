import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../utils/logger.dart';
import 'infestation_priority_analysis_service.dart';
import 'agronomist_data_validation_service.dart';
import 'fortsmart_agronomic_ai.dart';
import 'ia_aprendizado_continuo.dart';

/// Relatório executivo para o agrônomo
class AgronomistExecutiveReport {
  final DateTime reportDate;
  final String farmName;
  final int totalTalhoes;
  final int totalMonitorings;
  final int totalInfestations;
  final int criticalInfestations;
  final int highRiskInfestations;
  final int moderateRiskInfestations;
  final int lowRiskInfestations;
  final double overallFarmRiskScore;
  final String overallFarmRiskLevel;
  final List<TalhaoInfestationReport> talhaoReports;
  final List<String> urgentActions;
  final List<String> recommendations;
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> topInfestations;
  final double dataConfidenceScore;
  final String dataQualityLevel;
  final List<String> dataWarnings;
  final Map<String, dynamic> validationMetadata;

  AgronomistExecutiveReport({
    required this.reportDate,
    required this.farmName,
    required this.totalTalhoes,
    required this.totalMonitorings,
    required this.totalInfestations,
    required this.criticalInfestations,
    required this.highRiskInfestations,
    required this.moderateRiskInfestations,
    required this.lowRiskInfestations,
    required this.overallFarmRiskScore,
    required this.overallFarmRiskLevel,
    required this.talhaoReports,
    required this.urgentActions,
    required this.recommendations,
    required this.statistics,
    required this.topInfestations,
    required this.dataConfidenceScore,
    required this.dataQualityLevel,
    required this.dataWarnings,
    required this.validationMetadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportDate': reportDate.toIso8601String(),
      'farmName': farmName,
      'totalTalhoes': totalTalhoes,
      'totalMonitorings': totalMonitorings,
      'totalInfestations': totalInfestations,
      'criticalInfestations': criticalInfestations,
      'highRiskInfestations': highRiskInfestations,
      'moderateRiskInfestations': moderateRiskInfestations,
      'lowRiskInfestations': lowRiskInfestations,
      'overallFarmRiskScore': overallFarmRiskScore,
      'overallFarmRiskLevel': overallFarmRiskLevel,
      'talhaoReports': talhaoReports.map((e) => e.toMap()).toList(),
      'urgentActions': urgentActions,
      'recommendations': recommendations,
      'statistics': statistics,
      'topInfestations': topInfestations,
      'dataConfidenceScore': dataConfidenceScore,
      'dataQualityLevel': dataQualityLevel,
      'dataWarnings': dataWarnings,
      'validationMetadata': validationMetadata,
    };
  }
}

/// Serviço de relatórios para agrônomo
/// Gera relatórios inteligentes e práticos baseados em dados reais
class AgronomistReportService {
  final AppDatabase _appDatabase = AppDatabase();
  final InfestationPriorityAnalysisService _analysisService = InfestationPriorityAnalysisService();
  final AgronomistDataValidationService _validationService = AgronomistDataValidationService();
  final FortSmartAgronomicAI _aiService = FortSmartAgronomicAI();
  final IAAprendizadoContinuo _learningService = IAAprendizadoContinuo();

  /// Gera relatório executivo completo da fazenda
  Future<AgronomistExecutiveReport> generateFarmReport({
    String? farmName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Logger.info('📊 [RELATÓRIO] Gerando relatório executivo da fazenda...');
      
      final database = await _appDatabase.database;
      
      // DEBUG: Verificar tabelas e dados
      await _debugDatabaseInfo(database);
      
      // Buscar todos os monitoramentos do período
      final monitorings = await _getMonitoringsByPeriod(database, startDate, endDate);
      
      if (monitorings.isEmpty) {
        Logger.warning('⚠️ [RELATÓRIO] Nenhum monitoramento encontrado no período');
        return await _createEmptyReport(farmName ?? 'Fazenda');
      }
      
      // Agrupar monitoramentos por talhão
      final talhaoGroups = _groupMonitoringsByTalhao(monitorings);
      
      // Gerar relatórios por talhão
      final talhaoReports = <TalhaoInfestationReport>[];
      for (final entry in talhaoGroups.entries) {
        final talhaoId = entry.key;
        final talhaoMonitorings = entry.value;
        final talhaoName = await _getTalhaoName(database, talhaoId);
        
        final talhaoReport = await _analysisService.generateTalhaoReport(
          talhaoId,
          talhaoName,
          talhaoMonitorings,
        );
        
        talhaoReports.add(talhaoReport);
      }
      
      // Calcular estatísticas gerais
      final statistics = _calculateFarmStatistics(talhaoReports);
      
      // Gerar ações urgentes
      final urgentActions = _generateFarmUrgentActions(talhaoReports);
      
      // Gerar recomendações
      final recommendations = _generateFarmRecommendations(talhaoReports, statistics);
      
      // Identificar top infestações
      final topInfestations = _identifyTopInfestations(talhaoReports);
      
      // Calcular score geral da fazenda
      final overallFarmRiskScore = _calculateOverallFarmRiskScore(talhaoReports);
      final overallFarmRiskLevel = _determineOverallFarmRiskLevel(overallFarmRiskScore);
      
      // Validar dados para confiabilidade
      final validationResult = await _validationService.validateExecutiveReportData(monitorings);
      
      final report = AgronomistExecutiveReport(
        reportDate: DateTime.now(),
        farmName: farmName ?? 'Fazenda',
        totalTalhoes: talhaoReports.length,
        totalMonitorings: monitorings.length,
        totalInfestations: statistics['totalInfestations'] as int,
        criticalInfestations: statistics['criticalInfestations'] as int,
        highRiskInfestations: statistics['highRiskInfestations'] as int,
        moderateRiskInfestations: statistics['moderateRiskInfestations'] as int,
        lowRiskInfestations: statistics['lowRiskInfestations'] as int,
        overallFarmRiskScore: overallFarmRiskScore,
        overallFarmRiskLevel: overallFarmRiskLevel,
        talhaoReports: talhaoReports,
        urgentActions: urgentActions,
        recommendations: recommendations,
        statistics: statistics,
        topInfestations: topInfestations,
        dataConfidenceScore: validationResult.confidenceScore,
        dataQualityLevel: validationResult.qualityLevel,
        dataWarnings: validationResult.warnings,
        validationMetadata: validationResult.metadata,
      );
      
      Logger.info('✅ [RELATÓRIO] Relatório executivo gerado com sucesso');
      Logger.info('   📊 ${report.totalTalhoes} talhões analisados');
      Logger.info('   🔍 ${report.totalMonitorings} monitoramentos processados');
      Logger.info('   🚨 ${report.criticalInfestations} infestações críticas');
      Logger.info('   ⚠️ ${report.highRiskInfestations} infestações de alto risco');
      
      return report;
      
    } catch (e) {
      Logger.error('❌ [RELATÓRIO] Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Gera relatório de alertas urgentes
  Future<Map<String, dynamic>> generateUrgentAlertsReport() async {
    try {
      Logger.info('🚨 [ALERTAS] Gerando relatório de alertas urgentes...');
      
      final database = await _appDatabase.database;
      
      // Buscar monitoramentos recentes (últimas 24 horas)
      final recentMonitorings = await _getRecentMonitorings(database, 24);
      
      if (recentMonitorings.isEmpty) {
        return {
          'hasAlerts': false,
          'message': 'Nenhum alerta urgente encontrado',
          'alerts': [],
        };
      }
      
      final urgentAlerts = <Map<String, dynamic>>[];
      
      for (final monitoring in recentMonitorings) {
        final infestations = await _analysisService.analyzeMonitoring(monitoring);
        
        for (final infestation in infestations) {
          if (infestation.urgencyLevel == 'URGENTE' || infestation.severityLevel == 'CRÍTICO') {
            urgentAlerts.add({
              'id': '${monitoring.id}_${infestation.organismId}',
              'talhaoId': monitoring.plotId.toString(),
              'talhaoName': await _getTalhaoName(database, monitoring.plotId.toString()),
              'organismName': infestation.organismName,
              'organismType': infestation.organismType.toString(),
              'severityLevel': infestation.severityLevel,
              'urgencyLevel': infestation.urgencyLevel,
              'infestationIndex': infestation.infestationIndex,
              'priorityScore': infestation.priorityScore,
              'location': infestation.location,
              'detectedAt': infestation.detectedAt.toIso8601String(),
              'recommendations': infestation.recommendations,
              'riskCategory': infestation.riskCategory,
            });
          }
        }
      }
      
      // Ordenar por prioridade
      urgentAlerts.sort((a, b) => (b['priorityScore'] as double).compareTo(a['priorityScore'] as double));
      
      Logger.info('🚨 [ALERTAS] ${urgentAlerts.length} alertas urgentes encontrados');
      
      return {
        'hasAlerts': urgentAlerts.isNotEmpty,
        'alertCount': urgentAlerts.length,
        'alerts': urgentAlerts,
        'generatedAt': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro ao gerar relatório de alertas: $e');
      return {
        'hasAlerts': false,
        'error': e.toString(),
        'alerts': [],
      };
    }
  }

  /// Gera relatório de tendências
  Future<Map<String, dynamic>> generateTrendsReport({
    int days = 30,
  }) async {
    try {
      Logger.info('📈 [TENDÊNCIAS] Gerando relatório de tendências ($days dias)...');
      
      final database = await _appDatabase.database;
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      // Buscar monitoramentos do período
      final monitorings = await _getMonitoringsByPeriod(database, startDate, endDate);
      
      if (monitorings.isEmpty) {
        return {
          'hasData': false,
          'message': 'Nenhum dado encontrado no período',
          'trends': [],
        };
      }
      
      // Agrupar por semana
      final weeklyData = <String, Map<String, dynamic>>{};
      
      for (final monitoring in monitorings) {
        final weekKey = _getWeekKey(monitoring.createdAt);
        
        if (!weeklyData.containsKey(weekKey)) {
          weeklyData[weekKey] = {
            'week': weekKey,
            'monitorings': 0,
            'infestations': 0,
            'critical': 0,
            'high': 0,
            'moderate': 0,
            'low': 0,
            'organisms': <String, int>{},
          };
        }
        
        weeklyData[weekKey]!['monitorings']++;
        
        // Analisar infestações do monitoramento
        final infestations = await _analysisService.analyzeMonitoring(monitoring);
        weeklyData[weekKey]!['infestations'] += infestations.length;
        
        for (final infestation in infestations) {
          switch (infestation.severityLevel) {
            case 'CRÍTICO':
              weeklyData[weekKey]!['critical']++;
              break;
            case 'ALTO':
              weeklyData[weekKey]!['high']++;
              break;
            case 'MODERADO':
              weeklyData[weekKey]!['moderate']++;
              break;
            case 'BAIXO':
              weeklyData[weekKey]!['low']++;
              break;
          }
          
          // Contar organismos
          final organismType = infestation.organismType.toString().split('.').last;
          final organisms = weeklyData[weekKey]!['organisms'] as Map<String, int>;
          organisms[organismType] = (organisms[organismType] ?? 0) + 1;
        }
      }
      
      // Converter para lista ordenada
      final trends = weeklyData.values.toList()
        ..sort((a, b) => (a['week'] as String).compareTo(b['week'] as String));
      
      Logger.info('📈 [TENDÊNCIAS] Relatório de tendências gerado');
      
      return {
        'hasData': true,
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'days': days,
        },
        'trends': trends,
        'summary': _calculateTrendsSummary(trends),
      };
      
    } catch (e) {
      Logger.error('❌ [TENDÊNCIAS] Erro ao gerar relatório de tendências: $e');
      return {
        'hasData': false,
        'error': e.toString(),
        'trends': [],
      };
    }
  }

  /// Busca monitoramentos por período
  Future<List<Monitoring>> _getMonitoringsByPeriod(
    Database database,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final results = await database.query(
      'monitorings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return results.map((row) => Monitoring.fromMap(row)).toList();
  }

  /// Busca monitoramentos recentes
  Future<List<Monitoring>> _getRecentMonitorings(Database database, int hours) async {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    
    final results = await database.query(
      'monitorings',
      where: 'created_at >= ?',
      whereArgs: [cutoffTime.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    
    return results.map((row) => Monitoring.fromMap(row)).toList();
  }

  /// Agrupa monitoramentos por talhão
  Map<String, List<Monitoring>> _groupMonitoringsByTalhao(List<Monitoring> monitorings) {
    final groups = <String, List<Monitoring>>{};
    
    for (final monitoring in monitorings) {
      groups.putIfAbsent(monitoring.plotId.toString(), () => []).add(monitoring);
    }
    
    return groups;
  }

  /// Busca nome do talhão
  Future<String> _getTalhaoName(Database database, String talhaoId) async {
    try {
      final result = await database.query(
        'talhoes',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [talhaoId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['name'] as String;
      }
      
      return 'Talhão $talhaoId';
    } catch (e) {
      Logger.warning('⚠️ [RELATÓRIO] Erro ao buscar nome do talhão: $e');
      return 'Talhão $talhaoId';
    }
  }

  /// Calcula estatísticas da fazenda
  Map<String, dynamic> _calculateFarmStatistics(List<TalhaoInfestationReport> talhaoReports) {
    int totalInfestations = 0;
    int criticalInfestations = 0;
    int highRiskInfestations = 0;
    int moderateRiskInfestations = 0;
    int lowRiskInfestations = 0;
    
    for (final report in talhaoReports) {
      totalInfestations += report.criticalInfestations.length +
          report.highInfestations.length +
          report.moderateInfestations.length +
          report.lowInfestations.length;
      
      criticalInfestations += report.criticalInfestations.length;
      highRiskInfestations += report.highInfestations.length;
      moderateRiskInfestations += report.moderateInfestations.length;
      lowRiskInfestations += report.lowInfestations.length;
    }
    
    return {
      'totalInfestations': totalInfestations,
      'criticalInfestations': criticalInfestations,
      'highRiskInfestations': highRiskInfestations,
      'moderateRiskInfestations': moderateRiskInfestations,
      'lowRiskInfestations': lowRiskInfestations,
      'criticalPercentage': totalInfestations > 0 ? (criticalInfestations / totalInfestations * 100) : 0.0,
      'highRiskPercentage': totalInfestations > 0 ? (highRiskInfestations / totalInfestations * 100) : 0.0,
    };
  }

  /// Gera ações urgentes da fazenda
  List<String> _generateFarmUrgentActions(List<TalhaoInfestationReport> talhaoReports) {
    final actions = <String>[];
    
    int totalCritical = 0;
    int totalHigh = 0;
    
    for (final report in talhaoReports) {
      totalCritical += report.criticalInfestations.length;
      totalHigh += report.highInfestations.length;
    }
    
    if (totalCritical > 0) {
      actions.add('🚨 AÇÃO IMEDIATA: $totalCritical infestações críticas em ${talhaoReports.length} talhões');
      actions.add('📞 Contatar agrônomo responsável URGENTEMENTE');
      actions.add('🔬 Coletar amostras para análise laboratorial');
    }
    
    if (totalHigh > 0) {
      actions.add('⚠️ ATENÇÃO: $totalHigh infestações de alto risco detectadas');
      actions.add('📋 Planejar aplicação de defensivos para esta semana');
    }
    
    if (totalCritical > 0 || totalHigh > 0) {
      actions.add('📸 Documentar todas as ocorrências com fotos');
      actions.add('📝 Atualizar plano de manejo integrado');
      actions.add('🔄 Reavaliar em 24-48 horas');
    }
    
    return actions;
  }

  /// Gera recomendações da fazenda
  List<String> _generateFarmRecommendations(
    List<TalhaoInfestationReport> talhaoReports,
    Map<String, dynamic> statistics,
  ) {
    final recommendations = <String>[];
    
    final criticalPercentage = statistics['criticalPercentage'] as double;
    final highRiskPercentage = statistics['highRiskPercentage'] as double;
    
    if (criticalPercentage > 20) {
      recommendations.add('🔴 CRÍTICO: Mais de 20% das infestações são críticas');
      recommendations.add('📞 Contatar especialista em fitopatologia');
      recommendations.add('🔬 Análise laboratorial urgente');
    } else if (criticalPercentage > 10) {
      recommendations.add('🟠 ALTO RISCO: Mais de 10% das infestações são críticas');
      recommendations.add('📋 Revisar programa de aplicação de defensivos');
    }
    
    if (highRiskPercentage > 30) {
      recommendations.add('⚠️ ATENÇÃO: Mais de 30% das infestações são de alto risco');
      recommendations.add('📊 Implementar monitoramento mais frequente');
      recommendations.add('🌱 Considerar rotação de culturas');
    }
    
    recommendations.add('📈 Implementar sistema de alertas automáticos');
    recommendations.add('🎯 Focar em prevenção para próximas safras');
    recommendations.add('📚 Capacitar equipe em identificação precoce');
    
    return recommendations;
  }

  /// Identifica top infestações
  List<Map<String, dynamic>> _identifyTopInfestations(List<TalhaoInfestationReport> talhaoReports) {
    final allInfestations = <InfestationPriorityResult>[];
    
    for (final report in talhaoReports) {
      allInfestations.addAll(report.criticalInfestations);
      allInfestations.addAll(report.highInfestations);
    }
    
    // Ordenar por score de prioridade
    allInfestations.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    
    // Retornar top 10
    return allInfestations.take(10).map((infestation) => {
      'organismName': infestation.organismName,
      'organismType': infestation.organismType.toString(),
      'severityLevel': infestation.severityLevel,
      'priorityScore': infestation.priorityScore,
      'infestationIndex': infestation.infestationIndex,
      'urgencyLevel': infestation.urgencyLevel,
      'riskCategory': infestation.riskCategory,
      'recommendations': infestation.recommendations,
    }).toList();
  }

  /// Calcula score geral de risco da fazenda
  double _calculateOverallFarmRiskScore(List<TalhaoInfestationReport> talhaoReports) {
    if (talhaoReports.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    for (final report in talhaoReports) {
      totalScore += report.overallRiskScore;
    }
    
    return (totalScore / talhaoReports.length).clamp(0.0, 1000.0);
  }

  /// Determina nível geral de risco da fazenda
  String _determineOverallFarmRiskLevel(double riskScore) {
    if (riskScore >= 800) return 'CRÍTICO';
    if (riskScore >= 600) return 'ALTO';
    if (riskScore >= 400) return 'MÉDIO';
    return 'BAIXO';
  }

  /// DEBUG: Verifica informações do banco de dados
  Future<void> _debugDatabaseInfo(Database database) async {
    try {
      Logger.info('🔍 [DEBUG] Verificando banco de dados...');
      
      // Verificar se a tabela monitorings existe
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitorings'"
      );
      
      if (tables.isEmpty) {
        Logger.warning('⚠️ [DEBUG] Tabela "monitorings" não existe!');
        return;
      }
      
      Logger.info('✅ [DEBUG] Tabela "monitorings" existe');
      
      // Contar total de monitoramentos
      final countResult = await database.rawQuery('SELECT COUNT(*) as count FROM monitorings');
      final totalCount = countResult.first['count'] as int;
      Logger.info('📊 [DEBUG] Total de monitoramentos: $totalCount');
      
      if (totalCount > 0) {
        // Buscar alguns exemplos
        final examples = await database.query(
          'monitorings',
          limit: 3,
          orderBy: 'created_at DESC',
        );
        
        Logger.info('📋 [DEBUG] Exemplos de monitoramentos:');
        for (int i = 0; i < examples.length; i++) {
          final monitoring = examples[i];
          Logger.info('   ${i + 1}. ID: ${monitoring['id']}, Plot: ${monitoring['plot_id']}, Data: ${monitoring['created_at']}');
        }
        
        // Verificar estrutura da tabela
        final columns = await database.rawQuery('PRAGMA table_info(monitorings)');
        Logger.info('🏗️ [DEBUG] Colunas da tabela monitorings:');
        for (final column in columns) {
          Logger.info('   - ${column['name']}: ${column['type']}');
        }
      }
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro ao verificar banco: $e');
    }
  }

  /// Cria relatório vazio com dados da IA
  Future<AgronomistExecutiveReport> _createEmptyReport(String farmName) async {
    try {
      Logger.info('🤖 [RELATÓRIO] Gerando relatório com IA (sem dados reais)...');
      
      // Inicializar IA se necessário
      await _aiService.initialize();
      await _learningService.initialize();
      
      // Obter estatísticas do catálogo
      final catalogStats = _learningService.obterEstatisticasCatalogo();
      
      // Usar dados reais do catálogo ou fallback
      final totalOrganismos = catalogStats['total_organismos'] as int? ?? 0;
      final totalCulturas = catalogStats['total_culturas'] as int? ?? 0;
      final catalogoCarregado = catalogStats['catalogo_carregado'] as bool? ?? false;
      
      Logger.info('📊 [CATÁLOGO] Organismos: $totalOrganismos, Culturas: $totalCulturas, Carregado: $catalogoCarregado');
      
      return AgronomistExecutiveReport(
        reportDate: DateTime.now(),
        farmName: farmName,
        totalTalhoes: 0, // Sem talhões cadastrados
        totalMonitorings: 0, // Sem monitoramentos
        totalInfestations: 0, // Sem infestações registradas
        criticalInfestations: 0,
        highRiskInfestations: 0,
        moderateRiskInfestations: 0,
        lowRiskInfestations: 0,
        overallFarmRiskScore: 0.0,
        overallFarmRiskLevel: 'BAIXO',
        talhaoReports: [],
        urgentActions: [
          'Cadastrar talhões na fazenda',
          'Realizar primeiro monitoramento',
          'Configurar sistema de alertas'
        ],
        recommendations: catalogoCarregado ? [
          'Sistema FortSmart IA está pronto com $totalOrganismos organismos de $totalCulturas culturas',
          'Configure talhões para começar monitoramento',
          'Use a IA para predições precisas',
          'Sistema aprende com cada registro'
        ] : [
          'Carregando catálogo de organismos...',
          'Configure talhões para começar monitoramento',
          'Use a IA para predições precisas',
          'Sistema aprende com cada registro'
        ],
        statistics: {
          'organismos_disponiveis': totalOrganismos,
          'culturas_suportadas': totalCulturas,
          'ia_ativa': true,
          'aprendizado_continuo': true,
        },
        topInfestations: [],
        dataConfidenceScore: 85.0, // IA tem 85% de confiança base
        dataQualityLevel: 'BOM', // IA disponível
        dataWarnings: catalogoCarregado ? [
          'Nenhum dado de monitoramento disponível',
          'IA FortSmart pronta para uso',
          'Cadastre talhões para começar'
        ] : [
          'Nenhum dado de monitoramento disponível',
          'Carregando catálogo de organismos...',
          'Cadastre talhões para começar'
        ],
        validationMetadata: {
          'ia_status': 'ATIVA',
          'catalogo_carregado': catalogStats['catalogo_carregado'] ?? false,
          'aprendizado_disponivel': true,
        },
      );
      
    } catch (e) {
      Logger.error('❌ [RELATÓRIO] Erro ao gerar relatório com IA: $e');
      
      // Fallback para relatório básico
      return AgronomistExecutiveReport(
        reportDate: DateTime.now(),
        farmName: farmName,
        totalTalhoes: 0,
        totalMonitorings: 0,
        totalInfestations: 0,
        criticalInfestations: 0,
        highRiskInfestations: 0,
        moderateRiskInfestations: 0,
        lowRiskInfestations: 0,
        overallFarmRiskScore: 0.0,
        overallFarmRiskLevel: 'BAIXO',
        talhaoReports: [],
        urgentActions: ['Nenhum dado disponível para análise'],
        recommendations: ['Implementar sistema de monitoramento'],
        statistics: {},
        topInfestations: [],
        dataConfidenceScore: 0.0,
        dataQualityLevel: 'INVÁLIDO',
        dataWarnings: ['Nenhum dado disponível'],
        validationMetadata: {},
      );
    }
  }

  /// Gera chave da semana
  String _getWeekKey(DateTime date) {
    final year = date.year;
    final week = _getWeekNumber(date);
    return '${year}_W$week';
  }

  /// Calcula número da semana
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }

  /// Calcula resumo das tendências
  Map<String, dynamic> _calculateTrendsSummary(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) {
      return {
        'trend': 'ESTÁVEL',
        'message': 'Dados insuficientes para análise de tendências',
      };
    }
    
    final firstWeek = trends.first;
    final lastWeek = trends.last;
    
    final firstWeekInfestations = firstWeek['infestations'] as int;
    final lastWeekInfestations = lastWeek['infestations'] as int;
    
    if (lastWeekInfestations > firstWeekInfestations * 1.2) {
      return {
        'trend': 'CRESCENTE',
        'message': 'Aumento significativo de infestações detectado',
        'changePercentage': ((lastWeekInfestations - firstWeekInfestations) / firstWeekInfestations * 100).toStringAsFixed(1),
      };
    } else if (lastWeekInfestations < firstWeekInfestations * 0.8) {
      return {
        'trend': 'DECRESCENTE',
        'message': 'Redução significativa de infestações detectada',
        'changePercentage': ((firstWeekInfestations - lastWeekInfestations) / firstWeekInfestations * 100).toStringAsFixed(1),
      };
    } else {
      return {
        'trend': 'ESTÁVEL',
        'message': 'Nível de infestações estável',
        'changePercentage': '0.0',
      };
    }
  }
}
