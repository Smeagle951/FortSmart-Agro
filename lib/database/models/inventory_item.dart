class InventoryItem {
  int? id;
  String name;
  String? code;
  String type;
  String formulation;
  String unit;
  double quantity;
  double? unitPrice;
  String? supplier;
  String location;
  DateTime? expirationDate;
  String? manufacturer;
  double? minimumLevel;
  String? registrationNumber;
  String? pdfPath;
  String? activeIngredient;
  String? notes;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;

  InventoryItem({
    this.id,
    required this.name,
    this.code,
    required this.type,
    required this.formulation,
    required this.unit,
    required this.quantity,
    this.unitPrice,
    this.supplier,
    required this.location,
    this.expirationDate,
    this.manufacturer,
    this.minimumLevel,
    this.registrationNumber,
    this.pdfPath,
    this.activeIngredient,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
  });

  // Converter de Map para objeto InventoryItem
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      type: map['type'],
      formulation: map['formulation'],
      unit: map['unit'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      supplier: map['supplier'],
      location: map['location'],
      expirationDate: map['expiration_date'] != null
          ? DateTime.parse(map['expiration_date'])
          : null,
      manufacturer: map['manufacturer'],
      minimumLevel: map['minimum_level'],
      registrationNumber: map['registration_number'],
      pdfPath: map['pdf_path'],
      activeIngredient: map['active_ingredient'],
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 0,
      remoteId: map['remote_id'],
    );
  }

  // Converter de objeto InventoryItem para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'formulation': formulation,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'supplier': supplier,
      'location': location,
      'expiration_date': expirationDate?.toIso8601String(),
      'manufacturer': manufacturer,
      'minimum_level': minimumLevel,
      'registration_number': registrationNumber,
      'pdf_path': pdfPath,
      'active_ingredient': activeIngredient,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  // Criar uma cópia do objeto com alterações
  InventoryItem copyWith({
    int? id,
    String? name,
    String? type,
    String? formulation,
    String? unit,
    double? quantity,
    String? location,
    DateTime? expirationDate,
    String? manufacturer,
    double? minimumLevel,
    String? registrationNumber,
    String? pdfPath,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      formulation: formulation ?? this.formulation,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      expirationDate: expirationDate ?? this.expirationDate,
      manufacturer: manufacturer ?? this.manufacturer,
      minimumLevel: minimumLevel ?? this.minimumLevel,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  // Obter nome completo do produto (nome + formulação)
  String getFullName() {
    return '$name $formulation $unit';
  }

  // Obter quantidade formatada com unidade
  String getFormattedQuantity() {
    return '$quantity $unit';
  }
  
  // Verifica se o produto está vencido
  bool isExpired() {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }
  
  // Verifica se o produto está próximo do vencimento (30 dias)
  bool isNearExpiration() {
    if (expirationDate == null) return false;
    final today = DateTime.now();
    final daysUntilExpiration = expirationDate!.difference(today).inDays;
    return !isExpired() && daysUntilExpiration <= 30;
  }
  
  // Verifica se o estoque está abaixo do nível mínimo
  bool isBelowMinimumLevel() {
    if (minimumLevel == null) return false;
    return quantity <= minimumLevel!;
  }
}
