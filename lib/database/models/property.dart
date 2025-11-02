class Property {
  int? id;
  String name;
  String? address;
  String? city;
  String? state;
  double? totalArea;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;
  String? polygonJson;

  Property({
    this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.totalArea,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
    this.polygonJson,
  });

  // Converter de Map para objeto Property
  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      totalArea: map['total_area'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
      polygonJson: map['polygon_json'],
    );
  }

  // Converter para Map para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'total_area': totalArea,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
      'polygon_json': polygonJson,
    };
  }

  // Converter para o modelo de Property da aplicação
  dynamic toAppModel() {
    // Importamos no topo do arquivo, não aqui dentro do método
    // Retornamos um mapa que pode ser usado para criar um Property da aplicação
    return {
      'id': id ?? 0,
      'name': name,
      'address': address,
      'area': totalArea,
      'syncStatus': syncStatus,
    };
  }

  // Criar uma cópia do objeto com alterações
  Property copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    String? state,
    double? totalArea,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
    String? polygonJson,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      totalArea: totalArea ?? this.totalArea,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      polygonJson: polygonJson ?? this.polygonJson,
    );
  }
}
