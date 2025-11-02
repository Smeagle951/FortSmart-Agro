# Guia de Sincronização de Dados entre Módulos

## Problema Identificado

As telas de **Monitoramento Avançado** e **Novo Talhão** estavam com problemas ao carregar:
- Culturas do módulo de culturas da fazenda
- Talhões criados no módulo de talhões

Os dropdowns apareciam vazios mesmo com dados existentes nos respectivos módulos.

## Solução Implementada

Foi criado o utilitário `ModulesDataSync` que:

1. **Unifica o carregamento de dados** entre diferentes fontes
2. **Prioriza as fontes mais atualizadas** (Providers)
3. **Fornece fallbacks** para múltiplas fontes de dados
4. **Simplifica a implementação** nas telas

## Como Usar

### 1. Usando o Utilitário Diretamente

```dart
import '../utils/modules_data_sync.dart';

// Carregar talhões de todas as fontes
final talhoes = await ModulesDataSync.loadTalhoes(context);

// Carregar culturas de todas as fontes
final culturas = await ModulesDataSync.loadCulturas(context);

// Forçar sincronização completa
await ModulesDataSync.forceSyncAllData(context);

// Verificar consistência dos dados
final consistency = await ModulesDataSync.checkDataConsistency(context);
```

### 2. Usando o Mixin (Recomendado)

```dart
class MinhaTelaState extends State<MinhaTela> with ModulesDataSyncMixin {
  List<TalhaoModel> _talhoes = [];
  List<CulturaModel> _culturas = [];
  
  Future<void> _carregarDados() async {
    // Usar os métodos do mixin
    final talhoes = await loadTalhoesSync();
    final culturas = await loadCulturasSync();
    
    setState(() {
      _talhoes = talhoes;
      _culturas = culturas;
    });
  }
}
```

### 3. Usando o DataSyncWrapper

```dart
class MinhaTela extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataSyncWrapper(
      onDataLoaded: () {
        print('Dados sincronizados!');
      },
      child: MeuConteudo(),
    );
  }
}
```

## Implementação nas Telas Afetadas

### Tela de Monitoramento Avançado

**Antes:**
```dart
// Múltiplas tentativas manuais de carregamento
try {
  final talhoes = await _talhaoRepository.getTalhoes();
  // ... mais código
} catch (e) {
  try {
    final talhoes = await _talhaoService.getTalhoes();
    // ... mais código
  } catch (e) {
    // ... mais fallbacks
  }
}
```

**Depois:**
```dart
// Uma linha resolve todos os casos
final talhoes = await ModulesDataSync.loadTalhoes(context);
final culturas = await ModulesDataSync.loadCulturas(context);
```

### Tela de Novo Talhão

**Antes:**
```dart
// Carregamento manual com múltiplas fontes
try {
  final cultureImportService = CultureImportService();
  // ... código complexo
} catch (e) {
  try {
    final culturaProvider = Provider.of<CulturaProvider>(context);
    // ... mais código
  } catch (e) {
    // ... mais fallbacks
  }
}
```

**Depois:**
```dart
// Simplificado com o utilitário
final culturas = await ModulesDataSync.loadCulturas(context);
```

## Vantagens da Solução

### 1. **Consistência**
- Mesma lógica de carregamento em todas as telas
- Ordem de prioridade unificada das fontes de dados

### 2. **Manutenibilidade**
- Uma única implementação para manter
- Mudanças aplicadas automaticamente em todas as telas

### 3. **Robustez**
- Múltiplos fallbacks automáticos
- Tratamento centralizado de erros

### 4. **Facilidade de Uso**
- API simples e intuitiva
- Mixin para casos comuns
- Wrapper para casos complexos

## Fontes de Dados por Prioridade

### Talhões:
1. `TalhaoProvider` (mais atualizado)
2. `TalhaoRepository` (repositório principal)
3. `TalhaoModuleService` (serviço do módulo)
4. `DataCacheService` (cache local)

### Culturas:
1. `CulturaProvider` (fonte principal)
2. `CultureImportService` (módulo de culturas da fazenda)
3. `DataCacheService` (cache local)

## Métodos Disponíveis

### ModulesDataSync (Estático)
- `loadTalhoes(context)` - Carrega talhões
- `loadCulturas(context)` - Carrega culturas
- `forceSyncAllData(context)` - Força sincronização
- `checkDataConsistency(context)` - Verifica consistência

### ModulesDataSyncMixin
- `loadTalhoesSync()` - Carrega talhões
- `loadCulturasSync()` - Carrega culturas
- `forceSyncAllData()` - Força sincronização
- `checkDataConsistency()` - Verifica consistência

### DataSyncWrapper
- Widget que garante sincronização antes de renderizar
- Mostra loading/error states automaticamente
- Callback `onDataLoaded` quando dados estão prontos

## Exemplo Completo

Ver arquivo: `lib/examples/modules_data_sync_example.dart`

## Logs de Debug

O utilitário produz logs detalhados para facilitar debug:

```
🔄 ModulesDataSync: Carregando talhões de todas as fontes...
✅ ModulesDataSync: 5 talhões carregados do TalhaoProvider
  - Talhão Norte (ID: t001) - Área: 15.30 ha
  - Talhão Sul (ID: t002) - Área: 22.45 ha
```

## Resolução do Problema Original

Com essa implementação:

1. **Monitoramento Avançado** agora carrega corretamente:
   - Talhões do módulo Talhões
   - Culturas do módulo Culturas da Fazenda

2. **Novo Talhão** agora carrega corretamente:
   - Culturas do módulo Culturas da Fazenda

3. **Dropdowns funcionam** com dados reais dos módulos

4. **Sincronização automática** entre módulos

## Testes Recomendados

1. Verificar se dropdowns aparecem preenchidos
2. Testar seleção de itens nos dropdowns
3. Verificar se dados persistem entre navegações
4. Testar cenários de erro (dados vazios)
5. Verificar logs de debug para troubleshooting
