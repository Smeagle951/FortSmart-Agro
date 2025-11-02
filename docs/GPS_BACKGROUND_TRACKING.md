# Rastreamento GPS em Background - FortSmart Agro

## 📱 O Problema Resolvido

O sistema anterior de rastreamento GPS parava de funcionar após aproximadamente 5 minutos com a tela desligada, gravando apenas cerca de 30 pontos GPS. Isso ocorria porque o `Geolocator.getPositionStream()` não funciona em background no Flutter.

## ✅ Solução Implementada

Foi implementado um novo sistema de rastreamento GPS que **funciona continuamente em background**, mesmo com a tela desligada, usando:

### 1. **BackgroundGpsTrackingService**
- Serviço dedicado para rastreamento em background
- Utiliza `flutter_foreground_task` para manter o serviço ativo
- Utiliza `wakelock_plus` para manter o GPS ativo
- Mostra notificação permanente durante o rastreamento
- Funciona com a tela desligada

### 2. **Configurações Otimizadas**
- **Precisão GPS**: Best (melhor disponível)
- **Filtro de distância**: 0m (captura todos os pontos)
- **Intervalo mínimo**: 1 segundo entre pontos
- **Precisão máxima aceita**: 15 metros
- **Warm-up**: 2 pontos iniciais para estabilização

### 3. **Permissões Configuradas**
No `AndroidManifest.xml`:
- ✅ `ACCESS_FINE_LOCATION` - Localização precisa
- ✅ `ACCESS_BACKGROUND_LOCATION` - Localização em background
- ✅ `WAKE_LOCK` - Manter dispositivo ativo
- ✅ `FOREGROUND_SERVICE` - Serviço em primeiro plano
- ✅ `FOREGROUND_SERVICE_LOCATION` - Serviço de localização
- ✅ `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` - Isenção de otimização de bateria
- ✅ `POST_NOTIFICATIONS` - Notificações (Android 13+)

## 🚀 Como Usar

### Iniciar Rastreamento por Caminhada

```dart
// O código existente continua funcionando da mesma forma
await _gpsService.startTracking(
  onPointsChanged: (points) {
    // Recebe todos os pontos coletados
  },
  onDistanceChanged: (distance) {
    // Recebe a distância total percorrida
  },
  onAccuracyChanged: (accuracy) {
    // Recebe a precisão atual do GPS
  },
  onStatusChanged: (status) {
    // Recebe mensagens de status
  },
  onTrackingStateChanged: (isTracking) {
    // Recebe o estado do rastreamento
  },
);
```

### Solicitar Permissões (Recomendado)

```dart
import 'package:fortsmart_agro/services/gps_background_permission_helper.dart';

// Solicitar todas as permissões necessárias
final hasPermissions = await GpsBackgroundPermissionHelper.requestAllPermissions(context);

if (hasPermissions) {
  // Iniciar rastreamento
  await _startGpsTracking();
}
```

### Mostrar Dicas ao Usuário

```dart
// Mostrar dicas para melhor rastreamento
GpsBackgroundPermissionHelper.showGpsTips(context);
```

## 📊 Recursos do Novo Sistema

### 1. **Rastreamento Contínuo**
- ✅ Funciona com a tela desligada
- ✅ Grava todos os pontos GPS continuamente
- ✅ Não tem limite de tempo
- ✅ Não para após 5 minutos

### 2. **Notificação de Progresso**
Durante o rastreamento, uma notificação mostra:
- Número de pontos coletados
- Distância total percorrida
- Precisão atual do GPS

### 3. **Gerenciamento de Bateria**
- Solicita isenção de otimização de bateria
- Usa wakelock para manter GPS ativo
- Configurações otimizadas para eficiência

### 4. **Filtros de Qualidade**
- Rejeita pontos com precisão > 15m
- Rejeita saltos irreais (>50m em <3s)
- Warm-up inicial para estabilização
- Intervalo mínimo de 1s entre pontos

## 🔧 Configurações Técnicas

### BackgroundGpsTrackingService

