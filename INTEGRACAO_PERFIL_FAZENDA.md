# 🚀 Guia de Integração - Perfil de Fazenda

## 📱 Como Navegar para a Tela

### Opção 1: Navegação Simples (Criar/Ver Fazenda Atual)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FarmProfileScreen(),
  ),
);
```

### Opção 2: Navegação com ID Específico
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FarmProfileScreen(
      farmId: 'id-da-fazenda-aqui',
    ),
  ),
);
```

### Opção 3: Usando GetX (se preferir)
```dart
Get.to(() => const FarmProfileScreen());

// Ou com ID específico
Get.to(() => FarmProfileScreen(farmId: farmId));
```

---

## 🔗 Adicionar ao Menu Principal

### No Drawer/Menu Lateral

```dart
ListTile(
  leading: const Icon(Icons.agriculture),
  title: const Text('Perfil da Fazenda'),
  onTap: () {
    Navigator.pop(context); // Fecha o drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmProfileScreen(),
      ),
    );
  },
),
```

### No BottomNavigationBar

```dart
BottomNavigationBarItem(
  icon: Icon(Icons.agriculture),
  label: 'Fazenda',
),

// No onTap do BottomNavigationBar:
case 2: // Índice da aba
  return const FarmProfileScreen();
```

### Como Card/Botão na Home

```dart
Card(
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FarmProfileScreen(),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.agriculture, size: 48, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text('Perfil da Fazenda'),
        ],
      ),
    ),
  ),
)
```

---

## ⚙️ Configuração da API Base44

### 1. Configurar Token de Autenticação

Crie um arquivo de configuração ou use o existente:

```dart
// lib/config/base44_config.dart
class Base44Config {
  static const String baseUrl = 'https://api.base44.com.br/v1';
  static String? authToken;
  
  static void setAuthToken(String token) {
    authToken = token;
  }
  
  static String? getAuthToken() {
    return authToken;
  }
}
```

### 2. Inicializar o Serviço

No início do app (main.dart ou tela de login):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carregar token salvo (se existir)
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('base44_token');
  
  if (token != null) {
    final base44Service = Base44SyncService();
    base44Service.setAuthToken(token);
  }
  
  runApp(MyApp());
}
```

### 3. Salvar Token após Login

```dart
Future<void> loginToBase44(String username, String password) async {
  try {
    // Seu código de login aqui
    final response = await http.post(
      Uri.parse('https://api.base44.com.br/v1/auth/login'),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      
      // Salvar token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base44_token', token);
      
      // Configurar serviço
      final base44Service = Base44SyncService();
      base44Service.setAuthToken(token);
      
      print('Login realizado com sucesso!');
    }
  } catch (e) {
    print('Erro no login: $e');
  }
}
```

---

## 📊 Exemplos de Uso Prático

### Exemplo 1: Criar Nova Fazenda e Sincronizar

```dart
Future<void> criarESincronizarFazenda() async {
  final farmService = FarmService();
  final base44Service = Base44SyncService();
  
  // 1. Criar fazenda
  final farm = Farm(
    name: 'Fazenda Modelo',
    address: 'Estrada Rural, Km 10',
    municipality: 'Campo Grande',
    state: 'MS',
    ownerName: 'João Silva',
    documentNumber: '12345678900',
    phone: '(67) 99999-9999',
    email: 'joao@fazenda.com',
    totalArea: 0.0,
    plotsCount: 0,
    crops: [],
    hasIrrigation: false,
  );
  
  // 2. Salvar no banco local
  final farmId = await farmService.addFarm(farm);
  print('Fazenda criada com ID: $farmId');
  
  // 3. Sincronizar com Base44
  final result = await base44Service.syncFarm(farm);
  
  if (result['success']) {
    print('✅ Fazenda sincronizada com Base44');
  } else {
    print('❌ Erro na sincronização: ${result['message']}');
  }
}
```

### Exemplo 2: Sincronização Automática Periódica

```dart
import 'dart:async';

class AutoSyncService {
  Timer? _syncTimer;
  final Base44SyncService _base44Service = Base44SyncService();
  final FarmService _farmService = FarmService();
  
