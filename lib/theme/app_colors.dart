import 'package:flutter/material.dart';

/// Classe que define as cores padrão do aplicativo
class AppColors {
  static const primary = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF388E3C);
  static const primaryLight = Color(0xFFC8E6C9);
  static const accent = Color(0xFFFF9800);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFBDBDBD);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFFFA000);
  static const success = Color(0xFF388E3C);
  static const info = Color(0xFF1976D2);
  
  // Cores específicas para gráficos e visualizações
  static const chartBlue = Color(0xFF2196F3);
  static const chartGreen = Color(0xFF4CAF50);
  static const chartOrange = Color(0xFFFF9800);
  static const chartRed = Color(0xFFF44336);
  static const chartPurple = Color(0xFF9C27B0);
  static const chartYellow = Color(0xFFFFEB3B);
  
  // Cores para estados de botões e interações
  static const buttonPrimary = primary;
  static const buttonDisabled = Color(0xFFBDBDBD);
  static const buttonText = Colors.white;
  static const rippleEffect = Color(0x1F000000);
  
  // Cores para estados de campos de texto
  static const inputBorder = Color(0xFFBDBDBD);
  static const inputFocused = primary;
  static const inputError = error;
  
  // Cores para estados de seleção
  static const selected = primaryLight;
  static const unselected = Color(0xFFE0E0E0);
  
  // Cores para estados de alerta
  static const alertError = error;
  static const alertWarning = warning;
  static const alertSuccess = success;
  static const alertInfo = info;
  
  // Cores para estados de progresso
  static const progressBackground = Color(0xFFE0E0E0);
  static const progressForeground = primary;
  
  // Cores para estados de disponibilidade
  static const available = success;
  static const unavailable = error;
  static const partial = warning;
  
  // Cores para estados de cultivo
  static const plantingActive = success;
  static const plantingInactive = error;
  static const plantingPending = warning;
  
  // Cores para estados de safra
  static const cropSeasonActive = success;
  static const cropSeasonInactive = error;
  static const cropSeasonPending = warning;
  
  // Cores para estados de solo
  static const soilGood = success;
  static const soilModerate = warning;
  static const soilPoor = error;
  
  // Cores para estados de clima
  static const weatherGood = success;
  static const weatherModerate = warning;
  static const weatherBad = error;
  
  // Cores para estados de irrigação
  static const irrigationActive = success;
  static const irrigationInactive = error;
  static const irrigationScheduled = warning;

  static var primaryColor;

  static var primaryDarkColor;

  static var accentColor;

  static var accentLightColor;
}
