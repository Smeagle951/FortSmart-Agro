import '../models/produto_estoque.dart';
import '../models/aplicacao.dart';
import '../models/talhao_model.dart';
import '../database/daos/produto_estoque_dao.dart';
import '../database/daos/aplicacao_dao.dart';
import '../utils/logger.dart';

/// Serviço de Gestão de Custos - Integra todos os módulos para cálculo automático
class GestaoCustosService {
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();
  final AplicacaoDao _aplicacaoDao = AplicacaoDao();

  /// Registra uma aplicação com cálculo automático de custos
  Future<bool> registrarAplicacao({
    required String talhaoId,
    required String produtoId,
    required double dosePorHa,
    required double areaAplicadaHa,
    required DateTime dataAplicacao,
    String? operador,
    String? equipamento,
    String? condicoesClimaticas,
    String? observacoes,
    String? fazendaId,
  }) async {
    try {
      Logger.info('💰 Iniciando registro de aplicação com cálculo de custos...');

      // 1. Buscar produto para obter preço atual
      final produto = await _produtoDao.getById(produtoId);
      if (produto == null) {
        Logger.error('❌ Produto não encontrado: $produtoId');
        return false;
      }

      // 2. Verificar se há estoque suficiente
      final quantidadeNecessaria = dosePorHa * areaAplicadaHa;
      if (produto.saldoAtual < quantidadeNecessaria) {
        Logger.error('❌ Estoque insuficiente: necessário $quantidadeNecessaria, disponível ${produto.saldoAtual}');
        return false;
      }

      // 3. Criar aplicação com custos calculados
      final aplicacao = Aplicacao(
        talhaoId: talhaoId,
        produtoId: produtoId,
        dosePorHa: dosePorHa,
        areaAplicadaHa: areaAplicadaHa,
        precoUnitarioMomento: produto.precoUnitario,
        dataAplicacao: dataAplicacao,
        operador: operador,
        equipamento: equipamento,
        condicoesClimaticas: condicoesClimaticas,
        observacoes: observacoes,
        fazendaId: fazendaId,
      );

      // 4. Salvar aplicação
      final aplicacaoSalva = await _aplicacaoDao.save(aplicacao);
      if (aplicacaoSalva == null) {
        Logger.error('❌ Erro ao salvar aplicação');
        return false;
      }

      // 5. Atualizar estoque (saída automática)
      final novoSaldo = produto.saldoAtual - quantidadeNecessaria;
      final estoqueAtualizado = await _produtoDao.atualizarSaldo(produtoId, novoSaldo);
      if (!estoqueAtualizado) {
        Logger.error('❌ Erro ao atualizar estoque');
        return false;
      }

      Logger.info('✅ Aplicação registrada com sucesso!');
      Logger.info('📊 Custos calculados: R\$ ${aplicacao.custoTotal.toStringAsFixed(2)} total, R\$ ${aplicacao.custoPorHa.toStringAsFixed(2)}/ha');

      return true;
    } catch (e) {
      Logger.error('❌ Erro ao registrar aplicação: $e');
      return false;
    }
  }

