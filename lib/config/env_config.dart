import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração de ambiente segura
/// Carrega variáveis do arquivo .env
class EnvConfig {
  static bool _initialized = false;
  
  /// Inicializa as configurações de ambiente
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      // Configurações carregadas com sucesso
    } catch (e) {
      // Arquivo .env não encontrado, usando configurações padrão
      _initialized = true;
    }
  }
  
  /// Obtém a chave da API do MapTiler
  static String get mapTilerApiKey {
    return 'KQAa9lY3N0TR17zxhk9u'; // Hardcoded temporariamente
  }
  
  /// Obtém a URL base do MapTiler
  static String get mapTilerBaseUrl {
    return 'https://api.maptiler.com'; // Hardcoded temporariamente
  }
  
  /// Verifica se está em modo debug
  static bool get isDebugMode {
    return dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true' || true;
  }
  
  /// Obtém o nível de log
  static String get logLevel {
    return dotenv.env['LOG_LEVEL'] ?? 'info';
  }
  
  /// Verifica se as configurações estão inicializadas
  static bool get isInitialized => _initialized;
}
