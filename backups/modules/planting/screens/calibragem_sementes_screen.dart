import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calibragem_sementes_model.dart';
import '../services/calibragem_sementes_service.dart';
import '../services/modules_integration_service.dart';
import '../../../models/talhao_model.dart';
import '../../../utils/logger.dart';

class CalibragemSementesScreen extends StatefulWidget {
  final int? calibragemId;

  const CalibragemSementesScreen({Key? key, this.calibragemId}) : super(key: key);

  @override
  _CalibragemSementesScreenState createState() => _CalibragemSementesScreenState();
}

class _CalibragemSementesScreenState extends State<CalibragemSementesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calibragemService = CalibragemSementesService();
  final _modulesService = ModulesIntegrationService();

  // Controllers
  final _nomeController = TextEditingController();
  final _sementesColetadasController = TextEditingController();
  final _linhasColetadasController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _populacaoDesejadaController = TextEditingController();
  
  // Controllers para disco de sementes
  final _numeroFurosController = TextEditingController();
  final _engrenagemMotoraController = TextEditingController();
  final _engrenagemMovidaController = TextEditingController();
  final _numeroLinhasPlantadeiraController = TextEditingController();
  
  // Controllers para talhão e cultura
  final _talhaoController = TextEditingController();
  final _culturaController = TextEditingController();
  
  // Dados
  DateTime _dataRegulagem = DateTime.now();
  bool _calculoRealizado = false;
  bool _usaDiscoEngrenagens = false;
  bool _isLoading = false;
  Map<String, double> _resultados = {};
  
  // Dados de integração com outros módulos
  String? _talhaoId;
  int? _culturaId;
  List<TalhaoModel> _talhoes = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.calibragemId != null) {
      _carregarDadosExistentes();
    } else {
      _carregarDados();
    }
    // Valor padrão para linhas coletadas
    _linhasColetadasController.text = '1';
    
    // Carregar talhões e culturas
    _carregarTalhoes();
  }
  
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implementar carregamento de dados existentes
    // Por enquanto apenas inicializa os valores padrão
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
    });
  }
  
  // Método para carregar a lista de talhões disponíveis
  Future<void> _carregarTalhoes() async {
    try {
      final talhoes = await _modulesService.getTalhoes();
      setState(() {
        _talhoes = talhoes;
      });
      Logger.log('Carregados ${talhoes.length} talhões');
    } catch (e) {
      _mostrarErro('Erro ao carregar talhões: $e');
    }
  }
  
  // Método para exibir mensagem de erro
  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }
  
  // Método para selecionar talhão
  Future<void> _selecionarTalhao() async {
    if (_talhoes.isEmpty) {
      await _carregarTalhoes();
      if (_talhoes.isEmpty) {
        _mostrarErro('Nenhum talhão disponível');
        return;
      }
    }
    
    if (!mounted) return;
    
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
                title: Text(talhao.nome),
                subtitle: Text('${talhao.area.toStringAsFixed(2)} ha'),
                onTap: () {
                  setState(() {
                    _talhaoId = talhao.id;
                    _talhaoController.text = talhao.nome;
                  });
                  Navigator.of(context).pop();
                },
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
  
  // Método para selecionar cultura
  Future<void> _selecionarCultura() async {
    try {
      final culturas = await _modulesService.getCulturas();
      
      if (culturas.isEmpty) {
        _mostrarErro('Nenhuma cultura disponível');
        return;
      }
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selecionar Cultura'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: culturas.length,
              itemBuilder: (context, index) {
                final cultura = culturas[index];
                return ListTile(
                  title: Text(cultura.name),
                  onTap: () {
                    setState(() {
                      _culturaId = cultura.id;
                      _culturaController.text = cultura.name;
                    });
                    Navigator.of(context).pop();
                  },
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
    } catch (e) {
      _mostrarErro('Erro ao carregar culturas: $e');
    }
  }
  
  // Método para carregar o nome do talhão quando carregando um registro existente
  Future<void> _carregarNomeTalhao() async {
    if (_talhaoId == null) return;
    
    try {
      final talhao = await _modulesService.getTalhaoById(_talhaoId!);
      if (talhao != null && mounted) {
        setState(() {
          _talhaoController.text = talhao.nome;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar nome do talhão: $e');
    }
  }
  
  // Método para carregar o nome da cultura quando carregando um registro existente
  Future<void> _carregarNomeCultura() async {
    if (_culturaId == null) return;
    
    try {
      final cultura = await _modulesService.getCulturaById(_culturaId!);
      if (cultura != null && mounted) {
        setState(() {
          _culturaController.text = cultura.name;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar nome da cultura: $e');
    }
  }
  
  // Método para carregar dados existentes
  Future<void> _carregarDadosExistentes() async {
    setState(() => _isLoading = true);
    try {
      final calibragem = await _calibragemService.getCalibragemById(widget.calibragemId!);
      
      if (calibragem != null) {
        _nomeController.text = calibragem.nome ?? '';
        _sementesColetadasController.text = calibragem.sementesColetadas.toString();
        _linhasColetadasController.text = calibragem.linhasColetadas.toString();
        _espacamentoController.text = calibragem.espacamentoEntreLinhas.toString();
        _populacaoDesejadaController.text = calibragem.populacaoDesejada.toString();
        _dataRegulagem = calibragem.dataRegulagem;
        
        // Carregar dados de talhão e cultura
        _talhaoId = calibragem.talhaoId;
        _culturaId = calibragem.culturaId;
        
        // Carregar nomes de talhão e cultura se IDs estiverem presentes
        if (_talhaoId != null) {
          _carregarNomeTalhao();
        }
        
        if (_culturaId != null) {
          _carregarNomeCultura();
        }
        
        if (calibragem.numeroFurosNoDisco != null) {
          _usaDiscoEngrenagens = true;
          _numeroFurosController.text = calibragem.numeroFurosNoDisco.toString();
          _engrenagemMotoraController.text = calibragem.engrenagemMotora.toString();
          _engrenagemMovidaController.text = calibragem.engrenagemMovida.toString();
          _numeroLinhasPlantadeiraController.text = calibragem.numeroLinhasPlantadeira.toString();
          _calculoRealizado = true;
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _calcularCalibragem() {
    if (!_validarCamposCalculo()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (!_usaDiscoEngrenagens) {
        // Cálculo tradicional
        final sementesColetadas = double.parse(_sementesColetadasController.text);
        final linhasColetadas = int.parse(_linhasColetadasController.text);
        final espacamento = double.parse(_espacamentoController.text);
        final populacaoDesejada = _populacaoDesejadaController.text.isNotEmpty 
            ? double.parse(_populacaoDesejadaController.text) 
            : null;
        
        _resultados = _calibragemService.calcularResultados(
          sementesColetadas: sementesColetadas,
          linhasColetadas: linhasColetadas,
          espacamentoEntreLinhas: espacamento,
          populacaoDesejada: populacaoDesejada,
        );
      } else {
        // Cálculo por disco
        final numeroFuros = int.parse(_numeroFurosController.text);
        final engrenagemMotora = int.parse(_engrenagemMotoraController.text);
        final engrenagemMovida = int.parse(_engrenagemMovidaController.text);
        final espacamento = double.parse(_espacamentoController.text);
        final populacaoDesejada = _populacaoDesejadaController.text.isNotEmpty 
            ? double.parse(_populacaoDesejadaController.text) 
            : null;
        
        _resultados = _calibragemService.calcularResultadosVacuo(
          numeroFuros: numeroFuros,
          engrenagemMotora: engrenagemMotora,
          engrenagemMovida: engrenagemMovida,
          espacamentoEntreLinhas: espacamento,
          populacaoDesejada: populacaoDesejada,
        );
      }
      
      setState(() => _calculoRealizado = true);
      _mostrarSucesso('Cálculo realizado com sucesso!');
    } catch (e) {
      _mostrarErro('Erro ao calcular: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  bool _validarCamposCalculo() {
    if (_nomeController.text.isEmpty) {
      _mostrarErro('Informe um nome para a calibragem');
      return false;
    }
    
    // Validar talhão e cultura
    if (_talhaoId == null || _talhaoController.text.isEmpty) {
      _mostrarErro('Selecione um talhão');
      return false;
    }
    
    if (_culturaId == null || _culturaController.text.isEmpty) {
      _mostrarErro('Selecione uma cultura');
      return false;
    }
    
    if (!_usaDiscoEngrenagens) {
      // Validação para cálculo tradicional
      if (_sementesColetadasController.text.isEmpty) {
        _mostrarErro('Informe a quantidade de sementes coletadas por metro');
        return false;
      }
      
      if (_linhasColetadasController.text.isEmpty) {
        _mostrarErro('Informe o número de linhas coletadas');
        return false;
      }
    } else {
      // Validação para cálculo por disco
      if (_numeroFurosController.text.isEmpty) {
        _mostrarErro('Informe o número de furos no disco');
        return false;
      }
      
      if (_engrenagemMotoraController.text.isEmpty) {
        _mostrarErro('Informe o número de dentes da engrenagem motora');
        return false;
      }
      
      if (_engrenagemMovidaController.text.isEmpty) {
        _mostrarErro('Informe o número de dentes da engrenagem movida');
        return false;
      }
      
      if (_numeroLinhasPlantadeiraController.text.isEmpty) {
        _mostrarErro('Informe o número de linhas da plantadeira');
        return false;
      }
    }
    
    if (_espacamentoController.text.isEmpty) {
      _mostrarErro('Informe o espaçamento entre linhas');
      return false;
    }
    
    return true;
  }
  
  Future<void> _salvarCalibragem() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_calculoRealizado) {
      _mostrarErro('Realize o cálculo antes de salvar');
      return;
    }
    
    // Validar talhão e cultura
    if (_talhaoId == null || _talhaoController.text.isEmpty) {
      _mostrarErro('Selecione um talhão');
      return;
    }
    
    if (_culturaId == null || _culturaController.text.isEmpty) {
      _mostrarErro('Selecione uma cultura');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final calibragem = CalibragemSementesModel(
        id: widget.calibragemId,
        nome: _nomeController.text,
        dataRegulagem: _dataRegulagem,
        sementesPorMetro: _resultados['sementesPorMetro']!,
        sementesColetadas: double.parse(_sementesColetadasController.text),
        linhasColetadas: _usaDiscoEngrenagens ? null : int.parse(_linhasColetadasController.text),
        espacamentoEntreLinhas: double.parse(_espacamentoController.text),
        populacaoDesejada: _populacaoDesejadaController.text.isNotEmpty 
            ? double.parse(_populacaoDesejadaController.text) 
            : null,
        usaDiscoEngrenagens: _usaDiscoEngrenagens,
        numeroFurosNoDisco: _usaDiscoEngrenagens ? int.parse(_numeroFurosController.text) : null,
        engrenagemMotora: _usaDiscoEngrenagens ? int.parse(_engrenagemMotoraController.text) : null,
        engrenagemMovida: _usaDiscoEngrenagens ? int.parse(_engrenagemMovidaController.text) : null,
        numeroLinhasPlantadeira: _usaDiscoEngrenagens ? int.parse(_numeroLinhasPlantadeiraController.text) : null,
        plantasPorMetro: _resultados['plantasPorMetro']!,
        plantasPorHectare: _resultados['plantasPorHectare']!,
        plantasPorMetroQuadrado: _resultados['plantasPorMetroQuadrado']!,
        // Adicionar talhão e cultura
        talhaoId: _talhaoId,
        culturaId: _culturaId,
        erroPorcentagem: _populacaoDesejadaController.text.isNotEmpty ? _resultados['erroPorcentagem'] : null,
      );
      
      await _calibragemService.saveCalibragemSementes(calibragem);
      
      _mostrarSucesso('Calibragem salva com sucesso!');
      
      // Volta para a tela anterior após salvar
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro('Erro ao salvar calibragem: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataRegulagem,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF36963E),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (data != null) {
      setState(() => _dataRegulagem = data);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calibragemId == null ? 'Nova Calibragem' : 'Editar Calibragem'),
        actions: [
          if (_calculoRealizado)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _salvarCalibragem,
              tooltip: 'Salvar calibragem',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagem ilustrativa
                    Center(
                      child: Image.asset(
                        'assets/images/calibragem_sementes.png',
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.grass,
                              size: 80,
                              color: Color(0xFF36963E),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card de informações básicas
                    _buildCard(
                      title: 'Informações da Calibragem',
                      icon: Icons.info_outline,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Calibragem*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe um nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Alternância entre métodos de cálculo
                    SwitchListTile(
                      title: const Text(
                        'Usar disco perfurado com engrenagens',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Calibragem por disco - Plantadeira a vácuo',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _usaDiscoEngrenagens,
                      activeColor: const Color(0xFF36963E),
                      onChanged: (value) {
                        setState(() {
                          _usaDiscoEngrenagens = value;
                          _calculoRealizado = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Parâmetros diferentes dependendo do modo
                    _usaDiscoEngrenagens 
                        ? _buildDiscParameters()
                        : _buildStandardParameters(),
                    
                    const SizedBox(height: 16),
                    
                    // Parâmetros comuns
                    _buildCommonParameters(),
                    
                    const SizedBox(height: 16),
                    
                    // Botão de calcular
                    ElevatedButton.icon(
                      onPressed: _calcularCalibragem,
                      icon: const Icon(Icons.calculate),
                      label: const Text('CALCULAR CALIBRAGEM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF228B22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    // Resultado do cálculo
                    if (_calculoRealizado) ...[                      
                      const SizedBox(height: 16),
                      _buildResultCard(),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Botão salvar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvarCalibragem,
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
                              'SALVAR CALIBRAGEM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Componentes da UI

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF36963E)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF36963E),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selecionarData(),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Data da Calibragem',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(_dataRegulagem),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Parâmetros para cálculo tradicional
  Widget _buildStandardParameters() {
    return _buildCard(
      title: 'Coleta de Sementes',
      icon: Icons.grass,
      children: [
        TextFormField(
          controller: _sementesColetadasController,
          decoration: const InputDecoration(
            labelText: 'Quantidade de sementes coletadas*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grain),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe a quantidade de sementes';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _linhasColetadasController,
          decoration: const InputDecoration(
            labelText: 'Número de linhas coletadas',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.view_week),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
  
  // Parâmetros para cálculo por disco
  Widget _buildDiscParameters() {
    return _buildCard(
      title: 'Disco e Engrenagens',
      icon: Icons.settings,
      children: [
        TextFormField(
          controller: _numeroFurosController,
          decoration: const InputDecoration(
            labelText: 'Número de furos no disco*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.circle),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe o número de furos';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _engrenagemMotoraController,
                decoration: const InputDecoration(
                  labelText: 'Engrenagem motora (dentes)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_input_component),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe os dentes';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _engrenagemMovidaController,
                decoration: const InputDecoration(
                  labelText: 'Engrenagem movida (dentes)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_input_component),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe os dentes';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _numeroLinhasPlantadeiraController,
          decoration: const InputDecoration(
            labelText: 'Número de linhas da plantadeira*',
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
      ],
    );
  }

  // Parâmetros comuns para ambos os modos de cálculo
  Widget _buildCommonParameters() {
    return _buildCard(
      title: 'Parâmetros de Plantio',
      icon: Icons.eco,
      children: [
        // Campo de seleção de talhão
        TextFormField(
          controller: _talhaoController,
          decoration: const InputDecoration(
            labelText: 'Talhão*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.crop_square),
            hintText: 'Selecione um talhão',
          ),
          readOnly: true,
          onTap: $1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecione um talhão';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Campo de seleção de cultura
        TextFormField(
          controller: _culturaController,
          decoration: const InputDecoration(
            labelText: 'Cultura*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grass),
            hintText: 'Selecione uma cultura',
          ),
          readOnly: true,
          onTap: $1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecione uma cultura';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _espacamentoController,
          decoration: const InputDecoration(
            labelText: 'Espaçamento entre linhas (cm)*',
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
          controller: _populacaoDesejadaController,
          decoration: const InputDecoration(
            labelText: 'População desejada (mil plantas/ha)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people),
            hintText: 'Opcional',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // Card para resultados
  Widget _buildResultCard() {
    return _buildCard(
      title: 'Resultado da Calibragem',
      icon: Icons.check_circle,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              _buildResultRow(
                label: 'Sementes por metro:',
                value: '${_resultados['sementesPorMetro']?.toStringAsFixed(1) ?? "0.0"} sementes/m',
              ),
              const Divider(),
              _buildResultRow(
                label: 'Plantas por metro:',
                value: '${_resultados['plantasPorMetro']?.toStringAsFixed(1) ?? "0.0"} plantas/m',
              ),
              const Divider(),
              _buildResultRow(
                label: 'Plantas por hectare:',
                value: '${((_resultados['plantasPorHectare'] ?? 0.0) / 1000).toStringAsFixed(1)} mil plantas/ha',
              ),
              const Divider(),
              _buildResultRow(
                label: 'Plantas por m²:',
                value: '${_resultados['plantasPorMetroQuadrado']?.toStringAsFixed(2) ?? "0.00"} plantas/m²',
              ),
              
              if (_populacaoDesejadaController.text.isNotEmpty) ...[                
                const Divider(),
                _buildResultRow(
                  label: 'Diferença da meta:',
                  value: '${_resultados['erroPorcentagem']?.toStringAsFixed(1) ?? "0.0"}%',
                  isError: (_resultados['erroPorcentagem'] ?? 0.0).abs() > 5.0,
                ),
                const SizedBox(height: 8),
                Text(
                  _getSugestaoAjuste(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: (_resultados['erroPorcentagem'] ?? 0.0).abs() > 5.0
                        ? Colors.orange[800]
                        : Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Linha de resultado formatada
  Widget _buildResultRow({required String label, required String value, bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.red[700] : const Color(0xFF36963E),
          ),
        ),
      ],
    );
  }

  // Função auxiliar para retornar uma sugestão de ajuste
  String _getSugestaoAjuste() {
    final erro = _resultados['erroPorcentagem'] ?? 0.0;
    
    if (erro.abs() <= 5.0) {
      return 'Calibragem adequada, dentro da tolerância de ±5%.';
    } else if (erro > 5.0) {
      return _usaDiscoEngrenagens
          ? 'Reduzir população. Sugestão: diminuir engrenagem motora ou aumentar a movida.'
          : 'Reduzir população. Sementes por metro acima da meta.';
    } else {
      return _usaDiscoEngrenagens
          ? 'Aumentar população. Sugestão: aumentar engrenagem motora ou reduzir a movida.'
          : 'Aumentar população. Sementes por metro abaixo da meta.';
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
  
}

