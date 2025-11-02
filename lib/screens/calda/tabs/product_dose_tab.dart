import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/calda/product.dart';
import '../../../models/calda/calda_config.dart';
import '../../../services/calda/calda_service.dart';
import '../widgets/product_form_widget.dart';
import '../widgets/mixing_order_widget.dart';
import '../widgets/draggable_product_list.dart';
import '../widgets/save_recipe_dialog.dart';

class ProductDoseTab extends StatefulWidget {
  final Function({
    CaldaConfig? config,
    List<Product>? products,
    List<String>? mixingOrder,
    List<String>? warnings,
  }) onDataChanged;
  
  final CaldaConfig? caldaConfig;
  final List<Product> products;
  final List<String> mixingOrder;
  final List<String> compatibilityWarnings;

  const ProductDoseTab({
    Key? key,
    required this.onDataChanged,
    this.caldaConfig,
    required this.products,
    required this.mixingOrder,
    required this.compatibilityWarnings,
  }) : super(key: key);

  @override
  State<ProductDoseTab> createState() => _ProductDoseTabState();
}

class _ProductDoseTabState extends State<ProductDoseTab> {
  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();
  final _flowRateController = TextEditingController();
  final _areaController = TextEditingController();
  
  bool _isFlowPerHectare = true;
  bool _showProductForm = false;
  final CaldaService _caldaService = CaldaService.instance;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _flowRateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (widget.caldaConfig != null) {
      _volumeController.text = widget.caldaConfig!.volumeLiters.toString();
      _flowRateController.text = widget.caldaConfig!.flowRate.toString();
      _areaController.text = widget.caldaConfig!.area.toString();
      _isFlowPerHectare = widget.caldaConfig!.isFlowPerHectare;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        const Text(
                          'Configuração da Calda',
                          style: TextStyle(
                            fontSize: 16,
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
                      onChanged: (_) => _updateData(),
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
                      onChanged: (_) => _updateData(),
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
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Usar Column em telas pequenas e Row em telas maiores
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 400) {
                                      // Layout vertical para telas pequenas
                                      return Column(
                                        children: [
                                          RadioListTile<bool>(
                                            title: const Text(
                                              'L/ha',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            subtitle: const Text(
                                              'Litros por hectare',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            value: true,
                                            groupValue: _isFlowPerHectare,
                                            onChanged: (value) {
                                              setState(() {
                                                _isFlowPerHectare = value!;
                                              });
                                              _updateData();
                                            },
                                            activeColor: const Color(0xFF2E7D32),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                          RadioListTile<bool>(
                                            title: const Text(
                                              'L/alqueire',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            subtitle: const Text(
                                              'Litros por alqueire',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            value: false,
                                            groupValue: _isFlowPerHectare,
                                            onChanged: (value) {
                                              setState(() {
                                                _isFlowPerHectare = value!;
                                              });
                                              _updateData();
                                            },
                                            activeColor: const Color(0xFF2E7D32),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Layout horizontal para telas maiores
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: RadioListTile<bool>(
                                              title: const Text(
                                                'L/ha',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              subtitle: const Text(
                                                'Litros por hectare',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              value: true,
                                              groupValue: _isFlowPerHectare,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isFlowPerHectare = value!;
                                                });
                                                _updateData();
                                              },
                                              activeColor: const Color(0xFF2E7D32),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                              dense: true,
                                            ),
                                          ),
                                          Expanded(
                                            child: RadioListTile<bool>(
                                              title: const Text(
                                                'L/alqueire',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              subtitle: const Text(
                                                'Litros por alqueire',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              value: false,
                                              groupValue: _isFlowPerHectare,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isFlowPerHectare = value!;
                                                });
                                                _updateData();
                                              },
                                              activeColor: const Color(0xFF2E7D32),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                              dense: true,
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
                    
                    const SizedBox(height: 16),
                    
                    // Área
                    TextFormField(
                      controller: _areaController,
                      decoration: InputDecoration(
                        labelText: 'Área de Aplicação (${_isFlowPerHectare ? 'ha' : 'alqueires'})',
                        hintText: 'Ex: 20',
                        prefixIcon: const Icon(Icons.terrain),
                        border: const OutlineInputBorder(),
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
                      onChanged: (_) => _updateData(),
                    ),
                  ],
                ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Text(
                          'Produtos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      Text(
                        '${widget.products.length}/10',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Lista de produtos
                  if (widget.products.isEmpty)
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
                                  fontSize: 12,
                                ),
                              ),
                        ],
                      ),
                    )
                  else
                    DraggableProductList(
                      products: widget.products,
                      onReorder: _onProductsReordered,
                      onEdit: _editProduct,
                      onDelete: _removeProduct,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Botão adicionar produto
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.products.length >= 10 ? null : _addProduct,
                      icon: const Icon(Icons.add),
                      label: Text(
                        widget.products.isEmpty 
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
          
          const SizedBox(height: 20),
          
          // Ordem de mistura e avisos
          if (widget.products.isNotEmpty) ...[
            MixingOrderWidget(
              products: widget.products,
              mixingOrder: widget.mixingOrder,
              compatibilityWarnings: widget.compatibilityWarnings,
            ),
            
            const SizedBox(height: 20),
            
            // Botão salvar receita
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSaveRecipe() ? _saveRecipe : null,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Receita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          
          // Formulário de produto (modal)
          if (_showProductForm)
            ProductFormWidget(
              onProductAdded: _onProductAdded,
              onCancel: () => setState(() => _showProductForm = false),
            ),
        ],
      ),
    );
  }

  void _updateData() {
    if (_formKey.currentState?.validate() == true) {
      final config = CaldaConfig(
        volumeLiters: double.parse(_volumeController.text),
        flowRate: double.parse(_flowRateController.text),
        isFlowPerHectare: _isFlowPerHectare,
        area: double.parse(_areaController.text),
        createdAt: DateTime.now(),
      );
      
      final mixingOrder = _caldaService.getMixingOrder(widget.products)
          .map((p) => p.name)
          .toList();
      
      final warnings = _caldaService.checkCompatibility(widget.products);
      
      widget.onDataChanged(
        config: config,
        products: widget.products,
        mixingOrder: mixingOrder,
        warnings: warnings,
      );
    }
  }

  void _addProduct() {
    setState(() {
      _showProductForm = true;
    });
  }

  void _editProduct(int index) {
    // Implementar edição de produto
    _showError('Funcionalidade de edição em desenvolvimento');
  }

  void _removeProduct(int index) {
    setState(() {
      widget.products.removeAt(index);
    });
    _updateData();
  }

  void _onProductAdded(Product product) {
    setState(() {
      widget.products.add(product);
      _showProductForm = false;
    });
    _updateData();
  }

  void _onProductsReordered(List<Product> reorderedProducts) {
    setState(() {
      widget.products.clear();
      widget.products.addAll(reorderedProducts);
    });
    _updateData();
  }

  bool _canSaveRecipe() {
    return _formKey.currentState?.validate() == true && 
           widget.products.isNotEmpty;
  }

  void _saveRecipe() {
    if (widget.caldaConfig != null) {
      showDialog(
        context: context,
        builder: (context) => SaveRecipeDialog(
          products: widget.products,
          config: widget.caldaConfig!,
          onSave: (name, description) {
            _showSuccess('Receita "$name" salva com sucesso!');
            // Aqui você salvaria a receita no banco de dados
          },
        ),
      );
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
