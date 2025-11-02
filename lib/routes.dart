import 'package:flutter/material.dart';
import 'package:fortsmart_agro/screens/talhoes_com_safras/novo_talhao_screen_wrapper.dart';
// Removido - arquivo não existe mais
// Removido import do módulo antigo de talhões
import 'config/module_config.dart';
// import 'screens/dashboard/premium_dashboard_screen.dart'; // Removido
import 'screens/settings/settings_screen.dart';
import 'screens/settings/version_info_screen.dart';
import 'screens/settings/terms_of_use_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/contact_support_screen.dart';
import 'screens/database/database_diagnostic_screen.dart';
// Temporariamente comentados para evitar conflitos com o novo módulo premium
// import 'services/data_cache_service.dart';
// import 'models/safra_model.dart';
// import 'models/crop_model.dart' as app_crop;
import 'screens/database/database_maintenance_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/offline/download_fazenda_screen.dart';
import 'screens/dashboard/enhanced_dashboard_screen.dart';
import 'screens/dashboard/informative_dashboard_screen.dart';
import 'screens/plot/enhanced_plots_screen.dart';
import 'screens/plot/plot_details_screen.dart';
import 'screens/file_import/file_import_main_screen.dart';
import 'screens/machine_data/machine_data_import_screen.dart';
import 'screens/plot/plot_history_screen.dart';
import 'screens/farm/farm_profile_screen.dart';
import 'screens/farm/farm_edit_screen.dart';
import 'screens/farm/farm_list_screen.dart';
import 'screens/farm/farm_add_screen.dart';
import 'screens/farm/new_farm_crops_screen.dart';
import 'screens/farm/farm_weeds_screen.dart';
import 'screens/pest_details_screen.dart';
import 'screens/disease_details_screen.dart';
import 'screens/weed_details_screen.dart';
import 'screens/crops/crop_variety_list_screen.dart';
import 'screens/crops/crop_variety_form_screen.dart';
// import 'screens/stock/estoque_premium_screen.dart'; // Removido
// import 'screens/monitoring/monitoring_history_screen.dart';
import 'screens/planting/planting_form_screen.dart';
import 'screens/planting/planting_list_screen.dart';
// Removidos imports do módulo antigo de talhões
// Usando apenas o novo módulo de talhões com safras
// Temporariamente comentado para evitar conflitos com o novo módulo premium
// import 'package:fortsmart_agro/screens/talhoes/talhao_draw_screen.dart';
// Módulo de colheita removido
import 'screens/planter_calibration_list_screen.dart';
import 'screens/planter_calibration_screen.dart';
// import 'screens/data_sync_screen.dart';

import 'screens/application/pesticide_application_list_screen.dart' as pesticide_application;
import 'screens/application/pesticide_application_form_screen.dart' as pesticide_application_form;
import 'screens/application/pesticide_application_details_screen.dart' as pesticide_application_details;
import 'screens/prescription/prescription_list_screen.dart';
// Módulo de atividades removido
// Módulo de alertas removido - funcionalidades transferidas para mapa de infestação
// import 'screens/reports/reports_screen.dart'; // Arquivo removido - usando AdvancedAnalyticsDashboard
// import 'screens/reports/monitoring_report_screen.dart'; // Arquivo removido
import 'screens/reports/planting_report_screen.dart';
import 'screens/feedback/learning_dashboard_screen.dart';
import 'modules/soil_calculation/routes/soil_routes.dart';
import 'screens/reports/application_report_screen.dart';
import 'screens/reports/consolidated_report_screen.dart';
import 'screens/reports/complete_planting_detail_screen.dart';
import 'screens/reports/advanced_analytics_dashboard.dart';
import 'screens/reports/monitoring_dashboard.dart';
import 'screens/reports/infestation_dashboard.dart';
import 'screens/dashboard/integrated_statistics_dashboard.dart';
// import 'screens/reports/integrated_planting_report_screen.dart'; // Arquivo removido temporariamente
// import 'screens/reports/agronomist_intelligent_reports_screen.dart'; // Comentado temporariamente
import 'modules/ai/screens/ai_dashboard_screen.dart';
import 'modules/ai/screens/ai_diagnosis_screen.dart';
import 'modules/ai/screens/organism_catalog_screen.dart' as ai_organism;
import 'modules/ai/screens/ai_monitoring_screen.dart';
// Módulo de colheita removido
import 'screens/settings/version_info_screen.dart';
// Módulo de infestação recriado
import 'modules/infestation_map/infestation_map_module.dart';
import 'screens/monitoring/advanced_monitoring_screen.dart';
import 'screens/monitoring/point_monitoring_screen.dart';
import 'screens/monitoring/monitoring_history_screen.dart';
import 'screens/monitoring/monitoring_history_view_screen.dart';
// Novas telas de Monitoramento V2
import 'screens/monitoring/monitoring_history_v2_screen.dart';
import 'screens/monitoring/monitoring_details_v2_screen.dart';
import 'screens/monitoring/monitoring_point_resume_screen.dart';
import 'screens/monitoring/monitoring_point_edit_screen.dart';
// Módulo resumo de talhões removido
import 'screens/prescricao/prescricao_premium_screen.dart' as prescricao;
import 'screens/aplicacao/aplicacao_home_screen.dart';
import 'screens/aplicacao/aplicacao_lista_screen.dart';
import 'screens/aplicacao/aplicacao_registro_screen.dart';
import 'screens/aplicacao/aplicacao_detalhes_screen.dart';
import 'screens/aplicacao/aplicacao_relatorio_screen.dart';
import 'screens/prescription/prescricoes_agronomicas_screen.dart';
import 'screens/prescription/prescricao_relatorios_screen.dart';
// import 'screens/prescription/prescricao_premium_screen.dart'; // Arquivo removido



import 'modules/cost_management/screens/cost_management_main_screen.dart';
import 'modules/cost_management/screens/cost_simulation_screen.dart';
import 'modules/cost_management/screens/cost_report_screen.dart';
import 'modules/cost_management/screens/applications_list_screen.dart';
import 'modules/import_export/screens/import_export_main_screen.dart';
import 'modules/import_export/screens/export_screen.dart';
import 'modules/import_export/screens/import_screen.dart';

// Módulos de Mapas Offline e Download
import 'screens/enhanced_offline_maps_screen.dart';
import 'screens/enhanced_map_download_screen.dart';
import 'widgets/free_map_download_widget.dart';
import 'screens/overflow_fix_example_screen.dart';