```dart
// Configurações padrão
static const double _maxAccuracy = 15.0; // metros
static const double _minDistance = 0.5; // metros
static const double _maxJumpDistance = 50.0; // metros
static const int _maxJumpTime = 3; // segundos
static const int _warmupPoints = 2;
static const int _minIntervalMs = 1000; // 1 segundo
```

### LocationSettings

```dart
final locationSettings = LocationSettings(
  accuracy: LocationAccuracy.best,
  distanceFilter: 0, // Sem filtro de distância
  timeLimit: const Duration(seconds: 30),
);
```

## 📱 Fluxo de Uso Recomendado

### 1. **Ao Abrir a Tela de Talhões**
```dart
@override
void initState() {
  super.initState();
  // Verificar permissões
  _checkPermissions();
}

Future<void> _checkPermissions() async {
  final hasPermissions = await GpsBackgroundPermissionHelper.hasAllPermissions();
  if (!hasPermissions) {
    // Mostrar mensagem ou solicitar permissões
  }
}
```

### 2. **Ao Iniciar Rastreamento**
```dart
Future<void> _startGpsTracking() async {
  // Solicitar permissões se necessário
  final hasPermissions = await GpsBackgroundPermissionHelper.requestAllPermissions(context);
  
  if (!hasPermissions) {
    _showElegantSnackBar('Permissões necessárias não concedidas', isError: true);
    return;
  }
  
  // Iniciar rastreamento
  final success = await _gpsService.startTracking(...);
  
  if (success) {
    _showElegantSnackBar('Rastreamento GPS iniciado', isSuccess: true);
  }
}
```

### 3. **Durante o Rastreamento**
- O usuário pode desligar a tela
- O GPS continuará coletando pontos
- A notificação mostrará o progresso
- Os pontos serão adicionados automaticamente

### 4. **Ao Finalizar**
```dart
await _gpsService.stopTracking();
// O wakelock será desativado automaticamente
// A notificação será removida
// Todos os pontos estarão disponíveis
```

## 🐛 Troubleshooting

### GPS não funciona em background
1. Verificar se a permissão "Permitir o tempo todo" está concedida
2. Verificar se a otimização de bateria está desativada
3. Verificar se o serviço foreground está configurado no AndroidManifest

### Poucos pontos sendo coletados
1. Verificar se o GPS está ativo
2. Verificar sinal GPS (preferir áreas abertas)
3. Verificar logs para ver se pontos estão sendo rejeitados

### Bateria consumindo muito
1. Verificar se o intervalo mínimo está configurado (1s)
2. Considerar aumentar o `distanceFilter` se necessário
3. Verificar se há múltiplos serviços GPS rodando

## 📝 Logs e Debugging

O sistema gera logs detalhados:

```
🚀 Iniciando rastreamento GPS em background...
🔋 Wakelock ativado
📡 Stream de localização iniciado
📍 Nova posição: -23.550520, -46.633308 (accuracy: 8.5m)
✅ Ponto adicionado - Total: 45, Distância: 123.45m
```

Para ver os logs:
```bash
flutter logs --device <device-id>
```

## 🎯 Resultados Esperados

Com a nova implementação:
- ✅ **Rastreamento ilimitado**: Funciona por horas se necessário
- ✅ **Milhares de pontos**: Não há mais limite de 30 pontos
- ✅ **Tela desligada**: Funciona perfeitamente em background
- ✅ **Alta precisão**: Pontos com precisão < 15m
- ✅ **Feedback visual**: Notificação com progresso em tempo real

## 🔄 Migração

O sistema é **retrocompatível**. Todo código existente continua funcionando:
- `AdvancedGpsTrackingService` agora delega para `BackgroundGpsTrackingService`
- Mesma API pública
- Mesmos callbacks
- Sem necessidade de alterar código existente

## 📚 Referências

- [flutter_foreground_task](https://pub.dev/packages/flutter_foreground_task)
- [wakelock_plus](https://pub.dev/packages/wakelock_plus)
- [geolocator](https://pub.dev/packages/geolocator)
- [permission_handler](https://pub.dev/packages/permission_handler)

---

**Desenvolvido para FortSmart Agro - Sistema de Gestão Agrícola Inteligente**

