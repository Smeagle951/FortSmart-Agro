import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:latlong2/latlong.dart';

import '../models/penetrometro_reading_model.dart';
import '../services/penetrometro_bluetooth_service.dart';
import '../repositories/penetrometro_reading_repository.dart';
import '../widgets/penetrometro_chart_widget.dart';
import '../constants/app_colors.dart';

/// Tela de coleta de dados com penetrômetro Bluetooth
class SoilBluetoothCollectionScreen extends StatefulWidget {
  final int? talhaoId;
  final String? nomeTalhao;
  final List<LatLng>? polygonCoordinates;

  const SoilBluetoothCollectionScreen({
    Key? key,
    this.talhaoId,
    this.nomeTalhao,
    this.polygonCoordinates,
  }) : super(key: key);

  @override
  State<SoilBluetoothCollectionScreen> createState() => _SoilBluetoothCollectionScreenState();
}

class _SoilBluetoothCollectionScreenState extends State<SoilBluetoothCollectionScreen> {
  // Serviços
  late PenetrometroBluetoothService _bluetoothService;
  late PenetrometroReadingRepository _repository;
  
  // Estado
  List<DiscoveredDevice> _discoveredDevices = [];
  List<PenetrometroReading> _readings = [];
  PenetrometroReading? _lastReading;
  String _status = 'Inicializando...';
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isCollecting = false;
  
  // Controles
  Timer? _autoSaveTimer;
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _pointCodeController = TextEditingController();

  // UUIDs do penetrômetro (substitua pelos reais do seu equipamento)
  static const String _serviceUuid = '0000180A-0000-1000-8000-00805F9B34FB'; // Device Information Service
  static const String _charUuid = '00002A37-0000-1000-8000-00805F9B34FB'; // Heart Rate Measurement

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    _autoSaveTimer?.cancel();
    _observacoesController.dispose();
    _pointCodeController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _repository = PenetrometroReadingRepository();
      await _repository.init();
      
      _bluetoothService = PenetrometroBluetoothService(
        serviceUuid: Uuid.parse(_serviceUuid),
        charUuid: Uuid.parse(_charUuid),
      );
      
      _setupListeners();
      await _loadExistingReadings();
      
