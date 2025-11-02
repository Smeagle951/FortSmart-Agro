class SoilAnalysis {
  int? id;
  int monitoringId;
  String? plotId; // ID do talhão associado à análise
  double? ph;
  double? organicMatter;
  double? phosphorus;
  double? potassium;
  double? calcium;
  double? magnesium;
  double? sulfur;
  double? aluminum;
  double? cationExchangeCapacity;
  double? baseSaturation;
  double? clayContent;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;

  // Getters adicionais
  bool get synced => syncStatus == 1;

  SoilAnalysis({
    this.id,
    required this.monitoringId,
    this.plotId,
    this.ph,
    this.organicMatter,
    this.phosphorus,
    this.potassium,
    this.calcium,
    this.magnesium,
    this.sulfur,
    this.aluminum,
    this.cationExchangeCapacity,
    this.baseSaturation,
    this.clayContent,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
  });

  // Converter de Map para objeto SoilAnalysis
  factory SoilAnalysis.fromMap(Map<String, dynamic> map) {
    return SoilAnalysis(
      id: map['id'],
      monitoringId: map['monitoring_id'],
      plotId: map['plot_id'],
      ph: map['ph'],
      organicMatter: map['organic_matter'],
      phosphorus: map['phosphorus'],
      potassium: map['potassium'],
      calcium: map['calcium'],
      magnesium: map['magnesium'],
      sulfur: map['sulfur'],
      aluminum: map['aluminum'],
      cationExchangeCapacity: map['cation_exchange_capacity'],
      baseSaturation: map['base_saturation'],
      clayContent: map['clay_content'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
    );
  }

  // Converter de objeto SoilAnalysis para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monitoring_id': monitoringId,
      'plot_id': plotId,
      'ph': ph,
      'organic_matter': organicMatter,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'calcium': calcium,
      'magnesium': magnesium,
      'sulfur': sulfur,
      'aluminum': aluminum,
      'cation_exchange_capacity': cationExchangeCapacity,
      'base_saturation': baseSaturation,
      'clay_content': clayContent,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  // Criar uma cópia do objeto com alterações
  SoilAnalysis copyWith({
    int? id,
    int? monitoringId,
    String? plotId,
    double? ph,
    double? organicMatter,
    double? phosphorus,
    double? potassium,
    double? calcium,
    double? magnesium,
    double? sulfur,
    double? aluminum,
    double? cationExchangeCapacity,
    double? baseSaturation,
    double? clayContent,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return SoilAnalysis(
      id: id ?? this.id,
      monitoringId: monitoringId ?? this.monitoringId,
      plotId: plotId ?? this.plotId,
      ph: ph ?? this.ph,
      organicMatter: organicMatter ?? this.organicMatter,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      calcium: calcium ?? this.calcium,
      magnesium: magnesium ?? this.magnesium,
      sulfur: sulfur ?? this.sulfur,
      aluminum: aluminum ?? this.aluminum,
      cationExchangeCapacity: cationExchangeCapacity ?? this.cationExchangeCapacity,
      baseSaturation: baseSaturation ?? this.baseSaturation,
      clayContent: clayContent ?? this.clayContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
