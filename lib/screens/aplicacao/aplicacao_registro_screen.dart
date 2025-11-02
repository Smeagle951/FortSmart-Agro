import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../database/models/aplicacao_model.dart';
import '../../database/models/produto_aplicado_model.dart';
import '../../database/repositories/aplicacao_repository.dart';
// Import removido por não estar sendo utilizado
// import '../../services/data_cache_service.dart';
import '../../services/database_service.dart';
import '../../services/aplicacao_calculo_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/aplicacao_resumo_operacional_widget.dart';
import '../../services/talhao_unified_service.dart';
import '../../utils/logger.dart'; // Adicionado para o Logger

/// Tela para registro de aplicação agrícola
class AplicacaoRegistroScreen extends StatefulWidget {
  final String? aplicacaoId;

  const AplicacaoRegistroScreen({super.key, this.aplicacaoId});

  @override
  _AplicacaoRegistroScreenState createState() => _AplicacaoRegistroScreenState();
}

class _AplicacaoRegistroScreenState extends State<AplicacaoRegistroScreen> {
  // Controladores para os campos do formulário
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _equipamentoController = TextEditingController();
  final TextEditingController _capacidadeBombaController = TextEditingController();
  final TextEditingController _vazaoAplicacaoController = TextEditingController();
  final TextEditingController _bicoTipoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  // Campos removidos por não estarem sendo utilizados
  // final TextEditingController _areaManualController = TextEditingController();
  // final TextEditingController _larguraTrabalhoController = TextEditingController();
  // final TextEditingController _velocidadeController = TextEditingController();

  // Valores calculados
  double _hectaresPorBomba = 0;
  double _bombasNecessarias = 0;

  // Tipo de aplicação
  String _tipoAplicacao = 'Terrestre';
  
  // Configurações da máquina
  double _capacidadeTanque = 600.0;
  double _vazaoPorHectare = 150.0;
  
  // Resumo operacional
  Map<String, dynamic>? _resumoOperacional;
  
  // Validações - campo não utilizado
  // Map<String, dynamic>? _validacaoMaquina;

  // Talhão selecionado
  Map<String, dynamic>? _talhaoSelecionado;
  List<Map<String, dynamic>> _talhoes = [];

  // Produtos selecionados
  List<ProdutoAplicadoModel> _produtosSelecionados = [];

  // Imagens selecionadas
  List<File> _imagens = [];

  // Repositório
  late AplicacaoRepository _repository;
  
  // Serviço de cache de dados - não utilizado
  // late DataCacheService _dataCacheService;

  // Serviço unificado para talhões
  late TalhaoUnifiedService _talhaoUnifiedService;

  // Flag para indicar se está carregando
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = AplicacaoRepository();
    _talhaoUnifiedService = TalhaoUnifiedService(); // Inicializar o serviço unificado
    _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _responsavelController.text = 'Usuário Atual'; // Substituir pelo usuário logado
    
    // Inicializar controladores com valores padrão
    _capacidadeBombaController.text = _capacidadeTanque.toString();
    _vazaoAplicacaoController.text = _vazaoPorHectare.toString();
    
