import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/talhao_model.dart';
import '../utils/constants.dart';
import '../utils/api_config.dart';
// Importar o adaptador global para usar o tipo LatLng unificado
import '../utils/map_imports.dart' as maps;

/// Widget de mapa usando MapTiler como substituto do Google Maps
/// Mantém a mesma API do GoogleMapsWidget para facilitar a migração
class MapTilerGoogleCompatWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final Function(TalhaoModel)? onTalhaoSelected;
  final Function(maps.LatLng)? onMapTap;
  final List<maps.LatLng>? drawingPoints;
  final Function(List<maps.LatLng>)? onDrawingPointsChanged;
  final TalhaoModel? selectedTalhao;
  final bool isEditMode;
  final bool enableDrawing;
  final Color? drawingColor;
  final double? initialZoom;
  final maps.LatLng? initialCenter;
  final bool showControls;
  final Function(maps.LatLng)? onAddPoint;
  final Function(int)? onRemovePoint;
  final Function(int, maps.LatLng)? onMovePoint;
  
  const MapTilerGoogleCompatWidget({
    Key? key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.onMapTap,
    this.drawingPoints,
    this.onDrawingPointsChanged,
    this.selectedTalhao,
    this.isEditMode = false,
    this.enableDrawing = false,
    this.drawingColor = Colors.blue,
    this.initialZoom = 13.0,
    this.initialCenter,
    this.showControls = true,
    this.onAddPoint,
    this.onRemovePoint,
    this.onMovePoint,
  }) : super(key: key);

  @override
  State<MapTilerGoogleCompatWidget> createState() => _MapTilerGoogleCompatWidgetState();
}

class _MapTilerGoogleCompatWidgetState extends State<MapTilerGoogleCompatWidget> {
  late MapController _mapController;
  List<maps.LatLng> _currentDrawingPoints = [];
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<Polygon> _polygons = [];
  int _selectedPointIndex = -1;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentZoom = widget.initialZoom ?? 13.0;
    
    if (widget.drawingPoints != null) {
      _currentDrawingPoints = List.from(widget.drawingPoints!);
    }
    
