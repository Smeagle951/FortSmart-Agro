import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/models/inventory.dart';
import '../../models/inventory_movement.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/inventory_movement_repository.dart';
import 'add_inventory_item_screen.dart';
import 'add_inventory_movement_screen.dart';

class InventoryDetailsScreen extends StatefulWidget {
  final InventoryItem item;

  const InventoryDetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  _InventoryDetailsScreenState createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> with SingleTickerProviderStateMixin {
  final InventoryRepository _repository = InventoryRepository();
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();
  late TabController _tabController;
  late InventoryItem _item;
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _item = widget.item;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Recarregar item para ter os dados mais atualizados
      final item = await _repository.getItemById(_item.id!);
      if (item != null) {
        _item = item;
      }

      // Carregar movimentações
      final movements = await _movementRepository.getMovementsByItemId(_item.id!);
      
      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erro ao carregar dados: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }

  Future<void> _navigateToEditItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddInventoryItemScreen(item: _item),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToAddMovement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddInventoryMovementScreen(item: _item),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o item "${_item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteItem();
    }
  }

  Future<void> _deleteItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.deleteItem(_item.id!);
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erro ao excluir item: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditItem,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Detalhes'),
            Tab(text: 'Movimentações'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMovementsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _navigateToAddMovement,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantidade atual',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_item.quantity} ${_item.unit}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (_item.unitPrice != null) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor unitário',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'R\$ ${_item.unitPrice!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'R\$ ${_item.totalValue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações do Item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Código', _item.code ?? 'Não informado'),
                  _buildInfoRow('Categoria', _item.category),
                  _buildInfoRow('Unidade', _item.unit),
                  _buildInfoRow('Fornecedor', _item.supplier ?? 'Não informado'),
                  _buildInfoRow('Localização', _item.location ?? 'Não informado'),
                  _buildInfoRow('Data de validade', _item.expirationDate ?? 'Não informado'),
                  _buildInfoRow('Observações', _item.notes ?? 'Não informado'),
                  _buildInfoRow('Criado em', _formatDate(_item.createdAt)),
                  _buildInfoRow('Atualizado em', _formatDate(_item.updatedAt)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsTab() {
    if (_movements.isEmpty) {
      return const Center(
        child: Text('Nenhuma movimentação registrada'),
      );
    }

    return ListView.builder(
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];
        final isPositive = movement.quantity > 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 4.0,
          ),
          child: ListTile(
            leading: CircleAvatar(
              // backgroundColor: isPositive ? Colors.green : Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
              child: Icon(
                isPositive ? Icons.add : Icons.remove,
                color: Colors.white,
              ),
            ),
            title: Text(
              isPositive ? 'Entrada' : 'Saída',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(movement.date)),
                if (movement.purpose.isNotEmpty)
                  Text('Motivo: ${movement.purpose}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : ''}${movement.quantity} ${_item.unit}',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ${movement.newQuantity} ${_item.unit}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
