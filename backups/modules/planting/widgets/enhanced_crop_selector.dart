import 'package:flutter/material.dart';
import '../../../models/crop.dart';
import '../services/modules_integration_service.dart';
import '../../../screens/crops/crop_form_screen.dart';

/// Widget aprimorado para seleção de culturas com integração entre módulos
class EnhancedCropSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onChanged;
  final bool isRequired;
  final String label;
  final double? width;

  const EnhancedCropSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Cultura',
    this.width,
  }) : super(key: key);

  @override
  State<EnhancedCropSelector> createState() => _EnhancedCropSelectorState();
}

class _EnhancedCropSelectorState extends State<EnhancedCropSelector> {
  final _modulesService = ModulesIntegrationService();
  List<Crop> _crops = [];
  String? _selectedCropId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCropId = widget.initialValue;
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carrega culturas usando o novo serviço de integração
      final culturas = await _modulesService.getCulturas(forceRefresh: true);
      
      setState(() {
        _crops = culturas;
        _isLoading = false;
        
        // Se não encontrou a cultura selecionada na nova lista, limpa a seleção
        if (_selectedCropId != null && 
            !_crops.any((c) => c.id.toString() == _selectedCropId)) {
          _selectedCropId = null;
          widget.onChanged(null);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao carregar culturas: $e';
        _crops = [];
      });
    }
  }

  Future<void> _navigateToCreateCrop() async {
    // Navega para a tela de criação de cultura
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CropFormScreen(),
      ),
    );

    // Se retornou com sucesso, recarrega as culturas
    if (result == true) {
      _loadCrops();
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
                  : _crops.isEmpty
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
          onPressed: _loadCrops,
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
                  'Nenhuma cultura cadastrada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Cadastre culturas antes de continuar'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar Cultura'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF228B22),
            foregroundColor: Colors.white,
          ),
          onPressed: _navigateToCreateCrop,
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
              value: _selectedCropId,
              isExpanded: true,
              hint: const Text('Selecione uma cultura'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCropId = newValue;
                });
                widget.onChanged(newValue);
              },
              items: _crops.map<DropdownMenuItem<String>>((Crop crop) {
                return DropdownMenuItem<String>(
                  value: crop.id,
                  child: Text(
                    crop.name,
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
              onPressed: _loadCrops,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Cultura'),
              onPressed: _navigateToCreateCrop,
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
