import 'package:intl/intl.dart';

/// Formata um valor monetário para exibição
String formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

/// Formata uma data ISO 8601 para exibição no formato brasileiro
String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    return isoDate;
  }
}

/// Formata uma data e hora para exibição no formato brasileiro
String formatDateTime(dynamic dateInput) {
  try {
    if (dateInput is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateInput);
    } else if (dateInput is String) {
      final date = DateTime.parse(dateInput);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } else {
      return 'Data inválida';
    }
  } catch (e) {
    return dateInput is String ? dateInput : 'Data inválida';
  }
}

/// Converte uma string de data no formato brasileiro para ISO 8601
String dateToIso8601(String brDate) {
  try {
    final parts = brDate.split('/');
    if (parts.length != 3) return '';
    
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    
    return DateTime(year, month, day).toIso8601String().split('T')[0];
  } catch (e) {
    return '';
  }
}

/// Formata um número com precisão decimal para exibição
String formatNumber(double value, {int decimalDigits = 2}) {
  final formatter = NumberFormat.decimalPattern('pt_BR')
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = decimalDigits;
  return formatter.format(value);
}

/// Formata uma área em hectares para exibição
String formatArea(double value) {
  return '${formatNumber(value)} ha';
}

/// Formata uma coordenada GPS para exibição
String formatCoordinate(double latitude, double longitude) {
  final latFormatter = NumberFormat('0.000000°', 'pt_BR');
  final longFormatter = NumberFormat('0.000000°', 'pt_BR');
  
  final latDirection = latitude >= 0 ? 'N' : 'S';
  final longDirection = longitude >= 0 ? 'E' : 'W';
  
  return '${latFormatter.format(latitude.abs())} $latDirection, ${longFormatter.format(longitude.abs())} $longDirection';
}
