import 'package:uuid/uuid.dart';

/// Enum para os tipos de transação de estoque
enum TransactionType {
  entry,      // Entrada de produto
  manual,     // Saída manual
  application, // Saída por aplicação
  adjustment,  // Ajuste de estoque
}

/// Modelo para representar uma transação de estoque (entrada ou saída)
class InventoryTransactionModel {
  final String id;
  final String productId;
  final String batchNumber;
  final TransactionType type;
  final double quantity;
  final DateTime date;
  final String? applicationId; // ID da aplicação relacionada, se for uma saída por aplicação
  final String? plotId;       // ID do talhão relacionado, se for uma aplicação
  final String? cropId;       // ID da cultura relacionada, se for uma aplicação
  final String? notes;
  final String? reason; // Motivo da transação
  final String? reference; // Referência da transação
  final String? userId;
  final DateTime createdAt;
  final bool isSynced;

  InventoryTransactionModel({
    String? id,
    required this.productId,
    required this.batchNumber,
    required this.type,
    required this.quantity,
    DateTime? date,
    this.applicationId,
    this.plotId,
    this.cropId,
    this.notes,
    this.reason,
    this.reference,
    this.userId,
    DateTime? createdAt,
    this.isSynced = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.date = date ?? DateTime.now(),
    this.createdAt = createdAt ?? DateTime.now();

  /// Verifica se é uma entrada de estoque
  bool get isEntry => type == TransactionType.entry;

  /// Verifica se é uma saída de estoque
  bool get isExit => type == TransactionType.manual || type == TransactionType.application;

  /// Verifica se é um ajuste de estoque
  bool get isAdjustment => type == TransactionType.adjustment;

  /// Retorna o valor da transação (positivo para entrada, negativo para saída)
  double get value => isEntry ? quantity : -quantity;

  /// Cria uma cópia do modelo com os campos atualizados
  InventoryTransactionModel copyWith({
    String? id,
    String? productId,
    String? batchNumber,
    TransactionType? type,
    double? quantity,
    DateTime? date,
    String? applicationId,
    String? plotId,
    String? cropId,
    String? notes,
    String? reason,
    String? reference,
    String? userId,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return InventoryTransactionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      batchNumber: batchNumber ?? this.batchNumber,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      applicationId: applicationId ?? this.applicationId,
      plotId: plotId ?? this.plotId,
      cropId: cropId ?? this.cropId,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      reference: reference ?? this.reference,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'batch_number': batchNumber,
      'type': type.index,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'application_id': applicationId,
      'plot_id': plotId,
      'crop_id': cropId,
      'notes': notes,
      'reason': reason,
      'reference': reference,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransactionModel(
      id: map['id'],
      productId: map['product_id'],
      batchNumber: map['batch_number'],
      type: TransactionType.values[map['type']],
      quantity: map['quantity'],
      date: DateTime.parse(map['date']),
      applicationId: map['application_id'],
      plotId: map['plot_id'],
      cropId: map['crop_id'],
      notes: map['notes'],
      reason: map['reason'],
      reference: map['reference'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}
