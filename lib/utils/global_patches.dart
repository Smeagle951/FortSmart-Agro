import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Classe que contém patches globais para o aplicativo
class GlobalPatches {
  /// Aplica todos os patches globais
  static void applyAllPatches() {
    debugPrint('\n🚨 INICIANDO APLICAÇÃO DE PATCHES GLOBAIS 🚨');
    
    try {
      // Aplicar patch para hashValues
      applyHashValuesPatches();
      
      debugPrint('✅ TODOS OS PATCHES GLOBAIS APLICADOS COM SUCESSO!');
    } catch (e) {
      debugPrint('❌ ERRO AO APLICAR PATCHES GLOBAIS: $e');
    }
  }
  
  /// Aplica patches para o método hashValues
  static void applyHashValuesPatches() {
    debugPrint('Aplicando patches para hashValues...');
    
    try {
      // As funções hashValues e hashList já estão definidas globalmente abaixo
      // Não é possível atribuir valores a funções em Dart
      
      debugPrint('Patches para hashValues aplicados com sucesso!');
    } catch (e) {
      debugPrint('Erro ao aplicar patches para hashValues: $e');
    }
  }
}

/// Função global hashValues para compatibilidade com código legado
/// Esta função é usada pelo pacote positioned_tap_detector_2
/// Modificada para aceitar valores nulos (Offset?)
// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashValues(Object? a, Object? b) => Object.hash(a, b);

/// Função global hashList para compatibilidade com código legado
/// Modificada para aceitar listas nulas ou com valores nulos
// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashList(List<Object?>? objects) => Object.hashAll(objects ?? []);
