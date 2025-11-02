import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../screens/talhoes_com_safras/providers/talhao_provider.dart';
import 'cultura_provider.dart';
import 'safra_provider.dart';
import 'farm_provider.dart';
import '../screens/plantio/submods/germination_test/providers/germination_test_provider.dart';
import '../screens/plantio/submods/phenological_evolution/providers/phenological_provider.dart';
import '../database/app_database.dart';
import '../modules/offline_maps/providers/offline_map_provider.dart';
import '../services/fortsmart_notification_service.dart';

class AppProviders {
  static List<ChangeNotifierProvider> get providers => [
    ChangeNotifierProvider<TalhaoProvider>(
      create: (context) => TalhaoProvider(),
    ),
    ChangeNotifierProvider<CulturaProvider>(
      create: (context) => CulturaProvider(),
    ),
    ChangeNotifierProvider<SafraProvider>(
      create: (context) => SafraProvider(),
    ),
    ChangeNotifierProvider<FarmProvider>(
      create: (context) => FarmProvider(),
    ),
    ChangeNotifierProvider<GerminationTestProvider>(
      create: (context) {
        // Inicializar com o banco específico do módulo de germinação
        final provider = GerminationTestProvider(null); // Usa banco interno
        return provider;
      },
      // Removido lazy: true para garantir inicialização imediata
    ),
    ChangeNotifierProvider<PhenologicalProvider>(
      create: (context) => PhenologicalProvider(),
      lazy: true, // Inicializa apenas quando necessário
    ),
    ChangeNotifierProvider<OfflineMapProvider>(
      create: (context) => OfflineMapProvider(),
      lazy: true, // Inicializa apenas quando necessário
    ),
    ChangeNotifierProvider<FortSmartNotificationService>(
      create: (context) => FortSmartNotificationService(),
      lazy: false, // Inicializa imediatamente para monitoramento
    ),
  ];

  static MultiProvider getMultiProvider({required Widget child}) {
    return MultiProvider(
      providers: providers,
      child: child,
    );
  }
}
