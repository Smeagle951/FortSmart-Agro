/// 🌱 Widget de Filtros de Testes de Germinação
/// 
/// Filtros elegantes para testes de germinação
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import '../../../../../../utils/fortsmart_theme.dart';

class GerminationFilterWidget extends StatefulWidget {
  final String selectedCulture;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onCultureChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const GerminationFilterWidget({
    super.key,
    required this.selectedCulture,
    this.startDate,
    this.endDate,
    required this.onCultureChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<GerminationFilterWidget> createState() => _GerminationFilterWidgetState();
}

class _GerminationFilterWidgetState extends State<GerminationFilterWidget> {
  late String _selectedCulture;
  late DateTime? _startDate;
  late DateTime? _endDate;

  final List<String> _cultures = [
    'all',
    'Soja',
    'Milho',
    'Trigo',
    'Algodão',
    'Feijão',
    'Arroz',
    'Sorgo',
    'Girassol',
    'Aveia',
    'Gergelim',
    'Cana-de-açúcar',
    'Tomate',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCulture = widget.selectedCulture;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildCultureFilter(),
          const SizedBox(height: 20),
          _buildDateFilters(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCultureFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cultura',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCulture,
              isExpanded: true,
              items: _cultures.map((culture) {
                return DropdownMenuItem<String>(
                  value: culture,
                  child: Text(
                    culture == 'all' ? 'Todas as culturas' : culture,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCulture = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Data inicial',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                'Data final',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      onTap: () => _selectDate(context, value, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null 
                    ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                    : label,
                style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              widget.onClear();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text('Limpar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              widget.onCultureChanged(_selectedCulture);
              widget.onStartDateChanged(_startDate);
              widget.onEndDateChanged(_endDate);
              widget.onApply();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Aplicar Filtros'),
          ),
        ),
      ],
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
