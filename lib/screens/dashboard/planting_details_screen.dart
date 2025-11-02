import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planting_progress.dart';

class PlantingDetailsScreen extends StatelessWidget {
  final List<PlantingProgress> plantingProgresses;
  final String? selectedPlotId;

  const PlantingDetailsScreen({
    Key? key,
    required this.plantingProgresses,
    this.selectedPlotId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrar progresso com base no talhão selecionado, se houver
    final filteredProgresses = selectedPlotId != null
        ? plantingProgresses.where((p) => p.plotId == selectedPlotId).toList()
        : plantingProgresses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Plantio'),
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
                          Icon(Icons.grass, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Progresso de Plantio',
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
                      _buildProgressSummary(filteredProgresses),
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
                          Icon(Icons.calendar_today, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Detalhes do Plantio',
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
                        itemCount: filteredProgresses.length,
                        itemBuilder: (context, index) {
                          final progress = filteredProgresses[index];
                          return _buildPlantingItem(progress);
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
                        'Ver Previsão Climática', 
                        Icons.cloud, 
                        const Color(0xFF00BCD4),
                        () {
                          // Ver previsão climática
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Carregando previsão climática...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Gerar Relatório de Plantio', 
                        Icons.description, 
                        const Color(0xFF39B54A),
                        () {
                          // Gerar relatório
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gerando relatório...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Editar Dados do Plantio', 
                        Icons.edit, 
                        const Color(0xFFFFD400),
                        () {
                          // Editar dados
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Abrindo editor...')),
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

  Widget _buildProgressSummary(List<PlantingProgress> progresses) {
    double totalArea = 0;
    double plantedArea = 0;
    
    for (var progress in progresses) {
      totalArea += progress.totalArea;
      plantedArea += progress.plantedArea;
    }
    
    final percentage = totalArea > 0 ? (plantedArea / totalArea * 100) : 0.0;
    
    return Column(
      children: [
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF39B54A),
          ),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: percentage / 100,
          // backgroundColor: Colors.grey[200], // backgroundColor não é suportado em flutter_map 5.0.0
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39B54A)),
          minHeight: 10,
        ),
        const SizedBox(height: 16),
        Text(
          '${plantedArea.toStringAsFixed(1)} ha de ${totalArea.toStringAsFixed(1)} ha',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoBox('Talhões', '${progresses.length}', Icons.dashboard),
            _buildInfoBox('Área Média', '${(totalArea / (progresses.length > 0 ? progresses.length : 1)).toStringAsFixed(1)} ha', Icons.area_chart),
            _buildInfoBox('Dias de Plantio', '25', Icons.calendar_today),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF39B54A)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantingItem(PlantingProgress progress) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final plantingDate = DateTime.now().subtract(const Duration(days: 25));
    final formattedDate = dateFormat.format(plantingDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Talhão ${progress.plotId}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          _buildDetailRow('Data de Plantio', formattedDate),
          _buildDetailRow('Dias do Plantio', '+25 dias'),
          _buildDetailRow('Variedade', 'Soja BRS 1010'),
          _buildDetailRow('Densidade', '300 mil plantas/ha'),
          _buildDetailRow('Clima no Plantio', 'Ensolarado'),
          _buildDetailRow('Área Total', '${progress.totalArea.toStringAsFixed(1)} ha'),
          _buildDetailRow('Área Plantada', '${progress.plantedArea.toStringAsFixed(1)} ha'),
          _buildDetailRow('Progresso', '${(progress.plantedArea / progress.totalArea * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
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
