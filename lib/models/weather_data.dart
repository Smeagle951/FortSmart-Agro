import 'dart:convert';

/// Modelo para dados climáticos
class WeatherData {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final double temperature;
  final double? feelsLike;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final int visibility;
  final int clouds;
  final String condition;
  final String description;
  final String icon;
  final double uvIndex;
  final double dewPoint;
  final double sunHours;
  final DateTime timestamp;
  final String? farmId;
  final String? plotId;

  WeatherData({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.clouds,
    required this.condition,
    required this.description,
    required this.icon,
    required this.uvIndex,
    required this.dewPoint,
    required this.sunHours,
    required this.timestamp,
    this.farmId,
    this.plotId,
  });

  /// Cria uma cópia do objeto com campos atualizados
  WeatherData copyWith({
    String? id,
    String? locationName,
    double? latitude,
    double? longitude,
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    int? windDirection,
    double? pressure,
    int? visibility,
    int? clouds,
    String? condition,
    String? description,
    String? icon,
    double? uvIndex,
    double? dewPoint,
    double? sunHours,
    DateTime? timestamp,
    String? farmId,
    String? plotId,
  }) {
    return WeatherData(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      pressure: pressure ?? this.pressure,
      visibility: visibility ?? this.visibility,
      clouds: clouds ?? this.clouds,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      uvIndex: uvIndex ?? this.uvIndex,
      dewPoint: dewPoint ?? this.dewPoint,
      sunHours: sunHours ?? this.sunHours,
      timestamp: timestamp ?? this.timestamp,
      farmId: farmId ?? this.farmId,
      plotId: plotId ?? this.plotId,
    );
  }

  /// Converte para mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'visibility': visibility,
      'clouds': clouds,
      'condition': condition,
      'description': description,
      'icon': icon,
      'uvIndex': uvIndex,
      'dewPoint': dewPoint,
      'sunHours': sunHours,
      'timestamp': timestamp.toIso8601String(),
      'farmId': farmId,
      'plotId': plotId,
    };
  }

  /// Cria a partir de mapa
  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      id: map['id'] ?? '',
      locationName: map['locationName'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      temperature: map['temperature']?.toDouble() ?? 0.0,
      feelsLike: map['feelsLike']?.toDouble(),
      humidity: map['humidity']?.toInt() ?? 0,
      windSpeed: map['windSpeed']?.toDouble() ?? 0.0,
      windDirection: map['windDirection']?.toInt() ?? 0,
      pressure: map['pressure']?.toDouble() ?? 0.0,
      visibility: map['visibility']?.toInt() ?? 0,
      clouds: map['clouds']?.toInt() ?? 0,
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      uvIndex: map['uvIndex']?.toDouble() ?? 0.0,
      dewPoint: map['dewPoint']?.toDouble() ?? 0.0,
      sunHours: map['sunHours']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      farmId: map['farmId'],
      plotId: map['plotId'],
    );
  }

  /// Converte para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria a partir de JSON
  factory WeatherData.fromJson(String source) => WeatherData.fromMap(jsonDecode(source));

  /// Verifica se as condições são ideais para aplicação
  bool isIdealForApplication() {
    return humidity >= 50 && humidity <= 70 &&
           windSpeed >= 3 && windSpeed <= 10 &&
           uvIndex <= 8;
  }

  /// Retorna descrição do índice UV
  String getUvIndexDescription() {
    if (uvIndex <= 2) return 'Baixo';
    if (uvIndex <= 5) return 'Moderado';
    if (uvIndex <= 7) return 'Alto';
    if (uvIndex <= 10) return 'Muito Alto';
    return 'Extremo';
  }

  /// Retorna condições em português
  String get conditions {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Limpo';
      case 'clouds':
        return 'Nublado';
      case 'rain':
        return 'Chuva';
      case 'drizzle':
        return 'Chuvisco';
      case 'thunderstorm':
        return 'Tempestade';
      case 'snow':
        return 'Neve';
      case 'mist':
      case 'fog':
        return 'Neblina';
      default:
        return condition;
    }
  }
}

