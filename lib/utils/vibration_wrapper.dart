import 'package:flutter/services.dart';

/// Classe utilitária para gerenciar vibrações do dispositivo
class VibrationWrapper {
  /// Vibra o dispositivo com padrão padrão
  static void vibrate() {
    HapticFeedback.mediumImpact();
  }

  /// Vibra o dispositivo com padrão de sucesso
  static void vibrateSuccess() {
    HapticFeedback.lightImpact();
  }

  /// Vibra o dispositivo com padrão de erro
  static void vibrateError() {
    HapticFeedback.heavyImpact();
  }
}
