/// Módulo de Mapa de Infestação - FortSmart Agro
/// 
/// Este módulo fornece funcionalidades para:
/// - Visualização de mapas de infestação com dados REAIS
/// - Análise de dados de monitoramento existentes
/// - Geração de alertas automáticos baseados em dados reais
/// - Estatísticas e relatórios com dados reais
/// - Integração direta com módulos existentes (Monitoramento, Talhões, Catálogo)
/// 
/// ⚠️ IMPORTANTE: Este módulo NÃO usa dados de exemplo.
/// Todos os dados são coletados dos módulos existentes do sistema.

// Exporta todos os componentes do módulo
export 'models/models.dart';
export 'services/services.dart';
export 'repositories/repositories.dart';
export 'widgets/widgets.dart';
export 'utils/utils.dart';
export 'screens/infestation_map_screen.dart';

/// Configuração do módulo de infestação
class InfestationMapModule {
  /// Nome do módulo
  static const String name = 'Infestation Map';
  
  /// Versão do módulo
  static const String version = '1.0.0';
  
  /// Descrição do módulo
  static const String description = 'Módulo para visualização e análise de mapas de infestação';
  
  /// Dependências do módulo
  static const List<String> dependencies = [
    'monitoring',
    'talhoes',
    'organism_catalog',
  ];
  
  /// Verifica se o módulo está habilitado
  static bool get isEnabled => true;
  
  /// Inicializa o módulo
  static Future<void> initialize() async {
    // TODO: Implementar inicialização do módulo
    print('Inicializando módulo de infestação...');
  }
  
  /// Desabilita o módulo
  static Future<void> disable() async {
    // TODO: Implementar desabilitação do módulo
    print('Desabilitando módulo de infestação...');
  }
}
