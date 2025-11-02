import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../utils/maptiler_constants.dart';
import '../utils/latlng_adapter.dart';
import '../utils/cultura_colors.dart';

/// Widget de mapa usando flutter_map com MapTiler como provedor de tiles
class MapTilerMapWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final Function(TalhaoModel)? onTalhaoSelected;
  final Function(LatLng)? onMapTap;
  final List<LatLng>? drawingPoints;
  final Function(List<LatLng>)? onDrawingPointsChanged;
  final TalhaoModel? selectedTalhao;
  final bool isEditMode;
  final bool enableDrawing;
  final Color? drawingColor;
  final double? initialZoom;
  final LatLng? initialCenter;
  final bool showControls;
  final Function(LatLng)? onAddPoint;
  final Function(int)? onRemovePoint;
  final Function(int, LatLng)? onMovePoint;
  
  const MapTilerMapWidget({
    Key? key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.onMapTap,
    this.drawingPoints,
    this.onDrawingPointsChanged,
    this.selectedTalhao,
    this.isEditMode = false,
    this.enableDrawing = false,
    this.drawingColor,
    this.initialZoom = 15.0,
    this.initialCenter,
    this.showControls = true,
    this.onAddPoint,
    this.onRemovePoint,
    this.onMovePoint,
  }) : super(key: key);

  @override
  State<MapTilerMapWidget> createState() => _MapTilerMapWidgetState();
}

class _MapTilerMapWidgetState extends State<MapTilerMapWidget> {
  MapController? _mapController;
  String _currentMapStyle = 'hybrid';
  List<Polygon> _polygons = [];
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  
  // API Key do MapTiler fornecida através de MapTilerConstants
  
  // Controle de desenho
  List<LatLng> _currentDrawingPoints = [];
  
