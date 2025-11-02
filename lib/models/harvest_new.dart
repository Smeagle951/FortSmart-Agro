import 'package:intl/intl.dart';

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
  final DateTime lastAccessedAt; // Data do último acesso (para histórico temporário)
  final bool isSynced;
  
  // Campos adicionais para relatórios
  final DateTime? harvestEndDate; // Data de término da colheita
  final double harvestedArea; // Área colhida em hectares
  final double? grainMoisture; // Umidade dos grãos em %
  final double? estimatedLoss; // Perda estimada em kg
  final double sackWeight; // Peso da saca em kg (padrão: 60kg)
  final String? cropVariety; // Nome da variedade
  final double? latitude; // Coordenada GPS latitude
  final double? longitude; // Coordenada GPS longitude

  // Métodos para cálculos de produtividade
  double get yieldInBagsPerHectare {
    if (harvestedArea <= 0 || sackWeight <= 0) return 0;
    return (totalProduction / harvestedArea) / sackWeight;
  }
  
  double get totalProductionInBags {
    if (sackWeight <= 0) return 0;
    return totalProduction / sackWeight;
  }
  
  double get lossPerHectare {
    if (harvestedArea <= 0 || estimatedLoss == null) return 0;
    return estimatedLoss! / harvestedArea;
  }
  
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
  
  // Formatação de data
  String get formattedHarvestDate {
    return DateFormat('dd/MM/yyyy').format(harvestDate);
  }

  Harvest({
    required this.id,
    required this.plotId,
    required this.cropId,
    required this.varietyId,
    required this.harvestDate,
    required this.yield,
    required this.totalProduction,
    required this.responsiblePerson,
    this.machineId,
    required this.observations,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
    required this.isSynced,
    this.harvestEndDate,
    required this.harvestedArea,
    this.grainMoisture,
    this.estimatedLoss,
    required this.sackWeight,
    this.cropVariety,
    this.latitude,
    this.longitude,
  });

  // Construtor para copiar o objeto com alterações
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
    String? cropVariety,
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
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isSynced: isSynced ?? this.isSynced,
      harvestEndDate: harvestEndDate ?? this.harvestEndDate,
      harvestedArea: harvestedArea ?? this.harvestedArea,
      grainMoisture: grainMoisture ?? this.grainMoisture,
      estimatedLoss: estimatedLoss ?? this.estimatedLoss,
      sackWeight: sackWeight ?? this.sackWeight,
      cropVariety: cropVariety ?? this.cropVariety,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Factory para criar a partir de um Map (JSON)
  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'],
      plotId: json['plotId'],
      cropId: json['cropId'],
      varietyId: json['varietyId'],
      harvestDate: DateTime.parse(json['harvestDate']),
      yield: json['yield'].toDouble(),
      totalProduction: json['totalProduction'].toDouble(),
      responsiblePerson: json['responsiblePerson'],
      machineId: json['machineId'],
      observations: json['observations'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastAccessedAt: json.containsKey('lastAccessedAt') 
          ? DateTime.parse(json['lastAccessedAt']) 
          : DateTime.now(),
      isSynced: json['isSynced'] ?? false,
      harvestEndDate: json['harvestEndDate'] != null 
          ? DateTime.parse(json['harvestEndDate']) 
          : null,
      harvestedArea: json['harvestedArea']?.toDouble() ?? 0.0,
      grainMoisture: json['grainMoisture']?.toDouble(),
      estimatedLoss: json['estimatedLoss']?.toDouble(),
      sackWeight: json['sackWeight']?.toDouble() ?? 60.0,
      cropVariety: json['cropVariety'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // Método para converter em Map (JSON)
  Map<String, dynamic> toJson() {
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
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'isSynced': isSynced,
      'harvestEndDate': harvestEndDate?.toIso8601String(),
      'harvestedArea': harvestedArea,
      'grainMoisture': grainMoisture,
      'estimatedLoss': estimatedLoss,
      'sackWeight': sackWeight,
      'cropVariety': cropVariety,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
