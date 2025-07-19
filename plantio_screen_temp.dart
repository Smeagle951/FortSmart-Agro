import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../models/talhao_model_new.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/machine.dart';
import '../models/plantio_model.dart';
import '../services/plantio_service.dart';
import '../services/data_cache_service.dart';
import '../widgets/advanced_culture_filter.dart';
import '../widgets/talhao_map_widget.dart';
import '../widgets/machine_details_card.dart';

class PlantioScreen extends StatefulWidget {
  final int? plantioId;

  const PlantioScreen({Key? key, this.plantioId}) : super(key: key);

  @override
  _PlantioScreenState createState() => _PlantioScreenState();
}

class _PlantioScreenState extends State<PlantioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plantioService = PlantioService();
  final _dataCacheService = DataCacheService();
  
  // Serviços
  // O serviço de cache gerencia o acesso aos repositórios
  
  // Controllers
  final _talhaoController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _tratorController = TextEditingController();
  final _plantadeiraController = TextEditingController();
  final _populacaoController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Dados
  int? _talhaoId;
  String? _culturaId; // Alterado de int? para String? para compatibilidade
  int? _variedadeId;
  DateTime _dataPlantio = DateTime.now();
  int? _tratorId;
  int? _plantadeiraId;
  List<String> _fotos = [];
  
  // Listas de dados
  List<TalhaoModel> _talhoes = [];
  List<AgriculturalProduct> _culturas = [];
  List<AgriculturalProduct> _variedades = [];
  List<Machine> _tratores = [];
  List<Machine> _plantadeiras = [];
  
  // Objetos selecionados para uso futuro (como exibir o mapa do talhão)
  TalhaoModel? _selectedTalhao;
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarTalhoes();
    _carregarCulturas();
    _carregarMaquinas();
  }
  
  Future<void> _carregarTalhoes() async {
    setState(() => _isLoading = true);
    try {
      // Usar o serviço de cache para carregar os talhões
      _talhoes = await _dataCacheService.getTalhoes();
    } catch (e) {
      _mostrarErro('Erro ao carregar talhões: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _carregarCulturas() async {
    setState(() => _isLoading = true);
    try {
      // Usar o serviço de cache para carregar as culturas
      _culturas = await _dataCacheService.getCulturas();
    } catch (e) {
      _mostrarErro('Erro ao carregar culturas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _carregarMaquinas() async {
    setState(() => _isLoading = true);
    try {
      // Usar o serviço de cache para carregar as máquinas
      _tratores = await _dataCacheService.getTratores();
      _plantadeiras = await _dataCacheService.getPlantadeiras();
    } catch (e) {
      _mostrarErro('Erro ao carregar máquinas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _carregarVariedades() async {
    if (_culturaId == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Usar o serviço de cache para carregar as variedades filtradas por cultura
      _variedades = await _dataCacheService.getVariedades(culturaId: _culturaId);
    } catch (e) {
      _mostrarErro('Erro ao carregar variedades: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _carregarDados() async {
    if (widget.plantioId != null) {
      setState(() => _isLoading = true);
      try {
        final plantio = await _plantioService.getPlantioById(widget.plantioId!);
        if (plantio != null) {
          setState(() {
            _isEditing = true;
            _talhaoId = plantio.talhaoId;
            _culturaId = plantio.culturaId.toString(); // Convertendo int para String
            _variedadeId = plantio.variedadeId;
            _tratorId = plantio.tratorId;
            _plantadeiraId = plantio.plantadeiraId;
            _dataPlantio = plantio.dataPlantio;
            _fotos = plantio.fotos ?? [];
            
            // Carregar informações de nomes para os dropdowns
            _carregarNomesTalhao();
            _carregarNomesCultura();
            _carregarNomesVariedade();
            _carregarNomesTrator();
            _carregarNomesPlantadeira();
            
            _populacaoController.text = plantio.populacao.toString();
            _espacamentoController.text = plantio.espacamento.toString();
            _observacoesController.text = plantio.observacoes ?? '';
          });
        }
      } catch (e) {
        _mostrarErro('Erro ao carregar dados: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Métodos para carregar dados de outras tabelas
  Future<void> _carregarNomesTalhao() async {
    if (_talhaoId == null) return;
    
    try {
      final talhao = await _dataCacheService.getTalhaoById(_talhaoId.toString());
      if (talhao != null) {
        _talhaoController.text = talhao.nome;
        _selectedTalhao = talhao;
      } else {
        _talhaoController.text = 'Talhão não encontrado';
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados do talhão: $e');
      _talhaoController.text = 'Erro ao carregar talhão';
    }
  }
  
  Future<void> _carregarNomesCultura() async {
    if (_culturaId == null) return;
    
    try {
      final cultura = await _dataCacheService.getCulturaById(_culturaId.toString());
      if (cultura != null) {
        _culturaController.text = cultura.name;
      } else {
        _culturaController.text = 'Cultura não encontrada';
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados da cultura: $e');
      _culturaController.text = 'Erro ao carregar cultura';
    }
  }
  
  Future<void> _carregarNomesVariedade() async {
    if (_variedadeId == null) return;
    
    try {
      final variedade = await _dataCacheService.getVariedadeById(_variedadeId.toString());
      if (variedade != null) {
        _variedadeController.text = variedade.name;
      } else {
        _variedadeController.text = 'Variedade não encontrada';
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados da variedade: $e');
      _variedadeController.text = 'Erro ao carregar variedade';
    }
  }
  
  Future<void> _carregarNomesTrator() async {
    if (_tratorId == null) return;
    
    try {
      final trator = await _dataCacheService.getTratorById(_tratorId.toString());
      if (trator != null) {
        _tratorController.text = trator.name;
      } else {
        _tratorController.text = 'Trator não encontrado';
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados do trator: $e');
      _tratorController.text = 'Erro ao carregar trator';
    }
  }
  
  Future<void> _carregarNomesPlantadeira() async {
    if (_plantadeiraId == null) return;
    
    try {
      final plantadeira = await _dataCacheService.getPlantadeiraById(_plantadeiraId.toString());
      if (plantadeira != null) {
        _plantadeiraController.text = plantadeira.name;
      } else {
        _plantadeiraController.text = 'Plantadeira não encontrada';
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados da plantadeira: $e');
      _plantadeiraController.text = 'Erro ao carregar plantadeira';
    }
  }
  
  Future<void> _salvarPlantio() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_talhaoId == null || _culturaId == null || _variedadeId == null || 
        _tratorId == null || _plantadeiraId == null) {
      _mostrarErro('Preencha todos os campos obrigatórios');
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
          final targetPath = '${dir.path}/plantio_fotos/$fileName';
          
          // Criar diretório se não existir
          final directory = Directory('${dir.path}/plantio_fotos');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          // Copiar arquivo para local permanente
          await File(fotoPath).copy(targetPath);
          fotosProcessadas.add(targetPath);
        } catch (e) {
          print('Erro ao processar foto: $e');
          // Continua processando as outras fotos mesmo se uma falhar
        }
      }
      
      final plantio = PlantioModel(
        id: widget.plantioId,
        talhaoId: _talhaoId!,
        culturaId: int.parse(_culturaId!), // Convertendo String para int
        variedadeId: _variedadeId!,
        dataPlantio: _dataPlantio,
        tratorId: _tratorId!,
        plantadeiraId: _plantadeiraId!,
        populacao: double.parse(_populacaoController.text),
        espacamento: double.parse(_espacamentoController.text),
        observacoes: _observacoesController.text,
        fotos: fotosProcessadas.isNotEmpty ? fotosProcessadas : _fotos,
      );
      
      // Salvar plantio
      await _plantioService.savePlantio(plantio);
      
      // Limpar cache para garantir dados atualizados
      _dataCacheService.clearCache();
      
      _mostrarMensagem('Plantio salvo com sucesso!');
      
      // Volta para a tela anterior após salvar
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro('Erro ao salvar plantio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataPlantio,
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
      setState(() => _dataPlantio = data);
    }
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
  
  void _mostrarMensagem(String mensagem) {
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
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: Text(_isEditing ? 'Editar Plantio' : 'Cadastro de Plantio'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                      title: 'Informações Gerais',
                      icon: Icons.grass,
                      children: [
                        _buildDropdownField(
                          label: 'Talhão',
                          controller: _talhaoController,
                          onTap: () => _selecionarTalhao(),
                          icon: Icons.crop_square,
                        ),
                        if (_talhoes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navegar para a tela de cadastro de talhões
                                Navigator.of(context).pushNamed('/talhoes/cadastro').then((_) {
                                  _carregarTalhoes();
                                });
                              },
                              icon: const Icon(Icons.add, color: Color(0xFF228B22)),
                              label: const Text('Adicionar Talhão', style: TextStyle(color: Color(0xFF228B22))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF228B22)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Cultura',
                          controller: _culturaController,
                          onTap: () => _selecionarCultura(),
                          icon: Icons.spa,
                        ),
                        if (_culturas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navegar para a tela de cadastro de culturas
                                Navigator.of(context).pushNamed('/culturas/cadastro').then((_) {
                                  _carregarCulturas();
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
                        _buildDropdownField(
                          label: 'Variedade',
                          controller: _variedadeController,
                          onTap: () => _selecionarVariedade(),
                          icon: Icons.grain,
                        ),
                        if (_culturaId != null && _variedades.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navegar para a tela de cadastro de variedades
                                Navigator.of(context).pushNamed('/culturas/variedades/cadastro', arguments: _culturaId).then((_) {
                                  _carregarVariedades();
                                });
                              },
                              icon: const Icon(Icons.add, color: Color(0xFF228B22)),
                              label: const Text('Adicionar Variedade', style: TextStyle(color: Color(0xFF228B22))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF228B22)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          label: 'Data do Plantio',
                          value: _dataPlantio,
                          onTap: _selecionarData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Equipamentos',
                      icon: Icons.agriculture,
                      children: [
                        _buildDropdownField(
                          label: 'Trator',
                          controller: _tratorController,
                          onTap: () => _selecionarTrator(),
                          icon: Icons.agriculture,
                        ),
                        if (_tratores.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navegar para a tela de cadastro de tratores
                                Navigator.of(context).pushNamed('/maquinas/cadastro', arguments: {'tipo': MachineType.tractor.index}).then((_) {
                                  _carregarMaquinas();
                                });
                              },
                              icon: const Icon(Icons.add, color: Color(0xFF228B22)),
                              label: const Text('Adicionar Trator', style: TextStyle(color: Color(0xFF228B22))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF228B22)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Plantadeira',
                          controller: _plantadeiraController,
                          onTap: () => _selecionarPlantadeira(),
                          icon: Icons.precision_manufacturing,
                        ),
                        if (_plantadeiras.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navegar para a tela de cadastro de plantadeiras
                                Navigator.of(context).pushNamed('/maquinas/cadastro', arguments: {'tipo': MachineType.planter.index}).then((_) {
                                  _carregarMaquinas();
                                });
                              },
                              icon: const Icon(Icons.add, color: Color(0xFF228B22)),
                              label: const Text('Adicionar Plantadeira', style: TextStyle(color: Color(0xFF228B22))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF228B22)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Detalhes do Plantio',
                      icon: Icons.settings,
                      children: [
                        TextFormField(
                          controller: _populacaoController,
                          decoration: const InputDecoration(
                            labelText: 'População Desejada (plantas/ha)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a população';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _espacamentoController,
                          decoration: const InputDecoration(
                            labelText: 'Espaçamento entre Linhas (m)',
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
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Fotos do Plantio',
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
                                            onTap: () => _escolherFoto(),
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
                                              // onTap: () {
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
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _escolherFoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Adicionar Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF228B22),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvarPlantio,
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
                              'SALVAR PLANTIO',
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
    final formatter = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data do Plantio',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(formatter.format(value)),
      ),
    );
  }
  
  // Métodos para seleção de dados
  // Método para mostrar seleção com preview do talhão usando o widget de mapa real
  Future<Map<String, dynamic>?> _mostrarSelecaoComPreview(String titulo, List<Map<String, dynamic>> opcoes) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: opcoes.length,
            itemBuilder: (context, index) {
              final opcao = opcoes[index];
              final talhao = opcao['model'] as TalhaoModel;
              
              return Column(
                children: [
                  ListTile(
                    title: Text(opcao['nome']),
                    subtitle: Text('Cultura: ${talhao.cultura} | Área: ${talhao.area.toStringAsFixed(2)} ha'),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF228B22),
                      child: Text(talhao.icone),
                    ),
                    onTap: () => Navigator.of(context).pop(opcao),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TalhaoMapWidget(
                      talhao: talhao,
                      height: 200,
                      interactive: true,
                      onTalhaoTapped: (_) => Navigator.of(context).pop(opcao),
                    ),
                  ),
                  const Divider(),
                ],
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
  
  Future<void> _selecionarTalhao() async {
    setState(() => _isLoading = true);
    try {
      // Forçar atualização dos talhões do banco de dados
      _talhoes = await _dataCacheService.getTalhoes(forceRefresh: true);
      
      if (_talhoes.isEmpty) {
        _mostrarErro('Nenhum talhão cadastrado. Cadastre talhões primeiro.');
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);
      
      final List<Map<String, dynamic>> opcoesTalhoes = _talhoes.map((talhao) {
        return {
          'id': int.tryParse(talhao.id) ?? 1, // Convertendo String para int
          'nome': talhao.nome,
          'model': talhao,
        };
      }).toList();
      
      final result = await _mostrarSelecaoComPreview('Selecionar Talhão', opcoesTalhoes);
      
      if (result != null) {
        setState(() {
          _talhaoId = result['id'];
          _talhaoController.text = result['nome'];
          _selectedTalhao = result['model'] as TalhaoModel;
        });
      }
    } catch (error) {
      _mostrarErro('Erro ao carregar talhões: $error');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selecionarCultura() async {
    setState(() => _isLoading = true);
    try {
      // Forçar atualização das culturas do banco de dados
      _culturas = await _dataCacheService.getCulturas(forceRefresh: true);
      
      if (_culturas.isEmpty) {
        _mostrarErro('Nenhuma cultura cadastrada. Cadastre culturas primeiro.');
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _mostrarErro('Erro ao carregar culturas: $e');
      setState(() => _isLoading = false);
      return;
    }
    
    // Lista original de culturas para o filtro
    List<AgriculturalProduct> culturasFiltradas = List.from(_culturas);
    
    // Mostrar diálogo com filtro avançado
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Selecionar Cultura'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // Filtro avançado
                Expanded(
                  flex: 2,
                  child: AdvancedCultureFilter(
                    culturas: _culturas,
                    onFiltered: (filteredCulturas) {
                      setDialogState(() {
                        culturasFiltradas = filteredCulturas;
                      });
                    },
                  ),
                ),
                
                const Divider(),
                
                // Lista de culturas filtradas
                Expanded(
                  flex: 3,
                  child: culturasFiltradas.isEmpty
                    ? const Center(child: Text('Nenhuma cultura encontrada com esse filtro'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: culturasFiltradas.length,
                        itemBuilder: (context, index) {
                          final cultura = culturasFiltradas[index];
                          final opcao = {
                            'id': int.tryParse(cultura.id) ?? 1,
                            'nome': cultura.name,
                            'model': cultura,
                          };
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              title: Text(
                                cultura.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fabricante: ${cultura.manufacturer ?? "Não informado"}'),
                                  if (cultura.tags?.isNotEmpty ?? false)
                                    Text('Tags: ${cultura.tags!.join(", ")}'),
                                ],
                              ),
                              isThreeLine: cultura.tags?.isNotEmpty ?? false,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF228B22),
                                child: const Icon(
                                  Icons.grass,
                                  color: Color(0xFF228B22),
                                ),
                              ),
                              onTap:
                            ),
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
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _culturaId = result['id'];
        _culturaController.text = result['nome'];
        // Reset variedade quando cultura muda
        _variedadeId = null;
        _variedadeController.text = '';
        
        // Carregar variedades baseadas na cultura selecionada
        _carregarVariedades();
      });
    }
  }
  
  Future<void> _selecionarVariedade() async {
    if (_culturaId == null) {
      _mostrarErro('Selecione uma cultura primeiro');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // Forçar atualização das variedades do banco de dados
      _variedades = await _dataCacheService.getVariedades(culturaId: _culturaId, forceRefresh: true);
      
      if (_variedades.isEmpty) {
        _mostrarErro('Nenhuma variedade disponível para esta cultura.');
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _mostrarErro('Erro ao carregar variedades: $e');
      setState(() => _isLoading = false);
      return;
    }
    
    // Lista original de variedades para o filtro
    List<AgriculturalProduct> variedadesFiltradas = List.from(_variedades);
    TextEditingController searchController = TextEditingController();
    
    // Mostrar diálogo com filtro de busca
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Selecionar Variedade'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // Campo de busca
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar variedade',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        variedadesFiltradas = _variedades.where((variedade) {
                          return variedade.name.toLowerCase().contains(value.toLowerCase()) ||
                            (variedade.manufacturer?.toLowerCase().contains(value.toLowerCase()) ?? false);
                        }).toList();
                      });
                    },
                  ),
                ),
                
                // Lista de variedades filtradas
                Expanded(
                  child: variedadesFiltradas.isEmpty
                    ? const Center(child: Text('Nenhuma variedade encontrada com esse filtro'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: variedadesFiltradas.length,
                        itemBuilder: (context, index) {
                          final variedade = variedadesFiltradas[index];
                          final opcao = {
                            'id': int.tryParse(variedade.id) ?? 1,
                            'nome': variedade.name,
                            'model': variedade,
                          };
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              title: Text(
                                variedade.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fabricante: ${variedade.manufacturer ?? "Não informado"}'),
                                  if (variedade.tags?.isNotEmpty ?? false)
                                    Text('Tags: ${variedade.tags!.join(", ")}'),
                                ],
                              ),
                              isThreeLine: variedade.tags?.isNotEmpty ?? false,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF228B22),
                                child: const Icon(
                                  Icons.eco,
                                  color: Color(0xFF228B22),
                                ),
                              ),
                              onTap:
                            ),
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
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _variedadeId = result['id'];
        _variedadeController.text = result['nome'];
      });
    }
  }
  
  Future<void> _selecionarTrator() async {
    setState(() => _isLoading = true);
    try {
      // Forçar atualização dos tratores do banco de dados
      _tratores = await _dataCacheService.getTratores(forceRefresh: true);
      
      if (_tratores.isEmpty) {
        _mostrarErro('Nenhum trator cadastrado. Cadastre tratores primeiro.');
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _mostrarErro('Erro ao carregar tratores: $e');
      setState(() => _isLoading = false);
      return;
    }
    
    // Filtrar tratores por texto
    List<Machine> tratoresFiltrados = List.from(_tratores);
    TextEditingController searchController = TextEditingController();
    
    // Mostrar diálogo com detalhes técnicos das máquinas e filtro
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Selecionar Trator'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // Campo de busca
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar trator',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        tratoresFiltrados = _tratores.where((trator) {
                          return trator.name.toLowerCase().contains(value.toLowerCase()) ||
                            (trator.brand?.toLowerCase().contains(value.toLowerCase()) ?? false);
                        }).toList();
                      });
                    },
                  ),
                ),
                
                // Lista de tratores
                Expanded(
                  child: tratoresFiltrados.isEmpty
                    ? const Center(child: Text('Nenhum trator encontrado com esse filtro'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: tratoresFiltrados.length,
                        itemBuilder: (context, index) {
                          final trator = tratoresFiltrados[index];
                          return MachineDetailsCard(
                            machine: trator,
                            onSelect: () => Navigator.of(context).pop({
                              'id': int.tryParse(trator.id) ?? 1,
                              'nome': trator.name,
                              'model': trator,
                            }),
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
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _tratorId = result['id'];
        _tratorController.text = result['nome'];
      });
    }
  }
  
  Future<void> _selecionarPlantadeira() async {
    setState(() => _isLoading = true);
    try {
      // Forçar atualização das plantadeiras do banco de dados
      _plantadeiras = await _dataCacheService.getPlantadeiras(forceRefresh: true);
      
      if (_plantadeiras.isEmpty) {
        _mostrarErro('Nenhuma plantadeira cadastrada. Cadastre plantadeiras primeiro.');
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _mostrarErro('Erro ao carregar plantadeiras: $e');
      setState(() => _isLoading = false);
      return;
    }
    
    // Filtrar plantadeiras por texto
    List<Machine> plantadeirasFiltradas = List.from(_plantadeiras);
    TextEditingController searchController = TextEditingController();
    
    // Mostrar diálogo com detalhes técnicos das máquinas e filtro
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Selecionar Plantadeira'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // Campo de busca
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar plantadeira',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        plantadeirasFiltradas = _plantadeiras.where((plantadeira) {
                          return plantadeira.name.toLowerCase().contains(value.toLowerCase()) ||
                            (plantadeira.brand?.toLowerCase().contains(value.toLowerCase()) ?? false);
                        }).toList();
                      });
                    },
                  ),
                ),
                
                // Lista de plantadeiras
                Expanded(
                  child: plantadeirasFiltradas.isEmpty
                    ? const Center(child: Text('Nenhuma plantadeira encontrada com esse filtro'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: plantadeirasFiltradas.length,
                        itemBuilder: (context, index) {
                          final plantadeira = plantadeirasFiltradas[index];
                          return MachineDetailsCard(
                            machine: plantadeira,
                            onSelect: () => Navigator.of(context).pop({
                              'id': int.tryParse(plantadeira.id) ?? 1,
                              'nome': plantadeira.name,
                              'model': plantadeira,
                            }),
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
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _plantadeiraId = result['id'];
        _plantadeiraController.text = result['nome'];
      });
    }
  }
  

  
  @override
  void dispose() {
    _talhaoController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _tratorController.dispose();
    _plantadeiraController.dispose();
    _populacaoController.dispose();
    _espacamentoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
