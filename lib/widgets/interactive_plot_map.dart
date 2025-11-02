import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models/plot.dart';
import '../utils/mapbox_compatibility_adapter.dart' as mapbox;
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong2;
import '../utils/mapbox_utils_new.dart';
import '../models/agricultural_product.dart';
import '../database/models/crop.dart' as db_crop;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/data_cache_service.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class InteractivePlotMap extends StatefulWidget {
  final List<Plot> plots;
  final Function(String) onPlotTap;
  final bool showLegend;
  final String mapboxAccessToken;
  final String? selectedPlotId;

  const InteractivePlotMap({
    Key? key,
    required this.plots,
    required this.onPlotTap,
    this.showLegend = true,
    required this.mapboxAccessToken,
    this.selectedPlotId,
  }) : super(key: key);
  
  @override
  _InteractivePlotMapState createState() => _InteractivePlotMapState();
}

class _InteractivePlotMapState extends State<InteractivePlotMap> {
  mapbox.MapboxMapControllerAdapter? _mapController;
  final Set<dynamic> _polygons = {};
  final Set<dynamic> _markers = {};
  late DataCacheService _dataCacheService;
  Map<String, AgriculturalProduct> _culturas = {}; // Mapa de ID para objeto cultura
  
  // Controlador do mapa Flutter
  flutter_map.MapController? _flutterMapController;
  // Flag para controlar se estamos obtendo a localização
  bool _isGettingLocation = false;
  bool _showUserLocation = true;
  latlong2.LatLng? _userLocation;
  
  @override
  void initState() {
    super.initState();
    _dataCacheService = Provider.of<DataCacheService>(context, listen: false);
    _flutterMapController = flutter_map.MapController();
    _loadCulturas().then((_) {
      _createPolygonsAndMarkers();
    });
    _getUserLocation();
  }
  
  // Carrega as culturas do módulo de Culturas e Pragas
  Future<void> _loadCulturas() async {
    try {
      // O método getCulturas retorna List<AgriculturalProduct>, precisamos converter para Map<String, AgriculturalProduct>
      final List<AgriculturalProduct> culturasList = await _dataCacheService.getCulturas();
      final Map<String, AgriculturalProduct> culturasMap = {};
      
      // Adicionar cada AgriculturalProduct ao mapa
      for (final cultura in culturasList) {
        culturasMap[cultura.id] = cultura;
      }
      
      if (mounted) {
        setState(() {
          _culturas = culturasMap;
        });
      }
      
      debugPrint('Carregadas ${_culturas.length} culturas no mapa');
    } catch (e) {
      debugPrint('Erro ao carregar culturas: $e');
    }
  }
  
