import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/talhao_model.dart';
import '../utils/logger.dart';

/// Serviço de histórico de alterações para talhões
class TalhaoHistoryService {
  static final TalhaoHistoryService _instance = TalhaoHistoryService._internal();
  factory TalhaoHistoryService() => _instance;
  TalhaoHistoryService._internal();

  static const String _historyKey = 'talhao_history';
  static const int _maxHistoryEntries = 1000; // Máximo de entradas no histórico
  static const Duration _historyRetention = Duration(days: 90); // Retenção de 90 dias
  
  // Stream para notificar mudanças no histórico
  final _historyController = StreamController<List<TalhaoHistoryEntry>>.broadcast();
  Stream<List<TalhaoHistoryEntry>> get historyStream => _historyController.stream;
  
  /// Adiciona uma entrada ao histórico
  Future<void> addHistoryEntry({
    required String talhaoId,
    required String talhaoName,
    required TalhaoHistoryAction action,
    required Map<String, dynamic> changes,
    String? userId,
    String? notes,
  }) async {
    try {
      final entry = TalhaoHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: talhaoId,
        talhaoName: talhaoName,
        action: action,
        changes: changes,
        userId: userId,
        notes: notes,
        timestamp: DateTime.now(),
      );
      
      final history = await _getHistory();
      history.insert(0, entry); // Adicionar no início
      
      // Limitar número de entradas
      if (history.length > _maxHistoryEntries) {
        history.removeRange(_maxHistoryEntries, history.length);
      }
      
      await _saveHistory(history);
      
      // Notificar mudanças
      _historyController.add(history);
      
      Logger.info('📝 [HISTORY] Entrada adicionada: ${action.name} para talhão $talhaoName');
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao adicionar entrada: $e');
    }
  }
  
  /// Obtém histórico de um talhão específico
  Future<List<TalhaoHistoryEntry>> getTalhaoHistory(String talhaoId) async {
    try {
      final history = await _getHistory();
      return history.where((entry) => entry.talhaoId == talhaoId).toList();
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao obter histórico do talhão: $e');
      return [];
    }
  }
  
  /// Obtém histórico geral
  Future<List<TalhaoHistoryEntry>> getHistory({
    int? limit,
    DateTime? since,
    TalhaoHistoryAction? action,
  }) async {
    try {
      var history = await _getHistory();
      
      // Filtrar por data
      if (since != null) {
        history = history.where((entry) => entry.timestamp.isAfter(since)).toList();
      }
      
      // Filtrar por ação
      if (action != null) {
        history = history.where((entry) => entry.action == action).toList();
      }
      
      // Limitar resultados
      if (limit != null && limit > 0) {
        history = history.take(limit).toList();
      }
      
      return history;
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao obter histórico: $e');
      return [];
    }
  }
  
  /// Obtém estatísticas do histórico
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      final history = await _getHistory();
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final last7Days = now.subtract(const Duration(days: 7));
      
      // Contar por ação
      final actionCounts = <TalhaoHistoryAction, int>{};
      for (final entry in history) {
        actionCounts[entry.action] = (actionCounts[entry.action] ?? 0) + 1;
      }
      
      // Contar por período
      final last30DaysCount = history.where((e) => e.timestamp.isAfter(last30Days)).length;
      final last7DaysCount = history.where((e) => e.timestamp.isAfter(last7Days)).length;
      
      // Talhões mais modificados
      final talhaoCounts = <String, int>{};
      for (final entry in history) {
        talhaoCounts[entry.talhaoId] = (talhaoCounts[entry.talhaoId] ?? 0) + 1;
      }
      
      final mostModifiedTalhoes = talhaoCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'total_entries': history.length,
        'last_30_days': last30DaysCount,
        'last_7_days': last7DaysCount,
        'action_counts': actionCounts.map((k, v) => MapEntry(k.name, v)),
        'most_modified_talhoes': mostModifiedTalhoes.take(5).map((e) => {
          'talhao_id': e.key,
          'count': e.value,
        }).toList(),
        'oldest_entry': history.isNotEmpty ? history.last.timestamp : null,
        'newest_entry': history.isNotEmpty ? history.first.timestamp : null,
      };
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Limpa histórico antigo
  Future<void> cleanupOldHistory() async {
    try {
      final history = await _getHistory();
      final cutoffDate = DateTime.now().subtract(_historyRetention);
      
      final filteredHistory = history.where((entry) => 
        entry.timestamp.isAfter(cutoffDate)
      ).toList();
      
      if (filteredHistory.length != history.length) {
        await _saveHistory(filteredHistory);
        Logger.info('🧹 [HISTORY] ${history.length - filteredHistory.length} entradas antigas removidas');
      }
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao limpar histórico: $e');
    }
  }
  
  /// Exporta histórico para JSON
  Future<String> exportHistory({
    String? talhaoId,
    DateTime? since,
    DateTime? until,
  }) async {
    try {
      var history = await _getHistory();
      
      // Filtrar por talhão
      if (talhaoId != null) {
        history = history.where((entry) => entry.talhaoId == talhaoId).toList();
      }
      
      // Filtrar por data
      if (since != null) {
        history = history.where((entry) => entry.timestamp.isAfter(since)).toList();
      }
      
      if (until != null) {
        history = history.where((entry) => entry.timestamp.isBefore(until)).toList();
      }
      
      // Converter para JSON
      final exportData = {
        'export_info': {
          'exported_at': DateTime.now().toIso8601String(),
          'total_entries': history.length,
          'filters': {
            'talhao_id': talhaoId,
            'since': since?.toIso8601String(),
            'until': until?.toIso8601String(),
          },
        },
        'history': history.map((entry) => entry.toMap()).toList(),
      };
      
      return jsonEncode(exportData);
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao exportar histórico: $e');
      return '{}';
    }
  }
  
  /// Importa histórico de JSON
  Future<bool> importHistory(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      
      if (data['history'] is! List) {
        Logger.error('❌ [HISTORY] Formato de importação inválido');
        return false;
      }
      
      final importedEntries = (data['history'] as List)
          .map((entryData) => TalhaoHistoryEntry.fromMap(entryData))
          .toList();
      
      final currentHistory = await _getHistory();
      currentHistory.addAll(importedEntries);
      
      // Ordenar por timestamp
      currentHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      await _saveHistory(currentHistory);
      
      // Notificar mudanças
      _historyController.add(currentHistory);
      
      Logger.info('✅ [HISTORY] ${importedEntries.length} entradas importadas');
      return true;
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao importar histórico: $e');
      return false;
    }
  }
  
  /// Obtém histórico do armazenamento
  Future<List<TalhaoHistoryEntry>> _getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) {
        return [];
      }
      
      final historyData = jsonDecode(historyJson) as List;
      return historyData.map((data) => TalhaoHistoryEntry.fromMap(data)).toList();
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao carregar histórico: $e');
      return [];
    }
  }
  
  /// Salva histórico no armazenamento
  Future<void> _saveHistory(List<TalhaoHistoryEntry> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(history.map((entry) => entry.toMap()).toList());
      await prefs.setString(_historyKey, historyJson);
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao salvar histórico: $e');
    }
  }
  
  /// Limpa todo o histórico
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      // Notificar mudanças
      _historyController.add([]);
      
      Logger.info('🗑️ [HISTORY] Histórico limpo');
      
    } catch (e) {
      Logger.error('❌ [HISTORY] Erro ao limpar histórico: $e');
    }
  }
  
  /// Para o serviço
  void dispose() {
    _historyController.close();
  }
}

