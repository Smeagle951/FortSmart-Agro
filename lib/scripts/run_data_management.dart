import 'dart:io';
import '../services/organism_data_service.dart';
import 'data_audit_script.dart';
import 'data_sync_script.dart';

/// Script Principal de Gerenciamento de Dados - FortSmart Agro
/// 
/// Este script executa todas as operações de gerenciamento de dados:
/// - Auditoria de dados
/// - Sincronização entre fontes
/// - Validação de integridade
/// - Relatórios de qualidade
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

void main(List<String> arguments) async {
  print('🚀 FortSmart Agro - Sistema de Gerenciamento de Dados');
  print('=' * 60);
  print('Versão: 4.0 | Data: 2024-12-19');
  print('Autor: Especialista Agronômico + Desenvolvedor Sênior\n');

  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  final command = arguments[0].toLowerCase();

  switch (command) {
    case 'audit':
      await _runAudit();
      break;
    case 'sync':
      await _runSync();
      break;
    case 'validate':
      await _runValidation();
      break;
    case 'stats':
      await _runStatistics();
      break;
    case 'full':
      await _runFullProcess();
      break;
    case 'help':
      _showHelp();
      break;
    default:
      print('❌ Comando não reconhecido: $command');
      _showHelp();
  }
}

/// Executa auditoria completa dos dados
Future<void> _runAudit() async {
  print('🔍 Executando auditoria de dados...\n');
  
  final auditor = OrganismDataAuditor();
  final issues = await auditor.auditAllData();
  
  print('\n📊 Resumo da Auditoria:');
  print('  Total de issues: ${issues.length}');
  print('  Issues críticas: ${issues.where((i) => i.severity == 'CRITICAL').length}');
  print('  Issues altas: ${issues.where((i) => i.severity == 'HIGH').length}');
  print('  Issues médias: ${issues.where((i) => i.severity == 'MEDIUM').length}');
  print('  Issues baixas: ${issues.where((i) => i.severity == 'LOW').length}');
}

/// Executa sincronização dos dados
Future<void> _runSync() async {
  print('🔄 Executando sincronização de dados...\n');
  
  final synchronizer = OrganismDataSynchronizer();
  final results = await synchronizer.syncAllData();
  
  print('\n📊 Resumo da Sincronização:');
  print('  Total de operações: ${results.length}');
  print('  Sucessos: ${results.where((r) => r.status == 'SUCCESS').length}');
  print('  Avisos: ${results.where((r) => r.status == 'WARNING').length}');
  print('  Erros: ${results.where((r) => r.status == 'ERROR').length}');
}

/// Executa validação do serviço de dados
Future<void> _runValidation() async {
  print('✅ Executando validação do serviço de dados...\n');
  
  try {
    final service = OrganismDataService();
    await service.initialize();
    
    final issues = service.validateData();
    
    if (issues.isEmpty) {
      print('✅ Validação concluída sem problemas!');
    } else {
      print('⚠️ Encontrados ${issues.length} problemas:');
      for (final issue in issues) {
        print('  - $issue');
      }
    }
    
    final stats = service.getDataStatistics();
    print('\n📊 Estatísticas dos Dados:');
    print('  Total de organismos: ${stats['total_organisms']}');
    print('  Organismos ativos: ${stats['active_organisms']}');
    print('  Total de culturas: ${stats['total_cultures']}');
    
    print('\n📋 Organismos por Categoria:');
    final byCategory = stats['organisms_by_category'] as Map<String, int>;
    byCategory.forEach((category, count) {
      print('  $category: $count');
    });
    
    print('\n🌱 Organismos por Cultura:');
    final byCulture = stats['organisms_by_culture'] as Map<String, int>;
    byCulture.forEach((culture, count) {
      print('  $culture: $count');
    });
    
  } catch (e) {
    print('❌ Erro na validação: $e');
  }
}

