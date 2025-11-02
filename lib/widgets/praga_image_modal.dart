import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/crop.dart';
import '../models/pest.dart';
import '../models/disease.dart';
import '../services/culture_import_service.dart';

class PragaImageModal extends StatefulWidget {
  final Function(File? imageFile, String colorHex, int? cropId, int? pestId, int? diseaseId) onSave;

  const PragaImageModal({super.key, required this.onSave});

  @override
  State<PragaImageModal> createState() => _PragaImageModalState();
}

class _PragaImageModalState extends State<PragaImageModal> {
  final CultureImportService _cultureImportService = CultureImportService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  String _selectedColor = '#FF6B35';
  int? _selectedCropId;
  int? _selectedPestId;
  int? _selectedDiseaseId;
  
  List<Crop> _culturas = [];
  List<Pest> _pragas = [];
  List<Disease> _doencas = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> suggestedColors = [
    '#FF6B35', '#FF4F79', '#FFA500', '#FF8533', '#FF5C5C',
    '#00CC66', '#00C0C0', '#4B77BE', '#CC66FF', '#FFD700',
    '#A0522D', '#8B4513', '#00A86B', '#66CDAA', '#E34234',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Inicializar o serviço de importação
      await _cultureImportService.initialize();
      
      // Carregar culturas
      final culturas = await _cultureImportService.getAllCrops();
      
      setState(() {
        _culturas = culturas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPragas(int cropId) async {
    try {
      final pragas = await _cultureImportService.getPestsByCrop(cropId);
      setState(() {
        _pragas = pragas;
        _selectedPestId = null;
        _selectedDiseaseId = null;
        _doencas = [];
      });
    } catch (e) {
      setState(() {
        _pragas = [];
        _errorMessage = 'Erro ao carregar pragas: $e';
      });
    }
  }

  Future<void> _loadDoencas(int cropId) async {
    try {
      final doencas = await _cultureImportService.getDiseasesByCrop(cropId);
      setState(() {
        _doencas = doencas;
        _selectedDiseaseId = null;
        _selectedPestId = null;
        _pragas = [];
      });
    } catch (e) {
      setState(() {
        _doencas = [];
        _errorMessage = 'Erro ao carregar doenças: $e';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source, 
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorPicker() {
    Color currentColor = Color(int.parse(_selectedColor.replaceFirst('#', '0xff')));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎨 Escolha a cor'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              });
              Navigator.of(context).pop();
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

  void _saveConfiguration() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma imagem'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    widget.onSave(_selectedImage, _selectedColor, _selectedCropId, _selectedPestId, _selectedDiseaseId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.landscape, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Icon(Icons.image, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Upload de Imagem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      )
                    else ...[
                      // Seção de Filtros
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.search, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Filtros',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Seletor de Cultura
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Cultura',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.agriculture),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              value: _selectedCropId?.toString(),
                              hint: const Text('Selecione uma cultura'),
                              isExpanded: true,
                              items: _culturas.map((crop) {
                                return DropdownMenuItem<String>(
                                  value: crop.id.toString(),
                                  child: Text(
                                    crop.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedCropId = value != null ? int.parse(value) : null;
                                  _selectedPestId = null;
                                  _selectedDiseaseId = null;
                                  _pragas = [];
                                  _doencas = [];
                                });
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Botões para Pragas e Doenças
                            if (_selectedCropId != null) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _loadPragas(_selectedCropId!),
                                      icon: const Icon(Icons.bug_report, size: 16),
                                      label: const Text('Pragas', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade100,
                                        foregroundColor: Colors.orange.shade800,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _loadDoencas(_selectedCropId!),
                                      icon: const Icon(Icons.healing, size: 16),
                                      label: const Text('Doenças', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade100,
                                        foregroundColor: Colors.red.shade800,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Seletor de Praga ou Doença
                              if (_pragas.isNotEmpty || _doencas.isNotEmpty) ...[
                                if (_pragas.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Praga',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.bug_report),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    value: _selectedPestId?.toString(),
                                    hint: const Text('Selecione uma praga'),
                                    isExpanded: true,
                                    items: _pragas.map((pest) {
                                      return DropdownMenuItem<String>(
                                        value: pest.id.toString(),
                                        child: Text(
                                          pest.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedPestId = value != null ? int.parse(value) : null;
                                        _selectedDiseaseId = null;
                                      });
                                    },
                                  ),
                                
                                if (_doencas.isNotEmpty) ...[
                                  if (_pragas.isNotEmpty) const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Doença',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.healing),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    value: _selectedDiseaseId?.toString(),
                                    hint: const Text('Selecione uma doença'),
                                    isExpanded: true,
                                    items: _doencas.map((disease) {
                                      return DropdownMenuItem<String>(
                                        value: disease.id.toString(),
                                        child: Text(
                                          disease.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedDiseaseId = value != null ? int.parse(value) : null;
                                        _selectedPestId = null;
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Seção de Imagem
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.camera_alt, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Imagem',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image, size: 32, color: Colors.grey),
                                          SizedBox(height: 4),
                                          Text(
                                            'Sem imagem',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library, size: 16),
                                    label: const Text('Galeria', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade100,
                                      foregroundColor: Colors.blue.shade800,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('Câmera', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade100,
                                      foregroundColor: Colors.green.shade800,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Seção de Cor
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.palette, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cor de Identificação',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Text(
                              'Cor atual: $_selectedColor',
                              style: const TextStyle(fontSize: 14),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Cores sugeridas
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: suggestedColors.map((hex) {
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedColor = hex),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(hex.replaceFirst('#', '0xff'))),
                                      border: Border.all(
                                        color: _selectedColor == hex ? Colors.black : Colors.transparent,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _selectedColor == hex
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Campo de código hexadecimal
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Código Hexadecimal',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.color_lens),
                              ),
                              controller: TextEditingController(text: _selectedColor),
                              onChanged: (val) => setState(() => _selectedColor = val),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showColorPicker,
                                icon: const Icon(Icons.palette, size: 16),
                                label: const Text('Abrir Seletor de Cores', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade100,
                                  foregroundColor: Colors.purple.shade800,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedImage != null ? _saveConfiguration : null,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Salvar', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 