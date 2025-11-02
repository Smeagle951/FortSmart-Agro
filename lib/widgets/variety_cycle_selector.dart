import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_widgets.dart';
import '../widgets/adaptive_layouts.dart';
import 'add_variety_modal.dart';

/// Modelo para representar uma variedade
class Variety {
  final String id;
  final String name;
  final String description;
  final String type; // Ex: "RR", "Intacta", "Convencional"
  final Color color;

  const Variety({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.color = Colors.orange,
  });
}

/// Modelo para representar um ciclo
class Cycle {
  final String id;
  final String name;
  final int days;
  final String description;

  const Cycle({
    required this.id,
    required this.name,
    required this.days,
    required this.description,
  });
}

/// Resultado da seleção de variedade e ciclo
class VarietyCycleSelection {
  final Variety variety;
  final Cycle cycle;

  const VarietyCycleSelection({
    required this.variety,
    required this.cycle,
  });

  String get displayName => '${variety.name} - ${cycle.name}';
}

/// Widget responsivo para seleção de variedade e ciclo em duas etapas
class VarietyCycleSelector extends StatefulWidget {
  final List<Variety> varieties;
  final List<Cycle> cycles;
  final VarietyCycleSelection? initialSelection;
  final Function(VarietyCycleSelection) onSelectionChanged;
  final String? title;
  final String? varietyLabel;
  final String? cycleLabel;
  final String? cropId;
  final String? cropName;
  final Function(String varietyId)? onVarietyAdded;

  const VarietyCycleSelector({
    Key? key,
    required this.varieties,
    required this.cycles,
    this.initialSelection,
    required this.onSelectionChanged,
    this.title,
    this.varietyLabel,
    this.cycleLabel,
    this.cropId,
    this.cropName,
    this.onVarietyAdded,
  }) : super(key: key);

  @override
  State<VarietyCycleSelector> createState() => _VarietyCycleSelectorState();
}

