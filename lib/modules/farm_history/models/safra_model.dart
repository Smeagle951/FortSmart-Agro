import 'package:intl/intl.dart';

class SafraModel {
  int? id;
  String nome;
  int ano;
  int? fazendaId;
  String? dataInicio;
  String? dataFim;
  String? observacoes;
  String? createdAt;
  String? updatedAt;
  int syncStatus;

  SafraModel({
    this.id,
    required this.nome,
    required this.ano,
    this.fazendaId,
    this.dataInicio,
    this.dataFim,
    this.observacoes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  // Converter de Map para objeto
  factory SafraModel.fromMap(Map<String, dynamic> map) {
    return SafraModel(
      id: map['id'],
      nome: map['nome'],
      ano: map['ano'],
      fazendaId: map['fazenda_id'],
      dataInicio: map['data_inicio'],
      dataFim: map['data_fim'],
      observacoes: map['observacoes'],
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
      'nome': nome,
      'ano': ano,
      'fazenda_id': fazendaId,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'observacoes': observacoes,
      'created_at': createdAt ?? timestamp,
      'updated_at': timestamp,
      'sync_status': syncStatus,
    };
  }

  // Copiar objeto com alterações
  SafraModel copyWith({
    int? id,
    String? nome,
    int? ano,
    int? fazendaId,
    String? dataInicio,
    String? dataFim,
    String? observacoes,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
  }) {
    return SafraModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ano: ano ?? this.ano,
      fazendaId: fazendaId ?? this.fazendaId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Representação em string
  @override
  String toString() {
    return 'SafraModel(id: $id, nome: $nome, ano: $ano)';
  }
}
