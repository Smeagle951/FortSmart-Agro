# 🔄 Guia de Integração com Dados Reais

## 📋 Objetivo
Conectar o sistema de custos por hectare com os dados reais do projeto FortSmart Agro, substituindo os dados simulados por dados reais do banco de dados.

---

## 🗄️ Passo 1: Verificar Estrutura de Dados Existente

### Modelos Necessários
```dart
// Verificar se estes modelos existem e estão atualizados
- TalhaoModel
- CulturaModel
- ProdutoEstoqueModel
- AplicacaoModel
```

### DAOs Necessários
```dart
// Verificar se estes DAOs existem
- TalhaoDao
- CulturaDao
- ProdutoEstoqueDao
- AplicacaoDao
```

**Ação:** ✅ Verificar existência e estrutura dos modelos e DAOs

---

## 🔧 Passo 2: Atualizar CustoAplicacaoIntegrationService

### Substituir Dados Simulados por Reais

```dart
// Em lib/services/custo_aplicacao_integration_service.dart

class CustoAplicacaoIntegrationService {
  // Adicionar DAOs reais
  final TalhaoDao _talhaoDao;
  final CulturaDao _culturaDao;
  final ProdutoEstoqueDao _produtoEstoqueDao;
  final AplicacaoDao _aplicacaoDao;

  CustoAplicacaoIntegrationService({
    required TalhaoDao talhaoDao,
    required CulturaDao culturaDao,
    required ProdutoEstoqueDao produtoEstoqueDao,
    required AplicacaoDao aplicacaoDao,
  }) : _talhaoDao = talhaoDao,
       _culturaDao = culturaDao,
       _produtoEstoqueDao = produtoEstoqueDao,
       _aplicacaoDao = aplicacaoDao;

  // Método para carregar talhões reais
  Future<List<TalhaoModel>> carregarTalhoes() async {
    try {
      return await _talhaoDao.buscarTodos();
    } catch (e) {
      Logger.error('Erro ao carregar talhões: $e');
      return [];
    }
  }

  // Método para carregar culturas reais
  Future<List<CulturaModel>> carregarCulturas() async {
    try {
      return await _culturaDao.buscarTodas();
    } catch (e) {
      Logger.error('Erro ao carregar culturas: $e');
      return [];
    }
  }

  // Método para carregar produtos reais
  Future<List<ProdutoEstoqueModel>> carregarProdutos() async {
    try {
      return await _produtoEstoqueDao.buscarTodos();
    } catch (e) {
      Logger.error('Erro ao carregar produtos: $e');
      return [];
    }
  }

  // Método para carregar aplicações reais
  Future<List<Aplicacao>> carregarAplicacoes({
    String? talhaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
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
      Logger.error('Erro ao carregar aplicações: $e');
      return [];
    }
  }
}
```

**Ação:** ✅ Atualizar o serviço com DAOs reais

---

## 📊 Passo 3: Atualizar Dashboard de Custos

### Substituir Dados Simulados

```dart
// Em lib/screens/custos/custo_por_hectare_dashboard_screen.dart

class _CustoPorHectareDashboardScreenState extends State<CustoPorHectareDashboardScreen> {
  final CustoAplicacaoIntegrationService _custoService = CustoAplicacaoIntegrationService(
    talhaoDao: TalhaoDao(),
    culturaDao: CulturaDao(),
    produtoEstoqueDao: ProdutoEstoqueDao(),
    aplicacaoDao: AplicacaoDao(),
  );

  // Carregar dados reais
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar talhões reais
      final talhoes = await _custoService.carregarTalhoes();
      
      // Carregar aplicações reais
      final aplicacoes = await _custoService.carregarAplicacoes(
        talhaoId: _talhaoSelecionado?.id,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );

      // Calcular custos reais
      final custos = await _custoService.calcularCustosPorPeriodo(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        talhaoId: _talhaoSelecionado?.id,
      );

      setState(() {
        _talhoes = talhoes;
        _aplicacoes = aplicacoes;
        _resumoCustos = custos;
        _isLoading = false;
      });

    } catch (e) {
      Logger.error('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

**Ação:** ✅ Atualizar dashboard com dados reais

---

## 📈 Passo 4: Atualizar Histórico de Custos

### Substituir Dados Simulados

```dart
// Em lib/screens/historico/historico_custos_talhao_screen.dart

class _HistoricoCustosTalhaoScreenState extends State<HistoricoCustosTalhaoScreen> {
  final CustoAplicacaoIntegrationService _custoService = CustoAplicacaoIntegrationService(
    talhaoDao: TalhaoDao(),
    culturaDao: CulturaDao(),
    produtoEstoqueDao: ProdutoEstoqueDao(),
    aplicacaoDao: AplicacaoDao(),
  );

  // Carregar talhões reais
  Future<void> _carregarTalhoes() async {
    try {
      final talhoes = await _custoService.carregarTalhoes();
      setState(() {
        _talhoes = talhoes;
      });
    } catch (e) {
      Logger.error('Erro ao carregar talhões: $e');
    }
  }

