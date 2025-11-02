import 'package:flutter/material.dart';

/// Serviço para gerenciar cores dos módulos do dashboard
class ModuleColorsService {
  // Cores padrão FortSmart
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color darkNavy = Color(0xFF1A237E);
  
  // Cores de status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Cores neutras
  static const Color neutral = Color(0xFF9E9E9E);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF616161);

  /// Cores específicas para cada módulo
  static const Map<String, ModuleColorScheme> moduleColors = {
    'fazenda': ModuleColorScheme(
      primary: Color(0xFF2E7D32), // Verde escuro
      secondary: Color(0xFF4CAF50), // Verde médio
      accent: Color(0xFF8BC34A), // Verde claro
      background: Color(0xFFE8F5E8), // Verde muito claro
      text: Color(0xFF1B5E20), // Verde escuro para texto
    ),
    'alertas': ModuleColorScheme(
      primary: Color(0xFFD32F2F), // Vermelho
      secondary: Color(0xFFF44336), // Vermelho médio
      accent: Color(0xFFFFCDD2), // Vermelho claro
      background: Color(0xFFFFEBEE), // Vermelho muito claro
      text: Color(0xFFB71C1C), // Vermelho escuro para texto
    ),
    'talhoes': ModuleColorScheme(
      primary: Color(0xFF1976D2), // Azul
      secondary: Color(0xFF2196F3), // Azul médio
      accent: Color(0xFFBBDEFB), // Azul claro
      background: Color(0xFFE3F2FD), // Azul muito claro
      text: Color(0xFF0D47A1), // Azul escuro para texto
    ),
    'plantios': ModuleColorScheme(
      primary: Color(0xFF7B1FA2), // Roxo
      secondary: Color(0xFF9C27B0), // Roxo médio
      accent: Color(0xFFE1BEE7), // Roxo claro
      background: Color(0xFFF3E5F5), // Roxo muito claro
      text: Color(0xFF4A148C), // Roxo escuro para texto
    ),
    'monitoramentos': ModuleColorScheme(
      primary: Color(0xFFFF6F00), // Laranja
      secondary: Color(0xFFFF9800), // Laranja médio
      accent: Color(0xFFFFE0B2), // Laranja claro
      background: Color(0xFFFFF3E0), // Laranja muito claro
      text: Color(0xFFE65100), // Laranja escuro para texto
    ),
    'estoque': ModuleColorScheme(
      primary: Color(0xFF5D4037), // Marrom
      secondary: Color(0xFF795548), // Marrom médio
      accent: Color(0xFFD7CCC8), // Marrom claro
      background: Color(0xFFEFEBE9), // Marrom muito claro
      text: Color(0xFF3E2723), // Marrom escuro para texto
    ),
  };

  /// Obtém cores do módulo
  static ModuleColorScheme getModuleColors(String moduleName) {
    return moduleColors[moduleName.toLowerCase()] ?? 
           ModuleColorScheme.defaultColors();
  }

  /// Obtém cor baseada no status do módulo
  static Color getStatusColor(String moduleName, ModuleStatus status) {
    final colors = getModuleColors(moduleName);
    
    switch (status) {
      case ModuleStatus.active:
        return colors.primary;
      case ModuleStatus.warning:
        return warning;
      case ModuleStatus.error:
        return error;
      case ModuleStatus.neutral:
        return neutral;
      case ModuleStatus.success:
        return success;
    }
  }

  /// Obtém cor de fundo baseada no status
  static Color getBackgroundColor(String moduleName, ModuleStatus status) {
    final colors = getModuleColors(moduleName);
    
    switch (status) {
      case ModuleStatus.active:
        return colors.background;
      case ModuleStatus.warning:
        return const Color(0xFFFFF3E0);
      case ModuleStatus.error:
        return const Color(0xFFFFEBEE);
      case ModuleStatus.neutral:
        return lightGray;
      case ModuleStatus.success:
        return const Color(0xFFE8F5E8);
    }
  }
}

/// Esquema de cores para um módulo
class ModuleColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color text;

  const ModuleColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.text,
  });

  factory ModuleColorScheme.defaultColors() {
    return const ModuleColorScheme(
      primary: Color(0xFF9E9E9E),
      secondary: Color(0xFFBDBDBD),
      accent: Color(0xFFE0E0E0),
      background: Color(0xFFF5F5F5),
      text: Color(0xFF616161),
    );
  }
  }
}

/// Status do módulo
enum ModuleStatus {
  active,    // Módulo ativo com dados
  warning,   // Módulo com avisos
  error,     // Módulo com erros
  neutral,   // Módulo neutro/sem dados
  success,   // Módulo funcionando perfeitamente
}
