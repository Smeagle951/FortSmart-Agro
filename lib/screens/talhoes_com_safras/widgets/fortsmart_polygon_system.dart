import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'advanced_polygon_controller.dart';

/// Sistema proprietário FortSmart para edição de polígonos agrícolas
/// Funcionalidades únicas e diferenciadas do FortSmart Agro
class FortSmartPolygonSystem extends StatefulWidget {
  final AdvancedPolygonController controller;
  final MapController mapController;
  final Function(List<LatLng>) onPointsChanged;
  final Function(double) onAreaChanged;
  final Function(double) onPerimeterChanged;
  final bool isEditing;
  final Color polygonColor;
  final Color vertexColor;
  final Color smartPointColor;
  final double vertexSize;
  final double smartPointSize;
  final bool showSmartLabels;
  final bool showAgroMetrics;

  const FortSmartPolygonSystem({
    Key? key,
    required this.controller,
    required this.mapController,
    required this.onPointsChanged,
    required this.onAreaChanged,
    required this.onPerimeterChanged,
    this.isEditing = true,
    this.polygonColor = Colors.green,
    this.vertexColor = Colors.blue,
    this.smartPointColor = Colors.orange, // Cor única FortSmart
    this.vertexSize = 14.0,
    this.smartPointSize = 10.0,
    this.showSmartLabels = true,
    this.showAgroMetrics = true,
  }) : super(key: key);

  @override
  State<FortSmartPolygonSystem> createState() => _FortSmartPolygonSystemState();
}

class _FortSmartPolygonSystemState extends State<FortSmartPolygonSystem> {
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
        // Polígono principal com estilo FortSmart
        if (widget.controller.hasMinimumVertices)
          _buildFortSmartPolygon(),
        
        // Linhas do polígono com gradiente
        if (widget.controller.vertices.length >= 2)
          _buildFortSmartPolylines(),
        
        // Vértices inteligentes FortSmart
        if (widget.isEditing)
          ..._buildFortSmartVertices(),
        
        // Pontos inteligentes (nossa versão única dos midpoints)
        if (widget.isEditing)
          ..._buildFortSmartPoints(),
        
