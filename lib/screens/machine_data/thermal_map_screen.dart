import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/agricultural_machine_data_processor.dart';
import '../../widgets/thermal_map_painter.dart';
import '../../utils/logger.dart';

/// Tela principal do mapa térmico de dados de máquinas agrícolas
class ThermalMapScreen extends StatefulWidget {
  final MachineWorkData machineData;

  const ThermalMapScreen({
    Key? key,
    required this.machineData,
  }) : super(key: key);

  @override
  State<ThermalMapScreen> createState() => _ThermalMapScreenState();
}

class _ThermalMapScreenState extends State<ThermalMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;
  String _selectedMetric = 'rate';
  bool _showGrid = true;
  bool _showCompass = true;
  bool _showLegend = true;
  bool _showStatistics = true;
  
  // Controles de zoom e pan
  Offset? _lastPanPosition;
  double _lastZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            if (_showStatistics) _buildHeaderCard(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildMapArea(),
                  ),
                  if (_showLegend) 
                    SizedBox(
                      width: 300,
                      child: _buildLegendPanel(),
                    ),
                ],
              ),
            ),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  /// Constrói AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Mapa Térmico - ${widget.machineData.machineName}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.fullscreen),
          onPressed: _toggleFullscreen,
          tooltip: 'Tela cheia',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareMap,
          tooltip: 'Compartilhar',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportMap,
          tooltip: 'Exportar',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset_view',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Resetar Visualização'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'toggle_grid',
              child: ListTile(
                leading: Icon(Icons.grid_on),
                title: Text('Alternar Grid'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'toggle_compass',
              child: ListTile(
                leading: Icon(Icons.navigation),
                title: Text('Alternar Compass'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'toggle_legend',
              child: ListTile(
                leading: Icon(Icons.legend_toggle),
                title: Text('Alternar Legenda'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'toggle_stats',
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('Alternar Estatísticas'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói card de cabeçalho com estatísticas
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.machineData.machineName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.machineData.applicationType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDate(widget.machineData.workDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Área Total',
                      '${widget.machineData.totalArea.toStringAsFixed(2)} ha',
                      Icons.crop_square,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Volume Total',
                      '${widget.machineData.totalVolume.toStringAsFixed(1)} L',
                      Icons.water_drop,
                      Colors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Taxa Média',
                      '${widget.machineData.averageRate.toStringAsFixed(1)} kg/ha',
                      Icons.science,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Velocidade Média',
                      '${widget.machineData.averageSpeed.toStringAsFixed(1)} km/h',
                      Icons.speed,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói card de estatística
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói área do mapa
  Widget _buildMapArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: CustomPaint(
            painter: ThermalMapPainter(
              machineData: widget.machineData,
              zoom: _zoom,
              panOffset: _panOffset,
              canvasSize: const Size(400, 400),
              showGrid: _showGrid,
              showCompass: _showCompass,
              selectedMetric: _selectedMetric,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  /// Constrói painel de legenda
  Widget _buildLegendPanel() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.legend_toggle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Legenda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showLegend = false),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Seletor de métrica
              _buildMetricSelector(),
              const SizedBox(height: 16),
              
              // Faixas de valores
              Expanded(
                child: ListView.builder(
                  itemCount: widget.machineData.valueRanges.length,
                  itemBuilder: (context, index) {
                    final range = widget.machineData.valueRanges[index];
                    return _buildLegendItem(range, index);
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Estatísticas da legenda
              _buildLegendStatistics(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói seletor de métrica
  Widget _buildMetricSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métrica:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricButton('Taxa', 'rate', Icons.science),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricButton('Velocidade', 'speed', Icons.speed),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricButton('Volume', 'volume', Icons.water_drop),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói botão de métrica
  Widget _buildMetricButton(String label, String value, IconData icon) {
    final isSelected = _selectedMetric == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMetric = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item da legenda
  Widget _buildLegendItem(ValueRange range, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: range.color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${range.minValue.toStringAsFixed(1)} - ${range.maxValue.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${range.area.toStringAsFixed(1)} ha (${range.percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${range.pointCount} pts',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói estatísticas da legenda
  Widget _buildLegendStatistics() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total de pontos: ${widget.machineData.points.length}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Área total: ${widget.machineData.totalArea.toStringAsFixed(2)} ha',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Faixas de valores: ${widget.machineData.valueRanges.length}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Constrói painel de controles
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Controles de zoom
          _buildControlButton(
            Icons.zoom_in,
            'Zoom In',
            () => _zoomIn(),
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            Icons.zoom_out,
            'Zoom Out',
            () => _zoomOut(),
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            Icons.center_focus_strong,
            'Centralizar',
            () => _resetView(),
          ),
          const Spacer(),
          
          // Informações de zoom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              'Zoom: ${(_zoom * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói botão de controle
  Widget _buildControlButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // Métodos de controle de zoom e pan
  void _onPanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition != null) {
      setState(() {
        _panOffset += details.localPosition - _lastPanPosition!;
        _lastPanPosition = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoom = (_lastZoom * details.scale).clamp(0.5, 5.0);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastZoom = _zoom;
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom * 1.2).clamp(0.5, 5.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom / 1.2).clamp(0.5, 5.0);
    });
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _panOffset = Offset.zero;
    });
  }

  // Métodos de ação
  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset_view':
        _resetView();
        break;
      case 'toggle_grid':
        setState(() => _showGrid = !_showGrid);
        break;
      case 'toggle_compass':
        setState(() => _showCompass = !_showCompass);
        break;
      case 'toggle_legend':
        setState(() => _showLegend = !_showLegend);
        break;
      case 'toggle_stats':
        setState(() => _showStatistics = !_showStatistics);
        break;
    }
  }

  void _toggleFullscreen() {
    // Implementar tela cheia
    HapticFeedback.lightImpact();
  }

  void _shareMap() {
    // Implementar compartilhamento
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportMap() {
    // Implementar exportação
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de exportação em desenvolvimento'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
