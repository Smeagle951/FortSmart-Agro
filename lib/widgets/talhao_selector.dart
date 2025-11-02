import 'package:flutter/material.dart';
import '../models/talhao_model.dart';
import '../services/talhao_unified_loader_service.dart';

/// Widget para seleção de talhões
class TalhaoSelector extends StatefulWidget {
  final String? initialValue;
  final Function(TalhaoModel) onChanged;
  final bool required;
  final String label;

  const TalhaoSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.required = false,
    this.label = 'Talhão',
  }) : super(key: key);

  @override
  _TalhaoSelectorState createState() => _TalhaoSelectorState();
}

class _TalhaoSelectorState extends State<TalhaoSelector> {
  final TalhaoUnifiedLoaderService _talhaoLoader = TalhaoUnifiedLoaderService();
  List<TalhaoModel> _talhoes = [];
  TalhaoModel? _selectedTalhao;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
  }

  Future<void> _loadTalhoes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final talhoes = await _talhaoLoader.carregarTalhoes();
      
      // Verificar se o valor inicial existe na lista de talhões
      TalhaoModel? selectedTalhao;
      
      if (widget.initialValue != null && talhoes.isNotEmpty) {
        try {
          selectedTalhao = talhoes.firstWhere(
            (talhao) => talhao.id == widget.initialValue,
            orElse: () => throw Exception('Talhão não encontrado'),
          );
        } catch (e) {
          print('Talhão com ID ${widget.initialValue} não encontrado na lista de talhões');
          selectedTalhao = null;
        }
      }
      
      setState(() {
        _talhoes = talhoes;
        _selectedTalhao = selectedTalhao;
        _isLoading = false;
        
        if (_selectedTalhao != null) {
          widget.onChanged(_selectedTalhao!);
        }
      });
    } catch (e) {
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
          DropdownButtonFormField<TalhaoModel>(
            value: _selectedTalhao,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: Text('Selecione ${widget.label.toLowerCase()}'),
            isExpanded: true,
            items: _talhoes.map((talhao) {
              return DropdownMenuItem<TalhaoModel>(
                value: talhao,
                child: Text(talhao.nome),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTalhao = value;
                });
                widget.onChanged(value);
              }
            },
            validator: widget.required
                ? (value) => value == null ? 'Selecione um talhão' : null
                : null,
          ),
      ],
    );
  }
}
