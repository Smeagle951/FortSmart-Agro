import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/report_scheduler_service.dart';
import '../../services/consolidated_report_service.dart';
import '../../utils/app_theme.dart';
import 'schedule_form_screen.dart';

/// Tela para gerenciar agendamentos de relatórios
class ScheduleManagerScreen extends StatefulWidget {
  static const String routeName = '/reports/schedule-manager';

  const ScheduleManagerScreen({Key? key}) : super(key: key);

  @override
  _ScheduleManagerScreenState createState() => _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends State<ScheduleManagerScreen> {
  final ReportSchedulerService _schedulerService = ReportSchedulerService();
  final ConsolidatedReportService _reportService = ConsolidatedReportService();
  
  List<ReportSchedule> _schedules = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ScheduleStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    
    try {
      final schedules = _schedulerService.getSchedules();
      setState(() => _schedules = schedules);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos de Relatórios'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewSchedule,
            tooltip: 'Novo Agendamento',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                _buildStats(),
                Expanded(child: _buildSchedulesList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColorLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Agendamentos Automáticos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_schedules.length} agendamento(s) configurado(s)',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar agendamentos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<ScheduleStatus?>(
                value: _filterStatus,
                hint: const Text('Status'),
                items: [
                  const DropdownMenuItem<ScheduleStatus?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...ScheduleStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusText(status)),
                  )),
                ],
                onChanged: (value) => setState(() => _filterStatus = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = _schedulerService.getStatistics();
    final filteredSchedules = _getFilteredSchedules();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('Total', stats['total'].toString(), Icons.schedule),
          const SizedBox(width: 8),
          _buildStatCard('Ativos', stats['active'].toString(), Icons.play_circle),
          const SizedBox(width: 8),
          _buildStatCard('Pausados', stats['paused'].toString(), Icons.pause_circle),
          const SizedBox(width: 8),
          _buildStatCard('Execuções', stats['totalRuns'].toString(), Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulesList() {
    final filteredSchedules = _getFilteredSchedules();
    
    if (filteredSchedules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum agendamento encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Crie agendamentos para relatórios automáticos',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
        final schedule = filteredSchedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(ReportSchedule schedule) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getStatusIcon(schedule.status),
        title: Text(
          schedule.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schedule.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInfoChip('Frequência', _getFrequencyText(schedule.frequency)),
                const SizedBox(width: 8),
                _buildInfoChip('Status', _getStatusText(schedule.status)),
              ],
            ),
            if (schedule.nextRun != null) ...[
              const SizedBox(height: 4),
              Text(
                'Próxima execução: ${DateFormat('dd/MM/yyyy HH:mm').format(schedule.nextRun!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (schedule.lastRun != null) ...[
              Text(
                'Última execução: ${DateFormat('dd/MM/yyyy HH:mm').format(schedule.lastRun!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            Text(
              'Execuções: ${schedule.runCount}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleScheduleAction(action, schedule),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(schedule.status == ScheduleStatus.active ? Icons.pause : Icons.play_arrow),
                title: Text(schedule.status == ScheduleStatus.active ? 'Pausar' : 'Reativar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'execute',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Executar Agora'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showScheduleDetails(schedule),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Icon _getStatusIcon(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.active:
        return const Icon(Icons.play_circle, color: Colors.green);
      case ScheduleStatus.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange);
      case ScheduleStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.blue);
      case ScheduleStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  String _getStatusText(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.active:
        return 'Ativo';
      case ScheduleStatus.paused:
        return 'Pausado';
      case ScheduleStatus.completed:
        return 'Concluído';
      case ScheduleStatus.failed:
        return 'Falhou';
    }
  }

  String _getFrequencyText(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.daily:
        return 'Diário';
      case ScheduleFrequency.weekly:
        return 'Semanal';
      case ScheduleFrequency.monthly:
        return 'Mensal';
      case ScheduleFrequency.quarterly:
        return 'Trimestral';
      case ScheduleFrequency.yearly:
        return 'Anual';
    }
  }

  List<ReportSchedule> _getFilteredSchedules() {
    var filtered = _schedules;
    
    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        return schedule.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               schedule.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filtro por status
    if (_filterStatus != null) {
      filtered = filtered.where((schedule) => schedule.status == _filterStatus).toList();
    }
    
    return filtered;
  }

  Future<void> _handleScheduleAction(String action, ReportSchedule schedule) async {
    switch (action) {
      case 'toggle':
        await _schedulerService.toggleScheduleStatus(schedule.id);
        _loadSchedules();
        break;
        
      case 'execute':
        await _executeScheduleNow(schedule);
        break;
        
      case 'edit':
        _editSchedule(schedule);
        break;
        
      case 'delete':
        _confirmDelete(schedule);
        break;
    }
  }

  Future<void> _executeScheduleNow(ReportSchedule schedule) async {
    try {
      await _schedulerService.executeScheduleNow(schedule.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agendamento "${schedule.name}" executado com sucesso')),
      );
      _loadSchedules();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao executar agendamento: $e')),
      );
    }
  }

  void _editSchedule(ReportSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormScreen(schedule: schedule),
      ),
    ).then((_) => _loadSchedules());
  }

  void _confirmDelete(ReportSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o agendamento "${schedule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule(schedule);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(ReportSchedule schedule) async {
    try {
      await _schedulerService.removeSchedule(schedule.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento excluído com sucesso')),
      );
      _loadSchedules();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir agendamento: $e')),
      );
    }
  }

  void _addNewSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduleFormScreen(),
      ),
    ).then((_) => _loadSchedules());
  }

  void _showScheduleDetails(ReportSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Descrição: ${schedule.description}'),
              const SizedBox(height: 8),
              Text('Fazenda: ${schedule.reportConfig.farm}'),
              Text('Safra: ${schedule.reportConfig.season}'),
              Text('Frequência: ${_getFrequencyText(schedule.frequency)}'),
              Text('Status: ${_getStatusText(schedule.status)}'),
              if (schedule.nextRun != null)
                Text('Próxima execução: ${DateFormat('dd/MM/yyyy HH:mm').format(schedule.nextRun!)}'),
              if (schedule.lastRun != null)
                Text('Última execução: ${DateFormat('dd/MM/yyyy HH:mm').format(schedule.lastRun!)}'),
              Text('Execuções: ${schedule.runCount}'),
              if (schedule.lastError != null) ...[
                const SizedBox(height: 8),
                Text('Último erro: ${schedule.lastError}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
