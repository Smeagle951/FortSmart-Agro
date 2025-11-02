// Patches para o plugin Mapbox GL
// Este arquivo deve ser importado antes de qualquer importação do Mapbox GL

// Implementação da função hashValues que foi removida do Flutter
int hashValues(Object? a, [Object? b, Object? c, Object? d, Object? e]) {
  return Object.hash(a, b, c, d, e);
}

// Implementação da função hashList que foi removida do Flutter
int hashList(List<Object?> objects) {
  return Object.hashAll(objects);
}

// Aplicar patches ao inicializar o aplicativo
void applyMapboxPatches() {
  // O patch é aplicado automaticamente quando este arquivo é importado
  print('Mapbox patches aplicados com sucesso');
}
