import 'dart:async';
import 'dart:io';
import '../utils/logger.dart';

/// Sistema de Tratamento de Erros e Retry para Monitoramento Avançado
/// Implementa estratégias robustas de recuperação e notificação de erros
class MonitoringErrorHandler {
  static const String _tag = 'MonitoringErrorHandler';

  /// Configurações de retry
  static const int _maxRetries = 3;
  static const int _baseDelayMs = 1000;
  static const int _maxDelayMs = 30000;

  /// Tipos de erro conhecidos
  static const Map<String, String> _errorMessages = {
    'NETWORK_ERROR': 'Erro de conexão com a internet',
    'SERVER_ERROR': 'Erro no servidor',
    'TIMEOUT_ERROR': 'Tempo limite excedido',
    'GPS_ERROR': 'Erro no GPS',
    'DATABASE_ERROR': 'Erro no banco de dados local',
    'VALIDATION_ERROR': 'Erro de validação dos dados',
    'SYNC_ERROR': 'Erro na sincronização',
    'PERMISSION_ERROR': 'Permissão negada',
    'STORAGE_ERROR': 'Erro de armazenamento',
    'UNKNOWN_ERROR': 'Erro desconhecido',
  };

  /// Resultado de uma operação com retry
  class RetryResult<T> {
    final bool success;
    final T? data;
    final String? error;
    final int retryCount;
    final Duration totalDuration;
    final List<String> errors;

    RetryResult({
      required this.success,
      this.data,
      this.error,
      required this.retryCount,
      required this.totalDuration,
      required this.errors,
    });
  }

