import 'dart:convert';

class ImportJobModel {
  final int? id;
  final String tipo; // 'prescricoes', 'talhoes'
  final String arquivoPath;
  final String status; // 'pendente', 'validado', 'concluido', 'erro'
  final String? erros; // JSON com erros de validação
  final DateTime dataCriacao;
  final String? usuarioId;
  final String? observacoes;
  final int? totalRegistros;
  final int? registrosProcessados;
  final int? registrosSucesso;
  final int? registrosErro;
  final String? nomeArquivoOriginal;
  final double? tamanhoArquivo; // em MB

  ImportJobModel({
    this.id,
    required this.tipo,
    required this.arquivoPath,
    required this.status,
    this.erros,
    required this.dataCriacao,
    this.usuarioId,
    this.observacoes,
    this.totalRegistros,
    this.registrosProcessados,
    this.registrosSucesso,
    this.registrosErro,
    this.nomeArquivoOriginal,
    this.tamanhoArquivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'arquivo_path': arquivoPath,
      'status': status,
      'erros': erros,
      'data_criacao': dataCriacao.toIso8601String(),
      'usuario_id': usuarioId,
      'observacoes': observacoes,
      'total_registros': totalRegistros,
      'registros_processados': registrosProcessados,
      'registros_sucesso': registrosSucesso,
      'registros_erro': registrosErro,
      'nome_arquivo_original': nomeArquivoOriginal,
      'tamanho_arquivo': tamanhoArquivo,
    };
  }

  factory ImportJobModel.fromMap(Map<String, dynamic> map) {
    return ImportJobModel(
      id: map['id'],
      tipo: map['tipo'] ?? '',
      arquivoPath: map['arquivo_path'] ?? '',
      status: map['status'] ?? 'pendente',
      erros: map['erros'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      usuarioId: map['usuario_id'],
      observacoes: map['observacoes'],
      totalRegistros: map['total_registros'],
      registrosProcessados: map['registros_processados'],
      registrosSucesso: map['registros_sucesso'],
      registrosErro: map['registros_erro'],
      nomeArquivoOriginal: map['nome_arquivo_original'],
      tamanhoArquivo: map['tamanho_arquivo']?.toDouble(),
    );
  }

  List<Map<String, dynamic>> getErrosAsList() {
    try {
      if (erros == null || erros!.isEmpty) return [];
      return List<Map<String, dynamic>>.from(json.decode(erros!));
    } catch (e) {
      return [];
    }
  }

  double getProgresso() {
    if (totalRegistros == null || totalRegistros == 0) return 0.0;
    return (registrosProcessados ?? 0) / totalRegistros!;
  }

  ImportJobModel copyWith({
    int? id,
    String? tipo,
    String? arquivoPath,
    String? status,
    String? erros,
    DateTime? dataCriacao,
    String? usuarioId,
    String? observacoes,
    int? totalRegistros,
    int? registrosProcessados,
    int? registrosSucesso,
    int? registrosErro,
    String? nomeArquivoOriginal,
    double? tamanhoArquivo,
  }) {
    return ImportJobModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      arquivoPath: arquivoPath ?? this.arquivoPath,
      status: status ?? this.status,
      erros: erros ?? this.erros,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      usuarioId: usuarioId ?? this.usuarioId,
      observacoes: observacoes ?? this.observacoes,
      totalRegistros: totalRegistros ?? this.totalRegistros,
      registrosProcessados: registrosProcessados ?? this.registrosProcessados,
      registrosSucesso: registrosSucesso ?? this.registrosSucesso,
      registrosErro: registrosErro ?? this.registrosErro,
      nomeArquivoOriginal: nomeArquivoOriginal ?? this.nomeArquivoOriginal,
      tamanhoArquivo: tamanhoArquivo ?? this.tamanhoArquivo,
    );
  }

  @override
  String toString() {
    return 'ImportJobModel(id: $id, tipo: $tipo, status: $status, dataCriacao: $dataCriacao, progresso: ${getProgresso().toStringAsFixed(1)}%)';
  }
}
