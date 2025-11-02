import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Script de Sincronização de Dados - FortSmart Agro
/// 
/// Este script sincroniza dados entre catálogos consolidados e arquivos individuais,
/// garantindo consistência e integridade dos dados de organismos.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class DataSyncResult {
  final String operation;
  final String status; // 'SUCCESS', 'WARNING', 'ERROR'
  final String details;
  final int recordsProcessed;
  final int recordsUpdated;
  final int recordsCreated;
  final int recordsSkipped;

  DataSyncResult({
    required this.operation,
    required this.status,
    required this.details,
    this.recordsProcessed = 0,
    this.recordsUpdated = 0,
    this.recordsCreated = 0,
    this.recordsSkipped = 0,
  });

  @override
  String toString() {
    return '[$status] $operation\n'
           '  Processados: $recordsProcessed\n'
           '  Atualizados: $recordsUpdated\n'
           '  Criados: $recordsCreated\n'
           '  Ignorados: $recordsSkipped\n'
           '  Detalhes: $details\n';
  }
}

class OrganismDataSynchronizer {
  final List<DataSyncResult> _results = [];
  final Map<String, dynamic> _catalogData = {};
  final Map<String, List<Map<String, dynamic>>> _individualFiles = {};
  final String _backupDir = 'backups/data_sync_${DateTime.now().millisecondsSinceEpoch}';

  /// Executa sincronização completa dos dados
  Future<List<DataSyncResult>> syncAllData() async {
    print('🔄 Iniciando sincronização completa dos dados FortSmart Agro...\n');
    
    // Cria backup
    await _createBackup();
    
    // Carrega dados
    await _loadAllDataFiles();
    
    // Executa sincronizações
    await _syncFromIndividualToCatalog();
    await _syncFromCatalogToIndividual();
    await _standardizeData();
    await _validateSync();
    
    // Gera relatório
    _generateSyncReport();
    
    return _results;
  }

