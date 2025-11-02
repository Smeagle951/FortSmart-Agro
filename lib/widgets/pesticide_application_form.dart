import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/models/pesticide_application.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';
import 'package:fortsmart_agro/widgets/product_selector.dart';

/// Widget para exibir um formulário de aplicação de defensivos
class PesticideApplicationForm extends StatefulWidget {
  final PesticideApplication? initialApplication;
  final List<InventoryItem> availableProducts;
  final Function(PesticideApplication) onSave;
  final VoidCallback? onCancel;

  const PesticideApplicationForm({
    super.key,
    this.initialApplication,
    required this.availableProducts,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<PesticideApplicationForm> createState() => _PesticideApplicationFormState();
}

class _PesticideApplicationFormState extends State<PesticideApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plotController;
  late TextEditingController _cropController;
  late TextEditingController _totalAreaController;
  late TextEditingController _doseController;
  late TextEditingController _mixtureVolumeController;
  late TextEditingController _responsiblePersonController;
  late TextEditingController _observationsController;
  late DateTime _selectedDate;
  InventoryItem? _selectedProduct;
  String _doseUnit = 'L/ha';

  @override
  void initState() {
    super.initState();
    final app = widget.initialApplication;
    
    // Inicializar com valores da aplicação existente ou valores padrão
    _plotController = TextEditingController(text: app?.plotId ?? '');
    _cropController = TextEditingController(text: app?.cropId ?? '');
    _totalAreaController = TextEditingController(text: app?.totalArea.toString() ?? '');
    _doseController = TextEditingController(text: app?.dose.toString() ?? '');
    _mixtureVolumeController = TextEditingController(text: app?.mixtureVolume.toString() ?? '');
    _responsiblePersonController = TextEditingController(text: app?.responsiblePerson ?? '');
    _observationsController = TextEditingController(text: app?.observations ?? '');
    _selectedDate = app?.date ?? DateTime.now();
    _doseUnit = app?.doseUnit ?? 'L/ha';
    
    // Encontrar o produto selecionado
    if (app != null) {
      try {
        _selectedProduct = widget.availableProducts.firstWhere(
          (product) => product.id == app.productId,
        );
      } catch (e) {
        // Produto não encontrado na lista
        _selectedProduct = null;
      }
    }
  }

  @override
  void dispose() {
    _plotController.dispose();
    _cropController.dispose();
    _totalAreaController.dispose();
    _doseController.dispose();
    _mixtureVolumeController.dispose();
    _responsiblePersonController.dispose();
    _observationsController.dispose();
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
          _buildDateField(),
          const SizedBox(height: 16),
          _buildProductSelector(),
          const SizedBox(height: 16),
          _buildPlotField(),
          const SizedBox(height: 16),
          _buildCropField(),
          const SizedBox(height: 16),
          _buildAreaField(),
          const SizedBox(height: 16),
          _buildDoseField(),
          const SizedBox(height: 16),
          _buildMixtureVolumeField(),
          const SizedBox(height: 16),
          _buildResponsibleField(),
          const SizedBox(height: 16),
          _buildObservationsField(),
          const SizedBox(height: 24),
          _buildButtons(),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho do formulário
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.eco, color: Colors.green[700], size: 24),
        const SizedBox(width: 12),
        Text(
          'Registro de Aplicação de Defensivo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de data
  Widget _buildDateField() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data da Aplicação',
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

  /// Constrói o seletor de produto
  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedProduct != null)
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: _buildCategoryIcon(_selectedProduct!),
              title: Text(_selectedProduct!.name),
              subtitle: Text(
                '${_selectedProduct!.category} | Estoque: ${_selectedProduct!.quantity.toStringAsFixed(2)} ${_selectedProduct!.unit}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _selectProduct,
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _selectProduct,
            icon: const Icon(Icons.add),
            label: const Text('Selecionar Produto'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
      ],
    );
  }

