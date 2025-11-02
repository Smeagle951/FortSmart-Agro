import 'package:flutter/material.dart';
import '../../../models/talhao_model_new.dart';
import '../services/modules_integration_service.dart';
import '../../../screens/plots/plot_form_screen.dart';

/// Widget aprimorado para seleção de talhões com integração entre módulos
class EnhancedPlotSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onChanged;
  final bool isRequired;
  final String label;
  final double? width;

  const EnhancedPlotSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Talhão',
    this.width,
  }) : super(key: key);

  @override
  State<EnhancedPlotSelector> createState() => _EnhancedPlotSelectorState();
}

class _EnhancedPlotSelectorState extends State<EnhancedPlotSelector> {
  final _modulesService = ModulesIntegrationService();
  List<TalhaoModel> _plots = [];
  String? _selectedPlotId;
  bool _isLoading = true;
  String? _errorMessage;

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
      // Carrega talhões com safra usando o novo serviço de integração
      final talhoes = await _modulesService.getTalhoes(forceRefresh: true);
      
      setState(() {
        _plots = talhoes;
        _isLoading = false;
        
        // Se não encontrou o talhão selecionado na nova lista, limpa a seleção
        if (_selectedPlotId != null && 
            !_plots.any((p) => p.id.toString() == _selectedPlotId)) {
          _selectedPlotId = null;
          widget.onChanged(null);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao carregar talhões: $e';
        _plots = [];
      });
    }
  }

  Future<void> _navigateToCreatePlot() async {
    // Navega para a tela de criação de talhão
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlotFormScreen(),
      ),
    );

    // Se retornou com sucesso, recarrega os talhões
    if (result == true) {
      _loadPlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: widget.width,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (widget.isRequired)
                    Text(
                      '*',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : _plots.isEmpty
                      ? _buildEmptyWidget()
                      : _buildDropdownWidget(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
          onPressed: _loadPlots,
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Nenhum talhão cadastrado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Cadastre talhões antes de continuar'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar Talhão'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _navigateToCreatePlot,
        ),
      ],
    );
  }

  Widget _buildDropdownWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlotId,
              isExpanded: true,
              hint: const Text('Selecione um talhão'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPlotId = newValue;
                });
                widget.onChanged(newValue);
              },
              items: _plots.map<DropdownMenuItem<String>>((TalhaoModel plot) {
                return DropdownMenuItem<String>(
                  value: plot.id,
                  child: Text(
                    '${plot.nome} (${plot.area.toStringAsFixed(2)} ha)',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Atualizar'),
              onPressed: _loadPlots,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Talhão'),
              onPressed: _navigateToCreatePlot,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
