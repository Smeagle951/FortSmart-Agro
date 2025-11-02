import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/models/inventory.dart';
import '../../repositories/inventory_repository.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final InventoryItem? item;
  final String? itemId;

  const AddInventoryItemScreen({Key? key, this.item, this.itemId}) : super(key: key);

  @override
  _AddInventoryItemScreenState createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _notesController = TextEditingController();

  final InventoryRepository _repository = InventoryRepository();
  bool _isLoading = false;
  DateTime? _expirationDate;

  final List<String> _predefinedCategories = [
    'Fertilizantes',
    'Defensivos',
    'Sementes',
    'Ferramentas',
    'Equipamentos',
    'Combustíveis',
    'Outros'
  ];

  final List<String> _predefinedUnits = [
    'kg',
    'g',
    'L',
    'mL',
    'unid',
    'cx',
    'sc',
    'ton'
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.item != null) {
      _loadItemData(widget.item!);
    } else if (widget.itemId != null) {
      _loadItemById(widget.itemId!);
    }
  }

  Future<void> _loadItemById(String itemId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final item = await _repository.getItemById(itemId);
      if (item != null) {
        _loadItemData(item);
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar item: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadItemData(InventoryItem item) {
    _nameController.text = item.name;
    _codeController.text = item.code ?? '';
    _categoryController.text = item.category;
    _quantityController.text = item.quantity.toString();
    _unitController.text = item.unit;
    _unitPriceController.text = item.unitPrice?.toString() ?? '';
    _supplierController.text = item.supplier ?? '';
    _locationController.text = item.location ?? '';
    _expirationDateController.text = item.expirationDate ?? '';
    _notesController.text = item.notes ?? '';

    if (item.expirationDate != null) {
      try {
        _expirationDate = DateTime.parse(item.expirationDate!);
      } catch (e) {
        // Ignora erro de parsing
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    _expirationDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
        _expirationDateController.text = _expirationDate!.toIso8601String().split('T')[0];
      });
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
      final item = InventoryItem(
        id: widget.item?.id,
        name: _nameController.text,
        code: _codeController.text.isEmpty ? null : _codeController.text,
        category: _categoryController.text,
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text,
        unitPrice: _unitPriceController.text.isEmpty
            ? null
            : double.parse(_unitPriceController.text),
        supplier: _supplierController.text.isEmpty
            ? null
            : _supplierController.text,
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        expirationDate: _expirationDateController.text.isEmpty
            ? null
            : _expirationDateController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.item?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
        remoteId: widget.item?.remoteId,
      );

      if (widget.item == null) {
        await _repository.addItem(item);
      } else {
        await _repository.updateItem(item);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erro ao salvar item: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Adicionar Item' : 'Editar Item'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o nome do item';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _predefinedCategories.contains(_categoryController.text)
                          ? _categoryController.text
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Categoria *',
                        border: OutlineInputBorder(),
                      ),
                      items: _predefinedCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _categoryController.text = newValue;
                        }
                      },
                      validator: (value) {
                        if (_categoryController.text.isEmpty) {
                          return 'Por favor, selecione uma categoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantidade *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a quantidade';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Quantidade inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _predefinedUnits.contains(_unitController.text)
                                ? _unitController.text
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Unidade *',
                              border: OutlineInputBorder(),
                            ),
                            items: _predefinedUnits.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _unitController.text = newValue;
                              }
                            },
                            validator: (value) {
                              if (_unitController.text.isEmpty) {
                                return 'Informe a unidade';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Preço Unitário (R\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localização',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    GestureDetector(
                      // onTap: () => _selectDate(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _expirationDateController,
                          decoration: const InputDecoration(
                            labelText: 'Data de Validade',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(
                        widget.item == null ? 'Adicionar' : 'Salvar Alterações',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
