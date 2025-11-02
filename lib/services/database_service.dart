import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/device_id_manager.dart';

/// Serviço para operações genéricas no banco de dados
class DatabaseService {
  final AppDatabase _databaseHelper = AppDatabase();
  
  /// Obtém uma instância do banco de dados, garantindo que esteja aberto
  Future<Database> get database async => await _databaseHelper.database;
  
  /// Executa uma consulta SQL direta no banco de dados
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Executa uma inserção SQL direta no banco de dados
  Future<int> insert(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  /// Insere dados em uma tabela
  Future<int> insertData(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(tableName, data);
  }

  /// Consulta dados de uma tabela com condições
  Future<List<Map<String, dynamic>>> queryData(
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Atualiza dados em uma tabela
  Future<int> updateData(
    String tableName,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      tableName,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Remove dados de uma tabela
  Future<int> deleteData(
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Executa uma atualização SQL direta no banco de dados
  Future<int> update(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  /// Executa uma operação SQL que não retorna dados
  Future<void> execute(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Obtém todos os talhões do banco de dados
  Future<List<Map<String, dynamic>>> getTalhoes({String? fazendaId}) async {
    try {
      if (fazendaId != null) {
        return await queryData(
          'talhoes',
          where: 'idFazenda = ?',
          whereArgs: [fazendaId],
        );
      } else {
        return await queryData('talhoes');
      }
    } catch (e) {
      print('Erro ao obter talhões: $e');
      return [];
    }
  }

  /// Executa uma transação no banco de dados
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    final db = await database;
    return await db.transaction(action, exclusive: exclusive);
  }

  /// Verifica se uma tabela existe no banco de dados
  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtém informações sobre as colunas de uma tabela
  Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    try {
      final db = await database;
      return await db.rawQuery('PRAGMA table_info($tableName)');
    } catch (e) {
      return [];
    }
  }

  /// Obtém a versão atual do banco de dados
  Future<int> getDatabaseVersion() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA user_version');
      return result.first['user_version'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Define a versão do banco de dados
  Future<void> setDatabaseVersion(int version) async {
    try {
      final db = await database;
      await db.execute('PRAGMA user_version = $version');
    } catch (e) {
      // Ignora erros ao definir versão
    }
  }

  /// Obtém estatísticas do banco de dados
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await database;
      
      // Tamanho do banco
      final sizeResult = await db.rawQuery('PRAGMA page_count');
      final pageCount = sizeResult.first['page_count'] as int;
      final pageSizeResult = await db.rawQuery('PRAGMA page_size');
      final pageSize = pageSizeResult.first['page_size'] as int;
      final sizeInBytes = pageCount * pageSize;
      
      // Lista de tabelas
      final tablesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      final tables = tablesResult.map((row) => row['name'] as String).toList();
      
      // Contagem de registros por tabela
      final tableCounts = <String, int>{};
      for (final table in tables) {
        try {
          final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          tableCounts[table] = countResult.first['count'] as int;
        } catch (e) {
          tableCounts[table] = 0;
        }
      }
      
      return {
        'size_in_bytes': sizeInBytes,
        'page_count': pageCount,
        'page_size': pageSize,
        'tables': tables,
        'table_counts': tableCounts,
      };
    } catch (e) {
      return {
        'size_in_bytes': 0,
        'page_count': 0,
        'page_size': 0,
        'tables': [],
        'table_counts': {},
      };
    }
  }

  /// Limpa registros antigos de uma tabela
  Future<int> cleanupOldRecords(
    String tableName, {
    required String dateColumn,
    required int daysToKeep,
  }) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final result = await db.delete(
        tableName,
        where: '$dateColumn < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      return result;
    } catch (e) {
      return 0;
    }
  }

  /// Atualiza o device_id para registros que não o possuem
  Future<void> updateMissingDeviceIds(String tableName) async {
    try {
      final db = await database;
      
      // Atualizar registros existentes com o device_id atual
      final deviceId = await DeviceIdManager.getDeviceId();
      await db.update(
        tableName,
        {'device_id': deviceId},
        where: 'device_id IS NULL',
      );
    } catch (e) {
      // Ignora erros ao atualizar device_ids
    }
  }
}
