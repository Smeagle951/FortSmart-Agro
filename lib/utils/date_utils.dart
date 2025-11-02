import 'package:intl/intl.dart';

/// Utilitários para formatação e manipulação de datas
class DateUtils {
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormatter = DateFormat('MM/yyyy');
  static final DateFormat _yearFormatter = DateFormat('yyyy');

  /// Formata uma data para o padrão brasileiro (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Formata uma data e hora para o padrão brasileiro (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Formata apenas mês e ano (MM/yyyy)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  /// Formata apenas o ano (yyyy)
  static String formatYear(DateTime date) {
    return _yearFormatter.format(date);
  }

  /// Formata uma data para exibição relativa (hoje, ontem, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoje';
    } else if (dateOnly == yesterday) {
      return 'Ontem';
    } else if (dateOnly.isAfter(today.subtract(Duration(days: 7)))) {
      final daysDiff = today.difference(dateOnly).inDays;
      return 'Há $daysDiff dias';
    } else {
      return formatDate(date);
    }
  }

  /// Formata uma data para exibição em listas (dia da semana + data)
  static String formatListDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    return '$weekday, ${formatDate(date)}';
  }

  /// Retorna o nome do dia da semana em português
  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terça';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  /// Formata um período (data inicial - data final)
  static String formatPeriod(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year) {
      if (startDate.month == endDate.month) {
        return '${startDate.day} a ${endDate.day} de ${_getMonthName(endDate.month)} de ${endDate.year}';
      } else {
        return '${startDate.day} de ${_getMonthName(startDate.month)} a ${endDate.day} de ${_getMonthName(endDate.month)} de ${endDate.year}';
      }
    } else {
      return '${formatDate(startDate)} a ${formatDate(endDate)}';
    }
  }

  /// Retorna o nome do mês em português
  static String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Janeiro';
      case 2:
        return 'Fevereiro';
      case 3:
        return 'Março';
      case 4:
        return 'Abril';
      case 5:
        return 'Maio';
      case 6:
        return 'Junho';
      case 7:
        return 'Julho';
      case 8:
        return 'Agosto';
      case 9:
        return 'Setembro';
      case 10:
        return 'Outubro';
      case 11:
        return 'Novembro';
      case 12:
        return 'Dezembro';
      default:
        return '';
    }
  }

  /// Verifica se uma data é hoje
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Verifica se uma data é ontem
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Verifica se uma data está na semana atual
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(Duration(days: 1))) && 
           date.isBefore(endOfWeek.add(Duration(days: 1)));
  }

  /// Verifica se uma data está no mês atual
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Retorna o primeiro dia do mês
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Retorna o último dia do mês
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Retorna o primeiro dia da semana
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Retorna o último dia da semana
  static DateTime getLastDayOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  /// Calcula a diferença em dias entre duas datas
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Adiciona dias a uma data
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtrai dias de uma data
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Retorna uma data formatada para uso em APIs (ISO 8601)
  static String toIso8601String(DateTime date) {
    return date.toIso8601String();
  }

  /// Converte uma string ISO 8601 para DateTime
  static DateTime fromIso8601String(String dateString) {
    return DateTime.parse(dateString);
  }

  /// Formata uma data para exibição em cards (dia/mês)
  static String formatCardDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  /// Formata uma data para exibição em headers (mês/ano)
  static String formatHeaderDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  /// Formata uma data para exibição em tooltips
  static String formatTooltipDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    final month = _getMonthName(date.month);
    return '$weekday, ${date.day} de $month de ${date.year}';
  }
}
