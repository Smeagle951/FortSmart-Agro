import 'package:uuid/uuid.dart';

/// Modelo para representar uma calibragem de adubo
class CalibragemAduboModel {
  final String id;
  final String talhaoId;
  final String culturaId;
  final String tratorId;
  final String plantadeiraId;
  final DateTime dataCalibragem;
  final String tipoAdubo;
  final double quantidadeHectare;
  final double velocidadeTrabalho;
  final double larguraTrabalho;
  final int tempoColeta;
  final double quantidadeColetada;
  final double quantidadeCalculada;
  final double diferencaPercentual;
  final String? observacoes;
  final bool sincronizado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  CalibragemAduboModel({
    String? id,
    required this.talhaoId,
    required this.culturaId,
    required this.tratorId,
    required this.plantadeiraId,
    required this.dataCalibragem,
    required this.tipoAdubo,
    required this.quantidadeHectare,
    required this.velocidadeTrabalho,
    required this.larguraTrabalho,
    required this.tempoColeta,
    required this.quantidadeColetada,
    required this.quantidadeCalculada,
    required this.diferencaPercentual,
    this.observacoes,
    this.sincronizado = false,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.criadoEm = criadoEm ?? DateTime.now(),
    this.atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  CalibragemAduboModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    String? tratorId,
    String? plantadeiraId,
    DateTime? dataCalibragem,
    String? tipoAdubo,
    double? quantidadeHectare,
    double? velocidadeTrabalho,
    double? larguraTrabalho,
    int? tempoColeta,
    double? quantidadeColetada,
    double? quantidadeCalculada,
    double? diferencaPercentual,
    String? observacoes,
    bool? sincronizado,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return CalibragemAduboModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      tratorId: tratorId ?? this.tratorId,
      plantadeiraId: plantadeiraId ?? this.plantadeiraId,
      dataCalibragem: dataCalibragem ?? this.dataCalibragem,
      tipoAdubo: tipoAdubo ?? this.tipoAdubo,
      quantidadeHectare: quantidadeHectare ?? this.quantidadeHectare,
      velocidadeTrabalho: velocidadeTrabalho ?? this.velocidadeTrabalho,
      larguraTrabalho: larguraTrabalho ?? this.larguraTrabalho,
      tempoColeta: tempoColeta ?? this.tempoColeta,
      quantidadeColetada: quantidadeColetada ?? this.quantidadeColetada,
      quantidadeCalculada: quantidadeCalculada ?? this.quantidadeCalculada,
      diferencaPercentual: diferencaPercentual ?? this.diferencaPercentual,
      observacoes: observacoes ?? this.observacoes,
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
      'trator_id': tratorId,
      'plantadeira_id': plantadeiraId,
      'data_calibragem': dataCalibragem.toIso8601String(),
      'tipo_adubo': tipoAdubo,
      'quantidade_hectare': quantidadeHectare,
      'velocidade_trabalho': velocidadeTrabalho,
      'largura_trabalho': larguraTrabalho,
      'tempo_coleta': tempoColeta,
      'quantidade_coletada': quantidadeColetada,
      'quantidade_calculada': quantidadeCalculada,
      'diferenca_percentual': diferencaPercentual,
      'observacoes': observacoes,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory CalibragemAduboModel.fromMap(Map<String, dynamic> map) {
    return CalibragemAduboModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      tratorId: map['trator_id'],
      plantadeiraId: map['plantadeira_id'],
      dataCalibragem: DateTime.parse(map['data_calibragem']),
      tipoAdubo: map['tipo_adubo'],
      quantidadeHectare: map['quantidade_hectare'],
      velocidadeTrabalho: map['velocidade_trabalho'],
      larguraTrabalho: map['largura_trabalho'],
      tempoColeta: map['tempo_coleta'],
      quantidadeColetada: map['quantidade_coletada'],
      quantidadeCalculada: map['quantidade_calculada'],
      diferencaPercentual: map['diferenca_percentual'],
      observacoes: map['observacoes'],
      sincronizado: map['sincronizado'] == 1,
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
    );
  }
}
