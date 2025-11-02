import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:fortsmart_agro/database/models/inventory.dart';
import 'package:fortsmart_agro/repositories/inventory_repository.dart';
import 'package:fortsmart_agro/repositories/inventory_movement_repository.dart';
import 'package:fortsmart_agro/services/auth_service.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';
import 'package:fortsmart_agro/widgets/date_picker_field.dart';

class InventoryMovementFormScreen extends StatefulWidget {
  final InventoryItem item;
  final MovementType movementType;
  
  const InventoryMovementFormScreen({
    Key? key, 
    required this.item, 
    required this.movementType,
  }) : super(key: key);

  @override
  _InventoryMovementFormScreenState createState() => _InventoryMovementFormScreenState();
}

class _InventoryMovementFormScreenState extends State<InventoryMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purposeController = TextEditingController();
  final _documentController = TextEditingController();
  
  final InventoryRepository _repository = InventoryRepository();
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();
  // Usando o AuthService criado
  final AuthService _authService = AuthService();
  
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    _documentController.dispose();
    super.dispose();
  }
  
  // Não precisamos mais converter o modelo, pois o próprio modelo já tem o método toDbModel()
  // que faz essa conversão automaticamente
  
  // Método para atualizar o item com a nova quantidade
  InventoryItem _updateItemQuantity(InventoryItem item, double newQuantity) {
    return item.copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
  
  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtém o usuário atual
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Converte a quantidade para double
      final quantity = double.parse(_quantityController.text.replaceAll(',', '.'));
      
      // Verifica se há estoque suficiente para saída
      if (widget.movementType == MovementType.exit && quantity > widget.item.quantity) {
        SnackbarHelper.showErrorSnackbar(
          context, 
          'Quantidade insuficiente em estoque. Disponível: ${widget.item.getFormattedQuantity()}'
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Cria o movimento usando o modelo adaptado
      final movement = InventoryMovement(
        inventoryItemId: widget.item.id.toString(),
        type: widget.movementType == MovementType.entry ? MovementType.entry : MovementType.exit,
        quantity: quantity,
        purpose: _purposeController.text,
        responsiblePerson: currentUser.name,
        date: _date,
        documentNumber: _documentController.text.isNotEmpty ? _documentController.text : null,
        previousQuantity: widget.item.quantity,
        newQuantity: widget.movementType == MovementType.entry 
            ? widget.item.quantity + quantity 
            : widget.item.quantity - quantity,
      );
      
      // Usando o método addMovement do repositório que já faz a conversão internamente
      final movementId = await _movementRepository.addMovement(movement);
      
      // Verifica se a movimentação foi registrada corretamente
      if (movementId <= 0) {
        throw Exception('Erro ao registrar movimentação');
      }
      
      // Atualiza a quantidade do item
      final newQuantity = widget.movementType == MovementType.entry
          ? widget.item.quantity + quantity
          : widget.item.quantity - quantity;
      
      final updatedItem = _updateItemQuantity(widget.item, newQuantity);
      
      await _repository.updateItem(updatedItem);

      // Retorna para a tela anterior
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao registrar movimentação: ${e.toString()}'
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEntry = widget.movementType == MovementType.entry;
    final title = isEntry ? 'Registrar Entrada' : 'Registrar Saída';
    final buttonColor = isEntry ? Colors.green : Colors.red;
    final buttonIcon = isEntry ? Icons.add_circle : Icons.remove_circle;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do produto
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Produto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.item.getFullName(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Estoque atual: ${widget.item.getFormattedQuantity()}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Formulário
                    Text(
                      'Informações da Movimentação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Quantidade
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantidade',
                        hintText: 'Informe a quantidade',
                        suffixText: widget.item.unit,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a quantidade';
                        }
                        
                        final quantity = double.tryParse(value.replaceAll(',', '.'));
                        if (quantity == null || quantity <= 0) {
                          return 'Quantidade deve ser maior que zero';
                        }
                        
                        if (widget.movementType == MovementType.exit && 
                            quantity > widget.item.quantity) {
                          return 'Quantidade maior que o estoque disponível';
                        }
                        
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Finalidade
                    TextFormField(
                      controller: _purposeController,
                      decoration: InputDecoration(
                        labelText: 'Finalidade',
                        hintText: 'Informe a finalidade da movimentação',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Informe a finalidade' : null,
                    ),
                    SizedBox(height: 16),
                    
                    // Data
                    DatePickerField(
                      labelText: 'Data',
                      initialDate: _date,
                      onDateSelected: (date) {
                        setState(() {
                          _date = date;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Documento (opcional)
                    TextFormField(
                      controller: _documentController,
                      decoration: InputDecoration(
                        labelText: 'Número do Documento (opcional)',
                        hintText: 'Ex: Nota Fiscal, Requisição, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Botão de salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: Icon(buttonIcon),
                        label: Text('Confirmar $title'),
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: buttonColor, // backgroundColor não é suportado em flutter_map 5.0.0
                        ),
                        onPressed: _saveMovement,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

