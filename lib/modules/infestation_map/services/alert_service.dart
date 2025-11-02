import 'dart:async';
import '../../../utils/logger.dart';
import '../models/models.dart';
import '../../../services/infestation_application_integration_service.dart';

/// Serviço para gerenciamento de alertas de infestação
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();




  /// Stream controller para alertas em tempo real
  final StreamController<List<InfestationAlert>> _alertStreamController = 
      StreamController<List<InfestationAlert>>.broadcast();

  /// Stream público para alertas
  Stream<List<InfestationAlert>> get alertStream => _alertStreamController.stream;

  /// Lista de alertas ativos
  final List<InfestationAlert> _activeAlerts = [];

  /// Lista de alertas reconhecidos
  final List<InfestationAlert> _acknowledgedAlerts = [];

  /// Lista de alertas resolvidos
  final List<InfestationAlert> _resolvedAlerts = [];
  
  /// Serviço de integração com aplicação
  final InfestationApplicationIntegrationService _applicationService = 
      InfestationApplicationIntegrationService();

  /// Gera alertas automáticos baseados nos resumos de infestação
  Future<List<InfestationAlert>> generateAutomaticAlerts(
    List<InfestationSummary> summaries,
  ) async {
    try {
      Logger.info('Gerando alertas automáticos para ${summaries.length} resumos');
      
      final List<InfestationAlert> newAlerts = [];
      
      for (final summary in summaries) {
        final alert = await _evaluateSummaryForAlert(summary);
        if (alert != null) {
          newAlerts.add(alert);
        }
      }

      // Priorizar alertas por nível de risco
      final prioritizedAlerts = _prioritizeAlertsByRisk(newAlerts);
      
      // Adicionar aos alertas ativos
      _activeAlerts.addAll(prioritizedAlerts);
      
      // Emitir stream atualizado
      _emitAlertStream();
      
      Logger.info('Gerados ${newAlerts.length} novos alertas');
      return prioritizedAlerts;
      
    } catch (e) {
      Logger.error('Erro ao gerar alertas automáticos: $e');
      return [];
    }
  }

  /// Avalia um resumo para determinar se deve gerar alerta
  Future<InfestationAlert?> _evaluateSummaryForAlert(
    InfestationSummary summary,
  ) async {
    try {
      // Verificar se já existe alerta ativo para este talhão/organismo
      final existingAlert = _activeAlerts.firstWhere(
        (alert) => alert.talhaoId == summary.talhaoId && 
                   alert.organismoId == summary.organismoId,
        orElse: () => InfestationAlert.empty(),
      );

      if (existingAlert.id.isNotEmpty) {
        // Atualizar alerta existente se necessário
        return await _updateExistingAlert(existingAlert, summary);
      }

      // Gerar novo alerta baseado no nível de infestação
      return await _createNewAlert(summary);
      
    } catch (e) {
      Logger.error('Erro ao avaliar resumo para alerta: $e');
      return null;
    }
  }

  /// Cria novo alerta baseado no resumo
  Future<InfestationAlert?> _createNewAlert(InfestationSummary summary) async {
    try {
      // Determinar nível de risco baseado no nível de infestação
      final riskLevel = _determineRiskLevel(summary.level);
      
      // Calcular score de prioridade
      final priorityScore = await _calculatePriorityScore(summary);
      
      // Verificar se atende aos critérios para gerar alerta
      if (!_shouldGenerateAlert(summary, riskLevel, priorityScore)) {
        return null;
      }

      final alert = InfestationAlert(
        id: _generateAlertId(),
        talhaoId: summary.talhaoId,
        organismoId: summary.organismoId,
        level: summary.level,
        riskLevel: riskLevel,
        priorityScore: priorityScore,
        message: _generateAlertMessage(summary, riskLevel),
        description: _generateAlertMessage(summary, riskLevel),
        createdAt: DateTime.now(),
        status: AlertStatus.active,
        acknowledgedAt: null,
        acknowledgedBy: null,
        resolvedAt: null,
        resolvedBy: null,
        notes: '',
        metadata: {
          'infestationPercentage': summary.infestationPercentage,
          'lastMonitoringDate': summary.lastMonitoringDate?.toIso8601String(),
          'trend': summary.trend,
          'severity': summary.severity,
        },
      );

      Logger.info('Novo alerta criado: ${alert.id} - ${alert.message}');
      return alert;
      
    } catch (e) {
      Logger.error('Erro ao criar novo alerta: $e');
      return null;
    }
  }

  /// Atualiza alerta existente se necessário
  Future<InfestationAlert?> _updateExistingAlert(
    InfestationAlert existingAlert,
    InfestationSummary summary,
  ) async {
    try {
      // Verificar se houve mudança significativa
      final hasSignificantChange = _hasSignificantChange(existingAlert, summary);
      
      if (!hasSignificantChange) {
        return null; // Não atualizar se não houve mudança significativa
      }

      // Calcular novo score de prioridade
      final newPriorityScore = await _calculatePriorityScore(summary);
      
      // Atualizar alerta existente
      final updatedAlert = existingAlert.copyWith(
        level: summary.level,
        priorityScore: newPriorityScore,
        message: _generateAlertMessage(summary, existingAlert.riskLevel),
        metadata: {
          ...existingAlert.metadata,
          'infestationPercentage': summary.infestationPercentage,
          'lastMonitoringDate': summary.lastMonitoringDate?.toIso8601String(),
          'trend': summary.trend,
          'severity': summary.severity,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      // Substituir na lista de alertas ativos
      final index = _activeAlerts.indexWhere((a) => a.id == existingAlert.id);
      if (index != -1) {
        _activeAlerts[index] = updatedAlert;
      }

      Logger.info('Alerta atualizado: ${updatedAlert.id}');
      return updatedAlert;
      
    } catch (e) {
      Logger.error('Erro ao atualizar alerta existente: $e');
      return null;
    }
  }

  /// Determina o nível de risco baseado no nível de infestação
  String _determineRiskLevel(String infestationLevel) {
    switch (infestationLevel.toLowerCase()) {
      case 'baixa':
        return 'baixo';
      case 'média':
        return 'médio';
      case 'alta':
        return 'alto';
      case 'crítica':
        return 'crítico';
      default:
        return 'desconhecido';
    }
  }

  /// Calcula score de prioridade para o alerta
  Future<double> _calculatePriorityScore(InfestationSummary summary) async {
    try {
      double score = 0.0;
      
      // Base: nível de infestação (0-40 pontos)
      score += _getInfestationLevelScore(summary.level);
      
      // Tendência temporal (0-30 pontos)
      score += _getTrendScore(summary.trend);
      
      // Severidade (0-20 pontos)
      score += _getSeverityScore(summary.severity);
      
      // Recência do monitoramento (0-10 pontos)
      score += _getRecencyScore(summary.lastMonitoringDate);
      
      return score;
      
    } catch (e) {
      Logger.error('Erro ao calcular score de prioridade: $e');
      return 0.0;
    }
  }

  /// Score baseado no nível de infestação
  double _getInfestationLevelScore(String level) {
    switch (level.toLowerCase()) {
      case 'baixa':
        return 10.0;
      case 'média':
        return 20.0;
      case 'alta':
        return 30.0;
      case 'crítica':
        return 40.0;
      default:
        return 0.0;
    }
  }

  /// Score baseado na tendência
  double _getTrendScore(String? trend) {
    if (trend == null) return 0.0;
    
    switch (trend.toLowerCase()) {
      case 'crescente':
        return 30.0;
      case 'estável':
        return 15.0;
      case 'decrescente':
        return 5.0;
      default:
        return 0.0;
    }
  }

  /// Score baseado na severidade
  double _getSeverityScore(String? severity) {
    if (severity == null) return 0.0;
    
    switch (severity.toLowerCase()) {
      case 'baixa':
        return 5.0;
      case 'média':
        return 10.0;
      case 'alta':
        return 15.0;
      case 'crítica':
        return 20.0;
      default:
        return 0.0;
    }
  }

  /// Score baseado na recência do monitoramento
  double _getRecencyScore(DateTime? lastMonitoringDate) {
    if (lastMonitoringDate == null) return 0.0;
    
    final daysSinceMonitoring = DateTime.now().difference(lastMonitoringDate).inDays;
    
    if (daysSinceMonitoring <= 1) return 10.0;
    if (daysSinceMonitoring <= 3) return 7.0;
    if (daysSinceMonitoring <= 7) return 5.0;
    if (daysSinceMonitoring <= 14) return 3.0;
    return 1.0;
  }

  /// Verifica se deve gerar alerta
  bool _shouldGenerateAlert(
    InfestationSummary summary,
    String riskLevel,
    double priorityScore,
  ) {
    // Sempre gerar para níveis críticos
    if (riskLevel == 'crítico') return true;
    
    // Gerar para níveis altos com score mínimo
    if (riskLevel == 'alto' && priorityScore >= 50.0) return true;
    
    // Gerar para níveis médios com score alto
    if (riskLevel == 'médio' && priorityScore >= 70.0) return true;
    
    // Gerar para níveis baixos apenas com score muito alto
    if (riskLevel == 'baixo' && priorityScore >= 85.0) return true;
    
    return false;
  }

  /// Verifica se houve mudança significativa
  bool _hasSignificantChange(
    InfestationAlert alert,
    InfestationSummary summary,
  ) {
    // Mudança de nível
    if (alert.level != summary.level) return true;
    
    // Mudança significativa na porcentagem (mais de 10%)
    final currentPercentage = summary.infestationPercentage;
    final previousPercentage = alert.metadata['infestationPercentage'] as double? ?? 0.0;
    if ((currentPercentage - previousPercentage).abs() > 10.0) return true;
    
    // Mudança na tendência
    final currentTrend = summary.trend;
    final previousTrend = alert.metadata['trend'] as String?;
    if (currentTrend != previousTrend) return true;
    
    return false;
  }

  /// Gera mensagem do alerta
  String _generateAlertMessage(InfestationSummary summary, String riskLevel) {
          final organismName = summary.organismName.isNotEmpty 
          ? summary.organismName 
          : 'Organismo ${summary.organismoId}';
    
    final talhaoName = summary.talhaoName.isNotEmpty 
        ? summary.talhaoName 
        : 'Talhão ${summary.talhaoId}';
    
    return 'Alerta de $riskLevel: $organismName detectado em $talhaoName '
           'com ${summary.infestationPercentage.toStringAsFixed(1)}% de infestação';
  }

  /// Prioriza alertas por nível de risco
  List<InfestationAlert> _prioritizeAlertsByRisk(List<InfestationAlert> alerts) {
    // Ordenar por score de prioridade (decrescente)
    alerts.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    
    // Agrupar por nível de risco
    final Map<String, List<InfestationAlert>> groupedAlerts = {};
    
    for (final alert in alerts) {
      final riskLevel = alert.riskLevel;
      groupedAlerts.putIfAbsent(riskLevel, () => []).add(alert);
    }
    
    // Reordenar priorizando níveis de risco mais altos
    final List<InfestationAlert> prioritizedAlerts = [];
    
    // Ordem de prioridade: crítico > alto > médio > baixo
    final priorityOrder = ['crítico', 'alto', 'médio', 'baixo'];
    
    for (final riskLevel in priorityOrder) {
      if (groupedAlerts.containsKey(riskLevel)) {
        prioritizedAlerts.addAll(groupedAlerts[riskLevel]!);
      }
    }
    
    return prioritizedAlerts;
  }

  /// Reconhece um alerta (marca como reconhecido)
  Future<bool> acknowledgeAlert(
    String alertId,
    String acknowledgedBy,
    String? notes,
  ) async {
    try {
      final alertIndex = _activeAlerts.indexWhere((a) => a.id == alertId);
      
      if (alertIndex == -1) {
        Logger.warning('Alerta não encontrado para reconhecimento: $alertId');
        return false;
      }

      final alert = _activeAlerts[alertIndex];
      final acknowledgedAlert = alert.copyWith(
        status: AlertStatus.acknowledged,
        acknowledgedAt: DateTime.now(),
        acknowledgedBy: acknowledgedBy,
        notes: notes ?? alert.notes,
      );

      // Mover para lista de alertas reconhecidos
      _activeAlerts.removeAt(alertIndex);
      _acknowledgedAlerts.add(acknowledgedAlert);
      
      _emitAlertStream();
      
      Logger.info('Alerta reconhecido: $alertId por $acknowledgedBy');
      return true;
      
    } catch (e) {
      Logger.error('Erro ao reconhecer alerta: $e');
      return false;
    }
  }

  /// Resolve um alerta (marca como resolvido)
  Future<bool> resolveAlert(
    String alertId,
    String resolvedBy,
    String? resolutionNotes,
  ) async {
    try {
      // Procurar em alertas ativos
      var alertIndex = _activeAlerts.indexWhere((a) => a.id == alertId);
      var alertList = _activeAlerts;
      
      // Se não encontrado em ativos, procurar em reconhecidos
      if (alertIndex == -1) {
        alertIndex = _acknowledgedAlerts.indexWhere((a) => a.id == alertId);
        alertList = _acknowledgedAlerts;
      }
      
      if (alertIndex == -1) {
        Logger.warning('Alerta não encontrado para resolução: $alertId');
        return false;
      }

      final alert = alertList[alertIndex];
      final resolvedAlert = alert.copyWith(
        status: AlertStatus.resolved,
        resolvedAt: DateTime.now(),
        resolvedBy: resolvedBy,
        notes: resolutionNotes ?? alert.notes,
      );

      // Mover para lista de alertas resolvidos
      alertList.removeAt(alertIndex);
      _resolvedAlerts.add(resolvedAlert);
      
      _emitAlertStream();
      
      Logger.info('Alerta resolvido: $alertId por $resolvedBy');
      return true;
      
    } catch (e) {
      Logger.error('Erro ao resolver alerta: $e');
      return false;
    }
  }

  /// Obtém alertas ativos
  List<InfestationAlert> getActiveAlerts() {
    return List.unmodifiable(_activeAlerts);
  }

  /// Obtém alertas reconhecidos
  List<InfestationAlert> getAcknowledgedAlerts() {
    return List.unmodifiable(_acknowledgedAlerts);
  }

  /// Obtém alertas resolvidos
  List<InfestationAlert> getResolvedAlerts() {
    return List.unmodifiable(_resolvedAlerts);
  }

  /// Obtém todos os alertas
  List<InfestationAlert> getAllAlerts() {
    return [
      ..._activeAlerts,
      ..._acknowledgedAlerts,
      ..._resolvedAlerts,
    ];
  }

  /// Obtém alertas por talhão
  List<InfestationAlert> getAlertsByTalhao(String talhaoId) {
    return getAllAlerts().where((a) => a.talhaoId == talhaoId).toList();
  }

  /// Obtém alertas por organismo
  List<InfestationAlert> getAlertsByOrganism(String organismoId) {
    return getAllAlerts().where((a) => a.organismoId == organismoId).toList();
  }

  /// Obtém alertas por nível de risco
  List<InfestationAlert> getAlertsByRiskLevel(String riskLevel) {
    return getAllAlerts().where((a) => a.riskLevel == riskLevel).toList();
  }

  /// Obtém estatísticas dos alertas
  Map<String, dynamic> getAlertStatistics() {
    final totalAlerts = getAllAlerts().length;
    final activeCount = _activeAlerts.length;
    final acknowledgedCount = _acknowledgedAlerts.length;
    final resolvedCount = _resolvedAlerts.length;
    
    // Contar por nível de risco
    final riskLevelCounts = <String, int>{};
    for (final alert in getAllAlerts()) {
      riskLevelCounts[alert.riskLevel] = (riskLevelCounts[alert.riskLevel] ?? 0) + 1;
    }
    
    // Calcular tempo médio de resolução
    double avgResolutionTime = 0.0;
    if (resolvedCount > 0) {
      int totalResolutionTime = 0;
      for (final alert in _resolvedAlerts) {
        if (alert.acknowledgedAt != null && alert.resolvedAt != null) {
          totalResolutionTime += alert.resolvedAt!
              .difference(alert.acknowledgedAt!)
              .inHours;
        }
      }
      avgResolutionTime = totalResolutionTime / resolvedCount;
    }
    
    return {
      'totalAlerts': totalAlerts,
      'activeCount': activeCount,
      'acknowledgedCount': acknowledgedCount,
      'resolvedCount': resolvedCount,
      'riskLevelCounts': riskLevelCounts,
      'avgResolutionTimeHours': avgResolutionTime,
      'resolutionRate': totalAlerts > 0 ? (resolvedCount / totalAlerts) * 100 : 0.0,
    };
  }

  /// Emite stream atualizado de alertas
  void _emitAlertStream() {
    if (!_alertStreamController.isClosed) {
      _alertStreamController.add(getActiveAlerts());
    }
  }

  /// Gera ID único para alerta
  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${_activeAlerts.length}';
  }

  /// Limpa alertas antigos (mais de 30 dias)
  void cleanupOldAlerts() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    _resolvedAlerts.removeWhere((alert) => 
        alert.resolvedAt != null && alert.resolvedAt!.isBefore(cutoffDate));
    
    Logger.info('Limpeza de alertas antigos concluída');
  }

  /// Resolve um alerta com opção de criar prescrição
  Future<void> resolveAlertWithPrescription({
    required String alertId,
    required String resolvedBy,
    String? resolutionNotes,
    bool createPrescription = false,
    Map<String, dynamic>? prescriptionData,
  }) async {
    try {
      final alertIndex = _acknowledgedAlerts.indexWhere((alert) => alert.id == alertId);
      
      if (alertIndex == -1) {
        Logger.warning('Alerta reconhecido não encontrado: $alertId');
        return;
      }
      
      final alert = _acknowledgedAlerts[alertIndex];
      final updatedAlert = alert.copyWith(
        status: AlertStatus.resolved,
        resolvedAt: DateTime.now(),
        resolvedBy: resolvedBy,
        notes: resolutionNotes ?? alert.notes,
      );
      
      _acknowledgedAlerts[alertIndex] = updatedAlert;
      _resolvedAlerts.add(updatedAlert);
      _acknowledgedAlerts.removeAt(alertIndex);
      
      _emitAlertStream();
      
      Logger.info('Alerta resolvido: $alertId por $resolvedBy');
      
      // Se solicitado, criar prescrição de aplicação
      if (createPrescription && prescriptionData != null) {
        try {
          await _applicationService.createPrescriptionFromAlert(
            alert: updatedAlert,
            context: prescriptionData['context'],
            recommendedProduct: prescriptionData['recommended_product'],
            recommendedDose: prescriptionData['recommended_dose'],
            applicationMethod: prescriptionData['application_method'],
            notes: prescriptionData['notes'],
          );
          
          Logger.info('✅ Prescrição criada automaticamente para alerta: $alertId');
        } catch (e) {
          Logger.error('❌ Erro ao criar prescrição: $e');
        }
      }
    } catch (e) {
      Logger.error('Erro ao resolver alerta: $e');
    }
  }
  
  /// Verifica se alerta pode gerar prescrição
  bool canCreatePrescription(String alertId) {
    final alert = _acknowledgedAlerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => InfestationAlert.empty(),
    );
    
    return _applicationService.canCreatePrescription(alert);
  }
  
  /// Obtém recomendações de aplicação para um alerta
  Map<String, dynamic> getApplicationRecommendations(String alertId) {
    final alert = _acknowledgedAlerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => InfestationAlert.empty(),
    );
    
    return _applicationService.getApplicationRecommendations(alert);
  }

  /// Dispose do stream controller
  void dispose() {
    _alertStreamController.close();
  }
}
