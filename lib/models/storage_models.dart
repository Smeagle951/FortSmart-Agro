/// Enum para definir estratégias de limpeza de armazenamento
enum StorageCleanupStrategy {
  /// Limpa os arquivos mais antigos primeiro
  oldestFirst,
  
  /// Limpa os arquivos maiores primeiro
  largestFirst,
  
  /// Limpa arquivos temporários e de cache
  tempAndCache,
  
  /// Limpa arquivos de log antigos
  oldLogs,
  
  /// Limpa apenas imagens não referenciadas
  orphanedImages
}

/// Enum para definir o status do processo de recuperação
enum RecoveryStatus {
  idle,
  checking,
  analyzing,
  validatingImages,
  fixingData,
  fixingImages,
  fixingDatabase,
  databaseError,
  cleaning,
  completed,
  failed,
  partialSuccess
}

/// Classe para representar o status do armazenamento do dispositivo
class StorageStatus {
  /// Espaço total em MB
  final double totalSpaceMB;
  
  /// Espaço disponível em MB
  final double availableSpaceMB;
  
  /// Espaço usado pelo aplicativo em MB
  final double appUsageMB;
  
  /// Espaço usado por imagens em MB
  final double imagesMB;
  
  /// Espaço usado por logs em MB
  final double logsMB;
  
  /// Espaço usado por arquivos temporários em MB
  final double tempFilesMB;
  
  /// Espaço usado por banco de dados em MB
  final double databaseMB;
  
  /// Caminho do diretório de armazenamento principal
  final String storagePath;
  
  StorageStatus({
    required this.totalSpaceMB,
    required this.availableSpaceMB,
    required this.appUsageMB,
    this.imagesMB = 0.0,
    this.logsMB = 0.0,
    this.tempFilesMB = 0.0,
    this.databaseMB = 0.0,
    required this.storagePath
  });
  
  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'totalSpaceMB': totalSpaceMB,
      'availableSpaceMB': availableSpaceMB,
      'appUsageMB': appUsageMB,
      'imagesMB': imagesMB,
      'logsMB': logsMB,
      'tempFilesMB': tempFilesMB,
      'databaseMB': databaseMB,
      'storagePath': storagePath,
      'usedPercentage': (totalSpaceMB > 0) ? ((totalSpaceMB - availableSpaceMB) / totalSpaceMB * 100).round() : 0,
      'appUsagePercentage': (totalSpaceMB > 0) ? (appUsageMB / totalSpaceMB * 100).round() : 0,
    };
  }
}

/// Classe para representar o resultado de uma operação de limpeza de armazenamento
class StorageCleanupResult {
  /// Indica se a operação foi bem-sucedida
  final bool success;
  
  /// Espaço liberado em MB
  final double spaceClearedMB;
  
  /// Número de arquivos removidos
  final int filesRemoved;
  
  /// Mensagem de erro, se houver
  final String? error;
  
  /// Detalhes da operação
  final Map<String, dynamic>? details;
  
  StorageCleanupResult({
    required this.success,
    required this.spaceClearedMB,
    required this.filesRemoved,
    this.error,
    this.details,
  });
  
  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'spaceClearedMB': spaceClearedMB,
      'filesRemoved': filesRemoved,
      'error': error,
      'details': details,
    };
  }
}

/// Classe para representar informações sobre o progresso da recuperação
class RecoveryProgress {
  /// ID da amostra sendo processada
  final String sampleId;
  
  /// Progresso atual (0-100)
  final int progress;
  
  /// Status atual
  final String status;
  
  /// Mensagem detalhada
  final String message;
  
  /// Timestamp da atualização
  final DateTime timestamp;
  
  /// Detalhes adicionais
  final Map<String, dynamic>? details;
  
  RecoveryProgress({
    required this.sampleId,
    required this.progress,
    required this.status,
    required this.message,
    DateTime? timestamp,
    this.details,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'sampleId': sampleId,
      'progress': progress,
      'status': status,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
