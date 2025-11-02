import 'package:flutter/material.dart';

/// Modelo para uma cultura completa com todos os organismos
class NewCulture {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final Color color;
  final List<Organism> pests;
  final List<Organism> diseases;
  final List<Organism> weeds;
  final List<Variety> varieties;

  NewCulture({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.color,
    this.pests = const [],
    this.diseases = const [],
    this.weeds = const [],
    this.varieties = const [],
  });

  factory NewCulture.fromJson(Map<String, dynamic> json) {
    return NewCulture(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'] ?? '',
      color: _parseColor(json['color']),
      pests: (json['pests'] as List<dynamic>?)
          ?.map((pest) => Organism.fromJson(pest))
          .toList() ?? [],
      diseases: (json['diseases'] as List<dynamic>?)
          ?.map((disease) => Organism.fromJson(disease))
          .toList() ?? [],
      weeds: (json['weeds'] as List<dynamic>?)
          ?.map((weed) => Organism.fromJson(weed))
          .toList() ?? [],
      varieties: (json['varieties'] as List<dynamic>?)
          ?.map((variety) => Variety.fromJson(variety))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'color': color.value,
      'pests': pests.map((pest) => pest.toJson()).toList(),
      'diseases': diseases.map((disease) => disease.toJson()).toList(),
      'weeds': weeds.map((weed) => weed.toJson()).toList(),
      'varieties': varieties.map((variety) => variety.toJson()).toList(),
    };
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue is int) {
      return Color(colorValue);
    } else if (colorValue is String) {
      // Converter hex string para Color
      final hex = colorValue.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.green; // Cor padrão
  }
}

/// Modelo para organismos (pragas, doenças, plantas daninhas)
class Organism {
  final String id;
  final String name;
  final String scientificName;
  final String category; // 'Praga', 'Doença', 'Planta Daninha'
  final String description;
  final List<String> symptoms;
  final String economicDamage;
  final List<String> affectedParts;
  final List<String> phenology;
  final String lifeCycle;
  final String growthHabit;
  final String maxHeight;
  final String leafType;
  final String leafColor;
  final String rootType;
  final String reproduction;
  final String dispersal;
  final Map<String, String> favorableConditions;
  final Map<String, String> specificThresholds;

  Organism({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.description,
    this.symptoms = const [],
    this.economicDamage = '',
    this.affectedParts = const [],
    this.phenology = const [],
    this.lifeCycle = '',
    this.growthHabit = '',
    this.maxHeight = '',
    this.leafType = '',
    this.leafColor = '',
    this.rootType = '',
    this.reproduction = '',
    this.dispersal = '',
    this.favorableConditions = const {},
    this.specificThresholds = const {},
  });

  factory Organism.fromJson(Map<String, dynamic> json) {
    return Organism(
      id: json['id'] ?? '',
      name: json['nome'] ?? json['name'] ?? '',
      scientificName: json['nome_cientifico'] ?? json['scientificName'] ?? '',
      category: json['categoria'] ?? json['category'] ?? '',
      description: json['descricao'] ?? json['description'] ?? '',
      symptoms: (json['sintomas'] as List<dynamic>?)
          ?.map((s) => s.toString())
          .toList() ?? [],
      economicDamage: json['dano_economico'] ?? json['economicDamage'] ?? '',
      affectedParts: (json['partes_afetadas'] as List<dynamic>?)
          ?.map((p) => p.toString())
          .toList() ?? [],
      phenology: (json['fenologia'] as List<dynamic>?)
          ?.map((p) => p.toString())
          .toList() ?? [],
      lifeCycle: json['ciclo_vida'] ?? json['lifeCycle'] ?? '',
      growthHabit: json['habito_crescimento'] ?? json['growthHabit'] ?? '',
      maxHeight: json['altura_maxima'] ?? json['maxHeight'] ?? '',
      leafType: json['tipo_folha'] ?? json['leafType'] ?? '',
      leafColor: json['cor_folha'] ?? json['leafColor'] ?? '',
      rootType: json['tipo_raiz'] ?? json['rootType'] ?? '',
      reproduction: json['reproducao'] ?? json['reproduction'] ?? '',
      dispersal: json['dispersao'] ?? json['dispersal'] ?? '',
      favorableConditions: Map<String, String>.from(
        json['condicoes_favoraveis'] ?? json['favorableConditions'] ?? {}
      ),
      specificThresholds: Map<String, String>.from(
        json['limiares_especificos'] ?? json['specificThresholds'] ?? {}
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': name,
      'nome_cientifico': scientificName,
      'categoria': category,
      'descricao': description,
      'sintomas': symptoms,
      'dano_economico': economicDamage,
      'partes_afetadas': affectedParts,
      'fenologia': phenology,
      'ciclo_vida': lifeCycle,
      'habito_crescimento': growthHabit,
      'altura_maxima': maxHeight,
      'tipo_folha': leafType,
      'cor_folha': leafColor,
      'tipo_raiz': rootType,
      'reproducao': reproduction,
      'dispersao': dispersal,
      'condicoes_favoraveis': favorableConditions,
      'limiares_especificos': specificThresholds,
    };
  }
}

/// Modelo para variedades
class Variety {
  final String id;
  final String name;
  final String description;
  final int? cycleDays;
  final String notes;

  Variety({
    required this.id,
    required this.name,
    this.description = '',
    this.cycleDays,
    this.notes = '',
  });

  factory Variety.fromJson(Map<String, dynamic> json) {
    return Variety(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cycleDays: json['cycleDays'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cycleDays': cycleDays,
      'notes': notes,
    };
  }
}
