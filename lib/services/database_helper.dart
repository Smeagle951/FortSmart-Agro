import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database; // mantido por compatibilidade, mas não usado
  // Inicialização e completer não são mais necessários após unificação via AppDatabase

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    // Unificado: sempre usa o AppDatabase singleton
    return await AppDatabase.instance.database;
  }

  // As rotinas de criação/configuração estão centralizadas no AppDatabase

  // Método para verificar se o banco de dados está aberto e reconectá-lo se necessário
  Future<void> ensureDbIsOpen() async {
    await AppDatabase.instance.ensureDatabaseOpen();
  }

  // Método para verificar e corrigir problemas nas tabelas
  Future<Map<String, bool>> checkTables() async {
    Map<String, bool> tableStatus = {};
    List<String> tables = [
      'machines', 'crops', 'plots', 'monitorings', 
      'monitoring_points', 'harvest_losses', 'plantings'
    ];
    
    try {
      await ensureDbIsOpen();
      Database db = await database;
      
      for (String table in tables) {
        try {
          await db.query(table, limit: 1);
          tableStatus[table] = true;
        } catch (e) {
          print('Erro ao verificar tabela $table: $e');
          tableStatus[table] = false;
          
          // Tenta recriar a tabela
          try {
            switch (table) {
              case 'machines':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS machines (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    brand TEXT,
                    model TEXT,
                    year INTEGER,
                    power REAL,
                    created_at TEXT,
                    updated_at TEXT
                  )
                ''');
                break;
              case 'crops':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS crops (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    scientific_name TEXT,
                    category TEXT,
                    cycle_days INTEGER,
                    color TEXT,
                    icon TEXT,
                    created_at TEXT,
                    updated_at TEXT
                  )
                ''');
                break;
              case 'plots':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS plots (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    area REAL,
                    farm_id INTEGER,
                    coordinates TEXT,
                    created_at TEXT,
                    updated_at TEXT
                  )
                ''');
                break;
              case 'monitorings':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS monitorings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    plot_id INTEGER,
                    crop_id INTEGER,
                    date TEXT,
                    notes TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    FOREIGN KEY (plot_id) REFERENCES plots (id),
                    FOREIGN KEY (crop_id) REFERENCES crops (id)
                  )
                ''');
                break;
              case 'monitoring_points':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS monitoring_points (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    monitoring_id INTEGER,
                    latitude REAL,
                    longitude REAL,
                    observations TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    FOREIGN KEY (monitoring_id) REFERENCES monitorings (id)
                  )
                ''');
                break;
              case 'harvest_losses':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS harvest_losses (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    plot_id INTEGER,
                    crop_id INTEGER,
                    date TEXT,
                    loss_value REAL,
                    loss_type TEXT,
                    notes TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    FOREIGN KEY (plot_id) REFERENCES plots (id),
                    FOREIGN KEY (crop_id) REFERENCES crops (id)
                  )
                ''');
                break;
              case 'plantings':
                await db.execute('''
                  CREATE TABLE IF NOT EXISTS plantings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    plot_id INTEGER,
                    crop_id INTEGER,
                    planting_date TEXT,
                    harvest_date TEXT,
                    seed_quantity REAL,
                    spacing REAL,
                    notes TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    FOREIGN KEY (plot_id) REFERENCES plots (id),
                    FOREIGN KEY (crop_id) REFERENCES crops (id)
                  )
                ''');
                break;
            }
            tableStatus[table] = true;
          } catch (recreateError) {
            print('Erro ao recriar tabela $table: $recreateError');
          }
        }
      }
    } catch (e) {
      print('Erro ao verificar tabelas: $e');
    }
    
    return tableStatus;
  }

  // Método para fechar o banco de dados corretamente
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
  
  // Este bloco foi removido para evitar duplicação de código

  // Métodos auxiliares para diagnóstico e manutenção
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'fortsmart_agro.db');
  }
  
  Future<File> getDatabaseFile() async {
    final path = await getDatabasePath();
    return File(path);
  }
  
  Future<void> resetDatabase() async {
    // Fechar o banco de dados se estiver aberto
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    
    // Excluir o arquivo do banco de dados
    final file = await getDatabaseFile();
    if (await file.exists()) {
      await file.delete();
    }
    
    // Reinicializar o banco de dados
    _database = null;
    await database;
  }
}
