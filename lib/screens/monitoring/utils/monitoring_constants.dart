/// Constantes para o módulo de monitoramento
class MonitoringConstants {
  // Valores padrão
  static const double defaultMapHeight = 400.0;
  static const double defaultMapZoom = 13.0;
  static const double defaultMapMinZoom = 3.0;
  static const double defaultMapMaxZoom = 18.0;
  
  // Timeouts
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration initializationTimeout = Duration(seconds: 5);
  
  // Cores padrão
  static const int defaultTalhaoColor = 0xFF4CAF50; // Verde
  static const int defaultCulturaColor = 0xFF2196F3; // Azul
  static const int defaultErrorColor = 0xFFF44336; // Vermelho
  static const int defaultWarningColor = 0xFFFF9800; // Laranja
  static const int defaultSuccessColor = 0xFF4CAF50; // Verde
  
  // Tamanhos
  static const double defaultCardElevation = 2.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  
  // Ícones padrão
  static const String defaultTalhaoIcon = 'agriculture';
  static const String defaultCulturaIcon = 'grass';
  static const String defaultLocationIcon = 'my_location';
  static const String defaultMapIcon = 'map';
  
  // URLs padrão
  static const String defaultTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String satelliteTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  // Coordenadas padrão (Brasília)
  static const double defaultLatitude = -15.793889;
  static const double defaultLongitude = -47.882778;
  
  // Filtros padrão
  static const List<String> defaultSeverityLevels = [
    'Baixa',
    'Média', 
    'Alta',
    'Crítica',
  ];
  
  static const List<String> defaultFilterTypes = [
    'all',
    'critical',
    'recent',
    'pending',
  ];
  
  // Estados padrão
  static const bool defaultSatelliteMode = true;
  static const bool defaultShowControls = true;
  static const bool defaultShowLegend = true;
  static const bool defaultShowAdvancedFilters = true;
  static const bool defaultShowDateFilter = true;
  
  // Mensagens padrão
  static const String defaultLoadingMessage = 'Carregando módulo de monitoramento...';
  static const String defaultErrorMessage = 'Erro ao carregar módulo de monitoramento';
  static const String defaultNoDataMessage = 'Nenhum dado disponível';
  static const String defaultNoSelectionMessage = 'Nenhuma seleção ativa';
  
  // Títulos padrão
  static const String defaultAppTitle = 'Monitoramento';
  static const String defaultSectionTitle = 'Seção';
  static const String defaultCardTitle = 'Card';
  
  // Labels padrão
  static const String defaultCulturaLabel = 'Cultura';
  static const String defaultTalhaoLabel = 'Talhão';
  static const String defaultDataLabel = 'Data';
  static const String defaultStatusLabel = 'Status';
  static const String defaultLocationLabel = 'Localização';
  
  // Valores padrão para filtros
  static const String defaultFilterAll = 'all';
  static const String defaultFilterCritical = 'critical';
  static const String defaultFilterRecent = 'recent';
  static const String defaultFilterPending = 'pending';
  
  // Valores padrão para severidade
  static const String defaultSeverityLow = 'Baixa';
  static const String defaultSeverityMedium = 'Média';
  static const String defaultSeverityHigh = 'Alta';
  static const String defaultSeverityCritical = 'Crítica';
  
  // Valores padrão para tipos de cultura
  static const String defaultCulturaTypeSoja = 'soja';
  static const String defaultCulturaTypeMilho = 'milho';
  static const String defaultCulturaTypeAlgodao = 'algodão';
  static const String defaultCulturaTypeCafe = 'café';
  static const String defaultCulturaTypeCana = 'cana';
  
  // Valores padrão para cores de cultura
  static const int defaultCulturaColorSoja = 0xFF4CAF50; // Verde
  static const int defaultCulturaColorMilho = 0xFFFFEB3B; // Amarelo
  static const int defaultCulturaColorAlgodao = 0xFFFF9800; // Laranja
  static const int defaultCulturaColorCafe = 0xFF795548; // Marrom
  static const int defaultCulturaColorCana = 0xFF8BC34A; // Verde claro
  
  // Valores padrão para ícones de cultura
  static const String defaultCulturaIconSoja = 'grass';
  static const String defaultCulturaIconMilho = 'eco';
  static const String defaultCulturaIconAlgodao = 'local_florist';
  static const String defaultCulturaIconCafe = 'local_cafe';
  static const String defaultCulturaIconCana = 'forest';
  
  // Valores padrão para animações
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration defaultPulseAnimationDuration = Duration(milliseconds: 1000);
  static const Duration defaultSlideAnimationDuration = Duration(milliseconds: 500);
  
  // Valores padrão para refresh
  static const Duration defaultRefreshInterval = Duration(minutes: 5);
  static const Duration defaultAutoRefreshInterval = Duration(minutes: 10);
  
  // Valores padrão para cache
  static const Duration defaultCacheExpiration = Duration(hours: 1);
  static const int defaultMaxCacheSize = 100;
  
  // Valores padrão para logs
  static const String defaultLogTag = 'Monitoring';
  static const String defaultLogPrefix = '📊';
  static const String defaultErrorLogPrefix = '❌';
  static const String defaultSuccessLogPrefix = '✅';
  static const String defaultWarningLogPrefix = '⚠️';
  static const String defaultInfoLogPrefix = 'ℹ️';
}
