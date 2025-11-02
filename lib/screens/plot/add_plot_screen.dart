import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import '../../models/plot.dart';
import '../../models/property.dart';
import '../../repositories/plot_repository.dart';
import '../../repositories/property_repository.dart';
import '../../utils/constants.dart';

// Classe auxiliar para armazenar centro e zoom do mapa
class _MapCenter {
  final latlong2.LatLng center;
  final double zoom;
  
  _MapCenter(this.center, this.zoom);
}

class AddPlotScreen extends StatefulWidget {
  final int? propertyId;
  final Plot? plot; // Se fornecido, estamos editando um talhão existente
  
  const AddPlotScreen({
    Key? key,
    this.propertyId,
    this.plot,
  }) : super(key: key);
  
  @override
  _AddPlotScreenState createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  // Controladores e repositórios
  final PlotRepository _plotRepository = PlotRepository();
  final PropertyRepository _propertyRepository = PropertyRepository();
  final TextEditingController _nameController = TextEditingController();
  
  // Estado da tela
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Dados
  List<Property> _properties = [];
  Property? _selectedProperty;
  List<latlong2.LatLng> _points = [];
  List<Polygon> _polygons = [];
  double _area = 0.0;
  
  // MapTiler controller
  late MapController _mapController;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  // Carregar dados iniciais
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar propriedades
      _properties = await _propertyRepository.getAllProperties();
      
