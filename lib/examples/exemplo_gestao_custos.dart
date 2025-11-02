import '../services/gestao_custos_service.dart';
import '../models/produto_estoque.dart';
import '../models/aplicacao.dart';
import '../database/daos/produto_estoque_dao.dart';
import '../utils/logger.dart';

/// Exemplo prático de uso do sistema de gestão de custos
class ExemploGestaoCustos {
  final GestaoCustosService _gestaoCustosService = GestaoCustosService();
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();

  /// Exemplo completo de uso do sistema
  Future<void> executarExemplo() async {
    Logger.info('🚀 Iniciando exemplo de gestão de custos...');

    try {
      // 1. Cadastrar produtos no estoque
      await _cadastrarProdutosExemplo();

      // 2. Registrar aplicações com cálculo automático
      await _registrarAplicacoesExemplo();

      // 3. Gerar relatórios
      await _gerarRelatoriosExemplo();

      // 4. Simular custos futuros
      await _simularCustosFuturosExemplo();

      Logger.info('✅ Exemplo executado com sucesso!');
    } catch (e) {
      Logger.error('❌ Erro no exemplo: $e');
    }
  }

  /// Cadastra produtos de exemplo no estoque
  Future<void> _cadastrarProdutosExemplo() async {
    Logger.info('📦 Cadastrando produtos de exemplo...');

    final produtos = [
      ProdutoEstoque(
        nome: 'Roundup Original',
        tipo: TipoProduto.herbicida,
        unidade: 'L',
        precoUnitario: 45.50,
        saldoAtual: 100.0,
        fornecedor: 'Bayer',
        numeroLote: 'LOT001',
        dataValidade: DateTime.now().add(const Duration(days: 365)),
        observacoes: 'Herbicida para controle de plantas daninhas',
      ),
      ProdutoEstoque(
        nome: 'Fertilizante NPK 20-20-20',
        tipo: TipoProduto.fertilizante,
        unidade: 'kg',
        precoUnitario: 3.80,
        saldoAtual: 500.0,
        fornecedor: 'Fertilizantes ABC',
        numeroLote: 'LOT002',
        dataValidade: DateTime.now().add(const Duration(days: 730)),
        observacoes: 'Fertilizante balanceado para adubação',
      ),
      ProdutoEstoque(
        nome: 'Inseticida Decis',
        tipo: TipoProduto.inseticida,
        unidade: 'L',
        precoUnitario: 120.00,
        saldoAtual: 25.0,
        fornecedor: 'Bayer',
        numeroLote: 'LOT003',
        dataValidade: DateTime.now().add(const Duration(days: 180)),
        observacoes: 'Controle de pragas',
      ),
    ];

    for (final produto in produtos) {
      await _produtoDao.save(produto);
      Logger.info('✅ Produto cadastrado: ${produto.nome}');
    }
  }

  /// Registra aplicações de exemplo
  Future<void> _registrarAplicacoesExemplo() async {
    Logger.info('🚜 Registrando aplicações de exemplo...');

    // Buscar produtos cadastrados
    final produtos = await _produtoDao.buscarTodos();
    if (produtos.isEmpty) {
      Logger.error('❌ Nenhum produto encontrado para aplicação');
      return;
    }

    // Exemplo 1: Aplicação de herbicida
    final herbicida = produtos.firstWhere((p) => p.tipo == TipoProduto.herbicida);
    final sucesso1 = await _gestaoCustosService.registrarAplicacao(
      talhaoId: 'talhao-001',
      produtoId: herbicida.id,
      dosePorHa: 2.5, // 2.5 L/ha
      areaAplicadaHa: 50.0, // 50 hectares
      dataAplicacao: DateTime.now().subtract(const Duration(days: 5)),
      operador: 'João Silva',
      equipamento: 'Pulverizador autopropelido',
      condicoesClimaticas: 'Tempo seco, sem vento',
      observacoes: 'Aplicação pós-emergente',
    );

    if (sucesso1) {
      Logger.info('✅ Aplicação de herbicida registrada');
    }

    // Exemplo 2: Aplicação de fertilizante
    final fertilizante = produtos.firstWhere((p) => p.tipo == TipoProduto.fertilizante);
    final sucesso2 = await _gestaoCustosService.registrarAplicacao(
      talhaoId: 'talhao-001',
      produtoId: fertilizante.id,
      dosePorHa: 300.0, // 300 kg/ha
      areaAplicadaHa: 50.0, // 50 hectares
      dataAplicacao: DateTime.now().subtract(const Duration(days: 3)),
      operador: 'Maria Santos',
      equipamento: 'Adubadeira',
      condicoesClimaticas: 'Tempo úmido',
      observacoes: 'Adubação de cobertura',
    );

    if (sucesso2) {
      Logger.info('✅ Aplicação de fertilizante registrada');
    }

    // Exemplo 3: Aplicação de inseticida
    final inseticida = produtos.firstWhere((p) => p.tipo == TipoProduto.inseticida);
    final sucesso3 = await _gestaoCustosService.registrarAplicacao(
      talhaoId: 'talhao-002',
      produtoId: inseticida.id,
      dosePorHa: 0.5, // 0.5 L/ha
      areaAplicadaHa: 30.0, // 30 hectares
      dataAplicacao: DateTime.now().subtract(const Duration(days: 1)),
      operador: 'Pedro Costa',
      equipamento: 'Pulverizador costal',
      condicoesClimaticas: 'Tempo seco',
      observacoes: 'Controle de lagartas',
    );

    if (sucesso3) {
      Logger.info('✅ Aplicação de inseticida registrada');
    }
  }

