import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget para exibir estatísticas de infestação
class InfestationStatsCard extends StatelessWidget {
  final List<InfestationSummary> summaries;
  final List<InfestationAlert> alerts;

  const InfestationStatsCard({
    Key? key,
    required this.summaries,
    required this.alerts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSummaryStats(),
            const SizedBox(height: 16),
            _buildLevelDistribution(),
            const SizedBox(height: 16),
            _buildAlertsSummary(),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.analytics, color: Color(0xFF2A4F3D)),
        const SizedBox(width: 8),
        const Text(
          'Estatísticas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2A4F3D),
          ),
        ),
      ],
    );
  }

  /// Constrói estatísticas resumidas
  Widget _buildSummaryStats() {
    final totalTalhoes = summaries.map((s) => s.talhaoId).toSet().length;
    final totalOrganismos = summaries.map((s) => s.organismoId).toSet().length;
    final totalPontos = summaries.fold<int>(0, (sum, s) => sum + s.totalPoints);
    final pontosComOcorrencia = summaries.fold<int>(0, (sum, s) => sum + s.pointsWithOccurrence);

    return Column(
      children: [
        _buildStatRow('Talhões', totalTalhoes.toString(), Icons.map),
        const SizedBox(height: 8),
        _buildStatRow('Organismos', totalOrganismos.toString(), Icons.bug_report),
        const SizedBox(height: 8),
        _buildStatRow('Total de Pontos', totalPontos.toString(), Icons.gps_fixed),
        const SizedBox(height: 8),
        _buildStatRow('Com Ocorrência', pontosComOcorrencia.toString(), Icons.warning),
      ],
    );
  }

  /// Constrói linha de estatística
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Constrói distribuição por níveis
  Widget _buildLevelDistribution() {
    final levelCounts = <String, int>{};
    
    for (final summary in summaries) {
      levelCounts[summary.level] = (levelCounts[summary.level] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribuição por Níveis',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...InfestationLevel.values.map((level) {
          final count = levelCounts[level.code] ?? 0;
          return _buildLevelRow(level, count);
        }),
      ],
    );
  }

  /// Constrói linha de nível
  Widget _buildLevelRow(InfestationLevel level, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              level.label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói resumo de alertas
  Widget _buildAlertsSummary() {
    final totalAlerts = alerts.length;
    final criticalAlerts = alerts.where((a) => a.isCritical).length;
    final highRiskAlerts = alerts.where((a) => a.isHighRisk).length;
    final acknowledgedAlerts = alerts.where((a) => a.isAcknowledged).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Alertas',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: totalAlerts > 0 ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                totalAlerts.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAlertStatRow('Críticos', criticalAlerts, Colors.red),
        _buildAlertStatRow('Alto Risco', highRiskAlerts, Colors.orange),
        _buildAlertStatRow('Reconhecidos', acknowledgedAlerts, Colors.green),
      ],
    );
  }

  /// Constrói linha de estatística de alerta
  Widget _buildAlertStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
