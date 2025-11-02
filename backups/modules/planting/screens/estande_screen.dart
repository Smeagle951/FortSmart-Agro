import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/estande_model.dart';
import '../services/estande_service.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../models/agricultural_product.dart';
import '../services/data_cache_service.dart';

class EstandeScreen extends StatefulWidget {
  final int? estandeId;

  const EstandeScreen({Key? key, this.estandeId}) : super(key: key);

  @override
  _EstandeScreenState createState() => _EstandeScreenState();
}

class _EstandeScreenState extends State<EstandeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _estandeService = EstandeService();
  
  // Controladores de texto
  final TextEditingController _talhaoController = TextEditingController();
  final TextEditingController _culturaController = TextEditingController();
  final TextEditingController _variedadeController = TextEditingController();
  final TextEditingController _linhasController = TextEditingController();
  final TextEditingController _comprimentoController = TextEditingController();
  final TextEditingController _espacamentoController = TextEditingController();
  final TextEditingController _plantasContadasController = TextEditingController();
  final TextEditingController _populacaoDesejadaController = TextEditingController();
  final TextEditingController _germinacaoEstimadaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  
  // Lista de fotos
  List<String> _fotos = [];
  
  // Dados
  int? _talhaoId;
  int? _culturaId;
  int? _variedadeId;
  DateTime _dataAvaliacao = DateTime.now();
  double _resultadoEstande = 0;
  double _dae = 0;
  double _porcentagemFalha = 0;
  String _recomendacaoTecnica = '';
  bool _calculoRealizado = false;
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  bool _showList = false;
  List<EstandeModel> _estandeList = [];
  
  // Mapas para armazenar nomes de talhões, culturas e variedades
  Map<int, String> _talhaoNomes = {};
  Map<int, String> _culturaNomes = {};
  Map<int, String> _variedadeNomes = {};
  
  get decoration => null;
  
  get child => null;

  @override
  void initState() {
    super.initState();
    
    // Verificar se deve mostrar a lista de estandes
    Future.delayed(Duration.zero, () {
      if (ModalRoute.of(context)?.settings.arguments != null) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args['showList'] == true) {
          setState(() {
            _showList = true;
          });
          _carregarListaEstandes();
          return;
        }
      }
      
      // Se não for para mostrar a lista, carrega os dados do estande
      _carregarDados();
    });
  }
  
  // Método para carregar a lista de estandes
  Future<void> _carregarListaEstandes() async {
    setState(() => _isLoading = true);
    
    try {
      // Buscar todos os estandes cadastrados
      final estandes = await _estandeService.getAllEstandes();
      
      // Carregar nomes de talhões, culturas e variedades para exibição na lista
      await _carregarNomesTalhao();
      await _carregarNomesCultura();
      await _carregarNomesVariedade();
      
      setState(() {
        _estandeList = estandes;
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar lista de estandes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _carregarDados() async {
    if (widget.estandeId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final estande = await _estandeService.getEstandeById(widget.estandeId!);
      
      if (estande != null) {
        _talhaoId = estande.talhaoId;
        _culturaId = estande.culturaId;
        _variedadeId = estande.variedadeId;
        _dataAvaliacao = estande.dataAvaliacao;
        _resultadoEstande = estande.resultadoEstande;
        _dae = estande.dae ?? 0;
        _porcentagemFalha = estande.porcentagemFalha ?? 0;
        _recomendacaoTecnica = estande.recomendacaoTecnica ?? '';
        _calculoRealizado = true;
        
        _linhasController.text = estande.linhas.toString();
        _comprimentoController.text = estande.comprimento.toString();
        _espacamentoController.text = estande.espacamento.toString();
        _plantasContadasController.text = estande.plantasContadas.toString();
        if (estande.populacaoDesejada != null) {
          _populacaoDesejadaController.text = estande.populacaoDesejada.toString();
        }
        if (estande.germinacaoEstimada != null) {
          _germinacaoEstimadaController.text = estande.germinacaoEstimada.toString();
        }
        _observacoesController.text = estande.observacoes ?? '';
        _fotos = estande.fotos ?? [];
        
        await _carregarNomesTalhao();
        await _carregarNomesCultura();
        await _carregarNomesVariedade();
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Métodos para carregar dados de outras tabelas
  Future<void> _carregarNomesTalhao() async {
    // Implementar a busca do nome do talhão com base no ID
    _talhaoController.text = 'Talhão $_talhaoId';
  }
  
  Future<void> _carregarNomesCultura() async {
    // Implementar a busca do nome da cultura com base no ID
    _culturaController.text = 'Cultura $_culturaId';
  }
  
  Future<void> _carregarNomesVariedade() async {
    // Implementar a busca do nome da variedade com base no ID
    _variedadeController.text = 'Variedade $_variedadeId';
  }
  
  void _calcularEstande() {
    if (!_validarCamposCalculo()) return;
    
    final linhas = int.parse(_linhasController.text);
    final comprimento = double.parse(_comprimentoController.text);
    final espacamento = double.parse(_espacamentoController.text);
    final plantasContadas = int.parse(_plantasContadasController.text);
    final populacaoDesejada = int.parse(_populacaoDesejadaController.text);
    
    // Germinação estimada é opcional
    double? germinacaoEstimada;
    if (_germinacaoEstimadaController.text.isNotEmpty) {
      germinacaoEstimada = double.parse(_germinacaoEstimadaController.text);
    }
    
    // Realizar todos os cálculos de uma vez
    final resultados = _estandeService.realizarCalculosEstande(
      plantasContadas: plantasContadas, 
      linhas: linhas, 
      comprimento: comprimento, 
      espacamento: espacamento,
      populacaoDesejada: populacaoDesejada,
      germinacaoEstimada: germinacaoEstimada,
    );
    
    setState(() {
      _resultadoEstande = resultados['populacaoReal'] as double;
      _dae = resultados['dae'] as double;
      _porcentagemFalha = resultados['porcentagemFalha'] as double;
      _recomendacaoTecnica = resultados['recomendacaoTecnica'] as String;
      _calculoRealizado = true;
      
      // Log para debug
      print('População Real: $_resultadoEstande plantas/ha');
      print('DAE: $_dae plantas/ha');
      print('Porcentagem de Falha: $_porcentagemFalha%');
      print('Recomendação Técnica: $_recomendacaoTecnica');
    });
    
    _mostrarSucesso('Cálculo realizado com sucesso!');
  }
  
  bool _validarCamposCalculo() {
    if (_linhasController.text.isEmpty) {
      _mostrarErro('Informe o número de linhas avaliadas');
      return false;
    }
    
    if (_comprimentoController.text.isEmpty) {
      _mostrarErro('Informe o comprimento da linha');
      return false;
    }
    
    if (_espacamentoController.text.isEmpty) {
      _mostrarErro('Informe o espaçamento entre linhas');
      return false;
    }
    
    if (_plantasContadasController.text.isEmpty) {
      _mostrarErro('Informe a quantidade de plantas contadas');
      return false;
    }
    
    if (_populacaoDesejadaController.text.isEmpty) {
      _mostrarErro('Informe a população desejada de plantas por hectare');
      return false;
    }
    
    // Validar valores não negativos
    if (int.parse(_linhasController.text) <= 0) {
      _mostrarErro('O número de linhas deve ser maior que zero');
      return false;
    }
    
    if (double.parse(_comprimentoController.text) <= 0) {
      _mostrarErro('O comprimento da linha deve ser maior que zero');
      return false;
    }
    
    if (double.parse(_espacamentoController.text) <= 0) {
      _mostrarErro('O espaçamento entre linhas deve ser maior que zero');
      return false;
    }
    
    if (int.parse(_plantasContadasController.text) < 0) {
      _mostrarErro('A quantidade de plantas contadas não pode ser negativa');
      return false;
    }
    
    if (int.parse(_populacaoDesejadaController.text) <= 0) {
      _mostrarErro('A população desejada deve ser maior que zero');
      return false;
    }
    
    // Validar germinação estimada se preenchida
    if (_germinacaoEstimadaController.text.isNotEmpty) {
      final germinacao = double.parse(_germinacaoEstimadaController.text);
      if (germinacao <= 0 || germinacao > 100) {
        _mostrarErro('A germinação estimada deve estar entre 0 e 100%');
        return false;
      }
    }
    
    return true;
  }
  
  Future<void> _salvarEstande() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_calculoRealizado) {
      _mostrarErro('Realize o cálculo do estande antes de salvar');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Processar e salvar as imagens permanentemente
      List<String> fotosProcessadas = [];
      for (String fotoPath in _fotos) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${fotosProcessadas.length}.jpg';
          final targetPath = '${dir.path}/estande_fotos/$fileName';
          
          // Cria o diretório se não existir
          final directory = Directory('${dir.path}/estande_fotos');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          await File(fotoPath).copy(targetPath);
          fotosProcessadas.add(targetPath);
        } catch (e) {
          print('Erro ao processar foto: $e');
          // Continua processando as outras fotos mesmo se uma falhar
        }
      }
      
      // Obter valores dos campos
      int? populacaoDesejada;
      double? germinacaoEstimada;
      
      if (_populacaoDesejadaController.text.isNotEmpty) {
        populacaoDesejada = int.parse(_populacaoDesejadaController.text);
      }
      
      if (_germinacaoEstimadaController.text.isNotEmpty) {
        germinacaoEstimada = double.parse(_germinacaoEstimadaController.text);
      }
      
      final estande = EstandeModel(
        id: widget.estandeId,
        talhaoId: _talhaoId!,
        culturaId: _culturaId!,
        variedadeId: _variedadeId!,
        linhas: int.parse(_linhasController.text),
        comprimento: double.parse(_comprimentoController.text),
        espacamento: double.parse(_espacamentoController.text),
        plantasContadas: int.parse(_plantasContadasController.text),
        resultadoEstande: _resultadoEstande,
        populacaoDesejada: populacaoDesejada,
        germinacaoEstimada: germinacaoEstimada,
        dae: _dae,
        porcentagemFalha: _porcentagemFalha,
        recomendacaoTecnica: _recomendacaoTecnica,
        observacoes: _observacoesController.text,
        dataAvaliacao: _dataAvaliacao,
        fotos: fotosProcessadas.isNotEmpty ? fotosProcessadas : _fotos,
      );
      
      await _estandeService.saveEstande(estande);
      
      _mostrarSucesso('Estande salvo com sucesso!');
      
      // Volta para a tela anterior após salvar
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro('Erro ao salvar estande: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataAvaliacao,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF228B22),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (data != null) {
      setState(() => _dataAvaliacao = data);
    }
  }
  
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF228B22),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF228B22),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Exibe um diálogo de confirmação para ações importantes
  /// Retorna true se o usuário confirmar, false caso contrário
  Future<bool> _confirmarAcao(String titulo, String mensagem) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  

  
  // Método para construir a lista de estandes
  Widget _buildEstandeList() {
    if (_estandeList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_list_numbered, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhum estande cadastrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique no botão + para adicionar um novo estande',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EstandeScreen(),
                  ),
                ).then((value) {
                  if (value == true) {
                    _carregarListaEstandes();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Estande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _estandeList.length,
      itemBuilder: (context, index) {
        final estande = _estandeList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navegar para edição do estande
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EstandeScreen(estandeId: estande.id),
                ),
              ).then((value) {
                if (value == true) {
                  _carregarListaEstandes();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Estande #${estande.id ?? 'Novo'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF228B22),
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(estande.dataAvaliacao),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildEstandeListItem('Talhão', _talhaoNomes[estande.talhaoId] ?? 'Talhão ${estande.talhaoId}'),
                  _buildEstandeListItem('Cultura', _culturaNomes[estande.culturaId] ?? 'Cultura ${estande.culturaId}'),
                  _buildEstandeListItem('Variedade', _variedadeNomes[estande.variedadeId] ?? 'Variedade ${estande.variedadeId}'),
                  _buildEstandeListItem('Data', DateFormat('dd/MM/yyyy').format(estande.dataAvaliacao)),
                  _buildEstandeListItem('População Real', '${estande.resultadoEstande.toStringAsFixed(0)} plantas/ha'),
                  if (estande.populacaoDesejada != null)
                    _buildEstandeListItem('População Desejada', '${estande.populacaoDesejada} plantas/ha'),
                  if (estande.dae != null)
                    _buildEstandeListItem('DAE', '${estande.dae!.toStringAsFixed(0)} plantas/ha'),
                  if (estande.porcentagemFalha != null)
                    _buildEstandeListItem('Falha', '${estande.porcentagemFalha!.toStringAsFixed(1)}%'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmar = await _confirmarAcao(
                            'Confirmação',
                            'Deseja realmente excluir este estande?',
                          );
                          
                          if (confirmar) {
                            try {
                              await _estandeService.deleteEstande(estande.id!);
                              _mostrarSucesso('Estande excluído com sucesso!');
                              _carregarListaEstandes();
                            } catch (e) {
                              _mostrarErro('Erro ao excluir estande: $e');
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF228B22)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EstandeScreen(estandeId: estande.id),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _carregarListaEstandes();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget auxiliar para exibir itens na lista de estandes
  Widget _buildEstandeListItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    var buildDateField = _buildDateField(
                          label: 'Data da Avaliação',
                          value: _dataAvaliacao,
                          onTap: _selecionarData
                        );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: Text(_showList ? 'Lista de Estandes' : (_isEditing ? 'Editar Estande' : 'Estande de Plantas')),
        elevation: 0,
        actions: [
          if (_showList)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navegar para a tela de cadastro de estande
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EstandeScreen(),
                  ),
                ).then((value) {
                  if (value == true) {
                    // Recarregar a lista se um novo estande foi adicionado
                    _carregarListaEstandes();
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : _showList 
              ? _buildEstandeList()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCard(
                      title: 'Informações da Cultura',
                      icon: Icons.spa,
                      children: [
                        _buildDropdownField(
                          label: 'Talhão',
                          controller: _talhaoController,
                          onTap: _selecionarTalhao,
                          icon: Icons.crop_square,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Cultura',
                          controller: _culturaController,
                          onTap: _selecionarCultura,
                          icon: Icons.spa,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Variedade',
                          controller: _variedadeController,
                          onTap: _selecionarVariedade,
                          icon: Icons.grain,
                        ),
                        const SizedBox(height: 16),
                        buildDateField,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Medições',
                      icon: Icons.straighten,
                      children: [
                        TextFormField(
                          controller: _linhasController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Linhas Avaliadas',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.view_week),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o número de linhas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _comprimentoController,
                          decoration: const InputDecoration(
                            labelText: 'Comprimento da Linha (metros)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o comprimento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _espacamentoController,
                          decoration: const InputDecoration(
                            labelText: 'Espaçamento entre Linhas (metros)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.space_bar),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o espaçamento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _plantasContadasController,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade de Plantas Contadas',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.grass),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a quantidade de plantas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _populacaoDesejadaController,
                          decoration: const InputDecoration(
                            labelText: 'População Desejada (plantas/ha)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a população desejada';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _germinacaoEstimadaController,
                          decoration: const InputDecoration(
                            labelText: 'Germinação Estimada (%) - Opcional',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _calcularEstande,
                          icon: const Icon(Icons.calculate),
                          label: const Text('CALCULAR ESTANDE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF228B22),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_calculoRealizado) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Resultado',
                        icon: Icons.check_circle,
                        children: [
                          // População Real
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'População Real',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_resultadoEstande.toStringAsFixed(0)} plantas/ha',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF228B22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // DAE e Porcentagem de Falha
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DAE',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_dae.toStringAsFixed(0)} plantas/ha',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Desvio Absoluto Esperado',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _porcentagemFalha > 20 ? Colors.red.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _porcentagemFalha > 20 ? Colors.red.shade200 : Colors.orange.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Falha',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_porcentagemFalha.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _porcentagemFalha > 20 ? Colors.red.shade700 : Colors.orange.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Porcentagem de Falha',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Recomendação Técnica
                          if (_recomendacaoTecnica.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _porcentagemFalha > 20 ? Colors.amber.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _porcentagemFalha > 20 ? Colors.amber.shade200 : Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recomendação Técnica',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _recomendacaoTecnica,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _porcentagemFalha > 20 ? Colors.amber.shade900 : Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Observações
                          TextFormField(
                            controller: _observacoesController,
                            decoration: const InputDecoration(
                              labelText: 'Observações',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvarEstande,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF228B22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'SALVAR ESTANDE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Fotos do Estande',
                      icon: Icons.photo_library,
                      children: [
                        SizedBox(
                          height: 120,
                          child: _fotos.isEmpty
                              ? Center(
                                  child: Text(
                                    'Nenhuma foto adicionada',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _fotos.length,
                                  itemBuilder: (context, index) {
                                    final file = File(_fotos[index]);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _abrirFotoAmpliada(file),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                file,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 120,
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Icon(Icons.error),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _fotos.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _escolherFoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Adicionar Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF228B22),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF228B22),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdownField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione $label';
        }
        return null;
      },
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(value);
    
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        hintText: formattedDate,
      ),
      controller: TextEditingController(text: formattedDate),
    );
  }
  
  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      try {
        // Comprime a imagem para economizar espaço
        final compressedImage = await _compressImage(File(pickedFile.path));
        
        setState(() {
          _fotos.add(compressedImage.path);
        });
      } catch (e) {
        _mostrarErro('Erro ao processar imagem: $e');
      }
    }
  }
  
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 85,
      minWidth: 1200,
      minHeight: 1200,
    );
    
    return File(result!.path);
  }
  
  // Função para abrir foto ampliada em tela cheia
  Future<void> _abrirFotoAmpliada(File foto) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Visualizar Foto'),
            backgroundColor: const Color(0xFF228B22),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                foto,
                fit: BoxFit.contain,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF228B22),
        ),
      ),
    );
  }
  
  // Métodos para seleção de dados
  Future<void> _selecionarTalhao() async {
    try {
      // Carregar talhões do módulo Talhões com safra usando DataCacheService
      final dataCacheService = DataCacheService();
      final talhoes = await dataCacheService.getTalhoes(forceRefresh: true);
      
      if (talhoes.isEmpty) {
        _mostrarErro('Nenhum talhão com safra cadastrado. Cadastre talhões com safra primeiro.');
        // Opção para navegar para o cadastro de talhões
        final irParaCadastro = await _confirmarAcao(
          'Navegação',
          'Deseja ir para o cadastro de talhões com safra?'
        );
        
        if (irParaCadastro && mounted) {
          Navigator.of(context).pushNamed('/fazenda/talhoes-safra').then((_) {
            // Recarregar talhões quando voltar
            _selecionarTalhao();
          });
        }
        return;
      }
      
      // Converter talhões para o formato esperado pelo seletor
      final opcoes = talhoes.map((talhao) => {
        'id': int.tryParse(talhao.id) ?? 0,
        'nome': talhao.nome,
        'area': talhao.area,
        'safra': talhao.safraAtualPeriodo,
        'cultura': talhao.cultura,
        'culturaId': talhao.culturaId,
      }).toList();
      
      final result = await _mostrarSelecao('Selecionar Talhão', opcoes);
      
      if (result != null) {
        setState(() {
          _talhaoId = result['id'];
          _talhaoController.text = '${result['nome']} - ${result['safra'] ?? 'Sem safra'}';
          
          // Pré-selecionar a cultura do talhão, se disponível
          if (result['culturaId'] != null) {
            _culturaId = int.tryParse(result['culturaId']);
            _culturaController.text = result['cultura'] ?? 'Cultura não especificada';
          }
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar talhões: $e');
    }
  }
  
  Future<void> _selecionarCultura() async {
    try {
      // Carregar culturas do banco de dados
      final agriculturalProductRepository = AgriculturalProductRepository();
      final culturas = await agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
      
      if (culturas.isEmpty) {
        _mostrarErro('Nenhuma cultura cadastrada. Cadastre culturas primeiro.');
        // Opção para navegar para o cadastro de culturas
        final irParaCadastro = await _confirmarAcao(
          'Navegação',
          'Deseja ir para o cadastro de culturas da fazenda?'
        );
        
        if (irParaCadastro && mounted) {
          Navigator.of(context).pushNamed('/culturas-pragas/culturas-fazenda').then((_) {
            // Recarregar culturas quando voltar
            _selecionarCultura();
          });
        }
        return;
      }
      
      // Filtrar apenas culturas principais (não variedades)
      final culturasPrincipais = culturas.where((c) => c.parentId == null).toList();
      
      // Converter para o formato esperado pelo seletor
      final opcoes = culturasPrincipais.map((c) => {
        'id': int.tryParse(c.id) ?? 0,
        'nome': c.name,
        'colorValue': c.colorValue,
      }).toList();
      
      final result = await _mostrarSelecao('Selecionar Cultura', opcoes);
      
      if (result != null) {
        setState(() {
          _culturaId = result['id'];
          _culturaController.text = result['nome'];
          // Limpar variedade quando mudar a cultura
          _variedadeId = null;
          _variedadeController.clear();
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar culturas: $e');
    }
  }
  
  // Método para selecionar variedade
  Future<void> _selecionarVariedade() async {
    if (_culturaId == null) {
      _mostrarErro('Selecione uma cultura primeiro');
      return;
    }
    
    try {
      // Carregar variedades do banco de dados
      final agriculturalProductRepository = AgriculturalProductRepository();
      final produtos = await agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
      
      // Filtrar apenas variedades da cultura selecionada
      final variedades = produtos.where((p) => p.parentId == _culturaId).toList();
      
      if (variedades.isEmpty) {
        // Perguntar se deseja cadastrar nova variedade
        final cadastrarNova = await _confirmarAcao(
          'Cadastro de Variedade',
          'Nenhuma variedade encontrada para esta cultura. Deseja cadastrar uma nova variedade?'
        );
        
        if (cadastrarNova) {
          await _cadastrarNovaVariedade();
        }
        return;
      }
      
      final opcoes = variedades.map((variedade) => {
        'id': int.tryParse(variedade.id) ?? 0,
        'nome': variedade.name,
      }).toList();
      
      // Adicionar opção para cadastrar nova variedade
      opcoes.add({
        'id': -1,
        'nome': '+ Cadastrar nova variedade',
      });
      
      final resultado = await _mostrarSelecao('Selecionar Variedade', opcoes);
      if (resultado != null) {
        if (resultado['id'] == -1) {
          // Cadastrar nova variedade
          await _cadastrarNovaVariedade();
        } else {
          setState(() {
            _variedadeId = resultado['id'];
            _variedadeController.text = resultado['nome'];
          });
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar variedades: $e');
    }
  }
  
  // Método para cadastrar nova variedade
  Future<void> _cadastrarNovaVariedade() async {
    final nomeController = TextEditingController();
    
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Variedade'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome da Variedade',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nomeController.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    
    if (resultado != null && resultado.isNotEmpty) {
      try {
        // Criar nova variedade no banco
        final novaVariedade = AgriculturalProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: resultado,
          type: ProductType.seed,
          parentId: _culturaId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final repository = AgriculturalProductRepository();
        await repository.insert(novaVariedade);
        
        setState(() {
          _variedadeId = int.tryParse(novaVariedade.id) ?? 0;
          _variedadeController.text = novaVariedade.name;
        });
        
        _mostrarSucesso('Variedade cadastrada com sucesso!');
      } catch (e) {
        _mostrarErro('Erro ao cadastrar variedade: $e');
      }
    }
  }

  
  Future<Map<String, dynamic>?> _mostrarSelecao(String titulo, List<Map<String, dynamic>> opcoes) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: opcoes.length,
            itemBuilder: (context, index) {
              final opcao = opcoes[index];
              return ListTile(
                title: Text(opcao['nome']),
                onTap: () => Navigator.of(context).pop(opcao),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
} 