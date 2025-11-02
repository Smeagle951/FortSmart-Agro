import 'package:sqflite/sqflite.dart';

class ForceFixPlantioTable {
  static Future<void> forceFixPlantioTable(Database db) async {
    try {
      print('🔧 FORÇANDO correção da tabela plantio...');
      
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
        print('🔄 FORÇANDO atualização da tabela plantio...');
        
        // Fazer backup dos dados existentes
        final existingData = await db.rawQuery('SELECT * FROM plantio');
        print('📊 Dados existentes para backup: ${existingData.length} registros');
        
        // Dropar e recriar tabela com estrutura correta
        await db.execute('DROP TABLE IF EXISTS plantio');
        print('🗑️ Tabela plantio removida');
        
        await _createPlantioTable(db);
        print('✅ Nova tabela plantio criada com estrutura completa');
        
        // Restaurar dados existentes (apenas colunas compatíveis)
        int restoredCount = 0;
        for (final row in existingData) {
          try {
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
            restoredCount++;
          } catch (e) {
            print('⚠️ Erro ao restaurar registro ${row['id']}: $e');
          }
        }
        
        print('✅ Tabela plantio atualizada com sucesso!');
        print('📊 ${restoredCount} registros restaurados de ${existingData.length}');
      } else {
        print('✅ Tabela plantio já tem estrutura correta');
      }
      
      // Verificar estrutura final
      final finalColumns = await db.rawQuery("PRAGMA table_info(plantio)");
      final finalColumnNames = finalColumns.map((col) => col['name'] as String).toList();
      print('📋 Estrutura final da tabela plantio: $finalColumnNames');
      
    } catch (e) {
      print('❌ Erro ao forçar correção da tabela plantio: $e');
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
