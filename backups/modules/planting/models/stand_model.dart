import 'package:uuid/uuid.dart';

class StandModel {
  final String id;
  final DateTime dateTime;
  final int numPlants;
  final double evaluatedLength;
  final double rowSpacing;
  final double resultPlantsHa;

  StandModel({
    String? id,
    required this.dateTime,
    required this.numPlants,
    required this.evaluatedLength,
    required this.rowSpacing,
    required this.resultPlantsHa,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'numPlants': numPlants,
        'evaluatedLength': evaluatedLength,
        'rowSpacing': rowSpacing,
        'resultPlantsHa': resultPlantsHa,
      };

  factory StandModel.fromMap(Map<String, dynamic> map) => StandModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        numPlants: map['numPlants'],
        evaluatedLength: map['evaluatedLength'],
        rowSpacing: map['rowSpacing'],
        resultPlantsHa: map['resultPlantsHa'],
      );
}
