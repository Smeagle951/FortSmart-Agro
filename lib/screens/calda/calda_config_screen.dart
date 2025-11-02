import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calda/calda_config.dart';
import '../../models/calda/formulation_type.dart';
import '../../models/calda/dose_unit.dart';
import '../../models/calda/product.dart';
import '../../services/calda/calda_service.dart';
import 'product_form_screen.dart';
import 'calda_calculation_screen.dart';

class CaldaConfigScreen extends StatefulWidget {
  const CaldaConfigScreen({Key? key}) : super(key: key);

  @override
  State<CaldaConfigScreen> createState() => _CaldaConfigScreenState();
}

class _CaldaConfigScreenState extends State<CaldaConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();
  final _flowRateController = TextEditingController();
  final _areaController = TextEditingController();
  
  bool _isFlowPerHectare = true;
  List<Product> _products = [];
  final CaldaService _caldaService = CaldaService.instance;

  @override
  void dispose() {
    _volumeController.dispose();
    _flowRateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração da Calda'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de configuração básica
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
                        'Configuração Básica',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Volume da calda
                      TextFormField(
                        controller: _volumeController,
                        decoration: const InputDecoration(
                          labelText: 'Volume da Calda (L)',
                          hintText: 'Ex: 300',
                          prefixIcon: Icon(Icons.local_drink),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o volume da calda';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Volume deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Vazão
                      TextFormField(
                        controller: _flowRateController,
                        decoration: const InputDecoration(
                          labelText: 'Vazão',
                          hintText: 'Ex: 150',
                          prefixIcon: Icon(Icons.speed),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a vazão';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Vazão deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tipo de vazão
                      Card(
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tipo de Vazão:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      title: const Text('L/ha'),
                                      subtitle: const Text('Litros por hectare'),
                                      value: true,
                                      groupValue: _isFlowPerHectare,
                                      onChanged: (value) {
                                        setState(() {
                                          _isFlowPerHectare = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      title: const Text('L/alqueire'),
                                      subtitle: const Text('Litros por alqueire'),
                                      value: false,
                                      groupValue: _isFlowPerHectare,
                                      onChanged: (value) {
                                        setState(() {
                                          _isFlowPerHectare = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Área
                      TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(
                          labelText: 'Área de Aplicação (ha)',
                          hintText: 'Ex: 20',
                          prefixIcon: Icon(Icons.terrain),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a área de aplicação';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Área deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Card de produtos
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Produtos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          Text(
                            '${_products.length}/10',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Lista de produtos
                      if (_products.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Nenhum produto adicionado',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _products.asMap().entries.map((entry) {
                            int index = entry.key;
                            Product product = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${product.manufacturer} • ${product.formulation.code} • ${product.dose} ${product.doseUnit.symbol}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeProduct(index),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Botão adicionar produto
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _products.length >= 10 ? null : _addProduct,
                          icon: const Icon(Icons.add),
                          label: Text(
                            _products.isEmpty 
                                ? 'Adicionar Primeiro Produto'
                                : 'Adicionar Produto',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botão calcular
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canCalculate() ? _calculateRecipe : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Calcular Receita',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canCalculate() {
    return _formKey.currentState?.validate() == true && _products.isNotEmpty;
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    );
    
    if (result != null && result is Product) {
      setState(() {
        _products.add(result);
      });
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _calculateRecipe() async {
    if (!_canCalculate()) return;
    
    try {
      // Salva os produtos no banco
      for (Product product in _products) {
        await _caldaService.addProduct(product);
      }
      
      // Cria a configuração
      final config = CaldaConfig(
        volumeLiters: double.parse(_volumeController.text),
        flowRate: double.parse(_flowRateController.text),
        isFlowPerHectare: _isFlowPerHectare,
        area: double.parse(_areaController.text),
        createdAt: DateTime.now(),
      );
      
      // Navega para tela de cálculo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaldaCalculationScreen(
            products: _products,
            config: config,
          ),
        ),
      );
    } catch (e) {
      _showError('Erro ao calcular receita: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
