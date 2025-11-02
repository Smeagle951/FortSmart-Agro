import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';

import '../models/penetrometro_reading_model.dart';
import '../models/penetrometro_device_model.dart';
import '../services/bluetooth_permission_service.dart';
import '../services/penetrometro_bluetooth_advanced_service.dart';
import '../constants/app_colors.dart';

/// Tela profissional para gerenciamento de penetrômetros Bluetooth
class PenetrometroBluetoothProfessionalScreen extends StatefulWidget {
  const PenetrometroBluetoothProfessionalScreen({Key? key}) : super(key: key);

  @override
  State<PenetrometroBluetoothProfessionalScreen> createState() => _PenetrometroBluetoothProfessionalScreenState();
}

class _PenetrometroBluetoothProfessionalScreenState extends State<PenetrometroBluetoothProfessionalScreen> 
    with TickerProviderStateMixin {
  
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final PenetrometroBluetoothAdvancedService _bluetoothService = PenetrometroBluetoothAdvancedService();
  
  // Estado da interface
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isConnected = false;
  String _status = 'Inicializando...';
  
  // Dispositivos
  List<DiscoveredDevice> _dispositivosEncontrados = [];
  List<DiscoveredDevice> _dispositivosPareados = [];
  DiscoveredDevice? _dispositivoConectado;
  PenetrometroDeviceModel? _tipoDispositivo;
  
  // Leituras
  List<PenetrometroReading> _leituras = [];
  PenetrometroReading? _ultimaLeitura;
  
  // Controles de animação
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  
  // Streams
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<PenetrometroReading>? _readingSubscription;
  StreamSubscription<String>? _statusSubscription;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _inicializarAnimacoes();
    _inicializarBluetooth();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    _scanSubscription?.cancel();
    _readingSubscription?.cancel();
    _statusSubscription?.cancel();
    _scanTimer?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  void _inicializarAnimacoes() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _inicializarBluetooth() async {
    try {
      setState(() {
        _status = 'Verificando permissões...';
      });

      // Verifica prontidão inicial do Bluetooth
      final readiness = await BluetoothPermissionService.checkBluetoothReadiness();
      
      // Tenta resolver problemas de permissão
      if (readiness['hasPermissions'] != true) {
        setState(() {
          _status = 'Solicitando permissões Bluetooth...';
        });
        
        final hasPermissions = await BluetoothPermissionService.ensurePermissions();
        if (!hasPermissions) {
          setState(() {
            _status = 'Permissões Bluetooth negadas';
          });
          _mostrarDialogoPermissoes();
          return;
        }
      }
      
      // Tenta habilitar Bluetooth se estiver desligado
      if (readiness['isEnabled'] != true) {
        setState(() {
          _status = 'Habilitando Bluetooth...';
        });
        
        final isEnabled = await BluetoothPermissionService.ensureBluetoothEnabled();
        if (!isEnabled) {
          setState(() {
            _status = 'Bluetooth está desligado. Por favor, ligue o Bluetooth.';
          });
          _mostrarDialogoBluetooth();
          return;
        }
      }
      
      // Verifica novamente após tentar resolver problemas
      final newReadiness = await BluetoothPermissionService.checkBluetoothReadiness();
      if (!newReadiness['isReady']) {
        setState(() {
          _status = 'Bluetooth não está pronto: ${newReadiness['issues'].join(', ')}';
        });
        return;
      }

      // Inicializa o serviço
      await _bluetoothService.inicializar();
      
      // Escuta status
      _statusSubscription = _bluetoothService.statusStream.listen((status) {
        setState(() {
          _status = status;
        });
      });

      // Escuta leituras
      _readingSubscription = _bluetoothService.readingStream.listen((reading) {
        setState(() {
          _ultimaLeitura = reading;
          _leituras.add(reading);
        });
      });

      // Carrega dispositivos pareados
      await _carregarDispositivosPareados();
      
      setState(() {
        _isInitialized = true;
        _status = 'Bluetooth pronto - ${_dispositivosPareados.length} dispositivos pareados';
      });

    } catch (e) {
      setState(() {
        _status = 'Erro ao inicializar: $e';
      });
    }
  }

  Future<void> _carregarDispositivosPareados() async {
    try {
      setState(() {
        _status = 'Carregando dispositivos pareados...';
      });

      // Obtém dispositivos pareados do sistema
      final dispositivosPareados = await BluetoothPermissionService.getPairedDevices();
      
      // Converte para DiscoveredDevice (simulação)
      final dispositivos = dispositivosPareados.map((device) {
        return DiscoveredDevice(
          id: device['address'] ?? '',
          name: device['name'] ?? 'Dispositivo Desconhecido',
          rssi: -50, // RSSI padrão para dispositivos pareados
          serviceData: {},
          serviceUuids: [],
          manufacturerData: Uint8List(0),
        );
      }).toList();

      setState(() {
        _dispositivosPareados = dispositivos;
        _status = 'Bluetooth pronto - ${dispositivos.length} dispositivos pareados';
      });
    } catch (e) {
      print('Erro ao carregar dispositivos pareados: $e');
      setState(() {
        _status = 'Erro ao carregar dispositivos pareados: $e';
      });
    }
  }

  Future<void> _iniciarScan() async {
    if (_isScanning) return;

    try {
      // Garante permissões e Bluetooth ligado antes de escanear
      final readiness = await BluetoothPermissionService.checkBluetoothReadiness();
      if (readiness['hasPermissions'] != true) {
        await BluetoothPermissionService.ensurePermissions();
      }
      if (readiness['isEnabled'] != true) {
        await BluetoothPermissionService.ensureBluetoothEnabled();
      }
      final newReadiness = await BluetoothPermissionService.checkBluetoothReadiness();
      if (newReadiness['isReady'] != true) {
        setState(() {
          _status = 'Bluetooth não pronto: ${newReadiness['issues']}';
        });
        return;
      }

      setState(() {
        _isScanning = true;
        _dispositivosEncontrados.clear();
        _status = 'Escaneando dispositivos...';
      });

      _scanSubscription = _ble.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true,
      ).listen(
        (device) {
          setState(() {
            _dispositivosEncontrados.add(device);
          });
        },
        onError: (error) {
          setState(() {
            _status = 'Erro no scan: $error';
          });
        },
      );

      // Para o scan após 30 segundos
      _scanTimer = Timer(const Duration(seconds: 30), () {
        _pararScan();
      });

    } catch (e) {
      setState(() {
        _isScanning = false;
        _status = 'Erro ao iniciar scan: $e';
      });
    }
  }

  void _pararScan() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    setState(() {
      _isScanning = false;
      _status = 'Scan finalizado - ${_dispositivosEncontrados.length} dispositivos encontrados';
    });
  }

  void _mostrarDialogoPermissoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permissões Necessárias'),
          ],
        ),
        content: const Text(
          'O aplicativo precisa de permissões Bluetooth para conectar ao penetrômetro.\n\n'
          'Por favor, vá em Configurações > Aplicativos > FortSmart Agro > Permissões '
          'e ative as permissões Bluetooth.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _inicializarBluetooth(); // Tentar novamente
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoBluetooth() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.red),
            SizedBox(width: 8),
            Text('Bluetooth Desligado'),
          ],
        ),
        content: const Text(
          'O Bluetooth está desligado no seu dispositivo.\n\n'
          'Por favor, ligue o Bluetooth e toque em "Tentar Novamente".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await BluetoothPermissionService.requestEnableBluetooth();
              await Future.delayed(const Duration(seconds: 1));
              _inicializarBluetooth(); // Tentar novamente
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _conectarDispositivo(DiscoveredDevice device) async {
    try {
      setState(() {
        _status = 'Conectando a ${device.name}...';
      });

      // Tenta identificar o tipo de dispositivo
      final tipoDispositivo = _identificarTipoDispositivo(device);
      
      final sucesso = await _bluetoothService.conectarDispositivo(device, tipoDispositivo);
      
      if (sucesso) {
        setState(() {
          _isConnected = true;
          _dispositivoConectado = device;
          _tipoDispositivo = tipoDispositivo;
          _status = 'Conectado a ${device.name}';
        });
      } else {
        setState(() {
          _status = 'Falha na conexão com ${device.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Erro ao conectar: $e';
      });
    }
  }

  PenetrometroDeviceModel _identificarTipoDispositivo(DiscoveredDevice device) {
    // Tenta identificar o tipo de dispositivo baseado no nome
    for (final tipo in PenetrometroDeviceModel.dispositivosSuportados) {
      if (device.name.toLowerCase().contains(tipo.nome.toLowerCase()) ||
          device.name.toLowerCase().contains(tipo.fabricante.toLowerCase())) {
        return tipo;
      }
    }
    
    // Se não encontrar, usa o genérico
    return PenetrometroDeviceModel.getById('generic_penetrometer')!;
  }

  Future<void> _desconectar() async {
    try {
      await _bluetoothService.desconectar();
      setState(() {
        _isConnected = false;
        _dispositivoConectado = null;
        _tipoDispositivo = null;
        _status = 'Desconectado';
      });
    } catch (e) {
      setState(() {
        _status = 'Erro ao desconectar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penetrômetro Bluetooth Pro'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _pararScan,
              tooltip: 'Parar Scan',
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth_searching),
              onPressed: _iniciarScan,
              tooltip: 'Escanear Dispositivos',
            ),
        ],
      ),
      body: _isInitialized ? _buildBody() : _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Status e controles
        _buildStatusPanel(),
        
        // Leituras em tempo real
        if (_isConnected) _buildRealTimeReadings(),
        
        // Tabs para dispositivos
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Dispositivos Pareados'),
                    Tab(text: 'Dispositivos Próximos'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPairedDevicesTab(),
                      _buildNearbyDevicesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(
            color: _isConnected ? Colors.green : Colors.blue,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: _isConnected ? Colors.green : Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isConnected && _tipoDispositivo != null)
                  Text(
                    'Tipo: ${_tipoDispositivo!.nome}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_isConnected)
            ElevatedButton.icon(
              onPressed: _desconectar,
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text('Desconectar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRealTimeReadings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.sensors,
                      color: Colors.green,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Leituras em Tempo Real',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ultimaLeitura != null)
            _buildReadingCard(_ultimaLeitura!)
          else
            const Text('Aguardando leituras...'),
        ],
      ),
    );
  }

  Widget _buildReadingCard(PenetrometroReading reading) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resistência: ${reading.resistenciaMpa.toStringAsFixed(2)} MPa',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Profundidade: ${reading.profundidadeCm.toStringAsFixed(1)} cm'),
                  Text('Nível: ${reading.calcularNivelCompactacao()}'),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${reading.timestamp.hour.toString().padLeft(2, '0')}:${reading.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${reading.timestamp.day}/${reading.timestamp.month}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairedDevicesTab() {
    return _dispositivosPareados.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum dispositivo pareado encontrado',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _dispositivosPareados.length,
            itemBuilder: (context, index) {
              final device = _dispositivosPareados[index];
              return _buildDeviceCard(device, isPaired: true);
            },
          );
  }

  Widget _buildNearbyDevicesTab() {
    return Column(
      children: [
        // Controles de scan
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? _pararScan : _iniciarScan,
                  icon: AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _scanAnimation.value * 2 * 3.14159,
                        child: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                      );
                    },
                  ),
                  label: Text(_isScanning ? 'Parar Scan' : 'Escanear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? Colors.red : AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_dispositivosEncontrados.length} encontrados'),
            ],
          ),
        ),
        
        // Lista de dispositivos
        Expanded(
          child: _dispositivosEncontrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isScanning 
                            ? 'Procurando dispositivos...'
                            : 'Toque em "Escanear" para procurar dispositivos',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _dispositivosEncontrados.length,
                  itemBuilder: (context, index) {
                    final device = _dispositivosEncontrados[index];
                    return _buildDeviceCard(device, isPaired: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device, {required bool isPaired}) {
    final isConnected = _dispositivoConectado?.id == device.id;
    final tipoDispositivo = _identificarTipoDispositivo(device);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected 
              ? Colors.green 
              : isPaired 
                  ? Colors.blue 
                  : Colors.orange,
          child: Icon(
            isConnected 
                ? Icons.bluetooth_connected 
                : isPaired 
                    ? Icons.bluetooth 
                    : Icons.bluetooth_searching,
            color: Colors.white,
          ),
        ),
        title: Text(device.name.isNotEmpty ? device.name : 'Dispositivo Desconhecido'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.id}'),
            Text('RSSI: ${device.rssi} dBm'),
            Text('Tipo: ${tipoDispositivo.nome}'),
            if (isPaired)
              const Text(
                '✓ Pareado',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                '? Não pareado',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: isConnected
            ? const Chip(
                label: Text('Conectado'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              )
            : ElevatedButton(
                onPressed: () => _conectarDispositivo(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaired ? Colors.blue : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Conectar'),
              ),
      ),
    );
  }
}
