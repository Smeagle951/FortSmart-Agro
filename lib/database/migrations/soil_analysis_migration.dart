import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

/// Classe responsável pela migração da tabela de análises de solo
class SoilAnalysisMigration {
  /// Adiciona a coluna plot_id à tabela soil_analyses se ela não existir
  static Future<void> addPlotIdColumn([Database? database]) async {
    Database db;
    if (database != null) {
      db = database;
    } else {
      // Se não foi passado um database, não podemos prosseguir para evitar loops
      print('❌ SoilAnalysisMigration: Database não fornecido, pulando migração para evitar loops');
      return;
    }
    
    // Verifica se a tabela soil_analyses existe
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'soil_analyses'],
    );
    
    if (tables.isEmpty) {
      // Se a tabela não existir, cria com a coluna plot_id
      await db.execute('''
        CREATE TABLE IF NOT EXISTS soil_analyses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monitoring_id INTEGER,
          sample_id INTEGER,
          ph REAL,
          phosphorus REAL,
          potassium REAL,
          calcium REAL,
          magnesium REAL,
          aluminum REAL,
          h_al REAL,
          organic_matter REAL,
          cation_exchange_capacity REAL,
          base_saturation REAL,
          aluminum_saturation REAL,
          clay REAL,
          silt REAL,
          sand REAL,
          depth_start REAL,
          depth_end REAL,
          notes TEXT,
          plot_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (monitoring_id) REFERENCES monitorings(id) ON DELETE CASCADE
        )
      ''');
      print('Tabela soil_analyses criada com a coluna plot_id');
    } else {
      // Verifica se a coluna plot_id já existe na tabela
      try {
        // Tenta consultar a coluna para verificar se ela existe
        await db.rawQuery('SELECT plot_id FROM soil_analyses LIMIT 1');
        print('Coluna plot_id já existe na tabela soil_analyses');
      } catch (e) {
        // Se a consulta falhar, a coluna não existe e precisa ser adicionada
        try {
          await db.execute('ALTER TABLE soil_analyses ADD COLUMN plot_id TEXT');
          print('Coluna plot_id adicionada à tabela soil_analyses');
        } catch (e) {
          print('Erro ao adicionar coluna plot_id: $e');
        }
      }
    }
  }
}
