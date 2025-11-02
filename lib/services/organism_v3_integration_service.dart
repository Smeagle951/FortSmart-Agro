import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/organism_catalog_v3.dart';
import '../utils/logger.dart';
import 'organism_catalog_loader_service_v3.dart';
import 'fortsmart_ai_v3_integration.dart';

/// Serviço de integração dos dados v3.0 com serviços existentes
/// Conecta organismos v3.0 aos relatórios agronômicos e IA FortSmart
class OrganismV3IntegrationService {
  final OrganismCatalogLoaderServiceV3 _loader = OrganismCatalogLoaderServiceV3();
  static final OrganismV3IntegrationService _instance = OrganismV3IntegrationService._internal();
  factory OrganismV3IntegrationService() => _instance;
  OrganismV3IntegrationService._internal();
  
  // Cache de organismos por cultura
  final Map<String, List<OrganismCatalogV3>> _organismCache = {};
  final Map<String, OrganismCatalogV3> _organismByIdCache = {};
  
  /// Carrega e cacheia organismos de uma cultura
  Future<List<OrganismCatalogV3>> loadOrganismsForCulture(String cultura) async {
    if (_organismCache.containsKey(cultura)) {
      return _organismCache[cultura]!;
    }
    
    try {
      final organismos = await _loader.loadCultureOrganismsV3(cultura);
      _organismCache[cultura] = organismos;
    
    for (var org in organismos) {
        _organismByIdCache[org.id] = org;
        _organismByIdCache[org.name.toLowerCase()] = org;
        if (org.scientificName.isNotEmpty) {
          _organismByIdCache[org.scientificName.toLowerCase()] = org;
        }
      }
      
      Logger.info('✅ ${organismos.length} organismos carregados para $cultura');
      return organismos;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos para $cultura: $e');
      return [];
    }
  }
  
  /// Busca organismo por nome ou ID (com cache)
  Future<OrganismCatalogV3?> findOrganism({
    required String nomeOrganismo,
    required String cultura,
  }) async {
    // Tentar cache primeiro
    final key = nomeOrganismo.toLowerCase().trim();
    if (_organismByIdCache.containsKey(key)) {
      return _organismByIdCache[key];
    }
    
    // Carregar cultura se necessário
    await loadOrganismsForCulture(cultura);
    
    // Buscar novamente após carregar
    if (_organismByIdCache.containsKey(key)) {
      return _organismByIdCache[key];
    }
    
    // Busca alternativa: buscar por similaridade
    final organismos = _organismCache[cultura] ?? [];
    for (var org in organismos) {
      if (org.name.toLowerCase().contains(key) ||
          key.contains(org.name.toLowerCase()) ||
          org.scientificName.toLowerCase().contains(key)) {
        return org;
      }
    }
    
    Logger.warning('⚠️ Organismo não encontrado: $nomeOrganismo em $cultura');
    return null;
  }
  
  /// Obtém dados de organismo para relatórios agronômicos (compatível com código existente)
  Future<Map<String, dynamic>> getOrganismDataForReport({
    required String organismoNome,
    required String cultura,
    double? temperatura,
    double? umidade,
  }) async {
    final organismo = await findOrganism(
      nomeOrganismo: organismoNome,
      cultura: cultura,
    );
    
    if (organismo == null) {
      return _getDefaultData(organismoNome, cultura);
    }
    
    // Retornar dados no formato esperado pelos relatórios
    final dados = <String, dynamic>{
      'nome': organismo.name,
      'nome_cientifico': organismo.scientificName,
      'categoria': organismo.type.toString().contains('pest') ? 'praga' : 
                   organismo.type.toString().contains('disease') ? 'doenca' : 'daninha',
      'cultura': cultura,
      'sintomas': organismo.symptoms,
      'dano_economico': organismo.economicDamage ?? '',
      'manejo_quimico': organismo.chemicalControl,
      'manejo_biologico': organismo.biologicalControl,
      'manejo_cultural': organismo.culturalControl,
      'nivel_acao': organismo.actionLevel ?? '',
      'partes_afetadas': organismo.affectedParts,
      'fenologia': organismo.phenology,
      
      // Dados v3.0
      'versao': '3.0',
      'caracteristicas_visuais': organismo.visualCharacteristics?.toJson(),
      'condicoes_climaticas': organismo.climaticConditions?.toJson(),
      'ciclo_vida': organismo.lifeCycle?.toJson(),
      'rotacao_resistencia': organismo.resistanceRotation?.toJson(),
      'distribuicao_geografica': organismo.geographicDistribution,
      'economia_agronomica': organismo.agronomicEconomics?.toJson(),
      'controle_biologico': organismo.biologicalControlDetailed?.toJson(),
      'diagnostico_diferencial': organismo.differentialDiagnosis?.toJson(),
      'tendencias_sazonais': organismo.seasonalTrends?.toJson(),
      'features_ia': organismo.iaFeatures?.toJson(),
      'fontes_referencia': organismo.fontesReferencia?.toJson(),
      
      // Dados calculados se tiver temperatura/umidade
      'risco_climatico': null,
      'roi': null,
    };
    
    // Calcular risco climático se tiver dados
    if (temperatura != null && umidade != null && organismo.climaticConditions != null) {
      dados['risco_climatico'] = FortSmartAIV3Integration.calcularRiscoClimatico(
        organismo: organismo,
        temperaturaAtual: temperatura,
        umidadeAtual: umidade,
      );
    }
    
    return dados;
  }
  
  /// Obtém dados para IA FortSmart (compatível com formato antigo)
  Map<String, dynamic> _getOrganismDataForAI(OrganismCatalogV3 organismo) {
    final tempIdeal = organismo.climaticConditions != null
      ? [
          organismo.climaticConditions!.minTemperature?.toDouble() ?? 20.0,
          organismo.climaticConditions!.maxTemperature?.toDouble() ?? 30.0,
        ]
      : [25.0, 30.0];
    
    final umidadeIdeal = organismo.climaticConditions != null
      ? [
          organismo.climaticConditions!.minHumidity?.toDouble() ?? 60.0,
          organismo.climaticConditions!.maxHumidity?.toDouble() ?? 80.0,
        ]
      : [60.0, 80.0];
    
    return {
      'nome': organismo.name,
      'cientifico': organismo.scientificName,
      'tipo': organismo.type.toString().contains('pest') ? 'praga' : 'doenca',
      'cultura': organismo.cropName,
      'temp_ideal': tempIdeal,
      'umidade_ideal': umidadeIdeal,
      'estagio_critico': organismo.phenology,
      'limiar_controle': 2.0, // TODO: extrair de niveis_infestacao
      'unidade': 'unidades/ponto',
      'geracoes_safra': organismo.lifeCycle?.generationsPerYear ?? 4,
      'graus_dia_geracao': organismo.lifeCycle?.totalDurationDays != null
        ? (365.0 / (organismo.lifeCycle!.generationsPerYear ?? 1) * 30.0)
        : 280.0,
    };
  }
  
  /// Dados padrão quando organismo não é encontrado
  Map<String, dynamic> _getDefaultData(String nome, String cultura) {
    return {
      'nome': nome,
      'nome_cientifico': '',
      'categoria': 'praga',
      'cultura': cultura,
      'sintomas': [],
      'dano_economico': '',
      'manejo_quimico': [],
      'manejo_biologico': [],
      'manejo_cultural': [],
      'versao': '2.0',
    };
  }
  
  /// Limpa cache (útil para atualizações)
  void clearCache() {
    _organismCache.clear();
    _organismByIdCache.clear();
  }
}

