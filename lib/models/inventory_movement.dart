import 'package:intl/intl.dart';
import '../database/models/inventory_movement.dart' as db;

/// Tipos de movimentação de estoque
enum MovementType {
  entry,       // Entrada
  exit,        // Saída
  adjustment,  // Ajuste
  transfer,    // Transferência
  application  // Aplicação
}

/// Modelo para representar uma movimentação de estoque
/// Esta classe serve como adaptador para o modelo de banco de dados
class InventoryMovement {
  final String? id;
  final String inventoryItemId;
  final MovementType type;
  final double quantity;
  final String purpose; // Finalidade da movimentação (ex: "Importação por Planilha", "Aplicação no Talhão X")
  final String responsiblePerson;
  final DateTime date;
  final String? documentNumber; // Número da nota fiscal, etc.
  final String? relatedDocumentId; // ID do documento relacionado (ex: ID da aplicação)
  final String? relatedDocumentType; // Tipo do documento relacionado (ex: "Aplicação", "Importação")
  final String? pdfPath; // Caminho para o PDF relacionado
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? previousQuantity;
  final double? newQuantity;
  
  // Campos adicionais para exibição na interface
  final String? itemName;
  final String? itemFormulation;
  final String? itemUnit;
  final String? itemId; // Adicionando a propriedade itemId
  final String? reason; // Adicionando a propriedade reason

  InventoryMovement({
    this.id,
    required this.inventoryItemId,
    required this.type,
    required this.quantity,
    required this.purpose,
    required this.responsiblePerson,
    required this.date,
    this.documentNumber,
    this.relatedDocumentId,
    this.relatedDocumentType,
    this.pdfPath,
    this.syncStatus = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.previousQuantity,
    this.newQuantity,
    this.itemName,
    this.itemFormulation,
    this.itemUnit,
    this.itemId, // Adicionando o parâmetro itemId
    this.reason, // Adicionando o parâmetro reason
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia da movimentação com valores atualizados
  InventoryMovement copyWith({
    String? id,
    String? inventoryItemId,
    MovementType? type,
    double? quantity,
    String? purpose,
    String? responsiblePerson,
    DateTime? date,
    String? documentNumber,
    String? relatedDocumentId,
    String? relatedDocumentType,
    String? pdfPath,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? previousQuantity,
    double? newQuantity,
    String? itemName,
    String? itemFormulation,
    String? itemUnit,
    String? itemId, // Adicionando o parâmetro itemId
    String? reason, // Adicionando o parâmetro reason
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      purpose: purpose ?? this.purpose,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      date: date ?? this.date,
      documentNumber: documentNumber ?? this.documentNumber,
      relatedDocumentId: relatedDocumentId ?? this.relatedDocumentId,
      relatedDocumentType: relatedDocumentType ?? this.relatedDocumentType,
      pdfPath: pdfPath ?? this.pdfPath,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      itemName: itemName ?? this.itemName,
      itemFormulation: itemFormulation ?? this.itemFormulation,
      itemUnit: itemUnit ?? this.itemUnit,
      itemId: itemId ?? this.itemId, // Adicionando o parâmetro itemId
      reason: reason ?? this.reason, // Adicionando o parâmetro reason
    );
  }

  /// Converte a movimentação para um mapa (para armazenamento no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id != null ? int.tryParse(id!) : null,
      'inventory_item_id': inventoryItemId,
      'item_id': int.tryParse(inventoryItemId),
      'type': type == MovementType.entry ? 'entry' : 'exit',
      'quantity': quantity,
      'purpose': purpose,
      'reason': reason ?? purpose, // Mapeando purpose para reason para compatibilidade
      'responsible_person': responsiblePerson,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'document_number': documentNumber,
      'notes': documentNumber, // Mapeando documentNumber para notes para compatibilidade
      'related_document_id': relatedDocumentId,
      'related_document_type': relatedDocumentType,
      'activity_id': relatedDocumentId, // Mapeando relatedDocumentId para activityId para compatibilidade
      'pdf_path': pdfPath,
      'sync_status': syncStatus,
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
      'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(updatedAt),
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'item_id': itemId, // Adicionando o campo itemId
    };
  }

