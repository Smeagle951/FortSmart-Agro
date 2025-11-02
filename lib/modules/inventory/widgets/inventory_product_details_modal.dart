import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../models/product_class_model.dart';
import '../../shared/utils/app_colors.dart';

/// Modal para exibir detalhes de um produto do inventário
class InventoryProductDetailsModal extends StatelessWidget {
  final InventoryProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(InventoryTransactionModel)? onProductUpdated;

  const InventoryProductDetailsModal({
    Key? key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onProductUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ProductClassHelper.getIcon(product.productClass),
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Conteúdo
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('Informações Básicas', [
                      _buildInfoRow('Nome', product.name),
                      _buildInfoRow('Tipo', product.type.toString().split('.').last),
                      _buildInfoRow('Classe', ProductClassHelper.getName(product.productClass)),
                      _buildInfoRow('Unidade', product.unit),
                    ]),
                    
                    const SizedBox(height: 20),
                    _buildInfoSection('Estoque', [
                      _buildInfoRow('Quantidade', '${product.quantity.toStringAsFixed(2)} ${product.unit}'),
                      _buildInfoRow('Estoque Mínimo', '${product.minimumStock.toStringAsFixed(2)} ${product.unit}'),
                      _buildInfoRow('Status', _getStockStatusText()),
                    ]),
                    
                    const SizedBox(height: 20),
                    _buildInfoSection('Lote e Validade', [
                      _buildInfoRow('Número do Lote', product.batchNumber),
                      _buildInfoRow('Data de Entrada', dateFormat.format(product.entryDate)),
                      _buildInfoRow('Data de Vencimento', dateFormat.format(product.expirationDate)),
                    ]),
                    
                    if (product.supplier != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection('Fornecedor', [
                        _buildInfoRow('Fornecedor', product.supplier!),
                        if (product.invoiceNumber != null)
                          _buildInfoRow('Nota Fiscal', product.invoiceNumber!),
                      ]),
                    ],
                    
                    if (product.pricePerUnit != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection('Preço', [
                        _buildInfoRow('Preço por Unidade', currencyFormat.format(product.pricePerUnit!)),
                        _buildInfoRow('Valor Total', currencyFormat.format(product.pricePerUnit! * product.quantity)),
                      ]),
                    ],
                    
                    if (product.notes != null && product.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection('Observações', [
                        _buildInfoRow('', product.notes!),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            
            // Botões de ação
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (onDelete != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(width: 12),
                  if (onEdit != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStockStatusText() {
    if (product.isExpired) return 'Vencido';
    if (product.isStockCritical) return 'Crítico';
    if (product.isStockLow) return 'Baixo';
    if (product.isNearExpiration) return 'Próximo do Vencimento';
    return 'OK';
  }
}
