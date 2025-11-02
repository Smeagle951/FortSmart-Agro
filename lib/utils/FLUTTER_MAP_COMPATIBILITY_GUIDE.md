# Guia de Compatibilidade com Flutter Map 5.0.0

Este documento explica as correções feitas para resolver problemas de compatibilidade com o pacote flutter_map versão 5.0.0 no projeto FortSmart Agro.

## Problemas Resolvidos

### 1. Substituição de `child` por `builder` em Markers

Na versão 5.0.0 do flutter_map, o parâmetro `child` foi substituído por `builder` na classe `Marker`. O `builder` recebe um `BuildContext` e deve retornar um widget.

**Antes:**
```dart
Marker(
  point: LatLng(-15.7, -47.8),
  child: Icon(Icons.location_on),
)
```

**Depois:**
```dart
Marker(
  point: LatLng(-15.7, -47.8),
  builder: (context) => Icon(Icons.location_on),
)
```

### 2. Substituição de `initialCenter` e `initialZoom` por `center` e `zoom`

Na versão 5.0.0, os parâmetros `initialCenter` e `initialZoom` foram renomeados para `center` e `zoom` na classe `MapOptions`.

**Antes:**
```dart
MapOptions(
  initialCenter: LatLng(-15.7, -47.8),
  initialZoom: 15.0,
)
```

**Depois:**
```dart
MapOptions(
  center: LatLng(-15.7, -47.8),
  zoom: 15.0,
)
```

### 3. Remoção da propriedade `camera` do MapController

Na versão 5.0.0, a propriedade `camera` foi removida do `MapController`. Em vez disso, as propriedades `center` e `zoom` estão disponíveis diretamente no `MapController`.

**Antes:**
```dart
mapController.camera.center
mapController.camera.zoom
```

**Depois:**
```dart
mapController.center
mapController.zoom
```

### 4. Parâmetros não suportados

Alguns parâmetros não são mais suportados na versão 5.0.0:

- `backgroundColor` em `MapOptions`
- `onTap` em `Polygon`
- `alignment` em `Marker`
- `InteractionOptions` em `MapOptions`

### 5. Substituição de tipos

- `Point<num>` do `dart:math` deve ser substituído por `CustomPoint<num>` do flutter_map
- `fitCamera` foi substituído por `fitBounds`

### 6. Outros ajustes

- `tooltipBgColor` foi renomeado para `tooltipBackgroundColor` em `BarTouchTooltipData`

## Soluções Implementadas

### 1. MapControllerAdapter

Criamos um adaptador para o `MapController` que simula a propriedade `camera` que existia em versões anteriores:

```dart
class MapControllerAdapter {
  final MapController _controller;
  
  MapControllerAdapter(this._controller);
  
  LatLng get center => _controller.center;
  double get zoom => _controller.zoom;
  
  // Simula a propriedade camera
  CameraAdapter get camera => CameraAdapter(this);
}

class CameraAdapter {
  final MapControllerAdapter _adapter;
  
  CameraAdapter(this._adapter);
  
  LatLng get center => _adapter.center;
  double get zoom => _adapter.zoom;
}
```

### 2. MapOptionsExtension

Adicionamos uma extensão para a classe `MapOptions` que fornece o método `copyWith` que não existe na versão 5.0.0:

```dart
extension MapOptionsExtension on MapOptions {
  MapOptions copyWith({
    LatLng? center,
    double? zoom,
    // outros parâmetros...
  }) {
    return MapOptions(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      // outros parâmetros...
    );
  }
}
```

### 3. Scripts de Correção Automática

Criamos scripts para corrigir automaticamente os problemas mais comuns em todo o projeto:

- `flutter_map_fixer.dart`: Script básico para correções simples
- `flutter_map_bulk_fixer.dart`: Script avançado que percorre todos os arquivos do projeto e aplica correções

### 4. Arquivos Corrigidos

- `map_compatibility_layer_fixed.dart`: Corrigido para usar `center` e `zoom` em vez de `initialCenter` e `initialZoom`
- `map_tiler_map_widget_fixed.dart`: Corrigido para usar `TalhaoModel` em vez de `Talhao` e remover `onTap` de `Polygon`
- `map_tiler_map_widget_corrected.dart`: Versão completamente corrigida do widget de mapa
- Vários outros arquivos foram corrigidos pelo script de correção automática

## Como Usar as Correções

### 1. Para MapController

Use o adaptador para acessar propriedades do `MapController`:

```dart
final mapController = MapController();
final adapter = MapControllerAdapter(mapController);

// Acesso ao centro e zoom
final center = adapter.center;
final zoom = adapter.zoom;

// Ou usando a propriedade camera simulada
final centerViaCamera = adapter.camera.center;
```

### 2. Para Markers

Use `builder` em vez de `child`:

```dart
Marker(
  point: LatLng(-15.7, -47.8),
  builder: (context) => Icon(Icons.location_on),
)
```

### 3. Para MapOptions

Use `center` e `zoom` em vez de `initialCenter` e `initialZoom`:

```dart
MapOptions(
  center: LatLng(-15.7, -47.8),
  zoom: 15.0,
)
```

Use a extensão `copyWith` quando precisar criar uma nova instância com algumas propriedades alteradas:

```dart
import '../../utils/map_options_extensions.dart';

final newOptions = mapOptions.copyWith(
  center: LatLng(-15.8, -47.9),
  zoom: 16.0,
);
```

## Próximos Passos

1. Verifique se todos os arquivos que usam flutter_map foram corrigidos corretamente
2. Teste todas as funcionalidades relacionadas a mapas para garantir que estão funcionando como esperado
3. Considere criar testes automatizados para as funcionalidades de mapa
4. Planeje uma migração para versões mais recentes do flutter_map no futuro, se necessário

## Referências

- [Documentação do flutter_map 5.0.0](https://pub.dev/packages/flutter_map/versions/5.0.0)
- [Changelog do flutter_map](https://pub.dev/packages/flutter_map/changelog)
- [Exemplos de uso do flutter_map](https://github.com/fleaflet/flutter_map/tree/master/example/lib)
