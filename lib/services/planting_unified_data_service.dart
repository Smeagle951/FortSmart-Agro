import '../models/planting_cv_model.dart';
import '../models/planting_stand_model.dart';
import '../models/planting_integration_model.dart';
import '../enums/integration_analysis_enum.dart';
import '../database/models/estande_plantas_model.dart';
import 'planting_estande_integration_service.dart';
import 'planting_cv_standards_service.dart';
import '../../../utils/logger.dart';

/// Serviço unificado para gerenciar dados de plantio e estande
/// Conecta os dois submódulos mantendo sua singularidade
class PlantingUnifiedDataService {
  static const String _tag = 'PlantingUnifiedDataService';
  
  final PlantingEstandeIntegrationService _integrationService = PlantingEstandeIntegrationService();
  final PlantingCVStandardsService _cvStandardsService = PlantingCVStandardsService();

  /// Obtém dados completos de um talhão (CV% + Estande)
  Future<Map<String, dynamic>> getTalhaoCompleteData({
    required String talhaoId,
    required String culturaId,
    required String talhaoNome,
    required String culturaNome,
  }) async {
    Logger.info('$_tag: Obtendo dados completos para talhão $talhaoId');

    try {
      // Buscar dados de CV%
      final cvDataList = await _integrationService.getCvDataForTalhao(
        talhaoId: talhaoId,
        culturaId: culturaId,
      );

      // Buscar dados de estande
      final standDataList = await _integrationService.getStandDataForTalhao(
        talhaoId: talhaoId,
        culturaId: culturaId,
      );

      // Obter estatísticas consolidadas
      final statistics = await _integrationService.getTalhaoStatistics(
        talhaoId: talhaoId,
        culturaId: culturaId,
      );

      // Tentar criar análise integrada se houver dados suficientes
      PlantingIntegrationModel? integrationAnalysis;
      if (cvDataList.isNotEmpty && standDataList.isNotEmpty) {
        integrationAnalysis = await _integrationService.createIntegratedAnalysis(
          talhaoId: talhaoId,
          culturaId: culturaId,
          talhaoNome: talhaoNome,
          culturaNome: culturaNome,
        );
      }

      final completeData = {
        'talhaoId': talhaoId,
        'talhaoNome': talhaoNome,
        'culturaId': culturaId,
        'culturaNome': culturaNome,
        'cvData': cvDataList,
        'standData': standDataList,
        'statistics': statistics,
        'integrationAnalysis': integrationAnalysis,
        'hasCompleteData': cvDataList.isNotEmpty && standDataList.isNotEmpty,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      Logger.info('$_tag: Dados completos obtidos com sucesso');
      return completeData;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter dados completos: $e');
      return {
        'talhaoId': talhaoId,
        'talhaoNome': talhaoNome,
        'culturaId': culturaId,
        'culturaNome': culturaNome,
        'cvData': [],
        'standData': [],
        'statistics': {},
        'integrationAnalysis': null,
        'hasCompleteData': false,
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Obtém resumo executivo de um talhão
  Future<Map<String, dynamic>> getTalhaoExecutiveSummary({
    required String talhaoId,
    required String culturaId,
    required String talhaoNome,
    required String culturaNome,
  }) async {
    Logger.info('$_tag: Gerando resumo executivo para talhão $talhaoId');

    try {
      final completeData = await getTalhaoCompleteData(
        talhaoId: talhaoId,
        culturaId: culturaId,
        talhaoNome: talhaoNome,
        culturaNome: culturaNome,
      );

      final cvDataList = completeData['cvData'] as List<PlantingCVModel>;
      final standDataList = completeData['standData'] as List<PlantingStandModel>;
      final integrationAnalysis = completeData['integrationAnalysis'] as PlantingIntegrationModel?;

      // Gerar resumo executivo
      final summary = {
        'talhaoId': talhaoId,
        'talhaoNome': talhaoNome,
        'culturaId': culturaId,
        'culturaNome': culturaNome,
        'status': _generateStatus(cvDataList, standDataList, integrationAnalysis),
        'ultimoCv': cvDataList.isNotEmpty ? cvDataList.first.coeficienteVariacao : null,
        'ultimoStand': standDataList.isNotEmpty ? standDataList.first.populacaoRealPorHectare : null,
        'classificacaoCv': cvDataList.isNotEmpty ? cvDataList.first.classificacaoTexto : 'Não avaliado',
        'classificacaoStand': standDataList.isNotEmpty ? standDataList.first.classificacaoTexto : 'Não avaliado',
        'recomendacoes': integrationAnalysis?.recomendacoes.join('; ') ?? 'Dados insuficientes para análise',
        'alertas': _generateAlerts(cvDataList, standDataList, integrationAnalysis),
        'proximosPassos': _generateNextSteps(cvDataList, standDataList, integrationAnalysis),
        'dataAtualizacao': DateTime.now().toIso8601String(),
      };

      Logger.info('$_tag: Resumo executivo gerado com sucesso');
      return summary;
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar resumo executivo: $e');
      return {
        'talhaoId': talhaoId,
        'talhaoNome': talhaoNome,
        'culturaId': culturaId,
        'culturaNome': culturaNome,
        'status': 'Erro',
        'error': e.toString(),
        'dataAtualizacao': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Obtém dados para relatórios de monitoramento
  Future<Map<String, dynamic>> getMonitoringReportData({
    required String talhaoId,
    required String culturaId,
  }) async {
    Logger.info('$_tag: Obtendo dados para relatório de monitoramento');

    try {
      final completeData = await getTalhaoCompleteData(
        talhaoId: talhaoId,
        culturaId: culturaId,
        talhaoNome: 'Talhão $talhaoId', // Nome temporário
        culturaNome: 'Cultura $culturaId', // Nome temporário
      );

      final cvDataList = completeData['cvData'] as List<PlantingCVModel>;
      final standDataList = completeData['standData'] as List<PlantingStandModel>;
      final integrationAnalysis = completeData['integrationAnalysis'] as PlantingIntegrationModel?;

      final reportData = {
        'talhaoId': talhaoId,
        'culturaId': culturaId,
        'contextoPlantio': {
          'temCvData': cvDataList.isNotEmpty,
          'temStandData': standDataList.isNotEmpty,
          'temAnaliseIntegrada': integrationAnalysis != null,
          'ultimoCv': cvDataList.isNotEmpty ? cvDataList.first.coeficienteVariacao : null,
          'ultimoStand': standDataList.isNotEmpty ? standDataList.first.populacaoRealPorHectare : null,
          'classificacaoCv': cvDataList.isNotEmpty ? cvDataList.first.classificacaoTexto : null,
          'classificacaoStand': standDataList.isNotEmpty ? standDataList.first.classificacaoTexto : null,
        },
        'insights': integrationAnalysis?.diagnosticoIA ?? 'Dados de plantio não disponíveis',
        'recomendacoes': integrationAnalysis?.recomendacoes.join('; ') ?? 'Dados de plantio não disponíveis',
        'severidadeAjustada': _calculateAdjustedSeverity(cvDataList, standDataList),
        'alertas': _generateAlerts(cvDataList, standDataList, integrationAnalysis),
      };

      Logger.info('$_tag: Dados para relatório de monitoramento obtidos com sucesso');
      return reportData;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter dados para relatório: $e');
      return {
        'talhaoId': talhaoId,
        'culturaId': culturaId,
        'contextoPlantio': {
          'temCvData': false,
          'temStandData': false,
          'temAnaliseIntegrada': false,
        },
        'error': e.toString(),
      };
    }
  }

  /// Gera status do talhão baseado nos dados disponíveis
  String _generateStatus(List<PlantingCVModel> cvData, List<PlantingStandModel> standData, PlantingIntegrationModel? integration) {
    if (cvData.isEmpty && standData.isEmpty) {
      return 'Sem dados';
    } else if (cvData.isEmpty) {
      return 'Apenas estande';
    } else if (standData.isEmpty) {
      return 'Apenas CV%';
    } else if (integration != null) {
      switch (integration.analiseIntegracao) {
        case IntegrationAnalysis.excelencia:
          return 'Excelente';
        case IntegrationAnalysis.compensacaoGerminacao:
          return 'Bom (compensado)';
        case IntegrationAnalysis.germinacaoBaixa:
          return 'Atenção (germinação/solo)';
        case IntegrationAnalysis.plantioIrregular:
          return 'Crítico (plantio irregular)';
        case IntegrationAnalysis.dadosIncompletos:
          return 'Dados Incompletos';
        default:
          return 'Analisado';
      }
    } else {
      return 'Dados parciais';
    }
  }

  /// Gera alertas baseados nos dados
  List<String> _generateAlerts(List<PlantingCVModel> cvData, List<PlantingStandModel> standData, PlantingIntegrationModel? integration) {
    final alerts = <String>[];

    if (cvData.isNotEmpty) {
      final cv = cvData.first;
      if (cv.classificacao == CVClassification.ruim) {
        alerts.add('CV% crítico: ${cv.coeficienteVariacao.toStringAsFixed(1)}% - Verificar regulagem da plantadeira');
      }
    }

    if (standData.isNotEmpty) {
      final stand = standData.first;
      if (stand.percentualAtingidoPopulacaoAlvo != null && stand.percentualAtingidoPopulacaoAlvo! < 80) {
        alerts.add('Estande baixo: ${stand.percentualAtingidoPopulacaoAlvo!.toStringAsFixed(1)}% do alvo - Investigar causas');
      }
    }

    if (integration != null) {
      if (integration.analiseIntegracao == IntegrationAnalysis.plantioIrregular) {
        alerts.add('Problema crítico: Plantio irregular + estande baixo');
      } else if (integration.analiseIntegracao == IntegrationAnalysis.germinacaoBaixa) {
        alerts.add('Atenção: Problema de germinação, fertilidade ou solo');
      }
    }

    return alerts;
  }

  /// Gera próximos passos baseados nos dados
  List<String> _generateNextSteps(List<PlantingCVModel> cvData, List<PlantingStandModel> standData, PlantingIntegrationModel? integration) {
    final steps = <String>[];

    if (cvData.isEmpty) {
      steps.add('Registrar CV% do plantio para análise completa');
    }

    if (standData.isEmpty) {
      steps.add('Registrar estande de plantas para análise completa');
    }

    if (integration != null) {
      steps.add('Seguir recomendações da IA agronômica');
      steps.add('Monitorar evolução da cultura');
    } else if (cvData.isNotEmpty && standData.isNotEmpty) {
      steps.add('Aguardar análise integrada da IA');
    }

    return steps;
  }

  /// Calcula severidade ajustada baseada no contexto de plantio
  String _calculateAdjustedSeverity(List<PlantingCVModel> cvData, List<PlantingStandModel> standData) {
    if (cvData.isEmpty && standData.isEmpty) {
      return 'normal'; // Sem contexto de plantio
    }

    bool hasCriticalCv = cvData.any((cv) => cv.classificacao == CVClassification.ruim);
    bool hasLowStand = standData.any((stand) => stand.percentualAtingidoPopulacaoAlvo != null && stand.percentualAtingidoPopulacaoAlvo! < 80);

    if (hasCriticalCv && hasLowStand) {
      return 'alta'; // Plantio irregular + estande baixo
    } else if (hasCriticalCv || hasLowStand) {
      return 'media'; // Um dos problemas
    } else {
      return 'baixa'; // Plantio e estande bons
    }
  }
}
