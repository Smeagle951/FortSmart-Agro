import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Classe utilitária para logging de informações do sistema
class AppLogger {
  /// Registra uma mensagem informativa
  static void log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'FortSmart');
      print('[INFO] $message');
    }
  }
  
  /// Registra uma mensagem de erro
  static void error(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'FortSmart', error: true);
      print('[ERROR] $message');
    }
  }
  
  /// Registra uma mensagem de aviso
  static void warning(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'FortSmart', level: 900);
      print('[WARNING] $message');
    }
  }
  
  /// Registra uma mensagem de depuração
  static void debug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'FortSmart', level: 500);
      print('[DEBUG] $message');
    }
  }
}