  /// Constrói o campo de talhão
  Widget _buildPlotField() {
    return TextFormField(
      controller: _plotController,
      decoration: InputDecoration(
        labelText: 'Talhão',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe o talhão';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de cultura
  Widget _buildCropField() {
    return TextFormField(
      controller: _cropController,
      decoration: InputDecoration(
        labelText: 'Cultura',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe a cultura';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de área total
  Widget _buildAreaField() {
    return TextFormField(
      controller: _totalAreaController,
      decoration: InputDecoration(
        labelText: 'Área Total (ha)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixText: 'ha',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe a área total';
        }
        final area = double.tryParse(value);
        if (area == null || area <= 0) {
          return 'Área deve ser maior que zero';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de dose
  Widget _buildDoseField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _doseController,
            decoration: InputDecoration(
              labelText: 'Dose',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, informe a dose';
              }
              final dose = double.tryParse(value);
              if (dose == null || dose <= 0) {
                return 'Dose deve ser maior que zero';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _doseUnit,
            decoration: InputDecoration(
              labelText: 'Unidade',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'L/ha', child: Text('L/ha')),
              DropdownMenuItem(value: 'mL/ha', child: Text('mL/ha')),
              DropdownMenuItem(value: 'kg/ha', child: Text('kg/ha')),
              DropdownMenuItem(value: 'g/ha', child: Text('g/ha')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _doseUnit = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de volume de calda
  Widget _buildMixtureVolumeField() {
    return TextFormField(
      controller: _mixtureVolumeController,
      decoration: InputDecoration(
        labelText: 'Volume de Calda (L/ha)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixText: 'L/ha',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe o volume de calda';
        }
        final volume = double.tryParse(value);
        if (volume == null || volume <= 0) {
          return 'Volume deve ser maior que zero';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de responsável
  Widget _buildResponsibleField() {
    return TextFormField(
      controller: _responsiblePersonController,
      decoration: InputDecoration(
        labelText: 'Responsável pela Aplicação',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe o responsável';
        }
        return null;
      },
    );
  }

  /// Constrói o campo de observações
  Widget _buildObservationsField() {
    return TextFormField(
      controller: _observationsController,
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
          onPressed: _saveApplication,
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

  /// Exibe o diálogo de seleção de produto
  Future<void> _selectProduct() async {
    final product = await showProductSelectorDialog(
      context: context,
      products: widget.availableProducts,
      selectedProduct: _selectedProduct,
      title: 'Selecionar Defensivo',
      showOnlyAvailableProducts: true,
    );
    
    if (product != null) {
      setState(() {
        _selectedProduct = product;
      });
    }
  }

  /// Constrói o ícone de categoria do produto
  Widget _buildCategoryIcon(InventoryItem product) {
    IconData iconData;
    Color iconColor;
    
    // Definir ícone com base na categoria
    switch (product.category?.toLowerCase() ?? 'outro') {
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

  /// Salva a aplicação
  void _saveApplication() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final totalArea = double.parse(_totalAreaController.text);
      final dose = double.parse(_doseController.text);
      final mixtureVolume = double.parse(_mixtureVolumeController.text);
      
      final application = PesticideApplication(
        id: widget.initialApplication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        productId: _selectedProduct!.id,
        date: _selectedDate ?? DateTime.now(),
        plotId: _plotController.text.isNotEmpty ? _plotController.text : 'Sem talhão',
        cropId: _cropController.text.isNotEmpty ? _cropController.text : 'Sem cultura',
        totalArea: totalArea,
        dose: dose,
        doseUnit: _doseUnit,
        mixtureVolume: mixtureVolume,
        responsiblePerson: _responsiblePersonController.text.isNotEmpty ? _responsiblePersonController.text : 'Não informado',
        applicationType: ApplicationType.ground,
        observations: _observationsController.text,
      );
      
      widget.onSave(application);
    } else if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um produto'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }
}

/// Widget para exibir um diálogo de confirmação de aplicação
class PesticideApplicationConfirmationDialog extends StatelessWidget {
  final PesticideApplication application;
  final InventoryItem product;
  final VoidCallback onConfirm;

  const PesticideApplicationConfirmationDialog({
    super.key,
    required this.application,
    required this.product,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalProductAmount = application.calculateTotalProductAmount();
    final totalMixtureVolume = application.calculateTotalMixtureVolume();
    final isExceedingStock = totalProductAmount > product.quantity;
    
    return AlertDialog(
      title: Text(
        'Confirmar Aplicação',
        style: TextStyle(
          color: Colors.green[700],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produto: ${product.name}'),
          const SizedBox(height: 8),
          Text('Data: ${dateFormat.format(application.date)}'),
          const SizedBox(height: 8),
          Text('Talhão: ${application.plotId}'),
          const SizedBox(height: 8),
          Text('Cultura: ${application.cropId}'),
          const SizedBox(height: 8),
          Text('Área Total: ${(application.totalArea ?? 0.0).toStringAsFixed(2)} ha'),
          const SizedBox(height: 8),
          Text('Dose: ${application.getFormattedDose()}'),
          const SizedBox(height: 16),
          Text(
            'Quantidade Total de Produto: ${totalProductAmount.toStringAsFixed(2)} ${(application.doseUnit ?? '').split('/').first}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Volume Total de Calda: ${totalMixtureVolume.toStringAsFixed(2)} L',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Estoque Atual: ${product.quantity.toStringAsFixed(2)} ${product.unit}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Estoque Após Aplicação: ${(product.quantity - totalProductAmount).toStringAsFixed(2)} ${product.unit}',
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
                      'Atenção: Esta aplicação excede o estoque disponível!',
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
}

/// Função para exibir o diálogo de confirmação de aplicação
Future<bool> showApplicationConfirmationDialog({
  required BuildContext context,
  required PesticideApplication application,
  required InventoryItem product,
  required VoidCallback onConfirm,
}) async {
  bool confirmed = false;
  
  await showDialog(
    context: context,
    builder: (context) => PesticideApplicationConfirmationDialog(
      application: application,
      product: product,
      onConfirm: () {
        confirmed = true;
        onConfirm();
      },
    ),
  );
  
  return confirmed;
}

