/// 🚨 SISTEMA DE ALERTAS E RECOMENDAÇÕES AGRONÔMICAS AUTOMÁTICAS
/// 
/// Sistema inteligente que monitora continuamente os dados de germinação
/// e gera alertas automáticos e recomendações baseadas em:
/// - Normas internacionais (ISTA, AOSA, RAS)
/// - Machine Learning e análise preditiva
/// - Conhecimento agronômico especializado
/// - Condições ambientais e sazonais

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../screens/plantio/submods/germination_test/models/germination_test_model.dart';
import 'agronomic_calculation_engine.dart';

/// 🚨 SISTEMA PRINCIPAL DE ALERTAS
class AgronomicAlertSystem {
  static final AgronomicAlertSystem _instance = AgronomicAlertSystem._internal();
  factory AgronomicAlertSystem() => _instance;
  AgronomicAlertSystem._internal();
  
  // Streams de alertas por teste
  final Map<int, StreamController<AgronomicAlert>> _alertStreams = {};
  final Map<int, Timer> _monitoringTimers = {};
  
  // Configurações de alertas
  final Map<String, AlertThreshold> _thresholds = _initializeThresholds();
  
  /// 🔄 Inicia monitoramento automático de alertas
  Stream<AgronomicAlert> startMonitoring({
    required int testId,
    required List<GerminationDailyRecord> dailyRecords,
    required int totalSeeds,
    required String culture,
    required String variety,
    Duration checkInterval = const Duration(hours: 1),
  }) {
    // Parar monitoramento anterior se existir
    stopMonitoring(testId);
    
    // Criar stream controller
    final controller = StreamController<AgronomicAlert>.broadcast();
    _alertStreams[testId] = controller;
    
    // Verificação inicial
    _checkForAlerts(testId, dailyRecords, totalSeeds, culture, variety, controller);
    
    // Configurar timer para verificações periódicas
    _monitoringTimers[testId] = Timer.periodic(checkInterval, (timer) {
      _checkForAlerts(testId, dailyRecords, totalSeeds, culture, variety, controller);
    });
    
    return controller.stream;
  }
  
  /// ⏹️ Para monitoramento
  void stopMonitoring(int testId) {
    _monitoringTimers[testId]?.cancel();
    _monitoringTimers.remove(testId);
    _alertStreams[testId]?.close();
    _alertStreams.remove(testId);
  }
  
