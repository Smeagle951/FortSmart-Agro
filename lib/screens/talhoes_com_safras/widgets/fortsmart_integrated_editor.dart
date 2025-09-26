import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'fortsmart_polygon_system.dart';
import '../providers/desenho_provider.dart';

/// Editor integrado FortSmart - Sistema proprietário único
/// Combina funcionalidades agrícolas avançadas com interface diferenciada
class FortSmartIntegratedEditor extends StatefulWidget {
  final DesenhoProvider desenhoProvider;
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
  final bool showFortSmartToggle;

  const FortSmartIntegratedEditor({
    Key? key,
    required this.desenhoProvider,
    required this.mapController,
    required this.onPointsChanged,
    required this.onAreaChanged,
    required this.onPerimeterChanged,
    this.isEditing = true,
    this.polygonColor = Colors.green,
    this.vertexColor = Colors.blue,
    this.smartPointColor = Colors.orange,
    this.vertexSize = 14.0,
    this.smartPointSize = 10.0,
    this.showSmartLabels = true,
    this.showAgroMetrics = true,
    this.showFortSmartToggle = true,
  }) : super(key: key);

  @override
  State<FortSmartIntegratedEditor> createState() => _FortSmartIntegratedEditorState();
}

class _FortSmartIntegratedEditorState extends State<FortSmartIntegratedEditor> {
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
        if (widget.desenhoProvider.useFortSmartEditor)
          _buildFortSmartSystem()
        else
          _buildLegacySystem(),
        
        // Botão de alternância FortSmart
        if (widget.showFortSmartToggle)
          _buildFortSmartToggleButton(),
        
        // Indicador de sistema FortSmart
        _buildFortSmartIndicator(),
        
        // Painel de métricas agrícolas
        if (widget.desenhoProvider.useFortSmartEditor)
          _buildFortSmartMetricsPanel(),
      ],
    );
  }

  /// Constrói o sistema FortSmart
  Widget _buildFortSmartSystem() {
    return FortSmartPolygonSystem(
      controller: widget.desenhoProvider.fortSmartController,
      mapController: widget.mapController,
      onPointsChanged: widget.onPointsChanged,
      onAreaChanged: widget.onAreaChanged,
      onPerimeterChanged: widget.onPerimeterChanged,
      isEditing: widget.isEditing,
      polygonColor: widget.polygonColor,
      vertexColor: widget.vertexColor,
      smartPointColor: widget.smartPointColor,
      vertexSize: widget.vertexSize,
      smartPointSize: widget.smartPointSize,
      showSmartLabels: widget.showSmartLabels,
      showAgroMetrics: widget.showAgroMetrics,
    );
  }

  /// Constrói o sistema legado (simplificado)
  Widget _buildLegacySystem() {
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
        
        // Vértices simples
        if (widget.isEditing)
          ..._buildSimpleVertices(),
      ],
    );
  }

  /// Constrói vértices simples para o sistema legado
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

  /// Constrói o botão de alternância FortSmart
  Widget _buildFortSmartToggleButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: () {
          widget.desenhoProvider.toggleFortSmartEditor();
          _showFortSmartToggleMessage();
        },
        backgroundColor: widget.desenhoProvider.useFortSmartEditor 
            ? Colors.green 
            : Colors.orange,
        child: Icon(
          widget.desenhoProvider.useFortSmartEditor 
              ? Icons.agriculture 
              : Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Constrói o indicador FortSmart
  Widget _buildFortSmartIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.desenhoProvider.useFortSmartEditor 
              ? Colors.green.withOpacity(0.9)
              : Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.desenhoProvider.useFortSmartEditor 
                  ? Icons.agriculture 
                  : Icons.edit,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              widget.desenhoProvider.useFortSmartEditor 
                  ? 'FortSmart Agro'
                  : 'Editor Básico',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói painel de métricas FortSmart
  Widget _buildFortSmartMetricsPanel() {
    final controller = widget.desenhoProvider.fortSmartController;
    final metrics = controller.calculateAgroMetrics();
    
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header FortSmart
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Métricas Agrícolas FortSmart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Métricas principais
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Área', 
                  '${controller.area.toStringAsFixed(2)} ha',
                  Icons.crop_square,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Perímetro', 
                  '${(controller.perimeter / 1000).toStringAsFixed(2)} km',
                  Icons.straighten,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Vértices', 
                  '${controller.vertices.length}',
                  Icons.location_on,
                  Colors.orange,
                ),
              ],
            ),
            
            // Métricas avançadas (se disponíveis)
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCard(
                    'Largura', 
                    '${(metrics['width_meters'] ?? 0).toStringAsFixed(0)}m',
                    Icons.width_wide,
                    Colors.purple,
                  ),
                  _buildMetricCard(
                    'Altura', 
                    '${(metrics['height_meters'] ?? 0).toStringAsFixed(0)}m',
                    Icons.height,
                    Colors.teal,
                  ),
                  _buildMetricCard(
                    'Complexidade', 
                    '${((metrics['complexity_score'] ?? 0) * 100).toStringAsFixed(0)}%',
                    Icons.analytics,
                    Colors.red,
                  ),
                ],
              ),
            ],
            
            // Status do sistema
            const SizedBox(height: 8),
            Text(
              'Sistema: ${widget.desenhoProvider.useFortSmartEditor ? "FortSmart Agro" : "Básico"}',
              style: TextStyle(
                fontSize: 12,
                color: widget.desenhoProvider.useFortSmartEditor ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de métrica
  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Mostra opções para vértice do sistema legado
  void _showLegacyVertexOptions(int index) {
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
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Vértice ${index + 1} - Editor Básico',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Opção para ativar FortSmart
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.agriculture, color: Colors.green, size: 20),
              ),
              title: const Text(
                'Ativar FortSmart Agro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Vértices arrastáveis e métricas agrícolas'),
              onTap: () {
                Navigator.pop(context);
                widget.desenhoProvider.toggleFortSmartEditor();
                _showFortSmartToggleMessage();
              },
            ),
            
            // Outras opções
            if (widget.desenhoProvider.pontos.length > 3)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text('Remover Vértice'),
                subtitle: const Text('Remover este ponto do polígono'),
                onTap: () {
                  Navigator.pop(context);
                  widget.desenhoProvider.removerPonto(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Mostra mensagem de alternância FortSmart
  void _showFortSmartToggleMessage() {
    final message = widget.desenhoProvider.useFortSmartEditor 
        ? 'FortSmart Agro ativado! Vértices arrastáveis e métricas agrícolas disponíveis.'
        : 'Editor Básico ativado. Use o botão FortSmart para recursos avançados.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              widget.desenhoProvider.useFortSmartEditor 
                  ? Icons.agriculture 
                  : Icons.edit,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: widget.desenhoProvider.useFortSmartEditor 
            ? Colors.green 
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
