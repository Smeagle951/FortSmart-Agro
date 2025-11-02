class Prescription {
  int? id;
  int plotId;
  String title;
  String? description;
  String prescriptionDate;
  String? applicationDate;
  String? status;
  double? area;
  double? expectedYield;
  String? targetCrop;
  int? soilAnalysisId;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;

  // Getters adicionais
  String get name => title;
  bool get synced => syncStatus == 1;

  Prescription({
    this.id,
    required this.plotId,
    required this.title,
    this.description,
    required this.prescriptionDate,
    this.applicationDate,
    this.status,
    this.area,
    this.expectedYield,
    this.targetCrop,
    this.soilAnalysisId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
  });

  // Converter de Map para objeto Prescription
  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      plotId: map['plot_id'],
      title: map['title'],
      description: map['description'],
      prescriptionDate: map['prescription_date'],
      applicationDate: map['application_date'],
      status: map['status'],
      area: map['area'] != null ? double.parse(map['area'].toString()) : null,
      expectedYield: map['expected_yield'] != null ? double.parse(map['expected_yield'].toString()) : null,
      targetCrop: map['target_crop'],
      soilAnalysisId: map['soil_analysis_id'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
    );
  }

  // Converter de objeto Prescription para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plot_id': plotId,
      'title': title,
      'description': description,
      'prescription_date': prescriptionDate,
      'application_date': applicationDate,
      'status': status,
      'area': area,
      'expected_yield': expectedYield,
      'target_crop': targetCrop,
      'soil_analysis_id': soilAnalysisId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  // Criar uma cópia do objeto com alterações
  Prescription copyWith({
    int? id,
    int? plotId,
    String? title,
    String? description,
    String? prescriptionDate,
    String? applicationDate,
    String? status,
    double? area,
    double? expectedYield,
    String? targetCrop,
    int? soilAnalysisId,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return Prescription(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      title: title ?? this.title,
      description: description ?? this.description,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      area: area ?? this.area,
      expectedYield: expectedYield ?? this.expectedYield,
      targetCrop: targetCrop ?? this.targetCrop,
      soilAnalysisId: soilAnalysisId ?? this.soilAnalysisId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
