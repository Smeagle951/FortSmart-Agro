import 'package:sqflite/sqflite.dart';

/// Migração para corrigir a tabela planting_cv adicionando colunas faltantes
class FixPlantingCVTable {
  static Future<void> fixPlantingCVTable(Database db) async {
    print('🔄 Corrigindo tabela planting_cv - adicionando colunas faltantes...');
    
    try {
      // Verificar se a tabela existe
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='planting_cv'"
      );
      
      if (tableCheck.isEmpty) {
        print('⚠️ Tabela planting_cv não existe. Criando...');
        await _createPlantingCVTable(db);
        return;
      }
      
      // Verificar colunas existentes
      final columns = await db.rawQuery('PRAGMA table_info(planting_cv)');
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      print('📋 Colunas existentes: $columnNames');
      
      // Adicionar colunas faltantes
      final missingColumns = [
        'sugestoes',
        'motivo_resultado',
        'detalhes_calculo',
        'metricas_detalhadas'
      ];
      
      for (final column in missingColumns) {
        if (!columnNames.contains(column)) {
          print('➕ Adicionando coluna: $column');
          
          String columnType;
          String defaultValue;
          
          switch (column) {
            case 'sugestoes':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            case 'motivo_resultado':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            case 'detalhes_calculo':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            case 'metricas_detalhadas':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            default:
              columnType = 'TEXT';
              defaultValue = "''";
          }
          
          await db.execute('ALTER TABLE planting_cv ADD COLUMN $column $columnType DEFAULT $defaultValue');
          print('✅ Coluna $column adicionada com sucesso');
        } else {
          print('✅ Coluna $column já existe');
        }
      }
      
      print('✅ Tabela planting_cv corrigida com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao corrigir tabela planting_cv: $e');
      rethrow;
    }
  }
  
  /// Cria a tabela planting_cv se não existir
  static Future<void> _createPlantingCVTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS planting_cv (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        data_plantio TEXT NOT NULL,
        comprimento_linha_amostrada REAL NOT NULL,
        espacamento_entre_linhas REAL NOT NULL,
        distancias_entre_sementes TEXT NOT NULL,
        media_espacamento REAL NOT NULL,
        desvio_padrao REAL NOT NULL,
        coeficiente_variacao REAL NOT NULL,
        plantas_por_metro REAL NOT NULL,
        populacao_estimada_hectare REAL NOT NULL,
        classificacao TEXT NOT NULL,
        observacoes TEXT,
        meta_populacao_hectare REAL,
        meta_plantas_metro REAL,
        diferenca_populacao_percentual REAL,
        diferenca_plantas_metro_percentual REAL,
        status_comparacao_populacao TEXT,
        status_comparacao_plantas_metro TEXT,
        sugestoes TEXT DEFAULT '',
        motivo_resultado TEXT DEFAULT '',
        detalhes_calculo TEXT DEFAULT '',
        metricas_detalhadas TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');
    
    // Criar índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_talhao_id ON planting_cv (talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_cultura_id ON planting_cv (cultura_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_data_plantio ON planting_cv (data_plantio)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_sync_status ON planting_cv (sync_status)');
    
    print('✅ Tabela planting_cv criada com todas as colunas!');
  }
}
