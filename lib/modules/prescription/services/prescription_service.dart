import 'package:uuid/uuid.dart';
import '../models/prescription_model.dart' as prescription_model;
import '../daos/prescription_dao.dart';
import '../../../models/talhao_model.dart';
import '../../../models/cultura_model.dart';
import '../../../models/produto_estoque.dart';
import '../../../database/daos/produto_estoque_dao.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../services/talhao_unified_service.dart';
import '../../../services/cultura_service.dart';
import '../../../utils/logger.dart';

/// Serviço principal de prescrição agrícola com integração de custos
class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final PrescriptionDao _prescriptionDao = PrescriptionDao();
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final TalhaoUnifiedService _talhaoUnifiedService = TalhaoUnifiedService();
  final CulturaService _culturaService = CulturaService();
  final Uuid _uuid = Uuid();

  /// Cria uma nova prescrição com cálculos automáticos
  Future<Map<String, dynamic>> criarPrescricao({
    required String talhaoId,
    required prescription_model.TipoAplicacao tipoAplicacao,
    String? equipamento,
    required double capacidadeTanque,
    required double vazaoPorHectare,
    required bool doseFracionada,
    String? bicoSelecionado,
    required double vazaoBico,
    required double pressaoBico,
    required List<prescription_model.PrescriptionProduct> produtos,
    required String operador,
    String? observacoes,
    String? talhaoNome,
    double? areaTalhao,
  }) async {
    try {
      Logger.info('📋 Criando nova prescrição...');

      // 1. Buscar dados do talhão ou usar dados manuais
      TalhaoModel talhao;
      if (talhaoId.startsWith('MANUAL_')) {
        // Talhão manual - criar objeto temporário
        talhao = TalhaoModel(
          id: talhaoId,
          name: talhaoNome ?? 'Área Manual',
          area: areaTalhao ?? 0.0,
          fazendaId: 'manual',
          culturaId: null,
          crop: null,
          safraId: null,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          poligonos: [],
          safras: [],
          observacoes: 'Aplicação fora de talhão cadastrado',
        );
        Logger.info('📋 Usando talhão manual: ${talhao.name} (${talhao.area} ha)');
      } else {
        // Talhão real - buscar no repositório
        final talhoes = await _talhaoRepository.loadTalhoes();
        talhao = talhoes.firstWhere((t) => t.id == talhaoId);
        Logger.info('📋 Usando talhão real: ${talhao.name} (${talhao.area} ha)');
      }
      
      // 2. Calcular volume total da calda
      final volumeTotalCalda = talhao.area * vazaoPorHectare;
      
      // 3. Calcular número de tanques
      final numeroTanques = (volumeTotalCalda / capacidadeTanque).ceil();
      
      // 4. Calcular custos
      final custoTotal = produtos.fold(0.0, (total, produto) {
        final quantidadeTotal = produto.dosePorHectare * talhao.area;
        return total + (quantidadeTotal * produto.precoUnitario);
      });
      
      final custoPorHectare = talhao.area > 0 ? custoTotal / talhao.area : 0.0;

      // 5. Criar prescrição
      final prescricao = prescription_model.PrescriptionModel(
        id: _uuid.v4(),
        talhaoId: talhaoId,
        talhaoNome: talhao.nome,
        areaTalhao: talhao.area,
        tipoAplicacao: tipoAplicacao,
        equipamento: equipamento,
        capacidadeTanque: capacidadeTanque,
        vazaoPorHectare: vazaoPorHectare,
        doseFracionada: doseFracionada,
        bicoSelecionado: bicoSelecionado,
        vazaoBico: vazaoBico,
        pressaoBico: pressaoBico,
        produtos: produtos,
        dataPrescricao: DateTime.now(),
        operador: operador,
        observacoes: observacoes,
        status: prescription_model.StatusPrescricao.pendente,
        volumeTotalCalda: volumeTotalCalda,
        numeroTanques: numeroTanques,
        custoTotal: custoTotal,
        custoPorHectare: custoPorHectare,
      );

      // 6. Salvar no banco
      await _prescriptionDao.insert(prescricao);

      // 7. Validar estoque
      final validacaoEstoque = await _validarEstoquePrescricao(prescricao);

      Logger.info('✅ Prescrição criada com sucesso!');
      Logger.info('📊 Volume total: ${volumeTotalCalda.toStringAsFixed(1)} L');
      Logger.info('📊 Número de tanques: $numeroTanques');
      Logger.info('💰 Custo total: R\$ ${custoTotal.toStringAsFixed(2)}');
      Logger.info('💰 Custo por hectare: R\$ ${custoPorHectare.toStringAsFixed(2)}');

      return {
        'sucesso': true,
        'prescricao': prescricao,
        'validacao_estoque': validacaoEstoque,
        'calculos': {
          'volume_total_calda': volumeTotalCalda,
          'numero_tanques': numeroTanques,
          'custo_total': custoTotal,
          'custo_por_hectare': custoPorHectare,
        },
      };
    } catch (e) {
      Logger.error('❌ Erro ao criar prescrição: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
      };
    }
  }

  /// Carrega todas as prescrições
  Future<List<prescription_model.PrescriptionModel>> carregarPrescricoes() async {
    try {
      Logger.info('🔄 Carregando prescrições...');
      final prescricoes = await _prescriptionDao.getAll();
      Logger.info('✅ ${prescricoes.length} prescrições carregadas');
      return prescricoes;
    } catch (e) {
      Logger.error('❌ Erro ao carregar prescrições: $e');
      return [];
    }
  }

  /// Carrega prescrições por talhão
  Future<List<prescription_model.PrescriptionModel>> carregarPrescricoesPorTalhao(String talhaoId) async {
    try {
      Logger.info('🔄 Carregando prescrições do talhão: $talhaoId');
      final prescricoes = await _prescriptionDao.getByTalhao(talhaoId);
      Logger.info('✅ ${prescricoes.length} prescrições carregadas');
      return prescricoes;
    } catch (e) {
      Logger.error('❌ Erro ao carregar prescrições do talhão: $e');
      return [];
    }
  }

  /// Carrega prescrições por status
  Future<List<prescription_model.PrescriptionModel>> carregarPrescricoesPorStatus(prescription_model.StatusPrescricao status) async {
    try {
      Logger.info('🔄 Carregando prescrições com status: ${status.displayName}');
      final prescricoes = await _prescriptionDao.getByStatus(status);
      Logger.info('✅ ${prescricoes.length} prescrições carregadas');
      return prescricoes;
    } catch (e) {
      Logger.error('❌ Erro ao carregar prescrições por status: $e');
      return [];
    }
  }

  /// Carrega talhões disponíveis
  Future<List<TalhaoModel>> carregarTalhoes() async {
    try {
      Logger.info('🔄 Carregando talhões para prescrição...');
      
      // Tentar múltiplas estratégias para carregar talhões
      List<TalhaoModel> talhoes = [];
      
      try {
        // Estratégia 1: Usar serviço unificado
        talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
          nomeModulo: 'PRESCRICAO',
          forceRefresh: true,
        );
        Logger.info('✅ ${talhoes.length} talhões carregados via serviço unificado');
      } catch (e) {
        Logger.warning('⚠️ Erro no serviço unificado: $e');
        
        try {
          // Estratégia 2: Usar repositório diretamente
          talhoes = await _talhaoRepository.loadTalhoes();
          Logger.info('✅ ${talhoes.length} talhões carregados via repositório');
        } catch (e2) {
          Logger.warning('⚠️ Erro no repositório: $e2');
          
          try {
            // Estratégia 3: Usar serviço unificado com módulo geral
            talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
              nomeModulo: 'GERAL',
              forceRefresh: false,
            );
            Logger.info('✅ ${talhoes.length} talhões carregados via módulo geral');
          } catch (e3) {
            Logger.error('❌ Todas as estratégias falharam: $e3');
            talhoes = [];
          }
        }
      }
      
      Logger.info('✅ Total de ${talhoes.length} talhões carregados para prescrição');
      return talhoes;
    } catch (e) {
      Logger.error('❌ Erro geral ao carregar talhões: $e');
      return [];
    }
  }

  /// Carrega culturas disponíveis
  Future<List<CulturaModel>> carregarCulturas() async {
    try {
      Logger.info('🔄 Carregando culturas para prescrição...');
      final culturas = await _culturaService.loadCulturas();
      Logger.info('✅ ${culturas.length} culturas carregadas para prescrição');
      return culturas;
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      return [];
    }
  }

  /// Carrega produtos de estoque
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

  /// Carrega bicos de pulverização
  Future<List<prescription_model.BicoPulverizacao>> carregarBicos() async {
    try {
      Logger.info('🔄 Carregando bicos de pulverização...');
      final bicos = await _prescriptionDao.getAllBicos();
      Logger.info('✅ ${bicos.length} bicos carregados');
      return bicos;
    } catch (e) {
      Logger.error('❌ Erro ao carregar bicos: $e');
      return [];
    }
  }

  /// Converte produto de estoque para produto de prescrição
  prescription_model.PrescriptionProduct converterProdutoEstoque(ProdutoEstoque produtoEstoque, {
    required double dosePorHectare,
    String? observacoes,
  }) {
    return prescription_model.PrescriptionProduct(
      id: produtoEstoque.id,
      nome: produtoEstoque.nome,
      tipo: _mapearTipoProduto(produtoEstoque.tipo.toString()),
      unidade: produtoEstoque.unidade,
      dosePorHectare: dosePorHectare,
      precoUnitario: produtoEstoque.precoUnitario,
      estoqueAtual: produtoEstoque.saldoAtual,
      categoria: produtoEstoque.tipo.toString(),
      observacoes: observacoes,
    );
  }

  /// Calcula detalhes da prescrição
  Map<String, dynamic> calcularDetalhesPrescricao({
    required double areaTalhao,
    required double vazaoPorHectare,
    required double capacidadeTanque,
    required List<prescription_model.PrescriptionProduct> produtos,
    required bool doseFracionada,
  }) {
    // Volume total da calda
    final volumeTotalCalda = areaTalhao * vazaoPorHectare;
    
    // Número de tanques
    final numeroTanques = (volumeTotalCalda / capacidadeTanque).ceil();
    final tanquesFracionados = volumeTotalCalda / capacidadeTanque;
    
    // Detalhes por produto
    final detalhesProdutos = produtos.map((produto) {
      final quantidadeTotal = produto.dosePorHectare * areaTalhao;
      final quantidadePorTanque = produto.dosePorHectare * (capacidadeTanque / vazaoPorHectare);
      final custoProduto = quantidadeTotal * produto.precoUnitario;
      final estoqueSuficiente = produto.estoqueAtual >= quantidadeTotal;
      final percentualEstoque = produto.estoqueAtual > 0 
          ? (quantidadeTotal / produto.estoqueAtual) * 100 
          : 0.0;

      return {
        'produto': produto,
        'quantidade_total': quantidadeTotal,
        'quantidade_por_tanque': quantidadePorTanque,
        'custo_produto': custoProduto,
        'estoque_suficiente': estoqueSuficiente,
        'percentual_estoque': percentualEstoque,
      };
    }).toList();

    // Custo total
    final custoTotal = detalhesProdutos.fold(0.0, (total, detalhe) {
      return total + (detalhe['custo_produto'] as num).toDouble();
    });

    final custoPorHectare = areaTalhao > 0 ? custoTotal / areaTalhao : 0.0;

    return {
      'volume_total_calda': volumeTotalCalda,
      'numero_tanques': numeroTanques,
      'tanques_fracionados': tanquesFracionados,
      'detalhes_produtos': detalhesProdutos,
      'custo_total': custoTotal,
      'custo_por_hectare': custoPorHectare,
      'dose_fracionada': doseFracionada,
    };
  }

  /// Valida estoque para uma prescrição
  Future<Map<String, dynamic>> _validarEstoquePrescricao(prescription_model.PrescriptionModel prescricao) async {
    final produtosInsuficientes = <Map<String, dynamic>>[];
    final produtosSuficientes = <Map<String, dynamic>>[];

    for (final produto in prescricao.produtos) {
      final quantidadeNecessaria = prescricao.calcularProdutoTotal(produto);
      final estoqueSuficiente = produto.estoqueAtual >= quantidadeNecessaria;
      final percentualEstoque = produto.estoqueAtual > 0 
          ? (quantidadeNecessaria / produto.estoqueAtual) * 100 
          : 0.0;

      final detalhes = {
        'produto': produto,
        'quantidade_necessaria': quantidadeNecessaria,
        'estoque_disponivel': produto.estoqueAtual,
        'estoque_suficiente': estoqueSuficiente,
        'percentual_estoque': percentualEstoque,
      };

      if (estoqueSuficiente) {
        produtosSuficientes.add(detalhes);
      } else {
        produtosInsuficientes.add(detalhes);
      }
    }

    return {
      'estoque_suficiente': produtosInsuficientes.isEmpty,
      'produtos_insuficientes': produtosInsuficientes,
      'produtos_suficientes': produtosSuficientes,
      'total_produtos': prescricao.produtos.length,
      'produtos_com_estoque': produtosSuficientes.length,
      'produtos_sem_estoque': produtosInsuficientes.length,
    };
  }

  /// Aprova uma prescrição
  Future<bool> aprovarPrescricao(String prescricaoId) async {
    try {
      Logger.info('✅ Aprovando prescrição: $prescricaoId');
      final sucesso = await _prescriptionDao.updateStatus(prescricaoId, prescription_model.StatusPrescricao.aprovada);
      
      if (sucesso) {
        Logger.info('✅ Prescrição aprovada com sucesso');
      } else {
        Logger.error('❌ Erro ao aprovar prescrição');
      }
      
      return sucesso;
    } catch (e) {
      Logger.error('❌ Erro ao aprovar prescrição: $e');
      return false;
    }
  }

  /// Marca prescrição como em execução
  Future<bool> iniciarExecucao(String prescricaoId) async {
    try {
      Logger.info('▶️ Iniciando execução da prescrição: $prescricaoId');
      final sucesso = await _prescriptionDao.updateStatus(prescricaoId, prescription_model.StatusPrescricao.em_execucao);
      
      if (sucesso) {
        Logger.info('✅ Execução iniciada com sucesso');
      } else {
        Logger.error('❌ Erro ao iniciar execução');
      }
      
      return sucesso;
    } catch (e) {
      Logger.error('❌ Erro ao iniciar execução: $e');
      return false;
    }
  }

  /// Marca prescrição como executada
  Future<bool> finalizarExecucao(String prescricaoId, String operadorExecucao) async {
    try {
      Logger.info('✅ Finalizando execução da prescrição: $prescricaoId');
      final sucesso = await _prescriptionDao.markAsExecuted(prescricaoId, operadorExecucao);
      
      if (sucesso) {
        // Integrar com sistema de custos
        await _integrarComCustos(prescricaoId);
        Logger.info('✅ Execução finalizada com sucesso');
      } else {
        Logger.error('❌ Erro ao finalizar execução');
      }
      
      return sucesso;
    } catch (e) {
      Logger.error('❌ Erro ao finalizar execução: $e');
      return false;
    }
  }

  /// Cancela uma prescrição
  Future<bool> cancelarPrescricao(String prescricaoId) async {
    try {
      Logger.info('❌ Cancelando prescrição: $prescricaoId');
      final sucesso = await _prescriptionDao.updateStatus(prescricaoId, prescription_model.StatusPrescricao.cancelada);
      
      if (sucesso) {
        Logger.info('✅ Prescrição cancelada com sucesso');
      } else {
        Logger.error('❌ Erro ao cancelar prescrição');
      }
      
      return sucesso;
    } catch (e) {
      Logger.error('❌ Erro ao cancelar prescrição: $e');
      return false;
    }
  }

  /// Integra com sistema de custos após execução
  Future<void> _integrarComCustos(String prescricaoId) async {
    try {
      final prescricao = await _prescriptionDao.getById(prescricaoId);
      if (prescricao == null) return;

      Logger.info('💰 Integrando com sistema de custos...');

      // Converter produtos da prescrição para formato do sistema de custos
      final produtosCusto = prescricao.produtos.map((produto) {
        return {
          'id': produto.id,
          'nome': produto.nome,
          'dose': produto.dosePorHectare,
          'unidade': produto.unidade,
          'preco_unitario': produto.precoUnitario,
          'estoque_atual': produto.estoqueAtual,
          'categoria': produto.categoria,
        };
      }).toList();

      // Integrar com sistema de custos
      // TODO: Implementar integração com sistema de custos quando disponível
      Logger.info('💰 Integração com sistema de custos será implementada em breve');

      Logger.info('✅ Integração com custos concluída');
    } catch (e) {
      Logger.error('❌ Erro na integração com custos: $e');
    }
  }

  /// Gera relatório de prescrições
  Future<Map<String, dynamic>> gerarRelatorio({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? talhaoId,
    prescription_model.StatusPrescricao? status,
  }) async {
    try {
      Logger.info('📊 Gerando relatório de prescrições...');

      final prescricoes = await _prescriptionDao.getByPeriod(
        dataInicio: dataInicio ?? DateTime.now().subtract(Duration(days: 30)),
        dataFim: dataFim ?? DateTime.now(),
        talhaoId: talhaoId,
        status: status,
      );

      final estatisticas = await _prescriptionDao.getStatistics(
        dataInicio: dataInicio,
        dataFim: dataFim,
        talhaoId: talhaoId,
      );

      return {
        'prescricoes': prescricoes,
        'estatisticas': estatisticas,
        'filtros': {
          'data_inicio': dataInicio?.toIso8601String(),
          'data_fim': dataFim?.toIso8601String(),
          'talhao_id': talhaoId,
          'status': status?.name,
        },
      };
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
      return {
        'erro': e.toString(),
        'prescricoes': [],
        'estatisticas': {},
      };
    }
  }

  /// Mapeia categoria do produto para tipo
  prescription_model.TipoProduto _mapearTipoProduto(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    
    if (categoriaLower.contains('herbicida') || 
        categoriaLower.contains('fungicida') || 
        categoriaLower.contains('inseticida') ||
        categoriaLower.contains('defensivo')) {
      return prescription_model.TipoProduto.defensivo;
    } else if (categoriaLower.contains('fertilizante') || 
               categoriaLower.contains('adubo')) {
      return prescription_model.TipoProduto.fertilizante;
    } else if (categoriaLower.contains('calcario')) {
      return prescription_model.TipoProduto.calcario;
    } else if (categoriaLower.contains('semente')) {
      return prescription_model.TipoProduto.semente;
    } else {
      return prescription_model.TipoProduto.defensivo; // Padrão
    }
  }

  /// Inicializa dados padrão
  Future<void> initializeDefaultData() async {
    try {
      Logger.info('🔄 Inicializando dados padrão de prescrição...');
      await _prescriptionDao.initializeDefaultBicos();
      Logger.info('✅ Dados padrão inicializados');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar dados padrão: $e');
    }
  }
}
