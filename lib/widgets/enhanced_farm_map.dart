import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fortsmart_agro/models/talhao_model.dart';
import 'package:fortsmart_agro/models/agricultural_product.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/utils/maptiler_constants.dart';
import 'package:fortsmart_agro/utils/color_converter.dart';
import 'package:fortsmart_agro/utils/cultura_colors.dart';

/// Widget para exibir um mapa da fazenda com talhões coloridos por cultura
class EnhancedFarmMap extends StatefulWidget {
  final List<TalhaoModel>? talhoes;
  final Function(TalhaoModel)? onTalhaoTap;
  final double initialZoom;
  final bool showControls;
  final bool isInteractive;
  final LatLng? initialCenter;
  final bool showLegend;
  final bool showSatelliteLayer;

  const EnhancedFarmMap({
    Key? key,
    this.talhoes,
    this.onTalhaoTap,
    this.initialZoom = 14.0,
    this.showControls = true,
    this.isInteractive = true,
    this.initialCenter,
    this.showLegend = true,
    this.showSatelliteLayer = true,
  }) : super(key: key);

  @override
  State<EnhancedFarmMap> createState() => _EnhancedFarmMapState();
}

class _EnhancedFarmMapState extends State<EnhancedFarmMap> {
  late MapController _mapController;
  double _currentZoom = 14.0;
  List<TalhaoModel> _talhoes = [];
  List<dynamic> _culturas = [];
  bool _isLoading = true;
  final DataCacheService _dataCacheService = DataCacheService();
  
