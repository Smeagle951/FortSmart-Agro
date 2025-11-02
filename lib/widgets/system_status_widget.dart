import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/system_status_service.dart';

/// Widget para exibir o status do sistema (GPS e Conectividade)
class SystemStatusWidget extends StatefulWidget {
  final SystemStatusService? statusService;
  final bool showDetails;

  const SystemStatusWidget({
    Key? key,
    this.statusService,
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<SystemStatusWidget> createState() => _SystemStatusWidgetState();
}

class _SystemStatusWidgetState extends State<SystemStatusWidget> {
  late SystemStatusService _statusService;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _statusService = widget.statusService ?? SystemStatusService();
    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    try {
      await _statusService.initialize();
      _statusService.onStatusChanged = () {
        if (mounted) setState(() {});
      };
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingCard();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(Icons.satellite_alt, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Status do Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status GPS
            _buildGPSStatus(),
            
            const SizedBox(height: 16),
            
            // Sistemas GNSS
            if (widget.showDetails) _buildGNSSSystems(),
            
            const SizedBox(height: 16),
            
            // Modo Online
            if (widget.showDetails) _buildOnlineMode(),
            
            const SizedBox(height: 20),
            
            // Status Conectividade
            _buildConnectivityStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.satellite_alt, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Status do Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicializando sistema...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSStatus() {
    final statusColor = _getGPSStatusColor();
    final statusText = _statusService.gpsStatusText;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getGPSStatusIcon(),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              // Botão de ação
              if (!_statusService.gpsEnabled || !_statusService.gpsPermissionGranted)
                TextButton.icon(
                  onPressed: _handleGPSAction,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Configurar'),
                  style: TextButton.styleFrom(
                    foregroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          
          if (_statusService.gpsEnabled && _statusService.gpsPermissionGranted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precisão',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_statusService.gpsAccuracy.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satélites',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_statusService.activeSatellites}/${_statusService.satelliteCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGNSSSystems() {
    final gnssSystems = _statusService.gnssSystems;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistemas GNSS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: gnssSystems.entries.map((entry) {
              final color = _getGNSSSystemColor(entry.key);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineMode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: Colors.green[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS + GLONASS + Galileo com assistência de rede',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'MULTI-GNSS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityStatus() {
    final statusColor = _getConnectivityStatusColor();
    final statusText = _statusService.connectivityStatusText;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getConnectivityStatusIcon(),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _statusService.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (_statusService.isOnline) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Conexão',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _statusService.connectionSpeed,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latência',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_statusService.connectionLatency}ms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última Verificação',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Agora',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getGPSStatusColor() {
    if (!_statusService.gpsEnabled) return Colors.red;
    if (!_statusService.gpsPermissionGranted) return Colors.orange;
    if (_statusService.gpsAccuracy == 0.0) return Colors.yellow[700]!;
    if (_statusService.gpsAccuracy < 5.0) return Colors.green;
    if (_statusService.gpsAccuracy < 15.0) return Colors.orange;
    return Colors.red;
  }

  IconData _getGPSStatusIcon() {
    if (!_statusService.gpsEnabled) return Icons.location_disabled;
    if (!_statusService.gpsPermissionGranted) return Icons.location_off;
    if (_statusService.gpsAccuracy == 0.0) return Icons.location_searching;
    return Icons.location_on;
  }

  Color _getConnectivityStatusColor() {
    return _statusService.isOnline ? Colors.green : Colors.red;
  }

  IconData _getConnectivityStatusIcon() {
    return _statusService.isOnline ? Icons.wifi : Icons.wifi_off;
  }

  Color _getGNSSSystemColor(String system) {
    switch (system) {
      case 'GPS': return Colors.green;
      case 'GLONASS': return Colors.red;
      case 'GALILEO': return Colors.blue;
      case 'BEIDOU': return Colors.orange;
      case 'QZSS': return Colors.purple;
      case 'IRNSS': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _handleGPSAction() async {
    if (!_statusService.gpsEnabled) {
      // Abrir configurações do sistema
      await _statusService.openLocationSettings();
    } else if (!_statusService.gpsPermissionGranted) {
      // Solicitar permissão
      final granted = await _statusService.requestLocationPermission();
      if (granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização concedida!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
