/// Configuração de módulos do aplicativo
/// Este arquivo permite habilitar/desabilitar módulos específicos
/// para facilitar o desenvolvimento e testes

class ModuleConfig {
  /// Módulo de Plantio
  static const bool enablePlantioModule = true;
  
  /// Módulo de Colheita
  static const bool enableHarvestModule = true;
  
  /// Módulo de Aplicação de Produtos
  static const bool enableProductApplicationModule = true;
  
  /// Módulo de Aplicação Agrícola (Legacy)
  static const bool enableAplicacaoModule = true;
  
  /// Módulo de Relatórios
  static const bool enableReportsModule = true;
  
  /// Módulo de Monitoramento (sempre habilitado)
  static const bool enableMonitoringModule = true;
  
  /// Módulo de Alertas (sempre habilitado)
  static const bool enableAlertsModule = true;
  
  /// Módulo de Talhões (sempre habilitado)
  static const bool enablePlotsModule = true;
  
  /// Sistema de Custos por Hectare
  static const bool enableCostsModule = true;
  
  /// Módulo de Importação & Exportação
  static const bool enableImportExportModule = true;
  
  /// Módulo de Tratamento de Sementes (TS)
  static const bool enableTSModule = false; // Desabilitado por padrão para não travar compilação
}
