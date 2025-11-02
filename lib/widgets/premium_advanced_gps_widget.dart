import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/advanced_gps_tracking_service.dart';
import '../utils/geo_calculator.dart';

/// Widget premium avançado para GPS com funcionalidades completas
class PremiumAdvancedGpsWidget extends StatefulWidget {
  final Function(List<LatLng>)? onPointsChanged;
  final Function(double)? onAreaChanged;
  final Function(double)? onDistanceChanged;
  final Function(String)? onStatusChanged;
  final Function(bool)? onTrackingStateChanged;
  final VoidCallback? onSave;
  final Color? primaryColor;
  final bool enableBackgroundRecording;
  final bool enableWakeLock;

  const PremiumAdvancedGpsWidget({
    Key? key,
    this.onPointsChanged,
    this.onAreaChanged,
    this.onDistanceChanged,
    this.onStatusChanged,
    this.onTrackingStateChanged,
    this.onSave,
    this.primaryColor,
    this.enableBackgroundRecording = false,
    this.enableWakeLock = false,
  }) : super(key: key);

  @override
  State<PremiumAdvancedGpsWidget> createState() => _PremiumAdvancedGpsWidgetState();
}

class _PremiumAdvancedGpsWidgetState extends State<PremiumAdvancedGpsWidget> {
  final AdvancedGpsTrackingService _gpsService = AdvancedGpsTrackingService();
  
  bool _isTracking = false;
  bool _isPaused = false;
  List<LatLng> _trackedPoints = [];
  double _currentAccuracy = 0.0;
  double _totalDistance = 0.0;
  double _currentArea = 0.0;
  int _satellitesUsed = 0;
  int _satellitesVisible = 0;
  String _currentStatus = 'Parado';
  DateTime? _startTime;
  Timer? _durationTimer;
  Duration _elapsedTime = Duration.zero;
  Position? _currentPosition;
  
  @override
  void initState() {
    super.initState();
    _initializeGps();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _gpsService.stopTracking();
    _gpsService.dispose();
    super.dispose();
  }

  Future<void> _initializeGps() async {
    try {
      await _gpsService.initialize();
      setState(() {
        _currentStatus = 'Pronto';
      });
      widget.onStatusChanged?.call('GPS inicializado e pronto');
    } catch (e) {
      setState(() {
        _currentStatus = 'Erro: $e';
      });
      widget.onStatusChanged?.call('Erro ao inicializar GPS: $e');
    }
  }

  Future<void> _startTracking() async {
    try {
      final success = await _gpsService.startTracking(
        onPointsChanged: (points) {
          setState(() {
            _trackedPoints = points;
            _totalDistance = _calculateTotalDistance(points);
            if (points.length >= 3) {
              _currentArea = _calculateArea(points);
            }
          });
          
          widget.onPointsChanged?.call(points);
          widget.onDistanceChanged?.call(_totalDistance);
          if (points.length >= 3) {
            widget.onAreaChanged?.call(_currentArea);
          }
        },
        onLocationUpdate: (position) {
          setState(() {
            _currentPosition = position;
            _currentAccuracy = position.accuracy;
          });
        },
        onError: (error) {
          widget.onStatusChanged?.call('Erro: $error');
        },
      );

      if (success) {
        setState(() {
          _isTracking = true;
          _isPaused = false;
          _startTime = DateTime.now();
          _currentStatus = 'Rastreando';
        });
        
        // Iniciar timer de duração
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_isTracking && !_isPaused && _startTime != null) {
            setState(() {
              _elapsedTime = DateTime.now().difference(_startTime!);
            });
          }
        });
        