/// Modelo para previsão do tempo
class WeatherForecast {
  final String id;
  final DateTime forecastDate;
  final double temperature;
  final double temperatureMin;
  final double temperatureMax;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final String condition;
  final String description;
  final String icon;
  final double rainProbability;
  final double rainAmount;
  final double uvIndex;
  final String? farmId;
  final String? plotId;

  WeatherForecast({
    required this.id,
    required this.forecastDate,
    required this.temperature,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.condition,
    required this.description,
    required this.icon,
    required this.rainProbability,
    required this.rainAmount,
    required this.uvIndex,
    this.farmId,
    this.plotId,
  });

  /// Converte para mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'forecastDate': forecastDate.toIso8601String(),
      'temperature': temperature,
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'condition': condition,
      'description': description,
      'icon': icon,
      'rainProbability': rainProbability,
      'rainAmount': rainAmount,
      'uvIndex': uvIndex,
      'farmId': farmId,
      'plotId': plotId,
    };
  }

  /// Cria a partir de mapa
  factory WeatherForecast.fromMap(Map<String, dynamic> map) {
    return WeatherForecast(
      id: map['id'] ?? '',
      forecastDate: DateTime.parse(map['forecastDate']),
      temperature: map['temperature']?.toDouble() ?? 0.0,
      temperatureMin: map['temperatureMin']?.toDouble() ?? 0.0,
      temperatureMax: map['temperatureMax']?.toDouble() ?? 0.0,
      humidity: map['humidity']?.toInt() ?? 0,
      windSpeed: map['windSpeed']?.toDouble() ?? 0.0,
      windDirection: map['windDirection']?.toInt() ?? 0,
      pressure: map['pressure']?.toDouble() ?? 0.0,
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      rainProbability: map['rainProbability']?.toDouble() ?? 0.0,
      rainAmount: map['rainAmount']?.toDouble() ?? 0.0,
      uvIndex: map['uvIndex']?.toDouble() ?? 0.0,
      farmId: map['farmId'],
      plotId: map['plotId'],
    );
  }

  /// Converte para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria a partir de JSON
  factory WeatherForecast.fromJson(String source) => WeatherForecast.fromMap(jsonDecode(source));
}

/// Modelo para dados climáticos horários
class HourlyWeatherData {
  final String id;
  final DateTime timestamp;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final String condition;
  final String description;
  final String icon;
  final double rainProbability;
  final double rainAmount;
  final double uvIndex;
  final String? farmId;
  final String? plotId;

  HourlyWeatherData({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.condition,
    required this.description,
    required this.icon,
    required this.rainProbability,
    required this.rainAmount,
    required this.uvIndex,
    this.farmId,
    this.plotId,
  });

  /// Converte para mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'condition': condition,
      'description': description,
      'icon': icon,
      'rainProbability': rainProbability,
      'rainAmount': rainAmount,
      'uvIndex': uvIndex,
      'farmId': farmId,
      'plotId': plotId,
    };
  }

  /// Cria a partir de mapa
  factory HourlyWeatherData.fromMap(Map<String, dynamic> map) {
    return HourlyWeatherData(
      id: map['id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      temperature: map['temperature']?.toDouble() ?? 0.0,
      humidity: map['humidity']?.toInt() ?? 0,
      windSpeed: map['windSpeed']?.toDouble() ?? 0.0,
      windDirection: map['windDirection']?.toInt() ?? 0,
      pressure: map['pressure']?.toDouble() ?? 0.0,
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      rainProbability: map['rainProbability']?.toDouble() ?? 0.0,
      rainAmount: map['rainAmount']?.toDouble() ?? 0.0,
      uvIndex: map['uvIndex']?.toDouble() ?? 0.0,
      farmId: map['farmId'],
      plotId: map['plotId'],
    );
  }

  /// Converte para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria a partir de JSON
  factory HourlyWeatherData.fromJson(String source) => HourlyWeatherData.fromMap(jsonDecode(source));
}