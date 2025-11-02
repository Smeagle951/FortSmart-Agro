class InventoryMovement {
  int? id;
  int itemId;
  double quantity;
  double previousQuantity;
  double newQuantity;
  String reason;
  String? activityId;
  String? notes;
  String createdAt;
  String updatedAt; // Adicionado campo updatedAt
  int syncStatus;
  int? remoteId;
  DateTime? date;

  InventoryMovement({
    this.id,
    required this.itemId,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    this.activityId,
    this.notes,
    required this.createdAt,
    String? updatedAt,
    this.syncStatus = 0,
    this.remoteId,
    this.date,
  }) : this.updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  // Converter de Map para objeto InventoryMovement
  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'],
      itemId: map['item_id'],
      quantity: map['quantity'],
      previousQuantity: map['previous_quantity'],
      newQuantity: map['new_quantity'],
      reason: map['reason'],
      activityId: map['activity_id'],
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
    );
  }

  // Converter de objeto InventoryMovement para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'reason': reason,
      'activity_id': activityId,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  // Criar uma cópia do objeto com alterações
  InventoryMovement copyWith({
    int? id,
    int? itemId,
    double? quantity,
    double? previousQuantity,
    double? newQuantity,
    String? reason,
    String? activityId,
    String? notes,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      reason: reason ?? this.reason,
      activityId: activityId ?? this.activityId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  // Verifica se é uma entrada ou saída
  bool get isAddition => quantity > 0;
}
