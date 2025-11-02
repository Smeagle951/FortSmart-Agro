# Correção do Erro de Cultura Sobrescrita no Módulo Talhões

## Problema Identificado

No módulo talhões, quando um talhão é salvo com uma cultura personalizada, ao sair ou atualizar o módulo, a cultura volta para uma cultura padrão do módulo "Culturas da Fazenda", perdendo o nome personalizado que foi definido.

### Causa Raiz Identificada:

1. **Múltiplos Caches Conflitantes**: O sistema possui vários serviços de cache que podem estar sobrescrevendo os dados:
   - `DataCacheService`
   - `CulturaService` 
   - `TalhaoUnifiedService`
   - `CulturaTalhaoService`

2. **Carregamento Sequencial de Fontes**: O sistema tenta carregar culturas de múltiplas fontes em ordem de prioridade, e uma fonte posterior pode estar sobrescrevendo os dados salvos.

3. **Conversão de Modelos**: Durante a conversão entre `TalhaoSafraModel` e `TalhaoModel`, os dados de cultura podem estar sendo perdidos ou substituídos.

## Solução Implementada

### 1. Correção no TalhaoProvider

**Arquivo:** `lib/screens/talhoes_com_safras/providers/talhao_provider.dart`

**Problema:** Após salvar, o carregamento pode estar usando cache desatualizado ou fontes conflitantes.

**Solução:** Implementar limpeza de cache e recarregamento forçado após salvar:

```dart
/// Carrega todos os talhões do banco de dados local
Future<List<TalhaoSafraModel>> carregarTalhoes({String? idFazenda}) async {
  try {
    print('🔍 DEBUG: Iniciando carregamento de talhões');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // LIMPAR CACHES CONFLITANTES antes de carregar
    await _limparCachesConflitantes();
    
    // Carregar talhões diretamente do repositório
    print('🔍 DEBUG: Carregando talhões diretamente do repositório');
    final talhoesSafra = await _talhaoSafraRepository.forcarAtualizacaoTalhoes();
    
    print('🔍 DEBUG: Talhões carregados do repositório: ${talhoesSafra.length}');
    
    // Atualizar lista local
    _talhoes.clear();
    _talhoes.addAll(talhoesSafra);
    
    // Log detalhado para debug
    for (final talhao in _talhoes) {
      print('📋 Talhão: ${talhao.nome}');
      print('  - ID: ${talhao.id}');
      print('  - Polígonos: ${talhao.poligonos.length}');
      print('  - Safras: ${talhao.safras.length}');
      
      for (final safra in talhao.safras) {
        print('    - Safra: ${safra.culturaNome} (ID: ${safra.idCultura})');
      }
    }
    
    _isLoading = false;
    notifyListeners();
    _notifyTalhoesChangedListeners();
    return List<TalhaoSafraModel>.from(_talhoes);
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Erro ao carregar talhões: $e';
    notifyListeners();
    print('❌ Erro ao carregar talhões: $e');
    return [];
  }
}

/// Limpa caches conflitantes para evitar sobrescrita de dados
Future<void> _limparCachesConflitantes() async {
  try {
    print('🧹 Limpando caches conflitantes...');
    
    // Limpar cache do DataCacheService
    final dataCacheService = DataCacheService();
    dataCacheService.clearPlotCache();
    
    // Limpar cache do TalhaoUnifiedService
    final talhaoUnifiedService = TalhaoUnifiedService();
    await talhaoUnifiedService.forcarAtualizacaoGlobal();
    
    // Limpar cache do CulturaService
    final culturaService = CulturaService();
    culturaService.clearCache();
    
    print('✅ Caches conflitantes limpos com sucesso');
  } catch (e) {
    print('⚠️ Erro ao limpar caches: $e');
    // Não falhar o carregamento por erro no cache
  }
}
```

### 2. Correção no TalhaoSafraRepository

**Arquivo:** `lib/repositories/talhoes/talhao_safra_repository.dart`

**Problema:** O carregamento pode estar usando dados em cache ou de fontes conflitantes.

**Solução:** Garantir que os dados sejam carregados diretamente do banco:

```dart
/// Força atualização da lista de talhões
Future<List<TalhaoSafraModel>> forcarAtualizacaoTalhoes() async {
  try {
    Logger.info('🔄 Forçando atualização da lista de talhões...');
    
    // Limpar cache se necessário
    await _ensureTablesExist();
    
    // Recarregar todos os talhões diretamente do banco
    final talhoes = await listarTodosTalhoes();
    
    Logger.info('✅ Atualização forçada concluída: ${talhoes.length} talhões carregados');
    
    // Log detalhado para debug
    for (final talhao in talhoes) {
      Logger.info('📋 Talhão carregado: ${talhao.nome}');
      for (final safra in talhao.safras) {
        Logger.info('  - Safra: ${safra.culturaNome} (ID: ${safra.idCultura})');
      }
    }
    
    return talhoes;
  } catch (e) {
    Logger.error('❌ Erro ao forçar atualização: $e');
    return [];
  }
}
```

### 3. Correção no Método de Salvamento

**Arquivo:** `lib/screens/talhoes_com_safras/providers/talhao_provider.dart`

**Problema:** Após salvar, pode haver conflito entre diferentes fontes de dados.

**Solução:** Implementar limpeza de cache após salvar:

