import 'package:sqflite/sqflite.dart';

class PragaImagesMigration {
  static const String tableName = 'praga_images';

  static Future<void> migrate(Database db) async {
    // Verificar se a tabela já existe
    if (await _tableExists(db)) {
      print('Tabela $tableName já existe');
      return;
    }

    // Criar a tabela
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_base64 TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        crop_id INTEGER,
        pest_id INTEGER,
        disease_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    print('Tabela $tableName criada com sucesso');
  }

  static Future<bool> _tableExists(Database db) async {
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
    );
    return tables.isNotEmpty;
  }
} 