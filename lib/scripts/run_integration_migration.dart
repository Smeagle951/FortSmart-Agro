import 'dart:io';
import '../services/organism_data_integration_service.dart';
import '../services/organism_data_service.dart';
import '../database/migrations/integrate_organism_data_service_migration.dart';
import '../database/app_database.dart';
import 'data_audit_script.dart';
import 'data_sync_script.dart';

/// Script de Migração e Integração Completa - FortSmart Agro
/// 
/// Este script executa a migração completa do sistema legado para o novo sistema
/// de dados de organismos, incluindo:
/// - Migração do banco de dados
/// - Sincronização de dados
/// - Validação de integridade
/// - Testes de compatibilidade
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

void main(List<String> arguments) async {
  print('🚀 FortSmart Agro - Migração e Integração Completa');
  print('=' * 60);
  print('Versão: 4.0 | Data: 2024-12-19');
  print('Autor: Especialista Agronômico + Desenvolvedor Sênior\n');

  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  final command = arguments[0].toLowerCase();

  switch (command) {
    case 'migrate':
      await _runMigration();
      break;
    case 'integrate':
      await _runIntegration();
      break;
    case 'validate':
      await _runValidation();
      break;
    case 'diagnose':
      await _runDiagnostics();
      break;
    case 'full':
      await _runFullMigration();
      break;
    case 'rollback':
      await _runRollback();
      break;
    case 'help':
      _showHelp();
      break;
    default:
      print('❌ Comando não reconhecido: $command');
      _showHelp();
  }
}

/// Executa migração do banco de dados
Future<void> _runMigration() async {
  print('🗄️ Executando migração do banco de dados...\n');
  
  try {
    // Conectar ao banco de dados
    final database = await AppDatabase().database;
    
    // Executar migração
    await IntegrateOrganismDataServiceMigration.execute(database);
    
    print('✅ Migração do banco de dados concluída com sucesso!');
  } catch (e) {
    print('❌ Erro na migração do banco de dados: $e');
    exit(1);
  }
}

/// Executa integração dos serviços
Future<void> _runIntegration() async {
  print('🔗 Executando integração dos serviços...\n');
  
  try {
    final integrationService = OrganismDataIntegrationService();
    
    // Inicializar serviço de integração
    await integrationService.initialize();
    
    // Migrar dados do sistema legado
    await integrationService.migrateFromLegacySystem();
    
    // Sincronizar entre sistemas
    await integrationService.syncBetweenSystems();
    
    print('✅ Integração dos serviços concluída com sucesso!');
  } catch (e) {
    print('❌ Erro na integração dos serviços: $e');
    exit(1);
  }
}

/// Executa validação completa
Future<void> _runValidation() async {
  print('✅ Executando validação completa...\n');
  
  try {
    final integrationService = OrganismDataIntegrationService();
    await integrationService.initialize();
    
    // Validar dados
    final validationIssues = await integrationService.validateData();
    
    if (validationIssues.isEmpty) {
      print('✅ Validação concluída sem problemas!');
    } else {
      print('⚠️ Encontrados ${validationIssues.length} problemas:');
      for (final issue in validationIssues) {
        print('  - $issue');
      }
    }
    
    // Estatísticas
    final stats = await integrationService.getDataStatistics();
    print('\n📊 Estatísticas dos Dados:');
    print('  Total de organismos: ${stats['total_organisms']}');
    print('  Organismos ativos: ${stats['active_organisms']}');
    print('  Total de culturas: ${stats['total_cultures']}');
    
  } catch (e) {
    print('❌ Erro na validação: $e');
    exit(1);
  }
}

