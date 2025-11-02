class Property {
  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? area;
  final int? userId;
  final int syncStatus; // 0: não sincronizado, 1: sincronizado

  Property({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.area,
    this.userId,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'userId': userId,
      'syncStatus': syncStatus,
    };
  }
  
  // Converter do modelo do banco de dados para o modelo da aplicação
  static Property fromDbModel(dynamic dbProperty) {
    if (dbProperty is Map<String, dynamic>) {
      // Se for um mapa (resultado do método toAppModel)
      return Property(
        id: dbProperty['id'] ?? 0,
        name: dbProperty['name'] ?? '',
        address: dbProperty['address'],
        area: dbProperty['area'],
        syncStatus: dbProperty['syncStatus'] ?? 0,
      );
    } else {
      // Se for um objeto Property do banco de dados
      return Property(
        id: dbProperty.id ?? 0,
        name: dbProperty.name,
        address: dbProperty.address,
        area: dbProperty.totalArea,
        syncStatus: dbProperty.syncStatus,
      );
    }
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      area: map['area'],
      userId: map['userId'],
      syncStatus: map['syncStatus'] ?? 0,
    );
  }

  Property copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? area,
    int? userId,
    int? syncStatus,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      area: area ?? this.area,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
