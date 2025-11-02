import 'package:flutter/material.dart';
import '../../services/monitoring_history_service.dart';
import '../../utils/logger.dart';

/// Tela de visualização detalhada de um monitoramento histórico
class MonitoringHistoryViewScreen extends StatefulWidget {
  const MonitoringHistoryViewScreen({Key? key}) : super(key: key);

  @override
  State<MonitoringHistoryViewScreen> createState() => _MonitoringHistoryViewScreenState();
}

class _MonitoringHistoryViewScreenState extends State<MonitoringHistoryViewScreen> {
  final MonitoringHistoryService _historyService = MonitoringHistoryService();
  Map<String, dynamic>? _historyDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Deletar monitoramentos expirados automaticamente
    _deleteExpiredMonitorings();
    
    // Usar addPostFrameCallback para garantir que o context esteja disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistoryDetails();
    });
  }

  /// Deleta automaticamente monitoramentos com mais de 15 dias
  Future<void> _deleteExpiredMonitorings() async {
    try {
      Logger.info('🔄 Verificando monitoramentos expirados...');
      final deletedCount = await _historyService.deleteExpiredHistories(expirationDays: 15);
      
      if (deletedCount > 0) {
        Logger.info('✅ $deletedCount monitoramentos expirados foram deletados automaticamente');
      }
    } catch (e) {
      Logger.error('❌ Erro ao deletar monitoramentos expirados: $e');
    }
  }

  Future<void> _loadHistoryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Verificar se o context está montado
      if (!mounted) return;

      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      Logger.info('📋 Argumentos recebidos: $arguments');
      
      if (arguments == null) {
        throw Exception('Argumentos não fornecidos');
      }

      final historyId = arguments['id'] as String?;
      Logger.info('🆔 ID do histórico: $historyId');
      
      if (historyId == null) {
        throw Exception('ID do histórico não fornecido');
      }
      
      Logger.info('🔍 Carregando detalhes do histórico: $historyId');
      final details = await _historyService.getHistoryDetails(historyId);
      
      if (!mounted) return;
      
      Logger.info('📊 Detalhes carregados: $details');
      
      setState(() {
        _historyDetails = details;
        _isLoading = false;
      });
      
      Logger.info('✅ Detalhes do histórico carregados com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao carregar detalhes do histórico: $e');
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
    try {
      Logger.info('🏗️ Construindo tela de detalhes do histórico...');
      
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: const Text(
            'Detalhes do Monitoramento',
            style: TextStyle(
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
          actions: [
            IconButton(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit),
              tooltip: 'Editar/Continuar Monitoramento',
            ),
            IconButton(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete),
              tooltip: 'Deletar Histórico',
            ),
            IconButton(
              onPressed: _showShareDialog,
              icon: const Icon(Icons.share),
              tooltip: 'Compartilhar',
            ),
          ],
        ),
        body: _buildBody(),
      );
    } catch (e) {
      Logger.error('❌ Erro ao construir tela: $e');
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: const Text('Erro'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar tela: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    try {
      Logger.info('🏗️ Construindo body da tela...');
      Logger.info('📊 Estado: loading=$_isLoading, error=$_error, details=${_historyDetails != null}');
      
      if (_isLoading) {
        Logger.info('⏳ Mostrando loading...');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando detalhes...',
                style: TextStyle(
                  color: Color(0xFF2D9CDB),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      if (_error != null) {
        Logger.info('❌ Mostrando erro: $_error');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar detalhes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadHistoryDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9CDB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tentar Novamente'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        );
      }

    if (_historyDetails == null) {
      return const Center(
        child: Text(
          'Detalhes não encontrados',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF95A5A6),
          ),
        ),
      );
    }

      Logger.info('📊 Construindo conteúdo principal...');
      
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações principais
            _buildHeaderCard(),
            
            const SizedBox(height: 16),
            
            // Estatísticas do monitoramento
            _buildStatsCard(),
            
            const SizedBox(height: 16),
            
            // Lista de pontos monitorados
            _buildPointsCard(),
            
            const SizedBox(height: 16),
            
            // Lista de ocorrências
            _buildOccurrencesCard(),
            
            const SizedBox(height: 16),
            
            // Observações
            _buildObservationsCard(),
          ],
        ),
      );
    } catch (e) {
      Logger.error('❌ Erro ao construir body: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro ao construir tela: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeaderCard() {
    try {
      Logger.info('🏗️ Construindo header card...');
      
      final plotName = _historyDetails!['plot_name'] as String? ?? 'Talhão';
      final cropName = _historyDetails!['crop_name'] as String? ?? 'Cultura';
      final date = _historyDetails!['date'] as DateTime? ?? DateTime.now();
      final technicianName = _historyDetails!['technician_name'] as String? ?? 'Não informado';
      final severityValue = _historyDetails!['severity'];
      final severity = severityValue is num ? severityValue.toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: _getSeverityColor(severity),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plotName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF95A5A6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getSeverityText(severity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.access_time,
                  'Data',
                  _formatDate(date),
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.person,
                  'Técnico',
                  technicianName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    } catch (e) {
      Logger.error('❌ Erro ao construir header card: $e');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text('Erro ao carregar header: $e'),
          ],
        ),
      );
    }
  }

  Widget _buildStatsCard() {
    final points = _historyDetails!['points'] as List;
    final occurrences = _historyDetails!['occurrences'] as List;
    final severityValue = _historyDetails!['severity'];
    final severity = severityValue is num ? severityValue.toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas do Monitoramento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Pontos Monitorados',
                  '${points.length}',
                  Icons.location_on,
                  const Color(0xFF2D9CDB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Ocorrências',
                  '${occurrences.length}',
                  Icons.bug_report,
                  const Color(0xFFEB5757),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Severidade Média',
                  severity.toStringAsFixed(1),
                  Icons.trending_up,
                  _getSeverityColor(severity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Duração',
                  _calculateDuration(),
                  Icons.timer,
                  const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    final points = _historyDetails!['points'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF2D9CDB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pontos Monitorados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9CDB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${points.length} pontos',
                  style: const TextStyle(
                    color: Color(0xFF2D9CDB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value as Map<String, dynamic>;
            return _buildPointItem(point, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOccurrencesCard() {
    final occurrences = _historyDetails!['occurrences'] as List;
    
    // Remover duplicações baseado no nome e tipo
    final uniqueOccurrences = <Map<String, dynamic>>[];
    final seenKeys = <String>{};
    
    for (final occurrence in occurrences) {
      final name = occurrence['name'] as String? ?? occurrence['subtipo'] as String? ?? '';
      final type = occurrence['type'] as String? ?? occurrence['tipo'] as String? ?? '';
      final key = '$name-$type';
      
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        uniqueOccurrences.add(occurrence as Map<String, dynamic>);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report,
                color: Color(0xFFEB5757),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ocorrências Registradas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEB5757).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${uniqueOccurrences.length} ocorrências',
                  style: const TextStyle(
                    color: Color(0xFFEB5757),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (uniqueOccurrences.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma ocorrência registrada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoramento realizado sem problemas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...uniqueOccurrences.map((occurrence) => _buildOccurrenceItem(occurrence)).toList(),
        ],
      ),
    );
  }

  Widget _buildObservationsCard() {
    final observations = _historyDetails!['observations'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note,
                color: Color(0xFFF2C94C),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Observações Gerais',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (observations == null || observations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma observação registrada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                observations,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF95A5A6),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF95A5A6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPointItem(Map<String, dynamic> point, int number) {
    final occurrences = point['occurrences'] as List;
    final observations = point['observations'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2D9CDB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ponto $number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
              if (occurrences.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB5757).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${occurrences.length} ocorrências',
                    style: const TextStyle(
                      color: Color(0xFFEB5757),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (observations != null && observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              observations,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF95A5A6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOccurrenceItem(Map<String, dynamic> occurrence) {
    // Tentar obter o nome da infestação de diferentes campos
    String name = occurrence['name'] as String? ?? '';
    if (name.isEmpty) {
      name = occurrence['subtipo'] as String? ?? '';
    }
    if (name.isEmpty) {
      name = occurrence['organism_name'] as String? ?? '';
    }
    if (name.isEmpty) {
      name = occurrence['organismo'] as String? ?? '';
    }
    if (name.isEmpty) {
      name = 'Infestação não identificada';
    }
    
    final type = occurrence['type'] as String? ?? occurrence['tipo'] as String? ?? 'Outro';
    
    // Corrigir: garantir que o índice de infestação seja tratado como percentual (0-100)
    final infestationIndexValue = occurrence['infestationIndex'] ?? occurrence['percentual'];
    double infestationIndex = 0.0;
    
    if (infestationIndexValue is num) {
      infestationIndex = infestationIndexValue.toDouble();
      // Se o valor estiver entre 0-1, converter para percentual
      if (infestationIndex <= 1.0) {
        infestationIndex = infestationIndex * 100;
      }
    }
    
    final notes = occurrence['notes'] as String? ?? occurrence['observacao'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getOccurrenceTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getOccurrenceTypeColor(type).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getOccurrenceTypeColor(type),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getOccurrenceTypeIcon(type),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF95A5A6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeverityColor(infestationIndex),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSeverityText(infestationIndex),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(double severity) {
    // Corrigido: usar escala 0-100 em vez de 0-10
    if (severity >= 75) return const Color(0xFFEB5757); // Crítico - Vermelho
    if (severity >= 50) return const Color(0xFFF2C94C); // Alto - Laranja
    if (severity >= 25) return const Color(0xFF2D9CDB); // Médio - Azul
    return const Color(0xFF27AE60); // Baixo - Verde
  }

  String _getSeverityText(double severity) {
    // Corrigido: usar escala 0-100 em vez de 0-10
    if (severity >= 75) return 'Crítico';
    if (severity >= 50) return 'Alto';
    if (severity >= 25) return 'Médio';
    return 'Baixo';
  }

  Color _getOccurrenceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'praga':
        return const Color(0xFFF2994A);
      case 'doença':
        return const Color(0xFF9B51E0);
      case 'daninha':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF2D9CDB);
    }
  }

  String _getOccurrenceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'praga':
        return '🐛';
      case 'doença':
        return '🦠';
      case 'daninha':
        return '🌿';
      default:
        return '⚠️';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    // Simulação de duração baseada no número de pontos
    final points = _historyDetails!['points'] as List;
    final duration = points.length * 15; // 15 minutos por ponto
    
    if (duration < 60) {
      return '${duration}min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return '${hours}h ${minutes}min';
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar Monitoramento'),
        content: const Text('Funcionalidade de compartilhamento será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para editar/continuar monitoramento
  void _showEditDialog() async {
    try {
      Logger.info('🔧 Iniciando diálogo de edição...');
      Logger.info('📊 _historyDetails: $_historyDetails');
      
      final historyId = _historyDetails?['id'] as String?;
      final plotId = _historyDetails?['plot_id'] as String?;
      final cropName = _historyDetails?['crop_name'] as String? ?? 'Cultura';
      
      Logger.info('🆔 historyId: $historyId');
      Logger.info('🏞️ plotId: $plotId');
      Logger.info('🌱 cropName: $cropName');
      
      if (historyId == null || plotId == null) {
        Logger.error('❌ Dados do monitoramento não encontrados');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: Dados do monitoramento não encontrados'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Editar Monitoramento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O que você gostaria de fazer com este monitoramento?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Opções disponíveis:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Continuar de onde parou', style: TextStyle(fontSize: 12)),
                  Text('• Adicionar novos pontos', style: TextStyle(fontSize: 12)),
                  Text('• Editar pontos existentes', style: TextStyle(fontSize: 12)),
                  Text('• Revisar ocorrências', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop('continue'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    if (action == 'continue') {
      await _continueMonitoring(historyId, plotId, cropName);
    }
    
    } catch (e) {
      Logger.error('❌ Erro no diálogo de edição: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir diálogo de edição: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Continua o monitoramento a partir do ponto atual
  Future<void> _continueMonitoring(String historyId, String plotId, String cropName) async {
    try {
      Logger.info('🔄 Continuando monitoramento: $historyId');
      Logger.info('🏞️ Plot ID: $plotId');
      Logger.info('🌱 Crop Name: $cropName');
      
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando monitoramento...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      
      // Buscar dados do monitoramento para continuar
      final monitoringData = await _historyService.getHistoryDetails(historyId);
      
      if (monitoringData == null) {
        throw Exception('Dados do monitoramento não encontrados');
      }
      
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Navegar para a tela de ponto de monitoramento
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/monitoring_point',
          arguments: {
            'historyId': historyId,
            'plotId': plotId,
            'cropName': cropName,
            'isContinuing': true,
            'monitoringData': monitoringData,
          },
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao continuar monitoramento: $e');
      
      // Fechar loading se estiver aberto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao continuar monitoramento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostra diálogo de confirmação para deletar histórico
  void _showDeleteDialog() async {
    try {
      Logger.info('🗑️ Iniciando diálogo de exclusão...');
      Logger.info('📊 _historyDetails: $_historyDetails');
      
      final historyId = _historyDetails?['id'] as String?;
      Logger.info('🆔 historyId: $historyId');
      
      if (historyId == null) {
        Logger.error('❌ ID do histórico não encontrado');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: ID do histórico não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja deletar este histórico de monitoramento?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Esta ação não pode ser desfeita!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Serão deletados:', style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• Todos os pontos de monitoramento', style: TextStyle(fontSize: 12)),
                  Text('• Todas as ocorrências registradas', style: TextStyle(fontSize: 12)),
                  Text('• Todas as fotos anexadas', style: TextStyle(fontSize: 12)),
                  Text('• Todos os alertas relacionados', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Deletar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _deleteHistory(historyId);
    }
    
    } catch (e) {
      Logger.error('❌ Erro no diálogo de exclusão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir diálogo de exclusão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Deleta o histórico de monitoramento
  Future<void> _deleteHistory(String historyId) async {
    try {
      Logger.info('🗑️ Iniciando deleção do histórico: $historyId');
      Logger.info('📊 _historyDetails antes da deleção: $_historyDetails');
      
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deletando histórico...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      
      // Deletar histórico
      final success = await _historyService.deleteHistory(historyId);
      
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (success) {
        Logger.info('✅ Histórico deletado com sucesso');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Histórico deletado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Voltar para a tela anterior
          Navigator.of(context).pop();
        }
      } else {
        Logger.warning('⚠️ Falha ao deletar histórico');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao deletar histórico. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao deletar histórico: $e');
      
      // Fechar loading se estiver aberto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar histórico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
