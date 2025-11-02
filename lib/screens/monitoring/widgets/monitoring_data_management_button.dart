import 'package:flutter/material.dart';
import '../monitoring_data_selection_screen.dart';

/// Widget para botão de gestão de dados de monitoramento
class MonitoringDataManagementButton extends StatelessWidget {
  const MonitoringDataManagementButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _navigateToDataSelection(context),
        icon: const Icon(Icons.analytics, size: 20),
        label: const Text('Gestão de Dados'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D9CDB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _navigateToDataSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MonitoringDataSelectionScreen(),
      ),
    );
  }
}
