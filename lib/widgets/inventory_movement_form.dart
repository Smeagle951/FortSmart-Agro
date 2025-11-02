import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';

/// Widget para exibir um formulário de registro de movimentação de estoque
class InventoryMovementForm extends StatefulWidget {
  final InventoryItem? item;
  final MovementType movementType;
  final InventoryMovement? initialMovement;
  final Function(InventoryMovement) onSave;
  final VoidCallback? onCancel;
  final bool showProductSelector;

  const InventoryMovementForm({
    Key? key,
    this.item,
    required this.movementType,
    this.initialMovement,
    required this.onSave,
    this.onCancel,
    this.showProductSelector = false,
  }) : super(key: key);

  @override
  State<InventoryMovementForm> createState() => _InventoryMovementFormState();
}

class _InventoryMovementFormState extends State<InventoryMovementForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _sourceController;
  late TextEditingController _documentNumberController;
  late TextEditingController _responsiblePersonController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  InventoryItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.item;
    
    // Inicializar com valores do movimento existente ou valores padrão
    final movement = widget.initialMovement;
    _quantityController = TextEditingController(
      text: movement?.quantity.toString() ?? '',
    );
    _unitPriceController = TextEditingController(
      text: movement?.unitPrice.toString() ?? '',
    );
    _sourceController = TextEditingController(
      text: movement?.source ?? '',
    );
    _documentNumberController = TextEditingController(
      text: movement?.documentNumber ?? '',
    );
    _responsiblePersonController = TextEditingController(
      text: movement?.responsiblePerson ?? '',
    );
    _notesController = TextEditingController(
      text: movement?.notes ?? '',
    );
    _selectedDate = movement?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _sourceController.dispose();
    _documentNumberController.dispose();
    _responsiblePersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (widget.showProductSelector && _selectedItem != null)
            _buildProductInfo(),
          _buildDateField(),
          const SizedBox(height: 16),
          _buildQuantityField(),
          const SizedBox(height: 16),
          _buildUnitPriceField(),
          const SizedBox(height: 16),
          _buildSourceField(),
          const SizedBox(height: 16),
          _buildDocumentField(),
          const SizedBox(height: 16),
          _buildResponsibleField(),
          const SizedBox(height: 16),
          _buildNotesField(),
          const SizedBox(height: 24),
          _buildButtons(),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho do formulário
  Widget _buildHeader() {
    String title;
    Color color;
    IconData icon;
    
    switch (widget.movementType) {
      case MovementType.entry:
        title = 'Entrada de Estoque';
        color = Colors.green;
        icon = Icons.add_circle;
        break;
      case MovementType.exit:
        title = 'Saída de Estoque';
        color = Colors.red;
        icon = Icons.remove_circle;
        break;
      case MovementType.adjustment:
        title = 'Ajuste de Estoque';
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case MovementType.transfer:
        title = 'Transferência de Estoque';
        color = Colors.purple;
        icon = Icons.swap_horiz;
        break;
      case MovementType.application:
        title = 'Aplicação de Produto';
        color = Colors.teal;
        icon = Icons.eco;
        break;
    }
    
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de informações do produto
  Widget _buildProductInfo() {
    if (_selectedItem == null) return const SizedBox();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedItem!.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedItem!.category} | ${_selectedItem!.type}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
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
                      Text(
                        '${_selectedItem!.quantity.toStringAsFixed(2)} ${_selectedItem!.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                        'Estoque Mínimo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_selectedItem!.minimumStock.toStringAsFixed(2)} ${_selectedItem!.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o campo de data
  Widget _buildDateField() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return InkWell(
      // onTap: _selectDate, // onTap não é suportado em Polygon no flutter_map 5.0.0
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          dateFormat.format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Constrói o campo de quantidade
  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Quantidade',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixText: _selectedItem?.unit ?? '',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe a quantidade';
        }
        final quantity = double.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'Quantidade deve ser maior que zero';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de preço unitário
  Widget _buildUnitPriceField() {
    return TextFormField(
      controller: _unitPriceController,
      decoration: InputDecoration(
        labelText: 'Preço Unitário (R\$)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixText: 'R\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Preço unitário é opcional
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Preço deve ser um valor válido';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de origem/destino
  Widget _buildSourceField() {
    String label;
    
    switch (widget.movementType) {
      case MovementType.entry:
        label = 'Fornecedor';
        break;
      case MovementType.exit:
        label = 'Destino';
        break;
      case MovementType.transfer:
        label = 'Destino da Transferência';
        break;
      default:
        label = 'Origem/Destino';
    }
    
    return TextFormField(
      controller: _sourceController,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Constrói o campo de documento
  Widget _buildDocumentField() {
    return TextFormField(
      controller: _documentNumberController,
      decoration: InputDecoration(
        labelText: 'Número do Documento (NF/Pedido)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Constrói o campo de responsável
  Widget _buildResponsibleField() {
    return TextFormField(
      controller: _responsiblePersonController,
      decoration: InputDecoration(
        labelText: 'Responsável',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Constrói o campo de observações
  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Observações',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      maxLines: 3,
    );
  }

  /// Constrói os botões de ação
  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onCancel != null)
          OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('Cancelar'),
          ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _saveMovement,
          icon: const Icon(Icons.save),
          label: const Text('Salvar'),
        ),
      ],
    );
  }

  /// Exibe o seletor de data
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Salva a movimentação
  void _saveMovement() {
    if (_formKey.currentState!.validate() && _selectedItem != null) {
      final quantity = double.parse(_quantityController.text);
      final unitPrice = _unitPriceController.text.isNotEmpty
          ? double.parse(_unitPriceController.text)
          : 0.0;
      
      final movement = InventoryMovement(
        id: widget.initialMovement?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        inventoryItemId: _selectedItem!.id ?? '',
        type: widget.movementType,
        date: _selectedDate,
        quantity: quantity,
        purpose: _sourceController.text,
        responsiblePerson: _responsiblePersonController.text,
        documentNumber: _documentNumberController.text,
        itemName: _selectedItem!.name,
        itemUnit: _selectedItem!.unit,
        reason: _notesController.text,
      );
      
      widget.onSave(movement);
    }
  }
}

/// Widget para exibir um diálogo de confirmação de movimentação
class InventoryMovementConfirmationDialog extends StatelessWidget {
  final InventoryItem item;
  final InventoryMovement movement;
  final VoidCallback onConfirm;

  const InventoryMovementConfirmationDialog({
    Key? key,
    required this.item,
    required this.movement,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isEntry = movement.type == MovementType.entry;
    final isExit = movement.type == MovementType.exit;
    
    // Verificar se a saída excede o estoque disponível
    final isExceedingStock = isExit && movement.quantity > item.quantity;
    
    return AlertDialog(
      title: Text(
        isEntry ? 'Confirmar Entrada' : 'Confirmar Saída',
        style: TextStyle(
          color: isEntry ? Colors.green : Colors.red,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produto: ${item.name}'),
          const SizedBox(height: 8),
          Text('Data: ${dateFormat.format(movement.date)}'),
          const SizedBox(height: 8),
          Text('Quantidade: ${movement.quantity.toStringAsFixed(2)} ${movement.unit}'),
          if (movement.unitPrice > 0) ...[
            const SizedBox(height: 8),
            Text('Preço Unitário: R\$ ${movement.unitPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Valor Total: R\$ ${(movement.quantity * movement.unitPrice).toStringAsFixed(2)}'),
          ],
          const SizedBox(height: 16),
          Text(
            'Estoque Atual: ${item.quantity.toStringAsFixed(2)} ${item.unit}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Estoque Após Movimentação: ${_calculateNewStock().toStringAsFixed(2)} ${item.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExceedingStock ? Colors.red : null,
            ),
          ),
          if (isExceedingStock) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atenção: Esta saída excede o estoque disponível!',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            // backgroundColor: isExceedingStock ? Colors.red : null, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  /// Calcula o novo estoque após a movimentação
  double _calculateNewStock() {
    switch (movement.type) {
      case MovementType.entry:
        return item.quantity + movement.quantity;
      case MovementType.exit:
      case MovementType.application:
        return item.quantity - movement.quantity;
      case MovementType.adjustment:
        return movement.quantity; // Ajuste define o valor diretamente
      case MovementType.transfer:
        return item.quantity - movement.quantity;
    }
  }
}

/// Função para exibir o diálogo de confirmação de movimentação
Future<bool> showMovementConfirmationDialog({
  required BuildContext context,
  required InventoryItem item,
  required InventoryMovement movement,
  required VoidCallback onConfirm,
}) async {
  bool confirmed = false;
  
  await showDialog(
    context: context,
    builder: (context) => InventoryMovementConfirmationDialog(
      item: item,
      movement: movement,
      onConfirm: () {
        confirmed = true;
        onConfirm();
      },
    ),
  );
  
  return confirmed;
}

