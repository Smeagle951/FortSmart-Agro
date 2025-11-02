import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/enhanced_ai_organism_data.dart';
import '../services/ai_infestation_map_integration_service.dart';
import '../../../models/talhao_model.dart';
import '../../../utils/logger.dart';

/// Widget para mapa térmico com severidades baseadas na IA expandida
class ThermalSeverityMapWidget extends StatefulWidget {
  final String talhaoId;
  final TalhaoModel talhao;
  final List<Map<String, dynamic>> monitoringData;
  final DateTime startDate;
  final DateTime endDate;
  final Function(String)? onOrganismSelected;
  final Function(Map<String, dynamic>)? onPointSelected;

  const ThermalSeverityMapWidget({
    super.key,
    required this.talhaoId,
    required this.talhao,
    required this.monitoringData,
    required this.startDate,
    required this.endDate,
    this.onOrganismSelected,
    this.onPointSelected,
  });

  @override
  State<ThermalSeverityMapWidget> createState() => _ThermalSeverityMapWidgetState();
}

class _ThermalSeverityMapWidgetState extends State<ThermalSeverityMapWidget> {
  final AIInfestationMapIntegrationService _integrationService = AIInfestationMapIntegrationService();
  final MapController _mapController = MapController();
  
  bool _isLoading = true;
  Map<String, dynamic> _thermalMapData = {};
  List<EnhancedAIOrganismData> _organisms = [];
  String? _selectedOrganismId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadThermalMapData();
  }

  Future<void> _loadThermalMapData() async {
    try {
      setState(() => _isLoading = true);
      
      // Gera dados térmicos usando a IA expandida
      _thermalMapData = await _integrationService.generateTalhaoThermalMap(
        talhaoId: widget.talhaoId,
        talhao: widget.talhao,
        monitoringData: widget.monitoringData,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados térmicos: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando mapa térmico com IA...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadThermalMapData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildMapControls(),
        Expanded(
          child: _buildThermalMap(),
        ),
        _buildSeverityLegend(),
      ],
    );
  }

  Widget _buildMapControls() {
    final organismos = _thermalMapData['organismos'] as Map<String, dynamic>? ?? {};
    
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🗺️ Mapa Térmico - ${widget.talhao.nome}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Área: ${widget.talhao.area.toStringAsFixed(2)} hectares • Cultura: ${widget.talhao.cultura}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (organismos.isNotEmpty) ...[
            const Text(
              'Organismos Detectados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: organismos.entries.map((entry) {
                final organismId = entry.key;
                final organismData = entry.value as Map<String, dynamic>;
                final isSelected = _selectedOrganismId == organismId;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrganismId = isSelected ? null : organismId;
                    });
                    widget.onOrganismSelected?.call(organismId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          organismData['icon'] ?? '🐛',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          organismData['name'] ?? 'Organismo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(organismData['averageSeverity']),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${organismData['points'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThermalMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          widget.talhao.latitude ?? -23.5505,
          widget.talhao.longitude ?? -46.6333,
        ),
        initialZoom: 15.0,
        minZoom: 10.0,
        maxZoom: 20.0,
      ),
      children: [
        // Camada base do mapa
        TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=YOUR_MAPTILER_KEY',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Polígono do talhão
        _buildTalhaoPolygon(),
        
        // Pontos de monitoramento com severidade
        _buildMonitoringPoints(),
        
        // Heatmap baseado na severidade
        if (_selectedOrganismId != null) _buildSeverityHeatmap(),
        
        // Legenda do mapa
        _buildMapLegend(),
      ],
    );
  }

  Widget _buildTalhaoPolygon() {
    // Simula polígono do talhão (em produção, usar dados reais)
    return PolygonLayer(
      polygons: [
        Polygon(
          points: [
            LatLng(widget.talhao.latitude ?? -23.5505, widget.talhao.longitude ?? -46.6333),
            LatLng((widget.talhao.latitude ?? -23.5505) + 0.001, widget.talhao.longitude ?? -46.6333),
            LatLng((widget.talhao.latitude ?? -23.5505) + 0.001, (widget.talhao.longitude ?? -46.6333) + 0.001),
            LatLng(widget.talhao.latitude ?? -23.5505, (widget.talhao.longitude ?? -46.6333) + 0.001),
          ],
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  Widget _buildMonitoringPoints() {
    final organismos = _thermalMapData['organismos'] as Map<String, dynamic>? ?? {};
    final markers = <Marker>[];
    
    for (final entry in organismos.entries) {
      final organismId = entry.key;
      final organismData = entry.value as Map<String, dynamic>;
      
      // Filtra por organismo selecionado se houver
      if (_selectedOrganismId != null && _selectedOrganismId != organismId) {
        continue;
      }
      
      final points = organismData['points'] as int? ?? 0;
      final severity = organismData['averageSeverity'] as String? ?? 'baixo';
      
      // Cria marcadores para cada ponto
      for (int i = 0; i < points; i++) {
        final lat = (widget.talhao.latitude ?? -23.5505) + (i * 0.0001);
        final lng = (widget.talhao.longitude ?? -46.6333) + (i * 0.0001);
        
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () {
                widget.onPointSelected?.call({
                  'organismId': organismId,
                  'organismName': organismData['name'],
                  'severity': severity,
                  'latitude': lat,
                  'longitude': lng,
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
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
                child: Center(
                  child: Text(
                    organismData['icon'] ?? '🐛',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return MarkerLayer(markers: markers);
  }

  Widget _buildSeverityHeatmap() {
    final organismos = _thermalMapData['organismos'] as Map<String, dynamic>? ?? {};
    final selectedOrganism = organismos[_selectedOrganismId];
    
    if (selectedOrganism == null) return const SizedBox.shrink();
    
    // Simula heatmap baseado na severidade
    final severity = selectedOrganism['averageSeverity'] as String? ?? 'baixo';
    final intensity = _getSeverityIntensity(severity);
    
    return HeatMapLayer(
      points: _generateHeatmapPoints(selectedOrganism),
      radius: 50,
      blur: 15,
      maxZoom: 15,
      gradient: LinearGradient(
        colors: [
          _getSeverityColor(severity).withOpacity(0.0),
          _getSeverityColor(severity).withOpacity(0.3),
          _getSeverityColor(severity).withOpacity(0.6),
        ],
      ),
    );
  }

  List<HeatMapPoint> _generateHeatmapPoints(Map<String, dynamic> organismData) {
    final points = organismData['points'] as int? ?? 0;
    final severity = organismData['averageSeverity'] as String? ?? 'baixo';
    final intensity = _getSeverityIntensity(severity);
    
    return List.generate(points, (index) {
      final lat = (widget.talhao.latitude ?? -23.5505) + (index * 0.0001);
      final lng = (widget.talhao.longitude ?? -46.6333) + (index * 0.0001);
      
      return HeatMapPoint(
        lat: lat,
        lng: lng,
        intensity: intensity,
      );
    });
  }

  Widget _buildMapLegend() {
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
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Legenda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem('Baixo', Colors.green),
            _buildLegendItem('Médio', Colors.orange),
            _buildLegendItem('Alto', Colors.red),
            _buildLegendItem('Crítico', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityLegend() {
    final organismos = _thermalMapData['organismos'] as Map<String, dynamic>? ?? {};
    
    if (organismos.isEmpty) return const SizedBox.shrink();
    
    return Container(
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
          const Text(
            '📊 Estatísticas de Severidade',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...organismos.entries.map((entry) {
            final organismData = entry.value as Map<String, dynamic>;
            final severity = organismData['averageSeverity'] as String? ?? 'baixo';
            final points = organismData['points'] as int? ?? 0;
            final distribution = organismData['severityDistribution'] as Map<String, int>? ?? {};
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          organismData['icon'] ?? '🐛',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                organismData['name'] ?? 'Organismo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                organismData['scientificName'] ?? '',
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
                            color: _getSeverityColor(severity),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pontos: $points • Distribuição: ${distribution.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (organismData['recommendations'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recomendações: ${(organismData['recommendations'] as List).take(2).join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      case 'critico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  double _getSeverityIntensity(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo':
        return 0.2;
      case 'medio':
        return 0.5;
      case 'alto':
        return 0.8;
      case 'critico':
        return 1.0;
      default:
        return 0.1;
    }
  }
}

/// Classe para pontos do heatmap
class HeatMapPoint {
  final double lat;
  final double lng;
  final double intensity;

  HeatMapPoint({
    required this.lat,
    required this.lng,
    required this.intensity,
  });
}

/// Widget para camada de heatmap
class HeatMapLayer extends StatelessWidget {
  final List<HeatMapPoint> points;
  final double radius;
  final double blur;
  final double maxZoom;
  final Gradient gradient;

  const HeatMapLayer({
    super.key,
    required this.points,
    this.radius = 50,
    this.blur = 15,
    this.maxZoom = 15,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Implementação simplificada do heatmap
    // Em produção, usar biblioteca específica como heatmap_flutter
    return Container();
  }
}
