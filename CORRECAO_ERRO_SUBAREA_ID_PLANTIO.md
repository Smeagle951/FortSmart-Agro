# Correção do Erro "no such column: subarea_id" na Tabela Plantio

## Problema Identificado

O erro ocorria ao tentar salvar um plantio no sub módulo "Novo Plantio":

```
Erro ao salvar plantio: Exception: Erro ao salvar plantio: SqfliteFfiException(sqlite_error: 1,, SqliteException(1): while preparing statement, no such column: subarea_id, SQL logic error (code 1))
```

**Causa**: A tabela `plantio` no banco de dados não possuía a coluna `subarea_id`, mas o modelo `Plantio` e o DAO estavam tentando usar essa coluna.

## Análise do Problema

### 1. **Modelo Plantio** ✅
- O modelo `Plantio` já tinha o campo `subareaId` definido corretamente
- O método `toMap()` mapeava corretamente para `subarea_id`

### 2. **DAO de Plantio** ✅  
- O `PlantioDao` estava usando o método `toMap()` corretamente
- Não havia problemas na lógica de inserção/atualização

### 3. **Migração Existente** ⚠️
- A migração `create_lista_plantio_complete_system.dart` já criava a tabela com `subarea_id`
- Mas pode não ter sido executada ou a tabela já existia com estrutura antiga

### 4. **Estrutura do Banco** ❌
- A tabela `plantio` existente não tinha a coluna `subarea_id`
- Causando erro ao tentar fazer UPDATE/INSERT com essa coluna

## Solução Implementada

### 1. **Nova Migração Específica**

Criada a migração `fix_plantio_table_subarea_id.dart`:

```dart
class FixPlantioTableSubareaId {
  static Future<void> up(Database db) async {
    // Verificar se tabela existe
    // Verificar estrutura atual
    // Adicionar colunas faltantes se necessário
    // Fazer backup e restaurar dados existentes
  }
}
```

**Funcionalidades da migração:**
- ✅ Verifica se a tabela `plantio` existe
- ✅ Analisa estrutura atual da tabela
- ✅ Identifica colunas faltantes (`subarea_id`, `variedade`, `espacamento_cm`, `populacao_por_m`)
- ✅ Faz backup dos dados existentes
- ✅ Recria tabela com estrutura completa
- ✅ Restaura dados existentes com valores padrão para novas colunas

### 2. **Integração no AppDatabase**

**Import adicionado:**
```dart
import 'migrations/fix_plantio_table_subarea_id.dart';
```

**Versão do banco atualizada:**
```dart
static const int _databaseVersion = 25; // Atualizado para corrigir coluna subarea_id
```

**Chamada da migração:**
```dart
// Correção da tabela plantio - adicionar coluna subarea_id se necessário
if (oldVersion < 23) {
  print('🔧 Executando correção da tabela plantio...');
  await FixPlantioTableSubareaId.up(db);
}
```

### 3. **Correção Adicional**

**Erro no `subarea_registro_screen.dart`:**
- ❌ Método `_buildFormularioHorizontal()` não existia
- ✅ Corrigido para usar `_buildFormulario()`

## Estrutura Final da Tabela Plantio

```sql
CREATE TABLE plantio (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  subarea_id TEXT,                    -- ✅ Nova coluna
  cultura TEXT NOT NULL,
  variedade TEXT NOT NULL,            -- ✅ Nova coluna  
  data_plantio TEXT NOT NULL,
  espacamento_cm REAL NOT NULL,       -- ✅ Nova coluna
  populacao_por_m REAL NOT NULL,      -- ✅ Nova coluna
  observacao TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  FOREIGN KEY (talhao_id) REFERENCES talhao_safra(id),
  FOREIGN KEY (subarea_id) REFERENCES subarea(id)  -- ✅ Nova FK
);
```

## Logs de Debug Implementados

A migração inclui logs detalhados para acompanhar o processo:

```
🔧 Verificando e corrigindo estrutura da tabela plantio...
📋 Colunas atuais da tabela plantio: [id, talhao_id, cultura, data_plantio, observacao, created_at, updated_at, deleted_at]
🔄 Adicionando colunas faltantes à tabela plantio...
✅ Tabela plantio criada com estrutura completa
✅ Tabela plantio atualizada com sucesso!
```

## Benefícios da Solução

### 1. **Compatibilidade com Dados Existentes**
- ✅ Preserva todos os dados existentes
- ✅ Adiciona valores padrão para novas colunas
- ✅ Mantém integridade referencial

### 2. **Segurança**
- ✅ Faz backup antes de modificar estrutura
- ✅ Usa transações para garantir consistência
- ✅ Tratamento de erros robusto

### 3. **Flexibilidade**
- ✅ Verifica estrutura antes de modificar
- ✅ Pode ser executada múltiplas vezes sem problemas
- ✅ Funciona mesmo se tabela não existir

### 4. **Debugging**
- ✅ Logs detalhados para acompanhar processo
- ✅ Identifica exatamente quais colunas estão faltando
- ✅ Confirma sucesso da operação

## Status da Correção

✅ **Migração criada e integrada**
✅ **Versão do banco atualizada**
✅ **Erro de compilação corrigido**
🔄 **Teste em andamento**

### Próximos Passos:
1. **Testar salvamento de plantio** no sub módulo "Novo Plantio"
2. **Verificar logs** da migração durante execução
3. **Confirmar** que dados são salvos corretamente
4. **Validar** integração com subáreas

## Arquivos Modificados

1. **`lib/database/migrations/fix_plantio_table_subarea_id.dart`** - Nova migração
2. **`lib/database/app_database.dart`** - Integração da migração e versão
3. **`lib/screens/plantio/subarea_registro_screen.dart`** - Correção de método inexistente

## Comando para Testar

```bash
flutter build apk --release
```

A migração será executada automaticamente na primeira execução após a atualização da versão do banco.
