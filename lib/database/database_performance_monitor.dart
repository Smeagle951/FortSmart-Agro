import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Monitor de desempenho do banco de dados
/// Registra e analisa o tempo de execução das consultas SQL
class DatabasePerformanceMonitor {
  static final DatabasePerformanceMonitor _instance = DatabasePerformanceMonitor._internal();
  factory DatabasePerformanceMonitor() => _instance;
  DatabasePerformanceMonitor._internal();

  // Configurações
  int _maxQueryHistory = 100;
  bool _enabled = true;
  int _slowQueryThresholdMs = 100; // Consultas acima deste limite são consideradas lentas

  // Histórico de consultas
  final LinkedHashMap<String, _QueryStats> _queryStats = LinkedHashMap<String, _QueryStats>();
  final List<_QueryExecution> _recentQueries = [];
  final List<_QueryExecution> _slowQueries = [];

  // Estatísticas gerais
  int _totalQueries = 0;
  int _totalErrors = 0;
  int _totalSlowQueries = 0;
  int _totalTransactions = 0;
  int _totalTransactionErrors = 0;
  
  // Timestamps para cálculo de taxa de consultas
  DateTime _firstQueryTime = DateTime.now();
  DateTime _lastQueryTime = DateTime.now();

  /// Ativa ou desativa o monitoramento
  set enabled(bool value) => _enabled = value;
  
  /// Retorna se o monitoramento está ativado
  bool get enabled => _enabled;
  
  /// Define o limite para considerar uma consulta como lenta (em milissegundos)
  set slowQueryThresholdMs(int value) => _slowQueryThresholdMs = value;
  
  /// Retorna o limite para considerar uma consulta como lenta (em milissegundos)
  int get slowQueryThresholdMs => _slowQueryThresholdMs;
  
  /// Define o tamanho máximo do histórico de consultas
  set maxQueryHistory(int value) => _maxQueryHistory = value;
  
  /// Retorna o tamanho máximo do histórico de consultas
  int get maxQueryHistory => _maxQueryHistory;

  /// Registra o início de uma consulta
  String startQuery(String query, {Map<String, dynamic>? params}) {
    if (!_enabled) return '';
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final execution = _QueryExecution(
      id: id,
      query: query,
      params: params,
      startTime: DateTime.now(),
    );
    
    _recentQueries.add(execution);
    if (_recentQueries.length > _maxQueryHistory) {
      _recentQueries.removeAt(0);
    }
    
    return id;
  }

  /// Registra o fim de uma consulta
  void endQuery(String id, {dynamic result, dynamic error}) {
    if (!_enabled || id.isEmpty) return;
    
    final execution = _recentQueries.firstWhere(
      (e) => e.id == id && e.endTime == null,
      orElse: () => _QueryExecution(id: '', query: '', startTime: DateTime.now()),
    );
    
    if (execution.id.isEmpty) return;
    
    execution.endTime = DateTime.now();
    execution.error = error;
    execution.success = error == null;
    
    final duration = execution.duration;
    
    // Atualiza estatísticas
    _totalQueries++;
    if (error != null) _totalErrors++;
    _lastQueryTime = execution.endTime!;
    if (_totalQueries == 1) _firstQueryTime = execution.startTime;
    
    // Verifica se é uma consulta lenta
    if (duration.inMilliseconds > _slowQueryThresholdMs) {
      _totalSlowQueries++;
      _slowQueries.add(execution);
      if (_slowQueries.length > _maxQueryHistory) {
        _slowQueries.removeAt(0);
      }
    }
    
    // Atualiza estatísticas da consulta
    final normalizedQuery = _normalizeQuery(execution.query);
    if (!_queryStats.containsKey(normalizedQuery)) {
      _queryStats[normalizedQuery] = _QueryStats(query: normalizedQuery);
    }
    
    final stats = _queryStats[normalizedQuery]!;
    stats.count++;
    stats.totalDuration += duration.inMilliseconds;
    if (error != null) stats.errorCount++;
    
    if (duration.inMilliseconds > stats.maxDuration) {
      stats.maxDuration = duration.inMilliseconds;
    }
    
    if (stats.minDuration == 0 || duration.inMilliseconds < stats.minDuration) {
      stats.minDuration = duration.inMilliseconds;
    }
  }

