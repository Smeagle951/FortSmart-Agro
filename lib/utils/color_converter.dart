import 'package:flutter/material.dart';

/// Classe utilitária para padronizar a conversão entre Color e String hexadecimal
/// em todo o projeto FortSmart Agro.
class ColorConverter {
  /// Converte uma cor (Color) para uma string hexadecimal (#RRGGBB)
  /// 
  /// Exemplo: colorToHex(Colors.red) retorna "#FF0000"
  static String colorToHex(Color color) {
    // Extrair apenas os componentes RGB (ignorando o alpha)
    final hex = '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return hex;
  }

  /// Converte uma string hexadecimal (#RRGGBB ou RRGGBB) para um objeto Color
  /// 
  /// Exemplo: hexToColor("#FF0000") retorna Color(0xFFFF0000)
  static Color hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('0xFF$hexCode'));
    } else if (hexCode.length == 8) {
      return Color(int.parse('0x$hexCode'));
    } else if (hexCode.length == 3) {
      // Formato abreviado #RGB para #RRGGBB
      final r = hexCode.substring(0, 1);
      final g = hexCode.substring(1, 2);
      final b = hexCode.substring(2, 3);
      return Color(int.parse('0xFF$r$r$g$g$b$b'));
    }
    // Cor padrão se o formato for inválido
    return Colors.green;
  }

  /// Converte uma string hexadecimal ou um objeto Color para uma string hexadecimal
  /// 
  /// Esta função é útil quando não se sabe o tipo do parâmetro de entrada
  static String ensureHexString(dynamic colorValue) {
    if (colorValue is Color) {
      return colorToHex(colorValue);
    } else if (colorValue is String) {
      if (colorValue.startsWith('#')) {
        return colorValue;
      } else {
        try {
          // Tentar converter para um valor inteiro e depois para hex
          final color = Color(int.parse(colorValue));
          return colorToHex(color);
        } catch (e) {
          return '#4CAF50'; // Verde padrão se a conversão falhar
        }
      }
    } else if (colorValue is int) {
      return colorToHex(Color(colorValue));
    }
    return '#4CAF50'; // Verde padrão para outros tipos
  }

  /// Converte uma string hexadecimal ou um objeto Color para um objeto Color
  /// 
  /// Esta função é útil quando não se sabe o tipo do parâmetro de entrada
  static Color ensureColor(dynamic colorValue) {
    if (colorValue is Color) {
      return colorValue;
    } else if (colorValue is String) {
      return hexToColor(colorValue);
    } else if (colorValue is int) {
      return Color(colorValue);
    }
    return Colors.green; // Verde padrão para outros tipos
  }
}
