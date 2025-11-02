class Pest {
  final int id;
  final String name;
  final String scientificName;
  final String description;
  final int cropId;
  final bool isDefault;
  final int syncStatus;
  final int? remoteId;
  final String? type;
  final String? symptoms;
  final String? controlMethods;
  final String? unit;
  final String? economicDamageLevel;
  final String? monitoringMethod;
  final double? lowLimit;
  final double? mediumLimit;
  final double? highLimit;
  final List<int>? cropIds;

  Pest({
    required this.id,
    required this.name,
    required this.scientificName,
    this.description = '',
    required this.cropId,
    this.isDefault = true,
    this.syncStatus = 0,
    this.remoteId,
    this.type,
    this.symptoms,
    this.controlMethods,
    this.economicDamageLevel,
    this.cropIds,
    this.unit,
    this.monitoringMethod,
    this.lowLimit,
    this.mediumLimit,
    this.highLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'description': description,
      'crop_id': cropId,
      'is_default': isDefault ? 1 : 0,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }
  
  // Alias para compatibilidade com o repositório
  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory Pest.fromMap(Map<String, dynamic> map) {
    return Pest(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name']?.toString() ?? '',
      scientificName: map['scientific_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      cropId: map['crop_id'] is int ? map['crop_id'] : int.tryParse(map['crop_id'].toString()) ?? 0,
      isDefault: map['is_default'] == 1,
      syncStatus: map['sync_status'] is int ? map['sync_status'] : int.tryParse(map['sync_status'].toString()) ?? 0,
      remoteId: map['remote_id'] is int ? map['remote_id'] : 
                map['remote_id'] is String ? int.tryParse(map['remote_id']) : null,
    );
  }
  
  // Alias para compatibilidade com o repositório
  factory Pest.fromJson(Map<String, dynamic> json) {
    return Pest.fromMap(json);
  }

  Pest copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? description,
    int? cropId,
    bool? isDefault,
    int? syncStatus,
    int? remoteId,
  }) {
    return Pest(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      cropId: cropId ?? this.cropId,
      isDefault: isDefault ?? this.isDefault,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
