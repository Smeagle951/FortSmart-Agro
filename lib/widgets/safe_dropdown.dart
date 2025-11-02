import 'package:flutter/material.dart';

/// Widget seguro para DropdownButton que evita erros de assertion
class SafeDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final String? labelText;
  final InputDecoration? decoration;
  final bool isExpanded;
  final bool isDense;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final double iconSize;
  final bool autofocus;
  final bool enableFeedback;

  const SafeDropdownButton({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.labelText,
    this.decoration,
    this.isExpanded = false,
    this.isDense = false,
    this.padding,
    this.icon,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.iconSize = 24.0,
    this.autofocus = false,
    this.enableFeedback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validar se o valor existe na lista de itens
    final safeValue = _validateValue(value, items);
    
    return DropdownButton<T>(
      value: safeValue,
      items: items,
      onChanged: onChanged,
      hint: hint,
      isExpanded: isExpanded,
      isDense: isDense,
      padding: padding,
      icon: icon,
      iconEnabledColor: iconEnabledColor,
      iconDisabledColor: iconDisabledColor,
      iconSize: iconSize,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
    );
  }

  /// Valida se o valor existe na lista de itens
  T? _validateValue(T? value, List<DropdownMenuItem<T>> items) {
    if (value == null) return null;
    
    // Verificar se existe um item com o valor especificado
    final hasValidValue = items.any((item) => item.value == value);
    
    if (!hasValidValue) {
      print('⚠️ SafeDropdownButton: Valor "$value" não encontrado na lista. Usando null.');
      return null;
    }
    
    return value;
  }
}

/// Widget seguro para DropdownButtonFormField que evita erros de assertion
class SafeDropdownButtonFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final InputDecoration? decoration;
  final bool isExpanded;
  final bool isDense;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final double iconSize;
  final bool autofocus;
  final bool enableFeedback;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final bool enabled;
  final double? dropdownElevation;
  final double? menuMaxHeight;

  const SafeDropdownButtonFormField({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.decoration,
    this.isExpanded = false,
    this.isDense = false,
    this.padding,
    this.icon,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.iconSize = 24.0,
    this.autofocus = false,
    this.enableFeedback = true,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.dropdownElevation,
    this.menuMaxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validar se o valor existe na lista de itens
    final safeValue = _validateValue(value, items);
    
    return DropdownButtonFormField<T>(
      value: safeValue,
      items: items,
      onChanged: enabled ? onChanged : null,
      hint: hint,
      decoration: decoration,
      isExpanded: isExpanded,
      isDense: isDense,
      padding: padding,
      icon: icon,
      iconEnabledColor: iconEnabledColor,
      iconDisabledColor: iconDisabledColor,
      iconSize: iconSize,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
      validator: validator,
      onSaved: onSaved,
      menuMaxHeight: menuMaxHeight,
    );
  }

  /// Valida se o valor existe na lista de itens
  T? _validateValue(T? value, List<DropdownMenuItem<T>> items) {
    if (value == null) return null;
    
    // Verificar se existe um item com o valor especificado
    final hasValidValue = items.any((item) => item.value == value);
    
    if (!hasValidValue) {
      print('⚠️ SafeDropdownButtonFormField: Valor "$value" não encontrado na lista. Usando null.');
      return null;
    }
    
    return value;
  }
}

/// Utilitário para criar DropdownMenuItem com validação
class DropdownItemBuilder {
  /// Cria um DropdownMenuItem com validação
  static DropdownMenuItem<T> create<T>({
    required T value,
    required Widget child,
    bool enabled = true,
  }) {
    return DropdownMenuItem<T>(
      value: value,
      child: child,
      enabled: enabled,
    );
  }

  /// Cria uma lista de DropdownMenuItem a partir de uma lista de valores
  static List<DropdownMenuItem<T>> fromList<T>({
    required List<T> values,
    required Widget Function(T) builder,
    bool Function(T)? enabled,
  }) {
    return values.map((value) {
      return DropdownMenuItem<T>(
        value: value,
        child: builder(value),
        enabled: enabled?.call(value) ?? true,
      );
    }).toList();
  }

  /// Cria uma lista de DropdownMenuItem a partir de um mapa
  static List<DropdownMenuItem<T>> fromMap<T>({
    required Map<T, String> map,
    bool Function(T)? enabled,
  }) {
    return map.entries.map((entry) {
      return DropdownMenuItem<T>(
        value: entry.key,
        child: Text(entry.value),
        enabled: enabled?.call(entry.key) ?? true,
      );
    }).toList();
  }
}
