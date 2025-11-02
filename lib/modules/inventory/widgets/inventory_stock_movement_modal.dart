import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/custom_text_form_field.dart';
import '../../shared/widgets/custom_dropdown.dart';

/// Enum para os tipos de transação de estoque usados no modal
enum StockMovementType {
  stockIn,      // Entrada de produto
  stockOut,     // Saída manual
  adjustment,   // Ajuste de estoque
  application,  // Aplicação
  applicationCancellation, // Cancelamento de aplicação
}

class InventoryStockMovementModal extends StatefulWidget {
  final InventoryProductModel product;
  final Function(InventoryTransactionModel) onSave;
  final Function(InventoryTransactionModel)? onStockUpdated;

  const InventoryStockMovementModal({
    super.key,
    required this.product,
    required this.onSave,
    this.onStockUpdated,
  });

  @override
  State<InventoryStockMovementModal> createState() =>
      _InventoryStockMovementModalState();
}

class _InventoryStockMovementModalState
    extends State<InventoryStockMovementModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _reasonController;
  late final TextEditingController _referenceController;
  late final TextEditingController _unitCostController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  StockMovementType _transactionType = StockMovementType.stockIn;
  bool _showUnitCost = true;
  bool _isLoading = false;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
  }

  void _initializeControllers() {
    _quantityController = TextEditingController();
    _reasonController = TextEditingController();
    _referenceController = TextEditingController();
    _unitCostController = TextEditingController(
      text: widget.product.unitCost?.toString() ?? '',
    );
    _showUnitCost = _transactionType == StockMovementType.stockIn;
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _referenceController.dispose();
    _unitCostController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final quantity = double.parse(_quantityController.text.replaceAll(',', '.'));
        final unitCost = _showUnitCost && _unitCostController.text.isNotEmpty
            ? double.parse(_unitCostController.text.replaceAll(',', '.'))
            : null;

        // Mapear o tipo de transação interno para o tipo de transação do modelo
        TransactionType modelType;
        switch (_transactionType) {
          case StockMovementType.stockIn:
            modelType = TransactionType.entry;
            break;
          case StockMovementType.stockOut:
            modelType = TransactionType.manual;
            break;
          case StockMovementType.application:
            modelType = TransactionType.application;
            break;
          case StockMovementType.adjustment:
            modelType = TransactionType.adjustment;
            break;
          case StockMovementType.applicationCancellation:
            modelType = TransactionType.manual; // Usar manual como fallback
            break;
        }

        final transaction = InventoryTransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: widget.product.id,
          batchNumber: widget.product.batchNumber ?? 'N/A',
          type: modelType,
          quantity: quantity,
          date: DateTime.now(),
          reason: _reasonController.text.trim(),
          reference: _referenceController.text.trim().isNotEmpty
              ? _referenceController.text.trim()
              : null,
        );

        // Simular um pequeno delay para mostrar o loading
        await Future.delayed(const Duration(milliseconds: 500));

        widget.onSave(transaction);

        if (mounted) {
          _showSuccessSnackBar('Movimentação registrada com sucesso!');
          await _animationController.reverse();
          Navigator.of(context).pop();
        }
      } catch (e) {
        _showErrorSnackBar('Erro ao processar a movimentação: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }


  Color _getHeaderColor() {
    switch (_transactionType) {
      case StockMovementType.stockIn:
        return AppColors.success;
      case StockMovementType.stockOut:
        return AppColors.warning;
      case StockMovementType.adjustment:
        return AppColors.info;
      case StockMovementType.application:
        return AppColors.primary;
      case StockMovementType.applicationCancellation:
        return AppColors.danger;
    }
  }

  IconData _getTransactionIcon() {
    switch (_transactionType) {
      case StockMovementType.stockIn:
        return Icons.add_circle;
      case StockMovementType.stockOut:
        return Icons.remove_circle;
      case StockMovementType.adjustment:
        return Icons.sync;
      case StockMovementType.application:
        return Icons.agriculture;
      case StockMovementType.applicationCancellation:
        return Icons.cancel;
    }
  }

  Color _getButtonColor() {
    switch (_transactionType) {
      case StockMovementType.stockIn:
        return AppColors.success;
      case StockMovementType.stockOut:
        return AppColors.warning;
      case StockMovementType.adjustment:
        return AppColors.info;
      case StockMovementType.application:
        return AppColors.primary;
      case StockMovementType.applicationCancellation:
        return AppColors.danger;
    }
  }

  void _onTransactionTypeChanged(StockMovementType? value) {
    if (value != null) {
      setState(() {
        _transactionType = value;
        _showUnitCost = _transactionType == StockMovementType.stockIn;
      });
    }
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: _getHeaderColor(),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: _getHeaderColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getTransactionIcon(),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Movimentação de Estoque',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lote: ${widget.product.batchNumber}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Estoque Atual: ${widget.product.quantity} ${widget.product.unit}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de movimentação
          CustomDropdown<StockMovementType>(
            label: 'Tipo de Movimentação*',
            prefixIcon: const Icon(Icons.swap_vert),
            value: _transactionType,
            items: const [
              DropdownMenuItem<StockMovementType>(
                value: StockMovementType.stockIn,
                child: Text('Entrada de Estoque'),
              ),
              DropdownMenuItem<StockMovementType>(
                value: StockMovementType.stockOut,
                child: Text('Saída de Estoque'),
              ),
              DropdownMenuItem<StockMovementType>(
                value: StockMovementType.adjustment,
                child: Text('Ajuste de Estoque'),
              ),
              DropdownMenuItem<StockMovementType>(
                value: StockMovementType.application,
                child: Text('Aplicação'),
              ),
              DropdownMenuItem<StockMovementType>(
                value: StockMovementType.applicationCancellation,
                child: Text('Cancelamento de Aplicação'),
              ),
            ],
            onChanged: _onTransactionTypeChanged,
          ),
          const SizedBox(height: 20),

          // Quantidade
          CustomTextFormField(
            controller: _quantityController,
            label: 'Quantidade*',
            prefixIcon: const Icon(Icons.inventory_2),
            suffixText: widget.product.unit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateQuantity,
          ),
          const SizedBox(height: 20),

          // Custo unitário (apenas para entrada)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _showUnitCost
                ? Column(
                    key: const ValueKey('unitCost'),
                    children: [
                      CustomTextFormField(
                        controller: _unitCostController,
                        label: 'Custo Unitário (R\$)',
                        prefixIcon: const Icon(Icons.attach_money),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),

          // Motivo
          CustomTextFormField(
            controller: _reasonController,
            label: 'Motivo*',
            prefixIcon: const Icon(Icons.description),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Motivo é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Referência
          CustomTextFormField(
            controller: _referenceController,
            label: 'Referência (opcional)',
            prefixIcon: const Icon(Icons.tag),
            hintText: 'Nota fiscal, ordem de serviço, etc.',
          ),
        ],
      ),
    );
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantidade é obrigatória';
    }
    
    final quantity = double.tryParse(value.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      return 'Valor inválido';
    }
    
    if (_transactionType == StockMovementType.stockOut &&
        quantity > widget.product.quantity) {
      return 'Quantidade maior que o estoque disponível';
    }
    
    return null;
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirmar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: MediaQuery.of(context).size.width > 500
                ? 500
                : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildProductInfo(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildForm(),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}