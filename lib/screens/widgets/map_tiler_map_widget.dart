import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import '../../models/talhao_model.dart';

/// Widget de mapa usando Flutter Map com suporte a desenho de polígonos
class MapTilerMapWidget extends StatefulWidget {
  final MapOptions mapOptions;
  final List<TalhaoModel> talhoes;
  final List<latlong2.LatLng> drawingPoints;
  final Color drawingColor;
  final bool enableDrawing;
  final Function(latlong2.LatLng)? onTap;
  final Function(List<latlong2.LatLng>)? onPolygonCompleted;
  final Function(TalhaoModel)? onTalhaoTap;
  final MapController? mapController;
  final String? mapTileUrl;
  final Widget? floatingActionButton;
  final List<Widget>? additionalLayers;

  const MapTilerMapWidget({
    Key? key,
    required this.mapOptions,
    this.talhoes = const [],
    this.drawingPoints = const [],
    this.drawingColor = Colors.blue,
    this.enableDrawing = false,
    this.onTap,
    this.onPolygonCompleted,
    this.onTalhaoTap,
    this.mapController,
    this.mapTileUrl,
    this.floatingActionButton,
    this.additionalLayers,
  }) : super(key: key);

  @override
  _MapTilerMapWidgetState createState() => _MapTilerMapWidgetState();
}

class _MapTilerMapWidgetState extends State<MapTilerMapWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  @override
  Widget build(BuildContext context) {
    // Usar as opções de mapa fornecidas ou criar novas
    final mapOptions = widget.mapOptions;
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: mapOptions,
          children: [
            // Camada de tiles (mapa base)
            TileLayer(
              urlTemplate: widget.mapTileUrl ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Camada de polígonos para talhões
            PolygonLayer(
              polygons: _buildTalhaoPolygons(),
            ),
            
            // Camada de polígono para desenho atual
            if (widget.drawingPoints.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: widget.drawingPoints,
                    color: widget.drawingColor.withOpacity(0.3),
                    borderColor: widget.drawingColor,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
            
            // Camada de marcadores para os pontos de desenho
            MarkerLayer(
              markers: widget.drawingPoints.map((point) => Marker(
                point: point,
                builder: (ctx) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.drawingColor,
                    shape: BoxShape.circle,
                  ),
                ),
              )).toList(),
            ),
            
            // Camadas adicionais fornecidas pelo usuário
            if (widget.additionalLayers != null)
              ...widget.additionalLayers!,
          ],
        ),
        
        // Botão de ação flutuante
        if (widget.floatingActionButton != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: widget.floatingActionButton!,
          ),
      ],
    );
  }

  List<Polygon> _buildTalhaoPolygons() {
    final polygons = <Polygon>[];
    
    for (final talhao in widget.talhoes) {
      if (talhao.poligonos.isNotEmpty) {
        for (final poligono in talhao.poligonos) {
          // Converter MapboxLatLng para latlong2.LatLng
          final points = poligono.map((coord) => 
            latlong2.LatLng(coord.latitude, coord.longitude)
          ).toList();
          
          if (points.isNotEmpty) {
            polygons.add(
              Polygon(
                points: points,
                color: talhao.cor.withOpacity(0.3),
                borderColor: talhao.cor,
                borderStrokeWidth: 2.0,
                // onTap: widget.onTalhaoTap != null ? () => widget.onTalhaoTap!(talhao) : null, // onTap não é suportado em Polygon no flutter_map 5.0.0
              ),
            );
          }
        }
      }
    }
    
    return polygons;
  }
}
