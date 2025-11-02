import 'package:flutter/material.dart';

/// Classe que define as cores padrão do aplicativo
class AppColors {
  // Paleta de Cores FortSmart
  
  /// Cor primária - Verde Primário
  static const Color primaryColor = Color(0xFF27AE60); // #27AE60

  /// Cor primária escura - Verde Escuro
  static const Color primaryDarkColor = Color(0xFF1E8449); // #1E8449

  /// Cor secundária - Verde Escuro
  static const Color secondaryColor = Color(0xFF219653); // #219653
  
  /// Cor secundária clara - Verde Claro
  static const Color secondaryLightColor = Color(0xFF6FCF97); // #6FCF97

  /// Cor de acento - Azul Claro de GPS
  static const Color accentColor = Color(0xFF2F80ED); // #2F80ED
  
  /// Cor de acento clara - Azul Claro
  static const Color accentLightColor = Color(0xFF56CCF2); // #56CCF2

  /// Cor de fundo
  static const Color backgroundColor = Color(0xFFF5F5F5); // Cinza claro

  /// Cor de texto principal - Cinza Escuro
  static const Color textColor = Color(0xFF333333); // #333333

  /// Cor de texto secundário - Cinza Médio
  static const Color textSecondaryColor = Color(0xFF828282); // #828282

  /// Cor de erro - Vermelho
  static const Color errorColor = Color(0xFFEB5757); // #EB5757

  /// Cor de aviso - Amarelo
  static const Color warningColor = Color(0xFFF2C94C); // #F2C94C

  /// Cor de sucesso
  static const Color successColor = Color(0xFF388E3C); // Verde

  /// Cor de informação
  static const Color infoColor = Color(0xFF1976D2); // Azul

  /// Cor para safra
  static const Color safraColor = Color(0xFFFFA000); // Amarelo

  /// Cor para talhão
  static const Color talhaoColor = Color(0xFF388E3C); // Verde

  /// Cor para cultura
  static const Color culturaColor = Color(0xFF1976D2); // Azul

  /// Cor para monitoramento
  static const Color monitoringColor = Color(0xFF27AE60); // Verde Primário

  /// Cor para plantio
  static const Color plantingColor = Color(0xFF388E3C); // Verde

  /// Cor para colheita
  static const Color harvestColor = Color(0xFFD32F2F); // Vermelho

  /// Cor para aplicação
  static const Color applicationColor = Color(0xFF0097A7); // Ciano

  /// Mapa de severidade para cores
  static Color getSeverityColor(double severity) {
    if (severity < 0.25) return Colors.green;
    if (severity < 0.5) return Colors.yellow;
    if (severity < 0.75) return Colors.orange;
    return Colors.red;
  }

  /// Getter para cor primária (compatibilidade)
  static Color get primary => primaryColor;
}
