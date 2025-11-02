import 'package:flutter/material.dart';
import '../routes.dart';

/// Exemplo de como usar o módulo de dados de máquinas agrícolas
class MachineDataUsageExample extends StatelessWidget {
  const MachineDataUsageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo - Dados de Máquinas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.agriculture,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Módulo de Dados de Máquinas Agrícolas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Importe e analise dados de Jacto NPK 5030, Stara, John Deere e outras marcas com mapas térmicos e filtros avançados',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _openMachineDataModule(context),
                icon: const Icon(Icons.agriculture),
                label: const Text('Abrir Módulo de Máquinas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Suporta: Jacto, Stara, John Deere, Case, New Holland, Massey Ferguson, Valtra, Fendt',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre o módulo de dados de máquinas
  void _openMachineDataModule(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.machineDataImport);
  }
}
