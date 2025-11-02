import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/navigation_service.dart';
import '../utils/geo_calculator.dart';

/// Widget de navegação GPS até o talhão
/// Fornece instruções turn-by-turn para chegar ao talhão
class PlotNavigationWidget extends StatefulWidget {
  final LatLng plotCenter;
  final String plotName;
  final Color primaryColor;
  final VoidCallback? onNavigationComplete;
  final VoidCallback? onNavigationCancel;

  const PlotNavigationWidget({
    Key? key,
    required this.plotCenter,
    required this.plotName,
    this.primaryColor = const Color(0xFF3BAA57),
    this.onNavigationComplete,
    this.onNavigationCancel,
  }) : super(key: key);

  @override
  State<PlotNavigationWidget> createState() => _PlotNavigationWidgetState();
}

class _PlotNavigationWidgetState extends State<PlotNavigationWidget> {
  final NavigationService _navigationService = NavigationService();
  
  bool _isNavigating = false;
  bool _isPaused = false;
  Position? _currentPosition;
  Position? _destinationPosition;
  double _distanceToDestination = 0.0;
  double _bearingToDestination = 0.0;
  String _currentInstruction = 'Iniciando navegação...';
  String _nextInstruction = '';
  Duration _estimatedTime = Duration.zero;
  Timer? _navigationTimer;
  List<NavigationStep> _routeSteps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _navigationService.stopNavigation();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      await _navigationService.initialize();
      _destinationPosition = Position(
        latitude: widget.plotCenter.latitude,
        longitude: widget.plotCenter.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      // Calcular rota inicial
      await _calculateRoute();
    } catch (e) {
      setState(() {
        _currentInstruction = 'Erro ao inicializar navegação: $e';
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null) return;
    
    try {
      _routeSteps = await _navigationService.calculateRoute(
        _currentPosition!,
        _destinationPosition!,
      );
      
      if (_routeSteps.isNotEmpty) {
        _currentStepIndex = 0;
        _updateCurrentInstruction();
        _calculateEstimatedTime();
      }
    } catch (e) {
      setState(() {
        _currentInstruction = 'Erro ao calcular rota: $e';
      });
    }
  }

  void _updateCurrentInstruction() {
    if (_currentStepIndex < _routeSteps.length) {
      setState(() {
        _currentInstruction = _routeSteps[_currentStepIndex].instruction;
        _nextInstruction = _currentStepIndex + 1 < _routeSteps.length
            ? _routeSteps[_currentStepIndex + 1].instruction
            : 'Chegou ao destino';
      });
    }
  }

  void _calculateEstimatedTime() {
    double totalDistance = 0.0;
    for (final step in _routeSteps) {
      totalDistance += step.distance;
    }
    
    // Estimativa baseada em velocidade média de 30 km/h em estrada rural
    final estimatedSeconds = (totalDistance / 1000) / 30 * 3600;
    setState(() {
      _estimatedTime = Duration(seconds: estimatedSeconds.round());
    });
  }

  Future<void> _startNavigation() async {
    try {
      await _navigationService.startNavigation(
        onLocationUpdate: (position) {
          setState(() {
            _currentPosition = position;
            _updateNavigationData();
          });
        },
        onStepCompleted: () {
          setState(() {
            _currentStepIndex++;
            _updateCurrentInstruction();
          });
        },
        onNavigationComplete: () {
          setState(() {
            _isNavigating = false;
            _currentInstruction = 'Chegou ao talhão ${widget.plotName}!';
          });
          widget.onNavigationComplete?.call();
        },
        onError: (error) {
          setState(() {
            _currentInstruction = 'Erro na navegação: $error';
          });
        },
      );
      
      setState(() {
        _isNavigating = true;
        _isPaused = false;
      });
      
      // Timer para atualizar dados de navegação
      _navigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isNavigating && !_isPaused) {
          _updateNavigationData();
        }
      });
      
    } catch (e) {
      setState(() {
        _currentInstruction = 'Erro ao iniciar navegação: $e';
      });
    }
  }

  void _pauseNavigation() {
    _navigationService.pauseNavigation();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeNavigation() {
    _navigationService.resumeNavigation();
    setState(() {
      _isPaused = false;
    });
  }

  void _stopNavigation() {
    _navigationService.stopNavigation();
    _navigationTimer?.cancel();
    setState(() {
      _isNavigating = false;
      _isPaused = false;
    });
    widget.onNavigationCancel?.call();
  }

  void _updateNavigationData() {
    if (_currentPosition == null || _destinationPosition == null) return;
    
    setState(() {
      _distanceToDestination = GeoCalculator.calculateDistance(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_destinationPosition!.latitude, _destinationPosition!.longitude),
      );
      
      _bearingToDestination = GeoCalculator.calculateBearing(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_destinationPosition!.latitude, _destinationPosition!.longitude),
      );
    });
  }

  String _getDirectionIcon(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return '↑'; // Norte
    if (bearing >= 22.5 && bearing < 67.5) return '↗'; // Nordeste
    if (bearing >= 67.5 && bearing < 112.5) return '→'; // Leste
    if (bearing >= 112.5 && bearing < 157.5) return '↘'; // Sudeste
    if (bearing >= 157.5 && bearing < 202.5) return '↓'; // Sul
    if (bearing >= 202.5 && bearing < 247.5) return '↙'; // Sudoeste
    if (bearing >= 247.5 && bearing < 292.5) return '←'; // Oeste
    if (bearing >= 292.5 && bearing < 337.5) return '↖'; // Noroeste
    return '↑';
  }

  String _getDirectionText(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Nordeste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Leste';
    if (bearing >= 112.5 && bearing < 157.5) return 'Sudeste';
    if (bearing >= 157.5 && bearing < 202.5) return 'Sul';
    if (bearing >= 202.5 && bearing < 247.5) return 'Sudoeste';
    if (bearing >= 247.5 && bearing < 292.5) return 'Oeste';
    if (bearing >= 292.5 && bearing < 337.5) return 'Noroeste';
    return 'Norte';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.navigation, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navegação para Talhão',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.plotName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isNavigating)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isPaused ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isPaused ? 'PAUSADO' : 'NAVEGANDO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Instrução atual
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentInstruction,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_nextInstruction.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Próximo: $_nextInstruction',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações de navegação
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        Icons.straighten,
                        'Distância',
                        '${_distanceToDestination.toStringAsFixed(0)}m',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        Icons.access_time,
                        'Tempo Estimado',
                        _formatDuration(_estimatedTime),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        Icons.explore,
                        'Direção',
                        _getDirectionIcon(_bearingToDestination),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        Icons.gps_fixed,
                        'Precisão',
                        _currentPosition != null 
                            ? '${_currentPosition!.accuracy.toStringAsFixed(0)}m'
                            : 'N/A',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Controles
                Row(
                  children: [
                    if (!_isNavigating) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startNavigation,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar Navegação'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPaused ? _resumeNavigation : _pauseNavigation,
                          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                          label: Text(_isPaused ? 'Retomar' : 'Pausar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPaused ? Colors.blue : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stopNavigation,
                          icon: const Icon(Icons.stop),
                          label: const Text('Parar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes";
  }
}

/// Classe para representar um passo da navegação
class NavigationStep {
  final String instruction;
  final double distance;
  final double bearing;
  final LatLng position;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.bearing,
    required this.position,
  });
}
