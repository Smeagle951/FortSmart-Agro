/// Classe que define os endpoints da API
class ApiEndpoints {
  /// URL base da API
  static const String baseUrl = 'https://api.fortsmartagro.com.br';
  
  /// Endpoint para autenticação
  static const String auth = '/auth';
  
  /// Endpoint para sincronização
  static const String sync = '/sync';
  
  /// Endpoint para propriedades
  static const String properties = '/properties';
  
  /// Endpoint para talhões
  static const String plots = '/plots';
  
  /// Endpoint para amostras de solo
  static const String soilSamples = '/soil-samples';
  
  /// Endpoint para monitoramento
  static const String monitoring = '/monitoring';
  
  /// Endpoint para aplicações de defensivos
  static const String pesticideApplications = '/pesticide-applications';
  
  /// Endpoint para perdas na colheita
  static const String harvestLosses = '/harvest-losses';
  
  /// Endpoint para plantios
  static const String plantings = '/plantings';
  
  /// Endpoint para upload de imagens
  static const String imageUpload = '/images/upload';
  
  /// Endpoint para download de imagens
  static const String imageDownload = '/images/download';
  
  /// Endpoint para relatórios
  static const String reports = '/reports';
  
  /// Endpoint para usuários
  static const String users = '/users';
  
  /// Endpoint para configurações
  static const String settings = '/settings';
  
  /// Endpoint para logs
  static const String logs = '/logs';
  
  /// Endpoint para versão
  static const String version = '/version';
  
  /// Retorna a URL completa para um endpoint específico
  static String getUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}
