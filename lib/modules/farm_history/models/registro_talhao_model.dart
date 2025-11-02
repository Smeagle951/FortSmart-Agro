import 'package:intl/intl.dart';

class RegistroTalhaoModel {
  int? id;
  int talhaoId;
  int safraId;
  String data;
  String tipoRegistro;
  String? descricao;
  double? quantidade;
  String? unidade;
  double? custo;
  String? observacoes;
  String? fotos;
  String? createdAt;
  String? updatedAt;
  int syncStatus;

  RegistroTalhaoModel({
    this.id,
    required this.talhaoId,
    required this.safraId,
    required this.data,
    required this.tipoRegistro,
    this.descricao,
    this.quantidade,
    this.unidade,
    this.custo,
    this.observacoes,
    this.fotos,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  // Tipos de registro predefinidos
  static const String CALAGEM = 'Calagem';
  static const String GESSAGEM = 'Gessagem';
  static const String ADUBACAO = 'Adubação';
  static const String PLANTIO = 'Plantio';
  static const String APLICACAO = 'Aplicação';
  static const String COLHEITA = 'Colheita';
  static const String OUTROS = 'Outros';

  // Lista de tipos para seleção
  static List<String> getTiposRegistro() {
    return [CALAGEM, GESSAGEM, ADUBACAO, PLANTIO, APLICACAO, COLHEITA, OUTROS];
  }

  // Converter de Map para objeto
  factory RegistroTalhaoModel.fromMap(Map<String, dynamic> map) {
    return RegistroTalhaoModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      data: map['data'],
      tipoRegistro: map['tipo_registro'],
      descricao: map['descricao'],
      quantidade: map['quantidade'] != null ? map['quantidade'].toDouble() : null,
      unidade: map['unidade'],
      custo: map['custo'] != null ? map['custo'].toDouble() : null,
      observacoes: map['observacoes'],
      fotos: map['fotos'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  // Converter de objeto para Map
  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    return {
      'id': id,
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'data': data,
      'tipo_registro': tipoRegistro,
      'descricao': descricao,
      'quantidade': quantidade,
      'unidade': unidade,
      'custo': custo,
      'observacoes': observacoes,
      'fotos': fotos,
      'created_at': createdAt ?? timestamp,
      'updated_at': timestamp,
      'sync_status': syncStatus,
    };
  }

  // Copiar objeto com alterações
  RegistroTalhaoModel copyWith({
    int? id,
    int? talhaoId,
    int? safraId,
    String? data,
    String? tipoRegistro,
    String? descricao,
    double? quantidade,
    String? unidade,
    double? custo,
    String? observacoes,
    String? fotos,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
  }) {
    return RegistroTalhaoModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      data: data ?? this.data,
      tipoRegistro: tipoRegistro ?? this.tipoRegistro,
      descricao: descricao ?? this.descricao,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      custo: custo ?? this.custo,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Representação em string
  @override
  String toString() {
    return 'RegistroTalhaoModel(id: $id, tipoRegistro: $tipoRegistro, data: $data)';
  }
}
