// Classe para posição de toque no mapa (não existe no flutter_map)
// Esta classe é usada para compatibilidade com o Mapbox GL
class TapPosition {
  final double? x;
  final double? y;
  final double? globalX;
  final double? globalY;
  
  const TapPosition({this.x, this.y, this.globalX, this.globalY});
}
