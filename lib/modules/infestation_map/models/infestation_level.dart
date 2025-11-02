import 'package:flutter/material.dart';

/// Enum para representar os níveis de infestação
enum InfestationLevel {
  baixo('BAIXO', 'Baixo', 0.0, 25.0, Colors.green),
  moderado('MODERADO', 'Moderado', 25.1, 50.0, Colors.orange),
  alto('ALTO', 'Alto', 50.1, 75.0, Colors.deepOrange),
  critico('CRITICO', 'Crítico', 75.1, 100.0, Colors.red);

  const InfestationLevel(
    this.code,
    this.label,
    this.minValue,
    this.maxValue,
    this.color,
  );

  final String code;
  final String label;
  final double minValue;
  final double maxValue;
  final Color color;

  /// Obtém o nível baseado no valor percentual
  static InfestationLevel fromPercentage(double percentage) {
    if (percentage <= baixo.maxValue) return baixo;
    if (percentage <= moderado.maxValue) return moderado;
    if (percentage <= alto.maxValue) return alto;
    return critico;
  }

  /// Obtém o nível baseado no código
  static InfestationLevel fromCode(String code) {
    return InfestationLevel.values.firstWhere(
      (level) => level.code == code,
      orElse: () => InfestationLevel.baixo,
    );
  }

  /// Verifica se um valor está dentro do intervalo deste nível
  bool containsValue(double value) {
    return value >= minValue && value <= maxValue;
  }

  /// Obtém o próximo nível (para progressão)
  InfestationLevel? get nextLevel {
    switch (this) {
      case InfestationLevel.baixo:
        return InfestationLevel.moderado;
      case InfestationLevel.moderado:
        return InfestationLevel.alto;
      case InfestationLevel.alto:
        return InfestationLevel.critico;
      case InfestationLevel.critico:
        return null;
    }
  }

  /// Obtém o nível anterior (para regressão)
  InfestationLevel? get previousLevel {
    switch (this) {
      case InfestationLevel.baixo:
        return null;
      case InfestationLevel.moderado:
        return InfestationLevel.baixo;
      case InfestationLevel.alto:
        return InfestationLevel.moderado;
      case InfestationLevel.critico:
        return InfestationLevel.alto;
    }
  }

  /// Obtém a cor com opacidade
  Color getColorWithOpacity(double opacity) {
    return color.withOpacity(opacity);
  }

  /// Obtém a cor de fundo (versão clara)
  Color get backgroundColor {
    return color.withOpacity(0.1);
  }

  /// Obtém a cor do texto
  Color get textColor {
    return color.withOpacity(0.8);
  }

  @override
  String toString() => label;
}
