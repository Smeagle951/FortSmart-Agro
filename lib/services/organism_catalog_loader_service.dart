import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/organism_catalog.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Serviço para carregar dados do catálogo de organismos dos arquivos JSON
/// ✅ PRIORIZA arquivo customizado da fazenda
class OrganismCatalogLoaderService {
  static const String _basePath = 'assets/data';
  
  /// Carrega todos os organismos de todas as culturas
  /// ✅ PRIORIDADE: organism_catalog_custom.json → organism_catalog_complete.json → organismos_*.json
  Future<List<OrganismCatalog>> loadAllOrganisms() async {
    try {
      List<OrganismCatalog> allOrganisms = [];
      
      // 1️⃣ PRIMEIRA PRIORIDADE: Arquivo customizado da fazenda
      final customData = await _loadFromCustomCatalog();
      if (customData != null && customData.isNotEmpty) {
        Logger.info('✅ Usando catálogo CUSTOMIZADO da fazenda (${customData.length} organismos)');
        return customData;
      }
      
      // 2️⃣ SEGUNDA PRIORIDADE: Arquivo completo atualizado
      try {
        Logger.info('🔄 Tentando carregar do arquivo organism_catalog_complete.json...');
        final jsonString = await rootBundle.loadString('$_basePath/organism_catalog_complete.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        
        if (jsonData.containsKey('cultures')) {
          final cultures = jsonData['cultures'] as Map<String, dynamic>;
          
          for (String cultureKey in cultures.keys) {
            try {
              final cultureData = cultures[cultureKey];
              final organisms = _parseCultureData(cultureData);
              allOrganisms.addAll(organisms);
              Logger.info('✅ Carregados ${organisms.length} organismos da cultura $cultureKey');
            } catch (e) {
              Logger.warning('⚠️ Erro ao processar cultura $cultureKey: $e');
            }
          }
          
          Logger.info('✅ Carregados ${allOrganisms.length} organismos do arquivo completo');
          return allOrganisms;
        }
      } catch (e) {
        Logger.warning('⚠️ Erro ao carregar arquivo completo, tentando método alternativo: $e');
      }
      
      // Fallback: carregar de arquivos individuais
      final cultures = [
        'soja',
        'milho', 
        'trigo',
        'feijao',
        'algodao',
        'sorgo',
        'girassol',
        'aveia',
        'arroz',
        'batata',
        'cana_acucar',
        'gergelim',
        'tomate'
      ];
      
      for (String culture in cultures) {
        try {
          final organisms = await _loadCultureOrganisms(culture);
          allOrganisms.addAll(organisms);
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar cultura $culture: $e');
        }
      }
      
      Logger.info('✅ Carregados ${allOrganisms.length} organismos de ${cultures.length} culturas');
      return allOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos: $e');
      return [];
    }
  }
  
  /// Carrega organismos de uma cultura específica
  Future<List<OrganismCatalog>> loadCultureOrganisms(String cultureName) async {
    try {
      return await _loadCultureOrganisms(cultureName);
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos da cultura $cultureName: $e');
      return [];
    }
  }
  
  /// Carrega organismos de uma cultura específica (método interno)
  Future<List<OrganismCatalog>> _loadCultureOrganisms(String cultureName) async {
    try {
      // Tenta carregar do arquivo específico da cultura (organismos_*.json)
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('$_basePath/organismos_$cultureName.json');
      } catch (e) {
        // Se não encontrar arquivo específico, tenta do arquivo principal
        try {
          jsonString = await rootBundle.loadString('$_basePath/organism_catalog.json');
        } catch (e2) {
          Logger.warning('⚠️ Não foi possível carregar dados para $cultureName');
          return [];
        }
      }
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      List<OrganismCatalog> organisms = [];
      
      // Processa dados do arquivo específico da cultura (organismos_*.json)
      if (jsonData.containsKey('organismos')) {
        organisms = _parseOrganismosFile(jsonData, cultureName);
      }
      // Processa dados do arquivo específico da cultura (estrutura antiga)
      else if (jsonData.containsKey('culture')) {
        organisms = _parseCultureData(jsonData['culture']);
      }
      // Processa dados do arquivo principal
      else if (jsonData.containsKey('cultures') && jsonData['cultures'].containsKey(cultureName)) {
        organisms = _parseCultureData(jsonData['cultures'][cultureName]);
      }
      
      Logger.info('✅ Carregados ${organisms.length} organismos da cultura $cultureName');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao processar dados da cultura $cultureName: $e');
      return [];
    }
  }
  
