import 'package:flutter/material.dart';
import 'package:fortsmart_agro/modules/planting/models/calibragem_semente_model.dart';
import 'package:fortsmart_agro/modules/planting/services/calibragem_semente_service.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/widgets/custom_dropdown.dart';

/// Widget para seleção de calibragens de sementes
class CalibragemSementeSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onChanged;
  final bool required;
  final String label;
  final String? talhaoId;
  final String? culturaId;
  final bool showAddButton;

  const CalibragemSementeSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.required = false,
    this.label = 'Calibragem',
    this.talhaoId,
    this.culturaId,
    this.showAddButton = false,
  }) : super(key: key);

  @override
  State<CalibragemSementeSelector> createState() => _CalibragemSementeSelectorState();
}

class _CalibragemSementeSelectorState extends State<CalibragemSementeSelector> {
  final CalibragemSementeService _calibragemService = CalibragemSementeService();
  final DataCacheService _dataCacheService = DataCacheService();
  
  List<CalibragemSementeModel>? _calibragens;
  bool _isLoading = true;
  String? _selectedValue;
  
  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _loadCalibragens();
  }
  
  @override
  void didUpdateWidget(CalibragemSementeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.talhaoId != widget.talhaoId || 
        oldWidget.culturaId != widget.culturaId || 
        oldWidget.initialValue != widget.initialValue) {
      _selectedValue = widget.initialValue;
      _loadCalibragens();
    }
  }
  
  Future<void> _loadCalibragens() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<CalibragemSementeModel> calibragens = [];
      
      if (widget.talhaoId != null) {
        calibragens = await _calibragemService.listarPorTalhao(widget.talhaoId!);
      } else if (widget.culturaId != null) {
        calibragens = await _calibragemService.listarPorCultura(widget.culturaId!);
      } else {
        calibragens = await _calibragemService.listar();
      }
      
      setState(() {
        _calibragens = calibragens;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar calibragens: $e');
      setState(() {
        _calibragens = [];
        _isLoading = false;
      });
    }
  }
  
  void _onAddPressed() {
    // Aqui você pode navegar para a tela de cadastro de calibragem
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroCalibragemScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de adicionar calibragem em desenvolvimento')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: widget.label,
                value: _selectedValue,
                
                
                items: _calibragens?.map((calibragem) {
                  final String displayText = '${calibragem.dataCalibragem.day}/${calibragem.dataCalibragem.month}/${calibragem.dataCalibragem.year} - ${calibragem.metodoCalibragrem.toString().split('.').last}';
                  return DropdownMenuItem<String>(
                    value: calibragem.id,
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
                tooltip: 'Adicionar nova calibragem',
              ),
          ],
        ),
      ],
    );
  }
}
