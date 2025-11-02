import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../services/data_cache_service.dart';
import '../services/contexto_agricola_service.dart';

/// Serviço para migração de dados entre versões do banco
class MigracaoService {
  final AppDatabase _database = AppDatabase();
  final DataCacheService _dataCacheService = DataCacheService();
  final ContextoAgricolaService _contextoAgricola = ContextoAgricolaService();

  /// Migra os dados da tabela de experimentos para o novo formato
  Future<void> migrarExperimentos() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;

    // Verifica se a coluna safra_id existe
    var tableInfo = await db.rawQuery("PRAGMA table_info('experimentos')");
    bool temColunaSafra = tableInfo.any((column) => column['name'] == 'safra_id');

    if (!temColunaSafra) {
      // Backup da tabela antiga
      await db.execute('ALTER TABLE experimentos RENAME TO experimentos_old');

      // Criar nova tabela com a estrutura atualizada
      await db.execute('''
        CREATE TABLE experimentos (
          id TEXT PRIMARY KEY,
          nome TEXT NOT NULL,
          talhao_id TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          variedade_id TEXT NOT NULL,
          safra_id TEXT NOT NULL,
          area REAL NOT NULL,
          descricao TEXT NOT NULL,
          data_inicio TEXT NOT NULL,
          data_fim TEXT,
          observacoes TEXT,
          fotos TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Migrar dados da tabela antiga para a nova
      var experimentos = await db.query('experimentos_old');
      
      for (var exp in experimentos) {
        try {
          // Converter IDs para String
          String talhaoId = exp['talhao_id'].toString();
          
          // Obter safra atual do talhão
          var contexto = await _contextoAgricola.carregarContextoDoTalhao(talhaoId);
          var safraAtual = contexto['safra'];
          
          if (safraAtual != null) {
            await db.insert('experimentos', {
              'id': exp['id'].toString(),
              'nome': exp['nome'],
              'talhao_id': talhaoId,
              'cultura_id': exp['cultura_id'].toString(),
              'variedade_id': exp['variedade_id'].toString(),
              'safra_id': safraAtual.id,
              'area': exp['area'],
              'descricao': exp['descricao'],
              'data_inicio': exp['data_inicio'],
              'data_fim': exp['data_fim'],
              'observacoes': exp['observacoes'],
              'fotos': exp['fotos'],
              'created_at': exp['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          print('Erro ao migrar experimento ${exp['id']}: $e');
          // Continue com o próximo registro em caso de erro
          continue;
        }
      }

      // Remover tabela antiga após migração bem-sucedida
      await db.execute('DROP TABLE IF EXISTS experimentos_old');
    }
  }
}
