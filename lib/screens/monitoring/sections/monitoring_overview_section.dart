import 'package:flutter/material.dart';
import '../main/monitoring_controller.dart';

/// Seção de visão geral do monitoramento
/// Exibe resumo dos dados e estatísticas principais
class MonitoringOverviewSection extends StatelessWidget {
  final MonitoringController controller;
  
  const MonitoringOverviewSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildOverviewCards(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(
          Icons.dashboard,
          color: Colors.indigo[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Visão Geral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewCards() {
    return Column(
      children: [
        // Resumo dos talhões
        _buildTalhoesOverview(),
        
        const SizedBox(height: 16),
        
        // Resumo das culturas
        _buildCulturasOverview(),
        
        const SizedBox(height: 16),
        
        // Estatísticas de monitoramento
        _buildMonitoringStats(),
      ],
    );
  }
  
  Widget _buildTalhoesOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumo dos Talhões',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    '${controller.availableTalhoes.length}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Selecionado',
                    controller.selectedTalhao?.nome ?? 'Nenhum',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Área Total',
                    _calculateTotalArea(),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCulturasOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumo das Culturas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    '${controller.availableCulturas.length}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Selecionada',
                    controller.selectedCultura?.nome ?? 'Nenhuma',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ativas',
                    '${controller.availableCulturas.length}',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonitoringStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas de Monitoramento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Localização',
                    controller.currentPosition != null ? 'Ativa' : 'Inativa',
                    controller.currentPosition != null ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Modo',
                    controller.state.modoSatelite ? 'Satélite' : 'Terreno',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Status',
                    controller.isLoading ? 'Carregando' : 'Pronto',
                    controller.isLoading ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
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
    );
  }
  
  String _calculateTotalArea() {
    double totalArea = 0;
    for (final talhao in controller.availableTalhoes) {
      if (talhao.area != null) {
        totalArea += talhao.area!;
      }
    }
    return '${totalArea.toStringAsFixed(2)} ha';
  }
}
