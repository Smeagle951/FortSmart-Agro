import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/diagnosis_feedback_service.dart';
import '../../models/diagnosis_feedback.dart';
import '../../utils/logger.dart';

/// Dashboard de Aprendizado do Sistema
/// Mostra estatísticas de acurácia e feedback dos usuários
/// Funciona 100% OFFLINE com sincronização futura via API
class LearningDashboardScreen extends StatefulWidget {
  final String farmId;
  final String farmName;

  const LearningDashboardScreen({
    Key? key,
    required this.farmId,
    required this.farmName,
  }) : super(key: key);

  @override
  State<LearningDashboardScreen> createState() => _LearningDashboardScreenState();
}

class _LearningDashboardScreenState extends State<LearningDashboardScreen> with SingleTickerProviderStateMixin {
  final DiagnosisFeedbackService _feedbackService = DiagnosisFeedbackService();
  
  late TabController _tabController;
  
  Map<String, dynamic>? _overallStats;
  List<DiagnosisFeedback>? _recentFeedbacks;
  List<DiagnosisFeedback>? _pendingFollowUps;
  int _pendingSyncCount = 0;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('📊 Carregando dashboard de aprendizado...');

      // Carregar dados em paralelo (OFFLINE)
      final results = await Future.wait([
        _feedbackService.getAccuracyStats(widget.farmId),
        _feedbackService.getFeedbacksByFarm(widget.farmId),
        _feedbackService.getPendingFollowUps(),
      ]);

      if (!mounted) return;

      setState(() {
        _overallStats = results[0] as Map<String, dynamic>;
        
        final allFeedbacks = results[1] as List<DiagnosisFeedback>;
        _recentFeedbacks = allFeedbacks.take(10).toList();
        
        _pendingFollowUps = results[2] as List<DiagnosisFeedback>;
        
        // Contar feedbacks pendentes de sincronização
        _pendingSyncCount = allFeedbacks.where((f) => !f.syncedToCloud).length;
        
        _isLoading = false;
      });