  /// Calcula custos por talhão
  Future<Map<String, dynamic>> calcularCustosPorTalhao(String talhaoId) async {
    try {
      Logger.info('💰 Calculando custos para talhão: $talhaoId');

      // Buscar todas as aplicações do talhão
      final aplicacoes = await _aplicacaoDao.buscarPorTalhao(talhaoId);
      
      if (aplicacoes.isEmpty) {
        return {
          'talhao_id': talhaoId,
          'total_aplicacoes': 0,
          'custo_total': 0.0,
          'custo_medio_por_ha': 0.0,
          'aplicacoes': [],
        };
      }

      // Calcular totais
      final custoTotal = aplicacoes.fold<double>(0.0, (sum, app) => sum + app.custoTotal);
      final custoMedioPorHa = aplicacoes.fold<double>(0.0, (sum, app) => sum + app.custoPorHa) / aplicacoes.length;

      return {
        'talhao_id': talhaoId,
        'total_aplicacoes': aplicacoes.length,
        'custo_total': custoTotal,
        'custo_medio_por_ha': custoMedioPorHa,
        'aplicacoes': aplicacoes.map((app) => app.toMap()).toList(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao calcular custos por talhão: $e');
      return {
        'talhao_id': talhaoId,
        'total_aplicacoes': 0,
        'custo_total': 0.0,
        'custo_medio_por_ha': 0.0,
        'aplicacoes': [],
        'erro': e.toString(),
      };
    }
  }

  /// Calcula custos por período
  Future<Map<String, dynamic>> calcularCustosPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoId,
  }) async {
    try {
      Logger.info('💰 Calculando custos por período: ${dataInicio.toIso8601String()} até ${dataFim.toIso8601String()}');

      // Buscar aplicações no período
      final aplicacoes = await _aplicacaoDao.buscarPorPeriodo(
        dataInicio: dataInicio,
        dataFim: dataFim,
        talhaoId: talhaoId,
      );

      if (aplicacoes.isEmpty) {
        return {
          'periodo_inicio': dataInicio.toIso8601String(),
          'periodo_fim': dataFim.toIso8601String(),
          'total_aplicacoes': 0,
          'custo_total': 0.0,
          'custo_medio_por_ha': 0.0,
          'aplicacoes_por_talhao': {},
        };
      }

      // Agrupar por talhão
      final aplicacoesPorTalhao = <String, List<Aplicacao>>{};
      for (final aplicacao in aplicacoes) {
        aplicacoesPorTalhao.putIfAbsent(aplicacao.talhaoId, () => []).add(aplicacao);
      }

      // Calcular custos por talhão
      final custosPorTalhao = <String, Map<String, dynamic>>{};
      double custoTotalPeriodo = 0.0;

      for (final entry in aplicacoesPorTalhao.entries) {
        final talhaoId = entry.key;
        final aplicacoesTalhao = entry.value;

        final custoTotalTalhao = aplicacoesTalhao.fold<double>(0.0, (sum, app) => sum + app.custoTotal);
        final custoMedioPorHa = aplicacoesTalhao.fold<double>(0.0, (sum, app) => sum + app.custoPorHa) / aplicacoesTalhao.length;

        custosPorTalhao[talhaoId] = {
          'total_aplicacoes': aplicacoesTalhao.length,
          'custo_total': custoTotalTalhao,
          'custo_medio_por_ha': custoMedioPorHa,
          'aplicacoes': aplicacoesTalhao.map((app) => app.toMap()).toList(),
        };

        custoTotalPeriodo += custoTotalTalhao;
      }

      return {
        'periodo_inicio': dataInicio.toIso8601String(),
        'periodo_fim': dataFim.toIso8601String(),
        'total_aplicacoes': aplicacoes.length,
        'custo_total_periodo': custoTotalPeriodo,
        'custo_medio_por_ha_periodo': custoTotalPeriodo / aplicacoes.length,
        'aplicacoes_por_talhao': custosPorTalhao,
      };
    } catch (e) {
      Logger.error('❌ Erro ao calcular custos por período: $e');
      return {
        'periodo_inicio': dataInicio.toIso8601String(),
        'periodo_fim': dataFim.toIso8601String(),
        'total_aplicacoes': 0,
        'custo_total_periodo': 0.0,
        'custo_medio_por_ha_periodo': 0.0,
        'aplicacoes_por_talhao': {},
        'erro': e.toString(),
      };
    }
  }

  /// Obtém relatório de produtos mais utilizados
  Future<List<Map<String, dynamic>>> obterProdutosMaisUtilizados() async {
    try {
      Logger.info('💰 Gerando relatório de produtos mais utilizados...');

      final aplicacoes = await _aplicacaoDao.buscarTodas();
      
      // Agrupar por produto
      final produtosUtilizados = <String, Map<String, dynamic>>{};
      
      for (final aplicacao in aplicacoes) {
        final produtoId = aplicacao.produtoId;
        
        if (!produtosUtilizados.containsKey(produtoId)) {
          final produto = await _produtoDao.getById(produtoId);
          produtosUtilizados[produtoId] = {
            'produto_id': produtoId,
            'nome_produto': produto?.nome ?? 'Produto não encontrado',
            'tipo_produto': produto?.tipo.name ?? 'outro',
            'unidade': produto?.unidade ?? '',
            'total_aplicacoes': 0,
            'quantidade_total_usada': 0.0,
            'custo_total': 0.0,
          };
        }

        final produto = produtosUtilizados[produtoId]!;
        produto['total_aplicacoes'] = (produto['total_aplicacoes'] as int) + 1;
        produto['quantidade_total_usada'] = (produto['quantidade_total_usada'] as double) + aplicacao.quantidadeTotal;
        produto['custo_total'] = (produto['custo_total'] as double) + aplicacao.custoTotal;
      }

      // Ordenar por custo total
      final listaOrdenada = produtosUtilizados.values.toList();
      listaOrdenada.sort((a, b) => (b['custo_total'] as double).compareTo(a['custo_total'] as double));

      return listaOrdenada;
    } catch (e) {
      Logger.error('❌ Erro ao obter produtos mais utilizados: $e');
      return [];
    }
  }

