import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/infestacao_model.dart';
import '../../../models/ponto_monitoramento_model.dart';
import '../../../repositories/infestacao_repository.dart';
import '../../../database/app_database.dart';
import '../../../services/talhao_service.dart';
import '../../../modules/infestation_map/services/infestacao_integration_service.dart';
import 'dart:async';

class PointMonitoringMap extends StatefulWidget {
  final PontoMonitoramentoModel? currentPoint;
  final PontoMonitoramentoModel? nextPoint;
  final Position? currentPosition;
  final List<InfestacaoModel> ocorrencias;
  final int talhaoId;
  final String culturaId;

  const PointMonitoringMap({
    Key? key,
    this.currentPoint,
    this.nextPoint,
    this.currentPosition,
    required this.ocorrencias,
    required this.talhaoId,
    required this.culturaId,
  }) : super(key: key);

  @override
  State<PointMonitoringMap> createState() => _PointMonitoringMapState();
}

class _PointMonitoringMapState extends State<PointMonitoringMap> with TickerProviderStateMixin {
  MapController? _mapController;
  LatLng? _mapCenter;
  List<InfestacaoModel> _historicCriticalOccurrences = [];
  InfestacaoRepository? _infestacaoRepository;
  TalhaoService? _talhaoService;
  List<LatLng>? _talhaoPolygon;
  
  // Dados de infestação do Módulo Mapa de Infestação
  List<Map<String, dynamic>> _infestationPoints = [];
  InfestacaoIntegrationService? _infestationService;
  
  // Animações para ícones pulsantes
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Constantes para histórico crítico
  static const int _criticalHistoryDays = 30;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeAnimations();
    _initializeRepository();
    _initializeTalhaoService();
    _initializeInfestationService();
    _calculateMapCenter();
    _loadCriticalHistory();
    _loadTalhaoPolygon();
    _loadInfestationData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animação pulsante
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeRepository() async {
    try {
      final database = await AppDatabase().database;
      _infestacaoRepository = InfestacaoRepository(database);
    } catch (e) {
      // Log error but don't block the UI
      print('Erro ao inicializar repositório: $e');
    }
  }

  Future<void> _initializeTalhaoService() async {
    try {
      _talhaoService = TalhaoService();
    } catch (e) {
      print('Erro ao inicializar TalhaoService: $e');
    }
  }

  Future<void> _initializeInfestationService() async {
    try {
      _infestationService = InfestacaoIntegrationService();
    } catch (e) {
      print('Erro ao inicializar InfestacaoIntegrationService: $e');
    }
  }

  /// Carrega dados de infestação do Módulo Mapa de Infestação
  Future<void> _loadInfestationData() async {
    if (_infestationService == null) return;
    
    try {
      print('🔄 Carregando dados de infestação do Módulo Mapa de Infestação...');
      
      // Buscar dados de infestação georreferenciados para este talhão
      // TODO: Implementar método real no InfestacaoIntegrationService
      final infestationData = await _getMockInfestationData();
      
      setState(() {
        _infestationPoints = infestationData ?? [];
      });
      
      if (_infestationPoints.isNotEmpty) {
        print('✅ ${_infestationPoints.length} pontos de infestação carregados');
      } else {
        print('ℹ️ Nenhum ponto de infestação encontrado para este talhão');
      }
      
    } catch (e) {
      print('❌ Erro ao carregar dados de infestação: $e');
    }
  }

  /// Método mock para dados de infestação (temporário)
  Future<List<Map<String, dynamic>>?> _getMockInfestationData() async {
    // Dados mock para demonstração
    return [
      {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'tipo': 'praga',
        'subtipo': 'Lagarta-da-soja',
        'nivel': 'alto',
        'data': '2024-01-15',
        'observacoes': 'Alta infestação detectada',
      },
      {
        'latitude': -23.5515,
        'longitude': -46.6343,
        'tipo': 'doença',
        'subtipo': 'Ferrugem Asiática',
        'nivel': 'médio',
        'data': '2024-01-14',
        'observacoes': 'Focos iniciais da doença',
      },
    ];
  }

  Future<void> _loadTalhaoPolygon() async {
    if (_talhaoService == null) return;
    
    try {
      final polygon = await _talhaoService!.getTalhaoPolygon(widget.talhaoId.toString());
      setState(() {
        _talhaoPolygon = polygon;
      });
      
      if (polygon != null) {
        print('✅ Polígono do talhão carregado: ${polygon.length} pontos');
      } else {
        print('⚠️ Polígono do talhão não encontrado para ID: ${widget.talhaoId}');
      }
    } catch (e) {
      print('❌ Erro ao carregar polígono do talhão: $e');
    }
  }

