# Sistema de GPS em Background - FortSmart Agro

## 📍 Visão Geral

O novo sistema de GPS em background foi implementado para resolver o problema de coleta de coordenadas durante caminhadas e operações com veículos. O sistema mantém a coleta de GPS ativa mesmo quando o app está em segundo plano.

## 🔧 Componentes Implementados

### 1. BackgroundGpsService
- **Arquivo**: `lib/services/background_gps_service.dart`
- **Função**: Serviço principal que gerencia GPS em background usando `flutter_foreground_task`
- **Recursos**:
  - Coleta contínua de GPS em background
  - Suavização de pontos usando média móvel
  - Filtro de Kalman para pontos mais precisos
  - Integração com `wakelock_plus` para manter CPU ativa

### 2. EnhancedGpsProvider
- **Arquivo**: `lib/providers/enhanced_gps_provider.dart`
- **Função**: Provider que gerencia o estado do GPS aprimorado
- **Recursos**:
  - Interface simplificada para uso em widgets
  - Configurações flexíveis (distância mínima, intervalo, suavização)
  - Suporte a rastreamento em foreground e background
  - Streams para atualizações em tempo real

### 3. Integração com Controller
- **Arquivo**: `lib/screens/talhoes_com_safras/controllers/novo_talhao_controller.dart`
- **Função**: Integração com o sistema existente de talhões
- **Recursos**:
  - Mantém compatibilidade com banco de dados SQLite existente
  - Adiciona novos métodos para GPS aprimorado
  - Preserva toda funcionalidade atual

## 🚀 Como Usar

### Iniciar Rastreamento GPS Aprimorado

```dart
// No controller de talhões
await startEnhancedGpsTracking(
  talhaoId: 'talhao_123',
  talhaoNome: 'Talhão Norte',
  minDistanceMeters: 2,        // Distância mínima entre pontos
  updateIntervalMs: 1000,     // Intervalo de atualização
  enableSmoothing: true,       // Ativar suavização
  enableBackground: true,      // Permitir background
);
```

### Usar Provider Diretamente

```dart
final gpsProvider = EnhancedGpsProvider();

// Inicializar
await gpsProvider.initialize();

// Iniciar rastreamento
final success = await gpsProvider.startTracking(
  talhaoId: 'talhao_123',
  talhaoNome: 'Talhão Norte',
  minDistanceMeters: 2,
  updateIntervalMs: 1000,
  enableSmoothing: true,
  enableBackground: true,
);

// Parar rastreamento
await gpsProvider.stopTracking();
```

### Escutar Atualizações

```dart
// Listener para posições
gpsProvider.addListener(() {
  if (gpsProvider.currentPosition != null) {
    final position = gpsProvider.currentPosition!;
    print('Nova posição: ${position.latitude}, ${position.longitude}');
  }
});

// Stream de pontos rastreados
gpsProvider.trackPointsStream.listen((points) {
  print('Total de pontos: ${points.length}');
});
```

## ⚙️ Configurações

### Parâmetros de Rastreamento

- **minDistanceMeters**: Distância mínima entre pontos (padrão: 2m)
- **updateIntervalMs**: Intervalo entre atualizações (padrão: 1000ms)
- **enableSmoothing**: Ativar suavização de pontos (padrão: true)
- **enableBackground**: Permitir rastreamento em background (padrão: true)

### Configurações de Precisão

- **LocationAccuracy.bestForNavigation**: Máxima precisão para navegação
- **distanceFilter**: Filtro de distância para evitar pontos duplicados
- **speedFilter**: Filtro de velocidade para ignorar pontos quando parado

## 🔄 Fluxo de Funcionamento

1. **Início da Operação**:
   - Ativa foreground service
   - Ativa wakelock para manter CPU ativa
   - Inicia stream de GPS com alta precisão

2. **Durante a Coleta**:
   - Coleta pontos GPS continuamente
   - Aplica suavização (média móvel ou Kalman)
   - Filtra pontos por distância e velocidade
   - Atualiza polígono em tempo real

3. **Fim da Operação**:
   - Para o serviço de background
   - Desativa wakelock
   - Salva dados no banco SQLite existente

## 🛡️ Compatibilidade

### Banco de Dados
- ✅ **Mantém SQLite existente**
- ✅ **Preserva todos os modelos de dados**
- ✅ **Compatível com sistema atual de talhões**
- ✅ **Não remove nenhuma funcionalidade**

### Dependências Adicionadas
```yaml
flutter_foreground_task: ^7.0.0  # Serviço de background
workmanager: ^0.5.2              # Backup para tarefas
wakelock_plus: ^1.1.4            # Manter CPU ativa (já existia)
```

## 📱 Permissões Android

O `AndroidManifest.xml` já possui todas as permissões necessárias:
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE_LOCATION`
- `WAKE_LOCK`

## 🧪 Exemplo de Uso

Veja o arquivo `lib/examples/enhanced_gps_example.dart` para um exemplo completo de implementação.

## 🔧 Solução de Problemas

### GPS não funciona em background
- Verificar se `enableBackground: true`
- Confirmar permissões de localização
- Verificar se o serviço de localização está ativo

### Pontos imprecisos
- Ativar `enableSmoothing: true`
- Ajustar `minDistanceMeters` para valor maior
- Verificar se o dispositivo tem boa recepção GPS

### App fecha durante rastreamento
- Verificar se `wakelock_plus` está funcionando
- Confirmar se `flutter_foreground_task` está ativo
- Verificar configurações de economia de bateria do dispositivo

## 📊 Benefícios

1. **Coleta Contínua**: GPS funciona mesmo com app em background
2. **Precisão Aprimorada**: Suavização de pontos elimina ruídos
3. **Compatibilidade Total**: Não quebra funcionalidades existentes
4. **Performance**: Otimizado para operações longas
5. **Confiabilidade**: Múltiplas camadas de backup

## 🎯 Casos de Uso

- ✅ Caminhadas para delimitar talhões
- ✅ Operações com trator/implementos
- ✅ Mapeamento de áreas grandes
- ✅ Coleta de dados em campo
- ✅ Rastreamento de rotas agrícolas

O sistema está pronto para uso e mantém total compatibilidade com o banco de dados SQLite existente!