// Módulo Caldaflex
import 'screens/calda/calda_advanced_main_screen.dart';

// Módulo Tratamento de Sementes
// import 'screens/plantio/submods/tratamento_sementes/tratamento_sementes_screen.dart'; // Comentado temporariamente


// Módulo de Subáreas
import 'screens/plantio/subarea_routes.dart';
import 'screens/plantio/plantio_home_screen.dart';
import 'screens/plantio/plantio_registro_screen.dart';
import 'screens/plantio/submods/plantio_calculo_sementes_screen.dart';
import 'screens/plantio/submods/plantio_calibragem_plantadeira_screen.dart';
// import 'screens/plantio/submods/plantio_calibragem_adubo_screen.dart'; // Arquivo removido
import 'screens/plantio/submods/plantio_calibragem_adubo_coleta_screen.dart';
import 'screens/plantio/submods/plantio_calibragem_disco_screen.dart';
import 'screens/plantio/submods/plantio_estande_plantas_screen.dart';
import 'screens/colheita/colheita_main_screen.dart';
import 'screens/colheita/colheita_perda_screen.dart';

import 'modules/planting/screens/plantio_detalhes_screen.dart';
import 'screens/soil_analysis/soil_sample_plot_selection_screen.dart';
import 'screens/soil_analysis/add_soil_analysis_screen.dart';
import 'screens/fertilizer/fertilizer_calibration_simplified_screen.dart';
import 'screens/fertilizer/fertilizer_calibration_history_screen.dart';
import 'screens/diagnostic/talhao_diagnostic_screen.dart';
import 'screens/calibracao/calculo_basico_calibracao_screen.dart';
import 'screens/calibracao/historico_calculo_basico_screen.dart';
import 'screens/configuracao/organism_catalog_enhanced_screen.dart';
import 'screens/configuracao/infestation_rules_edit_screen.dart';
// Removido: import 'screens/configuracao/infestation_rules_screen.dart'; // Módulo desnecessário removido

// Imports para o sistema de custos por hectare
import 'screens/custos/custo_por_hectare_dashboard_screen.dart';
import 'screens/historico/historico_custos_talhao_screen.dart';
import 'screens/main_menu_with_costs_integration.dart';
import 'screens/gestao_custos_screen.dart';

// Imports condicionais para módulos específicos
// import 'modules/monitoring/models/monitoring_model.dart'; // Removido - não usado
// Comentado temporariamente até que os arquivos sejam criados
// import 'modules/planting/screens/experimento_screen.dart';
// import 'modules/planting/screens/estande_screen.dart';
// import 'modules/planting/screens/calculo_sementes_screen.dart';
// Comentado temporariamente até que os arquivos sejam criados
// Módulo de colheita removido
import 'modules/reports/reports_module.dart';
import 'modules/reports/screens/inventory_report_screen.dart' as new_reports;
import 'modules/reports/screens/product_application_report_screen.dart';
import 'modules/inventory/screens/inventory_products_screen.dart';
// Comentado temporariamente até que os arquivos sejam criados
// import 'modules/product_application/screens/product_applications_list_screen.dart';
// import 'modules/product_application/screens/product_application_form_screen.dart';
// import 'modules/product_application/models/product_application_model.dart';
import 'modules/soil_calculation/screens/soil_compaction_main_v2_screen.dart';
import 'modules/soil_calculation/screens/soil_compaction_menu_screen.dart';
import 'modules/soil_calculation/screens/simple_compaction_screen.dart';
// import 'modules/offline_maps/screens/offline_maps_manager_screen.dart';
// import 'modules/offline_maps/screens/offline_maps_download_screen.dart';
// import 'modules/crop_monitoring/screens/crop_monitoring_screen.dart';
// Submódulo de Germinação - Integrado ao Plantio
import 'screens/plantio/submods/germination_test/screens/germination_main_screen.dart';
import 'screens/plantio/submods/germination_test/screens/germination_test_list_screen.dart';
import 'screens/plantio/submods/germination_test/screens/germination_test_create_screen.dart';
import 'screens/plantio/submods/germination_test/screens/germination_test_settings_screen.dart';
import 'screens/plantio/submods/germination_test/models/germination_test_model.dart';

// Submódulo de Evolução Fenológica - Integrado ao Plantio
import 'screens/plantio/submods/phenological_evolution/screens/phenological_main_screen.dart';
import 'screens/plantio/submods/phenological_evolution/screens/phenological_record_screen.dart';
import 'screens/plantio/submods/phenological_evolution/screens/phenological_history_screen.dart';
import 'screens/plantio/submods/phenological_evolution/providers/phenological_provider.dart';

import 'screens/plantio/talhao_detalhes_screen.dart';
import 'screens/plantio/subarea_detalhes_screen.dart';
import 'screens/plantio/criar_subarea_screen.dart';
import 'screens/plantio/experimento_melhorado_screen.dart';
import 'models/experimento_completo_model.dart';

// Imports para variedades
import 'screens/crops/crop_variety_form_screen.dart';
import 'screens/crops/crop_variety_list_screen.dart';

// Imports para modelos
import 'models/talhao_model_new.dart';

/// Classe centralizada que define todas as rotas do aplicativo
/// Organizada por módulos para melhor manutenibilidade
class AppRoutes {
  // ROTAS PRINCIPAIS
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String enhancedDashboard = '/enhanced_dashboard';
  static const String informativeDashboard = '/informative_dashboard';
  
  // CONFIGURAÇÕES E SISTEMA
  static const String settings = '/settings';
  static const String versionInfo = '/version_info';
  static const String termsOfUse = '/terms_of_use';
  static const String privacyPolicy = '/privacy_policy';
  static const String contactSupport = '/contact_support';
  static const String dataSync = '/data/sync';

  static const String databaseDiagnostic = '/database_diagnostic';
  static const String databaseMaintenance = '/database_maintenance';
  static const String backup = '/backup';
  static const String downloadFazendaOffline = '/download_fazenda_offline';
  
  // FAZENDAS
  static const String farms = '/farms';
  static const String farmList = '/farm/list';
  static const String farmAdd = '/farm/add';
  static const String farmEdit = '/farm/edit';
  static const String farmProfile = '/farm/profile';
  static const String farmProfileNew = '/farm/profile/new';
  static const String farmCrops = '/farm/crops';
  static const String farmWeeds = '/farm/weeds';
  
