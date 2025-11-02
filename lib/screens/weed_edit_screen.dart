import 'package:flutter/material.dart';
import '../models/weed.dart';
import '../services/crop_service.dart';

class WeedEditScreen extends StatefulWidget {
  final Weed? weed;
  final int cropId;

  const WeedEditScreen({Key? key, this.weed, required this.cropId}) : super(key: key);

  @override
  _WeedEditScreenState createState() => _WeedEditScreenState();
}

class _WeedEditScreenState extends State<WeedEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _controlMethodsController = TextEditingController();
  
  final CropService _cropService = CropService();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDefault = true;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.weed != null;
    
    if (_isEditing) {
      _nameController.text = widget.weed!.name;
      _scientificNameController.text = widget.weed!.scientificName ?? '';
      _descriptionController.text = widget.weed!.description ?? '';
      _controlMethodsController.text = widget.weed!.controlMethods ?? '';
      _isDefault = widget.weed!.isDefault;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _controlMethodsController.dispose();
    super.dispose();
  }
  
  Future<void> _saveWeed() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final weed = _isEditing
          ? Weed(
              id: widget.weed!.id,
              name: _nameController.text,
              scientificName: _scientificNameController.text,
              description: _descriptionController.text,
              controlMethods: _controlMethodsController.text,
              isDefault: _isDefault,
              isSynced: false, // Marcar para sincronização
              cropIds: widget.weed!.cropIds,
            )
          : Weed(
              name: _nameController.text,
              scientificName: _scientificNameController.text,
              description: _descriptionController.text,
              controlMethods: _controlMethodsController.text,
              cropIds: [widget.cropId],
              isDefault: false, // Novas plantas daninhas adicionadas pelo usuário não são padrão
            );
      
      await _cropService.saveWeed(weed.toDbModel());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Planta daninha atualizada com sucesso'
              : 'Planta daninha adicionada com sucesso'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar planta daninha: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
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
        title: Text(_isEditing ? 'Editar Planta Daninha' : 'Nova Planta Daninha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWeed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Planta Daninha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grass),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome da planta daninha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _scientificNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Científico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.science),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome científico';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _controlMethodsController,
                      decoration: const InputDecoration(
                        labelText: 'Métodos de Controle',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pest_control),
                      ),
                      maxLines: 3,
                    ),
                    if (_isEditing && _isDefault)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Esta é uma planta daninha padrão do sistema e algumas propriedades não podem ser alteradas.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveWeed,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        // backgroundColor: Colors.brown, // backgroundColor não é suportado em flutter_map 5.0.0
                      ),
                      child: Text(
                        _isEditing ? 'Atualizar Planta Daninha' : 'Adicionar Planta Daninha',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
