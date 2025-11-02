import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/perda_colheita_model.dart';
import '../services/perda_colheita_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PerdaColheitaScreen extends StatefulWidget {
  final int? perdaId;

  const PerdaColheitaScreen({Key? key, this.perdaId}) : super(key: key);

  @override
  State<PerdaColheitaScreen> createState() => _PerdaColheitaScreenState();
}

class _PerdaColheitaScreenState extends State<PerdaColheitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PerdaColheitaService();
  
  final _talhaoController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _dataPerdaController = TextEditingController();
  final _espigasController = TextEditingController();
  final _graosPerdidosController = TextEditingController();
  final _pesoMilGraosController = TextEditingController();
  final _pesoColetadoController = TextEditingController();
  final _areaAmostradaController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  int? _talhaoId;
  int? _culturaId;
  int? _variedadeId;
  int? _perdaId;
  String _metodoSelecionado = 'peso_mil_graos'; // Default método
  List<String> _fotos = [];
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  
  double _resultadoPerdaKgHa = 0.0;
  double _resultadoPerdaScHa = 0.0;
  
  @override
  void initState() {
    super.initState();
    _carregarPerda();
  }
  
  Future<void> _carregarPerda() async {
    if (widget.perdaId != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final perda = await _service.getPerdaColheitaById(widget.perdaId!);
        if (perda != null) {
          _perdaId = perda.id;
          _talhaoId = perda.talhaoId;
          _culturaId = perda.culturaId;
          _variedadeId = perda.variedadeId;
          
          // TODO: Carregar nomes reais dos talhões, culturas e variedades do banco
          _talhaoController.text = 'Talhão #${perda.talhaoId}';
          _culturaController.text = 'Cultura #${perda.culturaId}';
          _variedadeController.text = 'Variedade #${perda.variedadeId}';
          
          _dataPerdaController.text = perda.dataPerda;
          _metodoSelecionado = perda.metodo;
          
          if (perda.metodo == 'peso_mil_graos') {
            _espigasController.text = perda.espigas.toString();
            _graosPerdidosController.text = perda.graosPerdidos.toString();
            _pesoMilGraosController.text = perda.pesoMilGraos.toString();
          } else {
            _pesoColetadoController.text = perda.pesoColetado.toString();
          }
          
          _areaAmostradaController.text = perda.areaAmostrada.toString();
          _resultadoPerdaKgHa = perda.resultadoPerdaKgHa;
          _resultadoPerdaScHa = perda.resultadoPerdaScHa;
          _observacoesController.text = perda.observacoes;
          
          if (perda.fotos.isNotEmpty) {
            _fotos = perda.fotos.split(',');
          }
        }
      } catch (e) {
        _mostrarErro('Erro ao carregar perda: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _calcularPerda() {
    if (_metodoSelecionado == 'peso_mil_graos') {
      if (_espigasController.text.isEmpty || 
          _graosPerdidosController.text.isEmpty || 
          _pesoMilGraosController.text.isEmpty || 
          _areaAmostradaController.text.isEmpty) {
        _mostrarErro('Preencha todos os campos para calcular a perda');
        return Future.value();
      }
      
      final espigas = int.parse(_espigasController.text);
      final graosPerdidos = int.parse(_graosPerdidosController.text);
      final pesoMilGraos = double.parse(_pesoMilGraosController.text);
      final areaAmostrada = double.parse(_areaAmostradaController.text);
      
      setState(() {
        _resultadoPerdaKgHa = _service.calcularPerdaMilGraos(
          espigas, graosPerdidos, pesoMilGraos, areaAmostrada);
        _resultadoPerdaScHa = _service.converterKgParaSacas(_resultadoPerdaKgHa);
      });
    } else {
      if (_pesoColetadoController.text.isEmpty || 
          _areaAmostradaController.text.isEmpty) {
        _mostrarErro('Preencha todos os campos para calcular a perda');
        return Future.value();
      }
      
      final pesoColetado = double.parse(_pesoColetadoController.text);
      final areaAmostrada = double.parse(_areaAmostradaController.text);
      
      setState(() {
        _resultadoPerdaKgHa = _service.calcularPerdaPesoTotal(
          pesoColetado, areaAmostrada);
        _resultadoPerdaScHa = _service.converterKgParaSacas(_resultadoPerdaKgHa);
      });
    }
    
    return Future.value();
  }
  
  Future<void> _salvarPerda() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Garantir que temos IDs válidos
        if (_talhaoId == null || _culturaId == null || _variedadeId == null) {
          // Por enquanto, apenas para testes, usaremos valores fictícios
          _talhaoId ??= 1;
          _culturaId ??= 1;
          _variedadeId ??= 1;
        }
        
        // Calcular perdas novamente para garantir valores atualizados
        await _calcularPerda();
        
        final perda = PerdaColheitaModel(
          id: _perdaId,
          talhaoId: _talhaoId!,
          culturaId: _culturaId!,
          variedadeId: _variedadeId!,
          dataPerda: _dataPerdaController.text,
          metodo: _metodoSelecionado,
          espigas: _metodoSelecionado == 'peso_mil_graos' ? int.parse(_espigasController.text) : null,
          graosPerdidos: _metodoSelecionado == 'peso_mil_graos' ? int.parse(_graosPerdidosController.text) : null,
          pesoMilGraos: _metodoSelecionado == 'peso_mil_graos' ? double.parse(_pesoMilGraosController.text) : null,
          pesoColetado: _metodoSelecionado == 'peso_total' ? double.parse(_pesoColetadoController.text) : null,
          areaAmostrada: double.parse(_areaAmostradaController.text),
          resultadoPerdaKgHa: _resultadoPerdaKgHa,
          resultadoPerdaScHa: _resultadoPerdaScHa,
          observacoes: _observacoesController.text,
          fotos: _fotos.join(','),
        );
        
        await _service.savePerdaColheita(perda);
        _mostrarSucesso('Perda de colheita salva com sucesso!');
        
        // Retornar para a tela anterior
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        _mostrarErro('Erro ao salvar perda de colheita: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _selecionarData() async {
    final dataAtual = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataPerdaController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dataPerdaController.text)
          : dataAtual,
      firstDate: DateTime(dataAtual.year - 5),
      lastDate: dataAtual,
    );
    
    if (data != null) {
      setState(() {
        _dataPerdaController.text = DateFormat('yyyy-MM-dd').format(data);
      });
    }
  }
  
  Future<void> _selecionarTalhao() async {
    // TODO: Implementar seleção de talhão do banco de dados
    setState(() {
      _talhaoId = 1; // Temporário
      _talhaoController.text = 'Talhão #1';
    });
  }
  
  Future<void> _selecionarCultura() async {
    // TODO: Implementar seleção de cultura do banco de dados
    setState(() {
      _culturaId = 1; // Temporário
      _culturaController.text = 'Milho';
    });
  }
  
  Future<void> _selecionarVariedade() async {
    // TODO: Implementar seleção de variedade do banco de dados
    setState(() {
      _variedadeId = 1; // Temporário
      _variedadeController.text = 'Híbrido X';
    });
  }
  
  Future<void> _tirarFoto() async {
    final XFile? imagem = await _imagePicker.pickImage(source: ImageSource.camera);
    if (imagem != null) {
      setState(() {
        _fotos.add(imagem.path);
      });
    }
  }
  
  Future<void> _selecionarImagem() async {
    final XFile? imagem = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _fotos.add(imagem.path);
      });
    }
  }
  
  void _removerFoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_perdaId == null ? 'Novo Cálculo de Perda' : 'Editar Cálculo de Perda'),
        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
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
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informações Básicas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Talhão
                            TextFormField(
                              controller: _talhaoController,
                              decoration: InputDecoration(
                                labelText: 'Talhão',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _selecionarTalhao,
                                ),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione um talhão';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Cultura
                            TextFormField(
                              controller: _culturaController,
                              decoration: InputDecoration(
                                labelText: 'Cultura',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _selecionarCultura,
                                ),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione uma cultura';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Variedade
                            TextFormField(
                              controller: _variedadeController,
                              decoration: InputDecoration(
                                labelText: 'Variedade',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _selecionarVariedade,
                                ),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione uma variedade';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Data da perda
                            TextFormField(
                              controller: _dataPerdaController,
                              decoration: InputDecoration(
                                labelText: 'Data da Avaliação',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: _selecionarData,
                                ),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione a data da avaliação';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Método de Cálculo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Seleção do método
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Peso de Mil Grãos'),
                                    value: 'peso_mil_graos',
                                    groupValue: _metodoSelecionado,
                                    onChanged: (value) {
                                      setState(() {
                                        _metodoSelecionado = value!;
                                      });
                                    },
                                    activeColor: const Color(0xFF228B22),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Peso Total'),
                                    value: 'peso_total',
                                    groupValue: _metodoSelecionado,
                                    onChanged: (value) {
                                      setState(() {
                                        _metodoSelecionado = value!;
                                      });
                                    },
                                    activeColor: const Color(0xFF228B22),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Campos específicos do método selecionado
                            if (_metodoSelecionado == 'peso_mil_graos') ...[  
                              TextFormField(
                                controller: _espigasController,
                                decoration: InputDecoration(
                                  labelText: 'Número de espigas coletadas',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_metodoSelecionado == 'peso_mil_graos' && (value == null || value.isEmpty)) {
                                    return 'Informe o número de espigas';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _graosPerdidosController,
                                decoration: InputDecoration(
                                  labelText: 'Grãos perdidos (contagem)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_metodoSelecionado == 'peso_mil_graos' && (value == null || value.isEmpty)) {
                                    return 'Informe o número de grãos perdidos';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _pesoMilGraosController,
                                decoration: InputDecoration(
                                  labelText: 'Peso de mil grãos (g)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_metodoSelecionado == 'peso_mil_graos' && (value == null || value.isEmpty)) {
                                    return 'Informe o peso de mil grãos';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[  // Método do peso total
                              TextFormField(
                                controller: _pesoColetadoController,
                                decoration: InputDecoration(
                                  labelText: 'Peso dos grãos coletados (g)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_metodoSelecionado == 'peso_total' && (value == null || value.isEmpty)) {
                                    return 'Informe o peso dos grãos coletados';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _areaAmostradaController,
                              decoration: InputDecoration(
                                labelText: 'Área amostrada (m²)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a área amostrada';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _calcularPerda,
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('CALCULAR PERDA'),
                            ),
                            const SizedBox(height: 16),
                            if (_resultadoPerdaKgHa > 0 || _resultadoPerdaScHa > 0)
                              Card(
                                color: Colors.grey[100],
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Resultado do Cálculo:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Perda: ${_resultadoPerdaKgHa.toStringAsFixed(2)} kg/ha'),
                                      Text('Perda: ${_resultadoPerdaScHa.toStringAsFixed(2)} sc/ha'),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Observações',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _observacoesController,
                              decoration: InputDecoration(
                                labelText: 'Observações',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fotos da Área',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _tirarFoto,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Tirar Foto'),
                                  style: ElevatedButton.styleFrom(
                                    // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _selecionarImagem,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Galeria'),
                                  style: ElevatedButton.styleFrom(
                                    // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_fotos.isNotEmpty)
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _fotos.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: FileImage(File(_fotos[index])),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 13,
                                          child: InkWell(
                                            // onTap: () => _removerFoto(index), // onTap não é suportado em Polygon no flutter_map 5.0.0
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvarPerda,
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SALVAR PERDA DE COLHEITA',
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
  
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  @override
  void dispose() {
    _talhaoController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _dataPerdaController.dispose();
    _espigasController.dispose();
    _graosPerdidosController.dispose();
    _pesoMilGraosController.dispose();
    _pesoColetadoController.dispose();
    _areaAmostradaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
