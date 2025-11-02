/// Configuração da calda (volume, vazão, área)
class CaldaConfig {
  final double volumeLiters;
  final double flowRate;
  final bool isFlowPerHectare;
  final double area;
  final DateTime createdAt;

  CaldaConfig({
    required this.volumeLiters,
    required this.flowRate,
    required this.isFlowPerHectare,
    required this.area,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'volume_liters': volumeLiters,
      'flow_rate': flowRate,
      'is_flow_per_hectare': isFlowPerHectare ? 1 : 0,
      'area': area,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CaldaConfig.fromMap(Map<String, dynamic> map) {
    return CaldaConfig(
      volumeLiters: map['volume_liters']?.toDouble() ?? 0.0,
      flowRate: map['flow_rate']?.toDouble() ?? 0.0,
      isFlowPerHectare: (map['is_flow_per_hectare'] ?? 0) == 1,
      area: map['area']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Calcula quantos hectares a calda pode cobrir
  double get hectaresCovered {
    if (isFlowPerHectare) {
      return volumeLiters / flowRate;
    } else {
      // Se vazão é por alqueire, converte para hectare (1 alqueire = 2.42 hectares)
      return (volumeLiters / flowRate) * 2.42;
    }
  }

  /// Calcula volume necessário por hectare
  double get volumePerHectare {
    if (isFlowPerHectare) {
      return flowRate;
    } else {
      // Converte de alqueire para hectare
      return flowRate / 2.42;
    }
  }
}
