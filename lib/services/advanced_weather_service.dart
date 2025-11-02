import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

/// Serviço avançado para dados do clima com cache e múltiplas APIs
class AdvancedWeatherService {
  // Chaves de API (configurar no arquivo de configuração)
  static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String _weatherApiKey = 'YOUR_WEATHER_API_KEY';
  
  // URLs das APIs
  static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _weatherApiBaseUrl = 'https://api.weatherapi.com/v1';
  
  // Chaves para cache
  static const String _lastLocationKey = 'last_weather_location';
  static const String _weatherDataKey = 'cached_weather_data';
  static const String _forecastDataKey = 'cached_forecast_data';
  static const String _hourlyDataKey = 'cached_hourly_data';
  
  // Duração do cache (30 minutos)
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  /// Obtém dados do clima atual
  Future<WeatherData?> fetchWeatherData({
    required double latitude,
    required double longitude,
    String? locationName,
    String? plotId,
    String? farmId,
  }) async {
    try {
      print('🌤️ Buscando dados do clima para $latitude, $longitude');
      
      // Tentar OpenWeatherMap primeiro
      final openWeatherData = await _getOpenWeatherData(latitude, longitude);
      if (openWeatherData != null) {
        final weatherData = _formatOpenWeatherData(openWeatherData, locationName, plotId, farmId);
        await _cacheWeatherData(weatherData);
        return weatherData;
      }
      
      // Fallback para WeatherAPI
      final weatherApiData = await _getWeatherApiData(latitude, longitude);
      if (weatherApiData != null) {
        final weatherData = _formatWeatherApiData(weatherApiData, locationName, plotId, farmId);
        await _cacheWeatherData(weatherData);
        return weatherData;
      }
      
      // Fallback para dados simulados
      return _getSimulatedWeatherData(locationName, plotId, farmId);
      
    } catch (e) {
      print('❌ Erro ao obter dados do clima: $e');
      return _getSimulatedWeatherData(locationName, plotId, farmId);
    }
  }
  
  /// Obtém previsão do tempo para os próximos dias
  Future<List<WeatherForecast>> fetchForecast({
    required double latitude,
    required double longitude,
    String? locationName,
    int days = 3,
  }) async {
    try {
      print('🌤️ Buscando previsão do tempo para $days dias');
      
      // Tentar OpenWeatherMap primeiro
      final forecastData = await _getOpenWeatherForecast(latitude, longitude, days);
      if (forecastData != null) {
        final forecasts = _formatOpenWeatherForecast(forecastData, locationName);
        await _cacheForecastData(forecasts);
        return forecasts;
      }
      
      // Fallback para WeatherAPI
      final weatherApiForecast = await _getWeatherApiForecast(latitude, longitude, days);
      if (weatherApiForecast != null) {
        final forecasts = _formatWeatherApiForecast(weatherApiForecast, locationName);
        await _cacheForecastData(forecasts);
        return forecasts;
      }
      
      // Fallback para dados simulados
      return _getSimulatedForecast(days, locationName);
      
    } catch (e) {
      print('❌ Erro ao obter previsão do tempo: $e');
      return _getSimulatedForecast(days, locationName);
    }
  }
  
  /// Obtém dados horários
  Future<List<HourlyWeatherData>> fetchHourlyData({
    required double latitude,
    required double longitude,
    String? locationName,
    int hours = 24,
  }) async {
    try {
      print('🌤️ Buscando dados horários para $hours horas');
      
      // Tentar OpenWeatherMap primeiro
      final hourlyData = await _getOpenWeatherHourly(latitude, longitude, hours);
      if (hourlyData != null) {
        final hourly = _formatOpenWeatherHourly(hourlyData, locationName);
        await _cacheHourlyData(hourly);
        return hourly;
      }
      
      // Fallback para WeatherAPI
      final weatherApiHourly = await _getWeatherApiHourly(latitude, longitude, hours);
      if (weatherApiHourly != null) {
        final hourly = _formatWeatherApiHourly(weatherApiHourly, locationName);
        await _cacheHourlyData(hourly);
        return hourly;
      }
      
      // Fallback para dados simulados
      return _getSimulatedHourlyData(hours, locationName);
      
    } catch (e) {
      print('❌ Erro ao obter dados horários: $e');
      return _getSimulatedHourlyData(hours, locationName);
    }
  }
  