  /// Converte dados JSON do arquivo organismos_*.json em objetos OrganismCatalog
  List<OrganismCatalog> _parseOrganismosFile(Map<String, dynamic> jsonData, String cultureName) {
    List<OrganismCatalog> organisms = [];
    
    try {
      final String cropName = jsonData['cultura'] ?? cultureName;
      final List<dynamic> organismosData = jsonData['organismos'] ?? [];
      
      for (var org in organismosData) {
        try {
          final String categoria = (org['categoria'] ?? '').toLowerCase();
          final String tipo = (org['tipo'] ?? '').toUpperCase();
          
          OccurrenceType occurrenceType;
          if (categoria.contains('praga') || tipo == 'PRAGA') {
            occurrenceType = OccurrenceType.pest;
          } else if (categoria.contains('doen') || tipo == 'DOENCA') {
            occurrenceType = OccurrenceType.disease;
          } else if (categoria.contains('daninha') || categoria.contains('weed')) {
            occurrenceType = OccurrenceType.weed;
          } else {
            continue; // Pular organismos sem categoria válida
          }
          
          // Extrair limites de infestação
          final niveis = org['niveis_infestacao'] as Map<String, dynamic>?;
          final int lowLimit = _extractNumber(niveis?['baixo']) ?? 1;
          final int mediumLimit = _extractNumber(niveis?['medio']) ?? 3;
          final int highLimit = _extractNumber(niveis?['alto']) ?? 5;
          
          final organism = OrganismCatalog(
            name: org['nome'] ?? 'Organismo sem nome',
            scientificName: org['nome_cientifico'] ?? '',
            type: occurrenceType,
            cropId: cultureName,
            cropName: cropName,
            unit: _getUnitForOrganism(org['nome'] ?? ''),
            lowLimit: lowLimit,
            mediumLimit: mediumLimit,
            highLimit: highLimit,
            description: org['dano_economico'] ?? '',
            isActive: true,
          );
          
          organisms.add(organism);
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar organismo: $e');
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar arquivo organismos_$cultureName.json: $e');
    }
    
    return organisms;
  }

  /// Extrai número de string (ex: "1-2" -> 2, ">10" -> 10)
  int? _extractNumber(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    return match != null ? int.tryParse(match.group(1) ?? '0') : null;
  }

  /// Determina unidade baseada no nome do organismo
  String _getUnitForOrganism(String organismName) {
    final name = organismName.toLowerCase();
    if (name.contains('percevejo') || name.contains('lagarta') || name.contains('pulgao')) {
      return 'unidades/ponto';
    } else if (name.contains('doença') || name.contains('ferrugem') || name.contains('mancha')) {
      return '% folhas afetadas';
    } else if (name.contains('daninha') || name.contains('buva') || name.contains('capim')) {
      return 'plantas/m²';
    } else {
      return 'unidades/ponto';
    }
  }

  /// Converte dados JSON em objetos OrganismCatalog
  List<OrganismCatalog> _parseCultureData(Map<String, dynamic> cultureData) {
    List<OrganismCatalog> organisms = [];
    
    try {
      final String cropId = cultureData['id'] ?? '';
      final String cropName = cultureData['name'] ?? '';
      final Map<String, dynamic> organismsData = cultureData['organisms'] ?? {};
      
      // Processa pragas
      if (organismsData.containsKey('pests')) {
        for (var pest in organismsData['pests']) {
          organisms.add(_createOrganismFromJson(pest, cropId, cropName, OccurrenceType.pest));
        }
      }
      
      // Processa doenças
      if (organismsData.containsKey('diseases')) {
        for (var disease in organismsData['diseases']) {
          organisms.add(_createOrganismFromJson(disease, cropId, cropName, OccurrenceType.disease));
        }
      }
      
      // Processa plantas daninhas
      if (organismsData.containsKey('weeds')) {
        for (var weed in organismsData['weeds']) {
          organisms.add(_createOrganismFromJson(weed, cropId, cropName, OccurrenceType.weed));
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar dados da cultura: $e');
    }
    
    return organisms;
  }
  
  /// Cria objeto OrganismCatalog a partir de dados JSON
  OrganismCatalog _createOrganismFromJson(
    Map<String, dynamic> data, 
    String cropId, 
    String cropName, 
    OccurrenceType type
  ) {
    return OrganismCatalog(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      scientificName: data['scientific_name'] ?? '',
      type: type,
      cropId: cropId,
      cropName: cropName,
      unit: data['unit'] ?? '',
      lowLimit: data['low_limit']?.toInt() ?? 0,
      mediumLimit: data['medium_limit']?.toInt() ?? 0,
      highLimit: data['high_limit']?.toInt() ?? 0,
      description: data['description'] ?? '',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Obtém estatísticas do catálogo
  Future<Map<String, dynamic>> getCatalogStatistics() async {
    try {
      final organisms = await loadAllOrganisms();
      
      final Map<String, int> organismsByType = {};
      final Map<String, int> organismsByCrop = {};
      
      for (var organism in organisms) {
        // Conta por tipo
        final typeKey = organism.type.toString().split('.').last;
        organismsByType[typeKey] = (organismsByType[typeKey] ?? 0) + 1;
        
        // Conta por cultura
        organismsByCrop[organism.cropName] = (organismsByCrop[organism.cropName] ?? 0) + 1;
      }
      
      return {
        'total_organisms': organisms.length,
        'by_type': organismsByType,
        'by_crop': organismsByCrop,
        'cultures_count': organismsByCrop.length,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Busca organismos por critérios
  Future<List<OrganismCatalog>> searchOrganisms({
    String? query,
    String? cropId,
    OccurrenceType? type,
  }) async {
    try {
      final allOrganisms = await loadAllOrganisms();
      
      return allOrganisms.where((organism) {
        // Filtro por query
        if (query != null && query.isNotEmpty) {
          final searchQuery = query.toLowerCase();
          if (!organism.name.toLowerCase().contains(searchQuery) &&
              !organism.scientificName.toLowerCase().contains(searchQuery) &&
              !organism.cropName.toLowerCase().contains(searchQuery)) {
            return false;
          }
        }
        
        // Filtro por cultura
        if (cropId != null && organism.cropId != cropId) {
          return false;
        }
        
        // Filtro por tipo
        if (type != null && organism.type != type) {
          return false;
        }
        
        return true;
      }).toList();
      
    } catch (e) {
      Logger.error('❌ Erro na busca de organismos: $e');
      return [];
    }
  }

  /// Obtém organismos validados para o mapa de infestação
  /// Filtra apenas organismos ativos e com dados completos
  Future<List<OrganismCatalog>> getValidatedOrganismsForInfestationMap() async {
    try {
      Logger.info('🔍 Obtendo organismos validados para mapa de infestação');
      
      final allOrganisms = await loadAllOrganisms();
      
      // Filtrar organismos válidos para infestação
      final validatedOrganisms = allOrganisms.where((organism) {
        return organism.isActive && 
               organism.name.isNotEmpty &&
               organism.scientificName.isNotEmpty &&
               organism.cropId.isNotEmpty &&
               organism.cropName.isNotEmpty &&
               organism.unit.isNotEmpty &&
               organism.lowLimit > 0 &&
               organism.mediumLimit > organism.lowLimit &&
               organism.highLimit > organism.mediumLimit;
      }).toList();
      
      Logger.info('✅ ${validatedOrganisms.length} organismos validados para mapa de infestação');
      return validatedOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos validados: $e');
      return [];
    }
  }
  
  /// 🔧 CARREGA DO ARQUIVO CUSTOMIZADO DA FAZENDA
  Future<List<OrganismCatalog>?> _loadFromCustomCatalog() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final customFile = File('${directory.path}/organism_catalog_custom.json');
      
      if (!await customFile.exists()) {
        Logger.info('📄 Arquivo customizado não existe, usando dados padrão');
        return null; // ✅ Retorna null para carregar JSONs padrão
      }
      
      final jsonString = await customFile.readAsString();
      final catalogData = json.decode(jsonString) as Map<String, dynamic>;
      
      final cultures = catalogData['cultures'] as Map<String, dynamic>?;
      if (cultures == null) {
        Logger.warning('⚠️ Estrutura inválida no arquivo customizado');
        return null; // ✅ Retorna null para carregar padrão
      }
      
      final allOrganisms = <OrganismCatalog>[];
      
      for (final cultureEntry in cultures.entries) {
        try {
          final cultureData = cultureEntry.value as Map<String, dynamic>;
          final organisms = _parseCultureData(cultureData);
          allOrganisms.addAll(organisms);
          
          Logger.info('✅ ${organisms.length} organismos customizados de ${cultureEntry.key}');
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar cultura customizada: $e');
        }
      }
      
      return allOrganisms.isEmpty ? null : allOrganisms; // ✅ Null se vazio
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar customizado: $e');
      return null; // ✅ Em caso de erro, retorna null para carregar padrão
    }
  }
}
