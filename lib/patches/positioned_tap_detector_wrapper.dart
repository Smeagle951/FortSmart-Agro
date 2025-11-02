import 'dart:ui';

/// Este arquivo fornece uma implementação segura para substituir a função hashValues
/// do pacote positioned_tap_detector_2 que está causando erro de null safety

/// Implementação segura da função hashValues que lida com valores nulos
int hashValues(Offset? a, Offset? b) {
  return Object.hash(a, b);
}

/// Implementação segura da função hashList que lida com valores nulos
int hashList(List<Object?>? list) {
  return Object.hashAll(list ?? []);
}
