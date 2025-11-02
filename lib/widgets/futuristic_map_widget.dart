import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../utils/map_compatibility.dart' as compat;
import 'clean_map_widget.dart';

/// Widget de mapa usando CleanMapWidget com flutter_map como base e MapTiler como fonte de tiles
class FuturisticMapWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final Function(TalhaoModel)? onTalhaoSelected;
  final Function(compat.LatLng)? onMapTap;
  final List<compat.LatLng>? drawingPoints;
  final Function(List<compat.LatLng>)? onDrawingPointsChanged;
  final TalhaoModel? selectedTalhao;
  final bool isEditMode;
  final bool enableDrawing;
  final Color? drawingColor;
  final double? initialZoom;
  final compat.LatLng? initialCenter;
  final bool showControls;
  final Function(compat.LatLng)? onAddPoint;
  final Function(int)? onRemovePoint;
  final Function(int, compat.LatLng)? onMovePoint;
  
  const FuturisticMapWidget({
    Key? key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.onMapTap,
    this.drawingPoints,
    this.onDrawingPointsChanged,
    this.selectedTalhao,
    this.isEditMode = false,
    this.enableDrawing = false,
    this.drawingColor,
    this.initialZoom = 15.0,
    this.initialCenter,
    this.showControls = true,
    this.onAddPoint,
    this.onRemovePoint,
    this.onMovePoint,
  }) : super(key: key);

  @override
  State<FuturisticMapWidget> createState() => _FuturisticMapWidgetState();
}

class _FuturisticMapWidgetState extends State<FuturisticMapWidget> {
  bool _isDrawing = false;
  MapType _currentMapType = MapType.satellite;
  LatLng? _userLocation;
  
  @override
  void initState() {
    super.initState();
    _isDrawing = widget.enableDrawing;
  }

  @override
  void didUpdateWidget(FuturisticMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.enableDrawing != oldWidget.enableDrawing) {
      setState(() {
        _isDrawing = widget.enableDrawing;
      });
    }
  }

  /// Converte coordenadas do formato de compatibilidade para o formato latlong2
  LatLng? _convertToLatLng(compat.LatLng? point) {
    return point != null 
        ? LatLng(point.latitude, point.longitude) 
        : null;
  }

  /// Converte lista de coordenadas
  List<LatLng>? _convertToLatLngList(List<compat.LatLng>? points) {
    return points?.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  /// Converte coordenada latlong2 para formato de compatibilidade
  compat.LatLng _convertFromLatLng(LatLng point) {
    return compat.LatLng(point.latitude, point.longitude);
  }

  /// Cria callback convertido para onMapTap
  Function(LatLng)? _createMapTapCallback() {
    if (widget.onMapTap == null) return null;
    
    return (LatLng point) {
      widget.onMapTap!(_convertFromLatLng(point));
    };
  }

  /// Cria callback convertido para onDrawingPointsChanged
  Function(List<LatLng>)? _createDrawingPointsChangedCallback() {
    if (widget.onDrawingPointsChanged == null) return null;
    
    return (List<LatLng> points) {
      final List<compat.LatLng> convertedPoints = points
          .map((point) => _convertFromLatLng(point))
          .toList();
      widget.onDrawingPointsChanged!(convertedPoints);
    };
  }

  // Métodos _createAddPointCallback e _createMovePointCallback foram removidos
  // pois não são suportados pelo CleanMapWidget

  /// Centraliza o mapa na localização atual do usuário
  void _centerOnCurrentLocation() {
    // Esta funcionalidade será implementada no MapTilerMapWidget
    // Por enquanto, apenas atualizamos o estado
    setState(() {
      // Trigger para o MapTilerMapWidget centralizar na localização
    });
  }

  /// Alterna entre os tipos de mapa
  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.satellite:
          _currentMapType = MapType.hybrid;
          break;
        case MapType.hybrid:
          _currentMapType = MapType.normal;
          break;
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
      }
    });
  }

  /// Centraliza o mapa no talhão selecionado
  void _centerOnSelectedTalhao() {
    if (widget.selectedTalhao != null && widget.selectedTalhao!.poligonos.isNotEmpty) {
      // Esta funcionalidade será implementada no MapTilerMapWidget
      setState(() {
        // Trigger para centralizar no talhão
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa MapTiler
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CleanMapWidget(
            talhoes: widget.talhoes,
            onTalhaoSelected: widget.onTalhaoSelected,
            onMapTap: _createMapTapCallback(),
            drawingPoints: _convertToLatLngList(widget.drawingPoints),
            onDrawingPointsChanged: _createDrawingPointsChangedCallback(),
            selectedTalhao: widget.selectedTalhao,
            isEditMode: widget.isEditMode,
            enableDrawing: widget.enableDrawing,
            drawingColor: widget.drawingColor,
            initialZoom: widget.initialZoom ?? 15.0,
            initialCenter: _convertToLatLng(widget.initialCenter),
            showControls: false, // Controles serão mostrados neste widget
            // mapType: _currentMapType, // Não suportado pelo MapTiler
          ),
        ),
        
        // Controles do mapa
        if (widget.showControls)
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão de alternar tipo de mapa
                _NeomorphicButton(
                  icon: Icons.layers,
                  onPressed: _toggleMapType,
                  tooltip: 'Alternar tipo de mapa',
                ),
                const SizedBox(height: 12),
                
                // Botão de centralizar no GPS
                _NeomorphicButton(
                  icon: Icons.my_location,
                  onPressed: _centerOnCurrentLocation,
                  tooltip: 'Centralizar na minha localização',
                ),
                const SizedBox(height: 12),
                
                // Botão de centralizar no talhão selecionado
                if (widget.selectedTalhao != null)
                  _NeomorphicButton(
                    icon: Icons.crop_free,
                    onPressed: _centerOnSelectedTalhao,
                    tooltip: 'Centralizar no talhão',
                  ),
              ],
            ),
          ),
          
        // Indicador de área (quando estiver desenhando)
        if (widget.drawingPoints != null && widget.drawingPoints!.length >= 3)
          Positioned(
            top: 16,
            left: 16,
            child: _AreaIndicator(
              points: _convertToLatLngList(widget.drawingPoints)!,
            ),
          ),
          
        // Barra de legenda e filtros (flutuante)
        if (widget.talhoes.isNotEmpty && !widget.isEditMode)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _CulturaLegend(
              talhoes: widget.talhoes,
              onTalhaoSelected: widget.onTalhaoSelected,
              selectedTalhao: widget.selectedTalhao,
            ),
          ),
      ],
    );
  }
}

