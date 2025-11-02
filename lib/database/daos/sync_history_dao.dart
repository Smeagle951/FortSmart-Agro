// TEMPORARIAMENTE COMENTADO - MODELO SYNC_HISTORY NÃO EXISTE
/*
import 'package:sqflite/sqflite.dart';
// import '../../models/sync_history.dart'; // Modelo não existe ainda
import '../app_database.dart';
import '../../utils/logger.dart';

/// DAO para operações de banco de dados relacionadas ao histórico de sincronização
class SyncHistoryDao {
  static final SyncHistoryDao _instance = SyncHistoryDao._internal();
  final AppDatabase _database = AppDatabase();
  final TaggedLogger _logger = TaggedLogger('SyncHistoryDao');

  factory SyncHistoryDao() {
    return _instance;
  }

  SyncHistoryDao._internal();

  /// Obtém uma instância do banco de dados
  Future<Database> get database async => await _database.database;

  /// Obtém todo o histórico de sincronização
  Future<List<SyncHistory>> getAllHistory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sync_history',
        orderBy: 'syncDate DESC',
      );
      return List.generate(maps.length, (i) {
        return SyncHistory.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.severe('Erro ao obter histórico de sincronização: $e');
      return [];
    }
  }

  /// Obtém o último registro de sincronização
  Future<SyncHistory?> getLastSync() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sync_history',
        orderBy: 'syncDate DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SyncHistory.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.severe('Erro ao obter último registro de sincronização: $e');
      return null;
    }
  }

  /// Insere um novo registro de histórico de sincronização
  Future<int> insertHistory(SyncHistory history) async {
    try {
      final db = await database;
      return await db.insert('sync_history', history.toMap());
    } catch (e) {
      _logger.severe('Erro ao inserir histórico de sincronização: $e');
      return -1;
    }
  }

  /// Limpa o histórico de sincronização, mantendo apenas os registros mais recentes
  Future<int> cleanupHistory(int keepLastN) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sync_history',
        orderBy: 'syncDate DESC',
      );

      if (maps.length <= keepLastN) {
        return 0; // Não há registros suficientes para limpar
      }

      // Obter o ID do último registro a ser mantido
      final lastIdToKeep = maps[keepLastN - 1]['id'];

      // Excluir todos os registros mais antigos
      return await db.delete(
        'sync_history',
        where: 'syncDate < (SELECT syncDate FROM sync_history WHERE id = ?)',
        whereArgs: [lastIdToKeep],
      );
    } catch (e) {
      _logger.severe('Erro ao limpar histórico de sincronização: $e');
      return 0;
    }
  }
}
*/
