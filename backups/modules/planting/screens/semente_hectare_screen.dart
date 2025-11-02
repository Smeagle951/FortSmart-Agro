import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/semente_hectare_model.dart';
import '../services/semente_hectare_service.dart';
import '../services/modules_integration_service.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../models/agricultural_product.dart';

class SementeHectareScreen extends StatefulWidget {
  final int? sementeHectareId;

  const SementeHectareScreen({Key? key, this.sementeHectareId}) : super(key: key);

  @override
  _SementeHectareScreenState createState() => _SementeHectareScreenState();
}

class _SementeHectareScreenState extends State<SementeHectareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sementeHectareService = SementeHectareService();
  final _modulesService = ModulesIntegrationService();
  
  // Controllers
  final _nomeCalculoController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _populacaoController = TextEditingController();
  final _pesoMilSementesController = TextEditingController();
  final _germinacaoController = TextEditingController();
  final _purezaController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _talhaoController = TextEditingController();
  
  // Dados
  int? _culturaId;
  int? _variedadeId;
  String? _talhaoId;
  DateTime _dataCalculo = DateTime.now();
  double _resultadoKgHectare = 0;
  bool _calculoRealizado = false;
  
  // Lista de talhões disponíveis
  List<dynamic> _talhoes = [];
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarTalhoes();
  }

  @override
  void dispose() {
    // Dispose dos controllers para evitar memory leaks
    _nomeCalculoController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _populacaoController.dispose();
    _pesoMilSementesController.dispose();
    _germinacaoController.dispose();
    _purezaController.dispose();
    _observacoesController.dispose();
    _talhaoController.dispose();
    super.dispose();
  }
  
  Future<void> _carregarDados() async {
    if (widget.sementeHectareId != null) {
      setState(() => _isLoading = true);
      try {
        final sementeHectare = await _sementeHectareService.getSementeHectareById(widget.sementeHectareId!);
        if (sementeHectare != null) {
          setState(() {
            _culturaId = sementeHectare.culturaId;
            _variedadeId = sementeHectare.variedadeId;
            if (sementeHectare.talhaoId != null) {
              _talhaoId = sementeHectare.talhaoId.toString();
            }
            _populacaoController.text = sementeHectare.populacao.toString();
            _pesoMilSementesController.text = sementeHectare.pesoMilSementes.toString();
            _germinacaoController.text = sementeHectare.germinacao.toString();
            _purezaController.text = sementeHectare.pureza.toString();
            _resultadoKgHectare = sementeHectare.resultadoKgHectare;
            _calculoRealizado = true;
            _dataCalculo = sementeHectare.dataCalculo;
            _observacoesController.text = sementeHectare.observacoes ?? '';
            
            // Carregar informações de nomes para os dropdowns
            _carregarNomesCultura();
            _carregarNomesVariedade();
            _carregarNomeTalhao();
          });
        }
      } catch (e) {
        _mostrarErro('Erro ao carregar dados: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _carregarNomesCultura() async {
    if (_culturaId == null) return;
    
    try {
      final cultura = await _modulesService.getCulturaPorId(_culturaId!.toString());
      
      if (cultura != null) {
        setState(() {
          _culturaController.text = cultura.name;
        });
      } else {
        final repository = AgriculturalProductRepository();
        final produtos = await repository.getAll();
        final culturaProduto = produtos.firstWhere(
          (p) => int.tryParse(p.id) == _culturaId,
          orElse: () => AgriculturalProduct(
            id: _culturaId.toString(),
            name: 'Cultura $_culturaId',
            type: ProductType.seed,
          ),
        );
        
        setState(() {
          _culturaController.text = culturaProduto.name;
        });
      }
    } catch (e) {
      print('Erro ao carregar nome da cultura: $e');
    }
  }
  
  Future<void> _carregarNomesVariedade() async {
    if (_variedadeId == null || _culturaId == null) return;
    
    try {
      final variedade = await _modulesService.getVariedadePorId(_variedadeId!.toString());
      
      if (variedade != null) {
        setState(() {
          _variedadeController.text = variedade.name;
        });
      } else {
        final repository = AgriculturalProductRepository();
        final produtos = await repository.getAll();
        final variedadeProduto = produtos.firstWhere(
          (p) => int.tryParse(p.id) == _variedadeId,
          orElse: () => AgriculturalProduct(
            id: _variedadeId.toString(),
            name: 'Variedade $_variedadeId',
            type: ProductType.seed,
          ),
        );
        
        setState(() {
          _variedadeController.text = variedadeProduto.name;
        });
      }
    } catch (e) {
      print('Erro ao carregar nome da variedade: $e');
    }
  }
  
  /// Carrega a lista de talhões disponíveis
  Future<void> _carregarTalhoes() async {
    setState(() => _isLoading = true);
    
    try {
      // Carrega todos os talhões
      final talhoes = await _modulesService.getTalhoes(forceRefresh: true);
      
      setState(() {
        _talhoes = List<dynamic>.from(talhoes);
      });
      
      if (_talhoes.isEmpty) {
        print('Nenhum talhão encontrado');
      } else {
        print('${_talhoes.length} talhões carregados');
      }
    } catch (e) {
      print('Erro ao carregar talhões: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  /// Carrega o nome do talhão selecionado
  Future<void> _carregarNomeTalhao() async {
    if (_talhaoId == null) return;
    
    try {
      // Busca o talhão pelo ID na lista de talhões carregados
      if (_talhoes.isEmpty) {
        await _carregarTalhoes();
      }
      
      // Tenta encontrar o talhão pelo ID
      final talhaoEncontrado = _talhoes.where((t) => t.id == _talhaoId).toList();
      
      if (talhaoEncontrado.isNotEmpty) {
        setState(() {
          _talhaoController.text = talhaoEncontrado.first.nome;
        });
      } else {
        print('Talhão com ID $_talhaoId não encontrado');
      }
    } catch (e) {
      print('Erro ao carregar nome do talhão: $e');
    }
  }
  
  /// Exibe diálogo para seleção de talhão
  Future<void> _selecionarTalhao() async {
    if (_talhoes.isEmpty) {
      final cadastrarNovo = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nenhum talhão cadastrado'),
          content: const Text('Deseja cadastrar um novo talhão?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        ),
      );
      
      if (cadastrarNovo == true) {
        // Navegar para a tela de cadastro de talhões
        final resultado = await Navigator.of(context).pushNamed('/talhoes/cadastro');
        if (resultado == true) {
          await _carregarTalhoes();
          _selecionarTalhao();
        }
      }
      return;
    }
    
    final opcoes = _talhoes.map((talhao) => {
      'id': talhao.id,
      'nome': talhao.nome,
    }).toList();
    
    opcoes.add({
      'id': 'novo',
      'nome': '+ Cadastrar novo talhão',
    });
    
    final resultado = await _mostrarSelecao('Selecionar Talhão', opcoes);
    
    if (resultado != null) {
      if (resultado['id'] == 'novo') {
        final cadastrou = await Navigator.of(context).pushNamed('/talhoes/cadastro');
        if (cadastrou == true) {
          await _carregarTalhoes();
          await _selecionarTalhao();
        }
      } else {
        setState(() {
          _talhaoId = resultado['id'];
          _talhaoController.text = resultado['nome'];
        });
      }
    }
  }
  
  void _calcular() {
    if (!_validarCamposCalculo()) return;
    
    final populacao = double.parse(_populacaoController.text);
    final pesoMilSementes = double.parse(_pesoMilSementesController.text);
    final germinacao = double.parse(_germinacaoController.text);
    final pureza = double.parse(_purezaController.text);
    
    // Calcular kg/ha usando o serviço
    final kgPorHectare = _sementeHectareService.calcularSementesKgHa(
      populacao, 
      pesoMilSementes, 
      germinacao, 
      pureza
    );
    
    setState(() {
      _resultadoKgHectare = kgPorHectare;
      _calculoRealizado = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cálculo realizado com sucesso!'),
        backgroundColor: Color(0xFF228B22),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  bool _validarCamposCalculo() {
    if (_culturaId == null || _variedadeId == null) {
      _mostrarErro('Selecione a cultura e variedade');
      return false;
    }
    
    if (_talhaoId == null || _talhaoController.text.isEmpty) {
      _mostrarErro('Selecione um talhão');
      return false;
    }
    
    if (_populacaoController.text.isEmpty) {
      _mostrarErro('Informe a população desejada');
      return false;
    }
    
    if (_pesoMilSementesController.text.isEmpty) {
      _mostrarErro('Informe o peso de mil sementes');
      return false;
    }
    
    if (_germinacaoController.text.isEmpty) {
      _mostrarErro('Informe o percentual de germinação');
      return false;
    }
    
    if (_purezaController.text.isEmpty) {
      _mostrarErro('Informe o percentual de pureza');
      return false;
    }
    
    // Validar valores numéricos
    try {
      final populacao = double.parse(_populacaoController.text);
      final pesoMilSementes = double.parse(_pesoMilSementesController.text);
      final germinacao = double.parse(_germinacaoController.text);
      final pureza = double.parse(_purezaController.text);
      
      if (populacao <= 0) {
        _mostrarErro('A população deve ser maior que zero');
        return false;
      }
      
      if (pesoMilSementes <= 0) {
        _mostrarErro('O peso de mil sementes deve ser maior que zero');
        return false;
      }
      
      if (germinacao <= 0 || germinacao > 100) {
        _mostrarErro('O percentual de germinação deve estar entre 1 e 100');
        return false;
      }
      
      if (pureza <= 0 || pureza > 100) {
        _mostrarErro('O percentual de pureza deve estar entre 1 e 100');
        return false;
      }
    } catch (e) {
      _mostrarErro('Valores inválidos. Verifique os campos numéricos');
      return false;
    }
    
    return true;
  }
  
  Future<void> _salvarCalculo() async {
    if (!_validarCamposCalculo()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final sementeHectare = SementeHectareModel(
        id: widget.sementeHectareId,
        talhaoId: _talhaoId != null ? int.tryParse(_talhaoId!) : null,
        culturaId: _culturaId!,
        variedadeId: _variedadeId!,
        populacao: double.parse(_populacaoController.text),
        pesoMilSementes: double.parse(_pesoMilSementesController.text),
        germinacao: double.parse(_germinacaoController.text),
        pureza: double.parse(_purezaController.text),
        resultadoKgHectare: _resultadoKgHectare,
        dataCalculo: _dataCalculo,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );
      
      await _sementeHectareService.saveSementeHectare(sementeHectare);
      
      _mostrarMensagem('Cálculo salvo com sucesso!');
      
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro('Erro ao salvar cálculo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selecionarCultura() async {
    setState(() => _isLoading = true);
    try {
      final culturas = await _modulesService.getCulturas(forceRefresh: true);
      
      setState(() => _isLoading = false);
      
      if (culturas.isEmpty) {
        final cadastrarNova = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nenhuma cultura cadastrada'),
            content: const Text('Deseja cadastrar uma nova cultura?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Não'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sim'),
              ),
            ],
          ),
        );
        
        if (cadastrarNova == true) {
          final resultado = await Navigator.of(context).pushNamed('/culturas/cadastro');
          if (resultado == true) {
            _selecionarCultura();
          }
        }
        return;
      }
      
      final opcoes = culturas.map((cultura) => {
        'id': int.tryParse(cultura.id.toString()) ?? -1,
        'nome': cultura.name,
      }).toList();
      
      opcoes.add({
        'id': -1,
        'nome': '+ Cadastrar nova cultura',
      });
      
      final resultado = await _mostrarSelecao('Selecionar Cultura', opcoes);
      
      if (resultado != null) {
        if (resultado['id'] == -1) {
          final cadastrou = await Navigator.of(context).pushNamed('/culturas/cadastro');
          if (cadastrou == true) {
            await _selecionarCultura();
          }
        } else {
          setState(() {
            _culturaId = resultado['id'];
            _culturaController.text = resultado['nome'];
            _variedadeId = null;
            _variedadeController.text = '';
          });
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar culturas: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selecionarVariedade() async {
    if (_culturaId == null) {
      _mostrarErro('Selecione uma cultura primeiro');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final variedades = await _modulesService.getVariedadesPorCultura(_culturaId!);
      
      setState(() => _isLoading = false);
      
      if (variedades.isEmpty) {
        final cadastrarNova = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nenhuma variedade cadastrada'),
            content: const Text('Deseja cadastrar uma nova variedade?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Não'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sim'),
              ),
            ],
          ),
        );
        
        if (cadastrarNova == true) {
          final resultado = await Navigator.of(context).pushNamed(
            '/variedades/cadastro',
            arguments: {'culturaId': _culturaId},
          );
          if (resultado == true) {
            _selecionarVariedade();
          }
        }
        return;
      }
      
      final opcoes = variedades.map((variedade) => {
        'id': int.tryParse(variedade.id) ?? -1,
        'nome': variedade.name,
      }).toList();
      
      opcoes.add({
        'id': -1,
        'nome': '+ Cadastrar nova variedade',
      });
      
      final resultado = await _mostrarSelecao('Selecionar Variedade', opcoes);
      if (resultado != null) {
        if (resultado['id'] == -1) {
          final cadastrou = await Navigator.of(context).pushNamed(
            '/culturas/variedades/cadastro',
            arguments: {'culturaId': _culturaId}
          );
          
          if (cadastrou == true) {
            await _selecionarVariedade();
          }
        } else {
          setState(() {
            _variedadeId = resultado['id'];
            _variedadeController.text = resultado['nome'];
          });
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar variedades: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF228B22),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Future<Map<String, dynamic>?> _mostrarSelecao(String titulo, List<Map<String, dynamic>> opcoes) async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> opcoesFiltradas = List.from(opcoes);
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(titulo),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            opcoesFiltradas = List.from(opcoes);
                          } else {
                            opcoesFiltradas = opcoes
                                .where((opcao) => opcao['nome']
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: opcoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final opcao = opcoesFiltradas[index];
                          final bool isAddOption = opcao['id'] == -1 || opcao['id'] == 'novo';
                          
                          return ListTile(
                            title: Text(
                              opcao['nome'],
                              style: TextStyle(
                                color: isAddOption ? Theme.of(context).primaryColor : null,
                                fontWeight: isAddOption ? FontWeight.bold : null,
                              ),
                            ),
                            leading: isAddOption ? Icon(Icons.add_circle, color: Theme.of(context).primaryColor) : null,
                            onTap: () => Navigator.of(context).pop(opcao),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Sementes/Hectare'),
        backgroundColor: const Color(0xFF228B22),
        foregroundColor: Colors.white,
        actions: [
          if (_calculoRealizado)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _salvarCalculo,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Opacity(
                    opacity: 0.05,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.grass,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nomeCalculoController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Cálculo*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe um nome para o cálculo';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _dataCalculo,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null && picked != _dataCalculo) {
                                setState(() {
                                  _dataCalculo = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data do cálculo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF228B22)),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_dataCalculo),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Campo de seleção de talhão
                          InkWell(
                            onTap: _selecionarTalhao,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Talhão*',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.map, color: Color(0xFF228B22)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _selecionarTalhao,
                                ),
                              ),
                              child: Text(
                                _talhaoController.text.isEmpty ? 'Selecione um talhão' : _talhaoController.text,
                                style: TextStyle(
                                  color: _talhaoController.text.isEmpty ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Campo de seleção de cultura
                          InkWell(
                            onTap: _selecionarCultura,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Cultura*',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.grass, color: Color(0xFF228B22)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _selecionarCultura,
                                ),
                              ),
                              child: Text(
                                _culturaController.text.isEmpty ? 'Selecione uma cultura' : _culturaController.text,
                                style: TextStyle(
                                  color: _culturaController.text.isEmpty ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Campo de seleção de variedade
                          InkWell(
                            onTap: _selecionarVariedade,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Variedade*',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.eco, color: Color(0xFF228B22)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _selecionarVariedade,
                                ),
                              ),
                              child: Text(
                                _variedadeController.text.isEmpty ? 'Selecione uma variedade' : _variedadeController.text,
                                style: TextStyle(
                                  color: _variedadeController.text.isEmpty ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _populacaoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'População desejada (plantas/ha)*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.group),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a população desejada';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Informe um valor válido';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _pesoMilSementesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Peso de 1000 sementes (g)*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o peso de mil sementes';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Informe um valor válido';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _germinacaoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Germinação (%)*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.spa),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o percentual de germinação';
                              }
                              final germinacao = double.tryParse(value);
                              if (germinacao == null || germinacao <= 0 || germinacao > 100) {
                                return 'Informe um valor entre 1 e 100';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _purezaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pureza (%)*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o percentual de pureza';
                              }
                              final pureza = double.tryParse(value);
                              if (pureza == null || pureza <= 0 || pureza > 100) {
                                return 'Informe um valor entre 1 e 100';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _observacoesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Observações',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          ElevatedButton(
                            onPressed: _calcular,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF228B22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('CALCULAR', style: TextStyle(fontSize: 16)),
                          ),
                          
                          if (_calculoRealizado) ...[  
                            const SizedBox(height: 24),
                            Card(
                              elevation: 4,
                              color: const Color(0xFFE8F5E9),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resultado do Cálculo',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Quantidade de sementes:',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          '${_resultadoKgHectare.toStringAsFixed(2)} kg/ha',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _salvarCalculo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF228B22),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 48),
                                      ),
                                      child: const Text('SALVAR CÁLCULO'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}