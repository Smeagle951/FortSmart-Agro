import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prescription_model.dart';
import '../services/prescription_service.dart';
import '../../../models/talhao_model.dart';
import '../../../models/cultura_model.dart';
import '../../../models/produto_estoque.dart';
import '../../../utils/logger.dart';
import '../../../constants/app_colors.dart';

class PrescriptionFormScreen extends StatefulWidget {
  @override
  _PrescriptionFormScreenState createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final _formKey = GlobalKey<FormState>();
  final _observacoesController = TextEditingController();
  final _operadorController = TextEditingController();

  // Estados
  bool _isLoading = false;
  bool _isCalculating = false;
  bool _doseFracionada = false;
  
  // Dados carregados
  List<TalhaoModel> _talhoes = [];
  List<CulturaModel> _culturas = [];
  List<ProdutoEstoque> _produtos = [];
  List<BicoPulverizacao> _bicos = [];
  List<PrescriptionProduct> _produtosSelecionados = [];
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  CulturaModel? _culturaSelecionada;
  TipoAplicacao _tipoAplicacao = TipoAplicacao.terrestre;
  BicoPulverizacao? _bicoSelecionado;
  
  // Opção de área manual
  bool _usarAreaManual = false;
  final _areaManualController = TextEditingController();
  final _nomeTalhaoManualController = TextEditingController();
  
  // Valores de entrada
  String _equipamento = '';
  double _capacidadeTanque = 600.0;
  double _vazaoPorHectare = 150.0;
  double _vazaoBico = 0.8;
  double _pressaoBico = 2.0;
  
