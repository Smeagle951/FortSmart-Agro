import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/experimento_model.dart';
import '../services/experimento_service.dart';
import '../services/data_cache_service.dart';
import '../services/contexto_agricola_service.dart';
import '../../../widgets/plot_selector.dart';
import '../../../widgets/crop_selector.dart';
import '../../../widgets/crop_variety_selector.dart';
// import '../../../widgets/notifications_wrapper.dart'; // Não utilizado

class ExperimentoScreen extends StatefulWidget {
  final ExperimentoModel? experimento;

  const ExperimentoScreen({Key? key, this.experimento}) : super(key: key);

  @override
  _ExperimentoScreenState createState() => _ExperimentoScreenState();
}

class _ExperimentoScreenState extends State<ExperimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experimento = ExperimentoService();
  final _contextoAgricola = ContextoAgricolaService();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _talhaoController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _areaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Dados
  String? _talhaoId;
  String? _culturaId;
  String? _variedadeId;
  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  List<String> _fotos = [];
  final _dataCacheService = DataCacheService();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    if (widget.experimento != null) {
      setState(() => _isLoading = true);
      try {
        // Se já temos o objeto experimento, usamos ele diretamente
        final experimento = widget.experimento;
        if (experimento != null) {
          setState(() {
            _isEditing = true;
            _nomeController.text = experimento.nome;
            _talhaoId = experimento.talhaoId.toString();
            _culturaId = experimento.culturaId.toString();
            _variedadeId = experimento.variedadeId.toString();
            _dataInicio = experimento.dataInicio;
            _dataFim = experimento.dataFim;
            _areaController.text = experimento.area.toString();
            _descricaoController.text = experimento.descricao;
            _observacoesController.text = experimento.observacoes ?? '';
            _fotos = experimento.fotos ?? [];
            
            // Carregar nomes dos itens selecionados
            _carregarNomeTalhao(_talhaoId!);
            _carregarNomeCultura(_culturaId!);
            _carregarNomeVariedade(_variedadeId!);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: const Color(0xFF228B22),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _carregarNomeTalhao(String plotId) async {
    try {
      final talhoes = await _dataCacheService.getTalhoes();
      final talhao = talhoes.firstWhere(
        (t) => t.id.toString() == plotId.toString(),
        orElse: () => talhoes.first,
      );
      setState(() {
        _talhaoController.text = talhao.nome;
      });
    } catch (e) {
      _talhaoController.text = 'Talhão $plotId';
    }
  }
  
  Future<void> _carregarNomeCultura(String cropId) async {
    try {
      final culturas = await _dataCacheService.getCulturas();
      // Garantir que estamos trabalhando com strings nas comparações
      final cultura = culturas.firstWhere(
        (c) => c.id.toString() == cropId.toString(),
        orElse: () => culturas.first,
      );
      setState(() {
        _culturaController.text = cultura.name;
      });
    } catch (e) {
      _culturaController.text = 'Cultura $cropId';
    }
  }
  
  Future<void> _carregarNomeVariedade(String varietyId) async {
    try {
      final variedades = await _dataCacheService.getVariedades(
        culturaId: _culturaId // Já é String?, não precisa de conversão
      );
      if (variedades.isNotEmpty) {
        final variedade = variedades.firstWhere(
          (v) => v.id.toString() == varietyId.toString(),
          orElse: () => variedades.first,
        );
        setState(() {
          _variedadeController.text = variedade.name;
        });
      } else {
        _variedadeController.text = 'Variedade $varietyId';
      }
    } catch (e) {
      _variedadeController.text = 'Variedade $varietyId';
    }
  }
  
  Future<void> _salvarExperimento() async {
    if (_formKey.currentState!.validate()) {
      if (_talhaoId == null || _culturaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione um talhão e uma cultura'),
            backgroundColor: const Color(0xFF228B22),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Carregar contexto do talhão para obter safra atual
        final contexto = await _contextoAgricola.carregarContextoDoTalhao(_talhaoId!);
        final safraAtual = contexto['safra'];

        if (safraAtual == null) {
          throw Exception('O talhão não possui uma safra ativa');
        }

        final experimento = ExperimentoModel(
          id: _isEditing ? widget.experimento!.id : null,
          nome: _nomeController.text,
          talhaoId: _talhaoId!,
          culturaId: _culturaId!,
          variedadeId: _variedadeId ?? '',
          safraId: safraAtual.id,
          dataInicio: _dataInicio,
          dataFim: _dataFim,
          area: double.tryParse(_areaController.text) ?? 0.0,
          descricao: _descricaoController.text,
          observacoes: _observacoesController.text,
          fotos: _fotos,
          culturaNome: '',
        );

        await _experimento.saveExperimento(experimento);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar experimento: ${e.toString()}'),
              backgroundColor: const Color(0xFF228B22),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
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
      setState(() => _dataInicio = data);
    }
  }
  
  Future<void> _selecionarDataFim() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? DateTime.now(),
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
      setState(() => _dataFim = data);
    }
  }
  
  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _fotos.add(pickedFile.path);
      });
    }
  }
  

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: Text(_isEditing ? 'Editar Experimento' : 'Novo Experimento'),
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
                      title: 'Informações Gerais',
                      icon: Icons.science,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Experimento',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o nome do experimento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PlotSelector(
                          initialValue: _talhaoId,
                          onChanged: (plotId) {
                            setState(() {
                              _talhaoId = plotId;
                              // Buscar o nome do talhão para exibição
                              _carregarNomeTalhao(plotId);
                            });
                          },
                          isRequired: true,
                          label: 'Talhão',
                        ),
                        const SizedBox(height: 16),
                        CropSelector(
                          initialValue: _culturaId,
                          onChanged: (cropId) {
                            setState(() {
                              _culturaId = cropId;
                              // Buscar o nome da cultura para exibição
                              _carregarNomeCultura(cropId);
                              // Limpar a variedade quando a cultura muda
                              _variedadeId = null;
                              _variedadeController.text = '';
                            });
                          },
                          isRequired: true,
                          label: 'Cultura',
                        ),
                        const SizedBox(height: 16),
                        CropVarietySelector(
                          initialValue: _variedadeId,
                          cropId: _culturaId,
                          onChanged: (varietyId) {
                            setState(() {
                              _variedadeId = varietyId;
                              // Buscar o nome da variedade para exibição
                              _carregarNomeVariedade(varietyId);
                            });
                          },
                          isRequired: true,
                          label: 'Variedade',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Detalhes do Experimento',
                      icon: Icons.science_outlined,
                      children: [
                        TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(
                            labelText: 'Área Experimental (ha)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a área';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descricaoController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição Técnica',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a descrição técnica';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          label: 'Data de Início',
                          value: _dataInicio,
                          onTap: () => _selecionarData(context, true),
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          label: 'Data de Término (opcional)',
                          value: _dataFim,
                          onTap: () => _selecionarData(context, false),
                          opcional: true,
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
                      title: 'Fotos do Experimento',
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
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(_fotos[index]),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
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
                      onPressed: _isLoading ? null : _salvarExperimento,
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
                              'SALVAR EXPERIMENTO',
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
  

  
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool opcional = false,
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
        child: Text(
          value != null ? formatter.format(value) : opcional ? 'Não definido' : 'Selecione uma data',
        ),
      ),
    );
  }
  

  
  /// Método para selecionar data de início ou término
  Future<void> _selecionarData(BuildContext context, bool isDataInicio) async {
    final DateTime hoje = DateTime.now();
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: isDataInicio 
          ? _dataInicio // _dataInicio nunca é null, pois é inicializado com DateTime.now()
          : (_dataFim ?? hoje),    // Se dataFim for null, use hoje
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    
    if (dataSelecionada != null) {
      setState(() {
        if (isDataInicio) {
          _dataInicio = dataSelecionada;
        } else {
          _dataFim = dataSelecionada;
        }
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _talhaoController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _areaController.dispose();
    _descricaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
