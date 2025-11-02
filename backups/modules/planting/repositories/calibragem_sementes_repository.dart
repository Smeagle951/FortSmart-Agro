import 'package:sqflite/sqflite.dart';

import '../../../database/db_helper.dart';
import '../models/calibragem_sementes_model.dart';

class CalibragemSementesRepository {
  final DbHelper _dbHelper = DbHelper();
  final String tableName = 'calibragem_sementes';

  Future<Database> get _database async => await _dbHelper.database;

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        data_regulagem TEXT NOT NULL,
        sementes_por_metro REAL NOT NULL,
        sementes_coletadas REAL NOT NULL,
        linhas_coletadas INTEGER,
        espacamento_entre_linhas REAL NOT NULL,
        populacao_desejada REAL,
        usa_disco_engrenagens INTEGER NOT NULL DEFAULT 0,
        numero_furos_no_disco INTEGER,
        engrenagem_motora INTEGER,
        engrenagem_movida INTEGER,
        numero_linhas_plantadeira INTEGER,
        plantas_por_metro REAL NOT NULL,
        plantas_por_hectare REAL NOT NULL,
        plantas_por_metro_quadrado REAL NOT NULL,
        erro_porcentagem REAL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(CalibragemSementesModel calibragem) async {
    final db = await _database;
    return await db.insert(tableName, calibragem.toMap());
  }

  Future<int> update(CalibragemSementesModel calibragem) async {
    final db = await _database;
    return await db.update(
      tableName,
      calibragem.toMap(),
      where: 'id = ?',
      whereArgs: [calibragem.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<CalibragemSementesModel?> getById(int id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CalibragemSementesModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CalibragemSementesModel>> getAll() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'data_regulagem DESC',
    );

    return List.generate(maps.length, (i) {
      return CalibragemSementesModel.fromMap(maps[i]);
    });
  }
}
