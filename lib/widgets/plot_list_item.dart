import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/map_global_adapter.dart';

import '../models/plot.dart';

/// Widget para exibir um item de talhão na lista
class PlotListItem extends StatelessWidget {
  final Plot plot;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const PlotListItem({
    Key? key,
    required this.plot,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Miniatura do polígono
              _buildPolygonThumbnail(),
              const SizedBox(width: 16),
              
              // Informações do talhão
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Área: ${plot.area?.toStringAsFixed(2) ?? '0.00'} hectares',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
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
                    onPressed: onEdit,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Constrói uma miniatura do polígono do talhão
  Widget _buildPolygonThumbnail() {
    // Extrair coordenadas do talhão
    List<LatLng> points = [];
    try {
      if (plot.coordinates?.isNotEmpty == true) {
        for (var coord in plot.coordinates!) {
          points.add(LatLng(
            coord['latitude'] ?? 0,
            coord['longitude'] ?? 0,
          ));
        }
      }
    } catch (e) {
      print('Erro ao extrair coordenadas: $e');
    }
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: PolygonPainter(points: points),
      ),
    );
  }
}

/// Painter para desenhar o polígono do talhão em miniatura
class PolygonPainter extends CustomPainter {
  final List<LatLng> points;
  
  PolygonPainter({required this.points});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) {
      // Desenhar um ícone de aviso se não houver pontos suficientes
      final paint = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 4,
        paint,
      );
      
      return;
    }
    
    // Normalizar coordenadas para o tamanho do container
    final normalizedPoints = _normalizePoints(points, size);
    
    // Configurar o paint para o polígono
    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.7)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;
    
    // Desenhar o polígono
    final path = Path();
    path.moveTo(normalizedPoints[0].dx, normalizedPoints[0].dy);
    
    for (int i = 1; i < normalizedPoints.length; i++) {
      path.lineTo(normalizedPoints[i].dx, normalizedPoints[i].dy);
    }
    
    path.close();
    canvas.drawPath(path, paint);
    
    // Desenhar borda
    final borderPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(path, borderPaint);
  }
  
  /// Normaliza as coordenadas geográficas para o tamanho do container
  List<Offset> _normalizePoints(List<LatLng> points, Size size) {
    if (points.isEmpty) return [];
    
    // Encontrar os limites do polígono
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;
    
    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    // Adicionar margem para evitar que o polígono fique muito próximo das bordas
    final padding = size.width * 0.1;
    final availableWidth = size.width - (padding * 2);
    final availableHeight = size.height - (padding * 2);
    
    // Calcular fatores de escala
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    // Evitar divisão por zero
    final latScale = latRange > 0 ? availableHeight / latRange : 1;
    final lngScale = lngRange > 0 ? availableWidth / lngRange : 1;
    
    // Usar o menor fator de escala para manter a proporção
    final scale = latScale < lngScale ? latScale : lngScale;
    
    // Normalizar pontos
    final List<Offset> normalizedPoints = [];
    
    for (var point in points) {
      // Inverter a latitude (y) porque as coordenadas do canvas aumentam para baixo
      final x = padding + ((point.longitude - minLng) * scale);
      final y = size.height - (padding + ((point.latitude - minLat) * scale));
      
      normalizedPoints.add(Offset(x, y));
    }
    
    return normalizedPoints;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
