import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planting.dart';
import '../../repositories/planting_repository.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/crop_selector.dart';
import '../../models/crop.dart' as app_crop;
import '../../modules/planting/services/data_cache_service.dart';
import '../../utils/model_converter_utils.dart';
import '../../widgets/crop_variety_selector.dart';
// import '../../widgets/tractor_selector.dart'; // Removido - módulo de máquinas removido
// import '../../widgets/planter_selector.dart'; // Removido - módulo de máquinas removido
import '../../widgets/plot_selector.dart';
import '../../widgets/optimized_image_upload.dart';
import '../../services/image_service.dart';
import '../../utils/logger.dart';
import 'planting_list_screen.dart';

class PlantingFormScreen extends StatefulWidget {
  final String? plantingId;
  final bool viewOnly;

  const PlantingFormScreen({
    Key? key,
    this.plantingId,
    this.viewOnly = false,
  }) : super(key: key);

  @override
  State<PlantingFormScreen> createState() => _PlantingFormScreenState();
}

class _PlantingFormScreenState extends State<PlantingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PlantingRepository();
  final _imageService = ImageService();
  
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // Form fields
  String? _cropId;
  String? _cropVarietyId;
  String? _plotId;
  String? _planterId;
  String? _tractorId;
  DateTime _plantingDate = DateTime.now();
  final _seedRateController = TextEditingController();
  final _seedDepthController = TextEditingController();
  final _spacingController = TextEditingController();
  final _areaController = TextEditingController();
  final _populationController = TextEditingController();
  final _notesController = TextEditingController();
  List<String> _imageUrls = [];
  
  // Loaded data
  Planting? _planting;
  List<app_crop.Crop> _crops = [];
  final DataCacheService _dataCacheService = DataCacheService();

  @override
  void initState() {
    super.initState();
    _loadCulturas();
    if (widget.plantingId != null) {
      _loadPlanting();
    } else {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadCulturas() async {
    final culturas = await _dataCacheService.getCulturas();
    setState(() {
      _crops = culturas.map((c) => app_crop.Crop(
        id: int.tryParse(c.id.toString()),
        name: c.name,
        description: c.description ?? '',
        colorValue: c.colorValue ?? 0xFF4CAF50,
      )).toList();
    });
  }

  @override
  void dispose() {
    _seedRateController.dispose();
    _seedDepthController.dispose();
    _spacingController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPlanting() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final planting = await _repository.getById(widget.plantingId!);
      setState(() {
        _planting = planting;
        if (planting != null) {
          _cropId = planting?.cropId;
          _cropVarietyId = planting?.cropVarietyId;
          _plotId = planting?.plotId;
          _planterId = planting?.planterId;
          _tractorId = planting?.tractorId;
          _plantingDate = planting?.plantingDate ?? DateTime.now();
          _seedRateController.text = planting?.seedRate?.toString() ?? '';
          _seedDepthController.text = planting.seedDepth?.toString() ?? '';
          _spacingController.text = planting.rowSpacing?.toString() ?? '';
          _areaController.text = planting.area?.toString() ?? '';
          _populationController.text = planting.seedRate?.toString() ?? '';
          _notesController.text = planting.notes ?? '';
          _imageUrls = planting.imageUrls;
        }
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar plantio: $e')),
        );
      }
    }
  }

  Future<void> _savePlanting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validações adicionais
    if (_cropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma cultura')),
      );
      return;
    }
    
    if (_plotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um talhão')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Processar imagens primeiro utilizando o ImageService
      List<String> processedImages = [];
      try {
        processedImages = await _imageService.processImages(_imageUrls);
        Logger.info('Imagens processadas: ${processedImages.length}');
      } catch (e) {
        Logger.error('Erro ao processar imagens: $e');
        // Em caso de erro, usar as imagens originais
        processedImages = _imageUrls;
      }

      // Extrair valores dos controladores
      final seedRate = double.tryParse(_seedRateController.text) ?? 0.0;
      final seedDepth = _seedDepthController.text.isNotEmpty 
          ? double.tryParse(_seedDepthController.text) 
          : null;
      final rowSpacing = double.tryParse(_spacingController.text) ?? 0.0;
      final area = _areaController.text.isNotEmpty 
          ? double.tryParse(_areaController.text) 
          : null;
      final population = _populationController.text.isNotEmpty
          ? double.tryParse(_populationController.text)
          : null;
      
      // Criar ou atualizar o objeto Planting
      final planting = Planting(
        id: _planting?.id,
        cropId: _cropId!,
        cropVarietyId: _cropVarietyId,
        plotId: _plotId!,
        planterId: _planterId,
        tractorId: _tractorId,
        plantingDate: _plantingDate,
        seedRate: population ?? seedRate,
        seedDepth: seedDepth,
        rowSpacing: rowSpacing,
        area: area,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        imageUrls: processedImages,
      );

      // Salvar no repositório
      if (_planting == null) {
        await _repository.insert(planting);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Plantio registrado com sucesso');
        }
      } else {
        await _repository.update(planting);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Plantio atualizado com sucesso');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao salvar plantio: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.viewOnly) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _plantingDate) {
      setState(() {
        _plantingDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewOnly 
            ? 'Detalhes do Plantio' 
            : (widget.plantingId == null ? 'Novo Plantio' : 'Editar Plantio')),
        actions: [
          // Botão de acesso aos plantios cadastrados
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Meus Plantios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlantingListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cultura
                    CropSelector(
                      initialValue: _crops.isNotEmpty ? ModelConverterUtils.stringToAppCrop(_cropId, _crops) : null,
                      onChanged: (value) {
                        setState(() {
                          _cropId = value.id?.toString();
                          _cropVarietyId = null; // Resetar variedade ao mudar a cultura
                        });
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Variedade
                    if (_cropId != null)
                      CropVarietySelector(
                        cropId: _cropId,
                        initialValue: _cropVarietyId,
                        onChanged: (value) {
                          setState(() {
                            _cropVarietyId = value;
                          });
                        },
                      ),
                    if (_cropId != null)
                      const SizedBox(height: 16),
                    
                    // Talhão
                    PlotSelector(
                      initialValue: _plotId,
                      onChanged: (value) {
                        setState(() {
                          _plotId = value;
                        });
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Plantadeira
                    // PlanterSelector( // Widget removido
                    //   initialValue: _planterId,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _planterId = value;
                    //     });
                    //   },
                    //   label: 'Plantadeira',
                    // ),
                    const SizedBox(height: 16),
                    
                    // Trator
                    // TractorSelector( // Widget removido
                    //   initialValue: _tractorId,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _tractorId = value;
                    //     });
                    //   },
                    //   label: 'Trator',
                    // ),
                    const SizedBox(height: 16),
                    
                    // Data do plantio
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data do Plantio *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          // onTap: () => _selectDate(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_plantingDate),
                                    style: TextStyle(
                                      color: widget.viewOnly ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                ),
                                if (!widget.viewOnly)
                                  const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Taxa de semeadura
                    TextFormField(
                      controller: _seedRateController,
                      decoration: const InputDecoration(
                        labelText: 'Taxa de Semeadura (sementes/ha) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe a taxa de semeadura';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, informe um valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Profundidade da semente
                    TextFormField(
                      controller: _seedDepthController,
                      decoration: const InputDecoration(
                        labelText: 'Profundidade da Semente (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Por favor, informe um valor numérico válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Espaçamento entre linhas
                    TextFormField(
                      controller: _spacingController,
                      decoration: const InputDecoration(
                        labelText: 'Espaçamento entre Linhas (cm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o espaçamento entre linhas';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, informe um valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Área plantada
                    TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área Plantada (ha)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Por favor, informe um valor numérico válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Observações
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: !widget.viewOnly,
                    ),
                    const SizedBox(height: 24),
                    
                    // Seção de upload de imagens
                    OptimizedImageUpload(
                      initialImages: _imageUrls,
                      onImagesChanged: (images) {
                        setState(() {
                          _imageUrls = images;
                        });
                      },
                      enabled: !widget.viewOnly,
                      title: 'Fotos do Plantio',
                      imageQuality: 85,
                      maxWidth: 1200,
                      maxHeight: 1200,
                    ),
                    const SizedBox(height: 24),
                    
                    if (!widget.viewOnly)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _savePlanting,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: Theme.of(context).primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('SALVAR'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
