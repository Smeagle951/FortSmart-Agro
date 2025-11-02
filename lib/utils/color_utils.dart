import 'package:flutter/material.dart';
import 'dart:math';

/// Utilitário para manipulação de cores
class ColorUtils {
  /// Converte uma string hexadecimal para Color
  static Color hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('0xFF$hexCode'));
    } else if (hexCode.length == 3) {
      // Converte formato abreviado (ex: #F00) para formato completo (ex: #FF0000)
      final r = hexCode.substring(0, 1);
      final g = hexCode.substring(1, 2);
      final b = hexCode.substring(2, 3);
      return Color(int.parse('0xFF$r$r$g$g$b$b'));
    }
    // Cor padrão se o formato for inválido
    return Colors.grey;
  }

  /// Converte Color para String hexadecimal (#AARRGGBB)
  static String colorToHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// Gera uma cor baseada em uma string (usando hash)
  static Color stringToColor(String input) {
    final int hash = input.hashCode & 0xFFFFFF;
    final String hexColor = hash.toRadixString(16).padLeft(6, '0');
    return hexToColor(hexColor);
  }

  /// Gera uma lista de cores distintas para uso em gráficos ou mapas
  static List<Color> generateDistinctColors(int count) {
    List<Color> colors = [];
    final Random random = Random(42); // Seed fixo para consistência
    
    for (int i = 0; i < count; i++) {
      // Gera cores HSV com saturação e brilho fixos para melhor distinção
      final double hue = (i * (360 / count)) % 360;
      final Color color = HSVColor.fromAHSV(1.0, hue, 0.8, 0.9).toColor();
      colors.add(color);
    }
    
    return colors;
  }

  /// Determina se uma cor é escura
  static bool isDarkColor(Color color) {
    // Fórmula YIQ para determinar se uma cor é escura
    final double y = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return y < 0.5;
  }

  /// Retorna uma cor de texto apropriada (branco ou preto) com base na cor de fundo
  static Color getTextColorForBackground(Color backgroundColor) {
    return isDarkColor(backgroundColor) ? Colors.white : Colors.black;
  }

  /// Ajusta o brilho de uma cor
  static Color adjustBrightness(Color color, double factor) {
    assert(factor >= -1.0 && factor <= 1.0);
    
    int r = color.red;
    int g = color.green;
    int b = color.blue;
    
    if (factor < 0) {
      // Escurecer
      r = (r * (1 + factor)).round();
      g = (g * (1 + factor)).round();
      b = (b * (1 + factor)).round();
    } else {
      // Clarear
      r = (r + ((255 - r) * factor)).round();
      g = (g + ((255 - g) * factor)).round();
      b = (b + ((255 - b) * factor)).round();
    }
    
    return Color.fromARGB(color.alpha, r, g, b);
  }
}
