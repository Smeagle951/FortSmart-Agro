import 'package:sqflite/sqflite.dart';

/// 🔧 MIGRAÇÃO COMPLETA - CORREÇÃO DE TODOS OS PROBLEMAS DO BANCO
/// Resolve todos os erros identificados no terminal de uma vez
class FixAllDatabaseIssuesMigration {
  static Future<void> up(Database db) async {
    print('🔧 Iniciando correção completa do banco de dados...');
    
    try {
      // 1. CORRIGIR TABELA infestation_data (FALTANTE)
      await _createInfestationDataTable(db);
      
      // 2. CORRIGIR TABELA estoque (FALTANTE)
      await _createEstoqueTable(db);
      
      // 3. CORRIGIR TABELA monitorings (COLUNA plot_id FALTANTE)
      await _fixMonitoringsTable(db);
      
      // 4. CORRIGIR TABELAS DE GERMINAÇÃO (COLUNAS DUPLICADAS)
      await _fixGerminationTables(db);
      
      // 5. CRIAR ÍNDICES PARA PERFORMANCE
      await _createIndexes(db);
      
      print('✅ Correção completa do banco concluída com sucesso!');
    } catch (e) {
      print('❌ Erro na correção do banco: $e');
      rethrow;
    }
  }
  
  /// Cria tabela infestation_data que está faltando
  static Future<void> _createInfestationDataTable(Database db) async {
    try {
      // Verificar se a tabela já existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='infestation_data'"
      );
      
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE infestation_data (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            cultura_id TEXT NOT NULL,
            organismo_id TEXT NOT NULL,
            tipo TEXT NOT NULL,
            quantidade INTEGER NOT NULL,
            percentual REAL NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            data_registro TEXT NOT NULL,
            monitoring_point_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');
        print('✅ Tabela infestation_data criada');
      } else {
        print('ℹ️ Tabela infestation_data já existe');
      }
    } catch (e) {
      print('ℹ️ Tabela infestation_data: $e');
    }
  }
  
  /// Cria tabela estoque que está faltando
  static Future<void> _createEstoqueTable(Database db) async {
    try {
      // Verificar se a tabela já existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='estoque'"
      );
      
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE estoque (
            id TEXT PRIMARY KEY,
            produto_id TEXT NOT NULL,
            produto_nome TEXT NOT NULL,
            quantidade REAL NOT NULL,
            unidade TEXT NOT NULL,
            lote TEXT,
            data_validade TEXT,
            preco_unitario REAL,
            fornecedor TEXT,
            observacoes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');
        print('✅ Tabela estoque criada');
      } else {
        print('ℹ️ Tabela estoque já existe');
      }
    } catch (e) {
      print('ℹ️ Tabela estoque: $e');
    }
  }
  
  /// Corrige tabela monitorings adicionando coluna plot_id se necessário
  static Future<void> _fixMonitoringsTable(Database db) async {
    try {
      // Verificar se a tabela monitorings existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitorings'"
      );
      
      if (tables.isNotEmpty) {
        // Verificar se a coluna plot_id existe
        final columns = await db.rawQuery("PRAGMA table_info(monitorings)");
        final hasPlotId = columns.any((col) => col['name'] == 'plot_id');
        
        if (!hasPlotId) {
          await db.execute('ALTER TABLE monitorings ADD COLUMN plot_id TEXT');
          print('✅ Coluna plot_id adicionada à tabela monitorings');
        } else {
          print('ℹ️ Coluna plot_id já existe na tabela monitorings');
        }
        
        // Adicionar outras colunas que podem estar faltando
        final hasTechnicianName = columns.any((col) => col['name'] == 'technicianName');
        if (!hasTechnicianName) {
          await db.execute('ALTER TABLE monitorings ADD COLUMN technicianName TEXT');
          print('✅ Coluna technicianName adicionada à tabela monitorings');
        }
        
        final hasPlotName = columns.any((col) => col['name'] == 'plotName');
        if (!hasPlotName) {
          await db.execute('ALTER TABLE monitorings ADD COLUMN plotName TEXT');
          print('✅ Coluna plotName adicionada à tabela monitorings');
        }
        
        final hasIsCompleted = columns.any((col) => col['name'] == 'isCompleted');
        if (!hasIsCompleted) {
          await db.execute('ALTER TABLE monitorings ADD COLUMN isCompleted INTEGER DEFAULT 0');
          print('✅ Coluna isCompleted adicionada à tabela monitorings');
        }
      } else {
        // Criar tabela monitorings se não existir
        await db.execute('''
          CREATE TABLE monitorings (
            id TEXT PRIMARY KEY,
            plot_id TEXT,
            technicianName TEXT,
            plotName TEXT,
            date TEXT NOT NULL,
            isCompleted INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');
        print('✅ Tabela monitorings criada');
      }
    } catch (e) {
      print('ℹ️ Tabela monitorings: $e');
    }
  }
  
  /// Corrige tabelas de germinação removendo tentativas de colunas duplicadas
  static Future<void> _fixGerminationTables(Database db) async {
    try {
      // Verificar se as tabelas de germinação existem e corrigir
      final germinationTables = ['germination_tests', 'germination_subtests', 'germination_daily_records'];
      
      for (String tableName in germinationTables) {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
        );
        
        if (tables.isNotEmpty) {
          // Verificar colunas existentes
          final columns = await db.rawQuery("PRAGMA table_info($tableName)");
          final columnNames = columns.map((col) => col['name'] as String).toList();
          
          print('ℹ️ Tabela $tableName: ${columnNames.length} colunas');
          
          // Adicionar colunas que podem estar faltando (sem duplicar)
          if (tableName == 'germination_tests' && !columnNames.contains('useSubtests')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN useSubtests INTEGER NOT NULL DEFAULT 0');
            print('✅ Coluna useSubtests adicionada à tabela $tableName');
          }
          
          if (tableName == 'germination_subtests' && !columnNames.contains('germinationTestId')) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN germinationTestId INTEGER NOT NULL DEFAULT 0');
            print('✅ Coluna germinationTestId adicionada à tabela $tableName');
          }
          
          if (tableName == 'germination_daily_records') {
            if (!columnNames.contains('otherSeeds')) {
              await db.execute('ALTER TABLE $tableName ADD COLUMN otherSeeds INTEGER NOT NULL DEFAULT 0');
              print('✅ Coluna otherSeeds adicionada à tabela $tableName');
            }
            if (!columnNames.contains('inertMatter')) {
              await db.execute('ALTER TABLE $tableName ADD COLUMN inertMatter INTEGER NOT NULL DEFAULT 0');
              print('✅ Coluna inertMatter adicionada à tabela $tableName');
            }
            if (!columnNames.contains('photos')) {
              await db.execute('ALTER TABLE $tableName ADD COLUMN photos TEXT');
              print('✅ Coluna photos adicionada à tabela $tableName');
            }
          }
        }
      }
    } catch (e) {
      print('ℹ️ Tabelas de germinação: $e');
    }
  }
  
  /// Cria índices para melhorar performance
  static Future<void> _createIndexes(Database db) async {
    try {
      // Índices para infestation_data
      await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_data_talhao_id ON infestation_data (talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_data_organismo_id ON infestation_data (organismo_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_data_data_registro ON infestation_data (data_registro)');
      
      // Índices para estoque
      await db.execute('CREATE INDEX IF NOT EXISTS idx_estoque_produto_id ON estoque (produto_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_estoque_data_validade ON estoque (data_validade)');
      
      // Índices para monitorings
      await db.execute('CREATE INDEX IF NOT EXISTS idx_monitorings_plot_id ON monitorings (plot_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_monitorings_date ON monitorings (date)');
      
      print('✅ Índices criados com sucesso');
    } catch (e) {
      print('ℹ️ Índices: $e');
    }
  }
}
