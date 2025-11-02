import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../utils/logger.dart';
import '../../modules/infestation_map/services/talhao_integration_service.dart';

/// Tela de navegação aprimorada com rota visual, polígono do talhão, giroscópio e otimização de bateria
class EnhancedNavigationScreen extends StatefulWidget {
  final String currentPointId;
  final String? nextPointId;
  final Map<String, dynamic>? nextPointData;
  final String fieldId;
  final String cropName;
  final VoidCallback? onArrived;
  final VoidCallback? onSkip;

  const EnhancedNavigationScreen({
    Key? key,
    required this.currentPointId,
    this.nextPointId,
    this.nextPointData,
    required this.fieldId,
    required this.cropName,
    this.onArrived,
    this.onSkip,
  }) : super(key: key);

  @override
  State<EnhancedNavigationScreen> createState() => _EnhancedNavigationScreenState();
}

class _EnhancedNavigationScreenState extends State<EnhancedNavigationScreen> with TickerProviderStateMixin {
  // Localização e navegação
  Position? _currentPosition;
  double? _distanceToNext;
  double? _bearingToNext;
  bool _isLoadingLocation = false;
  
  // Sistema de otimização de bateria
  Timer? _locationUpdateTimer;
  Timer? _batteryOptimizationTimer;
  bool _isBatteryOptimized = false;
  int _updateFrequency = 2; // segundos - aumenta quando bateria baixa
  
  // Giroscópio e orientação
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  double _deviceOrientation = 0.0;
  bool _hasGyroscope = false;
  
  // Mapa e polígono
  List<LatLng>? _talhaoPolygon;
  List<LatLng>? _routePoints;
  bool _showSatelliteLayer = false;
  MapController? _mapController;
  
  // Sistema de background otimizado
  bool _wakelockEnabled = false;
  StreamSubscription<Position>? _positionStream;
  
  // Animações otimizadas
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  // Serviços
  late TalhaoIntegrationService _talhaoService;

  @override
  void initState() {
    super.initState();
    _talhaoService = TalhaoIntegrationService();
    _initializeOptimizations();
    _initializeAnimations();
    _startOptimizedLocationTracking();
    _loadTalhaoPolygon();
    _initializeGyroscope();
    _startBatteryOptimization();
  }

  /// Inicializa otimizações de bateria
  void _initializeOptimizations() {
    // Configurar frequência de atualização baseada na bateria
    _updateFrequency = 2; // Começar com 2 segundos
    _isBatteryOptimized = false;
    
    Logger.info('🔋 Otimizações de bateria inicializadas');
  }

  /// Inicializa animações otimizadas
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Iniciar animações apenas se necessário
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  /// Inicia rastreamento de localização otimizado
  Future<void> _startOptimizedLocationTracking() async {
    try {
      setState(() => _isLoadingLocation = true);
      
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Obter localização inicial
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: _isBatteryOptimized ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      // Carregar polígono do talhão
      await _loadTalhaoPolygon();
      
      // Calcular distância e rota se temos próximo ponto
      if (widget.nextPointData != null) {
        await _calculateDistanceAndBearing();
        await _calculateRoute();
      }
      
      // Iniciar atualizações otimizadas
      _startOptimizedLocationUpdates();
      
      setState(() => _isLoadingLocation = false);
      
    } catch (e) {
      Logger.error('❌ Erro ao obter localização: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Carrega polígono do talhão
  Future<void> _loadTalhaoPolygon() async {
    try {
      Logger.info('🗺️ Carregando polígono do talhão: ${widget.fieldId}');
      
      final polygon = await _talhaoService.getTalhaoPolygon(widget.fieldId);
      
      setState(() {
        _talhaoPolygon = polygon;
      });
      
      Logger.info('✅ Polígono carregado: ${polygon?.length ?? 0} pontos');
    } catch (e) {
      Logger.error('❌ Erro ao carregar polígono: $e');
    }
  }

  /// Calcula rota entre pontos
  Future<void> _calculateRoute() async {
    if (_currentPosition == null || widget.nextPointData == null) return;
    
    try {
      final nextLat = widget.nextPointData!['latitude'] as double?;
      final nextLng = widget.nextPointData!['longitude'] as double?;
      
      if (nextLat != null && nextLng != null) {
        // Criar pontos da rota (simulação - em produção usar API de roteamento)
        final currentPoint = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        final nextPoint = LatLng(nextLat, nextLng);
        
        // Gerar pontos intermediários para a rota
        final routePoints = _generateRoutePoints(currentPoint, nextPoint);
        
        setState(() {
          _routePoints = routePoints;
        });
        
        Logger.info('🛣️ Rota calculada: ${routePoints.length} pontos');
      }
    } catch (e) {
      Logger.error('❌ Erro ao calcular rota: $e');
    }
  }

  /// Gera pontos intermediários para a rota
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const int segments = 10; // Número de segmentos na rota
    
    for (int i = 0; i <= segments; i++) {
      final ratio = i / segments;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  /// Inicializa giroscópio para orientação
  void _initializeGyroscope() {
    try {
      // Verificar disponibilidade do giroscópio
      _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        if (!mounted) return;
        
        // Calcular orientação do dispositivo
        final orientation = math.atan2(event.x, event.y) * 180 / math.pi;
        
        setState(() {
          _deviceOrientation = orientation;
          _hasGyroscope = true;
        });
      });
      
      // Fallback para acelerômetro se giroscópio não disponível
      _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        if (!mounted || _hasGyroscope) return;
        
        // Calcular orientação usando acelerômetro
        final orientation = math.atan2(event.x, event.y) * 180 / math.pi;
        
        setState(() {
          _deviceOrientation = orientation;
        });
      });
      
      Logger.info('🧭 Giroscópio inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar giroscópio: $e');
    }
  }

