import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/agricultural_machine_data_processor.dart';

/// Classe para representar bounds geográficos
class GeoBounds {
  final double north;
  final double south;
  final double east;
  final double west;
  
  const GeoBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

/// CustomPainter para renderizar mapa térmico de dados de máquinas agrícolas
class ThermalMapPainter extends CustomPainter {
  final MachineWorkData machineData;
  final double zoom;
  final Offset panOffset;
  final Size canvasSize;
  final bool showGrid;
  final bool showCompass;
  final String selectedMetric; // 'rate', 'speed', 'volume'

  ThermalMapPainter({
    required this.machineData,
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.canvasSize = const Size(400, 400),
    this.showGrid = true,
    this.showCompass = true,
    this.selectedMetric = 'rate',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Fundo branco
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    if (machineData.points.isEmpty) {
      _drawNoDataMessage(canvas, size);
      return;
    }
    
    // Calcular bounds dos dados
    final bounds = _calculateBounds();
    final center = _calculateCenter(bounds);
    
    // Aplicar transformações (zoom e pan)
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoom);
    
    // Desenhar grid se habilitado
    if (showGrid) {
      _drawGrid(canvas, size, bounds);
    }
    
    // Desenhar polígonos térmicos
    _drawThermalPolygons(canvas, size, bounds);
    
    // Desenhar contornos dos talhões
    _drawFieldBoundaries(canvas, size, bounds);
    
    // Desenhar pontos de dados
    _drawDataPoints(canvas, size, bounds);
    
    canvas.restore();
    
    // Desenhar compass se habilitado
    if (showCompass) {
      _drawCompass(canvas, size);
    }
    
    // Desenhar coordenadas dos cantos
    _drawCornerCoordinates(canvas, size, bounds);
  }
  
