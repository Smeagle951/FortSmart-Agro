import 'dart:math';
import '../models/infestation_timeline_model.dart';
import '../repositories/infestation_timeline_repository.dart';
import '../../../utils/logger.dart';

/// Resultado da análise de tendência temporal
class TendencyAnalysisResult {
  final String tendencia;
  final double coeficienteAngular;
  final double rQuadrado;
  final double intercepto;
  final int pontosAnalisados;
  final double periodoDias;
  final String confiabilidade;
  final String recomendacao;

  TendencyAnalysisResult({
    required this.tendencia,
    required this.coeficienteAngular,
    required this.rQuadrado,
    required this.intercepto,
    required this.pontosAnalisados,
    required this.periodoDias,
    required this.confiabilidade,
    required this.recomendacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'tendencia': tendencia,
      'coeficiente_angular': coeficienteAngular,
      'r_quadrado': rQuadrado,
      'intercepto': intercepto,
      'pontos_analisados': pontosAnalisados,
      'periodo_dias': periodoDias,
      'confiabilidade': confiabilidade,
      'recomendacao': recomendacao,
    };
  }
}

/// Dados para gráfico de timeline
class TimelineChartData {
  final List<DateTime> datas;
  final List<double> valores;
  final List<String> niveis;
  final String tendencia;
  final String corTendencia;

  TimelineChartData({
    required this.datas,
    required this.valores,
    required this.niveis,
    required this.tendencia,
    required this.corTendencia,
  });

  Map<String, dynamic> toMap() {
    return {
      'datas': datas.map((d) => d.toIso8601String()).toList(),
      'valores': valores,
      'niveis': niveis,
      'tendencia': tendencia,
      'cor_tendencia': corTendencia,
    };
  }
}

/// Serviço para análise temporal de infestação
class InfestationTimelineService {
  final InfestationTimelineRepository _repository;

  InfestationTimelineService(this._repository);

  /// Adiciona uma entrada na timeline a partir de dados de monitoramento
  Future<String> addTimelineEntry(
    String talhaoId,
    String organismoId,
    DateTime dataOcorrencia,
    int quantidade,
    String nivel,
    double percentual,
    double latitude,
    double longitude, {
    String? usuarioId,
    String? observacao,
    String? fotoPaths,
  }) async {
    try {
      final timelineEntry = InfestationTimelineModel(
        talhaoId: talhaoId,
        organismoId: organismoId,
        dataOcorrencia: dataOcorrencia,
        quantidade: quantidade,
        nivel: nivel,
        percentual: percentual,
        latitude: latitude,
        longitude: longitude,
        usuarioId: usuarioId,
        observacao: observacao,
        fotoPaths: fotoPaths,
      );

      final id = await _repository.insert(timelineEntry);
      Logger.info('✅ Entrada adicionada à timeline: $id');
      return id;
    } catch (e) {
      Logger.error('❌ Erro ao adicionar entrada na timeline: $e');
      rethrow;
    }
  }

