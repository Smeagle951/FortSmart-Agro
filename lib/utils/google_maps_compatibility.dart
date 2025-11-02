import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart';
import 'map_compatibility.dart';
import 'map_compatibility_layer.dart';

/// Este arquivo contém classes e definições para manter a compatibilidade
/// com o código existente que usa Google Maps, facilitando a migração para o MapTiler

/// Classe de compatibilidade para o LatLng do Google Maps
class GoogleLatLng {
  final double latitude;
  final double longitude;
  
  const GoogleLatLng(this.latitude, this.longitude);
  
  /// Converte para o formato LatLng do pacote latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }
  
  /// Converte para o formato LatLng do nosso adaptador de compatibilidade
  LatLng toCompatLatLng() {
    return LatLng(latitude, longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do pacote latlong2
  static GoogleLatLng fromLatLong2(latlong2.LatLng latLng) {
    return GoogleLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do nosso adaptador de compatibilidade
  static GoogleLatLng fromCompatLatLng(LatLng latLng) {
    return GoogleLatLng(latLng.latitude, latLng.longitude);
  }
  
  @override
  String toString() => 'GoogleLatLng(latitude: $latitude, longitude: $longitude)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleLatLng && 
           other.latitude == latitude && 
           other.longitude == longitude;
  }
  
  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Classe de compatibilidade para o Polygon do Google Maps
class GooglePolygon {
  final String polygonId;
  final List<GoogleLatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  
  GooglePolygon({
    required this.polygonId,
    required this.points,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 1.0,
  });
  
  /// Converte para o formato Polygon do flutter_map
  Polygon toFlutterMapPolygon() {
    return Polygon(
      points: points.map((p) => p.toLatLong2()).toList(),
      color: fillColor,
      borderColor: strokeColor,
      borderStrokeWidth: strokeWidth,
    );
  }
}

/// Classe de compatibilidade para o Polyline do Google Maps
class GooglePolyline {
  final String polylineId;
  final List<GoogleLatLng> points;
  final Color color;
  final double width;
  
  GooglePolyline({
    required this.polylineId,
    required this.points,
    this.color = Colors.blue,
    this.width = 1.0,
  });
  
  /// Converte para o formato Polyline do flutter_map
  Polyline toFlutterMapPolyline() {
    return Polyline(
      points: points.map((p) => p.toLatLong2()).toList(),
      color: color,
      strokeWidth: width,
    );
  }
}

/// Classe de compatibilidade para o Marker do Google Maps
class GoogleMarker {
  final String markerId;
  final GoogleLatLng position;
  final Widget? icon;
  final VoidCallback? onTap;
  
  GoogleMarker({
    required this.markerId,
    required this.position,
    this.icon,
    this.onTap,
  });
  
  /// Converte para o formato Marker do flutter_map
  Marker toFlutterMapMarker() {
    return Marker(
      point: position.toLatLong2(),
      child: GestureDetector(
        onTap: onTap,
        child: icon ?? const Icon(Icons.location_on, color: Colors.red),
      ),
    );
  }
}

/// Classe de compatibilidade para o CameraPosition do Google Maps
class GoogleCameraPosition {
  final GoogleLatLng target;
  final double zoom;
  
  GoogleCameraPosition({
    required this.target,
    required this.zoom,
  });
  
  /// Converte para o formato MapPosition do flutter_map
  MapPosition toFlutterMapPosition() {
    return MapPosition(
      center: target.toLatLong2(),
      zoom: zoom,
    );
  }
}

/// Widget de compatibilidade para o GoogleMap
class GoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final Set<GoogleMarker>? markers;
  final Set<GooglePolygon>? polygons;
  final Set<GooglePolyline>? polylines;
  final Function(dynamic)? onMapCreated;
  final Function(GoogleLatLng)? onTap;
  final MapType mapType;

  const GoogleMap({
    Key? key,
    required this.initialCameraPosition,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.markers,
    this.polygons,
    this.polylines,
    this.onMapCreated,
    this.onTap,
    this.mapType = MapType.normal,
  }) : super(key: key);

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  late MapController _mapController;


  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    // Converter para o formato de opções do flutter_map
    final mapOptions = MapOptions(
      center: widget.initialCameraPosition.target.toLatLong2(),
      zoom: widget.initialCameraPosition.zoom,
      onTap: widget.onTap != null
          ? (tapPosition, latLng) => widget.onTap!(GoogleLatLng.fromLatLong2(latLng))
          : null, // Comentário: onTap tem suporte limitado em Polygon no flutter_map 5.0.0
    );

    // Determinar a URL do tile com base no tipo de mapa
    String tileUrl;
    switch (widget.mapType) {
      case MapType.satellite:
        tileUrl = MapTilerUrl.satellite;
        break;
      case MapType.hybrid:
        tileUrl = MapTilerUrl.hybrid;
        break;
      case MapType.normal:
      default:
        tileUrl = MapTilerUrl.streets;
        break;
    }

    // Converter marcadores para o formato do flutter_map
    final markers = widget.markers != null
        ? widget.markers!.map((marker) => marker.toFlutterMapMarker()).toList()
        : <Marker>[];

    // Converter polígonos para o formato do flutter_map
    final polygons = widget.polygons != null
        ? widget.polygons!.map((polygon) => polygon.toFlutterMapPolygon()).toList()
        : <Polygon>[];

    return FlutterMap(
      mapController: _mapController,
      options: mapOptions,
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          subdomains: ['a', 'b', 'c'],
        ),
        // Adicionar polígonos
        if (polygons.isNotEmpty)
          PolygonLayer(polygons: polygons),
        // Adicionar marcadores
        if (markers.isNotEmpty)
          MarkerLayer(markers: markers),
      ],
    );
  }
}

/// Enum para os tipos de mapa
enum MapType {
  normal,
  satellite,
  hybrid,
}

/// Classe estática com métodos de utilitário para compatibilidade com o Google Maps
class GoogleMapsCompatibility {
  /// Converte uma lista de GoogleLatLng para uma lista de LatLng do latlong2
  static List<latlong2.LatLng> convertToLatLong2List(List<GoogleLatLng> points) {
    return points.map((p) => p.toLatLong2()).toList();
  }
  
  /// Converte uma lista de LatLng do latlong2 para uma lista de GoogleLatLng
  static List<GoogleLatLng> convertFromLatLong2List(List<latlong2.LatLng> points) {
    return points.map((p) => GoogleLatLng(p.latitude, p.longitude)).toList();
  }
  
  /// Converte uma lista de GoogleLatLng para uma lista de LatLng do nosso adaptador de compatibilidade
  static List<LatLng> convertToCompatLatLngList(List<GoogleLatLng> points) {
    return points.map((p) => p.toCompatLatLng()).toList();
  }
  
  /// Converte uma lista de LatLng do nosso adaptador de compatibilidade para uma lista de GoogleLatLng
  static List<GoogleLatLng> convertFromCompatLatLngList(List<LatLng> points) {
    return points.map((p) => GoogleLatLng(p.latitude, p.longitude)).toList();
  }
}
