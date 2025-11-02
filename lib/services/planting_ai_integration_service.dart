import '../models/planting_cv_model.dart';
import '../models/planting_stand_model.dart';
import '../models/planting_integration_model.dart';
import '../enums/integration_analysis_enum.dart';
import '../modules/ai/services/ai_diagnosis_service.dart';
import '../modules/ai/services/organism_prediction_service.dart';
import '../utils/logger.dart';

/// Serviço de integração entre Plantio (CV% + Estande) e IA Agronômica
class PlantingAIIntegrationService {
  static const String _tag = 'PlantingAIIntegrationService';
  
  final AIDiagnosisService _aiDiagnosisService = AIDiagnosisService();
  final OrganismPredictionService _predictionService = OrganismPredictionService();

  /// Analisa a integração entre CV% e Estande usando IA
  /// 
  /// Parâmetros:
  /// - cvPlantio: Dados do CV% do plantio
  /// - estandePlantas: Dados do estande de plantas
  /// 
  /// Retorna: PlantingIntegrationModel com análise completa
  Future<PlantingIntegrationModel> analisarIntegracaoComIA({
    required PlantingCVModel? cvPlantio,
    required PlantingStandModel? estandePlantas,
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
  }) async {
    try {
      Logger.info('$_tag: Iniciando análise de integração com IA');
      Logger.info('$_tag: Talhão: $talhaoNome');
      Logger.info('$_tag: Cultura: $culturaNome');
      Logger.info('$_tag: CV% disponível: ${cvPlantio != null}');
      Logger.info('$_tag: Estande disponível: ${estandePlantas != null}');

      // 1. Determinar tipo de análise baseado nos dados disponíveis
      final analiseIntegracao = _determinarTipoAnalise(cvPlantio, estandePlantas);
      Logger.info('$_tag: Tipo de análise: ${analiseIntegracao.toString().split('.').last}');

      // 2. Gerar diagnóstico da IA
      final diagnosticoIA = await _gerarDiagnosticoIA(
        cvPlantio,
        estandePlantas,
        culturaNome,
        analiseIntegracao,
      );

      // 3. Gerar recomendações específicas
      final recomendacoes = await _gerarRecomendacoes(
        cvPlantio,
        estandePlantas,
        culturaNome,
        analiseIntegracao,
      );

      // 4. Criar modelo de integração
      final integracao = PlantingIntegrationModel(
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        dataAnalise: DateTime.now(),
        qualidadePlantio: _getQualidadePlantio(analiseIntegracao),
        recomendacoes: recomendacoes,
        statusGeral: _getStatusGeral(analiseIntegracao),
        observacoes: _gerarObservacoesIntegracao(cvPlantio, estandePlantas),
        cvPlantio: cvPlantio,
        estandePlantas: estandePlantas,
        analiseIntegracao: analiseIntegracao,
        diagnosticoIA: diagnosticoIA,
      );

      Logger.info('$_tag: ✅ Análise de integração concluída');
      return integracao;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro na análise de integração: $e');
      rethrow;
    }
  }

  /// Obtém a qualidade do plantio baseada na análise
  String _getQualidadePlantio(IntegrationAnalysis analise) {
    switch (analise) {
      case IntegrationAnalysis.excelencia:
        return 'Excelente';
      case IntegrationAnalysis.compensacaoGerminacao:
        return 'Boa';
      case IntegrationAnalysis.germinacaoBaixa:
        return 'Moderada';
      case IntegrationAnalysis.plantioIrregular:
        return 'Ruim';
      case IntegrationAnalysis.dadosIncompletos:
        return 'Incompleta';
    }
  }

  /// Obtém o status geral baseado na análise
  String _getStatusGeral(IntegrationAnalysis analise) {
    switch (analise) {
      case IntegrationAnalysis.excelencia:
        return 'Plantio em excelente condição';
      case IntegrationAnalysis.compensacaoGerminacao:
        return 'Plantio com compensação adequada';
      case IntegrationAnalysis.germinacaoBaixa:
        return 'Plantio com germinação baixa';
      case IntegrationAnalysis.plantioIrregular:
        return 'Plantio irregular detectado';
      case IntegrationAnalysis.dadosIncompletos:
        return 'Dados insuficientes para análise';
    }
  }

