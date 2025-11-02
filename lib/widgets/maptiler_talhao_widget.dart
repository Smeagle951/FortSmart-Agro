import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../utils/constants.dart';
import 'glass_morphism_container.dart';

/// Widget para exibir o mapa com os talhões usando MapTiler
/// Substitui o antigo TalhaoMapWidget que usava Mapbox
class MapTilerTalhaoWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final TalhaoModel? selectedTalhao;
  final List<LatLng> drawingPoints;
  final bool isDrawingMode;
  final bool isSatelliteMode;
  final Function(LatLng) onMapTap;
  final Function(TalhaoModel) onTalhaoTap;
  final Function(MapController) onMapCreated;
  final Function() onMyLocationPressed;
  final Function() onDrawingModeToggled;
  final Function() onClearDrawing;
  final Function()? onSatelliteModeToggled; // Adicionado callback para modo satélite

  const MapTilerTalhaoWidget({
    super.key,
    required this.talhoes,
    this.selectedTalhao,
    required this.drawingPoints,
    required this.isDrawingMode,
    required this.isSatelliteMode,
    required this.onMapTap,
    required this.onTalhaoTap,
    required this.onMapCreated,
    required this.onMyLocationPressed,
    required this.onDrawingModeToggled,
    required this.onClearDrawing,
    this.onSatelliteModeToggled, // Parâmetro opcional
  });

  @override
  State<MapTilerTalhaoWidget> createState() => _MapTilerTalhaoWidgetState();
}

