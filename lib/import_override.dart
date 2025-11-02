// Este arquivo fornece substituições para pacotes problemáticos
// Ele deve ser importado antes de qualquer outro import nos arquivos que usam o pacote

// Substituição para positioned_tap_detector_2
export 'patches/positioned_tap_detector_2.dart';

// Funções globais seguras para null safety
int hashValues(dynamic a, dynamic b) => Object.hash(a, b);
int hashList(List<dynamic>? list) => Object.hashAll(list ?? []);
