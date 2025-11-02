import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:intl/intl.dart';

/// Widget para exibir um card de movimentação de estoque
class InventoryMovementCard extends StatelessWidget {
  final InventoryMovement movement;
  final String productName;
  final String productCategory;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InventoryMovementCard({
    Key? key,
    required this.movement,
    required this.productName,
    required this.productCategory,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getMovementColor().withOpacity(0.3),
          width: 1,
        ),
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
              _buildMovementDetails(context),
              const SizedBox(height: 8),
              _buildAdditionalInfo(context),
              if (onDelete != null) ...[
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
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMovementIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Data: ${dateFormat.format(movement.date)} | ${productCategory}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
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

  /// Constrói o ícone da movimentação
  Widget _buildMovementIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getMovementColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getMovementIcon(),
        color: _getMovementColor(),
        size: 24,
      ),
    );
  }

  /// Constrói os detalhes da movimentação
  Widget _buildMovementDetails(BuildContext context) {
    final isPositive = movement.type == MovementType.entry;
    final sign = isPositive ? '+' : '-';
    final color = _getMovementColor();
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantidade',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$sign${movement.quantity.toStringAsFixed(2)} ${movement.unit}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (movement.unitPrice > 0)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preço Unitário',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'R\$ ${movement.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valor Total',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'R\$ ${(movement.quantity * movement.unitPrice).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói informações adicionais da movimentação
  Widget _buildAdditionalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movement?.source?.isNotEmpty ?? false) ...[
          _buildInfoRow(
            context,
            isEntry() ? 'Fornecedor:' : 'Destino:',
            movement?.source ?? '',
          ),
        ],
        if (movement?.documentNumber?.isNotEmpty ?? false) ...[
          _buildInfoRow(
            context,
            'Documento:',
            movement?.documentNumber ?? '',
          ),
        ],
        if (movement.responsiblePerson.isNotEmpty) ...[
          _buildInfoRow(
            context,
            'Responsável:',
            movement?.responsiblePerson ?? '',
          ),
        ],
        if (movement?.notes?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            'Observações:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            movement.notes,
            style: const TextStyle(
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Constrói uma linha de informação
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói as ações do card
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
          label: const Text(
            'Excluir',
            style: TextStyle(color: Colors.red),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 36),
          ),
        ),
      ],
    );
  }

  /// Retorna o ícone da movimentação com base no tipo
  IconData _getMovementIcon() {
    switch (movement.type) {
      case MovementType.entry:
        return Icons.add_circle;
      case MovementType.exit:
        return Icons.remove_circle;
      case MovementType.adjustment:
        return Icons.sync;
      case MovementType.transfer:
        return Icons.swap_horiz;
      case MovementType.application:
        return Icons.eco;
    }
  }

  /// Retorna a cor da movimentação com base no tipo
  Color _getMovementColor() {
    switch (movement.type) {
      case MovementType.entry:
        return Colors.green;
      case MovementType.exit:
        return Colors.red;
      case MovementType.adjustment:
        return Colors.blue;
      case MovementType.transfer:
        return Colors.purple;
      case MovementType.application:
        return Colors.orange;
    }
  }

  /// Verifica se a movimentação é de entrada
  bool isEntry() {
    return movement.type == MovementType.entry;
  }
}

/// Widget para exibir uma lista de movimentações de estoque
class InventoryMovementList extends StatelessWidget {
  final List<InventoryMovementData> movements;
  final Function(String) onItemTap;
  final Function(String)? onDeleteMovement;

  const InventoryMovementList({
    Key? key,
    required this.movements,
    required this.onItemTap,
    this.onDeleteMovement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma movimentação encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há registros de movimentação para o período selecionado',
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
      itemCount: movements.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final data = movements[index];
        
        return InventoryMovementCard(
          movement: data.movement,
          productName: data.productName,
          productCategory: data.productCategory,
          // onTap: () => onItemTap(data.movement.id), // onTap não é suportado em Polygon no flutter_map 5.0.0
          onDelete: onDeleteMovement != null && data.movement.id != null ? () => onDeleteMovement!(data.movement.id!) : null,
        );
      },
    );
  }
}

/// Classe para armazenar dados de movimentação com informações do produto
class InventoryMovementData {
  final InventoryMovement movement;
  final String productName;
  final String productCategory;
  
  InventoryMovementData({
    required this.movement,
    required this.productName,
    required this.productCategory,
  });
}

