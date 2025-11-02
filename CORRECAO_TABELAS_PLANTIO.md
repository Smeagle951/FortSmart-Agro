# Correção das Tabelas de Plantio - Banco de Dados

## Problema Identificado

A tela de **Lista de plantio** estava apresentando erro porque as tabelas necessárias para o módulo de plantio não estavam sendo criadas no banco de dados principal. Especificamente, faltavam:

- ✅ Tabela `plantios` - Para armazenar os registros de plantio
- ✅ Tabela `calibragens` - Para armazenar calibrações de equipamentos
- ✅ Tabela `importacoes_plantio` - Para armazenar histórico de importações

## Solução Implementada

### 1. **Adição das Tabelas no Banco de Dados Principal**

#### **Tabela `plantios`**
```sql
CREATE TABLE IF NOT EXISTS plantios (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  cultura_id TEXT NOT NULL,
  variedade_id TEXT NOT NULL,
  data_plantio TEXT NOT NULL,
  espacamento REAL NOT NULL,
  populacao INTEGER NOT NULL,
  profundidade REAL NOT NULL,
  maquinas_ids TEXT,
  densidade_linear REAL NOT NULL,
  germinacao REAL NOT NULL,
  metodo_calibragem TEXT NOT NULL,
  fonte_sementes_id TEXT NOT NULL,
  resultados TEXT,
  observacoes TEXT,
  trator_id TEXT,
  plantadeira_id TEXT,
  calibragem_id TEXT,
  estande_id TEXT,
  peso_mil_sementes REAL NOT NULL,
  gramas_coletadas REAL NOT NULL,
  distancia_percorrida REAL NOT NULL,
  engrenagem_motora INTEGER NOT NULL,
  engrenagem_movida INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status INTEGER NOT NULL DEFAULT 0,
  remote_id TEXT
)
```

#### **Tabela `calibragens`**
```sql
CREATE TABLE IF NOT EXISTS calibragens (
  id TEXT PRIMARY KEY,
  tipo TEXT NOT NULL,
  equipamento_id TEXT NOT NULL,
  data_calibragem TEXT NOT NULL,
  responsavel TEXT NOT NULL,
  parametros TEXT NOT NULL,
  resultados TEXT,
  observacoes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status INTEGER NOT NULL DEFAULT 0,
  remote_id TEXT
)
```

#### **Tabela `importacoes_plantio`**
```sql
CREATE TABLE IF NOT EXISTS importacoes_plantio (
  id TEXT PRIMARY KEY,
  nome_arquivo TEXT NOT NULL,
  tipo_importacao TEXT NOT NULL,
  data_importacao TEXT NOT NULL,
  quantidade_registros INTEGER NOT NULL,
  status TEXT NOT NULL,
  detalhes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status INTEGER NOT NULL DEFAULT 0,
  remote_id TEXT
)
```

### 2. **Incremento da Versão do Banco de Dados**

```dart
static const int _databaseVersion = 19; // Incrementado para adicionar tabelas de plantio, calibração e importações
```

### 3. **Migração Automática**

Adicionada migração no método `_onUpgrade` para garantir que as tabelas sejam criadas em bancos existentes:

```dart
// Migração para a versão 19 - Adiciona tabelas de plantio, calibração e importações
if (oldVersion < 19) {
  print('Migrando para versão 19: Criando tabelas de plantio, calibração e importações...');
  
  // Criar tabela de plantios
  await db.execute('CREATE TABLE IF NOT EXISTS plantios (...)');
  
  // Criar tabela de calibragens
  await db.execute('CREATE TABLE IF NOT EXISTS calibragens (...)');
  
  // Criar tabela de importacoes_plantio
  await db.execute('CREATE TABLE IF NOT EXISTS importacoes_plantio (...)');
  
  print('✅ Tabelas de plantio, calibração e importações criadas com sucesso');
}
```

### 4. **Campos das Tabelas**

