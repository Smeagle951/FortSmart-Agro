class PrescriptionItem {
  int? id;
  int prescriptionId;
  int? productId;
  String productName;
  double dosage;
  String dosageUnit;
  double? area;
  String? areaUnit;
  String? category;
  String? instructions;
  String? notes;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;
  
  // Campos adicionais para exibição no PDF
  String get name => productName;
  String get unit => dosageUnit;
  double get amount => dosage;

  PrescriptionItem({
    this.id,
    required this.prescriptionId,
    this.productId,
    required this.productName,
    required this.dosage,
    required this.dosageUnit,
    this.area,
    this.areaUnit,
    this.category,
    this.instructions,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
  });

  // Converter de Map para objeto PrescriptionItem
  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      id: map['id'],
      prescriptionId: map['prescription_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      dosage: map['dosage'],
      dosageUnit: map['dosage_unit'],
      area: map['area'],
      areaUnit: map['area_unit'],
      category: map['category'],
      instructions: map['instructions'],
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
    );
  }

  // Converter de objeto PrescriptionItem para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prescription_id': prescriptionId,
      'product_id': productId,
      'product_name': productName,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'area': area,
      'area_unit': areaUnit,
      'category': category,
      'instructions': instructions,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  // Criar uma cópia do objeto com alterações
  PrescriptionItem copyWith({
    int? id,
    int? prescriptionId,
    int? productId,
    String? productName,
    double? dosage,
    String? dosageUnit,
    double? area,
    String? areaUnit,
    String? category,
    String? instructions,
    String? notes,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      category: category ?? this.category,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
