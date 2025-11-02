/// 🌱 DAO para Registros Diários de Germinação
/// 
/// Implementa operações CRUD para registros diários de germinação

import 'package:sqflite/sqflite.dart';
import '../../models/germination_test_model.dart';

class GerminationDailyRecordDao {
  final Database _database;

  GerminationDailyRecordDao(this._database);

  /// Cria um novo registro diário
  Future<int> insert(GerminationDailyRecord record) async {
    try {
      final id = await _database.insert(
        'germination_daily_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Erro ao criar registro diário: $e');
    }
  }

  /// Busca um registro por ID
  Future<GerminationDailyRecord?> findById(int id) async {
    try {
      final maps = await _database.query(
        'germination_daily_records',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return GerminationDailyRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar registro diário: $e');
    }
  }

  /// Busca registros por teste
  Future<List<GerminationDailyRecord>> findByTestId(int testId) async {
    try {
      final maps = await _database.query(
        'germination_daily_records',
        where: 'germinationTestId = ?', // Correto: germinationTestId é o nome real da coluna no banco
        whereArgs: [testId],
        orderBy: 'day ASC',
      );

      return maps.map((map) => GerminationDailyRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar registros por teste: $e');
    }
  }

  /// Busca registros por subteste
  Future<List<GerminationDailyRecord>> findBySubtestId(int subtestId) async {
    try {
      final maps = await _database.query(
        'germination_daily_records',
        where: 'subtestId = ?',
        whereArgs: [subtestId],
        orderBy: 'day ASC',
      );

      return maps.map((map) => GerminationDailyRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar registros por subteste: $e');
    }
  }

  /// Busca registros por dia
  Future<List<GerminationDailyRecord>> findByDay(int testId, int day) async {
    try {
      final maps = await _database.query(
        'germination_daily_records',
        where: 'testId = ? AND day = ?',
        whereArgs: [testId, day],
        orderBy: 'recordDate ASC',
      );

      return maps.map((map) => GerminationDailyRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar registros por dia: $e');
    }
  }

  /// Busca todos os registros
  Future<List<GerminationDailyRecord>> findAll() async {
    try {
      final maps = await _database.query(
        'germination_daily_records',
        orderBy: 'recordDate DESC',
      );

      return maps.map((map) => GerminationDailyRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar registros: $e');
    }
  }

  /// Atualiza um registro
  Future<int> update(GerminationDailyRecord record) async {
    try {
      final updatedRecord = record.copyWith(updatedAt: DateTime.now());
      
      final result = await _database.update(
        'germination_daily_records',
        updatedRecord.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar registro: $e');
    }
  }

  /// Exclui um registro
  Future<int> delete(int id) async {
    try {
      final result = await _database.delete(
        'germination_daily_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir registro: $e');
    }
  }

  /// Exclui registros por teste
  Future<int> deleteByTestId(int testId) async {
    try {
      final result = await _database.delete(
        'germination_daily_records',
        where: 'testId = ?',
        whereArgs: [testId],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir registros por teste: $e');
    }
  }

  /// Exclui registros por subteste
  Future<int> deleteBySubtestId(int subtestId) async {
    try {
      final result = await _database.delete(
        'germination_daily_records',
        where: 'subtestId = ?',
        whereArgs: [subtestId],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir registros por subteste: $e');
    }
  }

  /// Conta registros por teste
  Future<int> countByTestId(int testId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT COUNT(*) as count FROM germination_daily_records 
        WHERE testId = ?
      ''', [testId]);
      
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar registros: $e');
    }
  }

  /// Conta registros por subteste
  Future<int> countBySubtestId(int subtestId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT COUNT(*) as count FROM germination_daily_records 
        WHERE subtestId = ?
      ''', [subtestId]);
      
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar registros por subteste: $e');
    }
  }

  /// Obtém o último dia registrado para um teste
  Future<int?> getLastDayByTestId(int testId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT MAX(day) as lastDay FROM germination_daily_records 
        WHERE testId = ?
      ''', [testId]);
      
      return Sqflite.firstIntValue(result);
    } catch (e) {
      throw Exception('Erro ao obter último dia: $e');
    }
  }

  /// Obtém o último dia registrado para um subteste
  Future<int?> getLastDayBySubtestId(int subtestId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT MAX(day) as lastDay FROM germination_daily_records 
        WHERE subtestId = ?
      ''', [subtestId]);
      
      return Sqflite.firstIntValue(result);
    } catch (e) {
      throw Exception('Erro ao obter último dia do subteste: $e');
    }
  }

  /// Verifica se existe registro para um dia específico
  Future<bool> existsByDay(int testId, int day) async {
    try {
      final result = await _database.rawQuery('''
        SELECT COUNT(*) as count FROM germination_daily_records 
        WHERE testId = ? AND day = ?
      ''', [testId, day]);
      
      return (Sqflite.firstIntValue(result) ?? 0) > 0;
    } catch (e) {
      throw Exception('Erro ao verificar existência do registro: $e');
    }
  }

  /// Obtém estatísticas de germinação por teste
  Future<Map<String, dynamic>> getGerminationStatistics(int testId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT 
          SUM(normalGerminated) as totalNormal,
          SUM(abnormalGerminated) as totalAbnormal,
          SUM(diseasedFungi) as totalFungi,
          SUM(diseasedBacteria) as totalBacteria,
          SUM(notGerminated) as totalNotGerminated,
          COUNT(*) as totalRecords
        FROM germination_daily_records 
        WHERE testId = ?
      ''', [testId]);
      
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'totalNormal': row['totalNormal'] as int? ?? 0,
          'totalAbnormal': row['totalAbnormal'] as int? ?? 0,
          'totalFungi': row['totalFungi'] as int? ?? 0,
          'totalBacteria': row['totalBacteria'] as int? ?? 0,
          'totalNotGerminated': row['totalNotGerminated'] as int? ?? 0,
          'totalRecords': row['totalRecords'] as int? ?? 0,
        };
      }
      
      return {
        'totalNormal': 0,
        'totalAbnormal': 0,
        'totalFungi': 0,
        'totalBacteria': 0,
        'totalNotGerminated': 0,
        'totalRecords': 0,
      };
    } catch (e) {
      throw Exception('Erro ao obter estatísticas: $e');
    }
  }

  /// Obtém evolução diária da germinação
  Future<List<Map<String, dynamic>>> getDailyEvolution(int testId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT 
          day,
          recordDate,
          SUM(normalGerminated) as dailyNormal,
          SUM(abnormalGerminated) as dailyAbnormal,
          SUM(diseasedFungi) as dailyFungi,
          SUM(diseasedBacteria) as dailyBacteria,
          SUM(notGerminated) as dailyNotGerminated
        FROM germination_daily_records 
        WHERE testId = ?
        GROUP BY day, recordDate
        ORDER BY day ASC
      ''', [testId]);
      
      return result;
    } catch (e) {
      throw Exception('Erro ao obter evolução diária: $e');
    }
  }
}
