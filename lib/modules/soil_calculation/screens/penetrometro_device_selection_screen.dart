import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/penetrometro_device_model.dart';
import '../services/penetrometro_bluetooth_advanced_service.dart';
import '../constants/app_colors.dart';

/// Tela para seleção de dispositivos penetrômetro
class PenetrometroDeviceSelectionScreen extends StatefulWidget {
  const PenetrometroDeviceSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PenetrometroDeviceSelectionScreen> createState() => _PenetrometroDeviceSelectionScreenState();
}

class _PenetrometroDeviceSelectionScreenState extends State<PenetrometroDeviceSelectionScreen> {
  final PenetrometroBluetoothAdvancedService _bluetoothService = PenetrometroBluetoothAdvancedService();
  
  List<DiscoveredDevice> _dispositivosEncontrados = [];
  List<PenetrometroDeviceModel> _dispositivosSuportados = [];
  bool _isScanning = false;
  String _status = 'Pronto para escanear';

  @override
  void initState() {
    super.initState();
    _inicializarServico();
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  Future<void> _inicializarServico() async {
    try {
      await _bluetoothService.inicializar();
      
      // Escuta dispositivos suportados
      _bluetoothService.supportedDevicesStream.listen((dispositivos) {
        setState(() {
          _dispositivosSuportados = dispositivos;
        });
      });

      // Escuta dispositivos encontrados
      _bluetoothService.deviceStream.listen((device) {
        setState(() {
          _dispositivosEncontrados.add(device);
        });
      });

      // Escuta status
      _bluetoothService.statusStream.listen((status) {
        setState(() {
          _status = status;
        });
      });

    } catch (e) {
      setState(() {
        _status = 'Erro ao inicializar: $e';
      });
    }
  }

  Future<void> _iniciarScan() async {
    setState(() {
      _isScanning = true;
      _dispositivosEncontrados.clear();
      _status = 'Escaneando...';
    });

    await _bluetoothService.escanearDispositivos();
  }

  void _pararScan() {
    _bluetoothService.pararScan();
    setState(() {
      _isScanning = false;
      _status = 'Scan finalizado';
    });
  }

  Future<void> _conectarDispositivo(DiscoveredDevice device) async {
    // Tenta encontrar um dispositivo suportado compatível
    PenetrometroDeviceModel? dispositivoCompativel;
    
    for (final supported in _dispositivosSuportados) {
      if (device.name.toLowerCase().contains(supported.nome.toLowerCase()) ||
          device.name.toLowerCase().contains(supported.fabricante.toLowerCase())) {
        dispositivoCompativel = supported;
        break;
      }
    }

    // Se não encontrar, usa o genérico
    dispositivoCompativel ??= PenetrometroDeviceModel.getById('generic_penetrometer');

    if (dispositivoCompativel == null) {
      _mostrarSnackBar('Dispositivo não suportado', Colors.red);
      return;
    }

    final sucesso = await _bluetoothService.conectarDispositivo(device, dispositivoCompativel);
    
    if (sucesso) {
      _mostrarSnackBar('Conectado com sucesso!', Colors.green);
      Navigator.pop(context, dispositivoCompativel);
    } else {
      _mostrarSnackBar('Falha na conexão', Colors.red);
    }
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Penetrômetro'),
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
      body: Column(
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryColor.withOpacity(0.1),
            child: Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Dispositivos suportados
          if (_dispositivosSuportados.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Dispositivos Suportados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: _dispositivosSuportados.length,
                itemBuilder: (context, index) {
                  final dispositivo = _dispositivosSuportados[index];
                  return _buildDispositivoSuportadoCard(dispositivo);
                },
              ),
            ),
          ],

          // Dispositivos encontrados
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Dispositivos Encontrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _dispositivosEncontrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning 
                              ? 'Procurando dispositivos...'
                              : 'Toque no botão de scan para procurar dispositivos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _dispositivosEncontrados.length,
                    itemBuilder: (context, index) {
                      final device = _dispositivosEncontrados[index];
                      return _buildDispositivoEncontradoCard(device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispositivoSuportadoCard(PenetrometroDeviceModel dispositivo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            dispositivo.fabricante[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(dispositivo.nome),
        subtitle: Text('${dispositivo.fabricante} - ${dispositivo.modelo}'),
        trailing: Chip(
          label: Text(dispositivo.protocolo.nome),
          backgroundColor: AppColors.primaryColor.withOpacity(0.2),
        ),
        onTap: () {
          _mostrarDetalhesDispositivo(dispositivo);
        },
      ),
    );
  }

  Widget _buildDispositivoEncontradoCard(DiscoveredDevice device) {
    final isSupported = _dispositivosSuportados.any((supported) =>
        device.name.toLowerCase().contains(supported.nome.toLowerCase()) ||
        device.name.toLowerCase().contains(supported.fabricante.toLowerCase()));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSupported ? Colors.green : Colors.orange,
          child: Icon(
            isSupported ? Icons.check : Icons.help,
            color: Colors.white,
          ),
        ),
        title: Text(device.name.isNotEmpty ? device.name : 'Dispositivo Desconhecido'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.id}'),
            Text('RSSI: ${device.rssi} dBm'),
            if (isSupported)
              const Text(
                '✓ Suportado',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                '? Compatibilidade desconhecida',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _conectarDispositivo(device),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSupported ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Conectar'),
        ),
      ),
    );
  }

  void _mostrarDetalhesDispositivo(PenetrometroDeviceModel dispositivo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dispositivo.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fabricante: ${dispositivo.fabricante}'),
            Text('Modelo: ${dispositivo.modelo}'),
            Text('Protocolo: ${dispositivo.protocolo.nome}'),
            const SizedBox(height: 8),
            Text('Descrição: ${dispositivo.protocolo.descricao}'),
            const SizedBox(height: 8),
            const Text('Recursos:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (dispositivo.protocolo.suportaTemperatura)
              const Text('• Temperatura'),
            if (dispositivo.protocolo.suportaUmidade)
              const Text('• Umidade'),
            if (dispositivo.protocolo.suportaProfundidade)
              const Text('• Profundidade'),
            const SizedBox(height: 8),
            const Text('Configurações:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Unidade: ${dispositivo.configuracoes['unidade']}'),
            Text('• Precisão: ${dispositivo.configuracoes['precisao']}'),
            Text('• Range: ${dispositivo.configuracoes['range_min']}-${dispositivo.configuracoes['range_max']}'),
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
}
