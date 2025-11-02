import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../repositories/plot_repository.dart';
import '../../repositories/property_repository.dart';
import '../../models/plot.dart';
import '../../models/property.dart';
import '../../utils/kml_parser.dart';
import '../../utils/latlng_adapter.dart';
import '../../widgets/loading_indicator.dart';

/// Tela para visualização e gerenciamento de talhões (plots) agrícolas
class PlotsScreen extends StatefulWidget {
  final int? propertyId;
  final String? propertyName;

  const PlotsScreen({
    Key? key,
    this.propertyId,
    this.propertyName,
  }) : super(key: key);

  @override
  State<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends State<PlotsScreen> with TickerProviderStateMixin {
  // Repositórios
  final PlotRepository _plotRepository = PlotRepository();
  final PropertyRepository _propertyRepository = PropertyRepository();
  
  // Controlador do mapa
  late MapController _mapController;
  
  // Variáveis de estado
  List<Plot> _plots = [];
  List<Property> _properties = [];
  Property? _selectedProperty;
  Plot? _selectedPlot;
  String? _selectedPlotId;
  String _propertyName = '';
  
  // Estado de carregamento e UI
  bool _isLoading = true;
  bool _isSidebarOpen = false;
  bool _isHighlightingPlot = false;
  
  // Estado de desenho e edição
  bool _isDrawingMode = false;
  List<LatLng> _drawingPoints = [];
  
  // Estado de rastreamento GPS
  bool _isGpsTrackingMode = false;
  
  // Localização atual do dispositivo
  LatLng? _currentLocation;
  bool _isGpsTracking = false;
  List<LatLng> _gpsTrackingPoints = [];
  LatLng? _currentPosition;
  Timer? _gpsTrackingTimer;
  
  // Cálculos
  double _currentArea = 0.0;
  
  // Controladores de texto
  final TextEditingController plotNameController = TextEditingController();
  Property? selectedFarm;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadData();
    _getCurrentLocation(); // Obter localização atual ao inicializar
  }
  
