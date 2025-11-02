import 'dart:io';

/// Classe para rastrear o progresso de upload de uma imagem
class ImageUploadProgress {
  /// ID único para o upload
  final String uploadId;
  
  /// ID da entidade à qual a imagem pertence (amostra, ponto, etc.)
  final String entityId;
  
  /// Tipo da entidade (amostra, ponto, etc.)
  final String entityType;
  
  /// Arquivo da imagem sendo enviada
  final File imageFile;
  
  /// Nome do arquivo da imagem
  final String fileName;
  
  /// Tamanho total do arquivo em bytes
  final int totalBytes;
  
  /// Bytes enviados até o momento
  int bytesUploaded;
  
  /// Status atual do upload (pending, uploading, completed, failed, cancelled)
  String status;
  
  /// Mensagem de erro (se houver)
  String? error;
  
  /// Timestamp de início do upload
  final DateTime startTime;
  
  /// Timestamp de conclusão do upload
  DateTime? endTime;

  /// Construtor da classe
  ImageUploadProgress({
    required this.uploadId,
    required this.entityId,
    required this.entityType,
    required this.imageFile,
    required this.fileName,
    required this.totalBytes,
    this.bytesUploaded = 0,
    this.status = 'pending',
    this.error,
    DateTime? startTime,
  }) : this.startTime = startTime ?? DateTime.now();

  /// Percentual de conclusão do upload (0-100)
  double get percentComplete {
    if (totalBytes <= 0) return 0;
    return (bytesUploaded / totalBytes) * 100;
  }

  /// Velocidade de upload em bytes por segundo
  double get uploadSpeed {
    if (bytesUploaded <= 0) return 0;
    
    final now = DateTime.now();
    final duration = endTime != null
        ? endTime!.difference(startTime).inSeconds
        : now.difference(startTime).inSeconds;
    
    if (duration <= 0) return 0;
    
    return bytesUploaded / duration;
  }
  
  /// Tempo estimado para conclusão em segundos
  int get estimatedTimeRemaining {
    if (bytesUploaded <= 0 || percentComplete >= 100) return 0;
    
    final bytesRemaining = totalBytes - bytesUploaded;
    final speed = uploadSpeed;
    
    if (speed <= 0) return 0;
    
    return (bytesRemaining / speed).round();
  }
  
  /// Indica se o upload foi concluído com sucesso
  bool get isCompleted => status == 'completed';
  
  /// Indica se o upload falhou
  bool get isFailed => status == 'failed';
  
  /// Indica se o upload está em andamento
  bool get isInProgress => status == 'uploading';
  
  /// Indica se o upload está aguardando para iniciar
  bool get isPending => status == 'pending';
  
  /// Indica se o upload foi cancelado
  bool get isCancelled => status == 'cancelled';
  
  /// Cria uma cópia do objeto com alguns campos alterados
  ImageUploadProgress copyWith({
    String? uploadId,
    String? entityId,
    String? entityType,
    File? imageFile,
    String? fileName,
    int? totalBytes,
    int? bytesUploaded,
    String? status,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ImageUploadProgress(
      uploadId: uploadId ?? this.uploadId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      imageFile: imageFile ?? this.imageFile,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesUploaded: bytesUploaded ?? this.bytesUploaded,
      status: status ?? this.status,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
    )..endTime = endTime ?? this.endTime;
  }
  
  /// Atualiza o progresso do upload
  void updateProgress(int newBytesUploaded) {
    bytesUploaded = newBytesUploaded;
    if (bytesUploaded >= totalBytes) {
      status = 'completed';
      endTime = DateTime.now();
    } else {
      status = 'uploading';
    }
  }
  
  /// Marca o upload como concluído
  void markCompleted() {
    bytesUploaded = totalBytes;
    status = 'completed';
    endTime = DateTime.now();
  }
  
  /// Marca o upload como falho
  void markFailed(String errorMessage) {
    status = 'failed';
    error = errorMessage;
    endTime = DateTime.now();
  }
  
  /// Marca o upload como cancelado
  void markCancelled() {
    status = 'cancelled';
    endTime = DateTime.now();
  }
  
  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'uploadId': uploadId,
      'entityId': entityId,
      'entityType': entityType,
      'fileName': fileName,
      'totalBytes': totalBytes,
      'bytesUploaded': bytesUploaded,
      'percentComplete': percentComplete,
      'status': status,
      'error': error,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'uploadSpeed': uploadSpeed,
      'estimatedTimeRemaining': estimatedTimeRemaining,
    };
  }
}

/// Classe para gerenciar o progresso de múltiplos uploads de imagens
class ImageUploadBatch {
  /// ID único para o lote de uploads
  final String batchId;
  
  /// Lista de progresso de uploads individuais
  final List<ImageUploadProgress> uploads;
  
  /// Timestamp de início do lote
  final DateTime startTime;
  
  /// Timestamp de conclusão do lote
  DateTime? endTime;
  
  /// Status atual do lote
  String status;
  
  /// Número total de uploads no lote
  int get totalUploads => uploads.length;
  
  /// Número de uploads concluídos
  int get completedUploads => uploads.where((u) => u.isCompleted).length;
  
  /// Número de uploads falhos
  int get failedUploads => uploads.where((u) => u.isFailed).length;
  
  /// Número de uploads em andamento
  int get inProgressUploads => uploads.where((u) => u.isInProgress).length;
  
  /// Número de uploads pendentes
  int get pendingUploads => uploads.where((u) => u.isPending).length;
  
  /// Percentual de conclusão do lote (0-100)
  double get percentComplete {
    if (uploads.isEmpty) return 0;
    
    final totalBytes = uploads.fold<int>(0, (sum, item) => sum + item.totalBytes);
    final uploadedBytes = uploads.fold<int>(0, (sum, item) => sum + item.bytesUploaded);
    
    return totalBytes > 0 ? (uploadedBytes / totalBytes * 100) : 0;
  }
  
  /// Indica se todos os uploads foram concluídos (com sucesso ou falha)
  bool get isCompleted => 
      pendingUploads == 0 && inProgressUploads == 0;
  
  /// Cria uma nova instância de ImageUploadBatch
  ImageUploadBatch({
    required this.batchId,
    required this.uploads,
    this.status = 'in_progress',
  }) : startTime = DateTime.now();
  
  /// Adiciona um novo upload ao lote
  void addUpload(ImageUploadProgress upload) {
    uploads.add(upload);
  }
  
  /// Atualiza o status do lote com base nos uploads individuais
  void updateStatus() {
    if (isCompleted) {
      status = failedUploads > 0 ? 'completed_with_errors' : 'completed';
      endTime = DateTime.now();
    } else {
      status = 'in_progress';
    }
  }
  
  /// Cancela todos os uploads pendentes ou em andamento
  void cancelAll() {
    for (final upload in uploads) {
      if (upload.isPending || upload.isInProgress) {
        upload.markCancelled();
      }
    }
    status = 'cancelled';
    endTime = DateTime.now();
  }
  
  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'totalUploads': totalUploads,
      'completedUploads': completedUploads,
      'failedUploads': failedUploads,
      'inProgressUploads': inProgressUploads,
      'pendingUploads': pendingUploads,
      'percentComplete': percentComplete,
      'status': status,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'uploads': uploads.map((u) => u.toMap()).toList(),
    };
  }
}