  // Obtém a localização atual do usuário
  Future<void> _getUserLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permissão de localização negada');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada')),
          );
          setState(() {
            _isGettingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permissão de localização negada permanentemente');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões de localização negadas permanentemente')),
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }
      
      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      if (mounted) {
        setState(() {
          _userLocation = latlong2.LatLng(position.latitude, position.longitude);
          _isGettingLocation = false;
          // Centralizar o mapa na posição do usuário
          if (_flutterMapController != null) {
            _flutterMapController!.move(_userLocation!, 15.0);
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }
  
  @override
  void didUpdateWidget(InteractivePlotMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plots != widget.plots || 
        oldWidget.selectedPlotId != widget.selectedPlotId) {
      _createPolygonsAndMarkers();
    }
  }
  
  void _createPolygonsAndMarkers() {
    final polygons = <dynamic>{};
    final markers = <dynamic>{};
    
    for (final plot in widget.plots) {
      try {
        // Obter a cor com base no tipo de cultura
        Color plotColor = _getCulturaColor(plot.culturaId);
        
        // Usando "ok" como status padrão já que a classe Plot não tem status
        String status = 'ok';
        IconData markerIcon;
        
        switch (status.toLowerCase()) {
          case 'critical':
            markerIcon = Icons.warning;
            break;
          case 'warning':
            markerIcon = Icons.info_outline;
            break;
          default:
            markerIcon = Icons.check_circle_outline;
        }
        
        // Criar polígono
        final polygonId = plot.id ?? 'unknown';
        final coordinates = _parseCoordinates(plot.polygonJson ?? '[]');
        
        if (coordinates.isNotEmpty) {
          // No adaptador de compatibilidade, não precisamos criar um polígono real
          // apenas armazenar os dados para renderizar no mapa
          final polygon = {
            'id': polygonId,
            'points': coordinates,
            'fillColor': widget.selectedPlotId == plot.id 
                ? plotColor.withOpacity(0.7) 
                : plotColor.withOpacity(0.3),
            'strokeColor': plotColor,
            'strokeWidth': 2,
          };
          polygons.add(polygon);
          
          // Criar marcador no centro do polígono
          final center = _calculatePolygonCenter(coordinates);
          final markerId = plot.id ?? 'unknown';
          
          // No adaptador de compatibilidade, não precisamos criar um marcador real
          // apenas armazenar os dados para renderizar no mapa
          // Obter o nome real da cultura para o snippet do marcador
          String culturaNome = 'Sem cultura';
          if (plot.culturaId != null && _culturas.containsKey(plot.culturaId)) {
            culturaNome = _culturas[plot.culturaId]?.name ?? plot.cropType ?? 'Sem cultura';
          } else if (plot.cropType != null) {
            culturaNome = plot.cropType!;
          }
          
          final marker = {
            'id': markerId,
            'position': center,
            'icon': markerIcon,
            'title': plot.name,
            'snippet': culturaNome,
            'onTap': () {
              widget.onPlotTap(plot.id ?? '');
            },
          };
          markers.add(marker);
        }
      } catch (e) {
        debugPrint('Erro ao processar talhão: $e');
      }
    }
    
    setState(() {
      _polygons.clear();
      _polygons.addAll(polygons);
      _markers.clear();
      _markers.addAll(markers);
    });

    // Centralizar o mapa
    _fitBoundsToPolygons();
  }

  // Retorna a cor correspondente a uma cultura pelo ID
  Color _getCulturaColor(String? culturaId) {
    if (culturaId == null || culturaId.isEmpty || !_culturas.containsKey(culturaId)) {
      return Colors.grey; // Cor padrão se não houver cultura
    }
    
    final cultura = _culturas[culturaId];
    if (cultura?.colorValue != null) {
      // Cultura não é nulo e colorValue não é nulo, podemos fazer o null check uma vez
      final nonNullCultura = cultura!;
      try {
        // Verificar se colorValue já é um inteiro ou uma string
        if (nonNullCultura.colorValue is int) {
          return Color(nonNullCultura.colorValue as int);
        } else if (nonNullCultura.colorValue is String && (nonNullCultura.colorValue as String).isNotEmpty) {
          // Tentar converter o valor da string para um inteiro
          final colorStr = nonNullCultura.colorValue as String;
          final colorInt = int.parse(colorStr.startsWith('#') ? colorStr.substring(1) : colorStr, radix: 16);
          return Color(colorInt);
        }
      } catch (e) {
        // Se não conseguir converter, usar uma cor padrão
        print('Erro ao converter cor: $e');
      }
    }
    
    // Usar um sistema de cores baseado no hash do ID com cores mais vibrantes
    final List<Color> coresCulturas = [
      Color(0xFF2E7D32), // Verde escuro
      Color(0xFF1565C0), // Azul escuro
      Color(0xFFC62828), // Vermelho escuro
      Color(0xFFEF6C00), // Laranja escuro
      Color(0xFF6A1B9A), // Roxo escuro
      Color(0xFF00695C), // Verde-azulado escuro
      Color(0xFFFF8F00), // Âmbar escuro
      Color(0xFF283593), // Índigo escuro
      Color(0xFFC2185B), // Rosa escuro
      Color(0xFF0097A7), // Ciano escuro
      Color(0xFF4E342E), // Marrom escuro
      Color(0xFFD84315), // Laranja profundo
      Color(0xFF558B2F), // Verde limão escuro
      Color(0xFF0D47A1), // Azul escuro
      Color(0xFF880E4F), // Rosa escuro
    ];
    
    // Gerar um índice baseado no hash do ID para selecionar uma cor consistente
    final colorIndex = culturaId.hashCode % coresCulturas.length;
    return coresCulturas[colorIndex.abs()];
  }


  

  

  
  // Retorna a cor correspondente ao status do talhão
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'crítico':
      case 'critico':
        return Colors.red;
      case 'atenção':
      case 'atencao':
        return Colors.orange;
      case 'ok':
        return Colors.green;
      case 'selecionado':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  List<mapbox.MapboxLatLng> _parseCoordinates(String polygonData) {
    try {
      final List<dynamic> points = jsonDecode(polygonData);
      return points.map<mapbox.MapboxLatLng>((point) {
        return mapbox.MapboxLatLng(
          point['latitude'] as double,
          point['longitude'] as double,
        );
      }).toList();
    } catch (e) {
      print('Erro ao analisar coordenadas: $e');
      return [];
    }
  }

  mapbox.MapboxLatLng _calculatePolygonCenter(List<mapbox.MapboxLatLng> coordinates) {
    if (coordinates.isEmpty) {
      return mapbox.MapboxLatLng(0, 0);
    }

    double latitude = 0;
    double longitude = 0;

    for (var coordinate in coordinates) {
      latitude += coordinate.latitude;
      longitude += coordinate.longitude;
    }

    return mapbox.MapboxLatLng(
      latitude / coordinates.length,
      longitude / coordinates.length,
    );
  }

  void _fitBoundsToPolygons() {
    if (_polygons.isEmpty) return;

    // Calcular os limites de todos os polígonos
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;

    for (var polygon in _polygons) {
      final points = (polygon['points'] as List<mapbox.MapboxLatLng>);
      for (var point in points) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
    }

    // Adicionar um pequeno padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    final bounds = flutter_map.LatLngBounds(
      latlong2.LatLng(minLat - latPadding, minLng - lngPadding),
      latlong2.LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    // Como estamos usando flutter_map, precisamos ajustar a abordagem
    // para ajustar os limites do mapa
    if (_flutterMapController != null) {
      // Usando a API do flutter_map para ajustar os limites
      final latLngBounds = bounds;
      _flutterMapController?.fitBounds(latLngBounds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Mapa principal
              flutter_map.FlutterMap(
                mapController: _flutterMapController,
                options: flutter_map.MapOptions(
                  center: _userLocation ?? latlong2.LatLng(-15.793889, -47.882778), // Usar localização do usuário ou centro do Brasil como padrão
                  zoom: _userLocation != null ? 15.0 : 5.0,
                  onTap: (tapPosition, latLng) {
                    // Verificar se o toque foi em algum polígono
                    for (var polygon in _polygons) {
                      final points = (polygon['points'] as List<mapbox.MapboxLatLng>)
                          .map((p) => latlong2.LatLng(p.latitude, p.longitude))
                          .toList();

                      if (MapboxUtils.isPointInPolygon(latLng, points)) {
                        widget.onPlotTap(polygon['id'] as String);
                        break;
                      }
                    }
                  },
                  onMapReady: () {
                    // Ajustar os limites do mapa após a criação
                    Future.delayed(Duration(milliseconds: 500), () {
                      _fitBoundsToPolygons();
                    });
                  },
                ),
                children: [
                  // Camada de tiles (mapa base)
                  flutter_map.TileLayer(
                    urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.png?key={apiKey}',
                    additionalOptions: {
                      'apiKey': 'KQAa9lY3N0TR17zxhk9u', // Chave de API do MapTiler
                    },
                  ),
                  // Camada de polígonos
                  flutter_map.PolygonLayer(
                    polygons: _polygons.map((polygon) {
                      final points = (polygon['points'] as List<mapbox.MapboxLatLng>)
                          .map((p) => latlong2.LatLng(p.latitude, p.longitude))
                          .toList();

                      return flutter_map.Polygon(
                        points: points,
                        color: polygon['fillColor'] as Color,
                        borderColor: polygon['strokeColor'] as Color,
                        borderStrokeWidth: (polygon['strokeWidth'] as int).toDouble(),
                      );
                    }).toList(),
                  ),
                  // Camada de marcadores
                  flutter_map.MarkerLayer(
                    markers: _markers.map((marker) {
                      final position = (marker['position'] as mapbox.MapboxLatLng);
                      final latLng = latlong2.LatLng(position.latitude, position.longitude);

                       return flutter_map.Marker(
                        point: latLng,
                        child: GestureDetector(
                          onTap: () {
                            widget.onPlotTap(marker['id'] as String);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                marker['icon'] as IconData,
                                color: _getStatusColor(marker['snippet'] as String),
                                size: 24.0,
                              ),
                              Text(
                                marker['title'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Camada de localização do usuário
                  if (_showUserLocation && _userLocation != null)
                    flutter_map.MarkerLayer(
                      markers: [
                        flutter_map.Marker(
                          point: _userLocation!,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Informações sobre o mapa
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xEE333333), // Fundo escuro semi-transparente para melhor contraste
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Talhões: ${widget.plots.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.selectedPlotId != null)
                        Text(
                          'Selecionado: ${widget.plots.firstWhere(
                                (p) => p.id == widget.selectedPlotId,
                                orElse: () => Plot(name: 'Desconhecido', farmId: 0, propertyId: 0, createdAt: '', updatedAt: ''),
                              ).name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Botão de centralização GPS
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xEE333333), // Fundo escuro semi-transparente para melhor contraste
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: 'Centralizar no GPS',
                    onPressed: _isGettingLocation ? null : _getUserLocation,
                  ),
                ),
              ),
              // Legenda (opcional)
              if (widget.showLegend)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xEE333333), // Fundo escuro semi-transparente para melhor contraste
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Culturas:', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _buildCultureLegendItems(),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Status:', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildStatusLegend('Normal', Colors.green),
                            _buildStatusLegend('Atenção', Colors.orange),
                            _buildStatusLegend('Crítico', Colors.red),
                            _buildStatusLegend('Selecionado', Colors.yellow),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Constrói um item da legenda de culturas
  Widget _buildLegendItem(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Constrói um item da legenda de status
  Widget _buildStatusLegend(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 6, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Gera itens de legenda dinamicamente a partir das culturas presentes nos talhões
  List<Widget> _buildCultureLegendItems() {
    // Mapa para armazenar culturas únicas e suas cores
    final Map<String, Color> culturas = {};
    
    // Adiciona uma entrada para 'Sem cultura'
    culturas['Sem cultura'] = Colors.grey.withOpacity(0.5);
    
    // Coleta todas as culturas únicas dos talhões
    for (var plot in widget.plots) {
      if (plot.culturaId != null) {
        // Buscar o nome real da cultura no mapa de culturas carregado
        String culturaNome;
        Color culturaColor;
        
        if (_culturas.containsKey(plot.culturaId)) {
          // Usar o nome real da cultura se estiver disponível
          culturaNome = _culturas[plot.culturaId]?.name ?? plot.culturaId!;
          culturaColor = _getCulturaColor(plot.culturaId!);
        } else {
          // Fallback para o ID da cultura se não estiver disponível
          culturaNome = plot.culturaId!;
          culturaColor = _getCulturaColor(plot.culturaId!);
        }
        
        culturas[culturaNome] = culturaColor;
      }
    }
    
    // Converte o mapa em uma lista de widgets de legenda
    return culturas.entries.map((entry) {
      return _buildLegendItem(entry.key, entry.value);
    }).toList();
  }
}
