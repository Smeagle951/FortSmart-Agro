import 'package:uuid/uuid.dart';
import '../models/cost_simulation_model.dart';
import '../../../../models/produto_estoque.dart';
import '../../../../models/talhao_model.dart';
import '../../../../database/daos/produto_estoque_dao.dart';
import '../../../../utils/logger.dart';

class CostSimulationService {
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();
  final Uuid _uuid = Uuid();

  /// Simula custos para uma aplicação futura
  Future<CostSimulationModel?> simularCustos({
    required String talhaoId,
    required String talhaoNome,
    required double areaHa,
    required List<Map<String, dynamic>> produtosSimulacao,
    String observacoes = '',
  }) async {
    try {
      Logger.info('💰 Iniciando simulação de custos...');

      List<SimulationProduct> produtosCalculados = [];
      double custoTotal = 0.0;

      // Calcular custos para cada produto
      for (final produtoSim in produtosSimulacao) {
        final produtoId = produtoSim['produto_id'] as String;
        final dosePorHa = (produtoSim['dose_por_ha'] ?? 0.0).toDouble();

        // Buscar produto no estoque
        final produto = await _produtoDao.getById(produtoId);
        if (produto == null) {
          Logger.warning('⚠️ Produto não encontrado: $produtoId');
          continue;
        }

        // Calcular quantidade total necessária
        final quantidadeTotal = dosePorHa * areaHa;
        final custoProduto = quantidadeTotal * produto.precoUnitario;

        produtosCalculados.add(SimulationProduct(
          produtoId: produtoId,
          nomeProduto: produto.nome,
          tipoProduto: produto.tipo.name,
          unidade: produto.unidade,
          dosePorHa: dosePorHa,
          quantidadeTotal: quantidadeTotal,
          precoUnitario: produto.precoUnitario,
          custoTotal: custoProduto,
        ));

        custoTotal += custoProduto;
      }

      final custoPorHectare = areaHa > 0 ? custoTotal / areaHa : 0.0;

      final simulacao = CostSimulationModel(
        id: _uuid.v4(),
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        areaHa: areaHa,
        produtos: produtosCalculados,
        dataSimulacao: DateTime.now(),
        custoTotal: custoTotal,
        custoPorHectare: custoPorHectare,
        observacoes: observacoes,
      );

      Logger.info('✅ Simulação concluída: R\$ ${custoTotal.toStringAsFixed(2)}');
      return simulacao;
    } catch (e) {
      Logger.error('❌ Erro na simulação: $e');
      return null;
    }
  }

  /// Obtém produtos disponíveis para simulação
  Future<List<ProdutoEstoque>> obterProdutosDisponiveis() async {
    try {
      final produtos = await _produtoDao.getAll();
      return produtos.where((p) => p.saldoAtual > 0).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos: $e');
      return [];
    }
  }

  /// Valida se há estoque suficiente para a simulação
  Future<Map<String, dynamic>> validarEstoque({
    required List<Map<String, dynamic>> produtosSimulacao,
    required double areaHa,
  }) async {
    try {
      Map<String, dynamic> resultado = {
        'valido': true,
        'produtos_insuficientes': [],
        'total_necessario': 0.0,
        'total_disponivel': 0.0,
      };

      for (final produtoSim in produtosSimulacao) {
        final produtoId = produtoSim['produto_id'] as String;
        final dosePorHa = (produtoSim['dose_por_ha'] ?? 0.0).toDouble();

        final produto = await _produtoDao.getById(produtoId);
        if (produto == null) continue;

        final quantidadeNecessaria = dosePorHa * areaHa;
        resultado['total_necessario'] += quantidadeNecessaria;
        resultado['total_disponivel'] += produto.saldoAtual;

        if (produto.saldoAtual < quantidadeNecessaria) {
          resultado['valido'] = false;
          resultado['produtos_insuficientes'].add({
            'produto': produto.nome,
            'necessario': quantidadeNecessaria,
            'disponivel': produto.saldoAtual,
            'faltante': quantidadeNecessaria - produto.saldoAtual,
          });
        }
      }

      return resultado;
    } catch (e) {
      Logger.error('❌ Erro na validação: $e');
      return {'valido': false, 'erro': e.toString()};
    }
  }
}
