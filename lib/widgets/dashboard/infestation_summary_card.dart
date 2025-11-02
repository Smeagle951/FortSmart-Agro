import 'package:flutter/material.dart';
import '../fortsmart_card.dart';
import '../../modules/infestation_map/repositories/unified_monitoring_repository.dart';
import '../../modules/infestation_map/models/models.dart';
import '../../utils/logger.dart';

/// Card resumo de infestação para dashboard
class InfestationSummaryCard extends StatefulWidget {
  final int? talhaoId;
  final String? talhaoNome;
  final VoidCallback? onTap;
  final bool showDetails;

  const InfestationSummaryCard({
    Key? key,
    this.talhaoId,
    this.talhaoNome,
    this.onTap,
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<InfestationSummaryCard> createState() => _InfestationSummaryCardState();
}

class _InfestationSummaryCardState extends State<InfestationSummaryCard> {
  final UnifiedMonitoringRepository _repository = UnifiedMonitoringRepository();
  
  Map<String, dynamic> _stats = {};
  List<InfestationAlert> _activeAlerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(InfestationSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.talhaoId != widget.talhaoId) {
      _loadData();
    }
  }

  /// Carrega dados de infestação
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _repository.initialize();

      // Carregar estatísticas
      final stats = await _repository.getDashboardStats(
        talhaoId: widget.talhaoId,
      );

      // Carregar alertas ativos
      final alerts = await _repository.getActiveAlerts(
        talhaoId: widget.talhaoId,
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _activeAlerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('❌ [INFESTATION_CARD] Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FortSmartCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (_isLoading) _buildLoadingState(),
          if (_error != null) _buildErrorState(),
          if (!_isLoading && _error == null) _buildContent(),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho do card
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A4F3D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.bug_report,
            color: Color(0xFF2A4F3D),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.talhaoNome ?? 'Infestação Geral',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A4F3D),
                ),
              ),
              Text(
                'Monitoramento de Pragas e Doenças',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (widget.onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
      ],
    );
  }

  /// Constrói estado de carregamento
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A4F3D)),
        ),
      ),
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Erro ao carregar dados',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadData,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo principal
  Widget _buildContent() {
    final totalOccurrences = _stats['total_occurrences'] as int? ?? 0;
    final avgInfestation = _stats['avg_infestation'] as double? ?? 0.0;
    final criticalAlerts = _stats['critical_alerts'] as int? ?? 0;
    final highAlerts = _stats['high_alerts'] as int? ?? 0;
    final pendingSync = _stats['pending_sync'] as int? ?? 0;

    return Column(
      children: [
        // Métricas principais
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                'Total de Ocorrências',
                totalOccurrences.toString(),
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                'Infestação Média',
                '${avgInfestation.toStringAsFixed(1)}%',
                Icons.trending_up,
                _getInfestationColor(avgInfestation),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Alertas
        if (criticalAlerts > 0 || highAlerts > 0) ...[
          _buildAlertsSection(criticalAlerts, highAlerts),
          const SizedBox(height: 12),
        ],
        
        // Status de sincronização
        if (pendingSync > 0) _buildSyncStatus(pendingSync),
        
        // Detalhes expandidos
        if (widget.showDetails) ...[
          const Divider(),
          _buildDetailsSection(),
        ],
      ],
    );
  }

  /// Constrói item de métrica
  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói seção de alertas
  Widget _buildAlertsSection(int criticalAlerts, int highAlerts) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertas Ativos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                if (criticalAlerts > 0)
                  Text(
                    '$criticalAlerts crítico${criticalAlerts > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                if (highAlerts > 0)
                  Text(
                    '$highAlerts alto${highAlerts > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói status de sincronização
  Widget _buildSyncStatus(int pendingSync) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$pendingSync registro${pendingSync > 1 ? 's' : ''} pendente${pendingSync > 1 ? 's' : ''} de sincronização',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói seção de detalhes
  Widget _buildDetailsSection() {
    final moderateAlerts = _stats['moderate_alerts'] as int? ?? 0;
    final lowAlerts = _stats['low_alerts'] as int? ?? 0;
    final integratedOccurrences = _stats['integrated_occurrences'] as int? ?? 0;

    return Column(
      children: [
        _buildDetailRow('Alertas Moderados', moderateAlerts.toString(), Colors.yellow),
        _buildDetailRow('Alertas Baixos', lowAlerts.toString(), Colors.green),
        _buildDetailRow('Ocorrências Integradas', integratedOccurrences.toString(), Colors.blue),
      ],
    );
  }

  /// Constrói linha de detalhe
  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém cor baseada no nível de infestação
  Color _getInfestationColor(double infestation) {
    if (infestation >= 75) return Colors.red;
    if (infestation >= 50) return Colors.orange;
    if (infestation >= 25) return Colors.yellow;
    return Colors.green;
  }
}
