import 'dart:math';
import '../constants/ai_constants.dart';
import '../models/ai_organism_data.dart';
import '../models/ai_diagnosis_result.dart';

/// Extensões úteis para o Sistema IA FortSmart
extension AIStringExtensions on String {
  
  /// Remove acentos da string
  String get withoutAccents {
    return this
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
  
  /// Capitaliza a primeira letra
  String get capitalized {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
  
  /// Capitaliza cada palavra
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalized).join(' ');
  }
  
  /// Verifica se a string é numérica
  bool get isNumeric {
    return double.tryParse(this) != null;
  }
  
  /// Verifica se a string é um email válido
  bool get isEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }
  
  /// Verifica se a string é uma URL válida
  bool get isUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  /// Limita o comprimento da string
  String limitLength(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength - suffix.length) + suffix;
  }
  
  /// Remove caracteres especiais
  String get withoutSpecialChars {
    return replaceAll(RegExp(r'[^\w\s]'), '');
  }
  
  /// Converte para slug (URL amigável)
  String get toSlug {
    return toLowerCase()
        .withoutAccents
        .withoutSpecialChars
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
  
  /// Verifica se contém apenas letras
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(this);
  }
  
  /// Verifica se contém apenas letras e números
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(this);
  }
  
  /// Converte para formato de arquivo
  String get toFileName {
    return withoutSpecialChars
        .replaceAll(' ', '_')
        .toLowerCase();
  }
}

extension AIDoubleExtensions on double {
  
  /// Formata para porcentagem
  String get toPercentage {
    return '${(this * 100).toStringAsFixed(1)}%';
  }
  
  /// Formata para decimal com 2 casas
  String get toDecimal {
    return toStringAsFixed(2);
  }
  
  /// Formata para decimal com casas específicas
  String toDecimalPlaces(int places) {
    return toStringAsFixed(places);
  }
  
  /// Verifica se está dentro do intervalo
  bool isInRange(double min, double max) {
    return this >= min && this <= max;
  }
  
  /// Limita o valor a um intervalo
  double clampToRange(double min, double max) {
    return this < min ? min : (this > max ? max : this);
  }
  
  /// Converte para graus Celsius
  double get toCelsius {
    return (this - 32) * 5 / 9;
  }
  
  /// Converte para Fahrenheit
  double get toFahrenheit {
    return this * 9 / 5 + 32;
  }
  
  /// Arredonda para o inteiro mais próximo
  int get rounded {
    return round();
  }
  
  /// Arredonda para cima
  int get ceiling {
    return ceil();
  }
  
  /// Arredonda para baixo
  int get floor {
    return this.floor();
  }
}

extension AIIntExtensions on int {
  
  /// Formata para tamanho de arquivo
  String get toFileSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Verifica se é par
  bool get isEven {
    return this % 2 == 0;
  }
  
  /// Verifica se é ímpar
  bool get isOdd {
    return this % 2 != 0;
  }
  
  /// Verifica se é positivo
  bool get isPositive {
    return this > 0;
  }
  
  /// Verifica se é negativo
  bool get isNegative {
    return this < 0;
  }
  
  /// Verifica se é zero
  bool get isZero {
    return this == 0;
  }
  
  /// Limita o valor a um intervalo
  int clampToRange(int min, int max) {
    return this < min ? min : (this > max ? max : this);
  }
  
  /// Converte para duração formatada
  String get toDuration {
    if (this < 60) return '${this}s';
    if (this < 3600) return '${(this / 60).floor()}m ${this % 60}s';
    final hours = (this / 3600).floor();
    final minutes = ((this % 3600) / 60).floor();
    return '${hours}h ${minutes}m';
  }
  
  /// Converte para formato de tempo
  String get toTimeFormat {
    final hours = (this / 3600).floor();
    final minutes = ((this % 3600) / 60).floor();
    final seconds = this % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension AIDateTimeExtensions on DateTime {
  
  /// Formata para data brasileira
  String get toBrazilianDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
  
  /// Formata para data e hora brasileira
  String get toBrazilianDateTime {
    return '${toBrazilianDate} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  /// Formata para data ISO
  String get toIsoDate {
    return toIso8601String().split('T')[0];
  }
  
  /// Verifica se é hoje
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Verifica se é ontem
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  /// Verifica se é amanhã
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
  
  /// Verifica se é no passado
  bool get isPast {
    return isBefore(DateTime.now());
  }
  
  /// Verifica se é no futuro
  bool get isFuture {
    return isAfter(DateTime.now());
  }
  
  /// Obtém a idade em anos
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }
  
  /// Obtém o nome do mês
  String get monthName {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }
  
  /// Obtém o nome do dia da semana
  String get dayName {
    const days = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
      'Sexta-feira', 'Sábado', 'Domingo'
    ];
    return days[weekday - 1];
  }
  
  /// Obtém o início do dia
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }
  
  /// Obtém o fim do dia
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
  
  /// Obtém o início da semana
  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday));
  }
  
  /// Obtém o fim da semana
  DateTime get endOfWeek {
    final daysUntilSunday = 7 - weekday;
    return add(Duration(days: daysUntilSunday));
  }
}

