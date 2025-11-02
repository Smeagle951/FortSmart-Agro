// lib/modules/clima/clima_constants.dart

class ClimaConstants {
  // Sua chave (embutida apenas para ambiente de desenvolvimento).
  // Em produção, utilize flutter_dotenv ou secure storage.
  static const OPENWEATHERMAP_API_KEY = '5a1bf9af05e999b9bf42fe61d8629748';

  // URLs da API OpenWeatherMap
  static const BASE_URL = 'https://api.openweathermap.org/data/2.5';
  static const CURRENT_WEATHER_URL = '$BASE_URL/weather';
  static const FORECAST_URL = '$BASE_URL/forecast';
  static const ONECALL_URL = 'https://api.openweathermap.org/data/3.0/onecall';

  // Timeout e limites
  static const API_TIMEOUT_SECONDS = 10;
  static const REFRESH_INTERVAL_MINUTES = 30;
  static const MAX_CACHE_AGE_HOURS = 2;

  // Configurações de localização
  static const DEFAULT_LATITUDE = -15.7801; // Brasília
  static const DEFAULT_LONGITUDE = -47.9292;
  static const LOCATION_ACCURACY_METERS = 100;

  // Unidades
  static const UNITS = 'metric'; // Celsius, m/s, etc.
  static const LANGUAGE = 'pt_br';

  // Mapear icon codes → Lottie filenames
  static const Map<String, String> weatherIconMap = {
    // Sol
    '01d': 'sunny.json',
    '01n': 'clear_night.json',
    
    // Parcialmente nublado
    '02d': 'partly_cloudy.json',
    '02n': 'partly_cloudy.json',
    
    // Nublado
    '03d': 'cloudy.json',
    '03n': 'cloudy.json',
    '04d': 'cloudy.json',
    '04n': 'cloudy.json',
    
    // Chuva
    '09d': 'rain_light.json',
    '09n': 'rain_light.json',
    '10d': 'rain_heavy.json',
    '10n': 'rain_heavy.json',
    
    // Tempestade
    '11d': 'storm.json',
    '11n': 'storm.json',
    
    // Neve
    '13d': 'snow.json',
    '13n': 'snow.json',
    
    // Neblina/Névoa
    '50d': 'fog.json',
    '50n': 'fog.json',
  };

  // Mapear condições climáticas para alertas
  static const Map<String, String> alertConditions = {
    'storm': 'Tempestade prevista - evite atividades no campo',
    'heavy_rain': 'Chuva forte - risco de alagamento',
    'frost': 'Risco de geada - proteja culturas sensíveis',
    'high_wind': 'Vento forte - cuidado com aplicações',
    'extreme_heat': 'Calor extremo - irrigação necessária',
    'drought': 'Período seco prolongado - monitore irrigação',
  };

  // Thresholds para alertas (valores em unidades métricas)
  static const double WIND_ALERT_THRESHOLD = 25.0; // km/h
  static const double FROST_TEMP_THRESHOLD = 3.0; // °C
  static const double HIGH_TEMP_THRESHOLD = 38.0; // °C
  static const double HEAVY_RAIN_THRESHOLD = 20.0; // mm/h
  static const double LOW_HUMIDITY_THRESHOLD = 30.0; // %
  static const double HIGH_HUMIDITY_THRESHOLD = 85.0; // %

  // Cores para diferentes condições climáticas
  static const Map<String, List<int>> weatherColors = {
    'sunny': [0xFF79C2FF, 0xFFB6E0FF],
    'partly_cloudy': [0xFF8FB6C8, 0xFFD9EEFA],
    'cloudy': [0xFF6B8FB8, 0xFF9BB5D1],
    'rain': [0xFF6B8FB8, 0xFF36454F],
    'storm': [0xFF2C3E50, 0xFF34495E],
    'snow': [0xFFE6F0FA, 0xFFBFD8F1],
    'fog': [0xFF95A5A6, 0xFFBDC3C7],
    'clear_night': [0xFF2C3E50, 0xFF34495E],
  };

  // Ícones para diferentes métricas
  static const Map<String, String> metricIcons = {
    'temperature': '🌡️',
    'humidity': '💧',
    'wind': '💨',
    'pressure': '🏔️',
    'visibility': '👁️',
    'uv_index': '☀️',
    'precipitation': '🌧️',
    'clouds': '☁️',
  };

  // Descrições amigáveis para condições climáticas
  static const Map<String, String> weatherDescriptions = {
    'clear': 'Céu limpo',
    'clouds': 'Nublado',
    'rain': 'Chuva',
    'drizzle': 'Garoa',
    'thunderstorm': 'Tempestade',
    'snow': 'Neve',
    'mist': 'Névoa',
    'fog': 'Neblina',
    'haze': 'Neblina seca',
    'dust': 'Poeira',
    'sand': 'Areia',
    'ash': 'Cinzas vulcânicas',
    'squall': 'Rajadas',
    'tornado': 'Tornado',
  };

  // Configurações de cache local
  static const String CLIMA_TABLE = 'clima_cache';
  static const String PREVISAO_TABLE = 'previsao_cache';
  static const String HISTORICO_TABLE = 'clima_historico';

  // Configurações de notificação
  static const String NOTIFICATION_CHANNEL_ID = 'clima_alerts';
  static const String NOTIFICATION_CHANNEL_NAME = 'Alertas Climáticos';
  static const String NOTIFICATION_CHANNEL_DESC = 'Notificações sobre condições climáticas importantes';

  // Configurações para diferentes tipos de cultura
  static const Map<String, Map<String, double>> culturaThresholds = {
    'soja': {
      'temp_min': 20.0,
      'temp_max': 30.0,
      'humidity_min': 60.0,
      'humidity_max': 80.0,
      'wind_max': 20.0,
    },
    'milho': {
      'temp_min': 18.0,
      'temp_max': 32.0,
      'humidity_min': 55.0,
      'humidity_max': 85.0,
      'wind_max': 25.0,
    },
    'trigo': {
      'temp_min': 15.0,
      'temp_max': 25.0,
      'humidity_min': 50.0,
      'humidity_max': 75.0,
      'wind_max': 30.0,
    },
  };

  // Método auxiliar para obter arquivo Lottie
  static String getLottieAsset(String iconCode) {
    final filename = weatherIconMap[iconCode] ?? 'partly_cloudy.json';
    return 'assets/lottie/$filename';
  }

  // Método auxiliar para determinar se é dia ou noite
  static bool isDayTime(String iconCode) {
    return iconCode.endsWith('d');
  }

  // Método auxiliar para obter cor baseada na condição
  static List<int> getWeatherColors(String condition) {
    return weatherColors[condition] ?? weatherColors['partly_cloudy']!;
  }
}
