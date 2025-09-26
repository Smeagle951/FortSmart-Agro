import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/cultura_provider.dart';
import '../../../providers/talhao_provider.dart';
import '../../../utils/api_config.dart';

/// Widget personalizado para o mapa principal da tela de talhões
class TalhaoMapWidget extends StatelessWidget {
  final MapController? mapController;
  final LatLng? userLocation;
  final LatLng defaultCenter;
  final double defaultZoom;
  final bool isDrawing;
  final List<LatLng> currentPoints;
  final Color? selectedCulturaColor;
  final Function(LatLng) onTap;
  final VoidCallback? onMapReady;
  final Function(MapPosition, bool)? onPositionChanged;
  final Function(dynamic)? onTalhaoTap;

  const TalhaoMapWidget({
    Key? key,
    required this.mapController,
    required this.userLocation,
    required this.defaultCenter,
    required this.defaultZoom,
    required this.isDrawing,
    required this.currentPoints,
    required this.selectedCulturaColor,
    required this.onTap,
    this.onMapReady,
    this.onPositionChanged,
    this.onTalhaoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final talhaoProvider = Provider.of<TalhaoProvider>(context);
    final culturaProvider = Provider.of<CulturaProvider>(context);

    return FlutterMap(
      mapController: mapController ?? MapController(),
      options: MapOptions(
        zoom: defaultZoom,
        center: userLocation ?? defaultCenter,
        interactiveFlags: InteractiveFlag.all,
        onTap: (tapPosition, point) {
          if (isDrawing) {
            onTap(point);
          }
        },
        onMapReady: onMapReady,
        onPositionChanged: onPositionChanged,
      ),
      children: [
        // Camada de mapa base - SEMPRE em modo satélite usando APIConfig
        TileLayer(
          urlTemplate: APIConfig.getMapTilerUrl('satellite'),
          userAgentPackageName: 'com.fortsmart.agro',
          maxZoom: 18,
          minZoom: 3,
          fallbackUrl: APIConfig.getFallbackUrl(),
          backgroundColor: Colors.black,
        ),
        
        // Camada de polígonos dos talhões existentes
        Builder(
          builder: (context) {
            final polygons = _buildTalhaoPolygons(talhaoProvider.talhoes, culturaProvider);
            return PolygonLayer(
              polygons: polygons,
            );
          },
        ),
        
        // Camada de marcadores dos talhões existentes
        Builder(
          builder: (context) {
            final markers = _buildTalhaoMarkers(talhaoProvider.talhoes, culturaProvider);
            return MarkerLayer(
              markers: markers,
            );
          },
        ),
        
        // Polígono atual sendo desenhado
        if (currentPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: currentPoints,
                color: (selectedCulturaColor ?? Colors.blue).withOpacity(0.3),
                borderColor: selectedCulturaColor ?? Colors.blue,
                borderStrokeWidth: 3.0,
              ),
            ],
          ),
        
        // Linha atual sendo desenhada
        if (currentPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: currentPoints,
                color: selectedCulturaColor ?? Colors.blue,
                strokeWidth: 3.0,
              ),
            ],
          ),
        
        // Marcadores dos pontos atuais
        if (currentPoints.isNotEmpty)
          MarkerLayer(
            markers: currentPoints.map((point) => Marker(
              point: point,
              width: 12,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: selectedCulturaColor ?? Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            )).toList(),
          ),
        
        // Localização do usuário
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Constrói polígonos dos talhões existentes
  List<Polygon> _buildTalhaoPolygons(List<dynamic> talhoes, CulturaProvider culturaProvider) {
    final List<Polygon> polygons = [];
    
    for (final talhao in talhoes) {
      try {
        // Verificar se o talhão tem polígonos
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          for (final poligono in talhao.poligonos) {
            if (poligono.pontos != null && poligono.pontos.length >= 3) {
              // Obter cor da cultura
              Color polygonColor = Colors.blue;
              if (talhao.safras != null && talhao.safras.isNotEmpty) {
                final safra = talhao.safras.first;
                if (safra.culturaCor != null) {
                  polygonColor = safra.culturaCor;
                }
              }
              
              polygons.add(Polygon(
                points: poligono.pontos,
                color: polygonColor.withOpacity(0.3),
                borderColor: polygonColor,
                borderStrokeWidth: 2.0,
              ));
            }
          }
        }
      } catch (e) {
        print('Erro ao construir polígono do talhão: $e');
      }
    }
    
    return polygons;
  }

  /// Constrói marcadores dos talhões existentes
  List<Marker> _buildTalhaoMarkers(List<dynamic> talhoes, CulturaProvider culturaProvider) {
    final List<Marker> markers = [];
    
    for (final talhao in talhoes) {
      try {
        // Verificar se o talhão tem polígonos
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          for (final poligono in talhao.poligonos) {
            if (poligono.pontos != null && poligono.pontos.isNotEmpty) {
              // Calcular centro do polígono
              double latSum = 0;
              double lngSum = 0;
              for (final ponto in poligono.pontos) {
                latSum += ponto.latitude;
                lngSum += ponto.longitude;
              }
              final centerLat = latSum / poligono.pontos.length;
              final centerLng = lngSum / poligono.pontos.length;
              
              // Obter cor da cultura
              Color markerColor = Colors.blue;
              if (talhao.safras != null && talhao.safras.isNotEmpty) {
                final safra = talhao.safras.first;
                if (safra.culturaCor != null) {
                  markerColor = safra.culturaCor;
                }
              }
              
              markers.add(Marker(
                point: LatLng(centerLat, centerLng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    if (onTalhaoTap != null) {
                      onTalhaoTap!(talhao);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.crop_free,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ));
            }
          }
        }
      } catch (e) {
        print('Erro ao construir marcador do talhão: $e');
      }
    }
    
    return markers;
  }
}
