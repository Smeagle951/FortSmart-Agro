import 'package:uuid/uuid.dart';

class StockModel {
  final String id;
  final DateTime dateTime;
  final String farm;
  final String product;
  final double quantity;
  final String unit;
  final String operationType; // Entrada, Saída, Ajuste
  final String? notes;
  final bool isSynced;

  StockModel({
    String? id,
    required this.dateTime,
    required this.farm,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.operationType,
    this.notes,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'farm': farm,
        'product': product,
        'quantity': quantity,
        'unit': unit,
        'operationType': operationType,
        'notes': notes,
        'isSynced': isSynced ? 1 : 0,
      };

  factory StockModel.fromMap(Map<String, dynamic> map) => StockModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        farm: map['farm'],
        product: map['product'],
        quantity: map['quantity'],
        unit: map['unit'],
        operationType: map['operationType'],
        notes: map['notes'],
        isSynced: map['isSynced'] == 1,
      );
}
