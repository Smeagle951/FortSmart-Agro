import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../database/models/monitoring_model.dart';
import '../../database/models/monitoring_point_model.dart';
import '../../database/models/occurrence_model.dart';
import '../../utils/logger.dart';
import '../../services/monitoring_resume_service.dart';
import '../../services/monitoring_integration_service.dart';
import 'monitoring_point_screen.dart';
import 'monitoring_details_screen.dart';
import 'new_monitoring_screen.dart';
import '../../widgets/custom_alert_dialog.dart';

/// Tela de sessões de monitoramento - corresponde às imagens fornecidas
/// Mostra lista de sessões com botões funcionais: CONTINUAR, VER DETALHES, EDITAR, DELETAR, NOVO MONITORAMENTO
class MonitoringSessionsScreen extends StatefulWidget {
  const MonitoringSessionsScreen({Key? key}) : super(key: key);

  @override
  State<MonitoringSessionsScreen> createState() => _MonitoringSessionsScreenState();
}

class _MonitoringSessionsScreenState extends State<MonitoringSessionsScreen> {
  late AppDatabase _appDatabase;
  List<MonitoringModel> _monitorings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMonitorings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appDatabase = Provider.of<AppDatabase>(context);
  }

  Future<void> _loadMonitorings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Logger.info('📚 Carregando sessões de monitoramento...');
      final monitorings = await _appDatabase.monitoringDao.findAllMonitorings();
      
      Logger.info('📊 Sessões carregadas: ${monitorings.length} registros');
      
      setState(() {
        _monitorings = monitorings;
        _isLoading = false;
      });
      
      Logger.info('✅ Sessões carregadas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao carregar sessões: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// NOVO MONITORAMENTO - Funcionalidade implementada
  void _startNewMonitoring() {
    try {
      Logger.info('🆕 Iniciando novo monitoramento...');
      
      Navigator.of(context).pushNamed(AppRoutes.advancedMonitoring);
      
      Logger.info('✅ Navegação para monitoramento avançado realizada');
    } catch (e) {
      Logger.error('❌ Erro ao iniciar monitoramento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar monitoramento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// CONTINUAR - Funcionalidade implementada
  Future<void> _continueMonitoring(MonitoringModel monitoring) async {
    Logger.info('▶️ Continuando monitoramento: ${monitoring.id}');
    
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Carregando monitoramento...'),
            ],
          ),
        ),
      );

      final nextPointData = await MonitoringResumeService().resumeMonitoring(monitoring.id);

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      if (nextPointData != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MonitoringPointScreen(
              point: nextPointData['point'],
              monitoringId: monitoring.id,
              fieldId: monitoring.farmId,
              cropName: monitoring.cropName,
              onNavigateToNextPoint: () {
                Navigator.of(context).pop(); // Fechar tela de ponto
                _loadMonitorings(); // Recarregar lista
              },
            ),
          ),
        ).then((_) => _loadMonitorings()); // Recarregar ao retornar
      } else {
        _showMessage('Não há pontos para continuar ou monitoramento já finalizado.', isError: false);
        _loadMonitorings(); // Recarregar em caso de mudança de status
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) Navigator.of(context).pop();
      
      Logger.error('❌ Erro ao continuar monitoramento: $e');
      _showMessage('Erro ao continuar monitoramento: $e', isError: true);
    }
  }

  /// VER DETALHES - Funcionalidade implementada
  void _viewMonitoringDetails(MonitoringModel monitoring) {
    Logger.info('👁️ Visualizando detalhes do monitoramento: ${monitoring.id}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MonitoringDetailsScreen(monitoringId: monitoring.id),
      ),
    ).then((_) => _loadMonitorings()); // Recarregar ao retornar
  }

  /// EDITAR - Funcionalidade implementada
  void _editMonitoring(MonitoringModel monitoring) {
    Logger.info('✏️ Editando monitoramento: ${monitoring.id}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewMonitoringScreen(monitoringToEdit: monitoring),
      ),
    ).then((_) => _loadMonitorings()); // Recarregar ao retornar
  }

  /// DUPLICAR SESSÃO - Funcionalidade implementada
  Future<void> _duplicateMonitoring(MonitoringModel monitoring) async {
    Logger.info('📋 Duplicando monitoramento: ${monitoring.id}');
    
    try {
      // Mostrar confirmação
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Duplicar Sessão',
            content: 'Deseja criar uma cópia desta sessão de monitoramento?',
            confirmButtonText: 'Duplicar',
            cancelButtonText: 'Cancelar',
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          );
        },
      );

      if (confirm == true) {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Duplicando sessão...'),
              ],
            ),
          ),
        );

        // Criar cópia da sessão
        final duplicatedMonitoring = MonitoringModel(
          id: _appDatabase.uuid.v4(), // Novo ID
          farmId: monitoring.farmId,
          farmName: monitoring.farmName,
          cropId: monitoring.cropId,
          cropName: monitoring.cropName,
          startDate: DateTime.now(), // Nova data de início
          endDate: null, // Nova sessão não tem fim
          status: 'ativo', // Status ativo para nova sessão
          description: '${monitoring.description ?? ''} (Cópia)'.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncedToCloud: false,
        );

        await _appDatabase.monitoringDao.insertMonitoring(duplicatedMonitoring);

        // Fechar loading
        if (mounted) Navigator.of(context).pop();

        _showMessage('Sessão duplicada com sucesso!', isError: false);
        _loadMonitorings(); // Recarregar lista
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) Navigator.of(context).pop();
      
      Logger.error('❌ Erro ao duplicar monitoramento: $e');
      _showMessage('Erro ao duplicar sessão: $e', isError: true);
    }
  }

  /// COMPARTILHAR - Funcionalidade implementada
  Future<void> _shareMonitoring(MonitoringModel monitoring) async {
    Logger.info('📤 Compartilhando monitoramento: ${monitoring.id}');
    
    try {
      // Gerar dados para compartilhamento
      final shareData = '''
📊 RELATÓRIO DE MONITORAMENTO

🏢 Fazenda: ${monitoring.farmName}
🌱 Cultura: ${monitoring.cropName}
📅 Data de Início: ${monitoring.startDate.toLocal().toString().split(' ')[0]}
📊 Status: ${monitoring.status}
📝 Descrição: ${monitoring.description ?? 'Não informada'}

Gerado pelo FortSmart Agro
${DateTime.now().toLocal().toString().split(' ')[0]}
      '''.trim();

      // Compartilhar usando Share
      await Clipboard.setData(ClipboardData(text: shareData));
      
      _showMessage('Dados copiados para a área de transferência!', isError: false);
    } catch (e) {
      Logger.error('❌ Erro ao compartilhar monitoramento: $e');
      _showMessage('Erro ao compartilhar: $e', isError: true);
    }
  }

  /// EXCLUIR SESSÃO - Funcionalidade implementada
  Future<void> _deleteMonitoring(MonitoringModel monitoring) async {
    Logger.info('🗑️ Excluindo monitoramento: ${monitoring.id}');
    
    try {
      // Mostrar confirmação
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Excluir Sessão',
            content: 'Tem certeza que deseja excluir esta sessão de monitoramento?\n\nEsta ação não pode ser desfeita.',
            confirmButtonText: 'Excluir',
            cancelButtonText: 'Cancelar',
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          );
        },
      );

      if (confirm == true) {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Excluindo sessão...'),
              ],
            ),
          ),
        );

        // Excluir monitoramento e dados relacionados
        await _appDatabase.monitoringDao.deleteMonitoring(monitoring);

        // Fechar loading
        if (mounted) Navigator.of(context).pop();

        _showMessage('Sessão excluída com sucesso!', isError: false);
        _loadMonitorings(); // Recarregar lista
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) Navigator.of(context).pop();
      
      Logger.error('❌ Erro ao excluir monitoramento: $e');
      _showMessage('Erro ao excluir sessão: $e', isError: true);
    }
  }

  /// Mostra mensagem para o usuário
  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Calcula estatísticas de uma sessão
  Future<Map<String, int>> _calculateSessionStats(String monitoringId) async {
    try {
      final points = await _appDatabase.monitoringPointDao.findMonitoringPointsByMonitoringId(monitoringId);
      int totalOccurrences = 0;
      
      for (final point in points) {
        final occurrences = await _appDatabase.occurrenceDao.findOccurrencesByMonitoringPointId(point.id);
        totalOccurrences += occurrences.length;
      }
      
      return {
        'points': points.length,
        'occurrences': totalOccurrences,
        'duration': 0, // TODO: Implementar cálculo de duração
      };
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas: $e');
      return {'points': 0, 'occurrences': 0, 'duration': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Histórico de Monitoramento',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF27AE60),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewMonitoring,
            tooltip: 'Novo Monitoramento',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _loadMonitorings,
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : _monitorings.isEmpty
                  ? _buildEmptyWidget()
                  : _buildSessionsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewMonitoring,
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Monitoramento'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar sessões',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMonitorings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitoring,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma sessão encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Os monitoramentos aparecerão aqui após serem criados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewMonitoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeira Sessão'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return Column(
      children: [
        // Header com contador
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_monitorings.length} sessões encontradas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Lista de sessões
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _monitorings.length,
            itemBuilder: (context, index) {
              final monitoring = _monitorings[index];
              return _buildSessionCard(monitoring);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(MonitoringModel monitoring) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do card
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone de play
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Color(0xFF27AE60),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Informações principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${monitoring.cropName} - ${monitoring.farmName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monitoring.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(monitoring.startDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(monitoring.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(monitoring.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Estatísticas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatItem(Icons.location_on, '0 Pontos', Colors.blue),
                const SizedBox(width: 16),
                _buildStatItem(Icons.bug_report, '0 Ocorrências', Colors.red),
                const SizedBox(width: 16),
                _buildStatItem(Icons.access_time, '0min Duração', Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botões de ação
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Botão CONTINUAR
                if (monitoring.status != 'finalizado')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _continueMonitoring(monitoring),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                
                if (monitoring.status != 'finalizado')
                  const SizedBox(width: 8),
                
                // Botão VER DETALHES
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewMonitoringDetails(monitoring),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver Detalhes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C2C2C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Menu de 3 pontos
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editMonitoring(monitoring);
                        break;
                      case 'duplicate':
                        _duplicateMonitoring(monitoring);
                        break;
                      case 'share':
                        _shareMonitoring(monitoring);
                        break;
                      case 'delete':
                        _deleteMonitoring(monitoring);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text('Editar Sessão'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy, color: Colors.orange),
                        title: Text('Duplicar Sessão'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share, color: Colors.green),
                        title: Text('Compartilhar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Excluir Sessão', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'pausado':
        return Colors.orange;
      case 'finalizado':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
        return 'Em andamento';
      case 'pausado':
        return 'Pausado';
      case 'finalizado':
        return 'Finalizado';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
