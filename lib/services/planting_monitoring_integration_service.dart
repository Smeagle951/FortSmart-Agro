import '../models/planting_cv_model.dart';
import '../models/planting_stand_model.dart';
import '../models/planting_integration_model.dart';
import '../enums/integration_analysis_enum.dart';
import '../models/monitoring.dart';
import '../services/integrated_monitoring_service.dart';
import '../utils/logger.dart';

/// Serviço de integração entre Plantio (CV% + Estande) e Monitoramento
class PlantingMonitoringIntegrationService {
  static const String _tag = 'PlantingMonitoringIntegrationService';
  
  final IntegratedMonitoringService _monitoringService = IntegratedMonitoringService();

  /// Integra dados de plantio com o módulo de monitoramento
  /// 
  /// Parâmetros:
  /// - integracao: Dados de integração CV% + Estande
  /// - talhaoId: ID do talhão
  /// 
  /// Retorna: Map com dados integrados para o monitoramento
  Future<Map<String, dynamic>> integrarComMonitoramento({
    required PlantingIntegrationModel integracao,
    required String talhaoId,
  }) async {
    try {
      Logger.info('$_tag: Iniciando integração com módulo de monitoramento');
      Logger.info('$_tag: Talhão: ${integracao.talhaoNome}');
      Logger.info('$_tag: Cultura: ${integracao.culturaNome}');

      // 1. Preparar dados de contexto para o monitoramento
      final contextoPlantio = _prepararContextoPlantio(integracao);
      
      // 2. Gerar alertas baseados na análise de integração
      final alertas = _gerarAlertasMonitoramento(integracao);
      
      // 3. Preparar recomendações para o monitoramento
      final recomendacoesMonitoramento = _prepararRecomendacoesMonitoramento(integracao);
      
      // 4. Criar resumo para relatórios
      final resumoRelatorio = _criarResumoRelatorio(integracao);

      final dadosIntegrados = {
        'talhao_id': talhaoId,
        'contexto_plantio': contextoPlantio,
        'alertas': alertas,
        'recomendacoes_monitoramento': recomendacoesMonitoramento,
        'resumo_relatorio': resumoRelatorio,
        'data_integracao': DateTime.now().toIso8601String(),
      };

      Logger.info('$_tag: ✅ Integração com monitoramento concluída');
      return dadosIntegrados;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro na integração com monitoramento: $e');
      rethrow;
    }
  }

  /// Prepara contexto de plantio para o monitoramento
  Map<String, dynamic> _prepararContextoPlantio(PlantingIntegrationModel integracao) {
    final contexto = <String, dynamic>{
      'cultura': integracao.culturaNome,
      'analise_integracao': integracao.analiseIntegracao.toString().split('.').last,
      'nivel_prioridade': integracao.nivelPrioridade.toString().split('.').last,
      'diagnostico_ia': integracao.diagnosticoIA,
    };

    // Adicionar dados de CV% se disponível
    if (integracao.cvPlantio != null) {
      contexto['cv_plantio'] = {
        'coeficiente_variacao': integracao.cvPlantio!.coeficienteVariacao,
        'classificacao': integracao.cvPlantio!.classificacao.toString().split('.').last,
        'plantas_por_metro': integracao.cvPlantio!.plantasPorMetro,
        'populacao_estimada_hectare': integracao.cvPlantio!.populacaoEstimadaPorHectare,
        'data_plantio': integracao.cvPlantio!.dataPlantio.toIso8601String(),
      };
    }

    // Adicionar dados de estande se disponível
    if (integracao.estandePlantas != null) {
      contexto['estande_plantas'] = {
        'populacao_real_hectare': integracao.estandePlantas!.populacaoRealPorHectare,
        'classificacao': integracao.estandePlantas!.classificacao.toString().split('.').last,
        'plantas_por_metro': integracao.estandePlantas!.plantasPorMetro,
        'percentual_atingido_populacao_alvo': integracao.estandePlantas!.percentualAtingidoPopulacaoAlvo,
        'data_avaliacao': integracao.estandePlantas!.dataAvaliacao.toIso8601String(),
      };
    }

    return contexto;
  }

