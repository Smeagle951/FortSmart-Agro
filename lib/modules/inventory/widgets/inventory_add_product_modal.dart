import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortsmart_agro/models/agricultural_product.dart' show ProductType;
import 'package:intl/intl.dart';
import '../models/inventory_product_model.dart';
import '../models/product_class_model.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/custom_text_form_field.dart';
import '../../shared/widgets/custom_dropdown.dart';
import '../../shared/widgets/improved_dropdown.dart';

class InventoryAddProductModal extends StatefulWidget {
  final Function(InventoryProductModel) onSave;
  final InventoryProductModel? existingProduct;
  final Function(InventoryProductModel)? onProductAdded;
  final Function()? onProductUpdated;

  const InventoryAddProductModal({
    Key? key,
    required this.onSave,
    this.existingProduct,
    this.onProductAdded,
    this.onProductUpdated,
  }) : super(key: key);

  @override
  _InventoryAddProductModalState createState() => _InventoryAddProductModalState();
}

class _InventoryAddProductModalState extends State<InventoryAddProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _batchNumberController;
  late TextEditingController _quantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _unitCostController;
  late TextEditingController _supplierController;
  late TextEditingController _notesController;
  late TextEditingController _expirationDateController;
  
  ProductType _selectedType = ProductType.other;
  String _selectedUnit = 'L';
  DateTime? _expirationDate;
  bool _isEditing = false;

  final List<String> _unitOptions = ['L', 'kg', 'g', 'ml', 'un', 'sc', 'cx', 'pct'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingProduct != null;
    
    // Inicializar controladores
    _nameController = TextEditingController(text: _isEditing ? widget.existingProduct!.name : '');
    _batchNumberController = TextEditingController(text: _isEditing ? widget.existingProduct!.batchNumber : '');
    _quantityController = TextEditingController(
      text: _isEditing ? widget.existingProduct!.quantity.toString() : '',
    );
    _minQuantityController = TextEditingController(
      text: _isEditing ? widget.existingProduct!.minQuantity.toString() : '',
    );
    _unitCostController = TextEditingController(
      text: _isEditing && widget.existingProduct!.unitCost != null 
          ? widget.existingProduct!.unitCost.toString() 
          : '',
    );
    _supplierController = TextEditingController(
      text: _isEditing ? widget.existingProduct!.supplier ?? '' : '',
    );
    _notesController = TextEditingController(
      text: _isEditing ? widget.existingProduct!.description ?? '' : '',
    );
    _expirationDateController = TextEditingController();
    
    // Inicializar valores do produto existente se estiver editando
    if (_isEditing) {
      _selectedType = widget.existingProduct!.type;
      _selectedUnit = widget.existingProduct!.unit;
      _expirationDate = widget.existingProduct!.expirationDate;
      
      if (_expirationDate != null) {
        _expirationDateController.text = DateFormat('dd/MM/yyyy').format(_expirationDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _unitCostController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
        _expirationDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = InventoryProductModel(
        id: _isEditing ? widget.existingProduct!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        productId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        type: _selectedType,
        productClass: ProductClass.other, // Valor padrão
        unit: _selectedUnit,
        quantity: double.parse(_quantityController.text),
        minQuantity: double.tryParse(_minQuantityController.text) ?? 0.0,
        batchNumber: _batchNumberController.text.trim(),
        expirationDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
        supplier: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
        unitCost: _unitCostController.text.trim().isNotEmpty 
            ? double.parse(_unitCostController.text.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.')) 
            : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: _isEditing ? widget.existingProduct!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(product);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 
            ? 600 
            : MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  _isEditing ? 'Editar Produto' : 'Adicionar Produto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Conteúdo
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome do produto
                        CustomTextFormField(
                          controller: _nameController,
                          label: 'Nome do Produto*',
                          prefixIcon: const Icon(Icons.inventory),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nome do produto é obrigatório';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Tipo de produto e unidade
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Se a largura for menor que 400px, empilhar verticalmente
                            if (constraints.maxWidth < 400) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tipo de produto
                                  ImprovedDropdown<ProductType>(
                                    label: 'Tipo de Produto*',
                                    prefixIcon: const Icon(Icons.category),
                                    value: _selectedType,
                                    items: DropdownItemHelper.createProductTypeItems(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedType = value;
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  
                                  // Unidade
                                  ImprovedDropdown<String>(
                                    label: 'Unidade*',
                                    prefixIcon: const Icon(Icons.straighten),
                                    value: _selectedUnit,
                                    items: DropdownItemHelper.createUnitItems(_unitOptions),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedUnit = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              );
                            } else {
                              // Para telas maiores, usar layout horizontal
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tipo de produto
                                  Expanded(
                                    flex: 3,
                                    child: ImprovedDropdown<ProductType>(
                                      label: 'Tipo de Produto*',
                                      prefixIcon: const Icon(Icons.category),
                                      value: _selectedType,
                                      items: DropdownItemHelper.createProductTypeItems(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedType = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  
                                  // Unidade
                                  Expanded(
                                    flex: 2,
                                    child: ImprovedDropdown<String>(
                                      label: 'Unidade*',
                                      prefixIcon: const Icon(Icons.straighten),
                                      value: _selectedUnit,
                                      items: DropdownItemHelper.createUnitItems(_unitOptions),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedUnit = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Quantidade e quantidade mínima
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Se a largura for menor que 400px, empilhar verticalmente
                            if (constraints.maxWidth < 400) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Quantidade
                                  CustomTextFormField(
                                    controller: _quantityController,
                                    label: 'Quantidade*',
                                    prefixIcon: const Icon(Icons.inventory_2),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Quantidade é obrigatória';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Valor inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  
                                  // Quantidade mínima
                                  CustomTextFormField(
                                    controller: _minQuantityController,
                                    label: 'Qtd. Mínima*',
                                    prefixIcon: const Icon(Icons.warning_amber),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Qtd. mínima é obrigatória';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Valor inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              );
                            } else {
                              // Para telas maiores, usar layout horizontal
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Quantidade
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: _quantityController,
                                      label: 'Quantidade*',
                                      prefixIcon: const Icon(Icons.inventory_2),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Quantidade é obrigatória';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Valor inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  
                                  // Quantidade mínima
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: _minQuantityController,
                                      label: 'Qtd. Mínima*',
                                      prefixIcon: const Icon(Icons.warning_amber),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Qtd. mínima é obrigatória';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Valor inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Lote e data de vencimento
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Se a largura for menor que 400px, empilhar verticalmente
                            if (constraints.maxWidth < 400) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Lote
                                  CustomTextFormField(
                                    controller: _batchNumberController,
                                    label: 'Lote*',
                                    prefixIcon: const Icon(Icons.qr_code),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Lote é obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  
                                  // Data de vencimento
                                  CustomTextFormField(
                                    controller: _expirationDateController,
                                    label: 'Data de Vencimento',
                                    prefixIcon: const Icon(Icons.event),
                                    readOnly: true,
                                    onTap: () => _selectDate(context)
                                  ),
                                ],
                              );
                            } else {
                              // Para telas maiores, usar layout horizontal
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Lote
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: _batchNumberController,
                                      label: 'Lote*',
                                      prefixIcon: const Icon(Icons.qr_code),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Lote é obrigatório';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  
                                  // Data de vencimento
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: _expirationDateController,
                                      label: 'Data de Vencimento',
                                      prefixIcon: const Icon(Icons.event),
                                      readOnly: true,
                                      onTap: () => _selectDate(context)
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Fornecedor e custo unitário
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Se a largura for menor que 400px, empilhar verticalmente
                            if (constraints.maxWidth < 400) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fornecedor
                                  CustomTextFormField(
                                    controller: _supplierController,
                                    label: 'Fornecedor',
                                    prefixIcon: const Icon(Icons.business),
                                  ),
                                  SizedBox(height: 16),
                                  
                                  // Custo unitário
                                  CustomTextFormField(
                                    controller: _unitCostController,
                                    label: 'Custo Unitário (R\$)',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              // Para telas maiores, usar layout horizontal
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fornecedor
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: _supplierController,
                                      label: 'Fornecedor',
                                      prefixIcon: const Icon(Icons.business),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  
                                  // Custo unitário
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: _unitCostController,
                                      label: 'Custo Unitário (R\$)',
                                      prefixIcon: const Icon(Icons.attach_money),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Observações
                        CustomTextFormField(
                          controller: _notesController,
                          label: 'Observações',
                          prefixIcon: const Icon(Icons.note),
                          maxLines: 3,
                        ),
                        SizedBox(height: 24),
                        
                        // Botões de ação
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isEditing ? 'Atualizar' : 'Adicionar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _getProductTypeName(ProductType type) {
    switch (type) {
      case ProductType.herbicide:
        return 'Herbicida';
      case ProductType.insecticide:
        return 'Inseticida';
      case ProductType.fungicide:
        return 'Fungicida';
      case ProductType.fertilizer:
        return 'Fertilizante';
      case ProductType.growth:
        return 'Regulador de crescimento';
      case ProductType.adjuvant:
        return 'Adjuvante';
      case ProductType.seed:
        return 'Semente';
      case ProductType.other:
        return 'Outro';
      default:
        return 'Desconhecido';
    }
  }
}