  /// Registra o início de uma transação
  String startTransaction() {
    if (!_enabled) return '';
    
    _totalTransactions++;
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Registra o fim de uma transação
  void endTransaction(String id, {dynamic error}) {
    if (!_enabled || id.isEmpty) return;
    
    if (error != null) {
      _totalTransactionErrors++;
    }
  }

  /// Retorna as estatísticas gerais do banco de dados
  Map<String, dynamic> getGeneralStats() {
    final now = DateTime.now();
    final totalTimeMs = now.difference(_firstQueryTime).inMilliseconds;
    
    return {
      'totalQueries': _totalQueries,
      'totalErrors': _totalErrors,
      'errorRate': _totalQueries > 0 ? (_totalErrors / _totalQueries) : 0,
      'totalSlowQueries': _totalSlowQueries,
      'slowQueryRate': _totalQueries > 0 ? (_totalSlowQueries / _totalQueries) : 0,
      'queriesPerSecond': totalTimeMs > 0 ? (_totalQueries * 1000 / totalTimeMs) : 0,
      'totalTransactions': _totalTransactions,
      'totalTransactionErrors': _totalTransactionErrors,
      'transactionErrorRate': _totalTransactions > 0 ? (_totalTransactionErrors / _totalTransactions) : 0,
      'monitoringTime': _formatDuration(now.difference(_firstQueryTime)),
      'lastQueryTime': _lastQueryTime.toString(),
    };
  }

  /// Retorna as estatísticas das consultas mais lentas
  List<Map<String, dynamic>> getSlowestQueries({int limit = 10}) {
    final stats = _queryStats.values.toList();
    stats.sort((a, b) => b.avgDuration.compareTo(a.avgDuration));
    
    return stats.take(limit).map((stat) => {
      'query': stat.query,
      'count': stat.count,
      'avgDurationMs': stat.avgDuration,
      'maxDurationMs': stat.maxDuration,
      'minDurationMs': stat.minDuration,
      'errorCount': stat.errorCount,
      'errorRate': stat.count > 0 ? (stat.errorCount / stat.count) : 0,
    }).toList();
  }

  /// Retorna as consultas mais frequentes
  List<Map<String, dynamic>> getMostFrequentQueries({int limit = 10}) {
    final stats = _queryStats.values.toList();
    stats.sort((a, b) => b.count.compareTo(a.count));
    
    return stats.take(limit).map((stat) => {
      'query': stat.query,
      'count': stat.count,
      'avgDurationMs': stat.avgDuration,
      'maxDurationMs': stat.maxDuration,
      'minDurationMs': stat.minDuration,
      'errorCount': stat.errorCount,
      'errorRate': stat.count > 0 ? (stat.errorCount / stat.count) : 0,
    }).toList();
  }

  /// Retorna as consultas com mais erros
  List<Map<String, dynamic>> getMostErrorProneQueries({int limit = 10}) {
    final stats = _queryStats.values.where((stat) => stat.errorCount > 0).toList();
    stats.sort((a, b) => b.errorCount.compareTo(a.errorCount));
    
    return stats.take(limit).map((stat) => {
      'query': stat.query,
      'count': stat.count,
      'errorCount': stat.errorCount,
      'errorRate': stat.count > 0 ? (stat.errorCount / stat.count) : 0,
      'avgDurationMs': stat.avgDuration,
    }).toList();
  }

  /// Retorna as consultas lentas recentes
  List<Map<String, dynamic>> getRecentSlowQueries({int limit = 10}) {
    final queries = _slowQueries.reversed.take(limit).toList();
    
    return queries.map((query) => {
      'query': query.query,
      'params': query.params,
      'durationMs': query.duration.inMilliseconds,
      'timestamp': query.startTime.toString(),
      'error': query.error?.toString(),
    }).toList();
  }

  /// Limpa todas as estatísticas
  void reset() {
    _queryStats.clear();
    _recentQueries.clear();
    _slowQueries.clear();
    _totalQueries = 0;
    _totalErrors = 0;
    _totalSlowQueries = 0;
    _totalTransactions = 0;
    _totalTransactionErrors = 0;
    _firstQueryTime = DateTime.now();
    _lastQueryTime = DateTime.now();
  }

  /// Normaliza uma consulta SQL para agrupar consultas semelhantes
  String _normalizeQuery(String query) {
    // Remove espaços extras e quebras de linha
    var normalized = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove valores literais para agrupar consultas semelhantes
    normalized = normalized.replaceAll(RegExp(r"'[^']*'"), '?');
    normalized = normalized.replaceAll(RegExp(r'"[^"]*"'), '?');
    normalized = normalized.replaceAll(RegExp(r'\d+'), '?');
    
    return normalized;
  }

  /// Formata uma duração para exibição
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Estatísticas de uma consulta SQL
class _QueryStats {
  final String query;
  int count = 0;
  int totalDuration = 0;
  int maxDuration = 0;
  int minDuration = 0;
  int errorCount = 0;
  
  _QueryStats({required this.query});
  
  /// Duração média da consulta em milissegundos
  double get avgDuration => count > 0 ? (totalDuration / count) : 0;
}

/// Execução de uma consulta SQL
class _QueryExecution {
  final String id;
  final String query;
  final Map<String, dynamic>? params;
  final DateTime startTime;
  DateTime? endTime;
  dynamic error;
  bool success = false;
  
  _QueryExecution({
    required this.id,
    required this.query,
    this.params,
    required this.startTime,
  });
  
  /// Duração da consulta
  Duration get duration {
    return endTime != null 
        ? endTime!.difference(startTime) 
        : Duration.zero;
  }
}
