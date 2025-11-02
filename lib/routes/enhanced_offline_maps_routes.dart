import 'package:flutter/material.dart';
import '../../screens/enhanced_offline_maps_screen.dart';
import '../../screens/enhanced_map_download_screen.dart';

/// Rotas para módulos de mapas offline aprimorados
class EnhancedOfflineMapsRoutes {
  static const String enhancedOfflineMaps = '/enhanced-offline-maps';
  static const String enhancedMapDownload = '/enhanced-map-download';

  /// Obtém todas as rotas
  static Map<String, WidgetBuilder> get routes => {
    enhancedOfflineMaps: (context) => const EnhancedOfflineMapsScreen(),
    enhancedMapDownload: (context) => const EnhancedMapDownloadScreen(),
  };

  /// Navega para tela principal de mapas offline
  static Future<void> navigateToOfflineMaps(BuildContext context) {
    return Navigator.pushNamed(context, enhancedOfflineMaps);
  }

  /// Navega para tela de download de mapas
  static Future<void> navigateToMapDownload(BuildContext context) {
    return Navigator.pushNamed(context, enhancedMapDownload);
  }

  /// Navega para tela de download de mapas com resultado
  static Future<Map<String, dynamic>?> navigateToMapDownloadWithResult(BuildContext context) {
    return Navigator.pushNamed(context, enhancedMapDownload);
  }
}
