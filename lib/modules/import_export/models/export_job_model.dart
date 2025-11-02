import 'dart:convert';

class ExportJobModel {
  final int? id;
  final String tipo; // 'custos', 'prescricoes', 'talhoes'
  final String filtros; // JSON com filtros aplicados
  final String formato; // 'csv', 'xlsx', 'json'
  final String status; // 'pendente', 'concluido', 'erro'
  final String? arquivoPath;
  final DateTime dataCriacao;
  final String? usuarioId;
  final String? observacoes;
  final int? totalRegistros;
  final double? tamanhoArquivo; // em MB

  ExportJobModel({
    this.id,
    required this.tipo,
    required this.filtros,
    required this.formato,
    required this.status,
    this.arquivoPath,
    required this.dataCriacao,
    this.usuarioId,
    this.observacoes,
    this.totalRegistros,
    this.tamanhoArquivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'filtros': filtros,
      'formato': formato,
      'status': status,
      'arquivo_path': arquivoPath,
      'data_criacao': dataCriacao.toIso8601String(),
      'usuario_id': usuarioId,
      'observacoes': observacoes,
      'total_registros': totalRegistros,
      'tamanho_arquivo': tamanhoArquivo,
    };
  }

  factory ExportJobModel.fromMap(Map<String, dynamic> map) {
    return ExportJobModel(
      id: map['id'],
      tipo: map['tipo'] ?? '',
      filtros: map['filtros'] ?? '{}',
      formato: map['formato'] ?? '',
      status: map['status'] ?? 'pendente',
      arquivoPath: map['arquivo_path'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      usuarioId: map['usuario_id'],
      observacoes: map['observacoes'],
      totalRegistros: map['total_registros'],
      tamanhoArquivo: map['tamanho_arquivo']?.toDouble(),
    );
  }

  Map<String, dynamic> getFiltrosAsMap() {
    try {
      return json.decode(filtros);
    } catch (e) {
      return {};
    }
  }

  ExportJobModel copyWith({
    int? id,
    String? tipo,
    String? filtros,
    String? formato,
    String? status,
    String? arquivoPath,
    DateTime? dataCriacao,
    String? usuarioId,
    String? observacoes,
    int? totalRegistros,
    double? tamanhoArquivo,
  }) {
    return ExportJobModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      filtros: filtros ?? this.filtros,
      formato: formato ?? this.formato,
      status: status ?? this.status,
      arquivoPath: arquivoPath ?? this.arquivoPath,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      usuarioId: usuarioId ?? this.usuarioId,
      observacoes: observacoes ?? this.observacoes,
      totalRegistros: totalRegistros ?? this.totalRegistros,
      tamanhoArquivo: tamanhoArquivo ?? this.tamanhoArquivo,
    );
  }

  @override
  String toString() {
    return 'ExportJobModel(id: $id, tipo: $tipo, formato: $formato, status: $status, dataCriacao: $dataCriacao)';
  }
}
