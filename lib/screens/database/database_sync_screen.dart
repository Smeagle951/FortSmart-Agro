import 'package:flutter/material.dart';

/// Tela de sincronização do banco de dados
class DatabaseSyncScreen extends StatefulWidget {
  const DatabaseSyncScreen({super.key});

  @override
  State<DatabaseSyncScreen> createState() => _DatabaseSyncScreenState();
}

class _DatabaseSyncScreenState extends State<DatabaseSyncScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização do Banco de Dados'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Funcionalidade de sincronização do banco de dados em desenvolvimento',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
