import 'package:intl/intl.dart';

class AnaliseSoloModel {
  int? id;
  int talhaoId;
  int safraId;
  String data;
  double? ph;
  double? vPorcentagem;
  double? ctc;
  double? fosforo;
  double? potassio;
  double? calcio;
  double? magnesio;
  double? enxofre;
  double? aluminio;
  double? carbono;
  double? materiaOrganica;
  String? arquivoPdf;
  String? observacoes;
  String? createdAt;
  String? updatedAt;
  int syncStatus;

  AnaliseSoloModel({
    this.id,
    required this.talhaoId,
    required this.safraId,
    required this.data,
    this.ph,
    this.vPorcentagem,
    this.ctc,
    this.fosforo,
    this.potassio,
    this.calcio,
    this.magnesio,
    this.enxofre,
    this.aluminio,
    this.carbono,
    this.materiaOrganica,
    this.arquivoPdf,
    this.observacoes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  // Converter de Map para objeto
  factory AnaliseSoloModel.fromMap(Map<String, dynamic> map) {
    return AnaliseSoloModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      data: map['data'],
      ph: map['ph'] != null ? map['ph'].toDouble() : null,
      vPorcentagem: map['v_porcentagem'] != null ? map['v_porcentagem'].toDouble() : null,
      ctc: map['ctc'] != null ? map['ctc'].toDouble() : null,
      fosforo: map['fosforo'] != null ? map['fosforo'].toDouble() : null,
      potassio: map['potassio'] != null ? map['potassio'].toDouble() : null,
      calcio: map['calcio'] != null ? map['calcio'].toDouble() : null,
      magnesio: map['magnesio'] != null ? map['magnesio'].toDouble() : null,
      enxofre: map['enxofre'] != null ? map['enxofre'].toDouble() : null,
      aluminio: map['aluminio'] != null ? map['aluminio'].toDouble() : null,
      carbono: map['carbono'] != null ? map['carbono'].toDouble() : null,
      materiaOrganica: map['materia_organica'] != null ? map['materia_organica'].toDouble() : null,
      arquivoPdf: map['arquivo_pdf'],
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
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'data': data,
      'ph': ph,
      'v_porcentagem': vPorcentagem,
      'ctc': ctc,
      'fosforo': fosforo,
      'potassio': potassio,
      'calcio': calcio,
      'magnesio': magnesio,
      'enxofre': enxofre,
      'aluminio': aluminio,
      'carbono': carbono,
      'materia_organica': materiaOrganica,
      'arquivo_pdf': arquivoPdf,
      'observacoes': observacoes,
      'created_at': createdAt ?? timestamp,
      'updated_at': timestamp,
      'sync_status': syncStatus,
    };
  }

  // Copiar objeto com alterações
  AnaliseSoloModel copyWith({
    int? id,
    int? talhaoId,
    int? safraId,
    String? data,
    double? ph,
    double? vPorcentagem,
    double? ctc,
    double? fosforo,
    double? potassio,
    double? calcio,
    double? magnesio,
    double? enxofre,
    double? aluminio,
    double? carbono,
    double? materiaOrganica,
    String? arquivoPdf,
    String? observacoes,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
  }) {
    return AnaliseSoloModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      data: data ?? this.data,
      ph: ph ?? this.ph,
      vPorcentagem: vPorcentagem ?? this.vPorcentagem,
      ctc: ctc ?? this.ctc,
      fosforo: fosforo ?? this.fosforo,
      potassio: potassio ?? this.potassio,
      calcio: calcio ?? this.calcio,
      magnesio: magnesio ?? this.magnesio,
      enxofre: enxofre ?? this.enxofre,
      aluminio: aluminio ?? this.aluminio,
      carbono: carbono ?? this.carbono,
      materiaOrganica: materiaOrganica ?? this.materiaOrganica,
      arquivoPdf: arquivoPdf ?? this.arquivoPdf,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Representação em string
  @override
  String toString() {
    return 'AnaliseSoloModel(id: $id, data: $data, ph: $ph, v%: $vPorcentagem)';
  }
}
