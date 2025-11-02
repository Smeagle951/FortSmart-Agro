import 'package:uuid/uuid.dart';

/// Modelo para armazenar feedback do usuário sobre diagnósticos e infestações
/// Usado para aprendizado contínuo e melhoria da precisão do sistema
class DiagnosisFeedback {
  final String id;
  final String farmId; // ID da fazenda
  final String? diagnosisId; // ID do diagnóstico original (se aplicável)
  final String? monitoringId; // ID do monitoramento (se aplicável)
  final String? alertId; // ID do alerta (se aplicável)
  final String cropName; // Cultura (soja, milho, etc.)
  final String? imagePath; // Caminho da imagem (se houver)
  
  // Predição/Diagnóstico Original do Sistema
  final String systemPredictedOrganism; // O que o sistema previu
  final double systemPredictedSeverity; // Severidade prevista (0-100%)
  final String systemSeverityLevel; // Nível: baixo, moderado, alto, crítico
  final double? systemConfidence; // Confiança do sistema (0-1)
  final List<String> systemSymptoms; // Sintomas detectados pelo sistema
  
  // Feedback do Usuário
  final bool userConfirmed; // Usuário confirmou diagnóstico?
  final String? userCorrectedOrganism; // Organismo correto (se diferente)
  final double? userCorrectedSeverity; // Severidade real (0-100%)
  final String? userCorrectedSeverityLevel; // Nível correto
  final List<String>? userCorrectedSymptoms; // Sintomas corretos
  final String? userNotes; // Observações do usuário
  final String? userCorrectionReason; // Por que estava errado?
  
  // Metadados
  final DateTime diagnosisDate; // Data do diagnóstico original
  final DateTime feedbackDate; // Data do feedback do usuário
  final String technicianName; // Nome do técnico que deu feedback
  final Map<String, dynamic>? environmentalData; // Clima, solo, etc.
  final double? latitude; // Coordenada GPS
  final double? longitude; // Coordenada GPS
  
  // Resultado Real (Follow-up)
  final String? realOutcome; // Resultado após tratamento
  final DateTime? outcomeDate; // Data do resultado
  final double? treatmentEfficacy; // Eficácia do tratamento (0-100%)
  final String? treatmentApplied; // Qual tratamento foi aplicado
  final String? outcomeNotes; // Observações sobre resultado
  
  // Sincronização
  final bool syncedToCloud; // Sincronizado com servidor
  final DateTime? syncedAt; // Data da sincronização
  
  // Auditoria
  final DateTime createdAt;
  final DateTime updatedAt;

