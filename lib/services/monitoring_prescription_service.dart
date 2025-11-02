import 'dart:convert';
import '../database/app_database.dart';
import '../services/monitoring_analysis_service.dart';
import '../services/organism_catalog_service.dart';
import '../utils/logger.dart';

/// Serviço de Integração com Prescrição para Monitoramento Avançado
/// Converte dados de monitoramento em recomendações de prescrição
class MonitoringPrescriptionService {
  static const String _tag = 'MonitoringPrescriptionService';
  final AppDatabase _database = AppDatabase();
  final MonitoringAnalysisService _analysisService = MonitoringAnalysisService();
  final OrganismCatalogService _catalogService = OrganismCatalogService();

  /// Tipos de prescrição
  enum PrescriptionType {
    preventive,
    curative,
    emergency,
    maintenance,
  }

  /// Status da prescrição
  enum PrescriptionStatus {
    draft,
    recommended,
    approved,
    applied,
    cancelled,
  }

  /// Prioridade da prescrição
  enum PrescriptionPriority {
    low,
    medium,
    high,
    urgent,
  }

  /// Prescrição baseada em monitoramento
  class MonitoringPrescription {
    final String id;
    final String sessionId;
    final String fieldId;
    final String cropId;
    final PrescriptionType type;
    final PrescriptionStatus status;
    final PrescriptionPriority priority;
    final String title;
    final String description;
    final Map<String, dynamic> recommendations;
    final List<String> organismIds;
    final Map<String, dynamic> monitoringData;
    final DateTime createdAt;
    final DateTime? appliedAt;
    final String? appliedBy;
    final Map<String, dynamic>? results;

