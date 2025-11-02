import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'logger.dart';
import 'storage_utils.dart';

/// Classe para reportar erros do aplicativo
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();
  static const String _errorLogFileName = 'error_log.json';
  static const int _maxErrorsToKeep = 100;
  
  factory ErrorReporter() {
    return _instance;
  }
  
  ErrorReporter._internal();
  
  /// Reporta um erro
  static Future<void> reportError(String message, dynamic error, StackTrace? stackTrace) async {
    try {
      // Registra no log
      Logger.error(message, error, stackTrace);
      
      // Salva no histórico de erros
      await _saveErrorToHistory(message, error, stackTrace);
      
      // Em ambiente de desenvolvimento, exibe no console
      if (kDebugMode) {
        print('ERRO: $message');
        if (error != null) {
          print('Detalhes: $error');
        }
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
      
      // Aqui poderia ser implementado o envio para um serviço de monitoramento
      // como Firebase Crashlytics, Sentry, etc.
    } catch (e) {
      // Falha silenciosa para evitar loops de erro
      if (kDebugMode) {
        print('Erro ao reportar erro: $e');
      }
    }
  }
  
  /// Salva o erro no histórico
  static Future<void> _saveErrorToHistory(String message, dynamic error, StackTrace? stackTrace) async {
    try {
      final errorData = {
        'timestamp': DateTime.now().toIso8601String(),
        'message': message,
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
      };
      
      // Carrega o histórico existente
      List<dynamic> errorHistory = await _loadErrorHistory();
      
      // Adiciona o novo erro
      errorHistory.add(errorData);
      
      // Limita o tamanho do histórico
      if (errorHistory.length > _maxErrorsToKeep) {
        errorHistory = errorHistory.sublist(errorHistory.length - _maxErrorsToKeep);
      }
      
      // Salva o histórico atualizado
      await _saveErrorHistory(errorHistory);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar histórico de erros: $e');
      }
    }
  }
  
  /// Carrega o histórico de erros
  static Future<List<dynamic>> _loadErrorHistory() async {
    try {
      final errorHistoryJson = StorageUtils.getString('error_history');
      if (errorHistoryJson == null || errorHistoryJson.isEmpty) {
        return [];
      }
      
      return json.decode(errorHistoryJson) as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar histórico de erros: $e');
      }
      return [];
    }
  }
  
  /// Salva o histórico de erros
  static Future<void> _saveErrorHistory(List<dynamic> errorHistory) async {
    try {
      final errorHistoryJson = json.encode(errorHistory);
      await StorageUtils.saveString('error_history', errorHistoryJson);
      
      // Também salva em arquivo para persistência
      await _saveErrorHistoryToFile(errorHistoryJson);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar histórico de erros: $e');
      }
    }
  }
  
  /// Salva o histórico de erros em arquivo
  static Future<void> _saveErrorHistoryToFile(String errorHistoryJson) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final file = File(path.join(logDir.path, _errorLogFileName));
      await file.writeAsString(errorHistoryJson);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar histórico de erros em arquivo: $e');
      }
    }
  }
  
  /// Obtém o histórico de erros
  static Future<List<dynamic>> getErrorHistory() async {
    return await _loadErrorHistory();
  }
  
  /// Limpa o histórico de erros
  static Future<void> clearErrorHistory() async {
    try {
      await StorageUtils.saveString('error_history', '[]');
      
      final appDir = await getApplicationDocumentsDirectory();
      final logFile = File(path.join(appDir.path, 'logs', _errorLogFileName));
      
      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao limpar histórico de erros: $e');
      }
    }
  }
}
