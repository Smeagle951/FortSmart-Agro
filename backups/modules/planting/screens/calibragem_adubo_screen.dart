import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calibragem_adubo_model.dart';
import '../services/calibragem_adubo_service.dart';
import '../../../models/machine.dart';
import '../../../services/data_cache_service.dart';

class CalibragemAduboScreen extends StatefulWidget {
  final int? calibragemId;

  const CalibragemAduboScreen({super.key, this.calibragemId});

  @override
  State<CalibragemAduboScreen> createState() => _CalibragemAduboScreenState();
}

class _CalibragemAduboScreenState extends State<CalibragemAduboScreen> {
  // Serviços
  final CalibragemAduboService _calibragemService = CalibragemAduboService();
  final DataCacheService _dataCache = DataCacheService();
  
  // Controllers
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _equipamentoController = TextEditingController();
  final TextEditingController _roscaDosadoraController = TextEditingController();
  final TextEditingController _variedadeAduboController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _pesoColetadoController = TextEditingController();
  final TextEditingController _distanciaPercorridaController = TextEditingController();
  final TextEditingController _quantidadeDesejadaController = TextEditingController();
  final TextEditingController _engrenagemMotoraController = TextEditingController();
  final TextEditingController _engrenagemMovidaController = TextEditingController();
  
  // Estados
  final _formKey = GlobalKey<FormState>();
  DateTime _dataRegulagem = DateTime.now();
  bool _calculoRealizado = false;
  bool _isLoading = false;
  Map<String, dynamic> _resultados = {};
  
  // Equipamentos
  String? _equipamentoId;
  List<Machine> _equipamentos = [];
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  @override
  void dispose() {
    _nomeController.dispose();
    _equipamentoController.dispose();
    _roscaDosadoraController.dispose();
    _variedadeAduboController.dispose();
    _marcaController.dispose();
    _pesoColetadoController.dispose();
    _distanciaPercorridaController.dispose();
    _quantidadeDesejadaController.dispose();
    _engrenagemMotoraController.dispose();
    _engrenagemMovidaController.dispose();
    super.dispose();
  }

  // Método para carregar dados iniciais
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      await _carregarEquipamentos();
      