  DiagnosisFeedback({
    String? id,
    required this.farmId,
    this.diagnosisId,
    this.monitoringId,
    this.alertId,
    required this.cropName,
    this.imagePath,
    required this.systemPredictedOrganism,
    required this.systemPredictedSeverity,
    required this.systemSeverityLevel,
    this.systemConfidence,
    required this.systemSymptoms,
    required this.userConfirmed,
    this.userCorrectedOrganism,
    this.userCorrectedSeverity,
    this.userCorrectedSeverityLevel,
    this.userCorrectedSymptoms,
    this.userNotes,
    this.userCorrectionReason,
    required this.diagnosisDate,
    required this.feedbackDate,
    required this.technicianName,
    this.environmentalData,
    this.latitude,
    this.longitude,
    this.realOutcome,
    this.outcomeDate,
    this.treatmentEfficacy,
    this.treatmentApplied,
    this.outcomeNotes,
    this.syncedToCloud = false,
    this.syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Converte para Map para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farm_id': farmId,
      'diagnosis_id': diagnosisId,
      'monitoring_id': monitoringId,
      'alert_id': alertId,
      'crop_name': cropName,
      'image_path': imagePath,
      
      // Predição do sistema
      'system_predicted_organism': systemPredictedOrganism,
      'system_predicted_severity': systemPredictedSeverity,
      'system_severity_level': systemSeverityLevel,
      'system_confidence': systemConfidence,
      'system_symptoms': systemSymptoms.join('|'), // Separado por pipe
      
      // Feedback do usuário
      'user_confirmed': userConfirmed ? 1 : 0,
      'user_corrected_organism': userCorrectedOrganism,
      'user_corrected_severity': userCorrectedSeverity,
      'user_corrected_severity_level': userCorrectedSeverityLevel,
      'user_corrected_symptoms': userCorrectedSymptoms?.join('|'),
      'user_notes': userNotes,
      'user_correction_reason': userCorrectionReason,
      
      // Metadados
      'diagnosis_date': diagnosisDate.toIso8601String(),
      'feedback_date': feedbackDate.toIso8601String(),
      'technician_name': technicianName,
      'environmental_data': environmentalData != null 
          ? _encodeJson(environmentalData!) 
          : null,
      'latitude': latitude,
      'longitude': longitude,
      
      // Resultado real
      'real_outcome': realOutcome,
      'outcome_date': outcomeDate?.toIso8601String(),
      'treatment_efficacy': treatmentEfficacy,
      'treatment_applied': treatmentApplied,
      'outcome_notes': outcomeNotes,
      
      // Sincronização
      'synced_to_cloud': syncedToCloud ? 1 : 0,
      'synced_at': syncedAt?.toIso8601String(),
      
      // Auditoria
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria instância a partir de Map do banco de dados
  factory DiagnosisFeedback.fromMap(Map<String, dynamic> map) {
    return DiagnosisFeedback(
      id: map['id'] as String,
      farmId: map['farm_id'] as String,
      diagnosisId: map['diagnosis_id'] as String?,
      monitoringId: map['monitoring_id'] as String?,
      alertId: map['alert_id'] as String?,
      cropName: map['crop_name'] as String,
      imagePath: map['image_path'] as String?,
      
      // Predição do sistema
      systemPredictedOrganism: map['system_predicted_organism'] as String,
      systemPredictedSeverity: (map['system_predicted_severity'] as num).toDouble(),
      systemSeverityLevel: map['system_severity_level'] as String,
      systemConfidence: map['system_confidence'] != null 
          ? (map['system_confidence'] as num).toDouble() 
          : null,
      systemSymptoms: (map['system_symptoms'] as String).split('|'),
      
      // Feedback do usuário
      userConfirmed: (map['user_confirmed'] as int) == 1,
      userCorrectedOrganism: map['user_corrected_organism'] as String?,
      userCorrectedSeverity: map['user_corrected_severity'] != null
          ? (map['user_corrected_severity'] as num).toDouble()
          : null,
      userCorrectedSeverityLevel: map['user_corrected_severity_level'] as String?,
      userCorrectedSymptoms: map['user_corrected_symptoms'] != null
          ? (map['user_corrected_symptoms'] as String).split('|')
          : null,
      userNotes: map['user_notes'] as String?,
      userCorrectionReason: map['user_correction_reason'] as String?,
      
      // Metadados
      diagnosisDate: DateTime.parse(map['diagnosis_date'] as String),
      feedbackDate: DateTime.parse(map['feedback_date'] as String),
      technicianName: map['technician_name'] as String,
      environmentalData: map['environmental_data'] != null
          ? _decodeJson(map['environmental_data'] as String)
          : null,
      latitude: map['latitude'] != null 
          ? (map['latitude'] as num).toDouble() 
          : null,
      longitude: map['longitude'] != null 
          ? (map['longitude'] as num).toDouble() 
          : null,
      
      // Resultado real
      realOutcome: map['real_outcome'] as String?,
      outcomeDate: map['outcome_date'] != null
          ? DateTime.parse(map['outcome_date'] as String)
          : null,
      treatmentEfficacy: map['treatment_efficacy'] != null
          ? (map['treatment_efficacy'] as num).toDouble()
          : null,
      treatmentApplied: map['treatment_applied'] as String?,
      outcomeNotes: map['outcome_notes'] as String?,
      
      // Sincronização
      syncedToCloud: (map['synced_to_cloud'] as int) == 1,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      
      // Auditoria
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Cria uma cópia com campos atualizados
  DiagnosisFeedback copyWith({
    String? farmId,
    String? diagnosisId,
    String? monitoringId,
    String? alertId,
    String? cropName,
    String? imagePath,
    String? systemPredictedOrganism,
    double? systemPredictedSeverity,
    String? systemSeverityLevel,
    double? systemConfidence,
    List<String>? systemSymptoms,
    bool? userConfirmed,
    String? userCorrectedOrganism,
    double? userCorrectedSeverity,
    String? userCorrectedSeverityLevel,
    List<String>? userCorrectedSymptoms,
    String? userNotes,
    String? userCorrectionReason,
    DateTime? diagnosisDate,
    DateTime? feedbackDate,
    String? technicianName,
    Map<String, dynamic>? environmentalData,
    double? latitude,
    double? longitude,
    String? realOutcome,
    DateTime? outcomeDate,
    double? treatmentEfficacy,
    String? treatmentApplied,
    String? outcomeNotes,
    bool? syncedToCloud,
    DateTime? syncedAt,
  }) {
    return DiagnosisFeedback(
      id: id,
      farmId: farmId ?? this.farmId,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      monitoringId: monitoringId ?? this.monitoringId,
      alertId: alertId ?? this.alertId,
      cropName: cropName ?? this.cropName,
      imagePath: imagePath ?? this.imagePath,
      systemPredictedOrganism: systemPredictedOrganism ?? this.systemPredictedOrganism,
      systemPredictedSeverity: systemPredictedSeverity ?? this.systemPredictedSeverity,
      systemSeverityLevel: systemSeverityLevel ?? this.systemSeverityLevel,
      systemConfidence: systemConfidence ?? this.systemConfidence,
      systemSymptoms: systemSymptoms ?? this.systemSymptoms,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      userCorrectedOrganism: userCorrectedOrganism ?? this.userCorrectedOrganism,
      userCorrectedSeverity: userCorrectedSeverity ?? this.userCorrectedSeverity,
      userCorrectedSeverityLevel: userCorrectedSeverityLevel ?? this.userCorrectedSeverityLevel,
      userCorrectedSymptoms: userCorrectedSymptoms ?? this.userCorrectedSymptoms,
      userNotes: userNotes ?? this.userNotes,
      userCorrectionReason: userCorrectionReason ?? this.userCorrectionReason,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      feedbackDate: feedbackDate ?? this.feedbackDate,
      technicianName: technicianName ?? this.technicianName,
      environmentalData: environmentalData ?? this.environmentalData,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      realOutcome: realOutcome ?? this.realOutcome,
      outcomeDate: outcomeDate ?? this.outcomeDate,
      treatmentEfficacy: treatmentEfficacy ?? this.treatmentEfficacy,
      treatmentApplied: treatmentApplied ?? this.treatmentApplied,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Verifica se precisa de follow-up
  bool get needsFollowUp {
    return realOutcome == null && 
           feedbackDate.difference(DateTime.now()).inDays.abs() > 7;
  }

  /// Verifica se foi uma correção
  bool get wasCorrection => !userConfirmed;

  /// Verifica se já tem resultado
  bool get hasOutcome => realOutcome != null;

  // Helpers para codificar/decodificar JSON
  static String _encodeJson(Map<String, dynamic> data) {
    try {
      return data.toString();
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic> _decodeJson(String data) {
    try {
      // Implementação simples - pode ser melhorada com json.decode
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  String toString() {
    return 'DiagnosisFeedback(id: $id, crop: $cropName, confirmed: $userConfirmed, '
           'system: $systemPredictedOrganism, corrected: $userCorrectedOrganism)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiagnosisFeedback && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

