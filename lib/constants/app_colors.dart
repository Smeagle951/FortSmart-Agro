import 'package:flutter/material.dart';

/// Constantes de cores personalizadas para o sistema de custos
class AppColors {
  // Cores primárias
  static const Color primary = Color(0xFF2E7D32);      // Verde agrícola
  static const Color primaryLight = Color(0xFF4CAF50); // Verde claro
  static const Color primaryDark = Color(0xFF1B5E20);  // Verde escuro
  
  // Cores secundárias
  static const Color secondary = Color(0xFFFF8F00);    // Laranja
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  // Cores de fundo
  static const Color background = Color(0xFFFAFAFA);   // Cinza muito claro
  static const Color surface = Color(0xFFFFFFFF);      // Branco
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);  // Preto suave
  static const Color textSecondary = Color(0xFF757575); // Cinza médio
  static const Color textLight = Color(0xFFBDBDBD);    // Cinza claro
  
  // Cores de status
  static const Color success = Color(0xFF4CAF50);      // Verde
  static const Color warning = Color(0xFFFF9800);      // Laranja
  static const Color error = Color(0xFFF44336);        // Vermelho
  static const Color info = Color(0xFF2196F3);         // Azul
  
  // Cores por tipo de operação
  static const Color plantio = Color(0xFF4CAF50);      // Verde
  static const Color adubacao = Color(0xFF2196F3);     // Azul
  static const Color pulverizacao = Color(0xFFFF9800); // Laranja
  static const Color colheita = Color(0xFFFFC107);     // Âmbar
  static const Color solo = Color(0xFF795548);         // Marrom
  static const Color outros = Color(0xFF9E9E9E);       // Cinza
  
  // Cores de custos
  static const Color custoTotal = Color(0xFFE91E63);   // Rosa
  static const Color custoPorHa = Color(0xFF9C27B0);   // Roxo
  static const Color lucro = Color(0xFF4CAF50);        // Verde
  static const Color prejuizo = Color(0xFFF44336);     // Vermelho
  
  // Cores de gráficos
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Azul
    Color(0xFF4CAF50), // Verde
    Color(0xFFFF9800), // Laranja
    Color(0xFFE91E63), // Rosa
    Color(0xFF9C27B0), // Roxo
    Color(0xFF795548), // Marrom
    Color(0xFF607D8B), // Azul acinzentado
    Color(0xFFFF5722), // Vermelho laranja
  ];
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Sombras
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];
  
  // Métodos utilitários
  static Color getColorForTipoOperacao(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'plantio':
        return plantio;
      case 'adubacao':
        return adubacao;
      case 'pulverizacao':
        return pulverizacao;
      case 'colheita':
        return colheita;
      case 'solo':
        return solo;
      default:
        return outros;
    }
  }
  
  static Color getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sucesso':
      case 'success':
        return success;
      case 'aviso':
      case 'warning':
        return warning;
      case 'erro':
      case 'error':
        return error;
      case 'info':
      case 'informacao':
        return info;
      default:
        return textSecondary;
    }
  }
  
  static Color getColorForCusto(double valor, {double? limite}) {
    if (limite != null) {
      if (valor > limite) {
        return error;
      } else if (valor > limite * 0.8) {
        return warning;
      }
    }
    return success;
  }
}
