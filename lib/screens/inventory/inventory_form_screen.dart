import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortsmart_agro/database/models/inventory.dart';
import 'package:fortsmart_agro/repositories/inventory_repository.dart';
import 'package:fortsmart_agro/utils/validators.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';
import 'package:fortsmart_agro/widgets/date_picker_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item;
  
  const InventoryFormScreen({Key? key, this.item}) : super(key: key);

  @override
  _InventoryFormScreenState createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _formulationController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _minimumLevelController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  
  final InventoryRepository _repository = InventoryRepository();
  
  DateTime? _expirationDate;
  String? _pdfPath;
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Lista de tipos de produtos predefinidos
  final List<String> _productTypes = [
    'Herbicida', 
    'Inseticida', 
    'Fungicida', 
    'Acaricida', 
    'Fertilizante', 
    'Adjuvante', 
    'Outro'
  ];
  
  // Lista de formulações predefinidas
  final List<String> _formulations = [
    'EC', 'SC', 'WG', 'WP', 'SL', 'CS', 'OD', 'FS', 'DS', 'GR', 'Outro'
  ];
  
  // Lista de unidades predefinidas
  final List<String> _units = ['L', 'kg', 'g', 'mL', 'Outro'];
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.item != null;
    
    if (_isEditing) {
      _nameController.text = widget.item!.name;
      _typeController.text = widget.item!.type ?? '';
      _formulationController.text = widget.item!.formulation ?? '';
      _unitController.text = widget.item!.unit;
      _quantityController.text = widget.item!.quantity.toString();
      _locationController.text = widget.item!.location ?? '';
      // Converter a string de data para DateTime se não for nula
      if (widget.item!.expirationDate != null) {
        if (widget.item!.expirationDate is String) {
          try {
            _expirationDate = DateTime.parse(widget.item!.expirationDate as String);
          } catch (e) {
            _expirationDate = null;
          }
        } else {
          _expirationDate = widget.item!.expirationDate as DateTime?;
        }
      }
      _pdfPath = widget.item!.pdfPath;
      
      if (widget.item!.manufacturer != null) {
        _manufacturerController.text = widget.item!.manufacturer!;
      }
      
      if (widget.item!.minimumLevel != null) {
        _minimumLevelController.text = widget.item!.minimumLevel.toString();
      }
      
      if (widget.item!.registrationNumber != null) {
        _registrationNumberController.text = widget.item!.registrationNumber!;
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _formulationController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _manufacturerController.dispose();
    _minimumLevelController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _pickPdf() async {
    try {
      final file = await FilePickerWrapper.pickSingleFile();
      
      if (file == null) {
        return;
      }
      
      // Verificar a extensão do arquivo
      final filePath = file.path;
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        NotificationsWrapper.showErrorMessage('O arquivo selecionado não é um PDF válido.');
        return;
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      
      // Copia o arquivo para o diretório da aplicação
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/pdfs');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }
      
      final savedFile = await file.copy('${pdfDir.path}/$fileName');
      
      setState(() {
        _pdfPath = savedFile.path;
      });
      
      NotificationsWrapper.showSuccessMessage('PDF selecionado com sucesso');
    } catch (e) {
      NotificationsWrapper.showErrorMessage('Erro ao selecionar PDF: ${e.toString()}');
    }
  }
  
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Converte a quantidade e nível mínimo para double
      final quantity = double.parse(_quantityController.text.replaceAll(',', '.'));
      double? minimumLevel;
      if (_minimumLevelController.text.isNotEmpty) {
        minimumLevel = double.parse(_minimumLevelController.text.replaceAll(',', '.'));
      }
      
      final item = InventoryItem(
        id: _isEditing ? widget.item!.id : null,
        name: _nameController.text,
        type: _typeController.text,
        formulation: _formulationController.text,
        unit: _unitController.text,
        quantity: quantity,
        location: _locationController.text,
        expirationDate: _expirationDate?.toIso8601String(),
        manufacturer: _manufacturerController.text.isNotEmpty ? _manufacturerController.text : null,
        minimumLevel: minimumLevel,
        registrationNumber: _registrationNumberController.text.isNotEmpty ? _registrationNumberController.text : null,
        pdfPath: _pdfPath,
        createdAt: _isEditing ? widget.item!.createdAt : DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        category: 'Insumo', // Categoria padrão
      );
      
      bool success;
      if (_isEditing) {
        success = await _repository.updateItem(item);
      } else {
        final itemId = await _repository.addItem(item);
        success = true;
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        NotificationsWrapper.showSuccessMessage(
          _isEditing ? 'Produto atualizado com sucesso' : 'Produto adicionado com sucesso'
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Operação não realizada');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NotificationsWrapper.showErrorMessage(
        'Erro ao salvar produto: ${e.toString()}'
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Editar Produto' : 'Novo Produto';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas
                    Text(
                      'Informações Básicas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Produto',
                        hintText: 'Ex: Glifosato',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Informe o nome do produto' : null,
                    ),
                    SizedBox(height: 16),
                    
                    // Tipo
                    DropdownButtonFormField<String>(
                      value: _productTypes.contains(_typeController.text) ? _typeController.text : null,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: _productTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _typeController.text = value;
                        }
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Selecione o tipo' : null,
                    ),
                    SizedBox(height: 16),
                    
                    // Formulação
                    DropdownButtonFormField<String>(
                      value: _formulations.contains(_formulationController.text) ? _formulationController.text : null,
                      decoration: InputDecoration(
                        labelText: 'Formulação',
                        border: OutlineInputBorder(),
                      ),
                      items: _formulations.map((formulation) {
                        return DropdownMenuItem(
                          value: formulation,
                          child: Text(formulation),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _formulationController.text = value;
                        }
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Selecione a formulação' : null,
                    ),
                    SizedBox(height: 16),
                    
                    // Unidade
                    DropdownButtonFormField<String>(
                      value: _units.contains(_unitController.text) ? _unitController.text : null,
                      decoration: InputDecoration(
                        labelText: 'Unidade',
                        border: OutlineInputBorder(),
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _unitController.text = value;
                        }
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Selecione a unidade' : null,
                    ),
                    SizedBox(height: 24),
                    
                    // Estoque
                    Text(
                      'Informações de Estoque',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Quantidade
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantidade',
                        hintText: 'Ex: 20',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a quantidade';
                        }
                        
                        final quantity = double.tryParse(value.replaceAll(',', '.'));
                        if (quantity == null || quantity < 0) {
                          return 'Quantidade inválida';
                        }
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Local
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Local de Armazenamento',
                        hintText: 'Ex: Depósito A',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Informe o local de armazenamento' : null,
                    ),
                    SizedBox(height: 16),
                    
                    // Nível mínimo
                    TextFormField(
                      controller: _minimumLevelController,
                      decoration: InputDecoration(
                        labelText: 'Nível Mínimo (opcional)',
                        hintText: 'Ex: 10',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        
                        final minimumLevel = double.tryParse(value.replaceAll(',', '.'));
                        if (minimumLevel == null || minimumLevel < 0) {
                          return 'Nível mínimo inválido';
                        }
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Data de validade
                    // Usando o DatePickerField criado
                    DatePickerField(
                      labelText: 'Data de Validade (opcional)',
                      initialDate: _expirationDate,
                      onDateSelected: (date) {
                        setState(() {
                          _expirationDate = date;
                        });
                      },
                      allowNull: true,
                    ),
                    SizedBox(height: 24),
                    
                    // Informações adicionais
                    Text(
                      'Informações Adicionais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Fabricante
                    TextFormField(
                      controller: _manufacturerController,
                      decoration: InputDecoration(
                        labelText: 'Fabricante (opcional)',
                        hintText: 'Ex: Bayer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Número de registro
                    TextFormField(
                      controller: _registrationNumberController,
                      decoration: InputDecoration(
                        labelText: 'Número de Registro (opcional)',
                        hintText: 'Ex: 12345',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // PDF
                    ListTile(
                      title: Text('Bula / Documentação (PDF)'),
                      subtitle: _pdfPath != null
                          ? Text(path.basename(_pdfPath!))
                          : Text('Nenhum arquivo selecionado'),
                      leading: Icon(Icons.picture_as_pdf),
                      trailing: ElevatedButton(
                        onPressed: _pickPdf,
                        child: Text('Selecionar'),
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Botão de salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Salvar Produto'),
                        onPressed: _saveItem,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

