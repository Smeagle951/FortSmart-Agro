import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Serviço para obter dados do clima
/// Integra com APIs externas como OpenWeatherMap, WeatherAPI, etc.
class WeatherService {
  // Chaves de API (configurar no arquivo de configuração)
  static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String _weatherApiKey = '0cd51c8f4c3946eabe0145502250705';
  
  // URLs das APIs
  static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _weatherApiBaseUrl = 'https://api.weatherapi.com/v1';
  
  /// Obtém dados do clima atual baseado na localização GPS
  Future<Map<String, dynamic>?> getWeatherByLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🌤️ Buscando dados do clima para localização GPS: $latitude, $longitude');
      
      // Usar WeatherAPI para busca por coordenadas
      final weatherApiData = await _getWeatherApiData(latitude, longitude);
      if (weatherApiData != null) {
        return _formatWeatherApiData(weatherApiData);
      }
      
      // Fallback para dados simulados
      return _getSimulatedWeatherData();
      
    } catch (e) {
      print('❌ Erro ao obter dados do clima por localização: $e');
      return _getSimulatedWeatherData();
    }
  }

  /// Obtém dados do clima atual por cidade
  Future<Map<String, dynamic>?> getWeatherByCity({
    required String city,
    String? state,
  }) async {
    try {
      print('🌤️ Buscando dados do clima para $city${state != null ? ', $state' : ''}');
      
      // Usar WeatherAPI para busca por cidade
      final weatherApiData = await _getWeatherApiDataByCity(city, state);
      if (weatherApiData != null) {
        return _formatWeatherApiData(weatherApiData);
      }
      
      // Fallback para dados simulados
      return _getSimulatedWeatherData();
      
    } catch (e) {
      print('❌ Erro ao obter dados do clima por cidade: $e');
      return _getSimulatedWeatherData();
    }
  }

  /// Obtém dados do clima atual baseado nas coordenadas da fazenda
  Future<Map<String, dynamic>?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🌤️ Buscando dados do clima para $latitude, $longitude');
      
      // Tentar OpenWeatherMap primeiro
      final openWeatherData = await _getOpenWeatherData(latitude, longitude);
      if (openWeatherData != null) {
        return _formatOpenWeatherData(openWeatherData);
      }
      
      // Fallback para WeatherAPI
      final weatherApiData = await _getWeatherApiData(latitude, longitude);
      if (weatherApiData != null) {
        return _formatWeatherApiData(weatherApiData);
      }
      
      // Fallback para dados simulados
      return _getSimulatedWeatherData();
      
    } catch (e) {
      print('❌ Erro ao obter dados do clima: $e');
      return _getSimulatedWeatherData();
    }
  }
  
  /// Obtém previsão do tempo para os próximos dias
  Future<List<Map<String, dynamic>>> getWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    try {
      print('🌤️ Buscando previsão do tempo para $days dias');
      
      // Tentar OpenWeatherMap primeiro
      final forecastData = await _getOpenWeatherForecast(latitude, longitude, days);
      if (forecastData != null) {
        return _formatOpenWeatherForecast(forecastData);
      }
      
      // Fallback para WeatherAPI
      final weatherApiForecast = await _getWeatherApiForecast(latitude, longitude, days);
      if (weatherApiForecast != null) {
        return _formatWeatherApiForecast(weatherApiForecast);
      }
      
      // Fallback para dados simulados
      return _getSimulatedForecast(days);
      
    } catch (e) {
      print('❌ Erro ao obter previsão do tempo: $e');
      return _getSimulatedForecast(days);
    }
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
  
  /// Formata dados do OpenWeatherMap
  Map<String, dynamic> _formatOpenWeatherData(Map<String, dynamic> data) {
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;
    
    return {
      'temperature': (main['temp'] as num).round(),
      'humidity': main['humidity'],
      'windSpeed': ((wind['speed'] as num) * 3.6).round(), // Converter m/s para km/h
      'condition': weather['description'],
      'icon': weather['icon'],
      'feelsLike': (main['feels_like'] as num).round(),
      'pressure': main['pressure'],
      'visibility': data['visibility'] != null ? ((data['visibility'] as num) / 1000).round() : null,
    };
  }
  
  /// Formata previsão do OpenWeatherMap
  List<Map<String, dynamic>> _formatOpenWeatherForecast(Map<String, dynamic> data) {
    final List<dynamic> forecasts = data['list'];
    final List<Map<String, dynamic>> formattedForecasts = [];
    
    // Agrupar por dia e pegar o primeiro horário de cada dia
    final Map<String, Map<String, dynamic>> dailyForecasts = {};
    
    for (final forecast in forecasts) {
      final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!dailyForecasts.containsKey(dateKey)) {
        final main = forecast['main'] as Map<String, dynamic>;
        final weather = (forecast['weather'] as List).first as Map<String, dynamic>;
        
        dailyForecasts[dateKey] = {
          'day': _getDayName(date),
          'high': (main['temp_max'] as num).round(),
          'low': (main['temp_min'] as num).round(),
          'condition': weather['description'],
          'icon': weather['icon'],
        };
      }
    }
    
    return dailyForecasts.values.toList();
  }
  
  // ===== MÉTODOS PRIVADOS - WEATHERAPI =====
  
  /// Obtém dados do WeatherAPI por cidade
  Future<Map<String, dynamic>?> _getWeatherApiDataByCity(String city, String? state) async {
    try {
      String query = city;
      if (state != null && state.isNotEmpty) {
        query = '$city,$state';
      }
      
      final url = '$_weatherApiBaseUrl/current.json?key=$_weatherApiKey&q=$query&lang=pt';
      
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
      print('⚠️ Erro ao conectar com WeatherAPI por cidade: $e');
      return null;
    }
  }
  
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
  
  /// Formata dados do WeatherAPI
  Map<String, dynamic> _formatWeatherApiData(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final condition = current['condition'] as Map<String, dynamic>;
    
    return {
      'temperature': (current['temp_c'] as num).round(),
      'humidity': current['humidity'],
      'windSpeed': (current['wind_kph'] as num).round(),
      'condition': condition['text'],
      'icon': condition['icon'],
      'feelsLike': (current['feelslike_c'] as num).round(),
      'pressure': current['pressure_mb'],
      'visibility': current['vis_km'],
    };
  }
  
  /// Formata previsão do WeatherAPI
  List<Map<String, dynamic>> _formatWeatherApiForecast(Map<String, dynamic> data) {
    final List<dynamic> forecasts = data['forecast']['forecastday'];
    final List<Map<String, dynamic>> formattedForecasts = [];
    
    for (final forecast in forecasts) {
      final day = forecast['day'] as Map<String, dynamic>;
      final condition = day['condition'] as Map<String, dynamic>;
      final date = DateTime.parse(forecast['date']);
      
      formattedForecasts.add({
        'day': _getDayName(date),
        'high': (day['maxtemp_c'] as num).round(),
        'low': (day['mintemp_c'] as num).round(),
        'condition': condition['text'],
        'icon': condition['icon'],
      });
    }
    
    return formattedForecasts;
  }
  
  // ===== MÉTODOS PRIVADOS - DADOS SIMULADOS =====
  
  /// Retorna dados simulados do clima
  Map<String, dynamic> _getSimulatedWeatherData() {
    final conditions = [
      'Ensolarado',
      'Parcialmente nublado',
      'Nublado',
      'Chuvoso',
      'Tempestade',
    ];
    
    final random = DateTime.now().millisecond % conditions.length;
    
    return {
      'temperature': 25 + (DateTime.now().millisecond % 15), // 25-40°C
      'humidity': 50 + (DateTime.now().millisecond % 40), // 50-90%
      'windSpeed': 5 + (DateTime.now().millisecond % 20), // 5-25 km/h
      'condition': conditions[random],
      'icon': '01d',
      'feelsLike': 28 + (DateTime.now().millisecond % 10),
      'pressure': 1013 + (DateTime.now().millisecond % 20),
      'visibility': 10 + (DateTime.now().millisecond % 5),
    };
  }
  
  /// Retorna previsão simulada
  List<Map<String, dynamic>> _getSimulatedForecast(int days) {
    final conditions = [
      'Ensolarado',
      'Parcialmente nublado',
      'Nublado',
      'Chuvoso',
      'Tempestade',
    ];
    
    final List<Map<String, dynamic>> forecast = [];
    
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final random = (date.millisecondsSinceEpoch % conditions.length);
      
      forecast.add({
        'day': _getDayName(date),
        'high': 28 + (date.millisecondsSinceEpoch % 12),
        'low': 18 + (date.millisecondsSinceEpoch % 8),
        'condition': conditions[random],
        'icon': '01d',
      });
    }
    
    return forecast;
  }
  
  // ===== MÉTODOS AUXILIARES =====
  
  /// Retorna nome do dia em português
  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Hoje';
    } else if (targetDate == tomorrow) {
      return 'Amanhã';
    } else if (targetDate == dayAfter) {
      return 'Depois';
    } else {
      final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      return weekdays[date.weekday - 1];
    }
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
  
  /// Obtém dados do clima com cache
  Future<Map<String, dynamic>?> getCachedWeather({
    required double latitude,
    required double longitude,
    Duration cacheDuration = const Duration(minutes: 30),
  }) async {
    // TODO: Implementar cache local
    // Por enquanto, sempre busca dados novos
    return await getCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    );
  }
}