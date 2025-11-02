import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';
import '../database/app_database.dart';

/// Classe abstrata para padronizar operações de banco de dados
abstract class BaseRepository<T> {
  final String tableName;
  final AppDatabase _database = AppDatabase();

  BaseRepository(this.tableName);
  
  /// Nome da entidade para identificação em logs e outras operações
  String get entityName;

  /// Obtém a instância do banco de dados
  Future<Database> get database async {
    return await _database.database;
  }

  /// Converte um mapa para uma entidade
  T fromMap(Map<String, dynamic> map);

  /// Converte uma entidade para um mapa
  Map<String, dynamic> toMap(T entity);

  /// Obtém o nome do campo ID (padrão é 'id')
  String getIdField() => 'id';

  /// Obtém o ID de uma entidade
  String? getId(T entity);

  /// Obtém uma entidade pelo ID
  Future<T?> getById(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        tableName,
        where: '${getIdField()} = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return null;
      }

      return fromMap(result.first);
    } catch (e) {
      Logger.error('Erro ao obter entidade por ID', e);
      rethrow;
    }
  }

  /// Obtém todas as entidades
  Future<List<T>> getAll({String? orderBy}) async {
    try {
      final db = await database;
      final result = await db.query(tableName, orderBy: orderBy);

      return result.map((map) => fromMap(map)).toList();
    } catch (e) {
      Logger.error('Erro ao obter todas as entidades', e);
      return [];
    }
  }

  /// Salva uma entidade no banco de dados
  Future<bool> save(T entity) async {
    try {
      print('🔍 DEBUG: BaseRepository.save - Iniciando...');
      print('🔍 DEBUG: Tabela: $tableName');
      print('🔍 DEBUG: Entidade: ${entityName}');
      
      final db = await database;
      final data = toMap(entity);
      
      print('🔍 DEBUG: Dados para inserir: ${data.keys.toList()}');
      print('🔍 DEBUG: ID: ${data['id']}');
      
      await db.insert(
        tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ DEBUG: BaseRepository.save - Sucesso!');
      return true;
    } catch (e) {
      print('❌ DEBUG: BaseRepository.save - Erro: $e');
      Logger.error('Erro ao salvar entidade', e);
      return false;
    }
  }

  /// Atualiza uma entidade existente
  Future<bool> update(T entity) async {
    try {
      final db = await database;
      final id = getId(entity);
      
      if (id == null) {
        throw Exception('ID não pode ser nulo para atualização');
      }
      
      await db.update(
        tableName,
        toMap(entity),
        where: '${getIdField()} = ?',
        whereArgs: [id],
      );

      return true;
    } catch (e) {
      Logger.error('Erro ao atualizar entidade', e);
      return false;
    }
  }

  /// Exclui uma entidade pelo ID
  Future<bool> delete(String id) async {
    try {
      final db = await database;
      await db.delete(
        tableName,
        where: '${getIdField()} = ?',
        whereArgs: [id],
      );

      return true;
    } catch (e) {
      Logger.error('Erro ao excluir entidade', e);
      return false;
    }
  }

  /// Executa uma operação dentro de uma transação
  Future<T> executeInTransaction<T>(Future<T> Function(Transaction txn) operation) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await operation(txn);
    });
  }

  /// Executa uma operação com retry automático
  Future<T> executeWithRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int retryCount = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          Logger.error('Erro após $maxRetries tentativas', e);
          rethrow;
        }
        
        // Esperar um tempo antes de tentar novamente (backoff exponencial)
        final waitTime = Duration(milliseconds: 200 * (1 << retryCount));
        await Future.delayed(waitTime);
        Logger.log('Tentando novamente operação (tentativa $retryCount)');
      }
    }
  }
}
