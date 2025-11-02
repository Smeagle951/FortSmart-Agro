import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/calda/product.dart';
import '../../../models/calda/formulation_type.dart';
import '../../../models/calda/dose_unit.dart';

class ProductFormWidget extends StatefulWidget {
  final Function(Product) onProductAdded;
  final VoidCallback onCancel;

  const ProductFormWidget({
    Key? key,
    required this.onProductAdded,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _doseController = TextEditingController();
  
  FormulationType _selectedFormulation = FormulationType.ec;
  DoseUnit _selectedDoseUnit = DoseUnit.l;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do formulário
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Adicionar Produto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Nome do produto
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Produto *',
                    hintText: 'Ex: Glifosato 480',
                    prefixIcon: Icon(Icons.eco),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o nome do produto';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Fabricante
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Fabricante *',
                    hintText: 'Ex: Syngenta',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o fabricante';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Formulação
                DropdownButtonFormField<FormulationType>(
                  value: _selectedFormulation,
                  decoration: const InputDecoration(
                    labelText: 'Formulação *',
                    prefixIcon: Icon(Icons.science),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: FormulationType.values.map((formulation) {
                    return DropdownMenuItem(
                      value: formulation,
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formulation.code,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formulation.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFormulation = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a formulação';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Dose
                TextFormField(
                  controller: _doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose *',
                    hintText: 'Ex: 2.5',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a dose';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Dose deve ser maior que zero';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Unidade da dose
                DropdownButtonFormField<DoseUnit>(
                  value: _selectedDoseUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade *',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: DoseUnit.values.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              unit.symbol,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              unit.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDoseUnit = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a unidade';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Botões de ação
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 300) {
                      // Layout vertical para telas muito pequenas
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: widget.onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Incluir Produto'),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Layout horizontal para telas maiores
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Incluir Produto'),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        name: _nameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        formulation: _selectedFormulation,
        dose: double.parse(_doseController.text),
        doseUnit: _selectedDoseUnit,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Limpa os campos para o próximo produto
      _nameController.clear();
      _manufacturerController.clear();
      _doseController.clear();
      _selectedFormulation = FormulationType.ec;
      _selectedDoseUnit = DoseUnit.l;
      
      widget.onProductAdded(product);
      
      // Mostra feedback de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto adicionado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