class _VarietyCycleSelectorState extends State<VarietyCycleSelector> {
  Variety? _selectedVariety;
  Cycle? _selectedCycle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedVariety = widget.initialSelection!.variety;
      _selectedCycle = widget.initialSelection!.cycle;
    }
  }

  /// Mostra o modal de seleção de variedade e ciclo
  static Future<VarietyCycleSelection?> show({
    required BuildContext context,
    required List<Variety> varieties,
    required List<Cycle> cycles,
    VarietyCycleSelection? initialSelection,
    String? title,
    String? cropId,
    String? cropName,
    Function(String varietyId)? onVarietyAdded,
  }) async {
    VarietyCycleSelection? result;

    await showModalBottomSheet<VarietyCycleSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle para arrastar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: ResponsiveUtils.getAdaptivePadding(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: Colors.green.shade700,
                      size: ResponsiveUtils.getAdaptiveFontSize(context, small: 20.0, compact: 24.0),
                    ),
                    SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context)),
                    Expanded(
                      child: ResponsiveText(
                        title ?? 'Selecione Variedade e Ciclo',
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 16.0, compact: 18.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo
              Expanded(
              child: VarietyCycleSelector(
                varieties: varieties,
                cycles: cycles,
                initialSelection: initialSelection,
                onSelectionChanged: (selection) {
                  result = selection;
                  Navigator.of(context).pop(selection);
                },
                cropId: cropId,
                cropName: cropName,
                onVarietyAdded: onVarietyAdded,
              ),
              ),
            ],
          ),
        ),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getAdaptivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de Variedade
          _buildVarietySection(),
          
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
          
          // Seção de Ciclo
          _buildCycleSection(),
          
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
          
          // Preview da seleção
          if (_selectedVariety != null && _selectedCycle != null)
            _buildSelectionPreview(),
        ],
      ),
    );
  }

  Widget _buildVarietySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ResponsiveText(
                widget.varietyLabel ?? 'Tipo de Variedade',
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            if (widget.cropId != null && widget.cropName != null && widget.onVarietyAdded != null)
              IconButton(
                onPressed: _showAddVarietyModal,
                icon: Icon(
                  Icons.add_circle,
                  color: Colors.green.shade700,
                  size: ResponsiveUtils.getAdaptiveFontSize(context, small: 20.0, compact: 24.0),
                ),
                tooltip: 'Adicionar nova variedade',
              ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 8.0, compact: 12.0)),
        
        if (ResponsiveUtils.shouldUseCompactLayout(context))
          _buildCompactVarietySelector()
        else
          _buildGridVarietySelector(),
      ],
    );
  }

  Widget _buildCompactVarietySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
      ),
      child: DropdownButton<Variety>(
        value: _selectedVariety,
        isExpanded: true,
        hint: Padding(
          padding: ResponsiveUtils.getAdaptivePadding(context, small: const EdgeInsets.all(8.0), compact: const EdgeInsets.all(12.0)),
          child: ResponsiveText('Selecione o tipo de variedade'),
        ),
        padding: ResponsiveUtils.getAdaptivePadding(context, small: const EdgeInsets.all(8.0), compact: const EdgeInsets.all(12.0)),
        onChanged: (Variety? variety) {
          setState(() {
            _selectedVariety = variety;
            _selectedCycle = null; // Reset ciclo quando muda variedade
          });
          _notifySelectionChanged();
        },
        items: widget.varieties.map((variety) {
          return DropdownMenuItem<Variety>(
            value: variety,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: variety.color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, small: 8.0, compact: 12.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        variety.name,
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                        fontWeight: FontWeight.w500,
                      ),
                      ResponsiveText(
                        variety.type,
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 10.0, compact: 12.0),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridVarietySelector() {
    return AdaptiveGrid(
      children: widget.varieties.map((variety) {
        final isSelected = _selectedVariety?.id == variety.id;
        
        return AdaptiveCard(
          onTap: () {
            setState(() {
              _selectedVariety = variety;
              _selectedCycle = null; // Reset ciclo quando muda variedade
            });
            _notifySelectionChanged();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: ResponsiveUtils.shouldUseCompactLayout(context) ? 32.0 : 48.0,
                height: ResponsiveUtils.shouldUseCompactLayout(context) ? 32.0 : 48.0,
                decoration: BoxDecoration(
                  color: isSelected ? variety.color : variety.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.shouldUseCompactLayout(context) ? 16.0 : 24.0),
                  border: Border.all(
                    color: isSelected ? variety.color : Colors.transparent,
                    width: isSelected ? 2.0 : 0,
                  ),
                ),
                child: Icon(
                  Icons.eco,
                  color: isSelected ? Colors.white : variety.color,
                  size: ResponsiveUtils.shouldUseCompactLayout(context) ? 16.0 : 24.0,
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
              
              ResponsiveText(
                variety.name,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 2.0, compact: 4.0)),
              
              ResponsiveText(
                variety.type,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 10.0, compact: 12.0),
                color: Colors.grey.shade600,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCycleSection() {
    if (_selectedVariety == null) {
      return Container(
        padding: ResponsiveUtils.getAdaptivePadding(context),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context)),
            Expanded(
              child: ResponsiveText(
                'Selecione primeiro um tipo de variedade',
                color: Colors.grey.shade600,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          widget.cycleLabel ?? 'Ciclo de Desenvolvimento',
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
        
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 8.0, compact: 12.0)),
        
        if (ResponsiveUtils.shouldUseCompactLayout(context))
          _buildCompactCycleSelector()
        else
          _buildGridCycleSelector(),
      ],
    );
  }

  Widget _buildCompactCycleSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
      ),
      child: DropdownButton<Cycle>(
        value: _selectedCycle,
        isExpanded: true,
        hint: Padding(
          padding: ResponsiveUtils.getAdaptivePadding(context, small: const EdgeInsets.all(8.0), compact: const EdgeInsets.all(12.0)),
          child: ResponsiveText('Selecione o ciclo'),
        ),
        padding: ResponsiveUtils.getAdaptivePadding(context, small: const EdgeInsets.all(8.0), compact: const EdgeInsets.all(12.0)),
        onChanged: (Cycle? cycle) {
          setState(() {
            _selectedCycle = cycle;
          });
          _notifySelectionChanged();
        },
        items: widget.cycles.map((cycle) {
          return DropdownMenuItem<Cycle>(
            value: cycle,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, small: 8.0, compact: 12.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        cycle.name,
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                        fontWeight: FontWeight.w500,
                      ),
                      ResponsiveText(
                        '${cycle.days} dias',
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 10.0, compact: 12.0),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridCycleSelector() {
    return AdaptiveGrid(
      children: widget.cycles.map((cycle) {
        final isSelected = _selectedCycle?.id == cycle.id;
        
        return AdaptiveCard(
          onTap: () {
            setState(() {
              _selectedCycle = cycle;
            });
            _notifySelectionChanged();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: ResponsiveUtils.shouldUseCompactLayout(context) ? 32.0 : 48.0,
                height: ResponsiveUtils.shouldUseCompactLayout(context) ? 32.0 : 48.0,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.shouldUseCompactLayout(context) ? 16.0 : 24.0),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: isSelected ? 2.0 : 0,
                  ),
                ),
                child: Icon(
                  Icons.schedule,
                  color: isSelected ? Colors.white : Colors.blue,
                  size: ResponsiveUtils.shouldUseCompactLayout(context) ? 16.0 : 24.0,
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
              
              ResponsiveText(
                cycle.name,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 2.0, compact: 4.0)),
              
              ResponsiveText(
                '${cycle.days} dias',
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 10.0, compact: 12.0),
                color: Colors.grey.shade600,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectionPreview() {
    return Container(
      padding: ResponsiveUtils.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Seleção Final:',
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 2.0, compact: 4.0)),
                ResponsiveText(
                  '${_selectedVariety!.name} (${_selectedVariety!.type})',
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                  color: Colors.green.shade700,
                ),
                ResponsiveText(
                  'Ciclo: ${_selectedCycle!.name} (${_selectedCycle!.days} dias)',
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                  color: Colors.green.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _notifySelectionChanged() {
    if (_selectedVariety != null && _selectedCycle != null) {
      widget.onSelectionChanged(
        VarietyCycleSelection(
          variety: _selectedVariety!,
          cycle: _selectedCycle!,
        ),
      );
    }
  }

  void _showAddVarietyModal() {
    showDialog(
      context: context,
      builder: (context) => AddVarietyModal(
        cropId: widget.cropId!,
        cropName: widget.cropName!,
        onVarietyAdded: (varietyId) {
          // Recarregar variedades e notificar callback
          widget.onVarietyAdded?.call(varietyId);
          
          // Mostrar mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nova variedade adicionada! Recarregue a lista.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
