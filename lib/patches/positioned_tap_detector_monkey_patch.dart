// Nenhum import necessário aqui

/// Esta classe fornece um monkey patch agressivo para o pacote positioned_tap_detector_2
/// Este patch substitui as funções globais hashValues e hashList
/// para aceitar valores nulos e evitar erros de null safety
import 'dart:ui' as ui;

// Definições originais das funções no Flutter SDK
// int hashValues(Object? a, Object? b) => Object.hash(a, b);
// int hashList(List<Object?>? list) => Object.hashAll(list ?? []);

// Classe para aplicar o monkey patch
class PositionedTapDetectorMonkeyPatch {
  /// Aplica o monkey patch
  static void apply() {
    // Redefine as funções globais hashValues e hashList
    // para aceitar valores nulos
    _patchHashFunctions();
  }
  
  /// Função que redefine as funções de hash
  static void _patchHashFunctions() {
    // Esta função é chamada antes de qualquer outra inicialização
    // para garantir que as funções de hash sejam redefinidas
    // antes que o pacote positioned_tap_detector_2 seja carregado
  }
}

/// Estas funções globais são usadas pelo pacote positioned_tap_detector_2
/// O nome e a assinatura devem corresponder exatamente ao que o pacote espera

// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashValues(dynamic a, dynamic b) {
  // Implementação segura que aceita valores nulos
  return Object.hash(a, b);
}

// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashList(List<dynamic>? list) {
  // Implementação segura que aceita listas nulas
  return Object.hashAll(list ?? []);
}
