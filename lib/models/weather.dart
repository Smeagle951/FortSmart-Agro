import 'package:flutter/material.dart';

class WeatherData {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final CurrentWeather currentWeather;
  final List<ForecastDay> forecast;
  final AgriculturalDetails agriculturalDetails;

  WeatherData({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.currentWeather,
    required this.forecast,
    required this.agriculturalDetails,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      id: json['id'],
      locationName: json['locationName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      currentWeather: CurrentWeather.fromJson(json['currentWeather']),
      forecast: (json['forecast'] as List)
          .map((day) => ForecastDay.fromJson(day))
          .toList(),
      agriculturalDetails: AgriculturalDetails.fromJson(json['agriculturalDetails']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'currentWeather': currentWeather.toJson(),
      'forecast': forecast.map((day) => day.toJson()).toList(),
      'agriculturalDetails': agriculturalDetails.toJson(),
    };
  }
}

class CurrentWeather {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String windDirection;
  final int uvIndex;
  final double dewPoint;
  final String condition;
  final String conditionIcon;

  CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.uvIndex,
    required this.dewPoint,
    required this.condition,
    required this.conditionIcon,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: json['temperature'],
      humidity: json['humidity'],
      windSpeed: json['windSpeed'],
      windDirection: json['windDirection'],
      uvIndex: json['uvIndex'],
      dewPoint: json['dewPoint'],
      condition: json['condition'],
      conditionIcon: json['conditionIcon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'uvIndex': uvIndex,
      'dewPoint': dewPoint,
      'condition': condition,
      'conditionIcon': conditionIcon,
    };
  }

  String getUVIndexDescription() {
    if (uvIndex <= 2) return 'Baixo';
    if (uvIndex <= 5) return 'Moderado';
    if (uvIndex <= 7) return 'Alto';
    if (uvIndex <= 10) return 'Muito Alto';
    return 'Extremo';
  }

  IconData getConditionIcon() {
    switch (conditionIcon) {
      case 'clear':
        return Icons.wb_sunny;
      case 'partly-cloudy':
        return Icons.wb_cloudy;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'heavy-rain':
        return Icons.thunderstorm;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }
}

class ForecastDay {
  final String day;
  final String condition;
  final String conditionIcon;
  final double maxTemp;
  final double minTemp;
  final double precipitation;
  final int humidity;
  final double windSpeed;
  final String windDirection;
  final List<HourlyForecast> hourlyForecast;

  ForecastDay({
    required this.day,
    required this.condition,
    required this.conditionIcon,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.hourlyForecast,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      day: json['day'],
      condition: json['condition'],
      conditionIcon: json['conditionIcon'],
      maxTemp: json['maxTemp'],
      minTemp: json['minTemp'],
      precipitation: json['precipitation'],
      humidity: json['humidity'],
      windSpeed: json['windSpeed'],
      windDirection: json['windDirection'],
      hourlyForecast: (json['hourlyForecast'] as List)
          .map((hour) => HourlyForecast.fromJson(hour))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'condition': condition,
      'conditionIcon': conditionIcon,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'precipitation': precipitation,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'hourlyForecast': hourlyForecast.map((hour) => hour.toJson()).toList(),
    };
  }

  IconData getConditionIcon() {
    switch (conditionIcon) {
      case 'clear':
        return Icons.wb_sunny;
      case 'partly-cloudy':
        return Icons.wb_cloudy;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'heavy-rain':
        return Icons.thunderstorm;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }
}

class HourlyForecast {
  final int hour;
  final double temperature;
  final double precipitation;
  final int humidity;
  final double windSpeed;
  final String condition;

  HourlyForecast({
    required this.hour,
    required this.temperature,
    required this.precipitation,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      hour: json['hour'],
      temperature: json['temperature'],
      precipitation: json['precipitation'],
      humidity: json['humidity'],
      windSpeed: json['windSpeed'],
      condition: json['condition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'temperature': temperature,
      'precipitation': precipitation,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'condition': condition,
    };
  }
}

class AgriculturalDetails {
  final int rainProbabilityNext6h;
  final int sunshineHours;
  final bool idealHumidityForApplication;
  final String windStatusForSpraying;
  final String recommendation;
  final String bestApplicationWindow;

  AgriculturalDetails({
    required this.rainProbabilityNext6h,
    required this.sunshineHours,
    required this.idealHumidityForApplication,
    required this.windStatusForSpraying,
    required this.recommendation,
    required this.bestApplicationWindow,
  });

  factory AgriculturalDetails.fromJson(Map<String, dynamic> json) {
    return AgriculturalDetails(
      rainProbabilityNext6h: json['rainProbabilityNext6h'],
      sunshineHours: json['sunshineHours'],
      idealHumidityForApplication: json['idealHumidityForApplication'],
      windStatusForSpraying: json['windStatusForSpraying'],
      recommendation: json['recommendation'],
      bestApplicationWindow: json['bestApplicationWindow'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rainProbabilityNext6h': rainProbabilityNext6h,
      'sunshineHours': sunshineHours,
      'idealHumidityForApplication': idealHumidityForApplication,
      'windStatusForSpraying': windStatusForSpraying,
      'recommendation': recommendation,
      'bestApplicationWindow': bestApplicationWindow,
    };
  }

  String getWindStatusIcon() {
    switch (windStatusForSpraying) {
      case 'Ideal':
        return '✅';
      case 'Moderado':
        return '⚠️';
      case 'Alto':
        return '❌';
      default:
        return '⚠️';
    }
  }

  String getHumidityStatusIcon() {
    return idealHumidityForApplication ? '✅' : '❌';
  }
}
