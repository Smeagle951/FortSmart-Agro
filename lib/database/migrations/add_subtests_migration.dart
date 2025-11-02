import 'package:floor/floor.dart';

/// Migração para adicionar suporte a subtestes de germinação
/// Mantém compatibilidade total com dados existentes
@DatabaseView('''
  SELECT 
    gt.*,
    CASE 
      WHEN (SELECT COUNT(*) FROM germination_subtests WHERE germination_test_id = gt.id) > 0 
      THEN 1 
      ELSE 0 
    END as has_subtests
  FROM germination_tests gt
''', viewName: 'germination_tests_with_subtests')
class GerminationTestsWithSubtests {
  // Esta view será usada para consultas que precisam saber se um teste tem subtestes
}

/// Migração para adicionar campos de subtestes
class AddSubtestsMigration extends Migration {
  @override
  int get startVersion => 1;
  
  @override
  int get endVersion => 2;
  
  @override
  void migrate(Database database) async {
    // 1. Adicionar campos de subtestes à tabela principal (opcionais)
    await database.execute('''
      ALTER TABLE germination_tests ADD COLUMN has_subtests INTEGER DEFAULT 0;
    ''');
    
    await database.execute('''
      ALTER TABLE germination_tests ADD COLUMN subtest_seed_count INTEGER DEFAULT 100;
    ''');
    
    await database.execute('''
      ALTER TABLE germination_tests ADD COLUMN subtest_names TEXT;
    ''');
    
    // 2. Criar tabela de subtestes
    await database.execute('''
      CREATE TABLE germination_subtests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        germination_test_id INTEGER NOT NULL,
        subtest_code TEXT NOT NULL,
        subtest_name TEXT NOT NULL,
        seed_count INTEGER NOT NULL DEFAULT 100,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (germination_test_id) REFERENCES germination_tests (id) ON DELETE CASCADE
      );
    ''');
    
    // 3. Criar tabela de registros diários por subteste
    await database.execute('''
      CREATE TABLE germination_subtest_daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subtest_id INTEGER NOT NULL,
        day INTEGER NOT NULL,
        record_date TEXT NOT NULL,
        normal_germinated INTEGER NOT NULL DEFAULT 0,
        abnormal_germinated INTEGER NOT NULL DEFAULT 0,
        diseased_fungi INTEGER NOT NULL DEFAULT 0,
        not_germinated INTEGER NOT NULL DEFAULT 0,
        sanitary_symptoms TEXT,
        sanitary_severity TEXT,
        sanitary_observations TEXT,
        sanitary_photos TEXT,
        observations TEXT,
        photos TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subtest_id) REFERENCES germination_subtests (id) ON DELETE CASCADE
      );
    ''');
    
    // 4. Criar índices para performance
    await database.execute('''
      CREATE INDEX idx_germination_subtests_test_id ON germination_subtests (germination_test_id);
    ''');
    
    await database.execute('''
      CREATE INDEX idx_germination_subtests_code ON germination_subtests (germination_test_id, subtest_code);
    ''');
    
    await database.execute('''
      CREATE INDEX idx_germination_subtest_records_subtest_id ON germination_subtest_daily_records (subtest_id);
    ''');
    
    await database.execute('''
      CREATE INDEX idx_germination_subtest_records_day ON germination_subtest_daily_records (subtest_id, day);
    ''');
    
    // 5. Criar view para consultas com subtestes
    await database.execute('''
      CREATE VIEW germination_tests_with_subtests AS
      SELECT 
        gt.*,
        CASE 
          WHEN (SELECT COUNT(*) FROM germination_subtests WHERE germination_test_id = gt.id) > 0 
          THEN 1 
          ELSE 0 
        END as has_subtests
      FROM germination_tests gt;
    ''');
  }
}

/// Migração para adicionar triggers de integridade
class AddSubtestsTriggersMigration extends Migration {
  @override
  int get startVersion => 2;
  
  @override
  int get endVersion => 3;
  
  @override
  void migrate(Database database) async {
    // Trigger para garantir que apenas 3 subtestes sejam criados por teste
    await database.execute('''
      CREATE TRIGGER check_subtest_limit
      BEFORE INSERT ON germination_subtests
      FOR EACH ROW
      WHEN (SELECT COUNT(*) FROM germination_subtests WHERE germination_test_id = NEW.germination_test_id) >= 3
      BEGIN
        SELECT RAISE(ABORT, 'Máximo de 3 subtestes por teste');
      END;
    ''');
    
    // Trigger para garantir códigos únicos por teste
    await database.execute('''
      CREATE TRIGGER check_subtest_code_unique
      BEFORE INSERT ON germination_subtests
      FOR EACH ROW
      WHEN EXISTS (SELECT 1 FROM germination_subtests WHERE germination_test_id = NEW.germination_test_id AND subtest_code = NEW.subtest_code)
      BEGIN
        SELECT RAISE(ABORT, 'Código de subteste já existe para este teste');
      END;
    ''');
    
    // Trigger para atualizar timestamp de subteste quando registro é adicionado
    await database.execute('''
      CREATE TRIGGER update_subtest_timestamp
      AFTER INSERT ON germination_subtest_daily_records
      FOR EACH ROW
      BEGIN
        UPDATE germination_subtests 
        SET updated_at = datetime('now') 
        WHERE id = NEW.subtest_id;
      END;
    ''');
    
    // Trigger para atualizar timestamp de subteste quando registro é atualizado
    await database.execute('''
      CREATE TRIGGER update_subtest_timestamp_on_update
      AFTER UPDATE ON germination_subtest_daily_records
      FOR EACH ROW
      BEGIN
        UPDATE germination_subtests 
        SET updated_at = datetime('now') 
        WHERE id = NEW.subtest_id;
      END;
    ''');
  }
}

/// Classe para gerenciar migrações de subtestes
class SubtestsMigrationManager {
  static List<Migration> getMigrations() {
    return [
      AddSubtestsMigration(),
      AddSubtestsTriggersMigration(),
    ];
  }
  
  /// Verifica se as tabelas de subtestes existem
  static Future<bool> checkSubtestsTablesExist(Database database) async {
    try {
      await database.rawQuery('SELECT 1 FROM germination_subtests LIMIT 1');
      await database.rawQuery('SELECT 1 FROM germination_subtest_daily_records LIMIT 1');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Cria subtestes para um teste existente (se necessário)
  static Future<void> createSubtestsForExistingTest(
    Database database, 
    int testId, 
    bool hasSubtests,
    int seedCount,
  ) async {
    if (!hasSubtests) return;
    
    // Verificar se já existem subtestes
    final existingSubtests = await database.rawQuery(
      'SELECT COUNT(*) as count FROM germination_subtests WHERE germination_test_id = ?',
      [testId]
    );
    
    if (existingSubtests.first['count'] as int > 0) return;
    
    // Criar subtestes A, B, C
    final now = DateTime.now().toIso8601String();
    final subtests = ['A', 'B', 'C'];
    
    for (final code in subtests) {
      await database.rawInsert('''
        INSERT INTO germination_subtests (
          germination_test_id, 
          subtest_code, 
          subtest_name, 
          seed_count, 
          status, 
          created_at, 
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        testId,
        code,
        'Subteste $code',
        seedCount,
        'active',
        now,
        now,
      ]);
    }
  }
}