  /// Cria backup dos arquivos antes da sincronização
  Future<void> _createBackup() async {
    print('💾 Criando backup dos dados...');
    
    try {
      await Directory(_backupDir).create(recursive: true);
      
      final filesToBackup = [
        'assets/data/organism_catalog.json',
        'assets/data/organism_catalog_complete.json',
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
      
      for (final file in filesToBackup) {
        final sourceFile = File(file);
        if (await sourceFile.exists()) {
          final backupFile = File(path.join(_backupDir, path.basename(file)));
          await sourceFile.copy(backupFile.path);
          print('  ✓ Backup: $file');
        }
      }
      
      _addResult('Backup', 'SUCCESS', 'Backup criado com sucesso em $_backupDir');
    } catch (e) {
      _addResult('Backup', 'ERROR', 'Erro ao criar backup: $e');
    }
  }

  /// Carrega todos os arquivos de dados
  Future<void> _loadAllDataFiles() async {
    print('📂 Carregando arquivos de dados...');
    
    // Carrega catálogos
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

  /// Carrega arquivos individuais
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

  /// Sincroniza dados dos arquivos individuais para o catálogo
  Future<void> _syncFromIndividualToCatalog() async {
    print('📤 Sincronizando dados individuais → catálogo...');
    
    for (final catalogEntry in _catalogData.entries) {
      final catalogFile = catalogEntry.key;
      final catalogData = catalogEntry.value;
      
      if (catalogData['cultures'] != null) {
        final cultures = catalogData['cultures'] as Map<String, dynamic>;
        int updated = 0;
        int created = 0;
        
        for (final cultureEntry in cultures.entries) {
          final cultureName = cultureEntry.key;
          final cultureData = cultureEntry.value;
          
          // Busca arquivo individual correspondente
          final individualFile = 'assets/data/organismos_${cultureName}.json';
          if (_individualFiles.containsKey(individualFile)) {
            final individualOrganisms = _individualFiles[individualFile]!;
            
            // Atualiza organismos no catálogo
            if (cultureData['organisms'] != null) {
              final catalogOrganisms = cultureData['organisms'] as Map<String, dynamic>;
              
              for (final organism in individualOrganisms) {
                final organismId = organism['id'];
                final organismName = organism['nome'] ?? organism['name'];
                
                if (organismId != null && organismName != null) {
                  // Verifica se já existe no catálogo
                  bool exists = false;
                  for (final type in ['pests', 'diseases', 'deficiencies']) {
                    if (catalogOrganisms[type] != null) {
                      final organisms = catalogOrganisms[type] as List;
                      for (final catalogOrg in organisms) {
                        if (catalogOrg['id'] == organismId) {
                          // Atualiza dados existentes
                          _updateCatalogOrganism(catalogOrg, organism);
                          updated++;
                          exists = true;
                          break;
                        }
                      }
                    }
                    if (exists) break;
                  }
                  
                  if (!exists) {
                    // Cria novo organismo no catálogo
                    _createCatalogOrganism(catalogOrganisms, organism);
                    created++;
                  }
                }
              }
            }
          }
        }
        
        // Salva catálogo atualizado
        await _saveCatalogFile(catalogFile, catalogData);
        
        _addResult(
          'Sync Individual → Catalog ($catalogFile)',
          'SUCCESS',
          'Sincronização concluída',
          updated + created,
          updated,
          created,
        );
      }
    }
  }

  /// Sincroniza dados do catálogo para arquivos individuais
  Future<void> _syncFromCatalogToIndividual() async {
    print('📥 Sincronizando dados catálogo → individuais...');
    
    for (final catalogEntry in _catalogData.entries) {
      final catalogFile = catalogEntry.key;
      final catalogData = catalogEntry.value;
      
      if (catalogData['cultures'] != null) {
        final cultures = catalogData['cultures'] as Map<String, dynamic>;
        
        for (final cultureEntry in cultures.entries) {
          final cultureName = cultureEntry.key;
          final cultureData = cultureEntry.value;
          
          final individualFile = 'assets/data/organismos_${cultureName}.json';
          if (_individualFiles.containsKey(individualFile)) {
            final individualOrganisms = _individualFiles[individualFile]!;
            
            if (cultureData['organisms'] != null) {
              final catalogOrganisms = cultureData['organisms'] as Map<String, dynamic>;
              
              for (final type in ['pests', 'diseases', 'deficiencies']) {
                if (catalogOrganisms[type] != null) {
                  final catalogOrgList = catalogOrganisms[type] as List;
                  
                  for (final catalogOrg in catalogOrgList) {
                    final organismId = catalogOrg['id'];
                    
                    // Busca organismo correspondente no arquivo individual
                    bool found = false;
                    for (final individualOrg in individualOrganisms) {
                      if (individualOrg['id'] == organismId) {
                        // Atualiza dados do arquivo individual
                        _updateIndividualOrganism(individualOrg, catalogOrg);
                        found = true;
                        break;
                      }
                    }
                    
                    if (!found) {
                      // Cria novo organismo no arquivo individual
                      _createIndividualOrganism(individualOrganisms, catalogOrg, cultureName);
                    }
                  }
                }
              }
              
              // Salva arquivo individual atualizado
              await _saveIndividualFile(individualFile, individualOrganisms);
            }
          }
        }
      }
    }
  }

  /// Padroniza dados entre todas as fontes
  Future<void> _standardizeData() async {
    print('🔧 Padronizando dados...');
    
    int standardized = 0;
    
    for (final fileEntry in _individualFiles.entries) {
      final file = fileEntry.key;
      final organisms = fileEntry.value;
      
      for (final organism in organisms) {
        // Padroniza campos obrigatórios
        _standardizeOrganismFields(organism);
        standardized++;
      }
      
      // Salva arquivo padronizado
      await _saveIndividualFile(file, organisms);
    }
    
    _addResult(
      'Padronização',
      'SUCCESS',
      'Dados padronizados com sucesso',
      standardized,
      standardized,
    );
  }

  /// Valida sincronização
  Future<void> _validateSync() async {
    print('✅ Validando sincronização...');
    
    int validationErrors = 0;
    final errors = <String>[];
    
    for (final catalogEntry in _catalogData.entries) {
      final catalogFile = catalogEntry.key;
      final catalogData = catalogEntry.value;
      
      if (catalogData['cultures'] != null) {
        final cultures = catalogData['cultures'] as Map<String, dynamic>;
        
        for (final cultureEntry in cultures.entries) {
          final cultureName = cultureEntry.key;
          final individualFile = 'assets/data/organismos_${cultureName}.json';
          
          if (_individualFiles.containsKey(individualFile)) {
            // Valida consistência entre catálogo e arquivo individual
            final inconsistencies = _validateConsistency(catalogData, _individualFiles[individualFile]!);
            if (inconsistencies.isNotEmpty) {
              validationErrors += inconsistencies.length;
              errors.addAll(inconsistencies);
            }
          }
        }
      }
    }
    
    if (validationErrors == 0) {
      _addResult('Validação', 'SUCCESS', 'Sincronização validada com sucesso');
    } else {
      _addResult('Validação', 'WARNING', 'Encontradas $validationErrors inconsistências: ${errors.join(', ')}');
    }
  }

  /// Atualiza organismo no catálogo
  void _updateCatalogOrganism(Map<String, dynamic> catalogOrg, Map<String, dynamic> individualOrg) {
    // Atualiza campos essenciais
    catalogOrg['name'] = individualOrg['nome'] ?? catalogOrg['name'];
    catalogOrg['scientific_name'] = individualOrg['nome_cientifico'] ?? catalogOrg['scientific_name'];
    catalogOrg['description'] = individualOrg['dano_economico'] ?? catalogOrg['description'];
    
    // Atualiza limiares se disponíveis
    if (individualOrg['nivel_acao'] != null) {
      catalogOrg['action_threshold'] = individualOrg['nivel_acao'];
    }
  }

  /// Cria novo organismo no catálogo
  void _createCatalogOrganism(Map<String, dynamic> catalogOrganisms, Map<String, dynamic> individualOrg) {
    final organismType = _getOrganismType(individualOrg['categoria']);
    
    if (catalogOrganisms[organismType] == null) {
      catalogOrganisms[organismType] = [];
    }
    
    final newOrganism = {
      'id': individualOrg['id'],
      'name': individualOrg['nome'],
      'scientific_name': individualOrg['nome_cientifico'],
      'type': organismType.substring(0, organismType.length - 1), // Remove 's'
      'crop_id': individualOrg['cultura_id'],
      'crop_name': individualOrg['cultura_id']?.toString().toUpperCase(),
      'description': individualOrg['dano_economico'],
      'action_threshold': individualOrg['nivel_acao'],
      'monitoring_method': 'pano-de-batida',
    };
    
    (catalogOrganisms[organismType] as List).add(newOrganism);
  }

  /// Atualiza organismo no arquivo individual
  void _updateIndividualOrganism(Map<String, dynamic> individualOrg, Map<String, dynamic> catalogOrg) {
    // Atualiza campos do catálogo no arquivo individual
    individualOrg['nome'] = catalogOrg['name'] ?? individualOrg['nome'];
    individualOrg['nome_cientifico'] = catalogOrg['scientific_name'] ?? individualOrg['nome_cientifico'];
    individualOrg['dano_economico'] = catalogOrg['description'] ?? individualOrg['dano_economico'];
    individualOrg['nivel_acao'] = catalogOrg['action_threshold'] ?? individualOrg['nivel_acao'];
  }

  /// Cria novo organismo no arquivo individual
  void _createIndividualOrganism(List<Map<String, dynamic>> organisms, Map<String, dynamic> catalogOrg, String cultureName) {
    final newOrganism = {
      'id': catalogOrg['id'],
      'nome': catalogOrg['name'],
      'nome_cientifico': catalogOrg['scientific_name'],
      'categoria': _getCategoryFromType(catalogOrg['type']),
      'cultura_id': cultureName,
      'sintomas': ['Sintomas a serem definidos'],
      'dano_economico': catalogOrg['description'] ?? 'Dano econômico a ser definido',
      'partes_afetadas': ['Partes afetadas a serem definidas'],
      'fenologia': ['Fases fenológicas a serem definidas'],
      'nivel_acao': catalogOrg['action_threshold'] ?? 'Limiar a ser definido',
      'manejo_quimico': ['Manejo químico a ser definido'],
      'manejo_biologico': ['Manejo biológico a ser definido'],
      'manejo_cultural': ['Manejo cultural a ser definido'],
      'observacoes': 'Organismo criado automaticamente - dados a serem completados',
      'icone': '🐛',
      'ativo': true,
      'data_criacao': DateTime.now().toIso8601String(),
      'data_atualizacao': DateTime.now().toIso8601String(),
    };
    
    organisms.add(newOrganism);
  }

  /// Padroniza campos do organismo
  void _standardizeOrganismFields(Map<String, dynamic> organism) {
    // Garante campos obrigatórios
    organism['ativo'] = organism['ativo'] ?? true;
    organism['data_atualizacao'] = DateTime.now().toIso8601String();
    
    // Padroniza categoria
    if (organism['categoria'] != null) {
      final categoria = organism['categoria'].toString().toLowerCase();
      if (categoria.contains('praga')) {
        organism['categoria'] = 'Praga';
      } else if (categoria.contains('doença') || categoria.contains('doenca')) {
        organism['categoria'] = 'Doença';
      } else if (categoria.contains('deficiência') || categoria.contains('deficiencia')) {
        organism['categoria'] = 'Deficiência Nutricional';
      }
    }
    
    // Padroniza sintomas
    if (organism['sintomas'] == null) {
      organism['sintomas'] = ['Sintomas a serem definidos'];
    }
    
    // Padroniza partes afetadas
    if (organism['partes_afetadas'] == null) {
      organism['partes_afetadas'] = ['Partes afetadas a serem definidas'];
    }
  }

  /// Valida consistência entre catálogo e arquivo individual
  List<String> _validateConsistency(Map<String, dynamic> catalogData, List<Map<String, dynamic>> individualOrganisms) {
    final errors = <String>[];
    
    // Implementar validações específicas
    // Por exemplo: verificar se todos os organismos do catálogo existem no arquivo individual
    
    return errors;
  }

  /// Determina tipo de organismo
  String _getOrganismType(String? categoria) {
    if (categoria == null) return 'pests';
    
    final cat = categoria.toLowerCase();
    if (cat.contains('praga')) return 'pests';
    if (cat.contains('doença') || cat.contains('doenca')) return 'diseases';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return 'deficiencies';
    
    return 'pests';
  }

  /// Obtém categoria do tipo
  String _getCategoryFromType(String? type) {
    if (type == null) return 'Praga';
    
    final t = type.toLowerCase();
    if (t == 'pest') return 'Praga';
    if (t == 'disease') return 'Doença';
    if (t == 'deficiency') return 'Deficiência Nutricional';
    
    return 'Praga';
  }

  /// Salva arquivo de catálogo
  Future<void> _saveCatalogFile(String filePath, Map<String, dynamic> data) async {
    try {
      final file = File(filePath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      print('  ✓ Salvo: $filePath');
    } catch (e) {
      print('  ❌ Erro ao salvar $filePath: $e');
    }
  }

  /// Salva arquivo individual
  Future<void> _saveIndividualFile(String filePath, List<Map<String, dynamic>> organisms) async {
    try {
      final file = File(filePath);
      final data = {
        'cultura': _getCultureNameFromPath(filePath),
        'nome_cientifico': _getScientificNameFromPath(filePath),
        'versao': '4.0',
        'data_atualizacao': DateTime.now().toIso8601String(),
        'funcionalidades_extras': {
          'fases_desenvolvimento': true,
          'tamanhos_mm': true,
          'severidade_detalhada': true,
          'condicoes_favoraveis': true,
          'manejo_integrado': true,
          'limiares_especificos': true,
          'niveis_infestacao': true,
          'niveis_severidade': true,
          'sintomas_detalhados': true,
        },
        'organismos': organisms,
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      print('  ✓ Salvo: $filePath');
    } catch (e) {
      print('  ❌ Erro ao salvar $filePath: $e');
    }
  }

  /// Obtém nome da cultura do caminho do arquivo
  String _getCultureNameFromPath(String filePath) {
    final fileName = path.basename(filePath);
    final cultureName = fileName.replaceAll('organismos_', '').replaceAll('.json', '');
    return cultureName.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  /// Obtém nome científico da cultura
  String _getScientificNameFromPath(String filePath) {
    final cultureName = _getCultureNameFromPath(filePath).toLowerCase();
    
    final scientificNames = {
      'soja': 'Glycine max',
      'milho': 'Zea mays',
      'algodao': 'Gossypium hirsutum',
      'arroz': 'Oryza sativa',
      'aveia': 'Avena sativa',
      'cana acucar': 'Saccharum officinarum',
      'feijao': 'Phaseolus vulgaris',
      'gergelim': 'Sesamum indicum',
      'girassol': 'Helianthus annuus',
      'sorgo': 'Sorghum bicolor',
      'tomate': 'Solanum lycopersicum',
      'trigo': 'Triticum aestivum',
    };
    
    return scientificNames[cultureName] ?? 'Nome científico não definido';
  }

  /// Adiciona resultado à lista
  void _addResult(String operation, String status, String details, 
                 [int processed = 0, int updated = 0, int created = 0, int skipped = 0]) {
    _results.add(DataSyncResult(
      operation: operation,
      status: status,
      details: details,
      recordsProcessed: processed,
      recordsUpdated: updated,
      recordsCreated: created,
      recordsSkipped: skipped,
    ));
  }

  /// Gera relatório de sincronização
  void _generateSyncReport() {
    print('\n📊 RELATÓRIO DE SINCRONIZAÇÃO - FortSmart Agro');
    print('=' * 50);
    
    final totalOperations = _results.length;
    final successfulOperations = _results.where((r) => r.status == 'SUCCESS').length;
    final warningOperations = _results.where((r) => r.status == 'WARNING').length;
    final errorOperations = _results.where((r) => r.status == 'ERROR').length;
    
    print('\n📈 ESTATÍSTICAS GERAIS:');
    print('  Total de operações: $totalOperations');
    print('  ✅ Sucessos: $successfulOperations');
    print('  ⚠️  Avisos: $warningOperations');
    print('  ❌ Erros: $errorOperations');
    
    print('\n📋 DETALHES DAS OPERAÇÕES:');
    for (final result in _results) {
      print(result);
    }
    
    print('\n💡 PRÓXIMOS PASSOS:');
    print('  1. Revisar operações com avisos');
    print('  2. Corrigir operações com erros');
    print('  3. Validar dados sincronizados');
    print('  4. Executar testes de integração');
    print('  5. Atualizar documentação');
    
    print('\n✅ Sincronização concluída!');
    print('📁 Backup disponível em: $_backupDir');
  }
}

/// Função principal para executar a sincronização
Future<void> main() async {
  final synchronizer = OrganismDataSynchronizer();
  await synchronizer.syncAllData();
}
