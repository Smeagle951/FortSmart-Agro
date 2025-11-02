import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../utils/enums.dart';

/// Classe que representa uma ocorrência (praga, doença ou planta daninha)
class Occurrence {
  final String id;
  final OccurrenceType type;
  final String name;
  final double infestationIndex; // 0 a 100%
  final List<PlantSection> affectedSections; // Terços afetados
  final String? notes; // Notas adicionais
  final String? monitoringPointId; // ID do ponto de monitoramento
  
  // Novos campos para integração com IA e enriquecimento
  final String? estadioFenologicoId; // FK para tabela de estádios ou valor calculado
  final List<String> tipoManejoAnterior; // Lista múltipla: químico, biológico, cultural
  final String? historicoResumo; // Texto gerado automaticamente
  final String? estandeId; // FK para último estande associado ao talhão
  final double? impactoEconomicoPrevisto; // Calculado pela IA
  final String? organismId; // ID do organismo no catálogo
  final String? organismName; // Nome do organismo
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Propriedades calculadas
  double get intensity => infestationIndex;
  
  // Getters para compatibilidade
  double get severity => infestationIndex;
  List<String> get symptoms => tipoManejoAnterior;

  Occurrence({
    String? id,
    required this.type,
    required this.name,
    required this.infestationIndex,
    required this.affectedSections,
    this.notes,
    this.monitoringPointId,
    this.estadioFenologicoId,
    this.tipoManejoAnterior = const [],
    this.historicoResumo,
    this.estandeId,
    this.impactoEconomicoPrevisto,
    this.organismId,
    this.organismName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last, // Remove o prefixo da enum
      'name': name,
      'infestationIndex': infestationIndex,
      'affectedSections': jsonEncode(affectedSections.map((section) => section.toString()).toList()),
      'notes': notes ?? '',
      'monitoringPointId': monitoringPointId,
      'estadioFenologicoId': estadioFenologicoId,
      'tipoManejoAnterior': jsonEncode(tipoManejoAnterior),
      'historicoResumo': historicoResumo ?? '',
      'estandeId': estandeId,
      'impactoEconomicoPrevisto': impactoEconomicoPrevisto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sync_status': 0,
      'remote_id': null,
    };
  }

  /// Converte para JSON
  String toJson() => json.encode(toMap());

  /// Cria a partir de Map
  factory Occurrence.fromMap(Map<String, dynamic> map) {
    return Occurrence(
      id: map['id'],
      type: OccurrenceType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] || e.toString() == map['type'],
        orElse: () => OccurrenceType.pest
      ),
      name: map['name'] ?? '',
      infestationIndex: map['infestationIndex']?.toDouble() ?? 0.0,
      affectedSections: _parseAffectedSections(map['affectedSections']),
      notes: map['notes'],
      monitoringPointId: map['monitoringPointId'],
      estadioFenologicoId: map['estadioFenologicoId'],
      tipoManejoAnterior: _parseTipoManejoAnterior(map['tipoManejoAnterior']),
      historicoResumo: map['historicoResumo'],
      estandeId: map['estandeId'],
      impactoEconomicoPrevisto: map['impactoEconomicoPrevisto']?.toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Parse das seções afetadas
  static List<PlantSection> _parseAffectedSections(dynamic sections) {
    if (sections == null) return [];
    
    if (sections is String) {
      try {
        final List<dynamic> parsed = jsonDecode(sections);
        return parsed.map<PlantSection>((e) => PlantSection.values.firstWhere(
          (section) => section.toString().split('.').last == e || section.toString() == e,
          orElse: () => PlantSection.upper,
        )).toList();
      } catch (e) {
        return [];
      }
    }
    
    if (sections is List) {
      return sections.map<PlantSection>((e) => PlantSection.values.firstWhere(
        (section) => section.toString().split('.').last == e || section.toString() == e,
        orElse: () => PlantSection.upper,
      )).toList();
    }
    
    return [];
  }

  /// Parse do tipo de manejo anterior
  static List<String> _parseTipoManejoAnterior(dynamic manejo) {
    if (manejo == null) return [];
    
    if (manejo is String) {
      try {
        final List<dynamic> parsed = jsonDecode(manejo);
        return parsed.map<String>((e) => e.toString()).toList();
      } catch (e) {
        return [];
      }
    }
    
    if (manejo is List) {
      return manejo.map<String>((e) => e.toString()).toList();
    }
    
    return [];
  }

  /// Cria a partir de JSON
  factory Occurrence.fromJson(String source) => Occurrence.fromMap(json.decode(source));

  get count => null;

  /// Cria uma cópia com alterações
  Occurrence copyWith({
    String? id,
    OccurrenceType? type,
    String? name,
    double? infestationIndex,
    List<PlantSection>? affectedSections,
    String? notes,
    String? monitoringPointId,
    String? estadioFenologicoId,
    List<String>? tipoManejoAnterior,
    String? historicoResumo,
    String? estandeId,
    double? impactoEconomicoPrevisto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Occurrence(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      infestationIndex: infestationIndex ?? this.infestationIndex,
      affectedSections: affectedSections ?? this.affectedSections,
      notes: notes ?? this.notes,
      monitoringPointId: monitoringPointId ?? this.monitoringPointId,
      estadioFenologicoId: estadioFenologicoId ?? this.estadioFenologicoId,
      tipoManejoAnterior: tipoManejoAnterior ?? this.tipoManejoAnterior,
      historicoResumo: historicoResumo ?? this.historicoResumo,
      estandeId: estandeId ?? this.estandeId,
      impactoEconomicoPrevisto: impactoEconomicoPrevisto ?? this.impactoEconomicoPrevisto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters para compatibilidade
  String get observations => notes ?? '';
  List<PlantSection> get plantSections => affectedSections;
}
