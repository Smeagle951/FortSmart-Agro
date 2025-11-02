import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../widgets/plot_navigation_widget.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../utils/fortsmart_theme.dart';

/// Tela de navegação GPS até o talhão
class PlotNavigationScreen extends StatefulWidget {
  final LatLng plotCenter;
  final String plotName;
  final Color plotColor;

  const PlotNavigationScreen({
    Key? key,
    required this.plotCenter,
    required this.plotName,
    this.plotColor = const Color(0xFF3BAA57),
  }) : super(key: key);

  @override
  State<PlotNavigationScreen> createState() => _PlotNavigationScreenState();
}

class _PlotNavigationScreenState extends State<PlotNavigationScreen> {
  final MapController _mapController = MapController();
  bool _showNavigationWidget = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FortsmartAppBar(
        title: 'Navegação para ${widget.plotName}',
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showNavigationWidget = !_showNavigationWidget;
              });
            },
            icon: Icon(_showNavigationWidget ? Icons.visibility_off : Icons.visibility),
            tooltip: _showNavigationWidget ? 'Ocultar Navegação' : 'Mostrar Navegação',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.plotCenter,
              initialZoom: 16.0,
              minZoom: 10.0,
              maxZoom: 20.0,
            ),
            children: [
              // Camada de tiles
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=YOUR_MAPTILER_KEY',
                userAgentPackageName: 'com.fortsmart.agro',
                maxZoom: 20,
              ),
              
              // Marcador do talhão
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.plotCenter,
                    width: 40,
                    height: 40,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: widget.plotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Widget de navegação
          if (_showNavigationWidget)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PlotNavigationWidget(
                plotCenter: widget.plotCenter,
                plotName: widget.plotName,
                primaryColor: widget.plotColor,
                onNavigationComplete: () {
                  _showNavigationCompleteDialog();
                },
                onNavigationCancel: () {
                  Navigator.pop(context);
                },
              ),
            ),
          
          // Botão de alternar visualização
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showNavigationWidget = !_showNavigationWidget;
                });
              },
              backgroundColor: widget.plotColor,
              child: Icon(
                _showNavigationWidget ? Icons.map : Icons.navigation,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigationCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Navegação Concluída'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Você chegou ao talhão!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.plotColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.agriculture, color: widget.plotColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.plotName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.plotColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fechar diálogo
              Navigator.pop(context); // Voltar para tela anterior
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.plotColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}
