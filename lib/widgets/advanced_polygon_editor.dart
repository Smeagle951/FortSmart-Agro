import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../utils/geo_calculator.dart';

/// Editor avançado de polígonos com funcionalidades de edição em tempo real
class AdvancedPolygonEditor extends StatefulWidget {
  final List<LatLng> initialPoints;
  final Function(List<LatLng>) onPointsChanged;
  final Function(double) onAreaChanged;
  final Function(double) onPerimeterChanged;
  final Color polygonColor;
  final bool isEditing;
  final VoidCallback? onEditModeChanged;
  
  const AdvancedPolygonEditor({
    super.key,
    required this.initialPoints,
    required this.onPointsChanged,
    required this.onAreaChanged,
    required this.onPerimeterChanged,
    this.polygonColor = Colors.blue,
    this.isEditing = false,
    this.onEditModeChanged,
  });
  
  @override
  State<AdvancedPolygonEditor> createState() => _AdvancedPolygonEditorState();
}

class _AdvancedPolygonEditorState extends State<AdvancedPolygonEditor>
    with TickerProviderStateMixin {
  late List<LatLng> _points;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  int? _selectedPointIndex;
  bool _isDragging = false;
  LatLng? _dragStartPoint;
  LatLng? _originalPoint;
  
  @override
  void initState() {
    super.initState();
    _points = List.from(widget.initialPoints);
    
    // Controllers de animação
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Animações
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Iniciar animações
    _scaleController.forward();
    if (widget.isEditing) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(AdvancedPolygonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.initialPoints != oldWidget.initialPoints) {
      _points = List.from(widget.initialPoints);
      _updateMetrics();
    }
    
    if (widget.isEditing != oldWidget.isEditing) {
      if (widget.isEditing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  void _updateMetrics() {
    if (_points.length >= 3) {
      final area = GeoCalculator.calculateAreaHectares(_points);
      final perimeter = GeoCalculator.calculatePerimeterMeters(_points);
      
      widget.onAreaChanged(area);
      widget.onPerimeterChanged(perimeter);
    }
  }
  
  void _onPointTapped(int index) {
    if (!widget.isEditing) return;
    
    setState(() {
      _selectedPointIndex = index;
    });
    
    // Feedback háptico
    // HapticFeedback.lightImpact();
  }
  
  void _onPointDragStart(int index, DragStartDetails details) {
    if (!widget.isEditing) return;
    
    setState(() {
      _isDragging = true;
      _selectedPointIndex = index;
      _originalPoint = _points[index];
      _dragStartPoint = _points[index];
    });
  }
  
  void _onPointDragUpdate(int index, DragUpdateDetails details) {
    if (!widget.isEditing || !_isDragging) return;
    
    // Converter offset para coordenadas geográficas
    // Esta é uma implementação simplificada - em produção, você precisaria
    // de uma conversão mais precisa baseada na escala do mapa
    final newPoint = _convertOffsetToLatLng(details.globalPosition);
    
    setState(() {
      _points[index] = newPoint;
    });
    
    _updateMetrics();
    widget.onPointsChanged(_points);
  }
  
  void _onPointDragEnd(int index, DragEndDetails details) {
    if (!widget.isEditing || !_isDragging) return;
    
    final currentPoint = _points[index];
    final originalPoint = _originalPoint!;
    
    // Calcular distância entre ponto original e arrastado
    final distance = GeoCalculator.haversineDistance(originalPoint, currentPoint);
    
    if (distance > 10.0) { // Mais de 10 metros - criar novo ponto
      final newPoints = List<LatLng>.from(_points);
      newPoints.insert(index + 1, currentPoint);
      
      setState(() {
        _points = newPoints;
        _selectedPointIndex = index + 1;
      });
      
      _updateMetrics();
      widget.onPointsChanged(_points);
    } else {
      // Apenas mover o ponto existente
      setState(() {
        _points[index] = currentPoint;
      });
      
      _updateMetrics();
      widget.onPointsChanged(_points);
    }
    
    setState(() {
      _isDragging = false;
      _dragStartPoint = null;
      _originalPoint = null;
    });
  }
  
  LatLng _convertOffsetToLatLng(Offset offset) {
    // Implementação simplificada - em produção, você precisaria
    // de uma conversão mais precisa baseada na escala do mapa
    // Por enquanto, retornamos o ponto original
    return _points[_selectedPointIndex!];
  }
  
  void _addPointAt(int index) {
    if (!widget.isEditing) return;
    
    // Calcular ponto médio entre o ponto atual e o próximo
    final currentPoint = _points[index];
    final nextPoint = _points[(index + 1) % _points.length];
    
    final midLat = (currentPoint.latitude + nextPoint.latitude) / 2;
    final midLng = (currentPoint.longitude + nextPoint.longitude) / 2;
    final midPoint = LatLng(midLat, midLng);
    
    setState(() {
      _points.insert(index + 1, midPoint);
    });
    
    _updateMetrics();
    widget.onPointsChanged(_points);
  }
  
  void _removePointAt(int index) {
    if (!widget.isEditing || _points.length <= 3) return;
    
    setState(() {
      _points.removeAt(index);
      if (_selectedPointIndex == index) {
        _selectedPointIndex = null;
      } else if (_selectedPointIndex != null && _selectedPointIndex! > index) {
        _selectedPointIndex = _selectedPointIndex! - 1;
      }
    });
    
    _updateMetrics();
    widget.onPointsChanged(_points);
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Polígono
        if (_points.length >= 3)
          CustomPaint(
            painter: _PolygonPainter(
              points: _points,
              color: widget.polygonColor,
              isEditing: widget.isEditing,
            ),
            size: Size.infinite,
          ),
        
        // Pontos editáveis
        if (widget.isEditing)
          ..._buildEditablePoints(),
        
        // Controles de edição
        if (widget.isEditing)
          _buildEditControls(),
      ],
    );
  }
  
  List<Widget> _buildEditablePoints() {
    return _points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final isSelected = _selectedPointIndex == index;
      
      return Positioned(
        left: point.longitude, // Simplificado - em produção, converter para coordenadas de tela
        top: point.latitude,   // Simplificado - em produção, converter para coordenadas de tela
        child: GestureDetector(
          onTap: () => _onPointTapped(index),
          onPanStart: (details) => _onPointDragStart(index, details),
          onPanUpdate: (details) => _onPointDragUpdate(index, details),
          onPanEnd: (details) => _onPointDragEnd(index, details),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : widget.polygonColor,
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }
  
  Widget _buildEditControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            _buildControlButton(
              icon: Icons.add,
              onPressed: _selectedPointIndex != null 
                  ? () => _addPointAt(_selectedPointIndex!)
                  : null,
              tooltip: 'Adicionar ponto',
            ),
            const SizedBox(height: 8),
            _buildControlButton(
              icon: Icons.remove,
              onPressed: _selectedPointIndex != null 
                  ? () => _removePointAt(_selectedPointIndex!)
                  : null,
              tooltip: 'Remover ponto',
            ),
            const SizedBox(height: 8),
            _buildControlButton(
              icon: Icons.close,
              onPressed: widget.onEditModeChanged,
              tooltip: 'Sair do modo edição',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.blue : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: onPressed != null ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Painter personalizado para o polígono
class _PolygonPainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;
  final bool isEditing;
  
  _PolygonPainter({
    required this.points,
    required this.color,
    required this.isEditing,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;
    
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isEditing ? 3.0 : 2.0;
    
    final path = Path();
    
    // Converter pontos para coordenadas de tela
    // Esta é uma implementação simplificada
    final screenPoints = points.map((point) => Offset(
      point.longitude, // Simplificado
      point.latitude,  // Simplificado
    )).toList();
    
    path.moveTo(screenPoints.first.dx, screenPoints.first.dy);
    
    for (int i = 1; i < screenPoints.length; i++) {
      path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }
    
    path.close();
    
    // Desenhar preenchimento
    canvas.drawPath(path, paint);
    
    // Desenhar borda
    canvas.drawPath(path, borderPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _PolygonPainter &&
        (oldDelegate.points != points ||
         oldDelegate.color != color ||
         oldDelegate.isEditing != isEditing);
  }
}
