import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Script de Auditoria de Dados - FortSmart Agro
/// 
/// Este script identifica inconsistências entre os diferentes arquivos
/// de dados de organismos e culturas para garantir integridade dos dados.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class DataAuditResult {
  final String issue;
  final String severity; // 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'
  final String file;
  final String organism;
  final String details;
  final String recommendation;

  DataAuditResult({
    required this.issue,
    required this.severity,
    required this.file,
    required this.organism,
    required this.details,
    required this.recommendation,
  });

  @override
  String toString() {
    return '[$severity] $issue - $organism ($file)\n'
           '  Detalhes: $details\n'
           '  Recomendação: $recommendation\n';
  }
}

class OrganismDataAuditor {
  final List<DataAuditResult> _issues = [];
  final Map<String, dynamic> _catalogData = {};
  final Map<String, List<Map<String, dynamic>>> _individualFiles = {};

  /// Executa auditoria completa dos dados
  Future<List<DataAuditResult>> auditAllData() async {
    print('🔍 Iniciando auditoria completa dos dados FortSmart Agro...\n');
    
    // Carrega todos os arquivos
    await _loadAllDataFiles();
    
    // Executa verificações
    _checkDataConsistency();
    _checkNamingConventions();
    _checkThresholds();
    _checkScientificNames();
    _checkPhenologicalPhases();
    _checkMissingFields();
    _checkDataCompleteness();
    
    // Gera relatório
    _generateReport();
    
    return _issues;
  }

  /// Carrega todos os arquivos de dados
  Future<void> _loadAllDataFiles() async {
    print('📂 Carregando arquivos de dados...');
    
    // Carrega catálogos consolidados
    await _loadCatalogFiles();
    
    // Carrega arquivos individuais
    await _loadIndividualFiles();
    
    print('✅ Carregamento concluído\n');
  }

  /// Carrega arquivos de catálogo
  Future<void> _loadCatalogFiles() async {
    final catalogFiles = [
      'assets/data/organism_catalog.json',
      'assets/data/organism_catalog_complete.json',
    ];

    for (final file in catalogFiles) {
      try {
        final fileContent = await File(file).readAsString();
        final data = json.decode(fileContent);
        _catalogData[file] = data;
        print('  ✓ Carregado: $file');
      } catch (e) {
        print('  ❌ Erro ao carregar $file: $e');
      }
    }
  }

  /// Carrega arquivos individuais de organismos
  Future<void> _loadIndividualFiles() async {
    final individualFiles = [
      'assets/data/organismos_soja.json',
      'assets/data/organismos_milho.json',
      'assets/data/organismos_algodao.json',
      'assets/data/organismos_arroz.json',
      'assets/data/organismos_aveia.json',
      'assets/data/organismos_cana_acucar.json',
      'assets/data/organismos_feijao.json',
      'assets/data/organismos_gergelim.json',
      'assets/data/organismos_girassol.json',
      'assets/data/organismos_sorgo.json',
      'assets/data/organismos_tomate.json',
      'assets/data/organismos_trigo.json',
    ];

    for (final file in individualFiles) {
      try {
        final fileContent = await File(file).readAsString();
        final data = json.decode(fileContent);
        
        if (data['organismos'] != null) {
          _individualFiles[file] = List<Map<String, dynamic>>.from(data['organismos']);
          print('  ✓ Carregado: $file (${data['organismos'].length} organismos)');
        }
      } catch (e) {
        print('  ❌ Erro ao carregar $file: $e');
      }
    }
  }

  /// Verifica consistência entre catálogos e arquivos individuais
  void _checkDataConsistency() {
    print('🔍 Verificando consistência de dados...');
    
    for (final catalogEntry in _catalogData.entries) {
      final catalogFile = catalogEntry.key;
      final catalogData = catalogEntry.value;
      
      if (catalogData['cultures'] != null) {
        final cultures = catalogData['cultures'] as Map<String, dynamic>;
        
        for (final cultureEntry in cultures.entries) {
          final cultureName = cultureEntry.key;
          final cultureData = cultureEntry.value;
          
          // Verifica se existe arquivo individual correspondente
          final individualFile = 'assets/data/organismos_${cultureName}.json';
          if (!_individualFiles.containsKey(individualFile)) {
            _addIssue(
              'Arquivo individual ausente',
              'HIGH',
              catalogFile,
              cultureName,
              'Catálogo referencia cultura sem arquivo individual',
              'Criar arquivo individual ou remover do catálogo',
            );
          }
        }
      }
    }
  }

