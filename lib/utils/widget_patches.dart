import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Classe que contém patches para widgets do Flutter
class WidgetPatches {
  /// Aplica todos os patches para widgets
  static void applyAllPatches() {
    debugPrint('\n🔧 INICIANDO APLICAÇÃO DE PATCHES PARA WIDGETS 🔧');
    
    try {
      // Aplicar patches para SnackBar
      applySnackBarPatches();
      
      debugPrint('✅ TODOS OS PATCHES PARA WIDGETS APLICADOS COM SUCESSO!');
    } catch (e) {
      debugPrint('❌ ERRO AO APLICAR PATCHES PARA WIDGETS: $e');
    }
  }
  
  /// Aplica patches para SnackBar
  static void applySnackBarPatches() {
    debugPrint('Aplicando patches para SnackBar...');
    
    try {
      // O SnackBarHelper já está implementado em snackbar_helper.dart
      // Este método apenas registra que o patch foi aplicado
      
      debugPrint('Patches para SnackBar aplicados com sucesso!');
    } catch (e) {
      debugPrint('Erro ao aplicar patches para SnackBar: $e');
    }
  }
}
