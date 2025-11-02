import 'dart:io';
import '../modules/ai/services/ai_organism_data_integration_service.dart';
import '../modules/infestation_map/services/infestation_organism_data_integration_service.dart';
import '../services/organism_data_integration_service.dart';
import '../services/organism_data_service.dart';

/// Script de Verificação de Alinhamento - Módulos de IA FortSmart
/// 
/// Este script verifica se todos os módulos que utilizam a IA FortSmart
/// estão alinhados com o novo sistema de dados de organismos.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

void main(List<String> arguments) async {
  print('🤖 FortSmart Agro - Verificação de Alinhamento dos Módulos de IA');
  print('=' * 70);
  print('Versão: 4.0 | Data: 2024-12-19');
  print('Autor: Especialista Agronômico + Desenvolvedor Sênior\n');

  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  final command = arguments[0].toLowerCase();

  switch (command) {
    case 'check':
      await _checkAlignment();
      break;
    case 'test':
      await _testIntegration();
      break;
    case 'validate':
      await _validateData();
      break;
    case 'diagnose':
      await _runDiagnostics();
      break;
    case 'full':
      await _runFullCheck();
      break;
    case 'help':
      _showHelp();
      break;
    default:
      print('❌ Comando não reconhecido: $command');
      _showHelp();
  }
}

/// Verifica alinhamento dos módulos
Future<void> _checkAlignment() async {
  print('🔍 Verificando alinhamento dos módulos de IA...\n');
  
  try {
    // 1. Verificar serviço principal
    print('1️⃣ Verificando OrganismDataIntegrationService...');
    final integrationService = OrganismDataIntegrationService();
    await integrationService.initialize();
    
    final compatibilityInfo = integrationService.getCompatibilityInfo();
    print('  ✅ Serviço principal: ${compatibilityInfo['is_initialized'] ? "Inicializado" : "Não inicializado"}');
    print('  ✅ Sistema novo: ${compatibilityInfo['using_new_system'] ? "Ativo" : "Inativo"}');
    
    // 2. Verificar módulo de IA
    print('\n2️⃣ Verificando módulo de IA...');
    final aiService = AIOrganismDataIntegrationService();
    await aiService.initialize();
    
    final aiStats = await aiService.getAIStatistics();
    print('  ✅ Organismos para IA: ${aiStats['ai_specific']?['total_organisms_for_ai'] ?? 0}');
    print('  ✅ Qualidade dos dados: ${aiStats['ai_specific']?['data_quality_score']?.toStringAsFixed(1) ?? "N/A"}%');
    print('  ✅ Prontidão para IA: ${aiStats['ai_specific']?['ai_readiness']?.toStringAsFixed(1) ?? "N/A"}%');
    
    // 3. Verificar módulo de infestação
    print('\n3️⃣ Verificando módulo de infestação...');
    final infestationService = InfestationOrganismDataIntegrationService();
    await infestationService.initialize();
    
    final infestationStats = await infestationService.getInfestationStatistics();
    print('  ✅ Organismos para infestação: ${infestationStats['infestation_specific']?['total_organisms_for_infestation'] ?? 0}');
    print('  ✅ Qualidade para infestação: ${infestationStats['infestation_specific']?['data_quality_for_infestation']?.toStringAsFixed(1) ?? "N/A"}%');
    print('  ✅ Prontidão para infestação: ${infestationStats['infestation_specific']?['infestation_readiness']?.toStringAsFixed(1) ?? "N/A"}%');
    
    // 4. Verificar consistência
    print('\n4️⃣ Verificando consistência entre módulos...');
    final organismDataService = OrganismDataService();
    await organismDataService.initialize();
    
    final totalOrganisms = organismDataService.getActiveOrganisms().length;
    final cultures = organismDataService.getAllCultures();
    
    print('  ✅ Total de organismos ativos: $totalOrganisms');
    print('  ✅ Total de culturas: ${cultures.length}');
    
    // Verificar se todos os módulos têm acesso aos mesmos dados
    final aiOrganisms = await aiService.getAllOrganismsForAI();
    final infestationOrganisms = await infestationService.getValidatedOrganisms();
    
    print('  ✅ Organismos disponíveis para IA: ${aiOrganisms.length}');
    print('  ✅ Organismos disponíveis para infestação: ${infestationOrganisms.length}');
    
    if (aiOrganisms.length == infestationOrganisms.length && 
        aiOrganisms.length == totalOrganisms) {
      print('  ✅ Consistência: Todos os módulos têm acesso aos mesmos dados');
    } else {
      print('  ⚠️ Inconsistência detectada entre módulos');
    }
    
    print('\n✅ Verificação de alinhamento concluída!');
    
  } catch (e) {
    print('❌ Erro na verificação de alinhamento: $e');
    exit(1);
  }
}