  /// Gera alertas para o módulo de monitoramento
  List<Map<String, dynamic>> _gerarAlertasMonitoramento(PlantingIntegrationModel integracao) {
    final alertas = <Map<String, dynamic>>[];

    switch (integracao.analiseIntegracao) {
      case IntegrationAnalysis.excelencia:
        alertas.add({
          'tipo': 'sucesso',
          'nivel': 'baixo',
          'titulo': 'Plantio de Excelência',
          'descricao': 'CV% e estande ideais detectados. Continuar monitoramento regular.',
          'cor': '#4CAF50',
          'icone': 'check_circle',
        });
        break;

      case IntegrationAnalysis.plantioIrregular:
        alertas.add({
          'tipo': 'critico',
          'nivel': 'alto',
          'titulo': 'Plantio Irregular - Ação Necessária',
          'descricao': 'CV% ruim e estande baixo. Verificar regulagem da plantadeira e considerar replantio.',
          'cor': '#F44336',
          'icone': 'error',
        });
        break;

      case IntegrationAnalysis.germinacaoBaixa:
        alertas.add({
          'tipo': 'atencao',
          'nivel': 'medio',
          'titulo': 'Germinação Baixa',
          'descricao': 'Plantio bom mas germinação baixa. Investigar qualidade das sementes e condições de solo.',
          'cor': '#FF9800',
          'icone': 'warning',
        });
        break;

      case IntegrationAnalysis.compensacaoGerminacao:
        alertas.add({
          'tipo': 'info',
          'nivel': 'baixo',
          'titulo': 'Germinação Compensou Irregularidade',
          'descricao': 'Plantio irregular mas estande adequado. Melhorar regulagem para próximas safras.',
          'cor': '#2196F3',
          'icone': 'info',
        });
        break;

      case IntegrationAnalysis.dadosIncompletos:
        alertas.add({
          'tipo': 'info',
          'nivel': 'medio',
          'titulo': 'Dados Incompletos',
          'descricao': 'Completar registro de CV% e estande para análise mais precisa.',
          'cor': '#9E9E9E',
          'icone': 'help_outline',
        });
        break;
      case null:
        alertas.add({
          'tipo': 'erro',
          'nivel': 'alto',
          'titulo': 'Análise Não Disponível',
          'descricao': 'Não foi possível realizar análise de integração.',
          'cor': '#F44336',
          'icone': 'error',
        });
        break;
    }

    return alertas;
  }

  /// Prepara recomendações específicas para o monitoramento
  List<Map<String, dynamic>> _prepararRecomendacoesMonitoramento(PlantingIntegrationModel integracao) {
    final recomendacoes = <Map<String, dynamic>>[];

    // Recomendações baseadas na análise de integração
    switch (integracao.analiseIntegracao) {
      case IntegrationAnalysis.excelencia:
        recomendacoes.addAll([
          {
            'categoria': 'monitoramento',
            'acao': 'Continuar monitoramento regular',
            'frequencia': 'semanal',
            'prioridade': 'baixa',
          },
          {
            'categoria': 'desenvolvimento',
            'acao': 'Monitorar desenvolvimento das plantas',
            'frequencia': 'quinzenal',
            'prioridade': 'baixa',
          },
        ]);
        break;

      case IntegrationAnalysis.plantioIrregular:
        recomendacoes.addAll([
          {
            'categoria': 'urgente',
            'acao': 'Verificar regulagem da plantadeira',
            'frequencia': 'imediato',
            'prioridade': 'critica',
          },
          {
            'categoria': 'monitoramento',
            'acao': 'Monitoramento intensivo do desenvolvimento',
            'frequencia': 'diario',
            'prioridade': 'alta',
          },
          {
            'categoria': 'avaliacao',
            'acao': 'Avaliar necessidade de replantio',
            'frequencia': 'imediato',
            'prioridade': 'alta',
          },
        ]);
        break;

      case IntegrationAnalysis.germinacaoBaixa:
        recomendacoes.addAll([
          {
            'categoria': 'investigacao',
            'acao': 'Avaliar qualidade das sementes',
            'frequencia': 'imediato',
            'prioridade': 'alta',
          },
          {
            'categoria': 'solo',
            'acao': 'Verificar condições de solo e umidade',
            'frequencia': 'imediato',
            'prioridade': 'alta',
          },
          {
            'categoria': 'monitoramento',
            'acao': 'Monitoramento intensivo do desenvolvimento',
            'frequencia': 'diario',
            'prioridade': 'media',
          },
        ]);
        break;

      case IntegrationAnalysis.compensacaoGerminacao:
        recomendacoes.addAll([
          {
            'categoria': 'melhoria',
            'acao': 'Melhorar regulagem da plantadeira',
            'frequencia': 'proxima_safra',
            'prioridade': 'media',
          },
          {
            'categoria': 'monitoramento',
            'acao': 'Continuar monitoramento regular',
            'frequencia': 'semanal',
            'prioridade': 'baixa',
          },
        ]);
        break;

      case IntegrationAnalysis.dadosIncompletos:
        recomendacoes.addAll([
          {
            'categoria': 'coleta_dados',
            'acao': 'Completar registro de CV% do plantio',
            'frequencia': 'imediato',
            'prioridade': 'media',
          },
          {
            'categoria': 'coleta_dados',
            'acao': 'Completar registro de estande de plantas',
            'frequencia': 'imediato',
            'prioridade': 'media',
          },
        ]);
        break;
      case null:
        recomendacoes.addAll([
          {
            'categoria': 'erro',
            'acao': 'Verificar dados de integração',
            'frequencia': 'imediato',
            'prioridade': 'alta',
          },
        ]);
        break;
    }

    return recomendacoes;
  }

