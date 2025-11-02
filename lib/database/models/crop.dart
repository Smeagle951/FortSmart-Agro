class Crop {
  final int id;
  final String name;
  final String description;
  final int syncStatus;
  final int? remoteId;
  final String? scientificName;
  final int? growthCycle;
  final double? plantSpacing;
  final double? rowSpacing;
  final double? plantingDepth;
  final String? idealTemperature;
  final String? waterRequirement;
  
  // Propriedade para controle de sincronização
  bool get isSynced => syncStatus == 1;

  Crop({
    required this.id,
    required this.name,
    required this.description,
    this.syncStatus = 0,
    this.remoteId,
    this.scientificName,
    this.growthCycle,
    this.plantSpacing,
    this.rowSpacing,
    this.plantingDepth,
    this.idealTemperature,
    this.waterRequirement,
  });

  // Getter para verificar se a cultura é padrão do sistema
  bool get isDefault => id <= 10; // Considera as primeiras 10 culturas como padrão

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }
  
  // Alias para compatibilidade com o repositório
  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name']?.toString() ?? 'Desconhecida',
      description: map['description']?.toString() ?? 'Cultura desconhecida',
      syncStatus: map['sync_status'] is int ? map['sync_status'] : int.tryParse(map['sync_status'].toString()) ?? 0,
      remoteId: map['remote_id'] is int ? map['remote_id'] : int.tryParse(map['remote_id']?.toString() ?? ''),
    );
  }
  
  // Alias para compatibilidade com o repositório
  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop.fromMap(json);
  }

  // Getter para compatibilidade com outros modelos
  String get nome => name;

  // Getter para compatibilidade com outros modelos
  int get cor => 0xFF4CAF50;

  get iconPath => null;

  get color => null; // Verde padrão para culturas

  // Getter para compatibilidade com outros modelos
  int? get colorValue => 0xFF4CAF50; // Verde padrão

  Crop copyWith({
    int? id,
    String? name,
    String? description,
    int? syncStatus,
    int? remoteId,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
