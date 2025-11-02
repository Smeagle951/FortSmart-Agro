import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/seed_calculation.dart';
import '../utils/logger.dart';

class SeedCalculationRepository {
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'seed_calculations';

  Future<Database> get database async => await _appDatabase.database;

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER NOT NULL,
        cultura_id INTEGER NOT NULL,
        variedade_id INTEGER NOT NULL,
        populacao REAL NOT NULL,
        peso_mil_sementes REAL NOT NULL,
        germinacao REAL NOT NULL,
        pureza REAL NOT NULL,
        tipo_calculo TEXT NOT NULL,
        resultado_kg_hectare REAL NOT NULL,
        resultado_semente_metro REAL NOT NULL,
        observacoes TEXT,
        fotos TEXT,
        data_calculo TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (talhao_id) REFERENCES plots(id),
        FOREIGN KEY (cultura_id) REFERENCES crops(id),
        FOREIGN KEY (variedade_id) REFERENCES variedades(id)
      )
    ''');
  }

  Future<int> insert(SeedCalculation calculation) async {
    try {
      final db = await database;
      return await db.insert(tableName, calculation.toMap());
    } catch (e) {
      Logger.error('Erro ao inserir cálculo de sementes: $e');
      throw Exception('Erro ao salvar cálculo de sementes: $e');
    }
  }

  Future<int> update(SeedCalculation calculation) async {
    try {
      final db = await database;
      return await db.update(
        tableName,
        calculation.toMap(),
        where: 'id = ?',
        whereArgs: [calculation.id],
      );
    } catch (e) {
      Logger.error('Erro ao atualizar cálculo de sementes: $e');
      throw Exception('Erro ao atualizar cálculo de sementes: $e');
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await database;
      return await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      Logger.error('Erro ao excluir cálculo de sementes: $e');
      throw Exception('Erro ao excluir cálculo de sementes: $e');
    }
  }

  Future<SeedCalculation?> getById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return SeedCalculation.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao buscar cálculo de sementes: $e');
      throw Exception('Erro ao buscar cálculo de sementes: $e');
    }
  }

  Future<List<SeedCalculation>> getAll() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'created_at DESC');
      return List.generate(maps.length, (i) => SeedCalculation.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar cálculos de sementes: $e');
      return [];
    }
  }

  Future<List<SeedCalculation>> getByTalhaoId(int talhaoId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => SeedCalculation.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar cálculos por talhão: $e');
      return [];
    }
  }

  Future<List<SeedCalculation>> getByCulturaId(int culturaId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => SeedCalculation.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar cálculos por cultura: $e');
      return [];
    }
  }

  Future<List<SeedCalculation>> getByVariedadeId(int variedadeId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'variedade_id = ?',
        whereArgs: [variedadeId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => SeedCalculation.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar cálculos por variedade: $e');
      return [];
    }
  }

  Future<List<SeedCalculation>> search({
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    String? dataInicio,
    String? dataFim,
    String? tipoCalculo,
  }) async {
    try {
      final db = await database;
      
      // Construir a query dinamicamente com base nos filtros
      List<String> conditions = [];
      List<dynamic> arguments = [];
      
      if (talhaoId != null) {
        conditions.add('talhao_id = ?');
        arguments.add(talhaoId);
      }
      
      if (culturaId != null) {
        conditions.add('cultura_id = ?');
        arguments.add(culturaId);
      }
      
      if (variedadeId != null) {
        conditions.add('variedade_id = ?');
        arguments.add(variedadeId);
      }
      
      if (tipoCalculo != null) {
        conditions.add('tipo_calculo = ?');
        arguments.add(tipoCalculo);
      }
      
      if (dataInicio != null) {
        conditions.add('data_calculo >= ?');
        arguments.add(dataInicio);
      }
      
      if (dataFim != null) {
        conditions.add('data_calculo <= ?');
        arguments.add(dataFim);
      }
      
      String whereClause = conditions.isEmpty ? '' : conditions.join(' AND ');
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: arguments.isEmpty ? null : arguments,
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) => SeedCalculation.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar cálculos com filtros: $e');
      return [];
    }
  }
}