    _carregarDados();
  }

  /// Carrega os dados necessários para a tela
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar talhões
      await _carregarTalhoes();

      // Carregar aplicação existente se for edição
      if (widget.aplicacaoId != null) {
        await _carregarAplicacao(widget.aplicacaoId!);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carrega os talhões disponíveis
  Future<void> _carregarTalhoes() async {
    try {
      Logger.info('🔄 [APLICACAO] Carregando talhões via serviço unificado...');
      
      // Usar o serviço unificado para carregar talhões
      final talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
        nomeModulo: 'APLICACAO',
      );
      
      if (mounted) {
        setState(() {
          _talhoes = talhoes.map((talhao) => {
            'id': talhao.id,
            'nome': talhao.name,
            'area': talhao.area,
          }).toList();
        });
      }
      
      Logger.info('✅ [APLICACAO] ${_talhoes.length} talhões carregados com sucesso');
    } catch (e) {
      Logger.error('❌ [APLICACAO] Erro ao carregar talhões: $e');
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar talhões');
      }
    }
  }

  /// Carrega os dados de uma aplicação existente
  Future<void> _carregarAplicacao(String id) async {
    try {
      final aplicacao = await _repository.getById(int.parse(id));
      if (aplicacao != null && mounted) {
        setState(() {
          // Preencher os campos com os dados da aplicação
          _dataController.text = DateFormat('dd/MM/yyyy').format(
              DateTime.parse(aplicacao.data));
          _responsavelController.text = aplicacao.responsavel;
          _tipoAplicacao = aplicacao.tipoAplicacao;
          _equipamentoController.text = aplicacao.equipamento;
          _capacidadeBombaController.text = aplicacao.capacidadeBomba.toString();
          _vazaoAplicacaoController.text = aplicacao.vazaoAplicacao.toString();
          _bicoTipoController.text = aplicacao.bicoTipo;
          _observacoesController.text = aplicacao.observacoes ?? '';
          
          // Selecionar o talhão
          _talhaoSelecionado = _talhoes.firstWhere(
            (talhao) => talhao['id'] == aplicacao.talhaoId,
            orElse: () => _talhoes.isNotEmpty ? _talhoes.first : <String, dynamic>{},
          );
          
          // Carregar produtos
          _produtosSelecionados = (jsonDecode(aplicacao.produtosJson) as List)
              .map((produto) => ProdutoAplicadoModel.fromMap(produto))
              .toList();
          
          // Calcular valores
          _calcularValores();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar aplicação');
      }
    }
  }

  /// Calcula os valores de hectares por bomba e bombas necessárias
  void _calcularValores() {
    if (_capacidadeBombaController.text.isNotEmpty &&
        _vazaoAplicacaoController.text.isNotEmpty &&
        _talhaoSelecionado != null) {
      final capacidadeBomba = double.tryParse(_capacidadeBombaController.text) ?? 0;
      final vazaoAplicacao = double.tryParse(_vazaoAplicacaoController.text) ?? 0;
      final areaTalhao = _talhaoSelecionado!['area'] as double;

      if (capacidadeBomba > 0 && vazaoAplicacao > 0) {
        setState(() {
          _hectaresPorBomba = capacidadeBomba / vazaoAplicacao;
          _bombasNecessarias = areaTalhao / _hectaresPorBomba;
          
          // Atualizar quantidade por bomba para cada produto
          for (var produto in _produtosSelecionados) {
            final totalAplicar = produto.doseHa * areaTalhao;
            final quantidadePorBomba = produto.doseHa * _hectaresPorBomba;
            
            final index = _produtosSelecionados.indexOf(produto);
            _produtosSelecionados[index] = ProdutoAplicadoModel(
              produtoId: produto.produtoId,
              nome: produto.nome,
              doseHa: produto.doseHa,
              unidade: produto.unidade,
              estoqueAtual: produto.estoqueAtual,
              status: produto.status,
            );
          }
        });
      }
    }
  }

  /// Calcula valores automáticos usando o serviço de cálculo
  void _calcularValoresAutomaticos() {
    if (_talhaoSelecionado == null) return;
    
    final areaTotal = _talhaoSelecionado!['area'] as double;
    final capacidadeTanque = double.tryParse(_capacidadeBombaController.text) ?? _capacidadeTanque;
    final vazaoPorHectare = double.tryParse(_vazaoAplicacaoController.text) ?? _vazaoPorHectare;
    
    // Converter produtos para formato do serviço
    final produtos = _produtosSelecionados.map((produto) => {
      'nome': produto.nome,
      'dosePorHectare': produto.doseHa,
      'unidade': produto.unidade,
      'precoUnitario': 0.0, // Será obtido do estoque
      'estoqueDisponivel': produto.estoqueAtual,
    }).toList();
    
    // Gerar resumo operacional
    final resumo = AplicacaoCalculoService.gerarResumoOperacional(
      areaTotal: areaTotal,
      vazaoPorHectare: vazaoPorHectare,
      capacidadeTanque: capacidadeTanque,
      tipoMaquina: _tipoAplicacao,
      produtos: produtos,
    );
    
    // Validar configuração da máquina
    final validacao = AplicacaoCalculoService.validarConfiguracaoMaquina(
      vazaoPorHectare: vazaoPorHectare,
      capacidadeTanque: capacidadeTanque,
      tipoMaquina: _tipoAplicacao,
    );
    
    setState(() {
      _resumoOperacional = resumo;
      _hectaresPorBomba = resumo['hectaresPorTanque'] ?? 0;
      _bombasNecessarias = resumo['numeroTanques']?.toDouble() ?? 0;
    });
    
    // Mostrar alertas se houver
    if (validacao['alertas'].isNotEmpty) {
      _mostrarAlertasValidacao(validacao);
    }
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
    _capacidadeTanque = double.tryParse(_capacidadeBombaController.text) ?? _capacidadeTanque;
    _vazaoPorHectare = double.tryParse(_vazaoAplicacaoController.text) ?? _vazaoPorHectare;
    
    _calcularValoresAutomaticos();
  }

  /// Seleciona um talhão
  Future<void> _selecionarTalhao() async {
    if (_talhoes.isEmpty) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Nenhum talhão disponível');
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Talhão'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _talhoes.length,
            itemBuilder: (context, index) {
              final talhao = _talhoes[index];
              return ListTile(
                title: Text(talhao['nome'] ?? 'Talhão sem nome'),
                subtitle: Text('Área: ${talhao['area']?.toStringAsFixed(2)} ha'),
                onTap: () {
                  setState(() {
                    _talhaoSelecionado = talhao;
                  });
                  _calcularValoresAutomaticos();
                  Navigator.pop(context);
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
      ),
    );
  }

  /// Seleciona uma data
  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  /// Seleciona imagens da galeria
  Future<void> _selecionarImagens() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
        // Mostrar indicador de progresso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processando imagens...')),
        );
        
        // Salvar as imagens em um diretório permanente
        final List<File> novasImagens = [];
        final appDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${appDir.path}/aplicacoes_imagens');
        
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        
        for (var pickedFile in pickedFiles) {
          try {
            // Verificar se o arquivo existe
            if (await File(pickedFile.path).exists()) {
              final fileName = path.basename(pickedFile.path);
              final targetPath = '${targetDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
              
              // Copiar o arquivo para o diretório permanente
              final File newImage = await File(pickedFile.path).copy(targetPath);
              
              // Verificar se a cópia foi bem-sucedida
              if (await newImage.exists()) {
                novasImagens.add(newImage);
                print('Imagem salva com sucesso: $targetPath');
              } else {
                print('Falha ao salvar imagem: $targetPath');
              }
            } else {
              print('Arquivo de imagem não existe: ${pickedFile.path}');
            }
          } catch (imageError) {
            print('Erro ao processar imagem individual: $imageError');
          }
        }
        
        if (novasImagens.isNotEmpty) {
          setState(() {
            _imagens.addAll(novasImagens);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${novasImagens.length} imagens adicionadas')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma imagem foi adicionada. Tente novamente.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao selecionar imagens: $e');
      }
    }
  }
  
  /// Remove uma imagem da lista
  void _removerImagem(int index) {
    setState(() {
      _imagens.removeAt(index);
    });
  }
  
  /// Constrói a seção de imagens
  Widget _buildImagensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagens',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imagens.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma imagem selecionada',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagens.length,
                  itemBuilder: (context, index) {
                    // Verificar se o arquivo existe antes de tentar exibi-lo
                    final File imageFile = _imagens[index];
                    bool fileExists = imageFile.existsSync();
                    
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: fileExists
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  imageFile,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Erro ao carregar imagem: $error');
                                    return Container(
                                      height: 100,
                                      width: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                height: 100,
                                width: 100,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () => _removerImagem(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _selecionarImagens,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Adicionar Imagens'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }

  /// Salva a aplicação
  Future<void> _salvarAplicacao() async {
    // Validar campos obrigatórios
    if (_talhaoSelecionado == null ||
        _dataController.text.isEmpty ||
        _responsavelController.text.isEmpty ||
        _equipamentoController.text.isEmpty) {
      SnackbarUtils.showWarningSnackBar(
          context, 'Preencha todos os campos obrigatórios');
      return;
    }

    try {
      // Converter a data para o formato ISO
      final dataFormatada = DateFormat('dd/MM/yyyy').parse(_dataController.text);
      final dataISO = DateFormat('yyyy-MM-dd').format(dataFormatada);
      
      // Preparar lista de caminhos de imagens
      final List<String> imagensPaths = _imagens.map((file) => file.path).toList();
      
      // Criar o modelo de aplicação
      final aplicacao = AplicacaoModel.create(
        subareaId: _talhaoSelecionado!['id'].toString(),
        experimentoId: 'default', // ID padrão
        dataAplicacao: DateTime.parse(dataISO),
        tipoAplicacao: _tipoAplicacao,
        produto: _produtosSelecionados.isNotEmpty ? _produtosSelecionados.first.nome : '',
        principioAtivo: '',
        dosagem: _produtosSelecionados.isNotEmpty ? _produtosSelecionados.first.doseHa : 0.0,
        unidadeDosagem: _produtosSelecionados.isNotEmpty ? _produtosSelecionados.first.unidade : '',
        volumeCalda: double.tryParse(_vazaoAplicacaoController.text) ?? 0.0,
        equipamento: _equipamentoController.text,
        condicoesTempo: 'ensolarado', // Valor padrão
        temperatura: 25.0, // Valor padrão
        umidadeRelativa: 60.0, // Valor padrão
        velocidadeVento: 10.0, // Valor padrão
        observacoes: _observacoesController.text,
        fotos: imagensPaths,
        responsavelTecnico: _responsavelController.text,
        crmResponsavel: 'CRM-12345', // Valor padrão
      );

      try {
        if (widget.aplicacaoId != null) {
          await _repository.update(aplicacao);
          SnackbarUtils.showSuccessSnackBar(context, 'Aplicação atualizada com sucesso');
          Navigator.pop(context);
        } else {
          await _repository.insert(aplicacao);
          SnackbarUtils.showSuccessSnackBar(context, 'Aplicação registrada com sucesso');
          Navigator.pop(context);
        }
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar aplicação: $e');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar aplicação: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.aplicacaoId == null
            ? 'Nova Aplicação'
            : 'Editar Aplicação',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registro de Aplicação Agrícola',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Seção 1: Informações Básicas
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações Básicas',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Talhão
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Talhão'),
                            subtitle: Text(
                              _talhaoSelecionado != null
                                  ? '${_talhaoSelecionado!['nome']} - ${_talhaoSelecionado!['area']?.toStringAsFixed(2)} ha'
                                  : 'Nenhum talhão selecionado',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _selecionarTalhao,
                          ),
                          const Divider(),
                          
                          // Data
                          InkWell(
                            onTap: _selecionarData,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data da Aplicação',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(_dataController.text),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Responsável
                          TextFormField(
                            controller: _responsavelController,
                            decoration: const InputDecoration(
                              labelText: 'Responsável',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Tipo de Aplicação
                          Text('Tipo de Aplicação'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Terrestre'),
                                  value: 'Terrestre',
                                  groupValue: _tipoAplicacao,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoAplicacao = value!;
                                    });
                                    _atualizarConfiguracaoMaquina();
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Aérea'),
                                  value: 'Aérea',
                                  groupValue: _tipoAplicacao,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoAplicacao = value!;
                                    });
                                    _atualizarConfiguracaoMaquina();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Seção 2: Equipamento e Cálculos
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Equipamento e Cálculos',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Equipamento
                          TextFormField(
                            controller: _equipamentoController,
                            decoration: const InputDecoration(
                              labelText: 'Equipamento Utilizado',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Tipo de Bico
                          TextFormField(
                            controller: _bicoTipoController,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Bico',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Capacidade da Bomba
                          TextFormField(
                            controller: _capacidadeBombaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacidade da Bomba (L)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => _calcularValores(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Vazão de Aplicação
                          TextFormField(
                            controller: _vazaoAplicacaoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Vazão de Aplicação (L/ha)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => _atualizarConfiguracaoMaquina(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Campos removidos por não estarem sendo utilizados
                          // Largura de Trabalho e Velocidade foram removidos
                          
                          // Resultados dos cálculos
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resultados:',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Text('Hectares por Bomba: ${_hectaresPorBomba.toStringAsFixed(2)} ha'),
                                const SizedBox(height: 4),
                                Text('Bombas Necessárias: ${_bombasNecessarias.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Seção de Resumo Operacional
                  if (_resumoOperacional != null) ...[
                    const SizedBox(height: 16),
                    AplicacaoResumoOperacionalWidget(
                      resumoOperacional: _resumoOperacional!,
                      onEditar: () {
                        // Focar na seção de equipamento para edição
                        FocusScope.of(context).requestFocus(FocusNode());
                        Future.delayed(const Duration(milliseconds: 100), () {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 500),
                          );
                        });
                      },
                    ),
                  ],
                  
                  // Seção de imagens
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildImagensSection(),
                    ),
                  ),
                  
                  // Botões de ação
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _salvarAplicacao,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Aplicação'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
