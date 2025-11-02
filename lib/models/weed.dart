import '../database/models/weed.dart' as db;

class Weed {
  final int? id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? imageUrl;
  final List<int>? cropIds; // IDs das culturas que esta planta daninha afeta
  final bool isSynced;
  final bool isDefault;
  final String? controlMethods;
  final String? growthHabit;
  final String? reproductionMethod;

  Weed({
    this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.imageUrl,
    this.cropIds,
    this.isSynced = false,
    this.isDefault = false,
    this.controlMethods,
    this.growthHabit,
    this.reproductionMethod,
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
      'growthHabit': growthHabit,
      'reproductionMethod': reproductionMethod,
    };
  }
  
  // Converter para o modelo de banco de dados
  db.Weed toDbModel() {
    return db.Weed(
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
  factory Weed.fromDbModel(db.Weed dbModel) {
    return Weed(
      id: dbModel.id,
      name: dbModel.name,
      description: dbModel.description,
      cropIds: [dbModel.cropId],
      isSynced: dbModel.syncStatus == 1,
      isDefault: true, // Por padrão, consideramos os modelos do banco como padrão
      scientificName: '',
      controlMethods: '',
      growthHabit: '',
      reproductionMethod: '',
    );
  }
  
  // Converter lista de modelos de banco de dados para lista de modelos de aplicação
  static List<Weed> fromDbModelList(List<db.Weed> dbModels) {
    return dbModels.map((dbModel) => Weed.fromDbModel(dbModel)).toList();
  }

  factory Weed.fromMap(Map<String, dynamic> map) {
    return Weed(
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

  Weed copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? description,
    String? imageUrl,
    List<int>? cropIds,
    bool? isSynced,
  }) {
    return Weed(
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
