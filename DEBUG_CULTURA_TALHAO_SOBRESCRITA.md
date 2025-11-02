# Debug: Problema de Sobrescrita de Cultura em Talhões

## Problema Relatado
O usuário salva um talhão com uma cultura personalizada (ex: "Gergelim"), mas ao sair e entrar novamente no módulo, o nome da cultura é alterado automaticamente.

## Análise do Código

### ✅ Fluxo de Salvamento (Funcionando)
1. **`TalhaoProvider.salvarTalhao()`**:
   ```dart
   final safra = SafraTalhaoModel(
     id: const Uuid().v4(),
     idTalhao: talhaoId,
     idSafra: idSafra,
     idCultura: idCultura,           // ✅ Salvo corretamente
     culturaNome: nomeCultura,       // ✅ Salvo corretamente
     culturaCor: corCultura,         // ✅ Salvo corretamente
     area: area,
     dataCadastro: DateTime.now(),
     dataAtualizacao: DateTime.now(),
   );
   ```

2. **`TalhaoSafraRepository.adicionarTalhao()`**:
   ```dart
   await txn.insert(
     tabelaSafraTalhao,
     {
       'id': safra.id,
       'idTalhao': talhao.id,
       'idSafra': safra.idSafra,
       'idCultura': safra.idCultura,      // ✅ Salvo no banco
       'culturaNome': safra.culturaNome,  // ✅ Salvo no banco
       'culturaCor': safra.culturaCor.value,
       // ...
     },
   );
   ```

3. **`TalhaoSafraRepository._carregarTalhaoCompleto()`**:
   ```dart
   final safrasModels = safras.map((s) => SafraTalhaoModel.fromMap({
     'id': s['id'],
     'idTalhao': s['idTalhao'],
     'idSafra': s['idSafra'],
     'idCultura': s['idCultura'],      // ✅ Carregado do banco
     'culturaNome': s['culturaNome'],  // ✅ Carregado do banco
     'culturaCor': s['culturaCor'],
     // ...
   })).toList();
   ```

### ⚠️ Possíveis Pontos de Interferência

#### 1. **Cache Conflitante**
- `CulturaService` - Carrega culturas do módulo "Culturas da Fazenda"
- `CulturaTalhaoService` - Integra culturas com talhões  
- `DataCacheService` - Cache geral do sistema
- `TalhaoUnifiedService` - Cache unificado de talhões

#### 2. **Carregamento de Culturas da Fazenda**
No `novo_talhao_screen.dart`, o sistema carrega culturas do módulo "Culturas da Fazenda":

```dart
// Carrega culturas do módulo Culturas da Fazenda
final culturasFazenda = await culturaTalhaoService.listarCulturas();
final culturasConvertidas = culturasFazenda.map((crop) => CulturaModel(
  id: crop['id']?.toString() ?? '0',
  name: crop['nome'] ?? '',  // ⚠️ Pode estar sobrescrevendo
  color: crop['cor'] ?? _obterCorPorNome(crop['nome'] ?? ''),
  description: crop['descricao'] ?? '',
)).toList();
```

#### 3. **Mapeamento por ID**
Se o `idCultura` fornecido não corresponde a uma cultura existente no módulo "Culturas da Fazenda", o sistema pode estar fazendo fallback.

## Estratégia de Debug

### 1. **Logs Detalhados de Salvamento**
```dart
print('🔍 DEBUG SALVAMENTO:');
print('  - Nome da cultura recebido: $nomeCultura');
print('  - ID da cultura recebido: $idCultura');
print('  - Cor da cultura recebida: $corCultura');
```

### 2. **Logs Detalhados de Carregamento**
```dart
print('🔍 DEBUG CARREGAMENTO:');
print('  - Nome da cultura carregada: ${safra.culturaNome}');
print('  - ID da cultura carregado: ${safra.idCultura}');
print('  - Cor da cultura carregada: ${safra.culturaCor}');
```

### 3. **Verificação de Cache**
```dart
print('🔍 DEBUG CACHE:');
print('  - Cache de culturas válido: ${_isCacheValid()}');
print('  - Culturas em cache: ${_cachedCultures?.length}');
```

### 4. **Verificação de Fallback**
```dart
print('🔍 DEBUG FALLBACK:');
print('  - Cultura encontrada por ID: ${culturaEncontrada?.name}');
print('  - Cultura encontrada por nome: ${culturaPorNome?.name}');
```

## Teste Sugerido

### Cenário de Teste:
1. **Criar talhão** com cultura personalizada "Gergelim" (que não existe no módulo "Culturas da Fazenda")
2. **Salvar talhão** e verificar logs
3. **Sair do módulo** e **entrar novamente**
4. **Verificar se** "Gergelim" foi mantido ou alterado
5. **Analisar logs** para identificar onde ocorreu a alteração

### Dados de Teste:
- **Nome do Talhão**: "Teste Gergelim"
- **Cultura**: "Gergelim" (personalizada)
- **ID Cultura**: "custom_gergelim"
- **Cor**: Verde personalizada

## Soluções Possíveis

### 1. **Preservar Culturas Personalizadas**
Modificar o sistema para distinguir entre culturas do módulo "Culturas da Fazenda" e culturas personalizadas.

### 2. **Cache Mais Inteligente**
Implementar cache que preserve culturas personalizadas e não as sobrescreva com dados do módulo "Culturas da Fazenda".

### 3. **Validação de ID**
Verificar se o `idCultura` fornecido corresponde a uma cultura existente antes de fazer fallback.

### 4. **Logs de Auditoria**
Implementar sistema de logs que rastreie todas as alterações de cultura para identificar exatamente onde ocorre a sobrescrita.

## Próximos Passos

1. **Implementar logs detalhados** nos pontos críticos
2. **Testar cenário específico** com cultura personalizada
3. **Analisar logs** para identificar ponto exato da sobrescrita
4. **Implementar correção** baseada nos achados
