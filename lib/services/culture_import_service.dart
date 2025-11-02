import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import 'weed_data_service.dart';

/// Serviço para importar dados de culturas dos arquivos JSON
class CultureImportService {
  static const String _basePath = 'assets/data';
  static final Map<String, Map<String, dynamic>> _cultureCache = {};
  static final Map<String, List<Map<String, dynamic>>> _organismCache = {};
  bool _isInitialized = false;

  /// Lista de culturas disponíveis
  static const List<String> _availableCultures = [
    'soja',
    'milho',
    'trigo',
    'feijao',
    'algodao',
    'sorgo',
    'girassol',
    'aveia',
    'gergelim',
    'arroz',
    'tomate',
    'cana_acucar'
  ];

  /// Inicializa o serviço carregando os dados das culturas
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Logger.info('🔄 Inicializando CultureImportService...');
      
      // Primeiro, tentar carregar do arquivo completo
      try {
        await _loadFromCompleteCatalog();
      } catch (e) {
        Logger.warning('⚠️ Erro ao carregar catálogo completo, tentando método alternativo: $e');
        // Fallback: carregar arquivos individuais se existirem
        for (String culture in _availableCultures) {
          try {
            await _loadCultureData(culture);
          } catch (e) {
            Logger.warning('⚠️ Erro ao carregar cultura $culture: $e');
          }
        }
      }
      
