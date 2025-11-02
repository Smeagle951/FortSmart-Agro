import 'product.dart';
import 'calda_config.dart';

/// Receita de calda com produtos e configurações
class CaldaRecipe {
  final int? id;
  final String name;
  final CaldaConfig config;
  final List<Product> products;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaldaRecipe({
    this.id,
    required this.name,
    required this.config,
    required this.products,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'volume_liters': config.volumeLiters,
      'flow_rate': config.flowRate,
      'is_flow_per_hectare': config.isFlowPerHectare ? 1 : 0,
      'area': config.area,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CaldaRecipe.fromMap(Map<String, dynamic> map) {
    return CaldaRecipe(
      id: map['id'],
      name: map['name'],
      config: CaldaConfig(
        volumeLiters: map['volume_liters']?.toDouble() ?? 0.0,
        flowRate: map['flow_rate']?.toDouble() ?? 0.0,
        isFlowPerHectare: (map['is_flow_per_hectare'] ?? 0) == 1,
        area: map['area']?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(map['created_at']),
      ),
      products: [], // Será carregado separadamente
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  CaldaRecipe copyWith({
    int? id,
    String? name,
    CaldaConfig? config,
    List<Product>? products,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaldaRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      config: config ?? this.config,
      products: products ?? this.products,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
