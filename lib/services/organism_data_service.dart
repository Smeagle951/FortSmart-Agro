import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Serviço de Dados de Organismos - FortSmart Agro
/// 
/// Sistema híbrido que consolida dados de organismos de múltiplas fontes,
/// garantindo consistência, performance e facilidade de manutenção.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class OrganismData {
  final String id;
  final String name;
  final String scientificName;
  final String category;
  final String cultureId;
  final String cultureName;
  final List<String> symptoms;
  final String economicDamage;
  final List<String> affectedParts;
  final List<String> phenology;
  final String actionThreshold;
  final Map<String, dynamic>? detailedPhenology;
  final Map<String, dynamic>? severityLevels;
  final Map<String, dynamic>? infestationLevels;
  final List<String> chemicalManagement;
  final List<String> biologicalManagement;
  final List<String> culturalManagement;
  final Map<String, dynamic>? favorableConditions;
  final Map<String, dynamic>? specificThresholds;
  final Map<String, dynamic>? advancedManagement;
  final Map<String, dynamic>? detailedSymptoms;
  final List<Map<String, dynamic>>? lifeStages;
  final Map<String, dynamic>? resistanceCodes;
  final String? safetyPeriod;
  final Map<String, dynamic>? efficacyByPhase;
  final String? monitoringMethod;
  final String? observations;
  final String icon;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganismData({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.cultureId,
    required this.cultureName,
    required this.symptoms,
    required this.economicDamage,
    required this.affectedParts,
    required this.phenology,
    required this.actionThreshold,
    this.detailedPhenology,
    this.severityLevels,
    this.infestationLevels,
    required this.chemicalManagement,
    required this.biologicalManagement,
    required this.culturalManagement,
    this.favorableConditions,
    this.specificThresholds,
    this.advancedManagement,
    this.detailedSymptoms,
    this.lifeStages,
    this.resistanceCodes,
    this.safetyPeriod,
    this.efficacyByPhase,
    this.monitoringMethod,
    this.observations,
    required this.icon,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganismData.fromJson(Map<String, dynamic> json) {
    return OrganismData(
      id: json['id'] ?? '',
      name: json['nome'] ?? json['name'] ?? '',
      scientificName: json['nome_cientifico'] ?? json['scientific_name'] ?? '',
      category: json['categoria'] ?? json['category'] ?? '',
      cultureId: json['cultura_id'] ?? json['crop_id'] ?? '',
      cultureName: json['cultura'] ?? json['crop_name'] ?? '',
      symptoms: List<String>.from(json['sintomas'] ?? json['symptoms'] ?? []),
      economicDamage: json['dano_economico'] ?? json['economic_damage'] ?? '',
      affectedParts: List<String>.from(json['partes_afetadas'] ?? json['affected_parts'] ?? []),
      phenology: List<String>.from(json['fenologia'] ?? json['phenology'] ?? []),
      actionThreshold: json['nivel_acao'] ?? json['action_threshold'] ?? '',
      detailedPhenology: json['fases_fenologicas_detalhadas'],
      severityLevels: json['severidade'] ?? json['severity_levels'],
      infestationLevels: json['niveis_infestacao'] ?? json['infestation_levels'],
      chemicalManagement: List<String>.from(json['manejo_quimico'] ?? json['chemical_management'] ?? []),
      biologicalManagement: List<String>.from(json['manejo_biologico'] ?? json['biological_management'] ?? []),
      culturalManagement: List<String>.from(json['manejo_cultural'] ?? json['cultural_management'] ?? []),
      favorableConditions: json['condicoes_favoraveis'] ?? json['favorable_conditions'],
      specificThresholds: json['limiares_especificos'] ?? json['specific_thresholds'],
      advancedManagement: json['manejo_avancado'] ?? json['advanced_management'],
      detailedSymptoms: json['sintomas_detalhados'] ?? json['detailed_symptoms'],
      lifeStages: json['fases'] != null ? List<Map<String, dynamic>>.from(json['fases']) : null,
      resistanceCodes: json['codigos_resistencia'] ?? json['resistance_codes'],
      safetyPeriod: json['periodo_carencia'] ?? json['safety_period'],
      efficacyByPhase: json['eficacia_por_fase'] ?? json['efficacy_by_phase'],
      monitoringMethod: json['metodo_monitoramento'] ?? json['monitoring_method'],
      observations: json['observacoes'] ?? json['observations'],
      icon: json['icone'] ?? json['icon'] ?? '🐛',
      active: json['ativo'] ?? json['active'] ?? true,
      createdAt: DateTime.tryParse(json['data_criacao'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['data_atualizacao'] ?? json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': name,
      'nome_cientifico': scientificName,
      'categoria': category,
      'cultura_id': cultureId,
      'cultura': cultureName,
      'sintomas': symptoms,
      'dano_economico': economicDamage,
      'partes_afetadas': affectedParts,
      'fenologia': phenology,
      'nivel_acao': actionThreshold,
      'fases_fenologicas_detalhadas': detailedPhenology,
      'severidade': severityLevels,
      'niveis_infestacao': infestationLevels,
      'manejo_quimico': chemicalManagement,
      'manejo_biologico': biologicalManagement,
      'manejo_cultural': culturalManagement,
      'condicoes_favoraveis': favorableConditions,
      'limiares_especificos': specificThresholds,
      'manejo_avancado': advancedManagement,
      'sintomas_detalhados': detailedSymptoms,
      'fases': lifeStages,
      'codigos_resistencia': resistanceCodes,
      'periodo_carencia': safetyPeriod,
      'eficacia_por_fase': efficacyByPhase,
      'metodo_monitoramento': monitoringMethod,
      'observacoes': observations,
      'icone': icon,
      'ativo': active,
      'data_criacao': createdAt.toIso8601String(),
      'data_atualizacao': updatedAt.toIso8601String(),
    };
  }
}

class CultureData {
  final String id;
  final String name;
  final String scientificName;
  final String version;
  final DateTime lastUpdated;
  final Map<String, bool> extraFeatures;
  final List<OrganismData> organisms;

  CultureData({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.version,
    required this.lastUpdated,
    required this.extraFeatures,
    required this.organisms,
  });

  factory CultureData.fromJson(Map<String, dynamic> json) {
    final organisms = (json['organismos'] as List<dynamic>?)
        ?.map((org) => OrganismData.fromJson(org))
        .toList() ?? [];

    return CultureData(
      id: json['cultura_id'] ?? json['id'] ?? '',
      name: json['cultura'] ?? json['name'] ?? '',
      scientificName: json['nome_cientifico'] ?? json['scientific_name'] ?? '',
      version: json['versao'] ?? json['version'] ?? '1.0',
      lastUpdated: DateTime.tryParse(json['data_atualizacao'] ?? json['last_updated'] ?? '') ?? DateTime.now(),
      extraFeatures: Map<String, bool>.from(json['funcionalidades_extras'] ?? json['extra_features'] ?? {}),
      organisms: organisms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cultura': name,
      'nome_cientifico': scientificName,
      'versao': version,
      'data_atualizacao': lastUpdated.toIso8601String(),
      'funcionalidades_extras': extraFeatures,
      'organismos': organisms.map((org) => org.toJson()).toList(),
    };
  }
}

class OrganismDataService {
  static final OrganismDataService _instance = OrganismDataService._internal();
  factory OrganismDataService() => _instance;
  OrganismDataService._internal();

  final Map<String, CultureData> _culturesCache = {};
  final Map<String, OrganismData> _organismsCache = {};
  bool _isInitialized = false;

  /// Inicializa o serviço carregando todos os dados
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔄 Inicializando OrganismDataService...');
    
    await _loadAllCultures();
    _buildOrganismsCache();
    
    _isInitialized = true;
    print('✅ OrganismDataService inicializado com ${_culturesCache.length} culturas e ${_organismsCache.length} organismos');
  }

  /// Carrega todas as culturas dos arquivos individuais
  Future<void> _loadAllCultures() async {
    final cultureFiles = [
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

    for (final file in cultureFiles) {
      try {
        final cultureData = await _loadCultureFromFile(file);
        if (cultureData != null) {
          _culturesCache[cultureData.id] = cultureData;
          print('  ✓ Carregada: ${cultureData.name} (${cultureData.organisms.length} organismos)');
        }
      } catch (e) {
        print('  ❌ Erro ao carregar $file: $e');
      }
    }
  }

  /// Carrega dados de cultura de um arquivo
  Future<CultureData?> _loadCultureFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content);
      
      return CultureData.fromJson(json);
    } catch (e) {
      print('Erro ao carregar $filePath: $e');
      return null;
    }
  }

  /// Constrói cache de organismos para busca rápida
  void _buildOrganismsCache() {
    _organismsCache.clear();
    
    for (final culture in _culturesCache.values) {
      for (final organism in culture.organisms) {
        _organismsCache[organism.id] = organism;
      }
    }
  }

  /// Obtém todas as culturas disponíveis
  List<CultureData> getAllCultures() {
    return _culturesCache.values.toList();
  }

  /// Obtém cultura por ID
  CultureData? getCultureById(String cultureId) {
    return _culturesCache[cultureId];
  }

  /// Obtém cultura por nome
  CultureData? getCultureByName(String cultureName) {
    return _culturesCache.values.firstWhere(
      (culture) => culture.name.toLowerCase() == cultureName.toLowerCase(),
      orElse: () => throw StateError('Cultura não encontrada: $cultureName'),
    );
  }

  /// Obtém todos os organismos de uma cultura
  List<OrganismData> getOrganismsByCulture(String cultureId) {
    final culture = _culturesCache[cultureId];
    return culture?.organisms ?? [];
  }

  /// Obtém organismos por categoria
  List<OrganismData> getOrganismsByCategory(String category) {
    return _organismsCache.values
        .where((org) => org.category.toLowerCase().contains(category.toLowerCase()))
        .toList();
  }

  /// Obtém organismo por ID
  OrganismData? getOrganismById(String organismId) {
    return _organismsCache[organismId];
  }

  /// Busca organismos por nome
  List<OrganismData> searchOrganisms(String query) {
    final lowerQuery = query.toLowerCase();
    return _organismsCache.values
        .where((org) => 
          org.name.toLowerCase().contains(lowerQuery) ||
          org.scientificName.toLowerCase().contains(lowerQuery) ||
          org.symptoms.any((symptom) => symptom.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  /// Obtém organismos por fase fenológica
  List<OrganismData> getOrganismsByPhenology(String cultureId, String phenologyPhase) {
    final organisms = getOrganismsByCulture(cultureId);
    return organisms
        .where((org) => org.phenology.contains(phenologyPhase))
        .toList();
  }

  /// Obtém organismos ativos
  List<OrganismData> getActiveOrganisms() {
    return _organismsCache.values
        .where((org) => org.active)
        .toList();
  }

  /// Obtém dados consolidados para catálogo (versão simplificada)
  Map<String, dynamic> getCatalogData() {
    final cultures = <String, dynamic>{};
    
    for (final culture in _culturesCache.values) {
      final organisms = <String, dynamic>{
        'pests': <Map<String, dynamic>>[],
        'diseases': <Map<String, dynamic>>[],
        'deficiencies': <Map<String, dynamic>>[],
      };
      
      for (final organism in culture.organisms) {
        final organismType = _getOrganismType(organism.category);
        final simplifiedOrganism = {
          'id': organism.id,
          'name': organism.name,
          'scientific_name': organism.scientificName,
          'type': organismType,
          'crop_id': culture.id,
          'crop_name': culture.name,
          'description': organism.economicDamage,
          'action_threshold': organism.actionThreshold,
          'monitoring_method': organism.monitoringMethod ?? 'pano-de-batida',
        };
        
        (organisms[organismType] as List).add(simplifiedOrganism);
      }
      
      cultures[culture.id] = {
        'id': culture.id,
        'name': culture.name,
        'organisms': organisms,
      };
    }
    
    return {
      'version': '4.0',
      'last_updated': DateTime.now().toIso8601String(),
      'cultures': cultures,
    };
  }

  /// Determina tipo de organismo para catálogo
  String _getOrganismType(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'pests';
    if (cat.contains('doença') || cat.contains('doenca')) return 'diseases';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return 'deficiencies';
    return 'pests';
  }

  /// Atualiza organismo
  Future<void> updateOrganism(String organismId, Map<String, dynamic> updates) async {
    final organism = _organismsCache[organismId];
    if (organism == null) throw StateError('Organismo não encontrado: $organismId');

    // Atualiza cache
    final updatedOrganism = OrganismData.fromJson({
      ...organism.toJson(),
      ...updates,
      'data_atualizacao': DateTime.now().toIso8601String(),
    });
    
    _organismsCache[organismId] = updatedOrganism;
    
    // Atualiza cultura correspondente
    final culture = _culturesCache[organism.cultureId];
    if (culture != null) {
      final organismIndex = culture.organisms.indexWhere((org) => org.id == organismId);
      if (organismIndex != -1) {
        culture.organisms[organismIndex] = updatedOrganism;
      }
    }
    
    // Salva arquivo
    await _saveCultureToFile(organism.cultureId);
  }

  /// Salva cultura em arquivo
  Future<void> _saveCultureToFile(String cultureId) async {
    final culture = _culturesCache[cultureId];
    if (culture == null) return;

    final filePath = 'assets/data/organismos_${cultureId}.json';
    final file = File(filePath);
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(culture.toJson());
    await file.writeAsString(jsonString);
  }

  /// Valida consistência dos dados
  List<String> validateData() {
    final issues = <String>[];
    
    for (final culture in _culturesCache.values) {
      for (final organism in culture.organisms) {
        // Validações básicas
        if (organism.name.isEmpty) {
          issues.add('Organismo ${organism.id} sem nome');
        }
        if (organism.scientificName.isEmpty) {
          issues.add('Organismo ${organism.id} sem nome científico');
        }
        if (organism.actionThreshold.isEmpty) {
          issues.add('Organismo ${organism.id} sem limiar de ação');
        }
        if (organism.symptoms.isEmpty) {
          issues.add('Organismo ${organism.id} sem sintomas');
        }
      }
    }
    
    return issues;
  }

  /// Obtém estatísticas dos dados
  Map<String, dynamic> getDataStatistics() {
    final totalOrganisms = _organismsCache.length;
    final activeOrganisms = _organismsCache.values.where((org) => org.active).length;
    final totalCultures = _culturesCache.length;
    
    final organismsByCategory = <String, int>{};
    for (final organism in _organismsCache.values) {
      organismsByCategory[organism.category] = (organismsByCategory[organism.category] ?? 0) + 1;
    }
    
    final organismsByCulture = <String, int>{};
    for (final culture in _culturesCache.values) {
      organismsByCulture[culture.name] = culture.organisms.length;
    }
    
    return {
      'total_organisms': totalOrganisms,
      'active_organisms': activeOrganisms,
      'total_cultures': totalCultures,
      'organisms_by_category': organismsByCategory,
      'organisms_by_culture': organismsByCulture,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
