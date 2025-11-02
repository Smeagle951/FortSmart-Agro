import 'package:flutter/material.dart';
import '../../routes.dart' as app_routes;
import 'screens/cost_management_main_screen.dart';
import 'screens/new_application_screen.dart';
import 'screens/cost_simulation_screen.dart';
import 'screens/cost_report_screen.dart';
import 'screens/applications_list_screen.dart';

/// Módulo de Gestão de Custos
/// 
/// Este módulo oferece funcionalidades completas para:
/// - Registro de aplicações de produtos
/// - Simulação de custos
/// - Relatórios detalhados
/// - Análise de custos por talhão
/// - Gestão de produtos em estoque
class CostManagementModule {
  static const String moduleName = 'Gestão de Custos';
  static const String moduleDescription = 'Controle total dos custos de aplicação';
  static const IconData moduleIcon = Icons.attach_money;
  
  /// Verifica se o módulo está habilitado
  static bool get isEnabled => true;
  
  /// Retorna a tela principal do módulo
  static Widget get mainScreen => const CostManagementMainScreen();
  
  /// Retorna todas as rotas do módulo
  static Map<String, WidgetBuilder> get routes => {
    app_routes.AppRoutes.costManagement: (context) => const CostManagementMainScreen(),
    app_routes.AppRoutes.costManagementMain: (context) => const CostManagementMainScreen(),

    app_routes.AppRoutes.costSimulation: (context) => const CostSimulationScreen(),
    app_routes.AppRoutes.costReport: (context) => const CostReportScreen(),
    app_routes.AppRoutes.costApplicationsList: (context) => const ApplicationsListScreen(),
  };
  
  /// Retorna as funcionalidades principais do módulo
  static List<Map<String, dynamic>> get features => [
    {
      'title': 'Dashboard de Custos',
      'description': 'Visão geral dos custos e aplicações',
      'icon': Icons.analytics,
      'route': app_routes.AppRoutes.costManagement,
    },
    {
      'title': 'Nova Aplicação',
      'description': 'Registrar nova aplicação de produtos',
      'icon': Icons.add_circle,
      'route': app_routes.AppRoutes.costNewApplication,
    },
    {
      'title': 'Simulação de Custos',
      'description': 'Simular custos antes da aplicação',
      'icon': Icons.calculate,
      'route': app_routes.AppRoutes.costSimulation,
    },
    {
      'title': 'Relatórios',
      'description': 'Relatórios detalhados de custos',
      'icon': Icons.assessment,
      'route': app_routes.AppRoutes.costReport,
    },
    {
      'title': 'Lista de Aplicações',
      'description': 'Visualizar todas as aplicações',
      'icon': Icons.list,
      'route': app_routes.AppRoutes.costApplicationsList,
    },
  ];
  
  /// Retorna as estatísticas do módulo
  static Map<String, dynamic> get statistics => {
    'totalApplications': 0,
    'totalCost': 0.0,
    'averageCostPerHectare': 0.0,
    'mostUsedProducts': [],
    'costByPlot': {},
  };
  
  /// Retorna as configurações do módulo
  static Map<String, dynamic> get settings => {
    'enableNotifications': true,
    'autoCalculateCosts': true,
    'defaultCurrency': 'BRL',
    'costPrecision': 2,
    'enableStockValidation': true,
  };
  
  /// Inicializa o módulo
  static Future<void> initialize() async {
    // Aqui você pode adicionar inicializações específicas do módulo
    // Por exemplo, carregar dados padrão, configurar serviços, etc.
  }
  
  /// Retorna informações sobre o módulo
  static Map<String, dynamic> get moduleInfo => {
    'name': moduleName,
    'description': moduleDescription,
    'version': '1.0.0',
    'author': 'FortSmart Agro',
    'lastUpdate': DateTime.now().toIso8601String(),
    'features': features.length,
    'enabled': isEnabled,
  };
}