  /// Executa uma operação com retry automático
  static Future<RetryResult<T>> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = _maxRetries,
    int baseDelayMs = _baseDelayMs,
    int maxDelayMs = _maxDelayMs,
    bool Function(Exception)? shouldRetry,
    String? operationName,
  }) async {
    final startTime = DateTime.now();
    final errors = <String>[];
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        Logger.info('$_tag: Executando ${operationName ?? 'operação'} (tentativa ${retryCount + 1})');
        
        final result = await operation();
        
        final duration = DateTime.now().difference(startTime);
        Logger.info('$_tag: ✅ ${operationName ?? 'Operação'} concluída com sucesso em ${duration.inMilliseconds}ms');
        
        return RetryResult<T>(
          success: true,
          data: result,
          retryCount: retryCount,
          totalDuration: duration,
          errors: errors,
        );
      } catch (e) {
        retryCount++;
        final errorMessage = _getErrorMessage(e);
        errors.add('Tentativa $retryCount: $errorMessage');
        
        Logger.warning('$_tag: ❌ ${operationName ?? 'Operação'} falhou (tentativa $retryCount): $errorMessage');
        
        // Verificar se deve tentar novamente
        if (retryCount > maxRetries) {
          final duration = DateTime.now().difference(startTime);
          Logger.error('$_tag: ❌ ${operationName ?? 'Operação'} falhou após $maxRetries tentativas');
          
          return RetryResult<T>(
            success: false,
            error: errorMessage,
            retryCount: retryCount - 1,
            totalDuration: duration,
            errors: errors,
          );
        }
        
        // Verificar se o erro é recuperável
        if (shouldRetry != null && !shouldRetry(e as Exception)) {
          final duration = DateTime.now().difference(startTime);
          Logger.warning('$_tag: ⚠️ ${operationName ?? 'Operação'} não será retentada: erro não recuperável');
          
          return RetryResult<T>(
            success: false,
            error: errorMessage,
            retryCount: retryCount - 1,
            totalDuration: duration,
            errors: errors,
          );
        }
        
        // Aguardar antes da próxima tentativa
        if (retryCount <= maxRetries) {
          final delay = _calculateBackoffDelay(retryCount, baseDelayMs, maxDelayMs);
          Logger.info('$_tag: Aguardando ${delay.inMilliseconds}ms antes da próxima tentativa...');
          await Future.delayed(delay);
        }
      }
    }
    
    // Nunca deve chegar aqui, mas por segurança
    final duration = DateTime.now().difference(startTime);
    return RetryResult<T>(
      success: false,
      error: 'Erro inesperado',
      retryCount: retryCount - 1,
      totalDuration: duration,
      errors: errors,
    );
  }

  /// Calcula delay com backoff exponencial
  static Duration _calculateBackoffDelay(int retryCount, int baseDelayMs, int maxDelayMs) {
    final delay = baseDelayMs * (2 ^ (retryCount - 1));
    final jitter = (DateTime.now().millisecondsSinceEpoch % 1000); // Adiciona jitter
    final finalDelay = (delay + jitter).clamp(0, maxDelayMs);
    
    return Duration(milliseconds: finalDelay);
  }

  /// Obtém mensagem de erro amigável
  static String _getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return _errorMessages['NETWORK_ERROR'] ?? 'Erro de conexão';
    } else if (error is TimeoutException) {
      return _errorMessages['TIMEOUT_ERROR'] ?? 'Tempo limite excedido';
    } else if (error is HttpException) {
      return _errorMessages['SERVER_ERROR'] ?? 'Erro no servidor';
    } else if (error.toString().contains('GPS')) {
      return _errorMessages['GPS_ERROR'] ?? 'Erro no GPS';
    } else if (error.toString().contains('database')) {
      return _errorMessages['DATABASE_ERROR'] ?? 'Erro no banco de dados';
    } else if (error.toString().contains('validation')) {
      return _errorMessages['VALIDATION_ERROR'] ?? 'Erro de validação';
    } else if (error.toString().contains('sync')) {
      return _errorMessages['SYNC_ERROR'] ?? 'Erro na sincronização';
    } else if (error.toString().contains('permission')) {
      return _errorMessages['PERMISSION_ERROR'] ?? 'Permissão negada';
    } else if (error.toString().contains('storage')) {
      return _errorMessages['STORAGE_ERROR'] ?? 'Erro de armazenamento';
    } else {
      return _errorMessages['UNKNOWN_ERROR'] ?? 'Erro desconhecido: ${error.toString()}';
    }
  }

  /// Verifica se um erro é recuperável
  static bool isRecoverableError(dynamic error) {
    if (error is SocketException) {
      return true; // Erro de rede é recuperável
    } else if (error is TimeoutException) {
      return true; // Timeout é recuperável
    } else if (error is HttpException) {
      final statusCode = error.message.contains('500') || 
                        error.message.contains('502') || 
                        error.message.contains('503') ||
                        error.message.contains('504');
      return statusCode; // Apenas erros 5xx são recuperáveis
    } else if (error.toString().contains('GPS')) {
      return true; // Erro de GPS é recuperável
    } else if (error.toString().contains('database')) {
      return false; // Erro de banco não é recuperável
    } else if (error.toString().contains('validation')) {
      return false; // Erro de validação não é recuperável
    } else if (error.toString().contains('permission')) {
      return false; // Erro de permissão não é recuperável
    } else {
      return true; // Por padrão, assume que é recuperável
    }
  }

  /// Executa operações em paralelo com retry individual
  static Future<List<RetryResult<T>>> executeParallelWithRetry<T>({
    required List<Future<T> Function()> operations,
    int maxRetries = _maxRetries,
    String? operationName,
  }) async {
    final futures = operations.map((operation) => executeWithRetry<T>(
      operation: operation,
      maxRetries: maxRetries,
      operationName: operationName,
    )).toList();

    return await Future.wait(futures);
  }

  /// Executa operações em sequência com retry
  static Future<List<RetryResult<T>>> executeSequentialWithRetry<T>({
    required List<Future<T> Function()> operations,
    int maxRetries = _maxRetries,
    String? operationName,
  }) async {
    final results = <RetryResult<T>>[];
    
    for (int i = 0; i < operations.length; i++) {
      final result = await executeWithRetry<T>(
        operation: operations[i],
        maxRetries: maxRetries,
        operationName: '$operationName (operação ${i + 1})',
      );
      
      results.add(result);
      
      // Se falhou e não é a última operação, continuar mesmo assim
      if (!result.success && i < operations.length - 1) {
        Logger.warning('$_tag: ⚠️ Operação ${i + 1} falhou, continuando com as próximas...');
      }
    }
    
    return results;
  }

  /// Executa operação com timeout
  static Future<RetryResult<T>> executeWithTimeout<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = _maxRetries,
    String? operationName,
  }) async {
    return executeWithRetry<T>(
      operation: () => operation().timeout(timeout),
      maxRetries: maxRetries,
      operationName: operationName,
    );
  }

  /// Executa operação com validação de resultado
  static Future<RetryResult<T>> executeWithValidation<T>({
    required Future<T> Function() operation,
    required bool Function(T result) validator,
    int maxRetries = _maxRetries,
    String? operationName,
  }) async {
    return executeWithRetry<T>(
      operation: () async {
        final result = await operation();
        if (!validator(result)) {
          throw Exception('Resultado da operação não passou na validação');
        }
        return result;
      },
      maxRetries: maxRetries,
      operationName: operationName,
    );
  }

  /// Obtém estatísticas de erro
  static Map<String, dynamic> getErrorStats(List<RetryResult> results) {
    int totalOperations = results.length;
    int successfulOperations = results.where((r) => r.success).length;
    int failedOperations = totalOperations - successfulOperations;
    int totalRetries = results.fold(0, (sum, r) => sum + r.retryCount);
    Duration totalDuration = results.fold(
      Duration.zero, 
      (sum, r) => sum + r.totalDuration
    );
    
    final errorTypes = <String, int>{};
    for (final result in results) {
      if (!result.success && result.error != null) {
        final errorType = _getErrorType(result.error!);
        errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
      }
    }
    
    return {
      'total_operations': totalOperations,
      'successful_operations': successfulOperations,
      'failed_operations': failedOperations,
      'success_rate': totalOperations > 0 ? (successfulOperations / totalOperations) : 0.0,
      'total_retries': totalRetries,
      'average_retries': totalOperations > 0 ? (totalRetries / totalOperations) : 0.0,
      'total_duration': totalDuration.inMilliseconds,
      'average_duration': totalOperations > 0 ? (totalDuration.inMilliseconds / totalOperations) : 0,
      'error_types': errorTypes,
    };
  }

  /// Obtém o tipo de erro
  static String _getErrorType(String errorMessage) {
    if (errorMessage.contains('conexão') || errorMessage.contains('network')) {
      return 'NETWORK';
    } else if (errorMessage.contains('servidor') || errorMessage.contains('server')) {
      return 'SERVER';
    } else if (errorMessage.contains('timeout') || errorMessage.contains('tempo')) {
      return 'TIMEOUT';
    } else if (errorMessage.contains('GPS')) {
      return 'GPS';
    } else if (errorMessage.contains('banco') || errorMessage.contains('database')) {
      return 'DATABASE';
    } else if (errorMessage.contains('validação') || errorMessage.contains('validation')) {
      return 'VALIDATION';
    } else if (errorMessage.contains('sincronização') || errorMessage.contains('sync')) {
      return 'SYNC';
    } else if (errorMessage.contains('permissão') || errorMessage.contains('permission')) {
      return 'PERMISSION';
    } else if (errorMessage.contains('armazenamento') || errorMessage.contains('storage')) {
      return 'STORAGE';
    } else {
      return 'UNKNOWN';
    }
  }

  /// Loga estatísticas de erro
  static void logErrorStats(List<RetryResult> results) {
    final stats = getErrorStats(results);
    
    Logger.info('$_tag: 📊 Estatísticas de Erro:');
    Logger.info('$_tag:   Total de operações: ${stats['total_operations']}');
    Logger.info('$_tag:   Operações bem-sucedidas: ${stats['successful_operations']}');
    Logger.info('$_tag:   Operações falharam: ${stats['failed_operations']}');
    Logger.info('$_tag:   Taxa de sucesso: ${(stats['success_rate'] * 100).toStringAsFixed(1)}%');
    Logger.info('$_tag:   Total de retries: ${stats['total_retries']}');
    Logger.info('$_tag:   Média de retries: ${stats['average_retries'].toStringAsFixed(1)}');
    Logger.info('$_tag:   Duração total: ${stats['total_duration']}ms');
    Logger.info('$_tag:   Duração média: ${stats['average_duration']}ms');
    
    if (stats['error_types'] is Map) {
      Logger.info('$_tag:   Tipos de erro:');
      (stats['error_types'] as Map).forEach((type, count) {
        Logger.info('$_tag:     $type: $count');
      });
    }
  }
}
