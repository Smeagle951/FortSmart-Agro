import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget para exibir marcadores de pontos de monitoramento com design melhorado
class EnhancedMonitoringMarker extends StatelessWidget {
  final LatLng position;
  final String label;
  final bool isCurrentPoint;
  final bool isCompleted;
  final VoidCallback? onTap;

  const EnhancedMonitoringMarker({
    Key? key,
    required this.position,
    required this.label,
    this.isCurrentPoint = false,
    this.isCompleted = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final marker = Marker(
      width: 60.0,
      height: 60.0,
      point: position,
      builder: (context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Sombra
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                // Marcador principal
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getMarkerColor(),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                // Indicador de ponto atual
                if (isCurrentPoint)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.fastOutSlowIn,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
            // Rótulo abaixo do marcador
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Ponto $label',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getMarkerColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return marker;
  }

  Color _getMarkerColor() {
    if (isCurrentPoint) return Colors.blue;
    if (isCompleted) return Colors.green;
    return Colors.red;
  }
}

/// Widget para exibir a rota entre pontos de monitoramento com design melhorado
class EnhancedMonitoringRoute extends StatelessWidget {
  final List<LatLng> points;
  final List<LatLng> routeToCurrentPoint;
  final LatLng? currentPosition;

  const EnhancedMonitoringRoute({
    Key? key,
    required this.points,
    this.routeToCurrentPoint = const [],
    this.currentPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Polyline> polylines = [];

    // Adiciona a linha principal conectando todos os pontos
    if (points.length > 1) {
      polylines.add(
        Polyline(
          points: points,
          strokeWidth: 4.0,
          color: Colors.purple.withOpacity(0.7),
          borderStrokeWidth: 1.0,
          borderColor: Colors.white,
        ),
      );
    }

    // Adiciona a linha de navegação da posição atual até o próximo ponto
    if (currentPosition != null && routeToCurrentPoint.isNotEmpty) {
      final List<LatLng> navigationRoute = [
        currentPosition!,
        ...routeToCurrentPoint,
      ];

      polylines.add(
        Polyline(
          points: navigationRoute,
          strokeWidth: 4.0,
          color: Colors.blue,
          isDotted: true,
          borderStrokeWidth: 1.0,
          borderColor: Colors.white,
        ),
      );
    }

    return PolylineLayer(
      polylines: polylines,
    );
  }
}

/// Widget para exibir a área do talhão com design melhorado
class EnhancedPlotPolygon extends StatelessWidget {
  final List<LatLng> points;
  final Color color;
  final String label;

  const EnhancedPlotPolygon({
    Key? key,
    required this.points,
    this.color = Colors.green,
    this.label = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    // Calcula o centro do polígono para posicionar o rótulo
    double latSum = 0;
    double lngSum = 0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    final center = LatLng(latSum / points.length, lngSum / points.length);

    return Stack(
      children: [
        // Polígono do talhão
        PolygonLayer(
          polygons: [
            Polygon(
              points: points,
              color: color.withOpacity(0.2),
              borderColor: color.withOpacity(0.7),
              borderStrokeWidth: 2.0,
              isFilled: true,
            ),
          ],
        ),
        
        // Rótulo do talhão (opcional)
        if (label.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                width: 100.0,
                height: 40.0,
                point: center,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Widget para exibir a localização atual do usuário com design melhorado
class EnhancedCurrentLocationMarker extends StatelessWidget {
  final LatLng position;
  final double accuracy;
  final double heading;

  const EnhancedCurrentLocationMarker({
    Key? key,
    required this.position,
    this.accuracy = 10.0,
    this.heading = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        // Círculo de precisão
        Marker(
          width: accuracy * 2,
          height: accuracy * 2,
          point: position,
          builder: (context) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.15),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
        
        // Marcador de posição atual
        Marker(
          width: 40.0,
          height: 40.0,
          point: position,
          builder: (context) => Transform.rotate(
            angle: heading * (3.14159265359 / 180), // Converte graus para radianos
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo externo pulsante
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 24 + (value * 8),
                      height: 24 + (value * 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3 * (1 - value)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                
                // Círculo principal
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                
                // Indicador de direção
                if (heading != 0)
                  const Positioned(
                    top: 0,
                    child: ClipPath(
                      clipper: TriangleClipper(),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Clipper para criar um triângulo para o indicador de direção
class TriangleClipper extends CustomClipper<Path> {
  const TriangleClipper();
  
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TriangleClipper oldClipper) => false;
}
