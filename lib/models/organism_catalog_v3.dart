import 'package:uuid/uuid.dart';
import '../utils/enums.dart';

/// Modelo v3.0 para representar um organismo no catálogo FortSmart
/// Suporta as 10 melhorias integradas para IA agronômica
class OrganismCatalogV3 {
  final String id;
  final String name;
  final String scientificName;
  final OccurrenceType type;
  final String cropId;
  final String cropName;
  final List<String> affectedCrops; // Novos em v3.0
  
  // Campos existentes (compatibilidade v2.0)
  final String? unit;
  final int? lowLimit;
  final int? mediumLimit;
  final int? highLimit;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Campos básicos
  final List<String> symptoms;
  final String? economicDamage;
  final List<String> affectedParts;
  final List<String> phenology;
  final String? actionLevel;
  
  // Manejo
  final List<String> chemicalControl;
  final List<String> biologicalControl;
  final List<String> culturalControl;
  final String? observations;
  
  // ✨ NOVOS CAMPOS v3.0 - 10 Melhorias Integradas
  
  // 1. Dados Visuais
  final VisualCharacteristics? visualCharacteristics;
  
  // 2. Condições Climáticas
  final ClimaticConditions? climaticConditions;
  
  // 3. Ciclo de Vida
  final LifeCycle? lifeCycle;
  
  // 4. Rotação e Resistência
  final ResistanceRotation? resistanceRotation;
  
  // 5. Distribuição Geográfica
  final List<String>? geographicDistribution;
  
  // 6. Economia Agronômica
  final AgronomicEconomics? agronomicEconomics;
  
  // 7. Controle Biológico Detalhado
  final BiologicalControl? biologicalControlDetailed;
  
  // 8. Diagnóstico Diferencial
  final DifferentialDiagnosis? differentialDiagnosis;
  
  // 9. Tendências Sazonais
  final SeasonalTrends? seasonalTrends;
  
  // 10. Features IA
  final IAFeatures? iaFeatures;
  
  // 11. Fontes de Referência (NOVO)
  final FontesReferencia? fontesReferencia;

