import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/enhanced_culture_management_service.dart';
import '../models/crop_variety.dart';
import '../utils/logger.dart';

/// Widget para gerenciar variedades desenvolvidas
class DevelopedVarietyManager extends StatefulWidget {
  final int cropId;
  final String cropName;

  const DevelopedVarietyManager({
    Key? key,
    required this.cropId,
    required this.cropName,
  }) : super(key: key);

  @override
  State<DevelopedVarietyManager> createState() => _DevelopedVarietyManagerState();
}

class _DevelopedVarietyManagerState extends State<DevelopedVarietyManager> {
  final EnhancedCultureManagementService _service = EnhancedCultureManagementService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  List<CropVariety> _varieties = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVarieties();
  }

  Future<void> _loadVarieties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final varieties = await _service.getVarietiesByCrop(widget.cropId);
      
      setState(() {
        _varieties = varieties;
      });
      
      Logger.info('✅ ${varieties.length} variedades carregadas para ${widget.cropName}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar variedades: $e';
      });
      Logger.error('❌ Erro ao carregar variedades: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Variedades de ${widget.cropName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddVarietyDialog,
            tooltip: 'Adicionar Variedade',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVarietyDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.grass, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVarieties,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_varieties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grass, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma variedade desenvolvida',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no botão + para adicionar variedades',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _varieties.length,
      itemBuilder: (context, index) {
        final variety = _varieties[index];
        return _buildVarietyCard(variety, index);
      },
    );
  }

  Widget _buildVarietyCard(CropVariety variety, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showVarietyDetails(variety),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da variedade
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grass, color: Colors.blue, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variety.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (variety.description.isNotEmpty)
                          Text(
                            variety.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleVarietyAction(value, variety),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('Ver Detalhes'),
                          ],
                        ),
                      ),
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
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Excluir'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Características da variedade
              if (variety.characteristics.isNotEmpty)
                _buildCharacteristicItem('Características', variety.characteristics),
              
              if (variety.yield > 0)
                _buildCharacteristicItem('Produtividade', '${variety.yield.toStringAsFixed(1)} kg/ha'),
              
              if (variety.maturity > 0)
                _buildCharacteristicItem('Ciclo', '${variety.maturity} dias'),
              
              if (variety.resistance.isNotEmpty)
                _buildCharacteristicItem('Resistência', variety.resistance),
              
              const SizedBox(height: 16),
              
              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: 'Detalhes',
                    color: Colors.blue,
                    onTap: () => _showVarietyDetails(variety),
                  ),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Editar',
                    color: Colors.orange,
                    onTap: () => _showEditVarietyDialog(variety),
                  ),
                  _buildActionButton(
                    icon: Icons.photo_camera,
                    label: 'Fotos',
                    color: Colors.green,
                    onTap: () => _showVarietyPhotos(variety),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacteristicItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVarietyDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVarietyDialog(
        cropId: widget.cropId,
        cropName: widget.cropName,
        onSave: (variety) async {
          await _addVariety(variety);
        },
      ),
    );
  }

  Future<void> _addVariety(Map<String, dynamic> varietyData) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _service.addDevelopedVariety(
        cropId: widget.cropId,
        cropName: widget.cropName,
        varietyName: varietyData['name'],
        description: varietyData['description'],
        characteristics: varietyData['characteristics'],
        yield: varietyData['yield'],
        maturity: varietyData['maturity'],
        resistance: varietyData['resistance'],
        imageFile: varietyData['imageFile'],
      );
      
      if (result['success']) {
        Logger.info('✅ Variedade adicionada: ${result['varietyName']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variedade "${result['varietyName']}" adicionada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        await _loadVarieties();
      } else {
        Logger.error('❌ Erro ao adicionar variedade: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao adicionar variedade: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao adicionar variedade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar variedade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVarietyDetails(CropVariety variety) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grass, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        variety.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (variety.description.isNotEmpty) ...[
                        const Text(
                          'Descrição:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(variety.description),
                        const SizedBox(height: 16),
                      ],
                      
                      if (variety.characteristics.isNotEmpty) ...[
                        const Text(
                          'Características:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(variety.characteristics),
                        const SizedBox(height: 16),
                      ],
                      
                      if (variety.yield > 0) ...[
                        const Text(
                          'Produtividade:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('${variety.yield.toStringAsFixed(1)} kg/ha'),
                        const SizedBox(height: 16),
                      ],
                      
                      if (variety.maturity > 0) ...[
                        const Text(
                          'Ciclo:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('${variety.maturity} dias'),
                        const SizedBox(height: 16),
                      ],
                      
                      if (variety.resistance.isNotEmpty) ...[
                        const Text(
                          'Resistência:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(variety.resistance),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditVarietyDialog(CropVariety variety) {
    // Implementar edição de variedade
    Logger.info('Editando variedade: ${variety.name}');
  }

  void _showVarietyPhotos(CropVariety variety) {
    // Implementar visualização de fotos da variedade
    Logger.info('Mostrando fotos da variedade: ${variety.name}');
  }

  void _handleVarietyAction(String action, CropVariety variety) {
    switch (action) {
      case 'view':
        _showVarietyDetails(variety);
        break;
      case 'edit':
        _showEditVarietyDialog(variety);
        break;
      case 'delete':
        _showDeleteVarietyDialog(variety);
        break;
    }
  }

  void _showDeleteVarietyDialog(CropVariety variety) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Variedade'),
        content: Text('Tem certeza que deseja excluir a variedade "${variety.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVariety(variety);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVariety(CropVariety variety) async {
    // Implementar exclusão de variedade
    Logger.info('Excluindo variedade: ${variety.name}');
  }
}

/// Diálogo para adicionar variedade
class _AddVarietyDialog extends StatefulWidget {
  final int cropId;
  final String cropName;
  final Function(Map<String, dynamic>) onSave;

  const _AddVarietyDialog({
    required this.cropId,
    required this.cropName,
    required this.onSave,
  });

  @override
  State<_AddVarietyDialog> createState() => _AddVarietyDialogState();
}

class _AddVarietyDialogState extends State<_AddVarietyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _characteristicsController = TextEditingController();
  final _yieldController = TextEditingController();
  final _maturityController = TextEditingController();
  final _resistanceController = TextEditingController();
  
  XFile? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Adicionar Variedade Desenvolvida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Nome da variedade
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Variedade',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome é obrigatório';
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
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Características
                      TextFormField(
                        controller: _characteristicsController,
                        decoration: const InputDecoration(
                          labelText: 'Características',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Produtividade e Ciclo
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yieldController,
                              decoration: const InputDecoration(
                                labelText: 'Produtividade (kg/ha)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maturityController,
                              decoration: const InputDecoration(
                                labelText: 'Ciclo (dias)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Resistência
                      TextFormField(
                        controller: _resistanceController,
                        decoration: const InputDecoration(
                          labelText: 'Resistência',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Imagem
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Nenhuma imagem selecionada'),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Botão para selecionar imagem
                      ElevatedButton.icon(
                        onPressed: _selectImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Selecionar Imagem'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _saveVariety,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Salvar Variedade', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      Logger.error('❌ Erro ao selecionar imagem: $e');
    }
  }

  void _saveVariety() {
    if (_formKey.currentState!.validate()) {
      final varietyData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'characteristics': _characteristicsController.text,
        'yield': double.tryParse(_yieldController.text) ?? 0.0,
        'maturity': int.tryParse(_maturityController.text) ?? 0,
        'resistance': _resistanceController.text,
        'imageFile': _imageFile,
      };
      
      widget.onSave(varietyData);
      Navigator.of(context).pop();
    }
  }
}
