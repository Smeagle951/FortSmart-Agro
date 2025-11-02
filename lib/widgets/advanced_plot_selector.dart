import 'package:flutter/material.dart';
import '../models/plot.dart';
import '../repositories/plot_repository.dart';
import '../repositories/talhao_plot_adapter.dart';

import '../screens/talhoes_com_safras/novo_talhao_screen_wrapper.dart';
import '../theme/premium_theme.dart' as theme;
import '../utils/logger.dart';
import 'plot_thumbnail.dart';

/// Widget para seleção de talhões com funcionalidades avançadas
class AdvancedPlotSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool isRequired;
  final String label;
  final bool showAddButton;
  final bool showThumbnail;

  const AdvancedPlotSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Talhão',
    this.showAddButton = true,
    this.showThumbnail = true,
  }) : super(key: key);

  @override
  State<AdvancedPlotSelector> createState() => _AdvancedPlotSelectorState();
}

class _AdvancedPlotSelectorState extends State<AdvancedPlotSelector> {
  final PlotRepository _plotRepository = PlotRepository();
  final TalhaoPlotAdapter _talhaoAdapter = TalhaoPlotAdapter();
  List<Plot> _plots = [];
  String? _selectedPlotId;
  bool _isLoading = true;
  String? _errorMessage;
  Plot? _selectedPlot;

  @override
  void initState() {
    super.initState();
    _selectedPlotId = widget.initialValue;
    _loadPlots();
  }

  Future<void> _loadPlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Primeiro sincronizar os talhões do Mapbox com os plots
      await _talhaoAdapter.syncTalhoesToPlots();
      
      // Obter os plots sincronizados
      final plots = await _talhaoAdapter.getAllTalhoesAsPlots();
      
      setState(() {
        _plots = plots;
        _isLoading = false;
        
        // Se tiver um ID selecionado, encontrar o plot correspondente
        if (_selectedPlotId != null && _plots.isNotEmpty) {
          try {
            _selectedPlot = _plots.firstWhere(
              (plot) => plot.id.toString() == _selectedPlotId,
            );
          } catch (e) {
            // Se não encontrar, usar o primeiro da lista
            _selectedPlot = _plots.isNotEmpty ? _plots.first : null;
          }
        }
      });
      
      Logger.info('Talhões carregados com sucesso via adaptador: ${plots.length} talhões encontrados');
    } catch (e) {
      Logger.error('Erro ao carregar talhões: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar talhões: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label + (widget.isRequired ? ' *' : ''),
              style: TextStyle(
                color: theme.PremiumTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (widget.showAddButton)
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NovoTalhaoScreenWrapper(),
                    ),
                  ).then((_) {
                    _loadPlots();
                  });
                },
                icon: Icon(Icons.add, color: theme.PremiumTheme.primary),
                label: Text(
                  'Adicionar',
                  style: TextStyle(color: theme.PremiumTheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadPlots,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        else if (_plots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhum talhão cadastrado',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NovoTalhaoScreenWrapper(),
                      ),
                    ).then((_) {
                      _loadPlots();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: theme.PremiumTheme.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                  ),
                  child: const Text('Cadastrar Talhão'),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedPlotId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.PremiumTheme.primary),
                  ),
                  prefixIcon: Icon(
                    Icons.map_outlined,
                    color: theme.PremiumTheme.primary,
                  ),
                ),
                hint: Text(
                  'Selecione o talhão',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: theme.PremiumTheme.primary),
                items: _plots.map((plot) {
                  return DropdownMenuItem<String>(
                    value: plot.id.toString(),
                    child: Row(
                      children: [
                        Text(
                          plot.name,
                          style: TextStyle(color: theme.PremiumTheme.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${plot.area != null ? plot.area!.toStringAsFixed(2) : "0.00"} ha)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlotId = value;
                    if (value != null && _plots.isNotEmpty) {
                      try {
                        _selectedPlot = _plots.firstWhere(
                          (plot) => plot.id.toString() == value,
                        );
                      } catch (e) {
                        // Se não encontrar, usar o primeiro da lista
                        _selectedPlot = _plots.first;
                      }
                    } else {
                      _selectedPlot = null;
                    }
                  });
                  if (value != null) {
                    widget.onChanged(value);
                  }
                },
                validator: widget.isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione um talhão';
                        }
                        return null;
                      }
                    : null,
              ),
              if (widget.showThumbnail && _selectedPlot != null) ...[
                const SizedBox(height: 16),
                PlotThumbnail(plot: _selectedPlot!),
              ],
            ],
          ),
      ],
    );
  }
}