        widget.onTrackingStateChanged?.call(true);
        widget.onStatusChanged?.call('Rastreamento GPS iniciado');
      } else {
        widget.onStatusChanged?.call('Erro ao iniciar rastreamento GPS');
      }
    } catch (e) {
      widget.onStatusChanged?.call('Erro ao iniciar rastreamento: $e');
    }
  }

  void _pauseTracking() {
    _gpsService.pauseTracking();
    setState(() {
      _isPaused = true;
      _currentStatus = 'Pausado';
    });
    widget.onStatusChanged?.call('Rastreamento pausado');
  }

  void _resumeTracking() {
    _gpsService.resumeTracking();
    setState(() {
      _isPaused = false;
      _currentStatus = 'Rastreando';
    });
    widget.onStatusChanged?.call('Rastreamento retomado');
  }

  Future<void> _stopTracking() async {
    await _gpsService.stopTracking();
    _durationTimer?.cancel();
    
    setState(() {
      _isTracking = false;
      _isPaused = false;
      _currentStatus = 'Finalizado';
    });
    
    widget.onTrackingStateChanged?.call(false);
    widget.onStatusChanged?.call('Rastreamento finalizado');
  }

  void _clearTracking() {
    setState(() {
      _trackedPoints.clear();
      _totalDistance = 0.0;
      _currentArea = 0.0;
      _elapsedTime = Duration.zero;
      _startTime = null;
      _currentStatus = 'Pronto';
    });
    widget.onPointsChanged?.call([]);
    widget.onAreaChanged?.call(0.0);
    widget.onDistanceChanged?.call(0.0);
  }

  double _calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double distance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += GeoCalculator.calculateDistance(points[i], points[i + 1]);
    }
    return distance;
  }

  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    return GeoCalculator.calculatePolygonArea(points) / 10000; // m² para hectares
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Color get _primaryColor => widget.primaryColor ?? const Color(0xFF3BAA57);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho com botão de fechar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'GPS Avançado Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Fechar',
                ),
              ],
            ),
          ),
          
          // Conteúdo rolável
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de posição atual
                  _buildPositionCard(),
                  const SizedBox(height: 16),
                  
                  // Card de qualidade do sinal
                  _buildSignalQualityCard(),
                  const SizedBox(height: 16),
                  
                  // Card de sistemas de satélites
                  _buildSatelliteSystemsCard(),
                  const SizedBox(height: 16),
                  
                  // Card de estatísticas
                  if (_isTracking || _trackedPoints.isNotEmpty)
                    _buildStatisticsCard(),
                ],
              ),
            ),
          ),
          
          // Controles fixos na parte inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botões principais
                Row(
                  children: [
                    // Botão Iniciar/Pausar/Retomar
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTracking
                            ? (_isPaused ? _resumeTracking : _pauseTracking)
                            : _startTracking,
                        icon: Icon(
                          _isTracking
                              ? (_isPaused ? Icons.play_arrow : Icons.pause)
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _isTracking
                              ? (_isPaused ? 'Retomar' : 'Pausar')
                              : 'Iniciar',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTracking
                              ? (_isPaused ? Colors.blue : Colors.orange)
                              : _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Botão Parar
                    if (_isTracking)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stopTracking,
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
                ),
                const SizedBox(height: 8),
                
                // Botões secundários
                Row(
                  children: [
                    // Botão Limpar
                    if (!_isTracking && _trackedPoints.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearTracking,
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    
                    if (!_isTracking && _trackedPoints.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      // Botão Salvar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onSave?.call();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildPositionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: _primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Posição Atual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_currentPosition != null) ...[
              _buildInfoRow(
                Icons.north,
                'Latitude',
                '${_currentPosition!.latitude.toStringAsFixed(6)}°',
              ),
              _buildInfoRow(
                Icons.east,
                'Longitude',
                '${_currentPosition!.longitude.toStringAsFixed(6)}°',
              ),
              _buildInfoRow(
                Icons.height,
                'Altitude',
                '${_currentPosition!.altitude.toStringAsFixed(1)}m',
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aguardando sinal GPS...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignalQualityCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.signal_cellular_alt, color: _primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Qualidade do Sinal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(
              Icons.gps_fixed,
              'Precisão',
              '${_currentAccuracy.toStringAsFixed(1)}m',
              color: _getAccuracyColor(_currentAccuracy),
            ),
            _buildInfoRow(
              Icons.satellite_alt,
              'Satélites Usados',
              '$_satellitesUsed',
            ),
            _buildInfoRow(
              Icons.visibility,
              'Satélites Visíveis',
              '$_satellitesVisible',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatelliteSystemsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.satellite, color: _primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Sistemas de Satélites',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSatelliteSystem('GPS', 2, Colors.blue),
                _buildSatelliteSystem('GLONASS', 2, Colors.red),
                _buildSatelliteSystem('GALILEO', 2, Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSatelliteSystem('BEIDOU', 1, Colors.orange),
                _buildSatelliteSystem('QZSS', 1, Colors.purple),
                _buildSatelliteSystem('IRNSS', 1, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: _primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(
              Icons.timeline,
              'Pontos',
              '${_trackedPoints.length}',
            ),
            _buildInfoRow(
              Icons.straighten,
              'Distância',
              '${_totalDistance.toStringAsFixed(1)}m',
            ),
            if (_trackedPoints.length >= 3)
              _buildInfoRow(
                Icons.crop_square,
                'Área',
                '${_currentArea.toStringAsFixed(4)} ha',
              ),
            _buildInfoRow(
              Icons.access_time,
              'Duração',
              _formatDuration(_elapsedTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteSystem(String name, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'Rastreando':
        return Colors.green;
      case 'Pausado':
        return Colors.orange;
      case 'Finalizado':
        return Colors.blue;
      case 'Pronto':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 2) return Colors.green;
    if (accuracy <= 5) return Colors.lightGreen;
    if (accuracy <= 10) return Colors.orange;
    return Colors.red;
  }
}
