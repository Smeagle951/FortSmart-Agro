/// Classe que representa uma coordenada geográfica para compatibilidade com o modelo TalhaoModel
/// Esta classe é usada para manter compatibilidade com o código existente que espera MapboxLatLng
class MapboxLatLng {
  final double latitude;
  final double longitude;

  MapboxLatLng(this.latitude, this.longitude);

  @override
  String toString() => 'MapboxLatLng($latitude, $longitude)';
}
