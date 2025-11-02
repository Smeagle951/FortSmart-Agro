class MonitoringImage {
  int? id;
  int monitoringId;
  String imagePath;
  String? description;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;

  MonitoringImage({
    this.id,
    required this.monitoringId,
    required this.imagePath,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
  });

  // Converter de Map para objeto MonitoringImage
  factory MonitoringImage.fromMap(Map<String, dynamic> map) {
    return MonitoringImage(
      id: map['id'],
      monitoringId: map['monitoring_id'],
      imagePath: map['image_path'],
      description: map['description'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
    );
  }

  // Converter de objeto MonitoringImage para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monitoring_id': monitoringId,
      'image_path': imagePath,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  // Criar uma cópia do objeto com alterações
  MonitoringImage copyWith({
    int? id,
    int? monitoringId,
    String? imagePath,
    String? description,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
  }) {
    return MonitoringImage(
      id: id ?? this.id,
      monitoringId: monitoringId ?? this.monitoringId,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}
