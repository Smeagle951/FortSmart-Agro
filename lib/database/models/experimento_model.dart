import 'package:uuid/uuid.dart';

/// Modelo para experimentos científicos
class ExperimentoModel {
  final String id;
  final String nome;
  final String descricao;
  final String objetivo;
  final String talhaoId;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String status; // 'planejado', 'em_andamento', 'finalizado', 'cancelado'
  final String delineamento; // 'blocos_casualizados', 'parcelas_subdivididas', 'fatorial', 'outros'
  final int numeroRepeticoes;
  final int numeroTratamentos;
  final String cultura;
  final String variedade;
  final String responsavelTecnico;
  final String crmResponsavel;
  final String instituicao;
  final String protocolo;
  final List<String> variaveisResposta; // ['produtividade', 'qualidade', 'incidencia_doencas']
  final List<String> variaveisAmbientais; // ['temperatura', 'umidade', 'precipitacao']
  final String observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExperimentoModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.objetivo,
    required this.talhaoId,
    required this.dataInicio,
    this.dataFim,
    required this.status,
    required this.delineamento,
    required this.numeroRepeticoes,
    required this.numeroTratamentos,
    required this.cultura,
    required this.variedade,
    required this.responsavelTecnico,
    required this.crmResponsavel,
    required this.instituicao,
    required this.protocolo,
    required this.variaveisResposta,
    required this.variaveisAmbientais,
    required this.observacoes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria um novo experimento
  factory ExperimentoModel.create({
    required String nome,
    required String descricao,
    required String objetivo,
    required String talhaoId,
    required DateTime dataInicio,
    required String delineamento,
    required int numeroRepeticoes,
    required int numeroTratamentos,
    required String cultura,
    required String variedade,
    required String responsavelTecnico,
    required String crmResponsavel,
    required String instituicao,
    required String protocolo,
    List<String>? variaveisResposta,
    List<String>? variaveisAmbientais,
    String? observacoes,
    String? status,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    return ExperimentoModel(
      id: uuid.v4(),
      nome: nome,
      descricao: descricao,
      objetivo: objetivo,
      talhaoId: talhaoId,
      dataInicio: dataInicio,
      status: status ?? 'planejado',
      delineamento: delineamento,
      numeroRepeticoes: numeroRepeticoes,
      numeroTratamentos: numeroTratamentos,
      cultura: cultura,
      variedade: variedade,
      responsavelTecnico: responsavelTecnico,
      crmResponsavel: crmResponsavel,
      instituicao: instituicao,
      protocolo: protocolo,
      variaveisResposta: variaveisResposta ?? ['produtividade'],
      variaveisAmbientais: variaveisAmbientais ?? ['temperatura', 'umidade'],
      observacoes: observacoes ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia do experimento com campos alterados
  ExperimentoModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? objetivo,
    String? talhaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
    String? delineamento,
    int? numeroRepeticoes,
    int? numeroTratamentos,
    String? cultura,
    String? variedade,
    String? responsavelTecnico,
    String? crmResponsavel,
    String? instituicao,
    String? protocolo,
    List<String>? variaveisResposta,
    List<String>? variaveisAmbientais,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExperimentoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      objetivo: objetivo ?? this.objetivo,
      talhaoId: talhaoId ?? this.talhaoId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      delineamento: delineamento ?? this.delineamento,
      numeroRepeticoes: numeroRepeticoes ?? this.numeroRepeticoes,
      numeroTratamentos: numeroTratamentos ?? this.numeroTratamentos,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      responsavelTecnico: responsavelTecnico ?? this.responsavelTecnico,
      crmResponsavel: crmResponsavel ?? this.crmResponsavel,
      instituicao: instituicao ?? this.instituicao,
      protocolo: protocolo ?? this.protocolo,
      variaveisResposta: variaveisResposta ?? this.variaveisResposta,
      variaveisAmbientais: variaveisAmbientais ?? this.variaveisAmbientais,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'objetivo': objetivo,
      'talhao_id': talhaoId,
      'data_inicio': dataInicio.millisecondsSinceEpoch,
      'data_fim': dataFim?.millisecondsSinceEpoch,
      'status': status,
      'delineamento': delineamento,
      'numero_repeticoes': numeroRepeticoes,
      'numero_tratamentos': numeroTratamentos,
      'cultura': cultura,
      'variedade': variedade,
      'responsavel_tecnico': responsavelTecnico,
      'crm_responsavel': crmResponsavel,
      'instituicao': instituicao,
      'protocolo': protocolo,
      'variaveis_resposta': variaveisResposta.join(','),
      'variaveis_ambientais': variaveisAmbientais.join(','),
      'observacoes': observacoes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria a partir de Map do banco
  factory ExperimentoModel.fromMap(Map<String, dynamic> map) {
    return ExperimentoModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      objetivo: map['objetivo'],
      talhaoId: map['talhao_id'],
      dataInicio: DateTime.fromMillisecondsSinceEpoch(map['data_inicio']),
      dataFim: map['data_fim'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['data_fim'])
          : null,
      status: map['status'],
      delineamento: map['delineamento'],
      numeroRepeticoes: map['numero_repeticoes'],
      numeroTratamentos: map['numero_tratamentos'],
      cultura: map['cultura'],
      variedade: map['variedade'],
      responsavelTecnico: map['responsavel_tecnico'],
      crmResponsavel: map['crm_responsavel'],
      instituicao: map['instituicao'],
      protocolo: map['protocolo'],
      variaveisResposta: map['variaveis_resposta']?.split(',') ?? [],
      variaveisAmbientais: map['variaveis_ambientais']?.split(',') ?? [],
      observacoes: map['observacoes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  /// Calcula o número total de parcelas
  int get totalParcelas => numeroTratamentos * numeroRepeticoes;

  /// Calcula dias desde o início
  int get diasDesdeInicio {
    final agora = DateTime.now();
    return agora.difference(dataInicio).inDays;
  }

  /// Verifica se está ativo
  bool get isAtivo => status == 'em_andamento';

  @override
  String toString() {
    return 'ExperimentoModel(id: $id, nome: $nome, delineamento: $delineamento, tratamentos: $numeroTratamentos)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExperimentoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
