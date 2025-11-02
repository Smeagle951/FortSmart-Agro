import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Diagnóstico direto via SQL para verificar dados no banco
class SQLDirectDiagnostic {
  static Future<Map<String, dynamic>> runDirectSQL() async {
    final db = await AppDatabase.instance.database;
    final results = <String, dynamic>{};

    try {
      // 1. ✅ VERIFICAR SE AS TABELAS EXISTEM
      Logger.info('🔍 [SQL_DIAG] 1️⃣ Verificando tabelas...');
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('monitoring_sessions', 'monitoring_points', 'monitoring_occurrences')"
      );
      results['tables_exist'] = tables.map((t) => t['name']).toList();
      Logger.info('✅ [SQL_DIAG] Tabelas encontradas: ${results['tables_exist']}');

      // 2. ✅ CONTAR SESSÕES
      Logger.info('🔍 [SQL_DIAG] 2️⃣ Contando sessões...');
      final sessionsCount = await db.rawQuery('SELECT COUNT(*) as count FROM monitoring_sessions');
      results['sessions_count'] = Sqflite.firstIntValue(sessionsCount) ?? 0;
      Logger.info('✅ [SQL_DIAG] Total de sessões: ${results['sessions_count']}');

      // 3. ✅ CONTAR PONTOS
      Logger.info('🔍 [SQL_DIAG] 3️⃣ Contando pontos...');
      final pointsCount = await db.rawQuery('SELECT COUNT(*) as count FROM monitoring_points');
      results['points_count'] = Sqflite.firstIntValue(pointsCount) ?? 0;
      Logger.info('✅ [SQL_DIAG] Total de pontos: ${results['points_count']}');

      // 4. ✅ CONTAR OCORRÊNCIAS
      Logger.info('🔍 [SQL_DIAG] 4️⃣ Contando ocorrências...');
      final occurrencesCount = await db.rawQuery('SELECT COUNT(*) as count FROM monitoring_occurrences');
      results['occurrences_count'] = Sqflite.firstIntValue(occurrencesCount) ?? 0;
      Logger.info('✅ [SQL_DIAG] Total de ocorrências: ${results['occurrences_count']}');

      // 5. ✅ LISTAR ÚLTIMAS 10 SESSÕES
      Logger.info('🔍 [SQL_DIAG] 5️⃣ Listando últimas 10 sessões...');
      final sessions = await db.rawQuery('''
        SELECT id, talhao_id, talhao_nome, status, created_at 
        FROM monitoring_sessions 
        ORDER BY created_at DESC 
        LIMIT 10
      ''');
      results['latest_sessions'] = sessions;
      Logger.info('✅ [SQL_DIAG] Sessões encontradas: ${sessions.length}');
      for (final session in sessions) {
        Logger.info('   📍 Sessão: ${session['id']} | Talhão: ${session['talhao_nome']} | Status: ${session['status']}');
      }

      // 6. ✅ LISTAR ÚLTIMOS 20 PONTOS
      Logger.info('🔍 [SQL_DIAG] 6️⃣ Listando últimos 20 pontos...');
      final points = await db.rawQuery('''
        SELECT id, session_id, numero, latitude, longitude, created_at 
        FROM monitoring_points 
        ORDER BY created_at DESC 
        LIMIT 20
      ''');
      results['latest_points'] = points;
      Logger.info('✅ [SQL_DIAG] Pontos encontrados: ${points.length}');
      for (final point in points) {
        Logger.info('   📍 Ponto: ${point['id']} | Session: ${point['session_id']} | Número: ${point['numero']}');
      }

      // 7. ✅ LISTAR TODAS AS OCORRÊNCIAS (se existirem)
      Logger.info('🔍 [SQL_DIAG] 7️⃣ Listando TODAS as ocorrências...');
      final occurrences = await db.rawQuery('''
        SELECT id, point_id, session_id, tipo, subtipo, percentual, created_at 
        FROM monitoring_occurrences 
        ORDER BY created_at DESC
      ''');
      results['all_occurrences'] = occurrences;
      Logger.info('✅ [SQL_DIAG] Ocorrências encontradas: ${occurrences.length}');
      for (final occ in occurrences) {
        Logger.info('   🐛 Ocorrência: ${occ['id']} | Point: ${occ['point_id']} | Session: ${occ['session_id']} | Tipo: ${occ['tipo']}/${occ['subtipo']}');
      }

      // 8. ✅ VERIFICAR ESTRUTURA DA TABELA monitoring_occurrences
      Logger.info('🔍 [SQL_DIAG] 8️⃣ Verificando estrutura da tabela monitoring_occurrences...');
      final tableInfo = await db.rawQuery('PRAGMA table_info(monitoring_occurrences)');
      results['table_structure'] = tableInfo;
      Logger.info('✅ [SQL_DIAG] Colunas da tabela monitoring_occurrences:');
      for (final col in tableInfo) {
        Logger.info('   📝 ${col['name']} (${col['type']}) - ${col['notnull'] == 1 ? "NOT NULL" : "NULL"}');
      }

      // 9. ✅ VERIFICAR RELAÇÃO ENTRE PONTOS E OCORRÊNCIAS
      Logger.info('🔍 [SQL_DIAG] 9️⃣ Verificando relação pontos ↔ ocorrências...');
      final pointsWithOccurrences = await db.rawQuery('''
        SELECT 
          mp.id as point_id,
          mp.session_id,
          mp.numero,
          COUNT(mo.id) as occurrences_count
        FROM monitoring_points mp
        LEFT JOIN monitoring_occurrences mo ON mp.id = mo.point_id
        GROUP BY mp.id, mp.session_id, mp.numero
        ORDER BY mp.created_at DESC
        LIMIT 20
      ''');
      results['points_occurrences_relation'] = pointsWithOccurrences;
      Logger.info('✅ [SQL_DIAG] Relação pontos ↔ ocorrências:');
      for (final rel in pointsWithOccurrences) {
        Logger.info('   📊 Ponto: ${rel['point_id']} | Número: ${rel['numero']} | Ocorrências: ${rel['occurrences_count']}');
      }

      // 10. ✅ VERIFICAR SESSÕES FINALIZADAS COM PONTOS MAS SEM OCORRÊNCIAS
      Logger.info('🔍 [SQL_DIAG] 🔟 Verificando sessões finalizadas SEM ocorrências...');
      final sessionsWithoutOccurrences = await db.rawQuery('''
        SELECT 
          ms.id as session_id,
          ms.talhao_nome,
          ms.status,
          COUNT(DISTINCT mp.id) as points_count,
          COUNT(mo.id) as occurrences_count
        FROM monitoring_sessions ms
        LEFT JOIN monitoring_points mp ON ms.id = mp.session_id
        LEFT JOIN monitoring_occurrences mo ON mp.id = mo.point_id
        WHERE ms.status = 'finalized'
        GROUP BY ms.id, ms.talhao_nome, ms.status
        HAVING COUNT(mo.id) = 0
        ORDER BY ms.created_at DESC
      ''');
      results['finalized_sessions_without_occurrences'] = sessionsWithoutOccurrences;
      Logger.info('✅ [SQL_DIAG] Sessões finalizadas SEM ocorrências: ${sessionsWithoutOccurrences.length}');
      for (final session in sessionsWithoutOccurrences) {
        Logger.info('   ⚠️ Sessão: ${session['session_id']} | Talhão: ${session['talhao_nome']} | Pontos: ${session['points_count']} | Ocorrências: 0');
      }

      Logger.info('✅ [SQL_DIAG] Diagnóstico SQL concluído!');
      return results;

    } catch (e, stack) {
      Logger.error('❌ [SQL_DIAG] Erro no diagnóstico SQL: $e', null, stack);
      results['error'] = e.toString();
      results['stack_trace'] = stack.toString();
      return results;
    }
  }

  /// Formata os resultados para exibição
  static String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('🔍 DIAGNÓSTICO SQL DIRETO');
    buffer.writeln('═══════════════════════════════════════════\n');

    if (results.containsKey('error')) {
      buffer.writeln('❌ ERRO NO DIAGNÓSTICO:');
      buffer.writeln(results['error']);
      return buffer.toString();
    }

    buffer.writeln('1️⃣ TABELAS EXISTENTES:');
    buffer.writeln('   ${results['tables_exist']}\n');

    buffer.writeln('2️⃣ CONTADORES:');
    buffer.writeln('   📊 Sessões: ${results['sessions_count']}');
    buffer.writeln('   📍 Pontos: ${results['points_count']}');
    buffer.writeln('   🐛 Ocorrências: ${results['occurrences_count']}\n');

    if (results['occurrences_count'] == 0) {
      buffer.writeln('❌ PROBLEMA IDENTIFICADO:');
      buffer.writeln('   • Existem ${results['sessions_count']} sessões');
      buffer.writeln('   • Existem ${results['points_count']} pontos');
      buffer.writeln('   • MAS 0 OCORRÊNCIAS!\n');
      
      final sessionsWithout = results['finalized_sessions_without_occurrences'] as List;
      if (sessionsWithout.isNotEmpty) {
        buffer.writeln('⚠️ SESSÕES FINALIZADAS SEM OCORRÊNCIAS: ${sessionsWithout.length}');
        for (final session in sessionsWithout.take(5)) {
          buffer.writeln('   • Sessão: ${session['session_id']}');
          buffer.writeln('     Talhão: ${session['talhao_nome']}');
          buffer.writeln('     Pontos: ${session['points_count']}');
          buffer.writeln('     Ocorrências: 0\n');
        }
      }
    } else {
      buffer.writeln('✅ OCORRÊNCIAS ENCONTRADAS: ${results['occurrences_count']}');
      final occurrences = results['all_occurrences'] as List;
      for (final occ in occurrences.take(10)) {
        buffer.writeln('   • ${occ['tipo']}/${occ['subtipo']} (${occ['percentual']}%)');
        buffer.writeln('     Point ID: ${occ['point_id']}');
        buffer.writeln('     Session ID: ${occ['session_id']}\n');
      }
    }

    buffer.writeln('═══════════════════════════════════════════');
    return buffer.toString();
  }
}

