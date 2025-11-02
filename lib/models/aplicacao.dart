import 'package:uuid/uuid.dart';

class Aplicacao {
  final String id;
  final String talhaoId;
  final String produtoId;
  final double dosePorHa;
  final double areaAplicadaHa;
  final double precoUnitarioMomento;
  final DateTime dataAplicacao;
  final String? operador;
  final String? equipamento;
  final String? condicoesClimaticas;
  final String? observacoes;
  final String? fazendaId;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final bool isSincronizado;

  // Campos calculados
  double get quantidadeTotal => dosePorHa * areaAplicadaHa;
  double get custoTotal => quantidadeTotal * precoUnitarioMomento;
  double get custoPorHa => custoTotal / areaAplicadaHa;

  Aplicacao({
    String? id,
    required this.talhaoId,
    required this.produtoId,
    required this.dosePorHa,
    required this.areaAplicadaHa,
    required this.precoUnitarioMomento,
    required this.dataAplicacao,
    this.operador,
    this.equipamento,
    this.condicoesClimaticas,
    this.observacoes,
    this.fazendaId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    this.isSincronizado = false,
  }) : 
    id = id ?? const Uuid().v4(),
    dataCriacao = dataCriacao ?? DateTime.now(),
    dataAtualizacao = dataAtualizacao ?? DateTime.now();

  factory Aplicacao.fromMap(Map<String, dynamic> map) {
    return Aplicacao(
      id: map['id_aplicacao'] ?? map['id'],
      talhaoId: map['id_talhao'] ?? map['talhaoId'],
      produtoId: map['id_produto'] ?? map['produtoId'],
      dosePorHa: (map['dose_por_ha'] as num?)?.toDouble() ?? 0.0,
      areaAplicadaHa: (map['area_aplicada_ha'] as num?)?.toDouble() ?? 0.0,
      precoUnitarioMomento: (map['preco_unitario_momento'] as num?)?.toDouble() ?? 0.0,
      dataAplicacao: DateTime.parse(map['data_aplicacao']),
      operador: map['operador'],
      equipamento: map['equipamento'],
      condicoesClimaticas: map['condicoes_climaticas'],
      observacoes: map['observacoes'],
      fazendaId: map['fazenda_id'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      dataAtualizacao: DateTime.parse(map['data_atualizacao']),
      isSincronizado: map['is_sincronizado'] == 1 || map['is_sincronizado'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_aplicacao': id,
      'id_talhao': talhaoId,
      'id_produto': produtoId,
      'dose_por_ha': dosePorHa,
      'area_aplicada_ha': areaAplicadaHa,
      'preco_unitario_momento': precoUnitarioMomento,
      'data_aplicacao': dataAplicacao.toIso8601String(),
      'operador': operador,
      'equipamento': equipamento,
      'condicoes_climaticas': condicoesClimaticas,
      'observacoes': observacoes,
      'fazenda_id': fazendaId,
      'data_criacao': dataCriacao.toIso8601String(),
      'data_atualizacao': dataAtualizacao.toIso8601String(),
      'is_sincronizado': isSincronizado ? 1 : 0,
    };
  }

  Aplicacao copyWith({
    String? talhaoId,
    String? produtoId,
    double? dosePorHa,
    double? areaAplicadaHa,
    double? precoUnitarioMomento,
    DateTime? dataAplicacao,
    String? operador,
    String? equipamento,
    String? condicoesClimaticas,
    String? observacoes,
    String? fazendaId,
    bool? isSincronizado,
  }) {
    return Aplicacao(
      id: id,
      talhaoId: talhaoId ?? this.talhaoId,
      produtoId: produtoId ?? this.produtoId,
      dosePorHa: dosePorHa ?? this.dosePorHa,
      areaAplicadaHa: areaAplicadaHa ?? this.areaAplicadaHa,
      precoUnitarioMomento: precoUnitarioMomento ?? this.precoUnitarioMomento,
      dataAplicacao: dataAplicacao ?? this.dataAplicacao,
      operador: operador ?? this.operador,
      equipamento: equipamento ?? this.equipamento,
      condicoesClimaticas: condicoesClimaticas ?? this.condicoesClimaticas,
      observacoes: observacoes ?? this.observacoes,
      fazendaId: fazendaId ?? this.fazendaId,
      dataCriacao: dataCriacao,
      dataAtualizacao: DateTime.now(),
      isSincronizado: isSincronizado ?? this.isSincronizado,
    );
  }

  @override
  String toString() {
    return 'Aplicacao(id: $id, talhaoId: $talhaoId, produtoId: $produtoId, dosePorHa: $dosePorHa, custoTotal: $custoTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Aplicacao && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
