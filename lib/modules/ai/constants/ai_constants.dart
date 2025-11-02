/// Constantes do Sistema IA FortSmart
class AIConstants {
  // ===== CONFIGURAÇÕES GERAIS =====
  
  /// Nome do sistema IA
  static const String systemName = 'FortSmart IA';
  
  /// Versão atual do sistema IA
  static const String version = '2.0.0';
  
  /// Descrição do sistema
  static const String description = 'Sistema Inteligente de Diagnóstico Agrícola';
  
  // ===== CONFIGURAÇÕES DE DIAGNÓSTICO =====
  
  /// Limite mínimo de confiança para diagnóstico
  static const double minConfidenceThreshold = 0.3;
  
  /// Limite alto de confiança para diagnóstico
  static const double highConfidenceThreshold = 0.7;
  
  /// Número máximo de resultados por diagnóstico
  static const int maxDiagnosisResults = 5;
  
  /// Peso para sintomas principais no cálculo de similaridade
  static const double primarySymptomWeight = 1.0;
  
  /// Peso para sintomas secundários no cálculo de similaridade
  static const double secondarySymptomWeight = 0.7;
  
  /// Peso para palavras-chave no cálculo de similaridade
  static const double keywordWeight = 0.5;
  
  // ===== CONFIGURAÇÕES DE SEVERIDADE =====
  
  /// Limite para severidade baixa
  static const double lowSeverityThreshold = 0.4;
  
  /// Limite para severidade média
  static const double mediumSeverityThreshold = 0.7;
  
  /// Limite para severidade alta
  static const double highSeverityThreshold = 0.8;
  
  // ===== CONFIGURAÇÕES DE PREDIÇÃO =====
  
  /// Período de predição em dias
  static const int predictionPeriodDays = 30;
  
  /// Intervalo de atualização de predições (em horas)
  static const int predictionUpdateIntervalHours = 6;
  
  /// Limite de risco baixo
  static const double lowRiskThreshold = 0.3;
  
  /// Limite de risco médio
  static const double mediumRiskThreshold = 0.6;
  
  /// Limite de risco alto
  static const double highRiskThreshold = 0.8;
  
  // ===== CONFIGURAÇÕES DE IMAGEM =====
  
  /// Tamanho máximo de imagem em MB
  static const int maxImageSizeMB = 10;
  
  /// Formatos de imagem suportados
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  
  /// Qualidade de compressão de imagem (0-100)
  static const int imageCompressionQuality = 85;
  
  /// Tamanho máximo de largura da imagem
  static const int maxImageWidth = 1920;
  
  /// Tamanho máximo de altura da imagem
  static const int maxImageHeight = 1080;
  
  // ===== CONFIGURAÇÕES DE CACHE =====
  
  /// Tempo de cache para organismos (em minutos)
  static const int organismCacheMinutes = 60;
  
  /// Tempo de cache para diagnósticos (em minutos)
  static const int diagnosisCacheMinutes = 30;
  
  /// Tempo de cache para predições (em minutos)
  static const int predictionCacheMinutes = 120;
  
  /// Tamanho máximo do cache em MB
  static const int maxCacheSizeMB = 100;
  
  // ===== CONFIGURAÇÕES DE PERFORMANCE =====
  
  /// Timeout para operações de diagnóstico (em segundos)
  static const int diagnosisTimeoutSeconds = 30;
  
  /// Timeout para operações de predição (em segundos)
  static const int predictionTimeoutSeconds = 45;
  
  /// Timeout para upload de imagem (em segundos)
  static const int imageUploadTimeoutSeconds = 60;
  
  /// Número máximo de tentativas para operações
  static const int maxRetryAttempts = 3;
  
  // ===== CONFIGURAÇÕES DE UI =====
  
  /// Duração das animações em milissegundos
  static const int animationDurationMs = 300;
  
  /// Duração das transições em milissegundos
  static const int transitionDurationMs = 200;
  
