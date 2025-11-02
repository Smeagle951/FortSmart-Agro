import 'package:sqflite/sqflite.dart';

class FixPlantioTableSubareaId {
  static Future<void> up(Database db) async {
    try {
      print('🔧 Verificando e corrigindo estrutura da tabela plantio...');
      
      // Verificar se a tabela plantio existe
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plantio'"
      );
      
      if (tableExists.isEmpty) {
        print('⚠️ Tabela plantio não existe. Criando...');
        await _createPlantioTable(db);
        return;
      }
      
      // Verificar estrutura atual da tabela
      final columns = await db.rawQuery("PRAGMA table_info(plantio)");
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      print('📋 Colunas atuais da tabela plantio: $columnNames');
      
      // Verificar se precisa adicionar colunas
      final needsSubareaId = !columnNames.contains('subarea_id');
      final needsVariedade = !columnNames.contains('variedade');
      final needsEspacamentoCm = !columnNames.contains('espacamento_cm');
      final needsPopulacaoPorM = !columnNames.contains('populacao_por_m');
      
      if (needsSubareaId || needsVariedade || needsEspacamentoCm || needsPopulacaoPorM) {
        print('🔄 Adicionando colunas faltantes à tabela plantio...');
        
        // Fazer backup dos dados existentes
        final existingData = await db.rawQuery('SELECT * FROM plantio');
        
        // Dropar e recriar tabela com estrutura correta
        await db.execute('DROP TABLE IF EXISTS plantio');
        
        await _createPlantioTable(db);
        
        // Restaurar dados existentes (apenas colunas compatíveis)
        for (final row in existingData) {
          await db.insert('plantio', {
            'id': row['id'],
            'talhao_id': row['talhao_id'],
            'subarea_id': null, // Nova coluna
            'cultura': row['cultura'] ?? '',
            'variedade': row['variedade'] ?? '', // Nova coluna
            'data_plantio': row['data_plantio'],
            'espacamento_cm': row['espacamento_cm'] ?? 0.0, // Nova coluna
            'populacao_por_m': row['populacao_por_m'] ?? 0.0, // Nova coluna
            'observacao': row['observacao'],
            'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
            'deleted_at': row['deleted_at'],
          });
        }
        
        print('✅ Tabela plantio atualizada com sucesso!');
      } else {
        print('✅ Tabela plantio já tem estrutura correta');
      }
      
    } catch (e) {
      print('❌ Erro ao corrigir tabela plantio: $e');
      rethrow;
    }
  }
  
  static Future<void> _createPlantioTable(Database db) async {
    await db.execute('''
      CREATE TABLE plantio (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        subarea_id TEXT,
        cultura TEXT NOT NULL,
        variedade TEXT NOT NULL,
        data_plantio TEXT NOT NULL,
        espacamento_cm REAL NOT NULL,
        populacao_por_m REAL NOT NULL,
        observacao TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (talhao_id) REFERENCES talhao_safra(id),
        FOREIGN KEY (subarea_id) REFERENCES subarea(id)
      )
    ''');
    
    print('✅ Tabela plantio criada com estrutura completa');
  }
}
