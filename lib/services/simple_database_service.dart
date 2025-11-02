import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';
import '../database/app_database.dart';

/// Serviço simplificado para operações de banco de dados
/// sem loops infinitos ou resets agressivos
class SimpleDatabaseService {
  static final SimpleDatabaseService _instance = SimpleDatabaseService._internal();
  factory SimpleDatabaseService() => _instance;
  SimpleDatabaseService._internal();

  final AppDatabase _appDatabase = AppDatabase();

  /// Executa uma operação de banco de dados com tratamento básico de erro
  Future<T?> executeSimple<T>(
    Future<T> Function() operation,
    String operationName,
    {T? defaultValue}
  ) async {
    try {
      Logger.info('🔄 Executando: $operationName');
      final result = await operation();
      Logger.info('✅ $operationName executado com sucesso');
      return result;
    } catch (e) {
      Logger.error('❌ Erro em $operationName: $e');
      Logger.warning('⚠️ Retornando valor padrão para $operationName');
      return defaultValue;
    }
  }

  /// Verifica se uma tabela existe sem loops de inicialização
  Future<bool> tableExists(String tableName) async {
    try {
      final db = await _appDatabase.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      Logger.error('❌ Erro ao verificar se tabela $tableName existe: $e');
      return false;
    }
  }

  /// Obtém o banco de dados de forma simples
  Future<Database?> getDatabase() async {
    try {
      return await _appDatabase.database;
    } catch (e) {
      Logger.error('❌ Erro ao obter banco de dados: $e');
      return null;
    }
  }
}
