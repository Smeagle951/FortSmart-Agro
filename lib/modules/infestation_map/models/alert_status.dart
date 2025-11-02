/// Enum para representar o status de um alerta de infestação
enum AlertStatus {
  /// Alerta ativo e não reconhecido
  active('ativo'),
  
  /// Alerta reconhecido mas não resolvido
  acknowledged('reconhecido'),
  
  /// Alerta resolvido
  resolved('resolvido');

  const AlertStatus(this.label);
  
  /// Label em português para exibição
  final String label;
  
  /// Converte de string para enum
  static AlertStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ativo':
      case 'active':
        return AlertStatus.active;
      case 'reconhecido':
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'resolvido':
      case 'resolved':
        return AlertStatus.resolved;
      default:
        return AlertStatus.active;
    }
  }
  
  /// Converte para string
  String toString() => label;
}
