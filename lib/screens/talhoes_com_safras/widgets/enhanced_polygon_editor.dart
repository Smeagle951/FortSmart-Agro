import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'advanced_polygon_controller.dart';

/// Widget FortSmart para edição avançada de polígonos agrícolas
/// Sistema proprietário com funcionalidades únicas do FortSmart Agro
class FortSmartPolygonEditor extends StatefulWidget {
  final AdvancedPolygonController controller;
  final MapController mapController;
  final Function(List<LatLng>) onPointsChanged;
  final Function(double) onAreaChanged;
  final Function(double) onPerimeterChanged;
  final bool isEditing;
  final Color polygonColor;
  final Color vertexColor;
  final Color midpointColor;
  final double vertexSize;
  final double midpointSize;
  final bool showLabels;
  final bool showMeasurements;

  const EnhancedPolygonEditor({
    Key? key,
    required this.controller,
    required this.mapController,
    required this.onPointsChanged,
    required this.onAreaChanged,
    required this.onPerimeterChanged,
    this.isEditing = true,
    this.polygonColor = Colors.green,
    this.vertexColor = Colors.blue,
    this.midpointColor = Colors.grey,
    this.vertexSize = 12.0,
    this.midpointSize = 8.0,
    this.showLabels = true,
    this.showMeasurements = true,
  }) : super(key: key);

  @override
  State<FortSmartPolygonEditor> createState() => _FortSmartPolygonEditorState();
}

