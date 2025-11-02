import 'package:flutter/material.dart';
import '../main/monitoring_controller.dart';

/// Seção de ações do monitoramento
/// Exibe botões e controles para executar ações
class MonitoringActionsSection extends StatelessWidget {
  final MonitoringController controller;
  
  const MonitoringActionsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildActionsGrid(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(
          Icons.play_circle_outline,
          color: Colors.red[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Ações de Monitoramento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          'Novo Monitoramento',
          'Iniciar nova sessão de monitoramento',
          Icons.add_circle,
          Colors.blue,
          () => controller.startNewMonitoring(),
        ),
        _buildActionCard(
          'Localização Atual',
          'Ir para posição atual',
          Icons.my_location,
          Colors.green,
          () => controller.goToCurrentLocation(),
        ),
        _buildActionCard(
          'Histórico',
          'Ver histórico de monitoramentos',
          Icons.history,
          Colors.orange,
          () => controller.openHistory(),
        ),
        _buildActionCard(
          'Configurações',
          'Abrir configurações',
          Icons.settings,
          Colors.purple,
          () => controller.openSettings(),
        ),
        _buildActionCard(
          'Limpar Dados',
          'Limpar dados temporários',
          Icons.delete_sweep,
          Colors.red,
          () => controller.clearData(),
        ),
        _buildActionCard(
          'Atualizar',
          'Atualizar dados',
          Icons.refresh,
          Colors.teal,
          () => controller.refreshData(),
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