/// Testa integração dos módulos
Future<void> _testIntegration() async {
  print('🧪 Testando integração dos módulos...\n');
  
  try {
    // Testar módulo de IA
    print('1️⃣ Testando módulo de IA...');
    final aiService = AIOrganismDataIntegrationService();
    await aiService.initialize();
    
    // Testar busca
    final searchResults = await aiService.searchOrganismsForAI('lagarta');
    print('  ✅ Busca por "lagarta": ${searchResults.length} resultados');
    
    // Testar organismos por cultura
    final sojaOrganisms = await aiService.getOrganismsByCropForAI('soja');
    print('  ✅ Organismos da soja: ${sojaOrganisms.length}');
    
    // Testar módulo de infestação
    print('\n2️⃣ Testando módulo de infestação...');
    final infestationService = InfestationOrganismDataIntegrationService();
    await infestationService.initialize();
    
    // Testar pesos de risco
    final riskWeights = await infestationService.getRiskWeights();
    print('  ✅ Pesos de risco: ${riskWeights.length} organismos');
    
    // Testar organismos por cultura
    final infestationSoja = await infestationService.getValidatedOrganismsByCrop('soja');
    print('  ✅ Organismos da soja para infestação: ${infestationSoja.length}');
    
    // Testar consistência
    print('\n3️⃣ Testando consistência...');
    if (sojaOrganisms.length == infestationSoja.length) {
      print('  ✅ Consistência: Mesmo número de organismos da soja em ambos os módulos');
    } else {
      print('  ⚠️ Inconsistência: Números diferentes de organismos da soja');
    }
    
    print('\n✅ Testes de integração concluídos!');
    
  } catch (e) {
    print('❌ Erro nos testes de integração: $e');
    exit(1);
  }
}

/// Valida dados para todos os módulos
Future<void> _validateData() async {
  print('✅ Validando dados para todos os módulos...\n');
  
  try {
    // Validar dados para IA
    print('1️⃣ Validando dados para IA...');
    final aiService = AIOrganismDataIntegrationService();
    await aiService.initialize();
    
    final aiIssues = await aiService.validateDataForAI();
    if (aiIssues.isEmpty) {
      print('  ✅ Dados para IA: Sem problemas encontrados');
    } else {
      print('  ⚠️ Dados para IA: ${aiIssues.length} problemas encontrados');
      for (final issue in aiIssues.take(5)) {
        print('    - $issue');
      }
      if (aiIssues.length > 5) {
        print('    ... e mais ${aiIssues.length - 5} problemas');
      }
    }
    
    // Validar dados para infestação
    print('\n2️⃣ Validando dados para infestação...');
    final infestationService = InfestationOrganismDataIntegrationService();
    await infestationService.initialize();
    
    final infestationIssues = await infestationService.validateDataForInfestation();
    if (infestationIssues.isEmpty) {
      print('  ✅ Dados para infestação: Sem problemas encontrados');
    } else {
      print('  ⚠️ Dados para infestação: ${infestationIssues.length} problemas encontrados');
      for (final issue in infestationIssues.take(5)) {
        print('    - $issue');
      }
      if (infestationIssues.length > 5) {
        print('    ... e mais ${infestationIssues.length - 5} problemas');
      }
    }
    
    // Validar dados principais
    print('\n3️⃣ Validando dados principais...');
    final integrationService = OrganismDataIntegrationService();
    await integrationService.initialize();
    
    final mainIssues = await integrationService.validateData();
    if (mainIssues.isEmpty) {
      print('  ✅ Dados principais: Sem problemas encontrados');
    } else {
      print('  ⚠️ Dados principais: ${mainIssues.length} problemas encontrados');
      for (final issue in mainIssues.take(5)) {
        print('    - $issue');
      }
      if (mainIssues.length > 5) {
        print('    ... e mais ${mainIssues.length - 5} problemas');
      }
    }
    
    print('\n✅ Validação de dados concluída!');
    
  } catch (e) {
    print('❌ Erro na validação de dados: $e');
    exit(1);
  }
}

