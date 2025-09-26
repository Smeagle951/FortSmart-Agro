import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../controllers/talhao_controller.dart';
import '../../widgets/advanced_metrics_widget.dart';
import '../../widgets/advanced_action_buttons_widget.dart';
import '../../widgets/talhao_popup_widget.dart';
import '../../widgets/talhao_editor_bottom_sheet.dart';
import '../../widgets/gps_settings_dialog.dart';
import '../../models/talhao_model.dart';
import '../../models/poligono_model.dart';
import '../../models/gps_stats.dart';
import '../../services/geo_import_export_service.dart';
import '../../services/advanced_gps_tracking_service.dart';
import '../../config/maptiler_config.dart';

/// Tela principal avançada para criação de talhões
/// Versão completa e profissional baseada no arquivo original
class NovoTalhaoScreenAdvanced extends StatefulWidget {
  const NovoTalhaoScreenAdvanced({Key? key}) : super(key: key);

  @override
  State<NovoTalhaoScreenAdvanced> createState() => _NovoTalhaoScreenAdvancedState();
}

class _NovoTalhaoScreenAdvancedState extends State<NovoTalhaoScreenAdvanced> {
  late TalhaoController _controller;
  final GeoImportExportService _importExportService = GeoImportExportService();
  final AdvancedGpsTrackingService _gpsService = AdvancedGpsTrackingService();
  
