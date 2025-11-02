class PontoMonitoramentoModel {
  final int id;
  final int talhaoId;
  final int ordem;
  final double latitude;
  final double longitude;
  final DateTime? dataHoraInicio;
  final DateTime? dataHoraFim;
  final String? observacoesGerais;
  final bool sincronizado;
  final String? serverId;

  PontoMonitoramentoModel({
    required this.id,
    required this.talhaoId,
    required this.ordem,
    required this.latitude,
    required this.longitude,
    this.dataHoraInicio,
    this.dataHoraFim,
    this.observacoesGerais,
    this.sincronizado = false,
    this.serverId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'ordem': ordem,
      'latitude': latitude,
      'longitude': longitude,
      'data_hora_inicio': dataHoraInicio?.toIso8601String(),
      'data_hora_fim': dataHoraFim?.toIso8601String(),
      'observacoes_gerais': observacoesGerais,
      'sincronizado': sincronizado ? 1 : 0,
      'server_id': serverId,
    };
  }

  factory PontoMonitoramentoModel.fromMap(Map<String, dynamic> map) {
    return PontoMonitoramentoModel(
      id: map['id'] ?? 0,
      talhaoId: map['talhao_id'] ?? 0,
      ordem: map['ordem'] ?? 0,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      dataHoraInicio: map['data_hora_inicio'] != null 
          ? DateTime.parse(map['data_hora_inicio']) 
          : null,
      dataHoraFim: map['data_hora_fim'] != null 
          ? DateTime.parse(map['data_hora_fim']) 
          : null,
      observacoesGerais: map['observacoes_gerais'],
      sincronizado: (map['sincronizado'] ?? 0) == 1,
      serverId: map['server_id'],
    );
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'ponto_id': id,
      'talhao_id': talhaoId,
      'ordem': ordem,
      'latitude': latitude,
      'longitude': longitude,
      'data_hora_inicio': dataHoraInicio?.toIso8601String(),
      'ocorrencias': [], // Será preenchido com IDs das ocorrências
      'observacoes_gerais': observacoesGerais,
      'sincronizado': sincronizado,
    };
  }

  PontoMonitoramentoModel copyWith({
    int? id,
    int? talhaoId,
    int? ordem,
    double? latitude,
    double? longitude,
    DateTime? dataHoraInicio,
    DateTime? dataHoraFim,
    String? observacoesGerais,
    bool? sincronizado,
    String? serverId,
  }) {
    return PontoMonitoramentoModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      ordem: ordem ?? this.ordem,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
      dataHoraFim: dataHoraFim ?? this.dataHoraFim,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      sincronizado: sincronizado ?? this.sincronizado,
      serverId: serverId ?? this.serverId,
    );
  }

  bool get isCompleted => dataHoraFim != null;
  bool get isInProgress => dataHoraInicio != null && dataHoraFim == null;
}