  /// Delay para feedback visual em milissegundos
  static const int feedbackDelayMs = 1500;
  
  /// Altura padrão dos cards
  static const double defaultCardHeight = 120.0;
  
  /// Padding padrão
  static const double defaultPadding = 16.0;
  
  /// Border radius padrão
  static const double defaultBorderRadius = 8.0;
  
  // ===== CONFIGURAÇÕES DE LOGGING =====
  
  /// Nível de log para desenvolvimento
  static const bool enableDebugLogs = true;
  
  /// Nível de log para produção
  static const bool enableProductionLogs = false;
  
  /// Prefixo para logs da IA
  static const String logPrefix = '[FortSmart IA]';
  
  // ===== CONFIGURAÇÕES DE CULTURAS =====
  
  /// Culturas suportadas pelo sistema (expandido para incluir mais culturas)
  static const List<String> supportedCrops = [
    'Soja',
    'Milho',
    'Algodão',
    'Feijão',
    'Trigo',
    'Sorgo',
    'Girassol',
    'Aveia',
    'Gergelim',
    'Cana-de-açúcar',
    'Tomate',
    'Batata',
    'Café',
    'Arroz',
    'Mandioca',
    'Banana',
    'Laranja',
    'Uva',
    'Maçã',
    'Abacaxi',
    'Manga',
    'Limão',
    'Pêssego',
    'Pera',
    'Cenoura',
    'Cebola',
    'Alho',
    'Pimentão',
    'Berinjela',
    'Pepino',
    'Melancia',
    'Melão',
    'Girassol',
  ];
  
  /// Tipos de organismos suportados
  static const List<String> supportedOrganismTypes = [
    'pest',
    'disease',
  ];
  
  // ===== CONFIGURAÇÕES DE VALIDAÇÃO =====
  
  /// Comprimento mínimo para busca
  static const int minSearchLength = 2;
  
  /// Comprimento máximo para busca
  static const int maxSearchLength = 100;
  
  /// Número mínimo de sintomas para diagnóstico
  static const int minSymptomsForDiagnosis = 1;
  
  /// Número máximo de sintomas para diagnóstico
  static const int maxSymptomsForDiagnosis = 10;
  
  // ===== MENSAGENS DE ERRO =====
  
  /// Mensagens de erro comuns
  static const Map<String, String> errorMessages = {
    'network_error': 'Erro de conexão. Verifique sua internet.',
    'timeout_error': 'Tempo limite excedido. Tente novamente.',
    'invalid_image': 'Imagem inválida. Use JPG, PNG ou WebP.',
    'image_too_large': 'Imagem muito grande. Máximo 10MB.',
    'no_results': 'Nenhum resultado encontrado.',
    'invalid_symptoms': 'Sintomas inválidos.',
    'cache_error': 'Erro no cache. Tente novamente.',
    'prediction_error': 'Erro na predição. Tente novamente.',
    'diagnosis_error': 'Erro no diagnóstico. Tente novamente.',
  };
  
  /// Mensagens de sucesso
  static const Map<String, String> successMessages = {
    'diagnosis_complete': 'Diagnóstico concluído com sucesso!',
    'prediction_complete': 'Predição concluída com sucesso!',
    'image_uploaded': 'Imagem enviada com sucesso!',
    'cache_cleared': 'Cache limpo com sucesso!',
    'settings_saved': 'Configurações salvas com sucesso!',
  };
  
  // ===== CONFIGURAÇÕES DE DESENVOLVIMENTO =====
  
  /// Modo de desenvolvimento
  static const bool isDevelopmentMode = true;
  
  /// URL base para APIs (desenvolvimento)
  static const String devApiBaseUrl = 'http://localhost:3000/api';
  
  /// URL base para APIs (produção)
  static const String prodApiBaseUrl = 'https://api.fortsmart.com';
  
  /// Chave da API (desenvolvimento)
  static const String devApiKey = 'dev_key_123';
  
  /// Chave da API (produção)
  static const String prodApiKey = 'prod_key_456';
}
