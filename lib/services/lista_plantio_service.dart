import '../database/daos/plantio_dao.dart';
import '../database/daos/estoque_dao.dart';
import '../database/daos/estande_dao.dart';
import '../database/models/plantio_model.dart';
import '../database/models/lista_plantio_item.dart';
import '../database/models/historico_plantio_model.dart';
import '../database/repositories/historico_plantio_repository.dart';
import 'plantio_integration_service.dart';
import '../modules/planting/models/plantio_model.dart' as planting_model;
import '../services/talhao_service.dart';

class ListaPlantioService {
  final PlantioDao _plantioDao = PlantioDao();
  final EstoqueDao _estoqueDao = EstoqueDao();
  final EstandeDao _estandeDao = EstandeDao();
  final HistoricoPlantioRepository _historicoRepository = HistoricoPlantioRepository();
  final TalhaoService _talhaoService = TalhaoService();

  // Buscar lista de plantio com filtros
  Future<List<ListaPlantioItem>> buscar({
    String? cultura,
    String? talhaoId,
    DateTime? dataIni,
    DateTime? dataFim,
  }) async {
    try {
      return await _plantioDao.listarListaPlantio(
        cultura: cultura,
        talhaoId: talhaoId,
        dataIni: dataIni,
        dataFim: dataFim,
      );
    } catch (e) {
      throw Exception('Erro ao buscar lista de plantio: $e');
    }
  }

  // Criar ou atualizar plantio
  Future<void> criarOuAtualizarPlantio(Plantio plantio) async {
    try {
      // ✅ Agora o plantio só registra: Talhão, Cultura, Variedade, Data, Hectares
      // ❌ NÃO registra mais: População, Espaçamento (vem do Estande de Plantas)
      
      // Validar apenas cultura e variedade
      if (plantio.cultura.isEmpty) {
        throw Exception('Cultura deve ser informada');
      }
      
      if (plantio.variedade.isEmpty) {
        throw Exception('Variedade deve ser informada');
      }

      // Se é um novo plantio (sem ID), criar
      if (plantio.id.isEmpty) {
        final novoId = DateTime.now().millisecondsSinceEpoch.toString();
        final now = DateTime.now();
        
        final novoPlantio = plantio.copyWith(
          id: novoId,
          createdAt: now,
          updatedAt: now,
        );
        
        await _plantioDao.inserirPlantio(novoPlantio);
        
        // Salvar no histórico de plantios
        await _salvarNoHistorico(novoPlantio, 'novo_plantio');
        
        // Salvar também na tabela integrada usando o serviço de integração
        await _salvarNaTabelaIntegrada(novoPlantio);
        
      } else {
        // Atualizar plantio existente
        final plantioAtualizado = plantio.copyWith(
          updatedAt: DateTime.now(),
        );
        
        await _plantioDao.atualizarPlantio(plantioAtualizado);
        
        // Salvar no histórico de plantios
        await _salvarNoHistorico(plantioAtualizado, 'atualizacao_plantio');
      }
    } catch (e) {
      throw Exception('Erro ao salvar plantio: $e');
    }
  }

  // Duplicar plantio
  Future<String> duplicarPlantio(String plantioId) async {
    try {
      return await _plantioDao.duplicarPlantio(plantioId);
    } catch (e) {
      throw Exception('Erro ao duplicar plantio: $e');
    }
  }

  // Deletar plantio (soft delete)
  Future<void> deletarPlantio(String plantioId) async {
    try {
      await _plantioDao.deletarPlantio(plantioId);
    } catch (e) {
      throw Exception('Erro ao deletar plantio: $e');
    }
  }

  // Apontar saída de semente
  Future<void> apontarSaidaSemente({
    required String plantioId,
    required String loteId,
    required double quantidade,
  }) async {
    try {
      await _estoqueDao.apontarSaidaEstoque(
        plantioId: plantioId,
        loteId: loteId,
        quantidade: quantidade,
      );
    } catch (e) {
      throw Exception('Erro ao apontar saída de semente: $e');
    }
  }

