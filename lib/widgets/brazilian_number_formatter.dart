import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formata números no padrão brasileiro
class BrazilianNumberFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  /// Formata um número para o padrão brasileiro
  static String format(double value) {
    return _formatter.format(value).trim();
  }

  /// Formata um número para o padrão brasileiro com casas decimais específicas
  static String formatWithDecimals(double value, int decimalPlaces) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    return formatter.format(value).trim();
  }

  /// Converte uma string formatada brasileira para double
  static double? parse(String value) {
    if (value.isEmpty) return null;
    
    // Remove espaços e substitui vírgula por ponto
    final cleanValue = value.replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    
    return double.tryParse(cleanValue);
  }
}

/// TextInputFormatter para números brasileiros
class BrazilianNumberInputFormatter extends TextInputFormatter {
  final int? decimalPlaces;
  final bool allowNegative;

  BrazilianNumberInputFormatter({
    this.decimalPlaces,
    this.allowNegative = false,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se está vazio, permite
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove tudo exceto números, vírgula, ponto e sinal negativo
    String filtered = newValue.text.replaceAll(RegExp(r'[^\d,.-]'), '');
    
    // Se não permite negativos, remove o sinal
    if (!allowNegative) {
      filtered = filtered.replaceAll('-', '');
    }

    // Garante que só há uma vírgula
    final commaCount = ','.allMatches(filtered).length;
    if (commaCount > 1) {
      final lastCommaIndex = filtered.lastIndexOf(',');
      filtered = filtered.substring(0, lastCommaIndex) + 
                 filtered.substring(lastCommaIndex + 1).replaceAll(',', '');
    }

    // Garante que só há um ponto (para milhares)
    final dotCount = '.'.allMatches(filtered).length;
    if (dotCount > 1) {
      final lastDotIndex = filtered.lastIndexOf('.');
      filtered = filtered.substring(0, lastDotIndex) + 
                 filtered.substring(lastDotIndex + 1).replaceAll('.', '');
    }

    // Se há vírgula, limita as casas decimais
    if (filtered.contains(',') && decimalPlaces != null) {
      final parts = filtered.split(',');
      if (parts.length > 1 && parts[1].length > decimalPlaces!) {
        filtered = parts[0] + ',' + parts[1].substring(0, decimalPlaces!);
      }
    }

    // Formata com pontos para milhares
    if (filtered.isNotEmpty && !filtered.startsWith('-')) {
      final parts = filtered.split(',');
      final integerPart = parts[0];
      
      // Adiciona pontos para milhares
      String formattedInteger = '';
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
          formattedInteger += '.';
        }
        formattedInteger += integerPart[i];
      }
      
      filtered = formattedInteger + (parts.length > 1 ? ',' + parts[1] : '');
    }

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// Campo de texto para números brasileiros
class BrazilianNumberField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final int? decimalPlaces;
  final bool allowNegative;
  final ValueChanged<double?>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const BrazilianNumberField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.decimalPlaces,
    this.allowNegative = false,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
  }) : super(key: key);

  @override
  State<BrazilianNumberField> createState() => _BrazilianNumberFieldState();
}

class _BrazilianNumberFieldState extends State<BrazilianNumberField> {
  late TextEditingController _controller;
  bool _isInternalChange = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    if (_isInternalChange) return;

    final numericValue = BrazilianNumberFormatter.parse(value);
    widget.onChanged?.call(numericValue);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        border: const OutlineInputBorder(),
        enabled: widget.enabled,
      ),
      keyboardType: widget.keyboardType ?? TextInputType.number,
      inputFormatters: [
        BrazilianNumberInputFormatter(
          decimalPlaces: widget.decimalPlaces,
          allowNegative: widget.allowNegative,
        ),
      ],
      onChanged: _onChanged,
      validator: widget.validator,
    );
  }
} 