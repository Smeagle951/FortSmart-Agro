import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modules/stock/models/stock_product_model.dart';
import '../modules/stock/services/stock_service.dart';
import '../screens/talhoes_com_safras/providers/talhao_provider.dart';
import '../utils/logger.dart';
import '../services/talhao_unified_service.dart';

/// Tela de Simulação de Custos - Integração completa com estoque e talhões
class SimulacaoCustosScreen extends StatefulWidget {
  const SimulacaoCustosScreen({Key? key}) : super(key: key);

  @override
  State<SimulacaoCustosScreen> createState() => _SimulacaoCustosScreenState();
}

class _SimulacaoCustosScreenState extends State<SimulacaoCustosScreen> {
  final StockService _stockService = StockService();
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Estados
  bool _isLoading = true;
  bool _isCalculating = false;

  // Dados
  List<StockProduct> _produtos = [];
  List<Map<String, dynamic>> _talhoes = [];
  List<Map<String, dynamic>> _produtosSelecionados = [];

  // Seleções
  Map<String, dynamic>? _talhaoSelecionado;
  Map<String, dynamic>? _resultadoSimulacao;

  // Serviço unificado de talhões
  final TalhaoUnifiedService _talhaoUnifiedService = TalhaoUnifiedService();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Carrega produtos do estoque e talhões
  Future<void> _carregarDados() async {
    try {
      setState(() => _isLoading = true);
      print('🔄 Carregando dados para simulação...');

      // Carregar produtos do estoque
      print('📦 Carregando produtos do estoque...');
      final produtos = await _stockService.getAllProducts();
      print('✅ Produtos carregados: ${produtos.length}');

      // Carregar talhões
      print('🌾 [SIMULACAO_CUSTOS] Carregando talhões via serviço unificado...');
      final talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
        nomeModulo: 'SIMULACAO_CUSTOS',
      );
      print('✅ [SIMULACAO_CUSTOS] ${talhoes.length} talhões carregados');

      setState(() {
        _talhoes = talhoes.map((talhao) => {
          'id': talhao.id,
          'nome': talhao.name,
          'area': talhao.area,
          'fazenda': talhao.fazendaId,
        }).toList();
      });

      if (mounted) {
        setState(() {
          _produtos = produtos;
          _isLoading = false;
        });

        print('✅ Dados carregados com sucesso');
        print('📊 Produtos disponíveis: ${_produtos.length}');
        print('📊 Talhões disponíveis: ${_talhoes.length}');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      Logger.error('❌ Erro ao carregar dados: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErro('Erro ao carregar dados: $e');
      }
    }
  }

  /// Seleciona um talhão e preenche automaticamente a área
  void _selecionarTalhao(Map<String, dynamic> talhao) {
    setState(() {
      _talhaoSelecionado = talhao;
      _areaController.text = talhao['area'].toString();
    });
    print('✅ Talhão selecionado: ${talhao['nome']} (${talhao['area']} ha)');
  }

  /// Adiciona um produto à simulação
  void _adicionarProduto() {
    if (_produtos.isEmpty) {
      _mostrarErro('Nenhum produto disponível no estoque');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ProdutoDialog(
        produtos: _produtos,
        onProdutoSelecionado: (produto, dose) {
          setState(() {
            _produtosSelecionados.add({
              'id': produto.id,
              'nome': produto.name,
              'categoria': produto.category,
              'unidade': produto.unit,
              'precoUnitario': produto.unitValue,
              'dosePorHa': dose,
              'estoqueAtual': produto.availableQuantity,
            });
          });
          print('✅ Produto adicionado: ${produto.name} (${dose} ${produto.unit}/ha)');
        },
      ),
    );
  }

  /// Remove um produto da simulação
  void _removerProduto(int index) {
    setState(() {
      _produtosSelecionados.removeAt(index);
    });
  }