  // Cálculos
  Map<String, dynamic>? _calculos;
  Map<String, dynamic>? _validacaoEstoque;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _operadorController.text = 'Operador Padrão';
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _operadorController.dispose();
    _areaManualController.dispose();
    _nomeTalhaoManualController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _prescriptionService.carregarTalhoes(),
        _prescriptionService.carregarCulturas(),
        _prescriptionService.carregarProdutos(),
        _prescriptionService.carregarBicos(),
      ]);

      setState(() {
        _talhoes = futures[0] as List<TalhaoModel>;
        _culturas = futures[1] as List<CulturaModel>;
        _produtos = futures[2] as List<ProdutoEstoque>;
        _bicos = futures[3] as List<BicoPulverizacao>;
        _isLoading = false;
      });

      if (_talhoes.isNotEmpty) {
        _talhaoSelecionado = _talhoes.first;
      }
      if (_bicos.isNotEmpty) {
        _bicoSelecionado = _bicos.first;
        _vazaoBico = _bicoSelecionado!.vazaoLMin;
        _pressaoBico = _bicoSelecionado!.pressaoBar;
      }
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
        title: Text('📋 Nova Prescrição FortSmart'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _salvarPrescricao,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24),
                    _buildDadosGerais(),
                    SizedBox(height: 24),
                    _buildConfiguracaoAplicacao(),
                    SizedBox(height: 24),
                    _buildProdutosSection(),
                    SizedBox(height: 24),
                    if (_calculos != null) _buildCalculosSection(),
                    SizedBox(height: 24),
                    _buildObservacoesSection(),
                    SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.science,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescrição Agronômica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cálculos automáticos de calda e custos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDadosGerais() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Dados Gerais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Opções de configuração
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuração da Área e Cultura',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Opção 1: Usar talhão real
                    RadioListTile<bool>(
                      title: Text('Usar talhão real do módulo talhões'),
                      subtitle: Text('Área e cultura automáticas do talhão selecionado'),
                      value: false,
                      groupValue: _usarAreaManual,
                      onChanged: (value) {
                        setState(() {
                          _usarAreaManual = false;
                          _areaManualController.clear();
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    
                    // Opção 2: Usar área e cultura manuais
                    RadioListTile<bool>(
                      title: Text('Usar área e cultura manuais'),
                      subtitle: Text('Inserir área e cultura manualmente'),
                      value: true,
                      groupValue: _usarAreaManual,
                      onChanged: (value) {
                        setState(() {
                          _usarAreaManual = true;
                          _talhaoSelecionado = null;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Campos baseados na opção selecionada
            if (!_usarAreaManual) ...[
              // Opção 1: Talhão real
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TalhaoModel>(
                      value: _talhaoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Selecionar Talhão',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.agriculture),
                        helperText: 'Área e cultura serão carregadas automaticamente',
                      ),
                      items: _talhoes.map((talhao) {
                        return DropdownMenuItem(
                          value: talhao,
                          child: Text('${talhao.name} (${talhao.area?.toStringAsFixed(1) ?? '0.0'} ha)'),
                        );
                      }).toList(),
                      onChanged: (TalhaoModel? value) {
                        setState(() {
                          _talhaoSelecionado = value;
                          // Selecionar primeira cultura disponível se não houver seleção
                          if (_culturaSelecionada == null && _culturas.isNotEmpty) {
                            _culturaSelecionada = _culturas.first;
                          }
                          _calcularPrescricao();
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Mostrar informações do talhão selecionado
              if (_talhaoSelecionado != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações do Talhão Selecionado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('• Área: ${_talhaoSelecionado!.area?.toStringAsFixed(1) ?? '0.0'} hectares'),
                      Text('• Cultura: ${_culturaSelecionada?.name ?? 'Não selecionada'}'),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Opção 2: Área e cultura manuais
              Column(
                children: [
                  // Nome do talhão manual
                  TextFormField(
                    controller: _nomeTalhaoManualController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Talhão/Área *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      helperText: 'Nome da área onde será feita a aplicação',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome do talhão é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Área e cultura
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _areaManualController,
                          decoration: InputDecoration(
                            labelText: 'Área (hectares) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                            suffixText: 'ha',
                            helperText: 'Digite a área em hectares',
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Área é obrigatória';
                            }
                            final area = double.tryParse(value);
                            if (area == null || area <= 0) {
                              return 'Área deve ser maior que zero';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _calcularPrescricao();
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<CulturaModel>(
                          value: _culturaSelecionada,
                          decoration: InputDecoration(
                            labelText: 'Selecionar Cultura *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.eco),
                            helperText: 'Escolha a cultura para a prescrição',
                          ),
                          items: _culturas.map((cultura) {
                            return DropdownMenuItem(
                              value: cultura,
                              child: Text(cultura.name),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null) {
                              return 'Cultura é obrigatória';
                            }
                            return null;
                          },
                          onChanged: (CulturaModel? value) {
                            setState(() {
                              _culturaSelecionada = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Informação sobre aplicação fora de talhão
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta opção é ideal para aplicações fora de talhões cadastrados, como áreas de teste, bordas de propriedade ou aplicações pontuais.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            
            // Tipo de aplicação
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoAplicacao>(
                    value: _tipoAplicacao,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Aplicação',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(_tipoAplicacao.icon),
                    ),
                    items: TipoAplicacao.values.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Row(
                          children: [
                            Icon(tipo.icon, color: tipo.color),
                            SizedBox(width: 8),
                            Text(tipo.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (TipoAplicacao? value) {
                      setState(() {
                        _tipoAplicacao = value!;
                        _calcularPrescricao();
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_tipoAplicacao == TipoAplicacao.terrestre)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Equipamento',
                  border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build),
                ),
                onChanged: (value) {
                  _equipamento = value;
                },
              ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Operador',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    controller: _operadorController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o operador';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracaoAplicacao() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Configuração da Aplicação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Capacidade do Tanque (L)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    initialValue: _capacidadeTanque.toString(),
                    onChanged: (value) {
                      _capacidadeTanque = double.tryParse(value) ?? 600.0;
                      _calcularPrescricao();
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Vazão (L/ha)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    initialValue: _vazaoPorHectare.toString(),
                    onChanged: (value) {
                      _vazaoPorHectare = double.tryParse(value) ?? 150.0;
                      _calcularPrescricao();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<BicoPulverizacao>(
                    value: _bicoSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Bico de Pulverização',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.water),
                    ),
                    items: _bicos.map((bico) {
                      return DropdownMenuItem(
                        value: bico,
                        child: Text('${bico.nome} (${bico.vazaoLMin} L/min)'),
                      );
                    }).toList(),
                    onChanged: (BicoPulverizacao? value) {
                      setState(() {
                        _bicoSelecionado = value;
                        if (value != null) {
                          _vazaoBico = value.vazaoLMin;
                          _pressaoBico = value.pressaoBar;
                        }
                        _calcularPrescricao();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: Text('Dose Fracionada'),
                    subtitle: Text('Permitir tanques parciais'),
                    value: _doseFracionada,
                    onChanged: (bool value) {
                      setState(() {
                        _doseFracionada = value;
                        _calcularPrescricao();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutosSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Produtos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _adicionarProduto,
                  icon: Icon(Icons.add),
                  label: Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_produtosSelecionados.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum produto adicionado',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Clique em "Adicionar" para incluir produtos',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._produtosSelecionados.map((produto) => _buildProdutoCard(produto)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoCard(PrescriptionProduct produto) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(produto.tipo.icon, color: produto.tipo.color),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  produto.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removerProduto(produto),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dose: ${produto.dosePorHectare} ${produto.unidade}/ha',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: Text(
                  'Estoque: ${produto.estoqueAtual} ${produto.unidade}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: Text(
                  'Preço: R\$ ${produto.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculosSection() {
    if (_calculos == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Cálculos Automáticos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildCalculoCard(
                    'Volume Total',
                    '${_calculos!['volume_total_calda'].toStringAsFixed(1)} L',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildCalculoCard(
                    'Nº Tanques',
                    _calculos!['numero_tanques'].toString(),
                    Icons.inventory,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCalculoCard(
                    'Custo Total',
                    'R\$ ${(_calculos!['custo_total'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildCalculoCard(
                    'Custo/ha',
                    'R\$ ${(_calculos!['custo_por_hectare'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                    Icons.agriculture,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (_validacaoEstoque != null) ...[
              SizedBox(height: 16),
              _buildValidacaoEstoque(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculoCard(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          SizedBox(height: 8),
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

  Widget _buildValidacaoEstoque() {
    final estoqueSuficiente = _validacaoEstoque!['estoque_suficiente'] as bool;
    final produtosInsuficientes = _validacaoEstoque!['produtos_insuficientes'] as List;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estoqueSuficiente ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estoqueSuficiente ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                estoqueSuficiente ? Icons.check_circle : Icons.warning,
                color: estoqueSuficiente ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                estoqueSuficiente ? 'Estoque Suficiente' : 'Estoque Insuficiente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estoqueSuficiente ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (!estoqueSuficiente && produtosInsuficientes.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Produtos com estoque insuficiente:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 4),
            ...produtosInsuficientes.map((item) {
              final produto = item['produto'] as PrescriptionProduct;
              final necessario = item['quantidade_necessaria'];
              final disponivel = item['estoque_disponivel'];
              
              return Padding(
                padding: EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  '• ${produto.nome}: necessário ${necessario.toStringAsFixed(1)} ${produto.unidade}, disponível ${disponivel.toStringAsFixed(1)} ${produto.unidade}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildObservacoesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: AppColors.info),
                SizedBox(width: 8),
                Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: InputDecoration(
                labelText: 'Observações adicionais',
                border: OutlineInputBorder(),
                hintText: 'Informações importantes sobre a aplicação...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isCalculating ? null : _calcularPrescricao,
            icon: _isCalculating 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.calculate),
            label: Text(_isCalculating ? 'Calculando...' : 'Calcular'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _produtosSelecionados.isEmpty ? null : _salvarPrescricao,
            icon: Icon(Icons.save),
            label: Text('Salvar Prescrição'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _adicionarProduto() {
    showDialog(
      context: context,
      builder: (context) => _ProdutoSelectionDialog(
        produtos: _produtos,
        onProdutoSelected: (produto, dose) {
          final prescriptionProduct = _prescriptionService.converterProdutoEstoque(
            produto,
            dosePorHectare: dose,
          );
          
          setState(() {
            _produtosSelecionados.add(prescriptionProduct);
          });
          
          _calcularPrescricao();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _removerProduto(PrescriptionProduct produto) {
    setState(() {
      _produtosSelecionados.remove(produto);
    });
    _calcularPrescricao();
  }

  Future<void> _calcularPrescricao() async {
    // Verificar se tem área (talhão ou manual) e produtos
    double? area;
    if (_usarAreaManual) {
      area = double.tryParse(_areaManualController.text);
      if (area == null || area <= 0) {
        return;
      }
    } else {
      if (_talhaoSelecionado == null) {
        return;
      }
      area = _talhaoSelecionado!.area;
    }

    if (_produtosSelecionados.isEmpty) {
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final calculos = _prescriptionService.calcularDetalhesPrescricao(
        areaTalhao: area,
        vazaoPorHectare: _vazaoPorHectare,
        capacidadeTanque: _capacidadeTanque,
        produtos: _produtosSelecionados,
        doseFracionada: _doseFracionada,
      );

      // Simular validação de estoque
      final validacaoEstoque = {
        'estoque_suficiente': _produtosSelecionados.every((p) => p.temEstoqueSuficiente()),
        'produtos_insuficientes': _produtosSelecionados
            .where((p) => !p.temEstoqueSuficiente())
            .map((p) => {
              'produto': p,
              'quantidade_necessaria': p.dosePorHectare * _talhaoSelecionado!.area,
              'estoque_disponivel': p.estoqueAtual,
            })
            .toList(),
      };

      setState(() {
        _calculos = calculos;
        _validacaoEstoque = validacaoEstoque;
        _isCalculating = false;
      });
    } catch (e) {
      Logger.error('❌ Erro ao calcular prescrição: $e');
      setState(() {
        _isCalculating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao calcular prescrição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvarPrescricao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar se tem talhão selecionado ou dados manuais
    if (!_usarAreaManual && _talhaoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione um talhão ou use a opção de área manual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_usarAreaManual && _nomeTalhaoManualController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Informe o nome do talhão/área'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adicione pelo menos um produto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Determinar ID e nome do talhão baseado na opção selecionada
      String talhaoId;
      String talhaoNome;
      
      if (_usarAreaManual) {
        talhaoId = 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';
        talhaoNome = _nomeTalhaoManualController.text.trim();
      } else {
        talhaoId = _talhaoSelecionado!.id;
        talhaoNome = _talhaoSelecionado!.name;
      }

      final resultado = await _prescriptionService.criarPrescricao(
        talhaoId: talhaoId,
        tipoAplicacao: _tipoAplicacao,
        equipamento: _equipamento,
        capacidadeTanque: _capacidadeTanque,
        vazaoPorHectare: _vazaoPorHectare,
        doseFracionada: _doseFracionada,
        bicoSelecionado: _bicoSelecionado?.nome,
        vazaoBico: _vazaoBico,
        pressaoBico: _pressaoBico,
        produtos: _produtosSelecionados,
        operador: _operadorController.text,
        observacoes: _observacoesController.text,
        talhaoNome: talhaoNome,
        areaTalhao: _usarAreaManual ? double.tryParse(_areaManualController.text) : _talhaoSelecionado?.area,
      );

      setState(() {
        _isLoading = false;
      });

      if (resultado['sucesso']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescrição criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar prescrição: ${resultado['erro']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar prescrição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ProdutoSelectionDialog extends StatefulWidget {
  final List<ProdutoEstoque> produtos;
  final Function(ProdutoEstoque produto, double dose) onProdutoSelected;

  _ProdutoSelectionDialog({
    required this.produtos,
    required this.onProdutoSelected,
  });

  @override
  _ProdutoSelectionDialogState createState() => _ProdutoSelectionDialogState();
}

class _ProdutoSelectionDialogState extends State<_ProdutoSelectionDialog> {
  ProdutoEstoque? _produtoSelecionado;
  final _doseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar Produto'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProdutoEstoque>(
              value: _produtoSelecionado,
              decoration: InputDecoration(
                labelText: 'Produto',
                border: OutlineInputBorder(),
              ),
              items: widget.produtos.map((produto) {
                return DropdownMenuItem(
                  value: produto,
                  child: Text('${produto.nome} (${produto.saldoAtual} ${produto.unidade})'),
                );
              }).toList(),
              onChanged: (ProdutoEstoque? value) {
                setState(() {
                  _produtoSelecionado = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _doseController,
              decoration: InputDecoration(
                labelText: 'Dose por hectare',
                border: OutlineInputBorder(),
                suffixText: _produtoSelecionado?.unidade ?? '',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _produtoSelecionado == null || _doseController.text.isEmpty
              ? null
              : () {
                  final dose = double.tryParse(_doseController.text) ?? 0.0;
                  if (dose > 0) {
                    widget.onProdutoSelected(_produtoSelecionado!, dose);
                  }
                },
          child: Text('Adicionar'),
        ),
      ],
    );
  }
}
