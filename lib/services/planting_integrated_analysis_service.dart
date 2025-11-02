import '../models/planting_cv_model.dart';
import '../models/planting_stand_model.dart';
import '../models/planting_integration_model.dart';
import '../database/models/estande_plantas_model.dart';
import 'planting_cv_persistence_service.dart';
import '../utils/logger.dart';

/// Serviço para análise integrada de plantio
/// Conecta dados de CV% com estande de plantas para análise completa
class PlantingIntegratedAnalysisService {
  static const String _tag = 'PlantingIntegratedAnalysisService';
  
  final PlantingCVPersistenceService _cvPersistenceService = PlantingCVPersistenceService();

  /// Cria análise integrada combinando CV% e estande de plantas
  Future<PlantingIntegrationModel?> criarAnaliseIntegrada({
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
    PlantingCVModel? cvModel,
    EstandePlantasModel? estandeModel,
  }) async {
    try {
      Logger.info('$_tag: Criando análise integrada para talhão: $talhaoNome');

      // Se não foram fornecidos os modelos, buscar do histórico
      if (cvModel == null) {
        cvModel = await _cvPersistenceService.obterUltimoCv(talhaoId);
      }

      if (cvModel == null) {
        Logger.warning('$_tag: Nenhum CV% encontrado para talhão: $talhaoId');
        return null;
      }

      // Criar análise integrada
      final analiseIntegrada = PlantingIntegrationModel(
        id: '${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        cvModel: cvModel,
        // estandeModel: estandeModel, // Temporariamente comentado devido a incompatibilidade de tipos
        dataAnalise: DateTime.now(),
        qualidadePlantio: _calcularQualidadePlantio(cvModel),
        recomendacoes: _gerarRecomendacoes(cvModel, estandeModel),
        statusGeral: _determinarStatusGeral(cvModel, estandeModel),
        observacoes: _gerarObservacoes(cvModel, estandeModel),
      );

      Logger.info('$_tag: Análise integrada criada com sucesso');
      return analiseIntegrada;
    } catch (e) {
      Logger.error('$_tag: Erro ao criar análise integrada: $e');
      return null;
    }
  }

  /// Calcula a qualidade geral do plantio baseada no CV%
  String _calcularQualidadePlantio(PlantingCVModel cvModel) {
    switch (cvModel.classificacao) {
      case CVClassification.excelente:
        return 'Excelente';
      case CVClassification.bom:
        return 'Boa';
      case CVClassification.moderado:
        return 'Moderada';
      case CVClassification.ruim:
        return 'Ruim';
    }
  }

  /// Gera recomendações baseadas no CV% e estande
  List<String> _gerarRecomendacoes(PlantingCVModel cvModel, EstandePlantasModel? estandeModel) {
    final recomendacoes = <String>[];

    // Recomendações baseadas no CV%
    switch (cvModel.classificacao) {
      case CVClassification.excelente:
        recomendacoes.add('✅ Distribuição de sementes excelente - manter configuração atual');
        break;
      case CVClassification.bom:
        recomendacoes.add('✅ Distribuição de sementes boa - pequenos ajustes podem melhorar');
        break;
      case CVClassification.moderado:
        recomendacoes.add('⚠️ Distribuição moderada - verificar regulagem da plantadora');
        recomendacoes.add('📋 Considerar calibração dos discos de plantio');
        break;
      case CVClassification.ruim:
        recomendacoes.add('❌ Distribuição irregular - atenção necessária');
        recomendacoes.add('🔧 Verificar regulagem completa da plantadora');
        recomendacoes.add('📋 Realizar nova calibração dos discos');
        recomendacoes.add('🔍 Verificar qualidade das sementes');
        break;
    }

    // Recomendações baseadas no estande (se disponível)
    if (estandeModel != null) {
      final populacaoAtual = estandeModel.plantasPorHectare;
      final populacaoIdeal = estandeModel.populacaoIdeal;
      
      if (populacaoIdeal != null && populacaoIdeal > 0 && populacaoAtual != null) {
        final diferenca = ((populacaoAtual - populacaoIdeal) / populacaoIdeal * 100).abs();
        
        if (diferenca > 20) {
          recomendacoes.add('📊 População muito diferente da ideal - verificar regulagem');
        } else if (diferenca > 10) {
          recomendacoes.add('📊 Pequeno ajuste na população pode ser benéfico');
        } else {
          recomendacoes.add('✅ População dentro do ideal');
        }
      }
    }

    return recomendacoes;
  }

