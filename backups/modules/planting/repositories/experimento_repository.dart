import 'package:sqflite/sqflite.dart';
import '../models/experimento_model.dart';
import '../../../database/app_database.dart';

class ExperimentoRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'experimentos';

  Future<void> createTable() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        variedade_id TEXT NOT NULL,
        safra_id TEXT NOT NULL,
        area REAL NOT NULL,
        descricao TEXT NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        observacoes TEXT,
        fotos TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> insert(ExperimentoModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await createTable(); // Garantir que a tabela existe com a estrutura correta
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(ExperimentoModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.update(
      table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<List<ExperimentoModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'data_inicio DESC');
    return List.generate(maps.length, (i) {
      return ExperimentoModel.fromMap(maps[i]);
    });
  }

  Future<List<ExperimentoModel>> getByFilters({int? talhaoId, int? culturaId, String? nome, int? ano}) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (talhaoId != null) {
      whereClause += 'talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    if (culturaId != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'cultura_id = ?';
      whereArgs.add(culturaId);
    }
    
    if (nome != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'nome LIKE ?';
      whereArgs.add('%$nome%');
    }
    
    if (ano != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      // Filtrar por ano da data de início
      whereClause += "strftime('%Y', data_inicio) = ?";
      whereArgs.add(ano.toString());
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data_inicio DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ExperimentoModel.fromMap(maps[i]);
    });
  }

  Future<ExperimentoModel?> getById(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return ExperimentoModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> delete(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