  // Carregar culturas reais
  Future<void> _carregarCulturas() async {
    try {
      final culturas = await _custoService.carregarCulturas();
      setState(() {
        _culturas = culturas;
      });
    } catch (e) {
      Logger.error('Erro ao carregar culturas: $e');
    }
  }

  // Carregar registros reais
  Future<void> _carregarRegistros() async {
    if (_talhaoSelecionado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar aplicações reais
      final aplicacoes = await _custoService.carregarAplicacoes(
        talhaoId: _talhaoSelecionado!.id,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );

      // Converter aplicações para formato de registros
      _registros = aplicacoes.map((aplicacao) {
        return {
          'id': aplicacao.id,
          'tipo': _determinarTipoAplicacao(aplicacao),
          'titulo': _gerarTituloAplicacao(aplicacao),
          'data': aplicacao.dataAplicacao,
          'talhao': _talhaoSelecionado!.name,
          'safra': _safraSelecionada ?? '2024/25',
          'area': aplicacao.areaAplicadaHa,
          'produtos': _formatarProdutos(aplicacao),
          'custo_total': aplicacao.custoTotal,
          'custo_ha': aplicacao.custoPorHa,
          'observacoes': aplicacao.observacoes,
        };
      }).toList();

      // Aplicar filtros
      _aplicarFiltros();
      
      // Calcular resumo
      _calcularResumoCustos();

    } catch (e) {
      Logger.error('Erro ao carregar registros: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método auxiliar para determinar tipo de aplicação
  String _determinarTipoAplicacao(Aplicacao aplicacao) {
    // Implementar lógica baseada no produto ou categoria
    // Exemplo: herbicida -> pulverizacao, adubo -> adubacao
    return 'pulverizacao'; // Padrão
  }

  // Método auxiliar para gerar título
  String _gerarTituloAplicacao(Aplicacao aplicacao) {
    // Implementar lógica para gerar título baseado no produto
    return 'Aplicação - ${aplicacao.produtoId}';
  }

  // Método auxiliar para formatar produtos
  String _formatarProdutos(Aplicacao aplicacao) {
    // Implementar formatação dos produtos
    return 'Produto ${aplicacao.produtoId}';
  }
}
```

**Ação:** ✅ Atualizar histórico com dados reais

---

## 🔄 Passo 5: Integrar com Sistema de Estoque

### Conectar com ProdutoEstoqueDao

```dart
// Em lib/services/custo_aplicacao_integration_service.dart

// Método para validar estoque real
Future<bool> _validarEstoqueParaAplicacao(ApplicationCalculationModel calculo) async {
  try {
    for (final produto in calculo.produtos) {
      final produtoEstoque = await _produtoEstoqueDao.buscarPorId(produto.id);
      
      if (produtoEstoque == null) {
        Logger.warning('Produto ${produto.nome} não encontrado no estoque');
        return false;
      }

      final quantidadeNecessaria = produto.calcularQuantidadeNecessaria(calculo.areaHa);
      
      if (produtoEstoque.saldo < quantidadeNecessaria) {
        Logger.warning('Estoque insuficiente para ${produto.nome}');
        return false;
      }
    }
    return true;
  } catch (e) {
    Logger.error('Erro ao validar estoque: $e');
    return false;
  }
}

// Método para debitar estoque real
Future<void> _debitarEstoqueAplicacao(ApplicationCalculationModel calculo) async {
  try {
    for (final produto in calculo.produtos) {
      final produtoEstoque = await _produtoEstoqueDao.buscarPorId(produto.id);
      
      if (produtoEstoque != null) {
        final quantidadeNecessaria = produto.calcularQuantidadeNecessaria(calculo.areaHa);
        final novoSaldo = produtoEstoque.saldo - quantidadeNecessaria;
        
        await _produtoEstoqueDao.atualizarSaldo(produto.id, novoSaldo);
        
        Logger.info('Estoque debitado: ${produto.nome} - ${quantidadeNecessaria} unidades');
      }
    }
  } catch (e) {
    Logger.error('Erro ao debitar estoque: $e');
    throw Exception('Erro ao debitar estoque: $e');
  }
}
```

**Ação:** ✅ Integrar com sistema de estoque real

---

## 📊 Passo 6: Implementar Cálculos Reais

### Atualizar Cálculos de Custo

```dart
// Em lib/services/custo_aplicacao_integration_service.dart

// Método para calcular custos reais por talhão
Future<Map<String, dynamic>> calcularCustosPorTalhao(String talhaoId) async {
  try {
    final aplicacoes = await _aplicacaoDao.buscarPorTalhao(talhaoId);
    
    double custoTotal = 0.0;
    double areaTotal = 0.0;
    final custosPorTipo = <String, double>{};

    for (final aplicacao in aplicacoes) {
      custoTotal += aplicacao.custoTotal;
      areaTotal += aplicacao.areaAplicadaHa;
      
      final tipo = _determinarTipoAplicacao(aplicacao);
      custosPorTipo[tipo] = (custosPorTipo[tipo] ?? 0.0) + aplicacao.custoTotal;
    }

    final custoMedioPorHa = areaTotal > 0 ? custoTotal / areaTotal : 0.0;

    return {
      'custo_total': custoTotal,
      'custo_medio_por_ha': custoMedioPorHa,
      'area_total': areaTotal,
      'custos_por_tipo': custosPorTipo,
      'total_aplicacoes': aplicacoes.length,
    };
  } catch (e) {
    Logger.error('Erro ao calcular custos por talhão: $e');
    return {};
  }
}

// Método para calcular custos reais por período
Future<Map<String, dynamic>> calcularCustosPorPeriodo({
  required DateTime dataInicio,
  required DateTime dataFim,
  String? talhaoId,
}) async {
  try {
    final aplicacoes = await _aplicacaoDao.buscarPorPeriodo(
      dataInicio: dataInicio,
      dataFim: dataFim,
      talhaoId: talhaoId,
    );

    double custoTotal = 0.0;
    double areaTotal = 0.0;
    final custosPorTalhao = <String, double>{};
    final custosPorTipo = <String, double>{};

    for (final aplicacao in aplicacoes) {
      custoTotal += aplicacao.custoTotal;
      areaTotal += aplicacao.areaAplicadaHa;
      
      // Custos por talhão
      final talhao = await _talhaoDao.buscarPorId(aplicacao.talhaoId);
      final nomeTalhao = talhao?.name ?? 'Talhão ${aplicacao.talhaoId}';
      custosPorTalhao[nomeTalhao] = (custosPorTalhao[nomeTalhao] ?? 0.0) + aplicacao.custoTotal;
      
      // Custos por tipo
      final tipo = _determinarTipoAplicacao(aplicacao);
      custosPorTipo[tipo] = (custosPorTipo[tipo] ?? 0.0) + aplicacao.custoTotal;
    }

    final custoMedioPorHa = areaTotal > 0 ? custoTotal / areaTotal : 0.0;

    return {
      'custo_total': custoTotal,
      'custo_medio_por_ha': custoMedioPorHa,
      'area_total': areaTotal,
      'custos_por_talhao': custosPorTalhao,
      'custos_por_tipo': custosPorTipo,
      'total_aplicacoes': aplicacoes.length,
      'periodo': {
        'inicio': dataInicio.toIso8601String(),
        'fim': dataFim.toIso8601String(),
      },
    };
  } catch (e) {
    Logger.error('Erro ao calcular custos por período: $e');
    return {};
  }
}
```

**Ação:** ✅ Implementar cálculos com dados reais

---

## 🧪 Passo 7: Testes de Integração

### Testes com Dados Reais

```dart
// Testes para validar integração
void testarIntegracaoDadosReais() async {
  final custoService = CustoAplicacaoIntegrationService(
    talhaoDao: TalhaoDao(),
    culturaDao: CulturaDao(),
    produtoEstoqueDao: ProdutoEstoqueDao(),
    aplicacaoDao: AplicacaoDao(),
  );

  // Teste 1: Carregar talhões
  final talhoes = await custoService.carregarTalhoes();
  print('Talhões carregados: ${talhoes.length}');

  // Teste 2: Carregar culturas
  final culturas = await custoService.carregarCulturas();
  print('Culturas carregadas: ${culturas.length}');

  // Teste 3: Carregar produtos
  final produtos = await custoService.carregarProdutos();
  print('Produtos carregados: ${produtos.length}');

  // Teste 4: Calcular custos
  if (talhoes.isNotEmpty) {
    final custos = await custoService.calcularCustosPorTalhao(talhoes.first.id);
    print('Custos calculados: $custos');
  }
}
```

**Ação:** ✅ Executar testes de integração

---

## ✅ Checklist de Integração

### Verificação de Dados
- [ ] Modelos existem e estão atualizados
- [ ] DAOs implementados corretamente
- [ ] Conexão com banco de dados funcionando
- [ ] Dados sendo carregados corretamente

### Integração de Serviços
- [ ] CustoAplicacaoIntegrationService atualizado
- [ ] Dashboard usando dados reais
- [ ] Histórico usando dados reais
- [ ] Sistema de estoque integrado

### Cálculos e Validações
- [ ] Cálculos de custo funcionando
- [ ] Validação de estoque funcionando
- [ ] Débito de estoque funcionando
- [ ] Relatórios gerando dados corretos

### Testes
- [ ] Testes de integração executados
- [ ] Dados sendo exibidos corretamente
- [ ] Performance adequada
- [ ] Tratamento de erros funcionando

---

## 🎯 Status da Integração

**Progresso:** 0% → 100%

**Próximo Passo:** Após completar a integração, prosseguir para:
1. 🎨 Personalização de cores e estilos
2. 🧪 Validação completa das funcionalidades

---

## 📞 Suporte Durante Integração

Se encontrar problemas durante a integração:

1. **Verificar logs:** `flutter logs`
2. **Verificar banco de dados:** Confirmar se dados existem
3. **Testar DAOs individualmente:** Verificar se métodos funcionam
4. **Verificar imports:** Confirmar se todos os imports estão corretos

**Status:** ✅ Pronto para iniciar integração
