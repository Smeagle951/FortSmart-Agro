import 'package:flutter/material.dart';

/// 🎨 Nova Paleta Premium FortSmart
/// Sistema de cores elegante e profissional para o FortSmart Agro
class FortSmartColors {
  // 🌿 Tons Principais (Brand FortSmart)
  static const Color primary = Color(0xFF1B5E20);      // Verde Escuro (primário)
  static const Color primaryMedium = Color(0xFF43A047); // Verde Médio (destaque)
  static const Color primaryLight = Color(0xFFE8F5E9);  // Verde Claro (fundo suave)
  
  // 🔹 Apoio (Diferenciação Visual)
  static const Color accent = Color(0xFF1565C0);       // Azul Profundo
  static const Color accentLight = Color(0xFFBBDEFB);  // Azul Claro
  static const Color routePrimary = Color(0xFF1565C0); // Azul Profundo (rotas)
  static const Color backgroundLight = Color(0xFFE8F5E9); // Verde Claro (fundo)
  
  // ⚠️ Estados de Infestação
  static const Color infestationLow = Color(0xFF66BB6A);    // Baixa (verde vibrante)
  static const Color infestationMedium = Color(0xFFF9A825); // Média (amarelo premium)
  static const Color infestationHigh = Color(0xFFC62828);   // Alta (vermelho elegante)
  
  // ⚙️ Neutros
  static const Color textPrimary = Color(0xFF263238);   // Cinza Escuro (texto principal)
  static const Color textSecondary = Color(0xFF90A4AE); // Cinza Médio (ícones secundários)
  static const Color surfaceLight = Color(0xFFECEFF1);  // Cinza Claro (linhas/fundos suaves)
  static const Color neutralLight = Color(0xFFF5F5F5);  // Cinza muito claro
  static const Color neutralMedium = Color(0xFFBDBDBD); // Cinza médio
  static const Color white = Color(0xFFFFFFFF);         // Branco puro
  
  // 🎯 Estados do Sistema
  static const Color success = Color(0xFF43A047);       // Sucesso (Verde Médio)
  static const Color warning = Color(0xFFF9A825);       // Aviso (Amarelo Premium)
  static const Color error = Color(0xFFC62828);         // Erro (Vermelho Elegante)
  static const Color info = Color(0xFF1565C0);          // Informação (Azul Profundo)
  
  // 🗺️ Cores do Mapa
  static const Color mapRoute = Color(0xFF1565C0);      // Rotas (Azul Profundo)
  static const Color mapBackground = Color(0xFFF5F5F5); // Fundo do mapa
  static const Color mapBorder = Color(0xFFECEFF1);     // Bordas do mapa
  
  // 🏗️ Cores de Infraestrutura
  static const Color infrastructure = Color(0xFF795548); // Marrom (infraestrutura)
}

/// 🌈 Gradientes Premium FortSmart
class FortSmartGradients {
  // Gradiente Principal
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradiente de Superfície
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Gradiente de Card
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradiente de Cultura Selecionada
  static const LinearGradient cultureCardGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradiente de Distância
  static const LinearGradient distanceCardGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}





/// 🎨 Temas de Slider Premium
class FortSmartSliderThemes {
  // Slider de Infestação Baixa
  static SliderThemeData lowInfestationSlider = SliderThemeData(
    activeTrackColor: FortSmartColors.infestationLow,
    inactiveTrackColor: FortSmartColors.surfaceLight,
    thumbColor: FortSmartColors.infestationLow,
    overlayColor: FortSmartColors.infestationLow.withOpacity(0.2),
    trackHeight: 8,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
  );
  
  // Slider de Infestação Média
  static SliderThemeData mediumInfestationSlider = SliderThemeData(
    activeTrackColor: FortSmartColors.infestationMedium,
    inactiveTrackColor: FortSmartColors.surfaceLight,
    thumbColor: FortSmartColors.infestationMedium,
    overlayColor: FortSmartColors.infestationMedium.withOpacity(0.2),
    trackHeight: 8,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
  );
  
  // Slider de Infestação Alta
  static SliderThemeData highInfestationSlider = SliderThemeData(
    activeTrackColor: FortSmartColors.infestationHigh,
    inactiveTrackColor: FortSmartColors.surfaceLight,
    thumbColor: FortSmartColors.infestationHigh,
    overlayColor: FortSmartColors.infestationHigh.withOpacity(0.2),
    trackHeight: 8,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
  );
}

/// 🎯 Utilitários de Cores
class FortSmartColorUtils {
  /// Obtém a cor de infestação baseada no nível
  static Color getInfestationColor(double level) {
    if (level >= 0.7) return FortSmartColors.infestationHigh;
    if (level >= 0.4) return FortSmartColors.infestationMedium;
    return FortSmartColors.infestationLow;
  }
  
  /// Obtém o tema do slider baseado no nível de infestação
  static SliderThemeData getInfestationSliderTheme(double level) {
    if (level >= 0.7) return FortSmartSliderThemes.highInfestationSlider;
    if (level >= 0.4) return FortSmartSliderThemes.mediumInfestationSlider;
    return FortSmartSliderThemes.lowInfestationSlider;
  }
  
  /// Obtém o label de infestação
  static String getInfestationLabel(double level) {
    if (level >= 0.7) return 'Alta';
    if (level >= 0.4) return 'Média';
    return 'Baixa';
  }
  
  /// Obtém a cor do ícone baseada no tipo de organismo
  static Color getOrganismIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'praga':
        return FortSmartColors.primaryMedium;
      case 'doença':
        return FortSmartColors.error;
      case 'daninha':
        return FortSmartColors.success;
      default:
        return FortSmartColors.textSecondary;
    }
  }
}
