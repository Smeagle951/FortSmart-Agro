import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/advanced_gps_service.dart';

/// Exemplo de uso do GPS avançado com múltiplos sistemas de satélites
class AdvancedGPSExample extends StatefulWidget {
  const AdvancedGPSExample({Key? key}) : super(key: key);

  @override
  State<AdvancedGPSExample> createState() => _AdvancedGPSExampleState();
}

class _AdvancedGPSExampleState extends State<AdvancedGPSExample> {
  late AdvancedGPSService _gpsService;
  AdvancedPosition? _currentPosition;
  List<AdvancedPosition> _positionHistory = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _gpsService = AdvancedGPSService();
    _setupGPSCallbacks();
    _initializeGPS();
  }

  void _setupGPSCallbacks() {
    _gpsService.onPositionUpdate = (position) {
      setState(() {
        _currentPosition = position;
        _positionHistory.add(position);
        
        // Manter apenas as últimas 50 posições
        if (_positionHistory.length > 50) {
          _positionHistory.removeAt(0);
        }
        
        _statistics = _gpsService.getGPSStatistics();
      });
    };

    _gpsService.onError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro GPS: $error'),
          backgroundColor: Colors.red,
        ),
      );
    };

    _gpsService.onStatusChange = (status) {
      print('Status GPS alterado: $status');
    };
  }

  Future<void> _initializeGPS() async {
    final success = await _gpsService.initialize();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS avançado inicializado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao inicializar GPS avançado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Avançado - Exemplo'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status do GPS
          _buildStatusCard(),
          
          // Posição atual
          if (_currentPosition != null) _buildCurrentPositionCard(),
          
          // Estatísticas
          if (_statistics.isNotEmpty) _buildStatisticsCard(),
          
          // Histórico de posições
          if (_positionHistory.isNotEmpty) _buildHistoryCard(),
          
          // Botões de controle
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.satellite_alt,
                  color: _getStatusColor(),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status GPS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(),
              ),
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 8),
              Text(
                'Sistemas ativos: ${_gpsService.getActiveSatelliteSystems().join(', ')}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPositionCard() {
    final pos = _currentPosition!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Posição Atual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Coordenadas
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Latitude',
                    '${pos.latitude.toStringAsFixed(6)}°',
                    Icons.north,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile(
                    'Longitude',
                    '${pos.longitude.toStringAsFixed(6)}°',
                    Icons.east,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Precisão e altitude
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Precisão',
                    '${pos.accuracy.toStringAsFixed(1)}m',
                    Icons.center_focus_strong,
                    color: _getAccuracyColor(pos.accuracy),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile(
                    'Altitude',
                    '${pos.altitude.toStringAsFixed(1)}m',
                    Icons.height,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Qualidade
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Qualidade',
                    pos.qualityInfo,
                    Icons.signal_cellular_alt,
                    color: _getQualityColor(pos.qualityInfo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile(
                    'Satélites',
                    '${pos.totalSatellitesUsed}/${pos.totalSatellitesVisible}',
                    Icons.satellite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Posições',
                    '${_statistics['total_positions'] ?? 0}',
                    Icons.location_on,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile(
                    'Precisão Média',
                    '${(_statistics['average_accuracy'] ?? 0.0).toStringAsFixed(1)}m',
                    Icons.center_focus_strong,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Melhor Precisão',
                    '${(_statistics['best_accuracy'] ?? 0.0).toStringAsFixed(1)}m',
                    Icons.star,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile(
                    'Alta Precisão',
                    '${_statistics['high_accuracy_positions'] ?? 0}',
                    Icons.check_circle,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico de Posições',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _positionHistory.length,
                itemBuilder: (context, index) {
                  final pos = _positionHistory[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: _getAccuracyColor(pos.accuracy),
                    ),
                    title: Text(
                      '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      'Precisão: ${pos.accuracy.toStringAsFixed(1)}m | Satélites: ${pos.totalSatellitesUsed}/${pos.totalSatellitesVisible}',
                      style: TextStyle(fontSize: 10),
                    ),
                    trailing: Text(
                      '${pos.timestamp.hour}:${pos.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleStartStop,
              icon: Icon(_getStartStopIcon()),
              label: Text(_getStartStopText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStartStopColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Configurar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color ?? Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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

  void _handleStartStop() {
    final status = _gpsService.status;
    
    if (status == AdvancedGPSStatus.ready || status == AdvancedGPSStatus.paused) {
      _gpsService.startPositionCapture();
    } else if (status == AdvancedGPSStatus.recording) {
      _gpsService.stopPositionCapture();
    }
  }

  void _handleSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações GPS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Alta Precisão'),
              subtitle: const Text('Melhor precisão, mais consumo de bateria'),
              leading: Radio<LocationAccuracy>(
                value: LocationAccuracy.bestForNavigation,
                groupValue: LocationAccuracy.bestForNavigation,
                onChanged: (value) {
                  if (value != null) {
                    _gpsService.setDesiredAccuracy(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Precisão Alta'),
              subtitle: const Text('Boa precisão, consumo moderado'),
              leading: Radio<LocationAccuracy>(
                value: LocationAccuracy.high,
                groupValue: LocationAccuracy.bestForNavigation,
                onChanged: (value) {
                  if (value != null) {
                    _gpsService.setDesiredAccuracy(value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_gpsService.status) {
      case AdvancedGPSStatus.ready:
        return Colors.green;
      case AdvancedGPSStatus.recording:
        return Colors.blue;
      case AdvancedGPSStatus.paused:
        return Colors.orange;
      case AdvancedGPSStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_gpsService.status) {
      case AdvancedGPSStatus.idle:
        return 'Parado';
      case AdvancedGPSStatus.initializing:
        return 'Inicializando...';
      case AdvancedGPSStatus.ready:
        return 'Pronto para captura';
      case AdvancedGPSStatus.recording:
        return 'Capturando posições';
      case AdvancedGPSStatus.paused:
        return 'Pausado';
      case AdvancedGPSStatus.finished:
        return 'Finalizado';
      case AdvancedGPSStatus.error:
        return 'Erro';
    }
  }

  IconData _getStartStopIcon() {
    final status = _gpsService.status;
    if (status == AdvancedGPSStatus.recording) {
      return Icons.stop;
    }
    return Icons.play_arrow;
  }

  String _getStartStopText() {
    final status = _gpsService.status;
    if (status == AdvancedGPSStatus.recording) {
      return 'Parar';
    }
    return 'Iniciar';
  }

  Color _getStartStopColor() {
    final status = _gpsService.status;
    if (status == AdvancedGPSStatus.recording) {
      return Colors.red;
    }
    return Colors.green;
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 2.0) return Colors.green;
    if (accuracy <= 5.0) return Colors.lightGreen;
    if (accuracy <= 10.0) return Colors.yellow;
    if (accuracy <= 20.0) return Colors.orange;
    return Colors.red;
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excelente':
        return Colors.green;
      case 'muito boa':
        return Colors.lightGreen;
      case 'boa':
        return Colors.yellow;
      case 'regular':
        return Colors.orange;
      case 'baixa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}
