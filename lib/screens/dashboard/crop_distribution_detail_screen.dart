import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/plot_status.dart';

class CropDistributionDetailScreen extends StatelessWidget {
  final List<PlotStatus> plotStatuses;
  final String? selectedPlotId;

  const CropDistributionDetailScreen({
    Key? key,
    required this.plotStatuses,
    this.selectedPlotId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupar por tipo de cultura
    final Map<String, int> cropDistribution = {};
    for (var status in plotStatuses) {
      if (selectedPlotId != null && status.plotId != selectedPlotId) continue;
      
      final cropType = status.cropType ?? 'Sem cultura';
      if (cropDistribution.containsKey(cropType)) {
        cropDistribution[cropType] = cropDistribution[cropType]! + 1;
      } else {
        cropDistribution[cropType] = 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribuição de Culturas'),
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
                          Icon(Icons.pie_chart, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Visão Geral das Culturas',
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
                        itemCount: cropDistribution.length,
                        itemBuilder: (context, index) {
                          final entry = cropDistribution.entries.elementAt(index);
                          final cropType = entry.key;
                          final count = entry.value;
                          final total = plotStatuses.length;
                          final percentage = (count / total * 100).toStringAsFixed(1);
                          
                          return _buildCropItem(cropType, count, percentage);
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
                        'Gerar Relatório', 
                        Icons.description, 
                        const Color(0xFF39B54A),
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

  Widget _buildCropItem(String cropType, int count, String percentage) {
    // Definir cor com base no tipo de cultura
    Color color;
    switch (cropType.toLowerCase()) {
      case 'soja':
        color = const Color(0xFF00FF66);
        break;
      case 'algodão':
        color = const Color(0xFF9C27B0);
        break;
      case 'milho':
        color = const Color(0xFF00BCD4);
        break;
      case 'café':
        color = const Color(0xFF795548);
        break;
      case 'cana':
      case 'cana-de-açúcar':
        color = const Color(0xFFFFEB3B);
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cropType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count talhões ($percentage%)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
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
