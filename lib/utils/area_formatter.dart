import 'package:intl/intl.dart';

/// Utilitário para formatação de áreas no formato brasileiro
class AreaFormatter {
  /// Retorna um NumberFormat com locale pt_BR e precisão configurável
  static NumberFormat _numberFormat(int precision) {
    final pattern = precision <= 0
        ? '#,##0'
        : '#,##0.${List.filled(precision, '0').join()}';
    return NumberFormat(pattern, 'pt_BR');
  }

  /// Formata um número com locale brasileiro e precisão fixa
  static String _fmt(double value, {int precision = 2}) {
    return _numberFormat(precision).format(value);
  }

  /// Formata área em hectares com vírgula como separador decimal (formato brasileiro)
  static String formatHectaresFixed(double areaHa, {int decimalPlaces = 2}) {
    if (areaHa < 0.0001) return '0 ha';
    
    final formatted = areaHa.toStringAsFixed(decimalPlaces);
    return '${formatted.replaceAll('.', ',')} ha';
  }
  
  /// Formata área em hectares com separador brasileiro
  static String formatHectares(double areaHa, {int decimalPlaces = 2}) {
    if (areaHa < 0.0001) return '0 ha';
    
    final formatted = areaHa.toStringAsFixed(decimalPlaces);
    return '${formatted.replaceAll('.', ',')} ha';
  }
  
  /// Formata área em metros quadrados com separador brasileiro
  static String formatSquareMeters(double areaM2, {int decimalPlaces = 1}) {
    if (areaM2 < 0.1) return '0 m²';
    
    final formatted = areaM2.toStringAsFixed(decimalPlaces);
    return '${formatted.replaceAll('.', ',')} m²';
  }
  
  /// Formata área automaticamente escolhendo a unidade mais apropriada
  static String formatArea(double areaHa) {
    if (areaHa < 0.0001) return '0 m²';
    if (areaHa < 1.0) {
      return formatSquareMeters(areaHa * 10000, decimalPlaces: 1);
    } else if (areaHa < 100.0) {
      return formatHectares(areaHa, decimalPlaces: 2);
    } else {
      return formatHectares(areaHa, decimalPlaces: 1);
    }
  }
  
  /// Converte string formatada brasileira para double
  static double parseArea(String areaString) {
    try {
      // Remover unidades e espaços
      final cleanString = areaString
          .replaceAll('ha', '')
          .replaceAll('m²', '')
          .replaceAll(' ', '')
          .trim();
      
      // Substituir vírgula por ponto para parsing
      final normalizedString = cleanString.replaceAll(',', '.');
      
      return double.parse(normalizedString);
    } catch (e) {
      return 0.0;
    }
  }
}
