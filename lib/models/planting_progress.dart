class PlantingProgress {
  final String id;
  final String plotId;
  final String plotName;
  final String cropType;
  final int dae; // Dias Após Emergência
  final int idealDae;
  final DateTime plantingDate;
  final String status;
  final double totalArea;
  final double plantedArea;

  PlantingProgress({
    required this.id,
    required this.plotId,
    required this.plotName,
    required this.cropType,
    required this.dae,
    required this.idealDae,
    required this.plantingDate,
    required this.status,
    required this.totalArea,
    required this.plantedArea,
  });
  
  double get progressPercentage => dae / idealDae * 100;
  
  static PlantingProgress fromMap(Map<String, dynamic> map) {
    return PlantingProgress(
      id: map['id'],
      plotId: map['plot_id'],
      plotName: map['plot_name'],
      cropType: map['crop_type'],
      dae: map['dae'] ?? 0,
      idealDae: map['ideal_dae'] ?? 0,
      plantingDate: DateTime.parse(map['planting_date']),
      status: map['status'] ?? 'Em andamento',
      totalArea: map['total_area'] ?? 0.0,
      plantedArea: map['planted_area'] ?? 0.0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plot_id': plotId,
      'plot_name': plotName,
      'crop_type': cropType,
      'dae': dae,
      'ideal_dae': idealDae,
      'planting_date': plantingDate.toIso8601String(),
      'status': status,
      'total_area': totalArea,
      'planted_area': plantedArea,
    };
  }
  
  PlantingProgress copyWith({
    String? id,
    String? plotId,
    String? plotName,
    String? cropType,
    int? dae,
    int? idealDae,
    DateTime? plantingDate,
    String? status,
    double? totalArea,
    double? plantedArea,
    String? progressPercentage,
  }) {
    return PlantingProgress(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropType: cropType ?? this.cropType,
      dae: dae ?? this.dae,
      idealDae: idealDae ?? this.idealDae,
      plantingDate: plantingDate ?? this.plantingDate,
      status: status ?? this.status,
      totalArea: totalArea ?? this.totalArea,
      plantedArea: plantedArea ?? this.plantedArea,
    );
  }
}
