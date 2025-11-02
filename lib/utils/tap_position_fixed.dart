import 'package:flutter/material.dart';

/// Classe para substituir a implementação problemática de TapPosition no pacote positioned_tap_detector_2
class TapPosition {
  final Offset global;
  final Offset relative;

  const TapPosition({
    required this.global,
    required this.relative,
  });

  @override
  int get hashCode => Object.hash(global, relative);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TapPosition &&
          runtimeType == other.runtimeType &&
          global == other.global &&
          relative == other.relative;

  /// Método para criar uma instância de TapPosition a partir de um evento de toque
  static TapPosition fromTap(Offset globalPosition, Offset localPosition) {
    return TapPosition(
      global: globalPosition,
      relative: localPosition,
    );
  }
}
