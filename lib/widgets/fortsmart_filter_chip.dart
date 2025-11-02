import 'package:flutter/material.dart';

/// Chip de filtro personalizado do FortSmart Agro
class FortSmartFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const FortSmartFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.selectedColor,
    this.unselectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? Colors.green.withOpacity(0.2),
      checkmarkColor: selectedColor ?? Colors.green,
      labelStyle: TextStyle(
        color: selected 
            ? (selectedColor ?? Colors.green)
            : (unselectedColor ?? Colors.grey[600]),
        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected 
            ? (selectedColor ?? Colors.green)
            : Colors.grey[300]!,
        width: selected ? 2 : 1,
      ),
      backgroundColor: Colors.white,
    );
  }
}
