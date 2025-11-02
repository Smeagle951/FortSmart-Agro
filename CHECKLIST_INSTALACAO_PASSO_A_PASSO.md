# ✅ Checklist de Instalação - Passo a Passo

## 📋 Pré-requisitos Verificados

### Dependências no pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  uuid: ^3.0.7
  intl: ^0.18.1
  # Verificar se estas dependências existem no seu projeto
```

**Ação:** ✅ Adicionar dependências se necessário
```bash
flutter pub add uuid intl
flutter pub get
```

---

## 🔧 Passo 1: Verificar Estrutura de Pastas

### Estrutura Necessária
```
lib/
├── models/
│   ├── aplicacao.dart                    ✅ Verificar se existe
│   ├── talhao_model.dart                 ✅ Verificar se existe
│   └── cultura_model.dart                ✅ Verificar se existe
├── modules/
│   └── application/
│       └── models/                       ✅ Criar se não existir
├── services/                             ✅ Criar se não existir
├── screens/
│   ├── custos/                           ✅ Criar se não existir
│   └── historico/                        ✅ Criar se não existir
└── utils/
    ├── logger.dart                       ✅ Verificar se existe
    └── date_utils.dart                   ✅ Criar
```

**Ação:** ✅ Criar diretórios necessários
```bash
mkdir -p lib/modules/application/models
mkdir -p lib/services
mkdir -p lib/screens/custos
mkdir -p lib/screens/historico
```

---

## 📁 Passo 2: Criar Arquivos Novos

### Lista de Arquivos a Criar
1. ✅ `lib/modules/application/models/application_calculation_model.dart`
2. ✅ `lib/modules/application/models/application_product.dart`
3. ✅ `lib/services/custo_aplicacao_integration_service.dart`
4. ✅ `lib/screens/custos/custo_por_hectare_dashboard_screen.dart`
5. ✅ `lib/screens/historico/historico_custos_talhao_screen.dart`
6. ✅ `lib/utils/date_utils.dart`
7. ✅ `lib/screens/main_menu_with_costs_integration.dart`

**Ação:** ✅ Copiar código de cada arquivo conforme implementado

---

## 🔗 Passo 3: Integração no Menu Principal

### Opção A: Usar Menu de Exemplo
```dart
// Em main.dart
import 'screens/main_menu_with_costs_integration.dart';

// Navegar para o menu com custos
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MainMenuWithCostsIntegration(),
  ),
);
```

### Opção B: Integrar no Menu Existente
```dart
// Adicionar ao menu existente
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
```

**Ação:** ✅ Escolher opção e implementar

---

## 🗄️ Passo 4: Configuração do Banco de Dados

### Verificar DAOs Existentes
- ✅ `AplicacaoDao` - Verificar se existe
- ✅ `ProdutoEstoqueDao` - Verificar se existe
- ✅ `TalhaoDao` - Verificar se existe

### Adicionar Métodos Necessários
```dart
// Em AplicacaoDao (se não existir)
Future<List<Aplicacao>> buscarPorTalhao(String talhaoId);
Future<List<Aplicacao>> buscarPorPeriodo({
  required DateTime dataInicio,
  required DateTime dataFim,
  String? talhaoId,
});

// Em ProdutoEstoqueDao (se não existir)
Future<bool> atualizarSaldo(String produtoId, double novoSaldo);
```

**Ação:** ✅ Implementar métodos se necessário

---

## ⚙️ Passo 5: Configuração de Serviços

### Inicializar Serviços
```dart
// Em main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços
  final custoService = CustoAplicacaoIntegrationService();
  
  runApp(MyApp());
}
```

### Configurar Logger (se não existir)
```dart
// Em utils/logger.dart
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

**Ação:** ✅ Configurar serviços

---

## 🧪 Passo 6: Testes de Validação

### Teste de Compilação
```bash
flutter analyze
flutter build apk --debug
```

### Teste de Navegação
1. ✅ Executar o app
2. ✅ Navegar para Dashboard de Custos
3. ✅ Testar filtros
4. ✅ Navegar para Histórico de Custos
5. ✅ Testar funcionalidades

### Teste de Funcionalidades
- ✅ Filtros funcionando
- ✅ Cálculos automáticos
- ✅ Navegação entre telas
- ✅ Ações (editar, remover, etc.)
- ✅ Responsividade

**Ação:** ✅ Executar todos os testes

---

## 🐛 Passo 7: Solução de Problemas Comuns

### Erro: "Target of URI doesn't exist"
**Solução:** Verificar se o arquivo existe e o caminho está correto

### Erro: "The method 'xxx' isn't defined"
**Solução:** Implementar o método no DAO correspondente

### Erro: "No such file or directory"
**Solução:** Criar o arquivo e copiar o código

### Erro: "The getter 'xxx' isn't defined"
**Solução:** Verificar se o modelo tem a propriedade ou adicionar

**Ação:** ✅ Resolver problemas encontrados

---

## ✅ Checklist Final de Verificação

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

## 🎯 Status da Instalação

**Progresso:** 0% → 100%

**Próximo Passo:** Após completar este checklist, prosseguir para:
1. 🔄 Integração com dados reais
2. 🎨 Personalização de cores e estilos
3. 🧪 Validação completa das funcionalidades

---

## 📞 Suporte Durante Instalação

Se encontrar problemas durante a instalação:

1. **Verificar logs:** `flutter logs`
2. **Limpar cache:** `flutter clean && flutter pub get`
3. **Verificar versão:** `flutter doctor`
4. **Consultar documentação:** Verificar arquivos de documentação criados

**Status:** ✅ Pronto para iniciar instalação
