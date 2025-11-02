/// Enumerações utilizadas no aplicativo

/// Enum para representar o status de sincronização
enum SyncStatus { 
  pending,       // Item não sincronizado
  syncing,       // Em processo de sincronização
  synced,        // Item sincronizado com sucesso
  error,         // Erro durante a sincronização
  offline,       // Dispositivo offline
  partialError,  // Sincronização parcial (alguns itens sincronizados, outros não)
  permanentError, // Erro permanente que não pode ser resolvido
  completed      // Sincronização completa
}

/// Extensão para compatibilidade com código existente
extension SyncStatusExtension on SyncStatus {
  /// Verifica se o status é sincronizado
  bool get synced => this == SyncStatus.synced;
  
  /// Verifica se o status é parcialmente sincronizado
  bool get partialError => this == SyncStatus.partialError;
  
  /// Verifica se o status é sincronizado
  bool get isSynced => this == SyncStatus.synced;
  
  /// Verifica se o status é parcialmente sincronizado
  bool get isPartialSync => this == SyncStatus.partialError;
  
  /// Verifica se o status é um erro permanente
  bool get isPermanentError => this == SyncStatus.permanentError;
  
  /// Verifica se o status é um erro
  bool get isError => this == SyncStatus.error || this == SyncStatus.permanentError;
  
  /// Verifica se o status está em sincronização
  bool get isSyncing => this == SyncStatus.syncing;
  
  /// Verifica se o status está pendente
  bool get isPending => this == SyncStatus.pending;
}

/// Enum para representar o tipo de conexão
enum ConnectionType {
  wifi,
  mobile,
  none
}

/// Enum para representar o tipo de aplicação de defensivos
enum ApplicationType {
  ground,    // Terrestre
  aerial,    // Aérea
  manual,    // Manual
  mixed,     // Mista
  other      // Outra
}

/// Enum para representar o tipo de perda na colheita
enum HarvestLossType {
  preharvest, // Pré-colheita
  harvesting, // Durante colheita
  transport,  // Transporte
  storage,    // Armazenamento
  other       // Outros tipos
}

/// Enum para representar o tipo de ocorrência no monitoramento
enum OccurrenceType {
  pest,       // Praga
  disease,    // Doença
  weed,       // Erva daninha
  deficiency, // Deficiência nutricional
  other       // Outros
}

/// Enum para representar o terço da planta atacado
enum PlantSection {
  upper,    // Superior (compatibilidade)
  middle,   // Médio (compatibilidade)
  lower,    // Inferior (compatibilidade)
  leaf,     // Folha
  stem,     // Caule
  root,     // Raiz
  flower,   // Flor
  fruit,    // Fruto
  seed      // Semente
}

/// Enum para representar o status de uma operação
enum OperationStatus {
  notStarted, // Não iniciada
  inProgress, // Em andamento
  completed,  // Concluída
  canceled,   // Cancelada
  failed      // Falhou
}

/// Enum para tipo de relatório
enum ReportType {
  soil,       // Solo
  harvest,    // Colheita
  monitoring, // Monitoramento
  application // Aplicação de defensivos
}

/// Enum para representar o tipo de amostra de solo
enum SoilSampleType {
  standard,
  detailed,
  custom
}

/// Enum para representar a estratégia de limpeza de armazenamento
enum StorageCleanupStrategy {
  removeOldImages,
  removeUnusedFiles,
  compressLargeFiles,
  all
}

/// Enum para representar o tipo de clima
enum WeatherConditionType {
  clear,
  cloudy,
  partlyCloudy,
  rain,
  thunderstorm,
  snow,
  mist,
  unknown
}

/// Enum para representar a unidade de medida
enum MeasurementUnit {
  metric,
  imperial
}

/// Enum para representar o tipo de gráfico
enum ChartType {
  line,
  bar,
  pie,
  scatter,
  radar
}

/// Enum para representar o período de tempo
enum TimePeriod {
  hourly,
  daily,
  weekly,
  monthly,
  yearly
}

/// Extensão para converter enum OccurrenceType para string e vice-versa
extension OccurrenceTypeExtension on OccurrenceType {
  String get displayName {
    switch (this) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      case OccurrenceType.deficiency:
        return 'Deficiência Nutricional';
      case OccurrenceType.other:
        return 'Outro';
    }
  }
  
  static OccurrenceType fromString(String value) {
    switch (value) {
      case 'Praga':
        return OccurrenceType.pest;
      case 'Doença':
        return OccurrenceType.disease;
      case 'Planta Daninha':
        return OccurrenceType.weed;
      case 'Deficiência Nutricional':
        return OccurrenceType.deficiency;
      case 'Outro':
        return OccurrenceType.other;
      default:
        return OccurrenceType.other;
    }
  }
}

/// Extensão para converter enum PlantSection para string e vice-versa
extension PlantSectionExtension on PlantSection {
  String get displayName {
    switch (this) {
      case PlantSection.upper:
        return 'Superior';
      case PlantSection.middle:
        return 'Médio';
      case PlantSection.lower:
        return 'Inferior';
      case PlantSection.leaf:
        return 'Folha';
      case PlantSection.stem:
        return 'Caule';
      case PlantSection.root:
        return 'Raiz';
      case PlantSection.flower:
        return 'Flor';
      case PlantSection.fruit:
        return 'Fruto';
      case PlantSection.seed:
        return 'Semente';
    }
  }
  
  static PlantSection fromString(String value) {
    switch (value) {
      case 'Superior':
        return PlantSection.upper;
      case 'Médio':
        return PlantSection.middle;
      case 'Inferior':
        return PlantSection.lower;
      case 'Folha':
        return PlantSection.leaf;
      case 'Caule':
        return PlantSection.stem;
      case 'Raiz':
        return PlantSection.root;
      case 'Flor':
        return PlantSection.flower;
      case 'Fruto':
        return PlantSection.fruit;
      case 'Semente':
        return PlantSection.seed;
      default:
        return PlantSection.middle;
    }
  }
}
