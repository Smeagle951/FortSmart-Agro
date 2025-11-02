# Correções para os erros de compilação

## 1. Correções para o arquivo plantio_screen.dart

### Corrigir os problemas com onTap: $1

1. No método `_buildDropdownField` (linha ~789):
```dart
// Substituir
onTap: $1,

// Por
onTap: onTap,
```

2. No método `_buildDateField` (linha ~812):
```dart
// Substituir
onTap: $1,

// Por
onTap: onTap,
```

3. No método `_mostrarSelecaoComPreview` (linha ~850):
```dart
// Substituir
onTap: $1,

// Por
onTap: () => Navigator.of(context).pop(opcao),
```

4. No método `_selecionarCultura` (linha ~999):
```dart
// Substituir
onTap: $1,

// Por
onTap: () => Navigator.of(context).pop(cultura),
```

5. No método `_selecionarVariedade` (linha ~1129):
```dart
// Substituir
onTap: $1,

// Por
onTap: () => Navigator.of(context).pop(variedade),
```

## 2. Correções para o arquivo report_service.dart

Na linha ~514:
```dart
// Substituir
await Share.shareFiles([file.path], text: 'Relatório FORTSMART');

// Por
await Share.share('Relatório FORTSMART', subject: 'Relatório FORTSMART');
```

## 3. Correções para problemas com ListTile

Para todos os arquivos com erro de "Too many positional arguments: 0 allowed, but 1 found" em ListTile:

```dart
// Substituir
ListTile(
  // argumentos posicionais
)

// Por
ListTile(
  // argumentos nomeados
)
```

Exemplo específico para file_picker_wrapper.dart:
```dart
// Substituir
ListTile(
  title: Text('Tirar foto'),
  leading: Icon(Icons.camera_alt),
  onTap: () {
    _pickImage(ImageSource.camera);
    Navigator.pop(context);
  }
)

// Por
ListTile(
  title: Text('Tirar foto'),
  leading: Icon(Icons.camera_alt),
  onTap: () {
    _pickImage(ImageSource.camera);
    Navigator.pop(context);
  },
)
```

## 4. Correções para o arquivo map_controllers.dart

Para os erros "Cannot invoke a non-'const' constructor where a const expression is expected":

```dart
// Substituir
return const map_types.LatLng(-15.793889, -47.882778);

// Por
return map_types.LatLng(-15.793889, -47.882778);
```

Para os erros com CustomPoint:
```dart
// Substituir
final latLng = _controller.pointToLatLng(CustomPoint<num>(

// Por
final latLng = _controller.pointToLatLng(Point<num>(
```

Para os erros com acesso a propriedades nulas:
```dart
// Substituir
return map_types.LatLng(latLng.latitude, latLng.longitude);

// Por
return map_types.LatLng(latLng?.latitude ?? -15.793889, latLng?.longitude ?? -47.882778);
```

## 5. Correções para o arquivo maptiler_compatibility.dart

Para o erro de parâmetro duplicado:
```dart
// Substituir
const LatLngBounds(this.southwest, this.northeast, {required LatLng southwest});

// Por
const LatLngBounds(this.southwest, this.northeast);
```

## 6. Correções para o arquivo enhanced_dashboard_screen.dart

Para o erro "Expected an identifier, but got 'switch'":
```dart
// Substituir
switch (activity['type']) {

// Por
if (activity['type'] == 'plantio') {
  // código para plantio
} else if (activity['type'] == 'colheita') {
  // código para colheita
} else {
  // código para outros tipos
}
```

## 7. Correções para o arquivo monitoring_main_screen.dart

Para o erro "Expected an identifier, but got '}'":
Verifique se há chaves não balanceadas e corrija a estrutura do código.

## 8. Correções para o arquivo fl_chart

Para os erros com tooltipBackgroundColor:
```dart
// Substituir
tooltipBackgroundColor: Colors.blueAccent,

// Por
// Remover esta linha ou substituir pelo parâmetro correto conforme documentação
```

## 9. Correções para o arquivo advanced_monitoring_screen.dart

Para o erro "_buildMonitoringInfo is already declared in this scope":
Renomeie uma das funções para evitar duplicação:
```dart
// Substituir
Widget _buildMonitoringInfo() {

// Por
Widget _buildMonitoringInfoDetails() {
```

## 10. Correções para o arquivo inventory_service_integration.dart

Para o erro "No named parameter with the name 'plotId'":
```dart
// Substituir
plotId: plotId,

// Por
talhaoId: plotId,
```

## 11. Correções para o arquivo google_maps_adapter.dart

Para o erro "Required named parameter 'southwest' must be provided":
```dart
// Substituir
return maptiler.LatLngBounds(

// Por
return maptiler.LatLngBounds(
  southwest: maptiler.LatLng(-90, -180),
  northeast: maptiler.LatLng(90, 180),
);
```
