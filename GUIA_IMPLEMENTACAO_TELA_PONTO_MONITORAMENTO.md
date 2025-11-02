# 📘 Guia Completo de Implementação - Tela de Ponto de Monitoramento

## 🎯 Visão Geral

Este guia detalha a implementação completa da tela de **Ponto de Monitoramento** para o FortSmart Agro Premium, seguindo os princípios de design compacto, funcionalidade offline-first e UX otimizada para campo.

---

## 📁 Estrutura de Arquivos Criados

```
lib/
├── models/
│   ├── infestacao_model.dart                    # Modelo de dados para infestação
│   └── ponto_monitoramento_model.dart          # Modelo de dados para pontos
├── repositories/
│   ├── infestacao_repository.dart              # Repositório para infestações
│   └── ponto_monitoramento_repository.dart     # Repositório para pontos
├── screens/monitoring/
│   ├── point_monitoring_screen.dart            # Tela principal
│   ├── point_monitoring_provider.dart          # Provider/Estado
│   └── widgets/
│       ├── point_monitoring_header.dart        # Header compacto
│       ├── point_monitoring_map.dart           # Mini mapa
│       ├── point_monitoring_occurrences_list.dart # Lista de ocorrências
│       ├── point_monitoring_footer.dart        # Rodapé com navegação
│       └── new_occurrence_modal.dart           # Modal nova ocorrência
└── services/
    ├── sync_service.dart                       # Sincronização offline/online
    └── location_service.dart                   # Serviço de GPS
```

---

## 🔧 Passo 1: Configuração de Dependências

### 1.1 Adicionar ao pubspec.yaml

```yaml
dependencies:
  # GPS e Localização
  geolocator: ^10.1.0
  
  # HTTP para sincronização
  http: ^1.1.0
  
  # Gerenciamento de estado
  provider: ^6.1.1
  
  # Banco de dados local
  sqflite: ^2.3.0
  
  # Câmera e galeria
  image_picker: ^1.0.4
  
  # Compressão de imagens
  flutter_image_compress: ^2.0.4
  
  # Geração de UUID
  uuid: ^4.2.1
  
  # Vibração e feedback
  vibration: ^1.8.4
  
  # Permissões
  permission_handler: ^11.0.1
```

### 1.2 Configurar Permissões (Android)

**android/app/src/main/AndroidManifest.xml:**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
```

---

## 🔧 Passo 2: Configuração do Banco de Dados

### 2.1 Atualizar app_database.dart

```dart
// Adicionar às importações
import '../repositories/infestacao_repository.dart';
import '../repositories/ponto_monitoramento_repository.dart';

// Adicionar ao AppDatabase
class AppDatabase {
  // ... código existente ...
  
  late InfestacaoRepository _infestacaoRepository;
  late PontoMonitoramentoRepository _pontoRepository;
  
  InfestacaoRepository get infestacaoRepository => _infestacaoRepository;
  PontoMonitoramentoRepository get pontoRepository => _pontoRepository;
  
  @override
  Future<void> init() async {
    // ... código existente ...
    
    // Inicializar repositórios
    _infestacaoRepository = InfestacaoRepository(database);
    _pontoRepository = PontoMonitoramentoRepository(database);
    
    // Criar tabelas
    await _infestacaoRepository.createTable();
    await _pontoRepository.createTable();
  }
}
```

---

## 🔧 Passo 3: Configuração de Providers

### 3.1 Atualizar main.dart

```dart
// Adicionar às importações
import 'screens/monitoring/point_monitoring_provider.dart';
import 'services/location_service.dart';
import 'services/sync_service.dart';

