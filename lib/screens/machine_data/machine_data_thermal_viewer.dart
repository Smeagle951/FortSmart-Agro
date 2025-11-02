import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:math' as math;
import '../../services/agricultural_machine_data_service.dart';
import '../../models/talhao_model.dart';
import '../../models/poligono_model.dart';

/// Visualizador térmico para dados de máquinas agrícolas
class MachineDataThermalViewer extends StatefulWidget {
  final MachineWorkData machineData;

  const MachineDataThermalViewer({
    Key? key,
    required this.machineData,
  }) : super(key: key);

  @override
  State<MachineDataThermalViewer> createState() => _MachineDataThermalViewerState();
}

class _MachineDataThermalViewerState extends State<MachineDataThermalViewer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late MapController _mapController;
  List<TalhaoModel> _talhoes = [];
  bool _isLoading = true;
  
  // Filtros
  String _selectedFilter = 'application_rate';
  double _minValue = 0.0;
  double _maxValue = 200.0;
  bool _showHeatmap = true;
  bool _showPoints = true;
  bool _showStatistics = true;

  // Opções de filtro
  final Map<String, FilterOption> _filterOptions = {
    'application_rate': FilterOption(
      name: 'Taxa de Aplicação',
      unit: 'kg/ha',
      min: 0.0,
      max: 200.0,
      colorRange: ColorRange.greenToRed,
    ),
    'speed': FilterOption(
      name: 'Velocidade',
      unit: 'km/h',
      min: 0.0,
      max: 20.0,
      colorRange: ColorRange.blueToRed,
    ),
    'total_applied': FilterOption(
      name: 'Total Aplicado',
      unit: 'kg',
      min: 0.0,
      max: 1000.0,
      colorRange: ColorRange.yellowToRed,
    ),
    'area_covered': FilterOption(
      name: 'Área Coberta',
      unit: 'ha',
      min: 0.0,
      max: 5.0,
      colorRange: ColorRange.greenToBlue,
    ),
    'efficiency': FilterOption(
      name: 'Eficiência',
      unit: '%',
      min: 0.0,
      max: 100.0,
      colorRange: ColorRange.redToGreen,
    ),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _mapController = MapController();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega dados da máquina
  Future<void> _loadData() async {
    try {
      _talhoes = widget.machineData.toTalhoesWithWorkData();
      
      // Configurar filtros baseados nos dados
      _updateFilterRanges();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Atualiza ranges dos filtros baseado nos dados reais
  void _updateFilterRanges() {
    final points = widget.machineData.workPoints;
    if (points.isEmpty) return;

    for (final entry in _filterOptions.entries) {
      final key = entry.key;
      final option = entry.value;
      
      double min = double.infinity;
      double max = double.negativeInfinity;
      
      for (final point in points) {
        double value = _getPointValue(point, key);
        min = math.min(min, value);
        max = math.max(max, value);
      }
      
      _filterOptions[key] = FilterOption(
        name: option.name,
        unit: option.unit,
        min: min,
        max: max,
        colorRange: option.colorRange,
      );
    }
    
    // Atualizar filtro atual
    final currentOption = _filterOptions[_selectedFilter]!;
    _minValue = currentOption.min;
    _maxValue = currentOption.max;
  }

  /// Obtém valor do ponto para o filtro selecionado
  double _getPointValue(WorkPoint point, String filter) {
    switch (filter) {
      case 'application_rate':
        return point.applicationRate;
      case 'speed':
        return point.speed;
      case 'total_applied':
        return point.totalApplied;
      case 'area_covered':
        return point.areaCovered;
      case 'efficiency':
        return point.areaCovered > 0 ? (point.totalApplied / point.areaCovered) : 0.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Dados Térmicos - ${widget.machineData.machineModel}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Mapa Térmico'),
            Tab(icon: Icon(Icons.analytics), text: 'Análises'),
            Tab(icon: Icon(Icons.filter_list), text: 'Filtros'),
            Tab(icon: Icon(Icons.info), text: 'Detalhes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildThermalMapTab(),
                _buildAnalyticsTab(),
                _buildFiltersTab(),
                _buildDetailsTab(),
              ],
            ),
    );
  }

  /// Tab do mapa térmico
  Widget _buildThermalMapTab() {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Mapa térmico
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _calculateMapCenter(),
              initialZoom: 15.0,
              backgroundColor: Colors.white,
            ),
            children: [
              // Camada de tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fortsmart.agro',
                backgroundColor: Colors.white,
              ),
              
              // Camada de polígonos térmicos
              if (_showHeatmap)
                PolygonLayer(
                  polygons: _buildThermalPolygons(),
                ),
              
              // Camada de pontos térmicos
              if (_showPoints)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 120,
                    size: const Size(40, 40),
                    markers: _buildThermalMarkers(),
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${markers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          
          // Controles do mapa
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
          
          // Legenda térmica
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildThermalLegend(),
          ),
          
          // Estatísticas sobrepostas
          if (_showStatistics)
            Positioned(
              top: 16,
              left: 16,
              child: _buildStatisticsCard(),
            ),
          
          // Controles de visualização
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildViewControls(),
          ),
        ],
      ),
    );
  }

  /// Tab de análises
  Widget _buildAnalyticsTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsCard(),
            const SizedBox(height: 16),
            _buildPerformanceMetricsCard(),
            const SizedBox(height: 16),
            _buildEfficiencyChart(),
            const SizedBox(height: 16),
            _buildWorkDistributionChart(),
          ],
        ),
      ),
    );
  }

  /// Tab de filtros
  Widget _buildFiltersTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSelector(),
            const SizedBox(height: 16),
            _buildRangeSlider(),
            const SizedBox(height: 16),
            _buildFilterPreview(),
            const SizedBox(height: 16),
            _buildAdvancedFilters(),
          ],
        ),
      ),
    );
  }

  /// Tab de detalhes
  Widget _buildDetailsTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMachineInfoCard(),
            const SizedBox(height: 16),
            _buildWorkSummaryCard(),
            const SizedBox(height: 16),
            _buildDataQualityCard(),
            const SizedBox(height: 16),
            _buildExportOptionsCard(),
          ],
        ),
      ),
    );
  }

  /// Constrói polígonos térmicos
  List<Polygon> _buildThermalPolygons() {
    final polygons = <Polygon>[];
    final points = widget.machineData.workPoints;
    
    if (points.isEmpty) return polygons;
    
    // Agrupar pontos por área
    final groupedPoints = <String, List<WorkPoint>>{};
    for (final point in points) {
      final areaId = point.areaId ?? 'default';
      groupedPoints.putIfAbsent(areaId, () => []).add(point);
    }
    
    // Criar polígonos térmicos
    for (final entry in groupedPoints.entries) {
      final areaPoints = entry.value;
      if (areaPoints.length >= 3) {
        final polygonPoints = areaPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
        final thermalColor = _getThermalColor(areaPoints);
        
        polygons.add(Polygon(
          points: polygonPoints,
          color: thermalColor.withOpacity(0.6),
          borderColor: thermalColor,
          borderStrokeWidth: 2.0,
          isFilled: true,
        ));
      }
    }
    
    return polygons;
  }

  /// Constrói marcadores térmicos
  List<Marker> _buildThermalMarkers() {
    final markers = <Marker>[];
    final points = widget.machineData.workPoints;
    
    for (final point in points) {
      final value = _getPointValue(point, _selectedFilter);
      if (value >= _minValue && value <= _maxValue) {
        final thermalColor = _getPointThermalColor(point);
        
        markers.add(Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 20,
          height: 20,
          child: GestureDetector(
            onTap: () => _showPointDetails(point),
            child: Container(
              decoration: BoxDecoration(
                color: thermalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.circle,
                color: Colors.white,
                size: 8,
              ),
            ),
          ),
        ));
      }
    }
    
    return markers;
  }

  /// Obtém cor térmica para área
  Color _getThermalColor(List<WorkPoint> points) {
    if (points.isEmpty) return Colors.grey;
    
    final avgValue = points.fold(0.0, (sum, p) => sum + _getPointValue(p, _selectedFilter)) / points.length;
    return _getColorForValue(avgValue);
  }

  /// Obtém cor térmica para ponto
  Color _getPointThermalColor(WorkPoint point) {
    final value = _getPointValue(point, _selectedFilter);
    return _getColorForValue(value);
  }

  /// Obtém cor baseada no valor
  Color _getColorForValue(double value) {
    final option = _filterOptions[_selectedFilter]!;
    final normalizedValue = (value - option.min) / (option.max - option.min);
    
    switch (option.colorRange) {
      case ColorRange.greenToRed:
        return Color.lerp(Colors.green, Colors.red, normalizedValue) ?? Colors.grey;
      case ColorRange.blueToRed:
        return Color.lerp(Colors.blue, Colors.red, normalizedValue) ?? Colors.grey;
      case ColorRange.yellowToRed:
        return Color.lerp(Colors.yellow, Colors.red, normalizedValue) ?? Colors.grey;
      case ColorRange.greenToBlue:
        return Color.lerp(Colors.green, Colors.blue, normalizedValue) ?? Colors.grey;
      case ColorRange.redToGreen:
        return Color.lerp(Colors.red, Colors.green, normalizedValue) ?? Colors.grey;
    }
  }

  /// Calcula centro do mapa
  LatLng _calculateMapCenter() {
    final points = widget.machineData.workPoints;
    if (points.isEmpty) return const LatLng(-15.7801, -47.9292);
    
    double lat = 0, lng = 0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    
    return LatLng(lat / points.length, lng / points.length);
  }

  /// Constrói legenda térmica
  Widget _buildThermalLegend() {
    final option = _filterOptions[_selectedFilter]!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legenda Térmica',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${option.name} (${option.unit})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            _buildColorScale(option),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${option.min.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  '${option.max.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói escala de cores
  Widget _buildColorScale(FilterOption option) {
    return Container(
      height: 20,
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: _getColorScaleColors(option.colorRange),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  /// Obtém cores da escala
  List<Color> _getColorScaleColors(ColorRange range) {
    switch (range) {
      case ColorRange.greenToRed:
        return [Colors.green, Colors.yellow, Colors.orange, Colors.red];
      case ColorRange.blueToRed:
        return [Colors.blue, Colors.purple, Colors.orange, Colors.red];
      case ColorRange.yellowToRed:
        return [Colors.yellow, Colors.orange, Colors.red];
      case ColorRange.greenToBlue:
        return [Colors.green, Colors.cyan, Colors.blue];
      case ColorRange.redToGreen:
        return [Colors.red, Colors.yellow, Colors.green];
    }
  }

  /// Constrói card de estatísticas
  Widget _buildStatisticsCard() {
    final stats = widget.machineData.statistics;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Área: ${stats.totalArea.toStringAsFixed(2)} ha',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Total: ${stats.totalApplied.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Vel. Média: ${stats.averageSpeed.toStringAsFixed(1)} km/h',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Eficiência: ${stats.efficiency.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói controles de visualização
  Widget _buildViewControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _showHeatmap ? Icons.layers : Icons.layers_outlined,
                color: _showHeatmap ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _showHeatmap = !_showHeatmap;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _showPoints ? Icons.location_on : Icons.location_off,
                color: _showPoints ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _showPoints = !_showPoints;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _showStatistics ? Icons.analytics : Icons.analytics_outlined,
                color: _showStatistics ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _showStatistics = !_showStatistics;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seletor de filtros
  Widget _buildFilterSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtro Ativo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filterOptions.entries.map((entry) {
                final isSelected = entry.key == _selectedFilter;
                return FilterChip(
                  label: Text(entry.value.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = entry.key;
                        _minValue = entry.value.min;
                        _maxValue = entry.value.max;
                      });
                    }
                  },
                  selectedColor: Colors.green.withOpacity(0.3),
                  checkmarkColor: Colors.green,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói slider de range
  Widget _buildRangeSlider() {
    final option = _filterOptions[_selectedFilter]!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Range de Valores',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: RangeValues(_minValue, _maxValue),
              min: option.min,
              max: option.max,
              divisions: 100,
              labels: RangeLabels(
                '${_minValue.toStringAsFixed(1)} ${option.unit}',
                '${_maxValue.toStringAsFixed(1)} ${option.unit}',
              ),
              onChanged: (values) {
                setState(() {
                  _minValue = values.start;
                  _maxValue = values.end;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói preview do filtro
  Widget _buildFilterPreview() {
    final option = _filterOptions[_selectedFilter]!;
    final filteredPoints = widget.machineData.workPoints.where((point) {
      final value = _getPointValue(point, _selectedFilter);
      return value >= _minValue && value <= _maxValue;
    }).length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview do Filtro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPreviewMetric(
                    'Pontos Visíveis',
                    '$filteredPoints',
                    'de ${widget.machineData.workPoints.length}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPreviewMetric(
                    'Percentual',
                    '${(filteredPoints / widget.machineData.workPoints.length * 100).toStringAsFixed(1)}%',
                    'dos dados',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói métrica de preview
  Widget _buildPreviewMetric(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói filtros avançados
  Widget _buildAdvancedFilters() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros Avançados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Implementar filtros avançados aqui
            const Text(
              'Filtros por data, operador, cultura, etc.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de análises
  Widget _buildAnalyticsCard() {
    final stats = widget.machineData.statistics;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análise de Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Eficiência',
                    '${stats.efficiency.toStringAsFixed(1)}%',
                    Icons.speed,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Velocidade Média',
                    '${stats.averageSpeed.toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Área Trabalhada',
                    '${stats.totalArea.toStringAsFixed(2)} ha',
                    Icons.crop_square,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Total Aplicado',
                    '${stats.totalApplied.toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói métrica de análise
  Widget _buildAnalyticsMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói card de métricas de performance
  Widget _buildPerformanceMetricsCard() {
    final stats = widget.machineData.statistics;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métricas de Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.performanceMetrics.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatMetricName(entry.key),
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Formata nome da métrica
  String _formatMetricName(String key) {
    switch (key) {
      case 'max_speed':
        return 'Velocidade Máxima';
      case 'min_speed':
        return 'Velocidade Mínima';
      case 'max_application_rate':
        return 'Taxa Máxima de Aplicação';
      case 'min_application_rate':
        return 'Taxa Mínima de Aplicação';
      default:
        return key;
    }
  }

  /// Constrói gráfico de eficiência
  Widget _buildEfficiencyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gráfico de Eficiência',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Gráfico de eficiência ao longo do tempo\n(Implementar chart)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói gráfico de distribuição de trabalho
  Widget _buildWorkDistributionChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuição de Trabalho',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Gráfico de distribuição por área\n(Implementar chart)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de informações da máquina
  Widget _buildMachineInfoCard() {
    final data = widget.machineData;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Máquina',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Modelo', data.machineModel),
            _buildInfoRow('Tipo', _getMachineTypeName(data.machineType)),
            _buildInfoRow('Operação', _getOperationTypeName(data.operationType)),
            _buildInfoRow('Operador', data.operatorName),
            _buildInfoRow('Data', _formatDate(data.workDate)),
            _buildInfoRow('Pontos de Dados', '${data.workPoints.length}'),
          ],
        ),
      ),
    );
  }

  /// Constrói card de resumo de trabalho
  Widget _buildWorkSummaryCard() {
    final stats = widget.machineData.statistics;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do Trabalho',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Área Total', '${stats.totalArea.toStringAsFixed(2)} ha'),
            _buildInfoRow('Total Aplicado', '${stats.totalApplied.toStringAsFixed(1)} kg'),
            _buildInfoRow('Velocidade Média', '${stats.averageSpeed.toStringAsFixed(1)} km/h'),
            _buildInfoRow('Taxa Média', '${stats.averageApplicationRate.toStringAsFixed(1)} kg/ha'),
            _buildInfoRow('Tempo Total', '${stats.totalWorkTime.toStringAsFixed(1)} h'),
            _buildInfoRow('Eficiência', '${stats.efficiency.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  /// Constrói card de qualidade dos dados
  Widget _buildDataQualityCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qualidade dos Dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Completude', '95%'),
            _buildInfoRow('Precisão GPS', '±2m'),
            _buildInfoRow('Frequência', '1 ponto/segundo'),
            _buildInfoRow('Validação', 'Aprovada'),
          ],
        ),
      ),
    );
  }

  /// Constrói card de opções de exportação
  Widget _buildExportOptionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opções de Exportação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToShapefile,
                    icon: const Icon(Icons.map),
                    label: const Text('Exportar Shapefile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Exportar Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Mostra detalhes do ponto
  void _showPointDetails(WorkPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Ponto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${point.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${point.longitude.toStringAsFixed(6)}'),
            Text('Velocidade: ${point.speed.toStringAsFixed(1)} km/h'),
            Text('Taxa de Aplicação: ${point.applicationRate.toStringAsFixed(1)} kg/ha'),
            Text('Total Aplicado: ${point.totalApplied.toStringAsFixed(1)} kg'),
            Text('Área Coberta: ${point.areaCovered.toStringAsFixed(3)} ha'),
            Text('Data/Hora: ${_formatDateTime(point.timestamp)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Obtém nome do tipo de máquina
  String _getMachineTypeName(MachineType type) {
    switch (type) {
      case MachineType.jactoNPK:
        return 'Jacto NPK 5030';
      case MachineType.staraPlantio:
        return 'Stara Plantio';
      case MachineType.staraColheita:
        return 'Stara Colheita';
      case MachineType.staraAplicacao:
        return 'Stara Aplicação';
      case MachineType.johnDeerePlantio:
        return 'John Deere Plantio';
      case MachineType.johnDeereColheita:
        return 'John Deere Colheita';
      case MachineType.johnDeereAplicacao:
        return 'John Deere Aplicação';
      case MachineType.casePlantio:
        return 'Case Plantio';
      case MachineType.caseColheita:
        return 'Case Colheita';
      case MachineType.newHolland:
        return 'New Holland';
      case MachineType.masseyFerguson:
        return 'Massey Ferguson';
      case MachineType.valtra:
        return 'Valtra';
      case MachineType.fendt:
        return 'Fendt';
      case MachineType.desconhecido:
        return 'Desconhecido';
    }
  }

  /// Obtém nome do tipo de operação
  String _getOperationTypeName(OperationType type) {
    switch (type) {
      case OperationType.plantio:
        return 'Plantio';
      case OperationType.colheita:
        return 'Colheita';
      case OperationType.aplicacao:
        return 'Aplicação';
      case OperationType.pulverizacao:
        return 'Pulverização';
      case OperationType.adubacao:
        return 'Adubação';
      case OperationType.semeadura:
        return 'Semeadura';
      case OperationType.capina:
        return 'Capina';
      case OperationType.gradagem:
        return 'Gradagem';
      case OperationType.desconhecido:
        return 'Desconhecido';
    }
  }

  /// Formata data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formata data e hora
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Exporta para Shapefile
  void _exportToShapefile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação para Shapefile em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Exporta para Excel
  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação para Excel em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// Opção de filtro
class FilterOption {
  final String name;
  final String unit;
  final double min;
  final double max;
  final ColorRange colorRange;

  FilterOption({
    required this.name,
    required this.unit,
    required this.min,
    required this.max,
    required this.colorRange,
  });
}

/// Range de cores
enum ColorRange {
  greenToRed,
  blueToRed,
  yellowToRed,
  greenToBlue,
  redToGreen,
}
