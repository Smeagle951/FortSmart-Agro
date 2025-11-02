import 'package:flutter/material.dart';
import '../models/variety.dart';
import '../repositories/variety_repository.dart';
import '../utils/logger.dart';

/// Widget para seleção de variedades a partir do banco de dados
class VarietySelector extends StatefulWidget {
  final int? initialValue;
  final Function(int) onChanged;
  final bool isRequired;
  final String label;
  final int? culturaId;

  const VarietySelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Variedade',
    this.culturaId,
  }) : super(key: key);

  @override
  State<VarietySelector> createState() => _VarietySelectorState();
}

class _VarietySelectorState extends State<VarietySelector> {
  final VarietyRepository _varietyRepository = VarietyRepository();
  List<Variety> _varieties = [];
  int? _selectedVarietyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedVarietyId = widget.initialValue;
    _loadVarieties();
  }

  @override
  void didUpdateWidget(VarietySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar variedades se a cultura mudar
    if (widget.culturaId != oldWidget.culturaId) {
      _loadVarieties();
    }
  }

  Future<void> _loadVarieties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Variety> varieties = [];
      if (widget.culturaId != null) {
        varieties = await _varietyRepository.getByCropId(widget.culturaId!.toString());
      } else {
        varieties = await _varietyRepository.getAll();
      }

      // Verificar se o ID selecionado existe na lista de variedades carregadas
      bool selectedIdExists = _selectedVarietyId != null && 
          varieties.any((variety) => variety.id == _selectedVarietyId);
      
      setState(() {
        _varieties = varieties;
        // Se o ID selecionado não existir na lista, limpar a seleção
        if (!selectedIdExists && _selectedVarietyId != null) {
          print('ID selecionado $_selectedVarietyId não encontrado nas variedades carregadas');
          _selectedVarietyId = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar variedades: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar variedades: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label + (widget.isRequired ? ' *' : ''),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _varieties.isEmpty
                ? _buildEmptyVarietiesMessage()
                : _buildDropdown(),
      ],
    );
  }

  Widget _buildEmptyVarietiesMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nenhuma variedade encontrada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.culturaId != null 
                      ? 'Cadastre variedades para esta cultura antes de continuar'
                      : 'Cadastre variedades antes de continuar',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Navegar para tela de cadastro de variedades
                    // Implementar navegação
                  },
                  child: const Text('Cadastrar Variedade'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedVarietyId,
          isExpanded: true,
          hint: Text(widget.label + (widget.isRequired ? ' *' : '')),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (value) {
            setState(() {
              _selectedVarietyId = value;
            });
            if (value != null) {
              widget.onChanged(value);
            }
          },
          items: _varieties.map<DropdownMenuItem<int>>((Variety variety) {
            return DropdownMenuItem<int>(
              value: variety.id,
              child: Text(
                variety.nome,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
