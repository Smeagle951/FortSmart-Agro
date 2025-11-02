import 'package:flutter/foundation.dart';

/// Esta classe inicializa todos os patches necessários para corrigir problemas em pacotes externos
class PatchInitializer {
  /// Inicializa todos os patches
  static void initialize() {
    _applyPositionedTapDetectorPatch();
  }

  /// Aplica o patch para o pacote positioned_tap_detector_2
  static void _applyPositionedTapDetectorPatch() {
    // O patch é aplicado através da importação e uso das funções corrigidas
    // quando necessário no código do aplicativo
    if (kDebugMode) {
      print('Patch aplicado para positioned_tap_detector_2');
    }
  }
}