class _FortSmartPolygonEditorState extends State<FortSmartPolygonEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    widget.onPointsChanged(widget.controller.vertices);
    widget.onAreaChanged(widget.controller.area);
    widget.onPerimeterChanged(widget.controller.perimeter);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Polígono principal
        if (widget.controller.hasMinimumVertices)
          _buildPolygonLayer(),
        
        // Linhas do polígono
        if (widget.controller.vertices.length >= 2)
          _buildPolylineLayer(),
        
        // Vértices arrastáveis
        if (widget.isEditing)
          ..._buildDraggableVertices(),
        
        // Midpoints clicáveis
        if (widget.isEditing)
          ..._buildClickableMidpoints(),
        
        // Labels e medições
        if (widget.showLabels || widget.showMeasurements)
          ..._buildLabelsAndMeasurements(),
      ],
    );
  }

  /// Constrói a camada do polígono
  Widget _buildPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: widget.controller.vertices,
          color: widget.polygonColor.withOpacity(0.3),
          borderColor: widget.polygonColor,
          borderStrokeWidth: 2.0,
          isFilled: true,
        ),
      ],
    );
  }

  /// Constrói a camada das linhas
  Widget _buildPolylineLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.controller.vertices + [widget.controller.vertices.first],
          color: widget.polygonColor,
          strokeWidth: 2.0,
        ),
      ],
    );
  }

  /// Constrói os vértices arrastáveis
  List<Widget> _buildDraggableVertices() {
    return widget.controller.vertices.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return EnhancedDraggableVertex(
        key: ValueKey('vertex_$index'),
        point: point,
        index: index,
        controller: widget.controller,
        mapController: widget.mapController,
        color: widget.controller.selectedVertexIndex == index 
            ? Colors.red 
            : widget.vertexColor,
        size: widget.vertexSize,
        isSelected: widget.controller.selectedVertexIndex == index,
        showLabel: widget.showLabels,
      );
    }).toList();
  }

  /// Constrói os midpoints clicáveis
  List<Widget> _buildClickableMidpoints() {
    return widget.controller.midpoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return EnhancedClickableMidpoint(
        key: ValueKey('midpoint_$index'),
        point: point,
        index: index,
        controller: widget.controller,
        color: widget.midpointColor,
        size: widget.midpointSize,
      );
    }).toList();
  }

  /// Constrói labels e medições
  List<Widget> _buildLabelsAndMeasurements() {
    final widgets = <Widget>[];
    
    if (widget.showLabels) {
      // Labels dos vértices
      widgets.addAll(
        widget.controller.vertices.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          
          return MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 40,
                height: 20,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      );
    }
    
    if (widget.showMeasurements) {
      // Medições das arestas
      widgets.addAll(_buildEdgeMeasurements());
    }
    
    return widgets;
  }

  /// Constrói as medições das arestas
  List<Widget> _buildEdgeMeasurements() {
    final widgets = <Widget>[];
    
    for (int i = 0; i < widget.controller.vertices.length; i++) {
      final current = widget.controller.vertices[i];
      final next = widget.controller.vertices[(i + 1) % widget.controller.vertices.length];
      final midpoint = widget.controller.midpoints[i];
      
      final distance = GeoMath.calcularDistancia(current, next);
      
      widgets.add(
        MarkerLayer(
          markers: [
            Marker(
              point: midpoint,
              width: 60,
              height: 20,
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${distance.toStringAsFixed(0)}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return widgets;
  }
}

/// Widget aprimorado para vértice arrastável com integração ao MapController
class EnhancedDraggableVertex extends StatefulWidget {
  final LatLng point;
  final int index;
  final AdvancedPolygonController controller;
  final MapController mapController;
  final Color color;
  final double size;
  final bool isSelected;
  final bool showLabel;

  const EnhancedDraggableVertex({
    Key? key,
    required this.point,
    required this.index,
    required this.controller,
    required this.mapController,
    required this.color,
    required this.size,
    required this.isSelected,
    this.showLabel = true,
  }) : super(key: key);

  @override
  State<EnhancedDraggableVertex> createState() => _EnhancedDraggableVertexState();
}

class _EnhancedDraggableVertexState extends State<EnhancedDraggableVertex> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.point,
          width: widget.size * 2,
          height: widget.size * 2,
          builder: (context) => GestureDetector(
            onTap: () => widget.controller.selectVertex(widget.index),
            onLongPress: () => _showVertexOptions(),
            onPanStart: (_) {
              widget.controller.startDraggingVertex(widget.index);
              setState(() => _isDragging = true);
            },
            onPanUpdate: (details) {
              if (_isDragging) {
                _updateVertexPosition(details);
              }
            },
            onPanEnd: (_) {
              widget.controller.endDraggingVertex();
              setState(() => _isDragging = false);
            },
            child: Container(
              width: widget.size * 2,
              height: widget.size * 2,
              decoration: BoxDecoration(
                color: widget.isSelected ? Colors.red : widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: widget.size,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Atualiza a posição do vértice durante o arraste
  void _updateVertexPosition(DragUpdateDetails details) {
    // Converter offset para coordenadas geográficas usando o MapController
    final map = widget.mapController.map;
    if (map != null) {
      final newPoint = map.pointToLatLng(
        map.latLngToScreenPoint(widget.point) + details.delta,
      );
      widget.controller.updateDraggingVertex(widget.index, newPoint);
    }
  }

  /// Mostra opções do vértice
  void _showVertexOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vértice ${widget.index + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.controller.canRemoveVertex)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover Vértice'),
                onTap: () {
                  Navigator.pop(context);
                  widget.controller.removeVertex(widget.index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_location, color: Colors.blue),
              title: const Text('Editar Posição'),
              onTap: () {
                Navigator.pop(context);
                _showEditPositionDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text('Informações'),
              onTap: () {
                Navigator.pop(context);
                _showVertexInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra diálogo para editar posição
  void _showEditPositionDialog() {
    final point = widget.point;
    final latController = TextEditingController(text: point.latitude.toStringAsFixed(6));
    final lngController = TextEditingController(text: point.longitude.toStringAsFixed(6));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Vértice ${widget.index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final lat = double.parse(latController.text);
                final lng = double.parse(lngController.text);
                widget.controller.moveVertex(widget.index, LatLng(lat, lng));
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coordenadas inválidas'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Mostra informações do vértice
  void _showVertexInfo() {
    final point = widget.point;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vértice ${widget.index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${point.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${point.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            Text('Índice: ${widget.index}'),
            Text('Total de vértices: ${widget.controller.vertices.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

/// Widget aprimorado para midpoint clicável
class EnhancedClickableMidpoint extends StatelessWidget {
  final LatLng point;
  final int index;
  final AdvancedPolygonController controller;
  final Color color;
  final double size;

  const EnhancedClickableMidpoint({
    Key? key,
    required this.point,
    required this.index,
    required this.controller,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: size * 2,
          height: size * 2,
          builder: (context) => GestureDetector(
            onTap: () {
              controller.convertMidpointToVertex(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Novo vértice adicionado na posição ${index + 1}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: size * 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
