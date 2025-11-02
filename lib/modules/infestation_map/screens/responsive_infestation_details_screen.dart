import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/infestation_summary.dart';
import '../../../widgets/responsive/responsive_widgets.dart';
import '../../../utils/responsive_screen_utils.dart';

/// Tela de detalhes da infestação responsiva
class ResponsiveInfestationDetailsScreen extends StatelessWidget {
  final InfestationSummary summary;

  const ResponsiveInfestationDetailsScreen({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveTitle('Detalhes da Infestação'),
        backgroundColor: _getSeverityColor(summary.level),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ResponsivePadding(
      all: 16.0,
      child: ResponsiveList(
        children: [
          _buildMainInfoCard(context),
          ResponsiveSizedBox(height: 16.0),
          _buildStatsCard(context),
          ResponsiveSizedBox(height: 16.0),
          _buildPeriodCard(context),
          if (summary.trend != null) ...[
            ResponsiveSizedBox(height: 16.0),
            _buildTrendCard(context),
          ],
          if (summary.severity != null) ...[
            ResponsiveSizedBox(height: 16.0),
            _buildSeverityCard(context),
          ],
          ResponsiveSizedBox(height: 16.0),
          _buildMonitoringPointsCard(context),
          ResponsiveSizedBox(height: 16.0),
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsivePadding(
      all: 24.0,
      child: ResponsiveGrid(
        crossAxisCount: 2,
        children: [
          _buildMainInfoCard(context),
          _buildStatsCard(context),
          _buildPeriodCard(context),
          if (summary.trend != null) _buildTrendCard(context),
          if (summary.severity != null) _buildSeverityCard(context),
          _buildMonitoringPointsCard(context),
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsivePadding(
      all: 32.0,
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildMainInfoCard(context),
          _buildStatsCard(context),
          _buildPeriodCard(context),
          if (summary.trend != null) _buildTrendCard(context),
          if (summary.severity != null) _buildSeverityCard(context),
          _buildMonitoringPointsCard(context),
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 4.0,
      borderRadius: 12.0,
      child: ResponsiveContainer(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 12.0)),
          gradient: LinearGradient(
            colors: [
              _getSeverityColor(summary.level).withOpacity(0.1),
              _getSeverityColor(summary.level).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ResponsiveColumn(
          children: [
            ResponsiveRow(
              children: [
                Icon(
                  _getSeverityIcon(summary.level),
                  color: _getSeverityColor(summary.level),
                  size: ResponsiveScreenUtils.getResponsiveIconSize(context, 32.0),
                ),
                ResponsiveSizedBox(width: 12.0),
                Expanded(
                  child: ResponsiveColumn(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveTitle(
                        summary.organismName.isNotEmpty ? summary.organismName : 'Organismo não identificado',
                        fontSize: 20.0,
                      ),
                      ResponsiveSmallText(
                        'Talhão: ${summary.talhaoName.isNotEmpty ? summary.talhaoName : 'Não identificado'}',
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                ResponsiveContainer(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveScreenUtils.scale(context, 12.0),
                    vertical: ResponsiveScreenUtils.scale(context, 6.0),
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(summary.level),
                    borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 20.0)),
                  ),
                  child: ResponsiveText(
                    summary.level,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            ResponsiveSizedBox(height: 16.0),
            ResponsiveSubtitle(
              'Percentual de Infestação: ${summary.infestationPercentage.toStringAsFixed(1)}%',
              fontSize: 18.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 2.0,
      borderRadius: 12.0,
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Estatísticas', fontSize: 18.0),
          ResponsiveSizedBox(height: 12.0),
          ResponsiveRow(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Média de Infestação',
                  '${summary.avgInfestation.toStringAsFixed(2)}',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              ResponsiveSizedBox(width: 12.0),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total de Pontos',
                  '${summary.totalPoints}',
                  Icons.location_on,
                  Colors.green,
                ),
              ),
            ],
          ),
          ResponsiveSizedBox(height: 12.0),
          ResponsiveRow(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Pontos com Ocorrência',
                  '${summary.pointsWithOccurrence}',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              ResponsiveSizedBox(width: 12.0),
              Expanded(
                child: _buildStatItem(
                  context,
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
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return ResponsiveContainer(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 12.0)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 8.0)),
      ),
      child: ResponsiveColumn(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveScreenUtils.getResponsiveIconSize(context, 24.0),
          ),
          ResponsiveSizedBox(height: 8.0),
          ResponsiveText(
            value,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ResponsiveCaption(
            label,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 2.0,
      borderRadius: 12.0,
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Período de Análise', fontSize: 18.0),
          ResponsiveSizedBox(height: 12.0),
          ResponsiveRow(
            children: [
              Icon(
                Icons.date_range,
                color: Colors.blue[600],
                size: ResponsiveScreenUtils.getResponsiveIconSize(context, 16.0),
              ),
              ResponsiveSizedBox(width: 8.0),
              ResponsiveBodyText(
                'Início: ${dateFormat.format(summary.periodoIni)}',
                fontSize: 14.0,
              ),
            ],
          ),
          ResponsiveSizedBox(height: 8.0),
          ResponsiveRow(
            children: [
              Icon(
                Icons.date_range,
                color: Colors.blue[600],
                size: ResponsiveScreenUtils.getResponsiveIconSize(context, 16.0),
              ),
              ResponsiveSizedBox(width: 8.0),
              ResponsiveBodyText(
                'Fim: ${dateFormat.format(summary.periodoFim)}',
                fontSize: 14.0,
              ),
            ],
          ),
          if (summary.lastMonitoringDate != null) ...[
            ResponsiveSizedBox(height: 8.0),
            ResponsiveRow(
              children: [
                Icon(
                  Icons.update,
                  color: Colors.green[600],
                  size: ResponsiveScreenUtils.getResponsiveIconSize(context, 16.0),
                ),
                ResponsiveSizedBox(width: 8.0),
                ResponsiveBodyText(
                  'Último Monitoramento: ${dateFormat.format(summary.lastMonitoringDate!)}',
                  fontSize: 14.0,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 2.0,
      borderRadius: 12.0,
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Tendência', fontSize: 18.0),
          ResponsiveSizedBox(height: 12.0),
          ResponsiveRow(
            children: [
              Icon(
                _getTrendIcon(summary.trend!),
                color: _getTrendColor(summary.trend!),
                size: ResponsiveScreenUtils.getResponsiveIconSize(context, 24.0),
              ),
              ResponsiveSizedBox(width: 8.0),
              ResponsiveText(
                summary.trend!,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: _getTrendColor(summary.trend!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 2.0,
      borderRadius: 12.0,
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Severidade', fontSize: 18.0),
          ResponsiveSizedBox(height: 12.0),
          ResponsiveContainer(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveScreenUtils.scale(context, 12.0),
              vertical: ResponsiveScreenUtils.scale(context, 8.0),
            ),
            decoration: BoxDecoration(
              color: _getSeverityColor(summary.severity!),
              borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 8.0)),
            ),
            child: ResponsiveText(
              summary.severity!,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringPointsCard(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 2.0,
      borderRadius: 12.0,
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Pontos de Monitoramento', fontSize: 18.0),
          ResponsiveSizedBox(height: 12.0),
          LinearProgressIndicator(
            value: summary.totalPoints > 0 ? summary.pointsWithOccurrence / summary.totalPoints : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getSeverityColor(summary.level)),
          ),
          ResponsiveSizedBox(height: 8.0),
          ResponsiveCaption(
            '${summary.pointsWithOccurrence} de ${summary.totalPoints} pontos com ocorrência',
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      margin: EdgeInsets.zero,
      elevation: 2.0,
      borderRadius: 12.0,
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Ações', fontSize: 18.0),
          ResponsiveSizedBox(height: 12.0),
          ResponsiveRow(
            children: [
              Expanded(
                child: ResponsiveButton(
                  text: 'Monitorar',
                  icon: Icon(Icons.monitor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      ResponsiveText('Ação de monitoramento em desenvolvimento'),
                    );
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ResponsiveSizedBox(width: 8.0),
              Expanded(
                child: ResponsiveButton(
                  text: 'Tratar',
                  icon: Icon(Icons.healing),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      ResponsiveText('Ação de tratamento em desenvolvimento'),
                    );
                  },
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
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
