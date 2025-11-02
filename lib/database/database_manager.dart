import 'package:flutter/material.dart';
import 'database_helper.dart';

/// Gerenciador de banco de dados responsável por verificar e garantir
/// a integridade do banco de dados durante a inicialização do aplicativo
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isInitialized = false;
  bool _isRepairing = false;

  /// Inicializa o banco de dados e verifica sua integridade
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Primeiro, tenta acessar o banco de dados
      final db = await _databaseHelper.database;
      
      // Verifica a saúde do banco de dados
      final isHealthy = await _databaseHelper.checkDatabaseHealth();
      
      if (!isHealthy) {
        debugPrint('Problemas encontrados no banco de dados. Iniciando reparo automático...');
        await _repairDatabase();
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Erro ao inicializar banco de dados: $e');
      
      // Se ocorrer um erro grave, tenta reparar o banco de dados
      if (!_isRepairing) {
        _isRepairing = true;
        await _repairDatabase();
        _isRepairing = false;
      }
      
      return false;
    }
  }

  /// Repara o banco de dados em caso de problemas
  Future<void> _repairDatabase() async {
    try {
      debugPrint('Iniciando reparo do banco de dados...');
      await _databaseHelper.repairDatabase();
      debugPrint('Reparo do banco de dados concluído.');
    } catch (e) {
      debugPrint('Erro durante o reparo do banco de dados: $e');
      
      // Em caso de falha no reparo, tenta recriar as tabelas essenciais
      try {
        final db = await _databaseHelper.database;
        await _recreateEssentialTables(db);
      } catch (e2) {
        debugPrint('Falha ao recriar tabelas essenciais: $e2');
      }
    }
  }

  /// Recria as tabelas essenciais do banco de dados
  Future<void> _recreateEssentialTables(dynamic db) async {
    try {
      // Recria a tabela de máquinas
      await _databaseHelper.recreateMachinesTable(db);
      
      // Aqui você pode adicionar a recriação de outras tabelas essenciais
      // conforme necessário
    } catch (e) {
      debugPrint('Erro ao recriar tabelas essenciais: $e');
    }
  }

  /// Verifica a saúde do banco de dados e retorna um diagnóstico
  Future<String> checkDatabaseHealth() async {
    try {
      final isHealthy = await _databaseHelper.checkDatabaseHealth();
      if (isHealthy) {
        return 'O banco de dados está íntegro.';
      } else {
        return await _databaseHelper.getDatabaseDiagnostics();
      }
    } catch (e) {
      return 'Erro ao verificar saúde do banco de dados: $e';
    }
  }
}
