import 'package:uuid/uuid.dart';
import 'dart:convert';

class Harvest {
  final String id;
  final String plotId;
  final String cropId;
  final String varietyId;
  final DateTime harvestDate;
  final double yield; // produtividade em kg/ha
  final double totalProduction; // produção total em kg
  final String responsiblePerson;
  final String? machineId; // ID da colheitadeira
  final String observations;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccessedAt; // Data do último acesso (para histórico temporário e expiração após 7 dias)
  final bool isSynced;
  
  // Campos adicionais conforme especificação
  final DateTime? harvestEndDate; // Data de término da colheita
  final double harvestedArea; // Área colhida em hectares
  final double? grainMoisture; // Umidade dos grãos em %
  final double? estimatedLoss;
  final double? latitude; // Coordenada GPS latitude
  final double? longitude; // Coordenada GPS longitude
  final double sackWeight; // Peso da saca em kg (padrão: 60kg)
  final String? cropName; // Nome da cultura
  final String? cropVariety; // Variedade da cultura
  final String? notes; // Observações adicionais
  final List<Map<String, dynamic>>? qualityData; // Dados de qualidade

  // Métodos para cálculos de produtividade
  
  double get lossInBags {
    if (sackWeight <= 0 || estimatedLoss == null) return 0;
    return estimatedLoss! / sackWeight;
  }
  
  // Verificar se o registro expirou (7 dias sem acesso)
  bool get isExpired {
    final difference = DateTime.now().difference(lastAccessedAt);
    return difference.inDays > 7;
  }
  
  // Dias restantes até a expiração
  int get daysUntilExpiration {
    final difference = DateTime.now().difference(lastAccessedAt);
    final daysLeft = 7 - difference.inDays;
    return daysLeft > 0 ? daysLeft : 0;
  }
  
  Harvest({
    String? id,
    required this.plotId,
    required this.cropId,
    required this.varietyId,
    required this.harvestDate,
    required this.yield,
    required this.totalProduction,
    required this.responsiblePerson,
    required this.harvestedArea,
    this.machineId,
    this.observations = '',
    this.imageUrls = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    bool? isSynced,
    this.harvestEndDate,
    this.grainMoisture,
    this.estimatedLoss,
    this.sackWeight = 60.0, // Padrão: 60kg por saca
    this.qualityData,
    this.cropName,
    this.cropVariety,
    this.notes,
    this.latitude,
    this.longitude,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    lastAccessedAt = lastAccessedAt ?? DateTime.now(),
    isSynced = isSynced ?? false;

  /// Cria uma cópia do objeto com os campos atualizados
  Harvest copyWith({
    String? id,
    String? plotId,
    String? cropId,
    String? varietyId,
    DateTime? harvestDate,
    double? yield,
    double? totalProduction,
    String? responsiblePerson,
    String? machineId,
    String? observations,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    bool? isSynced,
    DateTime? harvestEndDate,
    double? harvestedArea,
    double? grainMoisture,
    double? estimatedLoss,
    double? sackWeight,
    List<Map<String, dynamic>>? qualityData,
    String? cropName,
    String? cropVariety,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return Harvest(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      cropId: cropId ?? this.cropId,
      varietyId: varietyId ?? this.varietyId,
      harvestDate: harvestDate ?? this.harvestDate,
      yield: yield ?? this.yield,
      totalProduction: totalProduction ?? this.totalProduction,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      machineId: machineId ?? this.machineId,
      observations: observations ?? this.observations,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? DateTime.now(), // Atualiza o último acesso
      isSynced: isSynced ?? this.isSynced,
      harvestEndDate: harvestEndDate ?? this.harvestEndDate,
      harvestedArea: harvestedArea ?? this.harvestedArea,
      grainMoisture: grainMoisture ?? this.grainMoisture,
      estimatedLoss: estimatedLoss ?? this.estimatedLoss,
      sackWeight: sackWeight ?? this.sackWeight,
      qualityData: qualityData ?? this.qualityData,
      cropName: cropName ?? this.cropName,
      cropVariety: cropVariety ?? this.cropVariety,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Calcula o rendimento em sacas por hectare
  double get yieldInBagsPerHectare {
    return yield / sackWeight; // Usando o peso da saca configurado
  }

  /// Calcula a produção total em sacas
  double get totalProductionInBags {
    return totalProduction / sackWeight;
  }

  /// Calcula a perda em kg/ha (se estimatedLoss for fornecido)
  double? get lossPerHectare {
    if (estimatedLoss == null) return null;
    return estimatedLoss! / harvestedArea;
  }

  /// Calcula a perda em sacas/ha
  double? get lossInBagsPerHectare {
    if (estimatedLoss == null || harvestedArea <= 0 || sackWeight <= 0) return null;
    return (estimatedLoss! / harvestedArea) / sackWeight;
  }

  /// Converte o objeto para um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotId': plotId,
      'cropId': cropId,
      'varietyId': varietyId,
      'harvestDate': harvestDate.toIso8601String(),
      'yield': yield,
      'totalProduction': totalProduction,
      'responsiblePerson': responsiblePerson,
      'machineId': machineId,
      'observations': observations,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'harvestEndDate': harvestEndDate?.toIso8601String(),
      'harvestedArea': harvestedArea,
      'grainMoisture': grainMoisture,
      'qualityData': qualityData,
      'cropName': cropName,
      'cropVariety': cropVariety,
      'notes': notes,
    };
  }

  /// Cria um objeto a partir de um Map
  factory Harvest.fromMap(Map<String, dynamic> map) {
    return Harvest(
      id: map['id'] ?? const Uuid().v4(),
      plotId: map['plotId'] ?? '',
      cropId: map['cropId'] ?? '',
      varietyId: map['varietyId'] ?? '',
      harvestDate: map['harvestDate'] != null 
          ? DateTime.parse(map['harvestDate']) 
          : DateTime.now(),
      yield: map['yield']?.toDouble() ?? 0.0,
      totalProduction: map['totalProduction']?.toDouble() ?? 0.0,
      responsiblePerson: map['responsiblePerson'] ?? '',
      machineId: map['machineId'],
      observations: map['observations'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isSynced: map['isSynced'] == 1,
      harvestEndDate: map['harvestEndDate'] != null 
          ? DateTime.parse(map['harvestEndDate']) 
          : null,
      harvestedArea: map['harvestedArea']?.toDouble(),
      grainMoisture: map['grainMoisture']?.toDouble(),
      qualityData: map['qualityData'] != null 
          ? List<Map<String, dynamic>>.from(map['qualityData']) 
          : null,
      cropName: map['cropName'],
      cropVariety: map['cropVariety'],
      notes: map['notes'],
    );
  }

  /// Converte o objeto para JSON
  String toJson() => json.encode(toMap());

  /// Cria um objeto a partir de JSON
  factory Harvest.fromJson(String source) => Harvest.fromMap(json.decode(source));

  // Getters para compatibilidade com código existente
  String get plotName => ""; // Este getter precisa ser implementado corretamente quando houver acesso aos dados de talhão
} 
