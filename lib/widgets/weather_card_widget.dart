import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../utils/logger.dart';

/// Widget de card de clima elegante e moderno
/// Pode ser usado em diferentes telas do sistema
class WeatherCardWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? cityName;
  final bool showDetails;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const WeatherCardWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.cityName,
    this.showDetails = true,
    this.onTap,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  State<WeatherCardWidget> createState() => _WeatherCardWidgetState();
}

class _WeatherCardWidgetState extends State<WeatherCardWidget>
    with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  
  // Estado do widget
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];
  
  // Animações
  late AnimationController _fadeController;
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
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
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
      Logger.info('🌤️ [WEATHER_CARD] Carregando dados do clima...');
      
      final lat = widget.latitude ?? _defaultLatitude;
      final lon = widget.longitude ?? _defaultLongitude;
      
      // Carregar clima atual
      final currentWeather = await _weatherService.getCurrentWeather(
        latitude: lat,
        longitude: lon,
      );
      
      // Carregar previsão se necessário
      if (widget.showDetails) {
        final forecast = await _weatherService.getWeatherForecast(
          latitude: lat,
          longitude: lon,
          days: 3,
        );
        
        if (mounted) {
          setState(() {
            _forecast = forecast;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _currentWeather = currentWeather;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
      
      Logger.info('✅ [WEATHER_CARD] Dados do clima carregados com sucesso');
    } catch (e) {
      Logger.error('❌ [WEATHER_CARD] Erro ao carregar dados do clima: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados do clima';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _buildWeatherCard(),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoading) {
      return _buildLoadingCard();
    }
    
    if (_errorMessage != null) {
      return _buildErrorCard();
    }
    
    if (_currentWeather == null) {
      return _buildEmptyCard();
    }
    
    return _buildContentCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white.withOpacity(0.8),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadWeatherData,
            child: const Text(
              'Tentar Novamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Dados não disponíveis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCurrentWeather(),
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              _buildAlerts(),
              const SizedBox(height: 16),
              _buildForecast(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cityName = widget.cityName ?? 'Primavera do Leste';
    
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            cityName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (widget.onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.6),
            size: 16,
          ),
      ],
    );
  }

  Widget _buildCurrentWeather() {
    final temp = _currentWeather!['temperature']?.toString() ?? '--';
    final condition = _currentWeather!['condition'] ?? 'N/A';
    final icon = _currentWeather!['icon'] ?? '01d';
    
    // Calcular min/max do dia atual
    final todayForecast = _forecast.isNotEmpty ? _forecast[0] : null;
    final maxTemp = todayForecast?['high']?.toString() ?? '--';
    final minTemp = todayForecast?['low']?.toString() ?? '--';
    
    return Row(
      children: [
        // Ícone do clima
        _buildWeatherIcon(icon, size: 48),
        const SizedBox(width: 16),
        
        // Temperatura e condição
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$temp°',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                condition,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                '$maxTemp° / $minTemp°',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    final alerts = _getWeatherAlerts();
    
    if (alerts.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
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
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alerts.first['title']?.toString() ?? 'Alerta',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    if (_forecast.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos 3 dias',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _forecast.take(3).map((day) {
            return Expanded(
              child: _buildForecastItem(day),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildForecastItem(Map<String, dynamic> day) {
    final dayName = day['day'] ?? 'N/A';
    final high = day['high']?.toString() ?? '--';
    final low = day['low']?.toString() ?? '--';
    final icon = day['icon'] ?? '01d';
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          _buildWeatherIcon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            '$high°',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '$low°',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String iconCode, {double size = 24}) {
    // Mapear códigos de ícone para emojis
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
        'title': 'Baixa umidade',
        'description': 'Monitore irrigação',
      });
    }
    
    // Alerta de calor extremo
    if (temp > 38) {
      alerts.add({
        'title': 'Calor extremo',
        'description': 'Proteja as culturas',
      });
    }
    
    // Alerta de vento forte
    if (windSpeed > 25) {
      alerts.add({
        'title': 'Vento forte',
        'description': 'Evite aplicações',
      });
    }
    
    return alerts;
  }
}
