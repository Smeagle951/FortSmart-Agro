import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço para obter dados de clima
class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = 'YOUR_API_KEY'; // Substituir por uma chave real em produção
  
  /// Obtém os dados de clima atuais para uma localização
  static Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    try {
      // Em um ambiente de produção, usaríamos a API real
      // Por enquanto, retornamos dados simulados para desenvolvimento
      
      // Simulação de chamada à API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Dados simulados
      return {
        'temperature': 25,
        'condition': 'Nublado',
        'humidity': 65,
        'windSpeed': 12,
        'icon': '04d',
      };
      
      // Código para chamada real à API (comentado para desenvolvimento)
      /*
      final response = await http.get(
        Uri.parse('$_baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': data['main']['temp'].round(),
          'condition': data['weather'][0]['main'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
          'icon': data['weather'][0]['icon'],
        };
      } else {
        throw Exception('Falha ao obter dados de clima: ${response.statusCode}');
      }
      */
    } catch (e) {
      print('Erro ao obter dados de clima: $e');
      // Retornar dados padrão em caso de erro
      return {
        'temperature': 25,
        'condition': 'Nublado',
        'humidity': 65,
        'windSpeed': 12,
        'icon': '04d',
      };
    }
  }
  
  /// Obtém a previsão do tempo para os próximos dias
  static Future<List<Map<String, dynamic>>> getForecast(double lat, double lon) async {
    try {
      // Simulação de chamada à API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Dados simulados para 5 dias
      return List.generate(5, (index) {
        return {
          'date': DateTime.now().add(Duration(days: index)),
          'temperature': 22 + index,
          'condition': index % 2 == 0 ? 'Ensolarado' : 'Parcialmente nublado',
          'icon': index % 2 == 0 ? '01d' : '02d',
        };
      });
    } catch (e) {
      print('Erro ao obter previsão do tempo: $e');
      return [];
    }
  }
}
