import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/models/crop.dart';
import '../services/crop_service.dart';
import '../services/praga_image_service.dart';
import 'disease_edit_screen.dart';
import '../models/disease.dart';

class DiseaseListScreen extends StatefulWidget {
  const DiseaseListScreen({Key? key}) : super(key: key);

  @override
  _DiseaseListScreenState createState() => _DiseaseListScreenState();
}

class _DiseaseListScreenState extends State<DiseaseListScreen> {
  final CropService _cropService = CropService();
  List<Disease> _diseases = [];
  List<Crop> _crops = [];
  Crop? _selectedCrop;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final crops = await _cropService.getAllCrops();
      
      setState(() {
        _crops = crops;
        if (crops.isNotEmpty && _selectedCrop == null) {
          _selectedCrop = crops.first;
        }
      });
      
      if (_selectedCrop != null) {
        await _loadDiseases(_selectedCrop!.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDiseases(int cropId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final dbDiseases = await _cropService.getDiseasesByCropId(cropId);
      final diseases = dbDiseases.map((dbDisease) => Disease.fromDbModel(dbDisease)).toList();
      
      setState(() {
        _diseases = diseases;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar doenças: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadPragaImagesForDiseases(List<Disease> diseases) async {
    try {
      final List<Map<String, dynamic>> images = [];
      for (final disease in diseases) {
        if (disease.id != null) {
          final pragaImages = await PragaImageService.getPragaImagesByDisease(disease.id!);
          if (pragaImages.isNotEmpty) {
            final pragaImage = pragaImages.first;
            images.add({
              'id': pragaImage.id,
              'diseaseId': disease.id,
              'imageBase64': pragaImage.imageBase64,
              'colorHex': pragaImage.colorHex,
            });
          }
        }
      }
      return images;
    } catch (e) {
      print('Erro ao carregar imagens das doenças: $e');
      return [];
    }
  }

  Widget _buildPragaImageWidget(Map<String, dynamic> pragaImage) {
    if (pragaImage.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
        ),
      );
    }

    final imageBase64 = pragaImage['imageBase64'] as String?;
    final colorHex = pragaImage['colorHex'] as String?;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorHex != null ? Color(int.parse(colorHex.replaceFirst('#', '0xff'))) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: imageBase64 != null && imageBase64.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                base64Decode(imageBase64),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          : const Icon(
              Icons.image,
              color: Colors.white,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4F3D),
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Doenças',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<Crop>(
                    decoration: const InputDecoration(
                      labelText: 'Selecione a Cultura',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.agriculture, color: Color(0xFF2A4F3D)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2A4F3D), width: 2),
                      ),
                    ),
                    value: _selectedCrop,
                    items: _crops.map((crop) {
                      return DropdownMenuItem<Crop>(
                        value: crop,
                        child: Text(crop.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCrop = value;
                        });
                        _loadDiseases(value.id);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _selectedCrop == null
                      ? const Center(
                          child: Text('Selecione uma cultura para ver as doenças'),
                        )
                      : _diseases.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A4F3D).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.coronavirus,
                                      size: 64,
                                      color: Color(0xFF2A4F3D),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma doença encontrada para ${_selectedCrop!.name}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DiseaseEditScreen(
                                            cropId: _selectedCrop!.id,
                                          ),
                                        ),
                                      ).then((_) => _loadDiseases(_selectedCrop!.id));
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adicionar Doença'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2A4F3D),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _diseases.length,
                              itemBuilder: (context, index) {
                                final disease = _diseases[index];
                                return FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadPragaImagesForDiseases([disease]),
                                  builder: (context, snapshot) {
                                    final pragaImages = snapshot.data ?? [];
                                    final pragaImage = pragaImages.isNotEmpty ? pragaImages.first : <String, dynamic>{};

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        leading: _buildPragaImageWidget(pragaImage),
                                        title: Text(disease.name),
                                        subtitle: disease.scientificName != null && disease.scientificName!.isNotEmpty
                                          ? Text(disease.scientificName!)
                                          : null,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (pragaImage.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () => _editPragaImage(pragaImage['id']),
                                                tooltip: 'Editar imagem',
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => DiseaseEditScreen(
                                                      disease: _diseases[index],
                                                      cropId: _selectedCrop!.id,
                                                    ),
                                                  ),
                                                ).then((_) => _loadDiseases(_selectedCrop!.id));
                                              },
                                            ),
                                            if (!disease.isDefault)
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () {
                                                  _showDeleteConfirmation(disease);
                                                },
                                              ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/disease/details',
                                            arguments: disease.id,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: _selectedCrop != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiseaseEditScreen(
                      cropId: _selectedCrop!.id,
                    ),
                  ),
                ).then((_) => _loadDiseases(_selectedCrop!.id));
              },
              child: const Icon(Icons.add),
              backgroundColor: const Color(0xFF2A4F3D),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showDeleteConfirmation(Disease disease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a doença "${disease.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _cropService.deleteDisease(disease.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doença excluída com sucesso')),
                );
                if (_selectedCrop != null) {
                  _loadDiseases(_selectedCrop!.id);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir doença: $e')),
                );
              }
            },
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _editPragaImage(int? imageId) {
    if (imageId == null) return;
    
    // Implementar edição de imagem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
    );
  }
}