/// Tipos de ações no histórico
enum TalhaoHistoryAction {
  created,
  updated,
  deleted,
  restored,
  duplicated,
  imported,
  exported,
  merged,
  split,
}

/// Entrada do histórico
class TalhaoHistoryEntry {
  final String id;
  final String talhaoId;
  final String talhaoName;
  final TalhaoHistoryAction action;
  final Map<String, dynamic> changes;
  final String? userId;
  final String? notes;
  final DateTime timestamp;
  
  TalhaoHistoryEntry({
    required this.id,
    required this.talhaoId,
    required this.talhaoName,
    required this.action,
    required this.changes,
    this.userId,
    this.notes,
    required this.timestamp,
  });
  
  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_name': talhaoName,
      'action': action.name,
      'changes': changes,
      'user_id': userId,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Cria a partir de Map
  factory TalhaoHistoryEntry.fromMap(Map<String, dynamic> map) {
    return TalhaoHistoryEntry(
      id: map['id'],
      talhaoId: map['talhao_id'],
      talhaoName: map['talhao_name'],
      action: TalhaoHistoryAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => TalhaoHistoryAction.updated,
      ),
      changes: Map<String, dynamic>.from(map['changes'] ?? {}),
      userId: map['user_id'],
      notes: map['notes'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
  
  /// Obtém descrição da ação
  String get actionDescription {
    switch (action) {
      case TalhaoHistoryAction.created:
        return 'Criado';
      case TalhaoHistoryAction.updated:
        return 'Atualizado';
      case TalhaoHistoryAction.deleted:
        return 'Excluído';
      case TalhaoHistoryAction.restored:
        return 'Restaurado';
      case TalhaoHistoryAction.duplicated:
        return 'Duplicado';
      case TalhaoHistoryAction.imported:
        return 'Importado';
      case TalhaoHistoryAction.exported:
        return 'Exportado';
      case TalhaoHistoryAction.merged:
        return 'Mesclado';
      case TalhaoHistoryAction.split:
        return 'Dividido';
    }
  }
  
  /// Obtém ícone da ação
  IconData get actionIcon {
    switch (action) {
      case TalhaoHistoryAction.created:
        return Icons.add_circle;
      case TalhaoHistoryAction.updated:
        return Icons.edit;
      case TalhaoHistoryAction.deleted:
        return Icons.delete;
      case TalhaoHistoryAction.restored:
        return Icons.restore;
      case TalhaoHistoryAction.duplicated:
        return Icons.copy;
      case TalhaoHistoryAction.imported:
        return Icons.download;
      case TalhaoHistoryAction.exported:
        return Icons.upload;
      case TalhaoHistoryAction.merged:
        return Icons.merge;
      case TalhaoHistoryAction.split:
        return Icons.call_split;
    }
  }
  
  /// Obtém cor da ação
  Color get actionColor {
    switch (action) {
      case TalhaoHistoryAction.created:
        return Colors.green;
      case TalhaoHistoryAction.updated:
        return Colors.blue;
      case TalhaoHistoryAction.deleted:
        return Colors.red;
      case TalhaoHistoryAction.restored:
        return Colors.orange;
      case TalhaoHistoryAction.duplicated:
        return Colors.purple;
      case TalhaoHistoryAction.imported:
        return Colors.teal;
      case TalhaoHistoryAction.exported:
        return Colors.indigo;
      case TalhaoHistoryAction.merged:
        return Colors.amber;
      case TalhaoHistoryAction.split:
        return Colors.cyan;
    }
  }
} 