  Future<void> _loadCriticalHistory() async {
    if (_infestacaoRepository == null) return;
    
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: _criticalHistoryDays));
      
      // Buscar ocorrências críticas (nível alto/crítico) dos últimos 30 dias
      final criticalOccurrences = await _infestacaoRepository!.getCriticalOccurrencesByTalhaoAndCultura(
        widget.talhaoId,
        widget.culturaId,
        cutoffDate,
      );
      
      // Filtrar apenas ocorrências realmente críticas para MIP
      final filteredOccurrences = criticalOccurrences.where((occurrence) {
        final nivel = occurrence.nivel.toLowerCase();
        return nivel.contains('crítico') || 
               nivel.contains('alto') || 
               nivel.contains('high') ||
               nivel.contains('critical');
      }).toList();
      
      setState(() {
        _historicCriticalOccurrences = filteredOccurrences;
      });
      
      if (filteredOccurrences.isNotEmpty) {
        print('⚠️ MIP: ${filteredOccurrences.length} ocorrências críticas encontradas nos últimos $_criticalHistoryDays dias');
        
        // Log detalhado para orientação MIP
        final groupedByType = <String, int>{};
        for (final occurrence in filteredOccurrences) {
          final tipo = occurrence.tipo.toLowerCase();
          groupedByType[tipo] = (groupedByType[tipo] ?? 0) + 1;
        }
        
        groupedByType.forEach((tipo, count) {
          print('🎯 MIP: $count ocorrências de ${tipo.toUpperCase()} requerem atenção');
        });
      } else {
        print('✅ MIP: Nenhuma ocorrência crítica encontrada nos últimos $_criticalHistoryDays dias');
      }
    } catch (e) {
      print('❌ Erro ao carregar histórico crítico para MIP: $e');
    }
  }

  @override
  void didUpdateWidget(PointMonitoringMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPoint != widget.currentPoint ||
        oldWidget.ocorrencias != widget.ocorrencias) {
      _calculateMapCenter();
      _loadInfestationData();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _calculateMapCenter() {
    List<LatLng> points = [];
    
    if (widget.currentPosition != null) {
      points.add(LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude));
    }
    
    if (widget.currentPoint != null) {
      points.add(LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude));
    }
    
    if (widget.nextPoint != null) {
      points.add(LatLng(widget.nextPoint!.latitude, widget.nextPoint!.longitude));
    }
    
    for (var ocorrencia in widget.ocorrencias) {
      points.add(LatLng(ocorrencia.latitude, ocorrencia.longitude));
    }
    
    if (points.isNotEmpty) {
      double latSum = 0;
      double lngSum = 0;
      for (var point in points) {
        latSum += point.latitude;
        lngSum += point.longitude;
      }
      _mapCenter = LatLng(latSum / points.length, lngSum / points.length);
    } else {
      // Coordenadas padrão do Brasil
      _mapCenter = const LatLng(-15.7801, -47.9292);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Mapa real
            _buildRealMap(),
            
            // Legenda compacta
            Positioned(
              top: 8,
              right: 8,
              child: _buildLegend(),
            ),
            
            // Overlay de alerta crítico MIP se necessário
            if (_hasCriticalOccurrences())
              Positioned(
                top: 8,
                left: 8,
                child: _buildMIPAlert(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMap() {
    if (_mapCenter == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _mapCenter!,
        zoom: 16.0,
        minZoom: 10.0,
        maxZoom: 20.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Camada de tiles (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
          maxZoom: 18,
        ),
        
        // Camada de marcadores
        MarkerLayer(
          markers: _buildMapMarkers(),
        ),
        
        // Camada de polígono do talhão
        PolygonLayer(
          polygons: _buildTalhaoPolygon(),
        ),
        
        // Camada de linhas conectando pontos
        PolylineLayer(
          polylines: _buildConnectionLines(),
        ),
      ],
    );
  }

  List<Marker> _buildMapMarkers() {
    List<Marker> markers = [];
    
    // Markers do histórico crítico (só exibir se não for o ponto atual)
    for (final occurrence in _historicCriticalOccurrences) {
      if (widget.currentPoint == null || 
          (occurrence.latitude != widget.currentPoint!.latitude || 
           occurrence.longitude != widget.currentPoint!.longitude)) {
        markers.add(_buildHistoricCriticalMarker(occurrence));
      }
    }
    
    // Marcador da posição atual
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
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
              Icons.my_location,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      );
    }
    
    // Marcador do ponto atual
    if (widget.currentPoint != null) {
      markers.add(
        Marker(
          point: LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
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
              Icons.place,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      );
    }
    
    // Marcador do próximo ponto
    if (widget.nextPoint != null) {
      markers.add(
        Marker(
          point: LatLng(widget.nextPoint!.latitude, widget.nextPoint!.longitude),
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
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
              Icons.radio_button_unchecked,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      );
    }
    
    // Marcadores de infestação pulsantes
    markers.addAll(_buildInfestationMarkers());
    
    // Marcadores das ocorrências
    for (var ocorrencia in widget.ocorrencias) {
      markers.add(
        Marker(
          point: LatLng(ocorrencia.latitude, ocorrencia.longitude),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: _getTipoColor(ocorrencia.tipo),
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
            child: Text(
              ocorrencia.tipoIcon,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    
    return markers;
  }

  Marker _buildHistoricCriticalMarker(InfestacaoModel occurrence) {
    return Marker(
      point: LatLng(occurrence.latitude, occurrence.longitude),
      width: 16,
      height: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.warning,
          color: Colors.white,
          size: 10,
        ),
      ),
    );
  }

  List<Polygon> _buildTalhaoPolygon() {
    // Carregar polígono real do talhão do banco de dados
    return _getTalhaoPolygonFromDatabase();
  }

  List<Polygon> _getTalhaoPolygonFromDatabase() {
    // Retorna o polígono real do talhão se disponível
    if (_talhaoPolygon != null && _talhaoPolygon!.isNotEmpty) {
      return [
        Polygon(
          points: _talhaoPolygon!,
          color: const Color(0xFF2D9CDB).withOpacity(0.1),
          borderColor: const Color(0xFF2D9CDB).withOpacity(0.3),
          borderStrokeWidth: 2,
        ),
      ];
    }
    
    // Se não há polígono disponível, retorna lista vazia
    return [];
  }

  List<Polyline> _buildConnectionLines() {
    List<Polyline> lines = [];
    
    if (widget.currentPoint != null && widget.nextPoint != null) {
      lines.add(
        Polyline(
          points: [
            LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude),
            LatLng(widget.nextPoint!.latitude, widget.nextPoint!.longitude),
          ],
          color: const Color(0xFF2D9CDB),
          strokeWidth: 2,
          strokeCap: StrokeCap.round,
        ),
      );
    }
    
    return lines;
  }

  Color _getOccurrenceColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'crítico':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'médio':
        return Colors.yellow;
      case 'baixo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Obtém cor baseada no tipo de infestação
  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return Colors.orange;
      case 'doença':
        return Colors.red;
      case 'daninha':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da legenda
          Text(
            'MIP - Últimos 30 dias',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          
          // Ponto atual
          _buildLegendItem('📍', 'Ponto Atual', Colors.blue),
          
          // Histórico crítico (dados reais)
          if (_historicCriticalOccurrences.isNotEmpty) ...[
            const Divider(height: 8, thickness: 1),
            Text(
              'Áreas Críticas (${_historicCriticalOccurrences.length})',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 2),
            
            // Agrupar por tipo para mostrar contadores reais
            ..._buildCriticalCounters(),
          ] else ...[
            const Divider(height: 8, thickness: 1),
            _buildLegendItem('✅', 'Sem alertas críticos', Colors.green),
          ],
          
          // Orientação MIP
          const Divider(height: 8, thickness: 1),
          Text(
            'Orientação MIP',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 2),
          _buildLegendItem('🎯', 'Foque nas áreas críticas', Colors.orange),
          _buildLegendItem('📊', 'Compare com histórico', Colors.purple),
        ],
      ),
    );
  }

  /// Constrói contadores de ocorrências críticas por tipo (dados reais para MIP)
  List<Widget> _buildCriticalCounters() {
    // Agrupar ocorrências críticas por tipo
    final Map<String, int> criticalCounters = {};
    final Map<String, String> typeIcons = {
      'praga': '🐛',
      'doença': '🦠', 
      'daninha': '🌿',
      'outro': '⚠️',
    };
    
    for (final occurrence in _historicCriticalOccurrences) {
      final tipo = occurrence.tipo.toLowerCase();
      criticalCounters[tipo] = (criticalCounters[tipo] ?? 0) + 1;
    }
    
    // Converter para lista de widgets ordenada por prioridade MIP
    final List<Widget> counters = [];
    final priorityOrder = ['praga', 'doença', 'daninha', 'outro'];
    
    for (final tipo in priorityOrder) {
      final count = criticalCounters[tipo];
      if (count != null && count > 0) {
        final icon = typeIcons[tipo] ?? '⚠️';
        final label = '${tipo.toUpperCase()}: $count';
        final color = _getTipoColor(tipo);
        
        counters.add(_buildLegendItem(icon, label, color));
      }
    }
    
    return counters;
  }

  Widget _buildLegendItem(String icon, String label, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color ?? const Color(0xFF2C2C2C),
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMIPAlert() {
    // Calcular estatísticas MIP
    final totalCritical = _historicCriticalOccurrences.length;
    final pragaCount = _historicCriticalOccurrences.where((o) => o.tipo.toLowerCase().contains('praga')).length;
    final doencaCount = _historicCriticalOccurrences.where((o) => o.tipo.toLowerCase().contains('doença')).length;
    final daninhaCount = _historicCriticalOccurrences.where((o) => o.tipo.toLowerCase().contains('daninha')).length;
    
    // Determinar cor e ícone baseado na severidade MIP
    Color alertColor;
    IconData alertIcon;
    String alertMessage;
    
    if (totalCritical >= 10) {
      alertColor = Colors.red;
      alertIcon = Icons.dangerous;
      alertMessage = 'ALTO RISCO MIP';
    } else if (totalCritical >= 5) {
      alertColor = Colors.orange;
      alertIcon = Icons.warning;
      alertMessage = 'ATENÇÃO MIP';
    } else {
      alertColor = Colors.amber;
      alertIcon = Icons.info;
      alertMessage = 'MONITORAR';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                alertIcon,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                alertMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (pragaCount > 0 || doencaCount > 0 || daninhaCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '🐛$pragaCount 🦠$doencaCount 🌿$daninhaCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasCriticalOccurrences() {
    // Verificar ocorrências atuais críticas OU histórico crítico
    final currentCritical = widget.ocorrencias.any((o) => 
      o.nivel.toLowerCase().contains('crítico') || 
      o.nivel.toLowerCase().contains('alto') ||
      o.nivel.toLowerCase().contains('high'));
    
    final historicCritical = _historicCriticalOccurrences.isNotEmpty;
    
    return currentCritical || historicCritical;
  }

  void _onMapTap() {
    // Implementar interação com o mapa
  }

  /// Constrói ícones pulsantes para pontos de infestação
  List<Marker> _buildInfestationMarkers() {
    List<Marker> markers = [];
    
    for (final infestationPoint in _infestationPoints) {
      final lat = infestationPoint['latitude'] as double?;
      final lng = infestationPoint['longitude'] as double?;
      final tipo = infestationPoint['tipo'] as String? ?? 'outro';
      final subtipo = infestationPoint['subtipo'] as String? ?? '';
      final nivel = infestationPoint['nivel'] as String? ?? 'baixo';
      
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showInfestationPopup(infestationPoint),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getInfestationColor(tipo, nivel),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _getInfestationColor(tipo, nivel).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getInfestationIcon(tipo),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }
    }
    
    return markers;
  }

  /// Obtém cor baseada no tipo e nível de infestação
  Color _getInfestationColor(String tipo, String nivel) {
    final tipoLower = tipo.toLowerCase();
    final nivelLower = nivel.toLowerCase();
    
    // Cores baseadas no tipo
    Color baseColor;
    if (tipoLower.contains('praga')) {
      baseColor = Colors.red;
    } else if (tipoLower.contains('doença')) {
      baseColor = Colors.orange;
    } else if (tipoLower.contains('daninha')) {
      baseColor = Colors.green;
    } else {
      baseColor = Colors.grey;
    }
    
    // Intensidade baseada no nível
    if (nivelLower.contains('crítico') || nivelLower.contains('alto')) {
      return baseColor;
    } else if (nivelLower.contains('médio')) {
      return baseColor.withOpacity(0.8);
    } else {
      return baseColor.withOpacity(0.6);
    }
  }

  /// Obtém ícone baseado no tipo de infestação
  IconData _getInfestationIcon(String tipo) {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('praga')) {
      return Icons.bug_report;
    } else if (tipoLower.contains('doença')) {
      return Icons.medical_services;
    } else if (tipoLower.contains('daninha')) {
      return Icons.local_florist;
    } else {
      return Icons.warning;
    }
  }

  /// Mostra pop-up com informações da infestação
  void _showInfestationPopup(Map<String, dynamic> infestationPoint) {
    final tipo = infestationPoint['tipo'] as String? ?? 'Desconhecido';
    final subtipo = infestationPoint['subtipo'] as String? ?? '';
    final nivel = infestationPoint['nivel'] as String? ?? 'baixo';
    final data = infestationPoint['data'] as String? ?? '';
    final observacoes = infestationPoint['observacoes'] as String? ?? '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getInfestationIcon(tipo),
                color: _getInfestationColor(tipo, nivel),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Infestação Detectada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPopupRow('Tipo:', tipo, _getInfestationColor(tipo, nivel)),
              if (subtipo.isNotEmpty)
                _buildPopupRow('Subtipo:', subtipo, Colors.grey[600]!),
              _buildPopupRow('Nível:', nivel.toUpperCase(), _getInfestationColor(tipo, nivel)),
              if (data.isNotEmpty)
                _buildPopupRow('Data:', data, Colors.grey[600]!),
              if (observacoes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Observações:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  observacoes,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  /// Constrói linha do pop-up
  Widget _buildPopupRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
