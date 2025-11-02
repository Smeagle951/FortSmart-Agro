import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../models/seed_calculation.dart';
import '../repositories/seed_calculation_repository.dart';
import '../repositories/plot_repository.dart';
import '../repositories/crop_repository.dart';
import '../repositories/variety_repository.dart';
import '../utils/image_service.dart';
import '../utils/logger.dart';
import '../widgets/advanced_plot_selector.dart';
import '../widgets/farm_crop_selector.dart';
import '../widgets/variety_selector.dart';
import '../widgets/custom_dialog.dart';

class SeedCalculationScreen extends StatefulWidget {
  final SeedCalculation? seedCalculation;

  const SeedCalculationScreen({Key? key, this.seedCalculation}) : super(key: key);

  @override
  _SeedCalculationScreenState createState() => _SeedCalculationScreenState();
}

class _SeedCalculationScreenState extends State<SeedCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _populacaoController = TextEditingController();
  final _pesoMilSementesController = TextEditingController();
  final _germinacaoController = TextEditingController();
  final _purezaController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  final _repository = SeedCalculationRepository();
  final _plotRepository = PlotRepository();
  final _cropRepository = CropRepository();
  final _varietyRepository = VarietyRepository();
  
  String? _selectedTalhaoId;
  String? _selectedCulturaId;
  String? _selectedVariedadeId;
  String _tipoCalculo = 'populacao'; // 'populacao' ou 'peso'
  double _resultadoSementesHa = 0.0;
  double _resultadoSementesMetro = 0.0;
  double _resultadoKgHa = 0.0;
  DateTime _dataCalculo = DateTime.now();
  
  List<String> _photoList = [];
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Valores padrão
    _populacaoController.text = '60000';
    _pesoMilSementesController.text = '320';
    _germinacaoController.text = '95';
    _purezaController.text = '98';
    _espacamentoController.text = '50';
    
    if (widget.seedCalculation != null) {
      _isEditing = true;
      _loadSeedCalculationData();
    }
    
    // Adicionar listeners para cálculos automáticos
    _populacaoController.addListener(_calculate);
    _pesoMilSementesController.addListener(_calculate);
    _germinacaoController.addListener(_calculate);
    _purezaController.addListener(_calculate);
    _espacamentoController.addListener(_calculate);
    
    // Calcular com os valores iniciais
    _calculate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _populacaoController.dispose();
    _pesoMilSementesController.dispose();
    _germinacaoController.dispose();
    _purezaController.dispose();
    _espacamentoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
  
  void _loadSeedCalculationData() {
    final seedCalc = widget.seedCalculation!;
    
    // Removido nome que não existe no modelo
    _selectedTalhaoId = seedCalc.talhaoId.toString();
    _selectedCulturaId = seedCalc.culturaId.toString();
    _selectedVariedadeId = seedCalc.variedadeId.toString();
    _populacaoController.text = seedCalc.populacao.toString();
    _pesoMilSementesController.text = seedCalc.pesoMilSementes.toString();
    _germinacaoController.text = (seedCalc.germinacao * 100).toString();
    _purezaController.text = (seedCalc.pureza * 100).toString();
    // Removido espacamento que não existe no modelo
    _tipoCalculo = seedCalc.tipoCalculo;
    _observacoesController.text = seedCalc.observacoes ?? '';
    
    if (seedCalc.fotos != null && seedCalc.fotos!.isNotEmpty) {
      _photoList = seedCalc.fotos!.split(',');
    }
    
    try {
      _dataCalculo = DateTime.parse(seedCalc.dataCalculo);
    } catch (e) {
      _dataCalculo = DateTime.now();
    }
  }
  
  void _calculate() {
    if (!mounted) return;
    
    try {
      final populacao = double.tryParse(_populacaoController.text) ?? 0;
      final pesoMilSementes = double.tryParse(_pesoMilSementesController.text) ?? 0;
      final germinacao = double.tryParse(_germinacaoController.text) ?? 0;
      final pureza = double.tryParse(_purezaController.text) ?? 0;
      final espacamento = double.tryParse(_espacamentoController.text) ?? 0;
      
      if (populacao <= 0 || pesoMilSementes <= 0 || germinacao <= 0 || pureza <= 0 || espacamento <= 0) {
        setState(() {
          _resultadoSementesHa = 0;
          _resultadoSementesMetro = 0;
          _resultadoKgHa = 0;
        });
        return;
      }
      
      // Converter para decimal (0-1)
      final germinacaoDecimal = germinacao / 100;
      final purezaDecimal = pureza / 100;
      
      // Calcular sementes por hectare corrigida
      final double sementesHaCorrigida = populacao / (germinacaoDecimal * purezaDecimal);
      
      // Calcular sementes por metro linear
      final double sementesMetro = (populacao / 10000) * (espacamento / 100);
      
      // Calcular kg por hectare
      final double kgHa = (sementesHaCorrigida * pesoMilSementes) / 1000000;
      
      setState(() {
        _resultadoSementesHa = sementesHaCorrigida;
        _resultadoSementesMetro = sementesMetro;
        _resultadoKgHa = kgHa;
      });
    } catch (e) {
      Logger.error('Erro ao calcular: $e');
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
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
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _isLoading = true);
        
        // Comprimir e salvar a imagem
        final imageService = ImageService();
        final savedImagePath = await imageService.saveImage(
          File(image.path),
        );
        
        setState(() {
          _photoList.add(savedImagePath);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Logger.error('Erro ao capturar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
    }
  }
  
  void _removePhoto(int index) {
    setState(() {
      _photoList.removeAt(index);
    });
  }
  
  Future<void> _saveSeedCalculation() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isLoading = true);
      
      final String fotosString = _photoList.join(',');
      final double populacao = double.tryParse(_populacaoController.text) ?? 0;
      final double pesoMilSementes = double.tryParse(_pesoMilSementesController.text) ?? 0;
      final double germinacao = double.tryParse(_germinacaoController.text) ?? 0;
      final double pureza = double.tryParse(_purezaController.text) ?? 0;
      // Removido espacamento pois não é usado no construtor
      
      final seedCalculation = SeedCalculation(
        id: widget.seedCalculation?.id,
        // nome removido pois é um getter no modelo
        talhaoId: _selectedTalhaoId != null ? int.parse(_selectedTalhaoId!) : 0,
        culturaId: _selectedCulturaId != null ? int.parse(_selectedCulturaId!) : 0,
        variedadeId: _selectedVariedadeId != null ? int.parse(_selectedVariedadeId!) : 0,
        populacao: populacao,
        pesoMilSementes: pesoMilSementes,
        germinacao: germinacao / 100, // Convertendo para decimal
        pureza: pureza / 100, // Convertendo para decimal
        tipoCalculo: _tipoCalculo,
        resultadoKgHectare: _resultadoKgHa,
        resultadoSementeMetro: _resultadoSementesMetro,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
        fotos: fotosString.isEmpty ? null : fotosString,
        dataCalculo: _dataCalculo.toIso8601String(),
      );
      
      if (_isEditing) {
        await _repository.update(seedCalculation);
      } else {
        await _repository.insert(seedCalculation);
      }
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Logger.error('Erro ao salvar cálculo de sementes: $e');
      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Erro',
          message: 'Erro ao salvar cálculo de sementes: $e',
          primaryButtonText: 'OK',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cálculo de Sementes' : 'Novo Cálculo de Sementes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSeedCalculation,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Cálculo*',
                        hintText: 'Ex: Cálculo Milho Safra 2025',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe um nome para o cálculo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Data do cálculo
                    InkWell(
                      // onTap: () => _selectDate(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data do cálculo',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_dataCalculo)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Seletores de talhão, cultura e variedade
                    AdvancedPlotSelector(
                      initialValue: _selectedTalhaoId,
                      onChanged: (value) {
                        setState(() {
                          _selectedTalhaoId = value;
                          // Resetar outros campos relacionados ao talhão se necessário
                        });
                      },
                      showThumbnail: true,
                    ),
                    const SizedBox(height: 12),
                    
                    FarmCropSelector(
                      initialValue: _selectedCulturaId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCulturaId = value;
                          _selectedVariedadeId = null; // Resetar variedade ao mudar cultura
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    if (_selectedCulturaId != null)
                      VarietySelector(
                        culturaId: int.tryParse(_selectedCulturaId!) ?? 0,
                        initialValue: _selectedVariedadeId != null ? int.tryParse(_selectedVariedadeId!) : null,
                        onChanged: (value) {
                          setState(() {
                            _selectedVariedadeId = value.toString();
                          });
                        },
                      ),
                    const SizedBox(height: 20),
                    
                    // Opções de tipo de cálculo
                    const Text(
                      'Tipo de Cálculo:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A4F3D),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Por População'),
                            value: 'populacao',
                            groupValue: _tipoCalculo,
                            onChanged: (value) {
                              setState(() {
                                _tipoCalculo = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Por Peso'),
                            value: 'peso',
                            groupValue: _tipoCalculo,
                            onChanged: (value) {
                              setState(() {
                                _tipoCalculo = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Campos de entrada
                    const Text(
                      'Parâmetros:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A4F3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // População
                    TextFormField(
                      controller: _populacaoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'População (plantas/ha)*',
                        hintText: 'Ex: 60000',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a população';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Peso de mil sementes
                    TextFormField(
                      controller: _pesoMilSementesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso de 1000 sementes (g)*',
                        hintText: 'Ex: 320',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o peso de mil sementes';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Germinação e pureza
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _germinacaoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Germinação (%)*',
                              hintText: 'Ex: 95',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a germinação';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _purezaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pureza (%)*',
                              hintText: 'Ex: 98',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a pureza';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Espaçamento
                    TextFormField(
                      controller: _espacamentoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Espaçamento (cm)*',
                        hintText: 'Ex: 50',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o espaçamento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Resultados calculados
                    const Text(
                      'Resultados:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A4F3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sementes por hectare: ${NumberFormat('#,###').format(_resultadoSementesHa.round())}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sementes por metro: ${_resultadoSementesMetro.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quilos por hectare: ${_resultadoKgHa.toStringAsFixed(1)} kg/ha',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Observações
                    TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        hintText: 'Informações adicionais sobre o cálculo',
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Fotos
                    const Text(
                      'Fotos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A4F3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Grid de fotos
                    if (_photoList.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _photoList.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_photoList[index]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  // onTap: () => _removePhoto(index), // onTap não é suportado em Polygon no flutter_map 5.0.0
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Adicionar Foto'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
