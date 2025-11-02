import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:ui';
import 'dart:math';

/// Widget para edição de vértices de polígonos
/// Permite mover, remover e inserir vértices
class PolygonVertexEditor extends StatefulWidget {
  final List<LatLng> points;
  final Color polygonColor;
  final Color vertexColor;
  final Color selectedVertexColor;
  final double vertexSize;
  final Function(List<LatLng>) onPointsChanged;
  final Function(double) onAreaChanged;
  final Function(double) onPerimeterChanged;
  final bool showCoordinates;
  final bool showMetrics;

  const PolygonVertexEditor({
    Key? key,
    required this.points,
    required this.onPointsChanged,
    required this.onAreaChanged,
    required this.onPerimeterChanged,
    this.polygonColor = Colors.blue,
    this.vertexColor = Colors.red,
    this.selectedVertexColor = Colors.yellow,
    this.vertexSize = 12.0,
    this.showCoordinates = true,
    this.showMetrics = true,
  }) : super(key: key);

  @override
  State<PolygonVertexEditor> createState() => _PolygonVertexEditorState();
}

class _PolygonVertexEditorState extends State<PolygonVertexEditor> {
  int? _selectedVertexIndex;
  bool _isDragging = false;
  Offset? _dragStartPosition;
  
  @override
  void initState() {
    super.initState();
    _updateMetrics();
  }
  