/// Executa estatísticas detalhadas
Future<void> _runStatistics() async {
  print('📊 Executando análise estatística...\n');
  
  try {
    final service = OrganismDataService();
    await service.initialize();
    
    final stats = service.getDataStatistics();
    
    print('📈 ESTATÍSTICAS DETALHADAS - FortSmart Agro');
    print('=' * 50);
    
    print('\n🌱 CULTURAS DISPONÍVEIS:');
    final cultures = service.getAllCultures();
    for (final culture in cultures) {
      print('  ${culture.name} (${culture.scientificName})');
      print('    Organismos: ${culture.organisms.length}');
      print('    Versão: ${culture.version}');
      print('    Última atualização: ${culture.lastUpdated}');
      print('');
    }
    
    print('\n🐛 ANÁLISE DE ORGANISMOS:');
    final allOrganisms = service.getActiveOrganisms();
    
    // Análise por categoria
    final pests = service.getOrganismsByCategory('praga');
    final diseases = service.getOrganismsByCategory('doença');
    final deficiencies = service.getOrganismsByCategory('deficiência');
    
    print('  Pragas: ${pests.length}');
    print('  Doenças: ${diseases.length}');
    print('  Deficiências: ${deficiencies.length}');
    
    // Análise de completude
    int completeOrganisms = 0;
    int partialOrganisms = 0;
    
    for (final organism in allOrganisms) {
      bool hasDetailedPhenology = organism.detailedPhenology != null;
      bool hasSeverityLevels = organism.severityLevels != null;
      bool hasInfestationLevels = organism.infestationLevels != null;
      bool hasResistanceCodes = organism.resistanceCodes != null;
      bool hasLifeStages = organism.lifeStages != null;
      
      int completenessScore = 0;
      if (hasDetailedPhenology) completenessScore++;
      if (hasSeverityLevels) completenessScore++;
      if (hasInfestationLevels) completenessScore++;
      if (hasResistanceCodes) completenessScore++;
      if (hasLifeStages) completenessScore++;
      
      if (completenessScore >= 4) {
        completeOrganisms++;
      } else {
        partialOrganisms++;
      }
    }
    
    print('\n📋 COMPLETUDE DOS DADOS:');
    print('  Organismos completos: $completeOrganisms');
    print('  Organismos parciais: $partialOrganisms');
    print('  Taxa de completude: ${(completeOrganisms / allOrganisms.length * 100).toStringAsFixed(1)}%');
    
    // Top 5 culturas com mais organismos
    print('\n🏆 TOP 5 CULTURAS COM MAIS ORGANISMOS:');
    final cultureStats = <String, int>{};
    for (final culture in cultures) {
      cultureStats[culture.name] = culture.organisms.length;
    }
    
    final sortedCultures = cultureStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < 5 && i < sortedCultures.length; i++) {
      final entry = sortedCultures[i];
      print('  ${i + 1}. ${entry.key}: ${entry.value} organismos');
    }
    
  } catch (e) {
    print('❌ Erro na análise estatística: $e');
  }
}

/// Executa processo completo
Future<void> _runFullProcess() async {
  print('🚀 Executando processo completo de gerenciamento de dados...\n');
  
  // 1. Auditoria
  print('1️⃣ Executando auditoria...');
  await _runAudit();
  
  print('\n' + '=' * 60 + '\n');
  
  // 2. Sincronização
  print('2️⃣ Executando sincronização...');
  await _runSync();
  
  print('\n' + '=' * 60 + '\n');
  
  // 3. Validação
  print('3️⃣ Executando validação...');
  await _runValidation();
  
  print('\n' + '=' * 60 + '\n');
  
  // 4. Estatísticas
  print('4️⃣ Executando análise estatística...');
  await _runStatistics();
  
  print('\n✅ Processo completo finalizado!');
  print('📁 Verifique os logs acima para detalhes de cada operação.');
}

/// Mostra ajuda
void _showHelp() {
  print('📖 AJUDA - FortSmart Agro Data Management');
  print('=' * 50);
  print('');
  print('Comandos disponíveis:');
  print('');
  print('  audit     - Executa auditoria completa dos dados');
  print('  sync      - Executa sincronização entre fontes');
  print('  validate  - Valida integridade do serviço de dados');
  print('  stats     - Exibe estatísticas detalhadas');
  print('  full      - Executa processo completo (audit + sync + validate + stats)');
  print('  help      - Exibe esta ajuda');
  print('');
  print('Exemplos de uso:');
  print('  dart run lib/scripts/run_data_management.dart audit');
  print('  dart run lib/scripts/run_data_management.dart sync');
  print('  dart run lib/scripts/run_data_management.dart full');
  print('');
  print('Para mais informações, consulte:');
  print('  docs/data_sources_documentation.md');
  print('');
}
