import 'package:sqflite/sqflite.dart';
import '../../utils/logger.dart';

/// Classe responsável por realizar as migrações necessárias para integrar
/// os módulos agrícolas com o contexto de Talhão, Safra e Cultura
class AgricultureIntegrationMigration {
  final Database db;
  final Logger _logger = Logger('AgricultureIntegrationMigration');

  AgricultureIntegrationMigration(this.db);

  /// Realiza todas as migrações necessárias para a integração dos módulos agrícolas
  Future<void> migrateAll() async {
    await _addContextColumnsToTables();
    await _backfillContextIds();
  }

  /// Adiciona as colunas talhaoId, safraId e culturaId às tabelas de atividades agrícolas
  Future<void> _addContextColumnsToTables() async {
    try {
      _logger.info('Iniciando adição de colunas de contexto agrícola às tabelas...');
      
      // Lista de tabelas que precisam ser atualizadas
      final tables = [
        'plantio',
        'colheita',
        'monitoramento',
        'aplicacao',
        'historico_atividades'
      ];
      
      // Adiciona as colunas a cada tabela
      for (final table in tables) {
        await _addColumnIfNotExists(table, 'talhaoId', 'TEXT');
        await _addColumnIfNotExists(table, 'safraId', 'TEXT');
        await _addColumnIfNotExists(table, 'culturaId', 'TEXT');
      }
      
      print('Colunas de contexto agrícola adicionadas com sucesso às tabelas.');
    } catch (e) {
      print('Erro ao adicionar colunas de contexto agrícola às tabelas: $e');
      rethrow;
    }
  }
  
  /// Verifica se uma coluna existe na tabela e, se não existir, adiciona
  Future<void> _addColumnIfNotExists(String table, String column, String type) async {
    try {
      // Verificar se a coluna já existe
      final result = await db.rawQuery("PRAGMA table_info($table)");
      final columnExists = result.any((col) => col['name'] == column);
      
      if (!columnExists) {
        print('Adicionando coluna $column à tabela $table');
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      } else {
        print('Coluna $column já existe na tabela $table. Pulando...');
      }
    } catch (e) {
      print('Erro ao adicionar coluna $column à tabela $table: $e');
      rethrow;
    }
  }
  
  /// Preenche automaticamente os IDs de contexto (safraId e culturaId) com base nos talhaoId existentes
  Future<void> _backfillContextIds() async {
    try {
      print('Iniciando preenchimento automático de contexto agrícola...');
      
      // Lista de tabelas que precisam ser atualizadas
      final tables = [
        'plantio',
        'colheita',
        'monitoramento',
        'aplicacao',
        'historico_atividades'
      ];
      
      // Para cada tabela, procurar registros que já tenham talhaoId mas não tenham safraId ou culturaId
      for (final table in tables) {
        // Obter registros que têm talhaoId mas não têm safraId ou culturaId
        final registros = await db.query(
          table,
          where: 'talhaoId IS NOT NULL AND (safraId IS NULL OR culturaId IS NULL)',
        );
        
        print('Encontrados ${registros.length} registros para preenchimento na tabela $table');
        
        // Preencher safraId e culturaId para cada registro
        for (final registro in registros) {
          final talhaoId = registro['talhaoId'] as String?;
          
          if (talhaoId != null && talhaoId.isNotEmpty) {
            // Buscar a safra atual/mais recente associada ao talhão
            final safras = await db.query(
              'safra',
              where: 'talhaoId = ?',
              whereArgs: [talhaoId],
              orderBy: 'dataInicio DESC',
              limit: 1,
            );
            
            if (safras.isNotEmpty) {
              final safra = safras.first;
              final safraId = safra['id'] as String?;
              final culturaId = safra['culturaId'] as String?;
              
              if (safraId != null) {
                // Atualizar o registro com safraId e culturaId
                await db.update(
                  table,
                  {
                    'safraId': safraId,
                    if (culturaId != null) 'culturaId': culturaId,
                  },
                  where: 'id = ?',
                  whereArgs: [registro['id']],
                );
                
                print('Registro ${registro['id']} da tabela $table atualizado com safraId=$safraId, culturaId=$culturaId');
              }
            }
          }
        }
      }
      
      print('Preenchimento automático de contexto agrícola concluído com sucesso.');
    } catch (e) {
      print('Erro ao preencher automaticamente dados de contexto agrícola: $e');
      rethrow;
    }
  }
}
