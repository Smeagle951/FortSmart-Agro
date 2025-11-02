import '../database/models/pest.dart' as db;

class Pest {
  final int? id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? imageUrl;
  final List<int>? cropIds; // IDs das culturas que esta praga afeta
  final bool isSynced;
  final bool isDefault;
  final String? controlMethods;
  final String? symptoms;
  final String? preventiveMeasures;

  Pest({
    this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.imageUrl,
    this.cropIds,
    this.isSynced = false,
    this.isDefault = false,
    this.controlMethods,
    this.symptoms,
    this.preventiveMeasures,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'imageUrl': imageUrl,
      'cropIds': cropIds != null ? cropIds!.join(',') : null,
      'isSynced': isSynced ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'controlMethods': controlMethods,
      'symptoms': symptoms,
      'preventiveMeasures': preventiveMeasures,
    };
  }
  
  // Converter para o modelo de banco de dados
  db.Pest toDbModel() {
    return db.Pest(
      id: id ?? 0,
      name: name,
      scientificName: scientificName ?? '',
      description: description ?? '',
      cropId: cropIds?.isNotEmpty == true ? cropIds!.first : 0,
      isDefault: true,
      syncStatus: isSynced ? 1 : 0,
    );
  }
  
  // Criar a partir do modelo de banco de dados
  factory Pest.fromDbModel(db.Pest dbModel) {
    return Pest(
      id: dbModel.id,
      name: dbModel.name,
      description: dbModel.description,
      cropIds: [dbModel.cropId],
      isSynced: dbModel.syncStatus == 1,
      isDefault: true, // Por padrão, consideramos os modelos do banco como padrão
      scientificName: '',
      controlMethods: '',
      symptoms: '',
      preventiveMeasures: '',
    );
  }
  
  // Converter lista de modelos de banco de dados para lista de modelos de aplicação
  static List<Pest> fromDbModelList(List<db.Pest> dbModels) {
    return dbModels.map((dbModel) => Pest.fromDbModel(dbModel)).toList();
  }

  factory Pest.fromMap(Map<String, dynamic> map) {
    return Pest(
      id: map['id'] is int ? map['id'] : 
          map['id'] is String ? int.tryParse(map['id']) : null,
      name: map['name']?.toString() ?? '',
      scientificName: map['scientificName']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      cropIds: map['cropIds'] != null && map['cropIds'].isNotEmpty
          ? (map['cropIds'] is String ? 
              map['cropIds'].split(',').map<int>((id) => int.tryParse(id) ?? 0).toList() :
              map['cropIds'] is List ? 
                map['cropIds'].map<int>((id) => id is int ? id : int.tryParse(id.toString()) ?? 0).toList() :
                [])
          : null,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  Pest copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? description,
    String? imageUrl,
    List<int>? cropIds,
    bool? isSynced,
  }) {
    return Pest(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      cropIds: cropIds ?? this.cropIds,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
