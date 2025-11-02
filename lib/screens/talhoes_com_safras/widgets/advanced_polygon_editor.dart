import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../utils/geo_math.dart';

/// Widget para edição avançada de polígonos com vértices arrastáveis e midpoints
class AdvancedPolygonEditor extends StatefulWidget {
  final List<LatLng> points;
  final Function(List<LatLng>) onPointsChanged;
  final Function(double) onAreaChanged;
  final Function(double) onPerimeterChanged;
  final bool isEditing;
  final Color polygonColor;
  final Color vertexColor;
  final Color midpointColor;
  final double vertexSize;
  final double midpointSize;

  const AdvancedPolygonEditor({
    Key? key,
    required this.points,
    required this.onPointsChanged,
    required this.onAreaChanged,
    required this.onPerimeterChanged,
    this.isEditing = true,
    this.polygonColor = Colors.green,
    this.vertexColor = Colors.blue,
    this.midpointColor = Colors.grey,
    this.vertexSize = 12.0,
    this.midpointSize = 8.0,
  }) : super(key: key);

  @override
  State<AdvancedPolygonEditor> createState() => _AdvancedPolygonEditorState();
}

class _AdvancedPolygonEditorState extends State<AdvancedPolygonEditor> {
  List<LatLng> _points = [];
  List<LatLng> _midpoints = [];
  int? _selectedVertexIndex;
  int? _selectedMidpointIndex;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.points);
    _calculateMidpoints();
  }

  @override
  void didUpdateWidget(AdvancedPolygonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _points = List.from(widget.points);
      _calculateMidpoints();
    }
  }

  /// Calcula os pontos intermediários (midpoints) entre os vértices
  void _calculateMidpoints() {
    _midpoints.clear();
    
    if (_points.length < 2) return;
    
    for (int i = 0; i < _points.length; i++) {
      final current = _points[i];
      final next = _points[(i + 1) % _points.length];
      
      // Calcular ponto médio
      final midLat = (current.latitude + next.latitude) / 2;
      final midLng = (current.longitude + next.longitude) / 2;
      
      _midpoints.add(LatLng(midLat, midLng));
    }
  }

  /// Atualiza métricas e notifica mudanças
  void _updateMetrics() {
    if (_points.length >= 3) {
      final area = GeoMath.calcularAreaDesenhoManual(_points);
      final perimeter = GeoMath.calcularPerimetroPoligono(_points);
      
      widget.onAreaChanged(area);
      widget.onPerimeterChanged(perimeter);
    }
    
    widget.onPointsChanged(List.from(_points));
    _calculateMidpoints();
  }

  /// Adiciona um novo vértice na posição especificada
  void _addVertexAt(int index, LatLng position) {
    setState(() {
      _points.insert(index, position);
      _updateMetrics();
    });
  }

  /// Remove um vértice
  void _removeVertex(int index) {
    if (_points.length <= 3) return; // Manter mínimo de 3 pontos
    
    setState(() {
      _points.removeAt(index);
      _updateMetrics();
    });
  }

  /// Move um vértice para nova posição
  void _moveVertex(int index, LatLng newPosition) {
    setState(() {
      _points[index] = newPosition;
      _updateMetrics();
    });
  }

  /// Converte um midpoint em vértice
  void _convertMidpointToVertex(int midpointIndex) {
    if (midpointIndex >= 0 && midpointIndex < _midpoints.length) {
      final midpoint = _midpoints[midpointIndex];
      final vertexIndex = (midpointIndex + 1) % _points.length;
      
      _addVertexAt(vertexIndex, midpoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Polígono principal
        if (_points.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _points,
                color: widget.polygonColor.withOpacity(0.3),
                borderColor: widget.polygonColor,
                borderStrokeWidth: 2.0,
                isFilled: true,
              ),
            ],
          ),
        
        // Linhas do polígono
        if (_points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _points + [_points.first], // Fechar polígono
                color: widget.polygonColor,
                strokeWidth: 2.0,
              ),
            ],
          ),
        
        // Vértices arrastáveis
        if (widget.isEditing)
          ..._buildDraggableVertices(),
        
        // Midpoints clicáveis
        if (widget.isEditing)
          ..._buildClickableMidpoints(),
      ],
    );
  }

  /// Constrói os vértices arrastáveis
  List<Widget> _buildDraggableVertices() {
    return _points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return DraggableVertex(
        key: ValueKey('vertex_$index'),
        point: point,
        color: _selectedVertexIndex == index 
            ? Colors.red 
            : widget.vertexColor,
        size: widget.vertexSize,
        isSelected: _selectedVertexIndex == index,
        onDragStart: () {
          setState(() {
            _selectedVertexIndex = index;
            _isDragging = true;
          });
        },
        onDragUpdate: (newPosition) {
          _moveVertex(index, newPosition);
        },
        onDragEnd: () {
          setState(() {
            _selectedVertexIndex = null;
            _isDragging = false;
          });
        },
        onTap: () {
          setState(() {
            _selectedVertexIndex = _selectedVertexIndex == index ? null : index;
          });
        },
        onLongPress: () {
          _showVertexOptions(index);
        },
      );
    }).toList();
  }

  /// Constrói os midpoints clicáveis
  List<Widget> _buildClickableMidpoints() {
    return _midpoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return ClickableMidpoint(
        key: ValueKey('midpoint_$index'),
        point: point,
        color: widget.midpointColor,
        size: widget.midpointSize,
        onTap: () {
          _convertMidpointToVertex(index);
        },
      );
    }).toList();
  }

  /// Mostra opções para um vértice
  void _showVertexOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opções do Vértice ${index + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_points.length > 3)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover Vértice'),
                onTap: () {
                  Navigator.pop(context);
                  _removeVertex(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_location, color: Colors.blue),
              title: const Text('Editar Posição'),
              onTap: () {
                Navigator.pop(context);
                _showEditPositionDialog(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra diálogo para editar posição do vértice
  void _showEditPositionDialog(int index) {
    final point = _points[index];
    final latController = TextEditingController(text: point.latitude.toStringAsFixed(6));
    final lngController = TextEditingController(text: point.longitude.toStringAsFixed(6));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Vértice ${index + 1}'),
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
                _moveVertex(index, LatLng(lat, lng));
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
}

/// Widget para vértice arrastável
class DraggableVertex extends StatelessWidget {
  final LatLng point;
  final Color color;
  final double size;
  final bool isSelected;
  final VoidCallback onDragStart;
  final Function(LatLng) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DraggableVertex({
    Key? key,
    required this.point,
    required this.color,
    required this.size,
    required this.isSelected,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: size * 2,
          height: size * 2,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            onPanStart: (_) => onDragStart(),
            onPanUpdate: (details) {
              // Converter offset para coordenadas geográficas
              // Esta é uma implementação simplificada
              // Em produção, use um MapController para conversão precisa
              final newPoint = LatLng(
                point.latitude + (details.delta.dy * 0.00001),
                point.longitude + (details.delta.dx * 0.00001),
              );
              onDragUpdate(newPoint);
            },
            onPanEnd: (_) => onDragEnd(),
            child: Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : color,
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
                size: size,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget para midpoint clicável
class ClickableMidpoint extends StatelessWidget {
  final LatLng point;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const ClickableMidpoint({
    Key? key,
    required this.point,
    required this.color,
    required this.size,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: size * 2,
          height: size * 2,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                color: color.withOpacity(0.7),
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
