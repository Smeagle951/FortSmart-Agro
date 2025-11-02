import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../utils/text_encoding_helper.dart';

/// Classe responsável por gerenciar migrações do banco de dados
class DatabaseMigration {
  final AppDatabase _database = AppDatabase();

  /// Executa todas as migrações necessárias
  Future<bool> runMigrations() async {
    try {
      debugPrint('Iniciando processo de migração do banco de dados');
      
      // Verifica a versão atual do banco de dados
      final db = await _database.database;
      final version = await _getDbVersion(db);
      
      debugPrint('Versão atual do banco de dados: $version');
      
      // Executa as migrações sequencialmente
      if (version < 2) await _migrateToV2(db);
      if (version < 3) await _migrateToV3(db);
      if (version < 4) await _migrateToV4(db);
      
      // Atualiza a versão do banco de dados
      await _updateDbVersion(db, 4);
      
      debugPrint('Migração concluída com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro durante a migração: ${e.toString()}');
      return false;
    }
  }

  /// Obtém a versão atual do banco de dados
  Future<int> _getDbVersion(Database db) async {
    try {
      // Verifica se a tabela de versão existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='db_version'",
      );
      
      if (tables.isEmpty) {
        // Se a tabela não existir, cria e define a versão como 1
        await db.execute(
          'CREATE TABLE db_version (version INTEGER PRIMARY KEY, updated_at TEXT)',
        );
        await db.insert('db_version', {
          'version': 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
        return 1;
      } else {
        // Se a tabela existir, obtém a versão atual
        final result = await db.query('db_version');
        if (result.isEmpty) {
          // Se não houver registro, insere a versão 1
          await db.insert('db_version', {
            'version': 1,
            'updated_at': DateTime.now().toIso8601String(),
          });
          return 1;
        } else {
          return result.first['version'] as int;
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter versão do banco: $e');
      // Em caso de erro, assume versão 1
      return 1;
    }
  }

  /// Atualiza a versão do banco de dados
  Future<void> _updateDbVersion(Database db, int version) async {
    await db.update(
      'db_version',
      {
        'version': version,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: '1=1',
    );
    debugPrint('Versão do banco atualizada para: $version');
  }

  /// Migração para a versão 2
  /// Adiciona as tabelas de aplicações de defensivos
  Future<void> _migrateToV2(Database db) async {
    debugPrint('Aplicando migração para versão 2');
    
    // Verifica se a tabela já existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='pesticide_applications'",
    );
    
    if (tables.isEmpty) {
      // Cria a tabela de aplicações de defensivos
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
      
      debugPrint('Tabela pesticide_applications criada');
    } else {
      debugPrint('Tabela pesticide_applications já existe');
    }
  }

  /// Migração para a versão 3
  /// Adiciona as tabelas de perdas na colheita
  Future<void> _migrateToV3(Database db) async {
    debugPrint('Aplicando migração para versão 3');
    
    // Verifica se a tabela já existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='harvest_losses'",
    );
    
    if (tables.isEmpty) {
      // Cria a tabela de perdas na colheita
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
      
      debugPrint('Tabela harvest_losses criada');
    } else {
      debugPrint('Tabela harvest_losses já existe');
    }
  }

  /// Migração para a versão 4
  /// Adiciona as tabelas de plantios
  Future<void> _migrateToV4(Database db) async {
    debugPrint('Aplicando migração para versão 4');
    
    // Verifica se a tabela já existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='plantings'",
    );
    
    if (tables.isEmpty) {
      // Cria a tabela de plantios
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
      
      debugPrint('Tabela plantings criada');
    } else {
      debugPrint('Tabela plantings já existe');
    }
  }

  /// Verifica se as tabelas essenciais existem e cria se necessário
  Future<bool> ensureEssentialTables() async {
    try {
      final db = await _database.database;
      
      // Lista de tabelas essenciais e seus scripts de criação
      final Map<String, String> essentialTables = {
        'pesticide_applications': '''
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
        ''',
        'harvest_losses': '''
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
        ''',
        'plantings': '''
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
        ''',
      };
      
      // Verifica cada tabela e cria se não existir
      for (final entry in essentialTables.entries) {
        final tableName = entry.key;
        final createScript = entry.value;
        
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        
        if (tables.isEmpty) {
          debugPrint('Tabela $tableName não encontrada. Criando...');
          await db.execute(createScript);
          debugPrint('Tabela $tableName criada com sucesso');
        } else {
          debugPrint('Tabela $tableName já existe');
        }
      }
      
      return true;
    } catch (e) {
      final errorMsg = TextEncodingHelper.normalizeText(e.toString());
      debugPrint('Erro ao verificar tabelas essenciais: $errorMsg');
      return false;
    }
  }
}
