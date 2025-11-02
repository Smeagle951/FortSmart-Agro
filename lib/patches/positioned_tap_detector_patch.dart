/// Patch para corrigir o problema de null safety no positioned_tap_detector_2
/// Este arquivo substitui a função hashValues que está causando o erro
class PositionedTapDetectorPatch {
  /// Versão corrigida da função hashValues que lida com valores nulos
  static int hashValues(Object? a, Object? b) {
    // Implementação segura para null safety
    return Object.hash(a, b);
  }
}
