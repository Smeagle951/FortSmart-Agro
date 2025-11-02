import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong2;
// Usando o pacote flutter_map diretamente em vez de importar de src
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/plot.dart';
import '../models/plot_status.dart';
import '../utils/constants.dart';

/// Classe auxiliar para cálculos de coordenadas no mapa
class MapUtils {
  /// Calcula o centro de um conjunto de coordenadas
  static latlong2.LatLng calculateCenter(List<latlong2.LatLng> coordinates) {
    if (coordinates.isEmpty) return latlong2.LatLng(0, 0);
    
    double lat = 0;
    double lng = 0;
    
    for (var point in coordinates) {
      lat += point.latitude;
      lng += point.longitude;
    }
    
    return latlong2.LatLng(lat / coordinates.length, lng / coordinates.length);
  }
  
  /// Calcula os limites (bounds) para um conjunto de coordenadas
  static LatLngBounds calculateBounds(List<latlong2.LatLng> coordinates) {
    if (coordinates.isEmpty) {
      // Retornar um bounds padrão centrado em (0, 0) se não houver coordenadas
      return LatLngBounds(
        latlong2.LatLng(-10, -10),
        latlong2.LatLng(10, 10),
      );
    }
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final coord in coordinates) {
      minLat = min(minLat, coord.latitude);
      maxLat = max(maxLat, coord.latitude);
      minLng = min(minLng, coord.longitude);
      maxLng = max(maxLng, coord.longitude);
    }
    
    // Adicionar um pequeno padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    
    // Criar um bounds com os pontos sudoeste e nordeste
    final southwest = latlong2.LatLng(minLat - latPadding, minLng - lngPadding);
    final northeast = latlong2.LatLng(maxLat + latPadding, maxLng + lngPadding);
    return LatLngBounds(southwest, northeast);
  }
}

/// Widget que exibe um mapa com talhões (plots) usando o MapTiler
class MapTilerPlotMap extends StatefulWidget {
  final List<Plot> plots;
  final List<PlotStatus> plotStatuses;
  final Function(String? plotId) onPlotSelected;
  final String? selectedPlotId;
  final bool showUserLocation;
  final String? apiKey; // MapTiler API Key opcional
  
  const MapTilerPlotMap({
    super.key,
    required this.plots,
    required this.onPlotSelected,
    this.selectedPlotId,
    this.plotStatuses = const [],
    this.showUserLocation = false,
    this.apiKey, // Se não fornecido, usará a chave padrão das constantes
  });
  
  @override
  State<MapTilerPlotMap> createState() => _MapTilerPlotMapState();
}

class _MapTilerPlotMapState extends State<MapTilerPlotMap> {
  late flutter_map.MapController _mapController;
  List<flutter_map.Polygon> _polygons = [];
  List<flutter_map.Marker> _markers = [];
  List<latlong2.LatLng> _allCoordinates = [];
  String _currentMapStyle = 'satellite'; // Estilo padrão do mapa (satélite)
  
  @override
  void initState() {
    super.initState();
    _updateMapElements();
  }
  
