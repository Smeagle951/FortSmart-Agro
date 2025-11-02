import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// 🔄 WRAPPER: Garante sincronização SEMPRE, independente do método de salvamento
class OccurrenceSyncWrapper {
  static const String _tag = 'SYNC_WRAPPER';
  
  /// Sincroniza UMA ocorrência para infestation_map
  /// Pode ser chamado DEPOIS de qualquer método de salvamento
  static Future<bool> ensureSyncToMap({
    required String occurrenceId,
    required String pointId,
    required String sessionId,
    required String talhaoId,
  }) async {
    try {
      Logger.info('🔄 [$_tag] Garantindo sincronização para infestation_map...');
      Logger.info('   - Occurrence ID: $occurrenceId');
      Logger.info('   - Point ID: $pointId');
      Logger.info('   - Session ID: $sessionId');
      Logger.info('   - Talhão ID: $talhaoId');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Verificar se já existe em infestation_map
      final existing = await db.query(
        'infestation_map',
        where: 'id = ?',
        whereArgs: [occurrenceId],
      );
      
      if (existing.isNotEmpty) {
        Logger.info('✅ [$_tag] Já sincronizado!');
        return true;
      }
      
      // 2. Buscar dados da ocorrência
      final occData = await db.query(
        'monitoring_occurrences',
        where: 'id = ?',
        whereArgs: [occurrenceId],
        limit: 1,
      );
      
      if (occData.isEmpty) {
        Logger.warning('⚠️ [$_tag] Ocorrência não encontrada em monitoring_occurrences');
        return false;
      }
      
      final occ = occData.first;
      
      // 3. Buscar dados da sessão
      final sessionData = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      if (sessionData.isEmpty) {
        Logger.warning('⚠️ [$_tag] Sessão não encontrada');
        return false;
      }
      
      final session = sessionData.first;
      
      // 4. Inserir em infestation_map
      await db.insert(
        'infestation_map',
        {
          'id': occurrenceId,
          'ponto_id': occ['point_id'],
          'talhao_id': talhaoId,
          'latitude': occ['latitude'],
          'longitude': occ['longitude'],
          'tipo': occ['tipo'],
          'subtipo': occ['subtipo'],
          'nivel': occ['nivel'],
          'percentual': occ['percentual'],
          'observacao': occ['observacao'],
          'foto_paths': occ['foto_paths'],
          'data_hora': occ['data_hora'],
          'sincronizado': 0,
          'cultura_id': session['cultura_id'],
          'cultura_nome': session['cultura_nome'],
          'talhao_nome': session['talhao_nome'],
          'severity_level': occ['nivel']?.toString().toLowerCase() ?? 'low',
          'status': 'active',
          'source': 'monitoring_module',
          'created_at': occ['created_at'],
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ [$_tag] Sincronização concluída!');
      return true;
      
    } catch (e, stack) {
      Logger.error('❌ [$_tag] Erro na sincronização: $e');
      Logger.error('❌ [$_tag] Stack: $stack');
      return false;
    }
  }
  
  /// Sincroniza TODAS as ocorrências de uma sessão
  static Future<int> syncAllFromSession(String sessionId) async {
    try {
      Logger.info('🔄 [$_tag] Sincronizando TODAS as ocorrências da sessão $sessionId...');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar todas as ocorrências da sessão
      final occurrences = await db.query(
        'monitoring_occurrences',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      Logger.info('📊 [$_tag] ${occurrences.length} ocorrências encontradas');
      
      int synced = 0;
      for (final occ in occurrences) {
        final success = await ensureSyncToMap(
          occurrenceId: occ['id'] as String,
          pointId: occ['point_id'] as String,
          sessionId: sessionId,
          talhaoId: occ['talhao_id'] as String,
        );
        
        if (success) synced++;
      }
      
      Logger.info('✅ [$_tag] $synced/${occurrences.length} sincronizadas!');
      return synced;
      
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao sincronizar sessão: $e');
      return 0;
    }
  }
}

