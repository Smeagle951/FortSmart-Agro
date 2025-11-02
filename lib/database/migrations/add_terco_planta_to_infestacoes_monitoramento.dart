import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

/// Migração para adicionar o campo terco_planta na tabela infestacoes_monitoramento
class AddTercoPlantaToInfestacoesMonitoramento {
  static const int version = 1;
  static const String description = 'Adiciona campo terco_planta na tabela infestacoes_monitoramento';

  /// Executa a migração
  static Future<void> migrate(Database db) async {
    try {
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='infestacoes_monitoramento'"
      );
      
      if (tables.isNotEmpty) {
        // Verificar se a coluna já existe
        final columns = await db.rawQuery("PRAGMA table_info(infestacoes_monitoramento)");
        final hasTercoPlanta = columns.any((column) => column['name'] == 'terco_planta');
        
        if (!hasTercoPlanta) {
          // Adicionar a coluna terco_planta
          await db.execute('''
            ALTER TABLE infestacoes_monitoramento 
            ADD COLUMN terco_planta TEXT
          ''');
          
          print('✅ Campo terco_planta adicionado à tabela infestacoes_monitoramento');
        } else {
          print('ℹ️ Campo terco_planta já existe na tabela infestacoes_monitoramento');
        }
      } else {
        // Criar a tabela se não existir
        await db.execute('''
          CREATE TABLE IF NOT EXISTS infestacoes_monitoramento (
            id TEXT PRIMARY KEY,
            talhao_id INTEGER NOT NULL,
            ponto_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            tipo TEXT NOT NULL,
            subtipo TEXT NOT NULL,
            terco_planta TEXT,
            nivel TEXT,
            quantidade INTEGER,
            observacao TEXT,
            foto_path TEXT,
            data_hora TEXT NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        print('✅ Tabela infestacoes_monitoramento criada com campo terco_planta');
      }
    } catch (e) {
      print('❌ Erro ao executar migração terco_planta: $e');
      rethrow;
    }
  }
}
