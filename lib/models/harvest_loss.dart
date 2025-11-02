import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo para representar um cálculo de perdas na colheita
class HarvestLoss {
  final String id;
  final String plotId; // ID do talhão
  final String cropId; // ID da cultura
  final double grainsPerArea; // número de grãos caídos por área
  final double sampleAreaSize; // dimensão da área amostrada (m²)
  final double? thousandGrainWeight; // peso de mil grãos (g)
  final double? collectedGrainsWeight; // peso dos grãos coletados (g)
  final bool useCollectedWeight; // indica se usa o peso coletado ou o PMS
  final int sampleCount; // quantidade de amostras
  final List<String> imageUrls; // imagens das perdas
  final DateTime assessmentDate; // data da avaliação
  final String responsiblePerson; // responsável pela avaliação
  final String observations; // observações
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? cropName;

  /// Perda calculada em kg/ha
  double get lossKgPerHa {
    if (useCollectedWeight && collectedGrainsWeight != null) {
      // Fórmula: Peso Total dos Grãos Coletados (g) / Área da amostra (m²) / 1000
      return collectedGrainsWeight! / sampleAreaSize / 1000;
    } else if (!useCollectedWeight && thousandGrainWeight != null) {
      // Fórmula: (grãos/m² × PMS) / 1000 = kg/ha perdidos
      return (grainsPerArea * thousandGrainWeight!) / 1000;
    }
    return 0.0;
  }

  /// Alias para assessmentDate para compatibilidade com o código existente
  DateTime get date => assessmentDate;

  /// Alias para grainsPerArea para compatibilidade com o código existente
  int get grainCount => grainsPerArea.toInt();

  /// Alias para sampleAreaSize para compatibilidade com o código existente
  double get sampleAreaSqm => sampleAreaSize;

  /// Alias para thousandGrainWeight para compatibilidade com o código existente
  double get thousandGrainWeightG => thousandGrainWeight ?? 0.0;

  /// Getters adicionais para compatibilidade com relatórios
  DateTime get evaluationDate => assessmentDate;
  String get responsible => responsiblePerson;
  double get sampleArea => sampleAreaSize;
  double get grainsPerSqm => grainsPerArea;
  double get totalArea => 1.0; // Valor padrão, deve ser preenchido pelo repositório
  double? get pricePerKg => null; // Valor padrão, deve ser preenchido pelo repositório

  HarvestLoss({
    String? id,
    required this.plotId,
    required this.cropId,
    required this.grainsPerArea,
    required this.sampleAreaSize,
    this.thousandGrainWeight,
    this.collectedGrainsWeight,
    this.useCollectedWeight = false,
    required this.sampleCount,
    this.imageUrls = const [],
    required this.assessmentDate,
    required this.responsiblePerson,
    this.observations = '',
    this.cropName,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  HarvestLoss copyWith({
    String? id,
    String? plotId,
    String? cropId,
    double? grainsPerArea,
    double? sampleAreaSize,
    double? thousandGrainWeight,
    double? collectedGrainsWeight,
    bool? useCollectedWeight,
    int? sampleCount,
    List<String>? imageUrls,
    DateTime? assessmentDate,
    String? responsiblePerson,
    String? observations,
    String? cropName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return HarvestLoss(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      cropId: cropId ?? this.cropId,
      grainsPerArea: grainsPerArea ?? this.grainsPerArea,
      sampleAreaSize: sampleAreaSize ?? this.sampleAreaSize,
      thousandGrainWeight: thousandGrainWeight ?? this.thousandGrainWeight,
      collectedGrainsWeight: collectedGrainsWeight ?? this.collectedGrainsWeight,
      useCollectedWeight: useCollectedWeight ?? this.useCollectedWeight,
      sampleCount: sampleCount ?? this.sampleCount,
      imageUrls: imageUrls ?? this.imageUrls,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      observations: observations ?? this.observations,
      cropName: cropName ?? this.cropName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotId': plotId,
      'cropId': cropId,
      'grainsPerArea': grainsPerArea,
      'sampleAreaSize': sampleAreaSize,
      'thousandGrainWeight': thousandGrainWeight,
      'collectedGrainsWeight': collectedGrainsWeight,
      'useCollectedWeight': useCollectedWeight ? 1 : 0,
      'sampleCount': sampleCount,
      'imageUrls': jsonEncode(imageUrls),
      'assessmentDate': assessmentDate.millisecondsSinceEpoch,
      'responsiblePerson': responsiblePerson,
      'observations': observations,
      'cropName': cropName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory HarvestLoss.fromMap(Map<String, dynamic> map) {
    return HarvestLoss(
      id: map['id'],
      plotId: map['plotId'] ?? '',
      cropId: map['cropId'] ?? '',
      grainsPerArea: map['grainsPerArea']?.toDouble() ?? 0.0,
      sampleAreaSize: map['sampleAreaSize']?.toDouble() ?? 0.0,
      thousandGrainWeight: map['thousandGrainWeight']?.toDouble(),
      collectedGrainsWeight: map['collectedGrainsWeight']?.toDouble(),
      useCollectedWeight: map['useCollectedWeight'] == 1,
      sampleCount: map['sampleCount']?.toInt() ?? 1,
      imageUrls: List<String>.from(jsonDecode(map['imageUrls'] ?? '[]')),
      assessmentDate: DateTime.fromMillisecondsSinceEpoch(map['assessmentDate'] ?? DateTime.now().millisecondsSinceEpoch),
      responsiblePerson: map['responsiblePerson'] ?? '',
      observations: map['observations'] ?? '',
      cropName: map['cropName'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      isSynced: map['isSynced'] == 1,
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory HarvestLoss.fromJson(String source) => 
      HarvestLoss.fromMap(jsonDecode(source));
  
  /// Calcula a perda em kg/ha
  /// peso_kg_ha = (grãos_m² × PMS) ÷ 1000
  double calculateLossKgPerHectare() {
    // Converter para grãos por m² se a área amostrada for diferente de 1m²
    final grainsPerSquareMeter = grainsPerArea / sampleAreaSize;
    
    // Calcular a perda em kg/ha
    if (useCollectedWeight && collectedGrainsWeight != null) {
      return collectedGrainsWeight! / sampleAreaSize / 1000;
    } else if (!useCollectedWeight && thousandGrainWeight != null) {
      return (grainsPerSquareMeter * thousandGrainWeight!) / 1000;
    }
    return 0.0;
  }
  
  /// Calcula a perda em sacas/ha (considerando saca de 60kg)
  double calculateLossBagsPerHectare() {
    return calculateLossKgPerHectare() / 60;
  }
  
  /// Calcula a perda média por amostra em kg/ha
  double calculateAverageLossPerSample() {
    if (sampleCount <= 0) return 0;
    return calculateLossKgPerHectare() / sampleCount;
  }
}
