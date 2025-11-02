/// 🌱 DAO para Testes de Germinação
/// 
/// Implementa operações CRUD para testes de germinação seguindo
/// metodologias agronômicas (ABNT NBR 9787)

import 'package:sqflite/sqflite.dart';
import '../../models/germination_test_model.dart';

class GerminationTestDao {
  final Database _database;

  GerminationTestDao(this._database);

  /// Cria um novo teste de germinação
  Future<int> insert(GerminationTest test) async {
    try {
      final id = await _database.insert(
        'germination_tests',
        test.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Erro ao criar teste de germinação: $e');
    }
  }

  /// Busca um teste por ID
  Future<GerminationTest?> findById(int id) async {
    try {
      final maps = await _database.query(
        'germination_tests',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return GerminationTest.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar teste: $e');
    }
  }

  /// Busca todos os testes
  Future<List<GerminationTest>> findAll() async {
    try {
      final maps = await _database.query(
        'germination_tests',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes: $e');
    }
  }

  /// Busca testes por status
  Future<List<GerminationTest>> findByStatus(String status) async {
    try {
      final maps = await _database.query(
        'germination_tests',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes por status: $e');
    }
  }

  /// Busca testes por cultura
  Future<List<GerminationTest>> findByCulture(String culture) async {
    try {
      final maps = await _database.query(
        'germination_tests',
        where: 'culture = ?',
        whereArgs: [culture],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes por cultura: $e');
    }
  }

  /// Busca testes por lote
  Future<List<GerminationTest>> findBySeedLot(String seedLot) async {
    try {
      final maps = await _database.query(
        'germination_tests',
        where: 'seedLot = ?',
        whereArgs: [seedLot],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes por lote: $e');
    }
  }

  /// Busca testes com filtros
  Future<List<GerminationTest>> findWithFilters({
    String? culture,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchText,
  }) async {
    try {
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (culture != null && culture.isNotEmpty) {
        whereClause += ' AND culture = ?';
        whereArgs.add(culture);
      }

      if (status != null && status.isNotEmpty) {
        whereClause += ' AND status = ?';
        whereArgs.add(status);
      }

      if (startDate != null) {
        whereClause += ' AND startDate >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND startDate <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (searchText != null && searchText.isNotEmpty) {
        whereClause += ' AND (culture LIKE ? OR variety LIKE ? OR seedLot LIKE ?)';
        final searchPattern = '%$searchText%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      final maps = await _database.query(
        'germination_tests',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes com filtros: $e');
    }
  }

  /// Atualiza um teste
  Future<int> update(GerminationTest test) async {
    try {
      final updatedTest = test.copyWith(updatedAt: DateTime.now());
      
      final result = await _database.update(
        'germination_tests',
        updatedTest.toMap(),
        where: 'id = ?',
        whereArgs: [test.id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar teste: $e');
    }
  }

  /// Atualiza o status de um teste
  Future<int> updateStatus(int id, String status) async {
    try {
      final result = await _database.update(
        'germination_tests',
        {
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar status do teste: $e');
    }
  }

  /// Atualiza os resultados finais de um teste
  Future<int> updateResults(int id, {
    double? finalGerminationPercentage,
    double? purityPercentage,
    double? diseasedPercentage,
    double? culturalValue,
    double? averageGerminationTime,
    int? firstCountDay,
    int? day50PercentGermination,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (finalGerminationPercentage != null) {
        updateData['finalGerminationPercentage'] = finalGerminationPercentage;
      }
      if (purityPercentage != null) {
        updateData['purityPercentage'] = purityPercentage;
      }
      if (diseasedPercentage != null) {
        updateData['diseasedPercentage'] = diseasedPercentage;
      }
      if (culturalValue != null) {
        updateData['culturalValue'] = culturalValue;
      }
      if (averageGerminationTime != null) {
        updateData['averageGerminationTime'] = averageGerminationTime;
      }
      if (firstCountDay != null) {
        updateData['firstCountDay'] = firstCountDay;
      }
      if (day50PercentGermination != null) {
        updateData['day50PercentGermination'] = day50PercentGermination;
      }

      final result = await _database.update(
        'germination_tests',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar resultados do teste: $e');
    }
  }

  /// Exclui um teste
  Future<int> delete(int id) async {
    try {
      final result = await _database.delete(
        'germination_tests',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir teste: $e');
    }
  }

  /// Exclui todos os testes
  Future<int> deleteAll() async {
    try {
      final result = await _database.delete('germination_tests');
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir todos os testes: $e');
    }
  }

  /// Conta o total de testes
  Future<int> count() async {
    try {
      final result = await _database.rawQuery('SELECT COUNT(*) as count FROM germination_tests');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar testes: $e');
    }
  }

  /// Conta testes por status
  Future<Map<String, int>> countByStatus() async {
    try {
      final result = await _database.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM germination_tests 
        GROUP BY status
      ''');
      
      final counts = <String, int>{};
      for (final row in result) {
        counts[row['status'] as String] = row['count'] as int;
      }
      
      return counts;
    } catch (e) {
      throw Exception('Erro ao contar testes por status: $e');
    }
  }

  /// Conta testes por cultura
  Future<Map<String, int>> countByCulture() async {
    try {
      final result = await _database.rawQuery('''
        SELECT culture, COUNT(*) as count 
        FROM germination_tests 
        GROUP BY culture
        ORDER BY count DESC
      ''');
      
      final counts = <String, int>{};
      for (final row in result) {
        counts[row['culture'] as String] = row['count'] as int;
      }
      
      return counts;
    } catch (e) {
      throw Exception('Erro ao contar testes por cultura: $e');
    }
  }

  /// Obtém estatísticas de germinação por cultura
  Future<Map<String, dynamic>> getGerminationStatisticsByCulture(String culture) async {
    try {
      final result = await _database.rawQuery('''
        SELECT 
          AVG(finalGerminationPercentage) as avgGermination,
          MIN(finalGerminationPercentage) as minGermination,
          MAX(finalGerminationPercentage) as maxGermination,
          COUNT(*) as totalTests
        FROM germination_tests 
        WHERE culture = ? AND finalGerminationPercentage IS NOT NULL
      ''', [culture]);
      
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'culture': culture,
          'avgGermination': row['avgGermination'] as double? ?? 0.0,
          'minGermination': row['minGermination'] as double? ?? 0.0,
          'maxGermination': row['maxGermination'] as double? ?? 0.0,
          'totalTests': row['totalTests'] as int? ?? 0,
        };
      }
      
      return {
        'culture': culture,
        'avgGermination': 0.0,
        'minGermination': 0.0,
        'maxGermination': 0.0,
        'totalTests': 0,
      };
    } catch (e) {
      throw Exception('Erro ao obter estatísticas de germinação: $e');
    }
  }

  /// Obtém testes recentes
  Future<List<GerminationTest>> findRecent({int limit = 10}) async {
    try {
      final maps = await _database.query(
        'germination_tests',
        orderBy: 'createdAt DESC',
        limit: limit,
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes recentes: $e');
    }
  }

  /// Obtém testes ativos
  Future<List<GerminationTest>> findActive() async {
    try {
      final maps = await _database.query(
        'germination_tests',
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes ativos: $e');
    }
  }

  /// Obtém testes completos
  Future<List<GerminationTest>> findCompleted() async {
    try {
      final maps = await _database.query(
        'germination_tests',
        where: 'status = ?',
        whereArgs: ['completed'],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationTest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar testes completos: $e');
    }
  }

  /// Verifica se existe um teste com o mesmo lote
  Future<bool> existsBySeedLot(String seedLot) async {
    try {
      final result = await _database.rawQuery('''
        SELECT COUNT(*) as count FROM germination_tests 
        WHERE seedLot = ?
      ''', [seedLot]);
      
      return (Sqflite.firstIntValue(result) ?? 0) > 0;
    } catch (e) {
      throw Exception('Erro ao verificar existência do lote: $e');
    }
  }

  /// Obtém o próximo ID disponível
  Future<int> getNextId() async {
    try {
      final result = await _database.rawQuery('SELECT MAX(id) as maxId FROM germination_tests');
      final maxId = Sqflite.firstIntValue(result) ?? 0;
      return maxId + 1;
    } catch (e) {
      throw Exception('Erro ao obter próximo ID: $e');
    }
  }
}
