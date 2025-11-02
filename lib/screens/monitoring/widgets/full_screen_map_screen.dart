import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Models
import '../../../models/talhao_model.dart';

// Controllers
import '../controllers/monitoring_point_premium_controller.dart';

/// Tela de mapa em tela cheia para o módulo de monitoramento
class FullScreenMapScreen extends StatefulWidget {
  final MonitoringPointPremiumController controller;
  final dynamic currentPoint;
  final TalhaoModel? talhao;

  const FullScreenMapScreen({
    super.key,
    required this.controller,
    this.currentPoint,
    this.talhao,
  });

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  late MapController _fullScreenMapController;
  double _currentZoom = 15.0;
  LatLng? _currentCenter;

  @override
  void initState() {
    super.initState();
    _fullScreenMapController = MapController();
    _currentCenter = widget.controller.currentPosition ?? 
                    widget.controller.targetPosition ?? 
                    const LatLng(-23.5505, -46.6333);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mapa em tela cheia
          FlutterMap(
            mapController: _fullScreenMapController,
            options: MapOptions(
              initialCenter: _currentCenter!,
              initialZoom: _currentZoom,
              minZoom: 5.0,
              maxZoom: 22.0,
              onMapEvent: (MapEvent event) {
                // Atualizar estado baseado no tipo de evento
                if (event is MapEventMoveEnd) {
                  setState(() {
                    _currentCenter = event.center;
                    _currentZoom = event.zoom;
                  });
                } else if (event is MapEventMove) {
                  setState(() {
                    _currentCenter = event.center;
                    _currentZoom = event.zoom;
                  });
                }
              },
            ),
            children: [
              // Camada de tiles do MapTiler
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u',
                userAgentPackageName: 'com.fortsmart.agro',
                maxZoom: 22,
              ),
              
              // Camada de marcadores
              MarkerLayer(
                markers: [
                  // Marcador da posição atual (GPS)
                  if (widget.controller.currentPosition != null)
                    Marker(
                      point: widget.controller.currentPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  
                  // Marcador do ponto de monitoramento
                  if (widget.currentPoint != null)
                    Marker(
                      point: LatLng(
                        widget.currentPoint.latitude,
                        widget.currentPoint.longitude,
                      ),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  
                  // Outros marcadores do controller
                  ...widget.controller.mapMarkers,
                ],
              ),
              
              // Camada de rotas
              if (widget.controller.routeLines.isNotEmpty)
                PolylineLayer(
                  polylines: widget.controller.routeLines,
                ),
            ],
          ),
          
          // Header com informações
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Botão voltar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Informações do talhão
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.talhao?.name ?? 'Ponto de Monitoramento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.currentPoint != null)
                          Text(
                            'Ponto: ${widget.currentPoint.latitude.toStringAsFixed(6)}, ${widget.currentPoint.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Informações de zoom
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Zoom: ${_currentZoom.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Controles de zoom
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: Column(
              children: [
                // Botão zoom in
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      _fullScreenMapController.move(
                        _currentCenter!,
                        (_currentZoom + 1).clamp(5.0, 22.0),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Botão zoom out
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      _fullScreenMapController.move(
                        _currentCenter!,
                        (_currentZoom - 1).clamp(5.0, 22.0),
                      );
                    },
                    icon: const Icon(
                      Icons.remove,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Botão centralizar GPS
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  if (widget.controller.currentPosition != null) {
                    _fullScreenMapController.move(
                      widget.controller.currentPosition!,
                      15.0,
                    );
                  }
                },
                icon: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullScreenMapController.dispose();
    super.dispose();
  }
}
