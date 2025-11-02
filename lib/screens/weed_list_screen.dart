import 'package:flutter/material.dart';
import '../database/models/crop.dart';
import '../services/crop_service.dart';
import 'weed_edit_screen.dart';
import '../models/weed.dart';

class WeedListScreen extends StatefulWidget {
  const WeedListScreen({Key? key}) : super(key: key);

  @override
  _WeedListScreenState createState() => _WeedListScreenState();
}

class _WeedListScreenState extends State<WeedListScreen> {
  final CropService _cropService = CropService();
  List<Weed> _weeds = [];
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
        await _loadWeeds(_selectedCrop!.id);
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

  Future<void> _loadWeeds(int cropId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final dbWeeds = await _cropService.getWeedsByCropId(cropId);
      final weeds = dbWeeds.map((dbWeed) => Weed.fromDbModel(dbWeed)).toList();
      
      setState(() {
        _weeds = weeds;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar plantas daninhas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantas Daninhas'),
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
                        _loadWeeds(value.id);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _selectedCrop == null
                      ? const Center(
                          child: Text('Selecione uma cultura para ver as plantas daninhas'),
                        )
                      : _weeds.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.grass,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma planta daninha encontrada para ${_selectedCrop!.name}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WeedEditScreen(
                                            cropId: _selectedCrop!.id,
                                          ),
                                        ),
                                      ).then((_) => _loadWeeds(_selectedCrop!.id));
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adicionar Planta Daninha'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _weeds.length,
                              itemBuilder: (context, index) {
                                final weed = _weeds[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      // backgroundColor: Colors.brown, // backgroundColor não é suportado em flutter_map 5.0.0
                                      child: Icon(
                                        Icons.grass,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(weed.name),
                                    subtitle: weed.scientificName != null && weed.scientificName!.isNotEmpty
                                      ? Text(weed.scientificName!)
                                      : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Botões de desenvolvimento removidos para produção
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/weed_details',
                                        arguments: weed.id,
                                      );
                                    },
                                  ),
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
                    builder: (context) => WeedEditScreen(
                      cropId: _selectedCrop!.id,
                    ),
                  ),
                ).then((_) => _loadWeeds(_selectedCrop!.id));
              },
              child: const Icon(Icons.add),
              // backgroundColor: Colors.brown, // backgroundColor não é suportado em flutter_map 5.0.0
            )
          : null,
    );
  }

  void _showDeleteConfirmation(Weed weed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a planta daninha "${weed.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _cropService.deleteWeed(weed.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Planta daninha excluída com sucesso')),
                );
                if (_selectedCrop != null) {
                  _loadWeeds(_selectedCrop!.id);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir planta daninha: $e')),
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
}
