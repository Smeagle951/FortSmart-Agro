import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Painter personalizado para desenhar heatmap de infestação
class HeatmapPainter extends CustomPainter {
  final List<LatLng> points;
  final List<double> intensities;
  final double radius;
  final MapController? mapController;

  HeatmapPainter({
    required this.points,
    required this.intensities,
    this.radius = 100.0,
    this.mapController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || intensities.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Desenhar cada ponto do heatmap
    for (int i = 0; i < points.length && i < intensities.length; i++) {
      final point = points[i];
      final intensity = intensities[i];
      
      // Converter coordenadas geográficas para pixels da tela
      final screenPoint = _latLngToScreenPoint(point, size);
      if (screenPoint == null) continue;

      // Cor baseada na intensidade
      final color = _getHeatmapColor(intensity);
      paint.color = color.withOpacity(intensity * 0.7);

      // Desenhar círculo com gradiente
      _drawHeatmapCircle(canvas, screenPoint, radius, paint, intensity);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  /// Converte coordenadas LatLng para pixels da tela
  Offset? _latLngToScreenPoint(LatLng latLng, Size size) {
    // Esta é uma implementação simplificada
    // Em produção, usar o MapController para conversão precisa
    
    // Coordenadas aproximadas para demonstração
    // Latitude: -90 a 90, Longitude: -180 a 180
    final x = ((latLng.longitude + 180) / 360) * size.width;
    final y = ((90 - latLng.latitude) / 180) * size.height;
    
    return Offset(x, y);
  }

  /// Obtém cor do heatmap baseada na intensidade
  Color _getHeatmapColor(double intensity) {
    if (intensity >= 0.8) {
      return Colors.red; // Crítico
    } else if (intensity >= 0.6) {
      return Colors.orange; // Alto
    } else if (intensity >= 0.4) {
      return Colors.yellow; // Moderado
    } else {
      return Colors.green; // Baixo
    }
  }

  /// Desenha círculo do heatmap com gradiente
  void _drawHeatmapCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    double intensity,
  ) {
    // Círculo principal
    canvas.drawCircle(center, radius, paint);
    
    // Círculo externo com transparência
    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = paint.color.withOpacity(intensity * 0.3);
    
    canvas.drawCircle(center, radius * 1.5, outerPaint);
    
    // Círculo interno mais intenso
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = paint.color.withOpacity(intensity * 0.9);
    
    canvas.drawCircle(center, radius * 0.7, innerPaint);
  }
}

/// Widget de heatmap otimizado para Flutter Map
class HeatmapLayer extends StatelessWidget {
  final List<LatLng> points;
  final List<double> intensities;
  final double radius;
  final MapController mapController;

  const HeatmapLayer({
    Key? key,
    required this.points,
    required this.intensities,
    this.radius = 100.0,
    required this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HeatmapPainter(
        points: points,
        intensities: intensities,
        radius: radius,
        mapController: mapController,
      ),
      size: Size.infinite,
    );
  }
}

/// Utilitário para gerar dados de heatmap
class HeatmapDataGenerator {
  /// Gera pontos de heatmap a partir de dados de infestação
  static List<LatLng> generateHeatmapPoints(
    List<Map<String, dynamic>> infestationData,
  ) {
    final points = <LatLng>[];
    
    for (final data in infestationData) {
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }
    
    return points;
  }

  /// Gera intensidades baseadas nos níveis de infestação
  static List<double> generateHeatmapIntensities(
    List<Map<String, dynamic>> infestationData,
  ) {
    final intensities = <double>[];
    
    for (final data in infestationData) {
      final level = data['level'] as String?;
      final intensity = _getLevelIntensity(level);
      intensities.add(intensity);
    }
    
    return intensities;
  }

  /// Obtém intensidade baseada no nível
  static double _getLevelIntensity(String? level) {
    switch (level?.toUpperCase()) {
      case 'CRITICO':
        return 1.0;
      case 'ALTO':
        return 0.8;
      case 'MODERADO':
        return 0.6;
      case 'BAIXO':
        return 0.4;
      default:
        return 0.2;
    }
  }

  /// Gera dados de heatmap interpolados para melhor visualização
  static List<Map<String, dynamic>> interpolateHeatmapData(
    List<LatLng> originalPoints,
    List<double> originalIntensities,
    int interpolationFactor,
  ) {
    final interpolatedData = <Map<String, dynamic>>[];
    
    for (int i = 0; i < originalPoints.length; i++) {
      final point = originalPoints[i];
      final intensity = originalIntensities[i];
      
      // Ponto original
      interpolatedData.add({
        'latitude': point.latitude,
        'longitude': point.longitude,
        'intensity': intensity,
      });
      
      // Pontos interpolados
      for (int j = 1; j < interpolationFactor; j++) {
        final factor = j / interpolationFactor;
        final interpolatedLat = point.latitude + (factor * 0.001); // Pequena variação
        final interpolatedLng = point.longitude + (factor * 0.001);
        final interpolatedIntensity = intensity * (1.0 - factor * 0.5);
        
        interpolatedData.add({
          'latitude': interpolatedLat,
          'longitude': interpolatedLng,
          'intensity': interpolatedIntensity,
        });
      }
    }
    
    return interpolatedData;
  }
}
