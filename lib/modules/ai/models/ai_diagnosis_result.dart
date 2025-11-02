/// Modelo para resultados de diagnóstico de IA
class AIDiagnosisResult {
  final int id;
  final String organismName;
  final String scientificName;
  final String cropName;
  final double confidence;
  final List<String> symptoms;
  final List<String> managementStrategies;
  final String description;
  final String imageUrl;
  final DateTime diagnosisDate;
  final String diagnosisMethod; // 'symptoms' ou 'image'
  final Map<String, dynamic> metadata;

  AIDiagnosisResult({
    required this.id,
    required this.organismName,
    required this.scientificName,
    required this.cropName,
    required this.confidence,
    required this.symptoms,
    required this.managementStrategies,
    required this.description,
    required this.imageUrl,
    required this.diagnosisDate,
    required this.diagnosisMethod,
    this.metadata = const {},
  });

  factory AIDiagnosisResult.fromMap(Map<String, dynamic> map) {
    return AIDiagnosisResult(
      id: map['id'] ?? 0,
      organismName: map['organismName'] ?? '',
      scientificName: map['scientificName'] ?? '',
      cropName: map['cropName'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      managementStrategies: List<String>.from(map['managementStrategies'] ?? []),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      diagnosisDate: DateTime.parse(map['diagnosisDate'] ?? DateTime.now().toIso8601String()),
      diagnosisMethod: map['diagnosisMethod'] ?? 'symptoms',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organismName': organismName,
      'scientificName': scientificName,
      'cropName': cropName,
      'confidence': confidence,
      'symptoms': symptoms,
      'managementStrategies': managementStrategies,
      'description': description,
      'imageUrl': imageUrl,
      'diagnosisDate': diagnosisDate.toIso8601String(),
      'diagnosisMethod': diagnosisMethod,
      'metadata': metadata,
    };
  }

  AIDiagnosisResult copyWith({
    int? id,
    String? organismName,
    String? scientificName,
    String? cropName,
    double? confidence,
    List<String>? symptoms,
    List<String>? managementStrategies,
    String? description,
    String? imageUrl,
    DateTime? diagnosisDate,
    String? diagnosisMethod,
    Map<String, dynamic>? metadata,
  }) {
    return AIDiagnosisResult(
      id: id ?? this.id,
      organismName: organismName ?? this.organismName,
      scientificName: scientificName ?? this.scientificName,
      cropName: cropName ?? this.cropName,
      confidence: confidence ?? this.confidence,
      symptoms: symptoms ?? this.symptoms,
      managementStrategies: managementStrategies ?? this.managementStrategies,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      diagnosisMethod: diagnosisMethod ?? this.diagnosisMethod,
      metadata: metadata ?? this.metadata,
    );
  }
}
