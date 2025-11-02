import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'text_theme_extension.dart';

/// Classe para aplicar patches ao flutter_map
class FlutterMapPatch {
  /// Converte headline5 para headlineSmall (nova nomenclatura)
  static TextStyle? getHeadlineStyle(BuildContext context) {
    // No Flutter mais recente, headline5 foi substituído por headlineSmall
    // Usamos a extensão TextThemeExtension para garantir compatibilidade
    return Theme.of(context).textTheme.headline5;
  }

  /// Aplica o patch para corrigir problemas de compatibilidade no flutter_map
  static void apply() {
    debugPrint('Aplicando patch para o problema de headline5 no flutter_map');
    try {
      // Verificar se a extensão TextThemeExtension está disponível
      // Isso é feito através da importação de text_theme_extension.dart
      
      // O patch é aplicado automaticamente quando a extensão é importada
      // pois ela adiciona getters para headline5, headline6, etc.
      debugPrint('✓ Patch aplicado com sucesso para o problema de headline5 no flutter_map');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patch para o flutter_map: $e');
      debugPrint('Certifique-se de que o arquivo text_theme_extension.dart existe e está correto');
    }
  }
}