  /// Calcula a simulação de custos
  Future<void> _calcularSimulacao() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Validação do formulário falhou');
      return;
    }

    if (_talhaoSelecionado == null) {
      _mostrarErro('Selecione um talhão');
      return;
    }

    if (_produtosSelecionados.isEmpty) {
      _mostrarErro('Adicione pelo menos um produto');
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final areaHa = double.parse(_areaController.text);
      print('🧮 Iniciando simulação para ${areaHa} hectares...');

      double custoTotal = 0.0;
      final List<Map<String, dynamic>> produtosCalculados = [];

      // Calcular custos para cada produto
      for (final produto in _produtosSelecionados) {
        final dosePorHa = produto['dosePorHa'] as double;
        final precoUnitario = produto['precoUnitario'] as double;
        final quantidadeNecessaria = dosePorHa * areaHa;
        final custoProduto = quantidadeNecessaria * precoUnitario;

        produtosCalculados.add({
          'produto': produto['nome'],
          'categoria': produto['categoria'],
          'unidade': produto['unidade'],
          'dosePorHa': dosePorHa,
          'quantidadeNecessaria': quantidadeNecessaria,
          'precoUnitario': precoUnitario,
          'custoProduto': custoProduto,
          'estoqueSuficiente': produto['estoqueAtual'] >= quantidadeNecessaria,
          'saldoAtual': produto['estoqueAtual'],
        });

        custoTotal += custoProduto;
      }

      final custoPorHectare = areaHa > 0 ? custoTotal / areaHa : 0.0;

      setState(() {
        _resultadoSimulacao = {
          'talhao': _talhaoSelecionado,
          'areaHa': areaHa,
          'custoTotal': custoTotal,
          'custoPorHectare': custoPorHectare,
          'produtos': produtosCalculados,
          'observacoes': _observacoesController.text,
          'dataSimulacao': DateTime.now(),
        };
        _isCalculating = false;
      });

      print('✅ Simulação concluída: R\$ ${custoTotal.toStringAsFixed(2)}');
      _mostrarSucesso('Simulação concluída: R\$ ${custoTotal.toStringAsFixed(2)}');

    } catch (e) {
      print('❌ Erro na simulação: $e');
      Logger.error('❌ Erro na simulação: $e');
      setState(() => _isCalculating = false);
      _mostrarErro('Erro na simulação: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular Custos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Recarregar dados',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dados...'),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelecaoTalhao(),
            const SizedBox(height: 16),
            _buildAreaAplicacao(),
            const SizedBox(height: 16),
            _buildProdutos(),
            const SizedBox(height: 16),
            _buildObservacoes(),
            const SizedBox(height: 24),
            _buildBotaoSimular(),
            const SizedBox(height: 24),
            if (_resultadoSimulacao != null) _buildResultadoSimulacao(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoTalhao() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Selecionar Talhão',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_talhoes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.agriculture_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum talhão disponível',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Cadastre talhões no módulo de talhões',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _talhaoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Talhão',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                items: _talhoes.map((talhao) {
                  return DropdownMenuItem(
                    value: talhao,
                    child: Text('${talhao['nome']} (${talhao['area']} ha)'),
                  );
                }).toList(),
                onChanged: (talhao) {
                  if (talhao != null) {
                    _selecionarTalhao(talhao);
                  }
                },
                validator: (value) => value == null ? 'Selecione um talhão' : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaAplicacao() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.area_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Área de Aplicação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Área (hectares)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.area_chart),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a área';
                }
                final area = double.tryParse(value);
                if (area == null || area <= 0) {
                  return 'Área deve ser maior que zero';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutos() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Produtos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _adicionarProduto,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_produtosSelecionados.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum produto selecionado',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Adicione produtos do estoque',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _produtosSelecionados.length,
                itemBuilder: (context, index) {
                  final produto = _produtosSelecionados[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoriaColor(produto['categoria']),
                        child: Icon(
                          _getCategoriaIcon(produto['categoria']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(produto['nome']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${produto['dosePorHa']} ${produto['unidade']}/ha'),
                          Text('R\$ ${produto['precoUnitario'].toStringAsFixed(2)}/${produto['unidade']}'),
                          Text('Estoque: ${produto['estoqueAtual']} ${produto['unidade']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removerProduto(index),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacoes() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações adicionais',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSimular() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCalculating ? null : _calcularSimulacao,
        icon: _isCalculating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.calculate),
        label: Text(_isCalculating ? 'Calculando...' : 'Simular Custos'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultadoSimulacao() {
    final resultado = _resultadoSimulacao!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Resultado da Simulação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Resumo geral
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Talhão: ${resultado['talhao']['nome']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Área: ${resultado['areaHa']} hectares'),
                  const SizedBox(height: 8),
                  Text(
                    'Custo Total: R\$ ${resultado['custoTotal'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Custo por Hectare: R\$ ${resultado['custoPorHectare'].toStringAsFixed(2)}/ha',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detalhes dos produtos
            const Text(
              'Detalhes dos Produtos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resultado['produtos'].length,
              itemBuilder: (context, index) {
                final produto = resultado['produtos'][index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoriaColor(produto['categoria']),
                      child: Icon(
                        _getCategoriaIcon(produto['categoria']),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(produto['produto']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${produto['dosePorHa']} ${produto['unidade']}/ha'),
                        Text('Quantidade: ${produto['quantidadeNecessaria'].toStringAsFixed(2)} ${produto['unidade']}'),
                        Text(
                          'Estoque: ${produto['saldoAtual']} ${produto['unidade']}',
                          style: TextStyle(
                            color: produto['estoqueSuficiente'] ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${produto['custoProduto'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (!produto['estoqueSuficiente'])
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'herbicida':
        return Colors.red;
      case 'fungicida':
        return Colors.blue;
      case 'inseticida':
        return Colors.orange;
      case 'fertilizante':
        return Colors.green;
      case 'semente':
        return Colors.brown;
      case 'adubo foliar':
        return Colors.purple;
      case 'adjuvante':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'herbicida':
        return Icons.eco;
      case 'fungicida':
        return Icons.healing;
      case 'inseticida':
        return Icons.bug_report;
      case 'fertilizante':
        return Icons.grass;
      case 'semente':
        return Icons.grain;
      case 'adubo foliar':
        return Icons.agriculture;
      case 'adjuvante':
        return Icons.science;
      default:
        return Icons.inventory;
    }
  }
}

/// Dialog para seleção de produto
class _ProdutoDialog extends StatefulWidget {
  final List<StockProduct> produtos;
  final Function(StockProduct produto, double dose) onProdutoSelecionado;

  const _ProdutoDialog({
    required this.produtos,
    required this.onProdutoSelecionado,
  });

  @override
  State<_ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends State<_ProdutoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _doseController = TextEditingController();
  
  StockProduct? _produtoSelecionado;

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Produto'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StockProduct>(
                value: _produtoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Produto',
                  border: OutlineInputBorder(),
                ),
                items: widget.produtos.map((produto) {
                  return DropdownMenuItem(
                    value: produto,
                    child: Text('${produto.name} (${produto.availableQuantity} ${produto.unit})'),
                  );
                }).toList(),
                onChanged: (produto) {
                  setState(() => _produtoSelecionado = produto);
                },
                validator: (value) => value == null ? 'Selecione um produto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doseController,
                decoration: InputDecoration(
                  labelText: 'Dose por hectare',
                  border: const OutlineInputBorder(),
                  suffixText: _produtoSelecionado?.unit ?? '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a dose';
                  }
                  final dose = double.tryParse(value);
                  if (dose == null || dose <= 0) {
                    return 'Dose deve ser maior que zero';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _produtoSelecionado != null) {
              final dose = double.parse(_doseController.text);
              widget.onProdutoSelecionado(_produtoSelecionado!, dose);
              Navigator.pop(context);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
