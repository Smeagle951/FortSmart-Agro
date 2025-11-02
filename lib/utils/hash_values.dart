// Implementação da função hashValues que foi removida do Flutter
// Esta função é usada pelo plugin mapbox_gl



/// Gera um valor de hash combinando os hashes de [objects].
///
/// Esta função substitui a função hashValues que foi removida do Flutter.
int hashValues(Object? a, [Object? b, Object? c, Object? d, Object? e]) {
  return Object.hash(a, b, c, d, e);
}

/// Gera um valor de hash combinando os hashes de uma lista de objetos.
///
/// Esta função substitui a função hashList que foi removida do Flutter.
int hashList(List<Object?> objects) {
  return Object.hashAll(objects);
}
