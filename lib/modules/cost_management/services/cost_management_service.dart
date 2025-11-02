import '../models/cost_management_model.dart';
import '../repositories/cost_management_repository.dart';
import '../../../models/produto_estoque.dart';
import '../../../models/talhao_model.dart';
import '../../../utils/logger.dart';

class CostManagementService {
  static final CostManagementService _instance = CostManagementService._internal();
  factory CostManagementService() => _instance;
  CostManagementService._internal();

  final CostManagementRepository _repository = CostManagementRepository();

  // Métodos para aplicações
  Future<List<CostManagementModel>> getAllAplicacoes() async {
    try {
      Logger.info('📋 Buscando todas as aplicações...');
      return await _repository.getAllAplicacoes();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações: $e');
      rethrow;
    }
  }

  Future<CostManagementModel?> getAplicacaoById(String id) async {
    try {
      Logger.info('📋 Buscando aplicação com ID: $id');
      return await _repository.getAplicacaoById(id);
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicação: $e');
      rethrow;
    }
  }

  Future<String> registrarAplicacao({
    required String talhaoId,
    required String talhaoNome,
    required double areaHa,
    required DateTime dataAplicacao,
    required String operador,
    required String equipamento,
    required String observacoes,
    required List<Map<String, dynamic>> produtos,
  }) async {
    try {
      Logger.info('💾 Registrando nova aplicação...');
      
      // Calcular custos dos produtos
      final List<CostProductModel> produtosCalculados = [];
      double custoTotal = 0.0;
      
      for (final produto in produtos) {
        final dosePorHa = produto['dose'] ?? 0.0;
        final precoUnitario = produto['preco'] ?? 0.0;
        final quantidade = dosePorHa * areaHa;
        final custoProduto = quantidade * precoUnitario;
        
        final produtoCalculado = CostProductModel(
          id: produto['id'] ?? '',
          nome: produto['nome'] ?? '',
          tipo: produto['tipo'] ?? '',
          unidade: produto['unidade'] ?? '',
          dosePorHa: dosePorHa,
          precoUnitario: precoUnitario,
          quantidade: quantidade,
          custoTotal: custoProduto,
        );
        
        produtosCalculados.add(produtoCalculado);
        custoTotal += custoProduto;
      }
      
      final custoPorHectare = areaHa > 0 ? custoTotal / areaHa : 0.0;
      
      final aplicacao = CostManagementModel(
        id: '',
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        areaHa: areaHa,
        dataAplicacao: dataAplicacao,
        operador: operador,
        equipamento: equipamento,
        observacoes: observacoes,
        custoTotal: custoTotal,
        custoPorHectare: custoPorHectare,
        produtos: produtosCalculados,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      final id = await _repository.insertAplicacao(aplicacao);
      Logger.info('✅ Aplicação registrada com sucesso: $id');
      return id;
    } catch (e) {
      Logger.error('❌ Erro ao registrar aplicação: $e');
      rethrow;
    }
  }

  Future<bool> atualizarAplicacao(CostManagementModel aplicacao) async {
    try {
      Logger.info('🔄 Atualizando aplicação: ${aplicacao.id}');
      return await _repository.updateAplicacao(aplicacao);
    } catch (e) {
      Logger.error('❌ Erro ao atualizar aplicação: $e');
      rethrow;
    }
  }

  Future<bool> excluirAplicacao(String id) async {
    try {
      Logger.info('🗑️ Excluindo aplicação: $id');
      return await _repository.deleteAplicacao(id);
    } catch (e) {
      Logger.error('❌ Erro ao excluir aplicação: $e');
      rethrow;
    }
  }

  // Métodos de relatórios
  Future<Map<String, dynamic>> calcularCustosPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoId,
  }) async {
    try {
      Logger.info('📊 Calculando custos por período...');
      return await _repository.getResumoCustos(dataInicio, dataFim, talhaoId: talhaoId);
    } catch (e) {
      Logger.error('❌ Erro ao calcular custos por período: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obterAplicacoesDetalhadas({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoId,
  }) async {
    try {
      Logger.info('📊 Obtendo aplicações detalhadas...');
      final aplicacoes = await _repository.getAplicacoesPorPeriodo(dataInicio, dataFim, talhaoId: talhaoId);
      
      return aplicacoes.map((aplicacao) => {
        'id': aplicacao.id,
        'talhaoId': aplicacao.talhaoId,
        'talhaoNome': aplicacao.talhaoNome,
        'areaHa': aplicacao.areaHa,
        'dataAplicacao': aplicacao.dataAplicacao.toIso8601String(),
        'operador': aplicacao.operador,
        'equipamento': aplicacao.equipamento,
        'observacoes': aplicacao.observacoes,
        'custoTotal': aplicacao.custoTotal,
        'custoPorHectare': aplicacao.custoPorHectare,
        'produtos': aplicacao.produtos.map((p) => p.toJson()).toList(),
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter aplicações detalhadas: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> calcularCustosPorTalhao({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      Logger.info('📊 Calculando custos por talhão...');
      return await _repository.getCustosPorTalhao(dataInicio, dataFim);
    } catch (e) {
      Logger.error('❌ Erro ao calcular custos por talhão: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obterProdutosMaisUtilizados({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      Logger.info('📊 Obtendo produtos mais utilizados...');
      return await _repository.getProdutosMaisUtilizados(dataInicio, dataFim);
    } catch (e) {
      Logger.error('❌ Erro ao obter produtos mais utilizados: $e');
      rethrow;
    }
  }

  // Métodos de simulação
  Future<Map<String, dynamic>> simularCustos({
    required String talhaoId,
    required String talhaoNome,
    required double areaHa,
    required List<Map<String, dynamic>> produtos,
    String? observacoes,
  }) async {
    try {
      Logger.info('🧮 Simulando custos...');
      
      double custoTotal = 0.0;
      final List<Map<String, dynamic>> produtosCalculados = [];
      
      for (final produto in produtos) {
        final dosePorHa = produto['dose'] ?? 0.0;
        final precoUnitario = produto['preco'] ?? 0.0;
        final quantidade = dosePorHa * areaHa;
        final custoProduto = quantidade * precoUnitario;
        
        produtosCalculados.add({
          'id': produto['id'],
          'nome': produto['nome'],
          'tipo': produto['tipo'],
          'unidade': produto['unidade'],
          'dosePorHa': dosePorHa,
          'precoUnitario': precoUnitario,
          'quantidade': quantidade,
          'custoTotal': custoProduto,
        });
        
        custoTotal += custoProduto;
      }
      
      final custoPorHectare = areaHa > 0 ? custoTotal / areaHa : 0.0;
      
      return {
        'talhaoId': talhaoId,
        'talhaoNome': talhaoNome,
        'areaHa': areaHa,
        'custoTotal': custoTotal,
        'custoPorHectare': custoPorHectare,
        'produtos': produtosCalculados,
        'observacoes': observacoes,
        'dataSimulacao': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao simular custos: $e');
      rethrow;
    }
  }

  // Métodos de validação
  bool validarAplicacao({
    required String talhaoId,
    required double areaHa,
    required List<Map<String, dynamic>> produtos,
  }) {
    try {
      if (talhaoId.isEmpty) {
        Logger.warning('⚠️ ID do talhão é obrigatório');
        return false;
      }
      
      if (areaHa <= 0) {
        Logger.warning('⚠️ Área deve ser maior que zero');
        return false;
      }
      
      if (produtos.isEmpty) {
        Logger.warning('⚠️ Pelo menos um produto deve ser selecionado');
        return false;
      }
      
      for (final produto in produtos) {
        final dose = produto['dose'] ?? 0.0;
        final preco = produto['preco'] ?? 0.0;
        
        if (dose <= 0) {
          Logger.warning('⚠️ Dose deve ser maior que zero');
          return false;
        }
        
        if (preco <= 0) {
          Logger.warning('⚠️ Preço deve ser maior que zero');
          return false;
        }
      }
      
      Logger.info('✅ Validação da aplicação aprovada');
      return true;
    } catch (e) {
      Logger.error('❌ Erro na validação: $e');
      return false;
    }
  }

  // Métodos de análise e insights
  Future<Map<String, dynamic>> gerarInsights({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      Logger.info('📊 Gerando insights...');
      
      final resumoCustos = await calcularCustosPorPeriodo(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      final custosPorTalhao = await calcularCustosPorTalhao(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      final produtosMaisUtilizados = await obterProdutosMaisUtilizados(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      // Calcular insights
      final custoTotal = resumoCustos['custoTotal'] ?? 0.0;
      final areaTotal = resumoCustos['areaTotal'] ?? 0.0;
      final totalAplicacoes = resumoCustos['totalAplicacoes'] ?? 0;
      
      // Talhão com maior custo
      final talhaoMaiorCusto = custosPorTalhao.isNotEmpty 
          ? custosPorTalhao.reduce((a, b) => (a['custoTotal'] ?? 0.0) > (b['custoTotal'] ?? 0.0) ? a : b)
          : null;
      
      // Produto mais utilizado
      final produtoMaisUtilizado = produtosMaisUtilizados.isNotEmpty 
          ? produtosMaisUtilizados.first
          : null;
      
      return {
        'resumo': resumoCustos,
        'talhaoMaiorCusto': talhaoMaiorCusto,
        'produtoMaisUtilizado': produtoMaisUtilizado,
        'insights': {
          'custoMedioPorAplicacao': totalAplicacoes > 0 ? custoTotal / totalAplicacoes : 0.0,
          'custoMedioPorHectare': areaTotal > 0 ? custoTotal / areaTotal : 0.0,
          'totalTalhoes': custosPorTalhao.length,
          'totalProdutos': produtosMaisUtilizados.length,
        },
      };
    } catch (e) {
      Logger.error('❌ Erro ao gerar insights: $e');
      rethrow;
    }
  }
}
