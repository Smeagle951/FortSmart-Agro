import 'dart:convert';
import '../../models/experimento_completo_model.dart';
import '../../models/plantio_model.dart';
import '../../database/models/plantio_model.dart' as database_plantio;
import '../../services/experimento_service.dart';
import '../../services/lista_plantio_service.dart';
import '../../repositories/talhao_repository.dart';

/// Serviço para integração entre experimentos e módulo de plantio
class ExperimentoPlantioIntegrationService {
  static final ExperimentoPlantioIntegrationService _instance = 
      ExperimentoPlantioIntegrationService._internal();
  factory ExperimentoPlantioIntegrationService() => _instance;
  ExperimentoPlantioIntegrationService._internal();

  final ExperimentoService _experimentoService = ExperimentoService();
  final ListaPlantioService _plantioService = ListaPlantioService();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();

  /// Integra uma subárea com o módulo de plantio
  Future<String> integrarSubareaComPlantio({
    required String subareaId,
    required String cultura,
    required String variedade,
    required DateTime dataPlantio,
    required double espacamentoCm,
    required double populacaoPorM,
    String? observacoes,
    String? variedadeTipo,
    String? cicloNome,
    int? cicloDias,
    String? cicloDescricao,
  }) async {
    try {
      // Buscar subárea
      final subarea = await _experimentoService.buscarSubareaPorId(subareaId);
      if (subarea == null) {
        throw Exception('Subárea não encontrada');
      }

      // Buscar experimento
      final experimento = await _experimentoService.buscarExperimentoPorId(subarea.experimentoId);
      if (experimento == null) {
        throw Exception('Experimento não encontrado');
      }

      // Buscar talhão
      final talhao = await _talhaoRepository.getTalhaoById(int.tryParse(experimento.talhaoId) ?? 0);
      if (talhao == null) {
        throw Exception('Talhão não encontrado');
      }

      // Criar observação completa
      String observacaoCompleta = '';
      if (variedadeTipo != null && cicloNome != null && cicloDias != null) {
        observacaoCompleta = 'Variedade: $variedade ($variedadeTipo) - Ciclo: $cicloNome ($cicloDias dias)';
        if (cicloDescricao != null) {
          observacaoCompleta += ' - $cicloDescricao';
        }
      } else {
        observacaoCompleta = variedade;
      }
      
      if (observacoes != null && observacoes.isNotEmpty) {
        observacaoCompleta += ' | $observacoes';
      }
      
      observacaoCompleta += ' | Subárea: ${subarea.nome} (${subarea.tipo}) | Experimento: ${experimento.nome}';

      // ✅ Criar plantio apenas com dados BÁSICOS
      // ❌ População/Espaçamento virão do Estande de Plantas!
      final plantio = database_plantio.Plantio(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: experimento.talhaoId,
        cultura: cultura,
        variedade: variedade,
        dataPlantio: dataPlantio,
        // hectares: experimento.area, // Descomentar se Experimento tiver area
        observacao: observacaoCompleta,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar plantio
      await _plantioService.criarOuAtualizarPlantio(plantio);

      // Atualizar dados de plantio na subárea
      final dadosPlantio = {
        'plantioId': plantio.id,
        'cultura': cultura,
        'variedade': variedade,
        'dataPlantio': dataPlantio.toIso8601String(),
        'espacamentoCm': espacamentoCm,
        'populacaoPorM': populacaoPorM,
        'variedadeTipo': variedadeTipo,
        'cicloNome': cicloNome,
        'cicloDias': cicloDias,
        'cicloDescricao': cicloDescricao,
        'observacoes': observacoes,
        'integradoEm': DateTime.now().toIso8601String(),
      };

      await _experimentoService.atualizarDadosPlantio(subareaId, dadosPlantio);

      return plantio.id ?? '';
    } catch (e) {
      throw Exception('Erro ao integrar subárea com plantio: $e');
    }
  }

  /// Busca plantios relacionados a uma subárea
  Future<List<PlantioModel>> buscarPlantiosPorSubarea(String subareaId) async {
    try {
      // Buscar todos os plantios que referenciam esta subárea
      // Como o campo subareaId foi adicionado ao modelo, precisamos buscar por observação
      // TODO: Implementar busca direta quando o modelo for atualizado
      
      final subarea = await _experimentoService.buscarSubareaPorId(subareaId);
      if (subarea == null) return [];

      // Buscar por observação que contém o nome da subárea
      final todosPlantios = await _plantioService.buscar();
      final plantiosFiltrados = todosPlantios.where((plantio) {
        return plantio.subareaNome?.contains(subarea.nome) ?? false;
      }).toList();

      // Converter ListaPlantioItem para PlantioModel
      return plantiosFiltrados.map((item) => PlantioModel(
        id: item.id,
        talhaoId: null, // ListaPlantioItem não tem talhaoId
        culturaId: item.cultura,
        variedadeId: item.variedade,
        dataPlantio: item.dataPlantio,
        espacamento: item.espacamentoCm,
        densidade: item.populacaoPorM,
        descricao: 'Plantio de ${item.cultura} - ${item.variedade}',
      )).toList();
    } catch (e) {
      print('Erro ao buscar plantios por subárea: $e');
      return [];
    }
  }

  /// Atualiza dados de colheita de uma subárea
  Future<void> atualizarDadosColheita({
    required String subareaId,
    required double produtividade,
    required double areaColhida,
    required DateTime dataColheita,
    String? observacoesColheita,
    double? umidade,
    double? impureza,
    Map<String, dynamic>? dadosAdicionais,
  }) async {
    try {
      final dadosColheita = {
        'produtividade': produtividade,
        'areaColhida': areaColhida,
        'dataColheita': dataColheita.toIso8601String(),
        'observacoesColheita': observacoesColheita,
        'umidade': umidade,
        'impureza': impureza,
        'dadosAdicionais': dadosAdicionais,
        'atualizadoEm': DateTime.now().toIso8601String(),
      };

      await _experimentoService.atualizarDadosColheita(subareaId, dadosColheita);

      // Finalizar subárea se necessário
      final subarea = await _experimentoService.buscarSubareaPorId(subareaId);
      if (subarea != null && subarea.status != SubareaStatus.finalizada) {
        final subareaFinalizada = subarea.copyWith(
          status: SubareaStatus.finalizada,
          dataFinalizacao: DateTime.now(),
        );
        await _experimentoService.atualizarSubarea(subareaFinalizada);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar dados de colheita: $e');
    }
  }

  /// Gera relatório comparativo entre subáreas de um experimento
  Future<Map<String, dynamic>> gerarRelatorioComparativo(String experimentoId) async {
    try {
      final experimento = await _experimentoService.buscarExperimentoPorId(experimentoId);
      if (experimento == null) {
        throw Exception('Experimento não encontrado');
      }

      final relatorio = {
        'experimento': {
          'id': experimento.id,
          'nome': experimento.nome,
          'talhaoNome': experimento.talhaoNome,
          'dataInicio': experimento.dataInicio.toIso8601String(),
          'dataFim': experimento.dataFim.toIso8601String(),
          'status': experimento.statusText,
        },
        'subareas': [],
        'resumo': {
          'totalSubareas': experimento.subareas.length,
          'subareasComPlantio': 0,
          'subareasComColheita': 0,
          'produtividadeMedia': 0.0,
          'melhorProdutividade': 0.0,
          'piorProdutividade': double.infinity,
        },
      };

      double somaProdutividade = 0.0;
      int subareasComProdutividade = 0;

      for (final subarea in experimento.subareas) {
        final dadosSubarea = {
          'id': subarea.id,
          'nome': subarea.nome,
          'tipo': subarea.tipo,
          'cor': subarea.cor.value,
          'area': subarea.area,
          'status': subarea.statusText,
          'cultura': subarea.cultura,
          'variedade': subarea.variedade,
          'dadosPlantio': subarea.dadosPlantio,
          'dadosColheita': subarea.dadosColheita,
        };

        (relatorio['subareas'] as List).add(dadosSubarea);

        // Contar subáreas com plantio
        if (subarea.dadosPlantio != null) {
          (relatorio['resumo'] as Map)['subareasComPlantio']++;
        }

        // Contar subáreas com colheita e calcular produtividade
        if (subarea.dadosColheita != null) {
          (relatorio['resumo'] as Map)['subareasComColheita']++;
          
          final produtividade = (subarea.dadosColheita!['produtividade'] as num?)?.toDouble();
          if (produtividade != null) {
            somaProdutividade += produtividade;
            subareasComProdutividade++;

            if (produtividade > (relatorio['resumo'] as Map)['melhorProdutividade']) {
              (relatorio['resumo'] as Map)['melhorProdutividade'] = produtividade;
            }

            if (produtividade < (relatorio['resumo'] as Map)['piorProdutividade']) {
              (relatorio['resumo'] as Map)['piorProdutividade'] = produtividade;
            }
          }
        }
      }

      // Calcular produtividade média
      if (subareasComProdutividade > 0) {
        (relatorio['resumo'] as Map)['produtividadeMedia'] = somaProdutividade / subareasComProdutividade;
      }

      // Ajustar pior produtividade se não houve dados
      if ((relatorio['resumo'] as Map)['piorProdutividade'] == double.infinity) {
        (relatorio['resumo'] as Map)['piorProdutividade'] = 0.0;
      }

      return relatorio;
    } catch (e) {
      throw Exception('Erro ao gerar relatório comparativo: $e');
    }
  }

  /// Lista experimentos que podem ser integrados com plantio
  Future<List<Map<String, dynamic>>> listarExperimentosParaPlantio() async {
    try {
      final experimentos = await _experimentoService.listarExperimentos();
      final List<Map<String, dynamic>> experimentosParaPlantio = [];

      for (final experimento in experimentos) {
        if (experimento.isAtivo && experimento.subareas.isNotEmpty) {
          final subareasParaPlantio = experimento.subareas.where((s) => 
            s.status == SubareaStatus.ativa && s.dadosPlantio == null
          ).toList();

          if (subareasParaPlantio.isNotEmpty) {
            experimentosParaPlantio.add({
              'experimento': experimento,
              'subareasDisponiveis': subareasParaPlantio,
              'totalSubareas': experimento.subareas.length,
            });
          }
        }
      }

      return experimentosParaPlantio;
    } catch (e) {
      print('Erro ao listar experimentos para plantio: $e');
      return [];
    }
  }

  /// Verifica se uma subárea pode ser plantada
  Future<bool> podePlantarSubarea(String subareaId) async {
    try {
      final subarea = await _experimentoService.buscarSubareaPorId(subareaId);
      if (subarea == null) return false;

      // Verificar se já foi plantada
      if (subarea.dadosPlantio != null) return false;

      // Verificar se está ativa
      if (subarea.status != SubareaStatus.ativa) return false;

      // Verificar se o experimento está ativo
      final experimento = await _experimentoService.buscarExperimentoPorId(subarea.experimentoId);
      if (experimento == null || !experimento.isAtivo) return false;

      return true;
    } catch (e) {
      print('Erro ao verificar se pode plantar subárea: $e');
      return false;
    }
  }

  /// Obtém estatísticas de integração
  Future<Map<String, dynamic>> obterEstatisticasIntegracao() async {
    try {
      final experimentos = await _experimentoService.listarExperimentos();
      
      int totalExperimentos = experimentos.length;
      int experimentosAtivos = experimentos.where((e) => e.isAtivo).length;
      int totalSubareas = experimentos.fold(0, (sum, e) => sum + e.subareas.length);
      int subareasComPlantio = experimentos.fold(0, (sum, e) => 
        sum + e.subareas.where((s) => s.dadosPlantio != null).length);
      int subareasComColheita = experimentos.fold(0, (sum, e) => 
        sum + e.subareas.where((s) => s.dadosColheita != null).length);

      return {
        'totalExperimentos': totalExperimentos,
        'experimentosAtivos': experimentosAtivos,
        'totalSubareas': totalSubareas,
        'subareasComPlantio': subareasComPlantio,
        'subareasComColheita': subareasComColheita,
        'taxaIntegracaoPlantio': totalSubareas > 0 ? (subareasComPlantio / totalSubareas * 100) : 0,
        'taxaIntegracaoColheita': subareasComPlantio > 0 ? (subareasComColheita / subareasComPlantio * 100) : 0,
      };
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {};
    }
  }
}
