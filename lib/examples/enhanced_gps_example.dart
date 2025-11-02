import 'package:flutter/material.dart';
import '../providers/enhanced_gps_provider.dart';
import '../services/background_gps_service.dart';

/// Exemplo de uso do sistema de GPS aprimorado para talhões
class EnhancedGpsExample extends StatefulWidget {
  const EnhancedGpsExample({Key? key}) : super(key: key);

  @override
  State<EnhancedGpsExample> createState() => _EnhancedGpsExampleState();
}

class _EnhancedGpsExampleState extends State<EnhancedGpsExample> {
  final EnhancedGpsProvider _gpsProvider = EnhancedGpsProvider();
  bool _isInitialized = false;
  String _status = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _initializeGps();
  }

  Future<void> _initializeGps() async {
    try {
      await _gpsProvider.initialize();
      setState(() {
        _isInitialized = true;
        _status = 'GPS inicializado com sucesso';
      });
    } catch (e) {
      setState(() {
        _status = 'Erro ao inicializar GPS: $e';
      });
    }
  }

  Future<void> _startTracking() async {
    if (!_isInitialized) return;

    setState(() {
      _status = 'Iniciando rastreamento...';
    });

    final success = await _gpsProvider.startTracking(
      talhaoId: 'talhao_${DateTime.now().millisecondsSinceEpoch}',
      talhaoNome: 'Talhão Exemplo',
      minDistanceMeters: 2,
      updateIntervalMs: 1000,
      enableSmoothing: true,
      enableBackground: true,
    );

    setState(() {
      _status = success 
          ? 'Rastreamento iniciado com sucesso'
          : 'Falha ao iniciar rastreamento';
    });
  }

  Future<void> _stopTracking() async {
    await _gpsProvider.stopTracking();
    setState(() {
      _status = 'Rastreamento parado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Aprimorado - Exemplo'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('GPS Ativo: ${_gpsProvider.isTracking ? "Sim" : "Não"}'),
                    Text('Localização Atual: ${_gpsProvider.currentLocation?.toString() ?? "N/A"}'),
                    Text('Pontos Rastreados: ${_gpsProvider.trackPoints.length}'),
                    Text('Pontos Suavizados: ${_gpsProvider.smoothedTrackPoints.length}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Controles
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized && !_gpsProvider.isTracking 
                        ? _startTracking 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Iniciar Rastreamento'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _gpsProvider.isTracking ? _stopTracking : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Parar Rastreamento'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Configurações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurações',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Suavização GPS'),
                      subtitle: const Text('Aplica filtro de média móvel'),
                      value: _gpsProvider.enableSmoothing,
                      onChanged: (value) {
                        _gpsProvider.updateTrackingSettings(enableSmoothing: value);
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Rastreamento em Background'),
                      subtitle: const Text('Continua funcionando com app fechado'),
                      value: _gpsProvider.enableBackgroundTracking,
                      onChanged: (value) {
                        _gpsProvider.updateTrackingSettings(enableBackground: value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de pontos
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pontos Rastreados',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _gpsProvider.trackPoints.length,
                          itemBuilder: (context, index) {
                            final point = _gpsProvider.trackPoints[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text('${index + 1}'),
                              ),
                              title: Text('Ponto ${index + 1}'),
                              subtitle: Text(
                                'Lat: ${point.latitude.toStringAsFixed(6)}\n'
                                'Lng: ${point.longitude.toStringAsFixed(6)}',
                              ),
                              trailing: _gpsProvider.enableSmoothing && 
                                      index < _gpsProvider.smoothedTrackPoints.length
                                  ? const Icon(Icons.tune, color: Colors.blue)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gpsProvider.dispose();
    super.dispose();
  }
}
