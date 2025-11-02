import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';

/// Widget para exibir alertas relacionados a itens de estoque
class InventoryAlertCard extends StatelessWidget {
  final InventoryItem item;
  final AlertType alertType;
  final VoidCallback? onTap;

  const InventoryAlertCard({
    Key? key,
    required this.item,
    this.alertType = AlertType.lowStock,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getAlertColor(alertType).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildAlertIcon(),
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
                    const SizedBox(height: 4),
                    Text(
                      _getAlertMessage(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o ícone de alerta
  Widget _buildAlertIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getAlertColor(alertType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getAlertIcon(alertType),
        color: _getAlertColor(alertType),
        size: 24,
      ),
    );
  }

  /// Retorna a cor do alerta com base no tipo
  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.lowStock:
        return Colors.orange;
      case AlertType.outOfStock:
        return Colors.red;
      case AlertType.nearExpiration:
        return Colors.amber;
      case AlertType.expired:
        return Colors.red;
    }
  }

  /// Retorna o ícone do alerta com base no tipo
  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.lowStock:
        return Icons.inventory_2;
      case AlertType.outOfStock:
        return Icons.inventory;
      case AlertType.nearExpiration:
        return Icons.access_time;
      case AlertType.expired:
        return Icons.warning;
    }
  }

  /// Retorna a mensagem do alerta com base no tipo
  String _getAlertMessage() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    switch (alertType) {
      case AlertType.lowStock:
        return 'Estoque baixo: ${item.quantity.toStringAsFixed(2)} ${item.unit} (mínimo: ${item.minimumStock.toStringAsFixed(2)})';
      case AlertType.outOfStock:
        return 'Produto sem estoque! Quantidade atual: ${item.quantity.toStringAsFixed(2)} ${item.unit}';
      case AlertType.nearExpiration:
        if (item.expirationDate != null) {
          final daysToExpire = item.expirationDate!.difference(DateTime.now()).inDays;
          return 'Vencimento próximo: ${dateFormat.format(item.expirationDate!)} (${daysToExpire} dias)';
        }
        return 'Vencimento próximo';
      case AlertType.expired:
        if (item.expirationDate != null) {
          final daysExpired = DateTime.now().difference(item.expirationDate!).inDays;
          return 'Produto vencido: ${dateFormat.format(item.expirationDate!)} (há ${daysExpired} dias)';
        }
        return 'Produto vencido';
    }
  }
}

/// Widget para exibir uma lista de alertas de estoque
class InventoryAlertList extends StatelessWidget {
  final List<InventoryItem> items;
  final Function(InventoryItem) onItemTap;
  final bool showExpired;
  final bool showLowStock;
  final bool showNearExpiration;

  const InventoryAlertList({
    Key? key,
    required this.items,
    required this.onItemTap,
    this.showExpired = true,
    this.showLowStock = true,
    this.showNearExpiration = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrar e classificar itens com alertas
    final alertItems = _getAlertItems();
    
    if (alertItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum alerta encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todos os produtos estão com estoque adequado e dentro do prazo de validade',
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
    
    return ListView.builder(
      itemCount: alertItems.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = alertItems[index].item;
        final alertType = alertItems[index].alertType;
        
        return InventoryAlertCard(
          item: item,
          alertType: alertType,
          // onTap: () => onItemTap(item), // onTap não é suportado em Polygon no flutter_map 5.0.0
        );
      },
    );
  }

  /// Retorna a lista de itens com alertas
  List<ItemAlert> _getAlertItems() {
    final List<ItemAlert> alertItems = [];
    
    for (final item in items) {
      // Verificar produtos vencidos
      if (showExpired && item.isExpired()) {
        alertItems.add(ItemAlert(item, AlertType.expired));
        continue; // Priorizar alerta de vencido sobre outros alertas
      }
      
      // Verificar produtos próximos do vencimento
      if (showNearExpiration && item.isNearExpiration()) {
        alertItems.add(ItemAlert(item, AlertType.nearExpiration));
      }
      
      // Verificar produtos sem estoque
      if (item.quantity <= 0) {
        alertItems.add(ItemAlert(item, AlertType.outOfStock));
        continue; // Priorizar alerta de sem estoque sobre estoque baixo
      }
      
      // Verificar produtos com estoque baixo
      if (showLowStock && item.isLowStock()) {
        alertItems.add(ItemAlert(item, AlertType.lowStock));
      }
    }
    
    // Ordenar alertas por prioridade
    alertItems.sort((a, b) {
      // Primeiro por tipo de alerta (prioridade)
      final priorityComparison = a.alertType.index.compareTo(b.alertType.index);
      if (priorityComparison != 0) return priorityComparison;
      
      // Em seguida por nome do produto
      return a.item.name.compareTo(b.item.name);
    });
    
    return alertItems;
  }
}

/// Classe auxiliar para associar um item a um tipo de alerta
class ItemAlert {
  final InventoryItem item;
  final AlertType alertType;
  
  ItemAlert(this.item, this.alertType);
}

/// Enum que define os tipos de alerta
enum AlertType {
  /// Produto vencido
  expired,
  
  /// Produto sem estoque
  outOfStock,
  
  /// Produto próximo do vencimento
  nearExpiration,
  
  /// Produto com estoque baixo
  lowStock,
}

