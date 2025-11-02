import 'mapbox_compatibility_adapter.dart' as mapbox;
import 'package:latlong2/latlong.dart' as latlong2;

/// Adaptador para converter entre diferentes implementações de coordenadas
/// Isso facilita a migração de Google Maps para Mapbox
class CoordinateAdapter {
  /// Converte LatLng do Mapbox para LatLng do latlong2
  static latlong2.LatLng mapboxToLatLng2(mapbox.MapboxLatLng location) {
    return latlong2.LatLng(location.latitude, location.longitude);
  }

  /// Converte LatLng do latlong2 para LatLng do Mapbox
  static mapbox.MapboxLatLng latLng2ToMapbox(latlong2.LatLng location) {
    return mapbox.MapboxLatLng(location.latitude, location.longitude);
  }

  /// Converte lista de LatLng do Mapbox para lista de LatLng do latlong2
  static List<latlong2.LatLng> mapboxListToLatLng2List(List<mapbox.MapboxLatLng> locations) {
    return locations.map((loc) => mapboxToLatLng2(loc)).toList();
  }

  /// Converte lista de LatLng do latlong2 para lista de LatLng do Mapbox
  static List<mapbox.MapboxLatLng> latLng2ListToMapboxList(List<latlong2.LatLng> locations) {
    return locations.map((loc) => latLng2ToMapbox(loc)).toList();
  }
  
  /// Converte lista de listas de LatLng do Mapbox para lista de listas de LatLng do latlong2
  static List<List<latlong2.LatLng>> mapboxListListToLatLng2ListList(
      List<List<mapbox.MapboxLatLng>> locationLists) {
    return locationLists.map((list) => mapboxListToLatLng2List(list)).toList();
  }

  /// Converte lista de listas de LatLng do latlong2 para lista de listas de LatLng do Mapbox
  static List<List<mapbox.MapboxLatLng>> latLng2ListListToMapboxListList(
      List<List<latlong2.LatLng>> locationLists) {
    return locationLists.map((list) => latLng2ListToMapboxList(list)).toList();
  }
}
