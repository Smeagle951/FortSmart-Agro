import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'package:flutter/foundation.dart';

/// Classe utilitária para operações comuns de banco de dados
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final AppDatabase _database = AppDatabase();
  
  // Singleton
  static DatabaseHelper get instance => _instance;
  
  factory DatabaseHelper() {
    return _instance;
  }
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    return await _database.database;
  }
  
  Future<void> initializeDatabase() async {
    await _database.ensureDatabaseOpen();
    await ensureAllTablesExist();
  }

  /// Verifica se uma tabela existe no banco de dados
  Future<bool> tableExists(String tableName) async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar existência da tabela $tableName: $e');
      return false;
    }
  }

  /// Verifica se uma coluna existe em uma tabela
  Future<bool> columnExists(String tableName, String columnName) async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      
      for (final row in result) {
        if (row['name'] == columnName) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar existência da coluna $columnName na tabela $tableName: $e');
      return false;
    }
  }

  /// Cria a tabela de aplicações de defensivos se não existir
  Future<void> createPesticideApplicationsTable() async {
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pesticide_applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id TEXT NOT NULL,
        application_date TEXT NOT NULL,
        product_name TEXT NOT NULL,
        dose REAL NOT NULL,
        dose_unit TEXT NOT NULL,
        target_pest TEXT,
        application_method TEXT,
        weather_conditions TEXT,
        operator_name TEXT,
        observations TEXT,
        images TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');
    debugPrint('Tabela pesticide_applications criada ou já existente');
  }

  /// Cria a tabela de perdas na colheita se não existir
  Future<void> createHarvestLossesTable() async {
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS harvest_losses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id TEXT NOT NULL,
        evaluation_date TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        loss_percentage REAL NOT NULL,
        loss_cause TEXT,
        estimated_financial_loss REAL,
        mitigation_actions TEXT,
        images TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');
    debugPrint('Tabela harvest_losses criada ou já existente');
  }

  /// Cria a tabela de plantios se não existir
  Future<void> createPlantingsTable() async {
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        variety TEXT,
        planting_date TEXT NOT NULL,
        expected_harvest_date TEXT,
        seed_quantity REAL,
        seed_unit TEXT,
        spacing REAL,
        density REAL,
        treatment_applied TEXT,
        observations TEXT,
        images TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');
    debugPrint('Tabela plantings criada ou já existente');
  }

  /// Verifica e cria todas as tabelas essenciais
  Future<void> ensureAllTablesExist() async {
    final tables = {
      'pesticide_applications': createPesticideApplicationsTable,
      'harvest_losses': createHarvestLossesTable,
      'plantings': createPlantingsTable,
    };

    for (final entry in tables.entries) {
      final tableName = entry.key;
      final createFunction = entry.value;
      
      final exists = await tableExists(tableName);
      if (!exists) {
        debugPrint('Tabela $tableName não encontrada. Criando...');
        await createFunction();
      } else {
        debugPrint('Tabela $tableName já existe');
      }
    }
  }
}
