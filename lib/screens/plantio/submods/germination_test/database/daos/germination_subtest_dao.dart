/// 🌱 DAO para Subtestes de Germinação (A, B, C)
/// 
/// Implementa operações CRUD para subtestes de germinação

import 'package:sqflite/sqflite.dart';
import '../../models/germination_test_model.dart';

class GerminationSubtestDao {
  final Database _database;

  GerminationSubtestDao(this._database);

  /// Cria um novo subteste
  Future<int> insert(GerminationSubtest subtest) async {
    try {
      final id = await _database.insert(
        'germination_subtests',
        subtest.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Erro ao criar subteste: $e');
    }
  }

  /// Busca um subteste por ID
  Future<GerminationSubtest?> findById(int id) async {
    try {
      final maps = await _database.query(
        'germination_subtests',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return GerminationSubtest.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar subteste: $e');
    }
  }

  /// Busca subtestes por teste principal
  Future<List<GerminationSubtest>> findByTestId(int testId) async {
    try {
      final maps = await _database.query(
        'germination_subtests',
        where: 'germinationTestId = ?',
        whereArgs: [testId],
        orderBy: 'subtestCode ASC',
      );

      return maps.map((map) => GerminationSubtest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar subtestes por teste: $e');
    }
  }

  /// Busca subteste por código (A, B, C)
  Future<GerminationSubtest?> findByCode(int testId, String code) async {
    try {
      final maps = await _database.query(
        'germination_subtests',
        where: 'germinationTestId = ? AND subtestCode = ?',
        whereArgs: [testId, code],
      );

      if (maps.isNotEmpty) {
        return GerminationSubtest.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar subteste por código: $e');
    }
  }

  /// Busca todos os subtestes
  Future<List<GerminationSubtest>> findAll() async {
    try {
      final maps = await _database.query(
        'germination_subtests',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => GerminationSubtest.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar subtestes: $e');
    }
  }

  /// Atualiza um subteste
  Future<int> update(GerminationSubtest subtest) async {
    try {
      final updatedSubtest = subtest.copyWith(updatedAt: DateTime.now());
      
      final result = await _database.update(
        'germination_subtests',
        updatedSubtest.toMap(),
        where: 'id = ?',
        whereArgs: [subtest.id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar subteste: $e');
    }
  }

  /// Atualiza o status de um subteste
  Future<int> updateStatus(int id, String status) async {
    try {
      final result = await _database.update(
        'germination_subtests',
        {
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao atualizar status do subteste: $e');
    }
  }

  /// Exclui um subteste
  Future<int> delete(int id) async {
    try {
      final result = await _database.delete(
        'germination_subtests',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir subteste: $e');
    }
  }

  /// Exclui subtestes por teste principal
  Future<int> deleteByTestId(int testId) async {
    try {
      final result = await _database.delete(
        'germination_subtests',
        where: 'germinationTestId = ?',
        whereArgs: [testId],
      );
      
      return result;
    } catch (e) {
      throw Exception('Erro ao excluir subtestes por teste: $e');
    }
  }

  /// Conta subtestes por teste
  Future<int> countByTestId(int testId) async {
    try {
      final result = await _database.rawQuery('''
        SELECT COUNT(*) as count FROM germination_subtests 
        WHERE germinationTestId = ?
      ''', [testId]);
      
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar subtestes: $e');
    }
  }

  /// Verifica se existe subteste com código específico
  Future<bool> existsByCode(int testId, String code) async {
    try {
      final result = await _database.rawQuery('''
        SELECT COUNT(*) as count FROM germination_subtests 
        WHERE germinationTestId = ? AND subtestCode = ?
      ''', [testId, code]);
      
      return (Sqflite.firstIntValue(result) ?? 0) > 0;
    } catch (e) {
      throw Exception('Erro ao verificar existência do subteste: $e');
    }
  }

  /// Obtém códigos de subtestes disponíveis para um teste
  Future<List<String>> getAvailableCodes(int testId) async {
    try {
      final usedCodes = await _database.rawQuery('''
        SELECT subtestCode FROM germination_subtests 
        WHERE germinationTestId = ?
      ''', [testId]);
      
      final allCodes = ['A', 'B', 'C'];
      final usedCodesList = usedCodes.map((row) => row['subtestCode'] as String).toList();
      
      return allCodes.where((code) => !usedCodesList.contains(code)).toList();
    } catch (e) {
      throw Exception('Erro ao obter códigos disponíveis: $e');
    }
  }
}
