import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/models/pest.dart';
import '../database/models/crop.dart';
import '../services/crop_service.dart';
import '../services/praga_image_service.dart';
import 'pest_edit_screen.dart';

class PestListScreen extends StatefulWidget {
  const PestListScreen({Key? key}) : super(key: key);

  @override
  _PestListScreenState createState() => _PestListScreenState();
}

class _PestListScreenState extends State<PestListScreen> {
  final CropService _cropService = CropService();
  List<Pest> _pests = [];
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
        await _loadPests(_selectedCrop!.id);
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

  Future<void> _loadPests(int cropId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pests = await _cropService.getPestsByCropId(cropId);
      setState(() {
        _pests = pests;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pragas: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadPragaImagesForPests(List<Pest> pests) async {
    try {
      final List<Map<String, dynamic>> images = [];
      for (final pest in pests) {
        if (pest.id != null) {
          final pragaImages = await PragaImageService.getPragaImagesByPest(pest.id!);
          if (pragaImages.isNotEmpty) {
            final pragaImage = pragaImages.first;
            images.add({
              'id': pragaImage.id,
              'pestId': pest.id,
              'imageBase64': pragaImage.imageBase64,
              'colorHex': pragaImage.colorHex,
            });
          }
        }
      }
      return images;
    } catch (e) {
      print('Erro ao carregar imagens das pragas: $e');
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
      appBar: AppBar(
        title: const Text('Pragas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                      prefixIcon: Icon(Icons.agriculture),
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
                        _loadPests(value.id);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _selectedCrop == null
                      ? const Center(
                          child: Text('Selecione uma cultura para ver as pragas'),
                        )
                      : _pests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bug_report,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma praga encontrada para ${_selectedCrop!.name}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PestEditScreen(
                                            cropId: _selectedCrop!.id,
                                          ),
                                        ),
                                      ).then((_) => _loadPests(_selectedCrop!.id));
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adicionar Praga'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _pests.length,
                              itemBuilder: (context, index) {
                                final pest = _pests[index];
                                return FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadPragaImagesForPests([pest]),
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
                                        title: Text(pest.name),
                                        subtitle: Text(pest.scientificName),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (pragaImage.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () => _editPragaImage(pragaImage['id']),
                                                tooltip: 'Editar imagem',
                                              ),
                                            // Botões de desenvolvimento removidos para produção
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/pest/details',
                                            arguments: pest.id,
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
                    builder: (context) => PestEditScreen(
                      cropId: _selectedCrop!.id,
                    ),
                  ),
                ).then((_) => _loadPests(_selectedCrop!.id));
              },
              child: const Icon(Icons.add),
              // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
            )
          : null,
    );
  }

  void _showDeleteConfirmation(Pest pest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a praga "${pest.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _cropService.deletePest(pest.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Praga excluída com sucesso')),
                );
                if (_selectedCrop != null) {
                  _loadPests(_selectedCrop!.id);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir praga: $e')),
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
