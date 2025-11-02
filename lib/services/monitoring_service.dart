import '../models/monitoring.dart';
import '../repositories/monitoring_repository.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar monitoramentos
class MonitoringService {
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  /// Obtém todos os monitoramentos
  Future<List<Monitoring>> getAllMonitorings() async {
    try {
      Logger.info('🔄 [MonitoringService] Carregando monitoramentos...');
      
      // Por enquanto, retornar lista vazia até implementar o repositório
      // TODO: Implementar carregamento real de monitoramentos
      final monitorings = <Monitoring>[];
      
      Logger.info('✅ [MonitoringService] ${monitorings.length} monitoramentos carregados');
      return monitorings;
      
    } catch (e) {
      Logger.error('❌ [MonitoringService] Erro ao carregar monitoramentos: $e');
      return [];
    }
  }

  /// Obtém monitoramentos pendentes
  Future<List<Monitoring>> getPendingMonitorings() async {
    try {
      final allMonitorings = await getAllMonitorings();
      return allMonitorings.where((m) => !m.isCompleted).toList();
    } catch (e) {
      Logger.error('❌ [MonitoringService] Erro ao carregar monitoramentos pendentes: $e');
      return [];
    }
  }

  /// Obtém monitoramentos concluídos
  Future<List<Monitoring>> getCompletedMonitorings() async {
    try {
      final allMonitorings = await getAllMonitorings();
      return allMonitorings.where((m) => m.isCompleted).toList();
    } catch (e) {
      Logger.error('❌ [MonitoringService] Erro ao carregar monitoramentos concluídos: $e');
      return [];
    }
  }

  /// Obtém estatísticas de monitoramento
  Future<Map<String, int>> getMonitoringStats() async {
    try {
      final allMonitorings = await getAllMonitorings();
      final pending = allMonitorings.where((m) => !m.isCompleted).length;
      final completed = allMonitorings.where((m) => m.isCompleted).length;
      final highInfestation = allMonitorings.where((m) => 
        m.points.any((p) => p.occurrences.any((o) => o.infestationIndex > 0.7))
      ).length;

      return {
        'total': allMonitorings.length,
        'pending': pending,
        'completed': completed,
        'highInfestation': highInfestation,
      };
    } catch (e) {
      Logger.error('❌ [MonitoringService] Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'pending': 0,
        'completed': 0,
        'highInfestation': 0,
      };
    }
  }
}
