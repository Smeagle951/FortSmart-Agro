import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de campo de texto personalizado para o FortSmart Agro
class FortsSmartTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool showCursor;

  const FortsSmartTextField({
    Key? key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.autofocus = false,
    this.showCursor = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final defaultFillColor = isDarkMode 
        ? Colors.grey[800] 
        : Colors.grey[100];
    
    final defaultBorderColor = isDarkMode
        ? Colors.grey[700]
        : Colors.grey[300];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor ?? theme.primaryColor,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          focusNode: focusNode,
          textAlign: textAlign,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: onSubmitted,
          autofocus: autofocus,
          showCursor: showCursor && enabled,
          style: TextStyle(
            color: enabled 
                ? (textColor ?? theme.textTheme.bodyLarge?.color) 
                : Colors.grey[600],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled 
                ? (fillColor ?? defaultFillColor) 
                : Colors.grey[200],
            hintText: hintText,
            hintStyle: TextStyle(
              color: hintColor ?? Colors.grey[500],
            ),
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: borderColor ?? defaultBorderColor!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: borderColor ?? defaultBorderColor!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: Colors.grey[400]!,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget de campo de texto para valores numéricos
class FortsSmartNumberField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool readOnly;
  final bool enabled;
  final ValueChanged<double?>? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final String? prefixText;
  final int? decimalPlaces;
  final double? min;
  final double? max;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  const FortsSmartNumberField({
    Key? key,
    required this.label,
    this.hintText,
    this.controller,
    this.readOnly = false,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.prefixText,
    this.decimalPlaces = 2,
    this.min,
    this.max,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cria formatadores para garantir apenas entrada numérica com decimais
    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      if (decimalPlaces != null)
        TextInputFormatter.withFunction((oldValue, newValue) {
          final regExp = RegExp(r'^\d*\.?\d{0,' + decimalPlaces.toString() + r'}');
          if (regExp.hasMatch(newValue.text)) {
            return newValue;
          }
          return oldValue;
        }),
      if (min != null || max != null)
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) {
            return newValue;
          }
          
          double? value = double.tryParse(newValue.text);
          if (value == null) {
            return oldValue;
          }
          
          if (min != null && value < min!) {
            return oldValue;
          }
          
          if (max != null && value > max!) {
            return oldValue;
          }
          
          return newValue;
        }),
    ];

    return FortsSmartTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      readOnly: readOnly,
      enabled: enabled,
      onChanged: (value) {
        if (onChanged != null) {
          final doubleValue = double.tryParse(value);
          onChanged!(doubleValue);
        }
      },
      onTap: onTap,
      validator: validator,
      inputFormatters: formatters,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.end,
    );
  }
}
