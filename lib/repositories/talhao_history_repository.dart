import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/talhao_history_entry.dart';
import '../utils/logger.dart';

/// Repositório para gerenciar histórico de talhões
class TalhaoHistoryRepository {
  final AppDatabase _database = AppDatabase.instance;
  
  /// Adiciona uma entrada de histórico
  Future<void> addHistoryEntry(TalhaoHistoryEntry entry) async {
    try {
      final db = await _database.database;
      await db.insert(
        'talhao_history',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('Entrada de histórico adicionada: ${entry.id}');
    } catch (e) {
      Logger.error('Erro ao adicionar entrada de histórico: $e');
      rethrow;
    }
  }
  
  /// Obtém histórico de um talhão
  Future<List<TalhaoHistoryEntry>> getTalhaoHistory(
    String talhaoId, {
    DateTime? startDate,
    DateTime? endDate,
    String? action,
    int limit = 50,
  }) async {
    try {
      final db = await _database.database;
      
      String whereClause = 'talhaoId = ?';
      List<dynamic> whereArgs = [talhaoId];
      
      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      if (action != null) {
        whereClause += ' AND action = ?';
        whereArgs.add(action);
      }
      
      final results = await db.query(
        'talhao_history',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      
      return results.map((row) => TalhaoHistoryEntry.fromMap(row)).toList();
    } catch (e) {
      Logger.error('Erro ao obter histórico do talhão: $e');
      return [];
    }
  }
  
  /// Obtém todas as entradas de histórico
  Future<List<TalhaoHistoryEntry>> getAllHistory({int limit = 100}) async {
    try {
      final db = await _database.database;
      
      final results = await db.query(
        'talhao_history',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      
      return results.map((row) => TalhaoHistoryEntry.fromMap(row)).toList();
    } catch (e) {
      Logger.error('Erro ao obter todo o histórico: $e');
      return [];
    }
  }
  
  /// Remove entradas antigas
  Future<int> deleteOldEntries(DateTime cutoffDate) async {
    try {
      final db = await _database.database;
      
      final deletedCount = await db.delete(
        'talhao_history',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      Logger.info('Removidas $deletedCount entradas antigas de histórico');
      return deletedCount;
    } catch (e) {
      Logger.error('Erro ao remover entradas antigas: $e');
      return 0;
    }
  }
  
  /// Remove histórico de um talhão específico
  Future<int> deleteTalhaoHistory(String talhaoId) async {
    try {
      final db = await _database.database;
      
      final deletedCount = await db.delete(
        'talhao_history',
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
      );
      
      Logger.info('Removido histórico do talhão $talhaoId: $deletedCount entradas');
      return deletedCount;
    } catch (e) {
      Logger.error('Erro ao remover histórico do talhão: $e');
      return 0;
    }
  }
  
  /// Obtém estatísticas de histórico
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      final db = await _database.database;
      
      // Total de entradas
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM talhao_history');
      final total = totalResult.first['total'] as int;
      
      // Entradas por ação
      final actionResult = await db.rawQuery('''
        SELECT action, COUNT(*) as count 
        FROM talhao_history 
        GROUP BY action 
        ORDER BY count DESC
      ''');
      
      // Entradas por usuário
      final userResult = await db.rawQuery('''
        SELECT userId, COUNT(*) as count 
        FROM talhao_history 
        GROUP BY userId 
        ORDER BY count DESC
      ''');
      
      // Entrada mais antiga
      final oldestResult = await db.rawQuery('''
        SELECT timestamp 
        FROM talhao_history 
        ORDER BY timestamp ASC 
        LIMIT 1
      ''');
      
      // Entrada mais recente
      final newestResult = await db.rawQuery('''
        SELECT timestamp 
        FROM talhao_history 
        ORDER BY timestamp DESC 
        LIMIT 1
      ''');
      
      return {
        'totalEntries': total,
        'actions': actionResult.map((row) => {
          'action': row['action'],
          'count': row['count'],
        }).toList(),
        'users': userResult.map((row) => {
          'userId': row['userId'],
          'count': row['count'],
        }).toList(),
        'oldestEntry': oldestResult.isNotEmpty ? oldestResult.first['timestamp'] : null,
        'newestEntry': newestResult.isNotEmpty ? newestResult.first['timestamp'] : null,
      };
    } catch (e) {
      Logger.error('Erro ao obter estatísticas de histórico: $e');
      return {};
    }
  }
} 