  /// Inicia otimização de bateria
  void _startBatteryOptimization() {
    _batteryOptimizationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _optimizeBatteryUsage();
    });
  }

  /// Otimiza uso de bateria baseado na situação
  void _optimizeBatteryUsage() {
    // Aumentar frequência de atualização se bateria baixa
    if (_distanceToNext != null && _distanceToNext! < 50) {
      // Próximo ao ponto - aumentar frequência
      _updateFrequency = 1;
      _isBatteryOptimized = false;
    } else {
      // Distante do ponto - otimizar bateria
      _updateFrequency = 5;
      _isBatteryOptimized = true;
    }
    
    // Reiniciar timer com nova frequência
    _locationUpdateTimer?.cancel();
    _startOptimizedLocationUpdates();
    
    Logger.info('🔋 Otimização de bateria: ${_isBatteryOptimized ? "ATIVA" : "DESATIVA"} (${_updateFrequency}s)');
  }

  /// Inicia atualizações de localização otimizadas
  void _startOptimizedLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(Duration(seconds: _updateFrequency), (timer) {
      _updateLocationOptimized();
    });
  }

  /// Atualiza localização de forma otimizada
  Future<void> _updateLocationOptimized() async {
    try {
      if (widget.nextPointData == null) return;
      
      // Obter nova localização com precisão otimizada
      final newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: _isBatteryOptimized ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 3),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = newPosition;
        });
        
        // Recalcular distância e rota
        await _calculateDistanceAndBearing();
        await _calculateRoute();
        
        // Verificar proximidade
        _checkProximity();
      }
    } catch (e) {
      Logger.error('❌ Erro ao atualizar localização: $e');
    }
  }

  /// Calcula distância e direção
  Future<void> _calculateDistanceAndBearing() async {
    if (_currentPosition == null || widget.nextPointData == null) return;
    
    try {
      final nextLat = widget.nextPointData!['latitude'] as double?;
      final nextLng = widget.nextPointData!['longitude'] as double?;
      
      if (nextLat != null && nextLng != null) {
        _distanceToNext = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          nextLat,
          nextLng,
        );
        
        _bearingToNext = Geolocator.bearingBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          nextLat,
          nextLng,
        );
        
        setState(() {});
      }
    } catch (e) {
      Logger.error('❌ Erro ao calcular distância: $e');
    }
  }

  /// Verifica proximidade ao ponto
  void _checkProximity() {
    if (_distanceToNext == null) return;
    
    const double proximityThreshold = 10.0; // metros
    final isNear = _distanceToNext! <= proximityThreshold;
    
    if (isNear) {
      // Vibração quando próximo
      HapticFeedback.mediumImpact();
      
      // Mostrar notificação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.vibration, color: Colors.white),
                SizedBox(width: 8),
                Text('Próximo ao ponto! (${_distanceToNext!.toStringAsFixed(1)}m)'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Habilita wake lock otimizado
  void _enableOptimizedWakeLock() {
    try {
      WakelockPlus.enable();
      _wakelockEnabled = true;
      Logger.info('🔋 Wake lock otimizado habilitado');
    } catch (e) {
      Logger.error('❌ Erro ao habilitar wake lock: $e');
    }
  }

  /// Desabilita wake lock
  void _disableWakeLock() {
    try {
      if (_wakelockEnabled) {
        WakelockPlus.disable();
        _wakelockEnabled = false;
        Logger.info('🔋 Wake lock desabilitado');
      }
    } catch (e) {
      Logger.error('❌ Erro ao desabilitar wake lock: $e');
    }
  }

  String _getDirectionText(double? bearing) {
    if (bearing == null) return 'Calculando...';
    
    if (bearing >= -22.5 && bearing < 22.5) return 'Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Nordeste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Leste';
    if (bearing >= 112.5 && bearing < 157.5) return 'Sudeste';
    if (bearing >= 157.5 || bearing < -157.5) return 'Sul';
    if (bearing >= -157.5 && bearing < -112.5) return 'Sudoeste';
    if (bearing >= -112.5 && bearing < -67.5) return 'Oeste';
    if (bearing >= -67.5 && bearing < -22.5) return 'Noroeste';
    
    return 'Calculando...';
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Calculando...';
    
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _batteryOptimizationTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionStream?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _disableWakeLock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Rumo ao próximo ponto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2D9CDB),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showSatelliteLayer ? Icons.map : Icons.satellite),
            onPressed: () {
              setState(() {
                _showSatelliteLayer = !_showSatelliteLayer;
              });
            },
            tooltip: _showSatelliteLayer ? 'Mapa' : 'Satélite',
          ),
          IconButton(
            icon: Icon(_isBatteryOptimized ? Icons.battery_saver : Icons.battery_std),
            onPressed: () {
              setState(() {
                _isBatteryOptimized = !_isBatteryOptimized;
              });
              _optimizeBatteryUsage();
            },
            tooltip: _isBatteryOptimized ? 'Modo Normal' : 'Economia de Bateria',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards de informação
          _buildInfoCards(),
          
          // Mapa aprimorado
          Expanded(
            child: _buildEnhancedMap(),
          ),
          
          // Botões de ação
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Container(
      height: 120,
      child: Row(
        children: [
          // Card GPS
          Expanded(
            child: _buildInfoCard(
              'GPS',
              '3.8m',
              Icons.gps_fixed,
              Colors.green,
            ),
          ),
          SizedBox(width: 8),
          
          // Card Distância
          Expanded(
            child: _buildInfoCard(
              'Distância',
              _formatDistance(_distanceToNext),
              Icons.straighten,
              Colors.red,
            ),
          ),
          SizedBox(width: 8),
          
          // Card Status
          Expanded(
            child: _buildInfoCard(
              'Status',
              'Navegando',
              Icons.navigation,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMap() {
    if (_isLoadingLocation) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
        ),
      );
    }

    if (_currentPosition == null) {
      return Center(
        child: Text(
          'Localização não disponível',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            initialZoom: 16.0,
            minZoom: 10.0,
            maxZoom: 20.0,
          ),
          children: [
            // Camada base (mapa ou satélite)
            TileLayer(
              urlTemplate: _showSatelliteLayer
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Polígono do talhão
            if (_talhaoPolygon != null)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _talhaoPolygon!,
                    color: Colors.green.withOpacity(0.3),
                    borderColor: Colors.green,
                    borderStrokeWidth: 2,
                    isFilled: true,
                  ),
                ],
              ),
            
            // Rota entre pontos
            if (_routePoints != null && _routePoints!.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints!,
                    color: Colors.blue,
                    strokeWidth: 4,
                  ),
                ],
              ),
            
            // Marcadores
            MarkerLayer(
              markers: [
                // Posição atual
                Marker(
                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                
                // Próximo ponto
                if (widget.nextPointData != null)
                  Marker(
                    point: LatLng(
                      widget.nextPointData!['latitude'] as double,
                      widget.nextPointData!['longitude'] as double,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.place,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onSkip,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey),
              ),
              child: Text(
                'Voltar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onArrived,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
