/// 🌱 Estrutura de Banco de Dados - Teste de Germinação
/// 
/// Implementa as tabelas necessárias para testes de germinação seguindo
/// metodologias agronômicas (ABNT NBR 9787) com suporte a subtestes A, B, C

import 'package:sqflite/sqflite.dart';
import '../models/germination_test_model.dart';

class GerminationDatabase {
  static const String _databaseName = 'germination_test.db';
  static const int _databaseVersion = 1;

  /// Cria todas as tabelas necessárias para o módulo de germinação
  static Future<void> createTables(Database db) async {
    await _createGerminationTestsTable(db);
    await _createGerminationSubtestsTable(db);
    await _createGerminationDailyRecordsTable(db);
    await _createGerminationSubtestDailyRecordsTable(db);
    await _createGerminationSettingsTable(db);
    
    // Adicionar colunas faltantes sem apagar dados
    await _addMissingColumns(db);
    
    await _createIndexes(db);
  }

  /// Adiciona colunas faltantes sem apagar dados existentes
  static Future<void> _addMissingColumns(Database db) async {
    try {
      // Adicionar coluna useSubtests se não existir
      await db.execute('''
        ALTER TABLE germination_tests ADD COLUMN useSubtests INTEGER NOT NULL DEFAULT 0
      ''');
      print('✅ Coluna useSubtests adicionada com sucesso');
    } catch (e) {
      // Coluna já existe, ignorar erro
      print('ℹ️ Coluna useSubtests já existe: $e');
    }

    try {
      // Adicionar coluna testId se não existir
      await db.execute('''
        ALTER TABLE germination_subtests ADD COLUMN testId INTEGER NOT NULL DEFAULT 0
      ''');
      print('✅ Coluna testId adicionada com sucesso');
    } catch (e) {
      // Coluna já existe, ignorar erro
      print('ℹ️ Coluna testId já existe: $e');
    }
  }

  /// Tabela principal de testes de germinação
  static Future<void> _createGerminationTestsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        culture TEXT NOT NULL,
        variety TEXT NOT NULL,
        seedLot TEXT NOT NULL,
        totalSeeds INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        expectedEndDate TEXT,
        pureSeeds INTEGER NOT NULL,
        brokenSeeds INTEGER NOT NULL,
        stainedSeeds INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        observations TEXT,
        photos TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        
        -- Campos de subtestes
        hasSubtests INTEGER NOT NULL DEFAULT 0,
        subtestSeedCount INTEGER NOT NULL DEFAULT 100,
        subtestNames TEXT,
        position TEXT,
        