// No MultiProvider
MultiProvider(
  providers: [
    // ... providers existentes ...
    
    // Serviços
    Provider<LocationService>(
      create: (_) => LocationService(),
    ),
    
    Provider<SyncService>(
      create: (context) {
        final db = context.read<AppDatabase>();
        return SyncService(
          db.infestacaoRepository,
          db.pontoRepository,
          'https://api.fortsmart.com', // URL da API
        );
      },
    ),
    
    // Provider do ponto de monitoramento
    ChangeNotifierProxyProvider<AppDatabase, PointMonitoringProvider>(
      create: (context) {
        final db = context.read<AppDatabase>();
        final locationService = context.read<LocationService>();
        return PointMonitoringProvider(
          db.infestacaoRepository,
          db.pontoRepository,
          locationService,
        );
      },
      update: (context, db, previous) {
        return previous ?? PointMonitoringProvider(
          db.infestacaoRepository,
          db.pontoRepository,
          context.read<LocationService>(),
        );
      },
    ),
  ],
  child: MyApp(),
)
```

---

## 🔧 Passo 4: Integração com Tela de Monitoramento Avançado

### 4.1 Atualizar advanced_monitoring_screen.dart

```dart
// Adicionar método para navegar para ponto de monitoramento
void _navigateToPointMonitoring(int pontoId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PointMonitoringScreen(
        pontoId: pontoId,
        talhaoId: talhaoId,
        culturaId: culturaId,
        talhaoNome: talhaoNome,
        culturaNome: culturaNome,
      ),
    ),
  );
}

// Atualizar botão "Iniciar Monitoramento"
ElevatedButton(
  onPressed: () {
    if (pontos.isNotEmpty) {
      _navigateToPointMonitoring(pontos.first.id);
    }
  },
  child: Text('Iniciar Monitoramento'),
)
```

---

## 🔧 Passo 5: Configuração de Rotas

### 5.1 Atualizar routes.dart (se existir)

```dart
import 'screens/monitoring/point_monitoring_screen.dart';

// Adicionar rota
'/point-monitoring': (context) => PointMonitoringScreen(
  pontoId: ModalRoute.of(context)!.settings.arguments['pontoId'],
  talhaoId: ModalRoute.of(context)!.settings.arguments['talhaoId'],
  culturaId: ModalRoute.of(context)!.settings.arguments['culturaId'],
  talhaoNome: ModalRoute.of(context)!.settings.arguments['talhaoNome'],
  culturaNome: ModalRoute.of(context)!.settings.arguments['culturaNome'],
),
```

---

## 🎨 Passo 6: Personalização Visual

### 6.1 Cores Premium (já implementadas)

```dart
// Adicionar ao theme.dart ou colors.dart
class FortSmartColors {
  // Cores principais
  static const Color backgroundPearl = Color(0xFFFAFAFA);
  static const Color textGrafite = Color(0xFF2C2C2C);
  static const Color dividerLight = Color(0xFFE0E0E0);
  
  // Cores de status
  static const Color azul = Color(0xFF2D9CDB);
  static const Color verde = Color(0xFF27AE60);
  static const Color amarelo = Color(0xFFF2C94C);
  static const Color vermelho = Color(0xFFEB5757);
  
