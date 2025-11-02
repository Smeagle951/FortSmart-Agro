import 'package:flutter/material.dart';
import '../repositories/farm_repository.dart';
import '../utils/logger.dart';
import '../theme/premium_theme.dart' as theme;

/// Widget para seleção de culturas a partir do perfil da Fazenda
class FarmCropSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool isRequired;
  final String label;
  final bool showAddButton;

  const FarmCropSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Cultura',
    this.showAddButton = true,
  }) : super(key: key);

  @override
  State<FarmCropSelector> createState() => _FarmCropSelectorState();
}

class _FarmCropSelectorState extends State<FarmCropSelector> {
  final FarmRepository _farmRepository = FarmRepository();
  List<String> _crops = [];
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
      // Carregar a fazenda ativa
      final farms = await _farmRepository.getAllFarms();
      
      // Filtrar apenas fazendas ativas
      final activeFarms = farms.where((farm) => farm.isActive).toList();
      
      if (activeFarms.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nenhuma fazenda ativa encontrada';
        });
        return;
      }
      
      // Usar a primeira fazenda ativa
      final activeFarm = activeFarms.first;
      
      setState(() {
        // Obter as culturas da fazenda
        _crops = activeFarm.crops;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar culturas da fazenda: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar culturas: $e';
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
                  // Navegar para a tela de cadastro de cultura
                  Navigator.pushNamed(context, '/crop/new').then((_) {
                    // Recarregar culturas após retornar
                    _loadCrops();
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
                  onPressed: _loadCrops,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        else if (_crops.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhuma cultura cadastrada',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Navegar para a tela de cadastro de cultura
                    Navigator.pushNamed(context, '/crop/new').then((_) {
                      // Recarregar culturas após retornar
                      _loadCrops();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: theme.PremiumTheme.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                  ),
                  child: const Text('Cadastrar Cultura'),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedCropId,
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
                Icons.grass,
                color: theme.PremiumTheme.primary,
              ),
            ),
            hint: Text(
              'Selecione a cultura',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: theme.PremiumTheme.primary),
            items: _crops.map((crop) {
              return DropdownMenuItem<String>(
                value: crop,
                child: Text(
                  crop,
                  style: TextStyle(color: theme.PremiumTheme.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCropId = value;
              });
              if (value != null) {
                widget.onChanged(value);
              }
            },
            validator: widget.isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma cultura';
                    }
                    return null;
                  }
                : null,
          ),
      ],
    );
  }
}
