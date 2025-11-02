import 'package:uuid/uuid.dart';

class ExperimentModel {
  final String id;
  final DateTime dateTime;
  final String experimentName;
  final List<String> varieties;
  final String plotDelimitation;
  final DateTime plantingDate;
  final String conditions;
  final String treatments;
  final List<String>? photos;
  final List<ExperimentEvaluation> evaluations;
  final double? harvestedProductionKg;
  final double? harvestedProductionBags;
  final String? productivityAnalysis;

  ExperimentModel({
    String? id,
    required this.dateTime,
    required this.experimentName,
    required this.varieties,
    required this.plotDelimitation,
    required this.plantingDate,
    required this.conditions,
    required this.treatments,
    this.photos,
    required this.evaluations,
    this.harvestedProductionKg,
    this.harvestedProductionBags,
    this.productivityAnalysis,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'experimentName': experimentName,
        'varieties': varieties.join(','),
        'plotDelimitation': plotDelimitation,
        'plantingDate': plantingDate.toIso8601String(),
        'conditions': conditions,
        'treatments': treatments,
        'photos': photos?.join(',') ?? '',
        'evaluations': evaluations.map((e) => e.toMap()).toList(),
        'harvestedProductionKg': harvestedProductionKg,
        'harvestedProductionBags': harvestedProductionBags,
        'productivityAnalysis': productivityAnalysis,
      };

  factory ExperimentModel.fromMap(Map<String, dynamic> map) => ExperimentModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        experimentName: map['experimentName'],
        varieties: (map['varieties'] as String).split(','),
        plotDelimitation: map['plotDelimitation'],
        plantingDate: DateTime.parse(map['plantingDate']),
        conditions: map['conditions'],
        treatments: map['treatments'],
        photos: (map['photos'] as String).isEmpty ? [] : (map['photos'] as String).split(','),
        evaluations: (map['evaluations'] as List<dynamic>).map((e) => ExperimentEvaluation.fromMap(Map<String, dynamic>.from(e))).toList(),
        harvestedProductionKg: map['harvestedProductionKg'],
        harvestedProductionBags: map['harvestedProductionBags'],
        productivityAnalysis: map['productivityAnalysis'],
      );
}

class ExperimentEvaluation {
  final String id;
  final DateTime dateTime;
  final String type; // Emergência, Crescimento, Sanidade, etc
  final String description;
  final double? value;
  final String? photo;

  ExperimentEvaluation({
    String? id,
    required this.dateTime,
    required this.type,
    required this.description,
    this.value,
    this.photo,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'type': type,
        'description': description,
        'value': value,
        'photo': photo,
      };

  factory ExperimentEvaluation.fromMap(Map<String, dynamic> map) => ExperimentEvaluation(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        type: map['type'],
        description: map['description'],
        value: map['value'],
        photo: map['photo'],
      );
}
