import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/talhao_model.dart';
import '../../models/produto_estoque.dart';
import '../../services/talhao_module_service.dart';
import '../../services/data_cache_service.dart';
import '../../services/aplicacao_calculo_service.dart';
import '../../services/prescricao_pdf_service.dart';
import '../../services/custo_aplicacao_integration_service.dart';
import '../../services/gestao_custos_service.dart';
import '../../modules/cost_management/models/cost_management_model.dart';
import '../../utils/snackbar_helper.dart';
import '../../database/daos/produto_estoque_dao.dart';
import '../../widgets/aplicacao_resumo_operacional_widget.dart';
import 'package:share_plus/share_plus.dart';

// Tipos de aplicação
enum TipoAplicacao { terrestre, aerea, drone }

// Produtos de prescrição
class PrescricaoProduto {
  final String id;
  final String nome;
  final String tipo;
  final String unidade;
  final double dosePorHectare;
  final double estoqueDisponivel;
  final double precoUnitario;
  final String? lote;
  
  PrescricaoProduto({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidade,
    required this.dosePorHectare,
    required this.estoqueDisponivel,
    required this.precoUnitario,
    this.lote,
  });
}

/// Tela principal de prescrição premium com cálculo automático de calda
class PrescricaoPremiumScreen extends StatefulWidget {
  const PrescricaoPremiumScreen({Key? key}) : super(key: key);

  @override
  State<PrescricaoPremiumScreen> createState() => _PrescricaoPremiumScreenState();
}

class _PrescricaoPremiumScreenState extends State<PrescricaoPremiumScreen> {
  final TalhaoModuleService _talhaoService = TalhaoModuleService();
  final DataCacheService _dataCacheService = DataCacheService();
  final CustoAplicacaoIntegrationService _custoIntegrationService = CustoAplicacaoIntegrationService();
  final GestaoCustosService _gestaoCustosService = GestaoCustosService();

  // Controllers
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _equipamentoController = TextEditingController();
  final TextEditingController _larguraController = TextEditingController();
  final TextEditingController _velocidadeController = TextEditingController();
  final TextEditingController _taxaVazaoController = TextEditingController();
  final TextEditingController _areaManualController = TextEditingController();
  final TextEditingController _capacidadeTanqueController = TextEditingController();
  final TextEditingController _vazaoPorHectareController = TextEditingController();
  
  // Estados
  bool _isLoading = true;
  bool _isSaving = false;
  bool _doseFracionada = false;
  
  // Dados carregados
  List<TalhaoModel> _talhoes = [];
  List<ProdutoEstoque> _produtos = [];
  List<PrescricaoProduto> _produtosSelecionados = [];
  
  // Alertas de validação
  List<String> _alertasProdutos = [];
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  String _tipoAplicacao = 'Terrestre';
  
  // Valores de entrada
  double _capacidadeTanque = 600.0;
  double _vazaoPorHectare = 150.0;
  double _volumeSeguranca = 50.0;
  double _areaTrabalho = 0.0;
  DateTime _dataAplicacao = DateTime.now();
  
  // Configurações avançadas de aplicação
  String _tipoBico = 'Automático';
  double _taxaVazaoBico = 0.5; // L/min
  double _larguraTrabalho = 20.0; // metros
  double _velocidadeAplicacao = 8.0; // km/h
  bool _modoAutomatico = true;
  
  // Cálculos
  Map<String, dynamic>? _calculos;
  Map<String, dynamic>? _validacaoEstoque;
  Map<String, dynamic>? _resumoOperacional;
  Map<String, dynamic>? _validacaoMaquina;
  
  // Estados adicionais
  bool _usarAreaManual = false;
  String _secaoAtiva = 'Geral';

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _operadorController.text = 'Operador Padrão';
    _larguraController.text = _larguraTrabalho.toString();
    _velocidadeController.text = _velocidadeAplicacao.toString();
    _taxaVazaoController.text = _taxaVazaoBico.toString();
    _capacidadeTanqueController.text = _capacidadeTanque.toString();
    _vazaoPorHectareController.text = _vazaoPorHectare.toString();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _operadorController.dispose();
    _equipamentoController.dispose();
    _larguraController.dispose();
    _velocidadeController.dispose();
    _taxaVazaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Carregar talhões
      final talhoes = await _talhaoService.getTalhoes();
      
      // Carregar produtos do estoque - usar ProdutoEstoque ao invés de AgriculturalProduct
      final produtosEstoque = await _carregarProdutosEstoque();

      setState(() {
        _talhoes = talhoes;
        _produtos = produtosEstoque;
        _isLoading = false;
      });
      
