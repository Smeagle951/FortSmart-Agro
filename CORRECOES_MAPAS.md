# Correções de Mapas - FortSmart Agro

Este documento descreve as correções implementadas para resolver problemas de compatibilidade e erros de compilação relacionados aos pacotes de mapas no projeto FortSmart Agro.

## Visão Geral

O projeto utiliza diversos pacotes de mapas que apresentavam problemas de compatibilidade com as versões mais recentes do Flutter. Para resolver esses problemas, foram implementados patches específicos para cada pacote problemático.

## Patches Implementados

### 1. MapControllerUtils (`map_controllers_fix.dart`)

Classe utilitária para corrigir erros de compilação no `map_controllers.dart`, incluindo:
- Conversões seguras entre tipos (`latlong2.LatLng` e `map_types.LatLng`)
- Tratamento de valores nulos
- Métodos auxiliares para mover a câmera e converter coordenadas

### 2. MapboxMapController e GoogleMapController (`map_controllers.dart`)

Correções para:
- Remoção de construtores `const` inválidos
- Conversões seguras de tipos `num` para `double`
- Tratamento adequado de valores nulos
- Uso de métodos seguros para conversão de coordenadas

### 3. SafePositionedTapDetector (`positioned_tap_detector_patch.dart`)

Wrapper seguro para o widget `PositionedTapDetector2` que:
- Corrige o problema de `hashValues` no pacote original
- Implementa uma classe `TapPosition` segura que trata valores nulos corretamente
- Remove operadores redundantes e importações não utilizadas

### 4. TextThemeExtension (`text_theme_extension.dart`)

Extensão para compatibilidade com diferentes versões do Flutter:
- Adiciona getters para propriedades depreciadas como `headline5`, `headline6`, etc.
- Mapeia para as novas propriedades (`headlineSmall`, `titleLarge`, etc.)

### 5. FlutterMapPatch (`flutter_map_patch.dart`)

Patch para o pacote `flutter_map`:
- Corrige o problema do `headline5` (substituído por `headlineSmall` em versões mais recentes)
- Utiliza a extensão `TextThemeExtension` para garantir compatibilidade

### 6. MapPatchesManager (`map_patches_manager.dart`)

Classe centralizada para aplicar todos os patches:
- Aplica patches para Mapbox, `positioned_tap_detector_2`, `MapController` e `flutter_map`
- Fornece logs detalhados para monitorar a aplicação dos patches
- Inclui método para verificar se os patches estão funcionando corretamente

## Como Usar

1. Certifique-se de que o `MapPatchesManager` seja chamado no início da aplicação:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Aplicar todos os patches necessários
  await MapPatchesManager.applyAllPatches();
  
  runApp(MyApp());
}
```

2. Ao usar o `PositionedTapDetector2`, substitua pelo wrapper seguro:

```dart
// Em vez de:
// PositionedTapDetector2(
//   onTap: (position) => handleTap(position),
//   child: child,
// )

// Use:
SafePositionedTapDetector(
  onTap: (position) => handleTap(position),
  child: child,
)
```

3. Ao usar o `MapController`, utilize os métodos auxiliares do `MapControllerUtils`:

```dart
// Em vez de:
// controller.move(LatLng(lat, lng), zoom);

// Use:
MapControllerUtils.moveCamera(controller, lat, lng, zoom);
```

## Problemas Conhecidos

- Alguns avisos de lint podem aparecer nos arquivos de patch, mas eles não afetam a funcionalidade
- Os patches são temporários e devem ser removidos quando os pacotes forem atualizados para versões compatíveis

## Dependências Atualizadas

As seguintes dependências foram atualizadas para garantir compatibilidade:

```yaml
flutter_map: ^3.0.0
latlong2: ^0.8.1
flutter_map_marker_popup: ^4.0.0
flutter_map_marker_cluster: ^1.0.0
geolocator: ^9.0.2
```
