import 'package:flutter/material.dart';
import '../models/crop.dart' as app_crop;
import '../services/culture_import_service.dart';

/// Widget para seleção de culturas usando o CultureImportService
class CulturaSelector extends StatefulWidget {
  final String? initialValue;
  final Function(app_crop.Crop) onChanged;
  final bool required;
  final String label;

  const CulturaSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.required = false,
    this.label = 'Cultura',
  }) : super(key: key);

  @override
  _CulturaSelectorState createState() => _CulturaSelectorState();
}

class _CulturaSelectorState extends State<CulturaSelector> {
  final CultureImportService _cultureImportService = CultureImportService();
  List<app_crop.Crop> _culturas = [];
  app_crop.Crop? _selectedCultura;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCulturas();
  }

  Future<void> _loadCulturas() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Inicializar o serviço de importação
      await _cultureImportService.initialize();
      
      // Carregar culturas do módulo Culturas da Fazenda
      final culturas = await _cultureImportService.getAllCrops();
      
      // Converter Map para Crop objects
      final culturasConvertidas = culturas.map((culturaMap) => app_crop.Crop(
        id: int.tryParse(culturaMap['id']?.toString() ?? '0') ?? 0,
        name: culturaMap['name'] ?? '',
        description: culturaMap['description'] ?? '',
      )).toList();
      
      // Verificar se o valor inicial existe na lista de culturas
      app_crop.Crop? selectedCultura;
      
      if (widget.initialValue != null && culturasConvertidas.isNotEmpty) {
        try {
          selectedCultura = culturasConvertidas.firstWhere(
            (cultura) => cultura.id.toString() == widget.initialValue,
            orElse: () => throw Exception('Cultura não encontrada'),
          );
        } catch (e) {
          print('Cultura com ID ${widget.initialValue} não encontrada na lista de culturas');
          selectedCultura = null;
        }
      }
      
      setState(() {
        _culturas = culturasConvertidas;
        _selectedCultura = selectedCultura;
        _isLoading = false;
        
        if (_selectedCultura != null) {
          widget.onChanged(_selectedCultura!);
        }
      });
    } catch (e) {
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
        Text(
          '${widget.label}${widget.required ? ' *' : ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          )
        else
          DropdownButtonFormField<app_crop.Crop>(
            value: _selectedCultura,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: Text('Selecione uma ${widget.label.toLowerCase()}'),
            items: _culturas.map((cultura) {
              return DropdownMenuItem<app_crop.Crop>(
                value: cultura,
                child: Text(cultura.name),
              );
            }).toList(),
            onChanged: (app_crop.Crop? newValue) {
              setState(() {
                _selectedCultura = newValue;
              });
              if (newValue != null) {
                widget.onChanged(newValue);
              }
            },
            validator: widget.required
                ? (value) {
                    if (value == null) {
                      return 'Por favor, selecione uma ${widget.label.toLowerCase()}';
                    }
                    return null;
                  }
                : null,
          ),
      ],
    );
  }
} 