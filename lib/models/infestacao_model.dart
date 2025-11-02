class InfestacaoModel {
  final String id;
  final String talhaoId; // String para compatibilidade
  final int pontoId;
  final double latitude;
  final double longitude;
  final String tipo; // Praga, Doença, Daninha, Outro
  final String subtipo;
  final String nivel; // Crítico, Alto, Médio, Baixo
  final int percentual; // Preview/cálculo simples
  final String? fotoPaths; // Separado por ';'
  final String? observacao;
  final DateTime dataHora;
  final bool sincronizado;
  final String? serverId;
  final String? lastSyncError;
  final int attemptsSync;
  
  // Novos campos para cálculo avançado no mapa de infestação
  final String? organismoId; // ID do organismo no catálogo JSON
  final int? quantidadeBruta; // Quantidade encontrada (valor bruto)
  final int? totalPlantasAvaliadas; // Total de plantas avaliadas
  final String? tercoPlanta; // Baixeiro, Médio, Ponteiro

  InfestacaoModel({
    required this.id,
    required this.talhaoId,
    required this.pontoId,
    required this.latitude,
    required this.longitude,
    required this.tipo,
    required this.subtipo,
    required this.nivel,
    required this.percentual,
    this.fotoPaths,
    this.observacao,
    required this.dataHora,
    this.sincronizado = false,
    this.serverId,
    this.lastSyncError,
    this.attemptsSync = 0,
    // Novos campos opcionais
    this.organismoId,
    this.quantidadeBruta,
    this.totalPlantasAvaliadas,
    this.tercoPlanta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'ponto_id': pontoId,
      'latitude': latitude,
      'longitude': longitude,
      'tipo': tipo,
      'subtipo': subtipo,
      'nivel': nivel,
      'percentual': percentual,
      'foto_paths': fotoPaths,
      'observacao': observacao,
      'data_hora': dataHora.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
      'server_id': serverId,
      'last_sync_error': lastSyncError,
      'attempts_sync': attemptsSync,
      // Novos campos para cálculo avançado
      'organismo_id': organismoId,
      'quantidade_bruta': quantidadeBruta,
      'total_plantas_avaliadas': totalPlantasAvaliadas,
      'terco_planta': tercoPlanta,
    };
  }

  factory InfestacaoModel.fromMap(Map<String, dynamic> map) {
    return InfestacaoModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? 0,
      pontoId: map['ponto_id'] ?? 0,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      tipo: map['tipo'] ?? '',
      subtipo: map['subtipo'] ?? '',
      nivel: map['nivel'] ?? '',
      percentual: map['percentual'] ?? 0,
      fotoPaths: map['foto_paths'],
      observacao: map['observacao'],
      dataHora: DateTime.parse(map['data_hora'] ?? DateTime.now().toIso8601String()),
      sincronizado: (map['sincronizado'] ?? 0) == 1,
      serverId: map['server_id'],
      lastSyncError: map['last_sync_error'],
      attemptsSync: map['attempts_sync'] ?? 0,
      // Novos campos
      organismoId: map['organismo_id'],
      quantidadeBruta: map['quantidade_bruta'],
      totalPlantasAvaliadas: map['total_plantas_avaliadas'],
      tercoPlanta: map['terco_planta'],
    );
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'infestacao_id': id,
      'talhao_id': talhaoId,
      'ponto_id': pontoId,
      'latitude': latitude,
      'longitude': longitude,
      'tipo': tipo,
      'subtipo': subtipo,
      'nivel': nivel,
      'percentual': percentual,
      'foto_urls': remotePhotoUrls,
      'observacao': observacao,
      'data_hora': dataHora.toIso8601String(),
      'sincronizado': sincronizado,
    };
  }

  List<String> get localPhotoPaths {
    if (fotoPaths == null || fotoPaths!.isEmpty) return [];
    return fotoPaths!.split(';').where((path) => path.isNotEmpty).toList();
  }

  List<String> remotePhotoUrls = [];

  InfestacaoModel copyWith({
    String? id,
    String? talhaoId,
    int? pontoId,
    double? latitude,
    double? longitude,
    String? tipo,
    String? subtipo,
    String? nivel,
    int? percentual,
    String? fotoPaths,
    String? observacao,
    DateTime? dataHora,
    bool? sincronizado,
    String? serverId,
    String? lastSyncError,
    int? attemptsSync,
    String? organismoId,
    int? quantidadeBruta,
    int? totalPlantasAvaliadas,
    String? tercoPlanta,
  }) {
    return InfestacaoModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      pontoId: pontoId ?? this.pontoId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tipo: tipo ?? this.tipo,
      subtipo: subtipo ?? this.subtipo,
      nivel: nivel ?? this.nivel,
      percentual: percentual ?? this.percentual,
      fotoPaths: fotoPaths ?? this.fotoPaths,
      observacao: observacao ?? this.observacao,
      dataHora: dataHora ?? this.dataHora,
      sincronizado: sincronizado ?? this.sincronizado,
      serverId: serverId ?? this.serverId,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      attemptsSync: attemptsSync ?? this.attemptsSync,
      organismoId: organismoId ?? this.organismoId,
      quantidadeBruta: quantidadeBruta ?? this.quantidadeBruta,
      totalPlantasAvaliadas: totalPlantasAvaliadas ?? this.totalPlantasAvaliadas,
      tercoPlanta: tercoPlanta ?? this.tercoPlanta,
    );
  }

  // Cores para cada tipo
  String get tipoColor {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return '#F2994A';
      case 'doença':
        return '#9B51E0';
      case 'daninha':
        return '#27AE60';
      default:
        return '#2D9CDB';
    }
  }

  // Ícones para cada tipo
  String get tipoIcon {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return '🐛';
      case 'doença':
        return '🦠';
      case 'daninha':
        return '🌿';
      default:
        return '📋';
    }
  }

  // Cor do badge de nível
  String get nivelColor {
    switch (nivel.toLowerCase()) {
      case 'crítico':
        return '#EB5757';
      case 'alto':
        return '#F2C94C';
      case 'médio':
        return '#2D9CDB';
      case 'baixo':
        return '#27AE60';
      default:
        return '#95A5A6';
    }
  }
}
