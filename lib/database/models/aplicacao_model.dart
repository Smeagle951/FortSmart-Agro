import 'package:uuid/uuid.dart';

/// Modelo para aplicações em subáreas
class AplicacaoModel {
  final String id;
  final String subareaId;
  final String experimentoId;
  final DateTime dataAplicacao;
  final String tipoAplicacao; // 'fertilizante', 'defensivo', 'corretivo', 'outros'
  final String produto;
  final String principioAtivo;
  final double dosagem; // kg/ha ou L/ha
  final String unidadeDosagem; // 'kg/ha', 'L/ha', 'mL/ha'
  final double volumeCalda; // L/ha
  final String equipamento;
  final String condicoesTempo; // 'ensolarado', 'nublado', 'chuvoso', 'vento'
  final double temperatura; // °C
  final double umidadeRelativa; // %
  final double velocidadeVento; // km/h
  final String observacoes;
  final List<String> fotos; // URLs ou paths das fotos
  final String responsavelTecnico;
  final String crmResponsavel;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Propriedades adicionais para compatibilidade com as telas
  String get data => dataAplicacao.toIso8601String();
  String get talhaoId => subareaId;
  String get condicoesClimaticas => condicoesTempo;
  double get areaTotal => 0.0; // Valor padrão, pode ser calculado
  int get totalBombas => 1; // Valor padrão
  String get statusSync => 'pending'; // Valor padrão
  List<String> get produtos => [produto]; // Lista com o produto atual
  List<String> get imagens => fotos;
  
  // Propriedades adicionais para compatibilidade com aplicacao_registro_screen
  String get responsavel => responsavelTecnico;
  double get capacidadeBomba => 0.0; // Valor padrão
  double get vazaoAplicacao => 0.0; // Valor padrão
  String get bicoTipo => 'Padrão'; // Valor padrão
  String get produtosJson => '[]'; // JSON vazio por padrão

  const AplicacaoModel({
    required this.id,
    required this.subareaId,
    required this.experimentoId,
    required this.dataAplicacao,
    required this.tipoAplicacao,
    required this.produto,
    required this.principioAtivo,
    required this.dosagem,
    required this.unidadeDosagem,
    required this.volumeCalda,
    required this.equipamento,
    required this.condicoesTempo,
    required this.temperatura,
    required this.umidadeRelativa,
    required this.velocidadeVento,
    required this.observacoes,
    required this.fotos,
    required this.responsavelTecnico,
    required this.crmResponsavel,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma nova aplicação com ID gerado automaticamente
  factory AplicacaoModel.create({
    required String subareaId,
    required String experimentoId,
    required DateTime dataAplicacao,
    required String tipoAplicacao,
    required String produto,
    required String principioAtivo,
    required double dosagem,
    required String unidadeDosagem,
    required double volumeCalda,
    required String equipamento,
    required String condicoesTempo,
    required double temperatura,
    required double umidadeRelativa,
    required double velocidadeVento,
    required String observacoes,
    List<String>? fotos,
    required String responsavelTecnico,
    required String crmResponsavel,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    return AplicacaoModel(
      id: uuid.v4(),
      subareaId: subareaId,
      experimentoId: experimentoId,
      dataAplicacao: dataAplicacao,
      tipoAplicacao: tipoAplicacao,
      produto: produto,
      principioAtivo: principioAtivo,
      dosagem: dosagem,
      unidadeDosagem: unidadeDosagem,
      volumeCalda: volumeCalda,
      equipamento: equipamento,
      condicoesTempo: condicoesTempo,
      temperatura: temperatura,
      umidadeRelativa: umidadeRelativa,
      velocidadeVento: velocidadeVento,
      observacoes: observacoes,
      fotos: fotos ?? [],
      responsavelTecnico: responsavelTecnico,
      crmResponsavel: crmResponsavel,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia da aplicação com campos alterados
  AplicacaoModel copyWith({
    String? id,
    String? subareaId,
    String? experimentoId,
    DateTime? dataAplicacao,
    String? tipoAplicacao,
    String? produto,
    String? principioAtivo,
    double? dosagem,
    String? unidadeDosagem,
    double? volumeCalda,
    String? equipamento,
    String? condicoesTempo,
    double? temperatura,
    double? umidadeRelativa,
    double? velocidadeVento,
    String? observacoes,
    List<String>? fotos,
    String? responsavelTecnico,
    String? crmResponsavel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AplicacaoModel(
      id: id ?? this.id,
      subareaId: subareaId ?? this.subareaId,
      experimentoId: experimentoId ?? this.experimentoId,
      dataAplicacao: dataAplicacao ?? this.dataAplicacao,
      tipoAplicacao: tipoAplicacao ?? this.tipoAplicacao,
      produto: produto ?? this.produto,
      principioAtivo: principioAtivo ?? this.principioAtivo,
      dosagem: dosagem ?? this.dosagem,
      unidadeDosagem: unidadeDosagem ?? this.unidadeDosagem,
      volumeCalda: volumeCalda ?? this.volumeCalda,
      equipamento: equipamento ?? this.equipamento,
      condicoesTempo: condicoesTempo ?? this.condicoesTempo,
      temperatura: temperatura ?? this.temperatura,
      umidadeRelativa: umidadeRelativa ?? this.umidadeRelativa,
      velocidadeVento: velocidadeVento ?? this.velocidadeVento,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      responsavelTecnico: responsavelTecnico ?? this.responsavelTecnico,
      crmResponsavel: crmResponsavel ?? this.crmResponsavel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subarea_id': subareaId,
      'experimento_id': experimentoId,
      'data_aplicacao': dataAplicacao.millisecondsSinceEpoch,
      'tipo_aplicacao': tipoAplicacao,
      'produto': produto,
      'principio_ativo': principioAtivo,
      'dosagem': dosagem,
      'unidade_dosagem': unidadeDosagem,
      'volume_calda': volumeCalda,
      'equipamento': equipamento,
      'condicoes_tempo': condicoesTempo,
      'temperatura': temperatura,
      'umidade_relativa': umidadeRelativa,
      'velocidade_vento': velocidadeVento,
      'observacoes': observacoes,
      'fotos': fotos.join(','), // Salvar como string separada por vírgulas
      'responsavel_tecnico': responsavelTecnico,
      'crm_responsavel': crmResponsavel,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria a partir de Map do banco
  factory AplicacaoModel.fromMap(Map<String, dynamic> map) {
    return AplicacaoModel(
      id: map['id'],
      subareaId: map['subarea_id'],
      experimentoId: map['experimento_id'],
      dataAplicacao: DateTime.fromMillisecondsSinceEpoch(map['data_aplicacao']),
      tipoAplicacao: map['tipo_aplicacao'],
      produto: map['produto'],
      principioAtivo: map['principio_ativo'],
      dosagem: map['dosagem'],
      unidadeDosagem: map['unidade_dosagem'],
      volumeCalda: map['volume_calda'],
      equipamento: map['equipamento'],
      condicoesTempo: map['condicoes_tempo'],
      temperatura: map['temperatura'],
      umidadeRelativa: map['umidade_relativa'],
      velocidadeVento: map['velocidade_vento'],
      observacoes: map['observacoes'],
      fotos: map['fotos']?.split(',') ?? [],
      responsavelTecnico: map['responsavel_tecnico'],
      crmResponsavel: map['crm_responsavel'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'AplicacaoModel(id: $id, produto: $produto, dosagem: $dosagem $unidadeDosagem, data: $dataAplicacao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AplicacaoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}