import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/monitoring.dart';
import '../../../models/monitoring_point.dart';
import '../../../utils/logger.dart';
import 'infestation_calculation_service.dart';
import 'talhao_integration_service.dart';
import 'talhao_infestation_calculation_service.dart';
import 'infestation_counting_service.dart';
import 'data_validation_service.dart';
import 'advanced_infestation_calculator.dart';
import '../repositories/infestation_repository.dart';
import '../models/infestation_summary.dart';

/// Serviço de integração para processar monitoramento e gerar dados de infestação
/// Implementa o pipeline completo: monitoramento → cálculo → resumo → alertas
class InfestacaoIntegrationService {
  final InfestationCalculationService _calculationService = InfestationCalculationService();
  final TalhaoIntegrationService _talhaoService = TalhaoIntegrationService();
  final TalhaoInfestationCalculationService _talhaoCalculationService = TalhaoInfestationCalculationService();
  final InfestationCountingService _countingService = InfestationCountingService();
  final DataValidationService _validationService = DataValidationService();
  final AdvancedInfestationCalculator _advancedCalculator = AdvancedInfestationCalculator();
  final InfestationRepository _repository = InfestationRepository();

  /// Processa um monitoramento para gerar dados de infestação
  /// Pipeline: validação → pontos → agrupamento → cálculo → resumo → alertas
  Future<void> processMonitoringForInfestation(Monitoring monitoring) async {
    try {
      Logger.info('🔄 Iniciando processamento de monitoramento: ${monitoring.id}');
      
      // 1) Validar dados reais
      final isValid = await _validationService.validateMonitoringData(monitoring);
      if (!isValid) {
        Logger.warning('⚠️ Monitoramento não passou na validação de dados reais: ${monitoring.id}');
        return;
      }
      
      // 2) Obter pontos do monitoramento (apenas dados reais)
      final pontos = _validationService.filterRealPoints(monitoring.points);
      if (pontos.isEmpty) {
        Logger.warning('⚠️ Nenhum ponto real encontrado para monitoramento: ${monitoring.id}');
        return;
      }

      Logger.info('📊 Processando ${pontos.length} pontos reais de monitoramento');

      // 2) Agrupar por organismo
      final byOrganism = <String, List<MonitoringPoint>>{};
      for (final ponto in pontos) {
        if (ponto.occurrences.isNotEmpty) {
          final occurrence = ponto.occurrences.first;
          final organismId = occurrence.name; // Usar nome como ID do organismo
          byOrganism.putIfAbsent(organismId, () => []).add(ponto);
        }
      }

      Logger.info('🔍 Organismos encontrados: ${byOrganism.keys.join(', ')}');

        // 3) Para cada organismo, calcular infestação por talhão
        final now = DateTime.now().toUtc();
        for (final entry in byOrganism.entries) {
          final organismId = entry.key;
          final organismPoints = entry.value;
          
          Logger.info('🧮 Calculando infestação por talhão para organismo: $organismId (${organismPoints.length} pontos)');
          
          // Obter polígono do talhão
          final talhaoPolygon = await _talhaoService.getTalhaoPolygon(monitoring.plotId.toString());
          if (talhaoPolygon == null || talhaoPolygon.isEmpty) {
            Logger.warning('⚠️ Polígono do talhão não encontrado: ${monitoring.plotId}');
            continue;
          }

          // Calcular infestação por talhão usando novo serviço
          final talhaoResult = await _talhaoCalculationService.calculateTalhaoInfestation(
            talhaoId: monitoring.plotId.toString(),
            organismoId: organismId,
            monitoringPoints: organismPoints,
            talhaoPolygon: talhaoPolygon,
            cropId: monitoring.cropId.toString(),
          );
          
          Logger.info('📊 Talhão: ${talhaoResult.talhaoId} | Organismo: ${talhaoResult.organismoId} | Infestação: ${talhaoResult.infestationPercentage.toStringAsFixed(1)}% | Nível: ${talhaoResult.severityLevel}');

        // 4) Gerar dados de hexbin para heatmap
        String? heatGeoJson;
        try {
          final talhaoPolygon = await _talhaoService.getTalhaoPolygon(monitoring.plotId.toString());
          if (talhaoPolygon != null && talhaoPolygon.isNotEmpty) {
            final hexbinData = await _calculationService.generateHexbinData(
              organismPoints,
              talhaoPolygon,
              organismoId: organismId,
            );
            heatGeoJson = hexbinData['geo_json']?.toString();
          }
        } catch (e) {
          Logger.warning('⚠️ Erro ao gerar hexbin: $e');
        }

        // 5) Upsert de resumo usando dados do talhão
        await _upsertInfestationSummary(
          talhaoId: monitoring.plotId.toString(),
          organismoId: organismId,
          periodoIni: monitoring.date.subtract(const Duration(days: 7)),
          periodoFim: monitoring.date,
          avgPct: talhaoResult.infestationPercentage,
          level: talhaoResult.severityLevel,
          heatGeoJson: heatGeoJson,
          metadata: talhaoResult.metadata,
        );

        // 6) Verificar se deve gerar alerta
        final shouldAlert = await _calculationService.shouldAlert(
          level: talhaoResult.severityLevel,
          pct: talhaoResult.infestationPercentage,
          organismoId: organismId,
        );

        if (shouldAlert) {
          await _createInfestationAlert(
            talhaoId: monitoring.plotId.toString(),
            organismoId: organismId,
            level: talhaoResult.severityLevel,
            description: 'Nível ${talhaoResult.severityLevel} detectado para organismo $organismId (${talhaoResult.infestationPercentage.toStringAsFixed(1)}%)',
            monitoringId: monitoring.id,
          );
          
          Logger.info('🚨 Alerta criado para organismo: $organismId (Nível: ${talhaoResult.severityLevel})');
        }
      }

      // 7) Atualizar resumo integrado do talhão
      await _updateTalhaoResumoFromInfestation(monitoring.plotId.toString());
      
      Logger.info('✅ Processamento de monitoramento concluído: ${monitoring.id}');
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramento: $e');
      rethrow;
    }
  }

