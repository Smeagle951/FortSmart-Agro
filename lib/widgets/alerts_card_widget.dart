import 'package:flutter/material.dart';
import '../services/dashboard_data_service.dart';
import '../utils/logger.dart';

/// Widget para card de alertas com dados em tempo real
class AlertsCardWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const AlertsCardWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<AlertsCardWidget> createState() => _AlertsCardWidgetState();
}

class _AlertsCardWidgetState extends State<AlertsCardWidget> {
  final DashboardDataService _dashboardDataService = DashboardDataService();
  
  Map<String, dynamic> _alertsData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlertsData();
  }

  Future<void> _loadAlertsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Logger.info('🔍 Carregando dados de alertas para o card...');
      
      final data = await _dashboardDataService.loadInfestationAlerts();
      
      if (mounted) {
        setState(() {
          _alertsData = data;
          _isLoading = false;
        });
      }
      
      Logger.info('✅ Dados de alertas carregados: ${data['total_count']} alertas');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de alertas: $e');
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alertas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (_isLoading)
                          const Text(
                            'Carregando...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                        else if (_error != null)
                          Text(
                            'Erro ao carregar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          )
                        else
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _error == null)
                    IconButton(
                      onPressed: _loadAlertsData,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      tooltip: 'Atualizar dados',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erro ao carregar dados',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadAlertsData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildAlertsContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsContent() {
    final totalCount = _alertsData['total_count'] ?? 0;
    final highSeverity = _alertsData['high_severity'] ?? 0;
    final criticalSeverity = _alertsData['critical_severity'] ?? 0;
    final alerts = _alertsData['alerts'] as List<dynamic>? ?? [];
    
    if (totalCount == 0) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhum alerta ativo',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema funcionando normalmente',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
    
    return Column(
      children: [
        // Contadores principais
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$totalCount',
                Icons.warning,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Alto Risco',
                '$highSeverity',
                Icons.priority_high,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Severidade crítica
        if (criticalSeverity > 0) ...[
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Crítico',
                  '$criticalSeverity',
                  Icons.dangerous,
                  Colors.red.shade800,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Status',
                  'Atenção',
                  Icons.info,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // Lista de alertas recentes (máximo 3)
        if (alerts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas Recentes',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...alerts.take(3).map((alert) => _buildAlertItem(alert)).toList(),
                if (alerts.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '... e mais ${alerts.length - 3} alertas',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final talhaoNome = alert['talhao_nome'] ?? 'Talhão ${alert['talhao_id']}';
    final tipo = alert['tipo'] ?? 'N/A';
    final percentual = alert['percentual'] ?? 0;
    final nivel = alert['nivel'] ?? 'N/A';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getSeverityColor(percentual),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$talhaoNome - $tipo ($percentual%)',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    final totalCount = _alertsData['total_count'] ?? 0;
    if (totalCount == 0) {
      return 'Nenhum ativo';
    } else if (totalCount == 1) {
      return '1 alerta ativo';
    } else {
      return '$totalCount alertas ativos';
    }
  }

  Color _getStatusColor() {
    final totalCount = _alertsData['total_count'] ?? 0;
    if (totalCount == 0) {
      return Colors.green.shade600;
    } else if (totalCount <= 3) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  Color _getSeverityColor(int percentual) {
    if (percentual >= 90) return Colors.red.shade800;
    if (percentual >= 75) return Colors.red.shade600;
    if (percentual >= 50) return Colors.orange.shade600;
    if (percentual >= 25) return Colors.yellow.shade600;
    return Colors.green.shade600;
  }
}
