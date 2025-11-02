/// Constantes relacionadas ao mapa e APIs
class MapConstants {
  /// Chave da API do Google Maps (legado)
  static const String googleMapsApiKey = 'AIzaSyC0za6vabzZJZBnE4-pk-Z74xUm0XpkGM0';
  
  /// Chave da API do MapTiler
  static const String mapTilerApiKey = 'KQAa9lY3N0TR17zxhk9u';
  
  /// Zoom inicial do mapa
  static const double defaultZoom = 15.0;
  
  /// Zoom máximo permitido
  static const double maxZoom = 20.0;
  
  /// Zoom mínimo permitido
  static const double minZoom = 5.0;
  
  /// Cor padrão dos polígonos
  static const int defaultPolygonColor = 0x804CAF50; // Verde semi-transparente
  
  /// Cor padrão das bordas dos polígonos
  static const int defaultPolygonStrokeColor = 0xFF4CAF50; // Verde
  
  /// Largura padrão das bordas dos polígonos
  static const double defaultPolygonStrokeWidth = 2.0;
  
  /// Cor do polígono selecionado
  static const int selectedPolygonColor = 0x802196F3; // Azul semi-transparente
  
  /// Cor da borda do polígono selecionado
  static const int selectedPolygonStrokeColor = 0xFF2196F3; // Azul
  
  /// Largura da borda do polígono selecionado
  static const double selectedPolygonStrokeWidth = 3.0;
  
  /// Cor do marcador de ponto
  static const int markerColor = 0xFF2196F3; // Azul
}
