import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/custo_aplicacao_integration_service.dart';
import '../../modules/cost_management/models/cost_management_model.dart';
import '../../models/talhao_model.dart';
import '../../models/aplicacao.dart';
import '../../utils/logger.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import '../simulacao_custos_screen.dart';

class CustoPorHectareDashboardScreen extends StatefulWidget {
  @override
  _CustoPorHectareDashboardScreenState createState() => _CustoPorHectareDashboardScreenState();
}

class _CustoPorHectareDashboardScreenState extends State<CustoPorHectareDashboardScreen> {
  final CustoAplicacaoIntegrationService _custoService = CustoAplicacaoIntegrationService();
  
  // Estados
  bool _isLoading = false;
  Map<String, dynamic>? _resumoCustos;
  Map<String, dynamic>? _custosPorTalhao;
  Map<String, dynamic>? _custosPorPeriodo;
  
  // Dados reais
  List<TalhaoModel> _talhoes = [];
  List<Aplicacao> _aplicacoes = [];
  
  // Filtros
  DateTime _dataInicio = DateTime.now().subtract(Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  String? _talhaoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar dados reais
      final talhoes = await _custoService.carregarTalhoes();
      final aplicacoes = await _custoService.carregarAplicacoes(
        talhaoId: _talhaoSelecionado,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );
      
      // Calcular custos reais
      final resumo = await _custoService.calcularCustosPorPeriodo(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        talhaoId: _talhaoSelecionado,
      );

      setState(() {
        _talhoes = talhoes;
        _aplicacoes = aplicacoes;
        _resumoCustos = resumo;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💰 Dashboard de Custos por Hectare'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _gerarRelatorio,
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoadingWidget(message: 'Carregando dados...')
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFiltros(),
                    SizedBox(height: 16),
                    _buildResumoGeral(),
                    SizedBox(height: 16),
                    _buildGraficoCustos(),
                    SizedBox(height: 16),
                    _buildTabelaCustosPorTalhao(),
                    SizedBox(height: 16),
                    _buildSimuladorCustos(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFiltros() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Filtros',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Início',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selecionarData(true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textLight),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(_dataInicio.toString().substring(0, 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Fim',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selecionarData(false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textLight),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(_dataFim.toString().substring(0, 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Aplicar Filtros',
            onPressed: _carregarDados,
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildResumoGeral() {
    if (_resumoCustos == null) {
      return CustomCard(
        child: Center(
          child: Text(
            'Nenhum dado disponível',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final resumo = _resumoCustos!;
    final custoTotal = resumo['custo_total'] ?? 0.0;
    final custoMedioPorHa = resumo['custo_medio_por_ha'] ?? 0.0;
    final totalAplicacoes = resumo['total_aplicacoes'] ?? 0;
    final areaTotal = resumo['area_total'] ?? 0.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Resumo Geral',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustoIndicator(
                  titulo: 'Custo Total',
                  valor: custoTotal.toStringAsFixed(2),
                  icone: Icons.attach_money,
                  cor: AppColors.custoTotal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustoIndicator(
                  titulo: 'Custo Médio/ha',
                  valor: custoMedioPorHa.toStringAsFixed(2),
                  icone: Icons.agriculture,
                  cor: AppColors.custoPorHa,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustoIndicator(
                  titulo: 'Aplicações',
                  valor: totalAplicacoes.toString(),
                  icone: Icons.science,
                  cor: AppColors.pulverizacao,
                  isMonetary: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustoIndicator(
                  titulo: 'Área Total',
                  valor: '${areaTotal.toStringAsFixed(1)} ha',
                  icone: Icons.map,
                  cor: AppColors.solo,
                  isMonetary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildGraficoCustos() {
    if (_resumoCustos == null || _resumoCustos!['aplicacoes_por_talhao'] == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum dado para gráfico'),
        ),
      );
    }

    final aplicacoesPorTalhao = _resumoCustos!['aplicacoes_por_talhao'] as Map<String, dynamic>;
    
    if (aplicacoesPorTalhao.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhuma aplicação registrada no período'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 Custos por Talhão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ...aplicacoesPorTalhao.entries.map((entry) {
              final talhaoId = entry.key;
              final dados = entry.value as Map<String, dynamic>;
              final custoTotal = dados['custo_total'] ?? 0.0;
              final custoMedioPorHa = dados['custo_medio_por_ha'] ?? 0.0;
              final areaTotal = dados['area_total'] ?? 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talhão $talhaoId',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Custo Total: R\$ ${custoTotal.toStringAsFixed(2)}'),
                        ),
                        Expanded(
                          child: Text('Custo/ha: R\$ ${custoMedioPorHa.toStringAsFixed(2)}'),
                        ),
                        Expanded(
                          child: Text('Área: ${areaTotal.toStringAsFixed(1)} ha'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaCustosPorTalhao() {
    if (_resumoCustos == null || _resumoCustos!['aplicacoes_por_talhao'] == null) {
      return SizedBox.shrink();
    }

    final aplicacoesPorTalhao = _resumoCustos!['aplicacoes_por_talhao'] as Map<String, dynamic>;
    
    if (aplicacoesPorTalhao.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Detalhamento por Talhão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Talhão')),
                  DataColumn(label: Text('Aplicações')),
                  DataColumn(label: Text('Área (ha)')),
                  DataColumn(label: Text('Custo Total')),
                  DataColumn(label: Text('Custo/ha')),
                ],
                rows: aplicacoesPorTalhao.entries.map((entry) {
                  final talhaoId = entry.key;
                  final dados = entry.value as Map<String, dynamic>;
                  final totalAplicacoes = dados['total_aplicacoes'] ?? 0;
                  final areaTotal = dados['area_total'] ?? 0.0;
                  final custoTotal = dados['custo_total'] ?? 0.0;
                  final custoMedioPorHa = dados['custo_medio_por_ha'] ?? 0.0;

                  return DataRow(
                    cells: [
                      DataCell(Text('Talhão $talhaoId')),
                      DataCell(Text(totalAplicacoes.toString())),
                      DataCell(Text(areaTotal.toStringAsFixed(1))),
                      DataCell(Text('R\$ ${custoTotal.toStringAsFixed(2)}')),
                      DataCell(Text('R\$ ${custoMedioPorHa.toStringAsFixed(2)}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimuladorCustos() {
    return CustomCard(
      gradient: AppColors.secondaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧮 Simulador de Custos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Calcule o custo estimado de uma aplicação futura',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _abrirSimulador,
            icon: const Icon(Icons.calculate),
            label: const Text('Abrir Simulador'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.secondary,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarData(bool isInicio) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (dataSelecionada != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = dataSelecionada;
        } else {
          _dataFim = dataSelecionada;
        }
      });
    }
  }

  Future<void> _gerarRelatorio() async {
    try {
      final relatorio = await _custoService.gerarRelatorioCustos(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        talhaoId: _talhaoSelecionado,
      );

      if (relatorio['erro'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar relatório: ${relatorio['erro']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Aqui você pode implementar a exportação do relatório
      // Por enquanto, vamos apenas mostrar um diálogo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Relatório Gerado'),
          content: Text('Relatório de custos gerado com sucesso!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar relatório: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _abrirSimulador() {
    // Navegar para a nova tela do simulador
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SimulacaoCustosScreen(),
      ),
    );
  }
}

class SimuladorCustosScreen extends StatefulWidget {
  @override
  _SimuladorCustosScreenState createState() => _SimuladorCustosScreenState();
}

class _SimuladorCustosScreenState extends State<SimuladorCustosScreen> {
  final CustoAplicacaoIntegrationService _custoService = CustoAplicacaoIntegrationService();
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  
  List<Map<String, dynamic>> _produtosSelecionados = [];
  Map<String, dynamic>? _resultadoSimulacao;
  bool _isCalculando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧮 Simulador de Custos'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simule o custo de uma aplicação',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Área (hectares)',
                  border: OutlineInputBorder(),
                  suffixText: 'ha',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a área';
                  }
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) {
                    return 'Área deve ser um número positivo';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _adicionarProduto,
                icon: Icon(Icons.add),
                label: Text('Adicionar Produto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              if (_produtosSelecionados.isNotEmpty) ...[
                Text(
                  'Produtos Selecionados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                ..._produtosSelecionados.map((produto) => _buildProdutoCard(produto)).toList(),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _calcularCustos,
                  icon: Icon(Icons.calculate),
                  label: Text('Calcular Custos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              SizedBox(height: 16),
              if (_resultadoSimulacao != null) _buildResultadoSimulacao(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(produto['nome'] ?? 'Produto'),
        subtitle: Text('${produto['dose'] ?? 0}${produto['unidade'] ?? ''}/ha - R\$ ${(produto['custoPorHectare'] ?? 0.0).toStringAsFixed(2)}/ha'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removerProduto(produto),
        ),
      ),
    );
  }

  Widget _buildResultadoSimulacao() {
    final resultado = _resultadoSimulacao!;
    final custoTotal = resultado['custo_total'] ?? 0.0;
    final custoPorHa = resultado['custo_por_ha'] ?? 0.0;
    final produtos = resultado['produtos'] as List<dynamic>? ?? [];

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 Resultado da Simulação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIndicadorSimulacao(
                    'Custo Total',
                    'R\$ ${custoTotal.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildIndicadorSimulacao(
                    'Custo por Hectare',
                    'R\$ ${custoPorHa.toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Detalhamento por Produto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...produtos.map((produto) {
              final nome = produto['produto'] ?? '';
              final custoProduto = produto['custo_produto'] ?? 0.0;
              final estoqueSuficiente = produto['estoque_suficiente'] ?? false;

              return Container(
                margin: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      estoqueSuficiente ? Icons.check_circle : Icons.warning,
                      color: estoqueSuficiente ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text(nome)),
                    Text('R\$ ${custoProduto.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadorSimulacao(String titulo, String valor, Color cor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  void _adicionarProduto() {
    // Aqui você pode implementar a seleção de produtos do estoque
    // Por enquanto, vamos adicionar um produto de exemplo
    final produto = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'nome': 'Glifosato',
      'unidade': 'L',
      'dose': 2.0,
      'precoUnitario': 12.50,
      'estoqueAtual': 100.0,
      'categoria': 'herbicida',
      'custoPorHectare': 25.0,
    };

    setState(() {
      _produtosSelecionados.add(produto);
    });
  }

  void _removerProduto(Map<String, dynamic> produto) {
    setState(() {
      _produtosSelecionados.remove(produto);
    });
  }

  Future<void> _calcularCustos() async {
    if (!_formKey.currentState!.validate()) return;
    if (_produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos um produto')),
      );
      return;
    }

    setState(() {
      _isCalculando = true;
    });

    try {
      final area = double.parse(_areaController.text);
      final resultado = await _custoService.simularCustoAplicacao(
        produtos: _produtosSelecionados,
        areaHa: area,
      );

      setState(() {
        _resultadoSimulacao = resultado;
        _isCalculando = false;
      });
    } catch (e) {
      setState(() {
        _isCalculando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao calcular: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