class _MapTilerTalhaoWidgetState extends State<MapTilerTalhaoWidget> {
  late MapController _mapController;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<Polygon> _polygons = [];
  double _currentZoom = 5.0;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapTilerTalhaoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Atualizar o mapa quando os talhões, o talhão selecionado ou os pontos de desenho mudarem
    if (widget.talhoes != oldWidget.talhoes ||
        widget.selectedTalhao != oldWidget.selectedTalhao ||
        widget.drawingPoints != oldWidget.drawingPoints) {
      _updateMapFeatures();
    }
  }

  void _updateMapFeatures() {
    setState(() {
      _updatePolygons();
      _updateDrawingPolyline();
      _updateMarkers();
    });
  }

  void _updatePolygons() {
    _polygons = [];
    
    // Adicionar polígonos dos talhões
    for (final talhao in widget.talhoes) {
      final isSelected = widget.selectedTalhao?.id == talhao.id;
      
      if (talhao.poligonos.isNotEmpty && talhao.poligonos.first.isNotEmpty) {
        _polygons.add(
          Polygon(
            points: talhao.poligonos.first.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: isSelected ? Colors.blue.withOpacity(0.4) : Colors.green.withOpacity(0.3),
            borderColor: isSelected ? Colors.blue.withOpacity(0.8) : Colors.green.withOpacity(0.7),
            borderStrokeWidth: isSelected ? 3.0 : 2.0,
          ),
        );
      }
    }
  }

  void _updateDrawingPolyline() {
    _polylines = [];
    
    // Adicionar polilinhas para o desenho atual
    if (widget.drawingPoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          points: widget.drawingPoints,
          color: Colors.red,
          strokeWidth: 3.0,
        ),
      );
      
      // Adicionar polígono de desenho se houver mais de 2 pontos
      if (widget.drawingPoints.length > 2) {
        _polygons.add(
          Polygon(
            points: widget.drawingPoints,
            color: Colors.red.withOpacity(0.2),
            borderColor: Colors.red.withOpacity(0.7),
            borderStrokeWidth: 2.0,
          ),
        );
      }
    }
  }

  void _updateMarkers() {
    _markers = [];
    
    // Adicionar marcadores para os pontos de desenho
    for (int i = 0; i < widget.drawingPoints.length; i++) {
      final point = widget.drawingPoints[i];
      
      _markers.add(
        Marker(
          point: point,
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () {
              // Implementar ação para clique no ponto de desenho se necessário
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Adicionar marcadores para os centros dos talhões
    for (final talhao in widget.talhoes) {
      if (talhao.poligonos.isEmpty || talhao.poligonos.first.isEmpty) continue;
      
      final points = talhao.poligonos.first.map((p) => LatLng(p.latitude, p.longitude)).toList();
      
      // Calcular o centro do talhão
      double lat = 0;
      double lng = 0;
      for (final point in points) {
        lat += point.latitude;
        lng += point.longitude;
      }
      lat /= points.length;
      lng /= points.length;
      
      final center = LatLng(lat, lng);
      final isSelected = widget.selectedTalhao?.id == talhao.id;
      
      // Buscar nome da cultura para exibir
      String nomeCultura = talhao.name.isNotEmpty ? talhao.name : 'Talhão';
      
      _markers.add(
        Marker(
          point: center,
          width: 80,
          height: 30,
          child: GestureDetector(
            onTap: () => widget.onTalhaoTap(talhao),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.green,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                nomeCultura,
                style: TextStyle(
                  color: isSelected ? Colors.red : Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _onMapTap(TapPosition position, LatLng point) {
    if (widget.isDrawingMode) {
      widget.onMapTap(point);
    }
  }

  void _centerOnTalhoes() {
    if (widget.talhoes.isEmpty) return;
    
    List<LatLng> allPoints = [];
    
    for (final talhao in widget.talhoes) {
      if (talhao.poligonos.isNotEmpty && talhao.poligonos.first.isNotEmpty) {
        allPoints.addAll(talhao.poligonos.first.map((p) => LatLng(p.latitude, p.longitude)).toList());
      }
    }
    
    if (allPoints.isEmpty) return;
    
    // Calcular os limites (bounds) dos pontos
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;
    
    for (final point in allPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    // Adicionar padding aos limites
    const padding = 0.01; // Aproximadamente 1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    // Centralizar o mapa
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    _mapController.move(LatLng(centerLat, centerLng), _currentZoom.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: LatLng(-15.7801, -47.9292), // Brasília como ponto inicial
            zoom: 5.0,
            // onTap: _onMapTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
            onMapReady: () {
              widget.onMapCreated(_mapController);
              _updateMapFeatures();
            },
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _currentZoom = position.zoom ?? 5.0;
                });
              }
            },
          ),
          children: [
            // Camada de mapa base do MapTiler
            TileLayer(
              urlTemplate: widget.isSatelliteMode 
                ? 'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=YOUR_MAPTILER_API_KEY'
                : 'https://api.maptiler.com/maps/streets/256/{z}/{x}/{y}.png?key=YOUR_MAPTILER_API_KEY',
              userAgentPackageName: 'com.fortsmartagro.app',
              tileProvider: NetworkTileProvider(),
              // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
              maxZoom: 22,
            ),
            
            // Camada de polígonos
            PolygonLayer(
              polygons: _polygons,
            ),
            
            // Camada de polilinhas
            PolylineLayer(
              polylines: _polylines,
            ),
            
            // Camada de marcadores
            MarkerLayer(
              markers: _markers,
            ),
          ],
        ),
        
        // Botões de controle do mapa
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão de modo satélite/normal
              GlassMorphismContainer(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
                borderColor: Colors.white.withOpacity(0.2),
                borderWidth: 1.5,
                child: IconButton(
                  icon: Icon(
                    widget.isSatelliteMode ? Icons.map : Icons.satellite,
                    color: Colors.white,
                  ),
                  onPressed: widget.onSatelliteModeToggled,
                ),
              ),
              const SizedBox(height: 10),
              
              // Botão de centralizar no mapa
              GlassMorphismContainer(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
                borderColor: Colors.white.withOpacity(0.2),
                borderWidth: 1.5,
                child: IconButton(
                  icon: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                  onPressed: widget.onMyLocationPressed,
                ),
              ),
              const SizedBox(height: 10),
              
              // Botão de centralizar nos talhões
              GlassMorphismContainer(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
                borderColor: Colors.white.withOpacity(0.2),
                borderWidth: 1.5,
                child: IconButton(
                  icon: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.white,
                  ),
                  onPressed: _centerOnTalhoes,
                ),
              ),
              const SizedBox(height: 10),
              
              // Botão de modo desenho
              GlassMorphismContainer(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
                borderColor: Colors.white.withOpacity(0.2),
                borderWidth: 1.5,
                child: IconButton(
                  icon: Icon(
                    widget.isDrawingMode ? Icons.edit_off : Icons.edit,
                    color: widget.isDrawingMode ? Colors.blue : Colors.white,
                  ),
                  onPressed: widget.onDrawingModeToggled,
                ),
              ),
              
              // Botão de limpar desenho (só aparece se estiver em modo desenho)
              if (widget.isDrawingMode && widget.drawingPoints.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 10),
                    GlassMorphismContainer(
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(25),
                      borderColor: Colors.white.withOpacity(0.2),
                      borderWidth: 1.5,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: widget.onClearDrawing,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // Área de cálculo (só aparece se estiver em modo desenho e tiver pontos)
        if (widget.isDrawingMode && widget.drawingPoints.length > 2)
          Positioned(
            left: 16,
            bottom: 16,
            child: GlassMorphismContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.circular(20),
              borderColor: Colors.white.withOpacity(0.2),
              borderWidth: 1.5,
              child: Text(
                'Área: ${_calculateArea(widget.drawingPoints).toStringAsFixed(2)} ha',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Calcula a área aproximada em hectares usando a fórmula de Haversine
  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    
    double area = 0;
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    // Implementação da fórmula de área esférica
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      
      double lat1 = _toRadians(points[i].latitude);
      double lon1 = _toRadians(points[i].longitude);
      double lat2 = _toRadians(points[j].latitude);
      double lon2 = _toRadians(points[j].longitude);
      
      area += (lon2 - lon1) * (lat1 + lat2);
    }
    
    area = (area * earthRadius * earthRadius / 2).abs();
    
    // Converter para hectares (1 hectare = 10.000 m²)
    return area / 10000;
  }
  
  /// Converte graus para radianos
  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }
}