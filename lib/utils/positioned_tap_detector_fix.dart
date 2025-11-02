import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Importamos o patch principal para evitar duplicação
import 'positioned_tap_detector_patch.dart';

/// Esta classe é um alias para a implementação do patch principal
/// para manter compatibilidade com código existente que possa estar usando TapPositionFixed
typedef TapPositionFixed = TapPosition;

/// Aplicar este patch no main.dart antes de executar o app
/// Exemplo:
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   applyPositionedTapDetectorFix();
///   runApp(MyApp());
/// }
Future<void> applyPositionedTapDetectorFix() async {
  // Delegamos para a implementação principal para evitar duplicação
  debugPrint('Redirecionando para a implementação principal do patch');
  return applyPositionedTapDetectorPatch();
}