  /// Cria uma movimentação a partir de um mapa (do banco de dados)
  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id']?.toString(),
      inventoryItemId: map['inventory_item_id'] ?? map['item_id']?.toString() ?? '',
      type: (map['type'] == 'entry' || (map['quantity'] != null && map['quantity'] > 0)) 
          ? MovementType.entry 
          : MovementType.exit,
      quantity: map['quantity'] != null ? map['quantity'].abs() : 0.0,
      purpose: map['purpose'] ?? map['reason'] ?? '',
      reason: map['reason'], // Adicionando o campo reason
      responsiblePerson: map['responsible_person'] ?? '',
      date: map['date'] != null 
          ? (map['date'] is String 
              ? DateFormat('yyyy-MM-dd').parse(map['date']) 
              : map['date'])
          : DateTime.now(),
      documentNumber: map['document_number'] ?? map['notes'],
      relatedDocumentId: map['related_document_id'] ?? map['activity_id'],
      relatedDocumentType: map['related_document_type'],
      pdfPath: map['pdf_path'],
      syncStatus: map['sync_status'] ?? 0,
      createdAt: map['created_at'] is String 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] is String 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['updated_at'])
          : DateTime.now(),
      previousQuantity: map['previous_quantity'],
      newQuantity: map['new_quantity'],
      itemId: map['item_id'], // Adicionando o campo itemId
    );
  }

  get unitPrice => null;

  get source => null;

  get notes => null;

  get unit => null;

  /// Converte um modelo de banco de dados para o modelo de aplicação
  static InventoryMovement fromDbModel(db.InventoryMovement dbModel) {
    // Determina o tipo de movimento com base na quantidade (positiva = entrada, negativa = saída)
    final type = dbModel.quantity >= 0 ? MovementType.entry : MovementType.exit;
    
    return InventoryMovement(
      id: dbModel.id?.toString(),
      inventoryItemId: dbModel.itemId.toString(),
      type: type,
      quantity: dbModel.quantity.abs(), // Usamos o valor absoluto para a quantidade
      purpose: dbModel.reason,
      reason: dbModel.reason, // Adicionando o campo reason
      responsiblePerson: 'Sistema', // Valor padrão, já que o modelo DB não tem este campo
      date: DateTime.tryParse(dbModel.createdAt) ?? DateTime.now(),
      documentNumber: dbModel.notes,
      relatedDocumentId: dbModel.activityId,
      relatedDocumentType: null,
      pdfPath: null,
      syncStatus: dbModel.syncStatus,
      createdAt: DateTime.tryParse(dbModel.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.now(),
      previousQuantity: dbModel.previousQuantity,
      newQuantity: dbModel.newQuantity,
      // Campos adicionais não estão no modelo de banco de dados
      // e devem ser preenchidos posteriormente
      itemName: null,
      itemFormulation: null,
      itemUnit: null,
      itemId: dbModel.itemId.toString(), // Adicionando o campo itemId
    );
  }

  /// Converte para o modelo de banco de dados
  db.InventoryMovement toDbModel() {
    return db.InventoryMovement(
      id: id != null ? int.tryParse(id!) : null,
      itemId: int.tryParse(inventoryItemId) ?? 0,
      // Para movimentos de saída, a quantidade é armazenada como negativa no banco de dados
      quantity: type == MovementType.entry ? quantity : -quantity,
      previousQuantity: previousQuantity ?? 0,
      newQuantity: newQuantity ?? 0,
      reason: reason ?? purpose, // Adicionando o campo reason
      activityId: relatedDocumentId,
      notes: documentNumber,
      createdAt: date.toIso8601String(),
      syncStatus: syncStatus,
      remoteId: null, // Não temos esse campo no modelo de aplicação
    );
  }

  /// Retorna o tipo de movimentação como string
  String getTypeString() {
    return type == MovementType.entry ? 'Entrada' : 'Saída';
  }

  /// Retorna a quantidade formatada com sinal (+ para entrada, - para saída)
  String getFormattedQuantity(String unit) {
    final sign = type == MovementType.entry ? '+' : '-';
    return '$sign ${quantity.toStringAsFixed(2)} $unit';
  }
}