  /// Desenha mensagem quando não há dados
  void _drawNoDataMessage(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey;
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Nenhum dado disponível',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }
  
  /// Calcula bounds dos dados
  GeoBounds _calculateBounds() {
    if (machineData.points.isEmpty) {
      return const GeoBounds(
        north: -15.7791,
        south: -15.7801,
        east: -47.9282,
        west: -47.9292,
      );
    }
    
    double minLat = machineData.points.first.latitude;
    double maxLat = machineData.points.first.latitude;
    double minLng = machineData.points.first.longitude;
    double maxLng = machineData.points.first.longitude;
    
    for (final point in machineData.points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    // Adicionar margem
    final latMargin = (maxLat - minLat) * 0.1;
    final lngMargin = (maxLng - minLng) * 0.1;
    
    return GeoBounds(
      north: maxLat + latMargin,
      south: minLat - latMargin,
      east: maxLng + lngMargin,
      west: minLng - lngMargin,
    );
  }
  
  /// Calcula centro dos bounds
  LatLng _calculateCenter(GeoBounds bounds) {
    return LatLng(
      (bounds.south + bounds.north) / 2,
      (bounds.west + bounds.east) / 2,
    );
  }
  
  /// Converte coordenada geográfica para pixel
  Offset _latLngToPixel(LatLng latLng, GeoBounds bounds, Size size) {
    final x = ((latLng.longitude - bounds.west) / (bounds.east - bounds.west)) * size.width;
    final y = ((bounds.north - latLng.latitude) / (bounds.north - bounds.south)) * size.height;
    return Offset(x, y);
  }
  
  /// Desenha grid
  void _drawGrid(Canvas canvas, Size size, GeoBounds bounds) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Linhas verticais
    for (int i = 1; i < 10; i++) {
      final lng = bounds.west + (bounds.east - bounds.west) * (i / 10);
      final start = _latLngToPixel(LatLng(bounds.north, lng), bounds, size);
      final end = _latLngToPixel(LatLng(bounds.south, lng), bounds, size);
      canvas.drawLine(start, end, paint);
    }
    
    // Linhas horizontais
    for (int i = 1; i < 10; i++) {
      final lat = bounds.south + (bounds.north - bounds.south) * (i / 10);
      final start = _latLngToPixel(LatLng(lat, bounds.west), bounds, size);
      final end = _latLngToPixel(LatLng(lat, bounds.east), bounds, size);
      canvas.drawLine(start, end, paint);
    }
  }
  
  /// Desenha polígonos térmicos
  void _drawThermalPolygons(Canvas canvas, Size size, GeoBounds bounds) {
    if (machineData.points.length < 3) return;
    
    // Criar triangulação dos pontos para preenchimento térmico
    final triangles = _createTriangulation();
    
    for (final triangle in triangles) {
      final color = _getColorForValue(_getValueForTriangle(triangle));
      final paint = Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      final path = ui.Path();
      final p1 = _latLngToPixel(triangle.p1, bounds, size);
      final p2 = _latLngToPixel(triangle.p2, bounds, size);
      final p3 = _latLngToPixel(triangle.p3, bounds, size);
      
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }
  
  /// Desenha contornos dos talhões
  void _drawFieldBoundaries(Canvas canvas, Size size, GeoBounds bounds) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Desenhar contorno geral da área de trabalho
    if (machineData.points.length >= 3) {
      final path = ui.Path();
      final hull = _calculateConvexHull();
      
      if (hull.isNotEmpty) {
        final firstPoint = _latLngToPixel(hull.first, bounds, size);
        path.moveTo(firstPoint.dx, firstPoint.dy);
        
        for (int i = 1; i < hull.length; i++) {
          final point = _latLngToPixel(hull[i], bounds, size);
          path.lineTo(point.dx, point.dy);
        }
        path.close();
        
        canvas.drawPath(path, paint);
      }
    }
  }
  
  /// Desenha pontos de dados
  void _drawDataPoints(Canvas canvas, Size size, GeoBounds bounds) {
    for (final point in machineData.points) {
      final pixel = _latLngToPixel(
        LatLng(point.latitude, point.longitude),
        bounds,
        size,
      );
      
      final color = _getColorForValue(_getValueForPoint(point));
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(pixel, 3.0, paint);
      
      // Contorno branco
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawCircle(pixel, 3.0, borderPaint);
    }
  }
  
  /// Desenha compass
  void _drawCompass(Canvas canvas, Size size) {
    final center = Offset(size.width - 60, 60);
    final radius = 25.0;
    
    // Círculo do compass
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, paint);
    
    // Borda
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, borderPaint);
    
    // Seta Norte
    final northPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;
    
    final northEnd = Offset(center.dx, center.dy - radius + 5);
    canvas.drawLine(center, northEnd, northPaint);
    