  OrganismCatalogV3({
    String? id,
    required this.name,
    required this.scientificName,
    required this.type,
    required this.cropId,
    required this.cropName,
    required this.affectedCrops,
    this.unit,
    this.lowLimit,
    this.mediumLimit,
    this.highLimit,
    this.description,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
    this.symptoms = const [],
    this.economicDamage,
    this.affectedParts = const [],
    this.phenology = const [],
    this.actionLevel,
    this.chemicalControl = const [],
    this.biologicalControl = const [],
    this.culturalControl = const [],
    this.observations,
    this.visualCharacteristics,
    this.climaticConditions,
    this.lifeCycle,
    this.resistanceRotation,
    this.geographicDistribution,
    this.agronomicEconomics,
    this.biologicalControlDetailed,
    this.differentialDiagnosis,
    this.seasonalTrends,
    this.iaFeatures,
    this.fontesReferencia,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now();

  /// Cria a partir de JSON (v2.0 ou v3.0)
  factory OrganismCatalogV3.fromJson(Map<String, dynamic> json, {String? cropId, String? cropName}) {
    // Detectar versão
    final version = json['versao']?.toString() ?? '2.0';
    final isV3 = version == '3.0' || json.containsKey('caracteristicas_visuais');
    
    // Parse tipo
    final categoria = json['categoria']?.toString() ?? '';
    final tipoStr = json['tipo']?.toString() ?? '';
    OccurrenceType type;
    
    if (tipoStr.contains('PRAGA') || categoria == 'Praga') {
      type = OccurrenceType.pest;
    } else if (tipoStr.contains('DOENCA') || categoria == 'Doença') {
      type = OccurrenceType.disease;
    } else {
      type = OccurrenceType.weed;
    }
    
    return OrganismCatalogV3(
      id: json['id']?.toString() ?? '',
      name: json['nome']?.toString() ?? json['name']?.toString() ?? '',
      scientificName: json['nome_cientifico']?.toString() ?? json['scientificName']?.toString() ?? '',
      type: type,
      cropId: cropId ?? json['cultura_id']?.toString() ?? '',
      cropName: cropName ?? json['cultura']?.toString() ?? '',
      affectedCrops: isV3 
        ? (json['culturas_afetadas'] as List?)?.map((e) => e.toString()).toList() ?? []
        : [cropName ?? json['cultura']?.toString() ?? ''],
      
      // Campos básicos
      symptoms: (json['sintomas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      economicDamage: json['dano_economico']?.toString(),
      affectedParts: (json['partes_afetadas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      phenology: (json['fenologia'] as List?)?.map((e) => e.toString()).toList() ?? [],
      actionLevel: json['nivel_acao']?.toString(),
      
      // Manejo
      chemicalControl: (json['manejo_quimico'] as List?)?.map((e) => e.toString()).toList() ?? [],
      biologicalControl: (json['manejo_biologico'] as List?)?.map((e) => e.toString()).toList() ?? [],
      culturalControl: (json['manejo_cultural'] as List?)?.map((e) => e.toString()).toList() ?? [],
      observations: json['observacoes']?.toString(),
      
      // Novos campos v3.0 (se disponíveis)
      visualCharacteristics: isV3 && json['caracteristicas_visuais'] != null
        ? VisualCharacteristics.fromJson(json['caracteristicas_visuais'])
        : null,
      
      climaticConditions: isV3 && json['condicoes_climaticas'] != null
        ? ClimaticConditions.fromJson(json['condicoes_climaticas'])
        : null,
      
      lifeCycle: isV3 && json['ciclo_vida'] != null
        ? LifeCycle.fromJson(json['ciclo_vida'])
        : null,
      
      resistanceRotation: isV3 && json['rotacao_resistencia'] != null && type == OccurrenceType.pest
        ? ResistanceRotation.fromJson(json['rotacao_resistencia'])
        : null,
      
      geographicDistribution: isV3 && json['distribuicao_geografica'] != null
        ? (json['distribuicao_geografica'] as List?)?.map((e) => e.toString()).toList()
        : null,
      
      agronomicEconomics: isV3 && json['economia_agronomica'] != null
        ? AgronomicEconomics.fromJson(json['economia_agronomica'])
        : null,
      
      biologicalControlDetailed: isV3 && json['controle_biologico'] != null
        ? BiologicalControl.fromJson(json['controle_biologico'])
        : null,
      
      differentialDiagnosis: isV3 && json['diagnostico_diferencial'] != null
        ? DifferentialDiagnosis.fromJson(json['diagnostico_diferencial'])
        : null,
      
      seasonalTrends: isV3 && json['tendencias_sazonais'] != null
        ? SeasonalTrends.fromJson(json['tendencias_sazonais'])
        : null,
      
      iaFeatures: isV3 && json['features_ia'] != null
        ? IAFeatures.fromJson(json['features_ia'])
        : null,
      
      fontesReferencia: json['fontes_referencia'] != null
        ? FontesReferencia.fromJson(json['fontes_referencia'])
        : null,
    );
  }

  /// Converte para Map/JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': name,
      'nome_cientifico': scientificName,
      'categoria': type == OccurrenceType.pest ? 'Praga' : 
                   type == OccurrenceType.disease ? 'Doença' : 'Planta Daninha',
      'culturas_afetadas': affectedCrops,
      'versao': '3.0',
      'sintomas': symptoms,
      'dano_economico': economicDamage,
      'partes_afetadas': affectedParts,
      'fenologia': phenology,
      'nivel_acao': actionLevel,
      'manejo_quimico': chemicalControl,
      'manejo_biologico': biologicalControl,
      'manejo_cultural': culturalControl,
      'observacoes': observations,
      
      // Novos campos v3.0
      if (visualCharacteristics != null) 'caracteristicas_visuais': visualCharacteristics!.toJson(),
      if (climaticConditions != null) 'condicoes_climaticas': climaticConditions!.toJson(),
      if (lifeCycle != null) 'ciclo_vida': lifeCycle!.toJson(),
      if (resistanceRotation != null) 'rotacao_resistencia': resistanceRotation!.toJson(),
      if (geographicDistribution != null) 'distribuicao_geografica': geographicDistribution,
      if (agronomicEconomics != null) 'economia_agronomica': agronomicEconomics!.toJson(),
      if (biologicalControlDetailed != null) 'controle_biologico': biologicalControlDetailed!.toJson(),
      if (differentialDiagnosis != null) 'diagnostico_diferencial': differentialDiagnosis!.toJson(),
      if (seasonalTrends != null) 'tendencias_sazonais': seasonalTrends!.toJson(),
      if (iaFeatures != null) 'features_ia': iaFeatures!.toJson(),
      if (fontesReferencia != null) 'fontes_referencia': fontesReferencia!.toJson(),
    };
  }
}

// ============================================
// CLASSES AUXILIARES PARA CAMPOS v3.0
// ============================================

/// 1. Características Visuais
class VisualCharacteristics {
  final List<String> predominantColors;
  final List<String> patterns;
  final Map<String, num>? averageSizeMm;
  
  VisualCharacteristics({
    this.predominantColors = const [],
    this.patterns = const [],
    this.averageSizeMm,
  });
  
  factory VisualCharacteristics.fromJson(Map<String, dynamic> json) {
    return VisualCharacteristics(
      predominantColors: (json['cores_predominantes'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      patterns: (json['padroes'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      averageSizeMm: json['tamanho_medio_mm'] != null
        ? Map<String, num>.from(json['tamanho_medio_mm'])
        : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'cores_predominantes': predominantColors,
    'padroes': patterns,
    if (averageSizeMm != null) 'tamanho_medio_mm': averageSizeMm,
  };
}

/// 2. Condições Climáticas
class ClimaticConditions {
  final int? minTemperature;
  final int? maxTemperature;
  final int? minHumidity;
  final int? maxHumidity;
  
  ClimaticConditions({
    this.minTemperature,
    this.maxTemperature,
    this.minHumidity,
    this.maxHumidity,
  });
  
  factory ClimaticConditions.fromJson(Map<String, dynamic> json) {
    return ClimaticConditions(
      minTemperature: json['temperatura_min'] as int?,
      maxTemperature: json['temperatura_max'] as int?,
      minHumidity: json['umidade_min'] as int?,
      maxHumidity: json['umidade_max'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    if (minTemperature != null) 'temperatura_min': minTemperature,
    if (maxTemperature != null) 'temperatura_max': maxTemperature,
    if (minHumidity != null) 'umidade_min': minHumidity,
    if (maxHumidity != null) 'umidade_max': maxHumidity,
  };
  
  /// Calcula risco baseado em temperatura e umidade atuais
  double calculateRisk(double currentTemp, double currentHumidity) {
    double risk = 0.0;
    
    if (minTemperature != null && maxTemperature != null) {
      if (currentTemp >= minTemperature! && currentTemp <= maxTemperature!) {
        risk += 0.4;
      }
    }
    
    if (minHumidity != null && maxHumidity != null) {
      if (currentHumidity >= minHumidity! && currentHumidity <= maxHumidity!) {
        risk += 0.4;
      }
    }
    
    return risk.clamp(0.0, 1.0);
  }
}

/// 3. Ciclo de Vida
class LifeCycle {
  final int? eggsDays;
  final int? larvaDays;
  final int? pupaDays;
  final int? adultDays;
  final int? generationsPerYear;
  final bool? diapause;
  final int? totalDurationDays;
  
  LifeCycle({
    this.eggsDays,
    this.larvaDays,
    this.pupaDays,
    this.adultDays,
    this.generationsPerYear,
    this.diapause,
    this.totalDurationDays,
  });
  
  factory LifeCycle.fromJson(Map<String, dynamic> json) {
    return LifeCycle(
      eggsDays: json['ovos_dias'] as int?,
      larvaDays: json['larva_dias'] as int?,
      pupaDays: json['pupa_dias'] as int?,
      adultDays: json['adulto_dias'] as int?,
      generationsPerYear: json['geracoes_por_ano'] as int?,
      diapause: json['diapausa'] as bool?,
      totalDurationDays: json['duracao_total_dias'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    if (eggsDays != null) 'ovos_dias': eggsDays,
    if (larvaDays != null) 'larva_dias': larvaDays,
    if (pupaDays != null) 'pupa_dias': pupaDays,
    if (adultDays != null) 'adulto_dias': adultDays,
    if (generationsPerYear != null) 'geracoes_por_ano': generationsPerYear,
    if (diapause != null) 'diapausa': diapause,
    if (totalDurationDays != null) 'duracao_total_dias': totalDurationDays,
  };
}

/// 4. Rotação e Resistência
class ResistanceRotation {
  final List<String> iracGroups;
  final List<String> strategies;
  final int? minimumIntervalDays;
  
  ResistanceRotation({
    this.iracGroups = const [],
    this.strategies = const [],
    this.minimumIntervalDays,
  });
  
  factory ResistanceRotation.fromJson(Map<String, dynamic> json) {
    return ResistanceRotation(
      iracGroups: (json['grupos_irac'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      strategies: (json['estrategias'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      minimumIntervalDays: json['intervalo_minimo_dias'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'grupos_irac': iracGroups,
    'estrategias': strategies,
    if (minimumIntervalDays != null) 'intervalo_minimo_dias': minimumIntervalDays,
  };
}

/// 5. Economia Agronômica
class AgronomicEconomics {
  final double? costNoControlPerHa;
  final double? costControlPerHa;
  final double? averageROI;
  final String? optimalApplicationTime;
  
  AgronomicEconomics({
    this.costNoControlPerHa,
    this.costControlPerHa,
    this.averageROI,
    this.optimalApplicationTime,
  });
  
  factory AgronomicEconomics.fromJson(Map<String, dynamic> json) {
    return AgronomicEconomics(
      costNoControlPerHa: (json['custo_nao_controle_por_ha'] as num?)?.toDouble(),
      costControlPerHa: (json['custo_controle_por_ha'] as num?)?.toDouble(),
      averageROI: (json['roi_medio'] as num?)?.toDouble(),
      optimalApplicationTime: json['momento_otimo_aplicacao']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    if (costNoControlPerHa != null) 'custo_nao_controle_por_ha': costNoControlPerHa,
    if (costControlPerHa != null) 'custo_controle_por_ha': costControlPerHa,
    if (averageROI != null) 'roi_medio': averageROI,
    if (optimalApplicationTime != null) 'momento_otimo_aplicacao': optimalApplicationTime,
  };
}

/// 6. Controle Biológico Detalhado
class BiologicalControl {
  final List<String> predators;
  final List<String> parasitoids;
  final List<String> entomopathogens;
  
  BiologicalControl({
    this.predators = const [],
    this.parasitoids = const [],
    this.entomopathogens = const [],
  });
  
  factory BiologicalControl.fromJson(Map<String, dynamic> json) {
    return BiologicalControl(
      predators: (json['predadores'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      parasitoids: (json['parasitoides'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      entomopathogens: (json['entomopatogenos'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'predadores': predators,
    'parasitoides': parasitoids,
    'entomopatogenos': entomopathogens,
  };
}

/// 7. Diagnóstico Diferencial
class DifferentialDiagnosis {
  final List<String> confounders;
  final List<String> keySymptoms;
  
  DifferentialDiagnosis({
    this.confounders = const [],
    this.keySymptoms = const [],
  });
  
  factory DifferentialDiagnosis.fromJson(Map<String, dynamic> json) {
    return DifferentialDiagnosis(
      confounders: (json['confundidores'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      keySymptoms: (json['sintomas_chave'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'confundidores': confounders,
    'sintomas_chave': keySymptoms,
  };
}

/// 8. Tendências Sazonais
class SeasonalTrends {
  final List<String> peakMonths;
  final String? elNinoCorrelation;
  final int? averageDegreeDays;
  
  SeasonalTrends({
    this.peakMonths = const [],
    this.elNinoCorrelation,
    this.averageDegreeDays,
  });
  
  factory SeasonalTrends.fromJson(Map<String, dynamic> json) {
    return SeasonalTrends(
      peakMonths: (json['pico_meses'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      elNinoCorrelation: json['correlacao_elnino']?.toString(),
      averageDegreeDays: json['graus_dia_media'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'pico_meses': peakMonths,
    if (elNinoCorrelation != null) 'correlacao_elnino': elNinoCorrelation,
    if (averageDegreeDays != null) 'graus_dia_media': averageDegreeDays,
  };
}

/// 9. Features IA
class IAFeatures {
  final List<String> behavioralKeywords;
  final List<String> visualMarkers;
  
  IAFeatures({
    this.behavioralKeywords = const [],
    this.visualMarkers = const [],
  });
  
  factory IAFeatures.fromJson(Map<String, dynamic> json) {
    return IAFeatures(
      behavioralKeywords: (json['keywords_comportamentais'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      visualMarkers: (json['marcadores_visuais'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'keywords_comportamentais': behavioralKeywords,
    'marcadores_visuais': visualMarkers,
  };
}

/// 10. Fontes de Referência
class FontesReferencia {
  final List<String> fontesPrincipais;
  final List<Map<String, String>> fontesEspecificas;
  final String? notaLicenca;
  final String? ultimaAtualizacao;
  
  FontesReferencia({
    this.fontesPrincipais = const [],
    this.fontesEspecificas = const [],
    this.notaLicenca,
    this.ultimaAtualizacao,
  });
  
  factory FontesReferencia.fromJson(Map<String, dynamic> json) {
    return FontesReferencia(
      fontesPrincipais: (json['fontes_principais'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
      fontesEspecificas: (json['fontes_especificas'] as List?)
        ?.map((e) => Map<String, String>.from(e as Map)).toList() ?? [],
      notaLicenca: json['nota_licenca']?.toString(),
      ultimaAtualizacao: json['ultima_atualizacao']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'fontes_principais': fontesPrincipais,
    'fontes_especificas': fontesEspecificas,
    if (notaLicenca != null) 'nota_licenca': notaLicenca,
    if (ultimaAtualizacao != null) 'ultima_atualizacao': ultimaAtualizacao,
  };
}

