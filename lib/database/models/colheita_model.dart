import 'package:uuid/uuid.dart';

/// Modelo para colheitas de subáreas
class ColheitaModel {
  final String id;
  final String subareaId;
  final String experimentoId;
  final DateTime dataColheita;
  final String tipoColheita; // 'manual', 'mecanizada', 'seletiva'
  final double areaColhida; // hectares
  final double producaoTotal; // kg ou toneladas
  final String unidadeProducao; // 'kg', 'toneladas'
  final double produtividade; // kg/ha ou toneladas/ha
  final String unidadeProdutividade; // 'kg/ha', 'toneladas/ha'
  final String qualidade; // 'excelente', 'boa', 'regular', 'ruim'
  final double umidade; // percentual
  final double impurezas; // percentual
  final double danos; // percentual
  final String equipamento;
  final String observacoes;
  final List<String> fotos; // URLs ou paths das fotos
  final String responsavelColheita;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ColheitaModel({
    required this.id,
    required this.subareaId,
    required this.experimentoId,
    required this.dataColheita,
    required this.tipoColheita,
    required this.areaColhida,
    required this.producaoTotal,
    required this.unidadeProducao,
    required this.produtividade,
    required this.unidadeProdutividade,
    required this.qualidade,
    required this.umidade,
    required this.impurezas,
    required this.danos,
    required this.equipamento,
    required this.observacoes,
    required this.fotos,
    required this.responsavelColheita,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma nova colheita com ID gerado automaticamente
  factory ColheitaModel.create({
    required String subareaId,
    required String experimentoId,
    required DateTime dataColheita,
    required String tipoColheita,
    required double areaColhida,
    required double producaoTotal,
    required String unidadeProducao,
    required double produtividade,
    required String unidadeProdutividade,
    required String qualidade,
    required double umidade,
    required double impurezas,
    required double danos,
    required String equipamento,
    required String observacoes,
    List<String>? fotos,
    required String responsavelColheita,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    return ColheitaModel(
      id: uuid.v4(),
      subareaId: subareaId,
      experimentoId: experimentoId,
      dataColheita: dataColheita,
      tipoColheita: tipoColheita,
      areaColhida: areaColhida,
      producaoTotal: producaoTotal,
      unidadeProducao: unidadeProducao,
      produtividade: produtividade,
      unidadeProdutividade: unidadeProdutividade,
      qualidade: qualidade,
      umidade: umidade,
      impurezas: impurezas,
      danos: danos,
      equipamento: equipamento,
      observacoes: observacoes,
      fotos: fotos ?? [],
      responsavelColheita: responsavelColheita,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia da colheita com campos alterados
  ColheitaModel copyWith({
    String? id,
    String? subareaId,
    String? experimentoId,
    DateTime? dataColheita,
    String? tipoColheita,
    double? areaColhida,
    double? producaoTotal,
    String? unidadeProducao,
    double? produtividade,
    String? unidadeProdutividade,
    String? qualidade,
    double? umidade,
    double? impurezas,
    double? danos,
    String? equipamento,
    String? observacoes,
    List<String>? fotos,
    String? responsavelColheita,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ColheitaModel(
      id: id ?? this.id,
      subareaId: subareaId ?? this.subareaId,
      experimentoId: experimentoId ?? this.experimentoId,
      dataColheita: dataColheita ?? this.dataColheita,
      tipoColheita: tipoColheita ?? this.tipoColheita,
      areaColhida: areaColhida ?? this.areaColhida,
      producaoTotal: producaoTotal ?? this.producaoTotal,
      unidadeProducao: unidadeProducao ?? this.unidadeProducao,
      produtividade: produtividade ?? this.produtividade,
      unidadeProdutividade: unidadeProdutividade ?? this.unidadeProdutividade,
      qualidade: qualidade ?? this.qualidade,
      umidade: umidade ?? this.umidade,
      impurezas: impurezas ?? this.impurezas,
      danos: danos ?? this.danos,
      equipamento: equipamento ?? this.equipamento,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      responsavelColheita: responsavelColheita ?? this.responsavelColheita,
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
      'data_colheita': dataColheita.millisecondsSinceEpoch,
      'tipo_colheita': tipoColheita,
      'area_colhida': areaColhida,
      'producao_total': producaoTotal,
      'unidade_producao': unidadeProducao,
      'produtividade': produtividade,
      'unidade_produtividade': unidadeProdutividade,
      'qualidade': qualidade,
      'umidade': umidade,
      'impurezas': impurezas,
      'danos': danos,
      'equipamento': equipamento,
      'observacoes': observacoes,
      'fotos': fotos.join(','), // Salvar como string separada por vírgulas
      'responsavel_colheita': responsavelColheita,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria a partir de Map do banco
  factory ColheitaModel.fromMap(Map<String, dynamic> map) {
    return ColheitaModel(
      id: map['id'],
      subareaId: map['subarea_id'],
      experimentoId: map['experimento_id'],
      dataColheita: DateTime.fromMillisecondsSinceEpoch(map['data_colheita']),
      tipoColheita: map['tipo_colheita'],
      areaColhida: map['area_colhida'],
      producaoTotal: map['producao_total'],
      unidadeProducao: map['unidade_producao'],
      produtividade: map['produtividade'],
      unidadeProdutividade: map['unidade_produtividade'],
      qualidade: map['qualidade'],
      umidade: map['umidade'],
      impurezas: map['impurezas'],
      danos: map['danos'],
      equipamento: map['equipamento'],
      observacoes: map['observacoes'],
      fotos: map['fotos']?.split(',') ?? [],
      responsavelColheita: map['responsavel_colheita'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'ColheitaModel(id: $id, produtividade: $produtividade $unidadeProdutividade, data: $dataColheita)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColheitaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
