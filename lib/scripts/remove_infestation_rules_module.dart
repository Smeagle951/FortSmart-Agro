import '../utils/logger.dart';

/// Script para remover o módulo de Regras de Infestação
/// O módulo é desnecessário pois duplica funcionalidade do Catálogo de Organismos
void main() async {
  try {
    Logger.info('🗑️ Iniciando remoção do módulo de Regras de Infestação...');
    
    // Lista de arquivos para remover
    final filesToRemove = [
      'lib/screens/configuracao/infestation_rules_screen.dart',
      'lib/repositories/infestation_rules_repository.dart',
      'lib/models/infestation_rule.dart',
      'lib/scripts/fix_infestation_rules_data.dart',
    ];
    
    // Lista de arquivos para atualizar (remover referências)
    final filesToUpdate = [
      'lib/services/intelligent_infestation_service.dart',
      'lib/services/monitoring_session_service.dart',
      'lib/routes.dart',
    ];
    
    Logger.info('📋 Arquivos que serão removidos:');
    for (final file in filesToRemove) {
      Logger.info('   - $file');
    }
    
    Logger.info('📋 Arquivos que serão atualizados:');
    for (final file in filesToUpdate) {
      Logger.info('   - $file');
    }
    
    Logger.info('✅ Script de remoção criado com sucesso!');
    Logger.info('');
    Logger.info('📝 PRÓXIMOS PASSOS:');
    Logger.info('1. Remover os arquivos listados acima');
    Logger.info('2. Atualizar os serviços para usar OrganismCatalogRepository diretamente');
    Logger.info('3. Remover a tabela infestation_rules do banco de dados');
    Logger.info('4. Atualizar as rotas para remover referências');
    Logger.info('5. Testar a compilação');
    
  } catch (e) {
    Logger.error('❌ Erro ao criar script de remoção: $e');
  }
}

/// Exemplo de como atualizar IntelligentInfestationService:
/// 
/// ANTES:
/// ```dart
/// final InfestationRulesRepository _rulesRepository = InfestationRulesRepository();
/// 
/// // Buscar regras personalizadas
/// final customRules = await _rulesRepository.getByOrganismAndField(organismId, fieldId);
/// if (customRules.isNotEmpty) {
///   // Usar regras personalizadas
/// } else {
///   // Usar limiares do catálogo
/// }
/// ```
/// 
/// DEPOIS:
/// ```dart
/// // Usar diretamente os limiares do catálogo
/// final organism = await _catalogRepository.getById(organismId);
/// if (organism != null) {
///   final thresholdLow = organism.lowLimit;
///   final thresholdMedium = organism.mediumLimit;
///   // Usar limiares padrão
/// }
/// ```

/// Exemplo de como atualizar MonitoringSessionService:
/// 
/// ANTES:
/// ```dart
/// final InfestationRulesRepository _infestationRulesRepository = InfestationRulesRepository();
/// ```
/// 
/// DEPOIS:
/// ```dart
/// // Remover a linha acima
/// // Usar diretamente OrganismCatalogRepository que já está importado
/// ```
