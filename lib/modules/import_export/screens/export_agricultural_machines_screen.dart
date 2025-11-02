import 'package:flutter/material.dart';

/// Tela de exportação de máquinas agrícolas
class ExportAgriculturalMachinesScreen extends StatefulWidget {
  const ExportAgriculturalMachinesScreen({super.key});

  @override
  State<ExportAgriculturalMachinesScreen> createState() => _ExportAgriculturalMachinesScreenState();
}

class _ExportAgriculturalMachinesScreenState extends State<ExportAgriculturalMachinesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Máquinas Agrícolas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Funcionalidade de exportação de máquinas agrícolas em desenvolvimento',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