  /// 🔍 Verifica alertas para um teste específico
  void _checkForAlerts(
    int testId,
    List<GerminationDailyRecord> dailyRecords,
    int totalSeeds,
    String culture,
    String variety,
    StreamController<AgronomicAlert> controller,
  ) {
    try {
      // Calcular resultados agronômicos
      final results = AgronomicCalculationEngine.calculateCompleteResults(
        dailyRecords: dailyRecords,
        totalSeeds: totalSeeds,
        culture: culture,
        variety: variety,
        testStartDate: dailyRecords.isNotEmpty ? dailyRecords.first.recordDate : DateTime.now(),
      );
      
      // Verificar alertas baseados em resultados
      final alerts = _generateAlerts(results, dailyRecords, culture, variety);
      
      // Enviar alertas para stream
      for (final alert in alerts) {
        if (!controller.isClosed) {
          controller.add(alert);
        }
      }
      
    } catch (e) {
      print('❌ Erro no sistema de alertas: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  /// 🚨 Gera alertas baseados em resultados e dados
  List<AgronomicAlert> _generateAlerts(
    AgronomicResults results,
    List<GerminationDailyRecord> dailyRecords,
    String culture,
    String variety,
  ) {
    final alerts = <AgronomicAlert>[];
    
    // Alertas de germinação
    alerts.addAll(_checkGerminationAlerts(results, dailyRecords));
    
    // Alertas de vigor
    alerts.addAll(_checkVigorAlerts(results, dailyRecords));
    
    // Alertas de pureza
    alerts.addAll(_checkPurityAlerts(results));
    
    // Alertas de contaminação
    alerts.addAll(_checkContaminationAlerts(results, dailyRecords));
    
    // Alertas de tendências
    alerts.addAll(_checkTrendAlerts(dailyRecords));
    
    // Alertas específicos por cultura
    alerts.addAll(_checkCultureSpecificAlerts(results, culture, variety));
    
    // Alertas de conformidade
    alerts.addAll(_checkComplianceAlerts(results));
    
    // Alertas de tempo
    alerts.addAll(_checkTimeAlerts(dailyRecords, results));
    
    return alerts;
  }
  
  /// 🌱 Alertas de Germinação
  List<AgronomicAlert> _checkGerminationAlerts(
    AgronomicResults results,
    List<GerminationDailyRecord> dailyRecords,
  ) {
    final alerts = <AgronomicAlert>[];
    
    // Germinação crítica
    if (results.germinationPercentage < _thresholds['germination_critical']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.critical,
        title: 'Germinação Crítica',
        message: 'Germinação de ${results.germinationPercentage.toStringAsFixed(1)}% está abaixo do limite crítico de ${_thresholds['germination_critical']!.value}%',
        action: 'Sementes não recomendadas para plantio. Verificar qualidade do lote.',
        severity: AlertSeverity.critical,
        category: AlertCategory.germination,
        timestamp: DateTime.now(),
        testId: 0, // Será definido pelo sistema
        recommendations: [
          'Verificar condições de armazenamento das sementes',
          'Considerar troca de lote',
          'Aplicar tratamento de sementes se necessário',
        ],
      ));
    }
    
    // Germinação baixa
    else if (results.germinationPercentage < _thresholds['germination_low']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Germinação Baixa',
        message: 'Germinação de ${results.germinationPercentage.toStringAsFixed(1)}% está abaixo do ideal',
        action: 'Monitorar de perto e considerar ajustes nas condições',
        severity: AlertSeverity.medium,
        category: AlertCategory.germination,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Verificar temperatura e umidade',
          'Ajustar densidade de plantio',
          'Considerar tratamento de sementes',
        ],
      ));
    }
    
    // Germinação excelente
    else if (results.germinationPercentage >= _thresholds['germination_excellent']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.info,
        title: 'Excelente Germinação',
        message: 'Germinação de ${results.germinationPercentage.toStringAsFixed(1)}% está excelente',
        action: 'Sementes aprovadas para plantio em condições ideais',
        severity: AlertSeverity.low,
        category: AlertCategory.germination,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Manter condições atuais',
          'Sementes ideais para plantio direto',
          'Pode reduzir densidade de plantio em 10%',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// ⚡ Alertas de Vigor
  List<AgronomicAlert> _checkVigorAlerts(
    AgronomicResults results,
    List<GerminationDailyRecord> dailyRecords,
  ) {
    final alerts = <AgronomicAlert>[];
    
    // Vigor crítico
    if (results.vigorIndex < _thresholds['vigor_critical']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.critical,
        title: 'Vigor Crítico',
        message: 'Vigor de ${results.vigorIndex.toStringAsFixed(1)}% indica sementes de baixa qualidade',
        action: 'Risco alto de estabelecimento inadequado no campo',
        severity: AlertSeverity.critical,
        category: AlertCategory.vigor,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Aplicar tratamento de sementes obrigatório',
          'Plantar em condições ideais de solo',
          'Considerar troca de lote',
        ],
      ));
    }
    
    // Vigor baixo
    else if (results.vigorIndex < _thresholds['vigor_low']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Vigor Baixo',
        message: 'Vigor de ${results.vigorIndex.toStringAsFixed(1)}% pode comprometer o estabelecimento',
        action: 'Aplicar medidas para melhorar o vigor',
        severity: AlertSeverity.medium,
        category: AlertCategory.vigor,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Aplicar tratamento de sementes',
          'Plantar em solo bem preparado',
          'Evitar condições adversas',
        ],
      ));
    }
    
    // Vigor excelente
    else if (results.vigorIndex >= _thresholds['vigor_excellent']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.info,
        title: 'Alto Vigor',
        message: 'Vigor de ${results.vigorIndex.toStringAsFixed(1)}% indica sementes de alta qualidade',
        action: 'Sementes ideais para condições adversas',
        severity: AlertSeverity.low,
        category: AlertCategory.vigor,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Sementes resistentes a estresse',
          'Ideal para plantio direto',
          'Pode tolerar condições subótimas',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// 🧹 Alertas de Pureza
  List<AgronomicAlert> _checkPurityAlerts(AgronomicResults results) {
    final alerts = <AgronomicAlert>[];
    
    // Pureza insuficiente
    if (results.purityPercentage < _thresholds['purity_minimum']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Pureza Insuficiente',
        message: 'Pureza de ${results.purityPercentage.toStringAsFixed(1)}% está abaixo do mínimo aceitável',
        action: 'Necessário beneficiamento das sementes',
        severity: AlertSeverity.medium,
        category: AlertCategory.purity,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Realizar beneficiamento das sementes',
          'Remover impurezas e sementes danificadas',
          'Verificar processo de colheita',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// 🦠 Alertas de Contaminação
  List<AgronomicAlert> _checkContaminationAlerts(
    AgronomicResults results,
    List<GerminationDailyRecord> dailyRecords,
  ) {
    final alerts = <AgronomicAlert>[];
    
    // Contaminação alta
    if (results.contaminationPercentage > _thresholds['contamination_high']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.critical,
        title: 'Alta Contaminação',
        message: 'Contaminação de ${results.contaminationPercentage.toStringAsFixed(1)}% representa risco de doenças',
        action: 'Tratamento fungicida obrigatório',
        severity: AlertSeverity.critical,
        category: AlertCategory.contamination,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Aplicar tratamento fungicida nas sementes',
          'Melhorar ventilação e condições de armazenamento',
          'Verificar qualidade do lote',
        ],
      ));
    }
    
    // Contaminação moderada
    else if (results.contaminationPercentage > _thresholds['contamination_moderate']!.value) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Contaminação Moderada',
        message: 'Contaminação de ${results.contaminationPercentage.toStringAsFixed(1)}% requer atenção',
        action: 'Considerar tratamento preventivo',
        severity: AlertSeverity.medium,
        category: AlertCategory.contamination,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Aplicar tratamento preventivo',
          'Monitorar condições de armazenamento',
          'Verificar ventilação',
        ],
      ));
    }
    
    // Detectar tendência crescente de contaminação
    if (dailyRecords.length >= 3) {
      final recentContamination = dailyRecords
          .sublist(dailyRecords.length - 3)
          .map((r) => r.diseasedFungi.toDouble())
          .toList()
          .cast<double>();
      
      final trend = _calculateTrend(recentContamination);
      if (trend > 1.0) {
        alerts.add(AgronomicAlert(
          type: AlertType.warning,
          title: 'Contaminação Crescente',
          message: 'Tendência crescente de contaminação detectada',
          action: 'Investigar causas e aplicar medidas preventivas',
          severity: AlertSeverity.medium,
          category: AlertCategory.contamination,
          timestamp: DateTime.now(),
          testId: 0,
          recommendations: [
            'Investigar causas da contaminação',
            'Aplicar medidas preventivas',
            'Melhorar condições ambientais',
          ],
        ));
      }
    }
    
    return alerts;
  }
  
  /// 📈 Alertas de Tendências
  List<AgronomicAlert> _checkTrendAlerts(List<GerminationDailyRecord> dailyRecords) {
    final alerts = <AgronomicAlert>[];
    
    if (dailyRecords.length < 3) return alerts;
    
    // Calcular tendência de germinação
    final germinationTrend = _calculateTrend(
      dailyRecords.map((r) => r.normalGerminated.toDouble()).toList().cast<double>()
    );
    
    // Desaceleração crítica
    if (germinationTrend < -2.0) {
      alerts.add(AgronomicAlert(
        type: AlertType.critical,
        title: 'Desaceleração Crítica',
        message: 'Germinação desacelerando rapidamente',
        action: 'Investigar causas imediatamente',
        severity: AlertSeverity.critical,
        category: AlertCategory.trend,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Verificar temperatura e umidade',
          'Investigar problemas de qualidade',
          'Considerar ajustes nas condições',
        ],
      ));
    }
    
    // Desaceleração moderada
    else if (germinationTrend < -1.0) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Desaceleração Moderada',
        message: 'Germinação desacelerando',
        action: 'Monitorar de perto',
        severity: AlertSeverity.medium,
        category: AlertCategory.trend,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Verificar condições ambientais',
          'Monitorar qualidade das sementes',
          'Ajustar se necessário',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// 🌾 Alertas Específicos por Cultura
  List<AgronomicAlert> _checkCultureSpecificAlerts(
    AgronomicResults results,
    String culture,
    String variety,
  ) {
    final alerts = <AgronomicAlert>[];
    
    switch (culture.toLowerCase()) {
      case 'soja':
        alerts.addAll(_checkSoybeanAlerts(results, variety));
        break;
      case 'milho':
        alerts.addAll(_checkCornAlerts(results, variety));
        break;
      case 'algodão':
        alerts.addAll(_checkCottonAlerts(results, variety));
        break;
      case 'trigo':
        alerts.addAll(_checkWheatAlerts(results, variety));
        break;
    }
    
    return alerts;
  }
  
  /// 🌱 Alertas específicos para Soja
  List<AgronomicAlert> _checkSoybeanAlerts(AgronomicResults results, String variety) {
    final alerts = <AgronomicAlert>[];
    
    // Soja com germinação alta pode reduzir densidade
    if (results.germinationPercentage >= 90) {
      alerts.add(AgronomicAlert(
        type: AlertType.info,
        title: 'Otimização de Plantio - Soja',
        message: 'Alta germinação permite redução da densidade de plantio',
        action: 'Reduzir densidade em 10-15% para otimizar custos',
        severity: AlertSeverity.low,
        category: AlertCategory.optimization,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Densidade recomendada: 12-15 plantas/m²',
          'Espaçamento entre linhas: 45-50 cm',
          'Monitorar população final',
        ],
      ));
    }
    
    // Vigor baixo em soja é crítico
    if (results.vigorIndex < 70) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Vigor Baixo - Soja',
        message: 'Vigor baixo pode comprometer nodulação e fixação de N',
        action: 'Aplicar inoculante e tratamento de sementes',
        severity: AlertSeverity.medium,
        category: AlertCategory.culture_specific,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Aplicar inoculante de Bradyrhizobium',
          'Tratamento de sementes com fungicida',
          'Plantar em solo bem preparado',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// 🌽 Alertas específicos para Milho
  List<AgronomicAlert> _checkCornAlerts(AgronomicResults results, String variety) {
    final alerts = <AgronomicAlert>[];
    
    // Milho com vigor alto é ideal para plantio direto
    if (results.vigorIndex >= 80) {
      alerts.add(AgronomicAlert(
        type: AlertType.info,
        title: 'Plantio Direto - Milho',
        message: 'Alto vigor ideal para plantio direto',
        action: 'Recomendado plantio direto para preservar vigor',
        severity: AlertSeverity.low,
        category: AlertCategory.optimization,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Plantio direto recomendado',
          'Densidade: 50-60 mil plantas/ha',
          'Espaçamento: 45-50 cm entre linhas',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// 🌿 Alertas específicos para Algodão
  List<AgronomicAlert> _checkCottonAlerts(AgronomicResults results, String variety) {
    final alerts = <AgronomicAlert>[];
    
    // Algodão com pureza alta está pronto para deslintamento
    if (results.purityPercentage >= 95) {
      alerts.add(AgronomicAlert(
        type: AlertType.info,
        title: 'Deslintamento - Algodão',
        message: 'Alta pureza indica sementes prontas para deslintamento',
        action: 'Processar para deslintamento',
        severity: AlertSeverity.low,
        category: AlertCategory.processing,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Iniciar processo de deslintamento',
          'Verificar equipamentos',
          'Monitorar qualidade do processo',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// 🌾 Alertas específicos para Trigo
  List<AgronomicAlert> _checkWheatAlerts(AgronomicResults results, String variety) {
    final alerts = <AgronomicAlert>[];
    
    // Trigo com germinação baixa é crítico
    if (results.germinationPercentage < 85) {
      alerts.add(AgronomicAlert(
        type: AlertType.critical,
        title: 'Germinação Baixa - Trigo',
        message: 'Trigo com germinação baixa compromete produtividade',
        action: 'Verificar qualidade e considerar troca de lote',
        severity: AlertSeverity.critical,
        category: AlertCategory.culture_specific,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Verificar qualidade do lote',
          'Considerar troca de sementes',
          'Aplicar tratamento de sementes',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// ✅ Alertas de Conformidade
  List<AgronomicAlert> _checkComplianceAlerts(AgronomicResults results) {
    final alerts = <AgronomicAlert>[];
    
    // Não conformidade com ISTA
    if (!results.istaCompliant) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Não Conformidade ISTA',
        message: 'Resultados não atendem aos padrões ISTA',
        action: 'Verificar critérios de qualidade',
        severity: AlertSeverity.medium,
        category: AlertCategory.compliance,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Revisar critérios ISTA',
          'Melhorar qualidade das sementes',
          'Documentar não conformidades',
        ],
      ));
    }
    
    // Não conformidade com RAS
    if (!results.rasCompliant) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Não Conformidade RAS',
        message: 'Resultados não atendem aos padrões RAS (Brasil)',
        action: 'Verificar critérios nacionais',
        severity: AlertSeverity.medium,
        category: AlertCategory.compliance,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Revisar critérios RAS',
          'Ajustar para padrões nacionais',
          'Documentar adequações necessárias',
        ],
      ));
    }
    
    return alerts;
  }
  
  /// ⏰ Alertas de Tempo
  List<AgronomicAlert> _checkTimeAlerts(
    List<GerminationDailyRecord> dailyRecords,
    AgronomicResults results,
  ) {
    final alerts = <AgronomicAlert>[];
    
    if (dailyRecords.isEmpty) return alerts;
    
    final testDuration = results.testDuration;
    final lastRecord = dailyRecords.last;
    final daysSinceLastRecord = DateTime.now().difference(lastRecord.recordDate).inDays;
    
    // Teste muito longo
    if (testDuration > 14) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Teste Muito Longo',
        message: 'Teste com ${testDuration} dias pode estar comprometido',
        action: 'Considerar finalizar o teste',
        severity: AlertSeverity.medium,
        category: AlertCategory.timing,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Avaliar necessidade de continuar',
          'Considerar finalizar o teste',
          'Documentar justificativa',
        ],
      ));
    }
    
    // Sem registros recentes
    if (daysSinceLastRecord > 2) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Registros Atrasados',
        message: 'Último registro há ${daysSinceLastRecord} dias',
        action: 'Atualizar registros diários',
        severity: AlertSeverity.medium,
        category: AlertCategory.timing,
        timestamp: DateTime.now(),
        testId: 0,
        recommendations: [
          'Registrar dados diários',
          'Manter consistência no monitoramento',
          'Atualizar sistema regularmente',
        ],
      ));
    }
    
    return alerts;
  }
  
  // === MÉTODOS AUXILIARES ===
  
  /// 📊 Calcula tendência de uma série de valores
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final sumX = (n * (n - 1)) / 2; // Soma de 0 a n-1
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = values.asMap().entries.map((e) => e.key * e.value).reduce((a, b) => a + b);
    final sumXX = (n * (n - 1) * (2 * n - 1)) / 6; // Soma dos quadrados
    
    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }
  
  /// ⚙️ Inicializa thresholds de alertas
  static Map<String, AlertThreshold> _initializeThresholds() {
    return {
      // Germinação
      'germination_critical': AlertThreshold(70.0, 'Germinação crítica'),
      'germination_low': AlertThreshold(80.0, 'Germinação baixa'),
      'germination_excellent': AlertThreshold(95.0, 'Germinação excelente'),
      
      // Vigor
      'vigor_critical': AlertThreshold(50.0, 'Vigor crítico'),
      'vigor_low': AlertThreshold(70.0, 'Vigor baixo'),
      'vigor_excellent': AlertThreshold(90.0, 'Vigor excelente'),
      
      // Pureza
      'purity_minimum': AlertThreshold(85.0, 'Pureza mínima'),
      
      // Contaminação
      'contamination_moderate': AlertThreshold(5.0, 'Contaminação moderada'),
      'contamination_high': AlertThreshold(10.0, 'Contaminação alta'),
    };
  }
}

