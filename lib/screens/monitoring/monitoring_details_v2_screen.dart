import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/monitoring_session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../models/organism_catalog.dart';
import 'monitoring_point_edit_screen.dart';

/// 📱 Tela de Detalhes do Monitoramento (v2)
/// 
/// FUNCIONALIDADES:
/// - Exibe dados brutos coletados (SEM interpretação de severidade)
/// - Permite edição e exclusão de pontos individuais
/// - Mostra coordenadas GPS precisas
/// - Lista ocorrências registradas com quantidades brutas
/// - Integração preparada para Mapa de Infestação
/// 
/// REGRAS DE NEGÓCIO (MIP):
/// - NÃO interpreta níveis (baixo/médio/alto)
/// - Apenas coleta e exibe dados brutos
/// - Georreferenciamento obrigatório
/// - Dados enviados para Mapa de Infestação para interpretação
class MonitoringDetailsV2Screen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const MonitoringDetailsV2Screen({
    Key? key,
    required this.sessionData,
  }) : super(key: key);

  @override
  State<MonitoringDetailsV2Screen> createState() => _MonitoringDetailsV2ScreenState();
}

class _MonitoringDetailsV2ScreenState extends State<MonitoringDetailsV2Screen> {
  final MonitoringSessionService _sessionService = MonitoringSessionService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _monitoringPoints = [];
  Map<String, OrganismCatalog> _organismsCache = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionId = widget.sessionData['id'] as String;
      
      // Carregar pontos da sessão
      _monitoringPoints = await _sessionService.getSessionPoints(sessionId);
      
      // Carregar organismos do catálogo
      await _loadOrganismsCache();
      
