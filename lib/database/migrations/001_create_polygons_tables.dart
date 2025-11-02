import 'package:sqflite/sqflite.dart';

// Migração para SQLite puro (sem Drift)

class CreatePolygonsTables {
  static const int version = 1;

  static Future<void> up(Database db) async {
    // Tabela principal de polígonos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS polygons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        method TEXT NOT NULL,
        coordinates TEXT NOT NULL,
        area_ha REAL NOT NULL,
        perimeter_m REAL NOT NULL,
        distance_m REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        fazenda_id TEXT,
        cultura_id TEXT,
        safra_id TEXT
      )
    ''');

    // Tabela de trilhas cruas da caminhada
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        polygon_id INTEGER,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        accuracy REAL,
        speed REAL,
        bearing REAL,
        ts TEXT NOT NULL,
        status TEXT,
        FOREIGN KEY(polygon_id) REFERENCES polygons(id) ON DELETE CASCADE
      )
    ''');

    // Índices para performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_polygon_ts ON tracks(polygon_id, ts)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_polygons_fazenda ON polygons(fazenda_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_polygons_method ON polygons(method)');
    
    print('✅ Tabelas de polígonos criadas com sucesso');
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS tracks');
    await db.execute('DROP TABLE IF EXISTS polygons');
    print('✅ Tabelas de polígonos removidas');
  }
}
