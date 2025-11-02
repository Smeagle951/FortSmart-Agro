import 'formulation_type.dart';
import 'dose_unit.dart';

/// Modelo para produto agrícola
class Product {
  final int? id;
  final String name;
  final String manufacturer;
  final FormulationType formulation;
  final double dose;
  final DoseUnit doseUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.manufacturer,
    required this.formulation,
    required this.dose,
    required this.doseUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'formulation': formulation.code,
      'dose': dose,
      'dose_unit': doseUnit.symbol,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      manufacturer: map['manufacturer'],
      formulation: FormulationType.values.firstWhere(
        (f) => f.code == map['formulation'],
        orElse: () => FormulationType.ec,
      ),
      dose: map['dose']?.toDouble() ?? 0.0,
      doseUnit: DoseUnit.values.firstWhere(
        (u) => u.symbol == map['dose_unit'],
        orElse: () => DoseUnit.l,
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? manufacturer,
    FormulationType? formulation,
    double? dose,
    DoseUnit? doseUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      formulation: formulation ?? this.formulation,
      dose: dose ?? this.dose,
      doseUnit: doseUnit ?? this.doseUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