extension AIListExtensions<T> on List<T> {
  
  /// Obtém elementos únicos
  List<T> get unique {
    return toSet().toList();
  }
  
  /// Obtém elementos duplicados
  List<T> get duplicates {
    final seen = <T>{};
    final duplicates = <T>{};
    for (final item in this) {
      if (seen.contains(item)) {
        duplicates.add(item);
      } else {
        seen.add(item);
      }
    }
    return duplicates.toList();
  }
  
  /// Obtém elementos não duplicados
  List<T> get nonDuplicates {
    final seen = <T>{};
    final nonDuplicates = <T>[];
    for (final item in this) {
      if (!seen.contains(item)) {
        seen.add(item);
        nonDuplicates.add(item);
      }
    }
    return nonDuplicates;
  }
  
  /// Obtém o primeiro elemento ou null
  T? get firstOrNull {
    return isEmpty ? null : first;
  }
  
  /// Obtém o último elemento ou null
  T? get lastOrNull {
    return isEmpty ? null : last;
  }
  
  /// Obtém elementos aleatórios
  List<T> randomElements(int count) {
    if (count >= length) return List.from(this);
    final shuffled = List<T>.from(this)..shuffle();
    return shuffled.take(count).toList();
  }
  
  /// Obtém um elemento aleatório
  T? get randomElement {
    if (isEmpty) return null;
    return this[Random().nextInt(length)];
  }
  
  /// Divide a lista em chunks
  List<List<T>> chunk(int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += chunkSize) {
      chunks.add(sublist(i, (i + chunkSize < length) ? i + chunkSize : length));
    }
    return chunks;
  }
  
  /// Filtra elementos não nulos
  List<T> get nonNull {
    return where((item) => item != null).toList();
  }
  
  /// Obtém elementos até um índice específico
  List<T> takeUntil(int index) {
    if (index >= length) return List.from(this);
    return sublist(0, index);
  }
  
  /// Obtém elementos a partir de um índice específico
  List<T> takeFrom(int index) {
    if (index >= length) return [];
    return sublist(index);
  }
}

extension AIOrganismDataExtensions on AIOrganismData {
  
  /// Obtém a severidade como texto
  String get severityText {
    if (severity >= AIConstants.highSeverityThreshold) return 'Alta';
    if (severity >= AIConstants.mediumSeverityThreshold) return 'Média';
    return 'Baixa';
  }
  
  /// Obtém a cor da severidade
  String get severityColor {
    if (severity >= AIConstants.highSeverityThreshold) return '#FF4444';
    if (severity >= AIConstants.mediumSeverityThreshold) return '#FFAA00';
    return '#44FF44';
  }
  
  /// Obtém o tipo em português
  String get typeInPortuguese {
    switch (type.toLowerCase()) {
      case 'pest':
        return 'Praga';
      case 'disease':
        return 'Doença';
      default:
        return type.capitalized;
    }
  }
  
  /// Obtém as culturas como texto
  String get cropsText {
    return crops.join(', ');
  }
  
  /// Obtém os sintomas como texto
  String get symptomsText {
    return symptoms.join(', ');
  }
  
  /// Obtém as estratégias como texto
  String get strategiesText {
    return managementStrategies.join(', ');
  }
  
  /// Obtém as palavras-chave como texto
  String get keywordsText {
    return keywords.join(', ');
  }
  
  /// Verifica se é uma praga
  bool get isPest {
    return type.toLowerCase() == 'pest';
  }
  
  /// Verifica se é uma doença
  bool get isDisease {
    return type.toLowerCase() == 'disease';
  }
  
  /// Obtém a idade em dias
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }
  
  /// Verifica se foi atualizado recentemente
  bool get isRecentlyUpdated {
    return DateTime.now().difference(updatedAt).inDays < 7;
  }
}

extension AIDiagnosisResultExtensions on AIDiagnosisResult {
  
  /// Obtém a confiança como texto
  String get confidenceText {
    if (confidence >= AIConstants.highConfidenceThreshold) return 'Alta';
    if (confidence >= AIConstants.minConfidenceThreshold) return 'Média';
    return 'Baixa';
  }
  
  /// Obtém a cor da confiança
  String get confidenceColor {
    if (confidence >= AIConstants.highConfidenceThreshold) return '#44FF44';
    if (confidence >= AIConstants.minConfidenceThreshold) return '#FFAA00';
    return '#FF4444';
  }
  
  /// Obtém os sintomas correspondentes como texto
  String get matchedSymptomsText {
    return matchedSymptoms.join(', ');
  }
  
  /// Obtém as recomendações como texto
  String get recommendationsText {
    return recommendations.join(', ');
  }
  
  /// Verifica se a confiança é alta
  bool get isHighConfidence {
    return confidence >= AIConstants.highConfidenceThreshold;
  }
  
  /// Verifica se a confiança é aceitável
  bool get isAcceptableConfidence {
    return confidence >= AIConstants.minConfidenceThreshold;
  }
  
  /// Obtém a idade em minutos
  int get ageInMinutes {
    return DateTime.now().difference(timestamp).inMinutes;
  }
  
  /// Verifica se é recente
  bool get isRecent {
    return ageInMinutes < 60;
  }
}
