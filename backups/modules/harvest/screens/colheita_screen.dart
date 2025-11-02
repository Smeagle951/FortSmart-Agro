import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/colheita_model.dart';
import '../services/colheita_service.dart';
// import 'dart:convert'; // Não utilizado
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ColheitaScreen extends StatefulWidget {
  final int? colheitaId;

  const ColheitaScreen({Key? key, this.colheitaId}) : super(key: key);

  @override
  State<ColheitaScreen> createState() => _ColheitaScreenState();
}

class _ColheitaScreenState extends State<ColheitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ColheitaService();
  
  final _talhaoController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _dataColheitaController = TextEditingController();
  final _areaColhidaController = TextEditingController();
  final _produtividadeController = TextEditingController();
  final _umidadeController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  int? _talhaoId;
  int? _culturaId;
  int? _variedadeId;
  int? _colheitaId;
  List<String> _fotos = [];
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _carregarColheita();
  }
  
  Future<void> _carregarColheita() async {
    if (widget.colheitaId != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final colheita = await _service.getColheitaById(widget.colheitaId!);
        if (colheita != null) {
          _colheitaId = colheita.id;
          _talhaoId = colheita.talhaoId;
          _culturaId = colheita.culturaId;
          _variedadeId = colheita.variedadeId;
          
          // TODO: Carregar nomes reais dos talhões, culturas e variedades do banco
          _talhaoController.text = 'Talhão #${colheita.talhaoId}';
          _culturaController.text = 'Cultura #${colheita.culturaId}';
          _variedadeController.text = 'Variedade #${colheita.variedadeId}';
          
          _dataColheitaController.text = colheita.dataColheita;
          _areaColhidaController.text = colheita.areaColhida.toString();
          _produtividadeController.text = colheita.produtividade.toString();
          _umidadeController.text = colheita.umidade.toString();
          _observacoesController.text = colheita.observacoes;
          
          if (colheita.fotos.isNotEmpty) {
            _fotos = colheita.fotos.split(',');
          }
        }
      } catch (e) {
        _mostrarErro('Erro ao carregar colheita: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _salvarColheita() async {
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
        
        final colheita = ColheitaModel(
          id: _colheitaId,
          talhaoId: _talhaoId!,
          culturaId: _culturaId!,
          variedadeId: _variedadeId!,
          dataColheita: _dataColheitaController.text,
          areaColhida: double.parse(_areaColhidaController.text),
          produtividade: double.parse(_produtividadeController.text),
          umidade: double.parse(_umidadeController.text),
          observacoes: _observacoesController.text,
          fotos: _fotos.join(','),
        );
        
        await _service.saveColheita(colheita);
        _mostrarSucesso('Colheita salva com sucesso!');
        
        // Retornar para a tela anterior
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        _mostrarErro('Erro ao salvar colheita: $e');
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
      initialDate: _dataColheitaController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dataColheitaController.text)
          : dataAtual,
      firstDate: DateTime(dataAtual.year - 5),
      lastDate: dataAtual,
    );
    
    if (data != null) {
      setState(() {
        _dataColheitaController.text = DateFormat('yyyy-MM-dd').format(data);
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
        title: Text(_colheitaId == null ? 'Nova Colheita' : 'Editar Colheita'),
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
                              'Informações da Colheita',
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
                            // Data da colheita
                            TextFormField(
                              controller: _dataColheitaController,
                              decoration: InputDecoration(
                                labelText: 'Data da Colheita',
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
                                  return 'Selecione a data da colheita';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Área colhida
                            TextFormField(
                              controller: _areaColhidaController,
                              decoration: InputDecoration(
                                labelText: 'Área Colhida (ha)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a área colhida';
                                }
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return 'Informe um número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Produtividade
                            TextFormField(
                              controller: _produtividadeController,
                              decoration: InputDecoration(
                                labelText: 'Produtividade (sc/ha)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a produtividade';
                                }
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return 'Informe um número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Umidade
                            TextFormField(
                              controller: _umidadeController,
                              decoration: InputDecoration(
                                labelText: 'Umidade (%)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a umidade';
                                }
                                try {
                                  final umidade = double.parse(value);
                                  if (umidade < 0 || umidade > 100) {
                                    return 'Umidade deve estar entre 0 e 100%';
                                  }
                                } catch (e) {
                                  return 'Informe um número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Observações
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
                              'Fotos da Colheita',
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
                      onPressed: _salvarColheita,
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SALVAR COLHEITA',
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
    _dataColheitaController.dispose();
    _areaColhidaController.dispose();
    _produtividadeController.dispose();
    _umidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
