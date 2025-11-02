/// Status do download de mapas offline
enum OfflineMapStatus {
  /// Mapa não foi baixado
  notDownloaded,
  
  /// Download em andamento
  downloading,
  
  /// Download concluído com sucesso
  downloaded,
  
  /// Erro durante o download
  error,
  
  /// Download pausado
  paused,
  
  /// Atualização disponível
  updateAvailable,
}

/// Extensões para OfflineMapStatus
extension OfflineMapStatusExtension on OfflineMapStatus {
  /// Retorna o texto descritivo do status
  String get displayName {
    switch (this) {
      case OfflineMapStatus.notDownloaded:
        return 'Não baixado';
      case OfflineMapStatus.downloading:
        return 'Baixando';
      case OfflineMapStatus.downloaded:
        return 'Baixado';
      case OfflineMapStatus.error:
        return 'Erro';
      case OfflineMapStatus.paused:
        return 'Pausado';
      case OfflineMapStatus.updateAvailable:
        return 'Atualização disponível';
    }
  }
  
  /// Retorna o ícone correspondente ao status
  String get icon {
    switch (this) {
      case OfflineMapStatus.notDownloaded:
        return '❌';
      case OfflineMapStatus.downloading:
        return '⏳';
      case OfflineMapStatus.downloaded:
        return '✅';
      case OfflineMapStatus.error:
        return '⚠️';
      case OfflineMapStatus.paused:
        return '⏸️';
      case OfflineMapStatus.updateAvailable:
        return '🔄';
    }
  }
  
  /// Verifica se o mapa está disponível offline
  bool get isAvailableOffline {
    return this == OfflineMapStatus.downloaded;
  }
  
  /// Verifica se está em processo de download
  bool get isDownloading {
    return this == OfflineMapStatus.downloading;
  }
  
  /// Verifica se há erro
  bool get hasError {
    return this == OfflineMapStatus.error;
  }
}
