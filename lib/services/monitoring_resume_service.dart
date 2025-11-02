import '../../database/app_database.dart';
import '../../utils/logger.dart';

/// Serviço para gerenciar a continuação de monitoramentos interrompidos
class MonitoringResumeService {
  static const String _tag = 'MonitoringResumeService';

  /// Verifica se um monitoramento pode ser continuado
  Future<bool> canResumeMonitoring(String monitoringId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar se há sessão ativa
      final activeSession = await db.query(
        'monitoring_sessions',
        where: 'id = ? AND status = ?',
        whereArgs: [monitoringId, 'in_progress'],
        limit: 1,
      );
      
      if (activeSession.isNotEmpty) {
        Logger.info('$_tag: ✅ Sessão ativa encontrada: $monitoringId');
        return true;
      }
      
      // Verificar se há pontos não monitorados
      final unmonitoredPoints = await _getUnmonitoredPoints(monitoringId);
      
      if (unmonitoredPoints.isNotEmpty) {
        Logger.info('$_tag: ✅ Pontos não monitorados encontrados: ${unmonitoredPoints.length}');
        return true;
      }
      
      Logger.info('$_tag: ⚠️ Monitoramento não pode ser continuado: $monitoringId');
      return false;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar se pode continuar: $e');
      return false;
    }
  }

  /// Obtém próximo ponto não monitorado
  Future<Map<String, dynamic>?> getNextUnmonitoredPoint(String monitoringId) async {
    try {
      final unmonitoredPoints = await _getUnmonitoredPoints(monitoringId);
      
      if (unmonitoredPoints.isEmpty) {
        Logger.info('$_tag: ⚠️ Nenhum ponto não monitorado encontrado');
        return null;
      }
      
      // Retornar o próximo ponto (menor número)
      final nextPoint = unmonitoredPoints.first;
      Logger.info('$_tag: ✅ Próximo ponto encontrado: ${nextPoint['numero']}');
      
      return nextPoint;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter próximo ponto: $e');
      return null;
    }
  }

  /// Obtém todos os pontos não monitorados
  Future<List<Map<String, dynamic>>> _getUnmonitoredPoints(String monitoringId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Buscar pontos planejados
      final plannedPoints = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [monitoringId],
        orderBy: 'numero ASC',
      );
      
      // Buscar pontos já monitorados
      final monitoredPoints = await db.query(
        'pontos_monitoramento',
        where: 'monitoring_id = ? OR session_id = ?',
        whereArgs: [monitoringId, monitoringId],
      );
      
      // Encontrar pontos não monitorados
      final unmonitoredPoints = <Map<String, dynamic>>[];
      
      for (final plannedPoint in plannedPoints) {
        final pointNumber = plannedPoint['numero'] as int;
        final isMonitored = monitoredPoints.any((monitored) => 
          monitored['numero'] == pointNumber);
        
        if (!isMonitored) {
          unmonitoredPoints.add({
            'id': plannedPoint['id'],
            'numero': pointNumber,
            'latitude': plannedPoint['latitude'],
            'longitude': plannedPoint['longitude'],
            'session_id': monitoringId,
          });
        }
      }
      
      Logger.info('$_tag: Pontos não monitorados: ${unmonitoredPoints.length}');
      return unmonitoredPoints;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar pontos não monitorados: $e');
      return [];
    }
  }

  /// Obtém progresso do monitoramento
  Future<Map<String, dynamic>> getMonitoringProgress(String monitoringId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Buscar pontos planejados
      final plannedPoints = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [monitoringId],
      );
      
      // Buscar pontos monitorados
      final monitoredPoints = await db.query(
        'pontos_monitoramento',
        where: 'monitoring_id = ? OR session_id = ?',
        whereArgs: [monitoringId, monitoringId],
      );
      
      final totalPoints = plannedPoints.length;
      final monitoredCount = monitoredPoints.length;
      final unmonitoredCount = totalPoints - monitoredCount;
      final progressPercentage = totalPoints > 0 ? (monitoredCount / totalPoints * 100).round() : 0;
      
      return {
        'total_points': totalPoints,
        'monitored_count': monitoredCount,
        'unmonitored_count': unmonitoredCount,
        'progress_percentage': progressPercentage,
        'can_resume': unmonitoredCount > 0,
      };
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter progresso: $e');
      return {
        'total_points': 0,
        'monitored_count': 0,
        'unmonitored_count': 0,
        'progress_percentage': 0,
        'can_resume': false,
      };
    }
  }

  /// Salva estado do monitoramento para continuação posterior
  Future<bool> saveMonitoringState({
    required String monitoringId,
    required String talhaoId,
    required String cropName,
    required List<Map<String, dynamic>> plannedPoints,
    required String technicianName,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar se já existe uma sessão
      final existingSession = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [monitoringId],
        limit: 1,
      );
      
      if (existingSession.isEmpty) {
        // Criar nova sessão
        await db.insert('monitoring_sessions', {
          'id': monitoringId,
          'talhao_id': talhaoId,
          'crop_name': cropName,
          'technician_name': technicianName,
          'status': 'in_progress',
          'started_at': DateTime.now().toIso8601String(),
          'sync_state': 'pending',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        Logger.info('$_tag: ✅ Nova sessão criada: $monitoringId');
      } else {
        // Atualizar sessão existente
        await db.update(
          'monitoring_sessions',
          {
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [monitoringId],
        );
        
        Logger.info('$_tag: ✅ Sessão atualizada: $monitoringId');
      }
      
      // Salvar pontos planejados
      for (final point in plannedPoints) {
        await db.insert(
          'monitoring_points',
          {
            'id': point['id'] ?? '${monitoringId}_${point['numero']}',
            'session_id': monitoringId,
            'numero': point['numero'],
            'latitude': point['latitude'],
            'longitude': point['longitude'],
            'timestamp': DateTime.now().toIso8601String(),
            'sync_state': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      Logger.info('$_tag: ✅ Estado do monitoramento salvo: $monitoringId');
      return true;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao salvar estado: $e');
      return false;
    }
  }

  /// Finaliza o monitoramento
  Future<bool> finishMonitoring(String monitoringId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      await db.update(
        'monitoring_sessions',
        {
          'status': 'completed',
          'finished_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [monitoringId],
      );
      
      Logger.info('$_tag: ✅ Monitoramento finalizado: $monitoringId');
      return true;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao finalizar monitoramento: $e');
      return false;
    }
  }

  /// Obtém monitoramentos que podem ser continuados
  Future<List<Map<String, dynamic>>> getResumableMonitorings() async {
    try {
      final db = await AppDatabase.instance.database;
      
      final resumableMonitorings = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['in_progress'],
        orderBy: 'updated_at DESC',
      );
      
      // Verificar quais realmente podem ser continuados
      final validMonitorings = <Map<String, dynamic>>[];
      
      for (final monitoring in resumableMonitorings) {
        final monitoringId = monitoring['id'] as String;
        final canResume = await canResumeMonitoring(monitoringId);
        
        if (canResume) {
          final progress = await getMonitoringProgress(monitoringId);
          validMonitorings.add({
            ...monitoring,
            'progress': progress,
          });
        }
      }
      
      Logger.info('$_tag: ✅ Monitoramentos resumíveis encontrados: ${validMonitorings.length}');
      return validMonitorings;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar monitoramentos resumíveis: $e');
      return [];
    }
  }
}
