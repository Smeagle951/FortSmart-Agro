class ExperimentoModel {
  final String? id;
  final String nome;
  final String talhaoId;
  final String? culturaId;
  final String? variedadeId;
  final String? safraId; // Adicionado safraId para rastreabilidade
  final String culturaNome; // Nome da cultura (entrada livre)
  final String? variedadeNome; // Nome da variedade (entrada livre)
  final double area;
  final String descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String? observacoes;
  final List<String>? fotos;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExperimentoModel({
    this.id,
    required this.nome,
    required this.talhaoId,
    this.culturaId,
    this.variedadeId,
    this.safraId, // Pode ser nulo em experimentos existentes (será preenchido ao editar)
    required this.culturaNome,
    this.variedadeNome,
    required this.area,
    required this.descricao,
    required this.dataInicio,
    this.dataFim,
    this.observacoes,
    this.fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'safra_id': safraId, // Incluir o safraId no mapa
      'cultura_nome': culturaNome,
      'variedade_nome': variedadeNome,
      'area': area,
      'descricao': descricao,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'observacoes': observacoes,
      'fotos': fotos?.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExperimentoModel.fromMap(Map<String, dynamic> map) {
    return ExperimentoModel(
      id: map['id']?.toString(),
      nome: map['nome'],
      talhaoId: map['talhao_id']?.toString() ?? '',
      culturaId: map['cultura_id']?.toString(),
      variedadeId: map['variedade_id']?.toString(),
      safraId: map['safra_id']?.toString(),
      culturaNome: map['cultura_nome'] ?? '',
      variedadeNome: map['variedade_nome'],
      area: map['area']?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      dataInicio: map['data_inicio'] != null ? DateTime.parse(map['data_inicio']) : DateTime.now(),
      dataFim: map['data_fim'] != null ? DateTime.parse(map['data_fim']) : null,
      observacoes: map['observacoes'],
      fotos: map['fotos'] != null && map['fotos'].toString().isNotEmpty ? map['fotos'].toString().split(',') : [],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
    );
  }

  ExperimentoModel copyWith({
    String? id,
    String? nome,
    String? talhaoId,
    String? culturaId,
    String? variedadeId,
    String? safraId,
    String? culturaNome,
    String? variedadeNome,
    double? area,
    String? descricao,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? observacoes,
    List<String>? fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExperimentoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      safraId: safraId ?? this.safraId,
      culturaNome: culturaNome ?? this.culturaNome,
      variedadeNome: variedadeNome ?? this.variedadeNome,
      area: area ?? this.area,
      descricao: descricao ?? this.descricao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
