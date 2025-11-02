// Arquivo de substituição direta para o pacote positioned_tap_detector_2
// Este arquivo fornece implementações seguras para null safety das funções problemáticas

// Implementações seguras para null safety que serão usadas globalmente
// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashValues(dynamic a, dynamic b) => Object.hash(a ?? 0, b ?? 0);

// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashList(List<dynamic>? list) => Object.hashAll(list ?? []);
