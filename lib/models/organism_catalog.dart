import 'package:uuid/uuid.dart';
import '../utils/enums.dart';

/// Modelo para representar um organismo no catálogo FortSmart
/// Define os limites de controle para cada praga, doença ou planta daninha
class OrganismCatalog {
  final String id;
  final String name;
  final String scientificName;
  final OccurrenceType type; // PEST, DISEASE, WEED
  final String cropId;
  final String cropName;
  final String unit; // Unidade de medição (indivíduos/ponto, % folhas, plantas/m²)
  final int lowLimit; // Limite para nível baixo
  final int mediumLimit; // Limite para nível médio
  final int highLimit; // Limite para nível alto
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrganismCatalog({
    String? id,
    required this.name,
    required this.scientificName,
    required this.type,
    required this.cropId,
    required this.cropName,
    required this.unit,
    required this.lowLimit,
    required this.mediumLimit,
    required this.highLimit,
    this.description,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
    String? metric,
    String? monitoringMethod,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'type': type.toString().split('.').last,
      'crop_id': cropId,
      'crop_name': cropName,
      'unit': unit,
      'low_limit': lowLimit,
      'medium_limit': mediumLimit,
      'high_limit': highLimit,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Cria a partir de Map
  factory OrganismCatalog.fromMap(Map<String, dynamic> map) {
    return OrganismCatalog(
      id: map['id'],
      name: map['name'],
      scientificName: map['scientific_name'] ?? '',
      type: _parseOccurrenceType(map['type']),
      cropId: map['crop_id'],
      cropName: map['crop_name'],
      unit: map['unit'],
      lowLimit: map['low_limit'] ?? 0,
      mediumLimit: map['medium_limit'] ?? 0,
      highLimit: map['high_limit'] ?? 0,
      description: map['description'],
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }

  /// Converte tipo de string para OccurrenceType
  static OccurrenceType _parseOccurrenceType(String? type) {
    switch (type?.toLowerCase()) {
      case 'pest':
        return OccurrenceType.pest;
      case 'disease':
        return OccurrenceType.disease;
      case 'weed':
        return OccurrenceType.weed;
      default:
        return OccurrenceType.pest;
    }
  }

  /// Determina o nível de alerta baseado na quantidade
  AlertLevel getAlertLevel(int quantity) {
    if (quantity <= lowLimit) {
      return AlertLevel.low;
    } else if (quantity <= mediumLimit) {
      return AlertLevel.medium;
    } else if (quantity <= highLimit) {
      return AlertLevel.high;
    } else {
      return AlertLevel.critical;
    }
  }

  /// Getters para compatibilidade com código existente
  double get lowThreshold => lowLimit.toDouble();
  double get mediumThreshold => mediumLimit.toDouble();
  double get highThreshold => highLimit.toDouble();

  /// Calcula a porcentagem de infestação baseada na quantidade
  double calculateInfestationPercentage(int quantity) {
    // Usa o limite alto como referência para 100%
    if (highLimit <= 0) return 0.0;
    
    double percentage = (quantity / highLimit) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  /// Retorna a cor correspondente ao nível de alerta
  String getAlertLevelColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.low:
        return '#4CAF50'; // Verde
      case AlertLevel.medium:
        return '#FF9800'; // Laranja
      case AlertLevel.high:
        return '#F44336'; // Vermelho
      case AlertLevel.critical:
        return '#9C27B0'; // Roxo
    }
  }

  /// Cria uma cópia com alterações
  OrganismCatalog copyWith({
    String? id,
    String? name,
    String? scientificName,
    OccurrenceType? type,
    String? cropId,
    String? cropName,
    String? unit,
    int? lowLimit,
    int? mediumLimit,
    int? highLimit,
    String? description,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganismCatalog(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      type: type ?? this.type,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      unit: unit ?? this.unit,
      lowLimit: lowLimit ?? this.lowLimit,
      mediumLimit: mediumLimit ?? this.mediumLimit,
      highLimit: highLimit ?? this.highLimit,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'OrganismCatalog(id: $id, name: $name, type: $type, crop: $cropName)';
  }
}

/// Enum para níveis de alerta
enum AlertLevel {
  low,
  medium,
  high,
  critical,
}

/// Extensão para facilitar o uso dos níveis de alerta
extension AlertLevelExtension on AlertLevel {
  String get displayName {
    switch (this) {
      case AlertLevel.low:
        return 'Baixo';
      case AlertLevel.medium:
        return 'Médio';
      case AlertLevel.high:
        return 'Alto';
      case AlertLevel.critical:
        return 'Crítico';
    }
  }

  String get color {
    switch (this) {
      case AlertLevel.low:
        return '#4CAF50'; // Verde
      case AlertLevel.medium:
        return '#FF9800'; // Laranja
      case AlertLevel.high:
        return '#F44336'; // Vermelho
      case AlertLevel.critical:
        return '#9C27B0'; // Roxo
    }
  }
}