  /// Obtém localização atual
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Serviços de localização estão desativados.';
    }
    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permissões de localização foram negadas.';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'Permissões de localização foram permanentemente negadas.';
    }
    
    return await Geolocator.getCurrentPosition();
  }
  
  /// Salva última localização usada
  Future<void> saveLastLocation(String locationName, double latitude, double longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLocationKey, jsonEncode({
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      print('❌ Erro ao salvar localização: $e');
    }
  }
  
  /// Obtém última localização salva
  Future<Map<String, dynamic>?> getLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_lastLocationKey);
      if (locationJson != null) {
        return jsonDecode(locationJson);
      }
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
    }
    return null;
  }
  
  /// Obtém dados climáticos mais recentes do cache
  Future<WeatherData?> getLatestWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = prefs.getString(_weatherDataKey);
      if (weatherJson != null) {
        final data = jsonDecode(weatherJson);
        final timestamp = DateTime.parse(data['timestamp']);
        
        // Verifica se os dados não estão muito antigos
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return WeatherData.fromMap(data);
        }
      }
    } catch (e) {
      print('❌ Erro ao obter dados do cache: $e');
    }
    return null;
  }
  
  /// Obtém previsões do cache
  Future<List<WeatherForecast>> getForecasts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final forecastsJson = prefs.getString(_forecastDataKey);
      if (forecastsJson != null) {
        final data = jsonDecode(forecastsJson);
        final timestamp = DateTime.parse(data['timestamp']);
        
        // Verifica se os dados não estão muito antigos
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return (data['forecasts'] as List)
              .map((f) => WeatherForecast.fromMap(f))
              .toList();
        }
      }
    } catch (e) {
      print('❌ Erro ao obter previsões do cache: $e');
    }
    return [];
  }
  
  /// Obtém dados horários do cache
  Future<List<HourlyWeatherData>> getHourlyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hourlyJson = prefs.getString(_hourlyDataKey);
      if (hourlyJson != null) {
        final data = jsonDecode(hourlyJson);
        final timestamp = DateTime.parse(data['timestamp']);
        
        // Verifica se os dados não estão muito antigos
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return (data['hourly'] as List)
              .map((h) => HourlyWeatherData.fromMap(h))
              .toList();
        }
      }
    } catch (e) {
      print('❌ Erro ao obter dados horários do cache: $e');
    }
    return [];
  }
  
  /// Verifica se os dados climáticos estão desatualizados
  Future<bool> isWeatherDataOutdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = prefs.getString(_weatherDataKey);
      if (weatherJson != null) {
        final data = jsonDecode(weatherJson);
        final timestamp = DateTime.parse(data['timestamp']);
        return DateTime.now().difference(timestamp) >= _cacheDuration;
      }
    } catch (e) {
      print('❌ Erro ao verificar dados: $e');
    }
    return true;
  }
  
  // ===== MÉTODOS PRIVADOS - OPENWEATHERMAP =====
  
  /// Obtém dados do OpenWeatherMap
  Future<Map<String, dynamic>?> _getOpenWeatherData(double lat, double lon) async {
    try {
      final url = '$_openWeatherBaseUrl/weather?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=pt_br';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ OpenWeatherMap retornou status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao conectar com OpenWeatherMap: $e');
      return null;
    }
  }
  
  /// Obtém previsão do OpenWeatherMap
  Future<Map<String, dynamic>?> _getOpenWeatherForecast(double lat, double lon, int days) async {
    try {
      final url = '$_openWeatherBaseUrl/forecast?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=pt_br';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ OpenWeatherMap forecast retornou status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao conectar com OpenWeatherMap forecast: $e');
      return null;
    }
  }
  
  /// Obtém dados horários do OpenWeatherMap
  Future<Map<String, dynamic>?> _getOpenWeatherHourly(double lat, double lon, int hours) async {
    try {
      final url = '$_openWeatherBaseUrl/forecast?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=pt_br';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ OpenWeatherMap hourly retornou status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao conectar com OpenWeatherMap hourly: $e');
      return null;
    }
  }
  
  /// Formata dados do OpenWeatherMap
  WeatherData _formatOpenWeatherData(Map<String, dynamic> data, String? locationName, String? plotId, String? farmId) {
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;
    final coord = data['coord'] as Map<String, dynamic>;
    
    return WeatherData(
      id: '${data['id']}_${DateTime.now().millisecondsSinceEpoch}',
      locationName: locationName ?? data['name'] ?? 'Localização desconhecida',
      latitude: coord['lat']?.toDouble() ?? 0.0,
      longitude: coord['lon']?.toDouble() ?? 0.0,
      temperature: main['temp']?.toDouble() ?? 0.0,
      feelsLike: main['feels_like']?.toDouble(),
      humidity: main['humidity']?.toInt() ?? 0,
      windSpeed: (wind['speed']?.toDouble() ?? 0.0) * 3.6, // Converter m/s para km/h
      windDirection: wind['deg']?.toInt() ?? 0,
      pressure: main['pressure']?.toDouble() ?? 0.0,
      visibility: data['visibility'] != null ? ((data['visibility'] as num) / 1000).round() : 0,
      clouds: data['clouds']?['all']?.toInt() ?? 0,
      condition: weather['main'] ?? '',
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '',
      uvIndex: 0.0, // OpenWeatherMap não fornece UV index na API gratuita
      dewPoint: main['dew_point']?.toDouble() ?? 0.0,
      sunHours: 0.0, // Calcular baseado na condição
      timestamp: DateTime.now(),
      farmId: farmId,
      plotId: plotId,
    );
  }
  
  /// Formata previsão do OpenWeatherMap
  List<WeatherForecast> _formatOpenWeatherForecast(Map<String, dynamic> data, String? locationName) {
    final List<dynamic> forecasts = data['list'];
    final List<WeatherForecast> formattedForecasts = [];
    
    // Agrupar por dia e pegar o primeiro horário de cada dia
    final Map<String, Map<String, dynamic>> dailyForecasts = {};
    
    for (final forecast in forecasts) {
      final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!dailyForecasts.containsKey(dateKey)) {
        final main = forecast['main'] as Map<String, dynamic>;
        final weather = (forecast['weather'] as List).first as Map<String, dynamic>;
        
        dailyForecasts[dateKey] = {
          'id': '${forecast['dt']}_${DateTime.now().millisecondsSinceEpoch}',
          'forecastDate': date.toIso8601String(),
          'temperature': main['temp'],
          'temperatureMin': main['temp_min'],
          'temperatureMax': main['temp_max'],
          'humidity': main['humidity'],
          'windSpeed': (forecast['wind']?['speed'] ?? 0) * 3.6,
          'windDirection': forecast['wind']?['deg'] ?? 0,
          'pressure': main['pressure'],
          'condition': weather['main'],
          'description': weather['description'],
          'icon': weather['icon'],
          'rainProbability': forecast['pop']?.toDouble() ?? 0.0,
          'rainAmount': forecast['rain']?['3h']?.toDouble() ?? 0.0,
          'uvIndex': 0.0,
        };
      }
    }
    
    return dailyForecasts.values
        .map((f) => WeatherForecast.fromMap(f))
        .toList();
  }
  
  /// Formata dados horários do OpenWeatherMap
  List<HourlyWeatherData> _formatOpenWeatherHourly(Map<String, dynamic> data, String? locationName) {
    final List<dynamic> forecasts = data['list'];
    final List<HourlyWeatherData> hourlyData = [];
    
    for (final forecast in forecasts) {
      final main = forecast['main'] as Map<String, dynamic>;
      final weather = (forecast['weather'] as List).first as Map<String, dynamic>;
      
      hourlyData.add(HourlyWeatherData(
        id: '${forecast['dt']}_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000),
        temperature: main['temp']?.toDouble() ?? 0.0,
        humidity: main['humidity']?.toInt() ?? 0,
        windSpeed: (forecast['wind']?['speed']?.toDouble() ?? 0.0) * 3.6,
        windDirection: forecast['wind']?['deg']?.toInt() ?? 0,
        pressure: main['pressure']?.toDouble() ?? 0.0,
        condition: weather['main'] ?? '',
        description: weather['description'] ?? '',
        icon: weather['icon'] ?? '',
        rainProbability: forecast['pop']?.toDouble() ?? 0.0,
        rainAmount: forecast['rain']?['3h']?.toDouble() ?? 0.0,
        uvIndex: 0.0,
      ));
    }
    
    return hourlyData;
  }
  
  // ===== MÉTODOS PRIVADOS - WEATHERAPI =====
  
  /// Obtém dados do WeatherAPI
  Future<Map<String, dynamic>?> _getWeatherApiData(double lat, double lon) async {
    try {
      final url = '$_weatherApiBaseUrl/current.json?key=$_weatherApiKey&q=$lat,$lon&lang=pt';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ WeatherAPI retornou status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao conectar com WeatherAPI: $e');
      return null;
    }
  }
  
  /// Obtém previsão do WeatherAPI
  Future<Map<String, dynamic>?> _getWeatherApiForecast(double lat, double lon, int days) async {
    try {
      final url = '$_weatherApiBaseUrl/forecast.json?key=$_weatherApiKey&q=$lat,$lon&days=$days&lang=pt';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ WeatherAPI forecast retornou status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao conectar com WeatherAPI forecast: $e');
      return null;
    }
  }
  
  /// Obtém dados horários do WeatherAPI
  Future<Map<String, dynamic>?> _getWeatherApiHourly(double lat, double lon, int hours) async {
    try {
      final url = '$_weatherApiBaseUrl/forecast.json?key=$_weatherApiKey&q=$lat,$lon&days=2&lang=pt';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ WeatherAPI hourly retornou status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao conectar com WeatherAPI hourly: $e');
      return null;
    }
  }
  
  /// Formata dados do WeatherAPI
  WeatherData _formatWeatherApiData(Map<String, dynamic> data, String? locationName, String? plotId, String? farmId) {
    final current = data['current'] as Map<String, dynamic>;
    final condition = current['condition'] as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>;
    
    return WeatherData(
      id: '${location['name']}_${DateTime.now().millisecondsSinceEpoch}',
      locationName: locationName ?? location['name'] ?? 'Localização desconhecida',
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lon']?.toDouble() ?? 0.0,
      temperature: current['temp_c']?.toDouble() ?? 0.0,
      feelsLike: current['feelslike_c']?.toDouble(),
      humidity: current['humidity']?.toInt() ?? 0,
      windSpeed: current['wind_kph']?.toDouble() ?? 0.0,
      windDirection: current['wind_degree']?.toInt() ?? 0,
      pressure: current['pressure_mb']?.toDouble() ?? 0.0,
      visibility: current['vis_km']?.toDouble()?.round() ?? 0,
      clouds: current['cloud']?.toInt() ?? 0,
      condition: condition['text'] ?? '',
      description: condition['text'] ?? '',
      icon: condition['icon'] ?? '',
      uvIndex: current['uv']?.toDouble() ?? 0.0,
      dewPoint: current['dewpoint_c']?.toDouble() ?? 0.0,
      sunHours: 0.0, // Calcular baseado na condição
      timestamp: DateTime.now(),
      farmId: farmId,
      plotId: plotId,
    );
  }
  
  /// Formata previsão do WeatherAPI
  List<WeatherForecast> _formatWeatherApiForecast(Map<String, dynamic> data, String? locationName) {
    final List<dynamic> forecasts = data['forecast']['forecastday'];
    final List<WeatherForecast> formattedForecasts = [];
    
    for (final forecast in forecasts) {
      final day = forecast['day'] as Map<String, dynamic>;
      final condition = day['condition'] as Map<String, dynamic>;
      final date = DateTime.parse(forecast['date']);
      
      formattedForecasts.add(WeatherForecast(
        id: '${forecast['date']}_${DateTime.now().millisecondsSinceEpoch}',
        forecastDate: date,
        temperature: day['avgtemp_c']?.toDouble() ?? 0.0,
        temperatureMin: day['mintemp_c']?.toDouble() ?? 0.0,
        temperatureMax: day['maxtemp_c']?.toDouble() ?? 0.0,
        humidity: day['avghumidity']?.toInt() ?? 0,
        windSpeed: day['maxwind_kph']?.toDouble() ?? 0.0,
        windDirection: 0, // WeatherAPI não fornece direção do vento na previsão
        pressure: 0.0, // WeatherAPI não fornece pressão na previsão
        condition: condition['text'] ?? '',
        description: condition['text'] ?? '',
        icon: condition['icon'] ?? '',
        rainProbability: day['daily_chance_of_rain']?.toDouble() ?? 0.0,
        rainAmount: day['totalprecip_mm']?.toDouble() ?? 0.0,
        uvIndex: day['uv']?.toDouble() ?? 0.0,
      ));
    }
    
    return formattedForecasts;
  }
  
  /// Formata dados horários do WeatherAPI
  List<HourlyWeatherData> _formatWeatherApiHourly(Map<String, dynamic> data, String? locationName) {
    final List<dynamic> forecasts = data['forecast']['forecastday'];
    final List<HourlyWeatherData> hourlyData = [];
    
    for (final forecast in forecasts) {
      final List<dynamic> hours = forecast['hour'];
      
      for (final hour in hours) {
        final condition = hour['condition'] as Map<String, dynamic>;
        
        hourlyData.add(HourlyWeatherData(
          id: '${hour['time']}_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.parse(hour['time']),
          temperature: hour['temp_c']?.toDouble() ?? 0.0,
          humidity: hour['humidity']?.toInt() ?? 0,
          windSpeed: hour['wind_kph']?.toDouble() ?? 0.0,
          windDirection: hour['wind_degree']?.toInt() ?? 0,
          pressure: hour['pressure_mb']?.toDouble() ?? 0.0,
          condition: condition['text'] ?? '',
          description: condition['text'] ?? '',
          icon: condition['icon'] ?? '',
          rainProbability: hour['chance_of_rain']?.toDouble() ?? 0.0,
          rainAmount: hour['precip_mm']?.toDouble() ?? 0.0,
          uvIndex: hour['uv']?.toDouble() ?? 0.0,
        ));
      }
    }
    
    return hourlyData;
  }
  
  // ===== MÉTODOS PRIVADOS - CACHE =====
  
  /// Cache dados do clima
  Future<void> _cacheWeatherData(WeatherData weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = weatherData.toMap();
      data['timestamp'] = DateTime.now().toIso8601String();
      await prefs.setString(_weatherDataKey, jsonEncode(data));
    } catch (e) {
      print('❌ Erro ao cachear dados do clima: $e');
    }
  }
  
  /// Cache dados de previsão
  Future<void> _cacheForecastData(List<WeatherForecast> forecasts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'forecasts': forecasts.map((f) => f.toMap()).toList(),
      };
      await prefs.setString(_forecastDataKey, jsonEncode(data));
    } catch (e) {
      print('❌ Erro ao cachear previsões: $e');
    }
  }
  
  /// Cache dados horários
  Future<void> _cacheHourlyData(List<HourlyWeatherData> hourlyData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'hourly': hourlyData.map((h) => h.toMap()).toList(),
      };
      await prefs.setString(_hourlyDataKey, jsonEncode(data));
    } catch (e) {
      print('❌ Erro ao cachear dados horários: $e');
    }
  }
  
  // ===== MÉTODOS PRIVADOS - DADOS SIMULADOS =====
  
  /// Retorna dados simulados do clima
  WeatherData _getSimulatedWeatherData(String? locationName, String? plotId, String? farmId) {
    final conditions = [
      'Ensolarado',
      'Parcialmente nublado',
      'Nublado',
      'Chuvoso',
      'Tempestade',
    ];
    
    final random = DateTime.now().millisecond % conditions.length;
    
    return WeatherData(
      id: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
      locationName: locationName ?? 'Localização simulada',
      latitude: -20.0,
      longitude: -52.0,
      temperature: 25 + (DateTime.now().millisecond % 15), // 25-40°C
      feelsLike: 28 + (DateTime.now().millisecond % 10),
      humidity: 50 + (DateTime.now().millisecond % 40), // 50-90%
      windSpeed: 5 + (DateTime.now().millisecond % 20), // 5-25 km/h
      windDirection: DateTime.now().millisecond % 360,
      pressure: 1013 + (DateTime.now().millisecond % 20),
      visibility: 10 + (DateTime.now().millisecond % 5),
      clouds: 20 + (DateTime.now().millisecond % 60),
      condition: conditions[random],
      description: conditions[random],
      icon: '01d',
      uvIndex: 3 + (DateTime.now().millisecond % 8),
      dewPoint: 15 + (DateTime.now().millisecond % 10),
      sunHours: 8 + (DateTime.now().millisecond % 4),
      timestamp: DateTime.now(),
      farmId: farmId,
      plotId: plotId,
    );
  }
  
  /// Retorna previsão simulada
  List<WeatherForecast> _getSimulatedForecast(int days, String? locationName) {
    final conditions = [
      'Ensolarado',
      'Parcialmente nublado',
      'Nublado',
      'Chuvoso',
      'Tempestade',
    ];
    
    final List<WeatherForecast> forecast = [];
    
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final random = (date.millisecondsSinceEpoch % conditions.length);
      
      forecast.add(WeatherForecast(
        id: 'simulated_${date.millisecondsSinceEpoch}',
        forecastDate: date,
        temperature: 28 + (date.millisecondsSinceEpoch % 12),
        temperatureMin: 18 + (date.millisecondsSinceEpoch % 8),
        temperatureMax: 32 + (date.millisecondsSinceEpoch % 10),
        humidity: 50 + (date.millisecondsSinceEpoch % 40),
        windSpeed: 5 + (date.millisecondsSinceEpoch % 20),
        windDirection: date.millisecondsSinceEpoch % 360,
        pressure: 1013 + (date.millisecondsSinceEpoch % 20),
        condition: conditions[random],
        description: conditions[random],
        icon: '01d',
        rainProbability: date.millisecondsSinceEpoch % 100,
        rainAmount: (date.millisecondsSinceEpoch % 20).toDouble(),
        uvIndex: 3 + (date.millisecondsSinceEpoch % 8),
      ));
    }
    
    return forecast;
  }
  
  /// Retorna dados horários simulados
  List<HourlyWeatherData> _getSimulatedHourlyData(int hours, String? locationName) {
    final conditions = [
      'Ensolarado',
      'Parcialmente nublado',
      'Nublado',
      'Chuvoso',
    ];
    
    final List<HourlyWeatherData> hourlyData = [];
    
    for (int i = 0; i < hours; i++) {
      final timestamp = DateTime.now().add(Duration(hours: i));
      final random = (timestamp.millisecondsSinceEpoch % conditions.length);
      
      hourlyData.add(HourlyWeatherData(
        id: 'simulated_${timestamp.millisecondsSinceEpoch}',
        timestamp: timestamp,
        temperature: 20 + (timestamp.millisecondsSinceEpoch % 20),
        humidity: 40 + (timestamp.millisecondsSinceEpoch % 50),
        windSpeed: 3 + (timestamp.millisecondsSinceEpoch % 15),
        windDirection: timestamp.millisecondsSinceEpoch % 360,
        pressure: 1010 + (timestamp.millisecondsSinceEpoch % 20),
        condition: conditions[random],
        description: conditions[random],
        icon: '01d',
        rainProbability: timestamp.millisecondsSinceEpoch % 80,
        rainAmount: (timestamp.millisecondsSinceEpoch % 10).toDouble(),
        uvIndex: 2 + (timestamp.millisecondsSinceEpoch % 6),
      ));
    }
    
    return hourlyData;
  }
  
  /// Verifica se há conexão com a internet
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
