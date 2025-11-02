import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/plot.dart';

/// Widget que exibe uma miniatura do polígono de um talhão
class PlotThumbnail extends StatelessWidget {
  final Plot plot;
  final double size;
  final Color color;
  final Color borderColor;

  const PlotThumbnail({
    Key? key,
    required this.plot,
    this.size = 50,
    this.color = Colors.green,
    this.borderColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: plot.coordinates?.isNotEmpty == true
          ? CustomPaint(
              painter: PlotThumbnailPainter(
                plot.coordinates!,
                fillColor: color.withOpacity(0.3),
                borderColor: borderColor,
              ),
            )
          : const Center(
              child: Icon(
                Icons.landscape,
                color: Colors.grey,
              ),
            ),
    );
  }
}

/// Painter que desenha uma miniatura de um polígono de talhão
class PlotThumbnailPainter extends CustomPainter {
  final List<Map<String, dynamic>> coordinates;
  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  PlotThumbnailPainter(
    this.coordinates, {
    this.fillColor = Colors.green,
    this.borderColor = Colors.white,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.isEmpty) return;

    // Converter coordenadas para pontos normalizados
    final points = coordinates.map((coord) {
      return Point(
        coord['latitude'] as double? ?? 0.0,
        coord['longitude'] as double? ?? 0.0,
      );
    }).toList();

    // Calcular limites (bounds) do polígono
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in points) {
      minLat = minLat > point.x ? point.x : minLat;
      maxLat = maxLat < point.x ? point.x : maxLat;
      minLng = minLng > point.y ? point.y : minLng;
      maxLng = maxLng < point.y ? point.y : maxLng;
    }

    // Normalizar pontos para o tamanho do canvas
    final pathPoints = <Offset>[];
    for (var point in points) {
      final normalizedX = (point.x - minLat) / (maxLat - minLat);
      final normalizedY = (point.y - minLng) / (maxLng - minLng);
      
      // Inverter Y para corresponder à orientação do canvas
      pathPoints.add(Offset(
        normalizedX * size.width,
        (1 - normalizedY) * size.height,
      ));
    }

    // Criar caminho (path) para o polígono
    final path = ui.Path();
    if (pathPoints.isNotEmpty) {
      path.moveTo(pathPoints.first.dx, pathPoints.first.dy);
      for (var i = 1; i < pathPoints.length; i++) {
        path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
      }
      path.close();
    }

    // Desenhar polígono preenchido
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Desenhar borda do polígono
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Classe auxiliar para representar um ponto 2D
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}