    MonitoringPrescription({
      required this.id,
      required this.sessionId,
      required this.fieldId,
      required this.cropId,
      required this.type,
      required this.status,
      required this.priority,
      required this.title,
      required this.description,
      required this.recommendations,
      required this.organismIds,
      required this.monitoringData,
      required this.createdAt,
      this.appliedAt,
      this.appliedBy,
      this.results,
    });

    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'session_id': sessionId,
        'field_id': fieldId,
        'crop_id': cropId,
        'type': type.toString(),
        'status': status.toString(),
        'priority': priority.toString(),
        'title': title,
        'description': description,
                 'recommendations': jsonEncode(recommendations),
        'organism_ids': organismIds.join(','),
                 'monitoring_data': jsonEncode(monitoringData),
        'created_at': createdAt.toIso8601String(),
        'applied_at': appliedAt?.toIso8601String(),
        'applied_by': appliedBy,
        'results': results,
      };
    }

    factory MonitoringPrescription.fromMap(Map<String, dynamic> map) {
      return MonitoringPrescription(
        id: map['id'],
        sessionId: map['session_id'],
        fieldId: map['field_id'],
        cropId: map['crop_id'],
        type: PrescriptionType.values.firstWhere(
          (e) => e.toString() == map['type'],
        ),
        status: PrescriptionStatus.values.firstWhere(
          (e) => e.toString() == map['status'],
        ),
        priority: PrescriptionPriority.values.firstWhere(
          (e) => e.toString() == map['priority'],
        ),
        title: map['title'],
        description: map['description'],
                 recommendations: map['recommendations'] != null ? jsonDecode(map['recommendations']) : {},
        organismIds: (map['organism_ids'] as String).split(','),
                 monitoringData: map['monitoring_data'] != null ? jsonDecode(map['monitoring_data']) : {},
        createdAt: DateTime.parse(map['created_at']),
        appliedAt: map['applied_at'] != null ? DateTime.parse(map['applied_at']) : null,
        appliedBy: map['applied_by'],
                 results: map['results'] != null ? jsonDecode(map['results']) : null,
      );
    }
  }

  /// Gera prescrição baseada em sessão de monitoramento
  Future<MonitoringPrescription?> generatePrescriptionFromSession(String sessionId) async {
    Logger.info('$_tag: Gerando prescrição para sessão: $sessionId');
    
    try {
      final db = await _database.database;
      
      // Obter dados da sessão
      final sessionData = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      if (sessionData.isEmpty) {
        Logger.warning('$_tag: Sessão não encontrada: $sessionId');
        return null;
      }
      
      final session = sessionData.first;
      
      // Obter ocorrências da sessão
      final occurrences = await db.rawQuery('''
        SELECT 
          o.*,
          org.nome as organism_name,
          org.tipo as organism_type,
          org.limiar_alto,
          org.limiar_critico
        FROM monitoring_occurrences o
        INNER JOIN monitoring_points p ON o.point_id = p.id
        INNER JOIN catalog_organisms org ON o.organism_id = org.id
        WHERE p.session_id = ?
        ORDER BY o.valor_bruto DESC
      ''', [sessionId]);
      
      if (occurrences.isEmpty) {
        Logger.info('$_tag: Nenhuma ocorrência encontrada para prescrição');
        return null;
      }
      
      // Analisar dados para determinar tipo de prescrição
      final prescriptionData = await _analyzeForPrescription(occurrences, session);
      
      if (prescriptionData == null) {
        Logger.info('$_tag: Não foi necessário gerar prescrição');
        return null;
      }
      
      // Criar prescrição
      final prescription = MonitoringPrescription(
        id: 'presc_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        fieldId: session['talhao_id'],
        cropId: session['cultura_id'],
        type: prescriptionData['type'],
        status: PrescriptionStatus.recommended,
        priority: prescriptionData['priority'],
        title: prescriptionData['title'],
        description: prescriptionData['description'],
        recommendations: prescriptionData['recommendations'],
        organismIds: prescriptionData['organismIds'],
        monitoringData: prescriptionData['monitoringData'],
        createdAt: DateTime.now(),
      );
      
      // Salvar prescrição
      await _savePrescription(prescription);
      
      Logger.info('$_tag: Prescrição gerada: ${prescription.title}');
      return prescription;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar prescrição: $e');
      return null;
    }
  }

  /// Analisa dados para determinar prescrição
  Future<Map<String, dynamic>?> _analyzeForPrescription(
    List<Map<String, dynamic>> occurrences,
    Map<String, dynamic> session,
  ) async {
    final criticalOrganisms = <String, Map<String, dynamic>>{};
    final highInfestationOrganisms = <String, Map<String, dynamic>>{};
    final moderateInfestationOrganisms = <String, Map<String, dynamic>>{};
    
    // Classificar organismos por nível de infestação
    for (final occurrence in occurrences) {
      final organismId = occurrence['organism_id'] as String;
      final valorBruto = occurrence['valor_bruto'] as double;
      final limiarAlto = occurrence['limiar_alto'] as double;
      final limiarCritico = occurrence['limiar_critico'] as double;
      
      if (valorBruto > limiarCritico) {
        criticalOrganisms[organismId] = occurrence;
      } else if (valorBruto > limiarAlto) {
        highInfestationOrganisms[organismId] = occurrence;
      } else if (valorBruto > limiarAlto * 0.5) {
        moderateInfestationOrganisms[organismId] = occurrence;
      }
    }
    
    // Determinar tipo de prescrição baseado na análise
    if (criticalOrganisms.isNotEmpty) {
      return await _generateEmergencyPrescription(criticalOrganisms, session);
    } else if (highInfestationOrganisms.isNotEmpty) {
      return await _generateCurativePrescription(highInfestationOrganisms, session);
    } else if (moderateInfestationOrganisms.isNotEmpty) {
      return await _generatePreventivePrescription(moderateInfestationOrganisms, session);
    }
    
    return null;
  }

  /// Gera prescrição de emergência
  Future<Map<String, dynamic>> _generateEmergencyPrescription(
    Map<String, Map<String, dynamic>> criticalOrganisms,
    Map<String, dynamic> session,
  ) async {
    final organismNames = criticalOrganisms.values.map((o) => o['organism_name']).join(', ');
    
    return {
      'type': PrescriptionType.emergency,
      'priority': PrescriptionPriority.urgent,
      'title': 'Prescrição de Emergência - Infestação Crítica',
      'description': 'Infestação crítica detectada: $organismNames. Ação imediata necessária.',
      'recommendations': {
        'action_required': 'immediate',
        'treatment_type': 'emergency_chemical',
        'application_method': 'spray',
        'coverage': 'full_field',
        'timing': 'within_24h',
        'organisms': criticalOrganisms.keys.toList(),
        'dosage_recommendations': await _getDosageRecommendations(criticalOrganisms),
        'safety_measures': [
          'Usar EPI completo',
          'Respeitar período de carência',
          'Monitorar condições climáticas',
          'Aplicar em horário adequado',
        ],
      },
      'organismIds': criticalOrganisms.keys.toList(),
      'monitoringData': {
        'session_id': session['id'],
        'field_id': session['talhao_id'],
        'critical_organisms': criticalOrganisms,
        'analysis_date': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Gera prescrição curativa
  Future<Map<String, dynamic>> _generateCurativePrescription(
    Map<String, Map<String, dynamic>> highInfestationOrganisms,
    Map<String, dynamic> session,
  ) async {
    final organismNames = highInfestationOrganisms.values.map((o) => o['organism_name']).join(', ');
    
    return {
      'type': PrescriptionType.curative,
      'priority': PrescriptionPriority.high,
      'title': 'Prescrição Curativa - Infestação Alta',
      'description': 'Infestação alta detectada: $organismNames. Tratamento curativo recomendado.',
      'recommendations': {
        'action_required': 'within_48h',
        'treatment_type': 'curative_chemical',
        'application_method': 'spray',
        'coverage': 'targeted_areas',
        'timing': 'within_48h',
        'organisms': highInfestationOrganisms.keys.toList(),
        'dosage_recommendations': await _getDosageRecommendations(highInfestationOrganisms),
        'monitoring_plan': [
          'Reavaliar em 7 dias',
          'Monitorar eficácia do tratamento',
          'Ajustar dose se necessário',
        ],
      },
      'organismIds': highInfestationOrganisms.keys.toList(),
      'monitoringData': {
        'session_id': session['id'],
        'field_id': session['talhao_id'],
        'high_infestation_organisms': highInfestationOrganisms,
        'analysis_date': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Gera prescrição preventiva
  Future<Map<String, dynamic>> _generatePreventivePrescription(
    Map<String, Map<String, dynamic>> moderateInfestationOrganisms,
    Map<String, dynamic> session,
  ) async {
    final organismNames = moderateInfestationOrganisms.values.map((o) => o['organism_name']).join(', ');
    
    return {
      'type': PrescriptionType.preventive,
      'priority': PrescriptionPriority.medium,
      'title': 'Prescrição Preventiva - Monitoramento',
      'description': 'Infestação moderada detectada: $organismNames. Ação preventiva recomendada.',
      'recommendations': {
        'action_required': 'within_week',
        'treatment_type': 'preventive_biological',
        'application_method': 'spray_or_granular',
        'coverage': 'selective',
        'timing': 'within_week',
        'organisms': moderateInfestationOrganisms.keys.toList(),
        'dosage_recommendations': await _getDosageRecommendations(moderateInfestationOrganisms),
        'preventive_measures': [
          'Aplicar produto preventivo',
          'Monitorar desenvolvimento',
          'Avaliar necessidade de reforço',
          'Manter registro de aplicações',
        ],
      },
      'organismIds': moderateInfestationOrganisms.keys.toList(),
      'monitoringData': {
        'session_id': session['id'],
        'field_id': session['talhao_id'],
        'moderate_infestation_organisms': moderateInfestationOrganisms,
        'analysis_date': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Obtém recomendações de dosagem
  Future<Map<String, dynamic>> _getDosageRecommendations(
    Map<String, Map<String, dynamic>> organisms,
  ) async {
    final recommendations = <String, Map<String, dynamic>>{};
    
    for (final entry in organisms.entries) {
      final organismId = entry.key;
      final organism = entry.value;
      final organismData = await _catalogService.getOrganismById(organismId);
      
      if (organismData != null) {
        final valorBruto = organism['valor_bruto'] as double;
        final limiarAlto = organism['limiar_alto'] as double;
        final limiarCritico = organism['limiar_critico'] as double;
        
        // Calcular dose baseada no nível de infestação
        double doseMultiplier = 1.0;
        if (valorBruto > limiarCritico) {
          doseMultiplier = 1.5; // Dose aumentada para infestação crítica
        } else if (valorBruto > limiarAlto) {
          doseMultiplier = 1.2; // Dose moderadamente aumentada
        }
        
        recommendations[organismId] = {
          'organism_name': organismData.nome,
          'organism_type': organismData.tipo,
          'infestation_level': valorBruto > limiarCritico ? 'critical' : 'high',
          'recommended_dose': 'Base dose × ${doseMultiplier.toStringAsFixed(1)}',
          'application_frequency': valorBruto > limiarCritico ? 'immediate + 7 days' : 'single',
          'product_type': _getRecommendedProductType(organismData.tipo, valorBruto, limiarCritico),
          'notes': _getDosageNotes(organismData.tipo, valorBruto),
        };
      }
    }
    
    return recommendations;
  }

  /// Obtém tipo de produto recomendado
  String _getRecommendedProductType(String organismType, double valorBruto, double limiarCritico) {
    if (valorBruto > limiarCritico) {
      switch (organismType) {
        case 'praga':
          return 'inseticida_sistêmico';
        case 'doenca':
          return 'fungicida_curativo';
        case 'daninha':
          return 'herbicida_pós_emergente';
        default:
          return 'produto_químico';
      }
    } else {
      switch (organismType) {
        case 'praga':
          return 'inseticida_contato';
        case 'doenca':
          return 'fungicida_preventivo';
        case 'daninha':
          return 'herbicida_pré_emergente';
        default:
          return 'produto_biológico';
      }
    }
  }

  /// Obtém notas de dosagem
  String _getDosageNotes(String organismType, double valorBruto) {
    if (valorBruto > 10) {
      return 'Dose máxima recomendada. Monitorar eficácia.';
    } else if (valorBruto > 5) {
      return 'Dose padrão. Reavaliar em 7 dias.';
    } else {
      return 'Dose preventiva. Manter monitoramento.';
    }
  }

  /// Salva prescrição no banco
  Future<void> _savePrescription(MonitoringPrescription prescription) async {
    final db = await _database.database;
    
    await db.insert('monitoring_prescriptions', prescription.toMap());
  }

  /// Obtém prescrições por campo
  Future<List<MonitoringPrescription>> getPrescriptionsByField(String fieldId) async {
    final db = await _database.database;
    
    final prescriptions = await db.query(
      'monitoring_prescriptions',
      where: 'field_id = ?',
      whereArgs: [fieldId],
      orderBy: 'created_at DESC',
    );
    
    return prescriptions.map((p) => MonitoringPrescription.fromMap(p)).toList();
  }

  /// Obtém prescrições por status
  Future<List<MonitoringPrescription>> getPrescriptionsByStatus(PrescriptionStatus status) async {
    final db = await _database.database;
    
    final prescriptions = await db.query(
      'monitoring_prescriptions',
      where: 'status = ?',
      whereArgs: [status.toString()],
      orderBy: 'created_at DESC',
    );
    
    return prescriptions.map((p) => MonitoringPrescription.fromMap(p)).toList();
  }

  /// Aprova uma prescrição
  Future<void> approvePrescription(String prescriptionId, String approvedBy) async {
    final db = await _database.database;
    
    await db.update(
      'monitoring_prescriptions',
      {
        'status': PrescriptionStatus.approved.toString(),
        'applied_by': approvedBy,
        'applied_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [prescriptionId],
    );
    
    Logger.info('$_tag: Prescrição aprovada: $prescriptionId');
  }

  /// Aplica uma prescrição
  Future<void> applyPrescription(String prescriptionId, String appliedBy, Map<String, dynamic> results) async {
    final db = await _database.database;
    
    await db.update(
      'monitoring_prescriptions',
      {
        'status': PrescriptionStatus.applied.toString(),
        'applied_by': appliedBy,
        'applied_at': DateTime.now().toIso8601String(),
        'results': results,
      },
      where: 'id = ?',
      whereArgs: [prescriptionId],
    );
    
    Logger.info('$_tag: Prescrição aplicada: $prescriptionId');
  }

  /// Cancela uma prescrição
  Future<void> cancelPrescription(String prescriptionId, String reason) async {
    final db = await _database.database;
    
    await db.update(
      'monitoring_prescriptions',
      {
        'status': PrescriptionStatus.cancelled.toString(),
        'results': {'cancellation_reason': reason},
      },
      where: 'id = ?',
      whereArgs: [prescriptionId],
    );
    
    Logger.info('$_tag: Prescrição cancelada: $prescriptionId');
  }

  /// Obtém estatísticas de prescrições
  Future<Map<String, dynamic>> getPrescriptionStats() async {
    final db = await _database.database;
    
    final stats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'recommended' THEN 1 ELSE 0 END) as recommended,
        SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved,
        SUM(CASE WHEN status = 'applied' THEN 1 ELSE 0 END) as applied,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled,
        SUM(CASE WHEN type = 'emergency' THEN 1 ELSE 0 END) as emergency,
        SUM(CASE WHEN type = 'curative' THEN 1 ELSE 0 END) as curative,
        SUM(CASE WHEN type = 'preventive' THEN 1 ELSE 0 END) as preventive
      FROM monitoring_prescriptions
      WHERE created_at >= ?
    ''', [DateTime.now().subtract(const Duration(days: 30)).toIso8601String()]);
    
    return stats.first;
  }

  /// Gera relatório de prescrições
  Future<Map<String, dynamic>> generatePrescriptionReport({
    DateTime? startDate,
    DateTime? endDate,
    String? fieldId,
    PrescriptionType? type,
  }) async {
    final db = await _database.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (fieldId != null) {
      whereClause += ' AND field_id = ?';
      whereArgs.add(fieldId);
    }
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.toString());
    }
    
    final prescriptions = await db.query(
      'monitoring_prescriptions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    final prescriptionsList = prescriptions.map((p) => MonitoringPrescription.fromMap(p)).toList();
    
    return {
      'prescriptions': prescriptionsList,
      'total': prescriptionsList.length,
      'period': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
      'field_id': fieldId,
      'type': type?.toString(),
    };
  }
}
