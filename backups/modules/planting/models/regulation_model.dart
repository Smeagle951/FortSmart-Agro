import 'package:uuid/uuid.dart';

class RegulationModel {
  final String id;
  final DateTime dateTime;
  final int numRows;
  final double wheelCircumference;
  final double testDistance;
  final List<double> weightsPerRow;
  final int drivingGear;
  final int drivenGear;
  final double rowSpacing;
  final String targetType; // 'kg/ha' or 'g/50m'
  final double targetValue;
  final double resultKgHa;
  final double resultG50m;
  final String operatorName;
  final String machine;
  final String? notes;
  final List<String>? photos;

  RegulationModel({
    String? id,
    required this.dateTime,
    required this.numRows,
    required this.wheelCircumference,
    required this.testDistance,
    required this.weightsPerRow,
    required this.drivingGear,
    required this.drivenGear,
    required this.rowSpacing,
    required this.targetType,
    required this.targetValue,
    required this.resultKgHa,
    required this.resultG50m,
    required this.operatorName,
    required this.machine,
    this.notes,
    this.photos,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'numRows': numRows,
        'wheelCircumference': wheelCircumference,
        'testDistance': testDistance,
        'weightsPerRow': weightsPerRow.join(','),
        'drivingGear': drivingGear,
        'drivenGear': drivenGear,
        'rowSpacing': rowSpacing,
        'targetType': targetType,
        'targetValue': targetValue,
        'resultKgHa': resultKgHa,
        'resultG50m': resultG50m,
        'operatorName': operatorName,
        'machine': machine,
        'notes': notes,
        'photos': photos?.join(',') ?? '',
      };

  factory RegulationModel.fromMap(Map<String, dynamic> map) => RegulationModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        numRows: map['numRows'],
        wheelCircumference: map['wheelCircumference'],
        testDistance: map['testDistance'],
        weightsPerRow: (map['weightsPerRow'] as String)
            .split(',')
            .map((e) => double.tryParse(e) ?? 0)
            .toList(),
        drivingGear: map['drivingGear'],
        drivenGear: map['drivenGear'],
        rowSpacing: map['rowSpacing'],
        targetType: map['targetType'],
        targetValue: map['targetValue'],
        resultKgHa: map['resultKgHa'],
        resultG50m: map['resultG50m'],
        operatorName: map['operatorName'],
        machine: map['machine'],
        notes: map['notes'],
        photos: (map['photos'] as String).isEmpty
            ? []
            : (map['photos'] as String).split(','),
      );
}
