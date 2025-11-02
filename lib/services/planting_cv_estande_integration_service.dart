import '../models/planting_cv_model.dart';
import '../database/models/estande_plantas_model.dart';
import '../database/repositories/planting_cv_repository.dart';
import '../database/repositories/estande_plantas_repository.dart';
import '../utils/logger.dart';

/// Serviço para integração entre CV% do plantio e estande de plantas
/// Garante que ambos sejam salvos individualmente mas sempre relacionados
class PlantingCVEstandeIntegrationService {
  static const String _tag = 'PlantingCVEstandeIntegrationService';
  
  final PlantingCVRepository _cvRepository = PlantingCVRepository();
  final EstandePlantasRepository _estandeRepository = EstandePlantasRepository();

  /// Salva CV% e estande de forma integrada
  /// Ambos são salvos individualmente mas com relacionamento
  Future<Map<String, String>> salvarCVEstandeIntegrado({
    required PlantingCVModel cvModel,
    required EstandePlantasModel estandeModel,
  }) async {
    try {
      Logger.info('$_tag: Iniciando salvamento integrado de CV% e estande...');
      
      // Salvar CV% primeiro
      final cvId = await _cvRepository.salvar(cvModel);
      Logger.info('$_tag: ✅ CV% salvo: $cvId');
      
      // Salvar estande
      final estandeId = await _estandeRepository.salvar(estandeModel);
      Logger.info('$_tag: ✅ Estande salvo: $estandeId');
      
      Logger.info('$_tag: ✅ Salvamento integrado concluído com sucesso');
      
      return {
        'cv_id': cvId,
        'estande_id': estandeId,
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no salvamento integrado: $e');
      rethrow;
    }
  }

  /// Busca CV% e estande relacionados por talhão
  Future<Map<String, dynamic>> buscarDadosIntegradosPorTalhao(String talhaoId) async {
    try {
      Logger.info('$_tag: Buscando dados integrados para talhão: $talhaoId');
      
      // Buscar CV% do talhão
      final cvs = await _cvRepository.buscarPorTalhao(talhaoId);
      
      // Buscar estandes do talhão
      final estandes = await _estandeRepository.buscarPorTalhao(talhaoId);
      
      // Organizar por data para facilitar a correlação
      final cvsOrdenados = cvs..sort((a, b) => b.dataPlantio.compareTo(a.dataPlantio));
      final estandesOrdenados = estandes..sort((a, b) => 
        DateTime.parse(b.dataAvaliacao).compareTo(DateTime.parse(a.dataAvaliacao)));
      
      Logger.info('$_tag: ✅ Dados encontrados - CV%: ${cvs.length}, Estandes: ${estandes.length}');
      
      return {
        'talhao_id': talhaoId,
        'cvs': cvsOrdenados,
        'estandes': estandesOrdenados,
        'total_cvs': cvs.length,
        'total_estandes': estandes.length,
        'cv_mais_recente': cvsOrdenados.isNotEmpty ? cvsOrdenados.first : null,
        'estande_mais_recente': estandesOrdenados.isNotEmpty ? estandesOrdenados.first : null,
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar dados integrados: $e');
      return {
        'talhao_id': talhaoId,
        'cvs': <PlantingCVModel>[],
        'estandes': <EstandePlantasModel>[],
        'total_cvs': 0,
        'total_estandes': 0,
        'cv_mais_recente': null,
        'estande_mais_recente': null,
      };
    }
  }

  /// Busca dados integrados por cultura
  Future<Map<String, dynamic>> buscarDadosIntegradosPorCultura(String culturaId) async {
    try {
      Logger.info('$_tag: Buscando dados integrados para cultura: $culturaId');
      
      // Buscar CV% da cultura
      final cvs = await _cvRepository.buscarPorCultura(culturaId);
      
      // Buscar estandes da cultura (assumindo que estande também tem cultura_id)
      final estandes = await _estandeRepository.buscarTodos(); // Implementar busca por cultura se necessário
      final estandesCultura = estandes.where((e) => e.culturaId == culturaId).toList();
      
      Logger.info('$_tag: ✅ Dados encontrados - CV%: ${cvs.length}, Estandes: ${estandesCultura.length}');
      
      return {
        'cultura_id': culturaId,
        'cvs': cvs,
        'estandes': estandesCultura,
        'total_cvs': cvs.length,
        'total_estandes': estandesCultura.length,
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar dados integrados por cultura: $e');
      return {
        'cultura_id': culturaId,
        'cvs': <PlantingCVModel>[],
        'estandes': <EstandePlantasModel>[],
        'total_cvs': 0,
        'total_estandes': 0,
      };
    }
  }

  /// Obtém estatísticas integradas de CV% e estande
  Future<Map<String, dynamic>> obterEstatisticasIntegradas() async {
    try {
      Logger.info('$_tag: Obtendo estatísticas integradas...');
      
      // Estatísticas de CV%
      final statsCV = await _cvRepository.obterEstatisticas();
      
      // Estatísticas de estande
      final todosEstandes = await _estandeRepository.buscarTodos();
      
      // Calcular estatísticas de estande
      final totalEstandes = todosEstandes.length;
      final estandesComPopulacaoIdeal = todosEstandes.where((e) => 
        e.populacaoIdeal != null && e.populacaoIdeal! > 0).length;
      
      // Calcular eficiência média
      double eficienciaMedia = 0.0;
      if (estandesComPopulacaoIdeal > 0) {
        final eficiencias = todosEstandes
          .where((e) => e.eficiencia != null)
          .map((e) => e.eficiencia!)
          .toList();
        
        if (eficiencias.isNotEmpty) {
          eficienciaMedia = eficiencias.reduce((a, b) => a + b) / eficiencias.length;
        }
      }
      
      Logger.info('$_tag: ✅ Estatísticas integradas obtidas');
      
      return {
        'cv': statsCV,
        'estande': {
          'total': totalEstandes,
          'com_populacao_ideal': estandesComPopulacaoIdeal,
          'eficiencia_media': eficienciaMedia,
          'percentual_com_meta': totalEstandes > 0 ? 
            (estandesComPopulacaoIdeal / totalEstandes * 100) : 0.0,
        },
        'resumo': {
          'total_avaliacoes': statsCV['total'] + totalEstandes,
          'cv_excelente_ou_bom': (statsCV['excelente'] ?? 0) + (statsCV['bom'] ?? 0),
          'estandes_com_meta': estandesComPopulacaoIdeal,
        }
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter estatísticas integradas: $e');
      return {
        'cv': {
          'total': 0,
          'excelente': 0,
          'bom': 0,
          'moderado': 0,
          'ruim': 0,
        },
        'estande': {
          'total': 0,
          'com_populacao_ideal': 0,
          'eficiencia_media': 0.0,
          'percentual_com_meta': 0.0,
        },
        'resumo': {
          'total_avaliacoes': 0,
          'cv_excelente_ou_bom': 0,
          'estandes_com_meta': 0,
        }
      };
    }
  }

  /// Verifica se um talhão tem dados completos (CV% e estande)
  Future<Map<String, dynamic>> verificarCompletudeTalhao(String talhaoId) async {
    try {
      Logger.info('$_tag: Verificando completude do talhão: $talhaoId');
      
      final cvs = await _cvRepository.buscarPorTalhao(talhaoId);
      final estandes = await _estandeRepository.buscarPorTalhao(talhaoId);
      
      final temCV = cvs.isNotEmpty;
      final temEstande = estandes.isNotEmpty;
      final temAmbos = temCV && temEstande;
      
      final cvMaisRecente = cvs.isNotEmpty ? cvs.first : null;
      final estandeMaisRecente = estandes.isNotEmpty ? estandes.first : null;
      
      Logger.info('$_tag: ✅ Verificação concluída - CV%: $temCV, Estande: $temEstande');
      
      return {
        'talhao_id': talhaoId,
        'tem_cv': temCV,
        'tem_estande': temEstande,
        'tem_ambos': temAmbos,
        'completo': temAmbos,
        'cv_mais_recente': cvMaisRecente,
        'estande_mais_recente': estandeMaisRecente,
        'total_cvs': cvs.length,
        'total_estandes': estandes.length,
        'status': temAmbos ? 'completo' : 
                  (temCV ? 'apenas_cv' : 
                   (temEstande ? 'apenas_estande' : 'incompleto')),
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar completude: $e');
      return {
        'talhao_id': talhaoId,
        'tem_cv': false,
        'tem_estande': false,
        'tem_ambos': false,
        'completo': false,
        'cv_mais_recente': null,
        'estande_mais_recente': null,
        'total_cvs': 0,
        'total_estandes': 0,
        'status': 'erro',
      };
    }
  }

  /// Obtém relatório integrado de um talhão
  Future<Map<String, dynamic>> obterRelatorioIntegradoTalhao(String talhaoId) async {
    try {
      Logger.info('$_tag: Gerando relatório integrado para talhão: $talhaoId');
      
      final dadosIntegrados = await buscarDadosIntegradosPorTalhao(talhaoId);
      final completude = await verificarCompletudeTalhao(talhaoId);
      
      // Análise de qualidade
      final cvMaisRecente = dadosIntegrados['cv_mais_recente'] as PlantingCVModel?;
      final estandeMaisRecente = dadosIntegrados['estande_mais_recente'] as EstandePlantasModel?;
      
      String qualidadeGeral = 'indefinida';
      List<String> recomendacoes = [];
      
      if (cvMaisRecente != null && estandeMaisRecente != null) {
        // Análise baseada em ambos os dados
        if (cvMaisRecente.classificacao.index <= 1 && // Excelente ou Bom
            (estandeMaisRecente.eficiencia ?? 0) >= 80) {
          qualidadeGeral = 'excelente';
          recomendacoes.add('Manter as práticas atuais');
        } else if (cvMaisRecente.classificacao.index <= 2 && // Até Moderado
                   (estandeMaisRecente.eficiencia ?? 0) >= 70) {
          qualidadeGeral = 'boa';
          recomendacoes.add('Verificar regulagem fina da plantadeira');
        } else {
          qualidadeGeral = 'precisa_melhorar';
          recomendacoes.addAll([
            'Verificar regulagem da plantadeira',
            'Calibrar dosadores de sementes',
            'Verificar velocidade de plantio',
          ]);
        }
      } else if (cvMaisRecente != null) {
        // Análise baseada apenas no CV%
        qualidadeGeral = cvMaisRecente.classificacao.index <= 1 ? 'boa' : 'precisa_melhorar';
        recomendacoes.add('Realizar avaliação de estande para análise completa');
      } else if (estandeMaisRecente != null) {
        // Análise baseada apenas no estande
        qualidadeGeral = (estandeMaisRecente.eficiencia ?? 0) >= 80 ? 'boa' : 'precisa_melhorar';
        recomendacoes.add('Realizar avaliação de CV% para análise completa');
      }
      
      Logger.info('$_tag: ✅ Relatório integrado gerado');
      
      return {
        'talhao_id': talhaoId,
        'completude': completude,
        'dados': dadosIntegrados,
        'analise': {
          'qualidade_geral': qualidadeGeral,
          'recomendacoes': recomendacoes,
          'cv_atual': cvMaisRecente,
          'estande_atual': estandeMaisRecente,
        },
        'gerado_em': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao gerar relatório integrado: $e');
      rethrow;
    }
  }
}
