import 'package:flutter/material.dart';
import '../services/hybrid_gps_service.dart';

/// Widget para mostrar status do GPS híbrido
class HybridGPSStatusWidget extends StatefulWidget {
  final HybridGPSService? gpsService;
  final bool showDetails;

  const HybridGPSStatusWidget({
    Key? key,
    this.gpsService,
    this.showDetails = false,
  }) : super(key: key);

  @override
  State<HybridGPSStatusWidget> createState() => _HybridGPSStatusWidgetState();
}

class _HybridGPSStatusWidgetState extends State<HybridGPSStatusWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.gpsService == null) {
      return const SizedBox.shrink();
    }

    final stats = widget.gpsService!.getTrackingStats();
    final isOnline = stats['isOnline'] as bool;
    final isTracking = stats['isTracking'] as bool;
    final isPaused = stats['isPaused'] as bool;
    final accuracy = stats['currentAccuracy'] as double;
    final satellitesCount = stats['satellitesCount'] as int;
    final activeSatellites = stats['activeSatellites'] as int;
    final mode = stats['mode'] as String;
    final availableSystems = stats['availableSystems'] as List<String>;
    final multiSystemEnabled = stats['multiSystemEnabled'] as bool;
    final systemSatelliteCounts = stats['systemSatelliteCounts'] as Map<String, int>;
    final systemAccuracy = stats['systemAccuracy'] as Map<String, double>;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(isOnline, isTracking, isPaused).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(isOnline, isTracking, isPaused).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status principal
          Row(
            children: [
              Icon(
                _getStatusIcon(isOnline, isTracking, isPaused),
                color: _getStatusColor(isOnline, isTracking, isPaused),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(isOnline, isTracking, isPaused),
                  style: TextStyle(
                    color: _getStatusColor(isOnline, isTracking, isPaused),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              // Indicador de modo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mode == 'online' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mode == 'online' ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Indicador de sistemas múltiplos
              if (multiSystemEnabled)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'MULTI-GNSS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          if (widget.showDetails) ...[
            const SizedBox(height: 8),
            
            // Detalhes técnicos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  'Precisão',
                  '${accuracy.toStringAsFixed(1)}m',
                  _getAccuracyColor(accuracy),
                ),
                _buildDetailItem(
                  'Satélites',
                  '$activeSatellites/$satellitesCount',
                  _getSatellitesColor(activeSatellites, satellitesCount),
                ),
              ],
            ),
            
            if (multiSystemEnabled) ...[
              const SizedBox(height: 8),
              
              // Sistemas de satélites disponíveis
              _buildSatelliteSystemsInfo(availableSystems, systemSatelliteCounts, systemAccuracy),
            ],
            
            const SizedBox(height: 8),
            
            // Informações de conectividade
            _buildConnectivityInfo(mode, multiSystemEnabled),
          ],
        ],
      ),
    );
  }

  /// Constrói item de detalhe
  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Obtém cor do status
  Color _getStatusColor(bool isOnline, bool isTracking, bool isPaused) {
    if (!isTracking) return Colors.grey;
    if (isPaused) return Colors.orange;
    if (isOnline) return Colors.green;
    return Colors.blue;
  }

  /// Obtém ícone do status
  IconData _getStatusIcon(bool isOnline, bool isTracking, bool isPaused) {
    if (!isTracking) return Icons.gps_off;
    if (isPaused) return Icons.pause;
    if (isOnline) return Icons.gps_fixed;
    return Icons.gps_not_fixed;
  }

  /// Obtém texto do status
  String _getStatusText(bool isOnline, bool isTracking, bool isPaused) {
    if (!isTracking) return 'GPS Desligado';
    if (isPaused) return 'GPS Pausado';
    if (isOnline) return 'GPS Ativo (Online)';
    return 'GPS Ativo (Offline)';
  }

  /// Obtém cor da precisão
  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 5) return Colors.green;
    if (accuracy <= 10) return Colors.orange;
    return Colors.red;
  }

  /// Obtém cor dos satélites
  Color _getSatellitesColor(int active, int total) {
    final ratio = total > 0 ? active / total : 0;
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.5) return Colors.orange;
    return Colors.red;
  }
  
  /// Constrói informações dos sistemas de satélites
  Widget _buildSatelliteSystemsInfo(
    List<String> availableSystems,
    Map<String, int> systemSatelliteCounts,
    Map<String, double> systemAccuracy,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.satellite, color: Colors.blue, size: 16),
              const SizedBox(width: 4),
              Text(
                'Sistemas GNSS (${availableSystems.length})',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: availableSystems.map((system) {
              final count = systemSatelliteCounts[system] ?? 0;
              final accuracy = systemAccuracy[system] ?? 0.0;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSystemColor(system),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${system.toUpperCase()}: $count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// Obtém cor do sistema de satélites
  Color _getSystemColor(String system) {
    switch (system.toLowerCase()) {
      case 'gps':
        return Colors.green;
      case 'glonass':
        return Colors.red;
      case 'galileo':
        return Colors.blue;
      case 'beidou':
        return Colors.orange;
      case 'qzss':
        return Colors.purple;
      case 'irnss':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  /// Constrói informações de conectividade
  Widget _buildConnectivityInfo(String mode, bool multiSystemEnabled) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: mode == 'online' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: mode == 'online' ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            mode == 'online' ? Icons.wifi : Icons.wifi_off,
            color: mode == 'online' ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == 'online' ? 'Modo Online' : 'Modo Offline',
                  style: TextStyle(
                    color: mode == 'online' ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  mode == 'online' 
                    ? 'GPS + GLONASS + Galileo com assistência de rede'
                    : 'GPS + GLONASS + Galileo sem assistência de rede',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (multiSystemEnabled)
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
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