/// 🚨 ALERTA AGRONÔMICO COMPLETO
class AgronomicAlert {
  final AlertType type;
  final String title;
  final String message;
  final String action;
  final AlertSeverity severity;
  final AlertCategory category;
  final DateTime timestamp;
  final int testId;
  final List<String> recommendations;
  final Map<String, dynamic>? metadata;
  
  AgronomicAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.action,
    required this.severity,
    required this.category,
    required this.timestamp,
    required this.testId,
    required this.recommendations,
    this.metadata,
  });
  
  /// 🎯 Verifica se o alerta é crítico
  bool get isCritical => severity == AlertSeverity.critical;
  
  /// ⚠️ Verifica se o alerta requer ação imediata
  bool get requiresImmediateAction => 
      severity == AlertSeverity.critical || severity == AlertSeverity.high;
  
  /// 📊 Retorna cor baseada na severidade
  Color get severityColor {
    switch (severity) {
      case AlertSeverity.low: return Colors.blue;
      case AlertSeverity.medium: return Colors.orange;
      case AlertSeverity.high: return Colors.red;
      case AlertSeverity.critical: return Colors.purple;
    }
  }
  
  /// 🎨 Retorna ícone baseado no tipo
  IconData get typeIcon {
    switch (type) {
      case AlertType.info: return Icons.info;
      case AlertType.warning: return Icons.warning;
      case AlertType.critical: return Icons.error;
    }
  }
}

/// ⚙️ THRESHOLD DE ALERTA
class AlertThreshold {
  final double value;
  final String description;
  
  AlertThreshold(this.value, this.description);
}

// === ENUMS ===

enum AlertType { info, warning, critical }
enum AlertSeverity { low, medium, high, critical }
enum AlertCategory {
  germination,
  vigor,
  purity,
  contamination,
  trend,
  culture_specific,
  compliance,
  timing,
  optimization,
  processing,
}
