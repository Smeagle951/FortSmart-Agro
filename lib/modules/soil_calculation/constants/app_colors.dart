import 'package:flutter/material.dart';

class AppColors {
  // Cores principais do módulo de solo
  static const Color primaryColor = Color(0xFF2E7D32); // Verde escuro
  static const Color secondaryColor = Color(0xFF4CAF50); // Verde médio
  static const Color accentColor = Color(0xFF8BC34A); // Verde claro
  
  // Cores para interpretação de compactação
  static const Color noCompaction = Color(0xFF4CAF50); // Verde
  static const Color lightCompaction = Color(0xFFFFEB3B); // Amarelo
  static const Color moderateCompaction = Color(0xFFFF9800); // Laranja
  static const Color highCompaction = Color(0xFFF44336); // Vermelho
  
  // Cores de fundo
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Cores de status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardBackground, surfaceColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}