  /// Verifica convenções de nomenclatura
  void _checkNamingConventions() {
    print('📝 Verificando convenções de nomenclatura...');
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        final organismName = organism['nome'] ?? organism['name'] ?? 'Desconhecido';
        
        // Verifica se nome está em português
        if (organismName.contains('_') || organismName.contains('-')) {
          _addIssue(
            'Nome com caracteres especiais',
            'MEDIUM',
            file,
            organismName,
            'Nome contém underscore ou hífen',
            'Usar espaços em vez de caracteres especiais',
          );
        }
        
        // Verifica se nome científico está presente
        if (organism['nome_cientifico'] == null && organism['scientific_name'] == null) {
          _addIssue(
            'Nome científico ausente',
            'HIGH',
            file,
            organismName,
            'Organismo sem nome científico',
            'Adicionar nome científico válido',
          );
        }
      }
    }
  }

  /// Verifica limiares de ação
  void _checkThresholds() {
    print('📊 Verificando limiares de ação...');
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        final organismName = organism['nome'] ?? organism['name'] ?? 'Desconhecido';
        
        // Verifica se tem limiar de ação
        if (organism['nivel_acao'] == null && organism['action_threshold'] == null) {
          _addIssue(
            'Limiar de ação ausente',
            'CRITICAL',
            file,
            organismName,
            'Organismo sem limiar de ação definido',
            'Definir limiar de ação baseado em literatura científica',
          );
        }
        
        // Verifica se tem níveis de severidade
        if (organism['severidade'] == null && organism['severity'] == null) {
          _addIssue(
            'Níveis de severidade ausentes',
            'HIGH',
            file,
            organismName,
            'Organismo sem níveis de severidade',
            'Adicionar níveis baixo, médio e alto',
          );
        }
      }
    }
  }

  /// Verifica nomes científicos
  void _checkScientificNames() {
    print('🧬 Verificando nomes científicos...');
    
    final scientificNames = <String, List<String>>{};
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        final scientificName = organism['nome_cientifico'] ?? organism['scientific_name'];
        final organismName = organism['nome'] ?? organism['name'] ?? 'Desconhecido';
        
        if (scientificName != null) {
          if (scientificNames.containsKey(scientificName)) {
            scientificNames[scientificName]!.add('$file:$organismName');
          } else {
            scientificNames[scientificName] = ['$file:$organismName'];
          }
        }
      }
    }
    
    // Verifica duplicatas
    for (final entry in scientificNames.entries) {
      if (entry.value.length > 1) {
        _addIssue(
          'Nome científico duplicado',
          'MEDIUM',
          'Múltiplos arquivos',
          entry.key,
          'Nome científico aparece em: ${entry.value.join(', ')}',
          'Verificar se são o mesmo organismo ou nomes diferentes',
        );
      }
    }
  }

  /// Verifica fases fenológicas
  void _checkPhenologicalPhases() {
    print('🌱 Verificando fases fenológicas...');
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        final organismName = organism['nome'] ?? organism['name'] ?? 'Desconhecido';
        
        // Verifica se tem fases fenológicas
        if (organism['fenologia'] == null && organism['phenology'] == null) {
          _addIssue(
            'Fases fenológicas ausentes',
            'HIGH',
            file,
            organismName,
            'Organismo sem fases fenológicas definidas',
            'Adicionar fases fenológicas relevantes',
          );
        }
        
        // Verifica se tem fases detalhadas
        if (organism['fases_fenologicas_detalhadas'] == null) {
          _addIssue(
            'Fases fenológicas detalhadas ausentes',
            'MEDIUM',
            file,
            organismName,
            'Organismo sem descrição detalhada das fases',
            'Adicionar descrições detalhadas das fases',
          );
        }
      }
    }
  }

  /// Verifica campos obrigatórios ausentes
  void _checkMissingFields() {
    print('📋 Verificando campos obrigatórios...');
    
    final requiredFields = [
      'nome', 'nome_cientifico', 'categoria', 'sintomas', 
      'dano_economico', 'partes_afetadas', 'nivel_acao'
    ];
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        final organismName = organism['nome'] ?? organism['name'] ?? 'Desconhecido';
        
        for (final field in requiredFields) {
          if (organism[field] == null) {
            _addIssue(
              'Campo obrigatório ausente',
              'HIGH',
              file,
              organismName,
              'Campo "$field" não encontrado',
              'Adicionar campo obrigatório',
            );
          }
        }
      }
    }
  }

  /// Verifica completude dos dados
  void _checkDataCompleteness() {
    print('✅ Verificando completude dos dados...');
    
    final completenessFields = [
      'manejo_quimico', 'manejo_biologico', 'manejo_cultural',
      'condicoes_favoraveis', 'limiares_especificos'
    ];
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        final organismName = organism['nome'] ?? organism['name'] ?? 'Desconhecido';
        int missingFields = 0;
        
        for (final field in completenessFields) {
          if (organism[field] == null) {
            missingFields++;
          }
        }
        
        if (missingFields > 2) {
          _addIssue(
            'Dados incompletos',
            'MEDIUM',
            file,
            organismName,
            'Faltam $missingFields campos de completude',
            'Preencher campos de manejo e condições',
          );
        }
      }
    }
  }

  /// Adiciona issue à lista
  void _addIssue(String issue, String severity, String file, String organism, 
                String details, String recommendation) {
    _issues.add(DataAuditResult(
      issue: issue,
      severity: severity,
      file: file,
      organism: organism,
      details: details,
      recommendation: recommendation,
    ));
  }

  /// Gera relatório final
  void _generateReport() {
    print('\n📊 RELATÓRIO DE AUDITORIA - FortSmart Agro');
    print('=' * 50);
    
    // Estatísticas gerais
    final totalIssues = _issues.length;
    final criticalIssues = _issues.where((i) => i.severity == 'CRITICAL').length;
    final highIssues = _issues.where((i) => i.severity == 'HIGH').length;
    final mediumIssues = _issues.where((i) => i.severity == 'MEDIUM').length;
    final lowIssues = _issues.where((i) => i.severity == 'LOW').length;
    
    print('\n📈 ESTATÍSTICAS GERAIS:');
    print('  Total de issues encontradas: $totalIssues');
    print('  🚨 Críticas: $criticalIssues');
    print('  ⚠️  Altas: $highIssues');
    print('  📝 Médias: $mediumIssues');
    print('  ℹ️  Baixas: $lowIssues');
    
    // Issues por severidade
    print('\n🚨 ISSUES CRÍTICAS:');
    _issues.where((i) => i.severity == 'CRITICAL').forEach(print);
    
    print('\n⚠️ ISSUES ALTAS:');
    _issues.where((i) => i.severity == 'HIGH').forEach(print);
    
    // Resumo por arquivo
    print('\n📁 ISSUES POR ARQUIVO:');
    final issuesByFile = <String, int>{};
    for (final issue in _issues) {
      issuesByFile[issue.file] = (issuesByFile[issue.file] ?? 0) + 1;
    }
    
    issuesByFile.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) => print('  ${entry.key}: ${entry.value} issues'));
    
    print('\n💡 RECOMENDAÇÕES PRIORITÁRIAS:');
    print('  1. Resolver issues críticas primeiro');
    print('  2. Padronizar nomenclaturas');
    print('  3. Implementar sistema de sincronização');
    print('  4. Criar validação automática');
    print('  5. Documentar padrões de dados');
    
    print('\n✅ Auditoria concluída!');
  }
}

/// Função principal para executar a auditoria
Future<void> main() async {
  final auditor = OrganismDataAuditor();
  await auditor.auditAllData();
}
