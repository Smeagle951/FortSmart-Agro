import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_application_model.dart';
import '../../../models/agricultural_product.dart';
import '../../../utils/app_colors.dart';

class ProductSelectionDialog extends StatefulWidget {
  final List<AgriculturalProduct> availableProducts;
  final double area;
  final List<String> alreadySelectedProductIds;
  final Function(ApplicationProductModel) onProductSelected;
  
  const ProductSelectionDialog({
    Key? key,
    required this.availableProducts,
    required this.area,
    required this.alreadySelectedProductIds,
    required this.onProductSelected,
  }) : super(key: key);

  @override
  _ProductSelectionDialogState createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  // Lista paginada para reduzir uso de memória
  late List<AgriculturalProduct> _allProducts;
  late List<AgriculturalProduct> _filteredProducts;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  
  String _selectedProductId = '';
  String _selectedProductName = '';
  String _selectedUnit = 'L/ha';
  double _dosePerHectare = 0.0;
  
  // Controle de paginação
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  final List<String> _availableUnits = ['L/ha', 'kg/ha', 'g/ha', 'mL/ha'];
  
  @override
  void initState() {
    super.initState();
    // Filtrar produtos já selecionados
    _allProducts = widget.availableProducts
        .where((product) => !widget.alreadySelectedProductIds.contains(product.id))
        .toList();
    
    // Inicializar com apenas a primeira página
    _loadInitialPage();
    
    // Adicionar listener para paginação no scroll
    _scrollController.addListener(_scrollListener);
  }
  
  void _loadInitialPage() {
    final endIndex = _allProducts.length < _pageSize ? _allProducts.length : _pageSize;
    _filteredProducts = _allProducts.sublist(0, endIndex);
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && 
        !_isLoadingMore && 
        _currentPage * _pageSize < _allProducts.length) {
      _loadMoreItems();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _doseController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Simular carregamento assíncrono para melhor experiência do usuário
    await Future.delayed(const Duration(milliseconds: 150));
    
    _currentPage++;
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize > _allProducts.length 
        ? _allProducts.length 
        : startIndex + _pageSize;
    
    if (startIndex < _allProducts.length) {
      setState(() {
        _filteredProducts.addAll(_allProducts.sublist(startIndex, endIndex));
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  void _filterProducts(String query) {
    // Resetar paginação ao filtrar
    _currentPage = 0;
    
    setState(() {
      if (query.isEmpty) {
        _allProducts = widget.availableProducts
            .where((product) => !widget.alreadySelectedProductIds.contains(product.id))
            .toList();
      } else {
        _allProducts = widget.availableProducts
            .where((product) =>
                !widget.alreadySelectedProductIds.contains(product.id) &&
                (product.name.toLowerCase().contains(query.toLowerCase()) ||
                    (product.notes?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                    (product.activeIngredient?.toLowerCase().contains(query.toLowerCase()) ?? false)))
            .toList();
      }
      
      // Carregar apenas a primeira página dos resultados filtrados
      final endIndex = _allProducts.length < _pageSize ? _allProducts.length : _pageSize;
      _filteredProducts = _allProducts.sublist(0, endIndex);
    });
  }
  
  void _selectProduct(AgriculturalProduct product) {
    setState(() {
      _selectedProductId = product.id;
      _selectedProductName = product.name;
    });
  }
  
  bool _validateForm() {
    if (_selectedProductId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um produto')),
      );
      return false;
    }
    
    if (_doseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a dose por hectare')),
      );
      return false;
    }
    
    _dosePerHectare = double.tryParse(_doseController.text) ?? 0;
    if (_dosePerHectare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A dose deve ser maior que zero')),
      );
      return false;
    }
    
    return true;
  }
  
  void _addProduct() {
    if (!_validateForm()) {
      return;
    }
    
    final totalDose = _dosePerHectare * widget.area;
    
    // Calculando valores para tanques (valores padrão se não houver cálculos específicos)
    // Estes valores serão recalculados posteriormente no ProductApplicationFormScreen
    final int numberOfTanks = 1;
    final double productPerTank = totalDose;
    
    final product = ApplicationProductModel(
      productId: _selectedProductId,
      productName: _selectedProductName,
      dosePerHectare: _dosePerHectare,
      totalDose: totalDose,
      unit: _selectedUnit,
      numberOfTanks: numberOfTanks,
      productPerTank: productPerTank,
    );
    
    widget.onProductSelected(product);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Produto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar produto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),
            
            // Lista de produtos
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _filteredProducts.isEmpty
                  ? const Center(
                      child: Text('Nenhum produto encontrado'),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Mostrar indicador de carregamento no final da lista
                            if (index >= _filteredProducts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            
                            // Renderizar item normal
                            final product = _filteredProducts[index];
                            final isSelected = _selectedProductId == product.id;
                            
                            // Usar ListTile para economizar memória em vez de widgets personalizados
                            return ListTile(
                              dense: true, // Reduzir tamanho para economizar espaço
                              title: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis, // Evitar texto muito longo
                              ),
                              subtitle: Text(
                                product.activeIngredient ?? 'Sem ingrediente ativo',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: isSelected,
                              selectedTileColor: AppColors.primaryColor.withOpacity(0.1),
                              // onTap: () => _selectProduct(product), // onTap não é suportado em Polygon no flutter_map 5.0.0
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: AppColors.primaryColor, size: 20)
                                  : null,
                            );
                          },
                        ),
                        
                        // Mostrar contador de resultados
                        if (_filteredProducts.isNotEmpty)
                          Positioned(
                            right: 8,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_filteredProducts.length}/${_allProducts.length}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Campos de dose
            if (_selectedProductId.isNotEmpty) ...[
              Text(
                'Produto selecionado: $_selectedProductName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _doseController,
                      decoration: const InputDecoration(
                        labelText: 'Dose por hectare',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
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
              ),
              const SizedBox(height: 16),
              
              // Dose total calculada
              if (_doseController.text.isNotEmpty)
                Text(
                  'Dose total: ${(double.tryParse(_doseController.text) ?? 0 * widget.area).toStringAsFixed(2)} $_selectedUnit para ${widget.area.toStringAsFixed(2)} ha',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
            
            const SizedBox(height: 24),
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedProductId.isEmpty ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: AppColors.primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
