/// Modelo para estatísticas do GPS
class GpsStats {
  final int totalPoints;
  final int validPoints;
  final double averageAccuracy;
  final double maxAccuracy;
  final double minAccuracy;
  final double totalDistance;
  final Duration trackingTime;
  final double averageSpeed;
  final double maxSpeed;
  final DateTime startTime;
  final DateTime? endTime;

  const GpsStats({
    required this.totalPoints,
    required this.validPoints,
    required this.averageAccuracy,
    required this.maxAccuracy,
    required this.minAccuracy,
    required this.totalDistance,
    required this.trackingTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.startTime,
    this.endTime,
  });

  /// Cria estatísticas vazias
  factory GpsStats.empty() {
    final now = DateTime.now();
    return GpsStats(
      totalPoints: 0,
      validPoints: 0,
      averageAccuracy: 0.0,
      maxAccuracy: 0.0,
      minAccuracy: 0.0,
      totalDistance: 0.0,
      trackingTime: Duration.zero,
      averageSpeed: 0.0,
      maxSpeed: 0.0,
      startTime: now,
      endTime: now,
    );
  }

  /// Cria uma cópia com novos valores
  GpsStats copyWith({
    int? totalPoints,
    int? validPoints,
    double? averageAccuracy,
    double? maxAccuracy,
    double? minAccuracy,
    double? totalDistance,
    Duration? trackingTime,
    double? averageSpeed,
    double? maxSpeed,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return GpsStats(
      totalPoints: totalPoints ?? this.totalPoints,
      validPoints: validPoints ?? this.validPoints,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      maxAccuracy: maxAccuracy ?? this.maxAccuracy,
      minAccuracy: minAccuracy ?? this.minAccuracy,
      totalDistance: totalDistance ?? this.totalDistance,
      trackingTime: trackingTime ?? this.trackingTime,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Calcula a precisão média em metros
  String get accuracyText {
    if (averageAccuracy < 1) {
      return '${(averageAccuracy * 100).toStringAsFixed(0)} cm';
    } else {
      return '${averageAccuracy.toStringAsFixed(1)} m';
    }
  }

  /// Calcula a distância total formatada
  String get distanceText {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(1)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Calcula a velocidade média formatada
  String get speedText {
    if (averageSpeed < 1) {
      return '${(averageSpeed * 1000).toStringAsFixed(0)} mm/s';
    } else if (averageSpeed < 3.6) {
      return '${averageSpeed.toStringAsFixed(1)} m/s';
    } else {
      return '${(averageSpeed * 3.6).toStringAsFixed(1)} km/h';
    }
  }

  /// Calcula o tempo de rastreamento formatado
  String get timeText {
    final hours = trackingTime.inHours;
    final minutes = trackingTime.inMinutes.remainder(60);
    final seconds = trackingTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  String toString() {
    return 'GpsStats(totalPoints: $totalPoints, validPoints: $validPoints, '
           'averageAccuracy: $averageAccuracy, totalDistance: $totalDistance, '
           'trackingTime: $trackingTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GpsStats &&
        other.totalPoints == totalPoints &&
        other.validPoints == validPoints &&
        other.averageAccuracy == averageAccuracy &&
        other.maxAccuracy == maxAccuracy &&
        other.minAccuracy == minAccuracy &&
        other.totalDistance == totalDistance &&
        other.trackingTime == trackingTime &&
        other.averageSpeed == averageSpeed &&
        other.maxSpeed == maxSpeed &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalPoints,
      validPoints,
      averageAccuracy,
      maxAccuracy,
      minAccuracy,
      totalDistance,
      trackingTime,
      averageSpeed,
      maxSpeed,
      startTime,
      endTime,
    );
  }
}
