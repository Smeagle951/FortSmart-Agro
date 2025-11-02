/// 🌱 Widget de Formulário de Informações Básicas
/// 
/// Formulário elegante para dados básicos do teste de germinação
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../utils/fortsmart_theme.dart';
import '../../../../../../utils/theme_utils.dart';

class GerminationBasicInfoForm extends StatefulWidget {
  final String culture;
  final String variety;
  final String seedLot;
  final int totalSeeds;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final int pureSeeds;
  final int brokenSeeds;
  final int stainedSeeds;
  final String observations;
  
  final ValueChanged<String> onCultureChanged;
  final ValueChanged<String> onVarietyChanged;
  final ValueChanged<String> onSeedLotChanged;
  final ValueChanged<int> onTotalSeedsChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime?> onExpectedEndDateChanged;
  final ValueChanged<int> onPureSeedsChanged;
  final ValueChanged<int> onBrokenSeedsChanged;
  final ValueChanged<int> onStainedSeedsChanged;
  final ValueChanged<String> onObservationsChanged;

  const GerminationBasicInfoForm({
    super.key,
    required this.culture,
    required this.variety,
    required this.seedLot,
    required this.totalSeeds,
    required this.startDate,
    this.expectedEndDate,
    required this.pureSeeds,
    required this.brokenSeeds,
    required this.stainedSeeds,
    required this.observations,
    required this.onCultureChanged,
    required this.onVarietyChanged,
    required this.onSeedLotChanged,
    required this.onTotalSeedsChanged,
    required this.onStartDateChanged,
    required this.onExpectedEndDateChanged,
    required this.onPureSeedsChanged,
    required this.onBrokenSeedsChanged,
    required this.onStainedSeedsChanged,
    required this.onObservationsChanged,
  });

  @override
  State<GerminationBasicInfoForm> createState() => _GerminationBasicInfoFormState();
}

class _GerminationBasicInfoFormState extends State<GerminationBasicInfoForm> {
  final _cultureController = TextEditingController();
  final _varietyController = TextEditingController();
  final _seedLotController = TextEditingController();
  final _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(GerminationBasicInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllers();
  }

  void _updateControllers() {
    _cultureController.text = widget.culture;
    _varietyController.text = widget.variety;
    _seedLotController.text = widget.seedLot;
    _observationsController.text = widget.observations;
  }

  @override
  void dispose() {
    _cultureController.dispose();
    _varietyController.dispose();
    _seedLotController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informações Básicas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBasicInfoSection(),
            const SizedBox(height: 20),
            _buildSeedQualitySection(),
            const SizedBox(height: 20),
            _buildDatesSection(),
            const SizedBox(height: 20),
            _buildObservationsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do Teste',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _cultureController,
                label: 'Cultura *',
                hint: 'Ex: Soja, Milho, Trigo',
                onChanged: widget.onCultureChanged,
                validator: (value) => value?.isEmpty == true ? 'Cultura é obrigatória' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _varietyController,
                label: 'Variedade *',
                hint: 'Ex: BRS 284, Pioneer 30F53',
                onChanged: widget.onVarietyChanged,
                validator: (value) => value?.isEmpty == true ? 'Variedade é obrigatória' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _seedLotController,
                label: 'Lote de Sementes *',
                hint: 'Ex: LOTE2024001',
                onChanged: widget.onSeedLotChanged,
                validator: (value) => value?.isEmpty == true ? 'Lote é obrigatório' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                value: widget.totalSeeds,
                label: 'Total de Sementes *',
                onChanged: widget.onTotalSeedsChanged,
                validator: (value) => value == null || value <= 0 ? 'Quantidade inválida' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeedQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qualidade das Sementes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        // Layout em coluna para melhor visualização em mobile
        _buildNumberField(
          value: widget.pureSeeds,
          label: 'Sementes Puras',
          onChanged: widget.onPureSeedsChanged,
          validator: (value) => value == null || value < 0 ? 'Valor inválido' : null,
        ),
        const SizedBox(height: 12),
        _buildNumberField(
          value: widget.brokenSeeds,
          label: 'Sementes Quebradas',
          onChanged: widget.onBrokenSeedsChanged,
          validator: (value) => value == null || value < 0 ? 'Valor inválido' : null,
        ),
        const SizedBox(height: 12),
        _buildNumberField(
          value: widget.stainedSeeds,
          label: 'Sementes Manchadas',
          onChanged: widget.onStainedSeedsChanged,
          validator: (value) => value == null || value < 0 ? 'Valor inválido' : null,
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datas do Teste',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Data de Início *',
                value: widget.startDate,
                onChanged: (date) => widget.onStartDateChanged(date!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Data Esperada de Fim',
                value: widget.expectedEndDate,
                onChanged: widget.onExpectedEndDateChanged,
                isOptional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observações',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _observationsController,
          label: 'Observações Adicionais',
          hint: 'Condições especiais, tratamentos, etc.',
          onChanged: widget.onObservationsChanged,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor),
        ),
      ),
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildNumberField({
    required int value,
    required String label,
    required ValueChanged<int> onChanged,
    String? Function(int?)? validator,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          onChanged(intValue);
        }
      },
      validator: (value) {
        final intValue = int.tryParse(value ?? '');
        return validator?.call(intValue);
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, value, onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: FortSmartTheme.primaryColor),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null 
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : isOptional ? 'Opcional' : 'Selecione a data',
          style: TextStyle(
            color: value != null ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentValue,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      onChanged(date);
    }
  }
}
