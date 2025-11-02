import 'package:sqflite/sqflite.dart';
import '../../models/calibration_history_model.dart';

class CalibrationHistoryDao {
  final Database _database;
  
  CalibrationHistoryDao(this._database);
  
  /// Insere uma nova calibração no histórico
  Future<int> insertCalibration(CalibrationHistoryModel calibration) async {
    try {
      final id = await _database.insert(
        'calibration_history',
        calibration.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Calibração inserida no histórico com ID: $id');
      return id;
    } catch (e) {
      print('❌ Erro ao inserir calibração no histórico: $e');
      rethrow;
    }
  }
  
  /// Busca todas as calibrações
  Future<List<CalibrationHistoryModel>> getAllCalibrations() async {
    try {
      final maps = await _database.query(
        'calibration_history',
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => CalibrationHistoryModel.fromJson(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar calibrações: $e');
      return [];
    }
  }
  
  /// Busca calibrações por talhão
  Future<List<CalibrationHistoryModel>> getCalibrationsByTalhao(String talhaoId) async {
    try {
      final maps = await _database.query(
        'calibration_history',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => CalibrationHistoryModel.fromJson(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar calibrações por talhão: $e');
      return [];
    }
  }
  
  /// Busca calibrações por cultura
  Future<List<CalibrationHistoryModel>> getCalibrationsByCultura(String culturaId) async {
    try {
      final maps = await _database.query(
        'calibration_history',
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => CalibrationHistoryModel.fromJson(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar calibrações por cultura: $e');
      return [];
    }
  }
  
  /// Busca calibrações por status
  Future<List<CalibrationHistoryModel>> getCalibrationsByStatus(String status) async {
    try {
      final maps = await _database.query(
        'calibration_history',
        where: 'status_calibracao = ?',
        whereArgs: [status],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => CalibrationHistoryModel.fromJson(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar calibrações por status: $e');
      return [];
    }
  }
  
  /// Busca calibrações por período
  Future<List<CalibrationHistoryModel>> getCalibrationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final maps = await _database.query(
        'calibration_history',
        where: 'data_calibracao BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => CalibrationHistoryModel.fromJson(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar calibrações por período: $e');
      return [];
    }
  }
  
  /// Busca calibrações com filtros combinados
  Future<List<CalibrationHistoryModel>> getCalibrationsWithFilters({
    String? talhaoId,
    String? culturaId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<String> whereConditions = [];
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereConditions.add('talhao_id = ?');
        whereArgs.add(talhaoId);
      }
      
      if (culturaId != null) {
        whereConditions.add('cultura_id = ?');
        whereArgs.add(culturaId);
      }
      
      if (status != null) {
        whereConditions.add('status_calibracao = ?');
        whereArgs.add(status);
      }
      
      if (startDate != null && endDate != null) {
        whereConditions.add('data_calibracao BETWEEN ? AND ?');
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ]);
      } else if (startDate != null) {
        whereConditions.add('data_calibracao >= ?');
        whereArgs.add(startDate.toIso8601String());
      } else if (endDate != null) {
        whereConditions.add('data_calibracao <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      final whereClause = whereConditions.isNotEmpty 
          ? whereConditions.join(' AND ')
          : null;
      
      final maps = await _database.query(
        'calibration_history',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );
      
      return maps.map((map) => CalibrationHistoryModel.fromJson(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar calibrações com filtros: $e');
      return [];
    }
  }
  
  /// Atualiza uma calibração
  Future<int> updateCalibration(CalibrationHistoryModel calibration) async {
    try {
      final updatedCalibration = calibration.copyWith(
        updatedAt: DateTime.now(),
      );
      
      final count = await _database.update(
        'calibration_history',
        updatedCalibration.toJson(),
        where: 'id = ?',
        whereArgs: [calibration.id],
      );
      
      print('✅ Calibração atualizada: $count registros afetados');
      return count;
    } catch (e) {
      print('❌ Erro ao atualizar calibração: $e');
      rethrow;
    }
  }
  
  /// Remove uma calibração
  Future<int> deleteCalibration(int id) async {
    try {
      final count = await _database.delete(
        'calibration_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('✅ Calibração removida: $count registros afetados');
      return count;
    } catch (e) {
      print('❌ Erro ao remover calibração: $e');
      rethrow;
    }
  }
  
  /// Remove todas as calibrações
  Future<int> deleteAllCalibrations() async {
    try {
      final count = await _database.delete('calibration_history');
      print('✅ Todas as calibrações removidas: $count registros afetados');
      return count;
    } catch (e) {
      print('❌ Erro ao remover todas as calibrações: $e');
      rethrow;
    }
  }
  
  /// Conta o total de calibrações
  Future<int> getTotalCalibrations() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM calibration_history',
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Erro ao contar calibrações: $e');
      return 0;
    }
  }
  
  /// Conta calibrações por status
  Future<Map<String, int>> getCalibrationCountsByStatus() async {
    try {
      final result = await _database.rawQuery(
        '''
        SELECT status_calibracao, COUNT(*) as count 
        FROM calibration_history 
        GROUP BY status_calibracao
        ''',
      );
      
      final Map<String, int> counts = {};
      for (final row in result) {
        counts[row['status_calibracao'] as String] = row['count'] as int;
      }
      
      return counts;
    } catch (e) {
      print('❌ Erro ao contar calibrações por status: $e');
      return {};
    }
  }
  
  /// Busca estatísticas de calibração
  Future<Map<String, dynamic>> getCalibrationStatistics() async {
    try {
      final totalResult = await _database.rawQuery(
        'SELECT COUNT(*) as total FROM calibration_history',
      );
      
      final statusResult = await _database.rawQuery(
        '''
        SELECT status_calibracao, COUNT(*) as count 
        FROM calibration_history 
        GROUP BY status_calibracao
        ''',
      );
      
      final recentResult = await _database.rawQuery(
        '''
        SELECT COUNT(*) as recent 
        FROM calibration_history 
        WHERE created_at >= datetime('now', '-7 days')
        ''',
      );
      
      final Map<String, dynamic> statistics = {
        'total': totalResult.first['total'] as int,
        'recent': recentResult.first['recent'] as int,
        'byStatus': {},
      };
      
      for (final row in statusResult) {
        statistics['byStatus'][row['status_calibracao'] as String] = row['count'] as int;
      }
      
      return statistics;
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return {
        'total': 0,
        'recent': 0,
        'byStatus': {},
      };
    }
  }
}