/// Executa diagnóstico completo
Future<void> _runDiagnostics() async {
  print('🔍 Executando diagnóstico completo...\n');
  
  try {
    final integrationService = OrganismDataIntegrationService();
    await integrationService.initialize();
    
    final diagnostics = await integrationService.runDiagnostics();
    
    print('📊 DIAGNÓSTICO COMPLETO - FortSmart Agro');
    print('=' * 50);
    
    print('\n🔧 Informações de Compatibilidade:');
    final compatibilityInfo = diagnostics['compatibility_info'] as Map<String, dynamic>;
    compatibilityInfo.forEach((key, value) {
      print('  $key: $value');
    });
    
    print('\n📈 Estatísticas do Novo Sistema:');
    final newSystemStats = diagnostics['new_system_stats'] as Map<String, dynamic>?;
    if (newSystemStats != null) {
      newSystemStats.forEach((key, value) {
        print('  $key: $value');
      });
    } else {
      print('  Sistema não inicializado');
    }
    
    print('\n📊 Estatísticas do Sistema Legado:');
    final legacySystemStats = diagnostics['legacy_system_stats'] as Map<String, dynamic>?;
    if (legacySystemStats != null) {
      legacySystemStats.forEach((key, value) {
        print('  $key: $value');
      });
    } else {
      print('  Sistema legado não disponível');
    }
    
    print('\n✅ Resultados da Validação:');
    final validationResults = diagnostics['validation_results'] as List<String>?;
    if (validationResults != null && validationResults.isNotEmpty) {
      print('  Encontrados ${validationResults.length} problemas:');
      for (final issue in validationResults) {
        print('    - $issue');
      }
    } else {
      print('  Nenhum problema encontrado');
    }
    
    print('\n💡 Recomendações:');
    final recommendations = diagnostics['recommendations'] as List<String>?;
    if (recommendations != null && recommendations.isNotEmpty) {
      for (final recommendation in recommendations) {
        print('  - $recommendation');
      }
    } else {
      print('  Nenhuma recomendação específica');
    }
    
  } catch (e) {
    print('❌ Erro no diagnóstico: $e');
    exit(1);
  }
}

/// Executa migração completa
Future<void> _runFullMigration() async {
  print('🚀 Executando migração completa...\n');
  
  try {
    // 1. Auditoria inicial
    print('1️⃣ Executando auditoria inicial...');
    await _runAudit();
    
    print('\n' + '=' * 60 + '\n');
    
    // 2. Migração do banco de dados
    print('2️⃣ Executando migração do banco de dados...');
    await _runMigration();
    
    print('\n' + '=' * 60 + '\n');
    
    // 3. Integração dos serviços
    print('3️⃣ Executando integração dos serviços...');
    await _runIntegration();
    
    print('\n' + '=' * 60 + '\n');
    
    // 4. Sincronização de dados
    print('4️⃣ Executando sincronização de dados...');
    await _runSync();
    
    print('\n' + '=' * 60 + '\n');
    
    // 5. Validação final
    print('5️⃣ Executando validação final...');
    await _runValidation();
    
    print('\n' + '=' * 60 + '\n');
    
    // 6. Diagnóstico final
    print('6️⃣ Executando diagnóstico final...');
    await _runDiagnostics();
    
    print('\n✅ Migração completa finalizada com sucesso!');
    print('🎉 Sistema FortSmart Agro atualizado para a versão 4.0');
    
  } catch (e) {
    print('❌ Erro na migração completa: $e');
    print('🔄 Execute "rollback" para reverter as alterações');
    exit(1);
  }
}

/// Executa rollback (reversão)
Future<void> _runRollback() async {
  print('🔄 Executando rollback...\n');
  
  try {
    // Implementar lógica de rollback
    // Por enquanto, apenas log
    print('⚠️ Rollback não implementado ainda');
    print('💡 Para reverter, restaure o backup dos arquivos');
    
  } catch (e) {
    print('❌ Erro no rollback: $e');
    exit(1);
  }
}

/// Executa auditoria
Future<void> _runAudit() async {
  final auditor = OrganismDataAuditor();
  await auditor.auditAllData();
}

/// Executa sincronização
Future<void> _runSync() async {
  final synchronizer = OrganismDataSynchronizer();
  await synchronizer.syncAllData();
}

/// Mostra ajuda
void _showHelp() {
  print('📖 AJUDA - FortSmart Agro Migration & Integration');
  print('=' * 50);
  print('');
  print('Comandos disponíveis:');
  print('');
  print('  migrate   - Executa migração do banco de dados');
  print('  integrate - Executa integração dos serviços');
  print('  validate  - Executa validação completa');
  print('  diagnose  - Executa diagnóstico completo');
  print('  full      - Executa migração completa (migrate + integrate + validate + diagnose)');
  print('  rollback  - Executa rollback (reversão)');
  print('  help      - Exibe esta ajuda');
  print('');
  print('Exemplos de uso:');
  print('  dart run lib/scripts/run_integration_migration.dart migrate');
  print('  dart run lib/scripts/run_integration_migration.dart full');
  print('  dart run lib/scripts/run_integration_migration.dart diagnose');
  print('');
  print('⚠️ IMPORTANTE:');
  print('  - Execute "full" para migração completa');
  print('  - Faça backup antes de executar');
  print('  - Execute "diagnose" para verificar status');
  print('');
  print('Para mais informações, consulte:');
  print('  docs/data_sources_documentation.md');
  print('');
}
