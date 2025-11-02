import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../utils/maptiler_constants.dart';
import '../utils/clean_map_compatibility.dart';
import '../utils/cultura_colors.dart';

/// Widget de mapa limpo usando flutter_map com MapTiler
class CleanMapWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final TalhaoModel? selectedTalhao;
  final Function(TalhaoModel)? onTalhaoSelected;
  final Function(LatLng)? onMapTap;
  final List<LatLng>? drawingPoints;
  final Function(List<LatLng>)? onDrawingPointsChanged;
  final bool isEditMode;
  final bool enableDrawing;
  final Color? drawingColor;
  final double initialZoom;
  final LatLng? initialCenter;
  final bool showControls;
  final String mapStyle;
  
  const CleanMapWidget({
    Key? key,
    required this.talhoes,
    this.selectedTalhao,
    this.onTalhaoSelected,
    this.onMapTap,
    this.drawingPoints,
    this.onDrawingPointsChanged,
    this.isEditMode = false,
    this.enableDrawing = false,
    this.drawingColor,
    this.initialZoom = 15.0,
    this.initialCenter,
    this.showControls = true,
    this.mapStyle = 'hybrid',
  }) : super(key: key);

  @override
  State<CleanMapWidget> createState() => _CleanMapWidgetState();
}

class _CleanMapWidgetState extends State<CleanMapWidget> {
  late MapController _mapController;
  late String _currentMapStyle;
  List<Polygon> _polygons = [];
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<LatLng> _currentDrawingPoints = [];
  int? _selectedMarkerIndex;
  
  @override
  void initState() {
    super.initState();
    _currentMapStyle = widget.mapStyle;
    _mapController = MapController();
    _initializeDrawingPoints();
    _updateMapFeatures();
  }
  
  @override
  void didUpdateWidget(CleanMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.talhoes != oldWidget.talhoes || 
        widget.selectedTalhao != oldWidget.selectedTalhao ||
        widget.drawingPoints != oldWidget.drawingPoints) {
      _updateMapFeatures();
    }
    
    if (widget.drawingPoints != null && 
        widget.drawingPoints != oldWidget.drawingPoints) {
      final points = widget.drawingPoints;
      if (points != null) {
        _currentDrawingPoints = List.from(points);
      }
    }
    