      _isInitialized = true;
      Logger.info('✅ CultureImportService inicializado com ${_cultureCache.length} culturas');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar CultureImportService: $e');
    }
  }

  /// Carrega dados do catálogo completo de organismos
  Future<void> _loadFromCompleteCatalog() async {
    try {
      Logger.info('🔄 Carregando todas as 12 culturas dos arquivos individuais...');
      
      // Carregar todas as 12 culturas dos arquivos individuais
      int totalCulturas = 0;
      for (String culture in _availableCultures) {
        try {
          await _loadCultureData(culture);
          totalCulturas++;
          Logger.info('✅ Carregada cultura $culture');
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar cultura $culture: $e');
        }
      }
      
      Logger.info('✅ Carregadas $totalCulturas de ${_availableCultures.length} culturas dos arquivos individuais');
      
      // Se ainda não temos culturas suficientes, tentar o arquivo completo como fallback
      if (_cultureCache.length < 9) {
        try {
          Logger.info('🔄 Tentando carregar do arquivo organism_catalog_complete.json como fallback...');
          final jsonString = await rootBundle.loadString('$_basePath/organism_catalog_complete.json');
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          
          if (jsonData.containsKey('cultures')) {
            final cultures = jsonData['cultures'] as Map<String, dynamic>;
            Logger.info('📊 Encontradas ${cultures.length} culturas no arquivo completo');
            
            for (String cultureKey in cultures.keys) {
              if (!_cultureCache.containsKey(cultureKey)) {
                try {
                  final cultureData = cultures[cultureKey];
                  await _processCultureData(cultureKey, cultureData);
                  Logger.info('✅ Carregada cultura $cultureKey do arquivo completo');
                } catch (e) {
                  Logger.warning('⚠️ Erro ao processar cultura $cultureKey: $e');
                }
              }
            }
          }
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar arquivo completo como fallback: $e');
        }
      }
      
      Logger.info('✅ Carregado catálogo completo com ${_cultureCache.length} culturas');
    } catch (e) {
      Logger.error('❌ Erro ao carregar catálogo completo: $e');
      rethrow;
    }
  }

  /// Processa dados de uma cultura específica
  Future<void> _processCultureData(String cultureKey, Map<String, dynamic> cultureData) async {
    // Armazenar dados da cultura
    _cultureCache[cultureKey] = {
      'id': cultureData['id'] ?? cultureKey,
      'name': cultureData['name'] ?? cultureKey,
      'scientificName': cultureData['scientificName'] ?? '',
      'description': cultureData['description'] ?? 'Cultura $cultureKey',
      'version': cultureData['version'] ?? '1.0',
      'updateDate': cultureData['updateDate'] ?? DateTime.now().toIso8601String(),
    };
    
    // Processar organismos
    final organisms = <Map<String, dynamic>>[];
    
    // Organismos (pragas, doenças, plantas daninhas)
    if (cultureData.containsKey('organisms')) {
      final organismsData = cultureData['organisms'] as Map<String, dynamic>? ?? {};
      
      // Pragas
      if (organismsData.containsKey('pests')) {
        final pests = organismsData['pests'] as List<dynamic>? ?? [];
        for (var pest in pests) {
          organisms.add({
            ...pest,
            'tipo': 'PRAGA',
            'cultura_id': cultureKey,
          });
        }
      }
      
      // Doenças
      if (organismsData.containsKey('diseases')) {
        final diseases = organismsData['diseases'] as List<dynamic>? ?? [];
        for (var disease in diseases) {
          organisms.add({
            ...disease,
            'tipo': 'DOENCA',
            'cultura_id': cultureKey,
          });
        }
      }
      
      // Plantas daninhas
      if (organismsData.containsKey('weeds')) {
        final weeds = organismsData['weeds'] as List<dynamic>? ?? [];
        for (var weed in weeds) {
          organisms.add({
            ...weed,
            'tipo': 'PLANTA_DANINHA',
            'cultura_id': cultureKey,
          });
        }
      }
    }
    
    _organismCache[cultureKey] = organisms;
    Logger.info('✅ Processada cultura $cultureKey com ${organisms.length} organismos');
  }

  /// Carrega dados de uma cultura específica (método alternativo)
  Future<void> _loadCultureData(String cultureName) async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/organismos_${cultureName}.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Armazenar dados da cultura
      _cultureCache[cultureName] = {
        'id': cultureName,
        'name': jsonData['cultura'] ?? cultureName,
        'scientificName': jsonData['nome_cientifico'] ?? '',
        'description': 'Cultura ${jsonData['cultura'] ?? cultureName}',
        'version': jsonData['versao'] ?? '1.0',
        'updateDate': jsonData['data_atualizacao'] ?? DateTime.now().toIso8601String(),
      };
      
      // Processar organismos
      final organisms = jsonData['organismos'] as List<dynamic>? ?? [];
      _organismCache[cultureName] = organisms.cast<Map<String, dynamic>>();
      
      Logger.info('✅ Carregada cultura $cultureName com ${organisms.length} organismos');
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar cultura $cultureName: $e');
    }
  }

  /// Retorna todas as culturas disponíveis
  Future<List<Map<String, dynamic>>> getAllCrops() async {
    if (!_isInitialized) await initialize();
    
    return _cultureCache.values.toList();
  }

  /// Retorna uma cultura específica pelo ID
  Future<Map<String, dynamic>?> getCropById(String id) async {
    if (!_isInitialized) await initialize();
    
    return _cultureCache[id];
  }

  /// Retorna pragas de uma cultura específica
  Future<List<Map<String, dynamic>>> getPestsByCrop(String cropId) async {
    if (!_isInitialized) await initialize();
    
    final organisms = _organismCache[cropId] ?? [];
    return organisms.where((org) => org['tipo'] == 'PRAGA').toList();
  }

  /// Retorna doenças de uma cultura específica
  Future<List<Map<String, dynamic>>> getDiseasesByCrop(String cropId) async {
    if (!_isInitialized) await initialize();
    
    final organisms = _organismCache[cropId] ?? [];
    return organisms.where((org) => org['tipo'] == 'DOENCA').toList();
  }

  /// Retorna plantas daninhas de uma cultura específica
  Future<List<Map<String, dynamic>>> getWeedsByCrop(String cropId) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Usar o WeedDataService para carregar plantas daninhas dos arquivos JSON
      final weedService = WeedDataService();
      final weeds = await weedService.loadWeedsForCrop(cropId);
      
      if (weeds.isEmpty) {
        Logger.warning('⚠️ Nenhuma planta daninha encontrada para $cropId');
        return [];
      }
      
      // Converter para o formato esperado
      final result = weeds.map((weed) => {
        'id': weed.id,
        'nome': weed.name,
        'nome_cientifico': weed.scientificName,
        'categoria': weed.category,
        'descricao': weed.description,
        'sintomas': weed.symptoms,
        'tipo': 'PLANTA_DANINHA',
        'cultura_id': cropId,
      }).toList();
      
      Logger.info('✅ ${result.length} plantas daninhas específicas retornadas para $cropId');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao carregar plantas daninhas para $cropId: $e');
      return [];
    }
  }

  /// Retorna todos os organismos de uma cultura específica
  Future<List<Map<String, dynamic>>> getOrganismsByCrop(String cropId) async {
    if (!_isInitialized) await initialize();
    
    return _organismCache[cropId] ?? [];
  }

  /// Retorna variedades de uma cultura específica (placeholder)
  Future<List<Map<String, dynamic>>> getVarietiesByCrop(String cropId) async {
    if (!_isInitialized) await initialize();
    
    // Por enquanto, retorna variedades genéricas baseadas na cultura
    final culture = _cultureCache[cropId];
    if (culture == null) return [];
    
    return [
      {
        'id': '${cropId}_variedade_1',
        'name': 'Variedade Convencional',
        'description': 'Variedade convencional de ${culture['name']}',
        'cycleDays': 120,
        'notes': 'Variedade padrão para ${culture['name']}',
      },
      {
        'id': '${cropId}_variedade_2',
        'name': 'Variedade Transgênica',
        'description': 'Variedade transgênica de ${culture['name']}',
        'cycleDays': 115,
        'notes': 'Variedade com tecnologia Bt para ${culture['name']}',
      },
    ];
  }

  /// Retorna todas as pragas de todas as culturas
  Future<List<Map<String, dynamic>>> getAllPests() async {
    if (!_isInitialized) await initialize();
    
    List<Map<String, dynamic>> allPests = [];
    for (String cultureId in _availableCultures) {
      final pests = await getPestsByCrop(cultureId);
      allPests.addAll(pests);
    }
    return allPests;
  }

  /// Retorna todas as doenças de todas as culturas
  Future<List<Map<String, dynamic>>> getAllDiseases() async {
    if (!_isInitialized) await initialize();
    
    List<Map<String, dynamic>> allDiseases = [];
    for (String cultureId in _availableCultures) {
      final diseases = await getDiseasesByCrop(cultureId);
      allDiseases.addAll(diseases);
    }
    return allDiseases;
  }

  /// Retorna todas as plantas daninhas de todas as culturas
  Future<List<Map<String, dynamic>>> getAllWeeds() async {
    if (!_isInitialized) await initialize();
    
    List<Map<String, dynamic>> allWeeds = [];
    for (String cultureId in _availableCultures) {
      final weeds = await getWeedsByCrop(cultureId);
      allWeeds.addAll(weeds);
    }
    return allWeeds;
  }

  /// Força a inserção de dados padrão (método de compatibilidade)
  Future<void> forceInsertDefaultData() async {
    await initialize();
    Logger.info('✅ Dados padrão carregados via CultureImportService');
  }

  /// Métodos de compatibilidade com nomes antigos
  Future<List<Map<String, dynamic>>> getAllCultures() async {
    return getAllCrops();
  }

  Future<List<Map<String, dynamic>>> getCulturesByType(String type) async {
    // Por enquanto, retorna todas as culturas independente do tipo
    return getAllCrops();
  }

  Future<Map<String, dynamic>?> getCultureById(String id) async {
    return getCropById(id);
  }
}
