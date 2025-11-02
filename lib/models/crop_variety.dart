import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo para representar uma variedade de cultura
class CropVariety {
  String get nome => name;
  final String id;
  final String cropId; // ID da cultura
  final String name; // Nome da variedade
  final String? company; // Empresa desenvolvedora
  final int? cycleDays; // Ciclo em dias
  final String? description; // Descrição
  final String? characteristics; // Características da variedade
  final double? yieldValue; // Produtividade esperada
  final double? recommendedPopulation; // População recomendada (plantas/ha)
  final double? weightOf1000Seeds; // Peso de mil sementes (gramas)
  final String? notes; // Notas adicionais
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  CropVariety({
    String? id,
    required this.cropId,
    required this.name,
    this.company,
    this.cycleDays,
    this.description,
    this.characteristics,
    this.yieldValue,
    this.recommendedPopulation,
    this.weightOf1000Seeds,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  CropVariety copyWith({
    String? id,
    String? cropId,
    String? name,
    String? company,
    int? cycleDays,
    String? description,
    double? recommendedPopulation,
    double? weightOf1000Seeds,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return CropVariety(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      name: name ?? this.name,
      company: company ?? this.company,
      cycleDays: cycleDays ?? this.cycleDays,
      description: description ?? this.description,
      recommendedPopulation: recommendedPopulation ?? this.recommendedPopulation,
      weightOf1000Seeds: weightOf1000Seeds ?? this.weightOf1000Seeds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'name': name,
      'company': company,
      'cycleDays': cycleDays,
      'description': description,
      'recommendedPopulation': recommendedPopulation,
      'weightOf1000Seeds': weightOf1000Seeds,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory CropVariety.fromMap(Map<String, dynamic> map) {
    return CropVariety(
      id: map['id']?.toString() ?? '',
      cropId: map['cropId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      company: map['company']?.toString(),
      cycleDays: map['cycleDays'] is int ? map['cycleDays'] : 
                 map['cycleDays'] is String ? int.tryParse(map['cycleDays']) : null,
      description: map['description']?.toString(),
      recommendedPopulation: map['recommendedPopulation'] != null ? 
          (map['recommendedPopulation'] is int ? 
              map['recommendedPopulation'].toDouble() : 
              map['recommendedPopulation'] is double ? map['recommendedPopulation'] :
              map['recommendedPopulation'] is String ? double.tryParse(map['recommendedPopulation']) : null) : 
          null,
      weightOf1000Seeds: map['weightOf1000Seeds'] != null ? 
          (map['weightOf1000Seeds'] is int ? 
              map['weightOf1000Seeds'].toDouble() : 
              map['weightOf1000Seeds'] is double ? map['weightOf1000Seeds'] :
              map['weightOf1000Seeds'] is String ? double.tryParse(map['weightOf1000Seeds']) : null) : 
          null,
      notes: map['notes']?.toString(),
      createdAt: map['createdAt'] != null ? 
          (map['createdAt'] is DateTime ? map['createdAt'] : 
           map['createdAt'] is String ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : 
           DateTime.now()) : 
          DateTime.now(),
      updatedAt: map['updatedAt'] != null ? 
          (map['updatedAt'] is DateTime ? map['updatedAt'] : 
           map['updatedAt'] is String ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now() : 
           DateTime.now()) : 
          DateTime.now(),
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory CropVariety.fromJson(String source) => 
      CropVariety.fromMap(jsonDecode(source));
      
  /// Retorna o ciclo formatado
  String getFormattedCycle() {
    if (cycleDays == null) return 'Não informado';
    return '$cycleDays dias';
  }
  
  /// Retorna a população recomendada formatada
  String getFormattedRecommendedPopulation() {
    if (recommendedPopulation == null) return 'Não informado';
    return '${recommendedPopulation!.toStringAsFixed(0)} plantas/ha';
  }
  
  /// Retorna o peso de mil sementes formatado
  String getFormattedWeightOf1000Seeds() {
    if (weightOf1000Seeds == null) return 'Não informado';
    return '${weightOf1000Seeds!.toStringAsFixed(2)} g';
  }
}
