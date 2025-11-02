import 'package:flutter/material.dart';
import 'package:fortsmart_agro/widgets/date_range_picker.dart';

/// Widget para exibir um bottom sheet com filtros avançados
class AdvancedFilterSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final List<FilterOption> filterOptions;
  final Function(Map<String, dynamic>) onApplyFilters;
  final VoidCallback? onResetFilters;

  const AdvancedFilterSheet({
    Key? key,
    required this.initialFilters,
    required this.filterOptions,
    required this.onApplyFilters,
    this.onResetFilters,
  }) : super(key: key);

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros Avançados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                ...widget.filterOptions.map((option) {
                  return _buildFilterOption(option);
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onResetFilters != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = {};
                    });
                    widget.onResetFilters!();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Limpar Filtros'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters);
                  Navigator.of(context).pop();
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói o widget de filtro com base no tipo de opção
  Widget _buildFilterOption(FilterOption option) {
    switch (option.type) {
      case FilterType.text:
        return _buildTextFilter(option);
      case FilterType.dropdown:
        return _buildDropdownFilter(option);
      case FilterType.dateRange:
        return _buildDateRangeFilter(option);
      case FilterType.numberRange:
        return _buildNumberRangeFilter(option);
      case FilterType.checkbox:
        return _buildCheckboxFilter(option);
      case FilterType.radioGroup:
        return _buildRadioGroupFilter(option);
      case FilterType.slider:
        return _buildSliderFilter(option);
    }
  }

  /// Constrói um filtro de texto
  Widget _buildTextFilter(FilterOption option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _filters[option.key] as String? ?? '',
            decoration: InputDecoration(
              hintText: option.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isEmpty) {
                  _filters.remove(option.key);
                } else {
                  _filters[option.key] = value;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  /// Constrói um filtro de dropdown
  Widget _buildDropdownFilter(FilterOption option) {
    final items = option.options ?? [];
    final currentValue = _filters[option.key];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todos'),
              ),
              ...items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label']),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                if (value == null) {
                  _filters.remove(option.key);
                } else {
                  _filters[option.key] = value;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  /// Constrói um filtro de intervalo de datas
  Widget _buildDateRangeFilter(FilterOption option) {
    final DateTimeRange? currentRange = _filters[option.key];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DateRangePicker(
            initialDateRange: currentRange,
            onDateRangeSelected: (range) {
              setState(() {
                if (range == null) {
                  _filters.remove(option.key);
                } else {
                  _filters[option.key] = range;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  /// Constrói um filtro de intervalo numérico
  Widget _buildNumberRangeFilter(FilterOption option) {
    final min = _filters['${option.key}_min'] as double? ?? option.minValue ?? 0.0;
    final max = _filters['${option.key}_max'] as double? ?? option.maxValue ?? 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: min.toString(),
                  decoration: InputDecoration(
                    labelText: 'Mínimo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _filters.remove('${option.key}_min');
                      } else {
                        _filters['${option.key}_min'] = double.tryParse(value) ?? min;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: max.toString(),
                  decoration: InputDecoration(
                    labelText: 'Máximo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _filters.remove('${option.key}_max');
                      } else {
                        _filters['${option.key}_max'] = double.tryParse(value) ?? max;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um filtro de checkbox
  Widget _buildCheckboxFilter(FilterOption option) {
    final isChecked = _filters[option.key] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                if (value == null || value == false) {
                  _filters.remove(option.key);
                } else {
                  _filters[option.key] = value;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(option.label),
          ),
        ],
      ),
    );
  }

  /// Constrói um filtro de grupo de radio buttons
  Widget _buildRadioGroupFilter(FilterOption option) {
    final items = option.options ?? [];
    final currentValue = _filters[option.key];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return RadioListTile<String>(
              title: Text(item['label']),
              value: item['value'],
              groupValue: currentValue,
              onChanged: (value) {
                setState(() {
                  if (value == null) {
                    _filters.remove(option.key);
                  } else {
                    _filters[option.key] = value;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Constrói um filtro de slider
  Widget _buildSliderFilter(FilterOption option) {
    final minValue = option.minValue ?? 0.0;
    final maxValue = option.maxValue ?? 100.0;
    final currentValue = _filters[option.key] as double? ?? minValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(minValue.toStringAsFixed(0)),
              Expanded(
                child: Slider(
                  value: currentValue,
                  min: minValue,
                  max: maxValue,
                  divisions: (maxValue - minValue).toInt(),
                  label: currentValue.toStringAsFixed(0),
                  onChanged: (value) {
                    setState(() {
                      _filters[option.key] = value;
                    });
                  },
                ),
              ),
              Text(maxValue.toStringAsFixed(0)),
            ],
          ),
          Center(
            child: Text(
              'Valor: ${currentValue.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe que representa uma opção de filtro
class FilterOption {
  final String key;
  final String label;
  final FilterType type;
  final String? hint;
  final List<Map<String, dynamic>>? options;
  final double? minValue;
  final double? maxValue;

  FilterOption({
    required this.key,
    required this.label,
    required this.type,
    this.hint,
    this.options,
    this.minValue,
    this.maxValue,
  });
}

/// Enum que define os tipos de filtro disponíveis
enum FilterType {
  text,
  dropdown,
  dateRange,
  numberRange,
  checkbox,
  radioGroup,
  slider,
}

/// Função para exibir o bottom sheet de filtros avançados
Future<void> showAdvancedFilterSheet({
  required BuildContext context,
  required Map<String, dynamic> initialFilters,
  required List<FilterOption> filterOptions,
  required Function(Map<String, dynamic>) onApplyFilters,
  VoidCallback? onResetFilters,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // backgroundColor: Colors.transparent, // backgroundColor não é suportado em flutter_map 5.0.0
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return AdvancedFilterSheet(
          initialFilters: initialFilters,
          filterOptions: filterOptions,
          onApplyFilters: onApplyFilters,
          onResetFilters: onResetFilters,
        );
      },
    ),
  );
}

