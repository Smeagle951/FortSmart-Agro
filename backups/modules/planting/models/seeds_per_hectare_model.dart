import 'package:uuid/uuid.dart';

class SeedsPerHectareModel {
  final String id;
  final DateTime dateTime;
  final double rowSpacing;
  final double seedSpacing;
  final double thousandSeedWeight;
  final double? germination;
  final double? purity;
  final double resultSeedsHa;
  final double resultKgHa;
  final double? resultKgHaAdjusted;

  SeedsPerHectareModel({
    String? id,
    required this.dateTime,
    required this.rowSpacing,
    required this.seedSpacing,
    required this.thousandSeedWeight,
    this.germination,
    this.purity,
    required this.resultSeedsHa,
    required this.resultKgHa,
    this.resultKgHaAdjusted,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'rowSpacing': rowSpacing,
        'seedSpacing': seedSpacing,
        'thousandSeedWeight': thousandSeedWeight,
        'germination': germination,
        'purity': purity,
        'resultSeedsHa': resultSeedsHa,
        'resultKgHa': resultKgHa,
        'resultKgHaAdjusted': resultKgHaAdjusted,
      };

  factory SeedsPerHectareModel.fromMap(Map<String, dynamic> map) => SeedsPerHectareModel(
        id: map['id'],
        dateTime: DateTime.parse(map['dateTime']),
        rowSpacing: map['rowSpacing'],
        seedSpacing: map['seedSpacing'],
        thousandSeedWeight: map['thousandSeedWeight'],
        germination: map['germination'],
        purity: map['purity'],
        resultSeedsHa: map['resultSeedsHa'],
        resultKgHa: map['resultKgHa'],
        resultKgHaAdjusted: map['resultKgHaAdjusted'],
      );
}