    // Texto "N"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(northEnd.dx - textPainter.width / 2, northEnd.dy - 15),
    );
  }
  
  /// Desenha coordenadas dos cantos
  void _drawCornerCoordinates(Canvas canvas, Size size, GeoBounds bounds) {
    final textStyle = const TextStyle(
      color: Colors.black,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    
    // Canto superior esquerdo
    _drawCoordinateText(
      canvas,
      '${bounds.north.toStringAsFixed(6)}, ${bounds.west.toStringAsFixed(6)}',
      Offset(10, 10),
      textStyle,
    );
    
    // Canto inferior direito
    _drawCoordinateText(
      canvas,
      '${bounds.south.toStringAsFixed(6)}, ${bounds.east.toStringAsFixed(6)}',
      Offset(size.width - 150, size.height - 20),
      textStyle,
    );
  }
  
  /// Desenha texto de coordenada
  void _drawCoordinateText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
  
  /// Cria triangulação dos pontos
  List<Triangle> _createTriangulation() {
    // Implementação simplificada de triangulação
    // Em produção, usar biblioteca como delaunay_triangulation
    final triangles = <Triangle>[];
    
    if (machineData.points.length < 3) return triangles;
    
    // Triangulação simples baseada em pontos adjacentes
    for (int i = 0; i < machineData.points.length - 2; i++) {
      final p1 = LatLng(machineData.points[i].latitude, machineData.points[i].longitude);
      final p2 = LatLng(machineData.points[i + 1].latitude, machineData.points[i + 1].longitude);
      final p3 = LatLng(machineData.points[i + 2].latitude, machineData.points[i + 2].longitude);
      
      triangles.add(Triangle(p1, p2, p3));
    }
    
    return triangles;
  }
  
  /// Calcula convex hull dos pontos
  List<LatLng> _calculateConvexHull() {
    if (machineData.points.length < 3) return [];
    
    // Implementação simplificada do algoritmo de Graham
    final points = machineData.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    
    // Encontrar ponto mais baixo (menor latitude)
    points.sort((a, b) => a.latitude.compareTo(b.latitude));
    final bottomPoint = points.first;
    
    // Ordenar por ângulo polar
    points.sort((a, b) {
      final angleA = _polarAngle(bottomPoint, a);
      final angleB = _polarAngle(bottomPoint, b);
      return angleA.compareTo(angleB);
    });
    
    // Construir convex hull
    final hull = <LatLng>[];
    for (final point in points) {
      while (hull.length > 1 && _crossProduct(hull[hull.length - 2], hull.last, point) <= 0) {
        hull.removeLast();
      }
      hull.add(point);
    }
    
    return hull;
  }
  
  /// Calcula ângulo polar
  double _polarAngle(LatLng center, LatLng point) {
    return math.atan2(point.longitude - center.longitude, point.latitude - center.latitude);
  }
  
  /// Calcula produto vetorial
  double _crossProduct(LatLng O, LatLng A, LatLng B) {
    return (A.longitude - O.longitude) * (B.latitude - O.latitude) - 
           (A.latitude - O.latitude) * (B.longitude - O.longitude);
  }
  
  /// Obtém valor para ponto baseado na métrica selecionada
  double _getValueForPoint(WorkPoint point) {
    switch (selectedMetric) {
      case 'rate':
        return point.applicationRate;
      case 'speed':
        return point.speed;
      case 'volume':
        return point.volume;
      default:
        return point.applicationRate;
    }
  }
  
  /// Obtém valor para triângulo (média dos vértices)
  double _getValueForTriangle(Triangle triangle) {
    // Encontrar pontos correspondentes
    final p1 = machineData.points.firstWhere(
      (p) => p.latitude == triangle.p1.latitude && p.longitude == triangle.p1.longitude,
      orElse: () => machineData.points.first,
    );
    final p2 = machineData.points.firstWhere(
      (p) => p.latitude == triangle.p2.latitude && p.longitude == triangle.p2.longitude,
      orElse: () => machineData.points.first,
    );
    final p3 = machineData.points.firstWhere(
      (p) => p.latitude == triangle.p3.latitude && p.longitude == triangle.p3.longitude,
      orElse: () => machineData.points.first,
    );
    
    return (_getValueForPoint(p1) + _getValueForPoint(p2) + _getValueForPoint(p3)) / 3;
  }
  
  /// Obtém cor baseada no valor
  Color _getColorForValue(double value) {
    // Encontrar faixa correspondente
    for (final range in machineData.valueRanges) {
      if (value >= range.minValue && value <= range.maxValue) {
        return range.color;
      }
    }
    
    // Fallback para primeira ou última faixa
    if (value < machineData.valueRanges.first.minValue) {
      return machineData.valueRanges.first.color;
    } else {
      return machineData.valueRanges.last.color;
    }
  }
  
  @override
  bool shouldRepaint(ThermalMapPainter oldDelegate) {
    return oldDelegate.machineData != machineData ||
           oldDelegate.zoom != zoom ||
           oldDelegate.panOffset != panOffset ||
           oldDelegate.selectedMetric != selectedMetric ||
           oldDelegate.showGrid != showGrid ||
           oldDelegate.showCompass != showCompass;
  }
}

/// Classe para representar triângulo
class Triangle {
  final LatLng p1;
  final LatLng p2;
  final LatLng p3;
  
  Triangle(this.p1, this.p2, this.p3);
}