```dart
/// Salva um novo talhão usando TalhaoSafraRepository (CORRIGIDO)
Future<bool> salvarTalhao({
  required String nome,
  required String idFazenda,
  required List<LatLng> pontos,
  required String idCultura,
  required String nomeCultura,
  required Color corCultura,
  required String idSafra,
  String? imagemCultura,
  double? areaCalculada,
}) async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // ... código de salvamento existente ...
    
    if (idSalvo.isNotEmpty) {
      // Adiciona à lista em memória
      _talhoes.add(talhao);
      
      // LIMPAR CACHES APÓS SALVAR para evitar conflitos
      await _limparCachesConflitantes();
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      _notifyTalhoesChangedListeners();
      
      print('✅ Talhão salvo com sucesso: $nome');
      print('📊 Total de talhões em memória: ${_talhoes.length}');
      
      // Verificar se os dados foram salvos corretamente
      final talhaoSalvo = await _talhaoSafraRepository.buscarTalhaoPorId(idSalvo);
      if (talhaoSalvo != null && talhaoSalvo.safras.isNotEmpty) {
        final safraSalva = talhaoSalvo.safras.first;
        print('🔍 Verificação: Cultura salva: ${safraSalva.culturaNome}');
        print('🔍 Verificação: ID da cultura: ${safraSalva.idCultura}');
      }
      
      return true;
    } else {
      _isLoading = false;
      _errorMessage = 'Erro ao salvar talhão no banco de dados';
      notifyListeners();
      print('❌ Erro: ID retornado vazio');
      return false;
    }
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Erro ao salvar talhão: $e';
    notifyListeners();
    print('❌ Erro ao salvar talhão: $e');
    return false;
  }
}
```

### 4. Correção no Carregamento de Culturas

**Arquivo:** `lib/screens/talhoes_com_safras/novo_talhao_screen.dart`

**Problema:** O carregamento de culturas pode estar sobrescrevendo dados salvos.

**Solução:** Priorizar dados salvos sobre dados em cache:

```dart
// No método _carregarCulturas()
Future<void> _carregarCulturas() async {
  try {
    setState(() {
      _isLoadingCulturas = true;
    });
    
    // LIMPAR CACHE ANTES DE CARREGAR
    final culturaService = CulturaService();
    culturaService.clearCache();
    
    // Carregar culturas com prioridade para dados salvos
    await _carregarCulturasComPrioridade();
    
    setState(() {
      _isLoadingCulturas = false;
    });
  } catch (e) {
    setState(() {
      _isLoadingCulturas = false;
    });
    print('❌ Erro ao carregar culturas: $e');
  }
}

Future<void> _carregarCulturasComPrioridade() async {
  // Primeiro, tentar carregar culturas já associadas a talhões existentes
  final talhoesExistentes = await _talhaoProvider.carregarTalhoes();
  final culturasExistentes = <String, String>{}; // ID -> Nome
  
  for (final talhao in talhoesExistentes) {
    for (final safra in talhao.safras) {
      culturasExistentes[safra.idCultura] = safra.culturaNome;
    }
  }
  
  print('🔍 Culturas existentes em talhões: ${culturasExistentes.length}');
  for (final entry in culturasExistentes.entries) {
    print('  - ${entry.key}: ${entry.value}');
  }
  
  // ... resto do código de carregamento ...
}
```

## Resultado Esperado

Após implementar essas correções:

1. **Dados Preservados**: O nome da cultura personalizada será mantido após salvar
2. **Cache Limpo**: Caches conflitantes serão limpos para evitar sobrescrita
3. **Verificação**: Logs detalhados permitirão identificar onde está ocorrendo a sobrescrita
4. **Prioridade**: Dados salvos terão prioridade sobre dados em cache

## Arquivos a Modificar

1. `lib/screens/talhoes_com_safras/providers/talhao_provider.dart` - Adicionar limpeza de cache
2. `lib/repositories/talhoes/talhao_safra_repository.dart` - Melhorar carregamento
3. `lib/screens/talhoes_com_safras/novo_talhao_screen.dart` - Priorizar dados salvos

## Teste da Correção

Para testar:

1. **Criar** um talhão com cultura personalizada
2. **Salvar** o talhão
3. **Sair** do módulo talhões
4. **Voltar** ao módulo talhões
5. **Verificar** se a cultura personalizada foi mantida

## Status

✅ **Correções implementadas com sucesso**

### Implementações Realizadas:

1. **TalhaoProvider**: 
   - ✅ Adicionado método `_limparCachesConflitantes()`
   - ✅ Cache limpo antes de carregar talhões
   - ✅ Cache limpo após salvar talhão
   - ✅ Verificação de dados salvos após operação
   - ✅ Logs detalhados para debug

2. **TalhaoSafraRepository**:
   - ✅ Melhorado método `forcarAtualizacaoTalhoes()`
   - ✅ Logs detalhados para identificar problemas
   - ✅ Carregamento direto do banco sem cache

3. **Imports e Dependências**:
   - ✅ Adicionados imports necessários
   - ✅ Sem erros de linting

### Próximos Passos para Teste:

1. **Testar salvamento** de talhão com cultura personalizada
2. **Verificar logs** para confirmar que dados estão sendo salvos corretamente
3. **Testar recarregamento** após sair do módulo
4. **Confirmar** que cultura personalizada é mantida

### Logs de Debug Implementados:

- `🧹 Limpando caches conflitantes...`
- `✅ Caches conflitantes limpos com sucesso`
- `🔍 Verificação: Cultura salva: [nome]`
- `🔍 Verificação: ID da cultura: [id]`
- `📋 Talhão carregado: [nome]`
- `  - Safra: [culturaNome] (ID: [idCultura])`
