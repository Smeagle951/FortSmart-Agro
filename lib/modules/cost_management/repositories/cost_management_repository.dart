import '../models/cost_management_model.dart';
import '../../../models/produto_estoque.dart';
import '../../../models/talhao_model.dart';
import '../../../models/aplicacao.dart';
import '../../../database/daos/aplicacao_dao.dart';
import '../../../utils/logger.dart';

class CostManagementRepository {
  static final CostManagementRepository _instance = CostManagementRepository._internal();
  factory CostManagementRepository() => _instance;
  CostManagementRepository._internal();

  final AplicacaoDao _aplicacaoDao = AplicacaoDao();
  final List<CostProductModel> _produtosCusto = [];
  final List<CostManagementModel> _aplicacoes = [];

  // Métodos para aplicações
  Future<List<CostManagementModel>> getAllAplicacoes() async {
    try {
      Logger.info('📋 Buscando todas as aplicações do banco de dados...');
      final aplicacoes = await _aplicacaoDao.getAll();
      return aplicacoes.map((aplicacao) => _convertAplicacaoToCostManagement(aplicacao)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações: $e');
      rethrow;
    }
  }

  Future<CostManagementModel?> getAplicacaoById(String id) async {
    try {
      Logger.info('📋 Buscando aplicação com ID: $id');
      final aplicacao = await _aplicacaoDao.getById(id);
      return aplicacao != null ? _convertAplicacaoToCostManagement(aplicacao) : null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicação: $e');
      return null;
    }
  }

  Future<String> insertAplicacao(CostManagementModel aplicacao) async {
    try {
      Logger.info('💾 Inserindo nova aplicação no banco de dados...');
      
      // Converter CostManagementModel para Aplicacao
      final aplicacaoDb = Aplicacao(
        talhaoId: aplicacao.talhaoId,
        produtoId: aplicacao.produtos.isNotEmpty ? aplicacao.produtos.first.id : '',
        dosePorHa: aplicacao.produtos.isNotEmpty ? aplicacao.produtos.first.dosePorHa : 0.0,
        areaAplicadaHa: aplicacao.areaHa,
        precoUnitarioMomento: aplicacao.produtos.isNotEmpty ? aplicacao.produtos.first.precoUnitario : 0.0,
        dataAplicacao: aplicacao.dataAplicacao,
        operador: aplicacao.operador,
        equipamento: aplicacao.equipamento,
        condicoesClimaticas: 'Prescrição automática',
        observacoes: aplicacao.observacoes,
        fazendaId: aplicacao.talhaoId, // Usar talhaoId como fazendaId temporariamente
      );
      
      final id = await _aplicacaoDao.insert(aplicacaoDb);
      Logger.info('✅ Aplicação inserida com sucesso no banco: $id');
      return id;
    } catch (e) {
      Logger.error('❌ Erro ao inserir aplicação: $e');
      rethrow;
    }
  }

  Future<bool> updateAplicacao(CostManagementModel aplicacao) async {
    try {
      Logger.info('🔄 Atualizando aplicação: ${aplicacao.id}');
      final index = _aplicacoes.indexWhere((a) => a.id == aplicacao.id);
      if (index != -1) {
        final aplicacaoAtualizada = aplicacao.copyWith(
          dataAtualizacao: DateTime.now(),
        );
        _aplicacoes[index] = aplicacaoAtualizada;
        Logger.info('✅ Aplicação atualizada com sucesso');
        return true;
      }
      Logger.warning('⚠️ Aplicação não encontrada para atualização');
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar aplicação: $e');
      return false;
    }
  }

  Future<bool> deleteAplicacao(String id) async {
    try {
      Logger.info('🗑️ Excluindo aplicação: $id');
      final index = _aplicacoes.indexWhere((a) => a.id == id);
      if (index != -1) {
        _aplicacoes.removeAt(index);
        Logger.info('✅ Aplicação excluída com sucesso');
        return true;
      }
      Logger.warning('⚠️ Aplicação não encontrada para exclusão');
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao excluir aplicação: $e');
      return false;
    }
  }

  // Métodos para produtos de custo
  Future<List<CostProductModel>> getAllProdutosCusto() async {
    try {
      Logger.info('📋 Buscando todos os produtos de custo...');
      return List.from(_produtosCusto);
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos de custo: $e');
      rethrow;
    }
  }

  Future<String> insertProdutoCusto(CostProductModel produto) async {
    try {
      Logger.info('💾 Inserindo novo produto de custo...');
      final novoProduto = CostProductModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: produto.nome,
        tipo: produto.tipo,
        unidade: produto.unidade,
        dosePorHa: produto.dosePorHa,
        precoUnitario: produto.precoUnitario,
        quantidade: produto.quantidade,
        custoTotal: produto.custoTotal,
      );
      _produtosCusto.add(novoProduto);
      Logger.info('✅ Produto de custo inserido com sucesso: ${novoProduto.id}');
      return novoProduto.id;
    } catch (e) {
      Logger.error('❌ Erro ao inserir produto de custo: $e');
      rethrow;
    }
  }

