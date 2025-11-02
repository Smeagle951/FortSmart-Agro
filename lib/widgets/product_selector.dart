import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';

/// Widget para selecionar um produto do estoque
class ProductSelector extends StatefulWidget {
  final List<InventoryItem> products;
  final InventoryItem? selectedProduct;
  final Function(InventoryItem) onProductSelected;
  final String? label;
  final String? hint;
  final bool showStockInfo;
  final bool showOnlyAvailableProducts;
  final List<String>? categoryFilter;

  const ProductSelector({
    Key? key,
    required this.products,
    this.selectedProduct,
    required this.onProductSelected,
    this.label,
    this.hint,
    this.showStockInfo = true,
    this.showOnlyAvailableProducts = false,
    this.categoryFilter,
  }) : super(key: key);

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  late InventoryItem? _selectedProduct;
  late List<InventoryItem> _filteredProducts;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.selectedProduct;
    _filterProducts();
  }

  @override
  void didUpdateWidget(ProductSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products ||
        oldWidget.selectedProduct != widget.selectedProduct ||
        oldWidget.categoryFilter != widget.categoryFilter ||
        oldWidget.showOnlyAvailableProducts != widget.showOnlyAvailableProducts) {
      _selectedProduct = widget.selectedProduct;
      _filterProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtra a lista de produtos com base nos critérios definidos
  void _filterProducts() {
    _filteredProducts = widget.products.where((product) {
      // Filtrar por categoria
      if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
        if (!widget.categoryFilter!.contains(product.category)) {
          return false;
        }
      }
      
      // Filtrar produtos sem estoque
      if (widget.showOnlyAvailableProducts && product.quantity <= 0) {
        return false;
      }
      
      // Filtrar por texto de busca
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return product.name.toLowerCase().contains(searchTerm) ||
            (product.category?.toLowerCase() ?? '').contains(searchTerm) ||
            (product.formulation?.toLowerCase() ?? '').contains(searchTerm);
      }
      
      return true;
    }).toList();
    
    // Ordenar por nome
    _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildProductList(),
      ],
    );
  }

  /// Constrói o campo de busca
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar produto...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _filterProducts();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _filterProducts();
        });
      },
    );
  }

  /// Constrói a lista de produtos
  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return Container(
        height: 200,
        // alignment: Alignment.center, // alignment não é suportado em Marker no flutter_map 5.0.0
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredProducts.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final isSelected = _selectedProduct?.id == product.id;
          
          return ListTile(
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.category} | ${product.type}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.showStockInfo) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Estoque: ${product.quantity.toStringAsFixed(2)} ${product.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: (product.quantity ?? 0) <= (product.minimumLevel ?? 0) ? Colors.orange : Colors.green[700],
                      fontWeight: (product.quantity ?? 0) <= (product.minimumLevel ?? 0) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
            leading: _buildCategoryIcon(product),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                : null,
            selected: isSelected,
            onTap: () {
              _selectProduct(product);
            },
          );
        },
      ),
    );
  }

  void _selectProduct(InventoryItem product) {
    setState(() {
      _selectedProduct = product;
    });
    widget.onProductSelected(product);
  }

  /// Constrói o ícone de categoria do produto
  Widget _buildCategoryIcon(InventoryItem product) {
    IconData iconData;
    Color iconColor;
    
    // Definir ícone com base na categoria
    switch (product.category?.toLowerCase() ?? 'outro') {
      case 'herbicida':
        iconData = Icons.grass;
        iconColor = Colors.green;
        break;
      case 'inseticida':
        iconData = Icons.bug_report;
        iconColor = Colors.orange;
        break;
      case 'fungicida':
        iconData = Icons.coronavirus;
        iconColor = Colors.purple;
        break;
      case 'fertilizante':
        iconData = Icons.spa;
        iconColor = Colors.blue;
        break;
      case 'adubo':
        iconData = Icons.eco;
        iconColor = Colors.green[700]!;
        break;
      case 'semente':
        iconData = Icons.grain;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.science;
        iconColor = Colors.grey[700]!;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
}

/// Widget para exibir um diálogo de seleção de produto
class ProductSelectorDialog extends StatefulWidget {
  final List<InventoryItem> products;
  final InventoryItem? selectedProduct;
  final String title;
  final bool showStockInfo;
  final bool showOnlyAvailableProducts;
  final List<String>? categoryFilter;

  const ProductSelectorDialog({
    Key? key,
    required this.products,
    this.selectedProduct,
    this.title = 'Selecionar Produto',
    this.showStockInfo = true,
    this.showOnlyAvailableProducts = false,
    this.categoryFilter,
  }) : super(key: key);

  @override
  State<ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<ProductSelectorDialog> {
  InventoryItem? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.selectedProduct;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: ProductSelector(
                products: widget.products,
                selectedProduct: _selectedProduct,
                onProductSelected: (product) {
                  setState(() {
                    _selectedProduct = product;
                  });
                },
                showStockInfo: widget.showStockInfo,
                showOnlyAvailableProducts: widget.showOnlyAvailableProducts,
                categoryFilter: widget.categoryFilter,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedProduct != null
                      ? () => Navigator.of(context).pop(_selectedProduct)
                      : null,
                  child: const Text('Selecionar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Função para exibir o diálogo de seleção de produto
Future<InventoryItem?> showProductSelectorDialog({
  required BuildContext context,
  required List<InventoryItem> products,
  InventoryItem? selectedProduct,
  String title = 'Selecionar Produto',
  bool showStockInfo = true,
  bool showOnlyAvailableProducts = false,
  List<String>? categoryFilter,
}) async {
  return showDialog<InventoryItem>(
    context: context,
    builder: (context) => ProductSelectorDialog(
      products: products,
      selectedProduct: selectedProduct,
      title: title,
      showStockInfo: showStockInfo,
      showOnlyAvailableProducts: showOnlyAvailableProducts,
      categoryFilter: categoryFilter,
    ),
  );
}