  @override
  void dispose() {
    _gpsTrackingTimer?.cancel();
    plotNameController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  // Carrega os dados iniciais
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carrega propriedades
      final properties = await _propertyRepository.getAllProperties();
      
      setState(() {
        _properties = properties;
        
        // Se foi passado um ID de propriedade, seleciona ela
        if (widget.propertyId != null && _properties.isNotEmpty) {
          try {
            _selectedProperty = _properties.firstWhere(
              (property) => property.id == widget.propertyId,
            );
          } catch (e) {
            _selectedProperty = _properties.first;
          }
        } else if (_properties.isNotEmpty) {
          _selectedProperty = _properties.first;
        }
        
        // Define o nome da propriedade
        if (widget.propertyName != null) {
          _propertyName = widget.propertyName!;
        } else if (_selectedProperty != null) {
          _propertyName = _selectedProperty!.name;
        }
      });
      
      // Se tem uma propriedade selecionada, carrega seus talhões
      if (_selectedProperty != null) {
        await _loadPlots(_selectedProperty!.id);
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar dados')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Carrega os talhões de uma propriedade
  Future<void> _loadPlots(int propertyId) async {
    try {
      final plots = await _plotRepository.getPlotsByFarmId(propertyId);
      
      if (mounted) {
        setState(() {
          _plots = plots;
          
          // Centraliza o mapa na propriedade se houver talhões
          if (_plots.isNotEmpty) {
            final bounds = _calculateBounds(_plots);
            _mapController.fitBounds(
              bounds,
              options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
            );
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar talhões: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar talhões')),
        );
      }
    }
  }
  
  // Calcula os limites para enquadrar todos os talhões no mapa
  LatLngBounds _calculateBounds(List<Plot> plots) {
    if (plots.isEmpty) {
      // Default para o Brasil se não houver talhões
      return LatLngBounds(
        LatLng(-33.7683, -73.9872),
        LatLng(5.2842, -34.7299),
      );
    }
    
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;
    
    for (final plot in plots) {
      if (plot.coordinates != null) {
        for (final point in plot.coordinates!) {
          minLat = math.min(minLat, point['latitude'] ?? 0.0);
          maxLat = math.max(maxLat, point['latitude'] ?? 0.0);
          minLng = math.min(minLng, point['longitude'] ?? 0.0);
          maxLng = math.max(maxLng, point['longitude'] ?? 0.0);
        }
      }
    }
    
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  // Calcula o centro de uma lista de coordenadas
  LatLng _calculateCenter(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      return LatLng(-15.7801, -47.9292); // Brasília como padrão
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final coord in coordinates) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }
    
    return LatLng(
      sumLat / coordinates.length,
      sumLng / coordinates.length,
    );
  }
  
  // Método para obter a localização atual
  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permissões de localização
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada'))
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões de localização negadas permanentemente. Habilite-as nas configurações do dispositivo.'))
        );
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _currentLocation = LatLng(position.latitude, position.longitude); // Armazenar também em _currentLocation
        _mapController.move(_currentLocation!, 15.0);
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível obter sua localização')),
        );
      }
    }
  }
  
  // Métodos para rastreamento GPS
  void _startGpsTracking() {
    setState(() {
      _isGpsTracking = true;
      _isGpsTrackingMode = true;
      _gpsTrackingPoints = [];
    });
    
    _gpsTrackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _addGpsPoint();
    });
    
    // Adiciona o primeiro ponto imediatamente
    _addGpsPoint();
  }
  
  void _stopGpsTracking() {
    setState(() {
      _isGpsTracking = false;
    });
    
    _gpsTrackingTimer?.cancel();
    _gpsTrackingTimer = null;
  }
  
  Future<void> _addGpsPoint() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newPoint = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _gpsTrackingPoints.add(newPoint);
          _currentPosition = newPoint;
          
          // Recalcular área se tiver pelo menos 3 pontos
          if (_gpsTrackingPoints.length >= 3) {
            _currentArea = _calculateArea(_gpsTrackingPoints);
          }
        });
      }
    } catch (e) {
      print('Erro ao rastrear ponto GPS: $e');
    }
  }
  
  // Método para importar arquivo KML
  Future<void> _importKmlFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml'],
      );
      
      if (result != null) {
        // Processar o arquivo KML
        // Implementação simplificada - na versão completa, usar KmlParser
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo KML selecionado. Implementação pendente.')),
          );
        }
      }
    } catch (e) {
      print('Erro ao importar arquivo KML: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao importar arquivo KML')),
        );
      }
    }
  }
  
  // Método para calcular área de um polígono em hectares
  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    
    // Implementação simplificada do cálculo de área
    // Em uma implementação completa, usar fórmula geodesic area
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
                area = (area.abs() * 111319.9 * 111319.9) / 100000000; // Conversão aproximada para hectares (corrigido)
    return area;
  }

  // Método auxiliar para converter Map<String, double> para LatLng
  List<LatLng> _convertToLatLng(List<Map<String, double>>? coordinates) {
    if (coordinates == null || coordinates.isEmpty) {
      return [];
    }
    
    return coordinates.map((coord) => LatLng(
      coord['latitude'] ?? 0.0,
      coord['longitude'] ?? 0.0,
    )).toList();
  }
  
  // Constrói os polígonos dos talhões para exibição no mapa
  List<Polygon> _buildPlotPolygons() {
    List<Polygon> polygons = [];
    
    for (final plot in _plots) {
      if (plot.coordinates != null && plot.coordinates!.isNotEmpty && plot.coordinates!.length >= 3) {
        final isHighlighted = _isHighlightingPlot && plot.id == _selectedPlotId;
        final latLngPoints = _convertToLatLng(plot.coordinates);
        
        if (latLngPoints.length >= 3) {
          polygons.add(
            Polygon(
              points: latLngPoints,
              color: isHighlighted 
                  ? Colors.yellow.withOpacity(0.5) 
                  : Colors.green.withOpacity(0.3),
              borderColor: isHighlighted 
                  ? Colors.orange 
                  : Colors.green,
              borderStrokeWidth: isHighlighted ? 3.0 : 2.0,
            ),
          );
        }
      }
    }
    
    // Adicionar polígono de desenho se houver pontos suficientes
    if (_drawingPoints.length >= 3) {
      polygons.add(
        Polygon(
          points: _drawingPoints,
          color: Colors.red.withOpacity(0.3),
          borderColor: Colors.red,
          borderStrokeWidth: 2.0,
        ),
      );
    }
    
    // Adicionar polígono de rastreamento GPS se houver pontos suficientes
    if (_gpsTrackingPoints.length >= 3) {
      polygons.add(
        Polygon(
          points: _gpsTrackingPoints,
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2.0,
        ),
      );
    }
    
    return polygons;
  }
  
  // Constrói o widget principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_propertyName.isNotEmpty ? _propertyName : 'Talhões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para tela de adicionar talhão
          Navigator.pushNamed(
            context,
            '/add-plot',
            arguments: {
              'propertyId': _selectedProperty?.id,
              'propertyName': _propertyName,
            },
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Constrói o conteúdo principal
  Widget _buildContent() {
    return Row(
      children: [
        // Sidebar com lista de talhões (se estiver aberta)
        if (_isSidebarOpen) _buildSidebar(),
        
        // Mapa e controles
        Expanded(
          child: Stack(
            children: [
              // Mapa
              _buildMap(),
              
              // Botão para abrir/fechar sidebar
              Positioned(
                top: 10,
                left: 10,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _isSidebarOpen = !_isSidebarOpen;
                    });
                  },
                  child: Icon(_isSidebarOpen ? Icons.chevron_left : Icons.list),
                ),
              ),
              
              // Painel de informações de desenho
              if (_isDrawingMode)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Modo desenho: ${_drawingPoints.length} pontos'),
                        Text('Área: ${_currentArea.toStringAsFixed(2)} ha'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _drawingPoints.clear();
                                  _currentArea = 0;
                                });
                              },
                              child: const Text('Limpar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _drawingPoints.length >= 3 ? () {
                                _saveDrawnPlot();
                              } : null,
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Painel de informações de rastreamento GPS
              if (_isGpsTrackingMode)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rastreamento GPS: ${_gpsTrackingPoints.length} pontos'),
                        Text('Área: ${_currentArea.toStringAsFixed(2)} ha'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: _isGpsTracking ? _stopGpsTracking : _startGpsTracking,
                              child: Text(_isGpsTracking ? 'Parar' : 'Iniciar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _gpsTrackingPoints.length >= 3 ? () {
                                _saveGpsPlot();
                              } : null,
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Botões de ação do mapa
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão de localização atual
                    FloatingActionButton(
                      heroTag: 'location',
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 10),
                    
                    // Botão de modo desenho
                    FloatingActionButton(
                      heroTag: 'draw',
                      onPressed: () {
                        setState(() {
                          _isDrawingMode = !_isDrawingMode;
                          if (_isDrawingMode) {
                            _isGpsTrackingMode = false;
                            _stopGpsTracking();
                            _drawingPoints = [];
                            _currentArea = 0;
                          }
                        });
                      },
                      backgroundColor: _isDrawingMode ? Colors.green : null,
                      child: const Icon(Icons.edit),
                    ),
                    const SizedBox(height: 10),
                    
                    // Botão de rastreamento GPS
                    FloatingActionButton(
                      heroTag: 'gps',
                      onPressed: () {
                        setState(() {
                          _isGpsTrackingMode = !_isGpsTrackingMode;
                          if (_isGpsTrackingMode) {
                            _isDrawingMode = false;
                            _gpsTrackingPoints = [];
                            _currentArea = 0;
                          } else {
                            _stopGpsTracking();
                          }
                        });
                      },
                      backgroundColor: _isGpsTrackingMode ? Colors.blue : null,
                      child: const Icon(Icons.gps_fixed),
                    ),
                    const SizedBox(height: 10),
                    
                    // Botão de importar KML
                    FloatingActionButton(
                      heroTag: 'kml',
                      onPressed: _importKmlFile,
                      child: const Icon(Icons.upload_file),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  




  // Constrói o mapa
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentLocation ?? LatLng(-15.7801, -47.9292), // Usa localização atual ou Brasília como centro padrão
        zoom: _currentLocation != null ? 15.0 : 5.0, // Zoom maior quando tem localização atual
        maxZoom: 18.0,
        minZoom: 3.0,
        interactiveFlags: InteractiveFlag.all,
        onTap: _handleMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.png?key={apiKey}',
          additionalOptions: const {
            'apiKey': 'KQAa9lY3N0TR17zxhk9u',
          },
        ),
        // Camada de polígonos dos talhões
        PolygonLayer(
          polygons: _buildPlotPolygons(),
        ),
        // Camada de pontos de desenho
        PolylineLayer(
          polylines: [
            if (_drawingPoints.length >= 2)
              Polyline(
                points: _drawingPoints,
                strokeWidth: 4.0,
                color: Colors.red,
              ),
            if (_gpsTrackingPoints.length >= 2)
              Polyline(
                points: _gpsTrackingPoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
          ],
        ),
        // Camada de marcadores
        MarkerLayer(
          markers: [
            // Marcador da posição atual
            if (_currentPosition != null)
              Marker(
                width: 40.0,
                height: 40.0,
                point: _currentPosition!,
                builder: (ctx) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.5),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
            // Marcadores dos pontos de desenho
            ..._drawingPoints.map(
              (point) => Marker(
                width: 16.0,
                height: 16.0,
                point: point,
                builder: (ctx) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            // Marcadores dos pontos de rastreamento GPS
            ..._gpsTrackingPoints.map(
              (point) => Marker(
                width: 12.0,
                height: 12.0,
                point: point,
                builder: (ctx) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Constrói o widget da barra lateral
  Widget _buildSidebar() {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da barra lateral
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Talhões',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Seletor de propriedade
          if (_properties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<Property>(
                decoration: const InputDecoration(
                  labelText: 'Propriedade',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProperty,
                items: _properties.map((property) {
                  return DropdownMenuItem<Property>(
                    value: property,
                    child: Text(property.name ?? 'Sem nome'),
                  );
                }).toList(),
                onChanged: (property) {
                  if (property != null && property.id != _selectedProperty?.id) {
                    setState(() {
                      _selectedProperty = property;
                      _propertyName = property.name ?? '';
                      _selectedPlot = null;
                      _selectedPlotId = null;
                    });
                    
                    // Carregar talhões da propriedade selecionada
                    _loadPlots(property.id!);
                  }
                },
              ),
            ),
          
          // Lista de talhões
          Expanded(
            child: _plots.isEmpty
                ? const Center(child: Text('Nenhum talhão encontrado'))
                : ListView.builder(
                    itemCount: _plots.length,
                    itemBuilder: (context, index) {
                      final plot = _plots[index];
                      final isSelected = plot.id == _selectedPlotId;
                      
                      return ListTile(
                        title: Text(plot.name),
                        subtitle: Text('Área: ${plot.area?.toStringAsFixed(2) ?? '?'} ha'),
                        selected: isSelected,
                        tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                        onTap: () {
                          setState(() {
                            _selectedPlot = plot;
                            _selectedPlotId = plot.id;
                            _isHighlightingPlot = true;
                          });
                          
                          // Centralizar mapa no talhão selecionado
                          if (plot.coordinates != null && plot.coordinates!.isNotEmpty) {
                            final latLngPoints = _convertToLatLng(plot.coordinates);
                            final center = _calculateCenter(latLngPoints);
                            _mapController.move(center, 15.0);
                          }
                          
                          // Desativar destaque após alguns segundos
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted) {
                              setState(() {
                                _isHighlightingPlot = false;
                              });
                            }
                          });
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showPlotOptions(plot);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  // Mostra opções para um talhão
  void _showPlotOptions(Plot plot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              // Implementar edição do talhão
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Excluir'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeletePlot(plot);
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Visualizar detalhes'),
            onTap: () {
              Navigator.pop(context);
              // Implementar visualização detalhada do talhão
            },
          ),
        ],
      ),
    );
  }
  
  // Confirma exclusão de um talhão
  void _confirmDeletePlot(Plot plot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir talhão'),
        content: Text('Tem certeza que deseja excluir o talhão "${plot.name ?? 'sem nome'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlot(plot);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
  
  // Exclui um talhão
  Future<void> _deletePlot(Plot plot) async {
    try {
      await _plotRepository.delete(plot.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talhão excluído com sucesso')),
        );
        
        // Recarregar talhões
        if (_selectedProperty != null) {
          _loadPlots(_selectedProperty!.id!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir talhão: $e')),
        );
      }
    }
  }
  
  // Método para lidar com toques no mapa
  void _handleMapTap(dynamic tapPosition, LatLng point) {
    if (_isDrawingMode) {
      setState(() {
        _drawingPoints.add(point);
        
        // Recalcular área se tiver pelo menos 3 pontos
        if (_drawingPoints.length >= 3) {
          _currentArea = _calculateArea(_drawingPoints);
        }
      });
    }
  }

  // Salva o talhão desenhado manualmente
  void _saveDrawnPlot() {
    if (_drawingPoints.length < 3 || _selectedProperty == null) return;
    
    // Abrir diálogo para inserir nome do talhão
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar talhão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plotNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do talhão',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _savePlot(_drawingPoints, plotNameController.text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  // Salva o talhão criado por rastreamento GPS
  void _saveGpsPlot() {
    if (_gpsTrackingPoints.length < 3 || _selectedProperty == null) return;
    
    // Abrir diálogo para inserir nome do talhão
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar talhão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plotNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do talhão',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _savePlot(_gpsTrackingPoints, plotNameController.text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  // Método comum para salvar um talhão
  Future<void> _savePlot(List<LatLng> coordinates, String name) async {
    if (_selectedProperty == null) return;
    
    try {
      // Limpar o controller após uso
      plotNameController.clear();
      
      // Calcular área
      final area = _calculateArea(coordinates);
      
      // Converter coordenadas para o formato esperado pelo modelo Plot
      final List<Map<String, double>> plotCoordinates = coordinates.map((latLng) => {
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
      }).toList();
      
      // Data atual para campos de data
      final now = DateTime.now().toIso8601String();
      
      // Criar novo talhão
      final plot = Plot(
        name: name.isNotEmpty ? name : 'Novo talhão',
        propertyId: _selectedProperty!.id,
        farmId: _selectedProperty!.id, // Usando propertyId como farmId
        coordinates: plotCoordinates,
        area: area,
        createdAt: now,
        updatedAt: now,
      );
      
      // Salvar no repositório
      await _plotRepository.save(plot);
      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talhão salvo com sucesso')),
        );
        
        // Limpar pontos e recarregar talhões
        setState(() {
          _drawingPoints = [];
          _gpsTrackingPoints = [];
          _currentArea = 0;
          _isDrawingMode = false;
          _isGpsTrackingMode = false;
        });
        
        // Recarregar talhões
        _loadPlots(_selectedProperty!.id);
      }
    } catch (e) {
      print('Erro ao salvar talhão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar talhão: $e')),
        );
      }
    }
  }
  
}