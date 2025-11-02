import 'package:flutter/material.dart';
import '../../services/weather_service.dart';
import '../../services/device_location_service.dart';
import '../../routes.dart';

/// Tela de clima agrícola
class AgriculturalWeatherScreen extends StatefulWidget {
  const AgriculturalWeatherScreen({Key? key}) : super(key: key);

  @override
  _AgriculturalWeatherScreenState createState() => _AgriculturalWeatherScreenState();
}

class _AgriculturalWeatherScreenState extends State<AgriculturalWeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final DeviceLocationService _locationService = DeviceLocationService.instance;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();
  
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isGettingLocation = false;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];
  String _errorMessage = '';
  String _currentLocation = 'São Paulo, SP';
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWeatherData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadWeatherData() async {
    print('🔄 Iniciando carregamento de dados do clima...');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Tentar obter localização GPS primeiro
      await _getWeatherByCurrentLocation();
      print('✅ Dados do clima carregados com sucesso');
    } catch (e) {
      print('❌ Erro ao carregar dados do clima: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados do clima: $e';
      });
    }
  }

  Future<void> _getWeatherByCurrentLocation() async {
    print('📍 Tentando obter localização GPS...');
    setState(() {
      _isGettingLocation = true;
      _errorMessage = '';
    });

    try {
      // Obter localização GPS
      final location = await _locationService.getCurrentLocation();
      print('📍 Localização GPS obtida: ${location?.latitude}, ${location?.longitude}');
      
      if (location != null) {
        // Buscar clima baseado na localização GPS
        print('🌤️ Buscando clima para localização GPS...');
        final currentWeather = await _weatherService.getWeatherByLocation(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        
        if (currentWeather != null) {
          print('✅ Clima obtido via GPS: $currentWeather');
          setState(() {
            _currentWeather = currentWeather;
            _currentLocation = 'Localização Atual';
            _isLoading = false;
            _isGettingLocation = false;
          });
          
          _showSuccess('Clima da sua localização atual carregado!');
        } else {
          print('⚠️ Clima não obtido via GPS, usando fallback...');
          // Fallback para Mato Grosso se não conseguir obter dados
          await _loadDefaultWeather();
        }
      } else {
        print('⚠️ Localização GPS não obtida, usando fallback...');
        // Fallback para Mato Grosso se não conseguir obter localização
        await _loadDefaultWeather();
      }
    } catch (e) {
      print('❌ Erro ao obter localização GPS: $e');
      // Fallback para Mato Grosso
      await _loadDefaultWeather();
    }
  }

  Future<void> _loadDefaultWeather() async {
    print('🌤️ Carregando clima padrão (Mato Grosso)...');
    try {
      // Coordenadas padrão (Mato Grosso)
      const double latitude = -15.593889;
      const double longitude = -56.083333;
      // Carregar dados atuais
      print('🌤️ Buscando clima atual...');
      final currentWeather = await _weatherService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      
      // Carregar previsão para 5 dias
      print('🌤️ Buscando previsão...');
      final forecast = await _weatherService.getWeatherForecast(
        latitude: latitude,
        longitude: longitude,
        days: 5,
      );
      
      print('✅ Clima padrão carregado: $currentWeather');
      setState(() {
        _currentWeather = currentWeather;
        _forecast = forecast;
        _currentLocation = 'Mato Grosso, MT';
        _isLoading = false;
        _isGettingLocation = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar clima padrão: $e');
      setState(() {
        _isLoading = false;
        _isGettingLocation = false;
        _errorMessage = 'Erro ao carregar dados do clima: $e';
      });
    }
  }

  Future<void> _searchWeatherByCity() async {
    if (_cityController.text.trim().isEmpty) {
      _showError('Digite o nome da cidade');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final city = _cityController.text.trim();
      final state = _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null;
      
      // Buscar dados por cidade
      final currentWeather = await _weatherService.getWeatherByCity(
        city: city,
        state: state,
      );
      
      if (currentWeather != null) {
        setState(() {
          _currentWeather = currentWeather;
          _currentLocation = state != null ? '$city, $state' : city;
          _isSearching = false;
        });
        
        // Limpar campos após busca bem-sucedida
        _cityController.clear();
        _stateController.clear();
        
        _showSuccess('Dados do clima carregados com sucesso!');
      } else {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Cidade não encontrada. Verifique o nome e tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Erro ao buscar dados do clima: $e';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Agrícola'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Atual'),
            Tab(text: 'Previsão'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Campo de pesquisa
          _buildSearchSection(),
          
          // Conteúdo principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCurrentWeather(),
                          _buildForecastNavigation(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de pesquisa
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Buscar Clima por Cidade',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cityController,
                  focusNode: _cityFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Cidade',
                    hintText: 'Ex: Mato Grosso',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_city),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _stateFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _stateController,
                  focusNode: _stateFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    hintText: 'Ex: MT',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.map),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchWeatherByCity(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchWeatherByCity,
                icon: _isSearching 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : _getWeatherByCurrentLocation,
                icon: _isGettingLocation 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_isGettingLocation ? 'GPS...' : 'GPS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Exemplos: São Paulo, SP |Mato Grosso do Sul, MS| Mato Grosso, MT| PARANA, PR\nOu use o botão GPS para sua localização atual',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentWeather() {
    if (_currentWeather == null) {
      return const Center(
        child: Text('Dados de clima não disponíveis'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentLocation,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atualizado: ${_formatDateTime(DateTime.now())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _getWeatherIcon(_currentWeather!['condition'] ?? 'Nublado'),
                        size: 48,
                        color: _getWeatherColor(_currentWeather!['condition'] ?? 'Nublado'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_currentWeather!['temperature'] ?? 25}°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentWeather!['condition'] ?? 'Nublado',
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Sensação térmica: ${_currentWeather!['feelsLike'] ?? 28}°C',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalhes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    Icons.water_drop,
                    'Umidade',
                    '${_currentWeather!['humidity'] ?? 70}%',
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    Icons.air,
                    'Vento',
                    '${_currentWeather!['windSpeed'] ?? 15} km/h',
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Impacto Agrícola',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAgriculturalImpact(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForecast() {
    if (_forecast.isEmpty) {
      return const Center(
        child: Text('Previsão não disponível'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _forecast.length,
      itemBuilder: (context, index) {
        final day = _forecast[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    day['day'] ?? 'Hoje',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Icon(
                    _getWeatherIcon(day['condition'] ?? 'Nublado'),
                    color: _getWeatherColor(day['condition'] ?? 'Nublado'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(day['condition'] ?? 'Nublado'),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${day['high'] ?? 28}°C',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  
  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAgriculturalImpact() {
    // Lógica simplificada para determinar o impacto agrícola com base nas condições climáticas
    final condition = _currentWeather!['condition'] ?? 'Nublado';
    final temperature = _currentWeather!['temperature'] ?? 25;
    
    String impactText = '';
    IconData impactIcon = Icons.info;
    Color impactColor = Colors.blue;
    
    if (condition.toLowerCase().contains('chuv')) {
      impactText = 'Condições favoráveis para o desenvolvimento de doenças fúngicas. Considere adiar aplicações de defensivos.';
      impactIcon = Icons.warning;
      impactColor = Colors.orange;
    } else if (condition.toLowerCase().contains('sol')) {
      if (temperature > 30) {
        impactText = 'Altas temperaturas podem causar estresse hídrico nas plantas. Monitore a irrigação.';
        impactIcon = Icons.warning;
        impactColor = Colors.orange;
      } else {
        impactText = 'Condições favoráveis para aplicação de defensivos e trabalhos no campo.';
        impactIcon = Icons.check_circle;
        impactColor = Colors.green;
      }
    } else if (condition.toLowerCase().contains('nublad')) {
      impactText = 'Condições moderadas. Bom para trabalhos no campo, mas monitore mudanças no clima.';
      impactIcon = Icons.info;
      impactColor = Colors.blue;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          impactIcon,
          color: impactColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            impactText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Hoje, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  
  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    
    if (lowerCondition.contains('sol')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('nublad')) {
      return Icons.cloud;
    } else if (lowerCondition.contains('chuv')) {
      return Icons.water_drop;
    } else if (lowerCondition.contains('tempes')) {
      return Icons.flash_on;
    } else if (lowerCondition.contains('nev')) {
      return Icons.ac_unit;
    } else {
      return Icons.cloud;
    }
  }

  /// Constrói a navegação para a tela de previsão
  Widget _buildForecastNavigation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.blue[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'Previsão Detalhada',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Visualize a previsão completa para os próximos 3 dias com animações e dados detalhados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.weatherForecast);
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Ver Previsão Completa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getWeatherColor(String condition) {
    final lowerCondition = condition.toLowerCase();
    
    if (lowerCondition.contains('sol')) {
      return Colors.orange;
    } else if (lowerCondition.contains('nublad')) {
      return Colors.grey;
    } else if (lowerCondition.contains('chuv')) {
      return Colors.blue;
    } else if (lowerCondition.contains('tempes')) {
      return Colors.deepPurple;
    } else if (lowerCondition.contains('nev')) {
      return Colors.lightBlue;
    } else {
      return Colors.grey;
    }
  }
}
