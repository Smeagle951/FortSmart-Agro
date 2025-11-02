import 'package:flutter/material.dart';
import '../main/monitoring_controller.dart';

/// Widget de status do monitoramento
/// Exibe informações sobre o estado atual e estatísticas
class MonitoringStatusWidget extends StatelessWidget {
  final MonitoringController controller;
  
  const MonitoringStatusWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatusGrid(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.blue[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Status do Monitoramento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildStatusCard(
          'Talhões',
          '${controller.availableTalhoes.length}',
          Icons.agriculture,
          Colors.green,
        ),
        _buildStatusCard(
          'Culturas',
          '${controller.availableCulturas.length}',
          Icons.grass,
          Colors.blue,
        ),
        _buildStatusCard(
          'Selecionado',
          controller.selectedTalhao?.nome ?? 'Nenhum',
          Icons.location_on,
          Colors.orange,
        ),
        _buildStatusCard(
          'Localização',
          controller.currentPosition != null ? 'Ativa' : 'Inativa',
          Icons.my_location,
          controller.currentPosition != null ? Colors.green : Colors.red,
        ),
      ],
    );
  }
  
  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
