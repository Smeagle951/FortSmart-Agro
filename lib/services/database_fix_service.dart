import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço para corrigir problemas de estrutura do banco de dados
class DatabaseFixService {
  static final DatabaseFixService _instance = DatabaseFixService._internal();
  factory DatabaseFixService() => _instance;
  DatabaseFixService._internal();

  /// Verifica e corrige a estrutura do banco de dados
  Future<bool> fixDatabaseStructure() async {
    try {
      Logger.info('🔧 Iniciando verificação e correção da estrutura do banco...');
      
      final db = await AppDatabase.instance.database;
      
      // Verificar se as tabelas principais existem
      final tablesExist = await _checkMainTables(db);
      
      if (!tablesExist) {
        Logger.info('🔄 Criando tabelas faltantes...');
        await _createMissingTables(db);
        Logger.info('✅ Tabelas criadas com sucesso');
      } else {
        Logger.info('✅ Todas as tabelas principais existem');
      }
      
      // Verificar integridade das foreign keys
      await _checkForeignKeys(db);
      
      Logger.info('✅ Estrutura do banco verificada e corrigida com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir estrutura do banco: $e');
      return false;
    }
  }

  /// Verifica se as tabelas principais existem
  Future<bool> _checkMainTables(Database db) async {
    final requiredTables = ['talhoes', 'safras', 'poligonos', 'plantios', 'monitorings'];
    
    for (String tableName in requiredTables) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]
      );
      
      if (result.isEmpty) {
        Logger.warning('⚠️ Tabela $tableName não existe');
        return false;
      }
    }
    
    return true;
  }

  /// Cria tabelas faltantes
  Future<void> _createMissingTables(Database db) async {
    // Tabela de talhões
    await db.execute('''
      CREATE TABLE IF NOT EXISTS talhoes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        idFazenda TEXT NOT NULL,
        poligonos TEXT NOT NULL,
        safras TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        device_id TEXT,
        deleted_at TEXT
      )
    ''');

    // Tabela de safras
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safras (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        dataInicio TEXT NOT NULL,
        dataFim TEXT,
        status TEXT NOT NULL,
        observacoes TEXT,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT
      )
    ''');

    // Tabela de polígonos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS poligonos (
        id TEXT PRIMARY KEY,
        idTalhao TEXT NOT NULL,
        pontos TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (idTalhao) REFERENCES talhoes (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de plantios
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER NOT NULL,
        cultura TEXT NOT NULL,
        variedade TEXT,
        data_plantio TEXT NOT NULL,
        area_plantada REAL NOT NULL,
        espacamento_linhas REAL,
        espacamento_plantas REAL,
        populacao_plantas INTEGER,
        densidade_sementes REAL,
        profundidade_plantio REAL,
        sistema_plantio TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT,
        synchronized INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (talhao_id) REFERENCES talhoes (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de monitoramentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitorings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER NOT NULL,
        data_monitoramento TEXT NOT NULL,
        tipo_monitoramento TEXT NOT NULL,
        observacoes TEXT,
        coordenadas TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT,
        synchronized INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (talhao_id) REFERENCES talhoes (id) ON DELETE CASCADE
      )
    ''');

    // Criar índices
    await _createIndexes(db);
  }

  /// Cria índices para performance
  Future<void> _createIndexes(Database db) async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_talhoes_idFazenda ON talhoes(idFazenda);',
      'CREATE INDEX IF NOT EXISTS idx_talhoes_deleted_at ON talhoes(deleted_at);',
      'CREATE INDEX IF NOT EXISTS idx_talhoes_sincronizado ON talhoes(sincronizado);',
      'CREATE INDEX IF NOT EXISTS idx_safras_status ON safras(status);',
      'CREATE INDEX IF NOT EXISTS idx_safras_deleted_at ON safras(deleted_at);',
      'CREATE INDEX IF NOT EXISTS idx_poligonos_idTalhao ON poligonos(idTalhao);',
      'CREATE INDEX IF NOT EXISTS idx_plantios_talhao_id ON plantios(talhao_id);',
      'CREATE INDEX IF NOT EXISTS idx_plantios_cultura ON plantios(cultura);',
      'CREATE INDEX IF NOT EXISTS idx_plantios_data_plantio ON plantios(data_plantio);',
      'CREATE INDEX IF NOT EXISTS idx_monitorings_talhao_id ON monitorings(talhao_id);',
      'CREATE INDEX IF NOT EXISTS idx_monitorings_data ON monitorings(data_monitoramento);',
    ];

    for (String indexSql in indexes) {
      try {
        await db.execute(indexSql);
      } catch (e) {
        Logger.warning('⚠️ Erro ao criar índice: $e');
      }
    }
  }

  /// Verifica integridade das foreign keys
  Future<void> _checkForeignKeys(Database db) async {
    try {
      // Verificar se foreign keys estão habilitadas
      final result = await db.rawQuery('PRAGMA foreign_keys');
      final foreignKeysEnabled = result.first['foreign_keys'] == 1;
      
      if (!foreignKeysEnabled) {
        Logger.info('🔄 Habilitando foreign keys...');
        await db.execute('PRAGMA foreign_keys = ON');
      }
      
      Logger.info('✅ Foreign keys verificadas');
    } catch (e) {
      Logger.warning('⚠️ Erro ao verificar foreign keys: $e');
    }
  }

  /// Obtém estatísticas do banco de dados
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await AppDatabase.instance.database;
      
      final stats = <String, dynamic>{};
      
      // Contar registros em cada tabela
      final tables = ['talhoes', 'safras', 'poligonos', 'plantios', 'monitorings'];
      
      for (String tableName in tables) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
          stats[tableName] = result.first['count'] ?? 0;
        } catch (e) {
          stats[tableName] = 'ERROR: ${e.toString()}';
        }
      }
      
      // Verificar tamanho do banco
      try {
        final result = await db.rawQuery('PRAGMA page_count');
        final pageCount = result.first['page_count'] as int;
        final result2 = await db.rawQuery('PRAGMA page_size');
        final pageSize = result2.first['page_size'] as int;
        stats['database_size_bytes'] = pageCount * pageSize;
      } catch (e) {
        stats['database_size_bytes'] = 'ERROR: ${e.toString()}';
      }
      
      return stats;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do banco: $e');
      return {'error': e.toString()};
    }
  }

  /// Limpa dados órfãos (sem referência)
  Future<void> cleanupOrphanedData() async {
    try {
      Logger.info('🧹 Iniciando limpeza de dados órfãos...');
      
      final db = await AppDatabase.instance.database;
      
      // Limpar plantios órfãos (sem talhão)
      await db.execute('''
        DELETE FROM plantios 
        WHERE talhao_id NOT IN (SELECT id FROM talhoes)
      ''');
      
      // Limpar monitoramentos órfãos (sem talhão)
      await db.execute('''
        DELETE FROM monitorings 
        WHERE talhao_id NOT IN (SELECT id FROM talhoes)
      ''');
      
      // Limpar polígonos órfãos (sem talhão)
      await db.execute('''
        DELETE FROM poligonos 
        WHERE idTalhao NOT IN (SELECT id FROM talhoes)
      ''');
      
      Logger.info('✅ Limpeza de dados órfãos concluída');
    } catch (e) {
      Logger.error('❌ Erro na limpeza de dados órfãos: $e');
    }
  }
}
