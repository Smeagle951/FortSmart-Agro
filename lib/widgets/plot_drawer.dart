import 'package:flutter/material.dart';

import '../models/plot.dart';
import '../models/property.dart';
import 'plot_list_item.dart';

/// Widget para o menu lateral que exibe a lista de talhões
class PlotDrawer extends StatelessWidget {
  final Property property;
  final List<Plot> plots;
  final Function(Plot) onPlotTap;
  final Function(Plot) onEditPlot;
  final Function(Plot) onDeletePlot;
  final VoidCallback onAddPlot;
  final VoidCallback onImportKml;
  
  const PlotDrawer({
    Key? key,
    required this.property,
    required this.plots,
    required this.onPlotTap,
    required this.onEditPlot,
    required this.onDeletePlot,
    required this.onAddPlot,
    required this.onImportKml,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Cabeçalho do drawer
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 16),
            color: const Color(0xFF4CAF50),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    property.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (property.area != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Área total: ${property.area!.toStringAsFixed(2)} hectares',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Botões de ação
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onAddPlot,
                        icon: const Icon(Icons.add),
                        label: const Text('Novo Talhão'),
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onImportKml,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Importar KML'),
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Título da lista
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.map, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text(
                  'Talhões (${plots.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de talhões
          Expanded(
            child: plots.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: plots.length,
                    itemBuilder: (context, index) {
                      final plot = plots[index];
                      return PlotListItem(
                        plot: plot,
                        onTap: () => onPlotTap(plot),
                        onEdit: () => onEditPlot(plot),
                        onDelete: () => onDeletePlot(plot),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói o estado vazio quando não há talhões
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum talhão cadastrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione um novo talhão ou importe um arquivo KML',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddPlot,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Talhão'),
            style: ElevatedButton.styleFrom(
              // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