  /// Obtém alertas de estoque
  Future<Map<String, dynamic>> obterAlertasEstoque() async {
    try {
      Logger.info('💰 Verificando alertas de estoque...');

      final produtosEstoqueBaixo = await _produtoDao.buscarComEstoqueBaixo();
      final produtosProximosVencimento = await _produtoDao.buscarVencidosOuProximosVencimento();

      return {
        'estoque_baixo': produtosEstoqueBaixo.map((p) => p.toMap()).toList(),
        'proximos_vencimento': produtosProximosVencimento.map((p) => p.toMap()).toList(),
        'total_alertas': produtosEstoqueBaixo.length + produtosProximosVencimento.length,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter alertas de estoque: $e');
      return {
        'estoque_baixo': [],
        'proximos_vencimento': [],
        'total_alertas': 0,
        'erro': e.toString(),
      };
    }
  }

  /// Simula custo de uma aplicação futura
  Future<Map<String, dynamic>> simularCustoAplicacao({
    required String produtoId,
    required double dosePorHa,
    required double areaAplicadaHa,
  }) async {
    try {
      Logger.info('💰 Simulando custo de aplicação...');

      final produto = await _produtoDao.getById(produtoId);
      if (produto == null) {
        return {
          'erro': 'Produto não encontrado',
          'custo_total': 0.0,
          'custo_por_ha': 0.0,
          'quantidade_necessaria': 0.0,
        };
      }

      final quantidadeNecessaria = dosePorHa * areaAplicadaHa;
      final custoTotal = quantidadeNecessaria * produto.precoUnitario;
      final custoPorHa = custoTotal / areaAplicadaHa;

      return {
        'produto': produto.toMap(),
        'dose_por_ha': dosePorHa,
        'area_aplicada_ha': areaAplicadaHa,
        'quantidade_necessaria': quantidadeNecessaria,
        'custo_total': custoTotal,
        'custo_por_ha': custoPorHa,
        'estoque_suficiente': produto.saldoAtual >= quantidadeNecessaria,
        'saldo_atual': produto.saldoAtual,
      };
    } catch (e) {
      Logger.error('❌ Erro ao simular custo de aplicação: $e');
      return {
        'erro': e.toString(),
        'custo_total': 0.0,
        'custo_por_ha': 0.0,
        'quantidade_necessaria': 0.0,
      };
    }
  }

  /// Obtém produtos disponíveis no estoque
  Future<List<Map<String, dynamic>>> getProdutosDisponiveis() async {
    try {
      Logger.info('💰 Obtendo produtos disponíveis no estoque...');
      
      final produtos = await _produtoDao.getAll();
      
      return produtos.map((produto) => {
        'id': produto.id,
        'nome': produto.nome,
        'tipo': produto.tipo.name,
        'unidade': produto.unidade,
        'saldo_atual': produto.saldoAtual,
        'preco_unitario': produto.precoUnitario,
        'data_vencimento': null,
        'descricao': '',
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter produtos disponíveis: $e');
      return [];
    }
  }

  /// Calcula aplicação com validação de estoque
  Future<Map<String, dynamic>> calcularAplicacao({
    required String produtoId,
    required double dosePorHa,
    required double areaAplicadaHa,
  }) async {
    try {
      Logger.info('💰 Calculando aplicação...');
      
      final produto = await _produtoDao.getById(produtoId);
      if (produto == null) {
        return {
          'erro': 'Produto não encontrado',
          'sucesso': false,
        };
      }

      final quantidadeNecessaria = dosePorHa * areaAplicadaHa;
      final custoTotal = quantidadeNecessaria * produto.precoUnitario;
      final custoPorHa = custoTotal / areaAplicadaHa;
      final estoqueSuficiente = produto.saldoAtual >= quantidadeNecessaria;

      return {
        'produto': produto.toMap(),
        'dose_por_ha': dosePorHa,
        'area_aplicada_ha': areaAplicadaHa,
        'quantidade_necessaria': quantidadeNecessaria,
        'custo_total': custoTotal,
        'custo_por_ha': custoPorHa,
        'estoque_suficiente': estoqueSuficiente,
        'saldo_atual': produto.saldoAtual,
        'sucesso': true,
      };
    } catch (e) {
      Logger.error('❌ Erro ao calcular aplicação: $e');
      return {
        'erro': e.toString(),
        'sucesso': false,
      };
    }
  }

  /// Valida estoque para uma aplicação
  Future<Map<String, dynamic>> validarEstoque(Map<String, dynamic> calculo) async {
    try {
      Logger.info('💰 Validando estoque...');
      
      final produtoId = calculo['produto']['id'];
      final quantidadeNecessaria = calculo['quantidade_necessaria'];
      
      final produto = await _produtoDao.getById(produtoId);
      if (produto == null) {
        return {
          'valido': false,
          'erro': 'Produto não encontrado',
        };
      }

      final estoqueSuficiente = produto.saldoAtual >= quantidadeNecessaria;
      
      return {
        'valido': estoqueSuficiente,
        'saldo_atual': produto.saldoAtual,
        'quantidade_necessaria': quantidadeNecessaria,
        'erro': estoqueSuficiente ? null : 'Estoque insuficiente',
      };
    } catch (e) {
      Logger.error('❌ Erro ao validar estoque: $e');
      return {
        'valido': false,
        'erro': e.toString(),
      };
    }
  }


}
