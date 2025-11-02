import 'package:flutter/material.dart';

import '../screens/reports/integrated_reports_dashboard.dart';
import '../screens/reports/enhanced_planting_report_screen.dart';
import '../screens/plantio/submods/germination_test/screens/germination_report_screen.dart';

/// Rotas específicas para o sistema de relatórios FortSmart
class ReportsRoutes {
  static const String integratedDashboard = '/reports/dashboard';
  static const String enhancedPlanting = '/reports/planting/enhanced';
  static const String germinationReports = '/germination/reports';
  
  /// Configura todas as rotas de relatórios
  static Map<String, WidgetBuilder> get routes => {
    integratedDashboard: (context) => const IntegratedReportsDashboard(),
    enhancedPlanting: (context) => const EnhancedPlantingReportScreen(),
    germinationReports: (context) => const GerminationReportScreen(),
  };
  
  /// Navega para o dashboard integrado de relatórios
  static void navigateToIntegratedDashboard(BuildContext context) {
    Navigator.pushNamed(context, integratedDashboard);
  }
  
  /// Navega para relatórios de plantio avançados
  static void navigateToEnhancedPlanting(BuildContext context) {
    Navigator.pushNamed(context, enhancedPlanting);
  }
  
  /// Navega para relatórios de germinação
  static void navigateToGerminationReports(BuildContext context) {
    Navigator.pushNamed(context, germinationReports);
  }
}
