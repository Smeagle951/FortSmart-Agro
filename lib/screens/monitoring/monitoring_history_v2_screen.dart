import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/monitoring_session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../routes.dart';
import '../../debug/monitoring_session_diagnostic.dart';
import '../../debug/monitoring_occurrences_diagnostic.dart';
import '../../debug/sql_direct_diagnostic.dart';
import '../../services/direct_occurrence_service.dart';
import '../../debug/force_populate_test_data.dart';
import '../../debug/complete_database_reset.dart';
import '../../database/app_database.dart';
import 'monitoring_details_v2_screen.dart';
import 'monitoring_point_screen.dart';
import 'monitoring_point_resume_screen.dart';

/// 📱 Nova Tela: Histórico de Monitoramento (v2)
/// 
/// FUNCIONALIDADES:
/// - Lista de sessões de monitoramento com status
/// - Sistema de retomada para monitoramentos incompletos
/// - Integração com Mapa de Infestação (sem interpretação de severidade)
/// - Edição e visualização de pontos registrados
/// 
/// REGRAS DE NEGÓCIO (MIP):
/// - Monitoramento apenas coleta dados brutos
/// - Interpretação fica a cargo do Mapa de Infestação
/// - Cada ponto deve ser georreferenciado corretamente
/// - Sessões podem ser pausadas e retomadas
class MonitoringHistoryV2Screen extends StatefulWidget {
  const MonitoringHistoryV2Screen({Key? key}) : super(key: key);

  @override
  State<MonitoringHistoryV2Screen> createState() => _MonitoringHistoryV2ScreenState();
}

class _MonitoringHistoryV2ScreenState extends State<MonitoringHistoryV2Screen> {
  final MonitoringSessionService _sessionService = MonitoringSessionService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _monitoringSessions = [];
  String _selectedStatus = 'all'; // 'all', 'draft', 'finalized'
  String _selectedTalhao = 'all';
  List<String> _availableTalhoes = [];
  Map<String, String> _talhoesNomes = {}; // ✅ NOVO: Map ID → Nome

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      Logger.info('🔄 [MONITORING_V2] Iniciando carregamento de sessões...');
      
      // Carregar sessões de monitoramento
      final sessions = await _sessionService.getSessions();
      
      Logger.info('📊 [MONITORING_V2] ${sessions.length} sessões carregadas do serviço');
      
      if (sessions.isEmpty) {
        Logger.warning('⚠️ [MONITORING_V2] Nenhuma sessão encontrada!');
      } else {
        Logger.info('✅ [MONITORING_V2] Primeira sessão: ${sessions.first}');
      }
      
      // Extrair talhões únicos com NOMES
      final talhoesMap = <String, String>{}; // ID → Nome
      for (final session in sessions) {
        final talhaoId = session['talhao_id']?.toString();
        final talhaoNome = session['talhao_nome']?.toString();
        
        if (talhaoId != null && talhaoId.isNotEmpty) {
          // ✅ Usar NOME se disponível, senão usar ID
          talhoesMap[talhaoId] = talhaoNome ?? 'Talhão $talhaoId';
        }
      }
      
      _talhoesNomes = talhoesMap; // ✅ Salvar mapa completo
      _availableTalhoes = ['all', ...talhoesMap.keys.toList()];
      
      setState(() {
        _monitoringSessions = sessions;
      });
      
