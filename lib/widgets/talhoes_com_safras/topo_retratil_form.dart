import 'package:flutter/material.dart';
import '../../../models/cultura_model.dart';
import 'dart:ui';

// Função auxiliar para converter string hexadecimal para Color
Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class TopoRetratilForm extends StatefulWidget {
  final Function(String) onNomeChanged;
  final Function(String) onCulturaChanged;
  final List<CulturaModel> culturaOpcoes;
  final String? nomeInicial;
  final String? culturaIdInicial;

  const TopoRetratilForm({
    Key? key,
    required this.onNomeChanged,
    required this.onCulturaChanged,
    required this.culturaOpcoes,
    this.nomeInicial,
    this.culturaIdInicial,
    required Function(dynamic safraId) onSafraChanged,
    required bool aberto,
    required Function() onExpandir,
    required TextEditingController nomeController,
    required String safraSelecionada,
    required List<String> safraOpcoes,
    String? culturaSelecionada,
  }) : super(key: key);

  @override
  State<TopoRetratilForm> createState() => _TopoRetratilFormState();
}

class _TopoRetratilFormState extends State<TopoRetratilForm> {
  late TextEditingController _nomeController;
  String? _culturaIdSelecionada;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeInicial ?? '');
    _culturaIdSelecionada = widget.culturaIdInicial;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 180 : 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho com botão de expandir/retrair
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: _isExpanded ? Radius.zero : const Radius.circular(8),
                  bottomRight: _isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Informações do Talhão',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // Conteúdo do formulário
          if (_isExpanded)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de nome
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Talhão',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: widget.onNomeChanged,
                    ),
                    const SizedBox(height: 16),
                    // Dropdown de culturas
                    DropdownButtonFormField<String>(
                      value: _culturaIdSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Cultura',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.culturaOpcoes.map((cultura) {
                        return DropdownMenuItem<String>(
                          value: cultura.id.toString(),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: cultura.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(cultura.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _culturaIdSelecionada = value;
                        });
                        if (value != null) {
                          widget.onCulturaChanged(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