  // Controle de edição
  int? _selectedMarkerIndex;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeDrawingPoints();
    _updateMapFeatures();
  }
  
  @override
  void didUpdateWidget(MapTilerMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.talhoes != oldWidget.talhoes || 
        widget.selectedTalhao != oldWidget.selectedTalhao ||
        widget.drawingPoints != oldWidget.drawingPoints) {
      _updateMapFeatures();
    }
    
    if (widget.drawingPoints != oldWidget.drawingPoints && 
        widget.drawingPoints != null) {
      _currentDrawingPoints = List.from(widget.drawingPoints!);
    }
  }
  
  void _initializeDrawingPoints() {
    if (widget.drawingPoints != null) {
      _currentDrawingPoints = List.from(widget.drawingPoints!);
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
            
            // Converter MapboxLatLng para latlong2.LatLng
            final convertedPoints = poligono.map((point) => LatLngAdapter.toLatLong2(point)).toList();
            
            polygons.add(
              Polygon(
                points: convertedPoints,
                color: _getCulturaColor(talhao.culturaId ?? '').withOpacity(0.5),
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
    
    // Adicionar marcadores de edição se estiver no modo de desenho
    if (widget.isEditMode && widget.enableDrawing && _currentDrawingPoints.isNotEmpty) {
      for (int i = 0; i < _currentDrawingPoints.length; i++) {
        final point = _currentDrawingPoints[i];
                    markers.add(
              Marker(
                point: point,
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onTap: () => _handleMarkerTap(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
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
    
    // Adicionar polyline para o desenho atual
    if (_currentDrawingPoints.isNotEmpty) {
      if (_currentDrawingPoints.length > 1) {
        // Fechar o polígono conectando o último ponto ao primeiro
        final List<LatLng> closedPoints = List.from(_currentDrawingPoints);
        if (closedPoints.length > 2) {
          closedPoints.add(closedPoints.first);
        }
        
        polylines.add(
          Polyline(
            points: closedPoints,
            color: widget.drawingColor ?? Colors.blue,
            strokeWidth: 3.0,
          ),
        );
      }
    }
    
    setState(() {
      _polylines = polylines;
    });
  }
  
  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.isEditMode && widget.enableDrawing) {
      // Adicionar um novo ponto ao desenho
      setState(() {
        _currentDrawingPoints.add(point);
        _updateMapFeatures();
      });
      
      if (widget.onAddPoint != null) {
        widget.onAddPoint!(point);
      }
      
      if (widget.onDrawingPointsChanged != null) {
        widget.onDrawingPointsChanged!(_currentDrawingPoints);
      }
    } else if (widget.onMapTap != null) {
      widget.onMapTap!(point);
    }
  }
  
  void _handleMarkerDrag(int index, LatLng position) {
    if (index >= 0 && index < _currentDrawingPoints.length) {
      setState(() {
        _currentDrawingPoints[index] = position;
        _updateMapFeatures();
      });
      
      if (widget.onMovePoint != null) {
        widget.onMovePoint!(index, position);
      }
      
      if (widget.onDrawingPointsChanged != null) {
        widget.onDrawingPointsChanged!(_currentDrawingPoints);
      }
    }
  }
  
  void _handleMarkerTap(int index) {
    setState(() {
      _selectedMarkerIndex = index;
    });
    
    // Mostrar diálogo de confirmação para remover o ponto
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover ponto'),
        content: const Text('Deseja remover este ponto do desenho?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _removeSelectedPoint();
              Navigator.of(context).pop();
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
  
  void _removeSelectedPoint() {
    if (_selectedMarkerIndex != null && 
        _selectedMarkerIndex! >= 0 && 
        _selectedMarkerIndex! < _currentDrawingPoints.length) {
      
      setState(() {
        _currentDrawingPoints.removeAt(_selectedMarkerIndex!);
        _updateMapFeatures();
      });
      
      if (widget.onRemovePoint != null) {
        widget.onRemovePoint!(_selectedMarkerIndex!);
      }
      
      if (widget.onDrawingPointsChanged != null) {
        widget.onDrawingPointsChanged!(_currentDrawingPoints);
      }
      
      _selectedMarkerIndex = null;
    }
  }
  
  void _toggleMapType() {
    setState(() {
      // Alternar entre os estilos de mapa disponíveis
      switch (_currentMapStyle) {
        case 'hybrid':
          _currentMapStyle = 'streets';
          break;
        case 'streets':
          _currentMapStyle = 'satellite';
          break;
        case 'satellite':
          _currentMapStyle = 'terrain';
          break;
        case 'terrain':
          _currentMapStyle = 'hybrid';
          break;
        default:
          _currentMapStyle = 'hybrid';
      }
    });
  }
  
  String _getMapTilerUrl() {
    // Retorna a URL do estilo de mapa selecionado usando as constantes
    switch (_currentMapStyle) {
      case 'satellite':
        return MapTilerConstants.satelliteUrl;
      case 'streets':
        return MapTilerConstants.streetsUrl;
      case 'terrain':
        return MapTilerConstants.outdoorUrl;
      case 'hybrid':
      default:
        return MapTilerConstants.satelliteUrl; // Usar satélite como padrão por enquanto
    }
  }
  
  void _clearDrawing() {
    setState(() {
      _currentDrawingPoints.clear();
      _updateMapFeatures();
    });
    
    if (widget.onDrawingPointsChanged != null) {
      widget.onDrawingPointsChanged!(_currentDrawingPoints);
    }
  }
  
  void _centerOnCurrentLocation() async {
    // Em uma implementação real, usaríamos o geolocator para obter a localização atual
    if (_mapController != null && widget.initialCenter != null) {
      _mapController!.move(widget.initialCenter!, widget.initialZoom ?? 15.0);
    }
  }
  
  Color _getCulturaColor(String? cultura) {
    if (cultura == null) return Colors.grey;
    return CulturaColorsUtils.getColorForName(cultura);
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: widget.initialCenter ?? LatLng(-15.7801, -47.9292), // Brasília como padrão
            zoom: widget.initialZoom ?? 15.0,
            onTap: _handleMapTap,
            // interactionOptions não é suportado no flutter_map 5.0.0
          ),
          children: [
            // Camada de Tiles do MapTiler
            TileLayer(
              urlTemplate: _getMapTilerUrl(),
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Camada de Polígonos
            PolygonLayer(polygons: _polygons),
            
            // Camada de Polylines
            PolylineLayer(polylines: _polylines),
            
            // Camada de Marcadores
            MarkerLayer(markers: _markers),
            
            // Atribuição - usando um widget personalizado simples
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: const Text(
                  '© MapTiler © OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10.0),
                ),
              ),
            ),
          ],
        ),
        
        // Controles do mapa
        if (widget.showControls)
          Positioned(
            top: 16.0,
            right: 16.0,
            child: Column(
              children: [
                _NeomorphicButton(
                  icon: Icons.layers,
                  onPressed: _toggleMapType,
                  tooltip: 'Alternar tipo de mapa',
                ),
                const SizedBox(height: 8.0),
                _NeomorphicButton(
                  icon: Icons.my_location,
                  onPressed: _centerOnCurrentLocation,
                  tooltip: 'Minha localização',
                ),
                if (widget.isEditMode && widget.enableDrawing) ...[
                  const SizedBox(height: 8.0),
                  _NeomorphicButton(
                    icon: Icons.delete_outline,
                    onPressed: _clearDrawing,
                    tooltip: 'Limpar desenho',
                  ),
                ],
              ],
            ),
          ),
        
        // Indicador de área
        if (widget.isEditMode && widget.enableDrawing && _currentDrawingPoints.length > 2)
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: _AreaIndicator(points: _currentDrawingPoints),
          ),
          
        // Legenda de culturas
        if (!widget.isEditMode && widget.talhoes.isNotEmpty)
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: _CulturaLegend(talhoes: widget.talhoes),
          ),
      ],
    );
  }
}

