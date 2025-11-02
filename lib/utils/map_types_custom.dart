import 'package:latlong2/latlong.dart' as latlong2;

/// Classe personalizada para substituir a dependência do mapbox_gl
class CustomLatLng {
  final double latitude;
  final double longitude;

  const CustomLatLng(this.latitude, this.longitude);

  /// Converte de latlong2.LatLng para CustomLatLng
  static CustomLatLng fromLatLong2(latlong2.LatLng latLng) {
    return CustomLatLng(latLng.latitude, latLng.longitude);
  }

  /// Converte para latlong2.LatLng
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }

  @override
  String toString() => 'CustomLatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomLatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
