import 'package:flutter/material.dart';
import '../../models/plot_status.dart';

class PlotStatusDetailScreen extends StatelessWidget {
  final List<PlotStatus> plotStatuses;
  final String? selectedPlotId;

  const PlotStatusDetailScreen({
    Key? key,
    required this.plotStatuses,
    this.selectedPlotId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrar status com base no talhão selecionado, se houver
    final filteredStatuses = selectedPlotId != null
        ? plotStatuses.where((s) => s.plotId == selectedPlotId).toList()
        : plotStatuses;

    // Contar status dos talhões
    int healthyCount = 0;
    int warningCount = 0;
    int criticalCount = 0;
    
    for (var status in filteredStatuses) {
      switch (status.status?.toLowerCase()) {
        case 'critical':
          criticalCount++;
          break;
        case 'warning':
          warningCount++;
          break;
        default:
          healthyCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status dos Talhões'),
        // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // backgroundColor: const Color(0xFFF4F6F8), // backgroundColor não é suportado em flutter_map 5.0.0
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Visão Geral dos Talhões',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusIndicator('Saudável', healthyCount, Colors.green),
                          _buildStatusIndicator('Atenção', warningCount, Colors.orange),
                          _buildStatusIndicator('Crítico', criticalCount, Colors.red),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              flex: healthyCount,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: warningCount,
                              child: Container(
                                color: Colors.orange,
                              ),
                            ),
                            Expanded(
                              flex: criticalCount,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Lista de Talhões',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredStatuses.length,
                        itemBuilder: (context, index) {
                          final status = filteredStatuses[index];
                          return _buildPlotStatusItem(status);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.map, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Ações Rápidas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        context, 
                        'Ver no Mapa', 
                        Icons.map, 
                        const Color(0xFF007AFF),
                        () {
                          // Navegar para o mapa
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navegando para o mapa...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Novo Ponto de Monitoramento', 
                        Icons.add_location_alt, 
                        const Color(0xFF39B54A),
                        () {
                          // Adicionar ponto de monitoramento
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Adicionando novo ponto de monitoramento...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Gerar Relatório', 
                        Icons.description, 
                        const Color(0xFFFFD400),
                        () {
                          // Gerar relatório
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gerando relatório...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPlotStatusItem(PlotStatus status) {
    // Definir cor com base no status
    Color statusColor;
    String statusText;
    
    switch (status.status?.toLowerCase()) {
      case 'critical':
        statusColor = Colors.red;
        statusText = 'Crítico';
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusText = 'Atenção';
        break;
      default:
        statusColor = Colors.green;
        statusText = 'Saudável';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          'Talhão ${status.plotId}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Cultura: ${status.cropType ?? 'Não definida'}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        // onTap: () {
          // Navegar para detalhes do talhão
        }, // onTap não é suportado em Polygon no flutter_map 5.0.0
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, 
    String label, 
    IconData icon, 
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          // backgroundColor: color, // backgroundColor não é suportado em flutter_map 5.0.0
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
