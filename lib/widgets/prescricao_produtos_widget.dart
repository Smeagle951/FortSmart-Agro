import 'package:flutter/material.dart';
import '../models/prescricao_model.dart';
import '../modules/stock/models/stock_product_model.dart';
import '../modules/stock/services/stock_service.dart';

import '../utils/app_colors.dart';

/// Widget para seleção e configuração de produtos e adjuvantes
/// Permite adicionar produtos com cálculos automáticos por tanque
class PrescricaoProdutosWidget extends StatefulWidget {
  final List<PrescricaoProdutoModel> produtos;
  final Function(List<PrescricaoProdutoModel>) onProdutosChanged;
  final double areaTrabalho;
  final double volumeLHa;
  final double capacidadeEfetiva;

  const PrescricaoProdutosWidget({
    super.key,
    required this.produtos,
    required this.onProdutosChanged,
    required this.areaTrabalho,
    required this.volumeLHa,
    required this.capacidadeEfetiva,
  });

  @override
  State<PrescricaoProdutosWidget> createState() => _PrescricaoProdutosWidgetState();
}

class _PrescricaoProdutosWidgetState extends State<PrescricaoProdutosWidget> {
  final _formKey = GlobalKey<FormState>();
  final StockService _stockService = StockService();
  
  // Controladores para o formulário de adição
  final _nomeController = TextEditingController();
  final _unidadeController = TextEditingController();
  final _doseController = TextEditingController();
  final _densidadeController = TextEditingController();
  final _percentualController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _loteController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _custoController = TextEditingController();

  // Estados
  String _unidadeSelecionada = 'L/ha';
  bool _isAdding = false;
  bool _showAddForm = false;
  bool _isLoadingProdutos = false;
  List<StockProduct> _produtosEstoque = [];

  // Lista de unidades disponíveis
  final List<String> _unidades = [
    'L/ha',
    'mL/ha',
    'kg/ha',
    'g/ha',
    '% v/v',
    '% m/v',
  ];