      if (_properties.isNotEmpty) {
        // Definir propriedade selecionada
        if (widget.propertyId != null) {
          _selectedProperty = _properties.firstWhere(
            (p) => p.id == widget.propertyId,
            orElse: () => _properties.first,
          );
        } else {
          _selectedProperty = _properties.first;
        }
        
        // Carregar pontos do talhão se estiver editando
        if (widget.plot != null && widget.plot!.coordinates != null) {
          _loadPlotPoints();
        } else {
          _getUserLocation();
        }
      } else {
        _showError('Nenhuma propriedade encontrada. Cadastre uma propriedade primeiro.');
      }
    } catch (e) {
      _showError('Erro ao carregar propriedades: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Carregar pontos do talhão para edição
  void _loadPlotPoints() {
    final coordinates = widget.plot!.coordinates;
    if (coordinates != null) {
      setState(() {
        _points = coordinates
            .map((coord) => latlong2.LatLng(
                  coord['latitude'] as double,
                  coord['longitude'] as double,
                ))
            .toList();
        
        // Atualizar área
        _area = widget.plot!.area ?? 0.0;
        
        // Atualizar nome
        _nameController.text = widget.plot!.name;
        
        // Atualizar propriedade selecionada
        final propertyId = widget.plot!.propertyId;
        _selectedProperty = _properties.firstWhere(
          (p) => p.id == propertyId,
          orElse: () => _properties.first,
        );
        
        // Centralizar mapa nos pontos
        _centerMapOnPoints();
      });
    }
  }
  
  // Configurar polígono no mapa
  void _setupPolygon() {
    if (_points.length < 3) {
      _polygons = [];
      return;
    }
    
    _polygons = [
      Polygon(
        points: _points,
        color: Colors.green.withOpacity(0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 2,
        isFilled: true,
      ),
    ];
    
    // Calcular área
    _area = _calculateArea();
  }
  
  // Calcular área do polígono em hectares
  double _calculateArea() {
    if (_points.length < 3) return 0.0;
    
    // Implementar cálculo de área usando fórmula de Shoelace
    double area = 0.0;
    
    for (int i = 0; i < _points.length; i++) {
      int j = (i + 1) % _points.length;
      area += _points[i].latitude * _points[j].longitude;
      area -= _points[j].latitude * _points[i].longitude;
    }
    
    area = area.abs() * 0.5;
    
    // Converter para hectares (aproximação simples)
    // Fator de conversão depende da latitude
    double avgLat = 0.0;
    for (final point in _points) {
      avgLat += point.latitude;
    }
    avgLat /= _points.length;
    
    // Fator de conversão aproximado (varia com a latitude)
    // Usar cos(latitude) para ajustar o fator de conversão
    double latRad = avgLat * pi / 180.0;
    double factor = 111320.0 * 111320.0 * cos(latRad) / 10000.0; // metros quadrados para hectares
    
    // Atualizar a área do campo
    _area = area * factor;
    return _area;
  }
  
  // Obter localização atual
  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        if (_points.isEmpty) {
          // Centralizar mapa na posição atual
          _initialMapCenter = latlong2.LatLng(position.latitude, position.longitude);
          _initialZoom = 15.0;
        } else {
          // Centralizar mapa no polígono existente
          final center = _calculateMapCenter();
          _initialMapCenter = center.center;
          _initialZoom = center.zoom;
        }
      });
      
      // Mover o mapa para a posição inicial se o controlador estiver inicializado
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.move(_initialMapCenter, _initialZoom);
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
      
      // Usar posição padrão se não conseguir obter a localização atual
      setState(() {
        if (_points.isEmpty) {
          _initialMapCenter = const latlong2.LatLng(-15.7801, -47.9292); // Brasil
          _initialZoom = 15.0;
        } else {
          final center = _calculateMapCenter();
          _initialMapCenter = center.center;
          _initialZoom = center.zoom;
        }
      });
    }
  }
  
  // Calcular centro do mapa e zoom adequado para mostrar todo o polígono
  _MapCenter _calculateMapCenter() {
    if (_points.isEmpty) {
      return _MapCenter(const latlong2.LatLng(-15.7801, -47.9292), 15.0); // Brasil
    }
    
    // Calcular limites do polígono
    double minLat = _points[0].latitude;
    double maxLat = _points[0].latitude;
    double minLng = _points[0].longitude;
    double maxLng = _points[0].longitude;
    
    for (var point in _points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    // Calcular centro
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // Adicionar um pequeno padding para o cálculo do zoom
    final latDiff = (maxLat - minLat) * 1.2; // 20% de padding
    final lngDiff = (maxLng - minLng) * 1.2; // 20% de padding
    
    // Calcular zoom apropriado (simplificado)
    final latZoom = _calculateZoomLevel(latDiff);
    final lngZoom = _calculateZoomLevel(lngDiff);
    final zoom = min(latZoom, lngZoom);
    
    return _MapCenter(latlong2.LatLng(centerLat, centerLng), zoom);
  }
  
  // Calcula um nível de zoom apropriado com base na diferença de coordenadas
  double _calculateZoomLevel(double difference) {
    if (difference <= 0) return 15.0;
    return 15.0 - log(difference * 111000) / log(2);
  }
  
  // Centralizar mapa nos pontos
  void _centerMapOnPoints() {
    if (_points.isEmpty) return;
    
    final center = _calculateMapCenter();
    _mapController.move(center.center, center.zoom);
  }
  
  // Posição inicial do mapa
  latlong2.LatLng _initialMapCenter = const latlong2.LatLng(-15.7801, -47.9292); // Brasil
  double _initialZoom = 15.0;
  
  // Adicionar ponto ao polígono
  void _addPoint(latlong2.LatLng point) {
    setState(() {
      _points.add(point);
      
      // Recalcular centro e zoom do mapa
      final center = _calculateMapCenter();
      _initialMapCenter = center.center;
      _initialZoom = center.zoom;
    });
  }
  
  // Remover último ponto do polígono
  void _removeLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
        _setupPolygon();
      });
    }
  }
  
  // Limpar todos os pontos
  void _clearPoints() {
    setState(() {
      _points = [];
      _polygons = [];
      _area = 0.0;
    });
  }
  
  // Salvar talhão
  Future<void> _savePlot() async {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 3 pontos para formar um polígono')),
      );
      return;
    }
    
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o talhão')),
      );
      return;
    }
    
    // Converter pontos de latlong2.LatLng para LatLng do adaptador
    final List<Map<String, double>> coordinates = _points
        .map((point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            })
        .toList();
    
    // Usar ID 1 como farmId padrão (considerando que não existe farmId no modelo Property)
    const int farmId = 1;
    
    // Criar objeto Plot com os dados do formulário
    final plot = Plot(
      id: widget.plot?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      propertyId: _selectedProperty!.id,
      farmId: farmId,
      area: _area,
      coordinates: coordinates,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      syncStatus: 0,
    );
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Salvar talhão no repositório
      if (widget.plot != null) {
        await _plotRepository.update(plot);
      } else {
        await _plotRepository.save(plot);
      }
      
      // Mostrar mensagem de sucesso com nome da fazenda
      final propertyName = _selectedProperty?.name ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talhão "${plot.name}" salvo com sucesso na fazenda "$propertyName"'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      // Voltar para a tela anterior
      Navigator.pop(context, true);
    } catch (e) {
      // Exibir mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar talhão: $e')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  // Mostrar erro em diálogo
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plot != null ? 'Editar Talhão' : 'Novo Talhão'),
        // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
        foregroundColor: Colors.white,
        actions: [
          // Botão de salvar
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Salvar Talhão',
            onPressed: _isSaving ? null : _savePlot,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Formulário
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de nome
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Talhão *',
                          hintText: 'Ex: Talhão 1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Seleção de propriedade
                      DropdownButtonFormField<Property>(
                        decoration: const InputDecoration(
                          labelText: 'Propriedade *',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProperty,
                        items: _properties.map((property) {
                          return DropdownMenuItem<Property>(
                            value: property,
                            child: Text(property.name),
                          );
                        }).toList(),
                        onChanged: (property) {
                          setState(() {
                            _selectedProperty = property;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Área calculada
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.area_chart, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 8),
                            Text(
                              'Área: ${_area.toStringAsFixed(2)} hectares',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Instruções
                      const Text(
                        'Toque no mapa para adicionar pontos ao talhão. Adicione pelo menos 3 pontos para formar um polígono.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mapa
                Expanded(
                  child: Stack(
                    children: [
                      // Mapa usando flutter_map com MapTiler
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _initialMapCenter,
                          zoom: _initialZoom,
                          interactiveFlags: InteractiveFlag.all,
                          // onTap: (_, // onTap não é suportado em Polygon no flutter_map 5.0.0 point) => _addPoint(point),
                        ),
                        children: [
                          // Camada de tiles do MapTiler (satélite)
                          TileLayer(
                            urlTemplate: 'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=${Constants.mapTilerAPIKey}',
                            userAgentPackageName: 'com.fortsmart.agro',
                            maxZoom: 22,
                            // backgroundColor: Colors.transparent, // backgroundColor não é suportado em flutter_map 5.0.0
                          ),
                          
                          // Camada de polígonos (talhões)
                          PolygonLayer(polygons: _polygons.map((polygon) => Polygon(
                            points: polygon.points,
                            color: Colors.green.withOpacity(0.5),
                            borderColor: Colors.white,
                            borderStrokeWidth: 3.0,
                            isFilled: true,
                          )).toList()),

                          
                          // Camada de marcadores (pontos do polígono)
                          MarkerLayer(
                            markers: _points.map((point) => Marker(
                              point: point,
                              width: 10,
                              height: 10,
                              builder: (context) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                      
                      // Atribuição para MapTiler
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Text(
                            '© MapTiler © OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10.0),
                          ),
                        ),
                      ),
                      
                      // Botão para alternar estilo do mapa
                      Positioned(
                        right: 16,
                        bottom: 100,
                        child: FloatingActionButton(
                          heroTag: 'locateButton',
                          mini: true,
                          // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.blue,
                          child: const Icon(Icons.my_location),
                          onPressed: () async {
                            try {
                              final position = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );
                              _mapController.move(
                                latlong2.LatLng(position.latitude, position.longitude),
                                18.0,
                              );
                            } catch (e) {
                              print('Erro ao obter localização: $e');
                            }
                          },
                        ),
                      ),
                      
                      // Botão para centralizar no polígono
                      Positioned(
                        right: 16,
                        bottom: 150,
                        child: FloatingActionButton(
                          heroTag: 'centerButton',
                          mini: true,
                          // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.green,
                          child: const Icon(Icons.center_focus_strong),
                          onPressed: _points.isEmpty ? null : () {
                            final center = _calculateMapCenter();
                            _mapController.move(center.center, center.zoom);
                          },
                        ),
                      ),
                      
                      
                      // Botões de controle
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Column(
                          children: [
                            // Botão para desfazer último ponto
                            FloatingActionButton(
                              heroTag: 'undoButton',
                              mini: true,
                              // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.red,
                              child: const Icon(Icons.undo),
                              onPressed: _points.isEmpty ? null : _removeLastPoint,
                            ),
                            const SizedBox(height: 8),
                            
                            // Botão para limpar todos os pontos
                            FloatingActionButton(
                              heroTag: 'clearButton',
                              mini: true,
                              // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.red,
                              child: const Icon(Icons.clear),
                              onPressed: _points.isEmpty ? null : _clearPoints,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
