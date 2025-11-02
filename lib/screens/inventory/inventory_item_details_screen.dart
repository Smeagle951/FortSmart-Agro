import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/models/inventory.dart';
import '../../repositories/inventory_repository.dart';
import '../../widgets/loading_indicator.dart';

class InventoryItemDetailsScreen extends StatefulWidget {
  final String itemId;

  const InventoryItemDetailsScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _InventoryItemDetailsScreenState createState() => _InventoryItemDetailsScreenState();
}

class _InventoryItemDetailsScreenState extends State<InventoryItemDetailsScreen> {
  final InventoryRepository _repository = InventoryRepository();
  bool _isLoading = true;
  InventoryItem? _item;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _item = await _repository.getItemById(widget.itemId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este item? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.deleteItem(widget.itemId as int);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir item: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editItem() {
    Navigator.pushNamed(
      context,
      '/add_inventory_item',
      arguments: {'itemId': widget.itemId},
    ).then((_) => _loadItem());
  }

  void _addMovement(bool isEntry) {
    Navigator.pushNamed(
      context,
      '/inventory/movement/form',
      arguments: {
        'itemId': widget.itemId,
        'isEntry': isEntry,
      },
    ).then((_) => _loadItem());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Item'),
        ),
        body: const LoadingIndicator(),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Item'),
        ),
        body: const Center(
          child: Text('Item não encontrado'),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editItem,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_item!.code != null && _item!.code!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Código: ${_item!.code}'),
                      ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Categoria:', _item!.category),
                    _buildInfoRow('Quantidade:', '${_item!.quantity} ${_item!.unit}'),
                    if (_item!.unitPrice != null)
                      _buildInfoRow('Preço Unitário:', currencyFormat.format(_item!.unitPrice)),
                    if (_item!.supplier != null && _item!.supplier!.isNotEmpty)
                      _buildInfoRow('Fornecedor:', _item!.supplier!),
                    if (_item!.location != null && _item!.location!.isNotEmpty)
                      _buildInfoRow('Localização:', _item!.location!),
                    if (_item!.expirationDate != null && _item!.expirationDate!.isNotEmpty)
                      _buildInfoRow(
                        'Data de Validade:',
                        dateFormat.format(DateTime.parse(_item!.expirationDate!)),
                      ),
                  ],
                ),
              ),
            ),
            if (_item!.notes != null && _item!.notes!.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observações',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_item!.notes!),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addMovement(true),
                    icon: const Icon(Icons.add),
                    label: const Text('Entrada'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addMovement(false),
                    icon: const Icon(Icons.remove),
                    label: const Text('Saída'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/inventory/movements',
                  arguments: {'itemId': widget.itemId},
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Ver Histórico de Movimentações'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
