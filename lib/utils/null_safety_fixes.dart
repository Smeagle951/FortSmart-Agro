import 'package:flutter/material.dart';

/// Utilitários para correção de problemas de null safety
class NullSafetyFixes {
  
  /// Converte valor para double de forma segura
  static double safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
  
  /// Converte valor para int de forma segura
  static int safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
  
  /// Converte valor para String de forma segura
  static String safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
  
  /// Converte valor para bool de forma segura
  static bool safeToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    return false;
  }
  
  /// Converte cor hex para Color de forma segura
  static Color safeToColor(dynamic value) {
    if (value == null) return Colors.grey;
    
    try {
      String colorStr = value.toString().trim();
      
      // Se começa com #
      if (colorStr.startsWith('#')) {
        String hex = colorStr.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        } else if (hex.length == 3) {
          // Expandir cores de 3 dígitos
          hex = hex.split('').map((c) => c + c).join();
          return Color(int.parse('0xFF$hex'));
        }
      }
      // Se começa com 0x
      else if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      }
      // Se é apenas um número
      else if (RegExp(r'^[0-9]+$').hasMatch(colorStr)) {
        return Color(int.parse(colorStr));
      }
    } catch (e) {
      print('Erro ao parsear cor: $value - $e');
    }
    
    return Colors.grey;
  }
  
  /// Converte valor para DateTime de forma segura
  static DateTime? safeToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  /// Obtém valor de mapa de forma segura
  static T? safeGetFromMap<T>(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value is T) return value;
    return null;
  }
  
  /// Obtém valor de mapa com fallback
  static T safeGetFromMapWithFallback<T>(Map<String, dynamic>? map, String key, T fallback) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is T) return value;
    return fallback;
  }
  
  /// Converte lista de forma segura
  static List<T> safeToList<T>(dynamic value) {
    if (value == null) return <T>[];
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (e) {
        return <T>[];
      }
    }
    return <T>[];
  }
  
  /// Converte mapa de forma segura
  static Map<String, dynamic> safeToMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }
  
  /// Verifica se valor é nulo ou vazio
  static bool isNullOrEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }
  
  /// Obtém valor não nulo ou fallback
  static T nonNullValue<T>(T? value, T fallback) {
    return value ?? fallback;
  }
  
  /// Executa função de forma segura
  static T? safeExecute<T>(T Function() function) {
    try {
      return function();
    } catch (e) {
      print('Erro ao executar função: $e');
      return null;
    }
  }
  
  /// Executa função assíncrona de forma segura
  static Future<T?> safeExecuteAsync<T>(Future<T> Function() function) async {
    try {
      return await function();
    } catch (e) {
      print('Erro ao executar função assíncrona: $e');
      return null;
    }
  }
}