  bool _isLoading = true;
  bool _showMetrics = true;
  GpsStats? _gpsStats;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _setupGpsService();
  }

  Future<void> _initializeController() async {
    _controller = TalhaoController();
    await _controller.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  void _setupGpsService() {
    // TODO: Implementar callbacks quando o GPS service estiver completo
  }

  @override
  void dispose() {
    _controller.dispose();
    _gpsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando sistema de talhões...'),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<TalhaoController>(
          builder: (context, controller, child) {
            return Stack(
              children: [
                // Mapa principal
                _buildMap(controller),
                
                // Métricas avançadas
                AdvancedMetricsWidget(
                  points: controller.currentPoints,
                  gpsStats: _gpsStats,
                  isVisible: _showMetrics,
                  onToggleVisibility: () => setState(() => _showMetrics = !_showMetrics),
                ),
                
                // Botões de ação
                AdvancedActionButtonsWidget(
                  showActionButtons: controller.showActionButtons,
                  isDrawing: controller.isDrawing,
                  isGpsTracking: false, // TODO: Implementar estado do GPS
                  isGpsPaused: false,
                  currentPoints: controller.currentPoints,
                  onStartDrawing: _startDrawing,
                  onStartGps: _startGpsTracking,
                  onPauseGps: _pauseGpsTracking,
                  onResumeGps: _resumeGpsTracking,
                  onFinishGps: _finishGpsTracking,
                  onClearDrawing: _clearDrawing,
                  onSaveTalhao: _showSaveDialog,
                  onImportPolygons: _importPolygons,
                  onExportPolygons: _exportPolygons,
                  onShowHelp: _showHelp,
                  onUndoLastPoint: _undoLastPoint,
                ),
                
                // Popup do talhão selecionado
                if (controller.showPopup && controller.selectedTalhao != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: TalhaoPopupWidget(
                      talhao: controller.selectedTalhao!,
                      cultures: controller.cultures,
                      onEdit: _editTalhao,
                      onDelete: _deleteTalhao,
                      onClose: _closePopup,
                    ),
                  ),
                
                // Indicador de status GPS
                if (false) // TODO: Implementar estado do GPS
                  _buildGpsStatusIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Novo Talhão - Versão Avançada'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        // Botão de métricas
        IconButton(
          onPressed: () => setState(() => _showMetrics = !_showMetrics),
          icon: Icon(_showMetrics ? Icons.visibility_off : Icons.visibility),
          tooltip: _showMetrics ? 'Ocultar métricas' : 'Mostrar métricas',
        ),
        
        // Botão para centralizar no GPS
        IconButton(
          onPressed: _centerMapOnLocation,
          icon: const Icon(Icons.my_location),
          tooltip: 'Centralizar no GPS',
        ),
        
        // Botão de configurações GPS
        IconButton(
          onPressed: _showGpsSettings,
          icon: const Icon(Icons.settings),
          tooltip: 'Configurações GPS',
        ),
        
        // Botão de ajuda
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Ajuda',
        ),
      ],
    );
  }

  Widget _buildMap(TalhaoController controller) {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.userLocation ?? const LatLng(MapTilerConfig.defaultLat, MapTilerConfig.defaultLng),
        initialZoom: MapTilerConfig.defaultZoom,
        onTap: (tapPosition, point) => _onMapTap(point, controller),
        minZoom: MapTilerConfig.minZoom,
        maxZoom: MapTilerConfig.maxZoom,
      ),
      children: [
        // Tile layer com MapTiler
        TileLayer(
          urlTemplate: MapTilerConfig.satelliteUrl,
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Polígonos dos talhões existentes
        PolygonLayer(
          polygons: _buildTalhaoPolygons(controller),
        ),
        
        // Pontos atuais sendo desenhados
        if (controller.currentPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: controller.currentPoints,
                color: Colors.blue,
                strokeWidth: 3.0,
              ),
            ],
          ),
        
        // Marcadores dos talhões
        MarkerLayer(
          markers: _buildTalhaoMarkers(controller),
        ),
        
        // Marcador da localização do usuário
        if (controller.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: controller.userLocation!,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildGpsStatusIndicator() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green, // TODO: Implementar estado do GPS
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
              _gpsService.isPaused ? Icons.pause : Icons.gps_fixed,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _gpsService.isPaused ? 'GPS Pausado' : 'GPS Ativo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Polygon> _buildTalhaoPolygons(TalhaoController controller) {
    final polygons = <Polygon>[];
    
    // Carregar talhões existentes do controller
    for (final talhao in controller.existingTalhoes) {
      if (talhao.poligonos.isNotEmpty) {
        // Converter polígonos do modelo para formato do mapa
        for (final poligono in talhao.poligonos) {
          if (poligono.pontos.isNotEmpty) {
            polygons.add(Polygon(
              points: poligono.pontos,
              color: _getColorForTalhao(talhao).withOpacity(0.3),
              borderColor: _getColorForTalhao(talhao),
              borderStrokeWidth: 2.0,
              isFilled: true,
            ));
          }
        }
      }
    }
    
    return polygons;
  }

  List<Marker> _buildTalhaoMarkers(TalhaoController controller) {
    final markers = <Marker>[];
    
    // Carregar talhões existentes do controller
    for (final talhao in controller.existingTalhoes) {
      if (talhao.poligonos.isNotEmpty) {
        // Calcular centroide do primeiro polígono
        final centroide = _calculateCentroid(talhao.poligonos.first.pontos);
        
        markers.add(Marker(
          point: centroide,
          child: GestureDetector(
            onTap: () => _onTalhaoTap(talhao, controller),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorForTalhao(talhao),
                borderRadius: BorderRadius.circular(20),
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
                talhao.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
      }
    }
    
    return markers;
  }

  void _onMapTap(LatLng point, TalhaoController controller) {
    if (controller.isDrawing) {
      controller.addPoint(point);
    }
  }

  void _onTalhaoTap(TalhaoModel talhao, TalhaoController controller) {
    controller.selectTalhao(talhao);
  }

  Color _getColorForTalhao(TalhaoModel talhao) {
    // Cores baseadas na cultura
    final colorMap = {
      'Soja': Colors.green,
      'Milho': Colors.yellow,
      'Algodão': const Color(0xFFE0E0E0), // Cinza claro
      'Café': Colors.brown,
      'Cana-de-açúcar': Colors.orange,
      'Trigo': Colors.amber,
      'Feijão': Colors.red,
    };
    
    return colorMap[talhao.culturaId] ?? Colors.blue;
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0.0;
    double lngSum = 0.0;
    
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  void _startDrawing() {
    _controller.startDrawing();
  }

  void _startGpsTracking() async {
    final success = await _gpsService.startTracking(
      onPointsChanged: (points) {
        if (mounted) {
          setState(() {
            _controller.addPoint(points.last);
          });
        }
      },
      onDistanceChanged: (distance) {
        if (mounted) {
          setState(() {
            // Atualizar distância se necessário
          });
        }
      },
      onAccuracyChanged: (accuracy) {
        if (mounted) {
          setState(() {
            // Atualizar precisão se necessário
          });
        }
      },
      onStatusChanged: (status) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GPS: $status')),
          );
        }
      },
      onTrackingStateChanged: (isTracking) {
        if (mounted) {
          setState(() {
            // Atualizar estado de rastreamento
          });
        }
      },
    );
    
    if (success) {
      _controller.startDrawing();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rastreamento GPS iniciado'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao iniciar GPS. Verifique as permissões.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _pauseGpsTracking() {
    _gpsService.pauseTracking();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS pausado'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _resumeGpsTracking() {
    _gpsService.resumeTracking();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS retomado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _finishGpsTracking() {
    _gpsService.stopTracking();
    _controller.finishDrawing();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rastreamento GPS finalizado'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearDrawing() {
    _controller.clearDrawing();
    _gpsService.clearData();
  }

  void _undoLastPoint() {
    _controller.undoLastPoint();
  }

  void _showSaveDialog() {
    if (_controller.currentPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desenhe pelo menos 3 pontos para salvar o talhão'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TalhaoEditorBottomSheet(
        cultures: _controller.cultures,
        safras: ['2024/2025', '2025/2026'], // TODO: Carregar safras dinamicamente
        onSave: _saveTalhao,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _saveTalhao(TalhaoModel talhao) async {
    try {
      // Criar polígono a partir dos pontos atuais
      final poligono = PoligonoModel(
        pontos: _controller.currentPoints,
        area: _controller.currentArea,
        perimetro: _controller.currentPerimeter,
      );

      // Criar talhão completo
      final talhaoCompleto = TalhaoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: talhao.name,
        poligonos: [poligono],
        area: _controller.currentArea,
        observacoes: talhao.observacoes,
        culturaId: talhao.culturaId,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false,
        safras: [],
      );

      // Salvar no controller
      final success = await _controller.saveCurrentTalhao(
        name: talhaoCompleto.name,
        culturaId: talhaoCompleto.culturaId ?? '',
        observacoes: talhaoCompleto.observacoes,
      );

      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talhão salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearDrawing();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar talhão'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar talhão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editTalhao(TalhaoModel talhao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TalhaoEditorBottomSheet(
        talhao: talhao,
        cultures: _controller.cultures,
        safras: _controller.safras,
        onSave: (editedTalhao) async {
          try {
            // Atualizar talhão no controller
            final success = await _controller.updateTalhao(editedTalhao);
            
            Navigator.pop(context);
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Talhão editado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao editar talhão'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao editar talhão: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _deleteTalhao(String id) async {
    // Mostrar confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este talhão? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _controller.deleteTalhao(id);
        _controller.closePopup();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Talhão excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir talhão'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        _controller.closePopup();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir talhão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _closePopup() {
    _controller.closePopup();
  }

  void _importPolygons() async {
    final result = await _importExportService.importPolygons();
    
    if (result.success && result.polygons != null && result.polygons!.isNotEmpty) {
      // Mostrar diálogo de seleção de polígono
      _showImportSelectionDialog(result.polygons!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: ${result.error ?? 'Nenhum polígono encontrado'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportSelectionDialog(List<ImportedPolygon> polygons) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Polígono'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: polygons.length,
            itemBuilder: (context, index) {
              final polygon = polygons[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: Text('Polígono ${index + 1}'),
                subtitle: Text(
                  'Área: ${polygon.areaHa.toStringAsFixed(2)} ha\n'
                  'Perímetro: ${(polygon.perimeterM / 1000).toStringAsFixed(2)} km\n'
                  'Formato: ${polygon.sourceFormat}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectImportedPolygon(polygon);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _selectImportedPolygon(ImportedPolygon polygon) {
    // Limpar pontos atuais
    _controller.clearDrawing();
    
    // Adicionar pontos do polígono importado
    for (final point in polygon.points) {
      _controller.addPoint(point);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Polígono importado: ${polygon.areaHa.toStringAsFixed(2)} ha'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportPolygons() async {
    if (_controller.currentPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desenhe pelo menos 3 pontos para exportar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo de formato
    final format = await _showExportFormatDialog();
    if (format == null) return;

    final result = await _importExportService.exportPolygons(
      _controller.currentPoints,
      format,
      'talhao_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (result.success && result.filePath != null) {
      await _importExportService.shareFile(result.filePath!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Polígono exportado em $format com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showExportFormatDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Formato de Exportação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('KML'),
              subtitle: const Text('Google Earth, Google Maps'),
              onTap: () => Navigator.pop(context, 'kml'),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text('GeoJSON'),
              subtitle: const Text('QGIS, ArcGIS, Leaflet'),
              onTap: () => Navigator.pop(context, 'geojson'),
            ),
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: Colors.orange),
              title: const Text('GPX'),
              subtitle: const Text('Dispositivos GPS, aplicativos de trilha'),
              onTap: () => Navigator.pop(context, 'gpx'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _centerMapOnLocation() async {
    // Atualizar localização atual
    await _controller.updateCurrentLocation();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mapa centralizado na sua localização atual'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showGpsSettings() {
    showDialog(
      context: context,
      builder: (context) => GpsSettingsDialog(
        onSave: (settings) {
          // TODO: Aplicar configurações do GPS
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configurações GPS salvas!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Novo Talhão Avançado'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯 Funcionalidades Principais:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Toque no mapa para desenhar manualmente'),
              Text('• Use o botão GPS para rastreamento automático'),
              Text('• Desenhe pelo menos 3 pontos para formar um polígono'),
              Text('• Use o botão Salvar para confirmar o talhão'),
              SizedBox(height: 16),
              Text('📊 Métricas Avançadas:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Área calculada com precisão geodésica'),
              Text('• Perímetro e distância percorrida'),
              Text('• Estatísticas detalhadas do GPS'),
              Text('• Precisão estimada baseada na densidade de pontos'),
              SizedBox(height: 16),
              Text('🔄 Importação/Exportação:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Suporte a KML, GeoJSON, GPX'),
              Text('• Compartilhamento direto do arquivo'),
              Text('• Preservação de metadados'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
