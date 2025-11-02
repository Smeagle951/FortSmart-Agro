import 'package:flutter/material.dart';
import '../../../models/crop_variety.dart';
import '../services/modules_integration_service.dart';
import '../../../screens/crops/crop_variety_form_screen.dart';

/// Widget aprimorado para seleção de variedades de cultura com integração entre módulos
class EnhancedCropVarietySelector extends StatefulWidget {
  final String? initialValue;
  final String? cropId;
  final Function(String?) onChanged;
  final bool isRequired;
  final String label;
  final double? width;

  const EnhancedCropVarietySelector({
    Key? key,
    this.initialValue,
    required this.cropId,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Variedade',
    this.width,
  }) : super(key: key);

  @override
  State<EnhancedCropVarietySelector> createState() => _EnhancedCropVarietySelectorState();
}

class _EnhancedCropVarietySelectorState extends State<EnhancedCropVarietySelector> {
  final _modulesService = ModulesIntegrationService();
  List<CropVariety> _varieties = [];
  String? _selectedVarietyId;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentCropId;

  @override
  void initState() {
    super.initState();
    _selectedVarietyId = widget.initialValue;
    _currentCropId = widget.cropId;
    if (widget.cropId != null) {
      _loadVarieties();
    }
  }

  @override
  void didUpdateWidget(EnhancedCropVarietySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a cultura mudou, recarregar as variedades
    if (widget.cropId != oldWidget.cropId) {
      _currentCropId = widget.cropId;
      _selectedVarietyId = null;
      widget.onChanged(null); // Limpar a seleção
      
      if (widget.cropId != null) {
        _loadVarieties();
      } else {
        setState(() {
          _varieties = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVarieties() async {
    if (_currentCropId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carrega variedades da cultura usando o novo serviço de integração
      final variedades = await _modulesService.getVariedadesPorCultura(
        _currentCropId!,
        forceRefresh: true
      );
      
      setState(() {
        _varieties = variedades;
        _isLoading = false;
        
        // Se não encontrou a variedade selecionada na nova lista, limpa a seleção
        if (_selectedVarietyId != null && 
            !_varieties.any((v) => v.id.toString() == _selectedVarietyId)) {
          _selectedVarietyId = null;
          widget.onChanged(null);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao carregar variedades: $e';
        _varieties = [];
      });
    }
  }

  Future<void> _navigateToCreateVariety() async {
    if (_currentCropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma cultura primeiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Navega para a tela de criação de variedade
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropVarietyFormScreen(cropId: _currentCropId!),
      ),
    );

    // Se retornou com sucesso, recarrega as variedades
    if (result == true) {
      _loadVarieties();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Se não tiver cultura selecionada, mostra mensagem
    if (_currentCropId == null) {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade300),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Selecione uma cultura primeiro',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
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
                  : _varieties.isEmpty
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
          onPressed: _loadVarieties,
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
                  'Nenhuma variedade cadastrada para esta cultura',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Cadastre variedades antes de continuar'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar Variedade'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _navigateToCreateVariety,
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
              value: _selectedVarietyId,
              isExpanded: true,
              hint: const Text('Selecione uma variedade'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedVarietyId = newValue;
                });
                widget.onChanged(newValue);
              },
              items: _varieties.map<DropdownMenuItem<String>>((CropVariety variety) {
                return DropdownMenuItem<String>(
                  value: variety.id,
                  child: Text(
                    variety.name,
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
              onPressed: _loadVarieties,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Variedade'),
              onPressed: _navigateToCreateVariety,
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
