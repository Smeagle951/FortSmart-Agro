import 'dart:convert';

class Experiment {
  final String? id;
  final String plotId;
  final String plotName;
  final String cropType;
  final String variety;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final int dae; // Dias Após Emergência
  final String status; // active, completed, canceled
  final Map<String, dynamic> results;
  final String? createdAt;
  final String? updatedAt;
  
  Experiment({
    this.id,
    required this.plotId,
    required this.plotName,
    required this.cropType,
    required this.variety,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.dae,
    required this.status,
    required this.results,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Experiment.fromMap(Map<String, dynamic> map) {
    return Experiment(
      id: map['id'],
      plotId: map['plot_id'],
      plotName: map['plot_name'],
      cropType: map['crop_type'],
      variety: map['variety'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      dae: map['dae'],
      status: map['status'],
      results: map['results'] != null 
          ? Map<String, dynamic>.from(map['results'] is String 
              ? Map<String, dynamic>.from(json.decode(map['results'])) 
              : map['results'])
          : {},
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plot_id': plotId,
      'plot_name': plotName,
      'crop_type': cropType,
      'variety': variety,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'dae': dae,
      'status': status,
      'results': results is String ? results : json.encode(results),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  Experiment copyWith({
    String? id,
    String? plotId,
    String? plotName,
    String? cropType,
    String? variety,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? dae,
    String? status,
    Map<String, dynamic>? results,
    String? createdAt,
    String? updatedAt,
  }) {
    return Experiment(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropType: cropType ?? this.cropType,
      variety: variety ?? this.variety,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dae: dae ?? this.dae,
      status: status ?? this.status,
      results: results ?? this.results,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
