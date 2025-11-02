class InventoryItem {
  int? id;
  String name;
  String? code;
  String category;
  double quantity;
  String unit;
  double? unitPrice;
  String? supplier;
  String? location;
  String? expirationDate;
  String? notes;
  String? pdfPath;
  String? type;
  String? formulation;
  String? manufacturer;
  double? minimumLevel;
  String? registrationNumber;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;

  InventoryItem({
    this.id,
    required this.name,
    this.code,
    required this.category,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.supplier,
    this.location,
    this.expirationDate,
    this.notes,
    this.pdfPath,
    this.type,
    this.formulation,
    this.manufacturer,
    this.minimumLevel,
    this.registrationNumber,
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
      category: map['category'],
      quantity: map['quantity'],
      unit: map['unit'],
      unitPrice: map['unit_price'],
      supplier: map['supplier'],
      location: map['location'],
      expirationDate: map['expiration_date'],
      notes: map['notes'],
      pdfPath: map['pdf_path'],
      type: map['type'],
      formulation: map['formulation'],
      manufacturer: map['manufacturer'],
      minimumLevel: map['minimum_level'] != null ? map['minimum_level'].toDouble() : null,
      registrationNumber: map['registration_number'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
    );
  }
  
  // Verifica se o produto está vencido
  bool isExpired() {
    if (expirationDate == null) return false;
    try {
      final expDate = DateTime.parse(expirationDate!);
      return expDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
  
  // Verifica se o produto está próximo do vencimento (30 dias)
  bool isNearExpiration() {
    if (expirationDate == null) return false;
    try {
      final expDate = DateTime.parse(expirationDate!);
      final today = DateTime.now();
      final daysUntilExpiration = expDate.difference(today).inDays;
      return !isExpired() && daysUntilExpiration <= 30;
    } catch (e) {
      return false;
    }
  }
  
  // Verifica se o estoque está abaixo do nível mínimo
  bool isBelowMinimumLevel() {
    if (minimumLevel == null) return false;
    return quantity <= minimumLevel!;
  }
  
  // Obter nome completo do produto
  String getFullName() {
    String fullName = name;
    if (formulation != null && formulation!.isNotEmpty) {
      fullName += ' $formulation';
    }
    if (type != null && type!.isNotEmpty) {
      fullName += ' ($type)';
    }
    return fullName;
  }
  
  // Obter quantidade formatada com unidade
  String getFormattedQuantity() {
    return '$quantity $unit';
  }

  // Converter de objeto InventoryItem para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'supplier': supplier,
      'location': location,
      'expiration_date': expirationDate,
      'notes': notes,
      'pdf_path': pdfPath,
      'type': type,
      'formulation': formulation,
      'manufacturer': manufacturer,
      'minimum_level': minimumLevel,
      'registration_number': registrationNumber,
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
    String? code,
    String? category,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? supplier,
    String? location,
    String? expirationDate,
    String? notes,
    String? pdfPath,
    String? type,
    String? formulation,
    String? manufacturer,
    double? minimumLevel,
    String? registrationNumber,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      expirationDate: expirationDate ?? this.expirationDate,
      notes: notes ?? this.notes,
      pdfPath: pdfPath ?? this.pdfPath,
      type: type ?? this.type,
      formulation: formulation ?? this.formulation,
      manufacturer: manufacturer ?? this.manufacturer,
      minimumLevel: minimumLevel ?? this.minimumLevel,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  // Calcular o valor total do item (quantidade * preço unitário)
  double get totalValue => quantity * (unitPrice ?? 0);
}