  @override
  void initState() {
    super.initState();
    _carregarProdutosEstoque();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _unidadeController.dispose();
    _doseController.dispose();
    _densidadeController.dispose();
    _percentualController.dispose();
    _observacoesController.dispose();
    _loteController.dispose();
    _estoqueController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  /// Carrega produtos do estoque
  Future<void> _carregarProdutosEstoque() async {
    try {
      setState(() => _isLoadingProdutos = true);
      
      print('🔄 Carregando produtos reais do estoque para prescrição...');
      final produtos = await _stockService.getAllProducts();
      
      setState(() {
        _produtosEstoque = produtos;
        _isLoadingProdutos = false;
      });
      
      print('✅ ${produtos.length} produtos reais carregados do estoque');
      
      if (produtos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum produto real encontrado no estoque. Adicione produtos no módulo Estoque de Produtos.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao carregar produtos do estoque: $e');
      setState(() => _isLoadingProdutos = false);
    }
  }

  /// Limpa dados de exemplo do estoque
  Future<void> _limparDadosExemplo() async {
    try {
      print('🧹 Limpando dados de exemplo do estoque...');
      await _stockService.limparDadosExemplo();
      
      // Recarregar produtos após limpeza
      await _carregarProdutosEstoque();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados de exemplo removidos com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erro ao limpar dados de exemplo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao limpar dados de exemplo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostra diálogo para selecionar produtos do estoque
  void _mostrarSelecaoProdutos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Selecionar do Estoque'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoadingProdutos
              ? const Center(child: CircularProgressIndicator())
              : _produtosEstoque.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum produto real encontrado no estoque',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Adicione produtos reais no módulo\n"Estoque de Produtos"',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _produtosEstoque.length,
                      itemBuilder: (context, index) {
                        final produto = _produtosEstoque[index];
                        return ListTile(
                          leading: Icon(
                            _getIconForCategory(produto.category),
                            color: _getColorForCategory(produto.category),
                          ),
                          title: Text(produto.name),
                          subtitle: Text(
                            '${produto.availableQuantity} ${produto.unit} - R\$ ${produto.unitValue.toStringAsFixed(2)}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _adicionarProdutoDoEstoque(produto),
                            child: const Text('Adicionar'),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => _limparDadosExemplo(),
            child: const Text('Limpar Exemplos'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Adiciona um produto do estoque à prescrição
  void _adicionarProdutoDoEstoque(StockProduct produto) {
    print('🔄 Adicionando produto do estoque: ${produto.name}');
    print('📊 Dados do produto:');
    print('  - ID: ${produto.id}');
    print('  - Nome: ${produto.name}');
    print('  - Unidade: ${produto.unit}');
    print('  - Quantidade disponível: ${produto.availableQuantity}');
    print('  - Valor unitário: R\$ ${produto.unitValue}');
    print('  - Lote: ${produto.lotNumber}');
    
    final prescricaoProduto = PrescricaoProdutoModel(
      produtoId: produto.id,
      produtoNome: produto.name,
      unidade: produto.unit,
      dosePorHa: 0, // Será definido pelo usuário
      densidade: null, // Não usar quantidade como densidade
      percentualVv: null,
      observacoes: 'Produto do estoque',
      loteCodigo: produto.lotNumber ?? '',
      estoqueDisponivel: produto.availableQuantity,
      custoUnitario: produto.unitValue,
    );

    final novosProdutos = List<PrescricaoProdutoModel>.from(widget.produtos);
    novosProdutos.add(prescricaoProduto);

    widget.onProdutosChanged(novosProdutos);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produto.name} adicionado à prescrição!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Retorna ícone para categoria do produto
  IconData _getIconForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'herbicida':
        return Icons.eco;
      case 'fungicida':
        return Icons.bug_report;
      case 'inseticida':
        return Icons.bug_report;
      case 'fertilizante':
        return Icons.grass;
      case 'semente':
        return Icons.grain;
      default:
        return Icons.inventory;
    }
  }

  /// Retorna cor para categoria do produto
  Color _getColorForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'herbicida':
        return Colors.green;
      case 'fungicida':
        return Colors.orange;
      case 'inseticida':
        return Colors.red;
      case 'fertilizante':
        return Colors.blue;
      case 'semente':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  /// Adiciona um novo produto
  void _adicionarProduto() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);

    try {
      final produto = PrescricaoProdutoModel(
        produtoId: 'produto_${DateTime.now().millisecondsSinceEpoch}',
        produtoNome: _nomeController.text.trim(),
        unidade: _unidadeSelecionada,
        dosePorHa: double.tryParse(_doseController.text) ?? 0,
        densidade: double.tryParse(_densidadeController.text),
        percentualVv: double.tryParse(_percentualController.text),
        observacoes: _observacoesController.text.trim(),
        loteCodigo: _loteController.text.trim(),
        estoqueDisponivel: double.tryParse(_estoqueController.text),
        custoUnitario: double.tryParse(_custoController.text),
      );

      final novosProdutos = List<PrescricaoProdutoModel>.from(widget.produtos);
      novosProdutos.add(produto);

      widget.onProdutosChanged(novosProdutos);
      _limparFormulario();
      setState(() => _showAddForm = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar produto: $e')),
      );
    } finally {
      setState(() => _isAdding = false);
    }
  }

  /// Remove um produto
  void _removerProduto(int index) {
    final novosProdutos = List<PrescricaoProdutoModel>.from(widget.produtos);
    novosProdutos.removeAt(index);
    widget.onProdutosChanged(novosProdutos);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produto removido!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Limpa o formulário
  void _limparFormulario() {
    _nomeController.clear();
    _unidadeController.clear();
    _doseController.clear();
    _densidadeController.clear();
    _percentualController.clear();
    _observacoesController.clear();
    _loteController.clear();
    _estoqueController.clear();
    _custoController.clear();
    _unidadeSelecionada = 'L/ha';
    _formKey.currentState?.reset();
  }

  /// Calcula quantidade total do produto
  double _calcularQuantidadeTotal(PrescricaoProdutoModel produto) {
    return produto.dosePorHa * widget.areaTrabalho;
  }

  /// Calcula quantidade por tanque
  double _calcularQuantidadePorTanque(PrescricaoProdutoModel produto) {
    if (widget.volumeLHa <= 0) return 0;
    final haPorTanque = widget.capacidadeEfetiva / widget.volumeLHa;
    if (produto.percentualVv != null && produto.percentualVv! > 0) {
      // Para adjuvantes em % v/v
      final volumePorTanque = haPorTanque * widget.volumeLHa;
      return (produto.percentualVv! / 100) * volumePorTanque;
    }
    return produto.dosePorHa * haPorTanque;
  }

  /// Calcula custo total do produto para toda a área
  double _calcularCustoTotal(PrescricaoProdutoModel produto) {
    final quantidadeTotal = _calcularQuantidadeTotal(produto);
    return quantidadeTotal * (produto.custoUnitario ?? 0);
  }

  /// Calcula custo por hectare do produto
  double _calcularCustoPorHectare(PrescricaoProdutoModel produto) {
    return produto.dosePorHa * (produto.custoUnitario ?? 0);
  }

  /// Calcula quantidade total para toda a área
  double _calcularQuantidadeTotalArea(PrescricaoProdutoModel produto) {
    return produto.dosePorHa * widget.areaTrabalho;
  }

  /// Verifica se há estoque suficiente
  bool _verificarEstoque(PrescricaoProdutoModel produto) {
    if (produto.estoqueDisponivel == null) return true;
    final quantidadeTotal = _calcularQuantidadeTotal(produto);
    return produto.estoqueDisponivel! >= quantidadeTotal;
  }

  /// Atualiza a dose de um produto e recalcula os valores
  void _atualizarDoseProduto(int index, double novaDose) {
    final novosProdutos = List<PrescricaoProdutoModel>.from(widget.produtos);
    if (index < novosProdutos.length) {
      novosProdutos[index] = novosProdutos[index].copyWith(dosePorHa: novaDose);
      widget.onProdutosChanged(novosProdutos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        _buildSectionTitle('Produtos e Adjuvantes'),
        
        const SizedBox(height: 16),

        // Resumo dos produtos
        if (widget.produtos.isNotEmpty) ...[
          _buildResumoProdutos(),
          const SizedBox(height: 16),
        ],

        // Lista de produtos
        if (widget.produtos.isNotEmpty) ...[
          _buildListaProdutos(),
          const SizedBox(height: 16),
        ],

        // Formulário de adição
        if (_showAddForm) ...[
          _buildFormularioAdicao(),
          const SizedBox(height: 16),
        ],

        // Botões de ação
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarSelecaoProdutos(),
                icon: const Icon(Icons.inventory),
                label: const Text('Estoque'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showAddForm = !_showAddForm);
                  if (!_showAddForm) {
                    _limparFormulario();
                  }
                },
                icon: Icon(_showAddForm ? Icons.close : Icons.add),
                label: Text(_showAddForm ? 'Cancelar' : 'Adicionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAddForm ? Colors.grey : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o título da seção
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói resumo dos produtos
  Widget _buildResumoProdutos() {
    final totalProdutos = widget.produtos.length;
    final custoTotal = widget.produtos.fold<double>(
      0, (sum, produto) => sum + _calcularCustoTotal(produto)
    );
    final custoPorHectare = widget.produtos.fold<double>(
      0, (sum, produto) => sum + _calcularCustoPorHectare(produto)
    );
    final produtosSemEstoque = widget.produtos.where((p) => !_verificarEstoque(p)).length;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    'Produtos',
                    '$totalProdutos',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    'Custo/ha',
                    'R\$ ${custoPorHectare.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    'Sem Estoque',
                    '$produtosSemEstoque',
                    Icons.warning,
                    produtosSemEstoque > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Custo Total da Aplicação: R\$ ${custoTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item do resumo
  Widget _buildResumoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Constrói lista de produtos
  Widget _buildListaProdutos() {
    return Card(
      child: Column(
        children: [
          // Cabeçalho da tabela
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Dose/ha Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Por Tanque', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Custo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(width: 40), // Espaço para botão
              ],
            ),
          ),
          
          // Lista de produtos
          ...widget.produtos.asMap().entries.map((entry) {
            final index = entry.key;
            final produto = entry.value;
            final temEstoque = _verificarEstoque(produto);
            
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produto.produtoNome,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (produto.observacoes?.isNotEmpty == true)
                            Text(
                              produto.observacoes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (produto.custoUnitario != null)
                            Text(
                              'R\$ ${produto.custoUnitario!.toStringAsFixed(2)}/${produto.unidade}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (produto.estoqueDisponivel != null)
                            Row(
                              children: [
                                Icon(
                                  temEstoque ? Icons.check_circle : Icons.warning,
                                  size: 12,
                                  color: temEstoque ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Estoque: ${produto.estoqueDisponivel!.toStringAsFixed(1)} ${produto.unidade}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: temEstoque ? Colors.blue.shade700 : Colors.red.shade700,
                                    fontWeight: temEstoque ? FontWeight.normal : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            child: TextFormField(
                              initialValue: produto.dosePorHa.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.blue.shade300),
                                ),
                                suffixText: produto.unidade,
                                suffixStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                              onChanged: (value) {
                                final novaDose = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                                _atualizarDoseProduto(index, novaDose);
                              },
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Total: ${_calcularQuantidadeTotalArea(produto).toStringAsFixed(2)} ${produto.unidade}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          '${_calcularQuantidadePorTanque(produto).toStringAsFixed(2)} ${produto.unidade}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'R\$ ${_calcularCustoPorHectare(produto).toStringAsFixed(2)}/ha',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Total: R\$ ${_calcularCustoTotal(produto).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: Colors.green.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removerProduto(index),
                      tooltip: 'Remover produto',
                    ),
                  ],
                ),
                tileColor: temEstoque ? null : Colors.red.shade50,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Constrói formulário de adição
  Widget _buildFormularioAdicao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adicionar Produto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Nome do produto
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Nome do produto é obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Unidade e dose
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _unidadeSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        border: OutlineInputBorder(),
                      ),
                      items: _unidades.map((unidade) => DropdownMenuItem(
                        value: unidade,
                        child: Text(unidade),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _unidadeSelecionada = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _doseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dose por Hectare',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null) return 'Digite um número válido';
                        if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Densidade e percentual
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _densidadeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Densidade (kg/L)',
                        border: OutlineInputBorder(),
                        helperText: 'Opcional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _percentualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '% v/v',
                        border: OutlineInputBorder(),
                        helperText: 'Para adjuvantes',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lote e estoque
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _loteController,
                      decoration: const InputDecoration(
                        labelText: 'Lote',
                        border: OutlineInputBorder(),
                        helperText: 'Opcional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _estoqueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estoque Disponível',
                        border: OutlineInputBorder(),
                        helperText: 'Opcional',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Custo unitário
              TextFormField(
                controller: _custoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custo Unitário (R\$)',
                  border: OutlineInputBorder(),
                  helperText: 'Opcional',
                ),
              ),
              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: _observacoesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                  helperText: 'Opcional',
                ),
              ),
              const SizedBox(height: 16),

              // Botão de adicionar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _adicionarProduto,
                  icon: _isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                  label: Text(_isAdding ? 'Adicionando...' : 'Adicionar Produto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
