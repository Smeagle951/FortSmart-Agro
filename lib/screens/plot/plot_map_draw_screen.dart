import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:convert';
import '../../models/plot.dart';
import '../../utils/geo_utils.dart';
import '../../utils/map_imports.dart' as maps;
import '../../utils/google_maps_types.dart' as google_maps_types;
import '../../utils/map_exports.dart';

class PlotMapDrawScreen extends StatefulWidget {
  final Plot? existingPlot;
  final String? farmId;
  
  const PlotMapDrawScreen({
    Key? key, 
    this.existingPlot,
    this.farmId,
  }) : super(key: key);

  @override
  _PlotMapDrawScreenState createState() => _PlotMapDrawScreenState();
}

class _PlotMapDrawScreenState extends State<PlotMapDrawScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  google_maps_types.GoogleMapController? _mapController;
  Location _location = Location();
  
  Set<google_maps_types.Marker> _markers = {};
  Set<google_maps_types.Polygon> _polygons = {};
  List<google_maps_types.LatLng> _polygonPoints = [];
  int _polygonIdCounter = 1;
  
  bool _isDrawing = false;
  bool _isGPSRecording = false;
  Timer? _gpsTimer;
  
  // Cor dos marcadores para melhorar visibilidade
  google_maps_types.BitmapDescriptor _markerIcon = google_maps_types.BitmapDescriptor.defaultMarkerWithHue(google_maps_types.BitmapDescriptor.hueRed);
  
  // Controles iniciais do mapa
  google_maps_types.LatLng _initialPosition = const google_maps_types.LatLng(-15.7801, -47.9292); // Brasil, como padrão
  double _initialZoom = 15.0;
  bool _isMapLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    
    // Se tiver um plot existente, carrega as coordenadas dele
    if (widget.existingPlot != null && widget.existingPlot!.polygonJson != null) {
      try {
        final List<dynamic> coords = jsonDecode(widget.existingPlot!.polygonJson!);
        _polygonPoints = coords.map((point) => 
          google_maps_types.LatLng(point['lat'] as double, point['lng'] as double)
        ).toList();
        
        _updatePolygon();
      } catch (e) {
        debugPrint('Erro ao carregar coordenadas existentes: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _stopGPSRecording();
    _mapController?.dispose();
    super.dispose();
  }
  
  // Obter a localização atual para centralizar o mapa
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }
      
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) return;
      }
      
      final locationData = await _location.getLocation();
      final currentPosition = google_maps_types.LatLng(
        locationData.latitude ?? _initialPosition.latitude,
        locationData.longitude ?? _initialPosition.longitude
      );
      
      setState(() {
        _initialPosition = currentPosition;
        _isMapLoaded = true;
        
        // Adicionar um marcador na localização atual
        _markers.add(
          google_maps_types.Marker(
            markerId: google_maps_types.MarkerId('current_location'),
            position: currentPosition,
            icon: google_maps_types.BitmapDescriptor.defaultMarkerWithHue(
              google_maps_types.BitmapDescriptor.hueAzure
            ),
            infoWindow: google_maps_types.InfoWindow(
              title: 'Sua localização atual',
              snippet: 'Lat: ${currentPosition.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.longitude.toStringAsFixed(6)}',
            ),
            zIndex: 5, // Maior valor para ficar acima dos outros marcadores
          ),
        );
      });
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          google_maps_types.CameraUpdate.newLatLngZoom(_initialPosition, _initialZoom)
        );
      }
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
    }
  }
  
  // Centralizar o mapa na localização atual
  Future<void> _centerOnCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      final currentPosition = google_maps_types.LatLng(
        locationData.latitude ?? _initialPosition.latitude,
        locationData.longitude ?? _initialPosition.longitude
      );
      
      // Atualizar o marcador de localização atual
      setState(() {
        // Remover o marcador anterior
        _markers.removeWhere(
          (marker) => marker.markerId == google_maps_types.MarkerId('current_location')
        );
        
        // Adicionar o novo marcador
        _markers.add(
          google_maps_types.Marker(
            markerId: google_maps_types.MarkerId('current_location'),
            position: currentPosition,
            icon: google_maps_types.BitmapDescriptor.defaultMarkerWithHue(
              google_maps_types.BitmapDescriptor.hueAzure
            ),
            infoWindow: google_maps_types.InfoWindow(
              title: 'Sua localização atual',
              snippet: 'Lat: ${currentPosition.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.longitude.toStringAsFixed(6)}',
            ),
            zIndex: 5,
          ),
        );
      });
      
      // Animar a câmera para a localização atual
      if (_mapController != null) {
        _mapController!.animateCamera(
          google_maps_types.CameraUpdate.newLatLngZoom(currentPosition, 18.0) // Zoom mais próximo para melhor visualização
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mapa centralizado na sua localização atual'),
          duration: Duration(seconds: 2),
        )
      );
    } catch (e) {
      debugPrint('Erro ao centralizar no local atual: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao obter localização: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        )
      );
    }
  }
  
  void _onMapCreated(google_maps_types.GoogleMapController controller) {
    _mapController = controller;
    if (_isMapLoaded) {
      _mapController!.animateCamera(
        google_maps_types.CameraUpdate.newLatLngZoom(_initialPosition, _initialZoom)
      );
    }
    
    // Configura a aparência do mapa para melhor visibilidade
    _mapController?.setMapStyle('''[
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]''');
  }
  
  // Adiciona um ponto ao polígono quando o usuário toca no mapa
  void _onMapTap(google_maps_types.LatLng position) {
    if (!_isDrawing) return;
    
    setState(() {
      _polygonPoints.add(position);
      _updatePolygon();
      
      // Adiciona um marcador no ponto com ícone visível
      final markerId = google_maps_types.MarkerId('marker_${_polygonPoints.length}');
      _markers.add(
        google_maps_types.Marker(
          markerId: markerId,
          position: position,
          draggable: true,
          icon: _markerIcon,
          visible: true,
          zIndex: 2,
          onDragEnd: (newPosition) {
            // Capturamos o markerId no escopo da função para poder passá-lo para _onMarkerDragEnd
            _onMarkerDragEnd(markerId, newPosition);
          },
        )
      );
    });
    
    // Exibe informações sobre o ponto adicionado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ponto ${_polygonPoints.length} adicionado'),
        duration: Duration(seconds: 1),
      )
    );
  }
  
  // Atualiza a posição de um marcador quando ele é arrastado
  void _onMarkerDragEnd(google_maps_types.MarkerId markerId, google_maps_types.LatLng newPosition) {
    final markerIndex = int.parse(markerId.value.split('_')[1]) - 1;
    if (markerIndex >= 0 && markerIndex < _polygonPoints.length) {
      setState(() {
        _polygonPoints[markerIndex] = newPosition;
        _updatePolygon();
      });
    }
  }
  
  // Atualiza o polígono com os pontos atuais
  void _updatePolygon() {
    if (_polygonPoints.length < 3) return; // Precisa de pelo menos 3 pontos para formar um polígono
    
    final polygon = google_maps_types.Polygon(
      polygonId: google_maps_types.PolygonId('polygon_$_polygonIdCounter'),
      points: _polygonPoints,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
    );
    
    setState(() {
      _polygons.clear();
      _polygons.add(polygon);
    });
  }
  
  // Inicia ou para o desenho manual
  void _toggleDrawing() {
    if (_isGPSRecording) {
      _stopGPSRecording();
    }
    
    setState(() {
      _isDrawing = !_isDrawing;
      
      // Se estiver iniciando o desenho, limpa os pontos anteriores
      if (_isDrawing) {
        _polygonPoints = [];
        _markers.clear();
        _polygons.clear();
      } else {
        _updatePolygon();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDrawing 
          ? 'Toque no mapa para adicionar pontos ao talhão. Os pontos aparecerão em vermelho.' 
          : 'Desenho manual desativado.'
        ),
        duration: Duration(seconds: 3),
      )
    );
  }
  
  // Inicia ou para a gravação por GPS
  void _toggleGPSRecording() {
    if (_isDrawing) {
      setState(() {
        _isDrawing = false;
      });
    }
    
    if (_isGPSRecording) {
      _stopGPSRecording();
    } else {
      _startGPSRecording();
    }
  }
  
  // Inicia a gravação por GPS
  void _startGPSRecording() {
    setState(() {
      _isGPSRecording = true;
    });
    
    // Adiciona pontos a cada 5 segundos
    _gpsTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final locationData = await _location.getLocation();
        final position = google_maps_types.LatLng(
          locationData.latitude ?? 0,
          locationData.longitude ?? 0
        );
        
        setState(() {
          _polygonPoints.add(position);
          
          // Adiciona um marcador no ponto
          final markerId = google_maps_types.MarkerId('marker_${_polygonPoints.length}');
          _markers.add(
            google_maps_types.Marker(
              markerId: markerId,
              position: position,
              draggable: true,
              onDragEnd: (newPosition) {
                // Capturamos o markerId no escopo da função para poder passá-lo para _onMarkerDragEnd
                _onMarkerDragEnd(markerId, newPosition);
              },
            )
          );
          
          _updatePolygon();
        });
      } catch (e) {
        debugPrint('Erro ao obter localização GPS: $e');
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gravação por GPS iniciada. Movimente-se pelo perímetro do talhão.'),
        duration: Duration(seconds: 3),
      )
    );
  }
  
  // Para a gravação por GPS
  void _stopGPSRecording() {
    _gpsTimer?.cancel();
    
    setState(() {
      _isGPSRecording = false;
    });
    
    if (_isGPSRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gravação por GPS finalizada.'),
          duration: Duration(seconds: 2),
        )
      );
    }
  }
  
  // Limpa todos os pontos
  void _clearPoints() {
    setState(() {
      _polygonPoints.clear();
      _markers.clear();
      _polygons.clear();
    });
  }
  
  // Desfaz o último ponto adicionado
  void _undoLastPoint() {
    if (_polygonPoints.isEmpty) return;
    
    setState(() {
      _polygonPoints.removeLast();
      
      // Remove o último marcador
      if (_markers.isNotEmpty) {
        final lastMarkerId = google_maps_types.MarkerId('marker_${_polygonPoints.length + 1}');
        _markers.removeWhere((marker) => marker.markerId == lastMarkerId);
      }
      
      _updatePolygon();
    });
  }
  
  // Calcula a área do polígono
  double _calculateArea() {
    if (_polygonPoints.length < 3) return 0;
    
    // Converte para o formato esperado pelo GeoUtils
    final List<maps.LatLng> latLngPoints = _polygonPoints.map((p) => 
      maps.LatLng(p.latitude, p.longitude)
    ).toList();
    
    // Calcula a área em hectares
    return GeoUtils.calculatePolygonArea(latLngPoints);
  }
  
  // Salva o talhão e retorna para a tela anterior
  Future<void> _savePlot() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desenhe um polígono com pelo menos 3 pontos')),
      );
      return;
    }
    
    // Converte os pontos para formato JSON
    final List<Map<String, double>> polygonCoords = _polygonPoints.map((point) => {
      'lat': point.latitude,
      'lng': point.longitude,
    }).toList();
    
    final area = _calculateArea();
    final String polygonJsonStr = jsonEncode(polygonCoords);
    final timestamp = DateTime.now().toIso8601String();
    
    // Cria ou atualiza o objeto Plot
    Plot? resultPlot;
    
    if (widget.existingPlot != null) {
      // Criar um novo objeto com os valores atualizados
      resultPlot = Plot(
        id: widget.existingPlot!.id,
        name: widget.existingPlot!.name,
        area: area,
        farmId: int.parse(widget.farmId ?? '0'),
        propertyId: widget.existingPlot!.propertyId,
        polygonJson: polygonJsonStr,
        createdAt: widget.existingPlot!.createdAt,
        updatedAt: timestamp,
        syncStatus: widget.existingPlot!.syncStatus,
        remoteId: widget.existingPlot!.remoteId,
        cropType: widget.existingPlot!.cropType,
        plantingDate: widget.existingPlot!.plantingDate,
        harvestDate: widget.existingPlot!.harvestDate,
      );
    } else {
      // Criar um novo plot
      resultPlot = Plot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Novo Talhão', // Nome temporário
        area: area,
        farmId: int.parse(widget.farmId ?? '0'),
        propertyId: 1, // Valor padrão, deve ser ajustado conforme necessário
        polygonJson: polygonJsonStr,
        createdAt: timestamp,
        updatedAt: timestamp,
      );
    }
    
    // Retorna o plot para a tela anterior
    Navigator.pop(context, resultPlot);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Desenhar Talhão no Mapa'),
        // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Salvar',
            onPressed: _savePlot,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: _initialZoom,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            // mapToolbarEnabled: false, // Não suportado pelo MapTiler
            markers: _markers,
            polygons: _polygons,
            // onTap: _isDrawing ? _onMapTap : null, // onTap não é suportado em Polygon no flutter_map 5.0.0
            mapType: google_maps_types.MapType.satellite, // Usar visualização de satélite
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Área aproximada: ${_calculateArea().toStringAsFixed(2)} hectares',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Pontos: ${_polygonPoints.length}', 
                          style: TextStyle(fontSize: 14)
                        ),
                        SizedBox(width: 8),
                        if (_isDrawing)
                          Text(
                            '(Desenho manual ativado)',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        if (_isGPSRecording)
                          Text(
                            '(Gravação GPS ativada)',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'btn_drawing',
                  onPressed: _toggleDrawing,
                  // backgroundColor: _isDrawing ? Colors.green : Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(_isDrawing ? Icons.edit_off : Icons.edit),
                  tooltip: _isDrawing ? 'Parar desenho manual' : 'Iniciar desenho manual',
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'btn_gps',
                  onPressed: _toggleGPSRecording,
                  // backgroundColor: _isGPSRecording ? Colors.red : Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(_isGPSRecording ? Icons.gps_off : Icons.gps_fixed),
                  tooltip: _isGPSRecording ? 'Parar GPS' : 'Iniciar com GPS',
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'btn_location',
                  onPressed: _centerOnCurrentLocation,
                  // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(Icons.my_location),
                  tooltip: 'Centralizar na minha localização',
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'btn_clear',
                  onPressed: _clearPoints,
                  // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(Icons.delete),
                  tooltip: 'Limpar tudo',
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'btn_undo',
                  onPressed: _undoLastPoint,
                  // backgroundColor: Colors.orange, // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(Icons.undo),
                  tooltip: 'Desfazer último ponto',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