  /// Determina o tipo de análise baseado nos dados disponíveis
  IntegrationAnalysis _determinarTipoAnalise(
    PlantingCVModel? cvPlantio,
    PlantingStandModel? estandePlantas,
  ) {
    if (cvPlantio == null || estandePlantas == null) {
      return IntegrationAnalysis.dadosIncompletos;
    }

    final cvClassificacao = cvPlantio.classificacao;
    final estandeClassificacao = estandePlantas.classificacao;

    // Lógica de análise baseada nas classificações
    if (cvClassificacao == CVClassification.excelente && 
        estandeClassificacao == StandClassification.excelente) {
      return IntegrationAnalysis.excelencia;
    } else if (cvClassificacao == CVClassification.ruim && 
               estandeClassificacao == StandClassification.ruim) {
      return IntegrationAnalysis.plantioIrregular;
    } else if (cvClassificacao == CVClassification.bom && 
               estandeClassificacao == StandClassification.ruim) {
      return IntegrationAnalysis.germinacaoBaixa;
    } else if (cvClassificacao == CVClassification.ruim && 
               estandeClassificacao == StandClassification.bom) {
      return IntegrationAnalysis.compensacaoGerminacao;
    } else {
      return IntegrationAnalysis.dadosIncompletos;
    }
  }

  /// Gera diagnóstico da IA baseado nos dados
  Future<String> _gerarDiagnosticoIA(
    PlantingCVModel? cvPlantio,
    PlantingStandModel? estandePlantas,
    String culturaNome,
    IntegrationAnalysis analiseIntegracao,
  ) async {
    try {
      // Simular análise da IA (em produção, isso seria uma chamada real para IA)
      final diagnostico = await _simularAnaliseIA(cvPlantio, estandePlantas, culturaNome, analiseIntegracao);
      return diagnostico;
    } catch (e) {
      Logger.warning('$_tag: Erro na análise da IA, usando diagnóstico padrão: $e');
      return _gerarDiagnosticoPadrao(analiseIntegracao);
    }
  }

  /// Simula análise da IA (placeholder para integração real)
  Future<String> _simularAnaliseIA(
    PlantingCVModel? cvPlantio,
    PlantingStandModel? estandePlantas,
    String culturaNome,
    IntegrationAnalysis analiseIntegracao,
  ) async {
    // Simular delay de processamento
    await Future.delayed(const Duration(milliseconds: 500));

    switch (analiseIntegracao) {
      case IntegrationAnalysis.excelencia:
        return 'Análise da IA: Excelente operação de plantio detectada. '
               'CV% de ${cvPlantio?.coeficienteVariacao.toStringAsFixed(1)}% indica distribuição muito uniforme das sementes. '
               'Estande de ${estandePlantas?.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha atinge ${estandePlantas?.percentualAtingidoPopulacaoAlvo?.toStringAsFixed(1)}% do alvo. '
               'Recomenda-se manter as práticas atuais para próximas safras.';

      case IntegrationAnalysis.plantioIrregular:
        return 'Análise da IA: Problema crítico identificado - plantio irregular com estande baixo. '
               'CV% de ${cvPlantio?.coeficienteVariacao.toStringAsFixed(1)}% indica distribuição muito irregular das sementes. '
               'Estande de apenas ${estandePlantas?.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha (${estandePlantas?.percentualAtingidoPopulacaoAlvo?.toStringAsFixed(1)}% do alvo). '
               'Ação imediata necessária: verificar regulagem da plantadeira e considerar replantio.';

      case IntegrationAnalysis.germinacaoBaixa:
        return 'Análise da IA: Plantio de boa qualidade mas germinação baixa detectada. '
               'CV% de ${cvPlantio?.coeficienteVariacao.toStringAsFixed(1)}% indica distribuição adequada das sementes. '
               'Porém, estande de ${estandePlantas?.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha (${estandePlantas?.percentualAtingidoPopulacaoAlvo?.toStringAsFixed(1)}% do alvo) sugere problemas na germinação. '
               'Possíveis causas: qualidade das sementes, condições de solo, profundidade de plantio ou condições climáticas.';

      case IntegrationAnalysis.compensacaoGerminacao:
        return 'Análise da IA: Plantio irregular mas germinação compensou a irregularidade. '
               'CV% de ${cvPlantio?.coeficienteVariacao.toStringAsFixed(1)}% indica distribuição irregular das sementes. '
               'Porém, estande de ${estandePlantas?.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha (${estandePlantas?.percentualAtingidoPopulacaoAlvo?.toStringAsFixed(1)}% do alvo) está adequado. '
               'A boa germinação compensou a irregularidade do plantio. Melhorar regulagem da plantadeira para otimizar ainda mais.';

      case IntegrationAnalysis.dadosIncompletos:
        return 'Análise da IA: Dados insuficientes para análise completa. '
               'Recomenda-se completar tanto o registro de CV% quanto o de estande para uma análise mais precisa. '
               'Com dados completos, a IA pode fornecer insights mais detalhados sobre a qualidade da operação de plantio.';
    }
  }