  // Mapa de cores por cultura (id da cultura -> cor)
  final Map<String, Color> _coresPorCultura = {};
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentZoom = widget.initialZoom;
    _loadData();
  }
  
  @override
  void didUpdateWidget(EnhancedFarmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.talhoes != oldWidget.talhoes) {
      _updateTalhoes();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<dynamic> culturas = [];
      try {
        final cachedCulturas = await _dataCacheService.getCulturas(forceRefresh: true);
        culturas = cachedCulturas;
      } catch (e) {
        print('Erro ao carregar culturas: $e');
      }
      
      // Carregar talhões se não foram fornecidos
      List<TalhaoModel> talhoes = widget.talhoes ?? [];
      if (talhoes.isEmpty) {
        // Usar o método getTalhoesNovos que já retorna o modelo correto
        talhoes = (await _dataCacheService.getTalhoesNovos(forceRefresh: true)).cast<TalhaoModel>();
      }
      
      // Criar mapa de cores por cultura
      for (var cultura in culturas) {
        // Como Crop não tem colorValue, usamos cores padrão baseadas no nome
        _coresPorCultura[cultura.id.toString()] = _getDefaultColor(cultura.name);
      }
      
      setState(() {
        _culturas = culturas;
        _talhoes = talhoes;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do mapa: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateTalhoes() {
    if (widget.talhoes != null) {
      setState(() {
        _talhoes = widget.talhoes!;
      });
    }
  }
  
  Color _getDefaultColor(String culturaName) {
    return CulturaColorsUtils.getColorForName(culturaName);
  }
  
  Color _getTalhaoColor(TalhaoModel talhao) {
    // Se o talhão tem informação de safra com cultura, usar a cor da cultura
    if (talhao.safras.isNotEmpty && talhao.safras.first.culturaId != null) {
      String culturaId = talhao.safras.first.culturaId.toString();
      var corCultura = _coresPorCultura[culturaId];
      if (corCultura != null) {
        return corCultura;
      } else {
        // Converter talhao.cor (que pode ser String ou Color) para Color
        return ColorConverter.ensureColor(talhao.cor);
      }
    }
    
    // Cor padrão para talhões sem cultura
    return Colors.grey.withOpacity(0.7);
  }
  
  LatLng _calculateMapCenter() {
    if (_talhoes.isEmpty) {
      // Coordenadas padrão (centro do Brasil)
      return LatLng(-15.77972, -47.92972);
    }
    
    // Calcular o centro baseado em todos os talhões
    double sumLat = 0;
    double sumLng = 0;
    int count = 0;
    
    for (var talhao in _talhoes) {
      if (talhao.poligonos.isNotEmpty) {
        for (var poligono in talhao.poligonos) {
          for (var coord in poligono) {
            sumLat += coord.latitude;
            sumLng += coord.longitude;
            count++;
          }
        }
      }
    }
    
    return count > 0 
      ? LatLng(sumLat / count, sumLng / count)
      : LatLng(-15.77972, -47.92972);
  }
  
  List<Polygon> _buildTalhaoPolygons() {
    final List<Polygon> polygons = [];
    
    for (var talhao in _talhoes) {
      if (talhao.poligonos.isNotEmpty) {
        for (var poligono in talhao.poligonos) {
          final List<LatLng> points = poligono
              .map((coord) => LatLng(
                    coord.latitude,
                    coord.longitude,
                  ))
              .toList();
          
          if (points.length >= 3) {
            final talhaoColor = _getTalhaoColor(talhao);
            polygons.add(
              Polygon(
                points: points,
                color: talhaoColor.withOpacity(0.5),
                borderColor: talhaoColor,
                borderStrokeWidth: 2.0,
                isFilled: true,
                label: talhao.nome,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  // backgroundColor: Colors.black45, // backgroundColor não é suportado em flutter_map 5.0.0
                  fontSize: 12,
                ),
                holePointsList: null,
                rotateLabel: false,
                // Usando o campo onTap do Polygon
                // Nota: Se este campo não existir na versão do flutter_map, será necessário atualizar a biblioteca
                // ou implementar uma solução alternativa com GestureDetector
              ),
            );
          }
        }
      }
    }
    
    return polygons;
  }
  
  Widget _buildLegend() {
    // Agrupar talhões por cultura
    final Map<String, List<TalhaoModel>> talhoesPorCultura = {};
    
    for (var talhao in _talhoes) {
      if (talhao.safras.isNotEmpty && talhao.safras.first.culturaId != null) {
        String culturaId = talhao.safras.first.culturaId.toString();
        if (!talhoesPorCultura.containsKey(culturaId)) {
          talhoesPorCultura[culturaId] = [];
        }
        talhoesPorCultura[culturaId]!.add(talhao);
      }
    }
    
    // Criar itens da legenda
    final List<Widget> legendItems = [];
    
    // Adicionar culturas com talhões
    talhoesPorCultura.forEach((culturaId, talhoes) {
      final cultura = _culturas.firstWhere(
        (c) => c.id == culturaId,
        orElse: () => AgriculturalProduct(
          name: 'Desconhecida',
          type: ProductType.seed,
        ),
      );
      
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _coresPorCultura[culturaId] ?? Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${cultura.name} (${talhoes.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    // Adicionar talhões sem cultura
    final talhoesSemCultura = _talhoes.where((t) => t.culturaId == null).toList();
    if (talhoesSemCultura.isNotEmpty) {
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sem cultura (${talhoesSemCultura.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Culturas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...legendItems,
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Determinar o centro do mapa
    final center = widget.initialCenter ?? _calculateMapCenter();
    
    return Stack(
      children: [
        // Mapa
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: center,
            zoom: _currentZoom,
            maxZoom: 18.0,
            minZoom: 4.0,
            interactiveFlags: widget.isInteractive
                ? InteractiveFlag.all
                : InteractiveFlag.none,
          ),
          children: [
            // Camada de mapa base (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Camada de satélite (opcional)
            if (widget.showSatelliteLayer)
              TileLayer(
                urlTemplate: MapTilerConstants.satelliteUrl,
                additionalOptions: {
                  'apiKey': MapTilerConstants.apiKey,
                },
              ),
            
            // Camada de polígonos dos talhões
            PolygonLayer(
              polygons: _buildTalhaoPolygons(),
            ),
          ],
        ),
        
        // Indicador de carregamento
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        
        // Controles de zoom
        if (widget.showControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    setState(() {
                      _currentZoom = (_currentZoom + 1).clamp(4.0, 18.0);
                      _mapController.move(_mapController.center, _currentZoom);
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    setState(() {
                      _currentZoom = (_currentZoom - 1).clamp(4.0, 18.0);
                      _mapController.move(_mapController.center, _currentZoom);
                    });
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: () {
                    // Implementar localização atual
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        
        // Legenda
        if (widget.showLegend && !_isLoading)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildLegend(),
          ),
      ],
    );
  }
}