  @override
  void didUpdateWidget(MapTilerPlotMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plots != widget.plots || 
        oldWidget.selectedPlotId != widget.selectedPlotId ||
        oldWidget.plotStatuses != widget.plotStatuses) {
      _updateMapElements();
    }
  }
  
  /// Atualiza os elementos do mapa (polígonos e marcadores)
  void _updateMapElements() {
    _polygons = [];
    _markers = [];
    _allCoordinates = [];
    
    // Processando cada plot para criar polígonos e marcadores
    for (final plot in widget.plots) {
      try {
        // Convertendo as coordenadas do formato JSON para latlong2.LatLng
        final List<dynamic> points = jsonDecode(plot.coordinates as String);
        final List<latlong2.LatLng> coordinates = points
            .map((point) => latlong2.LatLng(
                  double.parse(point['lat'].toString()),
                  double.parse(point['lng'].toString()),
                ))
            .toList();
        
        if (coordinates.isEmpty) continue;
        
        // Adicionando às coordenadas totais para cálculo de centro e limites
        _allCoordinates.addAll(coordinates);
        
        // Encontrando o status do plot, se disponível
        final plotStatus = widget.plotStatuses
            .firstWhere((status) => status.plotId == plot.id,
                orElse: () => PlotStatus(
                    id: 'default_${plot.id}',
                    name: 'Talhão',
                    cropType: '',
                    area: 0,
                    coordinates: '',
                    criticalCount: 0,
                    warningCount: 0,
                    okCount: 0,
                    plotId: plot.id!,
                    status: 'normal',
                    color: '0xFF4CAF50')); // Verde em formato de string hexadecimal
        
        // Definindo a cor do polígono com base no status
        Color polygonColor = _getColorFromStatus(plotStatus.status ?? 'normal');
        if (plotStatus.color != null) {
          try {
            polygonColor = Color(int.parse(plotStatus.color!));
          } catch (e) {
            // Erro ao converter cor
            debugPrint('Erro ao converter cor: ${plotStatus.color}');
          }
        }
        
        // Definindo a cor da borda com base na seleção
        Color borderColor = Colors.black.withOpacity(0.8);
        double borderWidth = 1.0;
        if (plot.id == widget.selectedPlotId) {
          borderColor = Colors.blue;
          borderWidth = 3.0;
        }
        
        // Criando o polígono para o plot
        _polygons.add(
          flutter_map.Polygon(
            points: coordinates,
            color: polygonColor.withOpacity(0.4),
            borderColor: borderColor,
            borderStrokeWidth: borderWidth,
            isFilled: true,
          ),
        );
        
        // Criando um marcador no centro do plot
        final center = MapUtils.calculateCenter(coordinates);
        _markers.add(
          flutter_map.Marker(
            point: center,
            child: GestureDetector(
              onTap: () => widget.onPlotSelected(plot.id),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: (plot.id == widget.selectedPlotId)
                            ? Colors.blue
                            : Colors.black54,
                        width: (plot.id == widget.selectedPlotId) ? 2.0 : 1.0,
                      ),
                    ),
                    child: Text(
                      plot.name ?? 'Sem nome', // Operador ?? já verifica se é nulo, não precisa de ?. adicional
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: (plot.id == widget.selectedPlotId)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Erro ao processar plot ${plot.id}: $e');
      }
    }
    
    // Atualiza o estado para redesenhar o mapa
    if (mounted) {
      setState(() {
        // Atualização do estado concluída
      });
      
      // Se houver coordenadas, centraliza o mapa nelas
      if (_allCoordinates.isNotEmpty) {
        final bounds = MapUtils.calculateBounds(_allCoordinates);
        Future.delayed(const Duration(milliseconds: 100), () {
          // Verificar se o mapa está pronto antes de ajustar os limites
          // Convertemos para o tipo esperado pelo MapController
          var northEast = bounds.northEast;
          var southWest = bounds.southWest;
          var southWest2 = southWest;
          _mapController.fitBounds(
            flutter_map.LatLngBounds.fromPoints([
              latlong2.LatLng(southWest.latitude, southWest.longitude),
              latlong2.LatLng(northEast.latitude, northEast.longitude),
            ]),
            options: const flutter_map.FitBoundsOptions(
              padding: EdgeInsets.all(50.0),
              maxZoom: 18.0,
            ),
          );
        });
      }
    }
  }
  
  /// Obtém a cor com base no status do plot
  Color _getColorFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'danger':
      case 'critical':
        return Colors.red.shade700;
      case 'warning':
      case 'alert':
        return Colors.orange;
      case 'success':
      case 'good':
        return Colors.green.shade600;
      case 'info':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade400;
    }
  }
  
  /// Alterna entre os estilos de mapa disponíveis
  void _toggleMapStyle() {
    setState(() {
      switch (_currentMapStyle) {
        case 'satellite':
          _currentMapStyle = 'streets';
          break;
        case 'streets':
          _currentMapStyle = 'hybrid';
          break;
        case 'hybrid':
          _currentMapStyle = 'satellite';
          break;
        default:
          _currentMapStyle = 'satellite';
      }
    });
  }
  
  /// Retorna a URL do tile do MapTiler com base no estilo atual
  String _getMapTilerUrl() {
    final apiKey = widget.apiKey ?? 'KQAa9lY3N0TR17zxhk9u';
    
    switch (_currentMapStyle) {
      case 'streets':
        return 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$apiKey';
      case 'hybrid':
        return 'https://api.maptiler.com/maps/hybrid/256/{z}/{x}/{y}.jpg?key=$apiKey';
      case 'satellite':
      default:
        return 'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=$apiKey';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // A apiKey é usada diretamente no método _getMapTilerUrl()
    return Stack(
      children: [
        flutter_map.FlutterMap(
          mapController: _mapController,
          options: flutter_map.MapOptions(
            center: _allCoordinates.isNotEmpty
                ? MapUtils.calculateCenter(_allCoordinates)
                : latlong2.LatLng(-15.7801, -47.9292), // Brasília como padrão
            zoom: 5.0,
            interactiveFlags: flutter_map.InteractiveFlag.all,
            onTap: (tapPosition, latLng) => widget.onPlotSelected(null) // Desseleciona ao tocar fora
          ),
          nonRotatedChildren: [
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
                  ' MapTiler OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10.0),
                ),
              ),
            ),
          ],
          children: [
            // Camada de tiles do MapTiler
            flutter_map.TileLayer(
              urlTemplate: _getMapTilerUrl(),
              userAgentPackageName: 'com.fortsmart.agro',
              tileProvider: flutter_map.NetworkTileProvider(),
              // backgroundColor: Colors.transparent, // backgroundColor não é suportado em flutter_map 5.0.0
              maxZoom: 22,
            ),
            
            // Camada de polígonos (talhões)
            flutter_map.PolygonLayer(polygons: _polygons),
            
            // Camada de marcadores (nomes dos talhões)
            flutter_map.MarkerLayer(markers: _markers),
          ],
        ),
        
        // Botão para alternar estilo do mapa
        Positioned(
          right: 16,
          bottom: 60,
          child: FloatingActionButton(
            heroTag: 'mapStyle',
            mini: true,
            // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
            onPressed: _toggleMapStyle,
            child: Icon(
              Icons.layers,
              color: Colors.blueGrey[700],
            )
          ),
        ),
        
        // Botão para centralizar o mapa
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'centerMap',
            mini: true,
            // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
            child: Icon(
              Icons.my_location,
              color: Colors.blueGrey[700],
            ),
            onPressed: () {
              if (_allCoordinates.isNotEmpty) {
                final bounds = MapUtils.calculateBounds(_allCoordinates);
                // Convertemos para o tipo esperado pelo MapController
                // Tratamos os casos onde os bounds podem ser nulos
                final southWest = bounds.southWest;
                final northEast = bounds.northEast;
                
                _mapController.fitBounds(
                  flutter_map.LatLngBounds.fromPoints([
                    southWest,
                    northEast,
                  ]),
                  options: const flutter_map.FitBoundsOptions(
                    padding: EdgeInsets.all(50.0),
                    maxZoom: 18.0,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