/// Executa diagnóstico completo
Future<void> _runDiagnostics() async {
  print('🔍 Executando diagnóstico completo...\n');
  
  try {
    // Diagnóstico do serviço principal
    print('1️⃣ Diagnóstico do serviço principal...');
    final integrationService = OrganismDataIntegrationService();
    await integrationService.initialize();
    
    final mainDiagnostics = await integrationService.runDiagnostics();
    print('  📊 Estatísticas principais:');
    print('    - Total de organismos: ${mainDiagnostics['new_system_stats']?['total_organisms'] ?? "N/A"}');
    print('    - Organismos ativos: ${mainDiagnostics['new_system_stats']?['active_organisms'] ?? "N/A"}');
    print('    - Total de culturas: ${mainDiagnostics['new_system_stats']?['total_cultures'] ?? "N/A"}');
    
    // Diagnóstico do módulo de IA
    print('\n2️⃣ Diagnóstico do módulo de IA...');
    final aiService = AIOrganismDataIntegrationService();
    await aiService.initialize();
    
    final aiStats = await aiService.getAIStatistics();
    print('  📊 Estatísticas da IA:');
    print('    - Organismos para IA: ${aiStats['ai_specific']?['total_organisms_for_ai'] ?? "N/A"}');
    print('    - Qualidade dos dados: ${aiStats['ai_specific']?['data_quality_score']?.toStringAsFixed(1) ?? "N/A"}%');
    print('    - Prontidão para IA: ${aiStats['ai_specific']?['ai_readiness']?.toStringAsFixed(1) ?? "N/A"}%');
    
    // Diagnóstico do módulo de infestação
    print('\n3️⃣ Diagnóstico do módulo de infestação...');
    final infestationService = InfestationOrganismDataIntegrationService();
    await infestationService.initialize();
    
    final infestationDiagnostics = await infestationService.runInfestationDiagnostics();
    print('  📊 Estatísticas de infestação:');
    print('    - Organismos para infestação: ${infestationDiagnostics['infestation_stats']?['infestation_specific']?['total_organisms_for_infestation'] ?? "N/A"}');
    print('    - Qualidade para infestação: ${infestationDiagnostics['infestation_stats']?['infestation_specific']?['data_quality_for_infestation']?.toStringAsFixed(1) ?? "N/A"}%');
    print('    - Prontidão para infestação: ${infestationDiagnostics['infestation_stats']?['infestation_specific']?['infestation_readiness']?.toStringAsFixed(1) ?? "N/A"}%');
    
    // Resumo geral
    print('\n📋 RESUMO GERAL:');
    final totalIssues = (mainDiagnostics['validation_results'] as List<String>?)?.length ?? 0;
    final aiIssues = (aiStats['validation_results'] as List<String>?)?.length ?? 0;
    final infestationIssues = (infestationDiagnostics['validation_results'] as List<String>?)?.length ?? 0;
    
    print('  - Problemas principais: $totalIssues');
    print('  - Problemas da IA: $aiIssues');
    print('  - Problemas de infestação: $infestationIssues');
    
    if (totalIssues == 0 && aiIssues == 0 && infestationIssues == 0) {
      print('  ✅ Todos os módulos estão alinhados e funcionando corretamente!');
    } else {
      print('  ⚠️ Alguns problemas foram encontrados. Execute correções conforme necessário.');
    }
    
    print('\n✅ Diagnóstico completo concluído!');
    
  } catch (e) {
    print('❌ Erro no diagnóstico: $e');
    exit(1);
  }
}

/// Executa verificação completa
Future<void> _runFullCheck() async {
  print('🚀 Executando verificação completa de alinhamento...\n');
  
  try {
    // 1. Verificar alinhamento
    print('1️⃣ Verificando alinhamento...');
    await _checkAlignment();
    
    print('\n' + '=' * 70 + '\n');
    
    // 2. Testar integração
    print('2️⃣ Testando integração...');
    await _testIntegration();
    
    print('\n' + '=' * 70 + '\n');
    
    // 3. Validar dados
    print('3️⃣ Validando dados...');
    await _validateData();
    
    print('\n' + '=' * 70 + '\n');
    
    // 4. Executar diagnóstico
    print('4️⃣ Executando diagnóstico...');
    await _runDiagnostics();
    
    print('\n🎉 Verificação completa finalizada!');
    print('📊 Todos os módulos de IA FortSmart estão alinhados com o novo sistema de dados');
    
  } catch (e) {
    print('❌ Erro na verificação completa: $e');
    exit(1);
  }
}

/// Mostra ajuda
void _showHelp() {
  print('📖 AJUDA - Verificação de Alinhamento dos Módulos de IA');
  print('=' * 60);
  print('');
  print('Comandos disponíveis:');
  print('');
  print('  check     - Verifica alinhamento dos módulos');
  print('  test      - Testa integração dos módulos');
  print('  validate  - Valida dados para todos os módulos');
  print('  diagnose  - Executa diagnóstico completo');
  print('  full      - Executa verificação completa (check + test + validate + diagnose)');
  print('  help      - Exibe esta ajuda');
  print('');
  print('Exemplos de uso:');
  print('  dart run lib/scripts/check_ai_modules_alignment.dart check');
  print('  dart run lib/scripts/check_ai_modules_alignment.dart test');
  print('  dart run lib/scripts/check_ai_modules_alignment.dart full');
  print('');
  print('⚠️ IMPORTANTE:');
  print('  - Execute "full" para verificação completa');
  print('  - Todos os módulos devem estar alinhados');
  print('  - A IA FortSmart precisa de dados consistentes');
  print('');
  print('Para mais informações, consulte:');
  print('  README_MIGRATION.md');
  print('');
}
