import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Tipo de produto agrícola
enum ProductType {
  herbicide,    // Herbicida
  insecticide,  // Inseticida
  fungicide,    // Fungicida
  fertilizer,   // Fertilizante
  growth,       // Regulador de crescimento
  adjuvant,     // Adjuvante
  seed,         // Semente
  other,        // Outro
}

/// Modelo para representar um produto agrícola
class AgriculturalProduct {
  final String id;
  final String name; // Nome comercial
  final String? manufacturer; // Fabricante
  final ProductType type; // Tipo de produto
  final String? activeIngredient; // Ingrediente ativo
  final String? concentration; // Concentração
  final String? formulation; // Formulação
  final String? registrationNumber; // Número de registro
  final String? safetyInterval; // Intervalo de segurança
  final String? applicationInstructions; // Instruções de aplicação
  final String? dosageRecommendation; // Recomendação de dosagem
  final String? notes; // Observações
  final int? parentId; // ID do produto pai (para variedades de culturas)
  final List<String>? tags; // Tags para categorização e filtragem
  final String? iconPath; // Caminho para o ícone da cultura
  final String? colorValue; // Valor da cor em formato hexadecimal
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? fazendaId; // ID da fazenda à qual o produto está associado

  /// Getter para categoria baseada no tipo
  String get category {
    switch (type) {
      case ProductType.herbicide:
        return 'Herbicida';
      case ProductType.insecticide:
        return 'Inseticida';
      case ProductType.fungicide:
        return 'Fungicida';
      case ProductType.fertilizer:
        return 'Fertilizante';
      case ProductType.growth:
        return 'Regulador de Crescimento';
      case ProductType.adjuvant:
        return 'Adjuvante';
      case ProductType.seed:
        return 'Semente';
      case ProductType.other:
        return 'Outro';
    }
  }

  AgriculturalProduct({
    String? id,
    required this.name,
    this.manufacturer,
    required this.type,
    this.activeIngredient,
    this.concentration,
    this.formulation,
    this.registrationNumber,
    this.safetyInterval,
    this.applicationInstructions,
    this.dosageRecommendation,
    this.notes,
    this.parentId,
    this.tags,
    this.iconPath,
    this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false, this.fazendaId, String? description, String? scientificName,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  AgriculturalProduct copyWith({
    String? id,
    String? name,
    String? manufacturer,
    ProductType? type,
    String? activeIngredient,
    String? concentration,
    String? formulation,
    String? registrationNumber,
    String? safetyInterval,
    String? applicationInstructions,
    String? dosageRecommendation,
    String? notes,
    int? parentId,
    List<String>? tags,
    String? iconPath,
    String? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? fazendaId,
  }) {
    return AgriculturalProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      type: type ?? this.type,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      concentration: concentration ?? this.concentration,
      formulation: formulation ?? this.formulation,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      safetyInterval: safetyInterval ?? this.safetyInterval,
      applicationInstructions: applicationInstructions ?? this.applicationInstructions,
      dosageRecommendation: dosageRecommendation ?? this.dosageRecommendation,
      notes: notes ?? this.notes,
      parentId: parentId ?? this.parentId,
      tags: tags ?? this.tags,
      iconPath: iconPath ?? this.iconPath,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      fazendaId: fazendaId ?? this.fazendaId,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'category': type.index, // Mapear 'type' para 'category' para compatibilidade com o banco
      'type': type.index, // Manter 'type' para compatibilidade com o modelo
      'activeIngredient': activeIngredient,
      'concentration': concentration,
      'formulation': formulation,
      'registrationNumber': registrationNumber,
      'safetyInterval': safetyInterval,
      'applicationInstructions': applicationInstructions,
      'dosageRecommendation': dosageRecommendation,
      'notes': notes,
      'parentId': parentId,
      'tags': tags != null ? jsonEncode(tags) : null,
      'iconPath': iconPath,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'fazendaId': fazendaId,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory AgriculturalProduct.fromMap(Map<String, dynamic> map) {
    // Tentar ler 'type' primeiro, depois 'category' para compatibilidade
    final typeIndex = map['type'] ?? map['category'];
    return AgriculturalProduct(
      id: map['id'],
      name: map['name'],
      manufacturer: map['manufacturer'],
      type: ProductType.values[typeIndex],
      activeIngredient: map['activeIngredient'],
      concentration: map['concentration'],
      formulation: map['formulation'],
      registrationNumber: map['registrationNumber'],
      safetyInterval: map['safetyInterval'],
      applicationInstructions: map['applicationInstructions'],
      dosageRecommendation: map['dosageRecommendation'],
      notes: map['notes'],
      parentId: map['parentId'],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : null,
      iconPath: map['iconPath'],
      colorValue: map['colorValue'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
      fazendaId: map['fazendaId'],
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory AgriculturalProduct.fromJson(String source) => 
      AgriculturalProduct.fromMap(jsonDecode(source));

  get description => null;

  get scientificName => null;
  
  /// Retorna o tipo de produto como string
  String getTypeString() {
    switch (type) {
      case ProductType.herbicide:
        return 'Herbicida';
      case ProductType.insecticide:
        return 'Inseticida';
      case ProductType.fungicide:
        return 'Fungicida';
      case ProductType.fertilizer:
        return 'Fertilizante';
      case ProductType.growth:
        return 'Regulador de crescimento';
      case ProductType.adjuvant:
        return 'Adjuvante';
      case ProductType.seed:
        return 'Semente';
      case ProductType.other:
        return 'Outro';
      default:
        return 'Desconhecido';
    }
  }
  
  /// Retorna a descrição completa do produto
  String getFullDescription() {
    final List<String> parts = [];
    
    if (manufacturer != null && manufacturer!.isNotEmpty) {
      parts.add('$manufacturer $name');
    } else {
      parts.add(name);
    }
    
    if (activeIngredient != null && activeIngredient!.isNotEmpty) {
      parts.add('Princípio ativo: $activeIngredient');
    }
    
    if (concentration != null && concentration!.isNotEmpty) {
      parts.add('Concentração: $concentration');
    }
    
    if (formulation != null && formulation!.isNotEmpty) {
      parts.add('Formulação: $formulation');
    }
    
    return parts.join(' | ');
  }
  
  /// Retorna as informações de segurança do produto
  String getSafetyInformation() {
    final List<String> info = [];
    
    if (safetyInterval != null && safetyInterval!.isNotEmpty) {
      info.add('Intervalo de segurança: $safetyInterval');
    }
    
    // Adicionar informações de segurança padrão com base no tipo
    switch (type) {
      case ProductType.herbicide:
      case ProductType.insecticide:
      case ProductType.fungicide:
        info.add('Utilize EPI completo durante o manuseio e aplicação.');
        info.add('Mantenha fora do alcance de crianças e animais domésticos.');
        info.add('Evite contato com a pele e olhos.');
        info.add('Em caso de intoxicação, procure assistência médica imediatamente.');
        break;
      case ProductType.fertilizer:
        info.add('Utilize luvas e máscara durante o manuseio.');
        info.add('Evite inalação prolongada.');
        break;
      default:
        info.add('Siga as recomendações de segurança do fabricante.');
        break;
    }
    
    return info.join('\n');
  }
}