  /// Processa múltiplos monitoramentos em lote (apenas dados reais)
  Future<void> processMultipleMonitorings(List<Monitoring> monitorings) async {
    try {
      Logger.info('🔄 Iniciando processamento em lote: ${monitorings.length} monitoramentos');
      
      // 1) Filtrar apenas monitoramentos com dados reais
      final realMonitorings = await _validationService.filterRealMonitorings(monitorings);
      Logger.info('📊 ${realMonitorings.length} monitoramentos reais de ${monitorings.length}');
      
      // 2) Processar cada monitoramento real
      for (final monitoring in realMonitorings) {
        try {
          await processMonitoringForInfestation(monitoring);
        } catch (e) {
          Logger.error('❌ Erro ao processar monitoramento ${monitoring.id}: $e');
          // Continuar com os próximos
        }
      }
      
      Logger.info('✅ Processamento em lote concluído com dados reais');
      
    } catch (e) {
      Logger.error('❌ Erro no processamento em lote: $e');
      rethrow;
    }
  }

  /// Processa monitoramento com contagem de números de infestação e geração de heatmaps térmicos
  Future<void> processMonitoringWithCounting(Monitoring monitoring) async {
    try {
      Logger.info('🔢 Processando monitoramento com contagem: ${monitoring.id}');
      
      // 1) Obter pontos do monitoramento
      final pontos = monitoring.points;
      if (pontos.isEmpty) {
        Logger.warning('⚠️ Nenhum ponto encontrado para monitoramento: ${monitoring.id}');
        return;
      }

      Logger.info('📊 Processando ${pontos.length} pontos com contagem de números');

      // 2) Contar números de infestação e calcular percentual médio do talhão
      final talhaoResult = await _countingService.countInfestationAndCalculateAverage(
        talhaoId: monitoring.plotId.toString(),
        monitoringPoints: pontos,
        cropId: monitoring.cropId.toString(),
      );

      Logger.info('📈 Talhão ${talhaoResult.talhaoId}: ${talhaoResult.averagePercentage.toStringAsFixed(1)}% - ${talhaoResult.overallSeverity}');
      Logger.info('🔥 ${talhaoResult.criticalSequentialPoints.length} pontos críticos sequenciais identificados');

      // 3) Salvar resultados no banco de dados
      await _saveCountingResults(talhaoResult, monitoring);

      // 4) Gerar alertas se necessário
      if (talhaoResult.overallSeverity == 'CRÍTICO' || talhaoResult.overallSeverity == 'ALTO') {
        await _generateInfestationAlert(talhaoResult, monitoring);
      }

      Logger.info('✅ Processamento com contagem concluído para monitoramento ${monitoring.id}');
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramento com contagem: $e');
      rethrow;
    }
  }

