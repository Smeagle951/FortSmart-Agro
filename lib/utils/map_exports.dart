/// Este arquivo exporta todas as classes de compatibilidade para facilitar a migração
/// para o MapTiler. Ele permite que os arquivos que ainda usam Google Maps ou Mapbox
/// possam importar apenas este arquivo em vez de vários arquivos separados.

// Exporta apenas o google_maps_types.dart para evitar conflitos de tipos
// Este arquivo contém todas as classes necessárias para compatibilidade com Google Maps
export 'google_maps_types.dart';

// Exporta as constantes do MapTiler
export 'maptiler_constants.dart';