  /// Gera diagnóstico padrão quando a IA não está disponível
  String _gerarDiagnosticoPadrao(IntegrationAnalysis analiseIntegracao) {
    switch (analiseIntegracao) {
      case IntegrationAnalysis.excelencia:
        return 'Operação de plantio de excelência - CV% e estande ideais.';
      case IntegrationAnalysis.plantioIrregular:
        return 'Plantio irregular com estande baixo - atenção necessária.';
      case IntegrationAnalysis.germinacaoBaixa:
        return 'Plantio bom mas germinação baixa - investigar causas.';
      case IntegrationAnalysis.compensacaoGerminacao:
        return 'Plantio irregular mas germinação compensou.';
      case IntegrationAnalysis.dadosIncompletos:
        return 'Dados insuficientes para análise completa.';
    }
  }

  /// Gera recomendações específicas baseadas na análise
  Future<List<String>> _gerarRecomendacoes(
    PlantingCVModel? cvPlantio,
    PlantingStandModel? estandePlantas,
    String culturaNome,
    IntegrationAnalysis analiseIntegracao,
  ) async {
    final recomendacoes = <String>[];

    switch (analiseIntegracao) {
      case IntegrationAnalysis.excelencia:
        recomendacoes.addAll([
          'Manter as práticas atuais de plantio',
          'Documentar as condições que levaram ao sucesso',
          'Continuar monitoramento do desenvolvimento das plantas',
          'Considerar replicar as práticas em outros talhões',
        ]);
        break;

      case IntegrationAnalysis.plantioIrregular:
        recomendacoes.addAll([
          'Verificar imediatamente a regulagem da plantadeira',
          'Calibrar dosadores de sementes',
          'Verificar velocidade de plantio (máximo 6 km/h)',
          'Considerar replantio se o estande estiver muito baixo',
          'Avaliar qualidade das sementes utilizadas',
          'Verificar condições de solo e umidade',
        ]);
        break;

      case IntegrationAnalysis.germinacaoBaixa:
        recomendacoes.addAll([
          'Avaliar qualidade das sementes (germinação, vigor)',
          'Verificar profundidade de plantio',
          'Avaliar condições de solo (compactação, umidade)',
          'Verificar condições climáticas durante a germinação',
          'Considerar adubação de cobertura para compensar',
          'Monitorar desenvolvimento das plantas existentes',
        ]);
        break;

      case IntegrationAnalysis.compensacaoGerminacao:
        recomendacoes.addAll([
          'Melhorar regulagem da plantadeira para próximas safras',
          'Manter condições que favoreceram a germinação',
          'Documentar as práticas que compensaram a irregularidade',
          'Continuar monitoramento do desenvolvimento',
        ]);
        break;

      case IntegrationAnalysis.dadosIncompletos:
        recomendacoes.addAll([
          'Completar registro de CV% do plantio',
          'Completar registro de estande de plantas',
          'Estabelecer rotina de monitoramento pós-plantio',
          'Documentar todas as operações de plantio',
        ]);
        break;
    }

    // Adicionar recomendações específicas da cultura
    recomendacoes.addAll(_obterRecomendacoesEspecificasCultura(culturaNome));

    return recomendacoes;
  }

