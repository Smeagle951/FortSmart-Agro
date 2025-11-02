import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';

/// Widget para seleção de fazenda
/// Permite ao usuário escolher entre múltiplas fazendas e filtrar dados
class FarmSelectorWidget extends StatefulWidget {
  final String? selectedFarmId;
  final Function(String? farmId)? onFarmSelected;
  final bool showAllOption;
  final String? label;
  final bool enabled;

  const FarmSelectorWidget({
    Key? key,
    this.selectedFarmId,
    this.onFarmSelected,
    this.showAllOption = true,
    this.label,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<FarmSelectorWidget> createState() => _FarmSelectorWidgetState();
}

class _FarmSelectorWidgetState extends State<FarmSelectorWidget> {
  final FarmService _farmService = FarmService();
  List<Farm> _farms = [];
  bool _isLoading = true;
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _selectedFarmId = widget.selectedFarmId;
    _loadFarms();
  }

  @override
  void didUpdateWidget(FarmSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFarmId != widget.selectedFarmId) {
      _selectedFarmId = widget.selectedFarmId;
    }
  }

  Future<void> _loadFarms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final farms = await _farmService.getAllFarms();
      setState(() {
        _farms = farms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar fazendas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFarmDisplayName(Farm? farm) {
    if (farm == null) return 'Todas as Fazendas';
    return '${farm.name} (${farm.totalArea.toStringAsFixed(1)} ha)';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.agriculture,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label ?? 'Fazenda',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_farms.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_farms.length} fazendas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_farms.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.agriculture_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nenhuma fazenda cadastrada',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/farm/add').then((_) {
                          _loadFarms();
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Criar Fazenda'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedFarmId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  enabled: widget.enabled,
                ),
                hint: Text(widget.showAllOption ? 'Todas as Fazendas' : 'Selecione uma fazenda'),
                isExpanded: true,
                items: [
                  if (widget.showAllOption)
                    DropdownMenuItem<String>(
                      value: null,
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Todas as Fazendas'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_farms.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ..._farms.map((farm) {
                    final isSelected = _selectedFarmId == farm.id;
                    return DropdownMenuItem<String>(
                      value: farm.id,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isSelected ? Colors.green : Colors.grey.shade300,
                              child: farm.logoUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        farm.logoUrl!,
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.agriculture,
                                            size: 14,
                                            color: isSelected ? Colors.white : Colors.grey.shade600,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.agriculture,
                                      size: 14,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    farm.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.green.shade700 : null,
                                    ),
                                  ),
                                  Text(
                                    '${farm.plotsCount} talhões • ${farm.totalArea.toStringAsFixed(1)} ha',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: widget.enabled ? (String? value) {
                  setState(() {
                    _selectedFarmId = value;
                  });
                  widget.onFarmSelected?.call(value);
                } : null,
              ),
            if (_farms.isNotEmpty && _selectedFarmId != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtro ativo: ${_farms.firstWhere((f) => f.id == _selectedFarmId).name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.showAllOption)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFarmId = null;
                          });
                          widget.onFarmSelected?.call(null);
                        },
                        child: Text(
                          'Limpar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