        // Labels e métricas agrícolas
        if (widget.showSmartLabels || widget.showAgroMetrics)
          ..._buildFortSmartLabels(),
      ],
    );
  }

  /// Constrói polígono com estilo único FortSmart
  Widget _buildFortSmartPolygon() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: widget.controller.vertices,
          color: widget.polygonColor.withOpacity(0.25), // Transparência única
          borderColor: widget.polygonColor,
          borderStrokeWidth: 3.0, // Mais espesso que o padrão
          isFilled: true,
        ),
      ],
    );
  }

  /// Constrói linhas com estilo FortSmart
  Widget _buildFortSmartPolylines() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.controller.vertices + [widget.controller.vertices.first],
          color: widget.polygonColor,
          strokeWidth: 3.0, // Linha mais espessa
          pattern: [10, 5], // Padrão tracejado único
        ),
      ],
    );
  }

  /// Constrói vértices inteligentes FortSmart
  List<Widget> _buildFortSmartVertices() {
    return widget.controller.vertices.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return FortSmartVertex(
        key: ValueKey('fortsmart_vertex_$index'),
        point: point,
        index: index,
        controller: widget.controller,
        mapController: widget.mapController,
        color: widget.controller.selectedVertexIndex == index 
            ? Colors.red 
            : widget.vertexColor,
        size: widget.vertexSize,
        isSelected: widget.controller.selectedVertexIndex == index,
        showLabel: widget.showSmartLabels,
      );
    }).toList();
  }

  /// Constrói pontos inteligentes FortSmart (nossa versão única)
  List<Widget> _buildFortSmartPoints() {
    return widget.controller.midpoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return FortSmartIntelligentPoint(
        key: ValueKey('fortsmart_point_$index'),
        point: point,
        index: index,
        controller: widget.controller,
        color: widget.smartPointColor,
        size: widget.smartPointSize,
      );
    }).toList();
  }

  /// Constrói labels e métricas agrícolas FortSmart
  List<Widget> _buildFortSmartLabels() {
    final widgets = <Widget>[];
    
    if (widget.showSmartLabels) {
      // Labels inteligentes dos vértices
      widgets.addAll(
        widget.controller.vertices.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          
          return MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 50,
                height: 25,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    'P${index + 1}', // Formato FortSmart: P1, P2, P3...
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
    
    if (widget.showAgroMetrics) {
      // Métricas agrícolas inteligentes
      widgets.addAll(_buildFortSmartAgroMetrics());
    }
    
    return widgets;
  }

  /// Constrói métricas agrícolas inteligentes
  List<Widget> _buildFortSmartAgroMetrics() {
    final widgets = <Widget>[];
    
    for (int i = 0; i < widget.controller.vertices.length; i++) {
      final current = widget.controller.vertices[i];
      final next = widget.controller.vertices[(i + 1) % widget.controller.vertices.length];
      final midpoint = widget.controller.midpoints[i];
      
      final distance = GeoMath.calcularDistancia(current, next);
      
      // Formato único FortSmart para distâncias
      String distanceText;
      if (distance < 1000) {
        distanceText = '${distance.toStringAsFixed(0)}m';
      } else {
        distanceText = '${(distance / 1000).toStringAsFixed(1)}km';
      }
      
      widgets.add(
        MarkerLayer(
          markers: [
            Marker(
              point: midpoint,
              width: 70,
              height: 25,
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.smartPointColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  distanceText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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

/// Vértice inteligente FortSmart com funcionalidades únicas
class FortSmartVertex extends StatefulWidget {
  final LatLng point;
  final int index;
  final AdvancedPolygonController controller;
  final MapController mapController;
  final Color color;
  final double size;
  final bool isSelected;
  final bool showLabel;

  const FortSmartVertex({
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
  State<FortSmartVertex> createState() => _FortSmartVertexState();
}

class _FortSmartVertexState extends State<FortSmartVertex> 
    with TickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.point,
          width: widget.size * 2.5,
          height: widget.size * 2.5,
          builder: (context) => GestureDetector(
            onTap: () {
              widget.controller.selectVertex(widget.index);
              _pulseController.forward().then((_) => _pulseController.reverse());
            },
            onLongPress: () => _showFortSmartVertexOptions(),
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
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isSelected ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: widget.size * 2.5,
                    height: widget.size * 2.5,
                    decoration: BoxDecoration(
                      color: widget.isSelected ? Colors.red : widget.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3.0, // Borda mais espessa
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.agriculture, // Ícone agrícola único
                      color: Colors.white,
                      size: widget.size,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Atualiza posição do vértice durante arraste
  void _updateVertexPosition(DragUpdateDetails details) {
    final map = widget.mapController.map;
    if (map != null) {
      final newPoint = map.pointToLatLng(
        map.latLngToScreenPoint(widget.point) + details.delta,
      );
      widget.controller.updateDraggingVertex(widget.index, newPoint);
    }
  }

  /// Mostra opções FortSmart do vértice
  void _showFortSmartVertexOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header FortSmart
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Vértice P${widget.index + 1} - FortSmart',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Opções FortSmart
            if (widget.controller.canRemoveVertex)
              _buildFortSmartOption(
                icon: Icons.delete_forever,
                title: 'Remover Vértice',
                subtitle: 'Remover este ponto do polígono',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  widget.controller.removeVertex(widget.index);
                },
              ),
            
            _buildFortSmartOption(
              icon: Icons.edit_location_alt,
              title: 'Editar Coordenadas',
              subtitle: 'Ajustar posição manualmente',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _showFortSmartEditDialog();
              },
            ),
            
            _buildFortSmartOption(
              icon: Icons.analytics,
              title: 'Métricas Agrícolas',
              subtitle: 'Ver informações detalhadas',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showFortSmartMetrics();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói opção FortSmart
  Widget _buildFortSmartOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  /// Mostra diálogo de edição FortSmart
  void _showFortSmartEditDialog() {
    final point = widget.point;
    final latController = TextEditingController(text: point.latitude.toStringAsFixed(6));
    final lngController = TextEditingController(text: point.longitude.toStringAsFixed(6));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.agriculture, color: Colors.green),
            const SizedBox(width: 8),
            Text('Editar P${widget.index + 1} - FortSmart'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
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
          ElevatedButton.icon(
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
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra métricas FortSmart
  void _showFortSmartMetrics() {
    final point = widget.point;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Métricas P${widget.index + 1}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow('Latitude', '${point.latitude.toStringAsFixed(6)}°'),
            _buildMetricRow('Longitude', '${point.longitude.toStringAsFixed(6)}°'),
            const Divider(),
            _buildMetricRow('Índice', '${widget.index}'),
            _buildMetricRow('Total de Vértices', '${widget.controller.vertices.length}'),
            const Divider(),
            _buildMetricRow('Área Total', '${widget.controller.area.toStringAsFixed(2)} ha'),
            _buildMetricRow('Perímetro Total', '${(widget.controller.perimeter / 1000).toStringAsFixed(2)} km'),
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

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Ponto inteligente FortSmart (nossa versão única dos midpoints)
class FortSmartIntelligentPoint extends StatelessWidget {
  final LatLng point;
  final int index;
  final AdvancedPolygonController controller;
  final Color color;
  final double size;

  const FortSmartIntelligentPoint({
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
          width: size * 2.5,
          height: size * 2.5,
          builder: (context) => GestureDetector(
            onTap: () {
              controller.convertMidpointToVertex(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.agriculture, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Novo vértice P${index + 1} adicionado - FortSmart'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: size * 2.5,
              height: size * 2.5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
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
                Icons.add_circle, // Ícone único FortSmart
                color: Colors.white,
                size: size * 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
