import 'dart:ui';

/// Esta extensão corrige o problema de null safety no positioned_tap_detector_2
/// Substitui a função hashValues que está causando o erro
extension TapDetectorExtension on Object {
  /// Versão segura da função hashValues que lida com valores nulos
  static int hashValues(Offset? a, Offset? b) {
    return Object.hash(a, b);
  }
}
