import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Modelo para representar uma avaliação de estande de plantas
class EstandeModel {
  final String id;
  final String talhaoId;
  final String culturaId;
  final DateTime dataAvaliacao;
  final double metrosAvaliados;
  final int plantasContadas;
  final double plantasPorMetro;
  final int plantasPorHectare;
  final String? observacoes;
  final List<String>? fotos;
  final double? latitude;
  final double? longitude;
  final bool sincronizado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  EstandeModel({
    String? id,
    required this.talhaoId,
    required this.culturaId,
    required this.dataAvaliacao,
    required this.metrosAvaliados,
    required this.plantasContadas,
    required this.plantasPorMetro,
    required this.plantasPorHectare,
    this.observacoes,
    this.fotos,
    this.latitude,
    this.longitude,
    this.sincronizado = false,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.criadoEm = criadoEm ?? DateTime.now(),
    this.atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  EstandeModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    DateTime? dataAvaliacao,
    double? metrosAvaliados,
    int? plantasContadas,
    double? plantasPorMetro,
    int? plantasPorHectare,
    String? observacoes,
    List<String>? fotos,
    double? latitude,
    double? longitude,
    bool? sincronizado,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return EstandeModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      metrosAvaliados: metrosAvaliados ?? this.metrosAvaliados,
      plantasContadas: plantasContadas ?? this.plantasContadas,
      plantasPorMetro: plantasPorMetro ?? this.plantasPorMetro,
      plantasPorHectare: plantasPorHectare ?? this.plantasPorHectare,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sincronizado: sincronizado ?? this.sincronizado,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? DateTime.now(),
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'data_avaliacao': dataAvaliacao.toIso8601String(),
      'metros_avaliados': metrosAvaliados,
      'plantas_contadas': plantasContadas,
      'plantas_por_metro': plantasPorMetro,
      'plantas_por_hectare': plantasPorHectare,
      'observacoes': observacoes,
      'fotos': fotos != null ? jsonEncode(fotos) : null,
      'latitude': latitude,
      'longitude': longitude,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory EstandeModel.fromMap(Map<String, dynamic> map) {
    return EstandeModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      dataAvaliacao: DateTime.parse(map['data_avaliacao']),
      metrosAvaliados: map['metros_avaliados'],
      plantasContadas: map['plantas_contadas'],
      plantasPorMetro: map['plantas_por_metro'],
      plantasPorHectare: map['plantas_por_hectare'],
      observacoes: map['observacoes'],
      fotos: map['fotos'] != null ? List<String>.from(jsonDecode(map['fotos'])) : null,
      latitude: map['latitude'],
      longitude: map['longitude'],
      sincronizado: map['sincronizado'] == 1,
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
    );
  }
}