      Logger.info('📊 [MONITORING_DETAILS_V2] ${_monitoringPoints.length} pontos carregados');
      
    } catch (e) {
      Logger.error('❌ [MONITORING_DETAILS_V2] Erro ao carregar dados: $e');
      _errorMessage = 'Erro ao carregar dados da sessão';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega cache de organismos
  Future<void> _loadOrganismsCache() async {
    try {
      final organismIds = <String>{};
      
      // Extrair IDs únicos de organismos
      for (final point in _monitoringPoints) {
        final occurrences = point['occurrences'] as List<dynamic>? ?? [];
        for (final occurrence in occurrences) {
          final organismId = occurrence['organism_id'] as String?;
          if (organismId != null) {
            organismIds.add(organismId);
          }
        }
      }
      
      // Carregar organismos do catálogo
      for (final organismId in organismIds) {
        final organism = await _sessionService.getOrganismById(organismId);
        if (organism != null) {
          _organismsCache[organismId] = organism;
        }
      }
      
      Logger.info('📊 [MONITORING_DETAILS_V2] ${_organismsCache.length} organismos carregados');
      
    } catch (e) {
      Logger.error('❌ [MONITORING_DETAILS_V2] Erro ao carregar organismos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes - ${widget.sessionData['cultura_nome'] ?? 'Monitoramento'}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editSession,
            tooltip: 'Editar Sessão',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSession,
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _monitoringPoints.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSessionSummary(),
                          const SizedBox(height: 24),
                          _buildPointsList(),
                        ],
                      ),
                    ),
    );
  }

  /// Constrói resumo da sessão
  Widget _buildSessionSummary() {
    final totalPoints = _monitoringPoints.length;
    final totalOccurrences = _monitoringPoints.fold<int>(
      0,
      (sum, point) => sum + ((point['occurrences'] as List?)?.length ?? 0),
    );
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resumo da Sessão',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Estatísticas principais
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pontos Monitorados',
                    totalPoints.toString(),
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Ocorrências',
                    totalOccurrences.toString(),
                    Icons.bug_report,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Cultura',
                    widget.sessionData['cultura_nome'] ?? 'N/A',
                    Icons.agriculture,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Talhão',
                    widget.sessionData['talhao_id'] ?? 'N/A',
                    Icons.map,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações da sessão
            _buildSessionInfo(),
          ],
        ),
      ),
    );
  }

  /// Constrói card de resumo
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói informações da sessão
  Widget _buildSessionInfo() {
    final startedAt = DateTime.tryParse(widget.sessionData['started_at'] ?? '');
    final finishedAt = DateTime.tryParse(widget.sessionData['finished_at'] ?? '');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Iniciado em:',
            startedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(startedAt) : 'N/A',
            Icons.schedule,
          ),
          if (finishedAt != null)
            _buildInfoRow(
              'Finalizado em:',
              DateFormat('dd/MM/yyyy HH:mm').format(finishedAt),
              Icons.check_circle,
            ),
          _buildInfoRow(
            'Status:',
            widget.sessionData['status'] == 'finalized' ? 'Finalizado' : 'Em andamento',
            widget.sessionData['status'] == 'finalized' ? Icons.check_circle : Icons.play_circle_outline,
          ),
        ],
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói lista de pontos
  Widget _buildPointsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Pontos Monitorados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_monitoringPoints.length} pontos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ..._monitoringPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return _buildPointCard(point, index + 1);
        }).toList(),
      ],
    );
  }

  /// Constrói card de ponto
  Widget _buildPointCard(Map<String, dynamic> point, int pointNumber) {
    final occurrences = point['occurrences'] as List<dynamic>? ?? [];
    final latitude = point['latitude'] as double? ?? 0.0;
    final longitude = point['longitude'] as double? ?? 0.0;
    final plantasAvaliadas = point['plantas_avaliadas'] as int? ?? 0;
    final gpsAccuracy = point['gps_accuracy'] as double?;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do ponto
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      pointNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ponto $pointNumber',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePointAction(value, point),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Excluir', style: TextStyle(color: Colors.red)),
                        dense: true,
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações do ponto
            Row(
              children: [
                Expanded(
                  child: _buildPointInfo(
                    'Plantas Avaliadas',
                    plantasAvaliadas.toString(),
                    Icons.eco,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPointInfo(
                    'Ocorrências',
                    occurrences.length.toString(),
                    Icons.bug_report,
                    Colors.red,
                  ),
                ),
                if (gpsAccuracy != null)
                  Expanded(
                    child: _buildPointInfo(
                      'Precisão GPS',
                      '${gpsAccuracy.toStringAsFixed(1)}m',
                      Icons.gps_fixed,
                      Colors.blue,
                    ),
                  ),
              ],
            ),
            
            // Ocorrências do ponto
            if (occurrences.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Ocorrências Registradas:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...occurrences.map((occurrence) => _buildOccurrenceItem(occurrence)).toList(),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhuma ocorrência registrada neste ponto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói informação do ponto
  Widget _buildPointInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói item de ocorrência (SEM interpretação de severidade)
  Widget _buildOccurrenceItem(Map<String, dynamic> occurrence) {
    final organismId = occurrence['organism_id'] as String?;
    final valorBruto = occurrence['valor_bruto'] as double? ?? 0.0;
    final observacao = occurrence['observacao'] as String?;
    
    // Buscar organismo no cache
    final organism = _organismsCache[organismId];
    final organismName = organism?.name ?? 'Organismo $organismId';
    final organismType = organism?.type;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _getOrganismTypeIcon(organismType),
            color: _getOrganismTypeColor(organismType),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organismName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (observacao != null && observacao.isNotEmpty)
                  Text(
                    observacao,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // DADOS BRUTOS - SEM INTERPRETAÇÃO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '${valorBruto.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Erro desconhecido',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSessionData,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Constrói estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum ponto encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta sessão não possui pontos de monitoramento registrados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Obtém ícone do tipo de organismo
  IconData _getOrganismTypeIcon(dynamic type) {
    if (type == null) return Icons.help_outline;
    
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('pest')) return Icons.bug_report;
    if (typeString.contains('disease')) return Icons.healing;
    if (typeString.contains('weed')) return Icons.eco;
    
    return Icons.help_outline;
  }

  /// Obtém cor do tipo de organismo
  Color _getOrganismTypeColor(dynamic type) {
    if (type == null) return Colors.grey;
    
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('pest')) return Colors.red;
    if (typeString.contains('disease')) return Colors.orange;
    if (typeString.contains('weed')) return Colors.green;
    
    return Colors.grey;
  }

  /// Manipula ações do ponto
  void _handlePointAction(String action, Map<String, dynamic> point) {
    switch (action) {
      case 'edit':
        _editPoint(point);
        break;
      case 'delete':
        _deletePoint(point);
        break;
    }
  }

  /// Edita ponto
  void _editPoint(Map<String, dynamic> point) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonitoringPointEditScreen(
          pointData: point,
          sessionId: widget.sessionData['id'] ?? '',
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Recarregar dados se houve alterações
        _loadSessionData();
      }
    });
  }

  /// Exclui ponto
  void _deletePoint(Map<String, dynamic> point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Ponto'),
        content: const Text('Tem certeza que deseja excluir este ponto? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeletePoint(point);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Confirma exclusão do ponto
  Future<void> _confirmDeletePoint(Map<String, dynamic> point) async {
    try {
      // TODO: Implementar exclusão no banco de dados
      _showInfoSnackBar('Exclusão de ponto em desenvolvimento');
    } catch (e) {
      Logger.error('❌ [MONITORING_DETAILS_V2] Erro ao excluir ponto: $e');
      _showErrorSnackBar('Erro ao excluir ponto');
    }
  }

  /// Edita sessão
  void _editSession() {
    _showInfoSnackBar('Edição de sessão em desenvolvimento');
  }

  /// Compartilha sessão
  void _shareSession() {
    _showInfoSnackBar('Compartilhamento em desenvolvimento');
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
}
