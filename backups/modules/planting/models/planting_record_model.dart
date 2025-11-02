import 'package:uuid/uuid.dart';

class PlantingRecordModel {
  final String id;
  final DateTime dateTime;
  final String farm;
  final String plot;
  final String crop;
  final String variety;
  final DateTime plantingDate;
  final int numRows;
  final double rowSpacing;
  final double sowingDensity;
  final String? regulationNotes;
  final String operatorName;
  final String machine;
  final String? notes;
  final String? gpsCoordinates;
  final List<String>? photos;

  PlantingRecordModel({
    String? id,
    required this.dateTime,
    required this.farm,
    required this.plot,
    required this.crop,
    required this.variety,
    required this.plantingDate,
    required this.numRows,
    required this.rowSpacing,
    required this.sowingDensity,
    this.regulationNotes,
    required this.operatorName,
    required this.machine,
    this.notes,
    this.gpsCoordinates,
    this.photos,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'farm': farm,
        'plot': plot,
        'crop': crop,
        'variety': variety,
        'plantingDate': plantingDate.toIso8601String(),
        'numRows': numRows,
        'rowSpacing': rowSpacing,
        'sowingDensity': sowingDensity,
        'regulationNotes': regulationNotes,
        'operatorName': operatorName,
        'machine': machine,
        'notes': notes,
        'gpsCoordinates': gpsCoordinates,
        'photos': photos?.join(',') ?? '',
      };

  factory PlantingRecordModel.fromMap(Map<String, dynamic> map) => PlantingRecordModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        farm: map['farm'],
        plot: map['plot'],
        crop: map['crop'],
        variety: map['variety'],
        plantingDate: DateTime.parse(map['plantingDate']),
        numRows: map['numRows'],
        rowSpacing: map['rowSpacing'],
        sowingDensity: map['sowingDensity'],
        regulationNotes: map['regulationNotes'],
        operatorName: map['operatorName'],
        machine: map['machine'],
        notes: map['notes'],
        gpsCoordinates: map['gpsCoordinates'],
        photos: (map['photos'] as String).isEmpty
            ? []
            : (map['photos'] as String).split(','),
      );
}
