import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço unificado para diagnóstico do banco de dados
class DatabaseDiagnosticService {
  static final DatabaseDiagnosticService _instance = DatabaseDiagnosticService._internal();
  factory DatabaseDiagnosticService() => _instance;
  DatabaseDiagnosticService._internal();

  final AppDatabase _appDatabase = AppDatabase();

  /// Executa diagnóstico completo do banco de dados
  Future<Map<String, dynamic>> runFullDiagnostic() async {
    try {
      Logger.info('🔍 Iniciando diagnóstico completo do banco de dados...');
      
      final results = <String, dynamic>{};
      
      // 1. Verificar se o banco pode ser acessado
      results['databaseAccess'] = await _checkDatabaseAccess();
      
      // 2. Verificar integridade
      results['integrity'] = await _checkIntegrity();
      
      // 3. Listar tabelas
      results['tables'] = await _listTables();
      
      // 4. Verificar estrutura das tabelas principais
      results['tableStructure'] = await _checkTableStructure();
      
      // 5. Verificar dados
      results['dataCheck'] = await _checkData();
      
      // 6. Verificar performance
      results['performance'] = await _checkPerformance();
      
      Logger.info('✅ Diagnóstico completo concluído');
      return results;
    } catch (e) {
      Logger.error('❌ Erro durante diagnóstico: $e');
      return {
        'error': e.toString(),
        'status': 'FAILED'
      };
    }
  }

  /// Verifica se o banco de dados pode ser acessado
  Future<Map<String, dynamic>> _checkDatabaseAccess() async {
    try {
      final db = await _appDatabase.database;
      final path = await _appDatabase.getDatabasePath();
      final file = File(path);
      
      return {
        'status': 'OK',
        'path': path,
        'exists': await file.exists(),
        'size': await file.exists() ? await file.length() : 0,
        'isOpen': db.isOpen,
        'version': await db.getVersion(),
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Verifica a integridade do banco
  Future<Map<String, dynamic>> _checkIntegrity() async {
    try {
      final db = await _appDatabase.database;
      final integrityCheck = await db.rawQuery('PRAGMA integrity_check');
      final foreignKeyCheck = await db.rawQuery('PRAGMA foreign_key_check');
      
      return {
        'status': 'OK',
        'integrity': integrityCheck.first['integrity_check'],
        'foreignKeyViolations': foreignKeyCheck.length,
        'isHealthy': integrityCheck.first['integrity_check'] == 'ok' && foreignKeyCheck.isEmpty,
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Lista todas as tabelas
  Future<Map<String, dynamic>> _listTables() async {
    try {
      final db = await _appDatabase.database;
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
      
      final tableNames = tables.map((t) => t['name'] as String).toList();
      
      return {
        'status': 'OK',
        'count': tableNames.length,
        'tables': tableNames,
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Verifica a estrutura das tabelas principais
  Future<Map<String, dynamic>> _checkTableStructure() async {
    try {
      final db = await _appDatabase.database;
      final essentialTables = [
        'talhoes', 'culturas', 'monitorings', 'infestacao_resumo',
        'pests', 'diseases', 'weeds', 'farms'
      ];
      
      final results = <String, Map<String, dynamic>>{};
      
      for (final tableName in essentialTables) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
          final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableName')
          );
          
          results[tableName] = {
            'exists': true,
            'columns': tableInfo.length,
            'records': count ?? 0,
            'status': 'OK',
          };
        } catch (e) {
          results[tableName] = {
            'exists': false,
            'error': e.toString(),
            'status': 'MISSING',
          };
        }
      }
      
      return {
        'status': 'OK',
        'tables': results,
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Verifica dados críticos
  Future<Map<String, dynamic>> _checkData() async {
    try {
      final db = await _appDatabase.database;
      
      final checks = <String, dynamic>{};
      
      // Verificar se há fazendas
      try {
        final farmCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM farms')
        );
        checks['farms'] = farmCount ?? 0;
      } catch (e) {
        checks['farms'] = 'ERROR: ${e.toString()}';
      }
      
      // Verificar se há talhões
      try {
        final plotCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM talhoes')
        );
        checks['plots'] = plotCount ?? 0;
      } catch (e) {
        checks['plots'] = 'ERROR: ${e.toString()}';
      }
      
      // Verificar se há culturas
      try {
        final cropCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM culturas')
        );
        checks['crops'] = cropCount ?? 0;
      } catch (e) {
        checks['crops'] = 'ERROR: ${e.toString()}';
      }
      
      return {
        'status': 'OK',
        'data': checks,
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Verifica performance do banco
  Future<Map<String, dynamic>> _checkPerformance() async {
    try {
      final db = await _appDatabase.database;
      
      // Verificar configurações PRAGMA
      final pragmaResults = <String, dynamic>{};
      
      final pragmas = [
        'journal_mode', 'synchronous', 'cache_size', 'temp_store',
        'foreign_keys', 'busy_timeout'
      ];
      
      for (final pragma in pragmas) {
        try {
          final result = await db.rawQuery('PRAGMA $pragma');
          pragmaResults[pragma] = result.first.values.first;
        } catch (e) {
          pragmaResults[pragma] = 'ERROR: ${e.toString()}';
        }
      }
      
      return {
        'status': 'OK',
        'pragma': pragmaResults,
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Repara problemas detectados
  Future<Map<String, dynamic>> repairDatabase() async {
    try {
      Logger.info('🔧 Iniciando reparo do banco de dados...');
      
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // 1. Executar VACUUM
      try {
        await db.execute('VACUUM');
        results['vacuum'] = 'OK';
      } catch (e) {
        results['vacuum'] = 'ERROR: ${e.toString()}';
      }
      
      // 2. Reindexar
      try {
        await db.execute('REINDEX');
        results['reindex'] = 'OK';
      } catch (e) {
        results['reindex'] = 'ERROR: ${e.toString()}';
      }
      
      // 3. Verificar integridade novamente
      results['integrityAfter'] = await _checkIntegrity();
      
      Logger.info('✅ Reparo concluído');
      return {
        'status': 'OK',
        'repairs': results,
      };
    } catch (e) {
      Logger.error('❌ Erro durante reparo: $e');
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Força recriação do banco de dados
  Future<Map<String, dynamic>> forceRecreateDatabase() async {
    try {
      Logger.warning('⚠️ Forçando recriação do banco de dados...');
      
      // Fazer backup se possível
      final backupPath = await _appDatabase.backupDatabase();
      
      // Resetar banco
      await _appDatabase.resetDatabase();
      
      Logger.info('✅ Banco de dados recriado com sucesso');
      return {
        'status': 'OK',
        'backupCreated': backupPath != null,
        'backupPath': backupPath,
      };
    } catch (e) {
      Logger.error('❌ Erro ao recriar banco: $e');
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }
}