  // Rotas para detalhes de pragas, doenças e plantas daninhas
  static const String pestDetails = '/pest/details';
  static const String diseaseDetails = '/disease/details';
  static const String weedDetails = '/weed/details';
  
  // TALHÕES
  static const String plots = '/plots';
  static const String plotList = '/plot/list';
  static const String plotDetails = '/plot/details';
  static const String plotHistory = '/plot/history';
  static const String enhancedPlots = '/enhanced_plots';
  
  // MAPAS OFFLINE E DOWNLOAD
  static const String offlineMapsManagement = '/offline_maps_management';
  static const String mapDownload = '/map_download';
  static const String freeMapDownload = '/free_map_download';
  static const String overflowFixExample = '/overflow_fix_example';
  
  // CALDAFLEX
  static const String caldaflex = '/caldaflex';
  static const String caldaflexAdvanced = '/caldaflex_advanced';
  
  // TRATAMENTO DE SEMENTES
  static const String tratamentoSementes = '/tratamento_sementes';
  
  
  // IMPORTAÇÃO DE ARQUIVOS
  static const String fileImport = '/file_import';
  
  // DADOS DE MÁQUINAS AGRÍCOLAS
  static const String machineDataImport = '/machine_data_import';
  static const String talhoesSafra = '/talhoes/safra';
  static const String dashboardSafras = '/dashboard/safras';
  static const String talhaoDetails = '/talhao/details';
  static const String talhaoAlertDetails = '/talhao/alert/details';
  static const String talhaoRelatorios = '/talhoes/relatorios';
  static const String talhaoDrawScreen = '/talhao/draw';
  
  // PLANTIO
  static const String plantioHome = '/plantio/home';
  static const String plantioRegistro = '/plantio/registro';
  static const String plantioCalculoSementes = '/plantio/calculo-sementes';
  static const String plantioCalibragemPlantadeira = '/plantio/calibragem-plantadeira';
  static const String plantioCalibragemAduboColeta = '/plantio/calibragem-adubo-coleta';
  static const String plantioCalibragemDisco = '/plantio/calibragem-disco';
  static const String plantioEstandePlantas = '/plantio/estande-plantas';
  static const String plantioHistorico = '/plantio/historico';

  static const String plantioDetalhes = '/plantio/detalhes';
  static const String seedsPerHectare = '/seeds_per_hectare';
  static const String standCalculation = '/stand_calculation';
  static const String plotEdit = '/plot/edit';
  static const String applicationAdd = '/application/add';
  static const String harvestAdd = '/harvest/add';
  static const String plantingList = '/planting/list';
  static const String plantingForm = '/planting/form';
  static const String planterCalibrationList = '/planting/calibration/list';
  static const String planterCalibrationNew = '/planting/calibration/new';
  static const String experimentRegistration = '/planting/experiment';
  static const String estandeCalculation = '/planting/estande';
  static const String calculoSementes = '/planting/calculo-sementes';
  

  
  // PRESCRIÇÃO PREMIUM
  static const String prescricaoPremium = '/prescricao/premium';
  static const String prescricaoLista = '/prescricao/lista';
  static const String prescricaoRelatorios = '/prescricao/relatorios';
  
  // APLICAÇÃO (LEGACY - SERÁ REMOVIDA)
  static const String aplicacaoHome = '/aplicacao/home';
  static const String aplicacaoLista = '/aplicacao/lista';
  static const String aplicacaoRegistro = '/aplicacao/registro';
  static const String aplicacaoDetalhes = '/aplicacao/detalhes';
  static const String aplicacaoRelatorio = '/aplicacao/relatorio';
  static const String aplicacaoPrescricao = '/aplicacao/prescricao';
  // Rotas antigas de aplicação removidas - agora usando módulo de gestão de custos
  static const String pesticideApplicationList = '/pesticide-applications';
  static const String productApplicationList = '/product-application/list';
  static const String productApplicationForm = '/product-application/form';
  static const String productApplicationDetails = '/product-application/details';
  
  // Módulo de colheita removido
  
  // ESTOQUE
  static const String inventory = '/inventory';
  static const String inventoryList = '/inventory/list';
  static const String inventoryReport = '/inventory/report';
  static const String inventoryMovement = '/inventory/movement';
  
  // MÁQUINAS
  
  // RELATÓRIOS
  static const String reports = '/reports';
  static const String reportsModule = '/reports/module';
  static const String integratedDashboard = '/integrated_dashboard';
  static const String learningDashboard = '/learning_dashboard';

  static const String plantingReport = '/planting/report';
  static const String applicationReport = '/application/report';
  // Módulo de colheita removido
  static const String inventoryStockReport = '/reports/inventory';
  static const String productApplicationReport = '/reports/product-application';
  static const String agronomistReports = '/reports/agronomist';
  static const String consolidatedReport = '/reports/consolidated';
  static const String integratedPlantingReport = '/reports/planting/integrated';
  static const String monitoringDashboard = '/reports/monitoring-dashboard';
  static const String infestationDashboard = '/reports/infestation-dashboard';
  
  // Módulo de IA
  static const String aiDashboard = '/ai/dashboard';
  static const String aiDiagnosis = '/ai/diagnosis';
  static const String aiOrganismCatalog = '/ai/organisms';
  static const String aiMonitoring = '/ai/monitoring';
  
  // ALERTAS - Removido (funcionalidades transferidas para mapa de infestação)
  
  // ATIVIDADES
  // Módulo de atividades removido
  
  // PRESCRIÇÕES
  static const String prescriptions = '/prescriptions';
  static const String prescriptionList = '/prescriptions/list';
  
  // SOLO
  static const String soilCalculationMain = '/soil';
  static const String soilCompaction = '/soil/compaction';
  static const String soilCompactionSimple = '/soil/compaction/simple';
  static const String soilSamplePlotSelection = '/soil/sample/plot-selection';
  static const String addSoilAnalysis = '/soil/analysis/add';
  
  // CALIBRAÇÃO DE FERTILIZANTES
  static const String calibracaoFertilizante = '/calibracao/fertilizante';
  static const String calculoBasicoCalibracao = '/fertilizer/calculo-basico';
  static const String historicoCalibracoes = '/fertilizer/historico';
  
  // INFESTAÇÃO
  static const String mapaInfestacao = '/infestacao/mapa';
  static const String detalhesTalhao = '/infestacao/talhao/detalhes';
  static const String listaAlertas = '/infestacao/alertas';
  