  /// Obtém timeline para um talhão e organismo específicos
  Future<List<InfestationTimelineModel>> getTimeline(
    String talhaoId,
    String organismoId, {
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      return await _repository.getByTalhaoAndOrganismo(
        talhaoId,
        organismoId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
    } catch (e) {
      Logger.error('❌ Erro ao obter timeline: $e');
      return [];
    }
  }

  /// Analisa tendência temporal dos dados
  Future<TendencyAnalysisResult> analyzeTendency(
    List<InfestationTimelineModel> timelineData,
  ) async {
    try {
      if (timelineData.length < 2) {
        return TendencyAnalysisResult(
          tendencia: 'INSUFICIENTE_DADOS',
          coeficienteAngular: 0.0,
          rQuadrado: 0.0,
          intercepto: 0.0,
          pontosAnalisados: timelineData.length,
          periodoDias: 0.0,
          confiabilidade: 'BAIXA',
          recomendacao: 'Coletar mais dados para análise',
        );
      }

      // Ordenar por data
      final sortedData = List<InfestationTimelineModel>.from(timelineData)
        ..sort((a, b) => a.dataOcorrencia.compareTo(b.dataOcorrencia));

      final n = sortedData.length;
      final xValues = <double>[];
      final yValues = <double>[];

      // Converter datas para dias desde o primeiro ponto
      final firstDate = sortedData.first.dataOcorrencia;
      for (final entry in sortedData) {
        final days = entry.dataOcorrencia.difference(firstDate).inDays.toDouble();
        xValues.add(days);
        yValues.add(entry.percentual);
      }

      // Regressão linear simples
      final sumX = xValues.reduce((a, b) => a + b);
      final sumY = yValues.reduce((a, b) => a + b);
      final sumXY = xValues.asMap().entries.map((e) => e.value * yValues[e.key]).reduce((a, b) => a + b);
      final sumX2 = xValues.map((x) => x * x).reduce((a, b) => a + b);

      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;

      // Calcular R²
      final yMean = sumY / n;
      final ssRes = yValues.asMap().entries.map((e) {
        final yPred = slope * xValues[e.key] + intercept;
        return pow(e.value - yPred, 2);
      }).reduce((a, b) => a + b);

      final ssTot = yValues.map((y) => pow(y - yMean, 2)).reduce((a, b) => a + b);
      final rSquared = ssTot > 0 ? (1 - ssRes / ssTot) : 0.0;

      // Determinar tendência
      String tendencia;
      String confiabilidade;
      String recomendacao;

      if (rSquared < 0.3) {
        tendencia = 'ESTAVEL';
        confiabilidade = 'BAIXA';
        recomendacao = 'Dados inconsistentes, coletar mais amostras';
      } else if (slope > 1.0) {
        tendencia = 'CRESCENTE_FORTE';
        confiabilidade = rSquared > 0.7 ? 'ALTA' : 'MEDIA';
        recomendacao = 'Ação imediata necessária - infestação em crescimento acelerado';
      } else if (slope > 0.1) {
        tendencia = 'CRESCENTE_SUAVE';
        confiabilidade = rSquared > 0.7 ? 'ALTA' : 'MEDIA';
        recomendacao = 'Monitorar de perto - tendência de crescimento';
      } else if (slope < -1.0) {
        tendencia = 'DECRESCENTE_FORTE';
        confiabilidade = rSquared > 0.7 ? 'ALTA' : 'MEDIA';
        recomendacao = 'Boa evolução - infestação em redução significativa';
      } else if (slope < -0.1) {
        tendencia = 'DECRESCENTE_SUAVE';
        confiabilidade = rSquared > 0.7 ? 'ALTA' : 'MEDIA';
        recomendacao = 'Evolução positiva - infestação em redução';
      } else {
        tendencia = 'ESTAVEL';
        confiabilidade = rSquared > 0.7 ? 'ALTA' : 'MEDIA';
        recomendacao = 'Situação controlada - manter monitoramento';
      }

      return TendencyAnalysisResult(
        tendencia: tendencia,
        coeficienteAngular: slope,
        rQuadrado: rSquared,
        intercepto: intercept,
        pontosAnalisados: n,
        periodoDias: xValues.last - xValues.first,
        confiabilidade: confiabilidade,
        recomendacao: recomendacao,
      );
    } catch (e) {
      Logger.error('❌ Erro ao analisar tendência: $e');
      return TendencyAnalysisResult(
        tendencia: 'ERRO_ANALISE',
        coeficienteAngular: 0.0,
        rQuadrado: 0.0,
        intercepto: 0.0,
        pontosAnalisados: 0,
        periodoDias: 0.0,
        confiabilidade: 'BAIXA',
        recomendacao: 'Erro na análise - verificar dados',
      );
    }
  }

  /// Gera dados para gráfico de timeline
  Future<TimelineChartData> generateChartData(
    List<InfestationTimelineModel> timelineData,
  ) async {
    try {
      if (timelineData.isEmpty) {
        return TimelineChartData(
          datas: [],
          valores: [],
          niveis: [],
          tendencia: 'SEM_DADOS',
          corTendencia: '#9E9E9E',
        );
      }

      // Ordenar por data
      final sortedData = List<InfestationTimelineModel>.from(timelineData)
        ..sort((a, b) => a.dataOcorrencia.compareTo(b.dataOcorrencia));

      final datas = sortedData.map((e) => e.dataOcorrencia).toList();
      final valores = sortedData.map((e) => e.percentual).toList();
      final niveis = sortedData.map((e) => e.nivel).toList();

      // Analisar tendência para determinar cor
      final analysis = await analyzeTendency(timelineData);
      String corTendencia;

      switch (analysis.tendencia) {
        case 'CRESCENTE_FORTE':
          corTendencia = '#F44336'; // Vermelho
          break;
        case 'CRESCENTE_SUAVE':
          corTendencia = '#FF9800'; // Laranja
          break;
        case 'DECRESCENTE_FORTE':
          corTendencia = '#4CAF50'; // Verde
          break;
        case 'DECRESCENTE_SUAVE':
          corTendencia = '#8BC34A'; // Verde claro
          break;
        case 'ESTAVEL':
          corTendencia = '#2196F3'; // Azul
          break;
        default:
          corTendencia = '#9E9E9E'; // Cinza
      }

      return TimelineChartData(
        datas: datas,
        valores: valores,
        niveis: niveis,
        tendencia: analysis.tendencia,
        corTendencia: corTendencia,
      );
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados do gráfico: $e');
      return TimelineChartData(
        datas: [],
        valores: [],
        niveis: [],
        tendencia: 'ERRO',
        corTendencia: '#9E9E9E',
      );
    }
  }

  /// Obtém estatísticas consolidadas por talhão
  Future<Map<String, dynamic>> getTalhaoStats(String talhaoId) async {
    try {
      final timelineData = await _repository.getByTalhao(talhaoId);
      
      if (timelineData.isEmpty) {
        return {
          'total_entradas': 0,
          'organismos_unicos': 0,
          'periodo_dias': 0,
          'nivel_atual': 'DESCONHECIDO',
          'tendencia_geral': 'SEM_DADOS',
        };
      }

      // Agrupar por organismo
      final organismos = timelineData.map((e) => e.organismoId).toSet();
      
      // Calcular período
      final datas = timelineData.map((e) => e.dataOcorrencia).toList();
      datas.sort();
      final periodoDias = datas.last.difference(datas.first).inDays;

      // Determinar nível atual (mais recente)
      final ultimaEntrada = timelineData.reduce((a, b) => 
        a.dataOcorrencia.isAfter(b.dataOcorrencia) ? a : b);

      // Analisar tendência geral
      final analysis = await analyzeTendency(timelineData);

      return {
        'total_entradas': timelineData.length,
        'organismos_unicos': organismos.length,
        'periodo_dias': periodoDias,
        'nivel_atual': ultimaEntrada.nivel,
        'tendencia_geral': analysis.tendencia,
        'confiabilidade': analysis.confiabilidade,
        'recomendacao': analysis.recomendacao,
        'ultima_atualizacao': ultimaEntrada.dataOcorrencia.toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do talhão: $e');
      return {};
    }
  }

  /// Sincroniza dados pendentes
  Future<Map<String, dynamic>> syncPendingData() async {
    try {
      final pendingData = await _repository.getPendingSync();
      int successCount = 0;
      int errorCount = 0;

      for (final entry in pendingData) {
        try {
          // Aqui seria feita a sincronização com o servidor
          // Por enquanto, apenas simular sucesso
          await _repository.updateSyncStatus(
            entry.id,
            'synced',
            serverId: 'server_${entry.id}',
          );
          successCount++;
        } catch (e) {
          await _repository.updateSyncStatus(
            entry.id,
            'error',
            error: e.toString(),
          );
          errorCount++;
        }
      }

      return {
        'total_pendentes': pendingData.length,
        'sucessos': successCount,
        'erros': errorCount,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar dados pendentes: $e');
      return {
        'erro': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
