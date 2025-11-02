import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// ✅ SERVIÇO DE SINCRONIZAÇÃO AUTOMÁTICA
/// Garante que dados de monitoring_occurrences apareçam em infestation_map
class MonitoringToMapSyncService {
  static const String _tag = 'SYNC_SERVICE';
  
  /// Sincroniza TODOS os dados de monitoring_occurrences para infestation_map
  static Future<int> syncAll() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🔄 [$_tag] SINCRONIZAÇÃO COMPLETA INICIADA');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Contar registros em cada tabela ANTES
      final countOccBefore = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      ) ?? 0;
      
      final countMapBefore = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM infestation_map')
      ) ?? 0;
      
      Logger.info('📊 [$_tag] ANTES DA SINCRONIZAÇÃO:');
      Logger.info('   • monitoring_occurrences: $countOccBefore');
      Logger.info('   • infestation_map: $countMapBefore');
      
      // 2. Buscar TODAS as ocorrências que NÃO estão no mapa
      final occurrencesToSync = await db.rawQuery('''
        SELECT 
          mo.id,
          mo.point_id as ponto_id,
          mo.session_id,
          mo.talhao_id,
          mo.tipo,
          mo.subtipo as organismo_nome,
          mo.nivel,
          mo.percentual as infestacao_percent,
          mo.percentual as intensidade_media,
          mo.latitude,
          mo.longitude,
          mo.observacao,
          mo.foto_paths,
          mo.terco_planta,
          mo.data_hora as data_hora_ocorrencia,
          mo.created_at
        FROM monitoring_occurrences mo
        WHERE mo.id NOT IN (
          SELECT id FROM infestation_map WHERE id IS NOT NULL
        )
        AND mo.percentual > 0
        AND mo.latitude IS NOT NULL
        AND mo.longitude IS NOT NULL
      ''');
      
      Logger.info('📦 [$_tag] ${occurrencesToSync.length} ocorrências para sincronizar');
      
      // 3. Inserir cada ocorrência em infestation_map
      int synced = 0;
      for (final occ in occurrencesToSync) {
        try {
          await db.insert(
            'infestation_map',
            {
              'id': occ['id'],
              'ponto_id': occ['ponto_id'],
              'talhao_id': occ['talhao_id'],
              'organismo_id': '${occ['tipo']}_${occ['organismo_nome']}'.replaceAll(' ', '_'),
              'organismo_nome': occ['organismo_nome'],
              'tipo': occ['tipo'],
              'nivel': occ['nivel'],
              'infestacao_percent': occ['infestacao_percent'],
              'intensidade_media': occ['intensidade_media'],
              'quantidade_organismo': occ['infestacao_percent'], // Usar percentual como quantidade
              'latitude': occ['latitude'],
              'longitude': occ['longitude'],
              'terco_planta': occ['terco_planta'],
              'observacao': occ['observacao'],
              'foto_paths': occ['foto_paths'],
              'data_hora_ocorrencia': occ['data_hora_ocorrencia'],
              'created_at': occ['created_at'],
              'updated_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore, // Ignorar duplicatas
          );
          synced++;
          
          if (synced % 10 == 0) {
            Logger.info('   ✅ $synced sincronizadas...');
          }
          
        } catch (e) {
          Logger.error('   ❌ Erro ao sincronizar ${occ['id']}: $e');
          continue;
        }
      }
      
      // 4. Contar registros DEPOIS
      final countMapAfter = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM infestation_map')
      ) ?? 0;
      
      Logger.info('═══════════════════════════════════════════');
      Logger.info('✅ [$_tag] SINCRONIZAÇÃO COMPLETA!');
      Logger.info('   • Ocorrências sincronizadas: $synced');
      Logger.info('   • infestation_map ANTES: $countMapBefore');
      Logger.info('   • infestation_map DEPOIS: $countMapAfter');
      Logger.info('   • GANHO: +${countMapAfter - countMapBefore}');
      Logger.info('═══════════════════════════════════════════');
      
      return synced;
      
    } catch (e, stack) {
      Logger.error('❌ [$_tag] ERRO NA SINCRONIZAÇÃO: $e');
      Logger.error('❌ [$_tag] Stack: $stack');
      return 0;
    }
  }
  
  /// Sincroniza UMA ocorrência específica
  static Future<bool> syncOne(String occurrenceId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Buscar ocorrência
      final occ = await db.query(
        'monitoring_occurrences',
        where: 'id = ?',
        whereArgs: [occurrenceId],
      );
      
      if (occ.isEmpty) {
        Logger.error('❌ [$_tag] Ocorrência $occurrenceId não encontrada');
        return false;
      }
      
      final occData = occ.first;
      
      // Inserir em infestation_map
      await db.insert(
        'infestation_map',
        {
          'id': occData['id'],
          'ponto_id': occData['point_id'],
          'talhao_id': occData['talhao_id'],
          'organismo_id': '${occData['tipo']}_${occData['subtipo']}'.replaceAll(' ', '_'),
          'organismo_nome': occData['subtipo'],
          'tipo': occData['tipo'],
          'nivel': occData['nivel'],
          'infestacao_percent': occData['percentual'],
          'intensidade_media': occData['percentual'],
          'quantidade_organismo': occData['percentual'],
          'latitude': occData['latitude'],
          'longitude': occData['longitude'],
          'terco_planta': occData['terco_planta'],
          'observacao': occData['observacao'],
          'foto_paths': occData['foto_paths'],
          'data_hora_ocorrencia': occData['data_hora'],
          'created_at': occData['created_at'],
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ [$_tag] Ocorrência $occurrenceId sincronizada!');
      return true;
      
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao sincronizar ocorrência: $e');
      return false;
    }
  }
  
  /// Diagnóstico rápido
  static Future<Map<String, int>> quickDiagnostic() async {
    final db = await AppDatabase.instance.database;
    
    final occCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences WHERE percentual > 0')
    ) ?? 0;
    
    final mapCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM infestation_map')
    ) ?? 0;
    
    final diff = occCount - mapCount;
    
    Logger.info('📊 [$_tag] DIAGNÓSTICO:');
    Logger.info('   • monitoring_occurrences (válidas): $occCount');
    Logger.info('   • infestation_map: $mapCount');
    Logger.info('   • Diferença (faltam sincronizar): $diff');
    
    return {
      'occurrences': occCount,
      'map': mapCount,
      'missing': diff,
    };
  }
}

