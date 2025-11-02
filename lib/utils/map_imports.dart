// Arquivo centralizado para importações de mapas
// Usado para facilitar a migração de Google Maps/Mapbox para MapTiler

// Importar pacote latlong2 para uso com flutter_map
import 'package:latlong2/latlong.dart' as latlong2;

// Exportar todas as classes e tipos do adaptador global
// Priorizar o adaptador global sobre os outros
export 'map_global_adapter.dart';

// Exportar tipos de mapa, escondendo os que conflitam com o adaptador global
export 'map_types.dart' hide LatLng, LatLngBounds, CameraPosition, CameraUpdate, ScreenCoordinate, MapType;

// Exportar controladores de mapa, escondendo os que conflitam com o adaptador global
export 'map_controllers.dart' hide MapboxMapController;

// Disponibilizar o pacote latlong2 para uso em outros arquivos
export 'package:latlong2/latlong.dart' hide LatLng;
