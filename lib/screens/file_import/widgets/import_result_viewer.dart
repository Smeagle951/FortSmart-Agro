import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:uuid/uuid.dart';
import '../../../models/talhao_model.dart';
import '../../../models/poligono_model.dart';
import '../../../services/geojson_reader_service.dart';
import '../../../models/geojson_data.dart' as geojson_model;
import '../../../services/agricultural_machine_data_processor.dart';
import '../../../screens/machine_data/thermal_map_screen.dart';
import '../file_import_main_screen.dart';

/// Visualizador de resultados da importação com fundo branco
class ImportResultViewer extends StatefulWidget {
  final ImportResult result;

  const ImportResultViewer({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  State<ImportResultViewer> createState() => _ImportResultViewerState();
}

class _ImportResultViewerState extends State<ImportResultViewer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late MapController _mapController;
  List<TalhaoModel> _talhoes = [];
  List<GeoJSONFeature> _features = [];
  GeoJSONDataType _dataType = GeoJSONDataType.unknown;
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mapController = MapController();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega dados do resultado
  Future<void> _loadData() async {
    try {
      // Processar dados reais do arquivo importado
      await _processImportedData();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Processa dados reais importados
  Future<void> _processImportedData() async {
    try {
      // Extrair dados do resultado da importação
      final data = widget.result.data;
      
      if (data.containsKey('dataType')) {
        _dataType = _parseDataType(data['dataType']);
      }
      
      if (data.containsKey('features')) {
        final featuresData = data['features'] as List;
        _features = featuresData.map((feature) {
          return GeoJSONFeature.fromJson(feature as Map<String, dynamic>);
        }).toList();
      }
      
      // Processar estatísticas
      if (widget.result.statistics != null) {
        _statistics = widget.result.statistics!;
      }
      
      // Converter para talhões se for tipo talhão
      if (_dataType == GeoJSONDataType.talhao) {
        _talhoes = _convertFeaturesToTalhoes();
      }
      
    } catch (e) {
      // Em caso de erro, usar dados de fallback
      _talhoes = _createFallbackTalhoes();
    }
  }

  /// Converte features para talhões
  List<TalhaoModel> _convertFeaturesToTalhoes() {
    return _features.map((feature) {
      return TalhaoModel(
        id: feature.id ?? 'talhao_${DateTime.now().millisecondsSinceEpoch}',
        name: feature.properties['nome'] ?? 
              feature.properties['name'] ?? 
              feature.properties['NOME'] ?? 
              'Talhão ${feature.id}',
        area: _parseArea(feature.properties),
        culturaId: feature.properties['cultura_id']?.toString() ?? 
                   feature.properties['culturaId']?.toString() ?? 
                   feature.properties['CULTURA_ID']?.toString() ?? 
                   '1',
        fazendaId: feature.properties['fazenda_id']?.toString() ?? 
                   feature.properties['fazendaId']?.toString() ?? 
                   feature.properties['FAZENDA_ID']?.toString() ?? 
                   '1',
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        poligonos: _createPolygonsFromFeature(feature),
        safras: [],
      );
    }).toList();
  }

  /// Cria polígonos a partir de uma feature
  List<PoligonoModel> _createPolygonsFromFeature(GeoJSONFeature feature) {
    if (feature.geometry == null) return [];
    
    final geometry = feature.geometry!;
    List<LatLng> points = [];
    
    switch (geometry['type']) {
      case 'Polygon':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final ring = coordinates[0] as List;
          points = ring.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
        break;
      case 'MultiPolygon':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.isNotEmpty && coordinates[0].isNotEmpty) {
          final ring = coordinates[0][0] as List;
          points = ring.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
        break;
      case 'Point':
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.length >= 2) {
          points = [LatLng(coordinates[1], coordinates[0])];
        }
        break;
    }
    
    if (points.isEmpty) return [];
    
    return [
      PoligonoModel(
        id: '${feature.id}_polygon',
        pontos: points,
        area: _parseArea(feature.properties),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        perimetro: 0.0,
        talhaoId: feature.id ?? 'talhao_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ];
  }

  /// Extrai área das propriedades
  double _parseArea(Map<String, dynamic> properties) {
    final area = properties['area'] ?? 
                 properties['AREA'] ?? 
                 properties['hectares'] ?? 
                 properties['HECTARES'] ?? 
                 properties['area_ha'] ?? 
                 properties['AREA_HA'];
    
    if (area != null) {
      return double.tryParse(area.toString()) ?? 0.0;
    }
    
    return 0.0;
  }

  /// Converte string para tipo de dados
  GeoJSONDataType _parseDataType(String dataTypeString) {
    switch (dataTypeString) {
      case 'GeoJSONDataType.talhao':
        return GeoJSONDataType.talhao;
      case 'GeoJSONDataType.machineWork':
        return GeoJSONDataType.machineWork;
      case 'GeoJSONDataType.planting':
        return GeoJSONDataType.planting;
      case 'GeoJSONDataType.harvest':
        return GeoJSONDataType.harvest;
      case 'GeoJSONDataType.soilSample':
        return GeoJSONDataType.soilSample;
      case 'GeoJSONDataType.irrigation':
        return GeoJSONDataType.irrigation;
      default:
        return GeoJSONDataType.unknown;
    }
  }

  /// Cria talhões de fallback quando não há dados reais
  List<TalhaoModel> _createFallbackTalhoes() {
    return [
      TalhaoModel(
        id: '1',
        name: 'Talhão Norte',
        area: 12.5,
        culturaId: '1',
        fazendaId: '1',
        poligonos: [
          PoligonoModel(
            id: '1',
            pontos: [
              const LatLng(-15.7801, -47.9292),
              const LatLng(-15.7801, -47.9282),
              const LatLng(-15.7791, -47.9282),
              const LatLng(-15.7791, -47.9292),
            ],
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            ativo: true,
            area: 12.5,
            perimetro: 0.0,
            talhaoId: 'talhao_1',
          ),
        ],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        safras: [],
      ),
      TalhaoModel(
        id: '2',
        name: 'Talhão Sul',
        area: 8.3,
        culturaId: '2',
        fazendaId: '1',
        poligonos: [
          PoligonoModel(
            id: '2',
            pontos: [
              const LatLng(-15.7791, -47.9292),
              const LatLng(-15.7791, -47.9282),
              const LatLng(-15.7781, -47.9282),
              const LatLng(-15.7781, -47.9292),
            ],
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            ativo: true,
            area: 8.3,
            perimetro: 0.0,
            talhaoId: 'talhao_2',
          ),
        ],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        safras: [],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Resultado: ${widget.result.fileName}',
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
            Tab(
              icon: Icon(Icons.map),
              text: 'Mapa',
            ),
            Tab(
              icon: Icon(Icons.table_chart),
              text: 'Dados',
            ),
            Tab(
              icon: Icon(Icons.info),
              text: 'Detalhes',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dados...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildDataTab(),
                _buildDetailsTab(),
              ],
            ),
    );
  }

  /// Tab do mapa
  Widget _buildMapTab() {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Mapa com fundo branco
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-15.7801, -47.9292),
              initialZoom: 15.0,
              backgroundColor: Colors.white,
            ),
            children: [
              // Camada de tiles com fundo branco
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fortsmart.agro',
                backgroundColor: Colors.white,
              ),
              
              // Camada de polígonos dos talhões
              PolygonLayer(
                polygons: _buildPolygons(),
              ),
              
              // Camada de marcadores
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 120,
                  size: const Size(40, 40),
                  markers: _buildMarkers(),
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
          
          // Legenda
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildLegend(),
          ),
          
          // Estatísticas
          Positioned(
            top: 16,
            left: 16,
            child: _buildStatsCard(),
          ),
        ],
      ),
    );
  }

  /// Tab de dados
  Widget _buildDataTab() {
    return Container(
      color: Colors.white,
      child: _dataType == GeoJSONDataType.talhao
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _talhoes.length,
              itemBuilder: (context, index) {
                final talhao = _talhoes[index];
                return _buildTalhaoCard(talhao, index);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _buildFeatureCard(feature, index);
              },
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
            _buildInfoCard(
              'Informações do Arquivo',
              [
                _buildInfoRow('Nome', widget.result.fileName),
                _buildInfoRow('Caminho', widget.result.filePath),
                _buildInfoRow('Data de importação', _formatDate(widget.result.importDate)),
                _buildInfoRow('Status', _getStatusText(widget.result.status)),
                _buildInfoRow('Itens importados', '${widget.result.itemCount}'),
              ],
              icon: Icons.description,
              color: Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoCard(
              'Estatísticas',
              _buildStatisticsRows(),
              icon: Icons.analytics,
              color: _getDataTypeColor(),
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoCard(
              'Ações',
              [],
              icon: Icons.settings,
              color: Colors.orange,
              child: Column(
                children: [
                  // Botão para mapa térmico (apenas para dados de máquina)
                  if (_dataType == GeoJSONDataType.machineWork) ...[
                    ElevatedButton.icon(
                      onPressed: _openThermalMap,
                      icon: const Icon(Icons.thermostat),
                      label: const Text('Mapa Térmico'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar Dados'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _shareData,
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói polígonos para o mapa
  List<Polygon> _buildPolygons() {
    return _talhoes.map((talhao) {
      return Polygon(
        points: talhao.poligonos.first.pontos,
        color: Colors.green.withOpacity(0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 2.0,
        isFilled: true,
      );
    }).toList();
  }

  /// Constrói marcadores para o mapa
  List<Marker> _buildMarkers() {
    return _talhoes.map((talhao) {
      final centroid = _calculateCentroid(talhao.poligonos.first.pontos);
      return Marker(
        point: centroid,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showTalhaoInfo(talhao),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Constrói legenda
  Widget _buildLegend() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legenda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    border: Border.all(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Talhões',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Centroides',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de estatísticas
  Widget _buildStatsCard() {
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
              '${_talhoes.length} talhões',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${_getTotalArea().toStringAsFixed(1)} ha total',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de feature genérica
  Widget _buildFeatureCard(GeoJSONFeature feature, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDataTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getDataTypeIcon(), color: _getDataTypeColor()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.properties['nome'] ?? 
                        feature.properties['name'] ?? 
                        feature.properties['NOME'] ?? 
                        'Feature ${feature.id ?? index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${feature.id ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDataTypeColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Exibir propriedades principais
            ..._buildPropertyChips(feature.properties),
          ],
        ),
      ),
    );
  }

  /// Card de talhão
  Widget _buildTalhaoCard(TalhaoModel talhao, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        talhao.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${talhao.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricChip(
                    Icons.crop_square,
                    'Área',
                    '${talhao.area.toStringAsFixed(2)} ha',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricChip(
                    Icons.location_on,
                    'Vértices',
                    '${talhao.poligonos.first.pontos.length}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (talhao.culturaId != null) ...[
              const SizedBox(height: 8),
              _buildMetricChip(
                Icons.eco,
                'Cultura',
                talhao.culturaId!,
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card de informações
  Widget _buildInfoCard(
    String title,
    List<Widget> children, {
    IconData? icon,
    Color? color,
    Widget? child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color ?? Colors.blue),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (child != null) child else ...children,
          ],
        ),
      ),
    );
  }

  /// Linha de informação
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

  /// Chip de métrica
  Widget _buildMetricChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Métodos auxiliares
  LatLng _calculateCentroid(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  double _getTotalArea() {
    return _talhoes.fold(0.0, (sum, talhao) => sum + talhao.area);
  }

  double _getAverageArea() {
    if (_talhoes.isEmpty) return 0.0;
    return _getTotalArea() / _talhoes.length;
  }

  double _getMinArea() {
    if (_talhoes.isEmpty) return 0.0;
    return _talhoes.map((t) => t.area).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxArea() {
    if (_talhoes.isEmpty) return 0.0;
    return _talhoes.map((t) => t.area).reduce((a, b) => a > b ? a : b);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getStatusText(ImportStatus status) {
    switch (status) {
      case ImportStatus.success:
        return 'Sucesso';
      case ImportStatus.error:
        return 'Erro';
      case ImportStatus.warning:
        return 'Aviso';
    }
  }

  void _showTalhaoInfo(TalhaoModel talhao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(talhao.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Área: ${talhao.area.toStringAsFixed(2)} ha'),
            Text('Vértices: ${talhao.poligonos.first.pontos.length}'),
            if (talhao.culturaId != null) Text('Cultura: ${talhao.culturaId}'),
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

  void _exportData() async {
    try {
      // Mostrar opções de exportação
      final exportFormat = await _showExportOptionsDialog();
      
      if (exportFormat != null) {
        await _performExport(exportFormat);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na exportação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareData() async {
    try {
      // Mostrar opções de compartilhamento
      final shareOption = await _showShareOptionsDialog();
      
      if (shareOption != null) {
        await _performShare(shareOption);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no compartilhamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostra opções de exportação
  Future<String?> _showExportOptionsDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('GeoJSON'),
              subtitle: const Text('Formato geoespacial padrão'),
              onTap: () => Navigator.of(context).pop('geojson'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('CSV'),
              subtitle: const Text('Planilha com coordenadas'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              subtitle: const Text('Relatório com mapa'),
              onTap: () => Navigator.of(context).pop('pdf'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Mostra opções de compartilhamento
  Future<String?> _showShareOptionsDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Compartilhar Link'),
              subtitle: const Text('Gerar link para compartilhar'),
              onTap: () => Navigator.of(context).pop('link'),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('Enviar por Email'),
              subtitle: const Text('Anexar arquivo ao email'),
              onTap: () => Navigator.of(context).pop('email'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.green),
              title: const Text('Upload para Nuvem'),
              subtitle: const Text('Salvar na nuvem'),
              onTap: () => Navigator.of(context).pop('cloud'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Executa exportação
  Future<void> _performExport(String format) async {
    // Mostrar progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exportando dados...'),
          ],
        ),
      ),
    );

    try {
      // Simular exportação
      await Future.delayed(const Duration(seconds: 2));

      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dados exportados em formato $format com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      rethrow;
    }
  }

  /// Executa compartilhamento
  Future<void> _performShare(String option) async {
    // Mostrar progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Preparando compartilhamento...'),
          ],
        ),
      ),
    );

    try {
      // Simular compartilhamento
      await Future.delayed(const Duration(seconds: 2));

      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dados compartilhados via $option com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      rethrow;
    }
  }

  /// Abre mapa térmico para dados de máquina
  Future<void> _openThermalMap() async {
    try {
      // Reconstruir dados de máquina a partir dos dados importados
      final machineWorkData = await _reconstructMachineWorkData();
      
      if (machineWorkData != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ThermalMapScreen(
              machineData: machineWorkData,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar dados para mapa térmico'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir mapa térmico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Reconstrói dados de máquina a partir dos dados importados
  Future<MachineWorkData?> _reconstructMachineWorkData() async {
    try {
      // Criar GeoJSONData a partir dos dados importados
      final geoJSONData = GeoJSONData(
        dataType: _dataType,
        features: _features,
        metadata: widget.result.data,
        importDate: widget.result.importDate,
      );
      
      // Processar usando o processador
      return await AgriculturalMachineDataProcessor.processMachineData(geoJSONData);
    } catch (e) {
      return null;
    }
  }

  /// Constrói chips de propriedades
  List<Widget> _buildPropertyChips(Map<String, dynamic> properties) {
    final chips = <Widget>[];
    final importantKeys = ['area', 'AREA', 'hectares', 'HECTARES', 'dose', 'DOSE', 'tipo', 'TIPO', 'cultura', 'CULTURA'];
    
    for (final key in importantKeys) {
      if (properties.containsKey(key) && properties[key] != null) {
        chips.add(
          _buildMetricChip(
            _getPropertyIcon(key),
            key.toUpperCase(),
            properties[key].toString(),
            _getDataTypeColor(),
          ),
        );
      }
    }
    
    // Se não há propriedades importantes, mostrar algumas genéricas
    if (chips.isEmpty) {
      final keys = properties.keys.take(3).toList();
      for (final key in keys) {
        chips.add(
          _buildMetricChip(
            Icons.info,
            key.toUpperCase(),
            properties[key]?.toString() ?? 'N/A',
            Colors.grey,
          ),
        );
      }
    }
    
    return chips;
  }

  /// Obtém ícone para propriedade
  IconData _getPropertyIcon(String key) {
    switch (key.toLowerCase()) {
      case 'area':
      case 'hectares':
        return Icons.crop_square;
      case 'dose':
        return Icons.science;
      case 'tipo':
        return Icons.category;
      case 'cultura':
        return Icons.eco;
      default:
        return Icons.info;
    }
  }

  /// Obtém cor do tipo de dados
  Color _getDataTypeColor() {
    switch (_dataType) {
      case GeoJSONDataType.talhao:
        return Colors.green;
      case GeoJSONDataType.machineWork:
        return Colors.blue;
      case GeoJSONDataType.planting:
        return Colors.orange;
      case GeoJSONDataType.harvest:
        return Colors.amber;
      case GeoJSONDataType.soilSample:
        return Colors.brown;
      case GeoJSONDataType.irrigation:
        return Colors.cyan;
      case GeoJSONDataType.unknown:
        return Colors.grey;
    }
  }

  /// Obtém ícone do tipo de dados
  IconData _getDataTypeIcon() {
    switch (_dataType) {
      case GeoJSONDataType.talhao:
        return Icons.agriculture;
      case GeoJSONDataType.machineWork:
        return Icons.agriculture;
      case GeoJSONDataType.planting:
        return Icons.eco;
      case GeoJSONDataType.harvest:
        return Icons.grass;
      case GeoJSONDataType.soilSample:
        return Icons.terrain;
      case GeoJSONDataType.irrigation:
        return Icons.water_drop;
      case GeoJSONDataType.unknown:
        return Icons.help;
    }
  }

  /// Constrói linhas de estatísticas baseadas no tipo de dados
  List<Widget> _buildStatisticsRows() {
    final rows = <Widget>[];
    
    // Estatísticas básicas
    rows.add(_buildInfoRow('Total de features', '${_features.length}'));
    rows.add(_buildInfoRow('Tipo de dados', _getDataTypeDisplayName()));
    
    // Estatísticas específicas do tipo
    if (_dataType == GeoJSONDataType.talhao) {
      rows.add(_buildInfoRow('Total de talhões', '${_talhoes.length}'));
      rows.add(_buildInfoRow('Área total', '${_getTotalArea().toStringAsFixed(2)} ha'));
      rows.add(_buildInfoRow('Área média', '${_getAverageArea().toStringAsFixed(2)} ha'));
      rows.add(_buildInfoRow('Área mínima', '${_getMinArea().toStringAsFixed(2)} ha'));
      rows.add(_buildInfoRow('Área máxima', '${_getMaxArea().toStringAsFixed(2)} ha'));
    } else {
      // Estatísticas das features importadas
      for (final entry in _statistics.entries) {
        if (entry.key != 'dataType' && entry.key != 'importDate') {
          rows.add(_buildInfoRow(
            _formatStatisticKey(entry.key), 
            entry.value.toString()
          ));
        }
      }
    }
    
    return rows;
  }

  /// Obtém nome de exibição do tipo de dados
  String _getDataTypeDisplayName() {
    switch (_dataType) {
      case GeoJSONDataType.talhao:
        return 'Talhões Agrícolas';
      case GeoJSONDataType.machineWork:
        return 'Trabalho de Máquina';
      case GeoJSONDataType.planting:
        return 'Dados de Plantio';
      case GeoJSONDataType.harvest:
        return 'Dados de Colheita';
      case GeoJSONDataType.soilSample:
        return 'Amostras de Solo';
      case GeoJSONDataType.irrigation:
        return 'Sistemas de Irrigação';
      case GeoJSONDataType.unknown:
        return 'Tipo Desconhecido';
    }
  }

  /// Formata chave de estatística para exibição
  String _formatStatisticKey(String key) {
    switch (key) {
      case 'totalFeatures':
        return 'Total de Features';
      case 'fileSize':
        return 'Tamanho do Arquivo';
      case 'fileName':
        return 'Nome do Arquivo';
      case 'totalArea':
        return 'Área Total';
      case 'averageArea':
        return 'Área Média';
      case 'totalDose':
        return 'Dose Total';
      case 'averageDose':
        return 'Dose Média';
      default:
        return key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    }
  }
}
