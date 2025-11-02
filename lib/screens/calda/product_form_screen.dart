import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calda/product.dart';
import '../../models/calda/formulation_type.dart';
import '../../models/calda/dose_unit.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({Key? key}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Produto'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de informações do produto
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do Produto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
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
                        items: FormulationType.values.map((formulation) {
                          return DropdownMenuItem(
                            value: formulation,
                            child: Text('${formulation.code} - ${formulation.description}'),
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
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Card de dosagem
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dosagem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
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
                        items: DoseUnit.values.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text('${unit.symbol} - ${unit.description}'),
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
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Informações sobre unidades
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Unidades de Dosagem:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• L: Litros por hectare\n'
                      '• L/100L: Litros por 100 litros de calda\n'
                      '• mL: Mililitros por hectare\n'
                      '• g: Gramas por hectare\n'
                      '• g/100L: Gramas por 100 litros de calda\n'
                      '• kg: Quilogramas por hectare\n'
                      '• kg/100L: Quilogramas por 100 litros de calda\n'
                      '• mL/100L: Mililitros por 100 litros de calda\n'
                      '• %v/v: Percentual volume/volume',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      child: const Text('Salvar Produto'),
                    ),
                  ),
                ],
              ),
            ],
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
      
      Navigator.pop(context, product);
    }
  }
}
