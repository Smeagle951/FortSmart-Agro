import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/talhao_model_new.dart';

class TalhaoMapWidget extends StatefulWidget {
  final TalhaoModel talhao;
  final bool interactive;
  final double height;
  final Function(TalhaoModel)? onTalhaoTapped;

  const TalhaoMapWidget({
    Key? key,
    required this.talhao,
    this.interactive = true,
    this.height = 200,
    this.onTalhaoTapped,
  }) : super(key: key);

  @override
  _TalhaoMapWidgetState createState() => _TalhaoMapWidgetState();
}

class _TalhaoMapWidgetState extends State<TalhaoMapWidget> {
  late MapController _mapController;
  List<LatLng> _polygonPoints = [];
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _processPolygonData();
  }

  @override
  void didUpdateWidget(TalhaoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.talhao != widget.talhao) {
      _processPolygonData();
    }
  }

  void _processPolygonData() {
    try {
      // Converter os pontos do talhão para LatLng
      if (widget.talhao.poligonos.isNotEmpty && widget.talhao.poligonos[0].isNotEmpty) {
        _polygonPoints = widget.talhao.poligonos[0].map((ponto) {
          return LatLng(ponto.latitude, ponto.longitude);
        }).toList();

        // Calcular o centro do polígono para centralizar o mapa
        if (_polygonPoints.isNotEmpty) {
          double latSum = 0;
          double lngSum = 0;
          for (var point in _polygonPoints) {
            latSum += point.latitude;
            lngSum += point.longitude;
          }
          _center = LatLng(
            latSum / _polygonPoints.length,
            lngSum / _polygonPoints.length,
          );
        } else {
          _center = LatLng(-15.793889, -47.882778); // Brasília como padrão
        }
      } else {
        _center = LatLng(-15.793889, -47.882778); // Brasília como padrão
        _polygonPoints = [];
      }
    } catch (e) {
      print('Erro ao processar pontos do talhão: $e');
      // Em caso de erro, usar um centro padrão
      _center = LatLng(-15.793889, -47.882778); // Brasília como padrão
      _polygonPoints = [];
    }
  }

  // Método removido pois não é compatível com flutter_map
  
  // Método compatível com flutter_map
  void _handleMapTap(tapPosition, latLng) {
    if (widget.onTalhaoTapped != null) {
      widget.onTalhaoTapped!(widget.talhao);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lista de camadas para o flutter_map
    final List<Widget> layers = [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.fortsmart.agro',
      ),
    ];
    
    // Adiciona a camada de polígono se houver pontos
    if (_polygonPoints.isNotEmpty) {
      layers.add(
        PolygonLayer(
          polygons: [
            Polygon(
              points: _polygonPoints,
              color: widget.talhao.cor.withOpacity(0.5),
              borderStrokeWidth: 3.0,
              borderColor: widget.talhao.cor,
              isFilled: true,
            ),
          ],
        ),
      );

      // Adiciona o marcador de localização
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              point: _center,
              width: 30.0,
              height: 30.0,
              builder: (context) => Icon(
                Icons.location_on,
                color: Colors.red,
                size: 30,
              ),
            ),
          ],
        ),
      );

      // Adiciona o marcador com o nome do talhão
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              point: _center,
              width: 150.0,
              height: 50.0,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    color: Colors.blue,
                    size: 30,
                  ),
                  Text(
                    widget.talhao.nome,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _polygonPoints.isEmpty
            ? Center(
                child: Text(
                  'Não foi possível carregar o mapa do talhão ${widget.talhao.nome}',
                  textAlign: TextAlign.center,
                ),
              )
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _center,
                  zoom: 15.0,
                  interactiveFlags: widget.interactive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                  onTap: widget.interactive && widget.onTalhaoTapped != null
                      ? _handleMapTap
                      : null,
                ),
                children: layers,
              ),
      ),
    );
  }
}
