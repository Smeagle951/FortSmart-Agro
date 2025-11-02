class TrackModel {
  final int? id;
  final int? polygonId;
  final double lat;
  final double lon;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final String ts;
  final String? status;

  TrackModel({
    this.id,
    this.polygonId,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.ts,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'polygon_id': polygonId,
      'lat': lat,
      'lon': lon,
      'accuracy': accuracy,
      'speed': speed,
      'bearing': bearing,
      'ts': ts,
      'status': status,
    };
  }

  factory TrackModel.fromMap(Map<String, dynamic> map) {
    return TrackModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      polygonId: map['polygon_id'] is int ? map['polygon_id'] : int.tryParse(map['polygon_id'].toString()),
      lat: map['lat'] is double ? map['lat'] : double.tryParse(map['lat'].toString()) ?? 0.0,
      lon: map['lon'] is double ? map['lon'] : double.tryParse(map['lon'].toString()) ?? 0.0,
      accuracy: map['accuracy'] is double ? map['accuracy'] : double.tryParse(map['accuracy'].toString()),
      speed: map['speed'] is double ? map['speed'] : double.tryParse(map['speed'].toString()),
      bearing: map['bearing'] is double ? map['bearing'] : double.tryParse(map['bearing'].toString()),
      ts: map['ts']?.toString() ?? '',
      status: map['status']?.toString(),
    );
  }

  TrackModel copyWith({
    int? id,
    int? polygonId,
    double? lat,
    double? lon,
    double? accuracy,
    double? speed,
    double? bearing,
    String? ts,
    String? status,
  }) {
    return TrackModel(
      id: id ?? this.id,
      polygonId: polygonId ?? this.polygonId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      ts: ts ?? this.ts,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'TrackModel(id: $id, polygonId: $polygonId, lat: $lat, lon: $lon, ts: $ts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
