import 'package:uuid/uuid.dart';

/// Modelo para armazenar os dados de calibragem de adubo
class CalibragemAduboModel {
  final String? id;
  final String? nomeFertilizante;
  final double distancia;
  final int linhas;
  final double pesoColetado;
  final double espacamento;
  final double metaKgHa;
  final double kgPorMetro;
  final double kgPorHectare;
  final double diferencaMeta;
  final String? talhaoId;
  final String? culturaId;
  final DateTime dataRegistro;

  CalibragemAduboModel({
    this.id,
    this.nomeFertilizante,
    required this.distancia,
    required this.linhas,
    required this.pesoColetado,
    required this.espacamento,
    required this.metaKgHa,
    required this.kgPorMetro,
    required this.kgPorHectare,
    required this.diferencaMeta,
    this.talhaoId,
    this.culturaId,
    DateTime? dataRegistro,
  }) : dataRegistro = dataRegistro ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos alterados
  CalibragemAduboModel copyWith({
    String? id,
    String? nomeFertilizante,
    double? distancia,
    int? linhas,
    double? pesoColetado,
    double? espacamento,
    double? metaKgHa,
    double? kgPorMetro,
    double? kgPorHectare,
    double? diferencaMeta,
    String? talhaoId,
    String? culturaId,
    DateTime? dataRegistro,
  }) {
    return CalibragemAduboModel(
      id: id ?? this.id,
      nomeFertilizante: nomeFertilizante ?? this.nomeFertilizante,
      distancia: distancia ?? this.distancia,
      linhas: linhas ?? this.linhas,
      pesoColetado: pesoColetado ?? this.pesoColetado,
      espacamento: espacamento ?? this.espacamento,
      metaKgHa: metaKgHa ?? this.metaKgHa,
      kgPorMetro: kgPorMetro ?? this.kgPorMetro,
      kgPorHectare: kgPorHectare ?? this.kgPorHectare,
      diferencaMeta: diferencaMeta ?? this.diferencaMeta,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      dataRegistro: dataRegistro ?? this.dataRegistro,
    );
  }

  /// Converte o modelo para um Map para armazenar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'nome_fertilizante': nomeFertilizante,
      'distancia': distancia,
      'linhas': linhas,
      'peso_coletado': pesoColetado,
      'espacamento': espacamento,
      'meta_kg_ha': metaKgHa,
      'kg_por_metro': kgPorMetro,
      'kg_por_hectare': kgPorHectare,
      'diferenca_meta': diferencaMeta,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'data_registro': dataRegistro.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um Map vindo do banco de dados
  factory CalibragemAduboModel.fromMap(Map<String, dynamic> map) {
    return CalibragemAduboModel(
      id: map['id'],
      nomeFertilizante: map['nome_fertilizante'],
      distancia: map['distancia']?.toDouble() ?? 0.0,
      linhas: map['linhas']?.toInt() ?? 1,
      pesoColetado: map['peso_coletado']?.toDouble() ?? 0.0,
      espacamento: map['espacamento']?.toDouble() ?? 45.0,
      metaKgHa: map['meta_kg_ha']?.toDouble() ?? 300.0,
      kgPorMetro: map['kg_por_metro']?.toDouble() ?? 0.0,
      kgPorHectare: map['kg_por_hectare']?.toDouble() ?? 0.0,
      diferencaMeta: map['diferenca_meta']?.toDouble() ?? 0.0,
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      dataRegistro: map['data_registro'] != null
          ? DateTime.parse(map['data_registro'])
          : DateTime.now(),
    );
  }
}
