import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Classe responsável por escrever logs no sistema
/// 
/// Provê métodos estáticos para uso global e suporte para instâncias com tags
class Logger {
  static File? _logFile;
  static bool _initialized = false;

  Logger(String s);
  
  /// Inicializa o sistema de logging
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/app_log_$today.txt');
      _initialized = true;
      
      // Limpeza de logs antigos
      cleanOldLogs();
    } catch (e) {
      print('Erro ao inicializar logger: $e');
    }
  }
  
  /// Escreve mensagem no arquivo de log
  static Future<void> _writeToLog(String message, String level, String tag) async {
    if (!_initialized) {
      initialize(); // Chamada assíncrona, mas não esperamos
    }
    
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final logMessage = '[$timestamp] [$tag] $level: $message\n';
    
    try {
      // Sempre exibe no console
      print(logMessage);
      
      // Escreve no arquivo assincronamente
      if (_logFile != null) {
        try {
          await _logFile!.writeAsString(logMessage, mode: FileMode.append);
        } catch (e) {
          print('Erro ao escrever log: $e');
        }
      }
    } catch (e) {
      print('Erro ao escrever log: $e');
    }
  }
  
  /// Limpa os logs antigos (mantém apenas os últimos 7 dias)
  static Future<void> cleanOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) return;
      
      final files = await logDir.list().toList();
      final now = DateTime.now();
      
      for (var file in files) {
        if (file is File && file.path.contains('app_log_')) {
          final fileName = file.path.split('/').last;
          final dateStr = fileName.replaceAll('app_log_', '').replaceAll('.txt', '');
          try {
            final fileDate = DateFormat('yyyy-MM-dd').parse(dateStr);
            final difference = now.difference(fileDate).inDays;
            
            if (difference > 7) {
              await file.delete();
            }
          } catch (e) {
            print('Erro ao processar arquivo de log: $e');
          }
        }
      }
    } catch (e) {
      print('Erro ao limpar logs antigos: $e');
    }
  }
  
  // ===== MÉTODOS ESTÁTICOS =====
  
  /// Registra uma mensagem de log
  static Future<void> log(String message, {String level = 'INFO', String tag = 'App'}) async {
    await _writeToLog(message, level, tag);
  }
  
  /// Registra uma mensagem informativa
  static Future<void> info(String message, [String tag = 'APP']) async {
    await log(message, level: 'INFO', tag: tag);
  }
  
  /// Registra uma mensagem de aviso
  static Future<void> warn(String message, [String tag = 'APP']) async {
    await _writeToLog(message, 'WARNING', tag);
  }
  
  /// Registra uma mensagem de aviso (alias para warn)
  static Future<void> warning(String message, [String tag = 'APP']) async {
    await _writeToLog(message, 'WARNING', tag);
  }
  
  /// Registra uma mensagem de erro
  static Future<void> error(String message, [dynamic erro, StackTrace? stackTrace, String tag = 'APP']) async {
    final errorMsg = erro != null ? '$message: $erro' : message;
    final traceMsg = stackTrace != null ? '\n$stackTrace' : '';
    await _writeToLog('$errorMsg$traceMsg', 'ERROR', tag);
  }
  
  /// Registra uma mensagem severa
  static Future<void> severe(String message, [String tag = 'APP']) async {
    await _writeToLog(message, 'SEVERE', tag);
  }
}

/// Classe para logging com tags específicos
class TaggedLogger {
  final String tag;
  
  TaggedLogger(this.tag);
  
  /// Registra uma mensagem de log
  Future<void> log(String message, {String level = 'INFO'}) async {
    await Logger._writeToLog(message, level, tag);
  }
  
  /// Registra uma mensagem de erro
  Future<void> error(String message, [dynamic erro, StackTrace? stackTrace]) async {
    final errorMsg = erro != null ? '$message: $erro' : message;
    final traceMsg = stackTrace != null ? '\n$stackTrace' : '';
    await log('$errorMsg$traceMsg', level: 'ERROR');
  }
  
  /// Registra uma mensagem de aviso
  Future<void> warning(String message) async {
    await log(message, level: 'WARNING');
  }
  
  /// Registra uma mensagem informativa
  Future<void> info(String message) async {
    await log(message, level: 'INFO');
  }
  
  /// Registra uma mensagem de depuração
  Future<void> debug(String message) async {
    await log(message, level: 'DEBUG');
  }
  
  /// Registra uma mensagem severa
  Future<void> severe(String message) async {
    await log(message, level: 'SEVERE');
  }
}
