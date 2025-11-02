import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'dart:async';
import '../../../models/ponto_monitoramento_model.dart';
import '../../../utils/distance_calculator.dart';
import '../../../services/talhao_service.dart';
import '../../../utils/logger.dart';

class RouteNavigationScreen extends StatefulWidget {
  final PontoMonitoramentoModel currentPoint;
  final PontoMonitoramentoModel nextPoint;
  final Position? currentPosition;
  final VoidCallback onArrived;
  final VoidCallback onCancel;
  final VoidCallback onBack;

  const RouteNavigationScreen({
    Key? key,
    required this.currentPoint,
    required this.nextPoint,
    this.currentPosition,
    required this.onArrived,
    required this.onCancel,
    required this.onBack,
  }) : super(key: key);

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  Position? _currentPosition;
  double? _distanceToNextPoint;
  String? _gpsAccuracy;
  bool _hasArrived = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _debounceTimer;
  
  // Variáveis para o mapa
  List<latlong.LatLng>? _talhaoPolygon;
  bool _isLoadingPolygon = true;
  final TalhaoService _talhaoService = TalhaoService();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    _startGpsMonitoring();
    _loadTalhaoPolygon();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  /// Carrega o polígono do talhão para o mapa
  Future<void> _loadTalhaoPolygon() async {
    try {
      Logger.info('🗺️ Carregando polígono do talhão para navegação...');
      
      final polygon = await _talhaoService.getTalhaoPolygon(widget.currentPoint.talhaoId.toString());
      
      setState(() {
        _talhaoPolygon = polygon;
        _isLoadingPolygon = false;
      });
      
      if (polygon != null) {
        Logger.info('✅ Polígono carregado para navegação: ${polygon.length} pontos');
      } else {
        Logger.warning('⚠️ Polígono não encontrado para talhão: ${widget.currentPoint.talhaoId}');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar polígono do talhão: $e');
      setState(() {
        _isLoadingPolygon = false;
      });
    }
  }

  void _startGpsMonitoring() {
    _positionSubscription?.cancel();
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // 1 metro
      ),
    ).listen(
      (position) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _updateGpsPosition(position);
        });
      },
      onError: (error) {
        setState(() {
          _gpsAccuracy = 'Erro: $error';
        });
      },
    );
  }

  void _updateGpsPosition(Position position) {
    // Calcular distância até o próximo ponto
    final distance = DistanceCalculator.calculateDistance(
      position.latitude,
      position.longitude,
      widget.nextPoint.latitude,
      widget.nextPoint.longitude,
    );

    // Verificar se chegou ao ponto
    final hasArrived = DistanceCalculator.hasArrivedAtPoint(distance, arrivalThreshold: 5.0);
    final previousArrived = _hasArrived;

    // Vibrar e tocar som quando chegar pela primeira vez
    if (hasArrived && !previousArrived) {
      _triggerArrivalNotification();
    }

    // Atualizar estado
    setState(() {
      _currentPosition = position;
      _distanceToNextPoint = distance;
      _gpsAccuracy = '${position.accuracy.toStringAsFixed(1)}m';
      _hasArrived = hasArrived;
    });
  }

  void _triggerArrivalNotification() {
    // Implementar vibração e som
    HapticFeedback.mediumImpact();
    
    // Vibração adicional para indicar chegada
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
    
    // Mostrar notificação visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Você chegou ao próximo ponto!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Chamar callback para avançar
      widget.onArrived();
    }
  }

  Color _getDistanceColor(double distance) {
    if (distance <= 5.0) {
      return const Color(0xFF27AE60); // Verde
    } else if (distance <= 20.0) {
      return const Color(0xFFF2C94C); // Amarelo
    } else if (distance <= 50.0) {
      return const Color(0xFFF2994A); // Laranja
    } else {
      return const Color(0xFFEB5757); // Vermelho
    }
  }
  
  /// Constrói widgets automáticos informativos
  Widget _buildAutomaticWidgets() {
    return Row(
      children: [
        // Widget GPS
        Expanded(
          child: _buildInfoCard(
            icon: Icons.gps_fixed,
            title: 'GPS',
            value: _gpsAccuracy ?? 'Aguardando...',
            color: _gpsAccuracy != null && _gpsAccuracy!.contains('Erro') 
                ? Colors.red 
                : const Color(0xFF27AE60),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Widget Distância
        Expanded(
          child: _buildInfoCard(
            icon: Icons.navigation,
            title: 'Distância',
            value: _distanceToNextPoint != null 
                ? '${_distanceToNextPoint!.toStringAsFixed(1)} m'
                : 'Calculando...',
            color: _distanceToNextPoint != null 
                ? _getDistanceColor(_distanceToNextPoint!)
                : Colors.grey,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Widget Status
        Expanded(
          child: _buildInfoCard(
            icon: _hasArrived ? Icons.check_circle : Icons.trending_flat,
            title: 'Status',
            value: _hasArrived ? 'Chegou!' : 'Navegando',
            color: _hasArrived ? const Color(0xFF27AE60) : const Color(0xFF2D9CDB),
          ),
        ),
      ],
    );
  }
  
  /// Constrói card de informação
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  /// Constrói o mapa de navegação
  Widget _buildNavigationMap() {
    if (_isLoadingPolygon) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando mapa...'),
          ],
        ),
      );
    }
    
    // Calcular centro do mapa
    latlong.LatLng center = const latlong.LatLng(-15.5, -54.3); // Centro padrão
    if (_currentPosition != null) {
      center = latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    
    return FlutterMap(
      options: MapOptions(
        center: center,
        zoom: 16.0,
        minZoom: 10.0,
        maxZoom: 20.0,
      ),
      children: [
        // Camada de tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Polígono do talhão
        if (_talhaoPolygon != null && _talhaoPolygon!.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _talhaoPolygon!,
                color: const Color(0xFF27AE60).withOpacity(0.3),
                borderColor: const Color(0xFF27AE60),
                borderStrokeWidth: 2,
              ),
            ],
          ),
        
        // Marcadores dos pontos
        MarkerLayer(
          markers: [
            // Ponto atual
            Marker(
              point: latlong.LatLng(widget.currentPoint.latitude, widget.currentPoint.longitude),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9CDB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            // Próximo ponto
            Marker(
              point: latlong.LatLng(widget.nextPoint.latitude, widget.nextPoint.longitude),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: _distanceToNextPoint != null && _distanceToNextPoint! <= 5.0
                      ? const Color(0xFF27AE60)
                      : const Color(0xFFEB5757),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            // Posição atual do usuário
            if (_currentPosition != null)
              Marker(
                point: latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        
        // Legenda do mapa
        const Positioned(
          top: 8,
          right: 8,
          child: _MapLegend(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: const Color(0xFF2C2C2C),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rumo ao próximo ponto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        if (_distanceToNextPoint != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Distância: ${_distanceToNextPoint!.toStringAsFixed(1)} m',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getDistanceColor(_distanceToNextPoint!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF2C2C2C),
                  ),
                ],
              ),
            ),

            // Conteúdo principal com mapa real
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Widgets automáticos informativos
                    _buildAutomaticWidgets(),
                    
                    const SizedBox(height: 16),
                    
                    // Mapa real com navegação
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildNavigationMap(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Badge de distância em destaque
                    if (_distanceToNextPoint != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: _getDistanceColor(_distanceToNextPoint!).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getDistanceColor(_distanceToNextPoint!).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _distanceToNextPoint! <= 5.0 
                                  ? Icons.check_circle
                                  : Icons.navigation,
                              color: _getDistanceColor(_distanceToNextPoint!),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _distanceToNextPoint! <= 5.0 
                                  ? 'CHEGOU!'
                                  : '${_distanceToNextPoint!.toStringAsFixed(1)} m',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getDistanceColor(_distanceToNextPoint!),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Botões de ação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      label: const Text('Voltar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2C2C2C),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEB5757),
                        side: const BorderSide(color: Color(0xFFEB5757)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget da legenda do mapa
class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem(
            Icons.location_on,
            const Color(0xFF2D9CDB),
            'Ponto Atual',
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            Icons.navigation,
            const Color(0xFFEB5757),
            'Próximo Ponto',
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            Icons.person,
            Colors.blue,
            'Sua Posição',
          ),
          if (true) // Sempre mostrar talhão se disponível
            const SizedBox(height: 4),
          if (true)
            _buildLegendItem(
              Icons.crop_free,
              const Color(0xFF27AE60),
              'Talhão',
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}
