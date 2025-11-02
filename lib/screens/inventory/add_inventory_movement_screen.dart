import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/models/inventory.dart';
import '../../database/models/inventory_movement.dart' as db;
import '../../models/inventory_movement.dart';
import '../../repositories/inventory_movement_repository.dart';
import '../../repositories/inventory_repository.dart';
// Módulo de atividades removido

class AddInventoryMovementScreen extends StatefulWidget {
  final InventoryItem item;
  final db.InventoryMovement? movement;

  const AddInventoryMovementScreen({
    Key? key,
    required this.item,
    this.movement,
  }) : super(key: key);

  @override
  _AddInventoryMovementScreenState createState() =>
      _AddInventoryMovementScreenState();
}

class _AddInventoryMovementScreenState
    extends State<AddInventoryMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  final InventoryMovementRepository _movementRepository =
      InventoryMovementRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();
  // Módulo de atividades removido

  bool _isLoading = false;
  bool _isEntrada = true;
  int? _selectedActivityId;
  // Módulo de atividades removido

  @override
  void initState() {
    super.initState();
    if (widget.movement != null) {
      _quantityController.text = widget.movement!.quantity.toString();
      _isEntrada = widget.movement!.quantity > 0;
      _reasonController.text = widget.movement!.reason;
      _notesController.text = widget.movement!.notes ?? '';
      _selectedActivityId = widget.movement!.activityId != null ? int.tryParse(widget.movement!.activityId!) : null;
    }
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      // Módulo de atividades removido
      setState(() {
        // Filtrando apenas atividades não concluídas
        // Módulo de atividades removido
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar atividades: $e');
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double quantity = double.parse(_quantityController.text);
      if (!_isEntrada) {
        quantity = -quantity;
      }

      // Verificar se há quantidade suficiente para saída
      if (quantity < 0 && widget.item.quantity + quantity < 0) {
        _showErrorSnackBar(
            'Quantidade insuficiente em estoque para esta saída');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Calcular nova quantidade
      final double newQuantity = widget.item.quantity + quantity;

      // Criar movimento
      final movement = InventoryMovement(
        id: widget.movement?.id != null ? widget.movement!.id.toString() : null,
        inventoryItemId: widget.item.id.toString(),
        type: MovementType.entry, // Entrada de estoque
        quantity: quantity,
        purpose: _reasonController.text.isEmpty ? 'Entrada de estoque' : _reasonController.text,
        responsiblePerson: 'Usuário',
        date: DateTime.now(),
        documentNumber: _notesController.text.isEmpty ? null : _notesController.text,
        relatedDocumentId: _selectedActivityId?.toString(),
        previousQuantity: widget.item.quantity,
        newQuantity: newQuantity,
        syncStatus: 0,
      );

      // Salvar movimento
      if (widget.movement == null) {
        await _movementRepository.addMovement(movement);
      } else {
        await _movementRepository.updateMovement(movement);
      }

      // Atualizar quantidade do item
      final updatedItem = InventoryItem(
        id: widget.item.id,
        name: widget.item.name,
        code: widget.item.code,
        category: widget.item.category,
        quantity: newQuantity,
        unit: widget.item.unit,
        unitPrice: widget.item.unitPrice,
        supplier: widget.item.supplier,
        location: widget.item.location,
        expirationDate: widget.item.expirationDate,
        notes: widget.item.notes,
        createdAt: widget.item.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
        remoteId: widget.item.remoteId,
      );

      await _inventoryRepository.updateItem(updatedItem);

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
      _showErrorSnackBar('Erro ao salvar movimentação: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movement == null
            ? 'Nova Movimentação'
            : 'Editar Movimentação'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item: ${widget.item.name}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Estoque atual: ${widget.item.quantity} ${widget.item.unit}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Entrada'),
                            value: true,
                            groupValue: _isEntrada,
                            onChanged: (value) {
                              setState(() {
                                _isEntrada = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Saída'),
                            value: false,
                            groupValue: _isEntrada,
                            onChanged: (value) {
                              setState(() {
                                _isEntrada = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantidade *',
                        border: const OutlineInputBorder(),
                        suffixText: widget.item.unit,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a quantidade';
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null) {
                          return 'Quantidade inválida';
                        }
                        if (quantity <= 0) {
                          return 'A quantidade deve ser maior que zero';
                        }
                        if (!_isEntrada && quantity > widget.item.quantity) {
                          return 'Quantidade insuficiente em estoque';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Módulo de atividades removido - DropdownButtonFormField comentado
                    // DropdownButtonFormField<int?>(
                    //   value: _selectedActivityId,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Atividade relacionada',
                    //     border: OutlineInputBorder(),
                    //   ),
                    //   items: [
                    //     const DropdownMenuItem<int?>(
                    //       value: null,
                    //       child: Text('Nenhuma'),
                    //     ),
                    //   ],
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _selectedActivityId = value;
                    //     });
                    //   },
                    // ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _saveMovement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(
                        widget.movement == null ? 'Registrar' : 'Salvar Alterações',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
