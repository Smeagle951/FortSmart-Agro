import 'package:flutter/material.dart';

/// Widget para seleção de tipo de ocorrência com botões coloridos
class OccurrenceTypeSelector extends StatelessWidget {
  final String? selectedType;
  final Function(String) onTypeSelected;
  final List<String> types;

  const OccurrenceTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
    this.types = const ['Praga', 'Doença', 'Daninha', 'Outro'],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione o Tipo:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        // Primeira linha
        Row(
          children: [
            if (types.length > 0)
              Expanded(
                child: _buildTypeButton(
                  types[0],
                  _getTypeIcon(types[0]),
                  _getTypeBackgroundColor(types[0]),
                  selectedType == types[0],
                ),
              ),
            if (types.length > 1) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeButton(
                  types[1],
                  _getTypeIcon(types[1]),
                  _getTypeBackgroundColor(types[1]),
                  selectedType == types[1],
                ),
              ),
            ],
          ],
        ),
        if (types.length > 2) ...[
          const SizedBox(height: 8),
          // Segunda linha
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  types[2],
                  _getTypeIcon(types[2]),
                  _getTypeBackgroundColor(types[2]),
                  selectedType == types[2],
                ),
              ),
              if (types.length > 3) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeButton(
                    types[3],
                    _getTypeIcon(types[3]),
                    _getTypeBackgroundColor(types[3]),
                    selectedType == types[3],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
  
  String _getTypeIcon(String type) {
    switch (type) {
      case 'Praga':
        return '🐛';
      case 'Doença':
        return '🦠';
      case 'Daninha':
        return '🌿';
      case 'Outro':
        return '📋';
      default:
        return '📋';
    }
  }
  
  Color _getTypeBackgroundColor(String type) {
    switch (type) {
      case 'Praga':
        return const Color(0xFFDFF5E1); // Verde claro suave
      case 'Doença':
        return const Color(0xFFFFF6D1); // Amarelo pastel
      case 'Daninha':
        return const Color(0xFFE1F0FF); // Azul claro
      case 'Outro':
        return const Color(0xFFF2E5FF); // Lilás suave
      default:
        return Colors.grey[100]!;
    }
  }

  Widget _buildTypeButton(
    String type,
    String icon,
    Color backgroundColor,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? backgroundColor.withOpacity(0.8)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF95A5A6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