  // Registrar estande/avaliação
  Future<void> registrarEstande({
    required String plantioId,
    required DateTime dataAvaliacao,
    required double comprimentoAmostradoM,
    required int linhasAmostradas,
    required int plantasContadas,
    int? dae,
  }) async {
    try {
      // Validar dados
      if (comprimentoAmostradoM <= 0) {
        throw Exception('Comprimento amostrado deve ser maior que zero');
      }
      
      if (linhasAmostradas <= 0) {
        throw Exception('Número de linhas amostradas deve ser maior que zero');
      }
      
      if (plantasContadas < 0) {
        throw Exception('Número de plantas contadas não pode ser negativo');
      }
      
      // Calcular DAE automaticamente se não fornecido
      final daeCalculado = dae ?? _estandeDao.calcularDae(
        comprimentoAmostradoM: comprimentoAmostradoM,
        linhasAmostradas: linhasAmostradas,
        plantasContadas: plantasContadas,
      );
      
      // Inserir avaliação
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _estandeDao.inserirEstande(
        id: id,
        plantioId: plantioId,
        dataAvaliacao: dataAvaliacao,
        comprimentoAmostradoM: comprimentoAmostradoM,
        linhasAmostradas: linhasAmostradas,
        plantasContadas: plantasContadas,
        dae: daeCalculado,
      );
    } catch (e) {
      throw Exception('Erro ao registrar estande: $e');
    }
  }

  // Buscar estatísticas
  Future<Map<String, dynamic>> buscarEstatisticas({
    String? cultura,
    String? talhaoId,
    DateTime? dataIni,
    DateTime? dataFim,
  }) async {
    try {
      return await _plantioDao.buscarEstatisticasPlantio(
        cultura: cultura,
        talhaoId: talhaoId,
        dataIni: dataIni,
        dataFim: dataFim,
      );
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas: $e');
    }
  }

  // Buscar apontamentos de estoque por plantio
  Future<List<Map<String, dynamic>>> buscarApontamentosPlantio(String plantioId) async {
    try {
      return await _estoqueDao.buscarApontamentosPlantio(plantioId);
    } catch (e) {
      throw Exception('Erro ao buscar apontamentos: $e');
    }
  }

  // Buscar custo total por plantio
  Future<double?> buscarCustoTotalPlantio(String plantioId) async {
    try {
      return await _estoqueDao.buscarCustoTotalPlantio(plantioId);
    } catch (e) {
      throw Exception('Erro ao buscar custo total: $e');
    }
  }

  // Buscar lotes disponíveis por produto
  Future<List<Map<String, dynamic>>> buscarLotesDisponiveis(String produtoId) async {
    try {
      return await _estoqueDao.buscarLotesDisponiveis(produtoId);
    } catch (e) {
      throw Exception('Erro ao buscar lotes disponíveis: $e');
    }
  }

