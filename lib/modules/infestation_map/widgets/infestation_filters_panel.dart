import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget para exibir e gerenciar filtros de infestação
class InfestationFiltersPanel extends StatefulWidget {
  final InfestationFilters filters;
  final Function(InfestationFilters) onFiltersChanged;

  const InfestationFiltersPanel({
    Key? key,
    required this.filters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<InfestationFiltersPanel> createState() => _InfestationFiltersPanelState();
}

class _InfestationFiltersPanelState extends State<InfestationFiltersPanel> {
  late InfestationFilters _currentFilters;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  @override
  void didUpdateWidget(InfestationFiltersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      _currentFilters = widget.filters;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDateRangeFilter(),
                      const SizedBox(height: 16),
                      _buildLevelFilter(),
                      const SizedBox(height: 16),
                      _buildOrganismTypeFilter(),
                      const SizedBox(height: 16),
                      _buildOrganismFilter(),
                      const SizedBox(height: 16),
                      _buildTalhaoFilter(),
                      const SizedBox(height: 16),
                      _buildAlertFilters(),
                      const SizedBox(height: 16),
                      _buildSearchFilter(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho do painel
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.filter_list, color: Color(0xFF2A4F3D)),
        const SizedBox(width: 8),
        const Text(
          'Filtros',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2A4F3D),
          ),
        ),
        const Spacer(),
        if (_currentFilters.hasActiveFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Ativos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// Constrói filtro de período
  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'De',
                value: _currentFilters.dataInicio,
                onChanged: (date) {
                  _updateFilters(
                    _currentFilters.copyWith(dataInicio: date),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                label: 'Até',
                value: _currentFilters.dataFim,
                onChanged: (date) {
                  _updateFilters(
                    _currentFilters.copyWith(dataFim: date),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói campo de data
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  color: value != null ? Colors.black : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói filtro de níveis
  Widget _buildLevelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Níveis de Infestação',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: InfestationLevel.values.map((level) {
            final isSelected = _currentFilters.niveis?.contains(level.code) ?? false;
            return FilterChip(
              label: Text(level.label),
              selected: isSelected,
              onSelected: (selected) {
                final currentLevels = List<String>.from(_currentFilters.niveis ?? []);
                if (selected) {
                  currentLevels.add(level.code);
                } else {
                  currentLevels.remove(level.code);
                }
                _updateFilters(
                  _currentFilters.copyWith(niveis: currentLevels),
                );
              },
              backgroundColor: level.backgroundColor,
              selectedColor: level.color.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? level.color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Constrói filtro por tipo de organismo
  Widget _buildOrganismTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Organismo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildOrganismTypeChip('pest', 'Pragas', Icons.bug_report, Colors.red),
            _buildOrganismTypeChip('disease', 'Doenças', Icons.healing, Colors.orange),
            _buildOrganismTypeChip('weed', 'Plantas Daninhas', Icons.eco, Colors.green),
          ],
        ),
      ],
    );
  }

  /// Chip de tipo de organismo
  Widget _buildOrganismTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _currentFilters.organismTypes?.contains(type) ?? false;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        final currentTypes = List<String>.from(_currentFilters.organismTypes ?? []);
        if (selected) {
          currentTypes.add(type);
        } else {
          currentTypes.remove(type);
        }
        _updateFilters(
          _currentFilters.copyWith(organismTypes: currentTypes),
        );
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Constrói filtro de organismo
  Widget _buildOrganismFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organismo Específico',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _currentFilters.organismoId,
          decoration: InputDecoration(
            hintText: 'Digite o nome do organismo (opcional)',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            helperText: 'Filtre por tipo acima ou digite um organismo específico',
          ),
          onChanged: (value) {
            _updateFilters(
              _currentFilters.copyWith(organismoId: value.isEmpty ? null : value),
            );
          },
        ),
      ],
    );
  }

  /// Constrói filtro de talhão
  Widget _buildTalhaoFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Talhão',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _currentFilters.talhaoId,
          decoration: InputDecoration(
            hintText: 'Digite o ID do talhão',
            prefixIcon: const Icon(Icons.map),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _updateFilters(
              _currentFilters.copyWith(talhaoId: value.isEmpty ? null : value),
            );
          },
        ),
      ],
    );
  }

  /// Constrói filtros de alertas
  Widget _buildAlertFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Apenas com alertas'),
          value: _currentFilters.apenasAlertas,
          onChanged: (value) {
            _updateFilters(
              _currentFilters.copyWith(apenasAlertas: value ?? false),
            );
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Apenas não reconhecidos'),
          value: _currentFilters.apenasNaoReconhecidos,
          onChanged: (value) {
            _updateFilters(
              _currentFilters.copyWith(apenasNaoReconhecidos: value ?? false),
            );
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  /// Constrói filtro de busca
  Widget _buildSearchFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Busca',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _currentFilters.searchQuery,
          decoration: InputDecoration(
            hintText: 'Buscar por texto...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _updateFilters(
              _currentFilters.copyWith(searchQuery: value.isEmpty ? null : value),
            );
          },
        ),
      ],
    );
  }

  /// Constrói botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Aplicar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BAA57),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear),
            label: const Text('Limpar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Atualiza filtros
  void _updateFilters(InfestationFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
  }

  /// Aplica filtros
  void _applyFilters() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onFiltersChanged(_currentFilters);
    }
  }

  /// Limpa filtros
  void _clearFilters() {
    setState(() {
      _currentFilters = const InfestationFilters();
    });
    widget.onFiltersChanged(_currentFilters);
  }
}
