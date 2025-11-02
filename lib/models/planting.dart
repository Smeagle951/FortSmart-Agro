import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../utils/google_maps_adapter.dart';

/// Modelo para representar um registro de plantio
class Planting {
  final String id;
  final String plotId; // ID do talhão
  final String? cropId; // ID da cultura
  final String? cropVarietyId; // ID da variedade
  final DateTime plantingDate;
  final DateTime? expectedHarvestDate; // Data esperada de colheita
  final String? planterId; // ID da plantadeira
  final String? tractorId; // ID do trator
  final double? seedRate; // Taxa de semeadura (sementes/ha)
  final double? seedDepth; // Profundidade da semente (cm)
  final double? rowSpacing; // Espaçamento entre linhas (cm)
  final double? area; // Área plantada (ha)
  final String? notes; // Observações
  final List<String> imageUrls;
  final List<Map<String, dynamic>>? coordinates;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? cropType; // Tipo de cultura (ex: soja, milho, etc.)
  final String? variety; // Variedade da cultura
  final String? observations; // Observações adicionais
  final String? calibrationId; // ID da calibração
  
  // Propriedades adicionais para compatibilidade com relatórios
  DateTime get date => plantingDate;
  String get season => "Safra ${plantingDate.year}";
  String get crop => cropType ?? "Não especificado";
  double? get population => seedRate;
  double? get spacing => rowSpacing;
  double? get depth => seedDepth;
  String get status => "completed"; // Status padrão

  // Getters para compatibilidade com relatórios
  String? get varietyName => variety;
  String get cropName => cropType ?? "Não especificado";
  String get responsiblePerson => "Responsável"; // Deve ser preenchido pelo repositório
  double get operationSpeed => 5.0; // Velocidade padrão de operação
  String get equipmentName => "Plantadeira"; // Nome do equipamento
  double get plantsPerMeter => seedRate != null && rowSpacing != null ? 
      (seedRate! * rowSpacing! / 10000) : 0.0;
  double get estimatedPopulation => seedRate ?? 0.0;
  double get plantingDepth => seedDepth ?? 0.0;
  double get seedQuantity => 0.0; // Deve ser calculado pelo repositório
  String? get fertilizerName => null; // Deve ser preenchido pelo repositório
  double? get fertilizerQuantity => null; // Deve ser preenchido pelo repositório

  Planting({
    String? id,
    required this.plotId,
    this.cropId,
    this.cropVarietyId,
    required this.plantingDate,
    this.expectedHarvestDate,
    this.planterId,
    this.tractorId,
    this.seedRate,
    this.seedDepth,
    this.rowSpacing,
    this.area,
    this.notes,
    this.imageUrls = const [],
    this.coordinates,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.cropType,
    this.variety,
    this.observations,
    this.calibrationId,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  Planting copyWith({
    String? id,
    String? plotId,
    String? cropId,
    String? cropVarietyId,
    DateTime? plantingDate,
    DateTime? expectedHarvestDate,
    String? planterId,
    String? tractorId,
    double? seedRate,
    double? seedDepth,
    double? rowSpacing,
    double? area,
    String? notes,
    List<String>? imageUrls,
    List<Map<String, dynamic>>? coordinates,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? cropType,
    String? variety,
    String? observations,
  }) {
    return Planting(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      cropId: cropId ?? this.cropId,
      cropVarietyId: cropVarietyId ?? this.cropVarietyId,
      plantingDate: plantingDate ?? this.plantingDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      planterId: planterId ?? this.planterId,
      tractorId: tractorId ?? this.tractorId,
      seedRate: seedRate ?? this.seedRate,
      seedDepth: seedDepth ?? this.seedDepth,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      area: area ?? this.area,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      coordinates: coordinates ?? this.coordinates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cropType: cropType ?? this.cropType,
      variety: variety ?? this.variety,
      observations: observations ?? this.observations,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotId': plotId,
      'cropId': cropId,
      'cropVarietyId': cropVarietyId,
      'plantingDate': plantingDate.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
      'planterId': planterId,
      'tractorId': tractorId,
      'seedRate': seedRate,
      'seedDepth': seedDepth,
      'rowSpacing': rowSpacing,
      'area': area,
      'notes': notes,
      'imageUrls': jsonEncode(imageUrls),
      'coordinates': coordinates != null ? jsonEncode(coordinates) : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'cropType': cropType,
      'variety': variety,
      'observations': observations,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory Planting.fromMap(Map<String, dynamic> map) {
    try {
      return Planting(
        id: map['id'],
        plotId: map['plotId'],
        cropId: map['cropId'],
        cropVarietyId: map['cropVarietyId'],
        plantingDate: DateTime.parse(map['plantingDate']),
        expectedHarvestDate: map['expectedHarvestDate'] != null ? DateTime.parse(map['expectedHarvestDate']) : null,
        planterId: map['planterId'],
        tractorId: map['tractorId'],
        seedRate: map['seedRate'] != null ? double.tryParse(map['seedRate'].toString()) : null,
        seedDepth: map['seedDepth'] != null ? double.tryParse(map['seedDepth'].toString()) : null,
        rowSpacing: map['rowSpacing'] != null ? double.tryParse(map['rowSpacing'].toString()) : null,
        area: map['area'] != null ? double.tryParse(map['area'].toString()) : null,
        notes: map['notes'],
        imageUrls: map['imageUrls'] != null 
            ? List<String>.from(jsonDecode(map['imageUrls']))
            : [],
        coordinates: map['coordinates'] != null 
            ? List<Map<String, dynamic>>.from(jsonDecode(map['coordinates']))
            : null,
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        isSynced: map['isSynced'] == 1,
        cropType: map['cropType'],
        variety: map['variety'],
        observations: map['observations'],
      );
    } catch (e) {
      // Tratamento de compatibilidade com versões anteriores do modelo
      return Planting(
        id: map['id'],
        plotId: map['plotId'],
        cropId: map['cropId'],
        cropVarietyId: map['cropVarietyId'] ?? map['varietyId'],
        plantingDate: DateTime.parse(map['plantingDate']),
        planterId: map['planterId'],
        tractorId: map['tractorId'],
        seedRate: map['targetPopulation'] != null 
            ? double.tryParse(map['targetPopulation'].toString()) 
            : null,
        rowSpacing: map['rowSpacing'] != null 
            ? double.tryParse(map['rowSpacing'].toString()) 
            : null,
        notes: map['notes'] ?? map['observations'],
        imageUrls: map['imageUrls'] != null 
            ? List<String>.from(jsonDecode(map['imageUrls'] ?? '[]'))
            : [],
        coordinates: map['coordinates'] != null 
            ? List<Map<String, dynamic>>.from(jsonDecode(map['coordinates']))
            : null,
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        isSynced: map['isSynced'] == 1,
      );
    }
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory Planting.fromJson(String source) => Planting.fromMap(jsonDecode(source));
  
  /// Converte as coordenadas para uma lista de LatLng
  List<LatLng>? getLatLngCoordinates() {
    if (coordinates == null || coordinates!.isEmpty) return null;
    
    return coordinates!.map((coord) {
      return LatLng(
        coord['latitude'] as double,
        coord['longitude'] as double,
      );
    }).toList();
  }

  // Getters para exibição na interface
  String? get plotName => null; // Será preenchido pelo repositório
  double get seedRateValue => seedRate ?? 0.0; // Taxa de sementes em plantas/ha
  double get seedDepthValue => seedDepth ?? 0.0; // Profundidade da semente (não armazenada no modelo)
  String? get machine => planterId; // Compatibilidade com código legado
  String get notesValue => notes ?? ''; // Observações
}
