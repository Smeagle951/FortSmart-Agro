import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/produto_estoque.dart';
import '../../../../models/talhao_model.dart';
import '../../../../models/aplicacao.dart';
import '../../../../services/gestao_custos_service.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/loading_widget.dart';

class NewApplicationScreen extends StatefulWidget {
  const NewApplicationScreen({Key? key}) : super(key: key);

  @override
  State<NewApplicationScreen> createState() => _NewApplicationScreenState();
}

class _NewApplicationScreenState extends State<NewApplicationScreen> {
  final GestaoCustosService _gestaoCustosService = GestaoCustosService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSaving = false;
  
  // Dados
  List<TalhaoModel> _talhoes = [];
  List<ProdutoEstoque> _produtos = [];
  
  // Controllers
  final _areaController = TextEditingController();
  final _operadorController = TextEditingController();
  final _equipamentoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  DateTime _dataAplicacao = DateTime.now();
  final List<Map<String, dynamic>> _produtosSelecionados = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _operadorController.dispose();
    _equipamentoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar carregamento de talhões e produtos
      setState(() {
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
        title: 'Nova Aplicação',
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelecaoTalhao(),
            const SizedBox(height: 16),
            _buildDataAplicacao(),
            const SizedBox(height: 16),
            _buildAreaAplicacao(),
            const SizedBox(height: 16),
            _buildProdutosSelecao(),
            const SizedBox(height: 16),
            _buildInformacoesAdicionais(),
            const SizedBox(height: 24),
            _buildResumoCustos(),
            const SizedBox(height: 24),
            _buildBotaoSalvar(),
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

  Widget _buildDataAplicacao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data da Aplicação',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _dataAplicacao,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (selectedDate != null) {
                  setState(() {
                    _dataAplicacao = selectedDate;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      '${_dataAplicacao.day.toString().padLeft(2, '0')}/${_dataAplicacao.month.toString().padLeft(2, '0')}/${_dataAplicacao.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
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
                      _calcularCustos();
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantidade: ${_calcularQuantidadeProduto(produto).toStringAsFixed(2)} ${produto['unidade'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Custo: R\$ ${_calcularCustoProduto(produto).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacoesAdicionais() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Adicionais',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _operadorController,
              decoration: const InputDecoration(
                labelText: 'Operador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _equipamentoController,
              decoration: const InputDecoration(
                labelText: 'Equipamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCustos() {
    final custoTotal = _calcularCustoTotal();
    final custoPorHectare = _calcularCustoPorHectare();

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo de Custos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCustoCard(
                    'Custo Total',
                    'R\$ ${custoTotal.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCustoCard(
                    'Custo/ha',
                    'R\$ ${custoPorHectare.toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildBotaoSalvar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _salvarAplicacao,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar Aplicação'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
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
              subtitle: Text('${produto.tipo} • ${produto.unidade} • Estoque: ${produto.saldoAtual}'),
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
    _calcularCustos();
  }

  double _calcularQuantidadeProduto(Map<String, dynamic> produto) {
    final dose = produto['dose'] ?? 0.0;
    final area = double.tryParse(_areaController.text) ?? 0.0;
    return dose * area;
  }

  double _calcularCustoProduto(Map<String, dynamic> produto) {
    final quantidade = _calcularQuantidadeProduto(produto);
    final preco = produto['preco'] ?? 0.0;
    return quantidade * preco;
  }

  double _calcularCustoTotal() {
    double total = 0.0;
    for (final produto in _produtosSelecionados) {
      total += _calcularCustoProduto(produto);
    }
    return total;
  }

  double _calcularCustoPorHectare() {
    final area = double.tryParse(_areaController.text) ?? 0.0;
    if (area <= 0) return 0.0;
    return _calcularCustoTotal() / area;
  }

  void _calcularCustos() {
    setState(() {
      // Força o rebuild para atualizar os custos
    });
  }

  Future<void> _salvarAplicacao() async {
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
      _isSaving = true;
    });

    try {
      final areaHa = double.parse(_areaController.text);
      
      // Registrar aplicação para cada produto
      for (final produto in _produtosSelecionados) {
        final dose = produto['dose'] ?? 0.0;
        if (dose > 0) {
          final sucesso = await _gestaoCustosService.registrarAplicacao(
            talhaoId: _talhaoSelecionado!.id,
            produtoId: produto['id'],
            dosePorHa: dose,
            areaAplicadaHa: areaHa,
            dataAplicacao: _dataAplicacao,
            operador: _operadorController.text,
            equipamento: _equipamentoController.text,
            observacoes: _observacoesController.text,
          );

          if (!sucesso) {
            throw Exception('Erro ao registrar aplicação do produto ${produto['nome']}');
          }
        }
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aplicação registrada com sucesso! Custo total: R\$ ${_calcularCustoTotal().toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      Logger.error('❌ Erro ao salvar aplicação: $e');
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar aplicação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