        -- Resultados finais
        finalGerminationPercentage REAL,
        purityPercentage REAL,
        diseasedPercentage REAL,
        culturalValue REAL,
        averageGerminationTime REAL,
        firstCountDay INTEGER,
        day50PercentGermination INTEGER
      )
    ''');
  }

  /// Tabela de subtestes (A, B, C)
  static Future<void> _createGerminationSubtestsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_subtests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        code TEXT NOT NULL,
        totalSeeds INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (testId) REFERENCES germination_tests (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Tabela de registros diários de germinação
  static Future<void> _createGerminationDailyRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        subtestId INTEGER,
        day INTEGER NOT NULL,
        recordDate TEXT NOT NULL,
        normalGerminated INTEGER NOT NULL,
        abnormalGerminated INTEGER NOT NULL,
        diseasedFungi INTEGER NOT NULL,
        diseasedBacteria INTEGER NOT NULL,
        notGerminated INTEGER NOT NULL,
        otherSeeds INTEGER NOT NULL,
        inertMatter INTEGER NOT NULL,
        observations TEXT,
        photos TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (testId) REFERENCES germination_tests (id) ON DELETE CASCADE,
        FOREIGN KEY (subtestId) REFERENCES germination_subtests (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Tabela de registros diários de subtestes
  static Future<void> _createGerminationSubtestDailyRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_subtest_daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subtestId INTEGER NOT NULL,
        day INTEGER NOT NULL,
        recordDate TEXT NOT NULL,
        normalGerminated INTEGER NOT NULL,
        abnormalGerminated INTEGER NOT NULL,
        diseasedFungi INTEGER NOT NULL,
        diseasedBacteria INTEGER NOT NULL,
        notGerminated INTEGER NOT NULL,
        otherSeeds INTEGER NOT NULL,
        inertMatter INTEGER NOT NULL,
        observations TEXT,
        photos TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (subtestId) REFERENCES germination_subtests (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Tabela de configurações de germinação
  static Future<void> _createGerminationSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        approvalThreshold REAL NOT NULL DEFAULT 80.0,
        alertThreshold REAL NOT NULL DEFAULT 70.0,
        diseaseThreshold REAL NOT NULL DEFAULT 10.0,
        autoAlerts INTEGER NOT NULL DEFAULT 1,
        autoApproval INTEGER NOT NULL DEFAULT 0,
        defaultSeedCount INTEGER NOT NULL DEFAULT 100,
        vigorDays INTEGER NOT NULL DEFAULT 5,
        temperature TEXT NOT NULL DEFAULT '25°C',
        humidity TEXT NOT NULL DEFAULT '60%',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Cria índices para otimização de consultas
  static Future<void> _createIndexes(Database db) async {
    // Índices para germination_tests
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_tests_culture ON germination_tests(culture);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_tests_variety ON germination_tests(variety);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_tests_seedLot ON germination_tests(seedLot);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_tests_status ON germination_tests(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_tests_startDate ON germination_tests(startDate);');
    
    // Índices para germination_subtests
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_subtests_testId ON germination_subtests(testId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_subtests_code ON germination_subtests(code);');
    
    // Índices para germination_daily_records
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_daily_records_testId ON germination_daily_records(testId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_daily_records_subtestId ON germination_daily_records(subtestId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_daily_records_day ON germination_daily_records(day);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_daily_records_date ON germination_daily_records(recordDate);');
    
    // Índices para germination_subtest_daily_records
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_subtest_daily_records_subtestId ON germination_subtest_daily_records(subtestId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_subtest_daily_records_day ON germination_subtest_daily_records(day);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_germination_subtest_daily_records_date ON germination_subtest_daily_records(recordDate);');
  }

  /// Inicializa configurações padrão
  static Future<void> initializeDefaultSettings(Database db) async {
    // Verificar se já existem configurações
    final existingSettings = await db.query('germination_settings');
    
    if (existingSettings.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('germination_settings', {
        'approvalThreshold': 80.0,
        'alertThreshold': 70.0,
        'diseaseThreshold': 10.0,
        'autoAlerts': 1,
        'autoApproval': 0,
        'defaultSeedCount': 100,
        'vigorDays': 5,
        'temperature': '25°C',
        'humidity': '60%',
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  /// Migra dados de versões anteriores
  static Future<void> migrateDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      // Migração da versão 0 para 1
      await createTables(db);
      await initializeDefaultSettings(db);
    }
  }

  /// Valida a integridade dos dados
  static Future<Map<String, dynamic>> validateDataIntegrity(Database db) async {
    final issues = <String>[];
    
    try {
      // Verificar se existem testes órfãos
      final orphanTests = await db.rawQuery('''
        SELECT gt.id FROM germination_tests gt 
        LEFT JOIN germination_subtests gs ON gt.id = gs.testId 
        WHERE gt.hasSubtests = 1 AND gs.id IS NULL
      ''');
      
      if (orphanTests.isNotEmpty) {
        issues.add('Encontrados ${orphanTests.length} testes com subtestes órfãos');
      }
      
      // Verificar registros diários órfãos
      final orphanRecords = await db.rawQuery('''
        SELECT gdr.id FROM germination_daily_records gdr 
        LEFT JOIN germination_tests gt ON gdr.testId = gt.id 
        WHERE gt.id IS NULL
      ''');
      
      if (orphanRecords.isNotEmpty) {
        issues.add('Encontrados ${orphanRecords.length} registros diários órfãos');
      }
      
      // Verificar registros de subtestes órfãos
      final orphanSubtestRecords = await db.rawQuery('''
        SELECT gsdr.id FROM germination_subtest_daily_records gsdr 
        LEFT JOIN germination_subtests gs ON gsdr.subtestId = gs.id 
        WHERE gs.id IS NULL
      ''');
      
      if (orphanSubtestRecords.isNotEmpty) {
        issues.add('Encontrados ${orphanSubtestRecords.length} registros de subtestes órfãos');
      }
      
      return {
        'isValid': issues.isEmpty,
        'issues': issues,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isValid': false,
        'issues': ['Erro na validação: $e'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Limpa dados órfãos
  static Future<void> cleanOrphanData(Database db) async {
    try {
      // Remover registros diários órfãos
      await db.rawDelete('''
        DELETE FROM germination_daily_records 
        WHERE testId NOT IN (SELECT id FROM germination_tests)
      ''');
      
      // Remover registros de subtestes órfãos
      await db.rawDelete('''
        DELETE FROM germination_subtest_daily_records 
        WHERE subtestId NOT IN (SELECT id FROM germination_subtests)
      ''');
      
      // Remover subtestes órfãos
      await db.rawDelete('''
        DELETE FROM germination_subtests 
        WHERE testId NOT IN (SELECT id FROM germination_tests)
      ''');
    } catch (e) {
      print('Erro ao limpar dados órfãos: $e');
    }
  }

  /// Obtém estatísticas do banco de dados
  static Future<Map<String, dynamic>> getDatabaseStatistics(Database db) async {
    try {
      final testsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM germination_tests')) ?? 0;
      final subtestsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM germination_subtests')) ?? 0;
      final dailyRecordsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM germination_daily_records')) ?? 0;
      final subtestRecordsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM germination_subtest_daily_records')) ?? 0;
      
      final activeTests = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM germination_tests WHERE status = "active"')) ?? 0;
      final completedTests = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM germination_tests WHERE status = "completed"')) ?? 0;
      
      return {
        'totalTests': testsCount,
        'totalSubtests': subtestsCount,
        'totalDailyRecords': dailyRecordsCount,
        'totalSubtestRecords': subtestRecordsCount,
        'activeTests': activeTests,
        'completedTests': completedTests,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Erro ao obter estatísticas: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
