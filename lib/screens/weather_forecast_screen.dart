import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../utils/logger.dart';

/// Tela de previsão do tempo elegante e moderna
/// Inspirada no layout da imagem, mas sempre consumindo dados reais da API
class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({Key? key}) : super(key: key);

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen>
    with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  
  // Estado da tela
  bool _isLoading = true;
  String? _errorMessage;
  
  // Dados do clima
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];
  String _cityName = 'Primavera do Leste';
  
  // Animações
  late AnimationController _gradientController;
  late AnimationController _fadeController;
  late Animation<Color?> _gradientAnimation;
  late Animation<double> _fadeAnimation;
  
  // Coordenadas padrão (Primavera do Leste, MT)
  final double _defaultLatitude = -15.5608;
  final double _defaultLongitude = -54.3000;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWeatherData();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _gradientAnimation = ColorTween(
      begin: const Color(0xFF4A90E2),
      end: const Color(0xFFFF8C42),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  /// Carrega dados do clima da API
  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('🌤️ [WEATHER] Carregando dados do clima...');
      
      // Carregar clima atual
      final currentWeather = await _weatherService.getCurrentWeather(
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
      );
      
      // Carregar previsão
      final forecast = await _weatherService.getWeatherForecast(
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
        days: 3,
      );
      
      if (mounted) {
        setState(() {
          _currentWeather = currentWeather;
          _forecast = forecast;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
      
      Logger.info('✅ [WEATHER] Dados do clima carregados com sucesso');
    } catch (e) {
      Logger.error('❌ [WEATHER] Erro ao carregar dados do clima: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados do clima: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildWeatherContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4A90E2), const Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Carregando dados do clima...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4A90E2), const Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar dados',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadWeatherData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_currentWeather == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildCurrentWeather(),
                    _buildAlerts(),
                    _buildForecast(),
                    _buildAdditionalInfo(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              _cityName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _loadWeatherData,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final temp = _currentWeather!['temperature']?.toString() ?? '--';
    final condition = _currentWeather!['condition'] ?? 'N/A';
    final feelsLike = _currentWeather!['feelsLike']?.toString() ?? '--';
    final icon = _currentWeather!['icon'] ?? '01d';
    
    // Calcular min/max do dia atual
    final todayForecast = _forecast.isNotEmpty ? _forecast[0] : null;
    final maxTemp = todayForecast?['high']?.toString() ?? '--';
    final minTemp = todayForecast?['low']?.toString() ?? '--';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          // Ícone e temperatura principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWeatherIcon(icon, size: 80),
              const SizedBox(width: 20),
              Text(
                '$temp°',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Condição atual
          Text(
            condition,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Min/Max e sensação térmica
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherInfo('$maxTemp° / $minTemp°', 'Máx / Mín'),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildWeatherInfo('Sensação $feelsLike°', 'Sensação'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    // Verificar se há alertas baseados nas condições
    final alerts = _getWeatherAlerts();
    
    if (alerts.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerts.first['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  alerts.first['description'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previsão dos Próximos 3 Dias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecast.length,
              itemBuilder: (context, index) {
                final day = _forecast[index];
                return _buildForecastCard(day, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> day, int index) {
    final dayName = day['day'] ?? 'N/A';
    final high = day['high']?.toString() ?? '--';
    final low = day['low']?.toString() ?? '--';
    final condition = day['condition'] ?? 'N/A';
    final icon = day['icon'] ?? '01d';
    
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: index < _forecast.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildWeatherIcon(icon, size: 40),
          const SizedBox(height: 8),
          Text(
            '$high° / $low°',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            condition,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final humidity = _currentWeather!['humidity']?.toString() ?? '--';
    final windSpeed = _currentWeather!['windSpeed']?.toString() ?? '--';
    final pressure = _currentWeather!['pressure']?.toString() ?? '--';
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Informações Adicionais',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip('💧', '$humidity%', 'Umidade'),
              _buildInfoChip('💨', '${windSpeed} km/h', 'Vento'),
              _buildInfoChip('🏔️', '${pressure} hPa', 'Pressão'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String icon, String value, String label) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(String iconCode, {double size = 48}) {
    // Mapear códigos de ícone para emojis ou usar imagens
    final iconMap = {
      '01d': '☀️', '01n': '🌙',
      '02d': '⛅', '02n': '☁️',
      '03d': '☁️', '03n': '☁️',
      '04d': '☁️', '04n': '☁️',
      '09d': '🌧️', '09n': '🌧️',
      '10d': '🌦️', '10n': '🌧️',
      '11d': '⛈️', '11n': '⛈️',
      '13d': '❄️', '13n': '❄️',
      '50d': '🌫️', '50n': '🌫️',
    };
    
    final emoji = iconMap[iconCode] ?? '☀️';
    
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
    );
  }

  // Métodos auxiliares

  List<Color> _getGradientColors() {
    final hour = DateTime.now().hour;
    
    // Cores baseadas no horário (dia/noite)
    if (hour >= 6 && hour < 18) {
      // Dia: azul para laranja
      return [const Color(0xFF4A90E2), const Color(0xFFFF8C42)];
    } else {
      // Noite: azul escuro para roxo
      return [const Color(0xFF2C3E50), const Color(0xFF8E44AD)];
    }
  }

  List<Map<String, String>> _getWeatherAlerts() {
    final alerts = <Map<String, String>>[];
    
    if (_currentWeather == null) return alerts;
    
    final temp = _currentWeather!['temperature'] ?? 0;
    final humidity = _currentWeather!['humidity'] ?? 0;
    final windSpeed = _currentWeather!['windSpeed'] ?? 0;
    
    // Alerta de baixa umidade
    if (humidity < 30) {
      alerts.add({
        'title': 'Alerta de baixa umidade',
        'description': 'Umidade muito baixa - monitore irrigação',
      });
    }
    
    // Alerta de calor extremo
    if (temp > 38) {
      alerts.add({
        'title': 'Alerta de calor extremo',
        'description': 'Temperatura muito alta - proteja as culturas',
      });
    }
    
    // Alerta de vento forte
    if (windSpeed > 25) {
      alerts.add({
        'title': 'Alerta de vento forte',
        'description': 'Vento forte - evite aplicações',
      });
    }
    
    return alerts;
  }
}
