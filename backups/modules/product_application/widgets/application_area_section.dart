import 'package:flutter/material.dart';

class ApplicationAreaSection extends StatelessWidget {
  final String cropId;
  final String cropName;
  final String plotId;
  final String plotName;
  final double area;
  final List<Map<String, dynamic>> availablePlots;
  final List<Map<String, dynamic>> availableCrops;
  final Function(String, String) onCropSelected;
  final Function(String, String, double) onPlotSelected;
  
  const ApplicationAreaSection({
    Key? key,
    required this.cropId,
    required this.cropName,
    required this.plotId,
    required this.plotName,
    required this.area,
    required this.availablePlots,
    required this.availableCrops,
    required this.onCropSelected,
    required this.onPlotSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Área de Aplicação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Cultura
            InkWell(
              // onTap: () => _showCropSelectionDialog(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Cultura',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  cropName.isEmpty ? 'Selecione a cultura' : cropName,
                  style: TextStyle(
                    color: cropName.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Talhão
            InkWell(
              // onTap: () => _showPlotSelectionDialog(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Talhão',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  plotName.isEmpty ? 'Selecione o talhão' : plotName,
                  style: TextStyle(
                    color: plotName.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Área
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Área',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      area > 0 ? '${area.toStringAsFixed(2)} ha' : 'Selecione um talhão',
                      style: TextStyle(
                        color: area > 0 ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.landscape, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCropSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione a Cultura'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableCrops.isEmpty
              ? const Center(
                  child: Text('Nenhuma cultura disponível'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableCrops.length,
                  itemBuilder: (context, index) {
                    final crop = availableCrops[index];
                    return ListTile(
                      title: Text(crop['name']),
                      onTap: () {
                        onCropSelected(crop['id'], crop['name']);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  void _showPlotSelectionDialog(BuildContext context) {
    // Filtrar talhões pela cultura selecionada se necessário
    final filteredPlots = cropId.isEmpty
        ? availablePlots
        : availablePlots.where((plot) => plot['cropId'] == cropId).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione o Talhão'),
        content: SizedBox(
          width: double.maxFinite,
          child: filteredPlots.isEmpty
              ? const Center(
                  child: Text('Nenhum talhão disponível para esta cultura'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredPlots.length,
                  itemBuilder: (context, index) {
                    final plot = filteredPlots[index];
                    return ListTile(
                      title: Text(plot['name']),
                      subtitle: Text('${plot['area'].toStringAsFixed(2)} ha'),
                      onTap: () {
                        onPlotSelected(
                          plot['id'],
                          plot['name'],
                          plot['area'],
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