    // Atualizar o estilo do mapa quando o parâmetro mapStyle mudar
    if (widget.mapStyle != oldWidget.mapStyle) {
      setState(() {
        _currentMapStyle = widget.mapStyle;
      });
    }
  }
  
  void _initializeDrawingPoints() {
    final points = widget.drawingPoints;
    if (points != null) {
      _currentDrawingPoints = List.from(points);
    }
  }
  
  void _updateMapFeatures() {
    _updatePolygons();
    _updateMarkers();
    _updatePolylines();
  }
  
  void _updatePolygons() {
    final List<Polygon> polygons = [];
    
    // Adicionar polígonos para cada talhão
    for (final talhao in widget.talhoes) {
      if (talhao.poligonos != null && talhao.poligonos!.isNotEmpty) {
        for (final poligono in talhao.poligonos!) {
          if (poligono.isNotEmpty) {
            final bool isSelected = widget.selectedTalhao?.id == talhao.id;
            
            // Converter para LatLng do latlong2 usando a classe de compatibilidade
            final convertedPoints = poligono.toList();
            
            polygons.add(
              Polygon(
                points: convertedPoints,
                color: _getCulturaColor(talhao.crop?.name).withOpacity(0.5),
                borderColor: isSelected ? Colors.yellow : Colors.black,
                borderStrokeWidth: isSelected ? 3.0 : 2.0,
                isFilled: true,
              ),
            );
          }
        }
      }
    }
    
    setState(() {
      _polygons = polygons;
    });
  }
  
  void _updateMarkers() {
    final List<Marker> markers = [];
    
    // Adicionar marcadores para pontos de desenho se estiver no modo de edição
    if (widget.isEditMode && _currentDrawingPoints.isNotEmpty) {
      for (int i = 0; i < _currentDrawingPoints.length; i++) {
        final point = _currentDrawingPoints[i];
        final bool isSelected = _selectedMarkerIndex == i;
        
        markers.add(
          Marker(
            width: 20.0,
            height: 20.0,
            point: point,
            builder: (ctx) => GestureDetector(
              onTap: () => _handleMarkerTap(i),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _updatePolylines() {
    final List<Polyline> polylines = [];
    
    // Adicionar linha para pontos de desenho
    if (_currentDrawingPoints.length > 1) {
      polylines.add(
        Polyline(
          points: _currentDrawingPoints,
          strokeWidth: 3.0,
          color: widget.drawingColor ?? Colors.blue,
        ),
      );
      
      // Fechar o polígono se tivermos pelo menos 3 pontos
      if (_currentDrawingPoints.length > 2) {
        polylines.add(
          Polyline(
            points: [
              _currentDrawingPoints.last,
              _currentDrawingPoints.first,
            ],
            strokeWidth: 3.0,
            color: widget.drawingColor ?? Colors.blue,
            isDotted: true,
          ),
        );
      }
    }
    
    setState(() {
      _polylines = polylines;
    });
  }
  
  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    // Notificar o callback de tap no mapa
    final onMapTap = widget.onMapTap;
    if (onMapTap != null) {
      onMapTap(point);
    }
    
    // Adicionar ponto ao desenho se estiver no modo de desenho
    if (widget.enableDrawing) {
      setState(() {
        _currentDrawingPoints.add(point);
        _selectedMarkerIndex = null;
      });
      
      _updateMapFeatures();
      
      // Notificar mudança nos pontos de desenho
      final onDrawingPointsChanged = widget.onDrawingPointsChanged;
      if (onDrawingPointsChanged != null) {
        onDrawingPointsChanged(_currentDrawingPoints);
      }
    }
  }
  
  void _handleMarkerTap(int index) {
    setState(() {
      _selectedMarkerIndex = index;
    });
  }
  
  void _removeSelectedPoint() {
    if (_selectedMarkerIndex != null && 
        _selectedMarkerIndex! < _currentDrawingPoints.length) {
      setState(() {
        _currentDrawingPoints.removeAt(_selectedMarkerIndex!);
        _selectedMarkerIndex = null;
      });
      
      _updateMapFeatures();
      
      // Notificar mudança nos pontos de desenho
      if (widget.onDrawingPointsChanged != null) {
        widget.onDrawingPointsChanged!(_currentDrawingPoints);
      }
    }
  }
  
  void _toggleMapType() {
    setState(() {
      switch (_currentMapStyle) {
        case 'streets':
          _currentMapStyle = 'satellite';
          break;
        case 'satellite':
          _currentMapStyle = 'hybrid';
          break;
        case 'hybrid':
          _currentMapStyle = 'outdoor';
          break;
        case 'outdoor':
          _currentMapStyle = 'basic';
          break;
        case 'basic':
        default:
          _currentMapStyle = 'streets';
          break;
      }
      debugPrint('Estilo de mapa alternado para: $_currentMapStyle');
    });
  }
  
  /// Retorna a URL da camada base do mapa de acordo com o estilo atual
  String _getMapTilerUrl() {
    switch (_currentMapStyle) {
      case 'streets':
        return MapTilerConstants.streetsUrl;
      case 'satellite':
        return MapTilerConstants.satelliteUrl;
      case 'hybrid':
        // Para o estilo híbrido, usamos o mapa de satélite como base
        // e sobrepor uma camada de ruas com opacidade reduzida
        return MapTilerConstants.satelliteUrl;
      case 'outdoor':
        return MapTilerConstants.outdoorUrl;
      case 'basic':
        return MapTilerConstants.basicUrl;
      default:
        return MapTilerConstants.streetsUrl;
    }
  }
  
  /// Retorna o ícone apropriado para o estilo de mapa atual
  IconData _getMapTypeIcon() {
    switch (_currentMapStyle) {
      case 'streets':
        return Icons.map;
      case 'satellite':
        return Icons.satellite;
      case 'hybrid':
        return Icons.satellite_alt;
      case 'outdoor':
        return Icons.terrain;
      case 'basic':
        return Icons.grid_on;
      default:
        return Icons.layers;
    }
  }
  
  void _clearDrawing() {
    setState(() {
      _currentDrawingPoints.clear();
      _selectedMarkerIndex = null;
    });
    
    _updateMapFeatures();
    
    // Notificar mudança nos pontos de desenho
    if (widget.onDrawingPointsChanged != null) {
      widget.onDrawingPointsChanged!(_currentDrawingPoints);
    }
  }
  
  Color _getCulturaColor(String? cultura) {
    if (cultura == null) return Colors.blue;
    return CulturaColorsUtils.getColorForName(cultura);
  }
  
  @override
  Widget build(BuildContext context) {
    // Determinar o centro do mapa
    final center = widget.initialCenter ?? 
        (_currentDrawingPoints.isNotEmpty ? 
            _currentDrawingPoints.first : 
            LatLng(-15.77972, -47.92972)); // Brasil central
    
    return Stack(
      children: [
        // Mapa
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: center,
            zoom: widget.initialZoom,
            minZoom: MapTilerConstants.minZoom,
            maxZoom: MapTilerConstants.maxZoom,
            interactiveFlags: InteractiveFlag.all,
            onTap: _handleMapTap,
            enableScrollWheel: true,
            keepAlive: true,
            adaptiveBoundaries: true,
            slideOnBoundaries: true,
            enableMultiFingerGestureRace: true,
          ),
          children: [
            TileLayer(
              urlTemplate: _getMapTilerUrl(),
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            PolygonLayer(polygons: _polygons),
            PolylineLayer(polylines: _polylines),
            MarkerLayer(markers: _markers),
            
            // Camada de overlay para o mapa híbrido
            if (_currentMapStyle == 'hybrid')
              TileLayer(
                urlTemplate: MapTilerConstants.streetsUrl,
                opacity: 0.7,
                userAgentPackageName: 'com.fortsmart.agro',
              ),
          ],
        ),
        
        // Controles do mapa
        if (widget.showControls)
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão de alternar tipo de mapa
                FloatingActionButton(
                  heroTag: 'map_type',
                  mini: true,
                  onPressed: _toggleMapType,
                  child: Icon(_getMapTypeIcon()),
                  tooltip: 'Alternar estilo de mapa: $_currentMapStyle',
                ),
                const SizedBox(height: 8.0),
                
                // Botão de limpar desenho (apenas se estiver no modo de desenho)
                if (widget.enableDrawing)
                  FloatingActionButton(
                    heroTag: 'clear_drawing',
                    mini: true,
                    onPressed: _clearDrawing,
                    child: const Icon(Icons.delete),
                  ),
                
                // Botão de remover ponto selecionado (apenas se houver ponto selecionado)
                if (_selectedMarkerIndex != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FloatingActionButton(
                      heroTag: 'remove_point',
                      mini: true,
                      onPressed: _removeSelectedPoint,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.remove),
                    ),
                  ),
              ],
            ),
          ),
        
        // Indicador de área
        if (_currentDrawingPoints.length > 2)
          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: _AreaIndicator(points: _currentDrawingPoints),
          ),
      ],
    );
  }
}

class _AreaIndicator extends StatelessWidget {
  final List<LatLng> points;
  
  const _AreaIndicator({required this.points});
  
  @override
  Widget build(BuildContext context) {
    final double areaInSquareMeters = _calculateArea();
    final double areaInHectares = areaInSquareMeters / 10000;
    
    String areaText;
    if (areaInHectares < 0.01) {
      areaText = '${areaInSquareMeters.toStringAsFixed(0)} m²';
    } else {
      areaText = '${areaInHectares.toStringAsFixed(2)} ha';
    }
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Área aproximada:'),
          Text(
            areaText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculateArea() {
    return CleanMapCompatibility.calcularAreaPoligono(points);
  }
}