  // Métodos de consulta e relatórios
  Future<List<CostManagementModel>> getAplicacoesPorPeriodo(
    DateTime dataInicio,
    DateTime dataFim, {
    String? talhaoId,
  }) async {
    try {
      Logger.info('📊 Buscando aplicações por período no banco de dados...');
      // final aplicacoes = await _aplicacaoDao.getByPeriod(dataInicio, dataFim, talhaoId: talhaoId);
      final aplicacoes = await _aplicacaoDao.getAll(); // Temporário
      return aplicacoes.map((aplicacao) => _convertAplicacaoToCostManagement(aplicacao)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações por período: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getResumoCustos(
    DateTime dataInicio,
    DateTime dataFim, {
    String? talhaoId,
  }) async {
    try {
      Logger.info('📊 Gerando resumo de custos...');
      final aplicacoes = await getAplicacoesPorPeriodo(dataInicio, dataFim, talhaoId: talhaoId);
      
      double custoTotal = 0.0;
      double areaTotal = 0.0;
      int totalAplicacoes = aplicacoes.length;
      
      for (final aplicacao in aplicacoes) {
        custoTotal += aplicacao.custoTotal;
        areaTotal += aplicacao.areaHa;
      }
      
      final custoPorHectare = areaTotal > 0 ? custoTotal / areaTotal : 0.0;
      
      return {
        'custoTotal': custoTotal,
        'areaTotal': areaTotal,
        'custoPorHectare': custoPorHectare,
        'totalAplicacoes': totalAplicacoes,
        'periodo': {
          'inicio': dataInicio.toIso8601String(),
          'fim': dataFim.toIso8601String(),
        },
      };
    } catch (e) {
      Logger.error('❌ Erro ao gerar resumo de custos: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCustosPorTalhao(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      Logger.info('📊 Gerando custos por talhão...');
      final aplicacoes = await getAplicacoesPorPeriodo(dataInicio, dataFim);
      
      final Map<String, Map<String, dynamic>> custosPorTalhao = {};
      
      for (final aplicacao in aplicacoes) {
        final talhaoId = aplicacao.talhaoId;
        
        if (!custosPorTalhao.containsKey(talhaoId)) {
          custosPorTalhao[talhaoId] = {
            'talhaoId': talhaoId,
            'talhaoNome': aplicacao.talhaoNome,
            'custoTotal': 0.0,
            'areaTotal': 0.0,
            'aplicacoes': 0,
          };
        }
        
        custosPorTalhao[talhaoId]!['custoTotal'] = 
            (custosPorTalhao[talhaoId]!['custoTotal'] as double) + aplicacao.custoTotal;
        custosPorTalhao[talhaoId]!['areaTotal'] = 
            (custosPorTalhao[talhaoId]!['areaTotal'] as double) + aplicacao.areaHa;
        custosPorTalhao[talhaoId]!['aplicacoes'] = 
            (custosPorTalhao[talhaoId]!['aplicacoes'] as int) + 1;
      }
      
      // Calcular custo por hectare para cada talhão
      for (final entry in custosPorTalhao.entries) {
        final areaTotal = entry.value['areaTotal'] as double;
        final custoTotal = entry.value['custoTotal'] as double;
        entry.value['custoPorHectare'] = areaTotal > 0 ? custoTotal / areaTotal : 0.0;
      }
      
      return custosPorTalhao.values.toList();
    } catch (e) {
      Logger.error('❌ Erro ao gerar custos por talhão: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProdutosMaisUtilizados(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      Logger.info('📊 Gerando produtos mais utilizados...');
      final aplicacoes = await getAplicacoesPorPeriodo(dataInicio, dataFim);
      
      final Map<String, Map<String, dynamic>> produtosUtilizados = {};
      
      for (final aplicacao in aplicacoes) {
        for (final produto in aplicacao.produtos) {
          final produtoId = produto.id;
          
          if (!produtosUtilizados.containsKey(produtoId)) {
            produtosUtilizados[produtoId] = {
              'produtoId': produtoId,
              'produtoNome': produto.nome,
              'tipo': produto.tipo,
              'unidade': produto.unidade,
              'quantidadeTotal': 0.0,
              'custoTotal': 0.0,
              'aplicacoes': 0,
            };
          }
          
          produtosUtilizados[produtoId]!['quantidadeTotal'] = 
              (produtosUtilizados[produtoId]!['quantidadeTotal'] as double) + produto.quantidade;
          produtosUtilizados[produtoId]!['custoTotal'] = 
              (produtosUtilizados[produtoId]!['custoTotal'] as double) + produto.custoTotal;
          produtosUtilizados[produtoId]!['aplicacoes'] = 
              (produtosUtilizados[produtoId]!['aplicacoes'] as int) + 1;
        }
      }
      
      // Ordenar por custo total (mais utilizados primeiro)
      final listaOrdenada = produtosUtilizados.values.toList();
      listaOrdenada.sort((a, b) => (b['custoTotal'] as double).compareTo(a['custoTotal'] as double));
      
      return listaOrdenada;
    } catch (e) {
      Logger.error('❌ Erro ao gerar produtos mais utilizados: $e');
      rethrow;
    }
  }

  /// Converte Aplicacao para CostManagementModel
  CostManagementModel _convertAplicacaoToCostManagement(Aplicacao aplicacao) {
    // Criar um produto fictício baseado na aplicação
    final produto = CostProductModel(
      id: aplicacao.produtoId,
      nome: 'Produto ${aplicacao.produtoId}',
      tipo: 'Produto',
      unidade: 'L',
      dosePorHa: aplicacao.dosePorHa,
      precoUnitario: aplicacao.precoUnitarioMomento,
      quantidade: aplicacao.dosePorHa * aplicacao.areaAplicadaHa,
      custoTotal: aplicacao.dosePorHa * aplicacao.areaAplicadaHa * aplicacao.precoUnitarioMomento,
    );

    return CostManagementModel(
      id: aplicacao.id,
      talhaoId: aplicacao.talhaoId,
      talhaoNome: 'Talhão ${aplicacao.talhaoId}',
      areaHa: aplicacao.areaAplicadaHa,
      dataAplicacao: aplicacao.dataAplicacao,
      operador: aplicacao.operador ?? 'Não informado',
      equipamento: aplicacao.equipamento ?? 'Não informado',
      observacoes: aplicacao.observacoes ?? '',
      custoTotal: produto.custoTotal,
      custoPorHectare: aplicacao.areaAplicadaHa > 0 ? produto.custoTotal / aplicacao.areaAplicadaHa : 0.0,
      produtos: [produto],
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
    );
  }
}
