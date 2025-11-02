import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import '../../models/talhao_model.dart';
import '../../utils/map_options_extensions.dart';

// Importar as classes necessárias para o flutter_map 5.0.0
import 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
import 'package:flutter_map/src/map/map.dart';

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
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: widget.mapOptions.copyWith(
            onTap: widget.enableDrawing && widget.onTap != null
                ? (tapPosition, latLng) => widget.onTap!(latLng)
                : null,
          ),
          children: [
            // Camada de tiles
            TileLayer(
              urlTemplate: widget.mapTileUrl ?? 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Camada de polígonos dos talhões
            _buildTalhoesPolygons(),
            
            // Camadas adicionais fornecidas pelo widget pai
            if (widget.additionalLayers != null) ...widget.additionalLayers!,
            
            // Camada para os pontos do polígono que está sendo desenhado
            MarkerLayer(
              markers: widget.drawingPoints.map((point) {
                return Marker(
                  width: 10.0,
                  height: 10.0,
                  point: point,
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: widget.drawingColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.0),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            // Linha conectando os pontos do polígono
            PolylineLayer(
              polylines: widget.drawingPoints.length >= 2
                  ? [
                      Polyline(
                        points: widget.drawingPoints,
                        strokeWidth: 2.0,
                        color: widget.drawingColor,
                      ),
                    ]
                  : [],
            ),
          ],
        ),
        
        // Botão de ação flutuante (opcional)
        if (widget.floatingActionButton != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: widget.floatingActionButton!,
          ),
      ],
    );
  }

  // Constrói a camada de polígonos para os talhões
  PolygonLayer _buildTalhoesPolygons() {
    List<Polygon> polygons = [];
    widget.talhoes.forEach((talhao) {
      if (talhao.poligonos.isNotEmpty) {
        talhao.poligonos.forEach((poligono) {
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
                // onTap não é suportado em flutter_map 5.0.0
              ),
            );
          }
        });
      }
    });
    return PolygonLayer(
      polygons: polygons,
      polygonCulling: true,
    );
  }
}
