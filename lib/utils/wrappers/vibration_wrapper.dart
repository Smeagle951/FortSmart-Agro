import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper para vibração do dispositivo
/// 
/// Esta classe fornece uma interface consistente para vibração
/// sem depender do plugin vibration, usando apenas recursos nativos do Flutter.
class VibrationWrapper {
  // Método para verificar se o dispositivo suporta vibração
  // Como não temos acesso direto a essa informação sem o plugin,
  // vamos assumir que o dispositivo suporta vibração
  static Future<bool> hasVibrator() async {
    // Implementação simplificada que sempre retorna true
    // Isso é uma solução temporária até que uma implementação melhor seja possível
    return true;
  }

  /// Vibra o dispositivo com um padrão específico
  /// 
  /// @param duration Duração da vibração em milissegundos
  /// @param amplitude Amplitude da vibração (ignorado nesta implementação)
  static Future<void> vibrate({int duration = 500, int amplitude = -1}) async {
    try {
      // Usando o HapticFeedback do Flutter para vibrar o dispositivo
      // Como não temos controle sobre a duração, usamos o feedback mais próximo
      if (duration <= 20) {
        await HapticFeedback.lightImpact();
      } else if (duration <= 100) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
      
      debugPrint('Vibração simulada com duração: $duration ms');
    } catch (e) {
      debugPrint('Erro ao vibrar dispositivo: $e');
    }
  }

  /// Vibra o dispositivo com um padrão personalizado
  /// 
  /// @param pattern Lista de durações em milissegundos, alternando entre vibração e pausa
  /// @param repeat Índice no padrão para repetir (ignorado nesta implementação)
  /// @param intensities Lista de intensidades para cada vibração (ignorado nesta implementação)
  static Future<void> vibrateWithPattern({
    required List<int> pattern,
    int repeat = -1,
    List<int> intensities = const [],
  }) async {
    try {
      // Implementação simplificada que apenas vibra uma vez
      // Isso é uma solução temporária até que uma implementação melhor seja possível
      await HapticFeedback.heavyImpact();
      
      debugPrint('Vibração com padrão simulada: $pattern');
    } catch (e) {
      debugPrint('Erro ao vibrar dispositivo com padrão: $e');
    }
  }

  /// Cancela qualquer vibração em andamento
  /// Nesta implementação, não faz nada, pois o HapticFeedback não permite cancelamento
  static Future<void> cancel() async {
    // Não faz nada, pois não podemos cancelar o HapticFeedback
    debugPrint('Tentativa de cancelar vibração (não suportado nesta implementação)');
  }
}
