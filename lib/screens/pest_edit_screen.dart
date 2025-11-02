import 'package:flutter/material.dart';
import '../database/models/pest.dart';
import '../services/crop_service.dart';

class PestEditScreen extends StatefulWidget {
  final Pest? pest;
  final int cropId;

  const PestEditScreen({Key? key, this.pest, required this.cropId}) : super(key: key);

  @override
  _PestEditScreenState createState() => _PestEditScreenState();
}

class _PestEditScreenState extends State<PestEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final CropService _cropService = CropService();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDefault = true;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.pest != null;
    
    if (_isEditing) {
      _nameController.text = widget.pest!.name;
      _scientificNameController.text = widget.pest!.scientificName;
      _descriptionController.text = widget.pest!.description;
      _isDefault = widget.pest!.isDefault;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _savePest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pest = _isEditing
          ? widget.pest!.copyWith(
              name: _nameController.text,
              scientificName: _scientificNameController.text,
              description: _descriptionController.text,
              isDefault: _isDefault,
              syncStatus: 0, // Marcar para sincronização
            )
          : Pest(
              id: 0, // Será substituído pelo autoincrement
              name: _nameController.text,
              scientificName: _scientificNameController.text,
              description: _descriptionController.text,
              cropId: widget.cropId,
              isDefault: false, // Novas pragas adicionadas pelo usuário não são padrão
            );
      
      await _cropService.savePest(pest);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Praga atualizada com sucesso'
              : 'Praga adicionada com sucesso'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar praga: $e'),
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
        title: Text(_isEditing ? 'Editar Praga' : 'Nova Praga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePest,
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
                        labelText: 'Nome da Praga',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bug_report),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome da praga';
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
                    if (_isEditing && _isDefault)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Esta é uma praga padrão do sistema e algumas propriedades não podem ser alteradas.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _savePest,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                      ),
                      child: Text(
                        _isEditing ? 'Atualizar Praga' : 'Adicionar Praga',
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
