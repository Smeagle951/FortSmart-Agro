import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/semente_hectare_model.dart';
import '../services/semente_hectare_service.dart';
import '../services/modules_integration_service.dart';
// Imports removidos por não serem utilizados
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
  final _nomeCalculoController = TextEditingController(); // Adicionado para nome do cálculo
  // Remoção do controller de talhão
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _populacaoController = TextEditingController();
  final _pesoMilSementesController = TextEditingController();
  final _germinacaoController = TextEditingController();
  final _purezaController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Dados
  // Remoção das variáveis relacionadas a talhão
  int? _culturaId;
  int? _variedadeId;
  DateTime _dataCalculo = DateTime.now();
  double _resultadoKgHectare = 0;
  bool _calculoRealizado = false;
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  get foregroundColor => null;
  
  get duration => null;
  
  void _calcular() {
    if (_formKey.currentState!.validate()) {
      // Obter valores dos campos
      final populacao = double.tryParse(_populacaoController.text) ?? 0;
      final pesoMilSementes = double.tryParse(_pesoMilSementesController.text) ?? 0;
      final germinacao = double.tryParse(_germinacaoController.text) ?? 0;
      final pureza = double.tryParse(_purezaController.text) ?? 0;
      
      // Validar valores
      if (populacao <= 0 || pesoMilSementes <= 0 || germinacao <= 0 || pureza <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos os valores devem ser maiores que zero')),
        );
        return;
      }
      
      // Realizar cálculo
      // Fórmula: (População * PMS) / (Germinação * Pureza)
      final kgHectare = (populacao * pesoMilSementes) / 
                      ((germinacao / 100) * (pureza / 100) * 1000);
      
      setState(() {
        _resultadoKgHectare = kgHectare;
        _calculoRealizado = true;
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
    // Remoção do carregamento de talhões // Carrega dados iniciais
  }
  
  Future<void> _carregarDados() async {
    if (widget.sementeHectareId != null) {
      setState(() => _isLoading = true);
      try {
        final sementeHectare = await _sementeHectareService.getSementeHectareById(widget.sementeHectareId!);
        if (sementeHectare != null) {
          setState(() {
            _isEditing = true;
            // Remoção do carregamento do talhão
            _culturaId = sementeHectare.culturaId;
            _variedadeId = sementeHectare.variedadeId;
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
      // Usar o ModulesIntegrationService para obter a cultura pelo ID
      final cultura = await _modulesService.getCulturaPorId(_culturaId!.toString());
      
      if (cultura != null) {
        setState(() {
          _culturaController.text = cultura.name;
        });
      } else {
        // Fallback para o repositório antigo se não encontrar no serviço de integração
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
      // Usar o ModulesIntegrationService para obter a variedade pelo ID
      final variedade = await _modulesService.getVariedadePorId(_variedadeId!.toString());
      
      if (variedade != null) {
        setState(() {
          _variedadeController.text = variedade.name;
        });
      } else {
        // Fallback para o repositório antigo se não encontrar no serviço de integração
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
  
  void _realizarCalculo() {
    if (!_validarCamposCalculo()) return;
    
    final populacao = double.parse(_populacaoController.text);
    final pesoMilSementes = double.parse(_pesoMilSementesController.text);
    final germinacao = double.parse(_germinacaoController.text);
    final pureza = double.parse(_purezaController.text);
    
    // Calcular kg/ha
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
    
    // Mostrar uma animação ou feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cálculo realizado com sucesso!'),
        backgroundColor: 
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  bool _validarCamposCalculo() {
    if (_culturaId == null || _variedadeId == null) {
      _mostrarErro('Selecione a cultura e variedade');
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
      // Carregar culturas do ModulesIntegrationService
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
          // Navegar para tela de cadastro de culturas no módulo Culturas e Pragas
          final resultado = await Navigator.of(context).pushNamed('/culturas/cadastro');
          if (resultado == true) {
            // Recarregar culturas após cadastro
            _selecionarCultura();
          }
        }
        return;
      }
      
      final opcoes = culturas.map((cultura) => {
        'id': cultura.id,
        'nome': cultura.name,
      }).toList();
      
      // Adicionar opção para cadastrar nova cultura
      opcoes.add({
        'id': -1,
        'nome': '+ Cadastrar nova cultura',
      });
      
      final resultado = await _mostrarSelecao('Selecionar Cultura', opcoes);
      
      if (resultado != null) {
        if (resultado['id'] == -1) {
          // Navegar para tela de cadastro de culturas no módulo Culturas e Pragas
          final cadastrou = await Navigator.of(context).pushNamed('/culturas/cadastro');
          if (cadastrou == true) {
            // Recarregar culturas após cadastro
            await _selecionarCultura();
          }
        } else {
          setState(() {
            _culturaId = resultado['id'];
            _culturaController.text = resultado['nome'];
            // Limpar variedade quando mudar a cultura
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
      // Carregar variedades usando ModulesIntegrationService
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
          // Navegar para tela de cadastro de variedades no módulo Culturas e Pragas
          final resultado = await Navigator.of(context).pushNamed(
            '/variedades/cadastro',
            arguments: {'culturaId': _culturaId},
          );
          if (resultado == true) {
            // Recarregar variedades após cadastro
            _selecionarVariedade();
          }
        }
        return;
      }
      
      final opcoes = variedades.map((variedade) => {
        'id': variedade.id,
        'nome': variedade.name,
      }).toList();
      
      // Adicionar opção para cadastrar nova variedade
      opcoes.add({
        'id': '-1',
        'nome': '+ Cadastrar nova variedade',
      });
      
      final resultado = await _mostrarSelecao('Selecionar Variedade', opcoes);
      if (resultado != null) {
        if (resultado['id'] == -1) {
          // Usuário escolheu cadastrar nova variedade
          // Navegar para tela de cadastro de variedades no módulo Culturas e Pragas
          final cadastrou = await Navigator.of(context).pushNamed(
            '/culturas/variedades/cadastro',
            arguments: {'culturaId': _culturaId}
          );
          
          if (cadastrou == true) {
            // Recarregar variedades após cadastro
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
        backgroundColor: 
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
      ),
    );
  }
  
  // Método para exibir diálogo de seleção com busca
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
                    // Campo de busca
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
                    // Lista de opções
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: opcoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final opcao = opcoesFiltradas[index];
                          final bool isAddOption = opcao['id'] == '-1';
                          
                          return ListTile(
                            title: Text(
                              opcao['nome'],
                              style: TextStyle(
                                color: isAddOption ? Theme.of(context).primaryColor : null,
                                fontWeight: isAddOption ? FontWeight.bold : null,
                              ),
                            ),
                            leading: isAddOption ? Icon(Icons.add_circle, color: Theme.of(context).primaryColor) : null,
                            onTap:
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
        backgroundColor: Theme.of(context).primaryColor,
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
                // Fundo decorativo
                Positioned(
                  top: -50,
                  right: -50,
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset(
                      'assets/images/seeds_bg.png',
                      width: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(); // Retorna container vazio se a imagem não carregar
                      },
                    ),
                  ),
                ),
                // Conteúdo principal
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo para Nome do Cálculo
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
                            
                            // Campo para Data do Cálculo
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
                            
                            // Imagem ilustrativa
                            Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.asset(
                              'assets/images/calculo_sementes.png',
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 160,
                                  width: double.infinity,
                                  color: Colors.green.shade50,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.grass, size: 60, color: Colors.green.shade300),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Cálculo de Sementes',
                                          style: TextStyle(fontSize: 18, color: Colors.green.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Cálculo preciso de sementes baseado em população desejada, peso de mil sementes, pureza e germinação.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Card de Seleção de Cultura e Variedade
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.grass,
                                  color: Color(0xFF228B22),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Cultura e Variedade',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            TextFormField(
                              controller: _culturaController,
                              readOnly: true,
                              onTap: () {
                                _selecionarCultura();
                              },
                              decoration: const InputDecoration(
                                labelText: 'Cultura',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                                prefixIcon: Icon(Icons.agriculture, color: const Color(0xFF228B22)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione a cultura';
                                }
                                return null;
                              },
                            ),
                            
                            // Botão para adicionar cultura
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Navegar para a tela de cadastro de culturas
                                  Navigator.of(context).pushNamed('/culturas/cadastro').then((_) {
                                    // Recarregar culturas após cadastro
                                    _selecionarCultura();
                                  });
                                },
                                icon: const Icon(Icons.add, color: Color(0xFF228B22)),
                                label: const Text('Adicionar Cultura', style: TextStyle(color: Color(0xFF228B22))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF228B22)),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _variedadeController,
                              readOnly: true,
                              onTap: 
                              decoration: const InputDecoration(
                                labelText: 'Variedade',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                                prefixIcon: Icon(Icons.eco, color: const Color(0xFF228B22)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione a variedade';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Card de Parâmetros de Cálculo
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.calculate,
                                  color: Color(0xFF228B22),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Parâmetros de Cálculo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            TextFormField(
                              controller: _populacaoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'População Desejada (plantas/ha)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a população desejada';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pesoMilSementesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Peso de Mil Sementes (g)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.grass, color: const Color(0xFF228B22)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o peso de mil sementes';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _germinacaoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Germinação (%)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.spa),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o percentual de germinação';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _purezaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pureza (%)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.check_circle),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o percentual de pureza';
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
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.note),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calculate),
                                label: const Text('CALCULAR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: _calcular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Card de Resultado
                    if (_calculoRealizado)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF228B22),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Resultado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1),
                              Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Quantidade de Sementes Necessárias',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_resultadoKgHectare.toStringAsFixed(2)} kg/ha',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF228B22),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Data do cálculo: ${DateFormat('dd/MM/yyyy').format(_dataCalculo)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save),
                                  label: const Text('SALVAR CÁLCULO'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: _salvarCalculo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _calcular,
        backgroundColor: const Color(0xFF228B22),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.calculate),
        label: const Text('Calcular'),
      ),
    );
  }

  @override
  void dispose() {
    _culturaController.dispose();
    _variedadeController.dispose();
    _populacaoController.dispose();
    _pesoMilSementesController.dispose();
    _germinacaoController.dispose();
    _purezaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }