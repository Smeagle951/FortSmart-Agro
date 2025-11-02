import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import '../services/direct_occurrence_service.dart';
import '../services/monitoring_to_map_sync_service.dart';

/// RESET COMPLETO E POPULAÇÃO COM DADOS DE TESTE CORRETOS
class CompleteDatabaseReset {
  
  /// PASSO 1: Limpar todas as ocorrências antigas
  static Future<void> cleanAllOccurrences() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🧹 LIMPANDO OCORRÊNCIAS ANTIGAS');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      
      // Contar antes
      final beforeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      ) ?? 0;
      
      Logger.info('📊 Ocorrências ANTES da limpeza: $beforeCount');
      
      // Deletar TODAS
      await db.delete('monitoring_occurrences');
      
      // Contar depois
      final afterCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      ) ?? 0;
      
      Logger.info('✅ Ocorrências deletadas: ${beforeCount - afterCount}');
      Logger.info('📊 Ocorrências DEPOIS da limpeza: $afterCount');
      Logger.info('═══════════════════════════════════════════\n');
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao limpar ocorrências: $e', null, stack);
    }
  }
  
  /// PASSO 2: Verificar schema da tabela
  static Future<Map<String, dynamic>> verifyTableSchema() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🔍 VERIFICANDO SCHEMA DA TABELA');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      
      // Get table info
      final columns = await db.rawQuery('PRAGMA table_info(monitoring_occurrences)');
      
      Logger.info('📊 COLUNAS DA TABELA monitoring_occurrences:');
      final columnNames = <String>[];
      for (final col in columns) {
        final name = col['name'] as String;
        final type = col['type'] as String;
        final notnull = col['notnull'] == 1;
        columnNames.add(name);
        Logger.info('   • $name ($type) ${notnull ? "NOT NULL" : "NULL"}');
      }
      
      Logger.info('═══════════════════════════════════════════\n');
      
      return {
        'columns': columnNames,
        'has_observacao': columnNames.contains('observacao'),
        'has_observacoes': columnNames.contains('observacoes'),
      };
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao verificar schema: $e', null, stack);
      return {};
    }
  }
  
  /// PASSO 3: Popular com dados de teste CORRETOS
  static Future<int> populateWithCorrectTestData() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🚀 POPULANDO COM DADOS DE TESTE CORRETOS');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Pegar uma sessão finalizada
      final sessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['finalized'],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      String sessionId;
      String talhaoId;
      
      if (sessions.isEmpty) {
        Logger.warning('⚠️ Nenhuma sessão finalizada! Pegando qualquer sessão...');
        final anySessions = await db.query('monitoring_sessions', limit: 1);
        
        if (anySessions.isEmpty) {
          Logger.error('❌ Nenhuma sessão encontrada no banco!');
          return 0;
        }
        
        sessionId = anySessions.first['id'] as String;
        talhaoId = anySessions.first['talhao_id'] as String;
      } else {
        sessionId = sessions.first['id'] as String;
        talhaoId = sessions.first['talhao_id'] as String;
      }
      
      Logger.info('✅ Usando sessão: $sessionId');
      Logger.info('✅ Talhão: $talhaoId');
      
      // 2. Pegar ou criar ponto
      var points = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      String pointId;
      if (points.isEmpty) {
        pointId = '${sessionId}_point_1';
        await db.insert('monitoring_points', {
          'id': pointId,
          'session_id': sessionId,
          'numero': 1,
          'latitude': -15.3247,
          'longitude': -54.4278,
          'ordem': 1,
          'status': 'completed',
          'observacoes': 'Ponto de teste',
          'created_at': DateTime.now().toIso8601String(),
        });
        Logger.info('✅ Ponto criado: $pointId');
      } else {
        pointId = points.first['id'] as String;
        Logger.info('✅ Ponto existente: $pointId');
      }
      
      // 3. Criar 5 ocorrências de teste com dados CORRETOS
      final testOccurrences = [
        {
          'tipo': 'Praga',
          'subtipo': 'Lagarta-da-soja',
          'nivel': 'Alto',
          'percentual': 85,
          'obs': 'Infestação severa detectada',
        },
        {
          'tipo': 'Doença',
          'subtipo': 'Ferrugem Asiática',
          'nivel': 'Médio',
          'percentual': 60,
          'obs': 'Manchas características',
        },
        {
          'tipo': 'Planta Daninha',
          'subtipo': 'Buva',
          'nivel': 'Baixo',
          'percentual': 30,
          'obs': 'Controle preventivo necessário',
        },
        {
          'tipo': 'Praga',
          'subtipo': 'Percevejo-marrom',
          'nivel': 'Médio',
          'percentual': 50,
          'obs': 'Monitorar evolução',
        },
        {
          'tipo': 'Doença',
          'subtipo': 'Mofo-branco',
          'nivel': 'Alto',
          'percentual': 75,
          'obs': 'Aplicação urgente recomendada',
        },
      ];
      
      int successCount = 0;
      for (int i = 0; i < testOccurrences.length; i++) {
        final occ = testOccurrences[i];
        
        final saved = await DirectOccurrenceService.saveOccurrence(
          sessionId: sessionId,
          pointId: pointId,
          talhaoId: talhaoId,
          tipo: occ['tipo'] as String,
          subtipo: occ['subtipo'] as String,
          nivel: occ['nivel'] as String,
          percentual: occ['percentual'] as int,
          latitude: -15.3247 + (i * 0.001), // Pequena variação
          longitude: -54.4278 + (i * 0.001),
          observacao: occ['obs'] as String,
          fotoPaths: null,
          tercoPlanta: i % 3 == 0 ? 'Superior' : (i % 3 == 1 ? 'Médio' : 'Baixeiro'),
        );
        
        if (saved) {
          successCount++;
          Logger.info('   ✅ ${occ['subtipo']} (${occ['percentual']}%) salvo!');
        } else {
          Logger.error('   ❌ Falha ao salvar ${occ['subtipo']}!');
        }
      }
      
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🎉 POPULAÇÃO COMPLETA!');
      Logger.info('   Sucesso: $successCount / ${testOccurrences.length}');
      Logger.info('═══════════════════════════════════════════\n');
      
      return successCount;
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao popular dados: $e', null, stack);
      return 0;
    }
  }
  
  /// PASSO 4: Verificar integração completa
  static Future<Map<String, dynamic>> verifyIntegration() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🔍 VERIFICANDO INTEGRAÇÃO COMPLETA');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      final results = <String, dynamic>{};
      
      // 1. Contar em monitoring_occurrences
      final occCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      ) ?? 0;
      results['monitoring_occurrences_count'] = occCount;
      Logger.info('📊 monitoring_occurrences: $occCount');
      
      // 2. Buscar ocorrências com percentual > 0
      final validOcc = await db.query(
        'monitoring_occurrences',
        where: 'percentual > ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
        limit: 10,
      );
      results['valid_occurrences'] = validOcc.length;
      Logger.info('✅ Ocorrências válidas (percentual > 0): ${validOcc.length}');
      
      // Mostrar detalhes
      for (final occ in validOcc) {
        Logger.info('   • ${occ['tipo']}/${occ['subtipo']} - ${occ['percentual']}%');
      }
      
      // 3. Verificar se o Mapa consegue ler
      final mapData = await db.query(
        'monitoring_occurrences',
        columns: ['id', 'tipo', 'subtipo', 'percentual', 'point_id', 'session_id'],
        where: 'percentual > ?',
        whereArgs: [0],
        limit: 5,
      );
      results['map_readable'] = mapData.length;
      Logger.info('📍 Dados legíveis pelo Mapa: ${mapData.length}');
      
      // 4. Verificar se o Relatório consegue ler
      final reportData = await db.rawQuery('''
        SELECT 
          mo.id,
          mo.tipo,
          mo.subtipo,
          mo.percentual,
          mo.data_hora
        FROM monitoring_occurrences mo
        WHERE mo.percentual > 0
        ORDER BY mo.data_hora DESC
        LIMIT 5
      ''');
      results['report_readable'] = reportData.length;
      Logger.info('📊 Dados legíveis pelo Relatório: ${reportData.length}');
      
      Logger.info('═══════════════════════════════════════════');
      
      if (validOcc.length >= 3 && mapData.length >= 3 && reportData.length >= 3) {
        Logger.info('✅ INTEGRAÇÃO OK! Tudo funcionando!');
        results['integration_ok'] = true;
      } else {
        Logger.error('❌ INTEGRAÇÃO COM PROBLEMAS!');
        results['integration_ok'] = false;
      }
      
      Logger.info('═══════════════════════════════════════════\n');
      
      return results;
      
    } catch (e, stack) {
      Logger.error('❌ Erro na verificação: $e', null, stack);
      return {'integration_ok': false, 'error': e.toString()};
    }
  }
  
  /// EXECUÇÃO COMPLETA: Limpar + Verificar + Popular + Testar
  static Future<Map<String, dynamic>> executeCompleteReset() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Limpar
      await cleanAllOccurrences();
      
      // 2. Verificar schema
      final schema = await verifyTableSchema();
      results['schema'] = schema;
      
      // 3. Popular
      final populated = await populateWithCorrectTestData();
      results['populated_count'] = populated;
      
      // 4. Sincronizar para infestation_map
      Logger.info('🔄 Sincronizando dados para o mapa...');
      final syncResult = await MonitoringToMapSyncService.syncAll();
      results['synced_to_map'] = syncResult;
      
      // 5. Verificar integração
      final integration = await verifyIntegration();
      results['integration'] = integration;
      
      // Resultado final
      results['success'] = integration['integration_ok'] == true && syncResult > 0;
      
      if (results['success'] == true) {
        final synced = results['synced_to_map'] ?? 0;
        Logger.info('🎉🎉🎉 RESET COMPLETO EXECUTADO COM SUCESSO! 🎉🎉🎉');
        Logger.info('✅ Banco limpo');
        Logger.info('✅ Dados de teste populados: $populated');
        Logger.info('✅ Sincronizados para mapa: $synced');
        Logger.info('✅ Integração verificada e funcionando!');
        Logger.info('');
        Logger.info('👉 PRÓXIMO PASSO:');
        Logger.info('   1. Vá em: Mapa de Infestação');
        Logger.info('   2. Selecione o talhão');
        Logger.info('   3. DEVE MOSTRAR: $synced pontos no mapa!');
        Logger.info('   4. DEVE MOSTRAR: Heatmap colorido!');
      } else {
        Logger.error('❌ RESET EXECUTADO MAS INTEGRAÇÃO AINDA TEM PROBLEMAS');
        Logger.error('   Dados populados: $populated');
        Logger.error('   Dados sincronizados: ${results['synced_to_map'] ?? 0}');
      }
      
      return results;
      
    } catch (e, stack) {
      Logger.error('❌ Erro no reset completo: $e', null, stack);
      return {'success': false, 'error': e.toString()};
    }
  }
}

