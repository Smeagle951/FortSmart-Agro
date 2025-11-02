import 'package:flutter/material.dart';
import '../models/plot.dart';
import '../routes.dart';

class PlotsSidebar extends StatelessWidget {
  final List<Plot> plots;
  final Function(Plot) onPlotSelected;
  final Function(Plot) onPlotDelete;
  final Function(Plot) onPlotEdit;
  final String farmName;
  final AnimationController animationController;

  const PlotsSidebar({
    Key? key,
    required this.plots,
    required this.onPlotSelected,
    required this.onPlotDelete,
    required this.onPlotEdit,
    required this.farmName,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 300 * animationController.value,
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF4CAF50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Talhões',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                animationController.reverse();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          farmName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plots.length} talhões',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de talhões
                  if (plots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Nenhum talhão cadastrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plots.length,
                      itemBuilder: (context, index) {
                        final plot = plots[index];
                        return _buildPlotItem(context, plot);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlotItem(BuildContext context, Plot plot) {
    // Converter coordenadas para pontos para desenhar miniatura
    List<Offset> points = [];
    if (plot.coordinates?.isNotEmpty == true) {
      // Encontrar limites para normalização
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      for (var coord in plot.coordinates!) {
        final lat = coord['latitude'] ?? 0.0;
        final lng = coord['longitude'] ?? 0.0;
        
        minLat = lat < minLat ? lat : minLat;
        maxLat = lat > maxLat ? lat : maxLat;
        minLng = lng < minLng ? lng : minLng;
        maxLng = lng > maxLng ? lng : maxLng;
      }
      
      // Normalizar pontos para o tamanho da miniatura
      for (var coord in plot.coordinates!) {
        final lat = coord['latitude'] ?? 0.0;
        final lng = coord['longitude'] ?? 0.0;
        
        // Inverter latitude (y) porque o eixo Y da tela cresce para baixo
        final normalizedX = (lng - minLng) / (maxLng - minLng);
        final normalizedY = 1.0 - (lat - minLat) / (maxLat - minLat);
        
        points.add(Offset(normalizedX, normalizedY));
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => onPlotSelected(plot),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura do polígono
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: points.isNotEmpty
                    ? CustomPaint(
                        painter: PolygonThumbnailPainter(points),
                      )
                    : const Icon(
                        Icons.crop_square,
                        color: Colors.grey,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Informações do talhão
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plot.area?.toStringAsFixed(2) ?? "0.00"} ha',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    if (plot.cropName != null && plot.cropName!.isNotEmpty)
                      Text(
                        'Cultura: ${plot.cropName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Botões de ação
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => onPlotEdit(plot),
                    tooltip: 'Editar',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onPlotDelete(plot),
                    tooltip: 'Excluir',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter para desenhar miniaturas de polígonos
class PolygonThumbnailPainter extends CustomPainter {
  final List<Offset> points;

  PolygonThumbnailPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final path = Path();
    
    if (points.isNotEmpty) {
      // Escalar pontos para o tamanho do canvas
      final scaledPoints = points.map((point) {
        return Offset(
          point.dx * size.width,
          point.dy * size.height,
        );
      }).toList();
      
      path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
      
      for (int i = 1; i < scaledPoints.length; i++) {
        path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
      }
      
      path.close();
      
      canvas.drawPath(path, paint);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
