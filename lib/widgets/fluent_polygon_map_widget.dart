import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/fluent_polygon_editor_service.dart';
import 'fluent_polygon_editor_controls.dart';

/// Widget de mapa com edição fluida de polígonos integrada
/// Combina o mapa existente com funcionalidades de edição avançada
class FluentPolygonMapWidget extends StatefulWidget {
  final List<LatLng> polygonPoints;
  final Function(List<LatLng>) onPolygonChanged;
  final MapController? mapController;
  final bool enableEditing;
  final bool showControls;
  final bool showQuickControls;
  final Widget? customControls;
  final Map<String, dynamic>? mapOptions;
  
  const FluentPolygonMapWidget({
    Key? key,
    required this.polygonPoints,
    required this.onPolygonChanged,
    this.mapController,
    this.enableEditing = false,
    this.showControls = true,
    this.showQuickControls = true,
    this.customControls,
    this.mapOptions,
  }) : super(key: key);
  
  @override
  State<FluentPolygonMapWidget> createState() => _FluentPolygonMapWidgetState();
}

class _FluentPolygonMapWidgetState extends State<FluentPolygonMapWidget> {
  late FluentPolygonEditorService _editorService;
  late MapController _mapController;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _setupEditorService();
  }
  
  void _setupEditorService() {
    _editorService = FluentPolygonEditorService();
    
    // Configurar callbacks
    _editorService.onPolygonChanged = (newPoints) {
      widget.onPolygonChanged(newPoints);
    };
    
    _editorService.onPointMoved = (index, newPosition) {
      _showSnackBar('Ponto ${index + 1} movido para nova posição');
    };
    
    _editorService.onPointAdded = (index, newPosition) {
      _showSnackBar('Novo ponto adicionado na posição ${index + 1}');
    };
    
    _editorService.onPointRemoved = (index) {
      _showSnackBar('Ponto ${index + 1} removido');
    };
    
    _editorService.onStatusChanged = (message) {
      // Status é mostrado nos controles
    };
    
    // Ativar edição se solicitado
    if (widget.enableEditing) {
      _editorService.enableEditing();
      _isEditing = true;
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _onEditingStateChanged() {
    setState(() {
      _isEditing = _editorService.isEditing;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa principal
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.polygonPoints.isNotEmpty 
                ? widget.polygonPoints.first 
                : LatLng(-15.7801, -47.9292), // Brasília como padrão
            initialZoom: 15.0,
            interactionOptions: InteractionOptions(
              flags: _isEditing 
                  ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
            ),
            onTap: (tapPosition, point) {
              if (_isEditing) {
                _editorService.handleMapTap(point, widget.polygonPoints, _mapController);
              }
            },
            ...?widget.mapOptions,
          ),
          children: [
            // Camada de tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Camada do polígono
            if (widget.polygonPoints.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: widget.polygonPoints,
                    color: _isEditing ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.5),
                    borderColor: _isEditing ? Colors.blue : Colors.blue,
                    borderStrokeWidth: _isEditing ? 3.0 : 2.0,
                    isFilled: true,
                  ),
                ],
              ),
            
            // Camada de pontos editáveis
            if (_isEditing)
              MarkerLayer(
                markers: _editorService.buildPolygonPoints(widget.polygonPoints, _mapController),
              ),
          ],
        ),
        
        // Controles de edição
        if (widget.showControls)
          Positioned(
            top: 16,
            right: 16,
            child: widget.customControls ?? 
              FluentPolygonEditorControls(
                editorService: _editorService,
                onEditingStateChanged: _onEditingStateChanged,
                showAdvancedControls: true,
              ),
          ),
        
        // Controles rápidos
        if (widget.showQuickControls && !widget.showControls)
          Positioned(
            bottom: 16,
            right: 16,
            child: FluentPolygonEditorQuickControls(
              editorService: _editorService,
              onEditingStateChanged: _onEditingStateChanged,
            ),
          ),
        
        // Status da edição
        if (_isEditing)
          Positioned(
            bottom: 16,
            left: 16,
            child: _editorService.buildStatusWidget(),
          ),
        
        // Instruções de uso (apenas quando editando)
        if (_isEditing)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        'Edição Fluida',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  _buildInstruction('🔴 Pontos existentes - arraste para mover'),
                  _buildInstruction('🟠 Handles intermediários - arraste para criar'),
                  _buildInstruction('📱 Tolerância ampla - fácil de tocar'),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildInstruction(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[700],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _editorService.disableEditing();
    super.dispose();
  }
}

/// Widget de demonstração da edição fluida
class FluentPolygonEditorDemo extends StatefulWidget {
  const FluentPolygonEditorDemo({Key? key}) : super(key: key);
  
  @override
  State<FluentPolygonEditorDemo> createState() => _FluentPolygonEditorDemoState();
}

class _FluentPolygonEditorDemoState extends State<FluentPolygonEditorDemo> {
  List<LatLng> _polygonPoints = [
    LatLng(-15.7801, -47.9292),
    LatLng(-15.7801, -47.9282),
    LatLng(-15.7791, -47.9282),
    LatLng(-15.7791, -47.9292),
  ];
  
  void _onPolygonChanged(List<LatLng> newPoints) {
    setState(() {
      _polygonPoints = newPoints;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edição Fluida de Polígonos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FluentPolygonMapWidget(
        polygonPoints: _polygonPoints,
        onPolygonChanged: _onPolygonChanged,
        enableEditing: true,
        showControls: true,
      ),
    );
  }
}
