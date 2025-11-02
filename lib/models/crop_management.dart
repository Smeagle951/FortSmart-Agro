import 'package:uuid/uuid.dart';

/// Enum para definir o tipo de item: praga, doença ou planta daninha
enum ItemType {
  pest,     // Praga
  disease,  // Doença
  weed,     // Planta daninha
}

/// Enum para definir o tipo de origem: padrão ou personalizado
enum OriginType {
  standard,    // Padrão do sistema
  custom,      // Personalizado pelo usuário
}

/// Enum para definir o nível de alerta
enum AlertLevel {
  low,      // Baixo
  medium,   // Médio
  high,     // Alto
}

/// Modelo para representar uma cultura
class Crop {
  final String id;
  final String name;
  final OriginType origin;
  final String? createdBy; // ID do usuário, se for personalizado
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Crop({
    String? id,
    required this.name,
    this.origin = OriginType.standard,
    this.createdBy,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  Crop copyWith({
    String? id,
    String? name,
    OriginType? origin,
    String? createdBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'origin': origin.index,
      'createdBy': createdBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria um objeto a partir de um mapa
  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'],
      name: map['name'],
      origin: OriginType.values[map['origin'] ?? 0],
      createdBy: map['createdBy'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

/// Modelo para representar um item de cultura (praga ou doença)
class CropItem {
  final String id;
  final String cropId;
  final String name;
  final ItemType type;
  final OriginType origin;
  final String? createdBy; // ID do usuário, se for personalizado
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropItem({
    String? id,
    required this.cropId,
    required this.name,
    required this.type,
    this.origin = OriginType.standard,
    this.createdBy,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  CropItem copyWith({
    String? id,
    String? cropId,
    String? name,
    ItemType? type,
    OriginType? origin,
    String? createdBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropItem(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      name: name ?? this.name,
      type: type ?? this.type,
      origin: origin ?? this.origin,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'name': name,
      'type': type.index,
      'origin': origin.index,
      'createdBy': createdBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria um objeto a partir de um mapa
  factory CropItem.fromMap(Map<String, dynamic> map) {
    return CropItem(
      id: map['id'],
      cropId: map['cropId'],
      name: map['name'],
      type: ItemType.values[map['type'] ?? 0],
      origin: OriginType.values[map['origin'] ?? 0],
      createdBy: map['createdBy'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

/// Modelo para representar uma planta daninha
class Weed {
  final String id;
  final String name;
  final OriginType origin;
  final String? createdBy; // ID do usuário, se for personalizado
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Weed({
    String? id,
    required this.name,
    this.origin = OriginType.standard,
    this.createdBy,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  Weed copyWith({
    String? id,
    String? name,
    OriginType? origin,
    String? createdBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Weed(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'origin': origin.index,
      'createdBy': createdBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria um objeto a partir de um mapa
  factory Weed.fromMap(Map<String, dynamic> map) {
    return Weed(
      id: map['id'],
      name: map['name'],
      origin: OriginType.values[map['origin'] ?? 0],
      createdBy: map['createdBy'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

/// Modelo para representar um nível de alerta
class AlertLevelConfig {
  final String id;
  final String userId;
  final String cropId;
  final String itemId;
  final ItemType itemType;
  final AlertLevel level;
  final int minIndex;
  final int maxIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlertLevelConfig({
    String? id,
    required this.userId,
    required this.cropId,
    required this.itemId,
    required this.itemType,
    required this.level,
    required this.minIndex,
    required this.maxIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  AlertLevelConfig copyWith({
    String? id,
    String? userId,
    String? cropId,
    String? itemId,
    ItemType? itemType,
    AlertLevel? level,
    int? minIndex,
    int? maxIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertLevelConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cropId: cropId ?? this.cropId,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      level: level ?? this.level,
      minIndex: minIndex ?? this.minIndex,
      maxIndex: maxIndex ?? this.maxIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cropId': cropId,
      'itemId': itemId,
      'itemType': itemType.index,
      'level': level.index,
      'minIndex': minIndex,
      'maxIndex': maxIndex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria um objeto a partir de um mapa
  factory AlertLevelConfig.fromMap(Map<String, dynamic> map) {
    return AlertLevelConfig(
      id: map['id'],
      userId: map['userId'],
      cropId: map['cropId'],
      itemId: map['itemId'],
      itemType: ItemType.values[map['itemType'] ?? 0],
      level: AlertLevel.values[map['level'] ?? 0],
      minIndex: map['minIndex'] ?? 0,
      maxIndex: map['maxIndex'] ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