      Logger.info('✅ Dashboard carregado com sucesso');
      Logger.info('   Total de diagnósticos: ${_overallStats!['totalDiagnoses']}');
      Logger.info('   Acurácia: ${_overallStats!['overallAccuracy'].toStringAsFixed(1)}%');
      Logger.info('   Pendentes de sincronização: $_pendingSyncCount');

    } catch (e) {
      Logger.error('❌ Erro ao carregar dashboard: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    }
  }

  Future<void> _syncFeedbacks() async {
    setState(() => _isSyncing = true);

    try {
      Logger.info('🔄 Iniciando sincronização de feedbacks...');

      final syncedCount = await _feedbackService.syncPendingFeedbacks(limit: 50);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ $syncedCount feedbacks sincronizados com sucesso!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Recarregar dados
      await _loadDashboardData();

    } catch (e) {
      Logger.error('❌ Erro ao sincronizar: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao sincronizar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aprendizado do Sistema'),
            Text(
              widget.farmName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
            Tab(icon: Icon(Icons.follow_the_signs), text: 'Follow-ups'),
          ],
        ),
        actions: [
          // Indicador de sincronização
          if (_pendingSyncCount > 0)
            IconButton(
              onPressed: _isSyncing ? null : _syncFeedbacks,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Badge(
                      label: Text('$_pendingSyncCount'),
                      child: const Icon(Icons.cloud_upload),
                    ),
              tooltip: 'Sincronizar com Servidor',
            ),
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatisticsTab(),
                    _buildHistoryTab(),
                    _buildFollowUpsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  // ========== ABA 1: ESTATÍSTICAS ==========

  Widget _buildStatisticsTab() {
    if (_overallStats == null) {
      return const Center(child: Text('Nenhum dado disponível'));
    }

    final totalDiagnoses = (_overallStats!['totalDiagnoses'] as num?)?.toInt() ?? 0;
    final totalConfirmed = (_overallStats!['totalConfirmed'] as num?)?.toInt() ?? 0;
    final totalCorrected = (_overallStats!['totalCorrected'] as num?)?.toInt() ?? 0;
    final overallAccuracy = (_overallStats!['overallAccuracy'] as num?)?.toDouble() ?? 0.0;
    final byCrop = _overallStats!['byCrop'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal de acurácia
            _buildAccuracyCard(overallAccuracy, totalDiagnoses),

            const SizedBox(height: 16),

            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Confirmados',
                    '$totalConfirmed',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Corrigidos',
                    '$totalCorrected',
                    Icons.edit,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pendentes Sync',
                    '$_pendingSyncCount',
                    Icons.cloud_upload,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Follow-ups',
                    '${_pendingFollowUps?.length ?? 0}',
                    Icons.follow_the_signs,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Acurácia por cultura
            Text(
              'Acurácia por Cultura',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            if (byCrop.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum feedback registrado ainda.'),
                ),
              )
            else
              ...byCrop.map((crop) => _buildCropAccuracyCard(crop)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard(double accuracy, int total) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acurácia Geral do Sistema',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${accuracy.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Baseado em $total diagnósticos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: accuracy / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropAccuracyCard(Map<String, dynamic> crop) {
    final cropName = crop['crop_name'] as String? ?? 'Cultura';
    final total = (crop['total'] as num?)?.toInt() ?? 0;
    final confirmed = (crop['confirmed'] as num?)?.toInt() ?? 0;
    final accuracy = (crop['accuracy_rate'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAccuracyColor(accuracy).withOpacity(0.2),
          child: Text(
            cropName[0].toUpperCase(),
            style: TextStyle(
              color: _getAccuracyColor(accuracy),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cropName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$confirmed de $total diagnósticos confirmados'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getAccuracyColor(accuracy),
              ),
            ),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: accuracy / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getAccuracyColor(accuracy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.green;
    if (accuracy >= 75) return Colors.lightGreen;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  // ========== ABA 2: HISTÓRICO ==========

  Widget _buildHistoryTab() {
    if (_recentFeedbacks == null || _recentFeedbacks!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhum feedback registrado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Os feedbacks aparecerão aqui',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentFeedbacks!.length,
        itemBuilder: (context, index) {
          final feedback = _recentFeedbacks![index];
          return _buildFeedbackCard(feedback);
        },
      ),
    );
  }

  Widget _buildFeedbackCard(DiagnosisFeedback feedback) {
    final isConfirmed = feedback.userConfirmed;
    final color = isConfirmed ? Colors.green : Colors.orange;
    final icon = isConfirmed ? Icons.check_circle : Icons.edit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          feedback.cropName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback.systemPredictedOrganism),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(feedback.feedbackDate),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!feedback.syncedToCloud)
              Icon(Icons.cloud_off, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Icon(
              isConfirmed ? Icons.thumb_up : Icons.thumb_down,
              color: color,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeedbackDetailRow(
                  'Sistema previu:',
                  feedback.systemPredictedOrganism,
                ),
                _buildFeedbackDetailRow(
                  'Severidade sistema:',
                  '${feedback.systemPredictedSeverity.toStringAsFixed(1)}% (${feedback.systemSeverityLevel})',
                ),
                if (!isConfirmed) ...[
                  const Divider(),
                  _buildFeedbackDetailRow(
                    'Usuário corrigiu:',
                    feedback.userCorrectedOrganism ?? 'N/A',
                    color: Colors.orange,
                  ),
                  if (feedback.userCorrectedSeverity != null)
                    _buildFeedbackDetailRow(
                      'Severidade real:',
                      '${feedback.userCorrectedSeverity!.toStringAsFixed(1)}% (${feedback.userCorrectedSeverityLevel})',
                      color: Colors.orange,
                    ),
                  if (feedback.userCorrectionReason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Motivo: ${feedback.userCorrectionReason}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
                if (feedback.userNotes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Obs: ${feedback.userNotes}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      feedback.technicianName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (feedback.syncedToCloud)
                      Chip(
                        label: const Text('Sincronizado'),
                        avatar: const Icon(Icons.cloud_done, size: 16),
                        labelStyle: const TextStyle(fontSize: 11),
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      Chip(
                        label: const Text('Offline'),
                        avatar: const Icon(Icons.cloud_off, size: 16),
                        labelStyle: const TextStyle(fontSize: 11),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.orange.shade100,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ABA 3: FOLLOW-UPS ==========

  Widget _buildFollowUpsTab() {
    if (_pendingFollowUps == null || _pendingFollowUps!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhum follow-up pendente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Todos os feedbacks foram acompanhados!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingFollowUps!.length,
        itemBuilder: (context, index) {
          final feedback = _pendingFollowUps![index];
          return _buildFollowUpCard(feedback);
        },
      ),
    );
  }

  Widget _buildFollowUpCard(DiagnosisFeedback feedback) {
    final daysSince = DateTime.now().difference(feedback.feedbackDate).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.2),
          child: const Icon(Icons.follow_the_signs, color: Colors.purple),
        ),
        title: Text(
          '${feedback.cropName} - ${feedback.userCorrectedOrganism ?? feedback.systemPredictedOrganism}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feedback há $daysSince dias'),
            Text(
              DateFormat('dd/MM/yyyy').format(feedback.feedbackDate),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _showFollowUpDialog(feedback),
          child: const Text('Registrar'),
        ),
      ),
    );
  }

  Future<void> _showFollowUpDialog(DiagnosisFeedback feedback) async {
    final outcomeController = TextEditingController();
    final notesController = TextEditingController();
    double treatmentEfficacy = 50.0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Follow-up'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organismo: ${feedback.userCorrectedOrganism ?? feedback.systemPredictedOrganism}'),
                const SizedBox(height: 16),
                TextField(
                  controller: outcomeController,
                  decoration: const InputDecoration(
                    labelText: 'Resultado do tratamento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Eficácia do tratamento: ${treatmentEfficacy.toStringAsFixed(0)}%'),
                Slider(
                  value: treatmentEfficacy,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${treatmentEfficacy.toStringAsFixed(0)}%',
                  onChanged: (value) => setState(() => treatmentEfficacy = value),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final success = await _feedbackService.updateOutcome(
        feedbackId: feedback.id,
        outcome: outcomeController.text,
        treatmentEfficacy: treatmentEfficacy,
        notes: notesController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Follow-up registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadDashboardData();
      }
    }
  }
}

