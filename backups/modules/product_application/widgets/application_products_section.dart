import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_application_model.dart';
import '../../../utils/app_colors.dart';

class ApplicationProductsSection extends StatelessWidget {
  final List<ApplicationProductModel> products;
  final double area;
  final Function(List<ApplicationProductModel>) onProductsChanged;
  final Function() onAddProduct;
  
  const ApplicationProductsSection({
    Key? key,
    required this.products,
    required this.area,
    required this.onProductsChanged,
    required this.onAddProduct,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Produto'),
                  onPressed: area > 0 ? onAddProduct : null,
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: AppColors.primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (area <= 0)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Selecione um talhão para adicionar produtos',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Nenhum produto adicionado',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              _buildProductsTable(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductsTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Produto')),
          DataColumn(label: Text('Dose/ha')),
          DataColumn(label: Text('Dose Total')),
          DataColumn(label: Text('Unidade')),
          DataColumn(label: Text('Ações')),
        ],
        rows: products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text(product.productName)),
              DataCell(Text(product.dosePerHectare.toStringAsFixed(2))),
              DataCell(Text(product.totalDose.toStringAsFixed(2))),
              DataCell(Text(product.unit)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditProductDialog(context, product),
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _confirmDeleteProduct(context, product),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  void _showEditProductDialog(BuildContext context, ApplicationProductModel product) {
    final doseController = TextEditingController(text: product.dosePerHectare.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${product.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: doseController,
              decoration: InputDecoration(
                labelText: 'Dose por hectare (${product.unit})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Dose total: ${(double.tryParse(doseController.text) ?? 0 * area).toStringAsFixed(2)} ${product.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDose = double.tryParse(doseController.text) ?? 0;
              if (newDose > 0) {
                final updatedProduct = product.copyWith(
                  dosePerHectare: newDose,
                  totalDose: newDose * area,
                );
                
                final updatedProducts = products.map((p) {
                  return p.productId == product.productId ? updatedProduct : p;
                }).toList();
                
                onProductsChanged(updatedProducts);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteProduct(BuildContext context, ApplicationProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Produto'),
        content: Text('Deseja remover ${product.productName} da aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final updatedProducts = products
                  .where((p) => p.productId != product.productId)
                  .toList();
              
              onProductsChanged(updatedProducts);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