  /// Cria resumo para relatórios de monitoramento
  Map<String, dynamic> _criarResumoRelatorio(PlantingIntegrationModel integracao) {
    final resumo = <String, dynamic>{
      'talhao': integracao.talhaoNome,
      'cultura': integracao.culturaNome,
      'analise_integracao': integracao.analiseTexto,
      'nivel_prioridade': integracao.nivelPrioridade.toString().split('.').last,
      'diagnostico_ia': integracao.diagnosticoIA,
      'recomendacoes_principais': integracao.recomendacoes.take(3).toList(),
    };

    // Adicionar métricas se disponíveis
    if (integracao.cvPlantio != null) {
      resumo['cv_percentual'] = integracao.cvPlantio!.coeficienteVariacao;
      resumo['classificacao_cv'] = integracao.cvPlantio!.classificacaoTexto;
    }

    if (integracao.estandePlantas != null) {
      resumo['populacao_real_hectare'] = integracao.estandePlantas!.populacaoRealPorHectare;
      resumo['classificacao_estande'] = integracao.estandePlantas!.classificacaoTexto;
    }

    return resumo;
  }

  /// Processa dados de monitoramento considerando contexto de plantio
  Future<ProcessedOccurrence> processarMonitoramentoComContexto({
    required String talhaoId,
    required String organismoNome,
    required int quantidade,
    required String culturaNome,
    PlantingIntegrationModel? integracaoPlantio,
  }) async {
    try {
      Logger.info('$_tag: Processando monitoramento com contexto de plantio');

      // Processar ocorrência normalmente
      final resultado = await _monitoringService.processOccurrence(
        organismName: organismoNome,
        quantity: quantidade,
        cropName: culturaNome,
        fieldId: talhaoId,
      );

      if (resultado == null) {
        throw Exception('Falha no processamento da ocorrência');
      }

      // Adicionar contexto de plantio se disponível
      if (integracaoPlantio != null) {
        // Log do contexto de plantio
        Logger.info('$_tag: Contexto de plantio disponível:');
        Logger.info('$_tag: CV%: ${integracaoPlantio.cvPlantio?.coeficienteVariacao}%');
        Logger.info('$_tag: Estande: ${integracaoPlantio.estandePlantas?.populacaoRealPorHectare} plantas/ha');
        Logger.info('$_tag: Análise: ${integracaoPlantio.analiseTexto}');
        
        // Nota: ProcessedOccurrence não tem propriedades para contexto de plantio
        // O contexto será adicionado via logs e pode ser usado em relatórios
      }

      Logger.info('$_tag: ✅ Monitoramento processado com contexto de plantio');
      return resultado;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro no processamento com contexto: $e');
      rethrow;
    }
  }

  /// Gera insights para relatórios de monitoramento
  List<String> gerarInsightsRelatorio(PlantingIntegrationModel integracao) {
    final insights = <String>[];

    if (integracao.cvPlantio != null && integracao.estandePlantas != null) {
      // Insight sobre qualidade do plantio
      if (integracao.cvPlantio!.classificacao == CVClassification.excelente) {
        insights.add('✅ Plantio no ${integracao.talhaoNome} apresentou CV = ${integracao.cvPlantio!.coeficienteVariacao.toStringAsFixed(1)}% (excelente). '
                    'O estande final atingiu ${integracao.estandePlantas!.percentualAtingidoPopulacaoAlvo?.toStringAsFixed(1) ?? 'N/A'}% do alvo, '
                    'indicando ótima operação de plantio.');
      } else if (integracao.cvPlantio!.classificacao == CVClassification.ruim) {
        insights.add('⚠️ Plantio no ${integracao.talhaoNome} apresentou CV = ${integracao.cvPlantio!.coeficienteVariacao.toStringAsFixed(1)}% (ruim). '
                    'O estande foi ${integracao.estandePlantas!.percentualAtingidoPopulacaoAlvo?.toStringAsFixed(1) ?? 'N/A'}% do esperado. '
                    'Possível causa: falhas de regulagem da plantadeira.');
      }
    }

    // Insight sobre análise de integração
    switch (integracao.analiseIntegracao) {
      case IntegrationAnalysis.excelencia:
        insights.add('🎯 Análise integrada indica excelência na operação de plantio. '
                    'Recomenda-se manter as práticas atuais e documentar as condições de sucesso.');
        break;
      case IntegrationAnalysis.plantioIrregular:
        insights.add('🚨 Análise integrada indica problemas críticos no plantio. '
                    'Ação imediata necessária para evitar perdas de produtividade.');
        break;
      case IntegrationAnalysis.germinacaoBaixa:
        insights.add('🔍 Análise integrada indica plantio adequado mas germinação baixa. '
                    'Investigar qualidade das sementes e condições de solo.');
        break;
      case IntegrationAnalysis.compensacaoGerminacao:
        insights.add('⚖️ Análise integrada indica que a boa germinação compensou irregularidades do plantio. '
                    'Melhorar regulagem da plantadeira para otimizar ainda mais.');
        break;
      case IntegrationAnalysis.dadosIncompletos:
        insights.add('📊 Dados incompletos para análise integrada. '
                    'Completar registros de CV% e estande para insights mais precisos.');
        break;
      case null:
        insights.add('❌ Análise de integração não disponível. '
                    'Verificar dados de entrada e tentar novamente.');
        break;
    }

    return insights;
  }
}
