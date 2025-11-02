import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/monitoring_session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../models/organism_catalog.dart';

/// 📱 Tela de Retomada de Monitoramento
/// 
/// FUNCIONALIDADES:
/// - Retoma monitoramento de onde parou
/// - Mostra pontos já registrados
/// - Continua para próximo ponto
/// - Mantém contexto da sessão
/// 
/// REGRAS DE NEGÓCIO (MIP):
/// - Preserva dados já coletados
/// - Continua sequência natural
/// - Não perde progresso anterior
class MonitoringPointResumeScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const MonitoringPointResumeScreen({
    Key? key,
    required this.sessionId,
    required this.sessionData,
  }) : super(key: key);

  @override
  State<MonitoringPointResumeScreen> createState() => _MonitoringPointResumeScreenState();
}

class _MonitoringPointResumeScreenState extends State<MonitoringPointResumeScreen> {
  final MonitoringSessionService _sessionService = MonitoringSessionService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _registeredPoints = [];
  int _nextPointNumber = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessionProgress();
  }

  Future<void> _loadSessionProgress() async {
    setState(() => _isLoading = true);

    try {
      // Carregar pontos já registrados na sessão
      _registeredPoints = await _sessionService.getSessionPoints(widget.sessionId);
      
      // Calcular próximo número do ponto
      if (_registeredPoints.isNotEmpty) {
        _nextPointNumber = (_registeredPoints.last['numero'] as int? ?? 0) + 1;
      } else {
        _nextPointNumber = 1;
      }
      
      Logger.info('📊 [RESUME] ${_registeredPoints.length} pontos registrados, próximo: $_nextPointNumber');
      
    } catch (e) {
      Logger.error('❌ [RESUME] Erro ao carregar progresso: $e');
      _errorMessage = 'Erro ao carregar progresso da sessão';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Retomar Monitoramento - ${widget.sessionData['cultura_nome'] ?? 'Cultura'}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSessionInfo(),
                      const SizedBox(height: 24),
                      _buildProgressSummary(),
                      const SizedBox(height: 24),
                      _buildRegisteredPoints(),
                      const SizedBox(height: 24),
                      _buildContinueSection(),
                    ],
                  ),
                ),
    );
  }

  /// Constrói informações da sessão
  Widget _buildSessionInfo() {
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
                  Icons.play_circle_outline,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Retomando Monitoramento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Continue de onde parou - todos os dados anteriores foram preservados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Cultura',
                    widget.sessionData['cultura_nome'] ?? 'N/A',
                    Icons.agriculture,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Talhão',
                    widget.sessionData['talhao_id'] ?? 'N/A',
                    Icons.map,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item de informação
  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói resumo do progresso
  Widget _buildProgressSummary() {
    final totalOccurrences = _registeredPoints.fold<int>(
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
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Progresso da Sessão',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard(
                    'Pontos Registrados',
                    '${_registeredPoints.length}',
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressCard(
                    'Ocorrências',
                    '$totalOccurrences',
                    Icons.bug_report,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressCard(
                    'Próximo Ponto',
                    '#$_nextPointNumber',
                    Icons.arrow_forward,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de progresso
  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  /// Constrói lista de pontos registrados
  Widget _buildRegisteredPoints() {
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
                  Icons.history,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pontos Já Registrados',
                  style: TextStyle(
                    fontSize: 16,
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
                    '${_registeredPoints.length} pontos',
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
            
            if (_registeredPoints.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum ponto registrado ainda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comece registrando o primeiro ponto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._registeredPoints.map((point) => _buildRegisteredPointItem(point)).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói item de ponto registrado
  Widget _buildRegisteredPointItem(Map<String, dynamic> point) {
    final pointNumber = point['numero'] as int? ?? 0;
    final occurrences = point['occurrences'] as List<dynamic>? ?? [];
    final latitude = point['latitude'] as double? ?? 0.0;
    final longitude = point['longitude'] as double? ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green,
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
                  'Ponto $pointNumber - Concluído',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${occurrences.length} ocorrências registradas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green[700],
            size: 20,
          ),
        ],
      ),
    );
  }

  /// Constrói seção de continuação
  Widget _buildContinueSection() {
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
                  Icons.arrow_forward,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Continuar Monitoramento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Clique no botão abaixo para continuar registrando o próximo ponto ($_nextPointNumber)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueMonitoring,
                icon: const Icon(Icons.play_arrow),
                label: Text('Continuar - Ponto $_nextPointNumber'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
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
            'Erro ao carregar progresso',
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
            onPressed: _loadSessionProgress,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE NEGÓCIO
  // ============================================================================

  /// Continua o monitoramento
  void _continueMonitoring() {
    // Navegar para tela de espera que vai para o próximo ponto
    Navigator.pushNamed(
      context,
      '/monitoring/point',
      arguments: {
        'historyId': widget.sessionId,
        'isContinuing': true,
        'monitoringData': widget.sessionData,
        'nextPointNumber': _nextPointNumber,
      },
    ).then((result) {
      if (result == true) {
        // Recarregar progresso se houve alterações
        _loadSessionProgress();
      }
    });
  }
}
