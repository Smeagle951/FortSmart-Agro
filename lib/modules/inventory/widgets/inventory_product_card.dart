import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product_model.dart';
import '../models/product_class_model.dart';
import '../../shared/utils/app_colors.dart';
import '../../../models/agricultural_product.dart';

class InventoryProductCard extends StatelessWidget {
  final InventoryProductModel product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onStockMovement;
  final VoidCallback? onDelete;

  const InventoryProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onHistory,
    required this.onStockMovement,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Formatadores
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    final quantityFormat = NumberFormat.decimalPattern('pt_BR');

    // Determinar cor de status
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (product.isExpired) {
      statusColor = AppColors.secondary;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Vencido';
    } else if (product.isStockCritical) {
      statusColor = AppColors.danger;
      statusIcon = Icons.error_outline;
      statusText = 'Crítico';
    } else if (product.isStockLow) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_outlined;
      statusText = 'Baixo';
    } else if (product.isNearExpiration) {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = 'Venc. Próximo';
    } else {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusText = 'OK';
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do card com nome e status
            Container(
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Corpo do card com informações do produto
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha 1: Classe e Tipo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Classe',
                          ProductClassHelper.getName(product.productClass),
                          ProductClassHelper.getIcon(product.productClass),
                          valueColor: ProductClassHelper.getColor(product.productClass),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Tipo',
                          _getProductTypeName(product.type),
                          Icons.category,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Linha 2: Unidade
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Unidade',
                          product.unit,
                          Icons.straighten,
                        ),
                      ),
                      // Espaço vazio para manter o layout equilibrado
                      Expanded(child: Container()),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Linha 2: Quantidade e Vencimento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Quantidade',
                          '${quantityFormat.format(product.quantity)} ${product.unit}',
                          Icons.inventory_2,
                          valueColor: product.isStockLow || product.isStockCritical
                              ? AppColors.warning
                              : null,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Vencimento',
                          product.expirationDate != null
                              ? dateFormat.format(product.expirationDate!)
                              : 'N/A',
                          Icons.event,
                          valueColor: product.isNearExpiration || product.isExpired
                              ? AppColors.warning
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Linha 3: Lote e Fornecedor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Lote',
                          product.batchNumber,
                          Icons.qr_code,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Fornecedor',
                          product.supplier ?? 'N/A',
                          Icons.business,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Linha 4: Custo unitário
                  if (product.unitCost != null)
                    _buildInfoItem(
                      'Custo Unitário',
                      currencyFormat.format(product.unitCost),
                      Icons.attach_money,
                    ),
                ],
              ),
            ),
            
            // Barra de ações
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botão Editar
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.primary),
                    onPressed: onEdit,
                    tooltip: 'Editar',
                  ),
                  // Botão Histórico
                  IconButton(
                    icon: Icon(Icons.history, color: AppColors.info),
                    onPressed: onHistory,
                    tooltip: 'Histórico de uso',
                  ),
                  // Botão Movimentação
                  IconButton(
                    icon: Icon(Icons.swap_vert, color: AppColors.success),
                    onPressed: onStockMovement,
                    tooltip: 'Entrada/Saída',
                  ),
                  // Botão Excluir (opcional)
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.danger),
                      onPressed: onDelete,
                      tooltip: 'Remover',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textLight,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getProductTypeName(ProductType type) {
    switch (type) {
      case ProductType.insecticide:
        return 'Inseticida';
      case ProductType.herbicide:
        return 'Herbicida';
      case ProductType.fungicide:
        return 'Fungicida';
      case ProductType.fertilizer:
        return 'Fertilizante';
      case ProductType.seed:
        return 'Semente';
      case ProductType.adjuvant:
        return 'Adjuvante';
      case ProductType.growth:
        return 'Regulador de Crescimento';
      case ProductType.other:
        return 'Outro';
      default:
        return 'Desconhecido';
    }
  }
}
