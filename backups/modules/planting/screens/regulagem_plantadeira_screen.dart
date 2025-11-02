import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/regulagem_plantadeira_model.dart';
import '../services/regulagem_plantadeira_service.dart';

class RegulagemPlantadeiraScreen extends StatefulWidget {
  final int? regulagemId;

  const RegulagemPlantadeiraScreen({Key? key, this.regulagemId}) : super(key: key);

  @override
  _RegulagemPlantadeiraScreenState createState() => _RegulagemPlantadeiraScreenState();
}

class _RegulagemPlantadeiraScreenState extends State<RegulagemPlantadeiraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regulagemService = RegulagemPlantadeiraService();
  
  // Controladores
  final _nomeController = TextEditingController();
  final _numFurosDiscoController = TextEditingController();
  final _engrenagemMotoraController = TextEditingController();
  final _engrenagemMovidaController = TextEditingController();
  final _distanciaPercorridaController = TextEditingController();
  final _numLinhasController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Variáveis de estado
  DateTime _dataRegulagem = DateTime.now();
  bool _isLoading = false;
  bool _calculoRealizado = false;
  bool _isEditing = false;
  
  // Resultados do cálculo
  double _sementesPorMetro = 0.0;
  double _populacaoEstimada = 0.0;
  double _relacaoTransmissao = 0.0;
  String _ajusteSugerido = '';


  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    if (widget.regulagemId != null) {
      setState(() => _isLoading = true);
      try {
        final regulagem = await _regulagemService.getRegulagemById(widget.regulagemId!);
        if (regulagem != null) {
          setState(() {
            _isEditing = true;
            _nomeController.text = regulagem.nome;
            _numFurosDiscoController.text = regulagem.numFurosDisco.toString();
            _engrenagemMotoraController.text = regulagem.engrenagemMotora.toString();
            _engrenagemMovidaController.text = regulagem.engrenagemMovida.toString();
            _distanciaPercorridaController.text = regulagem.distanciaPercorrida.toString();
            _numLinhasController.text = regulagem.numLinhas?.toString() ?? '';
            _sementesPorMetro = regulagem.sementePorMetro;
            _populacaoEstimada = regulagem.populacaoEstimada;
            _relacaoTransmissao = regulagem.relacaoTransmissao;
            _ajusteSugerido = regulagem.ajusteSugerido ?? '';
            _calculoRealizado = true;
            _dataRegulagem = regulagem.dataRegulagem;
            _observacoesController.text = regulagem.observacoes ?? '';
          });
        }
      } catch (e) {
        _mostrarErro('Erro ao carregar dados: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Removido métodos de carregamento de cultura e variedade
  
  void _calcularRegulagem() {
    if (!_validarCamposCalculo()) return;
    
    final numFurosDisco = int.tryParse(_numFurosDiscoController.text) ?? 0;
    final engrenagemMotora = int.tryParse(_engrenagemMotoraController.text) ?? 0;
    final engrenagemMovida = int.tryParse(_engrenagemMovidaController.text) ?? 0;
    final distanciaPercorrida = double.tryParse(_distanciaPercorridaController.text) ?? 0.0;
    
    // Calcular relação de transmissão
    final relacaoTransmissao = engrenagemMotora > 0 && engrenagemMovida > 0 
        ? engrenagemMovida / engrenagemMotora 
        : 0.0;
    
    // Calcular sementes por metro linear
    final sementesPorMetro = distanciaPercorrida > 0 && numFurosDisco > 0 
        ? numFurosDisco * relacaoTransmissao / distanciaPercorrida 
        : 0.0;
    
    // Calcular população estimada por hectare
    double populacaoEstimada = 0.0;
    final numLinhas = int.tryParse(_numLinhasController.text) ?? 1;
    if (numLinhas > 0) {
      // Considerando espaçamento padrão de 0.5m se não informado
      final espacamento = 0.5;
      populacaoEstimada = sementesPorMetro * 10000 / espacamento;
    }
    
    // Definir ajuste sugerido
    String ajusteSugerido = '';
    if (sementesPorMetro < 5) {
      ajusteSugerido = 'Aumentar a relação de transmissão';
    } else if (sementesPorMetro > 15) {
      ajusteSugerido = 'Diminuir a relação de transmissão';
    } else {
      ajusteSugerido = 'Regulagem adequada';
    }
    
    setState(() {
      _sementesPorMetro = sementesPorMetro;
      _populacaoEstimada = populacaoEstimada;
      _relacaoTransmissao = relacaoTransmissao;
      _ajusteSugerido = ajusteSugerido;
      _calculoRealizado = true;
    });
    
    _mostrarSucesso('Cálculo realizado com sucesso!');
  }
  
  bool _validarCamposCalculo() {
    if (_nomeController.text.isEmpty) {
      _mostrarErro('Informe o nome da calibragem');
      return false;
    }
    
    if (_numFurosDiscoController.text.isEmpty) {
      _mostrarErro('Informe o número de furos do disco');
      return false;
    }
    
    if (_engrenagemMotoraController.text.isEmpty) {
      _mostrarErro('Informe a engrenagem motora');
      return false;
    }
    
    if (_engrenagemMovidaController.text.isEmpty) {
      _mostrarErro('Informe a engrenagem movida');
      return false;
    }
    
    if (_distanciaPercorridaController.text.isEmpty) {
      _mostrarErro('Informe a distância percorrida');
      return false;
    }
    
    return true;
  }
  
  Future<void> _salvarRegulagem() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_calculoRealizado) {
      _mostrarErro('Realize o cálculo da regulagem antes de salvar');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final regulagem = RegulagemPlantadeiraModel(
        id: widget.regulagemId,
        nome: _nomeController.text.trim(),
        numFurosDisco: int.tryParse(_numFurosDiscoController.text) ?? 0,
        engrenagemMotora: int.tryParse(_engrenagemMotoraController.text) ?? 0,
        engrenagemMovida: int.tryParse(_engrenagemMovidaController.text) ?? 0,
        distanciaPercorrida: double.tryParse(_distanciaPercorridaController.text) ?? 0.0,
        numLinhas: _numLinhasController.text.isNotEmpty ? 
            int.tryParse(_numLinhasController.text) : null,
        sementePorMetro: _sementesPorMetro,
        populacaoEstimada: _populacaoEstimada,
        relacaoTransmissao: _relacaoTransmissao,
        ajusteSugerido: _ajusteSugerido,
        observacoes: _observacoesController.text,
        dataRegulagem: _dataRegulagem,
      );
      
      await _regulagemService.saveRegulagemPlantadeira(regulagem);
      
      _mostrarSucesso('Regulagem salva com sucesso!');
      
      // Volta para a tela anterior após salvar
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro('Erro ao salvar regulagem: $e');
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
              primary: Color(0xFF228B22),
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
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: Text(_isEditing ? 'Editar Calibragem' : 'Calibragem de Plantadeira'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCard(
                      title: 'Informações da Calibragem',
                      icon: Icons.settings,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Calibragem',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o nome da calibragem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          label: 'Data da Calibragem',
                          value: _dataRegulagem,
                          onTap: () => _selecionarData(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Parâmetros da Plantadeira',
                      icon: Icons.precision_manufacturing,
                      children: [
                        TextFormField(
                          controller: _numFurosDiscoController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Furos do Disco',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.circle_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o número de furos do disco';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _engrenagemMotoraController,
                          decoration: const InputDecoration(
                            labelText: 'Engrenagem Motora',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.settings),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a engrenagem motora';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _engrenagemMovidaController,
                          decoration: const InputDecoration(
                            labelText: 'Engrenagem Movida',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.settings_applications),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a engrenagem movida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _distanciaPercorridaController,
                          decoration: const InputDecoration(
                            labelText: 'Distância Percorrida (metros)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a distância percorrida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _numLinhasController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Linhas (opcional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.view_week),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _calcularRegulagem,
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
                    if (_calculoRealizado) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Resultado da Regulagem',
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Sementes por Metro:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_sementesPorMetro.toStringAsFixed(1)} sementes/m',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF228B22),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Relação de Transmissão:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_relacaoTransmissao.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF228B22),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'População Estimada: ${_populacaoEstimada.toStringAsFixed(0)} sementes/ha',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
                      onPressed: _isLoading ? null : _salvarRegulagem,
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
                              'SALVAR REGULAGEM',
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
  
  // Método removido: _buildDropdownField
  
  Widget _buildDateField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    final formatter = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(formatter.format(value)),
      ),
    );
  }
  
  // Nenhum método de seleção de dados é necessário na nova implementação
  
  @override
  void dispose() {
    _nomeController.dispose();
    _numFurosDiscoController.dispose();
    _engrenagemMotoraController.dispose();
    _engrenagemMovidaController.dispose();
    _distanciaPercorridaController.dispose();
    _numLinhasController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
