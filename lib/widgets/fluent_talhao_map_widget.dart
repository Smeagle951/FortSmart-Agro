import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../services/fluent_polygon_editor_service.dart';
import 'fluent_polygon_editor_controls.dart';

/// Widget de mapa para talhões com edição fluida integrada
/// Combina funcionalidades existentes com sistema de edição avançada
class FluentTalhaoMapWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final TalhaoModel? selectedTalhao;
  final List<LatLng> drawingPoints;
  final Color drawingColor;
  final bool enableDrawing;
  final bool enableFluentEditing;
  final Function(LatLng)? onTap;
  final Function(List<LatLng>)? onPolygonCompleted;
  final Function(TalhaoModel)? onTalhaoTap;
  final Function(TalhaoModel)? onTalhaoUpdated;
  final MapController? mapController;
  final String? mapTileUrl;
  final Widget? floatingActionButton;
  final List<Widget>? additionalLayers;
  final MapOptions? mapOptions;
  
  const FluentTalhaoMapWidget({
    Key? key,
    this.talhoes = const [],
    this.selectedTalhao,
    this.drawingPoints = const [],
    this.drawingColor = Colors.blue,
    this.enableDrawing = false,
    this.enableFluentEditing = false,
    this.onTap,
    this.onPolygonCompleted,
    this.onTalhaoTap,
    this.onTalhaoUpdated,
    this.mapController,
    this.mapTileUrl,
    this.floatingActionButton,
    this.additionalLayers,
    this.mapOptions,
  }) : super(key: key);
  
  @override
  State<FluentTalhaoMapWidget> createState() => _FluentTalhaoMapWidgetState();
}