/// Botão com estilo neomórfico
class _NeomorphicButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;
  
  const _NeomorphicButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blue).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // onTap: onPressed, // onTap não é suportado em Polygon no flutter_map 5.0.0
          borderRadius: BorderRadius.circular(15),
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: 50,
              height: 50,
              // alignment: Alignment.center, // alignment não é suportado em Marker no flutter_map 5.0.0
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador de área do polígono sendo desenhado
class _AreaIndicator extends StatelessWidget {
  final List<LatLng> points;
  
  const _AreaIndicator({
    Key? key,
    required this.points,
  }) : super(key: key);

  /// Calcula a área do polígono usando a fórmula de Shoelace
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter de graus quadrados para metros quadrados (aproximação)
    // 1 grau ≈ 111,320 metros no equador
    const double metersPerDegree = 111320.0;
    area = area * metersPerDegree * metersPerDegree;
    
    // Converter para hectares (1 hectare = 10,000 m²)
    return area / 10000.0;
  }

  @override
  Widget build(BuildContext context) {
    // Calcular a área em hectares
    final area = _calculatePolygonArea(points);
    final areaText = area < 1.0 
        ? '${(area * 10000).toStringAsFixed(1)} m²' 
        : '${area.toStringAsFixed(2)} ha';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.straighten,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            areaText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legenda das culturas com filtros
class _CulturaLegend extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  final Function(TalhaoModel)? onTalhaoSelected;
  final TalhaoModel? selectedTalhao;
  
  const _CulturaLegend({
    Key? key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.selectedTalhao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obter culturas únicas
    final culturas = talhoes.map((t) => t.crop?.name ?? 'Sem cultura').toSet().toList()..sort();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Culturas',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: culturas.map((cultura) {
              // Obter cor da cultura
               final TalhaoModel? talhaoComCultura = talhoes.firstWhere(
                 (t) => t.crop?.name == cultura,
                 orElse: () => TalhaoModel(
                   id: '',
                   name: '',
                   poligonos: [],
                   area: 0,
                   dataCriacao: DateTime.now(),
                   dataAtualizacao: DateTime.now(),
                   sincronizado: false,
                   safras: [],
                   points: [],
                   syncStatus: '',
                 ),
               );
               final TalhaoModel talhaoTemp = TalhaoModel.points(
                 name: 'temp',
                 points: [],
                 crop: talhaoComCultura?.crop,
               );
              final cor = talhaoTemp.cor;
              
              return InkWell(
                onTap: () {
                  // Filtrar talhões por cultura
                  final culturaFiltrada = talhoes.where((t) => t.crop?.name == cultura).toList();
                  if (culturaFiltrada.isNotEmpty && onTalhaoSelected != null) {
                    onTalhaoSelected!(culturaFiltrada.first);
                  }
                }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: cor.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cor.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cultura,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Enum para tipos de mapa
enum MapType {
  normal,
  satellite,
  hybrid,
}