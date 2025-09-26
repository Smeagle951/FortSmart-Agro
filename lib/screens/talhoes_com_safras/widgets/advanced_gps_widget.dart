import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/advanced_gps_service.dart';

/// Widget para exibir informações detalhadas do GPS avançado
class AdvancedGPSWidget extends StatefulWidget {
  final AdvancedGPSService gpsService;
  final Function(AdvancedPosition)? onPositionUpdate;
  final Function(String)? onError;

  const AdvancedGPSWidget({
    Key? key,
    required this.gpsService,
    this.onPositionUpdate,
    this.onError,
  }) : super(key: key);

  @override
  State<AdvancedGPSWidget> createState() => _AdvancedGPSWidgetState();
}

class _AdvancedGPSWidgetState extends State<AdvancedGPSWidget> {
  bool _isExpanded = false;
  AdvancedPosition? _currentPosition;

  @override
  void initState() {
    super.initState();
    _setupGPSCallbacks();
  }

  void _setupGPSCallbacks() {
    widget.gpsService.onPositionUpdate = (position) {
      setState(() {
        _currentPosition = position;
      });
      widget.onPositionUpdate?.call(position);
    };

    widget.gpsService.onError = (error) {
      widget.onError?.call(error);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Cabeçalho do GPS
          ListTile(
            leading: Icon(
              Icons.satellite_alt,
              color: _getStatusColor(),
              size: 28,
            ),
            title: Text(
              'GPS Avançado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(_getStatusText()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIndicator(),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          
          // Conteúdo expandido
          if (_isExpanded) ...[
            Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações de posição
                  if (_currentPosition != null) ...[
                    _buildPositionInfo(),
                    SizedBox(height: 16),
                    _buildSatelliteInfo(),
                    SizedBox(height: 16),
                    _buildQualityInfo(),
                    SizedBox(height: 16),
                    _buildActionButtons(),
                  ] else ...[
                    _buildNoPositionInfo(),
                    SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final status = widget.gpsService.status;
    Color color;
    IconData icon;
    
    switch (status) {
      case AdvancedGPSStatus.ready:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AdvancedGPSStatus.recording:
        color = Colors.blue;
        icon = Icons.radio_button_checked;
        break;
      case AdvancedGPSStatus.paused:
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      case AdvancedGPSStatus.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.radio_button_unchecked;
    }
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPositionInfo() {
    final pos = _currentPosition!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posição Atual',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Latitude',
                '${pos.latitude.toStringAsFixed(6)}°',
                Icons.north,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Longitude',
                '${pos.longitude.toStringAsFixed(6)}°',
                Icons.east,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Altitude',
                '${pos.altitude.toStringAsFixed(1)}m',
                Icons.height,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Precisão',
                '${pos.accuracy.toStringAsFixed(1)}m',
                Icons.center_focus_strong,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSatelliteInfo() {
    final pos = _currentPosition!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sistemas de Satélites',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        
        // Contadores de satélites
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Usados',
                '${pos.totalSatellitesUsed}',
                Icons.satellite,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Visíveis',
                '${pos.totalSatellitesVisible}',
                Icons.satellite_alt,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        // Sistemas ativos
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: pos.satellitesBySystem.entries.map((entry) {
            return Chip(
              label: Text(
                '${entry.key.toString().split('.').last.toUpperCase()}: ${entry.value}',
                style: TextStyle(fontSize: 10),
              ),
              backgroundColor: _getSystemColor(entry.key),
              labelStyle: TextStyle(color: Colors.white),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQualityInfo() {
    final pos = _currentPosition!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qualidade do Sinal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Qualidade',
                pos.qualityInfo,
                Icons.signal_cellular_alt,
                color: _getQualityColor(pos.qualityInfo),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'HDOP',
                '${pos.hdop.toStringAsFixed(1)}',
                Icons.precision_manufacturing,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        // Barra de qualidade
        LinearProgressIndicator(
          value: _getQualityValue(pos.qualityInfo),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getQualityColor(pos.qualityInfo)),
        ),
      ],
    );
  }

  Widget _buildNoPositionInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_searching,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Aguardando posição GPS...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Certifique-se de estar em área aberta',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleStartStop,
            icon: Icon(_getStartStopIcon()),
            label: Text(_getStartStopText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStartStopColor(),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleSettings,
            icon: Icon(Icons.settings),
            label: Text('Configurar'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: EdgeInsets.all(8),
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
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
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
    final status = widget.gpsService.status;
    
    if (status == AdvancedGPSStatus.ready || status == AdvancedGPSStatus.paused) {
      widget.gpsService.startPositionCapture();
    } else if (status == AdvancedGPSStatus.recording) {
      widget.gpsService.stopPositionCapture();
    }
  }

  void _handleSettings() {
    showDialog(
      context: context,
      builder: (context) => _buildSettingsDialog(),
    );
  }

  Widget _buildSettingsDialog() {
    return AlertDialog(
      title: Text('Configurações GPS'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Alta Precisão'),
            subtitle: Text('Melhor precisão, mais consumo de bateria'),
            leading: Radio<LocationAccuracy>(
              value: LocationAccuracy.bestForNavigation,
              groupValue: LocationAccuracy.bestForNavigation,
              onChanged: (value) {
                if (value != null) {
                  widget.gpsService.setDesiredAccuracy(value);
                }
              },
            ),
          ),
          ListTile(
            title: Text('Precisão Alta'),
            subtitle: Text('Boa precisão, consumo moderado'),
            leading: Radio<LocationAccuracy>(
              value: LocationAccuracy.high,
              groupValue: LocationAccuracy.bestForNavigation,
              onChanged: (value) {
                if (value != null) {
                  widget.gpsService.setDesiredAccuracy(value);
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fechar'),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.gpsService.status) {
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
    switch (widget.gpsService.status) {
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
    final status = widget.gpsService.status;
    if (status == AdvancedGPSStatus.recording) {
      return Icons.stop;
    }
    return Icons.play_arrow;
  }

  String _getStartStopText() {
    final status = widget.gpsService.status;
    if (status == AdvancedGPSStatus.recording) {
      return 'Parar';
    }
    return 'Iniciar';
  }

  Color _getStartStopColor() {
    final status = widget.gpsService.status;
    if (status == AdvancedGPSStatus.recording) {
      return Colors.red;
    }
    return Colors.green;
  }

  Color _getSystemColor(SatelliteSystem system) {
    switch (system) {
      case SatelliteSystem.gps:
        return Colors.blue;
      case SatelliteSystem.glonass:
        return Colors.red;
      case SatelliteSystem.galileo:
        return Colors.green;
      case SatelliteSystem.beidou:
        return Colors.orange;
      case SatelliteSystem.qzss:
        return Colors.purple;
      case SatelliteSystem.irnss:
        return Colors.teal;
    }
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

  double _getQualityValue(String quality) {
    switch (quality.toLowerCase()) {
      case 'excelente':
        return 1.0;
      case 'muito boa':
        return 0.8;
      case 'boa':
        return 0.6;
      case 'regular':
        return 0.4;
      case 'baixa':
        return 0.2;
      default:
        return 0.0;
    }
  }
}
