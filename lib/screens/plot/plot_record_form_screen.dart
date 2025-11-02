import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PlotRecordFormScreen extends StatefulWidget {
  final String? plotId;
  final String? plotName;
  final int? recordId; // Se estiver editando um registro existente

  const PlotRecordFormScreen({
    Key? key,
    this.plotId,
    this.plotName,
    this.recordId,
  }) : super(key: key);

  @override
  State<PlotRecordFormScreen> createState() => _PlotRecordFormScreenState();
}

class _PlotRecordFormScreenState extends State<PlotRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Controllers
  final _dataController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _unidadeController = TextEditingController();
  final _custoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Estado
  String _tipoRegistroSelecionado = 'Calagem';
  List<String> _tiposRegistro = [
    'Calagem', 
    'Gessagem', 
    'Adubação', 
    'Plantio', 
    'Aplicação', 
    'Colheita', 
    'Outros'
  ];
  List<String> _fotos = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Se estiver editando, carregar os dados
    if (widget.recordId != null) {
      _carregarRegistro();
    }
  }
  
  Future<void> _carregarRegistro() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulação de carregamento de dados
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Em uma implementação real, você buscaria os dados do banco
    setState(() {
      _dataController.text = '2024-05-01';
      _tipoRegistroSelecionado = 'Calagem';
      _descricaoController.text = 'Aplicação de calcário';
      _quantidadeController.text = '2000';
      _unidadeController.text = 'kg';
      _custoController.text = '800.00';
      _observacoesController.text = 'Aplicação realizada com tempo bom';
      _isLoading = false;
    });
  }
  
  Future<void> _selecionarData() async {
    final dataAtual = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dataController.text)
          : dataAtual,
      firstDate: DateTime(dataAtual.year - 5),
      lastDate: dataAtual,
    );
    
    if (data != null) {
      setState(() {
        _dataController.text = DateFormat('yyyy-MM-dd').format(data);
      });
    }
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
  
  Future<void> _salvarRegistro() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Em uma implementação real, você salvaria no banco de dados
        // Simulação
        await Future.delayed(const Duration(milliseconds: 800));
        
        _mostrarSucesso('Registro salvo com sucesso!');
        
        // Retornar para a tela anterior
        if (mounted) Navigator.of(context).pop(true); // Retorna true para indicar sucesso
      } catch (e) {
        _mostrarErro('Erro ao salvar registro: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recordId == null ? 'Novo Registro' : 'Editar Registro'),
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
                    // Informações do talhão
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
                            Text(
                              widget.plotName ?? 'Talhão não especificado',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ID: ${widget.plotId ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Formulário principal
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
                              'Detalhes do Registro',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Data
                            TextFormField(
                              controller: _dataController,
                              decoration: InputDecoration(
                                labelText: 'Data',
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
                                  return 'Selecione a data';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Tipo de Registro
                            DropdownButtonFormField<String>(
                              value: _tipoRegistroSelecionado,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Registro',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: _tiposRegistro.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Text(tipo),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _tipoRegistroSelecionado = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione o tipo de registro';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Descrição
                            TextFormField(
                              controller: _descricaoController,
                              decoration: InputDecoration(
                                labelText: 'Descrição',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a descrição';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Quantidade e Unidade (linha)
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _quantidadeController,
                                    decoration: InputDecoration(
                                      labelText: 'Quantidade',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _unidadeController,
                                    decoration: InputDecoration(
                                      labelText: 'Unidade',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Custo
                            TextFormField(
                              controller: _custoController,
                              decoration: InputDecoration(
                                labelText: 'Custo (R\$)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.number,
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
                    
                    // Fotos
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
                              'Fotos',
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
                    
                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _salvarRegistro,
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SALVAR REGISTRO',
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
    _dataController.dispose();
    _descricaoController.dispose();
    _quantidadeController.dispose();
    _unidadeController.dispose();
    _custoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
