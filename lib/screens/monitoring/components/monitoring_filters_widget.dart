import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/logger.dart';
import '../../models/talhao_model.dart';
import '../../models/cultura_model.dart';
import '../main/monitoring_controller.dart';

/// Widget de filtros para o módulo de monitoramento
/// Permite selecionar talhão, cultura, data e outros filtros
class MonitoringFiltersWidget extends StatefulWidget {
  final MonitoringController controller;
  final bool showAdvancedFilters;
  final bool showDateFilter;
  
  const MonitoringFiltersWidget({
    super.key,
    required this.controller,
    this.showAdvancedFilters = true,
    this.showDateFilter = true,
  });

  @override
  State<MonitoringFiltersWidget> createState() => _MonitoringFiltersWidgetState();
}

class _MonitoringFiltersWidgetState extends State<MonitoringFiltersWidget> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho dos filtros
          _buildFiltersHeader(),
          
          const SizedBox(height: 16),
          
          // Filtros principais
          _buildMainFilters(),
          
          // Filtros avançados
          if (widget.showAdvancedFilters) ...[
            const SizedBox(height: 16),
            _buildAdvancedFilters(),
          ],
          
          // Filtros de data
          if (widget.showDateFilter) ...[
            const SizedBox(height: 16),
            _buildDateFilters(),
          ],
          
          // Botões de ação
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildFiltersHeader() {
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Filtros de Monitoramento',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _clearAllFilters,
          icon: const Icon(Icons.clear_all, size: 20),
          tooltip: 'Limpar todos os filtros',
        ),
      ],
    );
  }
  
  Widget _buildMainFilters() {
    return Column(
      children: [
        // Filtro de Cultura
        _buildCulturaFilter(),
        
        const SizedBox(height: 12),
        
        // Filtro de Talhão
        _buildTalhaoFilter(),
      ],
    );
  }
  
  Widget _buildCulturaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultura',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CulturaModel?>(
              value: widget.controller.selectedCultura,
              hint: const Text('Selecione uma cultura'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<CulturaModel?>(
                  value: null,
                  child: Text('Todas as culturas'),
                ),
                ...widget.controller.availableCulturas.map((cultura) {
                  return DropdownMenuItem<CulturaModel?>(
                    value: cultura,
                    child: Row(
                      children: [
                        Icon(
                          _getCulturaIcon(cultura.nome),
                          size: 16,
                          color: _getCulturaColor(cultura.nome),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cultura.nome ?? 'Cultura sem nome',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (CulturaModel? cultura) {
                widget.controller.selectCultura(cultura);
                Logger.info('🌱 Cultura selecionada: ${cultura?.nome ?? 'Todas'}');
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTalhaoFilter() {
    final filteredTalhoes = widget.controller.getFilteredTalhoes();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Talhão',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TalhaoModel?>(
              value: widget.controller.selectedTalhao,
              hint: const Text('Selecione um talhão'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<TalhaoModel?>(
                  value: null,
                  child: Text('Todos os talhões'),
                ),
                ...filteredTalhoes.map((talhao) {
                  return DropdownMenuItem<TalhaoModel?>(
                    value: talhao,
                    child: Row(
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                talhao.nome ?? 'Talhão sem nome',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (talhao.area != null)
                                Text(
                                  '${talhao.area!.toStringAsFixed(2)} ha',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (TalhaoModel? talhao) {
                widget.controller.selectTalhao(talhao);
                Logger.info('🎯 Talhão selecionado: ${talhao?.nome ?? 'Todos'}');
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros Avançados',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Filtro de tipo
        _buildTypeFilter(),
        
        const SizedBox(height: 12),
        
        // Filtro de severidade
        _buildSeverityFilter(),
      ],
    );
  }
  
  Widget _buildTypeFilter() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tipo de Filtro',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.controller.state.selectedFilter,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todos'),
                      ),
                      const DropdownMenuItem(
                        value: 'critical',
                        child: Text('Críticos'),
                      ),
                      const DropdownMenuItem(
                        value: 'recent',
                        child: Text('Recentes'),
                      ),
                      const DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pendentes'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        widget.controller.state.setSelectedFilter(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSeverityFilter() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nível de Severidade',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: widget.controller.state.selectedSeverity,
                    isExpanded: true,
                    hint: const Text('Todas'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...widget.controller.state.availableSeverities.map((severity) {
                        return DropdownMenuItem<String?>(
                          value: severity,
                          child: Text(severity),
                        );
                      }),
                    ],
                    onChanged: (String? value) {
                      widget.controller.state.setSelectedSeverity(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros de Data',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Data de início
            Expanded(
              child: _buildDateField(
                label: 'Data Início',
                value: widget.controller.state.startDate,
                onChanged: (date) {
                  widget.controller.state.setStartDate(date);
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Data de fim
            Expanded(
              child: _buildDateField(
                label: 'Data Fim',
                value: widget.controller.state.endDate,
                onChanged: (date) {
                  widget.controller.state.setEndDate(date);
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Data específica
        _buildDateField(
          label: 'Data Específica',
          value: widget.controller.state.selectedDateFilter,
          onChanged: (date) {
            widget.controller.state.setSelectedDateFilter(date);
          },
        ),
      ],
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null ? _dateFormat.format(value) : 'Selecionar data',
                  style: TextStyle(
                    color: value != null ? Colors.black : Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                if (value != null)
                  IconButton(
                    onPressed: () => onChanged(null),
                    icon: const Icon(Icons.clear, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botão aplicar filtros
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Aplicar Filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Botão resetar filtros
        OutlinedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.refresh),
          label: const Text('Resetar'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
  
  // Métodos auxiliares
  void _clearAllFilters() {
    widget.controller.selectCultura(null);
    widget.controller.selectTalhao(null);
    widget.controller.state.setSelectedFilter('all');
    widget.controller.state.setSelectedSeverity(null);
    widget.controller.state.setStartDate(null);
    widget.controller.state.setEndDate(null);
    widget.controller.state.setSelectedDateFilter(null);
    
    Logger.info('🧹 Todos os filtros foram limpos');
  }
  
  void _applyFilters() {
    Logger.info('✅ Filtros aplicados');
    // TODO: Implementar aplicação dos filtros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtros aplicados com sucesso'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _resetFilters() {
    _clearAllFilters();
    Logger.info('🔄 Filtros resetados');
  }
  
  IconData _getCulturaIcon(String? nome) {
    if (nome == null) return Icons.agriculture;
    
    final nomeLower = nome.toLowerCase();
    if (nomeLower.contains('soja')) return Icons.grass;
    if (nomeLower.contains('milho')) return Icons.eco;
    if (nomeLower.contains('algodão') || nomeLower.contains('algodao')) return Icons.local_florist;
    if (nomeLower.contains('café') || nomeLower.contains('cafe')) return Icons.local_cafe;
    if (nomeLower.contains('cana')) return Icons.forest;
    
    return Icons.agriculture;
  }
  
  Color _getCulturaColor(String? nome) {
    if (nome == null) return Colors.grey;
    
    final nomeLower = nome.toLowerCase();
    if (nomeLower.contains('soja')) return Colors.green;
    if (nomeLower.contains('milho')) return Colors.yellow;
    if (nomeLower.contains('algodão') || nomeLower.contains('algodao')) return Colors.orange;
    if (nomeLower.contains('café') || nomeLower.contains('cafe')) return Colors.brown;
    if (nomeLower.contains('cana')) return Colors.lightGreen;
    
    return Colors.grey;
  }
}
