import 'package:sqflite/sqflite.dart';

/// Migração para corrigir a tabela monitoring_sessions
class FixMonitoringSessionsTable {
  static Future<void> fixMonitoringSessionsTable(Database db) async {
    try {
      print('🔄 Corrigindo tabela monitoring_sessions...');
      
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_sessions'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela monitoring_sessions não existe, criando...');
        await _createMonitoringSessionsTable(db);
        return;
      }
      
      // Verificar colunas existentes
      final columns = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      print('📋 Colunas existentes: $columnNames');
      
      // Adicionar colunas faltantes
      final missingColumns = [
        'talhao_nome',
        'cultura_nome', 
        'total_pontos',
        'total_ocorrencias',
        'data_inicio',
        'data_fim',
        'tecnico_nome',
        'observacoes'
      ];
      
      // Verificar se started_at tem valor padrão
      if (columnNames.contains('started_at')) {
        print('🔧 Corrigindo coluna started_at...');
        try {
          // Adicionar valor padrão para started_at se não tiver
          await db.execute('UPDATE monitoring_sessions SET started_at = created_at WHERE started_at IS NULL');
          print('✅ Coluna started_at corrigida');
        } catch (e) {
          print('⚠️ Erro ao corrigir started_at: $e');
        }
      }
      
      for (final column in missingColumns) {
        if (!columnNames.contains(column)) {
          print('➕ Adicionando coluna: $column');
          
          String columnType;
          String defaultValue;
          
          switch (column) {
            case 'talhao_nome':
            case 'cultura_nome':
            case 'tecnico_nome':
            case 'observacoes':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            case 'total_pontos':
            case 'total_ocorrencias':
              columnType = 'INTEGER';
              defaultValue = '0';
              break;
            case 'data_inicio':
            case 'data_fim':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            default:
              columnType = 'TEXT';
              defaultValue = "''";
          }
          
          await db.execute('ALTER TABLE monitoring_sessions ADD COLUMN $column $columnType DEFAULT $defaultValue');
          print('✅ Coluna $column adicionada');
        } else {
          print('✅ Coluna $column já existe');
        }
      }
      
      print('✅ Tabela monitoring_sessions corrigida com sucesso');
      
    } catch (e) {
      print('❌ Erro ao corrigir tabela monitoring_sessions: $e');
      rethrow;
    }
  }
  
  static Future<void> _createMonitoringSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_sessions (
        id TEXT PRIMARY KEY,
        fazenda_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        total_pontos INTEGER NOT NULL DEFAULT 0,
        total_ocorrencias INTEGER NOT NULL DEFAULT 0,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        tecnico_nome TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
