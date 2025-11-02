/// Módulo de Mapas Offline para FortSmart
/// 
/// Este módulo permite o download e armazenamento offline de tiles de mapas
/// para talhões específicos, garantindo funcionamento sem conexão com internet.
library offline_maps;

// Models
export 'models/offline_map_model.dart';
export 'models/offline_map_status.dart';

// Services
export 'services/offline_map_service.dart';
export 'services/tile_download_service.dart';

// Providers
export 'providers/offline_map_provider.dart';

// Screens
export 'screens/offline_maps_manager_screen.dart';

// Widgets
export 'widgets/offline_map_card.dart';
export 'widgets/download_progress_widget.dart';

// Utils
export 'utils/offline_map_utils.dart';
export 'utils/tile_calculator.dart';

// Config
export 'config/offline_maps_config.dart';

// Examples
export 'examples/integration_example.dart';
