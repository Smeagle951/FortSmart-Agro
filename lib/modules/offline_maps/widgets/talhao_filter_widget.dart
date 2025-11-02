import 'package:flutter/material.dart';
import '../models/offline_map_status.dart';

/// Widget para filtros avançados de talhões
class TalhaoFilterWidget extends StatefulWidget {
  const TalhaoFilterWidget({super.key});

  @override
  State<TalhaoFilterWidget> createState() => _TalhaoFilterWidgetState();
}

class _TalhaoFilterWidgetState extends State<TalhaoFilterWidget> {
  Set<OfflineMapStatus> _selectedStatuses = {};
  String _selectedFazenda = 'Todas';
  String _selectedCultura = 'Todas';
  double _minArea = 0.0;
  double _maxArea = 1000.0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showOnlyWithCoordinates = true;
  bool _showOnlyDownloaded = false;
  bool _showOnlyNotDownloaded = false;

  final List<String> _fazendas = [
    'Todas',
    'Fazenda São José',
    'Fazenda Santa Maria',
    'Fazenda Boa Vista',
    'Fazenda Nova Esperança',
  ];

  final List<String> _culturas = [
    'Todas',
    'Soja',
    'Milho',
    'Algodão',
    'Café',
    'Cana-de-açúcar',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Text(
                  'Filtros Avançados',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Conteúdo dos filtros
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro por status
                    _buildStatusFilter(),
                    
                    const SizedBox(height: 24),
                    
                    // Filtro por fazenda
                    _buildFazendaFilter(),
                    
                    const SizedBox(height: 24),
                    
                    // Filtro por cultura
                    _buildCulturaFilter(),
                    
                    const SizedBox(height: 24),
                    
                    // Filtro por área
                    _buildAreaFilter(),
                    
                    const SizedBox(height: 24),
                    
                    // Filtro por data
                    _buildDateFilter(),
                    
                    const SizedBox(height: 24),
                    
                    // Filtros especiais
                    _buildSpecialFilters(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Filtro por status
  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status do Download',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OfflineMapStatus.values.map((status) {
            final isSelected = _selectedStatuses.contains(status);
            return FilterChip(
              label: Text(status.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatuses.add(status);
                  } else {
                    _selectedStatuses.remove(status);
                  }
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Filtro por fazenda
  Widget _buildFazendaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fazenda',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedFazenda,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _fazendas.map((fazenda) {
            return DropdownMenuItem(
              value: fazenda,
              child: Text(fazenda),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFazenda = value!;
            });
          },
        ),
      ],
    );
  }

  /// Filtro por cultura
  Widget _buildCulturaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultura',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCultura,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _culturas.map((cultura) {
            return DropdownMenuItem(
              value: cultura,
              child: Text(cultura),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCultura = value!;
            });
          },
        ),
      ],
    );
  }

  /// Filtro por área
  Widget _buildAreaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Área (hectares)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Mínima',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minArea = double.tryParse(value) ?? 0.0;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Máxima',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxArea = double.tryParse(value) ?? 1000.0;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(_minArea, _maxArea),
          min: 0.0,
          max: 1000.0,
          divisions: 100,
          labels: RangeLabels(
            '${_minArea.toStringAsFixed(1)} ha',
            '${_maxArea.toStringAsFixed(1)} ha',
          ),
          onChanged: (values) {
            setState(() {
              _minArea = values.start;
              _maxArea = values.end;
            });
          },
        ),
      ],
    );
  }

  /// Filtro por data
  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período de Criação',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartDate(),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Data inicial',
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndDate(),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Data final',
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Filtros especiais
  Widget _buildSpecialFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros Especiais',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            CheckboxListTile(
              title: const Text('Apenas com coordenadas'),
              subtitle: const Text('Mostrar apenas talhões com polígonos definidos'),
              value: _showOnlyWithCoordinates,
              onChanged: (value) {
                setState(() {
                  _showOnlyWithCoordinates = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Apenas baixados'),
              subtitle: const Text('Mostrar apenas mapas já baixados'),
              value: _showOnlyDownloaded,
              onChanged: (value) {
                setState(() {
                  _showOnlyDownloaded = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Apenas não baixados'),
              subtitle: const Text('Mostrar apenas mapas não baixados'),
              value: _showOnlyNotDownloaded,
              onChanged: (value) {
                setState(() {
                  _showOnlyNotDownloaded = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ],
    );
  }

  /// Botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            child: const Text('Limpar Filtros'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            child: const Text('Aplicar Filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Seleciona data inicial
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  /// Seleciona data final
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  /// Limpa todos os filtros
  void _clearFilters() {
    setState(() {
      _selectedStatuses.clear();
      _selectedFazenda = 'Todas';
      _selectedCultura = 'Todas';
      _minArea = 0.0;
      _maxArea = 1000.0;
      _startDate = null;
      _endDate = null;
      _showOnlyWithCoordinates = true;
      _showOnlyDownloaded = false;
      _showOnlyNotDownloaded = false;
    });
  }

  /// Aplica os filtros
  void _applyFilters() {
    // Implementar aplicação dos filtros
    Navigator.pop(context);
    
    // Mostrar resultado dos filtros
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtros aplicados: ${_getFilterSummary()}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Obtém resumo dos filtros
  String _getFilterSummary() {
    final filters = <String>[];
    
    if (_selectedStatuses.isNotEmpty) {
      filters.add('Status: ${_selectedStatuses.map((s) => s.displayName).join(', ')}');
    }
    
    if (_selectedFazenda != 'Todas') {
      filters.add('Fazenda: $_selectedFazenda');
    }
    
    if (_selectedCultura != 'Todas') {
      filters.add('Cultura: $_selectedCultura');
    }
    
    if (_minArea > 0 || _maxArea < 1000) {
      filters.add('Área: ${_minArea.toStringAsFixed(1)}-${_maxArea.toStringAsFixed(1)} ha');
    }
    
    if (_startDate != null || _endDate != null) {
      final start = _startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : 'Início';
      final end = _endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'Fim';
      filters.add('Período: $start - $end');
    }
    
    if (_showOnlyWithCoordinates) {
      filters.add('Com coordenadas');
    }
    
    if (_showOnlyDownloaded) {
      filters.add('Apenas baixados');
    }
    
    if (_showOnlyNotDownloaded) {
      filters.add('Apenas não baixados');
    }
    
    return filters.isEmpty ? 'Nenhum filtro' : filters.join(', ');
  }
}