      Logger.info('📊 [MONITORING_V2] Estado atualizado com ${_monitoringSessions.length} sessões');
      
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro ao carregar dados: $e');
      Logger.error('❌ [MONITORING_V2] Stack: ${StackTrace.current}');
      _showErrorSnackBar('Erro ao carregar histórico de monitoramento');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Monitoramento'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewMonitoring,
            tooltip: 'Novo Monitoramento',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _monitoringSessions.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildFiltersBar(),
                    Expanded(
                      child: _buildSessionsList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewMonitoring,
        icon: const Icon(Icons.add),
        label: const Text('Novo Monitoramento'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Constrói barra de filtros
  Widget _buildFiltersBar() {
    final filteredSessions = _getFilteredSessions();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${filteredSessions.length} sessões encontradas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_selectedStatus != 'all')
            Chip(
              label: Text(_getStatusLabel(_selectedStatus)),
              onDeleted: () => setState(() => _selectedStatus = 'all'),
              backgroundColor: _getStatusColor(_selectedStatus).withOpacity(0.1),
              labelStyle: TextStyle(
                color: _getStatusColor(_selectedStatus),
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_selectedTalhao != 'all')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                label: Text(_selectedTalhao),
                onDeleted: () => setState(() => _selectedTalhao = 'all'),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói lista de sessões
  Widget _buildSessionsList() {
    final filteredSessions = _getFilteredSessions();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = filteredSessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  /// Constrói card de sessão
  Widget _buildSessionCard(Map<String, dynamic> session) {
    final status = session['status'] as String;
    final isDraft = status == 'draft';
    final isFinalized = status == 'finalized';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da sessão
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isDraft ? Icons.play_circle_outline : Icons.check_circle_outline,
                      color: _getStatusColor(status),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session['cultura_nome'] ?? 'Cultura'} - Talhão ${session['talhao_nome'] ?? session['talhao_id'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(
                            DateTime.parse(session['started_at'] ?? DateTime.now().toIso8601String()),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Estatísticas da sessão
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Pontos',
                      '${session['pontos_registrados'] ?? 0}',
                      Icons.location_on,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Ocorrências',
                      '${session['total_ocorrencias'] ?? 0}',
                      Icons.bug_report,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Duração',
                      _formatDuration(session['duracao_minutos'] ?? 0),
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              // Dados de Estande de Plantas (se disponíveis)
              if (session['estande_data'] != null) ...[
                const SizedBox(height: 8),
                _buildEstandeDataWidget(session['estande_data']),
              ],
              
              const SizedBox(height: 12),
              
              // Botões de ação
              Row(
                children: [
                  if (isDraft) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resumeMonitoring(session),
                        icon: const Icon(Icons.play_arrow, size: 14),
                        label: const Text('Continuar', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openSessionDetails(session),
                      icon: const Icon(Icons.visibility, size: 14),
                      label: Text(
                        isDraft ? 'Ver Detalhes' : 'Ver Relatório',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        side: BorderSide(color: AppTheme.secondaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showSessionOptions(session),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Mais opções',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói item de estatística
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói widget com dados de estande de plantas
  Widget _buildEstandeDataWidget(Map<String, dynamic> estandeData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green[600], size: 12),
              const SizedBox(width: 4),
              Text(
                'Estande de Plantas',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildEstandeStat(
                  'Estado',
                  estandeData['estadoFenologico'] ?? 'N/A',
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildEstandeStat(
                  'CV%',
                  '${(estandeData['cv'] ?? 0.0).toStringAsFixed(1)}%',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildEstandeStat(
                  'Efic.',
                  '${(estandeData['eficiencia'] ?? 0.0).toStringAsFixed(0)}%',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói estatística de estande
  Widget _buildEstandeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Constrói estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum monitoramento encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece um novo monitoramento para registrar dados de pragas e doenças',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewMonitoring,
            icon: const Icon(Icons.add),
            label: const Text('Iniciar Monitoramento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE NEGÓCIO
  // ============================================================================

  /// Obtém sessões filtradas
  List<Map<String, dynamic>> _getFilteredSessions() {
    return _monitoringSessions.where((session) {
      // Filtro por status
      if (_selectedStatus != 'all' && session['status'] != _selectedStatus) {
        return false;
      }
      
      // Filtro por talhão
      if (_selectedTalhao != 'all' && session['talhao_id'] != _selectedTalhao) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Inicia novo monitoramento
  void _startNewMonitoring() {
    try {
      Logger.info('🚀 [MONITORING_V2] Iniciando novo monitoramento...');
      
      Navigator.of(context).pushNamed(AppRoutes.advancedMonitoring);
      
      Logger.info('✅ [MONITORING_V2] Navegação para monitoramento avançado realizada');
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro ao iniciar monitoramento: $e');
      _showErrorSnackBar('Erro ao iniciar monitoramento: $e');
    }
  }

  /// Retoma monitoramento em andamento (de onde parou)
  void _resumeMonitoring(Map<String, dynamic> session) async {
    try {
      final sessionId = session['id'] as String;
      final talhaoId = session['talhao_id'] as String;
      final culturaId = session['cultura_id'] as String;
      final talhaoNome = session['talhao_nome'] as String;
      final culturaNome = session['cultura_nome'] as String;
      
      Logger.info('🔄 [MONITORING_V2] Retomando monitoramento: $sessionId');
      Logger.info('🔄 [MONITORING_V2] Talhão: $talhaoNome, Cultura: $culturaNome');
      
      // Gerar ID único para o ponto (pode ser monitoramento livre)
      final pontoId = DateTime.now().millisecondsSinceEpoch;
      
      // Navegar para tela de ponto de monitoramento SEM exigir pontos desenhados
      Logger.info('🚀 [MONITORING_V2] Navegando para continuar monitoramento livre...');
      
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.monitoringPoint,
        arguments: {
          'pontoId': pontoId,
          'talhaoId': talhaoId,
          'culturaId': culturaId,
          'talhaoNome': talhaoNome,
          'culturaNome': culturaNome,
          'pontos': null, // ✅ NULL para monitoramento livre
          'data': DateTime.now(),
          'sessionId': sessionId, // ✅ PASSAR SESSION ID EXISTENTE
          'isContinuing': true,
          'isFreeMonitoring': true, // ✅ Indicar que é monitoramento livre
        },
      );
      
      Logger.info('✅ [MONITORING_V2] Retornou da tela de monitoramento');
      
      // Recarregar dados após retomar
      _loadData();
      if (result == true) {
        _showSuccessSnackBar('Monitoramento retomado com sucesso');
      }
      
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro ao retomar monitoramento: $e');
      Logger.error('❌ [MONITORING_V2] Stack: ${StackTrace.current}');
      _showErrorSnackBar('Erro ao retomar monitoramento');
    }
  }

  /// Abre detalhes da sessão ou relatório agronômico
  void _openSessionDetails(Map<String, dynamic> session) {
    final isDraft = session['status'] == 'draft';
    
    if (isDraft) {
      // Para sessões em rascunho, abrir tela de detalhes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonitoringDetailsV2Screen(
            sessionData: session,
          ),
        ),
      );
    } else {
      // Para sessões finalizadas, abrir Relatório Agronômico
      Logger.info('📊 [MONITORING_V2] Abrindo Relatório Agronômico para sessão: ${session['id']}');
      Logger.info('📊 [MONITORING_V2] Talhão: ${session['talhao_nome']}, Cultura: ${session['cultura_nome']}');
      
      Navigator.pushNamed(
        context,
        AppRoutes.reports, // ✅ Rota correta para AdvancedAnalyticsDashboard
        arguments: {
          'talhaoId': session['talhao_id'],
          'culturaId': session['cultura_id'],
          'talhaoNome': session['talhao_nome'],
          'culturaNome': session['cultura_nome'],
          'sessionId': session['id'],
          'monitoringData': session,
        },
      );
    }
  }

  /// Mostra opções da sessão
  void _showSessionOptions(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Sessão'),
              subtitle: const Text('Editar ocorrências e observações', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _editSession(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.orange),
              title: const Text('Duplicar Sessão'),
              subtitle: const Text('Criar cópia desta sessão', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _duplicateSession(session);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Excluir Sessão', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Remover permanentemente', style: TextStyle(fontSize: 12, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSession(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra diálogo de filtros
  /// Executa diagnóstico de sessões
  Future<void> _runDiagnostic() async {
    try {
      Logger.info('🔧 [MONITORING_V2] Executando diagnóstico completo...');
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Executar diagnóstico NOVO e mais completo
      final results = await MonitoringSessionDiagnostic.runFullDiagnostic();
      
      // Fechar loading
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar resultados formatados
      final message = MonitoringSessionDiagnostic.formatResults(results);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Diagnóstico de Sessões'),
            content: SingleChildScrollView(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recarregar dados
                },
                child: const Text('Recarregar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro no diagnóstico: $e');
      
      // Fechar loading se estiver aberto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Erro no diagnóstico: $e');
    }
  }

  /// Executa reset completo do banco
  Future<void> _executeCompleteReset() async {
    try {
      // Mostrar confirmação
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 12),
              Text('Reset Completo'),
            ],
          ),
          content: const Text(
            '🧹 LIMPEZA COMPLETA:\n'
            '• Remove TODAS as ocorrências antigas (17)\n'
            '• Verifica schema do banco\n'
            '• Popula com 5 ocorrências de teste corretas\n'
            '• Testa integração: Monitoramento → Mapa → Relatório\n\n'
            '⚠️ Esta ação é SEGURA e REVERSÍVEL.\n\n'
            'Deseja continuar?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Executar Reset'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Executando reset completo...'),
              SizedBox(height: 10),
              Text('Isso pode levar alguns segundos', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
      
      // Executar reset completo
      final results = await CompleteDatabaseReset.executeCompleteReset();
      
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        
        // Recarregar dados
        await _loadData();
        
        // Mostrar resultado
        final success = results['success'] == true;
        final populated = results['populated_count'] ?? 0;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(success ? 'Reset Completo!' : 'Reset com Problemas'),
              ],
            ),
            content: Text(
              success
                ? '✅ SUCESSO TOTAL!\n\n'
                  '• Ocorrências antigas: LIMPAS\n'
                  '• Dados de teste: $populated populados\n'
                  '• Integração: VERIFICADA\n\n'
                  '👉 Agora vá em:\n'
                  '1. Mapa de Infestação → Ver os $populated pontos\n'
                  '2. Relatórios → Ver análises da IA\n'
                  '3. Fazer novo monitoramento para testar!'
                : '❌ Houve problemas no reset.\n\n'
                  'Verifique os logs para mais detalhes.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e, stack) {
      Logger.error('❌ Erro no reset completo: $e', null, stack);
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no reset: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Popula banco com dados de teste para validar integração
  Future<void> _populateTestData() async {
    try {
      // Mostrar confirmação
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.science, color: Colors.orange),
              SizedBox(width: 12),
              Text('Popular Dados de Teste'),
            ],
          ),
          content: const Text(
            'Isso vai ADICIONAR 3 ocorrências de teste a uma sessão existente.\n\n'
            'Use isto para TESTAR se a integração Monitoramento → Mapa está funcionando.\n\n'
            'Deseja continuar?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Popular'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Popular dados
      await ForcePopulateTestData.populateWithRealData();
      
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        
        // Recarregar dados
        await _loadData();
        
        // Mostrar sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dados de teste populados! Verifique o Mapa de Infestação.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao popular dados: $e');
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Executa diagnóstico de ocorrências
  Future<void> _runOccurrencesDiagnostic() async {
    try {
      Logger.info('🔍 [MONITORING_V2] Executando diagnóstico RÁPIDO...');
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Executando diagnóstico...'),
            ],
          ),
        ),
      );
      
      // ✅ EXECUTAR DIAGNÓSTICO RÁPIDO E DIRETO
      final quickResults = await DirectOccurrenceService.quickDiagnostic();
      final sqlResults = await SQLDirectDiagnostic.runDirectSQL();
      
      // Fechar loading
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar resultados formatados
      final quickSummary = '''
═══════════════════════════════════════
🚀 DIAGNÓSTICO RÁPIDO
═══════════════════════════════════════

📊 CONTADORES:
   • Sessões: ${quickResults['sessions']}
   • Pontos: ${quickResults['points']}
   • Ocorrências: ${quickResults['occurrences']}

${quickResults['occurrences'] == 0 ? '❌ PROBLEMA: 0 OCORRÊNCIAS!' : '✅ OCORRÊNCIAS ENCONTRADAS!'}

═══════════════════════════════════════
''';
      
      final sqlMessage = SQLDirectDiagnostic.formatResults(sqlResults);
      final message = quickSummary + '\n' + sqlMessage;
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.pest_control, color: Colors.orange),
                SizedBox(width: 12),
                Text('Diagnóstico de Ocorrências'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData();
                },
                child: const Text('Recarregar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro no diagnóstico de ocorrências: $e');
      
      // Fechar loading se estiver aberto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Erro no diagnóstico: $e');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtro por status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Todos')),
                const DropdownMenuItem(value: 'draft', child: Text('Em andamento')),
                const DropdownMenuItem(value: 'finalized', child: Text('Finalizados')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value ?? 'all'),
            ),
            const SizedBox(height: 16),
            // Filtro por talhão
            DropdownButtonFormField<String>(
              value: _selectedTalhao,
              decoration: const InputDecoration(
                labelText: 'Talhão',
                border: OutlineInputBorder(),
                isDense: true, // ✅ NOVO: Reduz altura
              ),
              isExpanded: true, // ✅ NOVO: Evita overflow
              items: _availableTalhoes.map((talhaoId) => DropdownMenuItem(
                value: talhaoId,
                child: Text(
                  talhaoId == 'all' ? 'Todos' : (_talhoesNomes[talhaoId] ?? 'Talhão $talhaoId'),
                  overflow: TextOverflow.ellipsis, // ✅ NOVO: Corta texto longo
                  maxLines: 1, // ✅ NOVO: Máximo 1 linha
                ),
              )).toList(),
              onChanged: (value) => setState(() => _selectedTalhao = value ?? 'all'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Obtém cor da status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'finalized':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Obtém label da status
  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Em andamento';
      case 'finalized':
        return 'Finalizado';
      default:
        return 'Desconhecido';
    }
  }

  /// Formata duração em minutos
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }

  /// Edita sessão
  void _editSession(Map<String, dynamic> session) async {
    try {
      // Navegar para tela de edição da sessão
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.monitoringPointEdit,
        arguments: {
          'sessionData': session,
        },
      );
      
      if (result == true) {
        // Recarregar dados após edição
        _loadData();
        _showSuccessSnackBar('Sessão editada com sucesso');
      }
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro ao editar sessão: $e');
      _showErrorSnackBar('Erro ao editar sessão');
    }
  }

  /// Duplica sessão
  void _duplicateSession(Map<String, dynamic> session) async {
    try {
      final sessionId = session['id'] as String;
      
      // Confirmar duplicação
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicar Sessão'),
          content: const Text('Deseja criar uma cópia desta sessão?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Duplicar'),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        // Duplicar sessão
        await _sessionService.duplicateSession(sessionId);
        _showSuccessSnackBar('Sessão duplicada com sucesso');
        _loadData();
      }
    } catch (e) {
      Logger.error('❌ [MONITORING_V2] Erro ao duplicar sessão: $e');
      _showErrorSnackBar('Erro ao duplicar sessão');
    }
  }

  /// Exclui sessão
  void _deleteSession(Map<String, dynamic> session) {
    final sessionName = '${session['cultura_nome']} - ${session['talhao_nome']}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Excluir Sessão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja excluir permanentemente a sessão:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                sessionName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Atenção: Esta ação não pode ser desfeita!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Serão excluídos:\n• Todos os pontos de monitoramento\n• Todas as ocorrências\n• Dados do mapa de infestação',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteSession(session);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir Permanentemente'),
          ),
        ],
      ),
    );
  }

  /// Confirma exclusão da sessão
  Future<void> _confirmDeleteSession(Map<String, dynamic> session) async {
    try {
      final sessionId = session['id'] as String;
      
      Logger.info('🗑️ [MONITORING_V2] Excluindo sessão: $sessionId');
      
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
      
      // Obter banco de dados
      final db = await AppDatabase.instance.database;
      
      // 1. Excluir ocorrências da sessão (via pontos)
      await db.rawDelete('''
        DELETE FROM monitoring_occurrences 
        WHERE point_id IN (
          SELECT id FROM monitoring_points WHERE session_id = ?
        )
      ''', [sessionId]);
      
      Logger.info('✅ [MONITORING_V2] Ocorrências excluídas');
      
      // 2. Buscar IDs dos pontos ANTES de excluir (para limpar mapa)
      final pointIds = await db.query(
        'monitoring_points',
        columns: ['id'],
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      Logger.info('📍 [MONITORING_V2] ${pointIds.length} pontos encontrados para exclusão');
      
      // 3. Excluir dados do mapa de infestação POR PONTO_ID
      // ✅ infestation_map NÃO tem session_id, usar ponto_id!
      for (final point in pointIds) {
        final pointId = point['id'] as String;
        await db.delete(
          'infestation_map',
          where: 'ponto_id = ?',
          whereArgs: [pointId],
        );
      }
      
      Logger.info('✅ [MONITORING_V2] Dados do mapa de infestação excluídos');
      
      // 4. Excluir pontos de monitoramento
      await db.delete(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      Logger.info('✅ [MONITORING_V2] Pontos excluídos');
      
      // 5. Excluir a sessão
      await db.delete(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      Logger.info('✅ [MONITORING_V2] Sessão excluída com sucesso');
      
      // Fechar loading
      if (mounted) Navigator.of(context).pop();
      
      // Recarregar dados
      _loadData();
      
      // Mostrar mensagem de sucesso
      _showSuccessSnackBar('Sessão excluída com sucesso');
      
    } catch (e, stack) {
      Logger.error('❌ [MONITORING_V2] Erro ao excluir sessão: $e');
      Logger.error('❌ [MONITORING_V2] Stack: $stack');
      
      // Fechar loading se estiver aberto
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Erro ao excluir sessão: $e');
    }
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Mostra snackbar de informação
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
