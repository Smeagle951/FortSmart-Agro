import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SoilCompactionModel {
  final String id;
  final String? talhaoId;
  final String? talhaoNome;
  final String? safraId;
  final String? safraNome;
  final double? profundidade; // em cm
  final double? diametroCone; // em mm²
  final double? forcaAplicada; // em kgf
  final double? resistenciaPenetracao; // em MPa (calculado)
  final String? interpretacao; // Baixa, Média, Alta, Muito Alta
  final Color? cor; // Cor da interpretação
  final DateTime dataCalculo;
  final double? latitude;
  final double? longitude;
  final String? observacoes;

  SoilCompactionModel({
    String? id,
    this.talhaoId,
    this.talhaoNome,
    this.safraId,
    this.safraNome,
    this.profundidade,
    this.diametroCone,
    this.forcaAplicada,
    this.resistenciaPenetracao,
    this.interpretacao,
    this.cor,
    DateTime? dataCalculo,
    this.latitude,
    this.longitude,
    this.observacoes,
  })  : id = id ?? const Uuid().v4(),
        dataCalculo = dataCalculo ?? DateTime.now();

  // Método para converter o modelo para um Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'talhaoNome': talhaoNome,
      'safraId': safraId,
      'safraNome': safraNome,
      'profundidade': profundidade,
      'diametroCone': diametroCone,
      'forcaAplicada': forcaAplicada,
      'resistenciaPenetracao': resistenciaPenetracao,
      'interpretacao': interpretacao,
      'cor': cor?.value,
      'dataCalculo': dataCalculo.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'observacoes': observacoes,
    };
  }

  // Método para criar um modelo a partir de um Map (para carregar do banco de dados)
  factory SoilCompactionModel.fromMap(Map<String, dynamic> map) {
    return SoilCompactionModel(
      id: map['id'],
      talhaoId: map['talhaoId'],
      talhaoNome: map['talhaoNome'],
      safraId: map['safraId'],
      safraNome: map['safraNome'],
      profundidade: map['profundidade'],
      diametroCone: map['diametroCone'],
      forcaAplicada: map['forcaAplicada'],
      resistenciaPenetracao: map['resistenciaPenetracao'],
      interpretacao: map['interpretacao'],
      cor: map['cor'] != null ? Color(map['cor']) : null,
      dataCalculo: map['dataCalculo'] != null 
          ? DateTime.parse(map['dataCalculo']) 
          : DateTime.now(),
      latitude: map['latitude'],
      longitude: map['longitude'],
      observacoes: map['observacoes'],
    );
  }

  // Método para criar uma cópia do modelo com algumas alterações
  SoilCompactionModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    String? safraId,
    String? safraNome,
    double? profundidade,
    double? diametroCone,
    double? forcaAplicada,
    double? resistenciaPenetracao,
    String? interpretacao,
    Color? cor,
    DateTime? dataCalculo,
    double? latitude,
    double? longitude,
    String? observacoes,
  }) {
    return SoilCompactionModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      safraId: safraId ?? this.safraId,
      safraNome: safraNome ?? this.safraNome,
      profundidade: profundidade ?? this.profundidade,
      diametroCone: diametroCone ?? this.diametroCone,
      forcaAplicada: forcaAplicada ?? this.forcaAplicada,
      resistenciaPenetracao: resistenciaPenetracao ?? this.resistenciaPenetracao,
      interpretacao: interpretacao ?? this.interpretacao,
      cor: cor ?? this.cor,
      dataCalculo: dataCalculo ?? this.dataCalculo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}