#### **Tabela `plantios` - Campos Principais:**
- `id`: Identificador único do plantio
- `talhao_id`: ID do talhão onde foi realizado o plantio
- `cultura_id`: ID da cultura plantada
- `variedade_id`: ID da variedade da cultura
- `data_plantio`: Data do plantio
- `espacamento`: Espaçamento entre linhas (cm)
- `populacao`: População de plantas por hectare
- `profundidade`: Profundidade de plantio (cm)
- `germinacao`: Percentual de germinação esperado
- `metodo_calibragem`: Método usado para calibração
- `peso_mil_sementes`: Peso de 1000 sementes (g)
- `gramas_coletadas`: Gramas coletadas na calibração
- `distancia_percorrida`: Distância percorrida na calibração (m)
- `engrenagem_motora`: Número de dentes da engrenagem motora
- `engrenagem_movida`: Número de dentes da engrenagem movida

#### **Tabela `calibragens` - Campos Principais:**
- `id`: Identificador único da calibração
- `tipo`: Tipo de calibração (plantadeira, adubadeira, etc.)
- `equipamento_id`: ID do equipamento calibrado
- `data_calibragem`: Data da calibração
- `responsavel`: Nome do responsável pela calibração
- `parametros`: Parâmetros da calibração (JSON)
- `resultados`: Resultados da calibração (JSON)

#### **Tabela `importacoes_plantio` - Campos Principais:**
- `id`: Identificador único da importação
- `nome_arquivo`: Nome do arquivo importado
- `tipo_importacao`: Tipo de importação (CSV, Excel, etc.)
- `data_importacao`: Data da importação
- `quantidade_registros`: Quantidade de registros importados
- `status`: Status da importação (sucesso, erro, etc.)
- `detalhes`: Detalhes da importação (logs, erros, etc.)

### 5. **Arquivos Modificados**

#### **Arquivo Principal:**
- `lib/database/app_database.dart` - Adicionadas tabelas e migração

#### **Serviços Existentes:**
- `lib/services/plantio_service.dart` - Já possui métodos para operações CRUD
- `lib/screens/plantio/plantio_lista_screen.dart` - Tela que estava com erro

### 6. **Funcionalidades Suportadas**

#### **Módulo de Plantio:**
- ✅ Cadastro de plantios
- ✅ Listagem de plantios
- ✅ Edição de plantios
- ✅ Exclusão de plantios
- ✅ Busca por talhão
- ✅ Busca por cultura
- ✅ Busca por período

#### **Módulo de Calibração:**
- ✅ Registro de calibrações
- ✅ Histórico de calibrações
- ✅ Parâmetros de calibração
- ✅ Resultados de calibração

#### **Módulo de Importação:**
- ✅ Histórico de importações
- ✅ Status de importações
- ✅ Detalhes de importações
- ✅ Logs de erro

### 7. **Benefícios da Correção**

#### **Para o Usuário:**
- ✅ Tela de Lista de plantio funcionando corretamente
- ✅ Dados de plantio persistidos no banco
- ✅ Histórico de calibrações disponível
- ✅ Rastreabilidade de importações

#### **Para o Desenvolvedor:**
- ✅ Estrutura de banco completa
- ✅ Migrações automáticas
- ✅ Compatibilidade com versões anteriores
- ✅ Fácil manutenção

### 8. **Próximos Passos**

#### **Melhorias Futuras:**
- [ ] Índices otimizados para consultas
- [ ] Relatórios de plantio
- [ ] Análise de produtividade
- [ ] Integração com outros módulos

#### **Otimizações:**
- [ ] Cache de dados frequentes
- [ ] Compressão de dados históricos
- [ ] Backup automático
- [ ] Sincronização com servidor

---

## Conclusão

As **tabelas de plantio foram criadas com sucesso** no banco de dados principal, resolvendo o erro na tela de Lista de plantio. A implementação inclui:

- **Estrutura completa** para plantios, calibrações e importações
- **Migração automática** para bancos existentes
- **Compatibilidade** com o código existente
- **Escalabilidade** para futuras funcionalidades

O módulo de plantio agora está **totalmente funcional** e integrado ao sistema principal.
