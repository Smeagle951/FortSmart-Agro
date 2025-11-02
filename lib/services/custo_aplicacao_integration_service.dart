import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/aplicacao.dart';
import '../models/talhao_model.dart';
import '../models/cultura_model.dart';
import '../models/produto_estoque.dart';
import '../modules/cost_management/models/cost_management_model.dart';
import '../database/daos/aplicacao_dao.dart';
import '../database/daos/produto_estoque_dao.dart';
import '../repositories/talhao_repository.dart';
import '../repositories/crop_repository.dart';
import '../utils/logger.dart';

/// Serviço de integração para sistema de custos por hectare
class CustoAplicacaoIntegrationService {
  static final CustoAplicacaoIntegrationService _instance = CustoAplicacaoIntegrationService._internal();
  factory CustoAplicacaoIntegrationService() => _instance;
  CustoAplicacaoIntegrationService._internal();

  final AplicacaoDao _aplicacaoDao = AplicacaoDao();
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final CropRepository _cropRepository = CropRepository();

  /// Registra uma aplicação completa com cálculo de custos e integração
  Future<Map<String, dynamic>> registrarAplicacaoCompleta({
    required CostManagementModel calculo,
    required String operador,
    required String equipamento,
    String? condicoesClimaticas,
    String? observacoes,
  }) async {
    try {
      Logger.info('💰 Iniciando registro de aplicação com custos...');

      // 1. Validar estoque
      final validacaoEstoque = await _validarEstoqueParaAplicacao(calculo);
      if (!validacaoEstoque['estoque_suficiente']) {
        return {
          'sucesso': false,
          'erro': 'Estoque insuficiente',
          'detalhes': validacaoEstoque['produtos_insuficientes'],
        };
      }

      // 2. Registrar aplicações individuais para cada produto
      final aplicacoesRegistradas = <Aplicacao>[];
      for (final produto in calculo.produtos) {
        final aplicacao = Aplicacao(
          talhaoId: calculo.talhaoId,
          produtoId: produto.id,
          dosePorHa: produto.dosePorHa,
          areaAplicadaHa: calculo.areaHa,
          precoUnitarioMomento: produto.precoUnitario,
          dataAplicacao: calculo.dataAplicacao,
          operador: operador,
          equipamento: equipamento,
          condicoesClimaticas: condicoesClimaticas,
          observacoes: observacoes,
          fazendaId: calculo.talhaoId, // Usar talhaoId como fazendaId temporariamente
        );

        final aplicacaoId = await _aplicacaoDao.insert(aplicacao);
        if (aplicacaoId.isNotEmpty) {
          aplicacoesRegistradas.add(aplicacao);
        }
      }

      // 3. Debitar estoque
      final estoqueDebitado = await _debitarEstoqueAplicacao(calculo);
      if (!estoqueDebitado) {
        Logger.error('❌ Erro ao debitar estoque');
        return {
          'sucesso': false,
          'erro': 'Erro ao debitar estoque',
        };
      }

      // 4. Registrar no histórico de talhão
      await _registrarNoHistoricoTalhao(calculo, aplicacoesRegistradas);

      Logger.info('✅ Aplicação registrada com sucesso!');
      Logger.info('📊 Custos: R\$ ${calculo.custoTotal.toStringAsFixed(2)} total, R\$ ${calculo.custoPorHectare.toStringAsFixed(2)}/ha');

      return {
        'sucesso': true,
        'aplicacoes_registradas': aplicacoesRegistradas.length,
        'custo_total': calculo.custoTotal,
        'custo_por_hectare': calculo.custoPorHectare,
        'volume_calda_total': 0.0, // Valor padrão
        'tanques_necessarios': 1, // Valor padrão
      };
    } catch (e) {
      Logger.error('❌ Erro ao registrar aplicação: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
      };
    }
  }

  /// Carrega talhões reais do banco de dados
  Future<List<TalhaoModel>> carregarTalhoes() async {
    try {
      Logger.info('🔄 Carregando talhões...');
      final talhoes = await _talhaoRepository.loadTalhoes();
      Logger.info('✅ ${talhoes.length} talhões carregados');
      return talhoes;
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhões: $e');
      return [];
    }
  }

  /// Carrega culturas reais do banco de dados
  Future<List<CulturaModel>> carregarCulturas() async {
    try {
      Logger.info('🔄 Carregando culturas...');
      // Usar o repositório de culturas para obter dados reais
      final culturas = await _cropRepository.getAllCrops();
      // Converter para CulturaModel se necessário
      return culturas.map<CulturaModel>((crop) => CulturaModel(
        id: crop.id.toString(),
        name: crop.name,
        scientificName: crop.scientificName ?? '',
        description: crop.description ?? '',
        color: Colors.green,
      )).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      return [];
    }
  }