   // MONITORAMENTO
  static const String monitoringMain = '/monitoring/main';
  static const String advancedMonitoring = '/monitoring/advanced';
  static const String monitoringPoint = '/monitoring/point';
  static const String monitoringHistory = '/monitoring/history';
  static const String monitoringHistoryView = '/monitoring/history/view';
  // Monitoramento V2
  static const String monitoringHistoryV2 = '/monitoring/history-v2';
  static const String monitoringDetailsV2 = '/monitoring/details-v2';
  static const String monitoringPointResume = '/monitoring/point-resume';
  static const String monitoringPointEdit = '/monitoring/point-edit';
  
  // CONFIGURAÇÃO DE ORGANISMOS
  static const String organismCatalog = '/config/organism-catalog';
  static const String infestationRules = '/config/infestation-rules'; // Regras de Infestação com Fenologia
  
  // TESTE DE GERMINAÇÃO
  // Rotas do Módulo de Germinação
  static const String germinationMain = '/germination-main';
  static const String germinationTests = '/germination-tests';
  static const String germinationTestCreate = '/germination-test-create';
  static const String germinationTestSettings = '/germination-test-settings';
  
  // EVOLUÇÃO FENOLÓGICA
  // Rotas do Módulo de Evolução Fenológica (12 culturas)
  static const String phenologicalMain = '/phenological-main';
  static const String phenologicalRecord = '/phenological-record';
  static const String phenologicalHistory = '/phenological-history';
  
  // SUBÁREAS E EXPERIMENTOS
  static const String talhaoDetalhes = '/talhao/detalhes';
  static const String subareaDetalhes = '/subarea/detalhes';
  static const String criarSubarea = '/subarea/criar';
  static const String exemploSubareas = '/subarea/exemplo';
  static const String experimentoMelhorado = '/experimento/melhorado';
  
  // VARIEDADES
  static const String variedadesCadastro = '/variedades/cadastro';
  static const String variedadesLista = '/variedades/lista';
  
  // MAPAS OFFLINE
  static const String offlineMaps = '/offline_maps';
  static const String offlineMapsDownload = '/offline_maps/download';
  
  
  

  
  // ROTAS DO SISTEMA DE CUSTOS POR HECTARE
  static const String custoPorHectareDashboard = '/custos/dashboard';
  static const String historicoCustosTalhao = '/custos/historico';
  static const String mainMenuWithCosts = '/custos/menu';
  static const String gestaoCustos = '/custos/gestao';
  static const String novaPrescricao = '/prescricao/nova';
  
  // ROTAS DO MÓDULO DE GESTÃO DE CUSTOS
  static const String costManagement = '/cost_management';
  static const String costManagementMain = '/cost_management/main';
  static const String costNewApplication = '/cost_management/new_application';
  static const String costSimulation = '/cost_management/simulation';
  
  // ROTAS DO MÓDULO DE IMPORTAÇÃO & EXPORTAÇÃO
  static const String importExportMain = '/import_export/main';
  static const String importExportExport = '/import_export/export';
  static const String importExportImport = '/import_export/import';
  static const String costReport = '/cost_management/report';
  static const String costApplicationsList = '/cost_management/applications_list';

  /// Mapa principal de rotas organizadas por funcionalidade
  static final Map<String, WidgetBuilder> routes = {
    // ROTAS PRINCIPAIS
    // home: (context) => const PremiumDashboardScreen(), // Removido - conflita com home no MaterialApp
    // dashboard: (context) => const PremiumDashboardScreen(), // Removido
    // enhancedDashboard: (context) => const PremiumDashboardScreen(), // Removido
    informativeDashboard: (context) => const InformativeDashboardScreen(),
    
    // CONFIGURAÇÕES E SISTEMA
    settings: (context) => const SettingsScreen(),
    versionInfo: (context) => const VersionInfoScreen(),
    termsOfUse: (context) => const TermsOfUseScreen(),
    privacyPolicy: (context) => const PrivacyPolicyScreen(),
    contactSupport: (context) => const ContactSupportScreen(),
    // dataSync: (context) => const DataSyncScreen(),

    databaseDiagnostic: (context) => const DatabaseDiagnosticScreen(),
    databaseMaintenance: (context) => const DatabaseMaintenanceScreen(),
    backup: (context) => const BackupScreen(),
    downloadFazendaOffline: (context) => const DownloadFazendaScreen(),
    
    // FAZENDAS
    farms: (context) => const FarmListScreen(),
    farmList: (context) => const FarmListScreen(),
    farmAdd: (context) => const FarmAddScreen(),
    farmEdit: (context) {
      final farmId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      return FarmEditScreen(farmId: farmId);
    },
    farmProfile: (context) {
      return const FarmProfileScreen();
    },
    // Redirecionando a rota farmProfileNew para usar a mesma tela que farmProfile
    // já que o conteúdo de farm_profile_screen_new.dart foi copiado para farm_profile_screen.dart
    farmProfileNew: (context) {
      return const FarmProfileScreen();
    },
    farmCrops: (context) => const NewFarmCropsScreen(),
    farmWeeds: (context) => const FarmWeedsScreen(),
    
    // Rotas para detalhes de pragas, doenças e plantas daninhas
    pestDetails: (context) {
      final pestId = ModalRoute.of(context)?.settings.arguments as int?;
      return PestDetailsScreen(pestId: pestId ?? 0);
    },
    diseaseDetails: (context) {
      final diseaseId = ModalRoute.of(context)?.settings.arguments as int?;
      return DiseaseDetailsScreen(diseaseId: diseaseId ?? 0);
    },
    weedDetails: (context) {
      final weedId = ModalRoute.of(context)?.settings.arguments as int?;
      return WeedDetailsScreen(weedId: weedId ?? 0);
    },
    
    // Rota para listagem de variedades
    '/crop/varieties': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return CropVarietyListScreen(
        cropId: args?['cropId'] as String?,
        cropName: args?['cropName'] as String?,
      );
    },
    
