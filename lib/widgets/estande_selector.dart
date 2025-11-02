import 'package:flutter/material.dart';
import 'package:fortsmart_agro/modules/planting/models/estande_model.dart';
import 'package:fortsmart_agro/modules/planting/services/estande_service.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/widgets/custom_dropdown.dart';
import 'package:intl/intl.dart';

/// Widget para seleção de avaliações de estande
class EstandeSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onChanged;
  final bool required;
  final String label;
  final String? talhaoId;
  final String? culturaId;
  final bool showAddButton;

  const EstandeSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.required = false,
    this.label = 'Avaliação de Estande',
    this.talhaoId,
    this.culturaId,
    this.showAddButton = false,
  }) : super(key: key);

  @override
  State<EstandeSelector> createState() => _EstandeSelectorState();
}

class _EstandeSelectorState extends State<EstandeSelector> {
  final EstandeService _estandeService = EstandeService();
  final DataCacheService _dataCacheService = DataCacheService();
  
  List<EstandeModel>? _estandes;
  bool _isLoading = true;
  String? _selectedValue;
  
  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _loadEstandes();
  }
  
  @override
  void didUpdateWidget(EstandeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.talhaoId != widget.talhaoId || 
        oldWidget.culturaId != widget.culturaId || 
        oldWidget.initialValue != widget.initialValue) {
      _selectedValue = widget.initialValue;
      _loadEstandes();
    }
  }
  
  Future<void> _loadEstandes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<EstandeModel> estandes = [];
      
      if (widget.talhaoId != null) {
        estandes = await _estandeService.listarPorTalhao(widget.talhaoId!);
      } else if (widget.culturaId != null) {
        estandes = await _estandeService.listarPorCultura(widget.culturaId!);
      } else {
        estandes = await _estandeService.listar();
      }
      
      setState(() {
        _estandes = estandes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar avaliações de estande: $e');
      setState(() {
        _estandes = [];
        _isLoading = false;
      });
    }
  }
  
  void _onAddPressed() {
    // Aqui você pode navegar para a tela de cadastro de avaliação de estande
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroEstandeScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de adicionar avaliação de estande em desenvolvimento')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: widget.label,
                value: _selectedValue,
                
                
                items: _estandes?.map((estande) {
                  final String displayText = '${dateFormat.format(estande.dataAvaliacao)} - ${estande.plantasPorMetro.toStringAsFixed(1)} pl/m';
                  return DropdownMenuItem<String>(
                    value: estande.id,
                    child: Text(displayText),
                  );
                }).toList() ?? [],
                onChanged: (value) {
                  setState(() {
                    _selectedValue = value;
                  });
                  widget.onChanged(value);
                },
                
              ),
            ),
            if (widget.showAddButton)
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _onAddPressed,
                tooltip: 'Adicionar nova avaliação de estande',
              ),
          ],
        ),
      ],
    );
  }
}
