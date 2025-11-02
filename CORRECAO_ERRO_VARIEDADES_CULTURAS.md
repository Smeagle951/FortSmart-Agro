# 🔧 CORREÇÃO DO ERRO DE SALVAMENTO DE VARIEDADES

## 📋 Problema Identificado

O erro `FOREIGN KEY constraint failed (code 787 SQLITE_CONSTRAINT_FOREIGNKEY)` ocorria ao tentar salvar variedades de culturas devido a:

1. **Referência incorreta na tabela `crop_varieties`**: A chave estrangeira estava referenciando `culturas (id)` em vez de `crops (id)`
2. **IDs incompatíveis**: As variedades usavam IDs como `custom_soja` em vez dos IDs numéricos da tabela `crops`
3. **Estrutura inconsistente**: A tabela `crop_varieties` não estava alinhada com a estrutura real da tabela `crops`

## ✅ Soluções Implementadas

### 1. Correção da Chave Estrangeira
- **Arquivo**: `lib/database/migrations/create_crop_varieties_table.dart`
- **Mudança**: `FOREIGN KEY (cropId) REFERENCES culturas (id)` → `FOREIGN KEY (cropId) REFERENCES crops (id)`

### 2. Atualização dos IDs das Variedades
- **Arquivo**: `lib/database/migrations/create_crop_varieties_table.dart`
- **Mudança**: IDs `custom_*` → IDs numéricos (1, 2, 3, etc.)
- **Mapeamento**:
  - `custom_soja` → `1` (Soja)
  - `custom_milho` → `2` (Milho)
  - `custom_sorgo` → `3` (Sorgo)
  - `custom_algodao` → `4` (Algodão)
  - `custom_feijao` → `5` (Feijão)
  - `custom_girassol` → `6` (Girassol)
  - `custom_aveia` → `7` (Aveia)
  - `custom_trigo` → `8` (Trigo)
  - `custom_gergelim` → `9` (Gergelim)

### 3. Migração de Correção
- **Arquivo**: `lib/database/migrations/fix_crop_varieties_foreign_key.dart`
- **Funcionalidades**:
  - Verifica e corrige registros existentes com cropId inválido
  - Recria a tabela com a estrutura correta
  - Mapeia IDs antigos para novos IDs
  - Cria culturas faltantes automaticamente

### 4. Atualização do AppDatabase
- **Versão**: 47 → 48
- **Migração**: Adicionada migração 48 para executar a correção
- **Import**: Adicionado import da migração de correção

### 5. Script de Teste
- **Arquivo**: `lib/scripts/test_crop_variety_saving.dart`
- **Funcionalidades**:
  - Verifica estrutura do banco
  - Testa salvamento de variedades
  - Valida integridade dos dados

## 🗂️ Estrutura das Tabelas

### Tabela `crops`
```sql
CREATE TABLE crops (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  scientific_name TEXT,
  family TEXT,
  description TEXT,
  image_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status INTEGER NOT NULL DEFAULT 0,
  remote_id INTEGER
)
```

### Tabela `crop_varieties` (Corrigida)
```sql
CREATE TABLE crop_varieties (
  id TEXT PRIMARY KEY,
  cropId TEXT NOT NULL,
  name TEXT NOT NULL,
  company TEXT,
  cycleDays INTEGER DEFAULT 0,
  description TEXT,
  recommendedPopulation REAL,
  weightOf1000Seeds REAL,
  notes TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  isSynced INTEGER DEFAULT 0,
  FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE CASCADE
)
```

## 🧪 Como Testar

### 1. Executar o Script de Teste
```bash
dart run lib/scripts/test_crop_variety_saving.dart
```

### 2. Testar no App
1. Abrir o módulo de culturas
2. Selecionar uma cultura (ex: Soja)
3. Tentar adicionar uma nova variedade
4. Verificar se o salvamento funciona sem erro

### 3. Verificar Logs
- Procurar por mensagens de erro de FOREIGN KEY
- Verificar se as variedades são salvas corretamente
- Confirmar que os IDs das culturas estão corretos

## 📊 Resultados Esperados

### Antes da Correção
```
❌ Erro ao salvar variedade: DatabaseException(FOREIGN KEY constraint failed (code 787 SQLITE_CONSTRAINT_FOREIGNKEY))
```

### Após a Correção
```
✅ Variedade inserida com sucesso: Nome da Variedade
✅ Cultura validada com ID: 1
```

## 🔍 Verificações Adicionais

### 1. Verificar Estrutura do Banco
```sql
-- Verificar se a tabela crops existe
SELECT name FROM sqlite_master WHERE type='table' AND name='crops';

-- Verificar se a tabela crop_varieties existe
SELECT name FROM sqlite_master WHERE type='table' AND name='crop_varieties';

-- Verificar culturas disponíveis
SELECT id, name FROM crops ORDER BY id;
```

### 2. Verificar Variedades
```sql
-- Verificar variedades por cultura
SELECT c.name, COUNT(cv.id) as variety_count
FROM crops c
LEFT JOIN crop_varieties cv ON c.id = cv.cropId
GROUP BY c.id, c.name
ORDER BY variety_count DESC;
```

### 3. Verificar Integridade
```sql
-- Verificar variedades com cropId inválido
SELECT cv.id, cv.name, cv.cropId, c.name as crop_name
FROM crop_varieties cv 
LEFT JOIN crops c ON cv.cropId = c.id 
WHERE c.id IS NULL;
```

## 🚀 Próximos Passos

1. **Testar a correção** executando o app
2. **Verificar se o salvamento funciona** para todas as culturas
3. **Monitorar logs** para garantir que não há mais erros
4. **Considerar adicionar validações** adicionais no CropValidationService

## 📝 Notas Técnicas

- A migração é executada automaticamente quando o app é iniciado
- Os dados existentes são preservados durante a correção
- A tabela é recriada apenas se necessário
- Índices são criados para melhorar a performance

## 🎯 Status

- ✅ **Problema identificado**: FOREIGN KEY constraint incorreta
- ✅ **Solução implementada**: Migração de correção
- ✅ **Teste criado**: Script de validação
- 🔄 **Aguardando teste**: Verificação no app real

---

**Data**: 2024-12-21  
**Autor**: Assistente IA  
**Versão**: 1.0
