import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/organism_catalog.dart';
import '../utils/enums.dart';
import '../services/organism_catalog_loader_service.dart';
import '../repositories/organism_catalog_repository.dart';
import '../utils/logger.dart';

class OrganismFormScreen extends StatefulWidget {
  final OrganismCatalog? organism; // Para edição
  final String? cropId;
  final String? cropName;

  const OrganismFormScreen({
    super.key,
    this.organism,
    this.cropId,
    this.cropName,
  });

  @override
  State<OrganismFormScreen> createState() => _OrganismFormScreenState();
}

class _OrganismFormScreenState extends State<OrganismFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowLimitController = TextEditingController();
  final _mediumLimitController = TextEditingController();
  final _highLimitController = TextEditingController();
  final _unitController = TextEditingController();

  OccurrenceType _selectedType = OccurrenceType.pest;
  String _selectedCropId = 'soja';
  String _selectedCropName = 'Soja';
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _availableCrops = [
    'soja', 'milho', 'trigo', 'feijao', 'algodao', 
    'sorgo', 'girassol', 'aveia', 'gergelim'
  ];

  final Map<String, String> _cropNames = {
    'soja': 'Soja',
    'milho': 'Milho',
    'trigo': 'Trigo',
    'feijao': 'Feijão',
    'algodao': 'Algodão',
    'sorgo': 'Sorgo',
    'girassol': 'Girassol',
    'aveia': 'Aveia',
    'gergelim': 'Gergelim',
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.organism != null) {
      // Modo edição
      _nameController.text = widget.organism!.name;
      _scientificNameController.text = widget.organism!.scientificName;
      _descriptionController.text = widget.organism!.description ?? '';
      _lowLimitController.text = widget.organism!.lowLimit.toString();
      _mediumLimitController.text = widget.organism!.mediumLimit.toString();
      _highLimitController.text = widget.organism!.highLimit.toString();
      _unitController.text = widget.organism!.unit;
      _selectedType = widget.organism!.type;
      _selectedCropId = widget.organism!.cropId;
      _selectedCropName = widget.organism!.cropName;
    } else {
      // Modo criação
      if (widget.cropId != null) {
        _selectedCropId = widget.cropId!;
        _selectedCropName = widget.cropName ?? _cropNames[widget.cropId!] ?? 'Soja';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _lowLimitController.dispose();
    _mediumLimitController.dispose();
    _highLimitController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveOrganism() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final organism = OrganismCatalog(
        id: widget.organism?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        scientificName: _scientificNameController.text.trim(),
        type: _selectedType,
        cropId: _selectedCropId,
        cropName: _selectedCropName,
        unit: _unitController.text.trim(),
        lowLimit: int.tryParse(_lowLimitController.text) ?? 0,
        mediumLimit: int.tryParse(_mediumLimitController.text) ?? 0,
        highLimit: int.tryParse(_highLimitController.text) ?? 0,
        description: _descriptionController.text.trim(),
        isActive: true,
        createdAt: widget.organism?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = OrganismCatalogRepository();
      await repository.initialize();

      if (widget.organism != null) {
        // Atualizar organismo existente
        await repository.update(organism);
        Logger.info('✅ Organismo atualizado: ${organism.name}');
      } else {
        // Criar novo organismo
        await repository.create(organism);
        Logger.info('✅ Organismo criado: ${organism.name}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.organism != null 
                ? 'Organismo atualizado com sucesso!' 
                : 'Organismo criado com sucesso!'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      Logger.error('❌ Erro ao salvar organismo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar organismo: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.organism != null ? 'Editar Organismo' : 'Novo Organismo',
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações básicas
              _buildSectionTitle('Informações Básicas'),
              const SizedBox(height: 16),
              
              // Nome comum
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome comum *',
                  hintText: 'Ex: Lagarta-da-soja',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome comum é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nome científico
              TextFormField(
                controller: _scientificNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome científico',
                  hintText: 'Ex: Anticarsia gemmatalis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo
              DropdownButtonFormField<OccurrenceType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: OccurrenceType.values.map((type) {
                  String label;
                  switch (type) {
                    case OccurrenceType.pest:
                      label = 'Praga';
                      break;
                    case OccurrenceType.disease:
                      label = 'Doença';
                      break;
                    case OccurrenceType.weed:
                      label = 'Planta Daninha';
                      break;
                    case OccurrenceType.deficiency:
                      label = 'Deficiência';
                      break;
                    case OccurrenceType.other:
                      label = 'Outro';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Cultura
              DropdownButtonFormField<String>(
                value: _selectedCropId,
                decoration: const InputDecoration(
                  labelText: 'Cultura *',
                  border: OutlineInputBorder(),
                ),
                items: _availableCrops.map((cropId) {
                  return DropdownMenuItem(
                    value: cropId,
                    child: Text(_cropNames[cropId] ?? cropId),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCropId = value;
                      _selectedCropName = _cropNames[value] ?? value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Limites de controle
              _buildSectionTitle('Limites de Controle'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lowLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Limite Baixo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obrigatório';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _mediumLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Limite Médio',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obrigatório';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _highLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Limite Alto',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obrigatório';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unidade
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unidade de Medida *',
                  hintText: 'Ex: indivíduos/ponto, % folhas, plantas/m²',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unidade é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Descrição
              _buildSectionTitle('Descrição'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva os sintomas, danos econômicos, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Imagem
              _buildSectionTitle('Imagem'),
              const SizedBox(height: 16),

              if (_selectedImage != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Nenhuma imagem selecionada'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Selecionar Imagem'),
              ),
              const SizedBox(height: 32),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrganism,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.organism != null ? 'Atualizar Organismo' : 'Criar Organismo',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green[700],
      ),
    );
  }
}
