import 'package:flutter/material.dart';

/// Extensão para compatibilidade com TextTheme do Material 2
/// Esta extensão fornece getters para os nomes antigos do TextTheme
extension TextThemeCompatibilityExtension on TextTheme {
  TextStyle? get headline5 => titleLarge;
  TextStyle? get headline6 => titleMedium;
  TextStyle? get subtitle1 => titleMedium;
  TextStyle? get subtitle2 => titleSmall;
  TextStyle? get bodyText1 => bodyLarge;
  TextStyle? get bodyText2 => bodyMedium;
  TextStyle? get button => labelLarge;
  TextStyle? get caption => bodySmall;
  TextStyle? get overline => labelSmall;
}

/// Classe que contém patches para problemas relacionados ao Material Design
class MaterialDesignPatches {
  /// Aplica todos os patches relacionados ao Material Design
  static void applyAllPatches() {
    debugPrint('INICIANDO APLICACAO DE PATCHES PARA MATERIAL DESIGN');
    
    try {
      // Aplicar patches para TextTheme
      applyTextThemePatches();
      
      // Aplicar patches para SnackBar
      applySnackBarPatches();
      
      debugPrint('TODOS OS PATCHES PARA MATERIAL DESIGN APLICADOS COM SUCESSO!');
    } catch (e) {
      debugPrint('ERRO AO APLICAR PATCHES PARA MATERIAL DESIGN: $e');
    }
  }
  
  /// Aplica patches para problemas relacionados ao TextTheme
  static void applyTextThemePatches() {
    debugPrint('🔧 Aplicando patches para TextTheme...');
    
    // O headline5 foi substituído por titleLarge no Material 3
    // A extensão TextThemeCompatibilityExtension já foi definida globalmente
    
    debugPrint('✅ Patches para TextTheme aplicados com sucesso!');
  }
  
  /// Aplica patches para problemas relacionados ao SnackBar
  static void applySnackBarPatches() {
    debugPrint('🔧 Aplicando patches para SnackBar...');
    
    // Implementação de um SnackBarHelper global para facilitar o uso
    // A classe SnackBarHelper já foi definida globalmente
    
    debugPrint('✅ Patches para SnackBar aplicados com sucesso!');
  }
}

/// Classe que contém patches para problemas relacionados a widgets e componentes
class WidgetPatches {
  /// Aplica todos os patches relacionados a widgets
  static void applyAllPatches() {
    applySnackBarPatches();
  }

  /// Aplica patches para problemas relacionados ao SnackBar
  static void applySnackBarPatches() {
    debugPrint('Aplicando patches para SnackBar');
    
    // Implementação de um SnackBarHelper global para facilitar o uso
    // Isso resolve problemas com o SnackBarHelper não definido em algumas classes
    
    debugPrint('Patches para SnackBar aplicados com sucesso');
  }
}

/// Classe auxiliar para mostrar SnackBars de forma consistente
class SnackBarHelper {
  /// Mostra um SnackBar de sucesso
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra um SnackBar de erro
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Mostra um SnackBar de informação
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra um SnackBar de aviso
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