  /// Determina o status geral da análise
  String _determinarStatusGeral(PlantingCVModel cvModel, EstandePlantasModel? estandeModel) {
    // Status baseado no CV%
    String statusCv;
    switch (cvModel.classificacao) {
      case CVClassification.excelente:
        statusCv = 'Excelente';
        break;
      case CVClassification.bom:
        statusCv = 'Bom';
        break;
      case CVClassification.moderado:
        statusCv = 'Moderado';
        break;
      case CVClassification.ruim:
        statusCv = 'Ruim';
        break;
    }

    // Se há dados de estande, considerar também
    if (estandeModel != null) {
      final populacaoAtual = estandeModel.plantasPorHectare;
      final populacaoIdeal = estandeModel.populacaoIdeal;
      
      if (populacaoIdeal != null && populacaoIdeal > 0 && populacaoAtual != null) {
        final diferenca = ((populacaoAtual - populacaoIdeal) / populacaoIdeal * 100).abs();
        
        if (diferenca > 20) {
          return 'Atenção - $statusCv CV% mas população fora do ideal';
        } else if (diferenca > 10) {
          return 'Bom - $statusCv CV% com população próxima do ideal';
        } else {
          return 'Excelente - $statusCv CV% com população ideal';
        }
      }
    }

    return statusCv;
  }

  /// Gera observações detalhadas
  String _gerarObservacoes(PlantingCVModel cvModel, EstandePlantasModel? estandeModel) {
    final observacoes = <String>[];

    // Observações do CV%
    observacoes.add('CV%: ${cvModel.coeficienteVariacao.toStringAsFixed(1)}% (${cvModel.classificacaoTexto})');
    observacoes.add('População estimada: ${cvModel.populacaoEstimadaPorHectare.toStringAsFixed(0)} plantas/ha');
    observacoes.add('Plantas por metro: ${cvModel.plantasPorMetro.toStringAsFixed(1)}');

    // Observações do estande (se disponível)
    if (estandeModel != null) {
      observacoes.add('Estande: ${estandeModel.plantasContadas} plantas em ${estandeModel.metrosLinearesMedidos}m');
      observacoes.add('População ideal: ${estandeModel.populacaoIdeal?.toStringAsFixed(0) ?? 'N/A'} plantas/ha');
    }

    return observacoes.join('\n');
  }

  /// Obtém resumo executivo da análise integrada
  Future<Map<String, dynamic>> obterResumoExecutivo({
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
  }) async {
    try {
      Logger.info('$_tag: Gerando resumo executivo para talhão: $talhaoNome');

      // Buscar último CV%
      final ultimoCv = await _cvPersistenceService.obterUltimoCv(talhaoId);
      
      if (ultimoCv == null) {
        return {
          'status': 'Sem dados',
          'mensagem': 'Nenhum cálculo de CV% encontrado para este talhão',
          'temDados': false,
        };
      }

      // Criar análise integrada
      final analiseIntegrada = await criarAnaliseIntegrada(
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        cvModel: ultimoCv,
      );

      if (analiseIntegrada == null) {
        return {
          'status': 'Erro',
          'mensagem': 'Erro ao criar análise integrada',
          'temDados': false,
        };
      }

      return {
        'status': analiseIntegrada.statusGeral,
        'qualidadePlantio': analiseIntegrada.qualidadePlantio,
        'cvPercentual': ultimoCv.coeficienteVariacao,
        'classificacaoCv': ultimoCv.classificacaoTexto,
        'populacaoEstimada': ultimoCv.populacaoEstimadaPorHectare,
        'plantasPorMetro': ultimoCv.plantasPorMetro,
        'recomendacoes': analiseIntegrada.recomendacoes,
        'observacoes': analiseIntegrada.observacoes,
        'dataAnalise': analiseIntegrada.dataAnalise.toIso8601String(),
        'temDados': true,
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar resumo executivo: $e');
      return {
        'status': 'Erro',
        'mensagem': 'Erro ao gerar resumo: $e',
        'temDados': false,
      };
    }
  }
}
