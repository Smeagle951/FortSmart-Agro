import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import '../services/direct_occurrence_service.dart';

/// POPULA O BANCO COM DADOS DE TESTE REAIS
/// Isso vai GARANTIR que a integração funciona
class ForcePopulateTestData {
  
  static Future<void> populateWithRealData() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🚀 POPULANDO BANCO COM DADOS DE TESTE REAIS');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Pegar uma sessão existente
      final sessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['finalized'],
        limit: 1,
      );
      
      if (sessions.isEmpty) {
        Logger.error('❌ Nenhuma sessão finalizada encontrada!');
        return;
      }
      
      final session = sessions.first;
      final sessionId = session['id'] as String;
      final talhaoId = session['talhao_id'] as String;
      
      Logger.info('✅ Usando sessão: $sessionId');
      Logger.info('✅ Talhão: $talhaoId');
      
      // 2. Pegar/criar um ponto para esta sessão
      var points = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      String pointId;
      if (points.isEmpty) {
        // Criar ponto de teste
        pointId = '${sessionId}_point_test';
        await db.insert('monitoring_points', {
          'id': pointId,
          'session_id': sessionId,
          'numero': 1,
          'latitude': -15.3247,
          'longitude': -54.4278,
          'plantas_avaliadas': 10,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        Logger.info('✅ Ponto de teste criado: $pointId');
      } else {
        pointId = points.first['id'] as String;
        Logger.info('✅ Usando ponto existente: $pointId');
      }
      
      // 3. POPULAR COM 3 OCORRÊNCIAS DE TESTE
      final testOccurrences = [
        {
          'tipo': 'Praga',
          'subtipo': 'Lagarta-da-soja',
          'nivel': 'Alto',
          'percentual': 85,
        },
        {
          'tipo': 'Doença',
          'subtipo': 'Ferrugem Asiática',
          'nivel': 'Médio',
          'percentual': 60,
        },
        {
          'tipo': 'Planta Daninha',
          'subtipo': 'Buva',
          'nivel': 'Baixo',
          'percentual': 30,
        },
      ];
      
      int successCount = 0;
      for (final occ in testOccurrences) {
        final saved = await DirectOccurrenceService.saveOccurrence(
          sessionId: sessionId,
          pointId: pointId,
          talhaoId: talhaoId,
          tipo: occ['tipo'] as String,
          subtipo: occ['subtipo'] as String,
          nivel: occ['nivel'] as String,
          percentual: occ['percentual'] as int,
          latitude: -15.3247,
          longitude: -54.4278,
          observacao: 'Ocorrência de teste - ${occ['subtipo']}',
          fotoPaths: null,
          tercoPlanta: 'Médio',
        );
        
        if (saved) {
          successCount++;
          Logger.info('✅ Ocorrência ${occ['subtipo']} salva!');
        } else {
          Logger.error('❌ Falha ao salvar ${occ['subtipo']}!');
        }
      }
      
      // 4. VERIFICAR RESULTADO
      final finalCount = await DirectOccurrenceService.countOccurrencesForSession(sessionId);
      
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🎉 POPULAÇÃO COMPLETA!');
      Logger.info('   - Ocorrências inseridas: $successCount');
      Logger.info('   - Ocorrências no banco: $finalCount');
      Logger.info('═══════════════════════════════════════════');
      
      if (finalCount >= 3) {
        Logger.info('✅ SUCESSO! Agora o Mapa de Infestação deve funcionar!');
      } else {
        Logger.error('❌ PROBLEMA: Esperava 3+, mas tem apenas $finalCount');
      }
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao popular dados de teste: $e', null, stack);
    }
  }
  
  /// Limpa todas as ocorrências de teste
  static Future<void> clearTestData() async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('monitoring_occurrences');
      Logger.info('✅ Ocorrências de teste removidas');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados: $e');
    }
  }
}

