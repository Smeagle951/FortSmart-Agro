import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/crop_variety.dart';
import '../../repositories/crop_variety_repository.dart';
import '../../models/crop.dart' as app_crop;
import '../../database/models/crop.dart' as db_crop;
import '../../repositories/crop_repository.dart';

class CropVarietyFormScreen extends StatefulWidget {
  final String? varietyId;
  final String? cropId;
  final bool viewOnly;

  const CropVarietyFormScreen({
    Key? key,
    this.varietyId,
    this.cropId,
    this.viewOnly = false,
  }) : super(key: key);

  @override
  State<CropVarietyFormScreen> createState() => _CropVarietyFormScreenState();
}

class _CropVarietyFormScreenState extends State<CropVarietyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _varietyRepository = CropVarietyRepository();
  final _cropRepository = CropRepository();
  
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // Form fields
  String? _cropId;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cycleController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Loaded data
  CropVariety? _variety;
  List<app_crop.Crop> _crops = [];

  @override
  void initState() {
    super.initState();
    print('🔍 CropVarietyFormScreen inicializada');
    print('🔍 Variety ID: ${widget.varietyId}');
    print('🔍 Crop ID: ${widget.cropId}');
    print('🔍 View Only: ${widget.viewOnly}');
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cycleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Carregar culturas
      final dbCrops = await _cropRepository.getAll();
      
      // Converter de db_crop.Crop para app_crop.Crop
      _crops = dbCrops.map((dbCrop) => app_crop.Crop(
        id: dbCrop.id,
        name: dbCrop.name,
        scientificName: dbCrop.scientificName,
        description: dbCrop.description,
        growthCycle: dbCrop.growthCycle,
        plantSpacing: dbCrop.plantSpacing,
        rowSpacing: dbCrop.rowSpacing,
        plantingDepth: dbCrop.plantingDepth,
        idealTemperature: dbCrop.idealTemperature,
        waterRequirement: dbCrop.waterRequirement,
        isSynced: dbCrop.syncStatus > 0,
        isDefault: dbCrop.isDefault,
      )).toList();
      
      // Se foi fornecido um ID de cultura, usar como padrão
      if (widget.cropId != null) {
        _cropId = widget.cropId;
      }
      
      // Se foi fornecido um ID de variedade, carregar os dados
      if (widget.varietyId != null) {
        _variety = await _varietyRepository.getById(widget.varietyId!);
        if (_variety != null) {
          _cropId = _variety!.cropId;
          _nameController.text = _variety!.name;
          _descriptionController.text = _variety!.description ?? '';
          _cycleController.text = _variety!.cycleDays?.toString() ?? '';
          _notesController.text = _variety!.notes ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _saveVariety() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma cultura')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cycleDays = _cycleController.text.isNotEmpty 
          ? int.tryParse(_cycleController.text) 
          : null;
          
      final variety = CropVariety(
        id: _variety?.id ?? const Uuid().v4(),
        cropId: _cropId!,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        cycleDays: cycleDays,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (_variety == null) {
        await _varietyRepository.insert(variety);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Variedade cadastrada com sucesso')),
          );
        }
      } else {
        await _varietyRepository.update(variety);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Variedade atualizada com sucesso')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar variedade: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewOnly 
            ? 'Detalhes da Variedade' 
            : (widget.varietyId == null ? 'Nova Variedade' : 'Editar Variedade')),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cultura *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cropId,
                              isExpanded: true,
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Selecione uma cultura'),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              onChanged: widget.viewOnly 
                                  ? null 
                                  : (String? newValue) {
                                      setState(() {
                                        _cropId = newValue;
                                      });
                                    },
                              items: _crops.map<DropdownMenuItem<String>>((app_crop.Crop crop) {
                                return DropdownMenuItem<String>(
                                  value: crop.id?.toString(),
                                  child: Text(crop.name),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Variedade *',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o nome da variedade';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !widget.viewOnly,
                    ),
                    const SizedBox(height: 16),
                    
                    // Ciclo em dias
                    TextFormField(
                      controller: _cycleController,
                      decoration: const InputDecoration(
                        labelText: 'Ciclo (dias)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Por favor, informe um número válido';
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
                    
                    if (!widget.viewOnly)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveVariety,
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