  /// Processa monitoramento usando fórmulas matemáticas precisas
  Future<void> processMonitoringWithMathematicalFormulas(Monitoring monitoring) async {
    try {
      Logger.info('🧮 Processando monitoramento com fórmulas matemáticas: ${monitoring.id}');
      
      // 1) Obter pontos do monitoramento
      final pontos = monitoring.points;
      if (pontos.isEmpty) {
        Logger.warning('⚠️ Nenhum ponto encontrado para monitoramento: ${monitoring.id}');
        return;
      }

      Logger.info('📊 Processando ${pontos.length} pontos com fórmulas matemáticas');

      // 2) Usar o serviço de cálculo de talhão existente
      final talhaoResult = await _talhaoCalculationService.calculateTalhaoInfestation(
        talhaoId: monitoring.plotId.toString(),
        organismoId: 'TALHAO_GERAL',
        monitoringPoints: pontos,
        talhaoPolygon: await _getTalhaoPolygon(monitoring.plotId.toString()),
        cropId: monitoring.cropId.toString(),
      );

      Logger.info('🧮 Talhão ${talhaoResult.talhaoId}: ${talhaoResult.infestationPercentage.toStringAsFixed(1)}% (${talhaoResult.severityLevel})');

      // 3) Salvar resultados matemáticos
      await _saveMathematicalResults(talhaoResult, monitoring);

      // 4) Gerar alertas baseados em fórmulas matemáticas
      if (talhaoResult.severityLevel == 'CRÍTICO') {
        await _generateMathematicalAlert(talhaoResult, monitoring);
      }

      Logger.info('✅ Processamento com fórmulas matemáticas concluído para monitoramento ${monitoring.id}');
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramento com fórmulas matemáticas: $e');
      rethrow;
    }
  }

