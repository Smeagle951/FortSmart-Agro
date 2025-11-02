import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Diagnóstico completo do sistema de salvamento do monitoramento
class MonitoringSaveDiagnostic {
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    try {
      Logger.info('🔍 Iniciando diagnóstico completo do sistema de monitoramento...');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Verificar existência das tabelas
      results['tables'] = await _checkTables(db);
      
      // 2. Verificar estrutura das tabelas
      results['table_structures'] = await _checkTableStructures(db);
      
      // 3. Verificar dados existentes
      results['data_counts'] = await _checkDataCounts(db);
      
      // 4. Verificar sessões de monitoramento
      results['sessions'] = await _checkMonitoringSessions(db);
      
      // 5. Verificar dados recentes
      results['recent_data'] = await _checkRecentData(db);
      
      // 6. Verificar integridade das foreign keys
      results['foreign_keys'] = await _checkForeignKeys(db);
      
      Logger.info('✅ Diagnóstico completo finalizado');
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }
  
  static Future<Map<String, bool>> _checkTables(Database db) async {
    final tables = <String, bool>{};
    
    final expectedTables = [
      'monitoring_sessions',
      'monitoring_history', 
      'monitoring_occurrences',
      'infestacoes_monitoramento',
      'infestacoes_monitoramento_alt',
      'pontos_monitoramento',
      'infestation_map',
    ];
    
    for (String tableName in expectedTables) {
      try {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        tables[tableName] = result.isNotEmpty;
      } catch (e) {
        tables[tableName] = false;
      }
    }
    
    return tables;
  }
  
  static Future<Map<String, List<Map<String, dynamic>>>> _checkTableStructures(Database db) async {
    final structures = <String, List<Map<String, dynamic>>>{};
    
    final tablesToCheck = ['monitoring_sessions', 'infestacoes_monitoramento'];
    
    for (String tableName in tablesToCheck) {
      try {
        final pragma = await db.rawQuery('PRAGMA table_info($tableName)');
        structures[tableName] = pragma;
      } catch (e) {
        structures[tableName] = [{'error': e.toString()}];
      }
    }
    
    return structures;
  }
  
  static Future<Map<String, int>> _checkDataCounts(Database db) async {
    final counts = <String, int>{};
    
    final tablesToCount = [
      'monitoring_sessions',
      'monitoring_history',
      'monitoring_occurrences', 
      'infestacoes_monitoramento',
      'infestacoes_monitoramento_alt',
    ];
    
    for (String tableName in tablesToCount) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        counts[tableName] = result.first['count'] as int;
      } catch (e) {
        counts[tableName] = -1; // Indica erro
      }
    }
    
    return counts;
  }
  
  static Future<Map<String, dynamic>> _checkMonitoringSessions(Database db) async {
    try {
      // Sessões ativas
      final activeSessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['active'],
      );
      
      // Sessões pausadas
      final pausedSessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['pausado'],
      );
      
      // Sessões finalizadas (últimas 10)
      final finalizedSessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['finalized'],
        orderBy: 'created_at DESC',
        limit: 10,
      );
      
      return {
        'active_count': activeSessions.length,
        'paused_count': pausedSessions.length,
        'finalized_count': finalizedSessions.length,
        'active_sessions': activeSessions,
        'paused_sessions': pausedSessions,
        'recent_finalized': finalizedSessions,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _checkRecentData(Database db) async {
    try {
      // Últimas ocorrências
      final recentOccurrences = await db.query(
        'infestacoes_monitoramento',
        orderBy: 'data_hora DESC',
        limit: 5,
      );
      
      // Últimos registros no histórico
      final recentHistory = await db.query(
        'monitoring_history',
        orderBy: 'data_monitoramento DESC',
        limit: 5,
      );
      
      return {
        'recent_occurrences': recentOccurrences,
        'recent_history': recentHistory,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _checkForeignKeys(Database db) async {
    try {
      // Verificar se foreign keys estão habilitadas
      final foreignKeysResult = await db.rawQuery('PRAGMA foreign_keys');
      final foreignKeysEnabled = foreignKeysResult.first['foreign_keys'] == 1;
      
      // Verificar integridade
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      
      return {
        'foreign_keys_enabled': foreignKeysEnabled,
        'integrity_check': integrityResult,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Método para exibir o diagnóstico de forma legível
  static String formatDiagnosticResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 DIAGNÓSTICO DO SISTEMA DE MONITORAMENTO');
    buffer.writeln('=' * 50);
    
    // Tabelas
    if (results.containsKey('tables')) {
      buffer.writeln('\n🗃️ TABELAS:');
      final tables = results['tables'] as Map<String, bool>;
      tables.forEach((table, exists) {
        buffer.writeln('  ${exists ? '✅' : '❌'} $table');
      });
    }
    
    // Contadores
    if (results.containsKey('data_counts')) {
      buffer.writeln('\n📊 CONTAGEM DE DADOS:');
      final counts = results['data_counts'] as Map<String, int>;
      counts.forEach((table, count) {
        final status = count == -1 ? '❌ ERRO' : '$count registros';
        buffer.writeln('  $table: $status');
      });
    }
    
    // Sessões
    if (results.containsKey('sessions')) {
      buffer.writeln('\n🔄 SESSÕES DE MONITORAMENTO:');
      final sessions = results['sessions'] as Map<String, dynamic>;
      if (sessions.containsKey('error')) {
        buffer.writeln('  ❌ Erro: ${sessions['error']}');
      } else {
        buffer.writeln('  📈 Ativas: ${sessions['active_count']}');
        buffer.writeln('  ⏸️ Pausadas: ${sessions['paused_count']}');
        buffer.writeln('  ✅ Finalizadas: ${sessions['finalized_count']}');
      }
    }
    
    // Foreign Keys
    if (results.containsKey('foreign_keys')) {
      buffer.writeln('\n🔗 INTEGRIDADE:');
      final fk = results['foreign_keys'] as Map<String, dynamic>;
      if (fk.containsKey('error')) {
        buffer.writeln('  ❌ Erro: ${fk['error']}');
      } else {
        buffer.writeln('  Foreign Keys: ${fk['foreign_keys_enabled'] ? '✅ Habilitadas' : '❌ Desabilitadas'}');
      }
    }
    
    return buffer.toString();
  }
}
