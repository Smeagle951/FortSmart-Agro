import 'package:uuid/uuid.dart';

/// Modelo para representar uma variedade de cultura
class VariedadeModel {
  final String id;
  final String nome;
  final String culturaId;
  final String? descricao;
  final int? cicloDias;
  final double? pesoMilSementes;
  final double? germinacaoPercentual;
  final double? vigorPercentual;
  final double? purezaPercentual;
  final String? observacoes;
  final bool sincronizado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  VariedadeModel({
    String? id,
    required this.nome,
    required this.culturaId,
    this.descricao,
    this.cicloDias,
    this.pesoMilSementes,
    this.germinacaoPercentual,
    this.vigorPercentual,
    this.purezaPercentual,
    this.observacoes,
    this.sincronizado = false,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.criadoEm = criadoEm ?? DateTime.now(),
    this.atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  VariedadeModel copyWith({
    String? id,
    String? nome,
    String? culturaId,
    String? descricao,
    int? cicloDias,
    double? pesoMilSementes,
    double? germinacaoPercentual,
    double? vigorPercentual,
    double? purezaPercentual,
    String? observacoes,
    bool? sincronizado,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return VariedadeModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      culturaId: culturaId ?? this.culturaId,
      descricao: descricao ?? this.descricao,
      cicloDias: cicloDias ?? this.cicloDias,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      germinacaoPercentual: germinacaoPercentual ?? this.germinacaoPercentual,
      vigorPercentual: vigorPercentual ?? this.vigorPercentual,
      purezaPercentual: purezaPercentual ?? this.purezaPercentual,
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
      'nome': nome,
      'cultura_id': culturaId,
      'descricao': descricao,
      'ciclo_dias': cicloDias,
      'peso_mil_sementes': pesoMilSementes,
      'germinacao_percentual': germinacaoPercentual,
      'vigor_percentual': vigorPercentual,
      'pureza_percentual': purezaPercentual,
      'observacoes': observacoes,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory VariedadeModel.fromMap(Map<String, dynamic> map) {
    return VariedadeModel(
      id: map['id'],
      nome: map['nome'],
      culturaId: map['cultura_id'],
      descricao: map['descricao'],
      cicloDias: map['ciclo_dias'],
      pesoMilSementes: map['peso_mil_sementes'],
      germinacaoPercentual: map['germinacao_percentual'],
      vigorPercentual: map['vigor_percentual'],
      purezaPercentual: map['pureza_percentual'],
      observacoes: map['observacoes'],
      sincronizado: map['sincronizado'] == 1,
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
    );
  }
}
