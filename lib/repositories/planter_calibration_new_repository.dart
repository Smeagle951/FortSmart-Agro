import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/planter_calibration_new.dart';
import '../utils/logger.dart';

/// Repositório para operações com calibragens de plantadeira (modelo atualizado)
class PlanterCalibrationNewRepository {
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'planter_calibrations_new';

  Future<Database> get database async => await _appDatabase.database;

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        talhao_id INTEGER,
        cultura_id INTEGER NOT NULL,
        variedade_id INTEGER,
        tipo TEXT NOT NULL,
        populacao REAL NOT NULL,
        espacamento REAL NOT NULL,
        num_linhas INTEGER NOT NULL,
        peso_mil_sementes REAL,
        disco TEXT,
        engrenagem_motora INTEGER,
        engrenagem_movida INTEGER,
        rosca_passo1 REAL,
        rosca_passo2 REAL,
        distancia_percorrida REAL,
        peso_coletado REAL,
        resultado_kg_ha REAL,
        resultado_kg_metro REAL,
        observacoes TEXT,
        fotos TEXT,
        data_regulagem TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (talhao_id) REFERENCES plots(id),
        FOREIGN KEY (cultura_id) REFERENCES crops(id),
        FOREIGN KEY (variedade_id) REFERENCES variedades(id)
      )
    ''');
  }

  Future<String> insert(PlanterCalibrationNew calibration) async {
    try {
      final db = await database;
      await db.insert(
        tableName,
        calibration.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return calibration.id;
    } catch (e) {
      Logger.error('Erro ao inserir calibragem: $e');
      throw Exception('Erro ao salvar calibragem: $e');
    }
  }

  Future<void> update(PlanterCalibrationNew calibration) async {
    try {
      final db = await database;
      await db.update(
        tableName,
        calibration.toMap(),
        where: 'id = ?',
        whereArgs: [calibration.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.error('Erro ao atualizar calibragem: $e');
      throw Exception('Erro ao atualizar calibragem: $e');
    }
  }

  Future<int> delete(String id) async {
    try {
      final db = await database;
      return await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      Logger.error('Erro ao excluir calibragem: $e');
      throw Exception('Erro ao excluir calibragem: $e');
    }
  }

  Future<PlanterCalibrationNew?> getById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return PlanterCalibrationNew.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao buscar calibragem: $e');
      throw Exception('Erro ao buscar calibragem: $e');
    }
  }

  Future<List<PlanterCalibrationNew>> getAll() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'created_at DESC');
      return List.generate(maps.length, (i) => PlanterCalibrationNew.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar calibragens: $e');
      return [];
    }
  }

  Future<List<PlanterCalibrationNew>> getByTipo(String tipo) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'tipo = ?',
        whereArgs: [tipo],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => PlanterCalibrationNew.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar calibragens por tipo: $e');
      return [];
    }
  }

  Future<List<PlanterCalibrationNew>> getByTalhaoId(int talhaoId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => PlanterCalibrationNew.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar calibragens por talhão: $e');
      return [];
    }
  }

  Future<List<PlanterCalibrationNew>> getByCulturaId(int culturaId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => PlanterCalibrationNew.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar calibragens por cultura: $e');
      return [];
    }
  }

  Future<List<PlanterCalibrationNew>> getByVariedadeId(int variedadeId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'variedade_id = ?',
        whereArgs: [variedadeId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => PlanterCalibrationNew.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar calibragens por variedade: $e');
      return [];
    }
  }

  Future<List<PlanterCalibrationNew>> search({
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    String? tipo,
    String? dataInicio,
    String? dataFim,
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
      
      if (tipo != null) {
        conditions.add('tipo = ?');
        arguments.add(tipo);
      }
      
      if (dataInicio != null) {
        conditions.add('data_regulagem >= ?');
        arguments.add(dataInicio);
      }
      
      if (dataFim != null) {
        conditions.add('data_regulagem <= ?');
        arguments.add(dataFim);
      }
      
      String whereClause = conditions.isEmpty ? '' : conditions.join(' AND ');
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: arguments.isEmpty ? null : arguments,
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) => PlanterCalibrationNew.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar calibragens com filtros: $e');
      return [];
    }
  }
}
