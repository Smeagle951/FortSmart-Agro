import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cost_simulation_model.dart';
import '../services/cost_simulation_service.dart';
import '../../../../models/produto_estoque.dart';
import '../../../../models/talhao_model.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/loading_widget.dart';

class CostSimulationScreen extends StatefulWidget {
  const CostSimulationScreen({Key? key}) : super(key: key);

  @override
  State<CostSimulationScreen> createState() => _CostSimulationScreenState();
}

class _CostSimulationScreenState extends State<CostSimulationScreen> {
  final CostSimulationService _simulationService = CostSimulationService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isCalculating = false;
  
  // Dados
  List<TalhaoModel> _talhoes = [];
  List<ProdutoEstoque> _produtos = [];
  CostSimulationModel? _simulacaoResultado;
  
  // Controllers
  final _areaController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  final List<Map<String, dynamic>> _produtosSelecionados = [];

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

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar talhões e produtos em paralelo
      final futures = await Future.wait([
        _simulationService.obterProdutosDisponiveis(),
        // TODO: Implementar carregamento de talhões
        Future.value(<TalhaoModel>[]),
      ]);

      setState(() {
        _produtos = futures[0] as List<ProdutoEstoque>;
        _talhoes = futures[1] as List<TalhaoModel>;
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
      appBar: const CustomAppBar(
        title: 'Simular Custos',
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelecaoTalhao(),
            const SizedBox(height: 16),
            _buildAreaAplicacao(),
            const SizedBox(height: 16),
            _buildProdutosSelecao(),
            const SizedBox(height: 16),
            _buildObservacoes(),
            const SizedBox(height: 24),
            _buildBotaoSimular(),
            const SizedBox(height: 24),
            if (_simulacaoResultado != null) _buildResultadoSimulacao(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoTalhao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecionar Talhão',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TalhaoModel>(
              value: _talhaoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Talhão',
                border: OutlineInputBorder(),
              ),
              items: _talhoes.map((talhao) {
                return DropdownMenuItem(
                  value: talhao,
                  child: Text('${talhao.name} (${talhao.area.toStringAsFixed(2)} ha)'),
                );
              }).toList(),
              onChanged: (TalhaoModel? value) {
                setState(() {
                  _talhaoSelecionado = value;
                  if (value != null) {
                    _areaController.text = value.area.toStringAsFixed(2);
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione um talhão';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaAplicacao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Área de Aplicação',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Área (hectares)',
                border: OutlineInputBorder(),
                suffixText: 'ha',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
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

  Widget _buildProdutosSelecao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produtos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _adicionarProduto,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_produtosSelecionados.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nenhum produto selecionado',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_produtosSelecionados.asMap().entries.map((entry) {
                final index = entry.key;
                final produto = entry.value;
                return _buildProdutoItem(index, produto);
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoItem(int index, Map<String, dynamic> produto) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    produto['nome'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: () => _removerProduto(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: produto['dose']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Dose por ha',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final dose = double.tryParse(value) ?? 0.0;
                      _produtosSelecionados[index]['dose'] = dose;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${produto['unidade'] ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacoes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações adicionais',
                border: OutlineInputBorder(),
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
        onPressed: _isCalculating ? null : _simularCustos,
        icon: _isCalculating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.calculate),
        label: Text(_isCalculating ? 'Calculando...' : 'Simular Custos'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildResultadoSimulacao() {
    if (_simulacaoResultado == null) return const SizedBox.shrink();

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Simulação Concluída',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResumoCustos(),
            const SizedBox(height: 16),
            _buildDetalhesProdutos(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCustos() {
    return Row(
      children: [
        Expanded(
          child: _buildCustoCard(
            'Custo Total',
            'R\$ ${_simulacaoResultado!.custoTotal.toStringAsFixed(2)}',
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCustoCard(
            'Custo/ha',
            'R\$ ${_simulacaoResultado!.custoPorHectare.toStringAsFixed(2)}',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildCustoCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesProdutos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhes dos Produtos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...(_simulacaoResultado!.produtos.map((produto) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(produto.nomeProduto),
              ),
              Expanded(
                child: Text('${produto.dosePorHa} ${produto.unidade}/ha'),
              ),
              Expanded(
                child: Text(
                  'R\$ ${produto.custoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ))),
      ],
    );
  }

  void _adicionarProduto() {
    showDialog(
      context: context,
      builder: (context) => _buildDialogSelecaoProduto(),
    );
  }

  Widget _buildDialogSelecaoProduto() {
    return AlertDialog(
      title: const Text('Selecionar Produto'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _produtos.length,
          itemBuilder: (context, index) {
            final produto = _produtos[index];
            return ListTile(
              title: Text(produto.nome),
              subtitle: Text('${produto.tipo} • ${produto.unidade}'),
              trailing: Text('R\$ ${produto.precoUnitario.toStringAsFixed(2)}'),
              onTap: () {
                Navigator.pop(context);
                _produtosSelecionados.add({
                  'id': produto.id,
                  'nome': produto.nome,
                  'tipo': produto.tipo,
                  'unidade': produto.unidade,
                  'preco': produto.precoUnitario,
                  'dose': 0.0,
                });
                setState(() {});
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  void _removerProduto(int index) {
    setState(() {
      _produtosSelecionados.removeAt(index);
    });
  }

  Future<void> _simularCustos() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_talhaoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um talhão'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um produto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final areaHa = double.parse(_areaController.text);
      
      final simulacao = await _simulationService.simularCustos(
        talhaoId: _talhaoSelecionado!.id,
        talhaoNome: _talhaoSelecionado!.nome,
        areaHa: areaHa,
        produtosSimulacao: _produtosSelecionados,
        observacoes: _observacoesController.text,
      );

      setState(() {
        _simulacaoResultado = simulacao;
        _isCalculating = false;
      });

      if (simulacao != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulação concluída: R\$ ${simulacao.custoTotal.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro na simulação: $e');
      setState(() {
        _isCalculating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na simulação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