    // Rota para formulário de variedades
    '/crop/variety/form': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return CropVarietyFormScreen(
        cropId: args?['cropId'] as String?,
      );
    },
    
    // Rota para resumos de talhões
          // Rota do módulo resumo de talhões removida
    
    // TALHÕES - Novo módulo premium
    plots: (context) => const NovoTalhaoScreenWrapper(),
    plotList: (context) => const EnhancedPlotsScreen(),
    plotDetails: (context) => const PlotDetailsScreen(),
    
    // IMPORTAÇÃO DE ARQUIVOS
    fileImport: (context) => const FileImportMainScreen(),
    
    // DADOS DE MÁQUINAS AGRÍCOLAS
    machineDataImport: (context) => const MachineDataImportScreen(),
    plotHistory: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final plotId = args['plotId'] as String?;
        final plotName = args['plotName'] as String?;
        return PlotHistoryScreen(plotId: plotId, plotName: plotName);
      } else if (args is String) {
        return PlotHistoryScreen(plotId: args);
      }
      return const PlotHistoryScreen();
    },
    enhancedPlots: (context) => const EnhancedPlotsScreen(),
    
    // MAPAS OFFLINE E DOWNLOAD - VERSÕES APRIMORADAS
    offlineMapsManagement: (context) => const EnhancedOfflineMapsScreen(),
    mapDownload: (context) => const EnhancedMapDownloadScreen(),
    freeMapDownload: (context) => const FreeMapDownloadWidget(),
    overflowFixExample: (context) => const OverflowFixExampleScreen(),
    
    // CALDAFLEX
    caldaflex: (context) => const CaldaAdvancedMainScreen(),
    caldaflexAdvanced: (context) => const CaldaAdvancedMainScreen(),
    
    // TRATAMENTO DE SEMENTES
    // tratamentoSementes: (context) => const TratamentoSementesScreen(), // Comentado temporariamente
    
    
    // Rotas do novo módulo premium de talhões
    talhoesSafra: (context) => const NovoTalhaoScreenWrapper(),
    dashboardSafras: (context) => const NovoTalhaoScreenWrapper(),
    // Nova rota para o módulo V2 otimizado
    // '/novo-talhao-v2': (context) => const NovoTalhaoScreenV2(), // Removido - arquivo não existe mais
    // '/editar-poligono': (context) {
    //   final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    //   return EditarPoligonoScreen(
    //     polygonId: args['polygonId'],
    //     polygonName: args['polygonName'],
    //   );
    // },
    // '/relatorios-poligonos': (context) => const RelatoriosPoligonosScreen(),
    // Rota para a versão limpa e funcional
    // Removido - arquivo não existe mais
    talhaoRelatorios: (context) {
      // Redirecionando para o novo módulo premium
      return const NovoTalhaoScreenWrapper();
    }, // Redirecionado para o novo módulo premium
    // Temporariamente comentado para evitar conflitos com o novo módulo premium
    talhaoDrawScreen: (context) {
      // Redirecionando para a tela principal para evitar erros
        return const EnhancedDashboardScreen();
      // final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      // return TalhaoDrawScreen(
      //   fazendaId: args?['fazendaId'] as String? ?? '1',
      //   safras: args?['safras'] ?? [],
      //   culturas: args?['culturas'] ?? [],
      //   selectedSafra: args?['selectedSafra'] as String? ?? '',
      //   isGpsMode: args?['isGpsMode'] as bool? ?? false,
      //   talhao: args?['talhao'],
      // );
    },
    talhaoDetails: (context) {
      final talhao = ModalRoute.of(context)?.settings.arguments as TalhaoModel?;
      return talhao != null ? const EnhancedDashboardScreen() : const EnhancedDashboardScreen(); // Tela removida
    },
    // Duplicada - removendo esta definição
    // talhaoAlertDetails já está definida acima
    '/talhao/edit': (context) {
      // Temporariamente redirecionando para a tela principal para evitar conflitos com o novo módulo premium
        return const EnhancedDashboardScreen();
      
      // Código original comentado
      // final talhao = ModalRoute.of(context)?.settings.arguments as TalhaoModel?;
      // if (talhao == null) return const PremiumDashboardScreen();
      // // Obtendo os dados necessários para o TalhaoDrawScreen
      // final dataCacheService = DataCacheService();
      // final safras = dataCacheService.getSafras() as List<SafraModel>? ?? [];
      // final culturas = dataCacheService.getCulturas() as List<app_crop.Crop>? ?? [];
      // 
      // return TalhaoDrawScreen(
      //   fazendaId: talhao.fazendaId ?? '',
      //   talhao: talhao,
      //   safras: safras,
      //   culturas: culturas,
      //   selectedSafra: talhao.safraId?.toString() ?? '',
      //   isGpsMode: false,
      // );
    },
    '/talhao/history': (context) {
      // Redirecionando para a tela de histórico de custos
      return HistoricoCustosTalhaoScreen();
    },
    '/talhao/relatorios': (context) {
      // Redirecionando para o novo módulo premium
      return const NovoTalhaoScreenWrapper();
    },
    
    // Rota para criar monitoramento a partir de um talhão
    '/talhao/monitoramento/criar': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? talhaoId;
      TalhaoModel? talhao;
      String? culturaId;
      
      if (args is Map<String, dynamic>) {
        talhaoId = args['talhaoId'] as String?;
        talhao = args['talhao'] as TalhaoModel?;
        culturaId = args['culturaId'] as String?;
      } else if (args is String) {
        // Compatibilidade com chamadas antigas
        talhaoId = args;
      }
      
        return const EnhancedDashboardScreen(); // CreateMonitoringScreen removida
    },
    
    // PLANTIO
    plantioHome: (context) => PlantioHomeScreen(),
    plantioRegistro: (context) {
      final plantioId = ModalRoute.of(context)?.settings.arguments as String?;
      return PlantioRegistroScreen(plantioId: plantioId);
    },
    plantioCalculoSementes: (context) => const PlantioCalculoSementesScreen(),
    plantioCalibragemPlantadeira: (context) => const PlantioCalibragePlantadeiraScreen(),
    plantioCalibragemAduboColeta: (context) => const PlantioCalibragemaAduboColetaScreen(),
    plantioCalibragemDisco: (context) => const PlantioCalibragDiscoScreen(),
    plantioEstandePlantas: (context) => const PlantioEstandePlantasScreen(),

    plantioDetalhes: (context) {
      final plantio = ModalRoute.of(context)?.settings.arguments as dynamic;
      return PlantioDetalhesScreen(plantio: plantio);
    },
    seedsPerHectare: (context) => const PlantioCalculoSementesScreen(),
    standCalculation: (context) => const PlantioEstandePlantasScreen(),
    plotEdit: (context) => const EnhancedDashboardScreen(), // Temporariamente redirecionando
    applicationAdd: (context) => const EnhancedDashboardScreen(), // Temporariamente redirecionando
    harvestAdd: (context) => const ColheitaMainScreen(),
    plantingList: (context) => PlantioHomeScreen(),
    plantingForm: (context) {
      final plantingId = ModalRoute.of(context)?.settings.arguments as String?;
      return PlantingFormScreen(plantingId: plantingId);
    },
    

    // '/premium_alert_map': (context) => const PremiumAlertMapScreen(), // Removido
    talhaoAlertDetails: (context) {
      // Funcionalidade transferida para mapa de infestação
        return const EnhancedDashboardScreen();
    },
    
    // PRESCRIÇÃO PREMIUM - TELA ELEGANTE COM CÁLCULOS E INTEGRAÇÃO DE CUSTOS
    prescricaoPremium: (context) => const prescricao.PrescricaoPremiumScreen(),
    
    // APLICAÇÃO (LEGACY - SERÁ REMOVIDA)
    aplicacaoHome: (context) => const AplicacaoHomeScreen(),
    aplicacaoLista: (context) => const AplicacaoListaScreen(),
    aplicacaoRegistro: (context) {
      final aplicacaoId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      return AplicacaoRegistroScreen(aplicacaoId: aplicacaoId);
    },
    aplicacaoDetalhes: (context) {
      final aplicacaoId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      return AplicacaoDetalhesScreen(aplicacaoId: aplicacaoId);
    },
    aplicacaoRelatorio: (context) => const AplicacaoRelatorioScreen(),
    aplicacaoPrescricao: (context) => const prescricao.PrescricaoPremiumScreen(), // Tela elegante de prescrição premium
    // Rotas antigas de aplicação removidas - agora usando módulo de gestão de custos
    pesticideApplicationList: (context) => const pesticide_application.PesticideApplicationListScreen(),
    
    // COLHEITA
    '/colheita': (context) => const ColheitaMainScreen(),
    '/colheita/perda': (context) => const ColheitaPerdaScreen(),
    '/colheita/historico': (context) => const ColheitaMainScreen(), // Temporariamente redirecionando
    
    // ESTOQUE - Módulo de Inventário
    inventory: (context) => const InventoryProductsScreen(),
    inventoryList: (context) => const InventoryProductsScreen(),
    inventoryReport: (context) => const InventoryProductsScreen(),
    inventoryMovement: (context) => const InventoryProductsScreen(),
    
    
    // RELATÓRIOS
    reports: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AdvancedAnalyticsDashboard(
        talhaoId: args?['talhaoId'],
        culturaId: args?['culturaId'],
        sessionId: args?['sessionId'],
        monitoringData: args?['monitoringData'],
      );
    },
    integratedDashboard: (context) => const IntegratedStatisticsDashboard(), // Dashboard integrado com notificações em tempo real
    '/reports/planting/complete': (context) {
      final plantioData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (plantioData == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Erro')),
          body: const Center(child: Text('Dados do plantio não encontrados')),
        );
      }
      return CompletePlantingDetailScreen(plantioData: plantioData);
    },
    learningDashboard: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return LearningDashboardScreen(
        farmId: args?['farmId'] ?? 'default',
        farmName: args?['farmName'] ?? 'Fazenda',
      );
    },

    plantingReport: (context) => const PlantingReportScreen(),
    applicationReport: (context) => const ApplicationReportScreen(),
    monitoringDashboard: (context) => const MonitoringDashboard(),
    infestationDashboard: (context) => const InfestationDashboard(),
    // Módulo de colheita removido
    
    // SISTEMA DE CUSTOS POR HECTARE
    custoPorHectareDashboard: (context) => CustoPorHectareDashboardScreen(),
    historicoCustosTalhao: (context) => HistoricoCustosTalhaoScreen(),
    mainMenuWithCosts: (context) => MainMenuWithCostsIntegration(),
    gestaoCustos: (context) => const GestaoCustosScreen(),
    novaPrescricao: (context) => const prescricao.PrescricaoPremiumScreen(), // Tela elegante de prescrição premium
    prescricaoLista: (context) => const PrescricoesAgronomicasScreen(), // Lista de prescrições
    prescricaoRelatorios: (context) => const PrescricaoRelatoriosScreen(), // Relatórios de prescrições
    
    // ALERTAS - Removido (funcionalidades transferidas para mapa de infestação)
    // alertLevelConfig: (context) => const alert_config_new.AlertLevelConfigScreen(), // Removido
    
    // Módulo de atividades removido
    
    // PRESCRIÇÕES
    prescriptions: (context) => const PrescriptionListScreen(),
    prescriptionList: (context) => const PrescriptionListScreen(),
    
    // SOLO
    soilCalculationMain: (context) => const SoilCompactionMainV2Screen(),
    soilCompaction: (context) => const SoilCompactionMenuScreen(),
    soilCompactionSimple: (context) => const SimpleCompactionScreen(),
    soilSamplePlotSelection: (context) => const SoilSamplePlotSelectionScreen(),
    addSoilAnalysis: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AddSoilAnalysisScreen(
        plotId: args?['plotId'] as String?,
        plotName: args?['plotName'] as String?,
      );
    },
    
    // CALIBRAÇÃO DE FERTILIZANTES
    '/fertilizer_calibration': (context) => const FertilizerCalibrationSimplifiedScreen(),
    '/fertilizer_calibration_history': (context) => const FertilizerCalibrationHistoryScreen(),
    calibracaoFertilizante: (context) => const FertilizerCalibrationSimplifiedScreen(),
    calculoBasicoCalibracao: (context) => const CalculoBasicoCalibracaoScreen(),
    historicoCalibracoes: (context) => const HistoricoCalculoBasicoScreen(),
    
    // DIAGNÓSTICO
    '/diagnostic/talhoes': (context) => const TalhaoDiagnosticScreen(),
    
    // INFESTAÇÃO - Redirecionado para Relatório Agronômico
    mapaInfestacao: (context) {
      // Redirecionar para Relatório Agronômico (Aba Infestação)
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AdvancedAnalyticsDashboard(
        talhaoId: args?['talhaoId'],
        culturaId: args?['culturaId'],
        sessionId: args?['sessionId'],
        monitoringData: args?['monitoringData'],
      );
    },
    
          // MONITORAMENTO
      monitoringMain: (context) => const AdvancedMonitoringScreen(),
      advancedMonitoring: (context) => const AdvancedMonitoringScreen(),
      monitoringPoint: (context) {
        try {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          
          if (args == null) {
            throw Exception('Argumentos não fornecidos para a tela de ponto de monitoramento');
          }
          
          // Validar argumentos obrigatórios
          final pontoId = args['pontoId'];
          final talhaoId = args['talhaoId'];
          final culturaId = args['culturaId'];
          final talhaoNome = args['talhaoNome'];
          final culturaNome = args['culturaNome'];
          final sessionId = args['sessionId'] as String?; // ✅ ADICIONAR SESSION ID OPCIONAL
          
          if (pontoId == null) {
            throw Exception('pontoId não fornecido');
          }
          if (talhaoId == null) {
            throw Exception('talhaoId não fornecido');
          }
          if (culturaId == null) {
            throw Exception('culturaId não fornecido');
          }
          if (talhaoNome == null) {
            throw Exception('talhaoNome não fornecido');
          }
          if (culturaNome == null) {
            throw Exception('culturaNome não fornecido');
          }
          
          return PointMonitoringScreen(
            pontoId: pontoId,
            talhaoId: talhaoId.toString(),
            culturaId: culturaId.toString(),
            talhaoNome: talhaoNome.toString(),
            culturaNome: culturaNome.toString(),
            pontos: args['pontos'],
            data: args['data'],
            sessionId: sessionId, // ✅ PASSAR SESSION ID
          );
        } catch (e) {
          // Retornar uma tela de erro em caso de problema com os argumentos
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erro'),
              backgroundColor: Colors.red,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao abrir monitoramento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          );
        }
      },
      monitoringHistory: (context) => const MonitoringHistoryScreen(),
      monitoringHistoryView: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return MonitoringHistoryViewScreen();
      },
      
      // MONITORAMENTO V2
      monitoringHistoryV2: (context) => const MonitoringHistoryV2Screen(),
      monitoringDetailsV2: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return MonitoringDetailsV2Screen(
          sessionData: args['sessionData'] as Map<String, dynamic>,
        );
      },
      monitoringPointResume: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return MonitoringPointResumeScreen(
          sessionId: args['sessionId'] as String,
          sessionData: args['sessionData'] as Map<String, dynamic>,
        );
      },
      monitoringPointEdit: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        
        if (args == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: const Center(child: Text('Argumentos não fornecidos')),
          );
        }
        
        return MonitoringPointEditScreen(
          pointData: args['pointData'] as Map<String, dynamic>? ?? args['sessionData'] as Map<String, dynamic>? ?? {},
          sessionId: args['sessionId'] as String? ?? (args['sessionData'] as Map<String, dynamic>?)?['id'] as String? ?? '',
        );
      },
    
    // CONFIGURAÇÃO DE ORGANISMOS
    organismCatalog: (context) => const OrganismCatalogEnhancedScreen(),
    infestationRules: (context) => const InfestationRulesEditScreen(), // Regras de Infestação com Fenologia
    
    // MÓDULO DE GERMINAÇÃO - Novo módulo
    germinationMain: (context) => const GerminationMainScreen(),
    germinationTests: (context) => const GerminationTestListScreen(),
    germinationTestCreate: (context) => const GerminationTestCreateScreen(),
    germinationTestSettings: (context) => const GerminationTestSettingsScreen(),
    
    // MÓDULO DE EVOLUÇÃO FENOLÓGICA - Novo módulo (12 culturas)
    phenologicalMain: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PhenologicalMainScreen(
        talhaoId: args?['talhaoId'],
        culturaId: args?['culturaId'],
        talhaoNome: args?['talhaoNome'],
        culturaNome: args?['culturaNome'],
      );
    },
    phenologicalRecord: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PhenologicalRecordScreen(
        talhaoId: args?['talhaoId'],
        culturaId: args?['culturaId'],
        talhaoNome: args?['talhaoNome'],
        culturaNome: args?['culturaNome'],
      );
    },
    phenologicalHistory: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PhenologicalHistoryScreen(
        talhaoId: args?['talhaoId'] ?? '',
        culturaId: args?['culturaId'] ?? '',
        talhaoNome: args?['talhaoNome'],
        culturaNome: args?['culturaNome'],
      );
    },
    
    // SUBÁREAS E EXPERIMENTOS
    talhaoDetalhes: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final experimento = args['experimento'];
      return TalhaoDetalhesScreen(experimento: experimento);
    },
    subareaDetalhes: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final subarea = args['subarea'];
      return SubareaDetalhesScreen(subarea: subarea);
    },
    criarSubarea: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final experimentoId = args['experimentoId'] as String? ?? '';
      final talhaoId = args['talhaoId'] as String? ?? '';
      return CriarSubareaScreen(
        experimentoId: experimentoId,
        talhaoId: talhaoId,
      );
    },
    exemploSubareas: (context) => const Scaffold(
      body: Center(
        child: Text('Funcionalidade em desenvolvimento'),
      ),
    ),
    experimentoMelhorado: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final experimento = args['experimento'] as ExperimentoCompleto?;
      if (experimento == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Experimento não encontrado'),
          ),
        );
      }
      return ExperimentoMelhoradoScreen(experimento: experimento);
    },
    
    // VARIEDADES
    variedadesCadastro: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final culturaId = args?['culturaId'] as String?;
      return CropVarietyFormScreen(cropId: culturaId);
    },
    variedadesLista: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final culturaId = args?['culturaId'] as String?;
      final culturaNome = args?['culturaNome'] as String?;
      return CropVarietyListScreen(cropId: culturaId, cropName: culturaNome);
    },
    
            // MAPAS OFFLINE - VERSÕES APRIMORADAS
            offlineMaps: (context) => const EnhancedOfflineMapsScreen(),
            offlineMapsDownload: (context) => const EnhancedMapDownloadScreen(),
    
    
    // SATÉLITE
    // enhancedSatellite: (context) => const EnhancedSatelliteScreen(),
    
    // ACOMPANHAMENTO DE SAFRA

  };

  /// Rotas condicionais baseadas na configuração dos módulos
  static Map<String, WidgetBuilder> get conditionalRoutes {
    final Map<String, WidgetBuilder> conditionalRoutes = {};

    // Módulo de Plantio
    if (ModuleConfig.enablePlantioModule) {
      conditionalRoutes.addAll({
        planterCalibrationList: (context) => const PlanterCalibrationListScreen(),
        planterCalibrationNew: (context) => const PlanterCalibrationScreen(),
        // Removido submódulo de experimentos duplicado
        estandeCalculation: (context) => const PlantingListScreen(), // Temporariamente usando PlantingListScreen
        calculoSementes: (context) => const PlantingListScreen(), // Temporariamente usando PlantingListScreen,
      });
    }

    // Módulo de Aplicação de Produtos
    if (ModuleConfig.enableProductApplicationModule) {
      conditionalRoutes.addAll({
        productApplicationList: (context) => const pesticide_application.PesticideApplicationListScreen(), // Temporariamente usando PesticideApplicationListScreen
        productApplicationForm: (context) {
          final applicationId = ModalRoute.of(context)?.settings.arguments as String?;
          return pesticide_application_form.PesticideApplicationFormScreen(applicationId: applicationId);
        },
        productApplicationDetails: (context) {
          final applicationId = ModalRoute.of(context)?.settings.arguments as String?;
          return applicationId != null
            ? pesticide_application_details.PesticideApplicationDetailsScreen(applicationId: applicationId)
            : const pesticide_application.PesticideApplicationListScreen();
        },
      });
    }

    // Módulo de Aplicação Agrícola (Legacy)
    if (ModuleConfig.enableAplicacaoModule) {
      conditionalRoutes.addAll({
        aplicacaoHome: (context) => const AplicacaoHomeScreen(),
        aplicacaoLista: (context) => const AplicacaoListaScreen(),
        aplicacaoRegistro: (context) {
          final aplicacaoId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return AplicacaoRegistroScreen(aplicacaoId: aplicacaoId);
        },
        aplicacaoDetalhes: (context) {
          final aplicacaoId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return AplicacaoDetalhesScreen(aplicacaoId: aplicacaoId);
        },
        aplicacaoRelatorio: (context) => const AplicacaoRelatorioScreen(),
        aplicacaoPrescricao: (context) => const prescricao.PrescricaoPremiumScreen(), // Tela elegante de prescrição premium
      });
    }

    // Módulo de Relatórios
    if (ModuleConfig.enableReportsModule) {
      conditionalRoutes.addAll({
        reportsModule: (context) => const ReportsModule(),
        inventoryStockReport: (context) => const new_reports.InventoryReportScreen(),
        productApplicationReport: (context) => const ProductApplicationReportScreen(),
        agronomistReports: (context) => const AdvancedAnalyticsDashboard(), // Tela de relatório agronômico com 4 abas incluindo Dashboard
        consolidatedReport: (context) => const AdvancedAnalyticsDashboard(), // Tela correta com 3 abas e dashboard
           // integratedPlantingReport: (context) => const IntegratedPlantingReportScreen(), // Temporariamente desabilitado
      });
    }
    
    // Módulo de IA
    conditionalRoutes.addAll({
      aiDashboard: (context) => const AIDashboardScreen(),
      aiDiagnosis: (context) => const AIDiagnosisScreen(),
      aiOrganismCatalog: (context) => const ai_organism.OrganismCatalogScreen(),
      aiMonitoring: (context) => const AIMonitoringScreen(),
    });

    // Sistema de Custos por Hectare
    if (ModuleConfig.enableCostsModule) {
      conditionalRoutes.addAll({
        custoPorHectareDashboard: (context) => CustoPorHectareDashboardScreen(),
        historicoCustosTalhao: (context) => HistoricoCustosTalhaoScreen(),
        mainMenuWithCosts: (context) => MainMenuWithCostsIntegration(),
      });
    }

    // Módulo de Gestão de Custos
    if (ModuleConfig.enableCostsModule) {
      conditionalRoutes.addAll({
        costManagement: (context) => const CostManagementMainScreen(),
        costManagementMain: (context) => const CostManagementMainScreen(),
    
        costSimulation: (context) => const CostSimulationScreen(),
        costReport: (context) => const CostReportScreen(),
        costApplicationsList: (context) => const ApplicationsListScreen(),
      });
    }

    // Módulo de Importação & Exportação
    if (ModuleConfig.enableImportExportModule) {
      conditionalRoutes.addAll({
        importExportMain: (context) => const ImportExportMainScreen(),
        importExportExport: (context) => const ExportScreen(),
        importExportImport: (context) => const ImportScreen(),
      });
    }

    // Módulo de colheita removido

    return conditionalRoutes;
  }

  /// Mapa completo de rotas incluindo as condicionais
  static Map<String, WidgetBuilder> get allRoutes {
    return {
      ...routes,
      ...conditionalRoutes,
      ...SoilRoutes.routes,
      ...SubareaRoutes.routes,
    };
  }

  /// Método para verificar se uma rota existe
  static bool hasRoute(String routeName) {
    return allRoutes.containsKey(routeName);
  }

  /// Método para obter uma rota específica
  static WidgetBuilder? getRoute(String routeName) {
    return allRoutes[routeName];
  }

  /// Método para navegar para uma rota com verificação de existência
  static Future<T?> navigateTo<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (hasRoute(routeName)) {
      return Navigator.pushNamed<T>(
        context,
        routeName,
        arguments: arguments,
      );
    } else {
      debugPrint('Rota não encontrada: $routeName');
      return Future.value(null);
    }
  }

  /// Método helper para navegar e substituir a rota atual
  static Future<T?> navigateAndReplace<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (hasRoute(routeName)) {
      return Navigator.pushReplacementNamed<T, void>(
        context,
        routeName,
        arguments: arguments,
      );
    } else {
      debugPrint('Rota não encontrada: $routeName');
      return Future.value(null);
    }
  }

  /// Método helper para navegar e limpar o stack
  static Future<T?> navigateAndClear<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (hasRoute(routeName)) {
      return Navigator.pushNamedAndRemoveUntil<T>(
        context,
        routeName,
        (route) => false,
        arguments: arguments,
      );
    } else {
      debugPrint('Rota não encontrada: $routeName');
      return Future.value(null);
    }
  }

  /// Método para gerar rotas dinamicamente (compatibilidade com main.dart)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    final args = settings.arguments;

    if (routeName == null) {
      return _errorRoute('Nome da rota não fornecido');
    }

    final routeBuilder = allRoutes[routeName];
    if (routeBuilder != null) {
      return MaterialPageRoute(
        builder: (context) => routeBuilder(context),
        settings: settings,
      );
    }

    return _errorRoute('Rota não encontrada: $routeName');
  }

  /// Rota de erro para casos não encontrados
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erro'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}