  // Iniciar sincronização automática a cada 30 minutos
  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 30),
      (timer) => _performSync(),
    );
  }
  
  Future<void> _performSync() async {
    try {
      print('🔄 Iniciando sincronização automática...');
      
      // Buscar fazenda atual
      final farm = await _farmService.getCurrentFarm();
      
      if (farm != null) {
        final result = await _base44Service.syncFarm(farm);
        
        if (result['success']) {
          print('✅ Sincronização automática concluída');
        } else {
          print('⚠️ Sincronização automática falhou');
        }
      }
    } catch (e) {
      print('❌ Erro na sincronização automática: $e');
    }
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
  }
}
```

### Exemplo 3: Sincronizar Dados de Monitoramento

```dart
Future<void> sincronizarMonitoramento() async {
  final base44Service = Base44SyncService();
  
  final monitoringData = {
    'farm_id': 'id-da-fazenda',
    'plot_id': 'id-do-talhao',
    'date': DateTime.now().toIso8601String(),
    'observations': [
      {
        'type': 'praga',
        'severity': 'média',
        'location': {
          'latitude': -20.123456,
          'longitude': -54.123456,
        },
        'notes': 'Observada presença de lagarta',
      }
    ],
  };
  
  final result = await base44Service.syncMonitoringData(monitoringData);
  
  if (result['success']) {
    print('✅ Dados de monitoramento sincronizados');
  }
}
```

### Exemplo 4: Verificar Status de Sincronização

```dart
Future<void> verificarStatus() async {
  final base44Service = Base44SyncService();
  
  final result = await base44Service.checkSyncStatus('id-da-fazenda');
  
  if (result['success']) {
    final data = result['data'];
    print('Status: ${data['status']}');
    print('Última sincronização: ${data['last_sync']}');
    print('Pendente: ${data['pending_count']}');
  }
}
```

### Exemplo 5: Obter Histórico de Sincronizações

```dart
Future<void> mostrarHistorico(BuildContext context) async {
  final base44Service = Base44SyncService();
  
  final history = await base44Service.getSyncHistory('id-da-fazenda');
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Histórico de Sincronizações'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: history.length,
          itemBuilder: (context, index) {
            final sync = history[index];
            return ListTile(
              leading: Icon(
                sync['success'] ? Icons.check_circle : Icons.error,
                color: sync['success'] ? Colors.green : Colors.red,
              ),
              title: Text(sync['date']),
              subtitle: Text(sync['message']),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
```

---

## 🎯 Casos de Uso Comuns

### Caso 1: Tela de Boas-Vindas / Onboarding

```dart
// No final do onboarding, direcionar para criar perfil da fazenda
ElevatedButton(
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmProfileScreen(),
      ),
    );
  },
  child: const Text('Criar Perfil da Minha Fazenda'),
)
```

### Caso 2: Configurações / Ajustes

```dart
// Menu de configurações
ListTile(
  leading: const Icon(Icons.agriculture),
  title: const Text('Gerenciar Fazenda'),
  subtitle: const Text('Editar informações da fazenda'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmProfileScreen(),
      ),
    );
  },
)
```

### Caso 3: Dashboard / Home

```dart
// Card informativo na home
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmProfileScreen(),
      ),
    );
  },
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.agriculture, size: 40, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('$totalHectares ha • $totalTalhoes talhões'),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios),
        ],
      ),
    ),
  ),
)
```

---

## 🔐 Segurança e Boas Práticas

### 1. Validar Token Antes de Sincronizar

```dart
Future<bool> isTokenValid() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('base44_token');
  
  if (token == null || token.isEmpty) {
    return false;
  }
  
  // Opcional: verificar validade do token com API
  try {
    final response = await http.get(
      Uri.parse('https://api.base44.com.br/v1/auth/validate'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
```

### 2. Tratar Erros de Rede

```dart
Future<void> syncWithRetry() async {
  int attempts = 0;
  const maxAttempts = 3;
  
  while (attempts < maxAttempts) {
    try {
      final result = await base44Service.syncFarm(farm);
      
      if (result['success']) {
        print('✅ Sincronização concluída');
        return;
      }
    } catch (e) {
      attempts++;
      if (attempts < maxAttempts) {
        print('⚠️ Tentativa $attempts falhou, tentando novamente...');
        await Future.delayed(Duration(seconds: attempts * 2));
      } else {
        print('❌ Todas as tentativas falharam');
        rethrow;
      }
    }
  }
}
```

### 3. Verificar Conectividade

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isConnected() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

Future<void> syncIfConnected() async {
  if (await isConnected()) {
    await _syncWithBase44();
  } else {
    print('⚠️ Sem conexão, sincronização adiada');
  }
}
```

---

## 📱 Permissões Necessárias

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## ✅ Checklist de Integração

- [ ] Adicionar navegação para FarmProfileScreen no menu
- [ ] Configurar token de autenticação Base44
- [ ] Implementar salvamento de token
- [ ] Testar criação de fazenda
- [ ] Testar edição de fazenda
- [ ] Testar sincronização com Base44
- [ ] Implementar sincronização automática (opcional)
- [ ] Adicionar tratamento de erros
- [ ] Testar modo offline
- [ ] Verificar permissões de internet
- [ ] Adicionar loading states
- [ ] Testar em dispositivos reais

---

## 🆘 Problemas Comuns

### Erro: "Token não configurado"
**Solução:** Configure o token antes de sincronizar:
```dart
final base44Service = Base44SyncService();
base44Service.setAuthToken('seu-token-aqui');
```

### Erro: "Timeout ao conectar"
**Solução:** Verifique conectividade ou aumente o timeout:
```dart
// No base44_sync_service.dart, ajuste:
.timeout(
  const Duration(seconds: 60), // Aumentar tempo
)
```

### Erro: "Fazenda não encontrada"
**Solução:** Certifique-se de que a fazenda foi salva antes de sincronizar.

---

## 📞 Suporte

Para dúvidas ou problemas:
- Consulte a documentação completa em `PERFIL_FAZENDA_BASE44.md`
- Verifique os logs com `Logger`
- Entre em contato com a equipe de desenvolvimento

---

**Desenvolvido para FortSmart Agro**  
*Sistema de Gestão Agrícola Inteligente*