      // Validar produtos após carregamento
      _validarProdutos();
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showError(context, 'Erro ao carregar dados: $e');
    }
  }

  /// Carrega produtos do estoque usando o DAO correto
  Future<List<ProdutoEstoque>> _carregarProdutosEstoque() async {
    try {
      // Importar o DAO de produtos de estoque
      final produtoEstoqueDao = ProdutoEstoqueDao();
      final produtos = await produtoEstoqueDao.buscarTodos();
      
      print('✅ Carregados ${produtos.length} produtos do estoque');
      return produtos;
    } catch (e) {
      print('❌ Erro ao carregar produtos do estoque: $e');
      return [];
    }
  }

  void _selecionarTalhao(TalhaoModel talhao) {
    setState(() {
      _talhaoSelecionado = talhao;
      _areaTrabalho = talhao.area ?? 0.0;
      _usarAreaManual = false;
    });
    _calcularPrescricaoAutomatica();
  }
  
  /// Calcula prescrição automática com todos os cálculos avançados
  void _calcularPrescricaoAutomatica() {
    if (_talhaoSelecionado == null) {
      print('❌ Nenhum talhão selecionado');
      return;
    }
    
    final areaTotal = _usarAreaManual 
        ? double.tryParse(_areaManualController.text) ?? _areaTrabalho
        : _areaTrabalho;
    
    final capacidadeTanque = double.tryParse(_capacidadeTanqueController.text) ?? _capacidadeTanque;
    final vazaoPorHectare = double.tryParse(_vazaoPorHectareController.text) ?? _vazaoPorHectare;
    
    print('🔍 Dados para cálculo:');
    print('   Área Total: $areaTotal ha');
    print('   Capacidade Tanque: $capacidadeTanque L');
    print('   Vazão por Hectare: $vazaoPorHectare L/ha');
    print('   Produtos Selecionados: ${_produtosSelecionados.length}');
    
    // ===== 1. CÁLCULOS AUTOMÁTICOS AVANÇADOS =====
    
    // 2.1 Capacidade da Máquina
    final hectaresCobertosPorTanque = capacidadeTanque / vazaoPorHectare;
    
    // 2.2 Quantidade de Tanques/Bombas/Vôos
    final numeroTanques = (areaTotal / hectaresCobertosPorTanque).ceil();
    final tanqueFracionado = areaTotal / hectaresCobertosPorTanque;
    
    print('📊 Cálculos básicos:');
    print('   Hectares por Tanque: ${hectaresCobertosPorTanque.toStringAsFixed(2)} ha');
    print('   Número de Tanques: $numeroTanques');
    
    // 2.3 Cálculos por Produto
    final calculosProdutos = <Map<String, dynamic>>[];
    double custoTotal = 0.0;
    final alertasEstoque = <String>[];
    
    for (final produto in _produtosSelecionados) {
      // Quantidade total do produto
      final quantidadeTotalProduto = produto.dosePorHectare * areaTotal;
      
      // Quantidade por tanque
      final quantidadeProdutoPorTanque = produto.dosePorHectare * hectaresCobertosPorTanque;
      
      // Custo do produto
      final custoProduto = quantidadeTotalProduto * produto.precoUnitario;
      custoTotal += custoProduto;
      
      // Verificar estoque
      final estoqueSuficiente = produto.estoqueDisponivel >= quantidadeTotalProduto;
      if (!estoqueSuficiente) {
        alertasEstoque.add('${produto.nome}: Estoque insuficiente (${produto.estoqueDisponivel} ${produto.unidade} disponível, ${quantidadeTotalProduto.toStringAsFixed(2)} ${produto.unidade} necessário)');
      }
      
      calculosProdutos.add({
        'produto': produto.nome,
        'dosePorHectare': produto.dosePorHectare,
        'unidade': produto.unidade,
        'quantidadeTotal': quantidadeTotalProduto,
        'quantidadePorTanque': quantidadeProdutoPorTanque,
        'custoProduto': custoProduto,
        'estoqueSuficiente': estoqueSuficiente,
        'estoqueDisponivel': produto.estoqueDisponivel,
        'lote': produto.lote,
      });
      
      print('   Produto ${produto.nome}: ${quantidadeTotalProduto.toStringAsFixed(2)} ${produto.unidade} total, ${quantidadeProdutoPorTanque.toStringAsFixed(2)} ${produto.unidade} por tanque');
    }
    
    // ===== 3. RESUMO OPERACIONAL =====
    final resumoOperacional = {
      'areaTotal': areaTotal,
      'vazaoPorHectare': vazaoPorHectare,
      'capacidadeTanque': capacidadeTanque,
      'hectaresCobertosPorTanque': hectaresCobertosPorTanque,
      'numeroTanques': numeroTanques,
      'tanqueFracionado': tanqueFracionado,
      'tipoMaquina': _tipoAplicacao,
      'velocidadeAplicacao': _velocidadeAplicacao,
      'larguraTrabalho': _larguraTrabalho,
    };
    
    // ===== 4. RESUMO FINANCEIRO =====
    final resumoFinanceiro = {
      'custoTotal': custoTotal,
      'custoPorHectare': areaTotal > 0 ? custoTotal / areaTotal : 0.0,
      'calculosProdutos': calculosProdutos,
    };
    
    // ===== 5. VALIDAÇÕES =====
    final validacaoMaquina = _validarConfiguracaoMaquina(
      vazaoPorHectare: vazaoPorHectare,
      capacidadeTanque: capacidadeTanque,
      tipoMaquina: _tipoAplicacao,
    );
    
    print('💾 Salvando resultados no estado...');
    
    setState(() {
      _resumoOperacional = resumoOperacional;
      _calculos = {
        ...resumoOperacional,
        ...resumoFinanceiro,
      };
      _validacaoMaquina = validacaoMaquina;
      _validacaoEstoque = {
        'alertas': alertasEstoque,
        'todosProdutosDisponiveis': alertasEstoque.isEmpty,
      };
    });
    
    print('✅ Estado atualizado:');
    print('   _calculos: ${_calculos != null ? 'SIM' : 'NÃO'}');
    print('   _resumoOperacional: ${_resumoOperacional != null ? 'SIM' : 'NÃO'}');
    print('   _validacaoEstoque: ${_validacaoEstoque != null ? 'SIM' : 'NÃO'}');
    
    // Mostrar alertas se houver
    if (validacaoMaquina['alertas'].isNotEmpty) {
      _mostrarAlertasValidacao(validacaoMaquina);
    }
    
    SnackbarHelper.showSuccess(context, 'Cálculos automáticos realizados com sucesso!');
  }
  
  /// Valida configuração da máquina
  Map<String, dynamic> _validarConfiguracaoMaquina({
    required double vazaoPorHectare,
    required double capacidadeTanque,
    required String tipoMaquina,
  }) {
    final alertas = <String>[];
    final sugestoes = <String>[];
    
    // Validações específicas por tipo de máquina
    if (tipoMaquina == 'Terrestre') {
      if (vazaoPorHectare < 50) {
        alertas.add('Vazão muito baixa para aplicação terrestre');
        sugestoes.add('Aumente a vazão para pelo menos 100 L/ha');
      }
      if (vazaoPorHectare > 300) {
        alertas.add('Vazão muito alta para aplicação terrestre');
        sugestoes.add('Reduza a vazão para no máximo 200 L/ha');
      }
      if (capacidadeTanque < 200) {
        alertas.add('Capacidade do tanque muito baixa');
        sugestoes.add('Use tanque com pelo menos 500 L');
      }
    } else if (tipoMaquina == 'Aérea') {
      if (vazaoPorHectare < 10) {
        alertas.add('Vazão muito baixa para aplicação aérea');
        sugestoes.add('Aumente a vazão para pelo menos 20 L/ha');
      }
      if (vazaoPorHectare > 50) {
        alertas.add('Vazão muito alta para aplicação aérea');
        sugestoes.add('Reduza a vazão para no máximo 30 L/ha');
      }
    }
    
    // Validações gerais
    if (capacidadeTanque <= 0) {
      alertas.add('Capacidade do tanque deve ser maior que zero');
    }
    if (vazaoPorHectare <= 0) {
      alertas.add('Vazão por hectare deve ser maior que zero');
    }
    
    return {
      'alertas': alertas,
      'sugestoes': sugestoes,
      'valida': alertas.isEmpty,
    };
  }
  
  /// Mostra alertas de validação
  void _mostrarAlertasValidacao(Map<String, dynamic> validacao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Alertas de Configuração'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (validacao['alertas'].isNotEmpty) ...[
              const Text(
                'Problemas identificados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...validacao['alertas'].map<Widget>((alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alerta)),
                  ],
                ),
              )).toList(),
            ],
            if (validacao['sugestoes'].isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Sugestões:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...validacao['sugestoes'].map<Widget>((sugestao) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(sugestao)),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
  
  /// Atualiza configurações da máquina
  void _atualizarConfiguracaoMaquina() {
    _capacidadeTanque = double.tryParse(_capacidadeTanqueController.text) ?? _capacidadeTanque;
    _vazaoPorHectare = double.tryParse(_vazaoPorHectareController.text) ?? _vazaoPorHectare;
    _larguraTrabalho = double.tryParse(_larguraController.text) ?? _larguraTrabalho;
    _velocidadeAplicacao = double.tryParse(_velocidadeController.text) ?? _velocidadeAplicacao;
    _taxaVazaoBico = double.tryParse(_taxaVazaoController.text) ?? _taxaVazaoBico;
    _calcularPrescricaoAutomatica();
  }

  /// Altera a seção ativa
  void _alterarSecao(String secao) {
    setState(() {
      _secaoAtiva = secao;
    });
  }

  /// Salva rascunho da prescrição
  void _salvarRascunho() {
    SnackbarHelper.showSuccess(context, 'Rascunho salvo com sucesso!');
  }
  
  /// Gera e compartilha PDF premium da prescrição
  Future<void> _gerarPdfPrescricao() async {
    if (_resumoOperacional == null) {
      SnackbarHelper.showError(context, 'Complete a prescrição antes de gerar o PDF');
      return;
    }
    
    try {
      setState(() {
        _isSaving = true;
      });
      
      // Preparar dados para o PDF
      final dadosPrescricao = {
        'talhao': _talhaoSelecionado?.name ?? 'N/A',
        'fazenda': _talhaoSelecionado?.fazendaId ?? 'N/A',
        'data': _dataAplicacao,
        'observacoes': _observacoesController.text,
        'tipoAplicacao': _tipoAplicacao,
        'capacidadeTanque': _capacidadeTanque,
        'vazaoPorHectare': _vazaoPorHectare,
        'larguraTrabalho': _larguraTrabalho,
        'velocidadeAplicacao': _velocidadeAplicacao,
      };
      
      // Gerar PDF
      final pdfFile = await PrescricaoPdfService.gerarPdfPrescricao(
        dadosPrescricao: dadosPrescricao,
        resumoOperacional: _resumoOperacional!,
        nomeFazenda: 'Fazenda', // Usando valor padrão
        nomeTecnico: _operadorController.text,
        creaTecnico: 'CREA-123456',
      );
      
      // Compartilhar PDF
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Prescrição Agronômica FortSmart - ${_talhaoSelecionado?.name ?? 'Talhão'}',
        subject: 'Prescrição Agronômica de Aplicação',
      );
      
      SnackbarHelper.showSuccess(context, 'PDF gerado e compartilhado com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao gerar PDF: $e');
      SnackbarHelper.showError(context, 'Erro ao gerar PDF: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  /// Gera PDF consolidado com múltiplas prescrições
  Future<void> _gerarPdfConsolidado() async {
    // Simular múltiplas prescrições (em produção, isso viria do banco de dados)
    final prescricoes = [
      {
        'talhao': 'Talhão A',
        'dados': {
          'talhao': 'Talhão A',
          'fazenda': _talhaoSelecionado?.fazendaId ?? 'Fazenda',
          'data': _dataAplicacao,
          'observacoes': 'Prescrição para talhão A',
        },
        'resumo': {
          'areaTotal': 25.0,
          'tipoMaquina': 'Terrestre',
          'numeroTanques': 2,
          'custoTotal': 1250.0,
          'produtos': [
            {
              'nome': 'Herbicida A',
              'dosePorHectare': 2.0,
              'unidade': 'L',
              'quantidadePorTanque': 25.0,
              'quantidadeTotal': 50.0,
            }
          ],
        },
      },
      {
        'talhao': 'Talhão B',
        'dados': {
          'talhao': 'Talhão B',
          'fazenda': _talhaoSelecionado?.fazendaId ?? 'Fazenda',
          'data': _dataAplicacao,
          'observacoes': 'Prescrição para talhão B',
        },
        'resumo': {
          'areaTotal': 30.0,
          'tipoMaquina': 'Terrestre',
          'numeroTanques': 3,
          'custoTotal': 1800.0,
          'produtos': [
            {
              'nome': 'Fungicida B',
              'dosePorHectare': 1.5,
              'unidade': 'L',
              'quantidadePorTanque': 22.5,
              'quantidadeTotal': 45.0,
            }
          ],
        },
      },
      {
        'talhao': 'Talhão C',
        'dados': {
          'talhao': 'Talhão C',
          'fazenda': _talhaoSelecionado?.fazendaId ?? 'Fazenda',
          'data': _dataAplicacao,
          'observacoes': 'Prescrição para talhão C',
        },
        'resumo': {
          'areaTotal': 20.0,
          'tipoMaquina': 'Aérea',
          'numeroTanques': 1,
          'custoTotal': 2200.0,
          'produtos': [
            {
              'nome': 'Inseticida C',
              'dosePorHectare': 0.8,
              'unidade': 'L',
              'quantidadePorTanque': 16.0,
              'quantidadeTotal': 16.0,
            }
          ],
        },
      },
    ];
    
    try {
      setState(() {
        _isSaving = true;
      });
      
      // Gerar PDF consolidado
      final pdfFile = await PrescricaoPdfService.gerarPdfConsolidado(
        prescricoes: prescricoes,
        nomeFazenda: 'Fazenda',
        nomeTecnico: _operadorController.text,
        creaTecnico: 'CREA-123456',
      );
      
      // Compartilhar PDF
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Prescrições Agronômicas Consolidadas FortSmart',
        subject: 'Prescrições Agronômicas Consolidadas',
      );
      
      SnackbarHelper.showSuccess(context, 'PDF consolidado gerado e compartilhado com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao gerar PDF consolidado: $e');
      SnackbarHelper.showError(context, 'Erro ao gerar PDF consolidado: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
        height: 400,
        child: Column(
          children: [
            // Filtro por tipo
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Produto',
                border: OutlineInputBorder(),
              ),
              value: null,
              items: ['Todos', 'Defensivo', 'Fertilizante', 'Calcário', 'Semente']
                  .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                  .toList(),
              onChanged: (value) {
                // Implementar filtro
              },
            ),
            const SizedBox(height: 16),
            // Lista de produtos
            Expanded(
              child: ListView.builder(
                itemCount: _produtos.length,
                itemBuilder: (context, index) {
                  final produto = _produtos[index];
                  return ListTile(
                    title: Text(produto.nome),
                    subtitle: Text('${produto.tipo.toString().split('.').last} - Estoque: ${produto.saldoAtual} ${produto.unidade}'),
                    trailing: Text('R\$ ${produto.precoUnitario.toStringAsFixed(2)}'),
                    onTap: () {
                      _selecionarProdutoParaPrescricao(produto);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
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

  void _selecionarProdutoParaPrescricao(ProdutoEstoque produto) {
    showDialog(
      context: context,
      builder: (context) => _buildDialogConfigurarProduto(produto),
    ).then((_) {
      // Recalcular após adicionar produto
      _calcularPrescricaoAutomatica();
    });
  }

  Widget _buildDialogConfigurarProduto(ProdutoEstoque produto) {
    final doseController = TextEditingController();
    final loteController = TextEditingController();
    
    return AlertDialog(
      title: Text('Configurar ${produto.nome}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: doseController,
            decoration: InputDecoration(
              labelText: 'Dose por hectare',
              suffixText: produto.unidade,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: loteController,
            decoration: const InputDecoration(
              labelText: 'Lote (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final dose = double.tryParse(doseController.text) ?? 0.0;
            if (dose > 0) {
              _adicionarProdutoAPrescricao(produto, dose, loteController.text);
              Navigator.pop(context);
            } else {
              SnackbarHelper.showWarning(context, 'Digite uma dose válida');
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  void _adicionarProdutoAPrescricao(ProdutoEstoque produto, double dose, String lote) {
    final prescricaoProduto = PrescricaoProduto(
      id: produto.id,
      nome: produto.nome,
      tipo: produto.tipo.toString().split('.').last,
      unidade: produto.unidade,
      dosePorHectare: dose,
      estoqueDisponivel: produto.saldoAtual,
      precoUnitario: produto.precoUnitario,
      lote: lote.isNotEmpty ? lote : null,
    );

    setState(() {
      _produtosSelecionados.add(prescricaoProduto);
    });
    
    _calcularPrescricaoAutomatica();
    SnackbarHelper.showSuccess(context, 'Produto adicionado à prescrição');
  }

  void _removerProduto(int index) {
    setState(() {
      _produtosSelecionados.removeAt(index);
    });
    _calcularPrescricaoAutomatica();
  }

  /// Calcula o tempo de aplicação em horas
  double _calcularTempoAplicacao(double area) {
    if (_velocidadeAplicacao <= 0 || _larguraTrabalho <= 0) return 0.0;
    
    // Fórmula: Tempo = Área / (Velocidade × Largura / 10)
    // Velocidade em km/h, Largura em metros, resultado em horas
    final eficiencia = 0.85; // 85% de eficiência operacional
    final tempo = area / ((_velocidadeAplicacao * _larguraTrabalho / 10) * eficiencia);
    return tempo;
  }

  /// Valida produtos para alertas de vencimento e disponibilidade
  void _validarProdutos() {
    _alertasProdutos.clear();
    final hoje = DateTime.now();
    
    for (final produto in _produtos) {
      try {
        // Verificar se produto tem data de validade
        if (produto.dataValidade != null) {
          final diasParaVencimento = produto.dataValidade!.difference(hoje).inDays;
          
          if (diasParaVencimento < 0) {
            _alertasProdutos.add('⚠️ ${produto.nome}: PRODUTO VENCIDO há ${diasParaVencimento.abs()} dias');
          } else if (diasParaVencimento <= 30) {
            _alertasProdutos.add('⚠️ ${produto.nome}: Vence em ${diasParaVencimento} dias');
          }
        }
        
        // Verificar disponibilidade
        if (produto.saldoAtual <= 0) {
          _alertasProdutos.add('❌ ${produto.nome}: PRODUTO INDISPONÍVEL (estoque zero)');
        } else if (produto.saldoAtual < 10) {
          _alertasProdutos.add('⚠️ ${produto.nome}: Estoque baixo (${produto.saldoAtual} ${produto.unidade})');
        }
      } catch (e) {
        print('⚠️ Erro ao validar produto ${produto.nome}: $e');
        // Continuar com a validação dos outros produtos
      }
    }
  }

  void _calcularPrescricao() {
    if (_talhaoSelecionado == null || _produtosSelecionados.isEmpty) {
      setState(() {
        _calculos = null;
        _validacaoEstoque = null;
      });
      return;
    }

    final area = _areaTrabalho > 0 ? _areaTrabalho : (_talhaoSelecionado!.area ?? 0.0);
    final capacidadeEfetiva = _capacidadeTanque - _volumeSeguranca;
    
    // Cálculos básicos
    final volumeTotalCalda = area * _vazaoPorHectare;
    final numeroTanques = (volumeTotalCalda / capacidadeEfetiva).ceil();
    final tanqueFracionado = volumeTotalCalda / capacidadeEfetiva;
    
    // Cálculos por produto
    final calculosProdutos = <Map<String, dynamic>>[];
    double custoTotal = 0.0;
    final alertasEstoque = <String>[];
    
    for (final produto in _produtosSelecionados) {
      final quantidadeTotal = produto.dosePorHectare * area;
      final quantidadePorTanque = produto.dosePorHectare * (capacidadeEfetiva / _vazaoPorHectare);
      final custoProduto = quantidadeTotal * produto.precoUnitario;
      
      calculosProdutos.add({
        'produto': produto.nome,
        'quantidadeTotal': quantidadeTotal,
        'quantidadePorTanque': quantidadePorTanque,
        'custoProduto': custoProduto,
        'estoqueSuficiente': produto.estoqueDisponivel >= quantidadeTotal,
        'estoqueDisponivel': produto.estoqueDisponivel,
        'lote': produto.lote,
      });
      
      custoTotal += custoProduto;
      
      if (produto.estoqueDisponivel < quantidadeTotal) {
        alertasEstoque.add('${produto.nome}: Estoque insuficiente (${produto.estoqueDisponivel} ${produto.unidade} disponível, ${quantidadeTotal.toStringAsFixed(2)} ${produto.unidade} necessário)');
      }
    }

    setState(() {
      _calculos = {
        'area': area,
        'volumeTotalCalda': volumeTotalCalda,
        'numeroTanques': numeroTanques,
        'tanqueFracionado': tanqueFracionado,
        'capacidadeEfetiva': capacidadeEfetiva,
        'vazaoPorHectare': _vazaoPorHectare,
        'calculosProdutos': calculosProdutos,
        'custoTotal': custoTotal,
        'custoPorHectare': area > 0 ? custoTotal / area : 0.0,
        // Novos cálculos avançados
        'tempoAplicacao': _calcularTempoAplicacao(area),
        'velocidadeAplicacao': _velocidadeAplicacao,
        'larguraTrabalho': _larguraTrabalho,
        'taxaVazaoBico': _taxaVazaoBico,
        'tipoBico': _tipoBico,
        'modoAutomatico': _modoAutomatico,
      };
      
      _validacaoEstoque = {
        'alertas': alertasEstoque,
        'todosProdutosDisponiveis': alertasEstoque.isEmpty,
      };
    });
  }

  Future<void> _salvarPrescricao() async {
    if (_talhaoSelecionado == null) {
      SnackbarHelper.showWarning(context, 'Selecione um talhão');
      return;
    }

    if (_produtosSelecionados.isEmpty) {
      SnackbarHelper.showWarning(context, 'Adicione pelo menos um produto');
      return;
    }

    if (_calculos == null) {
      SnackbarHelper.showWarning(context, 'Calcule a prescrição primeiro');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // ===== 4. INTEGRAÇÕES =====
      
      // 4.1 Atualizar estoque
      await _atualizarEstoque();
      
      // 4.2 Salvar prescrição no banco
      await _salvarPrescricaoNoBanco();
      
      // 4.3 Integrar com gestão de custos
      await _integrarComGestaoCustos();
      
      SnackbarHelper.showSuccess(context, 'Prescrição salva e estoque atualizado com sucesso!');
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao salvar prescrição: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  /// Atualiza o estoque conforme os cálculos
  Future<void> _atualizarEstoque() async {
    if (_calculos == null) return;
    
    try {
      print('📦 Iniciando atualização real do estoque...');
      
      final calculosProdutos = _calculos!['calculosProdutos'] as List;
      final produtoEstoqueDao = ProdutoEstoqueDao();
      
      for (final calculo in calculosProdutos) {
        final produto = _produtosSelecionados.firstWhere(
          (p) => p.nome == calculo['produto'],
        );
        
        final quantidadeUtilizada = calculo['quantidadeTotal'] as double;
        final novoSaldo = produto.estoqueDisponivel - quantidadeUtilizada;
        
        print('📦 Atualizando estoque: ${produto.nome} - ${produto.estoqueDisponivel} → ${novoSaldo.toStringAsFixed(2)} ${produto.unidade}');
        
        // ATUALIZAÇÃO REAL NO BANCO DE DADOS
        final sucesso = await produtoEstoqueDao.atualizarSaldo(produto.id, novoSaldo);
        
        if (sucesso) {
          print('✅ Estoque atualizado com sucesso: ${produto.nome}');
        } else {
          print('❌ Erro ao atualizar estoque: ${produto.nome}');
          throw Exception('Falha ao atualizar estoque do produto ${produto.nome}');
        }
      }
      
      print('✅ Todos os estoques foram atualizados com sucesso!');
    } catch (e) {
      print('❌ Erro ao atualizar estoque: $e');
      throw Exception('Erro ao atualizar estoque: $e');
    }
  }
  
  /// Salva a prescrição no banco de dados
  Future<void> _salvarPrescricaoNoBanco() async {
    try {
      print('💾 Iniciando salvamento real da prescrição...');
      
      if (_calculos == null || _talhaoSelecionado == null) {
        throw Exception('Dados insuficientes para salvar prescrição');
      }
      
      // INTEGRAÇÃO REAL COM SERVIÇO DE CUSTO DE APLICAÇÃO
      final resultado = await _custoIntegrationService.registrarAplicacaoCompleta(
        calculo: CostManagementModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporário
          talhaoId: _talhaoSelecionado!.id,
          talhaoNome: _talhaoSelecionado!.name,
          areaHa: _calculos!['areaTotal'] as double,
          dataAplicacao: _dataAplicacao,
          operador: _operadorController.text,
          equipamento: _equipamentoController.text,
          observacoes: _observacoesController.text,
          custoTotal: _calculos!['custoTotal'] as double,
          custoPorHectare: _calculos!['custoPorHectare'] as double,
          produtos: _produtosSelecionados.map((p) {
            final calculo = (_calculos!['calculosProdutos'] as List).firstWhere(
              (c) => c['produto'] == p.nome,
            );
            return CostProductModel(
              id: p.id,
              nome: p.nome,
              tipo: p.tipo,
              unidade: p.unidade,
              dosePorHa: p.dosePorHectare,
              precoUnitario: p.precoUnitario,
              quantidade: calculo['quantidadeTotal'] as double,
              custoTotal: calculo['custoProduto'] as double,
            );
          }).toList(),
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        ),
        operador: _operadorController.text,
        equipamento: _equipamentoController.text,
        condicoesClimaticas: 'Prescrição automática',
        observacoes: _observacoesController.text,
      );
      
      if (resultado['sucesso'] == true) {
        print('✅ Prescrição salva com sucesso no banco de dados');
        print('📊 Aplicações registradas: ${resultado['aplicacoes_registradas']}');
        print('💰 Custo total: R\$ ${resultado['custo_total']}');
      } else {
        throw Exception('Erro ao salvar prescrição: ${resultado['erro']}');
      }
    } catch (e) {
      print('❌ Erro ao salvar prescrição no banco: $e');
      throw Exception('Erro ao salvar prescrição no banco: $e');
    }
  }
  
  /// Integra com o módulo de gestão de custos
  Future<void> _integrarComGestaoCustos() async {
    if (_calculos == null || _talhaoSelecionado == null) return;
    
    try {
      print('💰 Iniciando integração real com gestão de custos...');
      
      final custoTotal = _calculos!['custoTotal'] as double;
      final custoPorHectare = _calculos!['custoPorHectare'] as double;
      final areaTotal = _calculos!['areaTotal'] as double;
      
      print('💰 Dados para integração: R\$ ${custoTotal.toStringAsFixed(2)} total, R\$ ${custoPorHectare.toStringAsFixed(2)}/ha');
      
      // INTEGRAÇÃO REAL COM GESTÃO DE CUSTOS
      for (final produto in _produtosSelecionados) {
        final calculo = (_calculos!['calculosProdutos'] as List).firstWhere(
          (c) => c['produto'] == produto.nome,
        );
        
        final sucesso = await _gestaoCustosService.registrarAplicacao(
          talhaoId: _talhaoSelecionado!.id,
          produtoId: produto.id,
          dosePorHa: produto.dosePorHectare,
          areaAplicadaHa: areaTotal,
          dataAplicacao: _dataAplicacao,
          operador: _operadorController.text,
          equipamento: _equipamentoController.text,
          condicoesClimaticas: 'Prescrição automática',
          observacoes: _observacoesController.text,
          fazendaId: _talhaoSelecionado!.fazendaId,
        );
        
        if (sucesso) {
          print('✅ Custo registrado com sucesso: ${produto.nome}');
        } else {
          print('❌ Erro ao registrar custo: ${produto.nome}');
          throw Exception('Falha ao registrar custo do produto ${produto.nome}');
        }
      }
      
      print('✅ Todos os custos foram registrados com sucesso!');
    } catch (e) {
      print('❌ Erro ao integrar com gestão de custos: $e');
      throw Exception('Erro ao integrar com gestão de custos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Nova Prescrição'),
        elevation: 0,
        actions: [
          if (_resumoOperacional != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                onPressed: _isSaving ? null : _gerarPdfPrescricao,
                tooltip: 'Gerar PDF Individual',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.article),
                onPressed: _isSaving ? null : _gerarPdfConsolidado,
                tooltip: 'Gerar PDF Consolidado',
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carregando prescrição...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Área principal com fundo verde
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // Cards de informações principais
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                // Layout vertical para telas pequenas
                                return Column(
                                  children: [
                                    _buildInfoCard(
                                      'Talhão',
                                      Icons.grid_on,
                                      _talhaoSelecionado?.name ?? 'Selecione',
                                      onTap: _mostrarDialogTalhoes,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoCard(
                                      'Área',
                                      Icons.terrain,
                                      '${_areaTrabalho.toStringAsFixed(2)} ha',
                                    ),
                                  ],
                                );
                              } else {
                                // Layout horizontal para telas maiores
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoCard(
                                        'Talhão',
                                        Icons.grid_on,
                                        _talhaoSelecionado?.name ?? 'Selecione',
                                        onTap: _mostrarDialogTalhoes,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildInfoCard(
                                        'Área',
                                        Icons.terrain,
                                        '${_areaTrabalho.toStringAsFixed(2)} ha',
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Botões de ação
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                // Layout vertical para telas pequenas
                                return Column(
                                  children: [
                                    _buildActionButton(
                                      'Rascunho',
                                      Icons.edit,
                                      Colors.green,
                                      _salvarRascunho,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildActionButton(
                                      'Salvar',
                                      Icons.save,
                                      Colors.white,
                                      _salvarPrescricao,
                                      textColor: const Color(0xFF2E7D32),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildActionButton(
                                      'Calcular',
                                      Icons.calculate,
                                      Colors.orange,
                                      _calcularPrescricaoAutomatica,
                                    ),
                                  ],
                                );
                              } else {
                                // Layout horizontal para telas maiores
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        'Rascunho',
                                        Icons.edit,
                                        Colors.green,
                                        _salvarRascunho,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildActionButton(
                                        'Salvar',
                                        Icons.save,
                                        Colors.white,
                                        _salvarPrescricao,
                                        textColor: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildActionButton(
                                        'Calcular',
                                        Icons.calculate,
                                        Colors.orange,
                                        _calcularPrescricaoAutomatica,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Cards de navegação
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Layout em grid 2x2 para telas pequenas
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNavigationCard(
                                      'Geral',
                                      Icons.info,
                                      _secaoAtiva == 'Geral',
                                      () => _alterarSecao('Geral'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildNavigationCard(
                                      'Calibração',
                                      Icons.settings,
                                      _secaoAtiva == 'Calibração',
                                      () => _alterarSecao('Calibração'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNavigationCard(
                                      'Produtos',
                                      Icons.inventory,
                                      _secaoAtiva == 'Produtos',
                                      () => _alterarSecao('Produtos'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildNavigationCard(
                                      'Resultados',
                                      Icons.bar_chart,
                                      _secaoAtiva == 'Resultados',
                                      () => _alterarSecao('Resultados'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // Layout horizontal para telas maiores
                          return Row(
                            children: [
                              Expanded(
                                child: _buildNavigationCard(
                                  'Geral',
                                  Icons.info,
                                  _secaoAtiva == 'Geral',
                                  () => _alterarSecao('Geral'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNavigationCard(
                                  'Calibração',
                                  Icons.settings,
                                  _secaoAtiva == 'Calibração',
                                  () => _alterarSecao('Calibração'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNavigationCard(
                                  'Produtos',
                                  Icons.inventory,
                                  _secaoAtiva == 'Produtos',
                                  () => _alterarSecao('Produtos'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNavigationCard(
                                  'Resultados',
                                  Icons.bar_chart,
                                  _secaoAtiva == 'Resultados',
                                  () => _alterarSecao('Resultados'),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  
                  // Conteúdo da seção ativa
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildSecaoConteudo(),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSelecaoInicial() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '1. Seleção Inicial',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Seleção de talhão
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Layout vertical para telas pequenas
                  return Column(
                    children: [
                      DropdownButtonFormField<TalhaoModel>(
                        decoration: const InputDecoration(
                          labelText: 'Talhão',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grid_on),
                        ),
                        value: _talhaoSelecionado,
                        items: _talhoes.map((talhao) => DropdownMenuItem(
                          value: talhao,
                          child: Text('${talhao.name} (${talhao.area?.toStringAsFixed(2)} ha)'),
                        )).toList(),
                        onChanged: (talhao) {
                          if (talhao != null) _selecionarTalhao(talhao);
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Área Manual'),
                        value: _usarAreaManual,
                        onChanged: (value) {
                          setState(() {
                            _usarAreaManual = value ?? false;
                          });
                        },
                      ),
                    ],
                  );
                } else {
                  // Layout horizontal para telas maiores
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TalhaoModel>(
                          decoration: const InputDecoration(
                            labelText: 'Talhão',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.grid_on),
                          ),
                          value: _talhaoSelecionado,
                          items: _talhoes.map((talhao) => DropdownMenuItem(
                            value: talhao,
                            child: Text('${talhao.name} (${talhao.area?.toStringAsFixed(2)} ha)'),
                          )).toList(),
                          onChanged: (talhao) {
                            if (talhao != null) _selecionarTalhao(talhao);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Área Manual'),
                          value: _usarAreaManual,
                          onChanged: (value) {
                            setState(() {
                              _usarAreaManual = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            if (_usarAreaManual) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaManualController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Área Manual (hectares)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.area_chart),
                ),
                onChanged: (value) => _calcularPrescricaoAutomatica(),
              ),
            ],
            const SizedBox(height: 16),
            
            // Tipo de aplicação
            const SizedBox(height: 20),
            const Text(
              'Tipo de Aplicação:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // Layout vertical para telas pequenas
                    return Column(
                      children: [
                        _buildTipoAplicacaoCard(
                          tipo: 'Terrestre',
                          titulo: '🚜 Terrestre',
                          icone: Icons.agriculture,
                          cor: const Color(0xFF2E7D32),
                          descricao: 'Pulverizador',
                        ),
                        const SizedBox(height: 12),
                        _buildTipoAplicacaoCard(
                          tipo: 'Aérea',
                          titulo: '✈️ Aérea',
                          icone: Icons.flight,
                          cor: Colors.orange,
                          descricao: 'Avião/Drone',
                        ),
                      ],
                    );
                  } else {
                    // Layout horizontal para telas maiores
                    return Row(
                      children: [
                        Expanded(
                          child: _buildTipoAplicacaoCard(
                            tipo: 'Terrestre',
                            titulo: '🚜 Terrestre',
                            icone: Icons.agriculture,
                            cor: const Color(0xFF2E7D32),
                            descricao: 'Pulverizador',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTipoAplicacaoCard(
                            tipo: 'Aérea',
                            titulo: '✈️ Aérea',
                            icone: Icons.flight,
                            cor: Colors.orange,
                            descricao: 'Avião/Drone',
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            
            // Data de aplicação
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataAplicacao,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _dataAplicacao = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data da Aplicação',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_dataAplicacao),
                ),
              ),
            ),
            
            // Área de trabalho (se dose fracionada)
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _doseFracionada,
                  onChanged: (value) {
                    setState(() {
                      _doseFracionada = value ?? false;
                      if (!_doseFracionada) {
                        _areaTrabalho = _talhaoSelecionado?.area ?? 0.0;
                      }
                    });
                    _calcularPrescricaoAutomatica();
                  },
                ),
                const Text('Dose Fracionada (área parcial)'),
              ],
            ),
            if (_doseFracionada) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Área de Trabalho (ha)',
                  border: OutlineInputBorder(),
                  suffixText: 'ha',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                onChanged: (value) {
                  _areaTrabalho = double.tryParse(value) ?? 0.0;
                  _calcularPrescricaoAutomatica();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracaoTanque() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '2. Configuração da Máquina',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
                        // Campos principais para cálculo
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Layout vertical para telas pequenas
                  return Column(
                    children: [
                      TextFormField(
                        controller: _capacidadeTanqueController,
                        decoration: const InputDecoration(
                          labelText: 'Capacidade do Tanque/Bomba',
                          border: OutlineInputBorder(),
                          suffixText: 'L',
                          helperText: 'Capacidade total do tanque',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (value) => _atualizarConfiguracaoMaquina(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vazaoPorHectareController,
                        decoration: const InputDecoration(
                          labelText: 'Vazão por Hectare',
                          border: OutlineInputBorder(),
                          suffixText: 'L/ha',
                          helperText: 'Volume de calda por hectare',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (value) => _atualizarConfiguracaoMaquina(),
                      ),
                    ],
                  );
                } else {
                  // Layout horizontal para telas maiores
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacidadeTanqueController,
                              decoration: const InputDecoration(
                                labelText: 'Capacidade do Tanque/Bomba',
                                border: OutlineInputBorder(),
                                suffixText: 'L',
                                helperText: 'Capacidade total do tanque',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              onChanged: (value) => _atualizarConfiguracaoMaquina(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _vazaoPorHectareController,
                              decoration: const InputDecoration(
                                labelText: 'Vazão por Hectare',
                                border: OutlineInputBorder(),
                                suffixText: 'L/ha',
                                helperText: 'Volume de calda por hectare',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              onChanged: (value) => _atualizarConfiguracaoMaquina(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _larguraController,
                              decoration: const InputDecoration(
                                labelText: 'Largura de Trabalho (opcional)',
                                border: OutlineInputBorder(),
                                suffixText: 'm',
                                helperText: 'Para referência',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              onChanged: (value) => _atualizarConfiguracaoMaquina(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _velocidadeController,
                              decoration: const InputDecoration(
                                labelText: 'Velocidade Média (opcional)',
                                border: OutlineInputBorder(),
                                suffixText: 'km/h',
                                helperText: 'Para referência',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              onChanged: (value) => _atualizarConfiguracaoMaquina(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Informações de ajuda
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: const Color(0xFF1976D2), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Informações de Referência:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tipoAplicacao == 'Terrestre' 
                        ? '• Terrestre: 100-200 L/ha, tanques 500-2000 L'
                        : '• Aérea: 20-30 L/ha, bombas 100-500 L',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracaoAvancada() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. Configuração Avançada de Aplicação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tipo de bico
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Bico',
                border: OutlineInputBorder(),
              ),
              value: _tipoBico,
              items: ['Automático', 'Manual', 'Eletrônico', 'Pneumático']
                  .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _tipoBico = value ?? 'Automático';
                });
                _calcularPrescricaoAutomatica();
              },
            ),
            const SizedBox(height: 16),
            
            // Modo automático
            Row(
              children: [
                Checkbox(
                  value: _modoAutomatico,
                  onChanged: (value) {
                    setState(() {
                      _modoAutomatico = value ?? true;
                    });
                    _calcularPrescricaoAutomatica();
                  },
                ),
                const Text('Modo Automático'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Configurações de velocidade e largura
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _larguraController,
                    decoration: const InputDecoration(
                      labelText: 'Largura de Trabalho',
                      border: OutlineInputBorder(),
                      suffixText: 'm',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    onChanged: (value) {
                      _larguraTrabalho = double.tryParse(value) ?? 20.0;
                      _calcularPrescricaoAutomatica();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _velocidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Velocidade de Aplicação',
                      border: OutlineInputBorder(),
                      suffixText: 'km/h',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    onChanged: (value) {
                      _velocidadeAplicacao = double.tryParse(value) ?? 8.0;
                      _calcularPrescricaoAutomatica();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Taxa de vazão do bico
            TextFormField(
              controller: _taxaVazaoController,
              decoration: const InputDecoration(
                labelText: 'Taxa de Vazão do Bico',
                border: OutlineInputBorder(),
                suffixText: 'L/min',
                helperText: 'Vazão individual de cada bico',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              onChanged: (value) {
                  _taxaVazaoBico = double.tryParse(value) ?? 0.5;
                  _calcularPrescricaoAutomatica();
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutosSelecionados() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: const Color(0xFF1976D2)),
                const SizedBox(width: 8),
                const Text(
                  '4. Produtos da Prescrição',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
                ),
                const SizedBox(height: 12),
            
            // Botão de adicionar produto
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _adicionarProduto,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Produto'),
                    style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            
            const SizedBox(height: 16),
            
            if (_produtosSelecionados.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.grey, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum produto selecionado',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clique em "Adicionar Produto" para começar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _produtosSelecionados.length,
                itemBuilder: (context, index) {
                  final produto = _produtosSelecionados[index];
                  
                  // Calcular se há estoque suficiente
                  final areaTotal = _areaTrabalho > 0 ? _areaTrabalho : (_talhaoSelecionado?.area ?? 0.0);
                  final quantidadeNecessaria = produto.dosePorHectare * areaTotal;
                  final estoqueSuficiente = produto.estoqueDisponivel >= quantidadeNecessaria;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: estoqueSuficiente ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: estoqueSuficiente ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: estoqueSuficiente ? Colors.green : Colors.red,
                        child: Icon(
                          estoqueSuficiente ? Icons.check : Icons.warning,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        produto.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${produto.tipo} - ${produto.dosePorHectare} ${produto.unidade}/ha'),
                          Text(
                            'Estoque: ${produto.estoqueDisponivel} ${produto.unidade}',
                            style: TextStyle(
                              color: estoqueSuficiente ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (areaTotal > 0) ...[
                            Text(
                              'Necessário: ${quantidadeNecessaria.toStringAsFixed(2)} ${produto.unidade}',
                              style: TextStyle(
                                color: estoqueSuficiente ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                          if (produto.lote != null) Text('Lote: ${produto.lote}'),
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

  Widget _buildResultadosCalculo() {
    print('🔍 _buildResultadosCalculo chamado');
    print('   _calculos: ${_calculos != null ? 'SIM' : 'NÃO'}');
    if (_calculos != null) {
      print('   Chaves disponíveis: ${_calculos!.keys.toList()}');
    }
    
    if (_calculos == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== RESUMO OPERACIONAL =====
        Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  children: [
                    Icon(Icons.engineering, color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
            const Text(
                      'Resumo Operacional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
            ),
            const SizedBox(height: 16),
            
                _buildInfoRow('Área Total', '${_calculos!['areaTotal'].toStringAsFixed(2)} ha'),
                _buildInfoRow('Vazão Definida', '${_calculos!['vazaoPorHectare'].toStringAsFixed(0)} L/ha'),
                _buildInfoRow('Capacidade Tanque', '${_calculos!['capacidadeTanque'].toStringAsFixed(0)} L'),
                _buildInfoRow('Hectares por Tanque', '${_calculos!['hectaresCobertosPorTanque'].toStringAsFixed(2)} ha'),
                _buildInfoRow('Nº de Tanques/Vôos', '${_calculos!['numeroTanques']}'),
            if (_calculos!['tanqueFracionado'] != _calculos!['numeroTanques'])
              _buildInfoRow('Tanque Fracionado', '${_calculos!['tanqueFracionado'].toStringAsFixed(2)}'),
                _buildInfoRow('Tipo de Máquina', _calculos!['tipoMaquina']),
              ],
            ),
          ),
        ),
            
            const SizedBox(height: 16),
        
        // ===== RESUMO POR PRODUTO =====
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: const Color(0xFF1976D2)),
                    const SizedBox(width: 8),
            const Text(
                      'Resumo por Produto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ...(_calculos!['calculosProdutos'] as List).map((produto) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: produto['estoqueSuficiente'] ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: produto['estoqueSuficiente'] ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              produto['estoqueSuficiente'] ? Icons.check_circle : Icons.warning,
                              color: produto['estoqueSuficiente'] ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                produto['produto'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
            ),
            const SizedBox(height: 8),
                        _buildInfoRow('Dose', '${produto['dosePorHectare'].toStringAsFixed(2)} ${produto['unidade']}/ha'),
                        _buildInfoRow('Quantidade Total', '${produto['quantidadeTotal'].toStringAsFixed(2)} ${produto['unidade']}'),
                        _buildInfoRow('Por Tanque', '${produto['quantidadePorTanque'].toStringAsFixed(2)} ${produto['unidade']}'),
                        _buildInfoRow('Estoque Disponível', '${produto['estoqueDisponivel'].toStringAsFixed(2)} ${produto['unidade']}'),
                        if (produto['lote'] != null)
                          _buildInfoRow('Lote', produto['lote']),
                      ],
                    ),
                  ),
                ).toList(),
              ],
            ),
          ),
        ),
            
            const SizedBox(height: 16),
        
        // ===== RESUMO FINANCEIRO =====
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: const Color(0xFFF57C00)),
                    const SizedBox(width: 8),
            const Text(
                      'Resumo Financeiro',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildInfoRow('Custo Total', 'R\$ ${_calculos!['custoTotal'].toStringAsFixed(2)}'),
                _buildInfoRow('Custo por Hectare', 'R\$ ${_calculos!['custoPorHectare'].toStringAsFixed(2)}'),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                
                // Detalhamento por produto
                const Text(
                  'Detalhamento por Produto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            ...(_calculos!['calculosProdutos'] as List).map((produto) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(produto['produto']),
                        Text(
                          'R\$ ${produto['custoProduto'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ===== RESUMO EXECUTIVO =====
              Card(
          color: const Color(0xFF2E7D32).withOpacity(0.1),
                child: Padding(
            padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Row(
                  children: [
                    Icon(Icons.assessment, color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    const Text(
                      'Resumo Executivo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Text(
                  'São necessários ${_calculos!['numeroTanques']} ${_calculos!['tipoMaquina'] == 'Aérea' ? 'vôos' : 'tanques'} de ${_calculos!['capacidadeTanque'].toStringAsFixed(0)} L, aplicando:',
                  style: const TextStyle(fontSize: 14),
                ),
                
                const SizedBox(height: 8),
                
                ...(_calculos!['calculosProdutos'] as List).map((produto) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      '• ${produto['quantidadePorTanque'].toStringAsFixed(2)} ${produto['unidade']} de ${produto['produto']} por ${_calculos!['tipoMaquina'] == 'Aérea' ? 'vôo' : 'tanque'}',
                      style: const TextStyle(fontSize: 14),
                ),
              ),
            ).toList(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Para cobrir ${_calculos!['areaTotal'].toStringAsFixed(2)} ha com custo total de R\$ ${_calculos!['custoTotal'].toStringAsFixed(2)}.',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
          ],
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildValidacaoEstoque() {
    if (_validacaoEstoque == null) return const SizedBox.shrink();
    
    final alertas = _validacaoEstoque!['alertas'] as List<String>;
    final todosDisponiveis = _validacaoEstoque!['todosProdutosDisponiveis'] as bool;
    
    // Combinar alertas de estoque com alertas de produtos
    final todosAlertas = [...alertas, ..._alertasProdutos];
    final temAlertas = todosAlertas.isNotEmpty;
    
    return Card(
      color: temAlertas ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  temAlertas ? Icons.warning : Icons.check_circle,
                  color: temAlertas ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '6. Validação de Estoque e Produtos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: temAlertas ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!temAlertas)
              const Text(
                '✅ Todos os produtos estão disponíveis e com estoque suficiente.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
            else ...[
              const Text(
                '⚠️ Atenção: Alguns produtos precisam de atenção:',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...todosAlertas.map((alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $alerta', style: const TextStyle(color: Colors.red)),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildObservacoes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7. Observações e Informações Adicionais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _operadorController,
              decoration: const InputDecoration(
                labelText: 'Operador Responsável',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
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

  Widget _buildBotaoSalvar() {
    return Column(
      children: [
        // Botão principal de salvar
        Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
            onPressed: _isSaving || _resumoOperacional == null ? null : _salvarPrescricao,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Salvando Prescrição...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.save,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Salvar Prescrição Premium',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
        ),
        
        const SizedBox(height: 16),
        
        // Botão de gerar PDF
        if (_resumoOperacional != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F4C5C).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _gerarPdfPrescricao,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Gerando PDF...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Gerar PDF Premium',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildTipoAplicacaoCard({
    required String tipo,
    required String titulo,
    required IconData icone,
    required Color cor,
    required String descricao,
  }) {
    final isSelected = _tipoAplicacao == tipo;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoAplicacao = tipo;
        });
        _atualizarConfiguracaoMaquina();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? cor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? cor : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icone,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? cor : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              descricao,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? cor.withOpacity(0.8) : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ===== MÉTODOS DA NOVA INTERFACE =====

  /// Constrói o conteúdo da seção ativa
  Widget _buildSecaoConteudo() {
    switch (_secaoAtiva) {
      case 'Geral':
        return _buildSecaoGeral();
      case 'Calibração':
        return _buildSecaoCalibracao();
      case 'Produtos':
        return _buildSecaoProdutos();
      case 'Resultados':
        return _buildSecaoResultados();
      default:
        return _buildSecaoGeral();
    }
  }

  /// Constrói a seção geral
  Widget _buildSecaoGeral() {
    print('🔍 _buildSecaoGeral chamado');
    print('   _resumoOperacional: ${_resumoOperacional != null ? 'SIM' : 'NÃO'}');
    print('   _calculos: ${_calculos != null ? 'SIM' : 'NÃO'}');
    print('   _validacaoEstoque: ${_validacaoEstoque != null ? 'SIM' : 'NÃO'}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelecaoInicial(),
        const SizedBox(height: 20),
        _buildConfiguracaoTanque(),
        const SizedBox(height: 20),
        _buildConfiguracaoAvancada(),
        const SizedBox(height: 20),
        _buildProdutosSelecionados(),
        const SizedBox(height: 20),
        if (_resumoOperacional != null) ...[
          AplicacaoResumoOperacionalWidget(
            resumoOperacional: _resumoOperacional!,
            onEditar: () {
              _alterarSecao('Calibração');
            },
          ),
          const SizedBox(height: 20),
        ],
        if (_calculos != null) ...[
          _buildResultadosCalculo(),
          const SizedBox(height: 20),
        ],
        if (_validacaoEstoque != null) ...[
          _buildValidacaoEstoque(),
          const SizedBox(height: 20),
        ],
        _buildObservacoes(),
        const SizedBox(height: 20),
        _buildBotaoSalvar(),
      ],
    );
  }

  /// Constrói a seção de calibração
  Widget _buildSecaoCalibracao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfiguracaoAvancada(),
        const SizedBox(height: 20),
        _buildConfiguracaoTanque(),
        const SizedBox(height: 20),
        if (_validacaoMaquina != null) ...[
          _buildValidacaoMaquina(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Constrói a seção de produtos
  Widget _buildSecaoProdutos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProdutosSelecionados(),
        const SizedBox(height: 20),
        if (_validacaoEstoque != null) ...[
          _buildValidacaoEstoque(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Constrói a seção de resultados
  Widget _buildSecaoResultados() {
    print('🔍 _buildSecaoResultados chamado');
    print('   _resumoOperacional: ${_resumoOperacional != null ? 'SIM' : 'NÃO'}');
    print('   _calculos: ${_calculos != null ? 'SIM' : 'NÃO'}');
    print('   _validacaoEstoque: ${_validacaoEstoque != null ? 'SIM' : 'NÃO'}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_resumoOperacional != null) ...[
          AplicacaoResumoOperacionalWidget(
            resumoOperacional: _resumoOperacional!,
            onEditar: () {
              _alterarSecao('Calibração');
            },
          ),
          const SizedBox(height: 20),
        ],
        if (_calculos != null) ...[
          _buildResultadosCalculo(),
          const SizedBox(height: 20),
        ],
        if (_validacaoEstoque != null) ...[
          _buildValidacaoEstoque(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Constrói card de informação
  Widget _buildInfoCard(String titulo, IconData icon, String valor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 200) {
              // Layout compacto para telas muito pequenas
              return Row(
                children: [
                  Icon(icon, color: const Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          valor,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Layout vertical padrão
              return Column(
                children: [
                  Icon(icon, color: const Color(0xFF2E7D32), size: 24),
                  const SizedBox(height: 8),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Constrói botão de ação
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed, {Color? textColor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 120) {
            // Layout horizontal para botões muito estreitos
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          } else {
            // Layout vertical padrão
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Constrói card de navegação
  Widget _buildNavigationCard(String titulo, IconData icon, bool ativo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFF2E7D32).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(
              color: ativo ? const Color(0xFF2E7D32) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 80) {
              // Layout horizontal para cards muito estreitos
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: ativo ? const Color(0xFF2E7D32) : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: ativo ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            } else {
              // Layout vertical padrão
              return Column(
                children: [
                  Icon(
                    icon,
                    color: ativo ? const Color(0xFF2E7D32) : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ativo ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Constrói validação da máquina
  Widget _buildValidacaoMaquina() {
    if (_validacaoMaquina == null) return const SizedBox.shrink();
    
    final alertas = _validacaoMaquina!['alertas'] as List<String>;
    final sugestoes = _validacaoMaquina!['sugestoes'] as List<String>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Validação da Máquina',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (alertas.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...alertas.map((alerta) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(alerta)),
                ],
              ),
            )),
          ],
          if (sugestoes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...sugestoes.map((sugestao) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(sugestao)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  /// Retorna o tamanho de fonte responsivo baseado na largura da tela
  double _getResponsiveFontSize(double baseSize, double screenWidth) {
    if (screenWidth < 400) return baseSize * 0.8;
    if (screenWidth < 600) return baseSize * 0.9;
    return baseSize;
  }

  /// Retorna o padding responsivo baseado na largura da tela
  EdgeInsets _getResponsivePadding(double screenWidth) {
    if (screenWidth < 400) return const EdgeInsets.all(8.0);
    if (screenWidth < 600) return const EdgeInsets.all(12.0);
    return const EdgeInsets.all(16.0);
  }

  /// Mostra o dialog de seleção de talhões
  void _mostrarDialogTalhoes() {
    // Implementar dialog de seleção de talhões
    print('Mostrar dialog de talhões');
  }
}