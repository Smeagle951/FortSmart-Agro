/// Modelo para dados de organismos (pragas/doenças) da IA
class AIOrganismData {
  final int id;
  final String name;
  final String scientificName;
  final String type; // 'pest' ou 'disease'
  final List<String> crops;
  final List<String> symptoms;
  final List<String> managementStrategies;
  final String description;
  final String imageUrl;
  final Map<String, dynamic> characteristics;
  final double severity; // 0.0 a 1.0
  final List<String> keywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIOrganismData({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.type,
    required this.crops,
    required this.symptoms,
    required this.managementStrategies,
    required this.description,
    required this.imageUrl,
    this.characteristics = const {},
    this.severity = 0.5,
    this.keywords = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIOrganismData.fromMap(Map<String, dynamic> map) {
    return AIOrganismData(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      type: map['type'] ?? 'pest',
      crops: List<String>.from(map['crops'] ?? []),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      managementStrategies: List<String>.from(map['managementStrategies'] ?? []),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      characteristics: Map<String, dynamic>.from(map['characteristics'] ?? {}),
      severity: (map['severity'] ?? 0.5).toDouble(),
      keywords: List<String>.from(map['keywords'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'type': type,
      'crops': crops,
      'symptoms': symptoms,
      'managementStrategies': managementStrategies,
      'description': description,
      'imageUrl': imageUrl,
      'characteristics': characteristics,
      'severity': severity,
      'keywords': keywords,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AIOrganismData copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? type,
    List<String>? crops,
    List<String>? symptoms,
    List<String>? managementStrategies,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? characteristics,
    double? severity,
    List<String>? keywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIOrganismData(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      type: type ?? this.type,
      crops: crops ?? this.crops,
      symptoms: symptoms ?? this.symptoms,
      managementStrategies: managementStrategies ?? this.managementStrategies,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      characteristics: characteristics ?? this.characteristics,
      severity: severity ?? this.severity,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
