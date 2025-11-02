import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/area_formatter.dart';
import '../models/produto_estoque.dart';
import '../database/daos/produto_estoque_dao.dart';

/// Classe para produtos selecionados com suas doses
class ProdutoSelecionado {
  final ProdutoEstoque produto;
  double dosePorHectare;
  String unidade;
  
  ProdutoSelecionado({
    required this.produto,
    required this.dosePorHectare,
    required this.unidade,
  });
}

/// Widget calculadora de doses para prescrições agronômicas
/// Calcula doses por hectare e por aplicação com validação em tempo real
class DosageCalculatorWidget extends StatefulWidget {
  final double? totalArea;
  final Function(double dosagePerHectare, double dosagePerApplication, double totalDosage, double applicationVolume)? onCalculationChanged;
  final String? productName;
  final String? initialDosagePerHectare;
  final String? initialApplicationVolume;
  final Function(Map<String, dynamic>)? onApplicationDataChanged;

  const DosageCalculatorWidget({
    Key? key,
    this.totalArea,
    this.onCalculationChanged,
    this.productName,
    this.initialDosagePerHectare,
    this.initialApplicationVolume,
    this.onApplicationDataChanged,
  }) : super(key: key);

  @override
  State<DosageCalculatorWidget> createState() => _DosageCalculatorWidgetState();
}

class _DosageCalculatorWidgetState extends State<DosageCalculatorWidget> {
  final _dosagePerHectareController = TextEditingController();
  final _applicationVolumeController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _tankVolumeController = TextEditingController();
  final _technicalResponsibleController = TextEditingController();
  final _operatorController = TextEditingController();
  final _doserController = TextEditingController();
  
  // Resultados calculados
  double _dosagePerHectare = 0.0;
  double _dosagePerApplication = 0.0;
  double _totalDosage = 0.0;
  double _applicationVolume = 0.0;
  double _totalArea = 0.0;
  double _tankVolume = 0.0;
  int _numberOfFlights = 0;
  int _numberOfRefills = 0;
  
  // Unidades selecionadas
  String _dosageUnit = 'L/ha';
  String _volumeUnit = 'L/ha';
  
  // Lista de unidades disponíveis
  final List<String> _dosageUnits = ['L/ha', 'kg/ha', 'ml/ha', 'g/ha'];
  final List<String> _volumeUnits = ['L/ha', 'ml/ha'];
  
  // Produtos do estoque
  List<ProdutoEstoque> _produtosEstoque = [];
  List<ProdutoSelecionado> _produtosSelecionados = [];
  bool _isLoadingProdutos = false;
  final ProdutoEstoqueDao _produtoEstoqueDao = ProdutoEstoqueDao();
  
  // Informações da aplicação
  DateTime _applicationDate = DateTime.now();
  List<String> _applicationTypes = [];
  String _applicationMethod = 'Terrestre'; // Terrestre ou Aérea
  String _volumeCalculationType = 'volume'; // volume ou vazao
  
  // Lista de tipos de aplicação
  final List<String> _availableApplicationTypes = [
    'Fungicida',
    'Inseticida', 
    'Herbicida',
    'Micro Nutrientes',
    'Macro Nutrientes',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _setupControllers();
    _carregarProdutosEstoque();
  }

  @override
  void dispose() {
    _dosagePerHectareController.dispose();
    _applicationVolumeController.dispose();
    _totalAreaController.dispose();
    _tankVolumeController.dispose();
    _technicalResponsibleController.dispose();
    _operatorController.dispose();
    _doserController.dispose();
    super.dispose();
  }

  /// Inicializa valores do widget
  void _initializeValues() {
    _totalArea = widget.totalArea ?? 0.0;
    _totalAreaController.text = _totalArea > 0 ? _totalArea.toStringAsFixed(2) : '';
    
    if (widget.initialDosagePerHectare != null) {
      _dosagePerHectareController.text = widget.initialDosagePerHectare!;
    }
    
    if (widget.initialApplicationVolume != null) {
      _applicationVolumeController.text = widget.initialApplicationVolume!;
    }
  }