  /// Obtém recomendações específicas para cada cultura
  List<String> _obterRecomendacoesEspecificasCultura(String culturaNome) {
    switch (culturaNome.toLowerCase()) {
      case 'soja':
        return [
          'Monitorar nodulação das plantas',
          'Avaliar necessidade de inoculação',
          'Verificar presença de pragas iniciais',
        ];
      case 'milho':
        return [
          'Avaliar uniformidade de emergência',
          'Verificar profundidade de plantio',
          'Monitorar desenvolvimento inicial',
        ];
      case 'algodão':
        return [
          'Verificar presença de pragas iniciais',
          'Avaliar condições de solo',
          'Monitorar desenvolvimento das plantas',
        ];
      case 'feijão':
        return [
          'Avaliar nodulação',
          'Verificar condições de umidade',
          'Monitorar desenvolvimento inicial',
        ];
      default:
        return [
          'Continuar monitoramento do desenvolvimento',
          'Documentar observações importantes',
        ];
    }
  }

  /// Gera observações da integração
  String _gerarObservacoesIntegracao(
    PlantingCVModel? cvPlantio,
    PlantingStandModel? estandePlantas,
  ) {
    final observacoes = <String>[];

    if (cvPlantio != null) {
      observacoes.add('CV%: ${cvPlantio.coeficienteVariacao.toStringAsFixed(1)}% (${cvPlantio.classificacaoTexto})');
    }

    if (estandePlantas != null) {
      observacoes.add('Estande: ${estandePlantas.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha (${estandePlantas.classificacaoTexto})');
    }

    return observacoes.join(' | ');
  }

  /// Prediz riscos futuros baseado nos dados de plantio
  Future<Map<String, dynamic>> predizerRiscosFuturos({
    required PlantingIntegrationModel integracao,
    required Map<String, dynamic> condicoesClimaticas,
  }) async {
    try {
      Logger.info('$_tag: Iniciando predição de riscos futuros');

      final riscos = <String, dynamic>{};

      // Analisar riscos baseados no CV%
      if (integracao.cvPlantio != null) {
        if (integracao.cvPlantio!.classificacao == CVClassification.ruim) {
          riscos['plantio_irregular'] = {
            'nivel': 'alto',
            'descricao': 'Plantio irregular pode afetar uniformidade da colheita',
            'probabilidade': 0.8,
          };
        }
      }

      // Analisar riscos baseados no estande
      if (integracao.estandePlantas != null) {
        if (integracao.estandePlantas!.classificacao == StandClassification.ruim) {
          riscos['baixa_produtividade'] = {
            'nivel': 'alto',
            'descricao': 'Estande baixo pode resultar em baixa produtividade',
            'probabilidade': 0.7,
          };
        }
      }

      // Predições baseadas em condições climáticas
      final predicoesClimaticas = await _predictionService.predictOutbreakRisk(
        cropName: integracao.culturaNome,
        weatherData: condicoesClimaticas,
        location: integracao.talhaoNome,
      );

      if (predicoesClimaticas['predictions'] != null) {
        riscos['pragas_doencas'] = predicoesClimaticas['predictions'];
      }

      Logger.info('$_tag: ✅ Predição de riscos concluída');
      return riscos;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro na predição de riscos: $e');
      return {};
    }
  }
}
