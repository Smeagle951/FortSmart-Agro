import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/background_location_service.dart';
import '../utils/logger.dart';

class BackgroundLocationController extends StatefulWidget {
  final Function(Position)? onLocationUpdate;
  final Function(String)? onError;
  final Widget? child;

  const BackgroundLocationController({
    Key? key,
    this.onLocationUpdate,
    this.onError,
    this.child,
  }) : super(key: key);

  @override
  State<BackgroundLocationController> createState() => _BackgroundLocationControllerState();
}

class _BackgroundLocationControllerState extends State<BackgroundLocationController> {
  final BackgroundLocationService _locationService = BackgroundLocationService();
  bool _isTracking = false;
  Position? _lastPosition;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final isEnabled = await _locationService.isLocationServiceEnabled();
    if (!isEnabled) {
      setState(() {
        _errorMessage = 'Serviço de localização desabilitado';
      });
    }
  }

  Future<void> _startTracking() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final success = await _locationService.startBackgroundTracking(
        onLocationUpdate: (position) {
          setState(() {
            _lastPosition = position;
            _errorMessage = null;
          });
          widget.onLocationUpdate?.call(position);
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
          });
          widget.onError?.call(error);
        },
        onTrackingStarted: () {
          setState(() {
            _isTracking = true;
          });
          Logger.info('✅ Rastreamento iniciado');
        },
        onTrackingStopped: () {
          setState(() {
            _isTracking = false;
          });
          Logger.info('🛑 Rastreamento parado');
        },
      );

      if (!success) {
        setState(() {
          _errorMessage = 'Falha ao iniciar rastreamento';
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      Logger.error('❌ Erro ao iniciar rastreamento: $e');
    }
  }

  Future<void> _stopTracking() async {
    try {
      await _locationService.stopBackgroundTracking();
    } catch (e) {
      Logger.error('❌ Erro ao parar rastreamento: $e');
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _lastPosition = position;
        });
        widget.onLocationUpdate?.call(position);
      } else {
        setState(() {
          _errorMessage = 'Não foi possível obter a posição atual';
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      Logger.error('❌ Erro ao obter posição atual: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status do rastreamento
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isTracking ? Icons.location_on : Icons.location_off,
                      color: _isTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rastreamento de Localização',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Switch(
                      value: _isTracking,
                      onChanged: (value) {
                        if (value) {
                          _startTracking();
                        } else {
                          _stopTracking();
                        }
                      },
                    ),
                  ],
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_lastPosition != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Última Posição:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Latitude: ${_lastPosition!.latitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                        Text(
                          'Longitude: ${_lastPosition!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                        Text(
                          'Precisão: ${_lastPosition!.accuracy.toStringAsFixed(1)}m',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Botões de controle
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _getCurrentPosition,
                icon: const Icon(Icons.my_location),
                label: const Text('Posição Atual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _locationService.openLocationSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Configurações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        // Widget filho (se fornecido)
        if (widget.child != null) ...[
          const SizedBox(height: 16),
          widget.child!,
        ],
      ],
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
