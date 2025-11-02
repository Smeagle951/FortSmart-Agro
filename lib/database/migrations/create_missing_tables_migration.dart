import 'package:sqflite/sqflite.dart';

/// Migração para criar as tabelas que estão faltando no banco de dados
/// Baseado no diagnóstico que mostra que as tabelas plantings e harvest_losses não existem
class CreateMissingTablesMigration {
  /// Executa a migração para criar as tabelas faltantes
  static Future<void> executeMigration(Database db) async {
    await db.transaction((txn) async {
      // Criar tabela plantings (plantios)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS plantings (
          id TEXT PRIMARY KEY,
          talhaoId TEXT NOT NULL,
          safraId TEXT,
          culturaId TEXT,
          atividadeId TEXT,
          dataPlantio TEXT NOT NULL,
          espacamento REAL,
          populacao REAL,
          densidade REAL,
          germinacao REAL,
          metodoCalibragem TEXT,
          fonteEstoqueId TEXT,
          fonteEstoqueNome TEXT,
          sementesHa INTEGER,
          kgHa REAL,
          sacasHa REAL,
          sementesPorMetroLinear REAL,
          fotoPath TEXT,
          latitude REAL,
          longitude REAL,
          observacoes TEXT,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          criadoEm TEXT NOT NULL,
          atualizadoEm TEXT NOT NULL,
          FOREIGN KEY (talhaoId) REFERENCES talhoes_unificados(id) ON DELETE CASCADE
        )
      ''');

      // Criar tabela harvest_losses (perdas na colheita)
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS harvest_losses (
          id TEXT PRIMARY KEY,
          talhaoId TEXT NOT NULL,
          safraId TEXT,
          culturaId TEXT,
          atividadeId TEXT,
          dataColheita TEXT NOT NULL,
          tipoPerda TEXT NOT NULL,
          percentualPerda REAL NOT NULL,
          areaAfetada REAL,
          observacoes TEXT,
          fotoPath TEXT,
          latitude REAL,
          longitude REAL,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          criadoEm TEXT NOT NULL,
          atualizadoEm TEXT NOT NULL,
          FOREIGN KEY (talhaoId) REFERENCES talhoes_unificados(id) ON DELETE CASCADE
        )
      ''');

      // Criar índices para melhorar performance
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_plantings_talhaoId ON plantings (talhaoId)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_plantings_dataPlantio ON plantings (dataPlantio)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_plantings_sincronizado ON plantings (sincronizado)');
      
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_harvest_losses_talhaoId ON harvest_losses (talhaoId)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_harvest_losses_dataColheita ON harvest_losses (dataColheita)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_harvest_losses_sincronizado ON harvest_losses (sincronizado)');

      print('Migração de tabelas faltantes aplicada com sucesso.');
      print('Tabelas criadas: plantings, harvest_losses');
    });
  }

  /// Verifica se as tabelas foram criadas corretamente
  static Future<Map<String, bool>> verifyTables(Database db) async {
    final tables = ['plantings', 'harvest_losses'];
    final results = <String, bool>{};

    for (final table in tables) {
      final result = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', table],
      );
      results[table] = result.isNotEmpty;
    }

    return results;
  }
} 