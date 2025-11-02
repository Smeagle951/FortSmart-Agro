import 'package:flutter/material.dart';
import '../services/dashboard_data_service.dart';
import '../utils/logger.dart';

/// Widget para card de monitoramento com dados em tempo real
class MonitoringCardWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const MonitoringCardWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<MonitoringCardWidget> createState() => _MonitoringCardWidgetState();
}

class _MonitoringCardWidgetState extends State<MonitoringCardWidget> {
  final DashboardDataService _dashboardDataService = DashboardDataService();
  
  Map<String, dynamic> _monitoringData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMonitoringData();
  }

  Future<void> _loadMonitoringData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Logger.info('🔍 Carregando dados de monitoramento para o card...');
      
      final data = await _dashboardDataService.loadMonitoringData();
      
      if (mounted) {
        setState(() {
          _monitoringData = data;
          _isLoading = false;
        });
      }
      
      Logger.info('✅ Dados de monitoramento carregados: ${data['total']} monitoramentos');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de monitoramento: $e');
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bug_report,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoramento',
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
                            'Sistema: Funcionando normalmente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _error == null)
                    IconButton(
                      onPressed: _loadMonitoringData,
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
                          onPressed: _loadMonitoringData,
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
                _buildMonitoringContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoringContent() {
    final pendentes = _monitoringData['pendentes'] ?? 0;
    final realizados = _monitoringData['realizados'] ?? 0;
    final total = _monitoringData['total'] ?? 0;
    final ultimo = _monitoringData['ultimo'];
    
    return Column(
      children: [
        // Status principal
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Pendentes',
                '$pendentes',
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Realizados',
                '$realizados',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Informações adicionais
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$total',
                Icons.analytics,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Último',
                ultimo != null ? (ultimo['talhao_nome'] ?? 'N/A') : 'Nenhum',
                Icons.schedule,
                Colors.purple,
              ),
            ),
          ],
        ),
        
        // Alerta se há monitoramentos pendentes
        if (pendentes > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pendentes monitoramentos pendentes',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
}