  @override
  void didUpdateWidget(PolygonVertexEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _updateMetrics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Polígono
        CustomPaint(
          painter: PolygonPainter(
            points: widget.points,
            color: widget.polygonColor,
            isClosed: true,
          ),
          size: Size.infinite,
        ),
        
        // Vértices
        ...widget.points.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return _buildVertex(point, index);
        }),
        
        // Controles de edição
        if (_selectedVertexIndex != null) _buildEditControls(),
        
        // Métricas
        if (widget.showMetrics) _buildMetricsDisplay(),
      ],
    );
  }

  /// Constrói um vértice
  Widget _buildVertex(LatLng point, int index) {
    final isSelected = _selectedVertexIndex == index;
    
    return Positioned(
      left: point.longitude - widget.vertexSize / 2,
      top: point.latitude - widget.vertexSize / 2,
      child: GestureDetector(
        onTap: () => _selectVertex(index),
        onLongPress: () => _showVertexOptions(index),
        onPanStart: (details) => _startDrag(details, index),
        onPanUpdate: (details) => _updateDrag(details),
        onPanEnd: (details) => _endDrag(),
        child: Container(
          width: widget.vertexSize,
          height: widget.vertexSize,
          decoration: BoxDecoration(
            color: isSelected ? widget.selectedVertexColor : widget.vertexColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói controles de edição
  Widget _buildEditControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vértice ${_selectedVertexIndex! + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: _removeVertex,
                  tooltip: 'Remover vértice',
                ),
                const SizedBox(width: 8),
                _buildEditButton(
                  icon: Icons.add,
                  color: Colors.green,
                  onPressed: _insertVertex,
                  tooltip: 'Inserir vértice',
                ),
                const SizedBox(width: 8),
                _buildEditButton(
                  icon: Icons.close,
                  color: Colors.grey,
                  onPressed: _deselectVertex,
                  tooltip: 'Fechar',
                ),
              ],
            ),
            if (widget.showCoordinates) ...[
              const SizedBox(height: 8),
              _buildCoordinateDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói botão de edição
  Widget _buildEditButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  /// Constrói display de coordenadas
  Widget _buildCoordinateDisplay() {
    if (_selectedVertexIndex == null) return const SizedBox.shrink();
    
    final point = widget.points[_selectedVertexIndex!];
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lat: ${point.latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            'Lng: ${point.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Constrói display de métricas
  Widget _buildMetricsDisplay() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Área: ${_formatArea(_calculateArea())}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Perímetro: ${_formatDistance(_calculatePerimeter())}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Vértices: ${widget.points.length}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Seleciona um vértice
  void _selectVertex(int index) {
    setState(() {
      _selectedVertexIndex = index;
    });
  }

  /// Remove seleção do vértice
  void _deselectVertex() {
    setState(() {
      _selectedVertexIndex = null;
    });
  }

  /// Mostra opções do vértice
  void _showVertexOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remover vértice'),
              onTap: () {
                Navigator.pop(context);
                _removeVertex();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('Inserir vértice antes'),
              onTap: () {
                Navigator.pop(context);
                _insertVertex();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Remove vértice selecionado
  void _removeVertex() {
    if (_selectedVertexIndex == null || widget.points.length <= 3) {
      _showSnackBar('Polígono deve ter pelo menos 3 vértices');
      return;
    }

    final newPoints = List<LatLng>.from(widget.points);
    newPoints.removeAt(_selectedVertexIndex!);
    
    widget.onPointsChanged(newPoints);
    _deselectVertex();
    _showSnackBar('Vértice removido');
  }

  /// Insere vértice antes do selecionado
  void _insertVertex() {
    if (_selectedVertexIndex == null) return;

    final newPoints = List<LatLng>.from(widget.points);
    final selectedPoint = newPoints[_selectedVertexIndex!];
    
    // Calcular ponto médio com o próximo vértice
    LatLng newPoint;
    if (_selectedVertexIndex! < newPoints.length - 1) {
      final nextPoint = newPoints[_selectedVertexIndex! + 1];
      newPoint = LatLng(
        (selectedPoint.latitude + nextPoint.latitude) / 2,
        (selectedPoint.longitude + nextPoint.longitude) / 2,
      );
    } else {
      // Se for o último vértice, usar o primeiro
      final firstPoint = newPoints[0];
      newPoint = LatLng(
        (selectedPoint.latitude + firstPoint.latitude) / 2,
        (selectedPoint.longitude + firstPoint.longitude) / 2,
      );
    }
    
    newPoints.insert(_selectedVertexIndex! + 1, newPoint);
    
    widget.onPointsChanged(newPoints);
    _selectVertex(_selectedVertexIndex! + 1);
    _showSnackBar('Vértice inserido');
  }

  /// Inicia arrastar
  void _startDrag(DragStartDetails details, int index) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.localPosition;
      _selectedVertexIndex = index;
    });
  }

  /// Atualiza arrastar
  void _updateDrag(DragUpdateDetails details) {
    if (!_isDragging || _selectedVertexIndex == null) return;

    final newPoints = List<LatLng>.from(widget.points);
    final newPoint = LatLng(
      newPoints[_selectedVertexIndex!].latitude + details.delta.dy,
      newPoints[_selectedVertexIndex!].longitude + details.delta.dx,
    );
    
    newPoints[_selectedVertexIndex!] = newPoint;
    widget.onPointsChanged(newPoints);
  }

  /// Finaliza arrastar
  void _endDrag() {
    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
    });
    _showSnackBar('Vértice movido');
  }

  /// Calcula área
  double _calculateArea() {
    if (widget.points.length < 3) return 0.0;
    return _calculatePolygonArea(widget.points);
  }

  /// Calcula perímetro
  double _calculatePerimeter() {
    if (widget.points.length < 2) return 0.0;
    return _calculatePolygonPerimeter(widget.points);
  }

  /// Atualiza métricas
  void _updateMetrics() {
    final area = _calculateArea();
    final perimeter = _calculatePerimeter();
    
    widget.onAreaChanged(area);
    widget.onPerimeterChanged(perimeter);
  }

  /// Mostra snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Formata distância
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }
  
  /// Formata área
  String _formatArea(double area) {
    if (area < 1) {
      return '${(area * 10000).toStringAsFixed(1)} m²';
    } else {
      return '${area.toStringAsFixed(2)} ha';
    }
  }
  
  /// Calcula área do polígono
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares usando fator de conversão correto
    // 1 grau² ≈ 111 km² na latitude média do Brasil
    const double grauParaHectares = 11100000; // 111 km² = 11.100.000 hectares
    return area * grauParaHectares;
  }
  
  /// Calcula perímetro do polígono
  double _calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      perimeter += _calculateDistance(points[i], points[j]);
    }
    
    return perimeter;
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}

/// Painter para desenhar o polígono
class PolygonPainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;
  final bool isClosed;

  PolygonPainter({
    required this.points,
    required this.color,
    this.isClosed = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Converter coordenadas para pixels (simplificado)
    final pointsInPixels = points.map((point) => Offset(
      (point.longitude + 180) * size.width / 360,
      (90 - point.latitude) * size.height / 180,
    )).toList();
    
    final uiPath = Path();
    
    for (int i = 0; i < pointsInPixels.length; i++) {
      final point = pointsInPixels[i];
      if (i == 0) {
        uiPath.moveTo(point.dx, point.dy);
      } else {
        uiPath.lineTo(point.dx, point.dy);
      }
    }
    
    if (isClosed && pointsInPixels.length > 2) {
      uiPath.close();
    }
    
    canvas.drawPath(uiPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
