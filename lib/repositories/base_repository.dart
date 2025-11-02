import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/database_cache_manager.dart';

/// Repositório base que implementa operações comuns de banco de dados
/// com suporte a cache e tratamento de erros
abstract class BaseRepository<T> {
  final AppDatabase _database = AppDatabase();
  final DatabaseCacheManager _cacheManager = DatabaseCacheManager();
  
  /// Nome da tabela no banco de dados
  String get tableName;
  
  /// Nome da entidade para o cache
  String get entityName;
  
  /// Converte um mapa para uma entidade
  T fromMap(Map<String, dynamic> map);
  
  /// Converte uma entidade para um mapa
  Map<String, dynamic> toMap(T entity);
  
  /// Obtém o ID de uma entidade
  String getId(T entity);
  
  /// Insere uma entidade no banco de dados
  Future<String> insert(T entity) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      final entityId = getId(entity);
      await db.transaction((txn) async {
        await txn.insert(
          tableName,
          toMap(entity),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      // Atualiza o cache
      _cacheManager.put(entityName, entityId, entity);
      return entityId;
    } catch (e) {
      print('Erro ao inserir $entityName: $e');
      rethrow;
    }
  }
  
  /// Atualiza uma entidade no banco de dados
  Future<int> update(T entity) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      final id = getId(entity);
      int result = 0;
      await db.transaction((txn) async {
        result = await txn.update(
          tableName,
          toMap(entity),
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      // Atualiza o cache
      _cacheManager.put(entityName, id, entity);
      return result;
    } catch (e) {
      print('Erro ao atualizar $entityName: $e');
      rethrow;
    }
  }
  
  /// Remove uma entidade do banco de dados
  Future<int> delete(String id) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      int result = 0;
      await db.transaction((txn) async {
        result = await txn.delete(
          tableName,
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      // Remove do cache
      if (result > 0) {
        _cacheManager.remove(entityName, id);
      }
      return result;
    } catch (e) {
      print('Erro ao excluir $entityName: $e');
      rethrow;
    }
  }
  
  /// Obtém uma entidade pelo ID
  Future<T?> getById(String id) async {
    // Verifica primeiro no cache
    final cachedEntity = _cacheManager.get<T>(entityName, id);
    if (cachedEntity != null) {
      return cachedEntity;
    }
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      final entity = fromMap(maps.first);
      // Adiciona ao cache
      _cacheManager.put(entityName, id, entity);
      return entity;
    } catch (e) {
      print('Erro ao obter $entityName por ID: $e');
      return null;
    }
  }
  
  /// Obtém todas as entidades
  Future<List<T>> getAll() async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      final entities = <T>[];
      final entityMap = <String, T>{};
      for (var i = 0; i < maps.length; i++) {
        try {
          final entity = fromMap(maps[i]);
          entities.add(entity);
          final id = getId(entity);
          entityMap[id] = entity;
        } catch (e) {
          print('Erro ao converter entidade do banco: $e');
        }
      }
      // Atualiza o cache em lote
      _cacheManager.putAll(entityName, entityMap);
      return entities;
    } catch (e) {
      print('Erro ao obter todos os $entityName: $e');
      return [];
    }
  }
  
  /// Obtém a contagem total de entidades
  Future<int> count() async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Erro ao contar $entityName: $e');
      return 0;
    }
  }
  
  /// Limpa o cache desta entidade
  void clearCache() {
    _cacheManager.clear(entityName);
  }
}