      if (widget.calibragemId != null) {
        await _carregarCalibragemExistente();
      } else {
        // Valores padrão para nova calibragem
        _engrenagemMotoraController.text = '15';
        _engrenagemMovidaController.text = '20';
        _roscaDosadoraController.text = 'Passo 1';
        _dataRegulagem = DateTime.now();
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _carregarEquipamentos() async {
    try {
      _equipamentos = await _dataCache.getMachines();
    } catch (e) {
      _mostrarErro('Erro ao carregar equipamentos: $e');
      _equipamentos = [];
    }
  }
  
  Future<void> _carregarCalibragemExistente() async {
    try {
      final calibragem = await _calibragemService.buscarPorId(widget.calibragemId!);
      if (calibragem != null) {
        _nomeController.text = calibragem.nome ?? '';
        _pesoColetadoController.text = calibragem.pesoColetado?.toString() ?? '';
        _distanciaPercorridaController.text = calibragem.distanciaPercorrida?.toString() ?? '';
        _quantidadeDesejadaController.text = calibragem.quantidadeDesejada?.toString() ?? '';
        _engrenagemMotoraController.text = calibragem.engrenagemMotora?.toString() ?? '';
        _engrenagemMovidaController.text = calibragem.engrenagemMovida?.toString() ?? '';
        _roscaDosadoraController.text = calibragem.roscaDosadora ?? '';
        _variedadeAduboController.text = calibragem.variedadeAdubo ?? '';
        _marcaController.text = calibragem.marca ?? '';
        _dataRegulagem = calibragem.dataRegulagem ?? DateTime.now();
        
        if (calibragem.equipamentoId != null) {
          _equipamentoId = calibragem.equipamentoId;
          await _carregarNomeEquipamento();
        }
        
        // Carregar resultados se já calculados
        if (calibragem.kgPorHa != null && calibragem.kgPorHa! > 0) {
          _calculoRealizado = true;
          _resultados = {
            'gramasAplicadas': calibragem.gramasAplicadas ?? 0,
            'kgPorHa': calibragem.kgPorHa ?? 0,
            'sacasPorHa': calibragem.sacasPorHa ?? 0,
            'erroPorcentagem': calibragem.erroPorcentagem ?? 0,
            'sugestaoAjuste': calibragem.sugestaoAjuste ?? '',
            'relacaoTransmissao': calibragem.relacaoTransmissao ?? 0,
          };
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar calibragem: $e');
    }
  }
  
  Future<void> _carregarNomeEquipamento() async {
    if (_equipamentoId == null) return;
    
    try {
      final equipamento = _equipamentos.firstWhere(
        (e) => e.id.toString() == _equipamentoId,
        orElse: () => throw Exception('Equipamento não encontrado'),
      );
      
      setState(() {
        _equipamentoController.text = equipamento.name;
      });
    } catch (e) {
      // Equipamento não encontrado, limpar seleção
      setState(() {
        _equipamentoId = null;
        _equipamentoController.text = '';
      });
    }
  }
  
  Future<void> _selecionarEquipamento() async {
    if (_equipamentos.isEmpty) {
      await _carregarEquipamentos();
    }
    
    if (_equipamentos.isEmpty) {
      _mostrarErro('Nenhum equipamento disponível');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selecione um Equipamento'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _equipamentos.length,
            itemBuilder: (context, index) {
              final equipamento = _equipamentos[index];
              return ListTile(
                title: Text(equipamento.name),
                subtitle: Text(equipamento.brand ?? ''),
                // onTap: () {
                  setState(() {
                    _equipamentoId = equipamento.id.toString();
                    _equipamentoController.text = equipamento.name;
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
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  // Método para selecionar data
  Future<void> _selecionarData() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataRegulagem,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD65A00),
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataRegulagem = dataSelecionada;
      });
    }
  }
  
  // Método para realizar os cálculos
  void _calcular() {
    if (!_formKey.currentState!.validate()) {
      _mostrarErro('Preencha todos os campos obrigatórios');
      return;
    }
    
    try {
      // Obter valores dos campos
      final double pesoColetado = double.parse(_pesoColetadoController.text);
      final double distanciaPercorrida = double.parse(_distanciaPercorridaController.text);
      final double quantidadeDesejada = double.parse(_quantidadeDesejadaController.text);
      final int engrenagemMotora = int.parse(_engrenagemMotoraController.text);
      final int engrenagemMovida = int.parse(_engrenagemMovidaController.text);
      
      // Cálculo da relação de transmissão
      final double relacaoTransmissao = engrenagemMotora / engrenagemMovida;
      
      // Cálculo da dosagem por metro e conversão para kg/ha
      final double dosagemPorMetro = (pesoColetado / distanciaPercorrida) * 10000;
      final double kgPorHa = dosagemPorMetro / 1000; // Converter gramas para kg
      
      // Cálculo em sacas/ha (considerando 50kg por saca)
      final double sacasPorHa = kgPorHa / 50;
      
      // Cálculo do erro em relação ao desejado
      final double erroPorcentagem = ((kgPorHa - quantidadeDesejada) / quantidadeDesejada) * 100;
      
      // Sugestão de ajuste baseada no erro
      String sugestaoAjuste = '';
      if (erroPorcentagem.abs() > 5) {
        if (erroPorcentagem > 0) {
          sugestaoAjuste = 'Reduzir abertura do dosador ou aumentar velocidade';
        } else {
          sugestaoAjuste = 'Aumentar abertura do dosador ou reduzir velocidade';
        }
      } else {
        sugestaoAjuste = 'Calibragem dentro da tolerância aceitável';
      }
      
      // Gramas aplicadas no percurso
      final double gramasAplicadas = pesoColetado;
      
      // Atualizar resultados
      setState(() {
        _calculoRealizado = true;
        _resultados = {
          'gramasAplicadas': gramasAplicadas,
          'kgPorHa': kgPorHa,
          'sacasPorHa': sacasPorHa,
          'erroPorcentagem': erroPorcentagem,
          'sugestaoAjuste': sugestaoAjuste,
          'relacaoTransmissao': relacaoTransmissao,
        };
      });
      
      _mostrarSucesso('Calibragem calculada com sucesso!');
      
    } catch (e) {
      _mostrarErro('Erro ao calcular: ${e.toString()}');
    }
  }
  
  // Método para salvar a calibragem
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      _mostrarErro('Preencha todos os campos obrigatórios');
      return;
    }
    
    if (!_calculoRealizado) {
      _mostrarErro('Realize a calibragem antes de salvar');
      return;
    }
    
    if (_equipamentoId == null || _equipamentoController.text.isEmpty) {
      _mostrarErro('Selecione um equipamento antes de salvar');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final calibragem = CalibragemAduboModel(
        id: widget.calibragemId,
        nome: _nomeController.text.trim(),
        dataRegulagem: _dataRegulagem,
        equipamentoId: _equipamentoId,
        roscaDosadora: _roscaDosadoraController.text.trim(),
        variedadeAdubo: _variedadeAduboController.text.trim(),
        marca: _marcaController.text.trim(),
        pesoColetado: double.tryParse(_pesoColetadoController.text) ?? 0.0,
        distanciaPercorrida: double.tryParse(_distanciaPercorridaController.text) ?? 0.0,
        quantidadeDesejada: double.tryParse(_quantidadeDesejadaController.text) ?? 0.0,
        engrenagemMotora: int.tryParse(_engrenagemMotoraController.text) ?? 0,
        engrenagemMovida: int.tryParse(_engrenagemMovidaController.text) ?? 0,
        gramasAplicadas: _resultados['gramasAplicadas'] as double? ?? 0.0,
        kgPorHa: _resultados['kgPorHa'] as double? ?? 0.0,
        sacasPorHa: _resultados['sacasPorHa'] as double? ?? 0.0,
        erroPorcentagem: _resultados['erroPorcentagem'] as double? ?? 0.0,
        sugestaoAjuste: _resultados['sugestaoAjuste'] as String? ?? '',
        relacaoTransmissao: _resultados['relacaoTransmissao'] as double? ?? 0.0,
      );
      
      await _calibragemService.saveCalibragemAdubo(calibragem);
      
      _mostrarSucesso(widget.calibragemId != null 
          ? 'Calibragem atualizada com sucesso!' 
          : 'Calibragem salva com sucesso!');
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
      
    } catch (e) {
      debugPrint('Erro ao criar CalibragemAduboModel: $e');
      _mostrarErro('Erro ao salvar calibragem. Verifique os dados e tente novamente.');
      
      // Verificar tipos específicos de erro para mensagens mais detalhadas
      if (e.toString().contains('parse')) {
        _mostrarErro('Erro nos valores informados. Verifique se todos os campos numéricos estão preenchidos corretamente.');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        _mostrarErro('Erro de conexão. Verifique sua internet e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Métodos de feedback
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

  // Método para construir cards da interface
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
                Icon(icon, color: const Color(0xFFD65A00)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD65A00),
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

  // Método para construir o campo de data
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

  // Método para construir linhas de resultado
  Widget _buildResultRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? const Color(0xFFD65A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFFD65A00),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calibragemId == null ? 'Nova Calibragem' : 'Editar Calibragem'),
        backgroundColor: const Color(0xFF228B22),
        foregroundColor: Colors.white,
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
                  // Identificação da calibragem
                  _buildCard(
                    title: 'Identificação',
                    icon: Icons.description,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Calibragem*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe um nome para a calibragem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Equipamento e configurações
                  _buildCard(
                    title: 'Equipamento e Configurações',
                    icon: Icons.precision_manufacturing,
                    children: [
                      // Seleção de equipamento
                      InkWell(
                        onTap: () => _selecionarEquipamento(),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Equipamento*',
                            hintText: 'Selecione um equipamento',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.agriculture),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _equipamentoController.text.isEmpty ? 'Selecione um equipamento' : _equipamentoController.text,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Rosca dosadora
                      DropdownButtonFormField<String>(
                        value: _roscaDosadoraController.text.isEmpty ? null : _roscaDosadoraController.text,
                        decoration: const InputDecoration(
                          labelText: 'Rosca Dosadora*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.settings),
                        ),
                        items: ['Passo 1', 'Passo 2'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _roscaDosadoraController.text = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione a rosca dosadora';
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
                                labelText: 'Engrenagem Motora*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.settings_input_component),
                                hintText: 'Ex: 15',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a engrenagem motora';
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
                                labelText: 'Engrenagem Movida*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.settings_input_component),
                                hintText: 'Ex: 20',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a engrenagem movida';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dados do adubo
                  _buildCard(
                    title: 'Dados do Adubo',
                    icon: Icons.scatter_plot,
                    children: [
                      TextFormField(
                        controller: _variedadeAduboController,
                        decoration: const InputDecoration(
                          labelText: 'Variedade do Adubo*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          hintText: 'Ex: NPK 20-05-20',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a variedade do adubo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _marcaController,
                        decoration: const InputDecoration(
                          labelText: 'Marca*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.branding_watermark),
                          hintText: 'Ex: Yara, Mosaic',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a marca do adubo';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Parâmetros da calibragem
                  _buildCard(
                    title: 'Parâmetros da Calibragem',
                    icon: Icons.tune,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pesoColetadoController,
                              decoration: const InputDecoration(
                                labelText: 'Peso Coletado (g)*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.scale),
                                hintText: 'Ex: 250',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o peso coletado';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _distanciaPercorridaController,
                              decoration: const InputDecoration(
                                labelText: 'Distância (m)*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.straighten),
                                hintText: 'Ex: 50',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a distância';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantidadeDesejadaController,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade Desejada (kg/ha)*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.track_changes),
                          hintText: 'Ex: 250',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a quantidade desejada';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  // Resultados (exibidos apenas quando calculados)
                  if (_calculoRealizado)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'Resultados da Calibragem',
                          icon: Icons.analytics,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _buildResultRow(
                                    'Gramas aplicadas no percurso',
                                    '${_resultados['gramasAplicadas']?.toStringAsFixed(1)} g',
                                    Icons.scale,
                                  ),
                                  _buildResultRow(
                                    'Estimativa atual',
                                    '${_resultados['kgPorHa']?.toStringAsFixed(1)} kg/ha',
                                    Icons.trending_up,
                                  ),
                                  _buildResultRow(
                                    'Estimativa em sacas',
                                    '${_resultados['sacasPorHa']?.toStringAsFixed(2)} sacas/ha',
                                    Icons.inventory_2,
                                  ),
                                  _buildResultRow(
                                    'Comparativo com objetivo',
                                    '${_resultados['erroPorcentagem']?.toStringAsFixed(1)}%',
                                    (_resultados['erroPorcentagem'] ?? 0).abs() > 5 ? Icons.error : Icons.check_circle,
                                    color: (_resultados['erroPorcentagem'] ?? 0).abs() > 5 ? Colors.red : Colors.green,
                                  ),
                                  _buildResultRow(
                                    'Relação de transmissão',
                                    '${_resultados['relacaoTransmissao']?.toStringAsFixed(2)}',
                                    Icons.settings,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_resultados['erroPorcentagem']?.abs() ?? 0) > 5 
                                    ? Colors.orange.shade50 
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (_resultados['erroPorcentagem']?.abs() ?? 0) > 5 
                                      ? Colors.orange 
                                      : Colors.green,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    (_resultados['erroPorcentagem']?.abs() ?? 0) > 5 
                                        ? Icons.warning 
                                        : Icons.check_circle,
                                    color: (_resultados['erroPorcentagem']?.abs() ?? 0) > 5 
                                        ? Colors.orange 
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sugestão: ${_resultados['sugestaoAjuste']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: (_resultados['erroPorcentagem']?.abs() ?? 0) > 5 
                                            ? Colors.orange.shade800                                             : Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _calcular,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Calcular'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF228B22),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _calculoRealizado ? _salvar : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _calculoRealizado ? const Color(0xFF228B22) : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}