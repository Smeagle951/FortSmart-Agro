import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Diagnóstico completo do sistema de sessões de monitoramento
class MonitoringSessionDiagnostic {
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    try {
      Logger.info('🔍 Iniciando diagnóstico completo de sessões...');
      
      final db = await AppDatabase.instance.database;
      results['database_path'] = db.path;
      
      // 1. Verificar se a tabela monitoring_sessions existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_sessions'"
      );
      results['tabela_existe'] = tables.isNotEmpty;
      
      if (!results['tabela_existe']) {
        results['erro'] = 'Tabela monitoring_sessions não existe!';
        return results;
      }
      
      // 2. Contar total de sessões
      results['total_sessoes'] = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_sessions')
      ) ?? 0;
      
      // 3. Contar sessões por status
      final sessionsByStatus = await db.rawQuery(
        'SELECT status, COUNT(*) as count FROM monitoring_sessions GROUP BY status'
      );
      results['sessoes_por_status'] = Map.fromIterable(
        sessionsByStatus,
        key: (row) => row['status'],
        value: (row) => row['count'],
      );
      
      // 4. Últimas 5 sessões (todas)
      final allSessions = await db.query(
        'monitoring_sessions',
        orderBy: 'created_at DESC',
        limit: 5,
      );
      results['ultimas_5_sessoes'] = allSessions.map((s) => {
        'id': s['id'],
        'talhao_id': s['talhao_id'],
        'talhao_nome': s['talhao_nome'],
        'cultura_id': s['cultura_id'],
        'cultura_nome': s['cultura_nome'],
        'status': s['status'],
        'total_pontos': s['total_pontos'],
        'total_ocorrencias': s['total_ocorrencias'],
        'data_inicio': s['data_inicio'],
        'data_fim': s['data_fim'],
        'created_at': s['created_at'],
        'updated_at': s['updated_at'],
      }).toList();
      
      // 5. Sessões finalizadas
      final finalizedSessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['finalized'],
        orderBy: 'created_at DESC',
        limit: 5,
      );
      results['sessoes_finalizadas'] = finalizedSessions.length;
      results['ultimas_5_finalizadas'] = finalizedSessions.map((s) => {
        'id': s['id'],
        'talhao_nome': s['talhao_nome'],
        'status': s['status'],
        'data_inicio': s['data_inicio'],
        'data_fim': s['data_fim'],
      }).toList();
      
      // 6. Verificar pontos das sessões
      if (allSessions.isNotEmpty) {
        final firstSessionId = allSessions.first['id'];
        final points = await db.query(
          'monitoring_points',
          where: 'session_id = ?',
          whereArgs: [firstSessionId],
        );
        results['pontos_primeira_sessao'] = points.length;
        
        if (points.isNotEmpty) {
          results['exemplo_ponto'] = {
            'id': points.first['id'],
            'session_id': points.first['session_id'],
            'numero': points.first['numero'],
            'latitude': points.first['latitude'],
            'longitude': points.first['longitude'],
          };
        }
      }
      
      // 7. Verificar ocorrências
      results['total_pontos'] = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_points')
      ) ?? 0;
      
      results['total_ocorrencias'] = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      ) ?? 0;
      
      // 8. Verificar estrutura da tabela
      final tableInfo = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      results['colunas_tabela'] = tableInfo.map((col) => col['name']).toList();
      
      // 9. Verificar sessões órfãs (sem pontos)
      final sessionsWithoutPoints = await db.rawQuery('''
        SELECT ms.id, ms.status, ms.total_pontos, ms.created_at
        FROM monitoring_sessions ms
        LEFT JOIN monitoring_points mp ON ms.id = mp.session_id
        WHERE mp.id IS NULL
        LIMIT 5
      ''');
      results['sessoes_sem_pontos'] = sessionsWithoutPoints.length;
      results['exemplo_sessoes_sem_pontos'] = sessionsWithoutPoints;
      
      Logger.info('✅ Diagnóstico completo finalizado!');
      
    } catch (e, stack) {
      results['erro_geral'] = e.toString();
      results['stack_trace'] = stack.toString();
      Logger.error('❌ Erro no diagnóstico: $e', e, stack); // Parâmetros posicionais, não nomeados
    }
    
    return results;
  }
  
  /// Formata os resultados do diagnóstico para exibição
  static String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('   DIAGNÓSTICO DE SESSÕES DE MONITORAMENTO');
    buffer.writeln('═══════════════════════════════════════════\n');
    
    buffer.writeln('📁 Banco de Dados: ${results['database_path'] ?? 'N/A'}\n');
    
    buffer.writeln('1️⃣ VERIFICAÇÃO DA TABELA:');
    buffer.writeln('   • Tabela existe: ${results['tabela_existe'] ? '✅ SIM' : '❌ NÃO'}');
    
    if (results['tabela_existe'] == false) {
      buffer.writeln('\n❌ ERRO CRÍTICO: Tabela monitoring_sessions não existe!');
      return buffer.toString();
    }
    
    buffer.writeln('\n2️⃣ CONTAGEM DE SESSÕES:');
    buffer.writeln('   • Total de sessões: ${results['total_sessoes'] ?? 0}');
    
    if (results['sessoes_por_status'] != null) {
      buffer.writeln('   • Por status:');
      (results['sessoes_por_status'] as Map).forEach((status, count) {
        buffer.writeln('     - $status: $count');
      });
    }
    
    buffer.writeln('\n3️⃣ ÚLTIMAS 5 SESSÕES:');
    if (results['ultimas_5_sessoes'] != null && (results['ultimas_5_sessoes'] as List).isNotEmpty) {
      for (var session in results['ultimas_5_sessoes']) {
        buffer.writeln('   ─────────────────────────');
        buffer.writeln('   • ID: ${session['id']}');
        buffer.writeln('   • Talhão: ${session['talhao_nome'] ?? session['talhao_id']}');
        buffer.writeln('   • Cultura: ${session['cultura_nome'] ?? session['cultura_id']}');
        buffer.writeln('   • Status: ${session['status']}');
        buffer.writeln('   • Pontos: ${session['total_pontos'] ?? 0}');
        buffer.writeln('   • Ocorrências: ${session['total_ocorrencias'] ?? 0}');
        buffer.writeln('   • Criada em: ${session['created_at']}');
        buffer.writeln('   • Data fim: ${session['data_fim'] ?? 'N/A'}');
      }
    } else {
      buffer.writeln('   ⚠️ Nenhuma sessão encontrada');
    }
    
    buffer.writeln('\n4️⃣ SESSÕES FINALIZADAS:');
    buffer.writeln('   • Total: ${results['sessoes_finalizadas'] ?? 0}');
    if (results['ultimas_5_finalizadas'] != null && (results['ultimas_5_finalizadas'] as List).isNotEmpty) {
      for (var session in results['ultimas_5_finalizadas']) {
        buffer.writeln('   • ${session['talhao_nome']} - Status: ${session['status']}');
      }
    } else {
      buffer.writeln('   ⚠️ Nenhuma sessão finalizada encontrada');
    }
    
    buffer.writeln('\n5️⃣ PONTOS E OCORRÊNCIAS:');
    buffer.writeln('   • Total de pontos: ${results['total_pontos'] ?? 0}');
    buffer.writeln('   • Total de ocorrências: ${results['total_ocorrencias'] ?? 0}');
    buffer.writeln('   • Pontos da primeira sessão: ${results['pontos_primeira_sessao'] ?? 0}');
    
    if (results['exemplo_ponto'] != null) {
      buffer.writeln('   • Exemplo de ponto:');
      buffer.writeln('     - ID: ${results['exemplo_ponto']['id']}');
      buffer.writeln('     - Session ID: ${results['exemplo_ponto']['session_id']}');
      buffer.writeln('     - Número: ${results['exemplo_ponto']['numero']}');
    }
    
    buffer.writeln('\n6️⃣ ESTRUTURA DA TABELA:');
    if (results['colunas_tabela'] != null) {
      buffer.writeln('   Colunas: ${(results['colunas_tabela'] as List).join(', ')}');
    }
    
    buffer.writeln('\n7️⃣ SESSÕES SEM PONTOS:');
    buffer.writeln('   • Total: ${results['sessoes_sem_pontos'] ?? 0}');
    if (results['exemplo_sessoes_sem_pontos'] != null && (results['exemplo_sessoes_sem_pontos'] as List).isNotEmpty) {
      for (var session in results['exemplo_sessoes_sem_pontos']) {
        buffer.writeln('   • ID: ${session['id']}, Status: ${session['status']}, Criada: ${session['created_at']}');
      }
    }
    
    if (results['erro_geral'] != null) {
      buffer.writeln('\n❌ ERRO GERAL:');
      buffer.writeln(results['erro_geral']);
      if (results['stack_trace'] != null) {
        buffer.writeln('\nStack Trace:');
        buffer.writeln(results['stack_trace']);
      }
    }
    
    buffer.writeln('\n═══════════════════════════════════════════');
    buffer.writeln('✅ Diagnóstico concluído!');
    buffer.writeln('═══════════════════════════════════════════');
    
    return buffer.toString();
  }
}

