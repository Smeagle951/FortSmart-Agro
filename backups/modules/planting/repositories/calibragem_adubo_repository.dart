import 'package:sqflite/sqflite.dart';

import '../../../database/db_helper.dart';
import '../models/calibragem_adubo_model.dart';

class CalibragemAduboRepository {
  final DbHelper _dbHelper = DbHelper();
  final String tableName = 'calibragem_adubo';

  Future<Database> get _database async => await _dbHelper.database;

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        data_regulagem TEXT NOT NULL,
        coleta_por_linha INTEGER NOT NULL,
        gramas_coletadas REAL NOT NULL,
        distancia_percorrida REAL NOT NULL,
        numero_linhas INTEGER NOT NULL,
        espacamento_entre_linhas REAL NOT NULL,
        valor_desejado REAL NOT NULL,
        usa_unidade_sacas INTEGER NOT NULL,
        engrenagem_motora INTEGER NOT NULL,
        engrenagem_movida INTEGER NOT NULL,
        kg_por_ha REAL NOT NULL,
        sacas_por_ha REAL NOT NULL,
        erro_porcentagem REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(CalibragemAduboModel calibragem) async {
    final db = await _database;
    return await db.insert(tableName, calibragem.toMap());
  }

  Future<int> update(CalibragemAduboModel calibragem) async {
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

  Future<CalibragemAduboModel?> getById(int id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CalibragemAduboModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CalibragemAduboModel>> getAll() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'data_regulagem DESC',
    );

    return List.generate(maps.length, (i) {
      return CalibragemAduboModel.fromMap(maps[i]);
    });
  }
}
