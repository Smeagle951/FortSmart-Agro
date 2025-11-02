import 'package:flutter/material.dart';

/// Utilitários para responsividade automática
class ResponsiveScreenUtils {
  static const double _baseWidth = 375.0; // iPhone X base width
  static const double _baseHeight = 812.0; // iPhone X base height
  
  /// Obtém o contexto da tela
  static MediaQueryData _getScreenData(BuildContext context) {
    return MediaQuery.of(context);
  }
  
  /// Calcula escala baseada na largura da tela
  static double getWidthScale(BuildContext context) {
    final screenData = _getScreenData(context);
    return screenData.size.width / _baseWidth;
  }
  
  /// Calcula escala baseada na altura da tela
  static double getHeightScale(BuildContext context) {
    final screenData = _getScreenData(context);
    return screenData.size.height / _baseHeight;
  }
  
  /// Calcula escala balanceada (média entre largura e altura)
  static double getBalancedScale(BuildContext context) {
    final widthScale = getWidthScale(context);
    final heightScale = getHeightScale(context);
    return (widthScale + heightScale) / 2;
  }
  
  /// Calcula escala baseada na menor dimensão
  static double getMinScale(BuildContext context) {
    final widthScale = getWidthScale(context);
    final heightScale = getHeightScale(context);
    return widthScale < heightScale ? widthScale : heightScale;
  }
  
  /// Calcula escala baseada na maior dimensão
  static double getMaxScale(BuildContext context) {
    final widthScale = getWidthScale(context);
    final heightScale = getHeightScale(context);
    return widthScale > heightScale ? widthScale : heightScale;
  }
  
  /// Aplica escala a um valor
  static double scale(BuildContext context, double value, {ResponsiveScale scaleType = ResponsiveScale.balanced}) {
    double scaleFactor;
    switch (scaleType) {
      case ResponsiveScale.width:
        scaleFactor = getWidthScale(context);
        break;
      case ResponsiveScale.height:
        scaleFactor = getHeightScale(context);
        break;
      case ResponsiveScale.balanced:
        scaleFactor = getBalancedScale(context);
        break;
      case ResponsiveScale.min:
        scaleFactor = getMinScale(context);
        break;
      case ResponsiveScale.max:
        scaleFactor = getMaxScale(context);
        break;
    }
    
    // Limita a escala entre 0.5 e 2.0 para evitar elementos muito pequenos ou grandes
    scaleFactor = scaleFactor.clamp(0.5, 2.0);
    return value * scaleFactor;
  }
  
  /// Verifica se é uma tela pequena
  static bool isSmallScreen(BuildContext context) {
    return _getScreenData(context).size.width < 600;
  }
  
  /// Verifica se é uma tela média
  static bool isMediumScreen(BuildContext context) {
    final width = _getScreenData(context).size.width;
    return width >= 600 && width < 1200;
  }
  
  /// Verifica se é uma tela grande
  static bool isLargeScreen(BuildContext context) {
    return _getScreenData(context).size.width >= 1200;
  }
  
  /// Obtém o tipo de tela
  static ScreenType getScreenType(BuildContext context) {
    if (isSmallScreen(context)) return ScreenType.small;
    if (isMediumScreen(context)) return ScreenType.medium;
    return ScreenType.large;
  }
  
  /// Calcula padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final scale = getBalancedScale(context);
    
    return EdgeInsets.only(
      left: scale * (left ?? horizontal ?? all ?? 16.0),
      top: scale * (top ?? vertical ?? all ?? 16.0),
      right: scale * (right ?? horizontal ?? all ?? 16.0),
      bottom: scale * (bottom ?? vertical ?? all ?? 16.0),
    );
  }
  
  /// Calcula margin responsivo
  static EdgeInsets getResponsiveMargin(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final scale = getBalancedScale(context);
    
    return EdgeInsets.only(
      left: scale * (left ?? horizontal ?? all ?? 0.0),
      top: scale * (top ?? vertical ?? all ?? 0.0),
      right: scale * (right ?? horizontal ?? all ?? 0.0),
      bottom: scale * (bottom ?? vertical ?? all ?? 0.0),
    );
  }
  
  /// Calcula tamanho de fonte responsivo
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    return scale(context, baseFontSize, scaleType: ResponsiveScale.balanced);
  }
  
  /// Calcula espaçamento responsivo
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    return scale(context, baseSpacing, scaleType: ResponsiveScale.balanced);
  }
  
  /// Calcula tamanho de ícone responsivo
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    return scale(context, baseIconSize, scaleType: ResponsiveScale.balanced);
  }
  
  /// Calcula elevação responsiva
  static double getResponsiveElevation(BuildContext context, double baseElevation) {
    return scale(context, baseElevation, scaleType: ResponsiveScale.min);
  }
  
  /// Calcula raio de borda responsivo
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    return scale(context, baseRadius, scaleType: ResponsiveScale.balanced);
  }
}

/// Tipos de escala responsiva
enum ResponsiveScale {
  width,    // Baseado na largura
  height,   // Baseado na altura
  balanced, // Média entre largura e altura
  min,      // Menor dimensão
  max,      // Maior dimensão
}

/// Tipos de tela
enum ScreenType {
  small,  // < 600px
  medium, // 600px - 1200px
  large,  // > 1200px
}
