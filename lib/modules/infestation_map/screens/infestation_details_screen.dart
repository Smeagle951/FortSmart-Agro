import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/infestation_summary.dart';

/// Tela de detalhes da infestação
class InfestationDetailsScreen extends StatelessWidget {
  final InfestationSummary summary;

  const InfestationDetailsScreen({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Infestação'),
        backgroundColor: _getSeverityColor(summary.level),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal com informações básicas
            _buildMainInfoCard(),
            const SizedBox(height: 16),
            
            // Card de estatísticas
            _buildStatsCard(),
            const SizedBox(height: 16),
            
            // Card de período
            _buildPeriodCard(),
            const SizedBox(height: 16),
            
            // Card de tendência (se disponível)
            if (summary.trend != null) ...[
              _buildTrendCard(),
              const SizedBox(height: 16),
            ],
            
            // Card de severidade (se disponível)
            if (summary.severity != null) ...[
              _buildSeverityCard(),
              const SizedBox(height: 16),
            ],
            
            // Card de pontos de monitoramento
            _buildMonitoringPointsCard(),
            const SizedBox(height: 16),
            
            // Ações
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getSeverityColor(summary.level).withOpacity(0.1),
              _getSeverityColor(summary.level).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSeverityIcon(summary.level),
                  color: _getSeverityColor(summary.level),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.organismName.isNotEmpty ? summary.organismName : 'Organismo não identificado',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Talhão: ${summary.talhaoName.isNotEmpty ? summary.talhaoName : 'Não identificado'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(summary.level),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    summary.level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Percentual de Infestação: ${summary.infestationPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Média de Infestação',
                    '${summary.avgInfestation.toStringAsFixed(2)}',
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total de Pontos',
                    '${summary.totalPoints}',
                    Icons.location_on,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Pontos com Ocorrência',
                    '${summary.pointsWithOccurrence}',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Taxa de Ocorrência',
                    '${((summary.pointsWithOccurrence / (summary.totalPoints > 0 ? summary.totalPoints : 1)) * 100).toStringAsFixed(1)}%',
                    Icons.percent,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período de Análise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Início: ${dateFormat.format(summary.periodoIni)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Fim: ${dateFormat.format(summary.periodoFim)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (summary.lastMonitoringDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.update, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Último Monitoramento: ${dateFormat.format(summary.lastMonitoringDate!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendência',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getTrendIcon(summary.trend!),
                  color: _getTrendColor(summary.trend!),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  summary.trend!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTrendColor(summary.trend!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Severidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getSeverityColor(summary.severity!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary.severity!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringPointsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pontos de Monitoramento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: summary.totalPoints > 0 ? summary.pointsWithOccurrence / summary.totalPoints : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getSeverityColor(summary.level)),
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.pointsWithOccurrence} de ${summary.totalPoints} pontos com ocorrência',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar ação de monitoramento
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ação de monitoramento em desenvolvimento')),
                      );
                    },
                    icon: const Icon(Icons.monitor),
                    label: const Text('Monitorar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar ação de tratamento
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ação de tratamento em desenvolvimento')),
                      );
                    },
                    icon: const Icon(Icons.healing),
                    label: const Text('Tratar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRÍTICO':
      case 'CRITICO':
        return Colors.red;
      case 'ALTO':
        return Colors.orange;
      case 'MÉDIO':
      case 'MEDIO':
        return Colors.yellow[700]!;
      case 'BAIXO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String level) {
    switch (level.toUpperCase()) {
      case 'CRÍTICO':
      case 'CRITICO':
        return Icons.dangerous;
      case 'ALTO':
        return Icons.warning;
      case 'MÉDIO':
      case 'MEDIO':
        return Icons.info;
      case 'BAIXO':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'crescendo':
      case 'aumentando':
        return Icons.trending_up;
      case 'diminuindo':
      case 'decrescendo':
        return Icons.trending_down;
      case 'estável':
      case 'estavel':
        return Icons.trending_flat;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'crescendo':
      case 'aumentando':
        return Colors.red;
      case 'diminuindo':
      case 'decrescendo':
        return Colors.green;
      case 'estável':
      case 'estavel':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