  /// Configura listeners dos controladores
  void _setupControllers() {
    _dosagePerHectareController.addListener(_calculateDosages);
    _applicationVolumeController.addListener(_calculateDosages);
    _totalAreaController.addListener(_calculateDosages);
    _tankVolumeController.addListener(_calculateDosages);
  }

  /// Carrega produtos do estoque
  Future<void> _carregarProdutosEstoque() async {
    try {
      setState(() => _isLoadingProdutos = true);
      
      print('🔄 Carregando produtos do estoque para calculadora...');
      
      // Debug: verificar se o DAO está funcionando
      print('🔍 Verificando DAO: ${_produtoEstoqueDao.runtimeType}');
      
      // Teste: verificar se o banco de dados está acessível
      try {
        final db = await _produtoEstoqueDao.database;
        print('✅ Banco de dados acessível');
        
        // Verificar se a tabela existe
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='produtos_estoque'"
        );
        print('📋 Tabela produtos_estoque existe: ${tables.isNotEmpty}');
        
        if (tables.isNotEmpty) {
          // Contar registros na tabela
          final count = await db.rawQuery("SELECT COUNT(*) as count FROM produtos_estoque");
          print('📊 Total de registros na tabela: ${count.first['count']}');
        }
      } catch (dbError) {
        print('❌ Erro ao acessar banco de dados: $dbError');
      }
      
      final produtos = await _produtoEstoqueDao.buscarTodos();
      
      setState(() {
        _produtosEstoque = produtos;
        _isLoadingProdutos = false;
      });
      
      print('✅ ${produtos.length} produtos carregados do estoque');
      
      // Debug: mostrar detalhes dos produtos carregados
      if (produtos.isNotEmpty) {
        print('📦 Produtos encontrados:');
        for (var produto in produtos) {
          print('  - ${produto.nome} (${produto.tipo.name}) - ${produto.saldoAtual} ${produto.unidade}');
        }
      } else {
        print('⚠️ Nenhum produto encontrado no estoque');
        print('💡 Sugestão: Cadastre produtos no módulo Estoque de Produtos');
        print('🔧 Verifique se a tabela "produtos_estoque" existe no banco de dados');
      }
    } catch (e) {
      print('❌ Erro ao carregar produtos do estoque: $e');
      print('🔧 Stack trace: ${e.toString()}');
      setState(() => _isLoadingProdutos = false);
    }
  }

  /// Adiciona produto à lista de selecionados
  void _adicionarProduto(ProdutoEstoque produto) {
    // Verificar se o produto já foi selecionado
    bool jaExiste = _produtosSelecionados.any((p) => p.produto.id == produto.id);
    
    if (!jaExiste) {
      setState(() {
        _produtosSelecionados.add(ProdutoSelecionado(
          produto: produto,
          dosePorHectare: _obterDoseRecomendada(produto),
          unidade: _obterUnidadeRecomendada(produto),
        ));
      });
      
      _calculateDosages();
      _notifyApplicationDataChanged();
    }
  }
  
  /// Remove produto da lista de selecionados
  void _removerProduto(ProdutoSelecionado produtoSelecionado) {
    setState(() {
      _produtosSelecionados.remove(produtoSelecionado);
    });
    
    _calculateDosages();
    _notifyApplicationDataChanged();
  }
  
  /// Atualiza dose de um produto selecionado
  void _atualizarDoseProduto(ProdutoSelecionado produtoSelecionado, double novaDose) {
    setState(() {
      produtoSelecionado.dosePorHectare = novaDose;
    });
    
    _calculateDosages();
    _notifyApplicationDataChanged();
  }
  
  /// Atualiza unidade de um produto selecionado
  void _atualizarUnidadeProduto(ProdutoSelecionado produtoSelecionado, String novaUnidade) {
    setState(() {
      produtoSelecionado.unidade = novaUnidade;
    });
    
    _calculateDosages();
    _notifyApplicationDataChanged();
  }

  /// Obtém dose recomendada baseada no tipo do produto
  double _obterDoseRecomendada(ProdutoEstoque produto) {
    switch (produto.tipo) {
      case TipoProduto.herbicida:
        return 2.0; // L/ha
      case TipoProduto.inseticida:
        return 0.5; // L/ha
      case TipoProduto.fungicida:
        return 1.0; // L/ha
      case TipoProduto.fertilizante:
        return 200.0; // kg/ha
      case TipoProduto.adjuvante:
        return 0.2; // L/ha
      case TipoProduto.semente:
        return 50.0; // kg/ha
      default:
        return 1.0; // L/ha
    }
  }

  /// Obtém unidade recomendada baseada no tipo do produto
  String _obterUnidadeRecomendada(ProdutoEstoque produto) {
    switch (produto.tipo) {
      case TipoProduto.fertilizante:
      case TipoProduto.semente:
        return 'kg/ha';
      case TipoProduto.herbicida:
      case TipoProduto.inseticida:
      case TipoProduto.fungicida:
      case TipoProduto.adjuvante:
        return 'L/ha';
      default:
        return 'L/ha';
    }
  }
  
  /// Notifica mudanças nos dados da aplicação
  void _notifyApplicationDataChanged() {
    final applicationData = {
      'applicationTypes': _applicationTypes,
      'applicationDate': _applicationDate,
      'technicalResponsible': _technicalResponsibleController.text,
      'operator': _operatorController.text,
      'doser': _doserController.text,
      'applicationMethod': _applicationMethod,
      'volumeCalculationType': _volumeCalculationType,
      'totalArea': _totalArea,
      'products': _produtosSelecionados.map((p) => {
        'productId': p.produto.id,
        'productName': p.produto.nome,
        'dosePerHectare': p.dosePorHectare,
        'unit': p.unidade,
        'totalDose': p.dosePorHectare * _totalArea,
      }).toList(),
      'tankVolume': _tankVolume,
      'applicationVolume': _applicationVolume,
      'numberOfFlights': _numberOfFlights,
      'numberOfRefills': _numberOfRefills,
    };
    
    widget.onApplicationDataChanged?.call(applicationData);
  }

  /// Calcula todas as doses baseado nos valores inseridos
  void _calculateDosages() {
    try {
      // Obter valores dos campos
      _applicationVolume = double.tryParse(_applicationVolumeController.text.replaceAll(',', '.')) ?? 0.0;
      _totalArea = double.tryParse(_totalAreaController.text.replaceAll(',', '.')) ?? 0.0;
      _tankVolume = double.tryParse(_tankVolumeController.text.replaceAll(',', '.')) ?? 0.0;
      
      // Calcular dose total considerando todos os produtos selecionados
      _dosagePerHectare = _produtosSelecionados.fold(0.0, (sum, produto) => sum + produto.dosePorHectare);
      _dosagePerApplication = _dosagePerHectare * _totalArea;
      _totalDosage = _dosagePerApplication;
      
      // Calcular número de voos/recargas
      if (_applicationMethod == 'Aérea') {
        if (_applicationVolume > 0) {
          _numberOfFlights = (_applicationVolume * _totalArea / _tankVolume).ceil();
        }
      } else { // Terrestre
        if (_applicationVolume > 0) {
          _numberOfRefills = (_applicationVolume * _totalArea / _tankVolume).ceil();
        }
      }
      
      // Notificar callback com os valores calculados
      widget.onCalculationChanged?.call(
        _dosagePerHectare,
        _dosagePerApplication,
        _totalDosage,
        _applicationVolume,
      );
      
      // Notificar mudanças nos dados da aplicação
      _notifyApplicationDataChanged();
      
      // Atualizar UI
      setState(() {});
    } catch (e) {
      print('Erro no cálculo de doses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            _buildHeader(),
            const SizedBox(height: 16),
            
            // Seção 1 - Informações Gerais da Aplicação
            _buildApplicationInfoSection(),
            const SizedBox(height: 16),
            
            // Seção 2 - Produtos Utilizados
            _buildProductsSection(),
            const SizedBox(height: 16),
            
            // Seção 3 - Área de Aplicação
            _buildAreaSection(),
            const SizedBox(height: 16),
            
            // Seção 4 - Volume de Aplicação
            _buildVolumeSection(),
            const SizedBox(height: 16),
            
            // Seção 5 - Resultados dos Cálculos
            _buildCalculationResults(),
            const SizedBox(height: 16),
            
            // Resumo da aplicação
            _buildApplicationSummary(),
          ],
        ),
      ),
    );
  }

  /// Constrói seção de informações gerais da aplicação
  Widget _buildApplicationInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Informações Gerais da Aplicação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tipo de Aplicação (seletor múltiplo)
          Text(
            'Tipo de Aplicação:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableApplicationTypes.map((type) {
              final isSelected = _applicationTypes.contains(type);
              return FilterChip(
                label: Text(type, style: TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _applicationTypes.add(type);
                    } else {
                      _applicationTypes.remove(type);
                    }
                  });
                  _notifyApplicationDataChanged();
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue[700],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          
          // Data da Aplicação
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _applicationDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _applicationDate = date;
                      });
                      _notifyApplicationDataChanged();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          '${_applicationDate.day.toString().padLeft(2, '0')}/${_applicationDate.month.toString().padLeft(2, '0')}/${_applicationDate.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Responsável Técnico, Operador e Dosador
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _technicalResponsibleController,
                  decoration: InputDecoration(
                    labelText: 'Responsável Técnico',
                    hintText: 'Nome do técnico',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.person, size: 16, color: Colors.blue[700]),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => _notifyApplicationDataChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _operatorController,
                  decoration: InputDecoration(
                    labelText: 'Operador',
                    hintText: 'Nome do operador',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.drive_eta, size: 16, color: Colors.green[700]),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => _notifyApplicationDataChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Dosador (opcional)
          TextFormField(
            controller: _doserController,
            decoration: InputDecoration(
              labelText: 'Dosador (Opcional)',
              hintText: 'Nome do dosador',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.settings, size: 16, color: Colors.orange[700]),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (_) => _notifyApplicationDataChanged(),
          ),
        ],
      ),
    );
  }

  /// Constrói seção de produtos utilizados
  Widget _buildProductsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.green[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Produtos Utilizados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Seleção de produtos
          _buildProductSelector(),
          const SizedBox(height: 12),
          
          // Lista de produtos selecionados
          if (_produtosSelecionados.isNotEmpty) ...[
            Text(
              'Produtos Selecionados:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            ..._produtosSelecionados.map((produtoSelecionado) => _buildSelectedProductCard(produtoSelecionado)),
          ],
        ],
      ),
    );
  }

  /// Constrói seção de área de aplicação
  Widget _buildAreaSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.crop_landscape, color: Colors.orange[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Área de Aplicação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Opção Manual
          TextFormField(
            controller: _totalAreaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Área Total (Manual)',
              hintText: '0,00',
              suffixText: 'ha',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.edit, color: Colors.orange[700], size: 18),
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          
          // TODO: Adicionar opção automática com talhões quando disponível
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Opção automática com talhões será implementada em breve',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói seção de volume de aplicação
  Widget _buildVolumeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.purple[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Volume de Aplicação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Método de aplicação
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Terrestre', style: TextStyle(fontSize: 12)),
                  subtitle: const Text('> 20 L/ha', style: TextStyle(fontSize: 10)),
                  value: 'Terrestre',
                  groupValue: _applicationMethod,
                  onChanged: (value) {
                    setState(() {
                      _applicationMethod = value!;
                    });
                    _calculateDosages();
                  },
                  activeColor: Colors.purple[700],
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Aérea', style: TextStyle(fontSize: 12)),
                  subtitle: const Text('< 20 L/ha', style: TextStyle(fontSize: 10)),
                  value: 'Aérea',
                  groupValue: _applicationMethod,
                  onChanged: (value) {
                    setState(() {
                      _applicationMethod = value!;
                    });
                    _calculateDosages();
                  },
                  activeColor: Colors.purple[700],
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tipo de cálculo
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Volume do Tanque', style: TextStyle(fontSize: 12)),
                  value: 'volume',
                  groupValue: _volumeCalculationType,
                  onChanged: (value) {
                    setState(() {
                      _volumeCalculationType = value!;
                    });
                    _calculateDosages();
                  },
                  activeColor: Colors.purple[700],
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Vazão por Hectare', style: TextStyle(fontSize: 12)),
                  value: 'vazao',
                  groupValue: _volumeCalculationType,
                  onChanged: (value) {
                    setState(() {
                      _volumeCalculationType = value!;
                    });
                    _calculateDosages();
                  },
                  activeColor: Colors.purple[700],
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Campos de entrada
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tankVolumeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Volume do Tanque',
                    hintText: '500',
                    suffixText: 'L',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.local_drink, color: Colors.purple[700], size: 18),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _applicationVolumeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Volume por Hectare',
                    hintText: '50',
                    suffixText: 'L/ha',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.water_drop, color: Colors.purple[700], size: 18),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói seletor de produtos
  Widget _buildProductSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Produto do Estoque',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              IconButton(
                onPressed: _carregarProdutosEstoque,
                icon: Icon(Icons.refresh, color: Colors.blue[700], size: 18),
                tooltip: 'Recarregar produtos',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_isLoadingProdutos)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_produtosEstoque.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.orange[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Nenhum produto cadastrado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para usar a calculadora de doses, você precisa cadastrar produtos no módulo Estoque de Produtos.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[600], size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Acesse: Menu → Estoque de Produtos → Novo Produto',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<ProdutoEstoque>(
              value: null, // Sempre null para permitir seleção múltipla
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Adicionar Produto',
                hintText: 'Escolha um produto para adicionar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(Icons.add, color: Colors.green[700], size: 18),
              ),
              items: _produtosEstoque.where((produto) => 
                !_produtosSelecionados.any((p) => p.produto.id == produto.id)
              ).map((produto) {
                return DropdownMenuItem<ProdutoEstoque>(
                  value: produto,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        produto.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${produto.tipo.name.toUpperCase()} • ${_formatarNumeroBrasileiro(produto.saldoAtual)} ${produto.unidade}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (ProdutoEstoque? produto) {
                if (produto != null) {
                  _adicionarProduto(produto);
                }
              },
            ),
        ],
      ),
    );
  }

  /// Constrói card de produto selecionado
  Widget _buildSelectedProductCard(ProdutoSelecionado produtoSelecionado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  produtoSelecionado.produto.nome,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removerProduto(produtoSelecionado),
                icon: Icon(Icons.remove_circle, color: Colors.red[700], size: 16),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: 'Remover produto',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Dose por hectare
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: produtoSelecionado.dosePorHectare.toStringAsFixed(2),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Dose por Hectare',
                    hintText: '0,00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (value) {
                    final dose = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                    _atualizarDoseProduto(produtoSelecionado, dose);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<String>(
                  value: produtoSelecionado.unidade,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                  items: _dosageUnits.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit, style: const TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _atualizarUnidadeProduto(produtoSelecionado, value);
                    }
                  },
                ),
              ),
            ],
          ),
          
          // Informações do produto
          const SizedBox(height: 4),
          Text(
            'Saldo: ${_formatarNumeroBrasileiro(produtoSelecionado.produto.saldoAtual)} ${produtoSelecionado.produto.unidade} • R\$ ${_formatarNumeroBrasileiro(produtoSelecionado.produto.precoUnitario)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói cabeçalho do widget
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calculate,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculadora de Doses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (widget.productName != null)
                Text(
                  widget.productName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói campos de entrada
  Widget _buildInputFields() {
    return Column(
      children: [
        // Área total
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _totalAreaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Área Total',
                  hintText: '0,00',
                  suffixText: 'ha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(Icons.crop_landscape, color: Colors.green[700], size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AreaFormatter.formatArea(_totalArea),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Dose por hectare
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _dosagePerHectareController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Dose por Hectare',
                  hintText: '0,00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(Icons.local_pharmacy, color: Colors.blue[700], size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _dosageUnit,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: _dosageUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dosageUnit = value!;
                  });
                  _calculateDosages();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Volume de aplicação
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _applicationVolumeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Volume de Aplicação',
                  hintText: '0,00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(Icons.water_drop, color: Colors.cyan[700], size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _volumeUnit,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: _volumeUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _volumeUnit = value!;
                  });
                  _calculateDosages();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói resultados dos cálculos
  Widget _buildCalculationResults() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📊 Resultados dos Cálculos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  icon: Icons.straighten,
                  title: 'Dose Total/Ha',
                  value: '${_formatarNumeroBrasileiro(_dosagePerHectare)} L/ha',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildResultCard(
                  icon: Icons.area_chart,
                  title: 'Dose Total',
                  value: '${_formatarNumeroBrasileiro(_dosagePerApplication)} L',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  icon: Icons.water_drop,
                  title: 'Volume/ha',
                  value: '${_formatarNumeroBrasileiro(_applicationVolume)} L/ha',
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildResultCard(
                  icon: Icons.calculate,
                  title: 'Volume Total',
                  value: '${_formatarNumeroBrasileiro(_applicationVolume * _totalArea)} L',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  icon: _applicationMethod == 'Aérea' ? Icons.flight : Icons.local_drink,
                  title: _applicationMethod == 'Aérea' ? 'Nº de Voos' : 'Nº de Recargas',
                  value: _applicationMethod == 'Aérea' ? _numberOfFlights.toString() : _numberOfRefills.toString(),
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildResultCard(
                  icon: Icons.crop_landscape,
                  title: 'Área Total',
                  value: '${_formatarNumeroBrasileiro(_totalArea)} ha',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de resultado
  Widget _buildResultCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Constrói resumo da aplicação
  Widget _buildApplicationSummary() {
    if (_totalArea <= 0 || _dosagePerHectare <= 0) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.green[700], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Resumo da Aplicação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Área a ser tratada:', AreaFormatter.formatArea(_totalArea)),
          _buildSummaryRow('Método de aplicação:', _applicationMethod),
          _buildSummaryRow('Dose total recomendada:', '${_formatarNumeroBrasileiro(_dosagePerHectare)} L/ha'),
          _buildSummaryRow('Volume total de calda:', '${_formatarNumeroBrasileiro(_applicationVolume * _totalArea)} L'),
          _buildSummaryRow('Número de ${_applicationMethod == 'Aérea' ? 'voos' : 'recargas'}:', _applicationMethod == 'Aérea' ? _numberOfFlights.toString() : _numberOfRefills.toString()),
          
          // Produtos selecionados
          if (_produtosSelecionados.isNotEmpty) ...[
            const Divider(),
            const Text('Produtos Selecionados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            ..._produtosSelecionados.map((produtoSelecionado) {
              final totalDose = produtoSelecionado.dosePorHectare * _totalArea;
              final custoTotal = produtoSelecionado.produto.precoUnitario * totalDose;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('${produtoSelecionado.produto.nome}:', '${_formatarNumeroBrasileiro(produtoSelecionado.dosePorHectare)} ${produtoSelecionado.unidade}'),
                  _buildSummaryRow('  Quantidade total:', '${_formatarNumeroBrasileiro(totalDose)} ${produtoSelecionado.unidade.split('/')[0]}'),
                  _buildSummaryRow('  Custo total:', 'R\$ ${_formatarNumeroBrasileiro(custoTotal)}'),
                  _buildSummaryRow('  Saldo disponível:', '${_formatarNumeroBrasileiro(produtoSelecionado.produto.saldoAtual)} ${produtoSelecionado.produto.unidade}'),
                  if (totalDose > produtoSelecionado.produto.saldoAtual)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        '⚠️ Estoque insuficiente para ${produtoSelecionado.produto.nome}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
          const Divider(),
          Text(
            '💡 Verifique sempre as recomendações do fabricante e as condições climáticas antes da aplicação.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói linha do resumo
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Formata número usando padrão brasileiro (vírgula como separador decimal)
  String _formatarNumeroBrasileiro(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Formata quantidade total com conversão automática de gramas para kg
  String _formatarQuantidadeTotal(double quantidade, String unidade) {
    final unidadeBase = unidade.split('/')[0];
    
    // Se a unidade for gramas e a quantidade for >= 1000g, converter para kg
    if (unidadeBase == 'g' && quantidade >= 1000) {
      final quantidadeKg = quantidade / 1000;
      return '${_formatarNumeroBrasileiro(quantidadeKg)} kg';
    }
    
    return '${_formatarNumeroBrasileiro(quantidade)} $unidadeBase';
  }
}
