import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget personalizado para entrada de números no FortSmart Agro
/// Permite configurar casas decimais, valores mínimos e máximos, etc.
class FortSmartNumberField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final bool required;
  final int? decimalPlaces;
  final double? minValue;
  final double? maxValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? suffixText;
  final EdgeInsetsGeometry? contentPadding;

  const FortSmartNumberField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.required = false,
    this.decimalPlaces = 2,
    this.minValue,
    this.maxValue,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.suffixText,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: decimalPlaces != 0),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,10}')),
      ],
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        suffixText: suffixText,
        suffix: suffix,
        contentPadding: contentPadding,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Este campo é obrigatório';
        }
        
        if (value != null && value.isNotEmpty) {
          final numValue = double.tryParse(value.replaceAll(',', '.'));
          
          if (numValue == null) {
            return 'Valor inválido';
          }
          
          if (minValue != null && numValue < minValue!) {
            return 'Valor mínimo: $minValue';
          }
          
          if (maxValue != null && numValue > maxValue!) {
            return 'Valor máximo: $maxValue';
          }
        }
        
        if (validator != null) {
          return validator!(value);
        }
        
        return null;
      },
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
