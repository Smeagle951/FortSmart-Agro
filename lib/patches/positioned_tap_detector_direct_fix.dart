// Arquivo de substituição direta para o pacote positioned_tap_detector_2
// Este arquivo será incluído no projeto antes do pacote original

// Definição das funções problemáticas com suporte a null safety
// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashValues(dynamic a, dynamic b) => Object.hash(a, b);

// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashList(List<dynamic>? list) => Object.hashAll(list ?? []);
