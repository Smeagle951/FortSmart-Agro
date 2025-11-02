import 'package:sqflite/sqflite.dart';
import '../models/soil_compaction_model.dart';
import '../../../services/database_service.dart';
import 'package:flutter/foundation.dart';

class SoilCompactionRepository extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  // Inicializa a tabela de compactação do solo
  Future<void> initTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS compactacao_solo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER,
        safra_id INTEGER,
        data TEXT,
        latitude REAL,
        longitude REAL,
        tipo_calculo TEXT,
        peso_martelo REAL,
        altura_queda REAL,
        diametro_ponteira REAL,
        angulo_ponteira REAL,
        num_golpes INTEGER,
        distancia_total REAL,
        resultado_rp REAL,
        interpretacao TEXT,
        profundidade REAL,
        foto_caminho TEXT
      )
    ''');
  }

  // Insere um novo registro de compactação do solo
  Future<int> insert(SoilCompactionModel compactacao) async {
    try {
      await initTable();
      final db = await _databaseService.database;
      final id = await db.insert(
        'compactacao_solo',
        compactacao.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      notifyListeners();
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inserir compactação do solo: $e');
      }
      return -1;
    }
  }

  // Atualiza um registro existente
  Future<int> update(SoilCompactionModel compactacao) async {
    try {
      final db = await _databaseService.database;
      final result = await db.update(
        'compactacao_solo',
        compactacao.toMap(),
        where: 'id = ?',
        whereArgs: [compactacao.id],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar compactação do solo: $e');
      }
      return -1;
    }
  }

  // Exclui um registro
  Future<int> delete(int id) async {
    try {
      final db = await _databaseService.database;
      final result = await db.delete(
        'compactacao_solo',
        where: 'id = ?',
        whereArgs: [id],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao excluir compactação do solo: $e');
      }
      return -1;
    }
  }

  // Busca todos os registros
  Future<List<SoilCompactionModel>> getAll() async {
    try {
      await initTable();
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query('compactacao_solo');
      return List.generate(maps.length, (i) {
        return SoilCompactionModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar compactações do solo: $e');
      }
      return [];
    }
  }

  // Busca um registro pelo ID
  Future<SoilCompactionModel?> getById(int id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_solo',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return SoilCompactionModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar compactação do solo por ID: $e');
      }
      return null;
    }
  }

  // Busca registros por talhão
  Future<List<SoilCompactionModel>> getByTalhao(int talhaoId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_solo',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar compactações do solo por talhão: $e');
      }
      return [];
    }
  }

  // Salva os dados de compactação
  Future<int> saveCompactionData(Map<String, dynamic> data) async {
    try {
      final db = await _databaseService.database;
      final id = await db.insert('compactacao_solo', data);
      notifyListeners();
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar dados de compactação: $e');
      }
      throw Exception('Falha ao salvar dados: $e');
    }
  }

  // Busca registros por safra
  Future<List<SoilCompactionModel>> getBySafra(int safraId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_solo',
        where: 'safra_id = ?',
        whereArgs: [safraId],
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar compactações do solo por safra: $e');
      }
      return [];
    }
  }

  // Busca registros por talhão e safra
  Future<List<SoilCompactionModel>> getByTalhaoAndSafra(int talhaoId, int safraId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_solo',
        where: 'talhao_id = ? AND safra_id = ?',
        whereArgs: [talhaoId, safraId],
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar compactações do solo por talhão e safra: $e');
      }
      return [];
    }
  }
}