class _FluentTalhaoMapWidgetState extends State<FluentTalhaoMapWidget> {
  late MapController _mapController;
  late FluentPolygonEditorService _editorService;
  bool _isFluentEditing = false;
  TalhaoModel? _editingTalhao;
  
  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _setupEditorService();
  }
  
  void _setupEditorService() {
    _editorService = FluentPolygonEditorService();
    
    _editorService.onPolygonChanged = (newPoints) {
      if (_editingTalhao != null) {
        _updateTalhaoPolygon(_editingTalhao!, newPoints);
      }
    };
    
    _editorService.onPointMoved = (index, newPosition) {
      _showSnackBar('Ponto ${index + 1} movido');
    };
    
    _editorService.onPointAdded = (index, newPosition) {
      _showSnackBar('Novo ponto adicionado');
    };
    
    _editorService.onPointRemoved = (index) {
      _showSnackBar('Ponto removido');
    };
    
    _editorService.onStatusChanged = (message) {
      // Status é mostrado nos controles
    };
  }
  
  void _updateTalhaoPolygon(TalhaoModel talhao, List<LatLng> newPoints) {
    // Converter LatLng para o formato do modelo
    final updatedPoligonos = [
      newPoints.map((point) => PoligonoPoint(
        latitude: point.latitude,
        longitude: point.longitude,
      )).toList()
    ];
    
    // Criar talhão atualizado
    final updatedTalhao = talhao.copyWith(
      poligonos: updatedPoligonos,
    );
    
    // Notificar callback
    widget.onTalhaoUpdated?.call(updatedTalhao);
    
    // Atualizar estado local
    setState(() {
      _editingTalhao = updatedTalhao;
    });
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
  
  void _startFluentEditing(TalhaoModel talhao) {
    if (talhao.poligonos.isNotEmpty && talhao.poligonos.first.isNotEmpty) {
      setState(() {
        _editingTalhao = talhao;
        _isFluentEditing = true;
      });
      
      _editorService.enableEditing();
      
      // Centralizar mapa no talhão
      final firstPoint = talhao.poligonos.first.first;
      _mapController.move(
        LatLng(firstPoint.latitude, firstPoint.longitude),
        _mapController.camera.zoom,
      );
    }
  }
  
  void _stopFluentEditing() {
    setState(() {
      _isFluentEditing = false;
      _editingTalhao = null;
    });
    
    _editorService.disableEditing();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa principal
        FlutterMap(
          mapController: _mapController,
          options: widget.mapOptions ?? MapOptions(
            initialCenter: LatLng(-15.7801, -47.9292), // Brasília
            initialZoom: 15.0,
            interactionOptions: InteractionOptions(
              flags: _isFluentEditing 
                  ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
            ),
            onTap: (tapPosition, point) {
              if (_isFluentEditing && _editingTalhao != null) {
                final polygonPoints = _editingTalhao!.poligonos.first
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList();
                _editorService.handleMapTap(point, polygonPoints, _mapController);
              } else {
                widget.onTap?.call(point);
              }
            },
          ),
          children: [
            // Camada de tiles
            TileLayer(
              urlTemplate: widget.mapTileUrl ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Camada de polígonos para talhões
            PolygonLayer(
              polygons: _buildTalhaoPolygons(),
            ),
            
            // Camada de polígono para desenho atual
            if (widget.drawingPoints.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: widget.drawingPoints,
                    color: widget.drawingColor.withOpacity(0.3),
                    borderColor: widget.drawingColor,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
            
            // Camada de marcadores para pontos de desenho
            if (widget.drawingPoints.isNotEmpty)
              MarkerLayer(
                markers: widget.drawingPoints.map((point) => Marker(
                  point: point,
                  width: 10,
                  height: 10,
                  builder: (context) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.drawingColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )).toList(),
              ),
            
            // Camada de pontos editáveis (modo fluido)
            if (_isFluentEditing && _editingTalhao != null)
              MarkerLayer(
                markers: _editorService.buildPolygonPoints(
                  _editingTalhao!.poligonos.first
                      .map((p) => LatLng(p.latitude, p.longitude))
                      .toList(),
                  _mapController,
                ),
              ),
            
            // Camadas adicionais
            if (widget.additionalLayers != null)
              ...widget.additionalLayers!,
          ],
        ),
        
        // Controles de edição fluida
        if (widget.enableFluentEditing && _isFluentEditing)
          Positioned(
            top: 16,
            right: 16,
            child: FluentPolygonEditorControls(
              editorService: _editorService,
              onEditingStateChanged: () {
                setState(() {});
              },
              showAdvancedControls: true,
            ),
          ),
        
        // Botão para ativar edição fluida
        if (widget.enableFluentEditing && !_isFluentEditing && widget.selectedTalhao != null)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () => _startFluentEditing(widget.selectedTalhao!),
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        
        // Botão para parar edição fluida
        if (_isFluentEditing)
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton.small(
              onPressed: _stopFluentEditing,
              backgroundColor: Colors.red,
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        
        // Status da edição
        if (_isFluentEditing)
          Positioned(
            bottom: 16,
            left: 16,
            child: _editorService.buildStatusWidget(),
          ),
        
        // Instruções de uso
        if (_isFluentEditing)
          Positioned(
            top: 80,
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
                        'Editando: ${_editingTalhao?.name ?? "Talhão"}',
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
        
        // FloatingActionButton personalizado
        if (widget.floatingActionButton != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: widget.floatingActionButton!,
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
  
  List<Polygon> _buildTalhaoPolygons() {
    final polygons = <Polygon>[];
    
    for (final talhao in widget.talhoes) {
      final isSelected = widget.selectedTalhao?.id == talhao.id;
      final isEditing = _editingTalhao?.id == talhao.id;
      
      if (talhao.poligonos.isNotEmpty && talhao.poligonos.first.isNotEmpty) {
        final points = talhao.poligonos.first
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        
        Color polygonColor;
        Color borderColor;
        double borderWidth;
        
        if (isEditing) {
          // Talhão sendo editado
          polygonColor = Colors.blue.withOpacity(0.4);
          borderColor = Colors.blue;
          borderWidth = 3.0;
        } else if (isSelected) {
          // Talhão selecionado
          polygonColor = Colors.green.withOpacity(0.4);
          borderColor = Colors.green;
          borderWidth = 3.0;
        } else {
          // Talhão normal
          polygonColor = Colors.green.withOpacity(0.3);
          borderColor = Colors.green.withOpacity(0.7);
          borderWidth = 2.0;
        }
        
        polygons.add(
          Polygon(
            points: points,
            color: polygonColor,
            borderColor: borderColor,
            borderStrokeWidth: borderWidth,
          ),
        );
      }
    }
    
    return polygons;
  }
  
  @override
  void dispose() {
    _editorService.disableEditing();
    super.dispose();
  }
}

/// Extensão para TalhaoModel para facilitar cópia com novos polígonos
extension TalhaoModelCopyWith on TalhaoModel {
  TalhaoModel copyWith({
    String? id,
    String? name,
    String? fazendaId,
    List<List<PoligonoPoint>>? poligonos,
    List<SafraModel>? safras,
    String? culturaId,
    String? culturaName,
    double? area,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TalhaoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fazendaId: fazendaId ?? this.fazendaId,
      poligonos: poligonos ?? this.poligonos,
      safras: safras ?? this.safras,
      culturaId: culturaId ?? this.culturaId,
      culturaName: culturaName ?? this.culturaName,
      area: area ?? this.area,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
