import '../database/app_database.dart';
import '../utils/logger.dart';

/// Diagnóstico para verificar sessões de monitoramento
class MonitoringSessionsDiagnostic {
  static Future<Map<String, dynamic>> runDiagnostic() async {
    try {
      Logger.info('🔍 [DIAGNOSTIC] Iniciando diagnóstico de sessões...');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_sessions'"
      );
      
      if (tables.isEmpty) {
        return {
          'success': false,
          'error': 'Tabela monitoring_sessions não existe!',
        };
      }
      
      Logger.info('✅ [DIAGNOSTIC] Tabela monitoring_sessions existe');
      
      // 2. Contar total de sessões
      final totalCount = await db.rawQuery('SELECT COUNT(*) as count FROM monitoring_sessions');
      final total = totalCount.first['count'] as int;
      
      Logger.info('📊 [DIAGNOSTIC] Total de sessões: $total');
      
      // 3. Contar por status
      final statusCounts = await db.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM monitoring_sessions 
        GROUP BY status
      ''');
      
      Logger.info('📈 [DIAGNOSTIC] Contagem por status:');
      for (final row in statusCounts) {
        Logger.info('   - ${row['status']}: ${row['count']}');
      }
      
      // 4. Mostrar últimas 3 sessões
      final recentSessions = await db.query(
        'monitoring_sessions',
        orderBy: 'created_at DESC',
        limit: 3,
      );
      
      Logger.info('📝 [DIAGNOSTIC] Últimas 3 sessões:');
      for (final session in recentSessions) {
        Logger.info('   - ID: ${session['id']}');
        Logger.info('     Status: ${session['status']}');
        Logger.info('     Talhão: ${session['talhao_id']}');
        Logger.info('     Cultura: ${session['cultura_id']}');
        Logger.info('     Data início: ${session['started_at']}');
        Logger.info('     Data fim: ${session['data_fim']}');
      }
      
      // 5. Verificar estrutura da tabela
      final schema = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      Logger.info('🏗️ [DIAGNOSTIC] Estrutura da tabela:');
      for (final column in schema) {
        Logger.info('   - ${column['name']} (${column['type']})');
      }
      
      return {
        'success': true,
        'total': total,
        'statusCounts': statusCounts,
        'recentSessions': recentSessions,
        'schema': schema,
      };
      
    } catch (e) {
      Logger.error('❌ [DIAGNOSTIC] Erro no diagnóstico: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Formata resultados para exibição
  static String formatResults(Map<String, dynamic> results) {
    if (!results['success']) {
      return '❌ ERRO: ${results['error']}';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('✅ DIAGNÓSTICO DE SESSÕES\n');
    buffer.writeln('📊 Total de sessões: ${results['total']}\n');
    
    buffer.writeln('📈 Por status:');
    for (final row in results['statusCounts']) {
      buffer.writeln('   • ${row['status']}: ${row['count']}');
    }
    
    buffer.writeln('\n📝 Últimas sessões:');
    final sessions = results['recentSessions'] as List;
    if (sessions.isEmpty) {
      buffer.writeln('   (Nenhuma sessão encontrada)');
    } else {
      for (int i = 0; i < sessions.length; i++) {
        final s = sessions[i];
        buffer.writeln('   ${i + 1}. ${s['id']}');
        buffer.writeln('      Status: ${s['status']}');
        buffer.writeln('      Talhão: ${s['talhao_id']}');
      }
    }
    
    return buffer.toString();
  }
}

