import 'package:uuid/uuid.dart';

class HarvestModel {
  final String id;
  final DateTime dateTime;
  final String farm;
  final String plot;
  final String crop;
  final double productivity;
  final double losses;
  final String operatorName;
  final String? notes;
  final List<String>? photos;
  final bool isSynced;

  HarvestModel({
    String? id,
    required this.dateTime,
    required this.farm,
    required this.plot,
    required this.crop,
    required this.productivity,
    required this.losses,
    required this.operatorName,
    this.notes,
    this.photos,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'farm': farm,
        'plot': plot,
        'crop': crop,
        'productivity': productivity,
        'losses': losses,
        'operatorName': operatorName,
        'notes': notes,
        'photos': photos?.join(',') ?? '',
        'isSynced': isSynced ? 1 : 0,
      };

  factory HarvestModel.fromMap(Map<String, dynamic> map) => HarvestModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        farm: map['farm'],
        plot: map['plot'],
        crop: map['crop'],
        productivity: map['productivity'],
        losses: map['losses'],
        operatorName: map['operatorName'],
        notes: map['notes'],
        photos: (map['photos'] as String).isEmpty ? [] : (map['photos'] as String).split(','),
        isSynced: map['isSynced'] == 1,
      );
}
