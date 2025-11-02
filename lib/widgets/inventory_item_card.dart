import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';

/// Widget para exibir um card de item de estoque
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddMovement;
  final VoidCallback? onRemoveMovement;

  const InventoryItemCard({
    Key? key,
    required this.item,
    this.onTap,
    this.onAddMovement,
    this.onRemoveMovement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildStockInfo(context),
              if (item.expirationDate != null) ...[
                const SizedBox(height: 8),
                _buildExpirationInfo(context),
              ],
              if (onAddMovement != null || onRemoveMovement != null) ...[
                const SizedBox(height: 8),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho do card
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryIcon(context),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.category} | ${item.type}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.manufacturer != null && item.manufacturer!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Fabricante: ${item.manufacturer}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói o ícone de categoria
  Widget _buildCategoryIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    // Definir ícone com base na categoria
    switch ((item.category ?? item.type).toLowerCase()) {
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

  /// Constrói as informações de estoque
  Widget _buildStockInfo(BuildContext context) {
    final isLowStock = item.isLowStock();
    final stockColor = isLowStock ? Colors.orange : Colors.green[700];
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estoque Atual',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${item.quantity.toStringAsFixed(2)} ${item.unit}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                  if (isLowStock) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estoque Mínimo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${item.minimumStock.toStringAsFixed(2)} ${item.unit}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  /// Constrói as informações de validade
  Widget _buildExpirationInfo(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isExpired = item.isExpired();
    final isNearExpiration = item.isNearExpiration();
    
    Color textColor = Colors.black87;
    if (isExpired) {
      textColor = Colors.red;
    } else if (isNearExpiration) {
      textColor = Colors.orange;
    }
    
    return Row(
      children: [
        Icon(
          isExpired ? Icons.warning : Icons.event,
          color: textColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          'Validade: ${dateFormat.format(item.expirationDate!)}',
          style: TextStyle(
            color: textColor,
            fontWeight: isExpired || isNearExpiration ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isExpired || isNearExpiration) ...[
          const SizedBox(width: 4),
          Text(
            isExpired ? '(Vencido)' : '(Próximo)',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  /// Constrói as ações do card
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onAddMovement != null)
          TextButton.icon(
            onPressed: onAddMovement,
            icon: const Icon(Icons.add_circle, size: 16),
            label: const Text('Entrada'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
        if (onRemoveMovement != null)
          TextButton.icon(
            onPressed: onRemoveMovement,
            icon: const Icon(Icons.remove_circle, size: 16),
            label: const Text('Saída'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
      ],
    );
  }
}

/// Widget para exibir uma grade de cards de itens de estoque
class InventoryItemGrid extends StatelessWidget {
  final List<InventoryItem> items;
  final Function(InventoryItem) onItemTap;
  final Function(InventoryItem)? onAddMovement;
  final Function(InventoryItem)? onRemoveMovement;
  final int crossAxisCount;
  final double childAspectRatio;

  const InventoryItemGrid({
    Key? key,
    required this.items,
    required this.onItemTap,
    this.onAddMovement,
    this.onRemoveMovement,
    this.crossAxisCount = 1,
    this.childAspectRatio = 2.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum item encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione itens ao estoque ou ajuste os filtros',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        
        return InventoryItemCard(
          item: item,
          // onTap: () => onItemTap(item), // onTap não é suportado em Polygon no flutter_map 5.0.0
          onAddMovement: onAddMovement != null ? () => onAddMovement!(item) : null,
          onRemoveMovement: onRemoveMovement != null ? () => onRemoveMovement!(item) : null,
        );
      },
    );
  }
}

