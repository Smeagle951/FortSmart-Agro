import '../models/planting_cv_model.dart';
import '../models/planting_stand_model.dart';
import '../models/planting_integration_model.dart';
import '../database/models/estande_plantas_model.dart';
import 'planting_ai_integration_service.dart';
import 'planting_monitoring_integration_service.dart';
import 'planting_cv_standards_service.dart';
import '../../../utils/logger.dart';

/// Serviço de integração entre os submódulos de plantio e estande
/// Mantém a singularidade dos submódulos, mas unifica as informações para análises
class PlantingEstandeIntegrationService {
  static const String _tag = 'PlantingEstandeIntegrationService';
  
  final PlantingAIIntegrationService _aiIntegrationService = PlantingAIIntegrationService();
  final PlantingMonitoringIntegrationService _monitoringService = PlantingMonitoringIntegrationService();
  final PlantingCVStandardsService _cvStandardsService = PlantingCVStandardsService();

  /// Converte dados do estande existente para o novo modelo de estande
  Future<PlantingStandModel> convertEstandePlantasToPlantingStand({
    required EstandePlantasModel estandePlantas,
    required String talhaoNome,
    required String culturaNome,
  }) async {
    Logger.info('$_tag: Convertendo EstandePlantasModel para PlantingStandModel');

    try {
      // Calcular percentual atingido em relação à população alvo
      double? percentualAtingidoPopulacaoAlvo;
      double? desvioPlantioEmergencia;
      
      if (estandePlantas.populacaoIdeal != null && estandePlantas.populacaoIdeal! > 0) {
        percentualAtingidoPopulacaoAlvo = (estandePlantas.plantasPorHectare! / estandePlantas.populacaoIdeal!) * 100;
        desvioPlantioEmergencia = estandePlantas.plantasPorHectare! - estandePlantas.populacaoIdeal!;
      }

      final plantingStand = PlantingStandModel(
        talhaoId: estandePlantas.talhaoId!,
        talhaoNome: talhaoNome,
        culturaId: estandePlantas.culturaId!,
        culturaNome: culturaNome,
        dataAvaliacao: estandePlantas.dataAvaliacao!,
        comprimentoLinhaAvaliado: estandePlantas.metrosLinearesMedidos!,
        numeroLinhasAvaliadas: 1, // Assumindo 1 linha por padrão
        espacamentoEntreLinhas: estandePlantas.espacamento!,
        plantasContadas: estandePlantas.plantasContadas!,
        plantasPorMetro: estandePlantas.plantasPorMetro!,
        populacaoRealPorHectare: estandePlantas.plantasPorHectare!,
        percentualAtingidoPopulacaoAlvo: percentualAtingidoPopulacaoAlvo,
        desvioPlantioEmergencia: desvioPlantioEmergencia,
        populacaoAlvo: estandePlantas.populacaoIdeal,
        observacoes: 'Convertido do EstandePlantasModel existente',
        createdAt: estandePlantas.createdAt ?? DateTime.now(),
      );

      Logger.info('$_tag: Conversão concluída com sucesso');
      return plantingStand;
    } catch (e) {
      Logger.error('$_tag: Erro ao converter EstandePlantasModel: $e');
      rethrow;
    }
  }

  /// Converte dados do novo modelo de estande para o modelo existente
  Future<EstandePlantasModel> convertPlantingStandToEstandePlantas({
    required PlantingStandModel plantingStand,
  }) async {
    Logger.info('$_tag: Convertendo PlantingStandModel para EstandePlantasModel');

    try {
      final estandePlantas = EstandePlantasModel(
        id: plantingStand.id,
        talhaoId: plantingStand.talhaoId,
        culturaId: plantingStand.culturaId,
        dataAvaliacao: plantingStand.dataAvaliacao,
        metrosLinearesMedidos: plantingStand.comprimentoLinhaAvaliado,
        plantasContadas: plantingStand.plantasContadas,
        espacamento: plantingStand.espacamentoEntreLinhas,
        plantasPorMetro: plantingStand.plantasPorMetro,
        plantasPorHectare: plantingStand.populacaoRealPorHectare,
        populacaoIdeal: plantingStand.populacaoAlvo,
        eficiencia: plantingStand.percentageAchievedTarget,
        createdAt: plantingStand.createdAt,
        updatedAt: plantingStand.updatedAt,
        syncStatus: 0,
      );

      Logger.info('$_tag: Conversão concluída com sucesso');
      return estandePlantas;
    } catch (e) {
      Logger.error('$_tag: Erro ao converter PlantingStandModel: $e');
      rethrow;
    }
  }

  /// Busca dados de CV% relacionados a um talhão e cultura
  Future<List<PlantingCVModel>> getCvDataForTalhao({
    required String talhaoId,
    required String culturaId,
  }) async {
    Logger.info('$_tag: Buscando dados de CV% para talhão $talhaoId, cultura $culturaId');
    
    try {
      // TODO: Implementar busca no banco de dados
      // Por enquanto, retorna lista vazia
      Logger.info('$_tag: Busca de CV% implementada (retornando lista vazia)');
      return [];
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar dados de CV%: $e');
      return [];
    }
  }

