import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar histórico de infestação
class InfestationHistoryService {
  static final InfestationHistoryService _instance = InfestationHistoryService._internal();
  factory InfestationHistoryService() => _instance;
  InfestationHistoryService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Obtém histórico de infestação para um talhão e organismo específico
  Future<List<Occurrence>> getInfestationHistory({
    required String talhaoId,
    required String organismId,
    int limit = 5,
  }) async {
    try {
      Logger.info('🔍 Buscando histórico de infestação - Talhão: $talhaoId, Organismo: $organismId');
      
      final db = await _databaseHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'occurrences',
        where: 'monitoringPointId LIKE ? AND name = ?',
        whereArgs: ['%$talhaoId%', organismId],
        orderBy: 'createdAt DESC',
        limit: limit,
      );

      final occurrences = maps.map((map) => Occurrence.fromMap(map)).toList();
      Logger.info('✅ ${occurrences.length} ocorrências históricas encontradas');
      return occurrences;
    } catch (e) {
      Logger.error('❌ Erro ao buscar histórico de infestação: $e');
      return [];
    }
  }

  /// Obtém histórico de infestação para um talhão (todos os organismos)
  Future<List<Occurrence>> getTalhaoInfestationHistory({
    required String talhaoId,
    int limit = 10,
  }) async {
    try {
      Logger.info('🔍 Buscando histórico de infestação para talhão: $talhaoId');
      
      final db = await _databaseHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'occurrences',
        where: 'monitoringPointId LIKE ?',
        whereArgs: ['%$talhaoId%'],
        orderBy: 'createdAt DESC',
        limit: limit,
      );

      final occurrences = maps.map((map) => Occurrence.fromMap(map)).toList();
      Logger.info('✅ ${occurrences.length} ocorrências históricas encontradas');
      return occurrences;
    } catch (e) {
      Logger.error('❌ Erro ao buscar histórico de infestação do talhão: $e');
      return [];
    }
  }

  /// Gera resumo automático do histórico de infestação
  Future<String> generateHistorySummary({
    required String talhaoId,
    required String organismId,
  }) async {
    try {
      Logger.info('📝 Gerando resumo do histórico - Talhão: $talhaoId, Organismo: $organismId');
      
      final history = await getInfestationHistory(
        talhaoId: talhaoId,
        organismId: organismId,
        limit: 3,
      );

      if (history.isEmpty) {
        return 'Nenhum histórico de infestação encontrado para este organismo.';
      }

      final lastOccurrence = history.first;
      final daysSinceLast = DateTime.now().difference(lastOccurrence.createdAt).inDays;
      
      // Determina severidade baseada no índice de infestação
      String severity = 'baixa';
      if (lastOccurrence.infestationIndex > 70) {
        severity = 'alta';
      } else if (lastOccurrence.infestationIndex > 30) {
        severity = 'média';
      }

      // Gera resumo contextual
      String summary = '$organismId registrado há $daysSinceLast dias com severidade $severity';
      
      if (history.length > 1) {
        final secondOccurrence = history[1];
        final daysBetween = lastOccurrence.createdAt.difference(secondOccurrence.createdAt).inDays;
        summary += '. Registro anterior há ${daysSinceLast + daysBetween} dias';
      }

      // Adiciona tendência se houver dados suficientes
      if (history.length >= 2) {
        final trend = _calculateTrend(history);
        summary += '. Tendência: $trend';
      }

      Logger.info('✅ Resumo gerado: $summary');
      return summary;
    } catch (e) {
      Logger.error('❌ Erro ao gerar resumo do histórico: $e');
      return 'Erro ao gerar resumo do histórico.';
    }
  }

  /// Calcula tendência baseada nas ocorrências históricas
  String _calculateTrend(List<Occurrence> occurrences) {
    if (occurrences.length < 2) return 'insuficiente';

    final recent = occurrences.first.infestationIndex;
    final previous = occurrences[1].infestationIndex;
    
    final difference = recent - previous;
    final percentChange = (difference / previous * 100).abs();

    if (percentChange < 10) {
      return 'estável';
    } else if (difference > 0) {
      return 'crescente';
    } else {
      return 'decrescente';
    }
  }

  /// Obtém estatísticas de infestação para um talhão
  Future<Map<String, dynamic>> getInfestationStatistics(String talhaoId) async {
    try {
      Logger.info('📊 Calculando estatísticas de infestação para talhão: $talhaoId');
      
      final history = await getTalhaoInfestationHistory(talhaoId: talhaoId, limit: 50);
      
      if (history.isEmpty) {
        return {
          'totalOccurrences': 0,
          'uniqueOrganisms': 0,
          'averageSeverity': 0.0,
          'mostCommonOrganism': null,
          'lastOccurrenceDate': null,
          'organismFrequency': {},
        };
      }

      final totalOccurrences = history.length;
      final uniqueOrganisms = history.map((o) => o.name).toSet().length;
      final averageSeverity = history.map((o) => o.infestationIndex).reduce((a, b) => a + b) / totalOccurrences;
      final lastOccurrenceDate = history.first.createdAt;

      // Calcula frequência de organismos
      final organismFrequency = <String, int>{};
      for (final occurrence in history) {
        organismFrequency[occurrence.name] = (organismFrequency[occurrence.name] ?? 0) + 1;
      }

      // Encontra organismo mais comum
      String? mostCommonOrganism;
      int maxFrequency = 0;
      for (final entry in organismFrequency.entries) {
        if (entry.value > maxFrequency) {
          maxFrequency = entry.value;
          mostCommonOrganism = entry.key;
        }
      }

      final statistics = {
        'totalOccurrences': totalOccurrences,
        'uniqueOrganisms': uniqueOrganisms,
        'averageSeverity': averageSeverity,
        'mostCommonOrganism': mostCommonOrganism,
        'lastOccurrenceDate': lastOccurrenceDate.toIso8601String(),
        'organismFrequency': organismFrequency,
      };

      Logger.info('✅ Estatísticas calculadas: $totalOccurrences ocorrências, $uniqueOrganisms organismos únicos');
      return statistics;
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas: $e');
      return {};
    }
  }

  /// Obtém organismos mais frequentes em um talhão
  Future<List<Map<String, dynamic>>> getMostFrequentOrganisms(String talhaoId) async {
    try {
      Logger.info('🔍 Buscando organismos mais frequentes no talhão: $talhaoId');
      
      final history = await getTalhaoInfestationHistory(talhaoId: talhaoId, limit: 100);
      
      final organismCount = <String, int>{};
      final organismSeverity = <String, List<double>>{};
      
      for (final occurrence in history) {
        organismCount[occurrence.name] = (organismCount[occurrence.name] ?? 0) + 1;
        organismSeverity.putIfAbsent(occurrence.name, () => []).add(occurrence.infestationIndex);
      }

      final frequentOrganisms = organismCount.entries.map((entry) {
        final name = entry.key;
        final count = entry.value;
        final severities = organismSeverity[name] ?? [];
        final averageSeverity = severities.reduce((a, b) => a + b) / severities.length;
        final maxSeverity = severities.isNotEmpty ? severities.reduce((a, b) => a > b ? a : b) : 0.0;

        return {
          'name': name,
          'frequency': count,
          'averageSeverity': averageSeverity,
          'maxSeverity': maxSeverity,
          'lastOccurrence': history.firstWhere((o) => o.name == name).createdAt,
        };
      }).toList();

      // Ordena por frequência
      frequentOrganisms.sort((a, b) => (b['frequency'] as int).compareTo(a['frequency'] as int));

      Logger.info('✅ ${frequentOrganisms.length} organismos frequentes encontrados');
      return frequentOrganisms;
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismos frequentes: $e');
      return [];
    }
  }

  /// Verifica se há infestação recente (últimos 7 dias)
  Future<bool> hasRecentInfestation(String talhaoId, {int daysThreshold = 7}) async {
    try {
      final history = await getTalhaoInfestationHistory(talhaoId: talhaoId, limit: 1);
      
      if (history.isEmpty) return false;

      final daysDifference = DateTime.now().difference(history.first.createdAt).inDays;
      final hasRecent = daysDifference <= daysThreshold;
      
      Logger.info('📅 Última infestação há ${daysDifference} dias - ${hasRecent ? 'Recente' : 'Antiga'}');
      return hasRecent;
    } catch (e) {
      Logger.error('❌ Erro ao verificar infestação recente: $e');
      return false;
    }
  }
}