  /// Carrega produtos de estoque reais do banco de dados
  Future<List<ProdutoEstoque>> carregarProdutos() async {
    try {
      Logger.info('🔄 Carregando produtos de estoque...');
      final produtos = await _produtoDao.buscarTodos();
      Logger.info('✅ ${produtos.length} produtos carregados');
      return produtos;
    } catch (e) {
      Logger.error('❌ Erro ao carregar produtos: $e');
      return [];
    }
  }

  /// Carrega aplicações reais do banco de dados
  Future<List<Aplicacao>> carregarAplicacoes({
    String? talhaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Logger.info('🔄 Carregando aplicações...');
      
      if (talhaoId != null) {
        return await _aplicacaoDao.buscarPorTalhao(talhaoId);
      } else if (dataInicio != null && dataFim != null) {
        return await _aplicacaoDao.buscarPorPeriodo(
          dataInicio: dataInicio,
          dataFim: dataFim,
        );
      } else {
        return await _aplicacaoDao.buscarTodas();
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar aplicações: $e');
      return [];
    }
  }

  /// Valida estoque para uma aplicação
  Future<Map<String, dynamic>> _validarEstoqueParaAplicacao(CostManagementModel calculo) async {
    final produtosInsuficientes = <String>[];
    
    for (final produto in calculo.produtos) {
      final totalNecessario = calculo.calcularTotalProduto(produto);
      
      // Buscar produto real no banco
      final produtoReal = await _produtoDao.getById(produto.id);
      if (produtoReal == null) {
        produtosInsuficientes.add('${produto.nome} (produto não encontrado)');
        continue;
      }
      
      if (produtoReal.saldoAtual < totalNecessario) {
        produtosInsuficientes.add('${produto.nome} (necessário: $totalNecessario${produto.unidade}, disponível: ${produtoReal.saldoAtual}${produto.unidade})');
      }
    }

    return {
      'estoque_suficiente': produtosInsuficientes.isEmpty,
      'produtos_insuficientes': produtosInsuficientes,
    };
  }

  /// Debita estoque após aplicação
  Future<bool> _debitarEstoqueAplicacao(CostManagementModel calculo) async {
    try {
      for (final produto in calculo.produtos) {
        final totalNecessario = calculo.calcularTotalProduto(produto);
        
        // Buscar produto real no banco
        final produtoReal = await _produtoDao.getById(produto.id);
        if (produtoReal == null) {
          Logger.error('❌ Produto não encontrado: ${produto.nome}');
          return false;
        }
        
        final novoSaldo = produtoReal.saldoAtual - totalNecessario;
        if (novoSaldo < 0) {
          Logger.error('❌ Saldo insuficiente para produto: ${produto.nome}');
          return false;
        }
        
        final estoqueAtualizado = await _produtoDao.atualizarSaldo(produto.id, novoSaldo);
        if (!estoqueAtualizado) {
          Logger.error('❌ Erro ao atualizar estoque do produto: ${produto.nome}');
          return false;
        }
        
        Logger.info('✅ Estoque debitado: ${produto.nome} - ${totalNecessario}${produto.unidade}');
      }
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao debitar estoque: $e');
      return false;
    }
  }

  /// Registra aplicação no histórico do talhão
  Future<void> _registrarNoHistoricoTalhao(CostManagementModel calculo, List<Aplicacao> aplicacoes) async {
    try {
      // Aqui você pode integrar com o sistema de histórico de talhões
      // Por enquanto, vamos apenas logar
      Logger.info('📝 Registrando no histórico do talhão: ${calculo.talhaoId}');
      Logger.info('   - Custo total: R\$ ${calculo.custoTotal.toStringAsFixed(2)}');
      Logger.info('   - Produtos aplicados: ${aplicacoes.length}');
    } catch (e) {
      Logger.error('❌ Erro ao registrar no histórico: $e');
    }
  }

  /// Calcula custos por talhão
  Future<Map<String, dynamic>> calcularCustosPorTalhao(String talhaoId) async {
    try {
      Logger.info('💰 Calculando custos para talhão: $talhaoId');

      final List<Aplicacao> aplicacoes = await _aplicacaoDao.buscarPorTalhao(talhaoId);
      
      if (aplicacoes.isEmpty) {
        return {
          'talhao_id': talhaoId,
          'total_aplicacoes': 0,
          'custo_total': 0.0,
          'custo_medio_por_ha': 0.0,
          'aplicacoes': [],
        };
      }

      final custoTotal = aplicacoes.fold<double>(0.0, (sum, app) => sum + app.custoTotal);
      final areaTotal = aplicacoes.fold<double>(0.0, (sum, app) => sum + app.areaAplicadaHa);
      final custoMedioPorHa = areaTotal > 0 ? custoTotal / areaTotal : 0.0;

      return {
        'talhao_id': talhaoId,
        'total_aplicacoes': aplicacoes.length,
        'custo_total': custoTotal,
        'custo_medio_por_ha': custoMedioPorHa,
        'area_total_aplicada': areaTotal,
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

      final List<Aplicacao> aplicacoes = await _aplicacaoDao.buscarPorPeriodo(
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
      double areaTotalPeriodo = 0.0;

      for (final entry in aplicacoesPorTalhao.entries) {
        final talhaoId = entry.key;
        final aplicacoesTalhao = entry.value;

        final custoTotalTalhao = aplicacoesTalhao.fold<double>(0.0, (sum, app) => sum + app.custoTotal);
        final areaTotalTalhao = aplicacoesTalhao.fold<double>(0.0, (sum, app) => sum + app.areaAplicadaHa);
        final custoMedioPorHaTalhao = areaTotalTalhao > 0 ? custoTotalTalhao / areaTotalTalhao : 0.0;

        custosPorTalhao[talhaoId] = {
          'total_aplicacoes': aplicacoesTalhao.length,
          'custo_total': custoTotalTalhao,
          'custo_medio_por_ha': custoMedioPorHaTalhao,
          'area_total': areaTotalTalhao,
          'aplicacoes': aplicacoesTalhao.map((app) => app.toMap()).toList(),
        };

        custoTotalPeriodo += custoTotalTalhao;
        areaTotalPeriodo += areaTotalTalhao;
      }

      final custoMedioPorHaPeriodo = areaTotalPeriodo > 0 ? custoTotalPeriodo / areaTotalPeriodo : 0.0;

      return {
        'periodo_inicio': dataInicio.toIso8601String(),
        'periodo_fim': dataFim.toIso8601String(),
        'total_aplicacoes': aplicacoes.length,
        'custo_total': custoTotalPeriodo,
        'custo_medio_por_ha': custoMedioPorHaPeriodo,
        'area_total': areaTotalPeriodo,
        'aplicacoes_por_talhao': custosPorTalhao,
      };
    } catch (e) {
      Logger.error('❌ Erro ao calcular custos por período: $e');
      return {
        'periodo_inicio': dataInicio.toIso8601String(),
        'periodo_fim': dataFim.toIso8601String(),
        'total_aplicacoes': 0,
        'custo_total': 0.0,
        'custo_medio_por_ha': 0.0,
        'aplicacoes_por_talhao': {},
        'erro': e.toString(),
      };
    }
  }

  /// Simula custo de uma aplicação futura
  Future<Map<String, dynamic>> simularCustoAplicacao({
    required List<Map<String, dynamic>> produtos,
    required double areaHa,
  }) async {
    try {
      Logger.info('💰 Simulando custo de aplicação para ${areaHa}ha');

      double custoTotal = 0.0;
      final detalhesProdutos = <Map<String, dynamic>>[];

      for (final produto in produtos) {
        final dose = produto['dose'] ?? 0.0;
        final precoUnitario = produto['precoUnitario'] ?? 0.0;
        final quantidadeNecessaria = dose * areaHa;
        final custoProduto = quantidadeNecessaria * precoUnitario;
        custoTotal += custoProduto;

        detalhesProdutos.add({
          'produto': produto['nome'] ?? 'Produto',
          'dose_ha': dose,
          'unidade': produto['unidade'] ?? '',
          'quantidade_necessaria': quantidadeNecessaria,
          'custo_produto': custoProduto,
          'custo_ha': custoProduto / areaHa,
          'estoque_suficiente': true, // Valor padrão
          'saldo_atual': produto['estoqueAtual'] ?? 0.0,
        });
      }

      final custoPorHa = areaHa > 0 ? custoTotal / areaHa : 0.0;

      return {
        'area_ha': areaHa,
        'custo_total': custoTotal,
        'custo_por_ha': custoPorHa,
        'produtos': detalhesProdutos,
        'total_produtos': produtos.length,
      };
    } catch (e) {
      Logger.error('❌ Erro ao simular custo de aplicação: $e');
      return {
        'erro': e.toString(),
        'custo_total': 0.0,
        'custo_por_ha': 0.0,
        'produtos': [],
      };
    }
  }

  /// Gera relatório de custos
  Future<Map<String, dynamic>> gerarRelatorioCustos({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? talhaoId,
  }) async {
    try {
      Logger.info('📊 Gerando relatório de custos...');

      final custosPeriodo = await calcularCustosPorPeriodo(
        dataInicio: dataInicio ?? DateTime.now().subtract(Duration(days: 30)),
        dataFim: dataFim ?? DateTime.now(),
        talhaoId: talhaoId,
      );

      return {
        'relatorio': {
          'titulo': 'Relatório de Custos por Aplicação',
          'periodo': {
            'inicio': custosPeriodo['periodo_inicio'],
            'fim': custosPeriodo['periodo_fim'],
          },
          'resumo': {
            'total_aplicacoes': custosPeriodo['total_aplicacoes'],
            'custo_total': custosPeriodo['custo_total'],
            'custo_medio_por_ha': custosPeriodo['custo_medio_por_ha'],
            'area_total': custosPeriodo['area_total'],
          },
          'detalhes_por_talhao': custosPeriodo['aplicacoes_por_talhao'],
        },
        'gerado_em': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
      return {
        'erro': e.toString(),
        'relatorio': null,
      };
    }
  }
}