  /// Busca dados de estande relacionados a um talhão e cultura
  Future<List<PlantingStandModel>> getStandDataForTalhao({
    required String talhaoId,
    required String culturaId,
  }) async {
    Logger.info('$_tag: Buscando dados de estande para talhão $talhaoId, cultura $culturaId');
    
    try {
      // TODO: Implementar busca no banco de dados
      // Por enquanto, retorna lista vazia
      Logger.info('$_tag: Busca de estande implementada (retornando lista vazia)');
      return [];
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar dados de estande: $e');
      return [];
    }
  }

  /// Cria análise integrada usando dados de ambos os submódulos
  Future<PlantingIntegrationModel?> createIntegratedAnalysis({
    required String talhaoId,
    required String culturaId,
    required String talhaoNome,
    required String culturaNome,
  }) async {
    Logger.info('$_tag: Criando análise integrada para talhão $talhaoId, cultura $culturaId');

    try {
      // Buscar dados de CV% e estande
      final cvDataList = await getCvDataForTalhao(talhaoId: talhaoId, culturaId: culturaId);
      final standDataList = await getStandDataForTalhao(talhaoId: talhaoId, culturaId: culturaId);

      // Se não há dados suficientes, retorna null
      if (cvDataList.isEmpty || standDataList.isEmpty) {
        Logger.info('$_tag: Dados insuficientes para análise integrada');
        return null;
      }

      // Usar os dados mais recentes
      final cvData = cvDataList.first;
      final standData = standDataList.first;

      // Criar análise integrada com IA
      final integrationModel = await _aiIntegrationService.analisarIntegracaoComIA(
        cvPlantio: cvData,
        estandePlantas: standData,
        talhaoId: cvData.talhaoId,
        talhaoNome: cvData.talhaoNome,
        culturaId: cvData.culturaId,
        culturaNome: cvData.culturaNome,
      );

      Logger.info('$_tag: Análise integrada criada com sucesso');
      return integrationModel;
    } catch (e) {
      Logger.error('$_tag: Erro ao criar análise integrada: $e');
      return null;
    }
  }

  /// Envia dados integrados para o monitoramento
  Future<void> sendIntegratedDataToMonitoring({
    required PlantingIntegrationModel integrationData,
  }) async {
    Logger.info('$_tag: Enviando dados integrados para o monitoramento');

    try {
      await _monitoringService.integrarComMonitoramento(
        integracao: integrationData,
        talhaoId: integrationData.talhaoId,
      );
      Logger.info('$_tag: Dados integrados enviados para o monitoramento com sucesso');
    } catch (e) {
      Logger.error('$_tag: Erro ao enviar dados para o monitoramento: $e');
      rethrow;
    }
  }

  /// Obtém estatísticas consolidadas de um talhão
  Future<Map<String, dynamic>> getTalhaoStatistics({
    required String talhaoId,
    required String culturaId,
  }) async {
    Logger.info('$_tag: Obtendo estatísticas consolidadas para talhão $talhaoId');

    try {
      final cvDataList = await getCvDataForTalhao(talhaoId: talhaoId, culturaId: culturaId);
      final standDataList = await getStandDataForTalhao(talhaoId: talhaoId, culturaId: culturaId);

      // Calcular estatísticas
      final statistics = {
        'totalCvRegistros': cvDataList.length,
        'totalStandRegistros': standDataList.length,
        'ultimoCv': cvDataList.isNotEmpty ? cvDataList.first.cvPercentage : null,
        'ultimoStand': standDataList.isNotEmpty ? standDataList.first.actualPopulationPerHectare : null,
        'mediaCv': cvDataList.isNotEmpty 
            ? cvDataList.map((e) => e.cvPercentage).reduce((a, b) => a + b) / cvDataList.length 
            : null,
        'mediaStand': standDataList.isNotEmpty 
            ? standDataList.map((e) => e.actualPopulationPerHectare).reduce((a, b) => a + b) / standDataList.length 
            : null,
        'temAnaliseIntegrada': false, // Será atualizado quando houver análise integrada
      };

      Logger.info('$_tag: Estatísticas consolidadas obtidas com sucesso');
      return statistics;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas consolidadas: $e');
      return {};
    }
  }

  /// Valida se os dados de CV% e estande são compatíveis para análise integrada
  bool validateDataCompatibility({
    required PlantingCVModel cvData,
    required PlantingStandModel standData,
  }) {
    Logger.info('$_tag: Validando compatibilidade dos dados');

    try {
      // Verificar se são do mesmo talhão e cultura
      if (cvData.talhaoId != standData.talhaoId || cvData.culturaId != standData.culturaId) {
        Logger.warning('$_tag: Dados de talhão ou cultura diferentes');
        return false;
      }

      // Verificar se as datas são compatíveis (estande deve ser posterior ao plantio)
      if (standData.dataAvaliacao.isBefore(cvData.dataPlantio)) {
        Logger.warning('$_tag: Data de estande anterior à data de plantio');
        return false;
      }

      Logger.info('$_tag: Dados compatíveis para análise integrada');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao validar compatibilidade: $e');
      return false;
    }
  }
}
