import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/infestation_alert.dart';
import '../services/alert_service.dart';
import '../../../utils/logger.dart';
import '../../../widgets/diagnosis_confirmation_dialog.dart';
import '../../../services/diagnosis_feedback_service.dart';

/// Painel para exibição e gerenciamento de alertas de infestação
class AlertsPanel extends StatefulWidget {
  final AlertService alertService;
  final Function(LatLng)? onAlertLocationTap;
  final Function(InfestationAlert)? onAlertTap;

  const AlertsPanel({
    super.key,
    required this.alertService,
    this.onAlertLocationTap,
    this.onAlertTap,
  });

  @override
  State<AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends State<AlertsPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;

  
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de Alertas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                StreamBuilder<List<InfestationAlert>>(
                  stream: widget.alertService.alertStream,
                  builder: (context, snapshot) {
                    final activeCount = widget.alertService.getActiveAlerts().length;
                    return Text(
                      '$activeCount alerta${activeCount != 1 ? 's' : ''} ativo${activeCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showAlertStatistics,
            icon: Icon(
              Icons.analytics_outlined,
              color: Colors.red.shade600,
            ),
            tooltip: 'Estatísticas dos Alertas',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.red.shade700,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.red.shade700,
        tabs: const [
          Tab(
            icon: Icon(Icons.warning),
            text: 'Ativos',
          ),
          Tab(
            icon: Icon(Icons.check_circle_outline),
            text: 'Reconhecidos',
          ),
          Tab(
            icon: Icon(Icons.done_all),
            text: 'Resolvidos',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAlertsList(widget.alertService.getActiveAlerts(), 'active'),
        _buildAlertsList(widget.alertService.getAcknowledgedAlerts(), 'acknowledged'),
        _buildAlertsList(widget.alertService.getResolvedAlerts(), 'resolved'),
      ],
    );
  }

  Widget _buildAlertsList(List<InfestationAlert> alerts, String status) {
    if (alerts.isEmpty) {
      return _buildEmptyState(status);
    }

    // Filtrar por busca
    final filteredAlerts = alerts.where((alert) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return alert.message.toLowerCase().contains(query) ||
             alert.talhaoId.toLowerCase().contains(query) ||
             alert.organismoId.toLowerCase().contains(query) ||
             alert.level.toLowerCase().contains(query);
    }).toList();

    if (filteredAlerts.isEmpty) {
      return _buildEmptySearchState();
    }

    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredAlerts.length,
            itemBuilder: (context, index) {
              return _buildAlertCard(filteredAlerts[index], status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'active':
        message = 'Nenhum alerta ativo';
        icon = Icons.check_circle;
        break;
      case 'acknowledged':
        message = 'Nenhum alerta reconhecido';
        icon = Icons.pending;
        break;
      case 'resolved':
        message = 'Nenhum alerta resolvido';
        icon = Icons.history;
        break;
      default:
        message = 'Nenhum alerta encontrado';
        icon = Icons.info;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum alerta encontrado para "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar alertas...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          _buildFilterChip('all', 'Todos'),
          _buildFilterChip('critical', 'Críticos'),
          _buildFilterChip('high', 'Altos'),
          _buildFilterChip('medium', 'Médios'),
          _buildFilterChip('low', 'Baixos'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      selectedColor: Colors.red.shade100,
      checkmarkColor: Colors.red.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAlertCard(InfestationAlert alert, String status) {
    final riskColor = _getRiskColor(alert.riskLevel);
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => widget.onAlertTap?.call(alert),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor),
                    ),
                    child: Text(
                      alert.riskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Score: ${alert.priorityScore.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alert.message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Talhão: ${alert.talhaoId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (widget.onAlertLocationTap != null)
                    IconButton(
                      onPressed: () {
                        // TODO: Implementar busca de coordenadas do talhão
                        Logger.info('Localizar talhão: ${alert.talhaoId}');
                      },
                      icon: Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      tooltip: 'Localizar no mapa',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Organismo: ${alert.organismoId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(alert.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (status == 'active') ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _acknowledgeAlert(alert),
                      child: const Text('Reconhecer'),
                    ),
                  ] else if (status == 'acknowledged') ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _resolveAlert(alert),
                      child: const Text('Resolver'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'crítico':
        return Colors.red.shade700;
      case 'alto':
        return Colors.orange.shade700;
      case 'médio':
        return Colors.yellow.shade700;
      case 'baixo':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.red.shade600;
      case 'acknowledged':
        return Colors.orange.shade600;
      case 'resolved':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'ATIVO';
      case 'acknowledged':
        return 'RECONHECIDO';
      case 'resolved':
        return 'RESOLVIDO';
      default:
        return 'DESCONHECIDO';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

  Future<void> _acknowledgeAlert(InfestationAlert alert) async {
    if (!mounted) return;
    
    try {
      final success = await widget.alertService.acknowledgeAlert(
        alert.id,
        'Usuário Atual', // TODO: Implementar sistema de usuários
        null,
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerta ${alert.id} reconhecido com sucesso'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
        
        // NOVO: Solicitar feedback do usuário sobre o alerta
        await _requestAlertFeedback(alert);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao reconhecer alerta'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Logger.error('Erro ao reconhecer alerta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _resolveAlert(InfestationAlert alert) async {
    if (!mounted) return;
    
    try {
      final success = await widget.alertService.resolveAlert(
        alert.id,
        'Usuário Atual', // TODO: Implementar sistema de usuários
        null,
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerta ${alert.id} resolvido com sucesso'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao resolver alerta'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Logger.error('Erro ao resolver alerta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showAlertStatistics() {
    final stats = widget.alertService.getAlertStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas dos Alertas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total de Alertas', '${stats['totalAlerts']}'),
            _buildStatRow('Alertas Ativos', '${stats['activeCount']}'),
            _buildStatRow('Alertas Reconhecidos', '${stats['acknowledgedCount']}'),
            _buildStatRow('Alertas Resolvidos', '${stats['resolvedCount']}'),
            _buildStatRow('Taxa de Resolução', '${stats['resolutionRate'].toStringAsFixed(1)}%'),
            if (stats['avgResolutionTimeHours'] > 0)
              _buildStatRow('Tempo Médio de Resolução', 
                  '${stats['avgResolutionTimeHours'].toStringAsFixed(1)}h'),
            const SizedBox(height: 16),
            const Text(
              'Distribuição por Nível de Risco:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(stats['riskLevelCounts'] as Map<String, int>).entries.map(
              (entry) => _buildStatRow(
                '${entry.key.toUpperCase()}:',
                '${entry.value}',
                isSubItem: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isSubItem = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSubItem ? 16.0 : 0.0,
        bottom: 4.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSubItem ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// NOVO: Solicita feedback do usuário sobre o alerta
  /// Integração com sistema de aprendizado contínuo
  Future<void> _requestAlertFeedback(InfestationAlert alert) async {
    if (!mounted) return;

    try {
      // Obter dados do metadata do alerta
      final cropName = alert.metadata['crop_name'] as String? ?? 'Cultura não especificada';
      final organismName = alert.metadata['organism_name'] as String? ?? alert.organismoId;
      final infestationPercentage = (alert.metadata['infestation_percentage'] as num?)?.toDouble() ?? 50.0;
      final severityLevel = alert.level; // usar level do alerta
      final latitude = (alert.metadata['latitude'] as num?)?.toDouble();
      final longitude = (alert.metadata['longitude'] as num?)?.toDouble();
      
      // Obter estatísticas de acurácia para ajustar confiança
      final feedbackService = DiagnosisFeedbackService();
      final stats = await feedbackService.getCropStats(
        alert.talhaoId, // farmId (usando talhaoId)
        cropName,
      );

      // Calcular confiança baseada em histórico
      double systemConfidence = 0.75; // Confiança padrão
      if (stats.containsKey('accuracy') && !stats.containsKey('noData')) {
        final accuracy = double.tryParse(stats['accuracy'] as String? ?? '75') ?? 75;
        systemConfidence = accuracy / 100;
      }

      // Aguardar um momento para não sobrepor com o snackbar
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Mostrar dialog de confirmação
      final feedbackGiven = await showDialog<bool>(
        context: context,
        builder: (context) => DiagnosisConfirmationDialog(
          farmId: alert.talhaoId, // TODO: Usar farmId real
          cropName: cropName,
          systemPredictedOrganism: organismName,
          systemPredictedSeverity: infestationPercentage,
          systemSeverityLevel: severityLevel,
          systemSymptoms: [alert.description],
          systemConfidence: systemConfidence,
          technicianName: alert.acknowledgedBy ?? 'Usuário Atual',
          alertId: alert.id,
          latitude: latitude,
          longitude: longitude,
          onFeedbackSaved: () {
            Logger.info('✅ Feedback salvo para alerta: ${alert.id}');
          },
        ),
      );

      if (feedbackGiven == true && mounted) {
        // Feedback foi salvo com sucesso
        Logger.info('🎓 Sistema aprendeu com feedback do alerta ${alert.id}');
        
        // Recarregar dados se necessário
        setState(() {
          // Atualizar UI
        });
      }
    } catch (e) {
      Logger.error('❌ Erro ao solicitar feedback do alerta: $e');
    }
  }
}
