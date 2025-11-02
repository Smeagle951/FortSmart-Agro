# 🚀 Guia de Instalação - Sistema de Custos por Hectare

## 📋 Pré-requisitos

### Dependências do Flutter
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  uuid: ^3.0.7
  intl: ^0.18.1
  # Outras dependências existentes...
```

### Estrutura de Pastas Necessária
```
lib/
├── models/
│   ├── aplicacao.dart                    ✅ Existente
│   ├── talhao_model.dart                 ✅ Existente
│   └── cultura_model.dart                ✅ Necessário
├── modules/
│   └── application/
│       └── models/
│           ├── application_calculation_model.dart    ✅ Novo
│           └── application_product.dart              ✅ Novo
├── services/
│   └── custo_aplicacao_integration_service.dart      ✅ Novo
├── screens/
│   ├── custos/
│   │   └── custo_por_hectare_dashboard_screen.dart   ✅ Novo
│   └── historico/
│       └── historico_custos_talhao_screen.dart       ✅ Novo
└── utils/
    ├── logger.dart                       ✅ Existente
    └── date_utils.dart                   ✅ Novo
```

---

## 🔧 Passos de Instalação

### 1. Instalar Dependências
```bash
# No terminal, na pasta do projeto
flutter pub get
```

### 2. Verificar Modelos Existentes
Certifique-se de que os seguintes modelos existem:
- `lib/models/aplicacao.dart`
- `lib/models/talhao_model.dart`
- `lib/models/cultura_model.dart`

### 3. Criar Arquivos Novos
Execute os seguintes comandos para criar a estrutura:

```bash
# Criar diretórios
mkdir -p lib/modules/application/models
mkdir -p lib/services
mkdir -p lib/screens/custos
mkdir -p lib/screens/historico

# Criar arquivos (se não existirem)
touch lib/modules/application/models/application_calculation_model.dart
touch lib/modules/application/models/application_product.dart
touch lib/services/custo_aplicacao_integration_service.dart
touch lib/screens/custos/custo_por_hectare_dashboard_screen.dart
touch lib/screens/historico/historico_custos_talhao_screen.dart
touch lib/utils/date_utils.dart
```

### 4. Copiar Código
Copie o código de cada arquivo conforme implementado anteriormente:

1. **ApplicationCalculationModel** → `lib/modules/application/models/application_calculation_model.dart`
2. **ApplicationProduct** → `lib/modules/application/models/application_product.dart`
3. **CustoAplicacaoIntegrationService** → `lib/services/custo_aplicacao_integration_service.dart`
4. **Dashboard de Custos** → `lib/screens/custos/custo_por_hectare_dashboard_screen.dart`
5. **Histórico de Custos** → `lib/screens/historico/historico_custos_talhao_screen.dart`
6. **DateUtils** → `lib/utils/date_utils.dart`

---

## 🔗 Integração no Menu Principal

### Opção 1: Usar o Menu de Exemplo
```dart
// Em main.dart ou onde estiver o menu principal
import 'screens/main_menu_with_costs_integration.dart';

// Navegar para o menu com custos
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MainMenuWithCostsIntegration(),
  ),
);
```

### Opção 2: Integrar no Menu Existente
Adicione os seguintes itens ao seu menu principal:

```dart
// Seção de Custos e Análises
ListTile(
  leading: Icon(Icons.dashboard, color: Colors.green),
  title: Text('Dashboard de Custos'),
  subtitle: Text('Visualize custos por hectare'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CustoPorHectareDashboardScreen(),
    ),
  ),
),

ListTile(
  leading: Icon(Icons.history, color: Colors.blue),
  title: Text('Histórico de Custos'),
  subtitle: Text('Histórico completo por talhão'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HistoricoCustosTalhaoScreen(),
    ),
  ),
),
```

---

## 🗄️ Configuração do Banco de Dados

### 1. Verificar DAOs Existentes
Certifique-se de que os seguintes DAOs existem:
- `AplicacaoDao`
- `ProdutoEstoqueDao`
- `TalhaoDao`

### 2. Adicionar Métodos Necessários
Se os métodos não existirem, adicione-os aos DAOs:

```dart
// Em AplicacaoDao
Future<List<Aplicacao>> buscarPorTalhao(String talhaoId);
Future<List<Aplicacao>> buscarPorPeriodo({
  required DateTime dataInicio,
  required DateTime dataFim,
  String? talhaoId,
});

