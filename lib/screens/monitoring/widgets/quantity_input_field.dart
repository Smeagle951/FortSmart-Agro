import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para entrada de quantidade numérica de organismos encontrados
class QuantityInputField extends StatefulWidget {
  final int initialValue;
  final Function(int) onChanged;

  const QuantityInputField({
    Key? key,
    this.initialValue = 0,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<QuantityInputField> createState() => _QuantityInputFieldState();
}

class _QuantityInputFieldState extends State<QuantityInputField> {
  final TextEditingController _controller = TextEditingController();
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialValue;
    _controller.text = _quantity.toString();
  }

  void _updateQuantity(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
      _controller.text = _quantity.toString();
    });
    widget.onChanged(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantidade encontrada:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Botão de diminuir
            _buildQuantityButton(
              icon: Icons.remove,
              onPressed: _quantity > 0 ? () => _updateQuantity(_quantity - 1) : null,
            ),
            const SizedBox(width: 12),
            
            // Campo de entrada
            Expanded(
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D9CDB), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  final quantity = int.tryParse(value) ?? 0;
                  if (quantity != _quantity) {
                    _updateQuantity(quantity);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            
            // Botão de aumentar
            _buildQuantityButton(
              icon: Icons.add,
              onPressed: () => _updateQuantity(_quantity + 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Indicador de nível calculado
        if (_quantity > 0) _buildLevelIndicator(),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: onPressed != null 
            ? const Color(0xFF2D9CDB)
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: const Color(0xFF2D9CDB).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Icon(
            icon,
            color: onPressed != null ? Colors.white : const Color(0xFF95A5A6),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIndicator() {
    final level = _calculateLevel(_quantity);
    final levelColor = _getLevelColor(level);
    final levelText = _getLevelText(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Nível: $levelText',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: levelColor,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateLevel(int quantity) {
    // Lógica simplificada para cálculo de nível
    // Em uma implementação real, isso viria do catálogo de organismos
    if (quantity == 0) return 'Nenhum';
    if (quantity <= 2) return 'Baixo';
    if (quantity <= 5) return 'Médio';
    if (quantity <= 10) return 'Alto';
    return 'Crítico';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Nenhum':
        return const Color(0xFF95A5A6);
      case 'Baixo':
        return const Color(0xFF27AE60);
      case 'Médio':
        return const Color(0xFF2D9CDB);
      case 'Alto':
        return const Color(0xFFF2C94C);
      case 'Crítico':
        return const Color(0xFFEB5757);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getLevelText(String level) {
    return level;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
