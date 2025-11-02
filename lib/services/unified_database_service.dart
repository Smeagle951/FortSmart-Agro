import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço unificado para gerenciar o banco de dados e resolver problemas de inicialização
class UnifiedDatabaseService {
  static final UnifiedDatabaseService _instance = UnifiedDatabaseService._internal();
  factory UnifiedDatabaseService() => _instance;
  UnifiedDatabaseService._internal();

  final AppDatabase _appDatabase = AppDatabase();
  bool _isInitialized = false;
  bool _isInitializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Inicializa o banco de dados de forma segura
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      return _initCompleter.future.then((_) => true);
    }

    try {
      _isInitializing = true;
      Logger.info('🚀 Iniciando serviço unificado de banco de dados...');

      // 1. Tentar acessar o banco de dados
      final db = await _appDatabase.database;
      
      // 2. Verificar se está funcionando
      await _testDatabaseConnection(db);
      
      // 3. Verificar integridade básica
      await _checkBasicIntegrity(db);
      
      // 4. Verificar tabelas essenciais
      await _ensureEssentialTables(db);
      
      _isInitialized = true;
      _initCompleter.complete();
      
      Logger.info('✅ Serviço unificado de banco de dados inicializado com sucesso');
      return true;
    } catch (e) {
      Logger.error('❌ Erro na inicialização do banco de dados: $e');
      
      // Tentar recuperação automática
      try {
        Logger.warning('🔄 Tentando recuperação automática...');
        await _performRecovery();
        
        _isInitialized = true;
        _initCompleter.complete();
        Logger.info('✅ Recuperação bem-sucedida');
        return true;
      } catch (recoveryError) {
        Logger.error('❌ Falha na recuperação: $recoveryError');
        _initCompleter.completeError(recoveryError);
        return false;
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Testa a conexão com o banco de dados
  Future<void> _testDatabaseConnection(Database db) async {
    try {
      // Teste simples de conexão
      final result = await db.rawQuery('SELECT 1 as test');
      if (result.isEmpty || result.first['test'] != 1) {
        throw Exception('Teste de conexão falhou');
      }
      
      // Verificar versão
      final version = await db.getVersion();
      Logger.info('📊 Versão do banco: $version');
      
    } catch (e) {
      throw Exception('Falha no teste de conexão: $e');
    }
  }

  /// Verifica integridade básica
  Future<void> _checkBasicIntegrity(Database db) async {
    try {
      // Verificar integridade
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      final integrity = integrityResult.first['integrity_check'] as String?;
      
      if (integrity != 'ok') {
        Logger.warning('⚠️ Problemas de integridade detectados: $integrity');
        // Não falhar aqui, apenas logar
      } else {
        Logger.info('✅ Integridade do banco OK');
      }
      
      // Verificar chaves estrangeiras
      final fkResult = await db.rawQuery('PRAGMA foreign_key_check');
      if (fkResult.isNotEmpty) {
        Logger.warning('⚠️ Violações de chave estrangeira detectadas: ${fkResult.length}');
      }
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao verificar integridade: $e');
      // Não falhar aqui, apenas logar
    }
  }

  /// Garante que tabelas essenciais existem
  Future<void> _ensureEssentialTables(Database db) async {
    try {
      final essentialTables = [
        'talhoes', 'culturas', 'farms', 'monitoring', 'infestacao_resumo'
      ];
      
      final existingTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      final existingTableNames = existingTables.map((t) => t['name'] as String).toList();
      
      Logger.info('📋 Tabelas existentes: ${existingTableNames.length}');
      
      for (final table in essentialTables) {
        if (!existingTableNames.contains(table)) {
          Logger.warning('⚠️ Tabela essencial não encontrada: $table');
        }
      }
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao verificar tabelas essenciais: $e');
      // Não falhar aqui, apenas logar
    }
  }

  /// Executa recuperação automática
  Future<void> _performRecovery() async {
    try {
      Logger.info('🔧 Iniciando recuperação automática...');
      
      // 1. Tentar resetar o banco
      await _appDatabase.resetDatabase();
      
      // 2. Aguardar um pouco
      await Future.delayed(Duration(milliseconds: 500));
      
      // 3. Tentar acessar novamente
      final db = await _appDatabase.database;
      await _testDatabaseConnection(db);
      
      Logger.info('✅ Recuperação concluída');
    } catch (e) {
      throw Exception('Falha na recuperação: $e');
    }
  }

  /// Obtém o banco de dados de forma segura
  Future<Database> getDatabase() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        throw Exception('Falha ao inicializar banco de dados');
      }
    }
    
    return await _appDatabase.database;
  }

  /// Verifica se o banco está funcionando
  Future<bool> isHealthy() async {
    try {
      final db = await getDatabase();
      
      // Teste simples
      final result = await db.rawQuery('SELECT 1 as test');
      return result.isNotEmpty && result.first['test'] == 1;
    } catch (e) {
      Logger.error('❌ Banco de dados não está saudável: $e');
      return false;
    }
  }

  /// Executa operação com retry automático
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 1000),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        Logger.warning('⚠️ Tentativa $attempts de $maxRetries falhou para $operationName: $e');
        
        if (attempts >= maxRetries) {
          Logger.error('❌ Todas as tentativas falharam para $operationName');
          rethrow;
        }
        
        // Aguardar antes da próxima tentativa
        await Future.delayed(delay * attempts);
        
        // Tentar reinicializar se necessário
        if (attempts == 1) {
          try {
            await initialize();
          } catch (initError) {
            Logger.warning('⚠️ Falha ao reinicializar: $initError');
          }
        }
      }
    }
    
    throw Exception('Todas as tentativas falharam para $operationName');
  }

  /// Força reinicialização
  Future<void> forceReinitialize() async {
    Logger.warning('🔄 Forçando reinicialização do banco de dados...');
    
    _isInitialized = false;
    _isInitializing = false;
    
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    
    await initialize();
  }

  /// Obtém informações de status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
      'hasError': _initCompleter.isCompleted && _initCompleter.hasError,
    };
  }
}
