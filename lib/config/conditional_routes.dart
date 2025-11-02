import 'package:flutter/material.dart';
import '../config/module_config.dart';

/// Classe utilitária para gerenciar rotas condicionais baseadas na configuração de módulos
class ConditionalRoutes {
  /// Retorna um mapa de rotas para o módulo de plantio
  /// Se o módulo estiver desabilitado, retorna um mapa vazio
  static Map<String, WidgetBuilder> getPlantingRoutes(Map<String, WidgetBuilder> routes) {
    if (!ModuleConfig.enablePlantioModule) {
      return {};
    }
    return routes;
  }

  /// Retorna um mapa de rotas para o módulo de colheita
  /// Se o módulo estiver desabilitado, retorna um mapa vazio
  static Map<String, WidgetBuilder> getHarvestRoutes(Map<String, WidgetBuilder> routes) {
    if (!ModuleConfig.enableHarvestModule) {
      return {};
    }
    return routes;
  }

  /// Retorna um mapa de rotas para o módulo de aplicação de produtos
  /// Se o módulo estiver desabilitado, retorna um mapa vazio
  static Map<String, WidgetBuilder> getProductApplicationRoutes(Map<String, WidgetBuilder> routes) {
    if (!ModuleConfig.enableProductApplicationModule) {
      return {};
    }
    return routes;
  }

  /// Retorna um mapa de rotas para o módulo de aplicação agrícola (legacy)
  /// Se o módulo estiver desabilitado, retorna um mapa vazio
  static Map<String, WidgetBuilder> getAplicacaoRoutes(Map<String, WidgetBuilder> routes) {
    if (!ModuleConfig.enableAplicacaoModule) {
      return {};
    }
    return routes;
  }

  /// Retorna um mapa de rotas para o módulo de relatórios
  /// Se o módulo estiver desabilitado, retorna um mapa vazio
  static Map<String, WidgetBuilder> getReportsRoutes(Map<String, WidgetBuilder> routes) {
    if (!ModuleConfig.enableReportsModule) {
      return {};
    }
    return routes;
  }

  /// Retorna um mapa de rotas para o módulo de Tratamento de Sementes
  /// Se o módulo estiver desabilitado, retorna um mapa vazio
  static Map<String, WidgetBuilder> getTSRoutes(Map<String, WidgetBuilder> routes) {
    if (!ModuleConfig.enableTSModule) {
      return {};
    }
    return routes;
  }

  /// Combina múltiplos mapas de rotas em um único mapa
  static Map<String, WidgetBuilder> combineRouteMaps(List<Map<String, WidgetBuilder>> routeMaps) {
    final Map<String, WidgetBuilder> combinedRoutes = {};
    for (final routeMap in routeMaps) {
      combinedRoutes.addAll(routeMap);
    }
    return combinedRoutes;
  }
}