class _NeomorphicButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  
  const _NeomorphicButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48.0,
        height: 48.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // onTap: onPressed, // onTap não é suportado em Polygon no flutter_map 5.0.0
            borderRadius: BorderRadius.circular(12.0),
            child: Center(
              child: Icon(
                icon,
                color: Colors.black87,
                size: 24.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaIndicator extends StatelessWidget {
  final List<LatLng> points;
  
  const _AreaIndicator({required this.points});
  
  @override
  Widget build(BuildContext context) {
    final double area = _calculateArea();
    final String areaText = area < 10000
        ? '${area.toStringAsFixed(2)} m²'
        : '${(area / 10000).toStringAsFixed(2)} ha';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Área aproximada:',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            areaText,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculateArea() {
    if (points.length < 3) return 0.0;
    
    // Implementação simplificada da fórmula de Gauss para calcular a área de um polígono
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() * 0.5;
    
    // Conversão aproximada para metros quadrados (simplificada)
    // Uma implementação mais precisa usaria a biblioteca geolocator ou similar
    const double metersPerDegreeAtEquator = 111319.9;
    return area * metersPerDegreeAtEquator * metersPerDegreeAtEquator;
  }
}

class _CulturaLegend extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  
  const _CulturaLegend({required this.talhoes});
  
  @override
  Widget build(BuildContext context) {
    final Map<String, Color> culturas = {};
    
    // Extrair culturas únicas
    for (final talhao in talhoes) {
      if (talhao.culturaId != null && talhao.culturaId!.isNotEmpty) {
        culturas[talhao.culturaId!] = _getCulturaColor(talhao.culturaId!);
      }
    }
    
    if (culturas.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Culturas:',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          ...culturas.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: entry.value.withOpacity(0.7),
                    border: Border.all(color: Colors.black45),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  Color _getCulturaColor(String cultura) {
    return CulturaColorsUtils.getColorForName(cultura);
  }
}