      setState(() {
        _status = 'Pronto para conectar';
      });
    } catch (e) {
      setState(() {
        _status = 'Erro na inicialização: $e';
      });
    }
  }

  void _setupListeners() {
    // Listener de status
    _bluetoothService.status.listen((status) {
      setState(() {
        _status = status;
      });
    });

    // Listener de dispositivos descobertos
    _bluetoothService.discoveredDevices.listen((device) {
      setState(() {
        if (!_discoveredDevices.any((d) => d.id == device.id)) {
          _discoveredDevices.add(device);
        }
      });
    });

    // Listener de leituras
    _bluetoothService.readings.listen((reading) {
      setState(() {
        _lastReading = reading;
        _readings.add(reading);
      });
      
      // Auto-save a cada 5 leituras
      if (_readings.length % 5 == 0) {
        _saveReadings();
      }
    });
  }

  Future<void> _loadExistingReadings() async {
    try {
      final readings = await _repository.getAllReadings(limit: 50);
      setState(() {
        _readings = readings;
      });
    } catch (e) {
      print('Erro ao carregar leituras: $e');
    }
  }

  Future<void> _checkPermissionsAndScan() async {
    final hasPermissions = await _bluetoothService.checkPermissions();
    if (!hasPermissions) {
      _showErrorDialog('Permissões necessárias não foram concedidas');
      return;
    }

    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    try {
      await for (final device in _bluetoothService.scanForDevices(
        nameFilter: 'Penetrômetro', // Filtro por nome
        timeout: const Duration(seconds: 10),
      )) {
        // Dispositivos são adicionados automaticamente pelo listener
      }
    } catch (e) {
      _showErrorDialog('Erro no scan: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _status = 'Conectando...';
    });

    final success = await _bluetoothService.connectToDevice(device.id);
    if (success) {
      setState(() {
        _isConnected = true;
        _isCollecting = true;
      });
      
      // Inicia auto-save a cada 30 segundos
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _saveReadings();
      });
    } else {
      _showErrorDialog('Falha na conexão');
    }
  }

  Future<void> _disconnect() async {
    await _bluetoothService.disconnect();
    _autoSaveTimer?.cancel();
    
    setState(() {
      _isConnected = false;
      _isCollecting = false;
    });
  }

  Future<void> _saveReadings() async {
    if (_readings.isEmpty) return;

    try {
      // Filtra leituras não salvas (sem ID)
      final unsavedReadings = _readings.where((r) => r.id == null).toList();
      
      if (unsavedReadings.isNotEmpty) {
        // Adiciona informações do talhão e observações
        final readingsToSave = unsavedReadings.map((reading) {
          return reading.copyWith(
            talhaoId: widget.talhaoId,
            pointCode: _pointCodeController.text.isNotEmpty ? _pointCodeController.text : null,
            observacoes: _observacoesController.text.isNotEmpty ? _observacoesController.text : null,
          );
        }).toList();

        await _repository.insertReadingsBatch(readingsToSave);
        
        // Atualiza lista local com IDs
        await _loadExistingReadings();
        
        _showSuccessSnackBar('${readingsToSave.length} leituras salvas');
      }
    } catch (e) {
      _showErrorDialog('Erro ao salvar: $e');
    }
  }

  void _simulateReading() {
    _bluetoothService.simularLeitura();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Coleta com Penetrômetro${widget.nomeTalhao != null ? ' - ${widget.nomeTalhao}' : ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isConnected)
            IconButton(
              onPressed: _disconnect,
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Desconectar',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          _buildControlPanel(),
          Expanded(
            child: _buildContent(),
          ),
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
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Conectado' : 'Desconectado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Status: $_status'),
            if (_lastReading != null) ...[
              const SizedBox(height: 8),
              Text('Última leitura: ${_lastReading!.resumoFormatado}'),
            ],
            Text('Total de leituras: ${_readings.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Botões de controle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _checkPermissionsAndScan,
                    icon: _isScanning 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isScanning ? 'Escaneando...' : 'Escanear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _disconnect : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Desconectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Campos de entrada
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pointCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Código do Ponto',
                      hintText: 'Ex: C-001',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Ex: Solo úmido',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveReadings,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Leituras'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _simulateReading,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Simular'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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

  Widget _buildContent() {
    if (_isScanning) {
      return _buildScanningView();
    } else if (_discoveredDevices.isNotEmpty) {
      return _buildDevicesView();
    } else if (_isConnected) {
      return _buildCollectionView();
    } else {
      return _buildEmptyView();
    }
  }

  Widget _buildScanningView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Escaneando dispositivos...'),
        ],
      ),
    );
  }

  Widget _buildDevicesView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Dispositivos Encontrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _discoveredDevices.length,
            itemBuilder: (context, index) {
              final device = _discoveredDevices[index];
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(device.name ?? 'Dispositivo Desconhecido'),
                subtitle: Text('ID: ${device.id}'),
                trailing: ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  child: const Text('Conectar'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionView() {
    return Column(
      children: [
        // Gráfico em tempo real
        if (_readings.isNotEmpty)
          Expanded(
            flex: 2,
            child: PenetrometroChartWidget(
              readings: _readings,
              showRealTime: true,
            ),
          ),
        
        // Lista de leituras
        Expanded(
          flex: 1,
          child: _buildReadingsList(),
        ),
      ],
    );
  }

  Widget _buildReadingsList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Leituras Coletadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _readings.length,
            itemBuilder: (context, index) {
              final reading = _readings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(reading.getCorNivel().replaceAll('#', '0xFF'))),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(reading.resumoFormatado),
                  subtitle: Text(
                    '${reading.timestamp.toString().substring(11, 19)} - ${reading.deviceId}',
                  ),
                  trailing: reading.synced
                      ? const Icon(Icons.cloud_done, color: Colors.green)
                      : const Icon(Icons.cloud_upload, color: Colors.orange),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum dispositivo conectado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em "Escanear" para buscar penetrômetros',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
