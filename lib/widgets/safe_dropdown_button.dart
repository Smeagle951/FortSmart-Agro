import 'package:flutter/material.dart';

/// Widget utilitário para DropdownButtons seguros que previne erros de assertion
/// quando o valor selecionado não existe na lista de items
class SafeDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final bool isExpanded;
  final InputDecoration? decoration;
  final String? Function(T?)? validator;
  final DropdownButtonBuilder? selectedItemBuilder;
  final Widget? underline;
  final Widget? icon;
  final double? iconSize;
  final bool isDense;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? dropdownColor;
  final double? itemHeight;
  final double? elevation;
  final TextStyle? style;
  final Widget? disabledHint;
  final int? menuMaxHeight;
  final bool enableFeedback;

  const SafeDropdownButton({
    Key? key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.isExpanded = false,
    this.decoration,
    this.validator,
    this.selectedItemBuilder,
    this.underline,
    this.icon,
    this.iconSize,
    this.isDense = false,
    this.autofocus = false,
    this.focusNode,
    this.dropdownColor,
    this.itemHeight,
    this.elevation,
    this.style,
    this.disabledHint,
    this.menuMaxHeight,
    this.enableFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validar se o valor existe na lista de items
    final validValue = _validateValue(value, items);
    
    return DropdownButtonFormField<T>(
      value: validValue,
      items: items,
      onChanged: onChanged,
      hint: hint,
      isExpanded: isExpanded,
      decoration: decoration,
      validator: validator,
      selectedItemBuilder: selectedItemBuilder,
      underline: underline,
      icon: icon,
      iconSize: iconSize,
      isDense: isDense,
      autofocus: autofocus,
      focusNode: focusNode,
      dropdownColor: dropdownColor,
      itemHeight: itemHeight,
      elevation: elevation,
      style: style,
      disabledHint: disabledHint,
      menuMaxHeight: menuMaxHeight,
      enableFeedback: enableFeedback,
    );
  }

  /// Valida se o valor existe na lista de items
  T? _validateValue(T? value, List<DropdownMenuItem<T>> items) {
    if (value == null) return null;
    
    // Verificar se o valor existe na lista de items
    final valueExists = items.any((item) => item.value == value);
    
    if (!valueExists) {
      print('⚠️ SafeDropdownButton: Valor "$value" não existe na lista de items. Usando null.');
      return null;
    }
    
    return value;
  }
}

/// Widget utilitário para DropdownButtonFormField seguro
class SafeDropdownButtonFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final bool isExpanded;
  final InputDecoration? decoration;
  final String? Function(T?)? validator;
  final DropdownButtonBuilder? selectedItemBuilder;
  final Widget? underline;
  final Widget? icon;
  final double? iconSize;
  final bool isDense;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? dropdownColor;
  final double? itemHeight;
  final double? elevation;
  final TextStyle? style;
  final Widget? disabledHint;
  final int? menuMaxHeight;
  final bool enableFeedback;

  const SafeDropdownButtonFormField({
    Key? key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.isExpanded = false,
    this.decoration,
    this.validator,
    this.selectedItemBuilder,
    this.underline,
    this.icon,
    this.iconSize,
    this.isDense = false,
    this.autofocus = false,
    this.focusNode,
    this.dropdownColor,
    this.itemHeight,
    this.elevation,
    this.style,
    this.disabledHint,
    this.menuMaxHeight,
    this.enableFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validar se o valor existe na lista de items
    final validValue = _validateValue(value, items);
    
    return DropdownButtonFormField<T>(
      value: validValue,
      items: items,
      onChanged: onChanged,
      hint: hint,
      isExpanded: isExpanded,
      decoration: decoration,
      validator: validator,
      selectedItemBuilder: selectedItemBuilder,
      underline: underline,
      icon: icon,
      iconSize: iconSize,
      isDense: isDense,
      autofocus: autofocus,
      focusNode: focusNode,
      dropdownColor: dropdownColor,
      itemHeight: itemHeight,
      elevation: elevation,
      style: style,
      disabledHint: disabledHint,
      menuMaxHeight: menuMaxHeight,
      enableFeedback: enableFeedback,
    );
  }

  /// Valida se o valor existe na lista de items
  T? _validateValue(T? value, List<DropdownMenuItem<T>> items) {
    if (value == null) return null;
    
    // Verificar se o valor existe na lista de items
    final valueExists = items.any((item) => item.value == value);
    
    if (!valueExists) {
      print('⚠️ SafeDropdownButtonFormField: Valor "$value" não existe na lista de items. Usando null.');
      return null;
    }
    
    return value;
  }
}

/// Extensão para facilitar a criação de DropdownMenuItems seguros
extension SafeDropdownItems<T> on List<T> {
  /// Cria uma lista de DropdownMenuItems segura
  List<DropdownMenuItem<T>> toDropdownItems({
    required String Function(T) displayText,
    String Function(T)? valueText,
  }) {
    return map((item) {
      return DropdownMenuItem<T>(
        value: item,
        child: Text(displayText(item)),
      );
    }).toList();
  }
  
  /// Cria uma lista de DropdownMenuItems com validação de valores únicos
  List<DropdownMenuItem<T>> toUniqueDropdownItems({
    required String Function(T) displayText,
    required T Function(T) valueExtractor,
  }) {
    final seen = <T>{};
    final uniqueItems = <T>[];
    
    for (final item in this) {
      final value = valueExtractor(item);
      if (!seen.contains(value)) {
        seen.add(value);
        uniqueItems.add(item);
      }
    }
    
    return uniqueItems.map((item) {
      return DropdownMenuItem<T>(
        value: item,
        child: Text(displayText(item)),
      );
    }).toList();
  }
}
