# Guia de Compatibilidade do Flutter Map 5.0.0

Este documento explica as mudanças feitas para garantir a compatibilidade com o Flutter Map 5.0.0 e como usar as novas classes de adaptação.

## Problemas Resolvidos

1. **Substituição de `child` por `builder` em Markers**
   - Na versão 5.0.0 do Flutter Map, os marcadores usam o parâmetro `builder` em vez de `child`.
   - Todas as classes que criavam marcadores foram atualizadas para usar `builder`.

2. **Remoção da propriedade `camera` do MapController**
   - Na versão 5.0.0, o `MapController` não possui a propriedade `camera`.
   - Criamos adaptadores para simular essa propriedade.

3. **Substituição de parâmetros `initialCenter` e `initialZoom` por `center` e `zoom`**
   - Os parâmetros para `MapOptions` foram atualizados para usar os nomes corretos.

4. **Correção de tipos incompatíveis**
   - Substituição de `Point` do `dart:math` por `CustomPoint` do Flutter Map.
   - Adição de importações corretas para funções matemáticas.

## Novas Classes e Adaptadores

### `MapControllerCompat`

Adaptador para o `MapController` que adiciona a propriedade `camera`:

```dart
// Exemplo de uso:
final mapController = MapController();
final compatController = MapControllerCompat(mapController);

// Acesso ao centro do mapa
final center = compatController.camera.center;

// Ou usando a extensão:
final center = mapController.compat.camera.center;
```

### `MapCompatibilityLayer`

Camada de compatibilidade para facilitar a migração do Google Maps e Mapbox para o Flutter Map:

```dart
// Exemplo de uso com Google Maps:
final googleMarker = GoogleMarker(
  position: GoogleLatLng(-15.7, -47.8),
  icon: Icon(Icons.location_on),
);

// Converter para marcador do Flutter Map
final flutterMapMarker = googleMarker.toFlutterMapMarker();
```

## Como Usar os Adaptadores

### Para MapController e camera

```dart
import 'package:flutter_map/flutter_map.dart';
import '../utils/map_controller_compatibility.dart';

// No seu widget:
late MapController _mapController;

@override
void initState() {
  super.initState();
  _mapController = MapController();
}

// Para acessar o centro do mapa:
void _getCenter() {
  // Usando o adaptador:
  final center = _mapController.compat.camera.center;
  print('Centro do mapa: $center');
}

// Para mover o mapa:
void _moveMap() {
  final newCenter = latlong2.LatLng(-15.7, -47.8);
  _mapController.move(newCenter, 15.0);
  // Ou usando o adaptador:
  // _mapController.compat.move(newCenter, 15.0);
}
```

### Para Markers

```dart
// Criar um marcador:
final marker = Marker(
  point: latlong2.LatLng(-15.7, -47.8),
  builder: (context) => Icon(Icons.location_on, color: Colors.red),
  width: 30,
  height: 30,
);

// Usar o marcador em um MarkerLayer:
MarkerLayer(
  markers: [marker],
)
```

## Dicas de Migração

1. **Substitua todos os usos de `child` em `Marker` por `builder`**:
   ```dart
   // Antes:
   Marker(
     point: point,
     child: Icon(Icons.location_on),
   )
   
   // Depois:
   Marker(
     point: point,
     builder: (context) => Icon(Icons.location_on),
   )
   ```

2. **Substitua todos os acessos a `mapController.camera` pelo adaptador**:
   ```dart
   // Antes:
   final center = mapController.camera.center;
   
   // Depois:
   final center = mapController.compat.camera.center;
   ```

3. **Substitua `initialCenter` e `initialZoom` em `MapOptions` por `center` e `zoom`**:
   ```dart
   // Antes:
   MapOptions(
     initialCenter: LatLng(-15.7, -47.8),
     initialZoom: 15.0,
   )
   
   // Depois:
   MapOptions(
     center: LatLng(-15.7, -47.8),
     zoom: 15.0,
   )
   ```

## Arquivos Atualizados

1. `map_compatibility_layer.dart` - Camada de compatibilidade para Google Maps e Mapbox
2. `map_tiler_map_widget.dart` - Widget de mapa usando Flutter Map
3. `map_controller_compatibility.dart` - Adaptador para MapController
4. `map_controller_adapter.dart` - Adaptador para MapController.camera

## Próximos Passos

1. Verifique se todos os arquivos que usam `MapController.camera` foram atualizados para usar o adaptador.
2. Verifique se todos os marcadores estão usando `builder` em vez de `child`.
3. Verifique se todos os `MapOptions` estão usando `center` e `zoom` em vez de `initialCenter` e `initialZoom`.
4. Execute o aplicativo e teste todas as funcionalidades relacionadas ao mapa.
