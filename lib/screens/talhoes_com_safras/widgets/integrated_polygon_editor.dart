import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'advanced_polygon_controller.dart';
import 'enhanced_polygon_editor.dart';
import '../providers/desenho_provider.dart';

/// Widget integrado que combina o editor legado com o avançado
class IntegratedPolygonEditor extends StatefulWidget {
  final DesenhoProvider desenhoProvider;
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
  final bool showToggleButton;

  const IntegratedPolygonEditor({
    Key? key,
    required this.desenhoProvider,
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
    this.showToggleButton = true,
  }) : super(key: key);

  @override
  State<IntegratedPolygonEditor> createState() => _IntegratedPolygonEditorState();
}

class _IntegratedPolygonEditorState extends State<IntegratedPolygonEditor> {
  @override
  void initState() {
    super.initState();
    widget.desenhoProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    widget.desenhoProvider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Editor baseado no sistema selecionado
        if (widget.desenhoProvider.useAdvancedEditor)
          _buildAdvancedEditor()
        else
          _buildLegacyEditor(),
        
        // Botão de alternância (se habilitado)
        if (widget.showToggleButton)
          _buildToggleButton(),
        
        // Indicador de sistema ativo
        _buildSystemIndicator(),
      ],
    );
  }

  /// Constrói o editor avançado
  Widget _buildAdvancedEditor() {
    return EnhancedPolygonEditor(
      controller: widget.desenhoProvider.advancedController,
      mapController: widget.mapController,
      onPointsChanged: widget.onPointsChanged,
      onAreaChanged: widget.onAreaChanged,
      onPerimeterChanged: widget.onPerimeterChanged,
      isEditing: widget.isEditing,
      polygonColor: widget.polygonColor,
      vertexColor: widget.vertexColor,
      midpointColor: widget.midpointColor,
      vertexSize: widget.vertexSize,
      midpointSize: widget.midpointSize,
      showLabels: widget.showLabels,
      showMeasurements: widget.showMeasurements,
    );
  }

  /// Constrói o editor legado (simplificado)
  Widget _buildLegacyEditor() {
    return Stack(
      children: [
        // Polígono principal
        if (widget.desenhoProvider.pontos.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: widget.desenhoProvider.pontos,
                color: widget.polygonColor.withOpacity(0.3),
                borderColor: widget.polygonColor,
                borderStrokeWidth: 2.0,
                isFilled: true,
              ),
            ],
          ),
        
        // Linhas do polígono
        if (widget.desenhoProvider.pontos.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.desenhoProvider.pontos + [widget.desenhoProvider.pontos.first],
                color: widget.polygonColor,
                strokeWidth: 2.0,
              ),
            ],
          ),
        
        // Vértices simples (não arrastáveis)
        if (widget.isEditing)
          ..._buildSimpleVertices(),
      ],
    );
  }

  /// Constrói vértices simples para o editor legado
  List<Widget> _buildSimpleVertices() {
    return widget.desenhoProvider.pontos.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return MarkerLayer(
        markers: [
          Marker(
            point: point,
            width: widget.vertexSize * 2,
            height: widget.vertexSize * 2,
            builder: (context) => GestureDetector(
              onTap: () => _showLegacyVertexOptions(index),
              child: Container(
                width: widget.vertexSize * 2,
                height: widget.vertexSize * 2,
                decoration: BoxDecoration(
                  color: widget.vertexColor,
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
                  size: widget.vertexSize,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Constrói o botão de alternância
  Widget _buildToggleButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: () {
          widget.desenhoProvider.toggleAdvancedEditor();
          _showToggleMessage();
        },
        backgroundColor: widget.desenhoProvider.useAdvancedEditor 
            ? Colors.green 
            : Colors.orange,
        child: Icon(
          widget.desenhoProvider.useAdvancedEditor 
              ? Icons.auto_awesome 
              : Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Constrói o indicador de sistema ativo
  Widget _buildSystemIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.desenhoProvider.useAdvancedEditor 
              ? Colors.green.withOpacity(0.9)
              : Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.desenhoProvider.useAdvancedEditor 
                  ? Icons.auto_awesome 
                  : Icons.edit,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              widget.desenhoProvider.useAdvancedEditor 
                  ? 'Editor Avançado'
                  : 'Editor Básico',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra opções para vértice do editor legado
  void _showLegacyVertexOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vértice ${index + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.green),
              title: const Text('Usar Editor Avançado'),
              subtitle: const Text('Ativar vértices arrastáveis e midpoints'),
              onTap: () {
                Navigator.pop(context);
                widget.desenhoProvider.toggleAdvancedEditor();
                _showToggleMessage();
              },
            ),
            if (widget.desenhoProvider.pontos.length > 3)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover Vértice'),
                onTap: () {
                  Navigator.pop(context);
                  widget.desenhoProvider.removerPonto(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Informações'),
              onTap: () {
                Navigator.pop(context);
                _showVertexInfo(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra informações do vértice
  void _showVertexInfo(int index) {
    final point = widget.desenhoProvider.pontos[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vértice ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${point.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${point.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            Text('Índice: ${index}'),
            Text('Total de vértices: ${widget.desenhoProvider.pontos.length}'),
            const SizedBox(height: 8),
            Text('Área: ${widget.desenhoProvider.areaFormatada}'),
            Text('Perímetro: ${widget.desenhoProvider.perimetroFormatado}'),
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

  /// Mostra mensagem de alternância
  void _showToggleMessage() {
    final message = widget.desenhoProvider.useAdvancedEditor 
        ? 'Editor Avançado ativado! Agora você pode arrastar vértices e usar midpoints.'
        : 'Editor Básico ativado. Use o botão de alternância para voltar ao modo avançado.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: widget.desenhoProvider.useAdvancedEditor 
            ? Colors.green 
            : Colors.orange,
      ),
    );
  }
}

/// Widget de demonstração das funcionalidades
class PolygonEditorDemo extends StatefulWidget {
  const PolygonEditorDemo({Key? key}) : super(key: key);

  @override
  State<PolygonEditorDemo> createState() => _PolygonEditorDemoState();
}

class _PolygonEditorDemoState extends State<PolygonEditorDemo> {
  late DesenhoProvider _desenhoProvider;
  late MapController _mapController;
  List<LatLng> _currentPoints = [];
  double _currentArea = 0.0;
  double _currentPerimeter = 0.0;

  @override
  void initState() {
    super.initState();
    _desenhoProvider = DesenhoProvider();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _desenhoProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Polígonos - Demo'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-23.5505, -46.6333),
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                _desenhoProvider.adicionarPontoAvancado(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fortsmart.agro',
              ),
              // Editor integrado
              IntegratedPolygonEditor(
                desenhoProvider: _desenhoProvider,
                mapController: _mapController,
                onPointsChanged: (points) {
                  setState(() {
                    _currentPoints = points;
                  });
                },
                onAreaChanged: (area) {
                  setState(() {
                    _currentArea = area;
                  });
                },
                onPerimeterChanged: (perimeter) {
                  setState(() {
                    _currentPerimeter = perimeter;
                  });
                },
                isEditing: true,
                showToggleButton: true,
                showLabels: true,
                showMeasurements: true,
              ),
            ],
          ),
          
          // Painel de informações
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Métricas do Polígono',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCard('Área', '${_currentArea.toStringAsFixed(2)} ha'),
                      _buildMetricCard('Perímetro', '${(_currentPerimeter / 1000).toStringAsFixed(2)} km'),
                      _buildMetricCard('Vértices', '${_currentPoints.length}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistema: ${_desenhoProvider.useAdvancedEditor ? "Avançado" : "Básico"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _desenhoProvider.useAdvancedEditor ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