  /// Gera relatórios de exemplo
  Future<void> _gerarRelatoriosExemplo() async {
    Logger.info('📊 Gerando relatórios de exemplo...');

    // 1. Custos por talhão
    final custosTalhao1 = await _gestaoCustosService.calcularCustosPorTalhao('talhao-001');
    Logger.info('💰 Custos talhão 001: R\$ ${custosTalhao1['custo_total']?.toStringAsFixed(2)}');

    final custosTalhao2 = await _gestaoCustosService.calcularCustosPorTalhao('talhao-002');
    Logger.info('💰 Custos talhão 002: R\$ ${custosTalhao2['custo_total']?.toStringAsFixed(2)}');

    // 2. Custos por período (últimos 30 dias)
    final custosPeriodo = await _gestaoCustosService.calcularCustosPorPeriodo(
      dataInicio: DateTime.now().subtract(const Duration(days: 30)),
      dataFim: DateTime.now(),
    );
    Logger.info('📅 Custo total período: R\$ ${custosPeriodo['custo_total_periodo']?.toStringAsFixed(2)}');

    // 3. Produtos mais utilizados
    final produtosMaisUtilizados = await _gestaoCustosService.obterProdutosMaisUtilizados();
    Logger.info('🏆 Produtos mais utilizados: ${produtosMaisUtilizados.length} produtos');

    for (final produto in produtosMaisUtilizados.take(3)) {
      Logger.info('  - ${produto['nome_produto']}: R\$ ${produto['custo_total']?.toStringAsFixed(2)}');
    }

    // 4. Alertas de estoque
    final alertas = await _gestaoCustosService.obterAlertasEstoque();
    Logger.info('⚠️ Alertas de estoque: ${alertas['total_alertas']} alertas');
  }

  /// Simula custos de aplicações futuras
  Future<void> _simularCustosFuturosExemplo() async {
    Logger.info('🧮 Simulando custos futuros...');

    final produtos = await _produtoDao.buscarTodos();
    if (produtos.isEmpty) return;

    final herbicida = produtos.firstWhere((p) => p.tipo == TipoProduto.herbicida);

    // Simular aplicação em 100 hectares
    final simulacao = await _gestaoCustosService.simularCustoAplicacao(
      produtoId: herbicida.id,
      dosePorHa: 2.5,
      areaAplicadaHa: 100.0,
    );

    Logger.info('📋 Simulação de aplicação:');
    Logger.info('  - Produto: ${simulacao['produto']['nome_produto']}');
    Logger.info('  - Dose: ${simulacao['dose_por_ha']} ${simulacao['produto']['unidade']}/ha');
    Logger.info('  - Área: ${simulacao['area_aplicada_ha']} ha');
    Logger.info('  - Quantidade necessária: ${simulacao['quantidade_necessaria']} ${simulacao['produto']['unidade']}');
    Logger.info('  - Custo total: R\$ ${simulacao['custo_total']?.toStringAsFixed(2)}');
    Logger.info('  - Custo por ha: R\$ ${simulacao['custo_por_ha']?.toStringAsFixed(2)}');
    Logger.info('  - Estoque suficiente: ${simulacao['estoque_suficiente']}');
  }

  /// Exemplo de uso em uma aplicação real
  Future<void> exemploUsoReal() async {
    Logger.info('🎯 Exemplo de uso real do sistema...');

    // 1. Usuário seleciona talhão e produto
    final talhaoId = 'talhao-001';
    final produtos = await _produtoDao.buscarPorTipo(TipoProduto.herbicida);
    
    if (produtos.isEmpty) {
      Logger.error('❌ Nenhum herbicida disponível');
      return;
    }

    final produto = produtos.first;

    // 2. Usuário informa dados da aplicação
    final dosePorHa = 2.0; // 2 L/ha
    final areaAplicadaHa = 25.0; // 25 hectares
    final dataAplicacao = DateTime.now();
    final operador = 'João Silva';

    // 3. Sistema calcula automaticamente
    final simulacao = await _gestaoCustosService.simularCustoAplicacao(
      produtoId: produto.id,
      dosePorHa: dosePorHa,
      areaAplicadaHa: areaAplicadaHa,
    );

    Logger.info('📊 Simulação antes da aplicação:');
    Logger.info('  - Custo estimado: R\$ ${simulacao['custo_total']?.toStringAsFixed(2)}');
    Logger.info('  - Estoque disponível: ${simulacao['saldo_atual']} ${produto.unidade}');

    // 4. Usuário confirma e registra aplicação
    if (simulacao['estoque_suficiente'] == true) {
      final sucesso = await _gestaoCustosService.registrarAplicacao(
        talhaoId: talhaoId,
        produtoId: produto.id,
        dosePorHa: dosePorHa,
        areaAplicadaHa: areaAplicadaHa,
        dataAplicacao: dataAplicacao,
        operador: operador,
        equipamento: 'Pulverizador',
        condicoesClimaticas: 'Tempo seco',
        observacoes: 'Aplicação registrada via app',
      );

      if (sucesso) {
        Logger.info('✅ Aplicação registrada com sucesso!');
        
        // 5. Sistema atualiza automaticamente
        final custosAtualizados = await _gestaoCustosService.calcularCustosPorTalhao(talhaoId);
        Logger.info('💰 Custos atualizados do talhão: R\$ ${custosAtualizados['custo_total']?.toStringAsFixed(2)}');
      }
    } else {
      Logger.warning('⚠️ Estoque insuficiente para esta aplicação');
    }
  }
}
