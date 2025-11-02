import 'package:sqflite/sqflite.dart';

/// Classe responsável por criar e migrar a tabela de talhões premium
class TalhoesPremiumMigration {
  /// Cria a tabela de talhões premium se ela não existir
  static Future<void> createTalhoesTable(Database db) async {
    // Verificar se a tabela já existe
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
    );
    
    if (result.isEmpty) {
      // Criar a tabela de talhões premium
      await db.execute('''
        CREATE TABLE talhoes (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          idFazenda TEXT NOT NULL,
          poligonos TEXT NOT NULL,
          safras TEXT NOT NULL,
          dataCriacao TEXT NOT NULL,
          dataAtualizacao TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          device_id TEXT
        )
      ''');
      
      // Criar índices para melhorar a performance
      await db.execute('CREATE INDEX idx_talhoes_fazenda_id ON talhoes (idFazenda)');
    }
  }
  
  /// Migra dados da tabela plots para a tabela talhoes, se necessário
  static Future<void> migrateFromPlotsIfNeeded(Database db) async {
    // Verificar se a tabela plots existe
    final plotsExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='plots'"
    );
    
    if (plotsExists.isNotEmpty) {
      // Verificar se há dados para migrar
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM plots'));
      
      if (count != null && count > 0) {
        // Obter todos os plots
        final plots = await db.query('plots');
        
        // Migrar cada plot para a tabela talhoes
        for (var plot in plots) {
          try {
            // Converter para o formato esperado pela tabela talhoes
            final now = DateTime.now().toIso8601String();
            
            // Extrair coordenadas e converter para o formato de polígono
            String poligonoJson = '[]';
            if (plot['coordinates'] != null) {
              try {
                // As coordenadas podem estar em diferentes formatos, tentar converter
                poligonoJson = '[{"id":"${DateTime.now().millisecondsSinceEpoch}","pontos":${plot['coordinates']}}]';
              } catch (e) {
                print('Erro ao converter coordenadas: $e');
              }
            }
            
            // Criar registro na tabela talhoes
            await db.insert('talhoes', {
              'id': plot['id'].toString(),
              'name': plot['name'],
              'idFazenda': plot['farmId'].toString(),
              'poligonos': poligonoJson,
              'safras': '[]', // Safras vazias inicialmente
              'dataCriacao': now,
              'dataAtualizacao': now,
              'sincronizado': plot['isSynced'] ?? 0,
              'device_id': plot['device_id'],
            });
          } catch (e) {
            print('Erro ao migrar plot ${plot['id']}: $e');
          }
        }
        
        print('Migração de plots para talhoes concluída');
      }
    }
  }
  
  /// Executa todas as migrações necessárias
  static Future<void> migrate(Database db) async {
    await createTalhoesTable(db);
    await migrateFromPlotsIfNeeded(db);
  }
}