// Em ProdutoEstoqueDao
Future<bool> atualizarSaldo(String produtoId, double novoSaldo);
```

### 3. Configurar Tabelas (se necessário)
```sql
-- Tabela de aplicações (se não existir)
CREATE TABLE aplicacoes (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  produto_id TEXT NOT NULL,
  dose_por_ha REAL NOT NULL,
  area_aplicada_ha REAL NOT NULL,
  preco_unitario_momento REAL NOT NULL,
  data_aplicacao TEXT NOT NULL,
  operador TEXT,
  equipamento TEXT,
  condicoes_climaticas TEXT,
  observacoes TEXT,
  fazenda_id TEXT,
  data_criacao TEXT NOT NULL,
  data_atualizacao TEXT NOT NULL,
  is_sincronizado INTEGER DEFAULT 0
);
```

---

## ⚙️ Configuração de Serviços

### 1. Inicializar Serviços
```dart
// Em main.dart ou configuração inicial
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços
  final custoService = CustoAplicacaoIntegrationService();
  
  runApp(MyApp());
}
```

### 2. Configurar Logger
```dart
// Em utils/logger.dart (se não existir)
class Logger {
  static void info(String message) {
    print('ℹ️ INFO: $message');
  }
  
  static void error(String message) {
    print('❌ ERROR: $message');
  }
  
  static void warning(String message) {
    print('⚠️ WARNING: $message');
  }
}
```

---

## 🧪 Testes e Validação

### 1. Teste de Compilação
```bash
# Verificar se compila sem erros
flutter analyze
flutter build apk --debug
```

### 2. Teste de Navegação
1. Execute o app
2. Navegue para o Dashboard de Custos
3. Teste os filtros
4. Navegue para o Histórico de Custos
5. Teste as funcionalidades

### 3. Teste de Funcionalidades
- ✅ Filtros funcionando
- ✅ Cálculos automáticos
- ✅ Navegação entre telas
- ✅ Ações (editar, remover, etc.)
- ✅ Responsividade

---

## 🐛 Solução de Problemas

### Erro: "Target of URI doesn't exist"
**Problema:** Import não encontrado
**Solução:** Verificar se o arquivo existe e o caminho está correto

### Erro: "The method 'xxx' isn't defined"
**Problema:** Método não existe no DAO
**Solução:** Implementar o método no DAO correspondente

### Erro: "No such file or directory"
**Problema:** Arquivo não criado
**Solução:** Criar o arquivo e copiar o código

### Erro: "The getter 'xxx' isn't defined"
**Problema:** Propriedade não existe no modelo
**Solução:** Verificar se o modelo tem a propriedade ou adicionar

---

## 📱 Configuração de Permissões

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
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

## 🔄 Atualizações e Manutenção

### 1. Backup Antes de Atualizar
```bash
# Fazer backup do projeto
cp -r . ../fortsmart_agro_backup_$(date +%Y%m%d_%H%M%S)
```

### 2. Verificar Compatibilidade
- Testar em diferentes versões do Flutter
- Verificar compatibilidade com dependências
- Testar em diferentes dispositivos

### 3. Logs de Debug
```dart
// Ativar logs detalhados
Logger.info('Iniciando sistema de custos...');
Logger.info('Carregando dados...');
Logger.error('Erro ao carregar: $e');
```

---

## 📞 Suporte

### Documentação
- ✅ Código comentado
- ✅ Documentação técnica completa
- ✅ Exemplos de uso

### Contato
Para suporte técnico ou dúvidas:
- 📧 Email: suporte@fortsmart.com
- 📱 WhatsApp: (11) 99999-9999
- 🌐 Website: www.fortsmart.com

---

## ✅ Checklist Final

### Instalação
- [ ] Dependências instaladas
- [ ] Arquivos criados
- [ ] Código copiado
- [ ] Estrutura de pastas correta

### Integração
- [ ] Menu principal atualizado
- [ ] Navegação funcionando
- [ ] Imports corretos
- [ ] Serviços inicializados

### Banco de Dados
- [ ] DAOs configurados
- [ ] Métodos implementados
- [ ] Tabelas criadas (se necessário)
- [ ] Conexão funcionando

### Testes
- [ ] Compilação sem erros
- [ ] Navegação testada
- [ ] Funcionalidades validadas
- [ ] Responsividade verificada

### Configuração
- [ ] Permissões configuradas
- [ ] Logger funcionando
- [ ] Logs de debug ativos
- [ ] Backup realizado

---

## 🎯 Próximos Passos

Após a instalação bem-sucedida:

1. **Personalização:** Adaptar cores e estilos
2. **Integração:** Conectar com dados reais
3. **Testes:** Testes unitários e de integração
4. **Otimização:** Melhorar performance
5. **Funcionalidades:** Adicionar novas features

---

## 🚀 Conclusão

O sistema de custos por hectare está pronto para uso! 

**Funcionalidades Disponíveis:**
- 📊 Dashboard de custos interativo
- 📈 Histórico completo por talhão
- 🧮 Simulador de custos
- 📋 Relatórios detalhados
- 🔄 Integração com estoque
- 📱 Interface responsiva

**Benefícios:**
- Controle total de custos
- Análises em tempo real
- Tomada de decisão baseada em dados
- Otimização de recursos
- Gestão eficiente

O sistema está preparado para crescer e pode ser facilmente expandido com novas funcionalidades conforme necessário.