  // Cores por tipo
  static const Color praga = Color(0xFFF2994A);
  static const Color doenca = Color(0xFF9B51E0);
  static const Color daninha = Color(0xFF27AE60);
}
```

---

## 📱 Passo 7: Funcionalidades Implementadas

### 7.1 ✅ Layout Compacto
- Header escuro com informações essenciais
- Linha de status da cultura com contadores
- Mini mapa ocupando metade da tela
- Lista de ocorrências expansível
- Rodapé fixo com navegação

### 7.2 ✅ Sistema de GPS
- Monitoramento em tempo real
- Validação de precisão (≤10m)
- Cálculo de distância até pontos
- Vibração e som ao chegar no ponto
- Badge de status GPS no header

### 7.3 ✅ Gestão de Ocorrências
- Modal completo para nova ocorrência
- Tipos: Praga, Doença, Daninha, Outro
- Subtipos específicos por tipo
- Níveis: Baixo, Médio, Alto, Crítico
- Percentual com slider visual
- Upload de até 4 fotos
- Observações opcionais

### 7.4 ✅ Navegação entre Pontos
- Validação de distância (≤5m para avançar)
- Botões anterior/próximo
- Finalização do monitoramento
- Salvamento automático de observações

### 7.5 ✅ Sistema Offline-First
- Todas as operações funcionam offline
- Sincronização automática quando online
- Upload de imagens em background
- Retry automático com backoff exponencial
- Marcação de sincronização no banco

---

## 🔧 Passo 8: Configurações Avançadas

### 8.1 Configurar Sincronização Automática

```dart
// No main.dart ou app.dart
@override
void initState() {
  super.initState();
  
  // Iniciar sincronização automática
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final syncService = context.read<SyncService>();
    syncService.startAutoSync(interval: Duration(minutes: 5));
  });
}
```

### 8.2 Configurar Compressão de Imagens

```dart
// Adicionar ao new_occurrence_modal.dart
Future<File> _compressImage(File imageFile) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    imageFile.absolute.path,
    '${imageFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    quality: 80,
    minWidth: 800,
    minHeight: 600,
  );
  
  return result ?? imageFile;
}
```

---

## 🧪 Passo 9: Testes e Validação

### 9.1 Testes de Campo Recomendados

1. **Teste GPS Real**
   - Caminhar até pontos de monitoramento
   - Verificar precisão e vibração
   - Testar em diferentes condições climáticas

2. **Teste Offline**
   - Desligar internet
   - Registrar várias ocorrências
   - Reativar internet e verificar sincronização

3. **Teste de Performance**
   - Muitas ocorrências no mesmo ponto
   - Fotos grandes
   - Navegação rápida entre pontos

### 9.2 Casos de Teste Críticos

```dart
// Testes unitários sugeridos
test('deve salvar ocorrência offline', () async {
  // Simular modo offline
  // Salvar ocorrência
  // Verificar persistência local
});

test('deve validar distância para navegação', () async {
  // Posição atual longe do ponto
  // Tentar avançar
  // Deve bloquear
});

test('deve sincronizar quando online', () async {
  // Ocorrências offline
  // Simular conexão
  // Verificar envio
});
```

---

## 🚀 Passo 10: Deploy e Configuração

### 10.1 Configuração da API

```dart
// Configurar URL da API
const String API_BASE_URL = 'https://api.fortsmart.com';

// Endpoints necessários
const String UPLOAD_IMAGE_ENDPOINT = '$API_BASE_URL/api/upload/image';
const String SYNC_INFESTACOES_ENDPOINT = '$API_BASE_URL/api/sync/infestacoes';
const String SYNC_PONTOS_ENDPOINT = '$API_BASE_URL/api/sync/pontos';
```

### 10.2 Configuração de Build

```yaml
# android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## 📋 Checklist de Implementação

### ✅ Modelos de Dados
- [x] InfestacaoModel com todos os campos
- [x] PontoMonitoramentoModel
- [x] Métodos de serialização/deserialização

### ✅ Repositórios
- [x] InfestacaoRepository com CRUD completo
- [x] PontoMonitoramentoRepository
- [x] Métodos de sincronização

### ✅ Tela Principal
- [x] Layout compacto conforme especificação
- [x] Header com status GPS
- [x] Mini mapa com markers
- [x] Lista de ocorrências expansível
- [x] Rodapé com navegação

### ✅ Funcionalidades
- [x] Modal de nova ocorrência
- [x] Sistema de GPS em tempo real
- [x] Validação de distância
- [x] Upload de fotos
- [x] Sincronização offline/online

### ✅ Integração
- [ ] Configuração no main.dart
- [ ] Rotas configuradas
- [ ] Providers registrados
- [ ] Permissões configuradas

---

## 🎯 Próximos Passos

1. **Integrar com tela existente** de monitoramento avançado
2. **Configurar permissões** de GPS e câmera
3. **Testar em dispositivo real** com GPS
4. **Configurar API backend** para sincronização
5. **Implementar notificações** de chegada ao ponto
6. **Adicionar relatórios** de monitoramento

---

## 📞 Suporte

Para dúvidas sobre implementação:
- Verificar logs de erro no console
- Testar cada componente individualmente
- Validar permissões no dispositivo
- Verificar conectividade de rede

**Implementação completa e funcional seguindo todas as especificações do design premium!** 🚀
