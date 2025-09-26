import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import '../../services/polygon_database_service.dart';
import '../../services/unified_geo_export_service.dart';
import '../../database/daos/polygon_dao.dart';
import '../../models/talhao_model.dart';

class RelatoriosPoligonosScreen extends StatefulWidget {
  const RelatoriosPoligonosScreen({Key? key}) : super(key: key);

  @override
  State<RelatoriosPoligonosScreen> createState() => _RelatoriosPoligonosScreenState();
}

class _RelatoriosPoligonosScreenState extends State<RelatoriosPoligonosScreen> {
  final PolygonDatabaseService _polygonDatabaseService = PolygonDatabaseService.instance;
  
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _polygons = [];
  String _selectedFilter = 'todos';
  String _selectedExportFormat = 'geojson';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carrega dados dos polígonos
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      await _polygonDatabaseService.initialize();
      final storageService = _polygonDatabaseService.storageService;
      
      if (storageService == null) {
        throw Exception('Serviço de armazenamento não disponível');
      }
      
      // Carregar todos os polígonos
      final allPolygons = await storageService.loadAllPolygons();
      
      setState(() {
        _polygons = allPolygons;
        _isLoading = false;
      });
      
      _calculateStatistics();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao carregar dados: $e');
    }
  }

  /// Calcula estatísticas
  void _calculateStatistics() {
    final filteredPolygons = _getFilteredPolygons();
    
    double totalArea = 0.0;
    double totalPerimeter = 0.0;
    double totalDistance = 0.0;
    int manualCount = 0;
    int gpsCount = 0;
    int importedCount = 0;
    
    for (final polygon in filteredPolygons) {
      totalArea += polygon['areaHa'] as double;
      totalPerimeter += polygon['perimeterM'] as double;
      totalDistance += polygon['distanceM'] as double;
      
      switch (polygon['method']) {
        case 'manual':
          manualCount++;
          break;
        case 'caminhada':
          gpsCount++;
          break;
        case 'importado':
          importedCount++;
          break;
      }
    }
    
    setState(() {
      _statistics = {
        'total_polygons': filteredPolygons.length,
        'total_area_ha': totalArea,
        'total_perimeter_m': totalPerimeter,
        'total_distance_m': totalDistance,
        'manual_count': manualCount,
        'gps_count': gpsCount,
        'imported_count': importedCount,
        'average_area_ha': filteredPolygons.isNotEmpty ? totalArea / filteredPolygons.length : 0.0,
        'average_perimeter_m': filteredPolygons.isNotEmpty ? totalPerimeter / filteredPolygons.length : 0.0,
      };
    });
  }

  /// Obtém polígonos filtrados
  List<Map<String, dynamic>> _getFilteredPolygons() {
    switch (_selectedFilter) {
      case 'manual':
        return _polygons.where((p) => p['method'] == 'manual').toList();
      case 'gps':
        return _polygons.where((p) => p['method'] == 'caminhada').toList();
      case 'importado':
        return _polygons.where((p) => p['method'] == 'importado').toList();
      default:
        return _polygons;
    }
  }

  /// Exporta dados
  Future<void> _exportData() async {
    try {
      final filteredPolygons = _getFilteredPolygons();
      final polygonIds = filteredPolygons.map((p) => p['id'] as int).toList();
      
      if (polygonIds.isEmpty) {
        _showError('Nenhum polígono para exportar');
        return;
      }
      
      final storageService = _polygonDatabaseService.storageService;
      if (storageService == null) {
        _showError('Serviço de armazenamento não disponível');
        return;
      }
      
      final exportService = UnifiedGeoExportService();
      
      // Converter polígonos para TalhaoModel
      final talhoes = await _convertPolygonsToTalhoes(polygonIds);
      
      if (_selectedExportFormat == 'kml') {
        await exportService.exportTalhoesToKML(talhoes);
      } else {
        await exportService.exportTalhoesToGeoJSON(talhoes);
      }
      
      _showSuccess('Dados exportados com sucesso!');
      
    } catch (e) {
      _showError('Erro ao exportar: $e');
    }
  }

  /// Mostra erro
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra sucesso
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Polígonos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros e controles
                _buildControls(),
                
                // Estatísticas gerais
                _buildGeneralStatistics(),
                
                // Gráficos
                Expanded(
                  child: _buildCharts(),
                ),
                
                // Lista de polígonos
                _buildPolygonsList(),
              ],
            ),
    );
  }

  /// Constrói controles
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filtros
          Row(
            children: [
              const Text('Filtrar por: '),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  _calculateStatistics();
                },
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'manual', child: Text('Manual')),
                  DropdownMenuItem(value: 'gps', child: Text('GPS')),
                  DropdownMenuItem(value: 'importado', child: Text('Importado')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Exportação
          Row(
            children: [
              const Text('Exportar como: '),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedExportFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedExportFormat = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'geojson', child: Text('GeoJSON')),
                  DropdownMenuItem(value: 'kml', child: Text('KML')),
                  DropdownMenuItem(value: 'csv', child: Text('CSV')),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói estatísticas gerais
  Widget _buildGeneralStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas Gerais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Polígonos',
                  '${_statistics['total_polygons'] ?? 0}',
                  Icons.polygon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Área Total',
                  '${(_statistics['total_area_ha'] ?? 0.0).toStringAsFixed(2)} ha',
                  Icons.area_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Perímetro Total',
                  '${(_statistics['total_perimeter_m'] ?? 0.0).toStringAsFixed(0)} m',
                  Icons.straighten,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Área Média',
                  '${(_statistics['average_area_ha'] ?? 0.0).toStringAsFixed(2)} ha',
                  Icons.analytics,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Perímetro Médio',
                  '${(_statistics['average_perimeter_m'] ?? 0.0).toStringAsFixed(0)} m',
                  Icons.timeline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Distância Total',
                  '${(_statistics['total_distance_m'] ?? 0.0).toStringAsFixed(0)} m',
                  Icons.route,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de estatística
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói gráficos
  Widget _buildCharts() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gráfico de pizza - Métodos
          SizedBox(
            height: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribuição por Método',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: (_statistics['manual_count'] ?? 0).toDouble(),
                              title: 'Manual\n${_statistics['manual_count'] ?? 0}',
                              color: Colors.blue,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: (_statistics['gps_count'] ?? 0).toDouble(),
                              title: 'GPS\n${_statistics['gps_count'] ?? 0}',
                              color: Colors.green,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: (_statistics['imported_count'] ?? 0).toDouble(),
                              title: 'Importado\n${_statistics['imported_count'] ?? 0}',
                              color: Colors.orange,
                              radius: 50,
                            ),
                          ],
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Gráfico de barras - Área por método
          SizedBox(
            height: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Área por Método',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _calculateMaxArea(),
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const titles = ['Manual', 'GPS', 'Importado'];
                                  return Text(
                                    titles[value.toInt()],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: _calculateAreaByMethod('manual'),
                                  color: Colors.blue,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: _calculateAreaByMethod('caminhada'),
                                  color: Colors.green,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: _calculateAreaByMethod('importado'),
                                  color: Colors.orange,
                                  width: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula área máxima para o gráfico
  double _calculateMaxArea() {
    final manualArea = _calculateAreaByMethod('manual');
    final gpsArea = _calculateAreaByMethod('caminhada');
    final importedArea = _calculateAreaByMethod('importado');
    
    final maxArea = [manualArea, gpsArea, importedArea].reduce((a, b) => a > b ? a : b);
    return maxArea * 1.2; // 20% de margem
  }

  /// Calcula área por método
  double _calculateAreaByMethod(String method) {
    return _polygons
        .where((p) => p['method'] == method)
        .fold(0.0, (sum, p) => sum + (p['areaHa'] as double));
  }

  /// Constrói lista de polígonos
  Widget _buildPolygonsList() {
    final filteredPolygons = _getFilteredPolygons();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Polígonos (${filteredPolygons.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implementar visualização detalhada
                },
                child: const Text('Ver Todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPolygons.take(5).length,
              itemBuilder: (context, index) {
                final polygon = filteredPolygons[index];
                return ListTile(
                  leading: Icon(
                    _getMethodIcon(polygon['method']),
                    color: _getMethodColor(polygon['method']),
                  ),
                  title: Text(polygon['name']),
                  subtitle: Text(
                    '${polygon['areaHa'].toStringAsFixed(2)} ha • ${polygon['method']}',
                  ),
                  trailing: Text(
                    polygon['createdAt'].toString().substring(0, 10),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    // TODO: Navegar para tela de edição
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém ícone do método
  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'manual':
        return Icons.edit;
      case 'caminhada':
        return Icons.directions_walk;
      case 'importado':
        return Icons.file_download;
      default:
        return Icons.polygon;
    }
  }

  /// Obtém cor do método
  Color _getMethodColor(String method) {
    switch (method) {
      case 'manual':
        return Colors.blue;
      case 'caminhada':
        return Colors.green;
      case 'importado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Converte polígonos para TalhaoModel
  Future<List<TalhaoModel>> _convertPolygonsToTalhoes(List<String> polygonIds) async {
    final talhoes = <TalhaoModel>[];
    
    for (final polygonId in polygonIds) {
      final polygon = _polygons.firstWhere(
        (p) => p['id'] == polygonId,
        orElse: () => <String, dynamic>{},
      );
      
      if (polygon.isNotEmpty) {
        // Converter coordenadas para LatLng
        final coordinates = (polygon['coordinates'] as List<dynamic>)
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();
        
        final talhao = TalhaoModel(
          id: polygon['id'] as String,
          nome: polygon['name'] as String,
          area: polygon['areaHa'] as double,
          perimetro: polygon['perimeterM'] as double,
          poligonos: [coordinates],
          status: 'ativo',
          dataCriacao: DateTime.parse(polygon['createdAt'] as String),
          dataAtualizacao: DateTime.parse(polygon['updatedAt'] as String),
          observacoes: polygon['description'] as String? ?? '',
        );
        
        talhoes.add(talhao);
      }
    }
    
    return talhoes;
  }
}
