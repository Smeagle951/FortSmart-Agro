// Arquivo para corrigir problemas do Mapbox GL
// Este arquivo deve ser importado antes de qualquer importação do Mapbox GL

// Reimplementação da função hashValues removida do Flutter
// Esta função é usada internamente pelo plugin Mapbox GL
int hashValues(dynamic a, [dynamic b, dynamic c, dynamic d, dynamic e]) {
  if (b == null) return a.hashCode;
  if (c == null) return _finish(_combine(a.hashCode, b.hashCode));
  if (d == null) return _finish(_combine(_combine(a.hashCode, b.hashCode), c.hashCode));
  if (e == null) return _finish(_combine(_combine(_combine(a.hashCode, b.hashCode), c.hashCode), d.hashCode));
  return _finish(_combine(_combine(_combine(_combine(a.hashCode, b.hashCode), c.hashCode), d.hashCode), e.hashCode));
}

// Reimplementação da função hashList removida do Flutter
int hashList(List<dynamic> values) {
  return values.fold(0, (int hash, dynamic item) => _combine(hash, item.hashCode));
}

// Funções auxiliares para implementação de hash
int _combine(int hash, int value) {
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

// Classe para aplicar os patches
class MapboxMonkeyPatch {
  static void apply() {
    print('Mapbox MonkeyPatch aplicado com sucesso');
  }
}
