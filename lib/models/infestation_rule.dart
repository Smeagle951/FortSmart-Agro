import '../utils/enums.dart';

/// Modelo para regras de infestação personalizadas por organismo
/// ✅ UNIDADE PADRÃO: organismos/ponto (média por ponto de monitoramento)
class InfestationRule {
  final String id;
  final String organismId;
  final String organismName;
  final OccurrenceType type;
  final double lowThreshold;      // Ex: 0.5 organismos/ponto
  final double mediumThreshold;   // Ex: 1.5 organismos/ponto
  final double highThreshold;     // Ex: 3.0 organismos/ponto
  final double criticalThreshold; // Ex: 5.0 organismos/ponto
  final String unit;              // ✅ NOVO: 'organismos/ponto' ou 'organismos/metro'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InfestationRule({
    required this.id,
    required this.organismId,
    required this.organismName,
    required this.type,
    this.lowThreshold = 0.5,      // ✅ NOVO PADRÃO: 0.5 organismos/ponto
    this.mediumThreshold = 1.5,   // ✅ NOVO PADRÃO: 1.5 organismos/ponto
    this.highThreshold = 3.0,     // ✅ NOVO PADRÃO: 3.0 organismos/ponto
    this.criticalThreshold = 5.0, // ✅ NOVO PADRÃO: 5.0 organismos/ponto
    this.unit = 'organismos/ponto', // ✅ NOVO: Unidade padrão
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  /// Converte para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organism_id': organismId,
      'organism_name': organismName,
      'type': type.toString().split('.').last,
      'low_threshold': lowThreshold,
      'medium_threshold': mediumThreshold,
      'high_threshold': highThreshold,
      'critical_threshold': criticalThreshold,
      'unit': unit, // ✅ NOVO
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria a partir de Map (carregar do banco)
  factory InfestationRule.fromMap(Map<String, dynamic> map) {
    return InfestationRule(
      id: map['id'] as String,
      organismId: map['organism_id'] as String,
      organismName: map['organism_name'] as String,
      type: _parseOccurrenceType(map['type'] as String?),
      lowThreshold: (map['low_threshold'] as num?)?.toDouble() ?? 0.5,
      mediumThreshold: (map['medium_threshold'] as num?)?.toDouble() ?? 1.5,
      highThreshold: (map['high_threshold'] as num?)?.toDouble() ?? 3.0,
      criticalThreshold: (map['critical_threshold'] as num?)?.toDouble() ?? 5.0,
      unit: map['unit'] as String? ?? 'organismos/ponto', // ✅ NOVO
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Determina o nível de alerta baseado em uma porcentagem
  String getAlertLevel(double percentage) {
    if (percentage <= lowThreshold) return 'baixo';
    if (percentage <= mediumThreshold) return 'moderado';
    if (percentage <= highThreshold) return 'alto';
    return 'critico';
  }

  /// Obtém cor do alerta baseado no nível
  String getAlertColor(double percentage) {
    final level = getAlertLevel(percentage);
    switch (level) {
      case 'baixo':
        return '#4CAF50'; // Verde
      case 'moderado':
        return '#FF9800'; // Laranja
      case 'alto':
        return '#F44336'; // Vermelho
      case 'critico':
        return '#9C27B0'; // Roxo
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Parse de OccurrenceType
  static OccurrenceType _parseOccurrenceType(String? typeStr) {
    if (typeStr == null) return OccurrenceType.pest;
    
    switch (typeStr.toLowerCase()) {
      case 'pest':
      case 'praga':
        return OccurrenceType.pest;
      case 'disease':
      case 'doenca':
      case 'doença':
        return OccurrenceType.disease;
      case 'weed':
      case 'daninha':
        return OccurrenceType.weed;
      default:
        return OccurrenceType.pest;
    }
  }

  /// Cria regra padrão para um organismo
  factory InfestationRule.defaultForOrganism(
    String organismId,
    String organismName,
    OccurrenceType type,
  ) {
    return InfestationRule(
      id: 'default_$organismId',
      organismId: organismId,
      organismName: organismName,
      type: type,
      lowThreshold: 0.5,  // ✅ NOVO PADRÃO: organismos/ponto
      mediumThreshold: 1.5,
      highThreshold: 3.0,
      criticalThreshold: 5.0,
      unit: 'organismos/ponto', // ✅ Unidade padrão
      notes: 'Regra padrão do sistema (organismos por ponto)',
    );
  }

  /// Copia com alterações
  InfestationRule copyWith({
    String? id,
    String? organismId,
    String? organismName,
    OccurrenceType? type,
    double? lowThreshold,
    double? mediumThreshold,
    double? highThreshold,
    double? criticalThreshold,
    String? unit, // ✅ NOVO
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InfestationRule(
      id: id ?? this.id,
      organismId: organismId ?? this.organismId,
      organismName: organismName ?? this.organismName,
      type: type ?? this.type,
      lowThreshold: lowThreshold ?? this.lowThreshold,
      mediumThreshold: mediumThreshold ?? this.mediumThreshold,
      highThreshold: highThreshold ?? this.highThreshold,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      unit: unit ?? this.unit, // ✅ NOVO
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'InfestationRule(id: $id, organism: $organismName, type: $type, thresholds: $lowThreshold/$mediumThreshold/$highThreshold/$criticalThreshold $unit)';
  }
}


