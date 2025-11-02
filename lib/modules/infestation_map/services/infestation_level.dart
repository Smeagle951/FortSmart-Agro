/// Enum para níveis de infestação
enum InfestationLevel {
  low,
  medium,
  high,
  critical,
}

/// Extensão para converter níveis de infestação para string
extension InfestationLevelExtension on InfestationLevel {
  String get displayName {
    switch (this) {
      case InfestationLevel.low:
        return 'BAIXO';
      case InfestationLevel.medium:
        return 'MÉDIO';
      case InfestationLevel.high:
        return 'ALTO';
      case InfestationLevel.critical:
        return 'CRÍTICO';
    }
  }

  String get colorCode {
    switch (this) {
      case InfestationLevel.low:
        return '#4CAF50'; // Verde
      case InfestationLevel.medium:
        return '#FF9800'; // Laranja
      case InfestationLevel.high:
        return '#F44336'; // Vermelho
      case InfestationLevel.critical:
        return '#D32F2F'; // Vermelho escuro
    }
  }

  double get threshold {
    switch (this) {
      case InfestationLevel.low:
        return 0.0;
      case InfestationLevel.medium:
        return 25.0;
      case InfestationLevel.high:
        return 50.0;
      case InfestationLevel.critical:
        return 75.0;
    }
  }
}

/// Classe para determinar nível de infestação baseado em valores
class InfestationLevelDeterminer {
  /// Determina o nível de infestação baseado em um valor percentual
  static InfestationLevel determineLevel(double percentage) {
    if (percentage >= 75.0) return InfestationLevel.critical;
    if (percentage >= 50.0) return InfestationLevel.high;
    if (percentage >= 25.0) return InfestationLevel.medium;
    return InfestationLevel.low;
  }

  /// Determina o nível de infestação baseado em um valor e thresholds específicos
  static InfestationLevel determineLevelWithThresholds(
    double value,
    double lowThreshold,
    double mediumThreshold,
    double highThreshold,
  ) {
    if (value >= highThreshold) return InfestationLevel.critical;
    if (value >= mediumThreshold) return InfestationLevel.high;
    if (value >= lowThreshold) return InfestationLevel.medium;
    return InfestationLevel.low;
  }

  /// Obtém a descrição do nível de infestação
  static String getDescription(InfestationLevel level) {
    switch (level) {
      case InfestationLevel.low:
        return 'Infestação baixa - Monitoramento normal';
      case InfestationLevel.medium:
        return 'Infestação moderada - Atenção aumentada';
      case InfestationLevel.high:
        return 'Infestação alta - Ação recomendada';
      case InfestationLevel.critical:
        return 'Infestação crítica - Ação imediata necessária';
    }
  }
}
