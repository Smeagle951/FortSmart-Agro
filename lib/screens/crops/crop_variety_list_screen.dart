import 'package:flutter/material.dart';
import '../../models/crop_variety.dart';
import '../../repositories/crop_variety_repository.dart';
import '../../models/crop.dart' as app_crop;
import '../../database/models/crop.dart' as db_crop;
import '../../repositories/crop_repository.dart';
import 'crop_variety_form_screen.dart';

class CropVarietyListScreen extends StatefulWidget {
  final String? cropId;
  final String? cropName;

  const CropVarietyListScreen({
    Key? key,
    this.cropId,
    this.cropName,
  }) : super(key: key);

  @override
  State<CropVarietyListScreen> createState() => _CropVarietyListScreenState();
}

class _CropVarietyListScreenState extends State<CropVarietyListScreen> {
  final _varietyRepository = CropVarietyRepository();
  final _cropRepository = CropRepository();
  
  bool _isLoading = true;
  List<CropVariety> _varieties = [];
  List<app_crop.Crop> _crops = [];
  String? _selectedCropId;
  String? _selectedCropName;

  @override
  void initState() {
    super.initState();
    _selectedCropId = widget.cropId;
    _selectedCropName = widget.cropName;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar culturas
      final dbCrops = await _cropRepository.getAll();
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

      // Se não foi selecionada uma cultura, usar a primeira
      if (_selectedCropId == null && _crops.isNotEmpty) {
        _selectedCropId = _crops.first.id.toString();
        _selectedCropName = _crops.first.name;
      }

      // Carregar variedades da cultura selecionada
      if (_selectedCropId != null) {
        await _loadVarieties();
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVarieties() async {
    if (_selectedCropId == null) return;

    try {
      final varieties = await _varietyRepository.getByCropId(_selectedCropId!);
      setState(() {
        _varieties = varieties;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar variedades: $e')),
        );
      }
    }
  }

  Future<void> _deleteVariety(CropVariety variety) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir a variedade "${variety.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _varietyRepository.delete(variety.id);
        await _loadVarieties();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Variedade excluída com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir variedade: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCropName != null 
            ? 'Variedades - $_selectedCropName' 
            : 'Variedades'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Filtro de cultura
          if (_crops.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (cropId) async {
                final crop = _crops.firstWhere((c) => c.id.toString() == cropId);
                setState(() {
                  _selectedCropId = cropId;
                  _selectedCropName = crop.name;
                });
                await _loadVarieties();
              },
              itemBuilder: (context) => _crops.map((crop) => PopupMenuItem(
                value: crop.id.toString(),
                child: Text(crop.name),
              )).toList(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.filter_list),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtro de cultura (alternativo)
                if (_crops.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCropId,
                      decoration: const InputDecoration(
                        labelText: 'Cultura',
                        border: OutlineInputBorder(),
                      ),
                      items: _crops.map((crop) => DropdownMenuItem(
                        value: crop.id.toString(),
                        child: Text(crop.name),
                      )).toList(),
                      onChanged: (cropId) async {
                        if (cropId != null) {
                          final crop = _crops.firstWhere((c) => c.id.toString() == cropId);
                          setState(() {
                            _selectedCropId = cropId;
                            _selectedCropName = crop.name;
                          });
                          await _loadVarieties();
                        }
                      },
                    ),
                  ),
                
                // Lista de variedades
                Expanded(
                  child: _varieties.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grain,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma variedade encontrada',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Adicione uma nova variedade para esta cultura',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _varieties.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final variety = _varieties[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.grain, color: Colors.green),
                                title: Text(
                                  variety.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (variety.description?.isNotEmpty == true)
                                      Text(variety.description!),
                                    if (variety.cycleDays != null)
                                      Text('Ciclo: ${variety.cycleDays} dias'),
                                    if (variety.company?.isNotEmpty == true)
                                      Text('Empresa: ${variety.company}'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    switch (action) {
                                      case 'edit':
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CropVarietyFormScreen(
                                              varietyId: variety.id,
                                              cropId: variety.cropId,
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          await _loadVarieties();
                                        }
                                        break;
                                      case 'delete':
                                        await _deleteVariety(variety);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Excluir', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CropVarietyFormScreen(
                                        varietyId: variety.id,
                                        cropId: variety.cropId,
                                        viewOnly: true,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadVarieties();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropVarietyFormScreen(
                cropId: _selectedCropId,
              ),
            ),
          );
          if (result == true) {
            await _loadVarieties();
          }
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
} 