  // Buscar produtos de estoque
  Future<List<Map<String, dynamic>>> buscarProdutos({
    String? tipo,
    String? cultura,
  }) async {
    try {
      return await _estoqueDao.buscarProdutos(
        tipo: tipo,
        cultura: cultura,
      );
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }

  // Verificar se plantio tem custo calculado
  Future<bool> verificarPlantioComCusto(String plantioId) async {
    try {
      final custo = await _estoqueDao.buscarCustoTotalPlantio(plantioId);
      return custo != null && custo > 0;
    } catch (e) {
      return false;
    }
  }

  // Verificar se plantio tem área válida
  Future<bool> verificarPlantioComArea(String plantioId) async {
    try {
      final plantio = await _plantioDao.buscarPlantioPorId(plantioId);
      if (plantio == null) return false;
      
      return await _plantioDao.verificarAreaValida(
        plantio.talhaoId, 
        plantio.subareaId,
      );
    } catch (e) {
      return false;
    }
  }

  // Buscar avaliações de estande por plantio
  Future<List<Map<String, dynamic>>> buscarAvaliacoesEstande(String plantioId) async {
    try {
      return await _estandeDao.buscarAvaliacoesPlantio(plantioId);
    } catch (e) {
      throw Exception('Erro ao buscar avaliações de estande: $e');
    }
  }

  // Buscar DAE mais recente por plantio
  Future<int?> buscarDaeMaisRecente(String plantioId) async {
    try {
      return await _estandeDao.buscarDaeMaisRecente(plantioId);
    } catch (e) {
      return null;
    }
  }

  // Verificar se plantio tem avaliações de estande
  Future<bool> verificarPlantioComEstande(String plantioId) async {
    try {
      return await _estandeDao.verificarPlantioComAvaliacoes(plantioId);
    } catch (e) {
      return false;
    }
  }

  // Buscar estatísticas de estande
  Future<Map<String, dynamic>> buscarEstatisticasEstande(String plantioId) async {
    try {
      return await _estandeDao.buscarEstatisticasEstande(plantioId);
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas de estande: $e');
    }
  }

  // Buscar plantio por ID
  Future<Plantio?> buscarPlantioPorId(String plantioId) async {
    try {
      return await _plantioDao.buscarPlantioPorId(plantioId);
    } catch (e) {
      throw Exception('Erro ao buscar plantio: $e');
    }
  }

  // ❌ REMOVIDO: População agora é calculada APENAS no Estande de Plantas
  // Não temos mais dados fictícios de população/espaçamento aqui!

  // Calcular custo por hectare
  double? calcularCustoHa(double? custoTotal, double? areaHa) {
    if (custoTotal == null || areaHa == null || areaHa <= 0) {
      return null;
    }
    return custoTotal / areaHa;
  }

  // Salvar plantio no histórico
  Future<void> _salvarNoHistorico(Plantio plantio, String tipo) async {
    try {
      print('🔄 DEBUG: Iniciando salvamento no histórico...');
      print('🔄 DEBUG: Plantio ID: ${plantio.id}');
      print('🔄 DEBUG: Talhão ID: ${plantio.talhaoId}');
      print('🔄 DEBUG: Cultura: ${plantio.cultura}');
      print('🔄 DEBUG: Tipo: $tipo');
      
      // Buscar nome do talhão
      String? talhaoNome;
      try {
        final talhao = await _talhaoService.obterPorId(plantio.talhaoId);
        talhaoNome = talhao?.name;
        print('🔄 DEBUG: Nome do talhão: $talhaoNome');
      } catch (e) {
        print('⚠️ DEBUG: Erro ao buscar nome do talhão: $e');
        talhaoNome = null;
      }
      
      final historico = HistoricoPlantioModel(
        calculoId: plantio.id,
        talhaoId: plantio.talhaoId,
        talhaoNome: talhaoNome,
        safraId: '', // Plantio não tem safraId direto
        culturaId: plantio.cultura,
        tipo: tipo,
        data: DateTime.now(),
        resumo: _gerarResumoPlantio(plantio),
      );
      
      print('🔄 DEBUG: Modelo de histórico criado');
      print('🔄 DEBUG: Chamando _historicoRepository.salvar()...');
      
      await _historicoRepository.salvar(historico);
      print('✅ Plantio salvo no histórico: $tipo');
    } catch (e) {
      print('⚠️ Erro ao salvar no histórico: $e');
      print('⚠️ Stack trace: ${StackTrace.current}');
      // Não falhar o salvamento principal por erro no histórico
    }
  }

  // Gerar resumo do plantio para o histórico
  String _gerarResumoPlantio(Plantio plantio) {
    // ✅ Agora só salva dados REAIS, sem invenções!
    final resumo = {
      'cultura': plantio.cultura,
      'variedade': plantio.variedade,
      'data_plantio': plantio.dataPlantio?.toIso8601String(),
      'hectares': plantio.hectares,
      'observacao': plantio.observacao,
    };
    
    // Remover valores nulos
    resumo.removeWhere((key, value) => value == null);
    
    return resumo.toString();
  }

  // Salvar plantio na tabela integrada para evolução fenológica
  Future<void> _salvarNaTabelaIntegrada(Plantio plantio) async {
    try {
      print('🔄 DEBUG: Salvando plantio na tabela integrada...');
      
      // Converter Plantio (submódulo) para PlantioModel (módulo principal)
      // ✅ Agora salvamos APENAS dados básicos do plantio
      // ❌ População e Espaçamento virão do Estande de Plantas!
      final plantioModel = planting_model.PlantioModel(
        id: plantio.id,
        talhaoId: plantio.talhaoId,
        culturaId: plantio.cultura,
        variedadeId: plantio.variedade,
        dataPlantio: plantio.dataPlantio ?? DateTime.now(),
        populacao: 0, // Será preenchido pelo Estande de Plantas
        espacamento: 0, // Será preenchido pelo Estande de Plantas
        profundidade: 0, // Será preenchido pelo CV%
        maquinasIds: [],
        observacoes: plantio.observacao,
      );
      
      // Usar o serviço de integração para salvar
      final integrationService = PlantioIntegrationService();
      final sucesso = await integrationService.salvarPlantioIntegrado(plantioModel);
      
      if (sucesso) {
        print('✅ DEBUG: Plantio salvo na tabela integrada com sucesso');
      } else {
        print('⚠️ DEBUG: Falha ao salvar plantio na tabela integrada');
      }
      
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar plantio na tabela integrada: $e');
      // Não propagar o erro para não quebrar o fluxo principal
    }
  }
}
