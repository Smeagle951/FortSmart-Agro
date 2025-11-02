import 'package:flutter/material.dart';
import '../../../models/calda/product.dart';

class DraggableProductList extends StatefulWidget {
  final List<Product> products;
  final Function(List<Product>) onReorder;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const DraggableProductList({
    Key? key,
    required this.products,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DraggableProductList> createState() => _DraggableProductListState();
}

class _DraggableProductListState extends State<DraggableProductList> {
  late List<Product> _products;

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
  }

  @override
  void didUpdateWidget(DraggableProductList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products != oldWidget.products) {
      _products = List.from(widget.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product, index);
      },
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return Card(
      key: ValueKey(product.name + index.toString()),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _getFormulationColor(product.formulation.code),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.manufacturer,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${product.formulation.code} • ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${product.dose} ${product.doseUnit.symbol}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
              onPressed: null, // O drag é controlado pelo ReorderableListView
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              onPressed: () => widget.onEdit(index),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () => widget.onDelete(index),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _products.removeAt(oldIndex);
      _products.insert(newIndex, item);
    });
    widget.onReorder(_products);
  }

  Color _getFormulationColor(String formulation) {
    switch (formulation) {
      case 'SL':
        return Colors.blue; // Soluções
      case 'EC':
      case 'SC':
        return Colors.green; // Líquidos solúveis
      case 'WG':
      case 'WP':
      case 'SP':
      case 'SG':
        return Colors.orange; // Sólidos
      case 'AD':
      case 'OD':
      case 'EO':
      case 'EW':
        return Colors.purple; // Adjuvantes
      default:
        return const Color(0xFF2E7D32);
    }
  }
}