    _updateMapElements();
    _initializeLocation();
  }

  /// Inicializa a localização GPS
  Future<void> _initializeLocation() async {
    try {
      final position = await _getCurrentLocation();
      if (position != null && mounted) {
        // Atualizar o centro do mapa para a localização GPS
        _mapController.move(
          latlong2.LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      }
    } catch (e) {
      print('Erro ao inicializar localização: $e');
    }
  }

  /// Obtém a localização atual do dispositivo
  Future<Position?> _getCurrentLocation() async {
    try {
      // Verificar permissões
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        print('Permissão de localização negada');
        return null;
      }

      // Verificar se o serviço de localização está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Serviço de localização desabilitado');
        return null;
      }

      // Obter localização atual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  @override
  void didUpdateWidget(MapTilerGoogleCompatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.drawingPoints != oldWidget.drawingPoints) {
      if (widget.drawingPoints != null) {
        setState(() {
          _currentDrawingPoints = List.from(widget.drawingPoints!);
        });
      }
    }
    
    if (widget.talhoes != oldWidget.talhoes ||
        widget.selectedTalhao != oldWidget.selectedTalhao) {
      _updateMapElements();
    }
  }

  void _updateMapElements() {
    setState(() {
      _updatePolygons();
      _updateMarkers();
      _updateDrawingPolyline();
    });
  }

  void _updatePolygons() {
    _polygons = [];
    
    // Adicionar polígonos dos talhões
    for (final talhao in widget.talhoes) {
      final List<dynamic> points = talhao.poligonos.isNotEmpty ? talhao.poligonos.first.pontos : <dynamic>[];
      if (points.isEmpty) continue;
      
      final isSelected = widget.selectedTalhao?.id == talhao.id;
      
      _polygons.add(
        Polygon(
          points: points.map((p) => latlong2.LatLng(p.latitude, p.longitude)).toList(),
          color: isSelected 
              ? Colors.blue.withOpacity(0.4) 
              : Colors.green.withOpacity(0.3),
          borderColor: isSelected 
              ? Colors.blue.withOpacity(0.8)
              : Colors.green.withOpacity(0.7),
          borderStrokeWidth: isSelected ? 3.0 : 2.0,
        ),
      );
    }
    
    // Adicionar polígono de desenho se estiver no modo de edição
    if (widget.isEditMode && _currentDrawingPoints.length > 2) {
      _polygons.add(
        Polygon(
          points: _currentDrawingPoints.map((p) => latlong2.LatLng(p.latitude, p.longitude)).toList(),
          color: (widget.drawingColor ?? Colors.blue).withOpacity(0.3),
          borderColor: (widget.drawingColor ?? Colors.blue).withOpacity(0.7),
          borderStrokeWidth: 2.0,
        ),
      );
    }
  }

  void _updateMarkers() {
    _markers = [];
    
    // Adicionar marcadores para pontos de desenho se estiver no modo de edição
    if (widget.isEditMode) {
      _addDrawingMarkers();
    }
    
    // Adicionar marcadores para talhões
    _addTalhaoMarkers();
  }

  void _addDrawingMarkers() {
    for (int i = 0; i < _currentDrawingPoints.length; i++) {
      final point = _currentDrawingPoints[i];
      final isSelected = i == _selectedPointIndex;
      
      _markers.add(
        Marker(
          point: latlong2.LatLng(point.latitude, point.longitude),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPointIndex = i;
              });
            },
            onPanUpdate: (details) {
              if (widget.onMovePoint != null) {
                _handlePointMove(i, point, details);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.blue,
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
  }

  void _handlePointMove(int index, maps.LatLng point, details) {
    // No flutter_map 5.0.0, precisamos calcular o deslocamento de uma maneira diferente
    // usando a transformação do controlador do mapa
    final currentLoc = point.toLatLong2();
    
    // Estima a nova localização com base no gesto de arrastar
    final currentZoom = _mapController.zoom;
    final scale = 1.0 / (math.pow(2, currentZoom) * 256.0); // aproximação de escala para conversão de pixels para coordenadas
    
    // Aplicar o deslocamento (uma aproximação simples)
    final newLat = currentLoc.latitude - (details.delta.dy * scale * 2.0);
    final newLng = currentLoc.longitude + (details.delta.dx * scale * 2.0);
    
    final newLatLng = maps.LatLng(newLat, newLng);
    
    widget.onMovePoint!(index, newLatLng);
    setState(() {
      _currentDrawingPoints[index] = newLatLng;
    });
    _updateMapElements();
  }

  void _addTalhaoMarkers() {
    for (final talhao in widget.talhoes) {
      final List<dynamic> points = talhao.poligonos.isNotEmpty ? talhao.poligonos.first.pontos : <dynamic>[];
      if (points.isEmpty) continue;
      
      final center = _calculateTalhaoCenter(talhao);
      final isSelected = widget.selectedTalhao?.id == talhao.id;
      
      if (widget.isEditMode && isSelected) {
        // Marcador especial para talhão selecionado no modo de edição
        _markers.add(
          Marker(
            point: center,
            child: GestureDetector(
              onTap: () {
                if (widget.onTalhaoSelected != null) {
                  widget.onTalhaoSelected!(talhao);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      } else if (!widget.isEditMode) {
        // Marcador normal para talhões
        _markers.add(
          Marker(
            point: center,
            width: 80,
            height: 30,
            child: GestureDetector(
              onTap: () {
                if (widget.onTalhaoSelected != null) {
                  widget.onTalhaoSelected!(talhao);
                }
              },
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
                  talhao.name.isNotEmpty ? talhao.name : 'Talhão',
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
  }

  latlong2.LatLng _calculateTalhaoCenter(TalhaoModel talhao) {
    double lat = 0;
    double lng = 0;
    final List<dynamic> points = talhao.poligonos.isNotEmpty ? talhao.poligonos.first.pontos : <dynamic>[];
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return latlong2.LatLng(
      lat / points.length,
      lng / points.length,
    );
  }

  void _updateDrawingPolyline() {
    _polylines = [];
    
    // Adicionar linha de desenho se estiver no modo de edição
    if (widget.isEditMode && _currentDrawingPoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          points: _currentDrawingPoints.map((p) => p.toLatLong2()).toList(),
          color: widget.drawingColor ?? Colors.blue,
          strokeWidth: 3.0,
        ),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, latlong2.LatLng point) {
    // Verificar se temos um callback de toque no mapa
    if (widget.onMapTap != null) {
      // Converter de latlong2.LatLng para maps.LatLng
      final mapsLatLng = maps.LatLng(point.latitude, point.longitude);
      widget.onMapTap!(mapsLatLng);
    }
    
    // Se estamos em modo de desenho, adicionar ponto ao desenhar
    if (widget.enableDrawing && widget.onAddPoint != null) {
      final mapsLatLng = maps.LatLng(point.latitude, point.longitude);
      widget.onAddPoint!(mapsLatLng);
    }
  }

  latlong2.LatLng _getMapCenter() {
    if (widget.initialCenter != null) {
      return widget.initialCenter!.toLatLong2();
    } else if (widget.selectedTalhao != null && (widget.selectedTalhao!.poligonos.isNotEmpty && widget.selectedTalhao!.poligonos.first.isNotEmpty)) {
      return _calculateTalhaoCenter(widget.selectedTalhao!);
    } else if (widget.talhoes.isNotEmpty && (widget.talhoes.first.poligonos.isNotEmpty && widget.talhoes.first.poligonos.first.isNotEmpty)) {
      return _calculateTalhaoCenter(widget.talhoes.first);
    } else {
      // Centro padrão (Brasil central) - será substituído pela localização GPS
      return latlong2.LatLng(-15.7801, -47.9292);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _getMapCenter();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: center,
            zoom: _currentZoom,
            maxZoom: 22.0,
            minZoom: 4.0,
            interactiveFlags: InteractiveFlag.all,
            onTap: _onMapTap,
          ),
          children: [
            // Camada de mapa base do MapTiler (modo satélite por padrão)
            TileLayer(
              urlTemplate: APIConfig.getMapTilerUrl('satellite'),
              userAgentPackageName: 'com.fortsmart.agro',
              tileProvider: NetworkTileProvider(),
              // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
              maxZoom: 22,
            ),
            
            // Camada de polígonos
            PolygonLayer(polygons: _polygons),
            
            // Camada de polilinhas
            PolylineLayer(polylines: _polylines),
            
            // Camada de marcadores
            MarkerLayer(markers: _markers),
          ],
        ),
        
        // Controles do mapa
        if (widget.showControls) _buildMapControls(center),
      ],
    );
  }

  Widget _buildMapControls(latlong2.LatLng center) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de zoom in
          _buildMapControl(
            Icons.add,
            () {
              final currentZoom = math.min(_currentZoom + 1, 22.0);
              _mapController.move(center, currentZoom);
              setState(() {
                _currentZoom = currentZoom;
              });
            },
          ),
          const SizedBox(height: 8),
          
          // Botão de zoom out
          _buildMapControl(
            Icons.remove,
            () {
              final currentZoom = math.max(_currentZoom - 1, 4.0);
              _mapController.move(center, currentZoom);
              setState(() {
                _currentZoom = currentZoom;
              });
            },
          ),
          
          // Botão para remover ponto selecionado
          if (widget.isEditMode && 
              _selectedPointIndex >= 0 && 
              _selectedPointIndex < _currentDrawingPoints.length) ...[
            const SizedBox(height: 8),
            _buildMapControl(
              Icons.delete,
              () => _removeSelectedPoint(),
              // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
            ),
          ],
        ],
      ),
    );
  }

  void _removeSelectedPoint() {
    if (widget.onRemovePoint != null) {
      widget.onRemovePoint!(_selectedPointIndex);
    } else {
      setState(() {
        _currentDrawingPoints.removeAt(_selectedPointIndex);
        if (widget.onDrawingPointsChanged != null) {
          widget.onDrawingPointsChanged!(_currentDrawingPoints);
        }
      });
    }
    
    setState(() {
      _selectedPointIndex = -1;
    });
    _updateMapElements();
  }

  Widget _buildMapControl(
    IconData icon, 
    VoidCallback onPressed, {
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: backgroundColor != null ? Colors.white : Colors.black,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        iconSize: 20,
      ),
    );
  }
}