  /// Processa monitoramentos por período
  Future<void> processMonitoringsByPeriod({
    required DateTime from,
    required DateTime to,
    String? talhaoId,
  }) async {
    try {
      Logger.info('🔄 Processando monitoramentos de ${from.toIso8601String()} até ${to.toIso8601String()}');
      
      // TODO: Implementar busca de monitoramentos por período
      // Por enquanto, usar lista vazia
      final monitorings = <Monitoring>[];
      
      if (monitorings.isNotEmpty) {
        await processMultipleMonitorings(monitorings);
      } else {
        Logger.info('ℹ️ Nenhum monitoramento encontrado no período especificado');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramentos por período: $e');
      rethrow;
    }
  }

  /// Processa monitoramentos de um talhão específico
  Future<void> processTalhaoMonitorings(String talhaoId, {Duration? lookback}) async {
    try {
      Logger.info('🔄 Processando monitoramentos do talhão: $talhaoId');
      
      final lookbackPeriod = lookback ?? const Duration(days: 30);
      final from = DateTime.now().subtract(lookbackPeriod);
      
      await processMonitoringsByPeriod(
        from: from,
        to: DateTime.now(),
        talhaoId: talhaoId,
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramentos do talhão: $e');
      rethrow;
    }
  }

  /// Recalcula dados de infestação para um período
  Future<void> recalculateInfestationData({
    required DateTime from,
    required DateTime to,
    String? talhaoId,
    String? organismoId,
  }) async {
    try {
      Logger.info('🔄 Recalculando dados de infestação para período: ${from.toIso8601String()} - ${to.toIso8601String()}');
      
      // TODO: Implementar recálculo
      // 1. Limpar dados existentes do período
      // 2. Buscar monitoramentos do período
      // 3. Reprocessar todos os monitoramentos
      // 4. Regenerar resumos e alertas
      
      Logger.info('ℹ️ Recálculo será implementado na próxima fase');
      
    } catch (e) {
      Logger.error('❌ Erro ao recalcular dados de infestação: $e');
      rethrow;
    }
  }

  /// Sincroniza dados de infestação com backend
  Future<void> syncInfestationData() async {
    try {
      Logger.info('🔄 Sincronizando dados de infestação com backend');
      
      // TODO: Implementar sincronização
      // 1. Buscar dados não sincronizados
      // 2. Enviar para backend
      // 3. Atualizar status de sincronização
      
      Logger.info('ℹ️ Sincronização será implementada na próxima fase');
      
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar dados de infestação: $e');
      rethrow;
    }
  }

  // ===== MÉTODOS PRIVADOS =====

  /// Upsert de resumo de infestação com persistência completa para timelapse
  Future<void> _upsertInfestationSummary({
    required String talhaoId,
    required String organismoId,
    required DateTime periodoIni,
    required DateTime periodoFim,
    required double avgPct,
    required String level,
    String? heatGeoJson,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      
      // Criar resumo completo com dados para timelapse
      final summary = InfestationSummary(
        id: '${talhaoId}_${organismoId}_${periodoFim.millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        organismoId: organismoId,
        periodoIni: periodoIni,
        periodoFim: periodoFim,
        avgInfestation: avgPct,
        infestationPercentage: avgPct,
        level: level,
        lastUpdate: now,
        lastMonitoringDate: periodoFim,
        heatGeoJson: heatGeoJson,
        totalPoints: metadata?['total_points'] ?? 0,
        pointsWithOccurrence: metadata?['points_with_occurrence'] ?? 0,
        trend: metadata?['trend'],
        severity: metadata?['severity'],
      );

      await _repository.upsertSummary(
        talhaoId: talhaoId,
        organismoId: organismoId,
        periodoIni: periodoIni,
        periodoFim: periodoFim,
        avgPct: avgPct,
        level: level,
        heatGeoJson: heatGeoJson,
      );
      
      // Salvar também no histórico para timelapse (dados históricos)
      await _saveHistoricalData(summary, metadata);
      
      Logger.info('💾 Upsert de resumo: Talhão: $talhaoId | Organismo: $organismoId | Nível: $level | Timestamp: ${now.toIso8601String()}');
      
    } catch (e) {
      Logger.error('❌ Erro ao fazer upsert de resumo: $e');
      rethrow;
    }
  }

  /// Salva dados históricos para timelapse
  Future<void> _saveHistoricalData(InfestationSummary summary, Map<String, dynamic>? metadata) async {
    try {
      final db = await _repository.database;
      final now = DateTime.now().toUtc();
      
      // Inserir no histórico de timelapse
      await db.insert(
        'infestation_timelapse',
        {
          'id': '${summary.talhaoId}_${summary.organismoId}_${now.millisecondsSinceEpoch}',
          'talhao_id': summary.talhaoId,
          'organismo_id': summary.organismoId,
          'data_coleta': summary.lastMonitoringDate?.toIso8601String() ?? now.toIso8601String(),
          'periodo_ini': summary.periodoIni.toIso8601String(),
          'periodo_fim': summary.periodoFim.toIso8601String(),
          'infestacao_percent': summary.infestationPercentage,
          'nivel': summary.level,
          'total_pontos': summary.totalPoints,
          'pontos_com_ocorrencia': summary.pointsWithOccurrence,
          'trend': summary.trend,
          'severity': summary.severity,
          'heat_geojson': summary.heatGeoJson,
          'metadata': metadata != null ? jsonEncode(metadata) : null,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('📊 Dados históricos salvos para timelapse: ${summary.talhaoId}_${summary.organismoId}');
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar dados históricos: $e');
      // Não rethrow para não interromper o fluxo principal
    }
  }

  /// Criar alerta de infestação
  Future<void> _createInfestationAlert({
    required String talhaoId,
    required String organismoId,
    required String level,
    required String description,
    String? monitoringId,
  }) async {
    try {
      await _repository.createAlert(
        talhaoId: talhaoId,
        organismoId: organismoId,
        level: level,
        description: description,
        monitoringId: monitoringId,
      );
      
      Logger.info('🚨 Criando alerta: Talhão: $talhaoId | Organismo: $organismoId | Nível: $level');
      
    } catch (e) {
      Logger.error('❌ Erro ao criar alerta: $e');
      rethrow;
    }
  }

  /// Atualizar resumo integrado do talhão
  Future<void> _updateTalhaoResumoFromInfestation(String talhaoId) async {
    try {
      // Obter estatísticas atualizadas do talhão
      final stats = await _repository.getInfestationStatsByTalhao(talhaoId);
      
      Logger.info('🔄 Resumo integrado atualizado para talhão: $talhaoId | Nível: ${stats['nivel_geral']} | Alertas: ${stats['alertas_ativos']}');
      
    } catch (e) {
      Logger.error('❌ Erro ao atualizar resumo integrado: $e');
      rethrow;
    }
  }

  /// Salva resultados da contagem no banco de dados
  Future<void> _saveCountingResults(TalhaoAverageResult result, Monitoring monitoring) async {
    try {
      // Salvar resumo geral do talhão
      await _upsertInfestationSummary(
        talhaoId: result.talhaoId,
        organismoId: 'TALHAO_GERAL',
        periodoIni: monitoring.date.subtract(const Duration(days: 7)),
        periodoFim: monitoring.date,
        avgPct: result.averagePercentage,
        level: result.overallSeverity,
        heatGeoJson: null,
        metadata: result.metadata,
      );

      // Salvar resultados por organismo
      for (final organismResult in result.organismResults) {
        await _upsertInfestationSummary(
          talhaoId: result.talhaoId,
          organismoId: organismResult.organismoId,
          periodoIni: monitoring.date.subtract(const Duration(days: 7)),
          periodoFim: monitoring.date,
          avgPct: organismResult.averagePerPoint,
          level: organismResult.severityLevel,
          heatGeoJson: null,
          metadata: organismResult.details,
        );
      }

      Logger.info('💾 Resultados da contagem salvos no banco de dados');
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar resultados da contagem: $e');
    }
  }

  /// Gera alerta de infestação baseado nos resultados da contagem
  Future<void> _generateInfestationAlert(TalhaoAverageResult result, Monitoring monitoring) async {
    try {
      final criticalOrganisms = result.organismResults
          .where((r) => r.severityLevel == 'CRÍTICO')
          .map((r) => r.organismoNome)
          .join(', ');

      final message = criticalOrganisms.isNotEmpty
          ? 'Infestação CRÍTICA detectada: $criticalOrganisms'
          : 'Infestação ${result.overallSeverity} detectada no talhão';

      final description = 'Talhão ${result.talhaoId}: ${result.averagePercentage.toStringAsFixed(1)}% de infestação média. '
          '${result.criticalSequentialPoints.length} pontos críticos sequenciais identificados.';

      await _createInfestationAlert(
        talhaoId: result.talhaoId,
        organismoId: 'TALHAO_GERAL',
        level: result.overallSeverity,
        description: description,
        monitoringId: monitoring.id,
      );

      Logger.info('🚨 Alerta de infestação gerado: $message');
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar alerta de infestação: $e');
    }
  }

  /// Obtém polígono do talhão
  Future<List<LatLng>> _getTalhaoPolygon(String talhaoId) async {
    try {
      final polygon = await _talhaoService.getTalhaoPolygon(talhaoId);
      return polygon ?? [];
    } catch (e) {
      Logger.warning('⚠️ Erro ao obter polígono do talhão $talhaoId: $e');
      return [];
    }
  }

  /// Salva resultados matemáticos no banco de dados
  Future<void> _saveMathematicalResults(
    TalhaoInfestationResult talhaoResult,
    Monitoring monitoring,
  ) async {
    try {
      // Salvar resultado geral do talhão
      await _upsertInfestationSummary(
        talhaoId: talhaoResult.talhaoId,
        organismoId: 'TALHAO_MATEMATICO',
        periodoIni: monitoring.date.subtract(const Duration(days: 7)),
        periodoFim: monitoring.date,
        avgPct: talhaoResult.infestationPercentage, // Já está em percentual
        level: talhaoResult.severityLevel,
        heatGeoJson: null,
        metadata: {
          'calculation_method': 'mathematical_formulas',
          'formulas_used': [
            'I_ponto = N_observado / N_limiar',
            'I_talhão = Σ(N_observado,i) / Σ(N_limiar,i)',
            'H_ponto = I_ponto × Peso_distância',
            'Peso_distância(d) = e^(-d²/2σ²)',
          ],
          'statistics': talhaoResult.metadata,
          'heatmap_metadata': {},
        },
      );

      // Salvar resultado geral do talhão (sem pointResults)
      Logger.info('💾 Resultado matemático salvo para talhão: ${talhaoResult.talhaoId}');

      Logger.info('💾 Resultados matemáticos salvos no banco de dados');
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar resultados matemáticos: $e');
    }
  }


  /// Gera alerta baseado em fórmulas matemáticas
  Future<void> _generateMathematicalAlert(
    TalhaoInfestationResult talhaoResult,
    Monitoring monitoring,
  ) async {
    try {
      final message = talhaoResult.severityLevel == 'CRÍTICO'
          ? 'Infestação CRÍTICA detectada matematicamente no talhão'
          : 'Infestação ${talhaoResult.severityLevel} detectada matematicamente no talhão';

      final description = 'Talhão ${talhaoResult.talhaoId}: ${talhaoResult.infestationPercentage.toStringAsFixed(1)}% '
          '(${talhaoResult.severityLevel}). '
          'Cálculo matemático baseado em fórmulas precisas.';

      await _createInfestationAlert(
        talhaoId: talhaoResult.talhaoId,
        organismoId: 'TALHAO_MATEMATICO',
        level: talhaoResult.severityLevel,
        description: description,
        monitoringId: monitoring.id,
      );

      Logger.info('🚨 Alerta matemático gerado: $message');
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar alerta matemático: $e');
    }
  }
}
