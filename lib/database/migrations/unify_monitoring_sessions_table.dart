import 'package:sqflite/sqflite.dart';
import '../../utils/logger.dart';

/// Unifica e corrige a estrutura da tabela monitoring_sessions
/// 
/// PROBLEMA IDENTIFICADO:
/// - Existem duas definições diferentes da tabela em diferentes partes do código
/// - Algumas partes usam `data_inicio/data_fim`, outras usam `started_at/finished_at`
/// - Algumas incluem `talhao_nome`, outras não
/// 
/// SOLUÇÃO:
/// - Garantir que a tabela tenha TODAS as colunas necessárias
/// - Manter compatibilidade com ambos os esquemas
class UnifyMonitoringSessionsTable {
  
  static Future<void> execute(Database db) async {
    try {
      Logger.info('🔄 Unificando estrutura da tabela monitoring_sessions...');
      
      // 1. Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_sessions'"
      );
      
      if (tables.isEmpty) {
        Logger.info('📋 Criando tabela monitoring_sessions do zero...');
        await _createUnifiedTable(db);
        return;
      }
      
      // 2. Verificar colunas existentes
      final columns = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      Logger.info('📋 Colunas existentes: ${columnNames.join(', ')}');
      
      // 3. Adicionar todas as colunas necessárias se não existirem
      final requiredColumns = {
        'id': 'TEXT PRIMARY KEY',
        'fazenda_id': 'TEXT',
        'talhao_id': 'TEXT',
        'cultura_id': 'TEXT',
        'talhao_nome': 'TEXT',  // ✅ Necessário
        'cultura_nome': 'TEXT', // ✅ Necessário
        'total_pontos': 'INTEGER DEFAULT 0',
        'total_ocorrencias': 'INTEGER DEFAULT 0',
        'amostragem_padrao_plantas_por_ponto': 'INTEGER DEFAULT 10',
        'data_inicio': 'TEXT',  // ✅ Compatibilidade
        'data_fim': 'TEXT',     // ✅ Compatibilidade
        'started_at': 'TEXT',   // ✅ Compatibilidade
        'finished_at': 'TEXT',  // ✅ Compatibilidade
        'status': 'TEXT DEFAULT \'draft\'',
        'tecnico_nome': 'TEXT',
        'observacoes': 'TEXT',
        'device_id': 'TEXT',
        'catalog_version': 'TEXT',
        'sync_state': 'TEXT DEFAULT \'pending\'',
        'sync_error': 'TEXT',
        'retry_count': 'INTEGER DEFAULT 0',
        'created_at': 'TEXT',
        'updated_at': 'TEXT',
      };
      
      // 4. Adicionar colunas faltantes
      for (final entry in requiredColumns.entries) {
        final columnName = entry.key;
        final columnDef = entry.value;
        
        if (!columnNames.contains(columnName) && columnName != 'id') {
          try {
            Logger.info('➕ Adicionando coluna: $columnName');
            await db.execute('ALTER TABLE monitoring_sessions ADD COLUMN $columnName $columnDef');
            Logger.info('✅ Coluna $columnName adicionada');
          } catch (e) {
            Logger.warning('⚠️ Erro ao adicionar coluna $columnName: $e');
          }
        }
      }
      
      // 5. Sincronizar dados entre colunas duplicadas
      await _syncDuplicateColumns(db);
      
      // 6. Criar índices necessários
      await _createIndexes(db);
      
      Logger.info('✅ Tabela monitoring_sessions unificada com sucesso!');
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao unificar tabela monitoring_sessions: $e', e, stack);
      rethrow;
    }
  }
  
  /// Sincroniza dados entre colunas duplicadas
  static Future<void> _syncDuplicateColumns(Database db) async {
    try {
      Logger.info('🔄 Sincronizando colunas duplicadas...');
      
      // Sincronizar started_at <-> data_inicio
      await db.execute('''
        UPDATE monitoring_sessions 
        SET started_at = data_inicio 
        WHERE started_at IS NULL AND data_inicio IS NOT NULL
      ''');
      
      await db.execute('''
        UPDATE monitoring_sessions 
        SET data_inicio = started_at 
        WHERE data_inicio IS NULL AND started_at IS NOT NULL
      ''');
      
      // Sincronizar finished_at <-> data_fim
      await db.execute('''
        UPDATE monitoring_sessions 
        SET finished_at = data_fim 
        WHERE finished_at IS NULL AND data_fim IS NOT NULL
      ''');
      
      await db.execute('''
        UPDATE monitoring_sessions 
        SET data_fim = finished_at 
        WHERE data_fim IS NULL AND finished_at IS NOT NULL
      ''');
      
      Logger.info('✅ Colunas sincronizadas');
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao sincronizar colunas: $e');
    }
  }
  
  /// Cria índices necessários
  static Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_talhao ON monitoring_sessions(talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_status ON monitoring_sessions(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_sync ON monitoring_sessions(sync_state)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_created ON monitoring_sessions(created_at)');
      
      Logger.info('✅ Índices criados');
    } catch (e) {
      Logger.warning('⚠️ Erro ao criar índices: $e');
    }
  }
  
  /// Cria a tabela unificada do zero
  static Future<void> _createUnifiedTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_sessions (
        id TEXT PRIMARY KEY,
        fazenda_id TEXT,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        talhao_nome TEXT,
        cultura_nome TEXT,
        total_pontos INTEGER DEFAULT 0,
        total_ocorrencias INTEGER DEFAULT 0,
        amostragem_padrao_plantas_por_ponto INTEGER DEFAULT 10,
        data_inicio TEXT,
        data_fim TEXT,
        started_at TEXT,
        finished_at TEXT,
        status TEXT DEFAULT 'draft',
        tecnico_nome TEXT,
        observacoes TEXT,
        device_id TEXT,
        catalog_version TEXT,
        sync_state TEXT DEFAULT 'pending',
        sync_error TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    await _createIndexes(db);
    
    Logger.info('✅ Tabela unificada criada');
  }
}

