import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../services/crop_service.dart';

class DiseaseEditScreen extends StatefulWidget {
  final Disease? disease;
  final int cropId;

  const DiseaseEditScreen({Key? key, this.disease, required this.cropId}) : super(key: key);

  @override
  _DiseaseEditScreenState createState() => _DiseaseEditScreenState();
}

class _DiseaseEditScreenState extends State<DiseaseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _symptomsController = TextEditingController();
  
  final CropService _cropService = CropService();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDefault = true;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.disease != null;
    
    if (_isEditing) {
      _nameController.text = widget.disease!.name;
      _scientificNameController.text = widget.disease!.scientificName ?? '';
      _descriptionController.text = widget.disease!.description ?? '';
      _symptomsController.text = widget.disease!.symptoms ?? '';
      _isDefault = widget.disease!.isDefault;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }
  
  Future<void> _saveDisease() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final disease = _isEditing
          ? Disease(
              id: widget.disease!.id,
              name: _nameController.text,
              scientificName: _scientificNameController.text,
              description: _descriptionController.text,
              symptoms: _symptomsController.text,
              isDefault: _isDefault,
              isSynced: false, // Marcar para sincronização
              cropIds: widget.disease!.cropIds,
            )
          : Disease(
              name: _nameController.text,
              scientificName: _scientificNameController.text,
              description: _descriptionController.text,
              symptoms: _symptomsController.text,
              cropIds: [widget.cropId],
              isDefault: false, // Novas doenças adicionadas pelo usuário não são padrão
            );
      
      await _cropService.saveDisease(disease.toDbModel());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Doença atualizada com sucesso'
              : 'Doença adicionada com sucesso'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar doença: $e'),
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
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4F3D),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(
          _isEditing ? 'Editar Doença' : 'Nova Doença',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveDisease,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2A4F3D)))
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
                        labelText: 'Nome da Doença',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.coronavirus, color: Color(0xFF2A4F3D)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2A4F3D), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome da doença';
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
                        prefixIcon: Icon(Icons.science, color: Color(0xFF2A4F3D)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2A4F3D), width: 2),
                        ),
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
                        prefixIcon: Icon(Icons.description, color: Color(0xFF2A4F3D)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2A4F3D), width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _symptomsController,
                      decoration: const InputDecoration(
                        labelText: 'Sintomas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_information, color: Color(0xFF2A4F3D)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2A4F3D), width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    if (_isEditing && _isDefault)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Esta é uma doença padrão do sistema e algumas propriedades não podem ser alteradas.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveDisease,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFF2A4F3D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Atualizar Doença' : 'Adicionar Doença',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
