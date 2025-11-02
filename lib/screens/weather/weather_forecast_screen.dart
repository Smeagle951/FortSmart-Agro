import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/weather_service.dart';
import '../../services/device_location_service.dart';

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen>
    with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final DeviceLocationService _locationService = DeviceLocationService.instance;
  
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentLocation = 'Carregando...';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadForecastData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadForecastData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obter localização atual
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';
        
        // Carregar previsão para 3 dias
        final forecast = await _weatherService.getWeatherForecast(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        
        if (mounted) {
          setState(() {
            _forecast = forecast;
            _isLoading = false;
          });
          
          // Iniciar animações
          _fadeController.forward();
          _slideController.forward();
        }
      } else {
        // Fallback para Mato Grosso se não conseguir localização
        _currentLocation = 'Mato Grosso, Brasil';
        final forecast = await _weatherService.getWeatherForecast(
          latitude: -15.6,
          longitude: -56.1,
        );
        
        if (mounted) {
          setState(() {
            _forecast = forecast;
            _isLoading = false;
          });
          
          _fadeController.forward();
          _slideController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar previsão: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage.isNotEmpty
                  ? _buildErrorState()
                  : _buildForecastContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando previsão...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            _errorMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadForecastData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent() {
    if (_forecast.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma previsão disponível',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadForecastData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildForecastList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Botão voltar e refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: _loadForecastData,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Título
          const Text(
            'Previsão do Tempo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // Localização
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _currentLocation,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Subtítulo
          const Text(
            'Previsão para os próximos 3 dias',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: _forecast.length,
        itemBuilder: (context, index) {
          return _buildForecastCard(_forecast[index], index);
        },
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> dayData, int index) {
    final dateString = dayData['date']?.toString() ?? DateTime.now().toIso8601String();
    final date = DateTime.tryParse(dateString) ?? DateTime.now();
    final dayName = _getDayName(date, index);
    final condition = dayData['condition']?.toString() ?? 'Nublado';
    final maxTemp = dayData['temperatureMax']?.toDouble() ?? 25.0;
    final minTemp = dayData['temperatureMin']?.toDouble() ?? 15.0;
    final humidity = dayData['humidity']?.toInt() ?? 60;
    final windSpeed = dayData['windSpeed']?.toDouble() ?? 10.0;
    final precipitation = dayData['precipitation']?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho do dia
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getConditionColor(condition).withOpacity(0.1),
                  _getConditionColor(condition).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Ícone do clima
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getConditionColor(condition).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    _getWeatherIcon(condition),
                    color: _getConditionColor(condition),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informações do dia
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        condition,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Temperaturas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${maxTemp.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    Text(
                      '${minTemp.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Barra de temperatura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _buildTemperatureBar(minTemp, maxTemp, maxTemp),
          ),
          
          // Detalhes do clima
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildDetailItem(
                  Icons.water_drop,
                  'Umidade',
                  '$humidity%',
                  const Color(0xFF2196F3),
                ),
                const SizedBox(width: 20),
                _buildDetailItem(
                  Icons.air,
                  'Vento',
                  '${windSpeed.toStringAsFixed(0)} km/h',
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 20),
                _buildDetailItem(
                  Icons.cloud,
                  'Chuva',
                  '${precipitation.toStringAsFixed(0)}mm',
                  const Color(0xFF9C27B0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureBar(double min, double max, double current) {
    final range = max - min;
    final currentPosition = range > 0 ? (current - min) / range : 0.5;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toStringAsFixed(0)}°',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${max.toStringAsFixed(0)}°',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50),
                const Color(0xFFFFEB3B),
                const Color(0xFFFF9800),
                const Color(0xFFF44336),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width * 0.3 * currentPosition,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date, int index) {
    if (index == 0) return 'Hoje';
    if (index == 1) return 'Amanhã';
    
    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[date.weekday - 1];
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sol':
      case 'ensolarado':
      case 'clear':
        return Icons.wb_sunny;
      case 'nublado':
      case 'cloudy':
        return Icons.cloud;
      case 'chuva':
      case 'rain':
        return Icons.grain;
      case 'tempestade':
      case 'storm':
        return Icons.thunderstorm;
      case 'neblina':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sol':
      case 'ensolarado':
      case 'clear':
        return const Color(0xFFFF9800);
      case 'nublado':
      case 'cloudy':
        return const Color(0xFF607D8B);
      case 'chuva':
      case 'rain':
        return const Color(0xFF2196F3);
      case 'tempestade':
      case 'storm':
        return const Color(0xFF9C27B0);
      case 'neblina':
      case 'fog':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF607D8B);
    }
  }
}