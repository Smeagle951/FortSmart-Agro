# Guia de Correção do Salvamento de Monitoramento

## Problema Identificado

O botão "Salvar e Finalizar" na tela de monitoramento não estava salvando os dados corretamente, retornando o erro "Falha ao salvar monitoramento no repositório".

## Causas Identificadas

1. **Tabelas do banco de dados não existiam ou estavam corrompidas**
2. **Dados inválidos sendo passados para o repositório**
3. **Falta de validação antes do salvamento**
4. **Problemas de estrutura nas tabelas do banco**

## Soluções Implementadas

### 1. Serviço de Correção do Banco de Dados (`MonitoringDatabaseFixService`)

**Arquivo:** `lib/services/monitoring_database_fix_service.dart`

**Funcionalidades:**
- ✅ Verifica e cria todas as tabelas necessárias
- ✅ Corrige estrutura das tabelas (adiciona colunas faltantes)
- ✅ Corrige dados corrompidos (IDs nulos, datas inválidas, etc.)
- ✅ Cria índices para melhor performance
- ✅ Testa conexão com o banco de dados
- ✅ Remove dados de teste ou corrompidos

**Tabelas Criadas/Corrigidas:**
- `monitorings` - Tabela principal de monitoramentos
- `monitoring_points` - Pontos de monitoramento
- `occurrences` - Ocorrências registradas
- `monitoring_alerts` - Alertas do sistema

### 2. Serviço de Validação (`MonitoringValidationService`)

**Arquivo:** `lib/services/monitoring_validation_service.dart`

**Funcionalidades:**
- ✅ Valida dados básicos do monitoramento
- ✅ Valida pontos e suas coordenadas
- ✅ Valida ocorrências e seus índices
- ✅ Verifica IDs únicos
- ✅ Aplica correções automáticas quando possível
- ✅ Gera relatórios detalhados de validação

**Validações Implementadas:**
- IDs obrigatórios e únicos
- Coordenadas válidas (latitude/longitude)
- Índices de infestação entre 0-100%
- Datas válidas
- Estrutura de dados correta

### 3. Melhorias no `MonitoringPointScreen`

**Arquivo:** `lib/screens/monitoring/monitoring_point_screen.dart`

**Modificações:**
- ✅ Inicialização automática do banco de dados
- ✅ Validação antes do salvamento
- ✅ Melhor tratamento de erros
- ✅ Logs detalhados para debug
- ✅ Correção automática de dados

### 4. Script de Teste

**Arquivo:** `lib/scripts/test_monitoring_save.dart`

**Funcionalidades:**
- ✅ Testa correção do banco de dados
- ✅ Testa validação de dados
- ✅ Testa salvamento e recuperação
- ✅ Cria dados de teste realistas
- ✅ Limpa dados de teste

## Como Usar

### 1. Correção Automática

O sistema agora corrige automaticamente problemas comuns:

```dart
// Na inicialização da tela
await _databaseFixService.fixMonitoringDatabase();

// Antes de salvar
final validationResult = await _validationService.validateMonitoring(monitoring);
if (!validationResult['isValid']) {
  // Aplicar correções
  final correctedMonitoring = await _validationService.fixMonitoring(monitoring);
  await _monitoringRepository.saveMonitoring(correctedMonitoring);
}
```

### 2. Executar Testes

Para testar se tudo está funcionando:

```bash
# No terminal, dentro do projeto
flutter run lib/scripts/test_monitoring_save.dart
```

### 3. Verificar Logs

Os logs detalhados ajudam a identificar problemas:

```
🔧 Verificando e corrigindo banco de dados...
✅ Banco de dados corrigido com sucesso
🔍 Validando monitoramento...
✅ Monitoramento válido
💾 Salvando monitoramento no repositório...
✅ Monitoramento salvo com sucesso
```

## Estrutura das Tabelas

### Tabela `monitorings`
```sql
CREATE TABLE monitorings (
  id TEXT PRIMARY KEY,
  plot_id TEXT NOT NULL,
  plotName TEXT,
  crop_id TEXT NOT NULL,
  cropName TEXT,
  cropType TEXT,
  date TEXT NOT NULL,
  route TEXT,
  isCompleted INTEGER DEFAULT 0,
  isSynced INTEGER DEFAULT 0,
  severity INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  metadata TEXT,
  technicianName TEXT,
  technicianIdentification TEXT,
  latitude REAL,
  longitude REAL,
  pests TEXT,
  diseases TEXT,
  weeds TEXT,
  images TEXT,
  observations TEXT,
  recommendations TEXT,
  sync_status INTEGER DEFAULT 0
)
```

### Tabela `monitoring_points`
```sql
CREATE TABLE monitoring_points (
  id TEXT PRIMARY KEY,
  monitoring_id TEXT NOT NULL,
  plot_id TEXT NOT NULL,
  plot_name TEXT,
  crop_id INTEGER,
  crop_name TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  occurrences TEXT,
  image_paths TEXT,
  audio_path TEXT,
  observations TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  is_synced INTEGER DEFAULT 0,
  metadata TEXT,
  sync_status INTEGER DEFAULT 0,
  FOREIGN KEY (monitoring_id) REFERENCES monitorings (id) ON DELETE CASCADE
)
```

### Tabela `occurrences`
```sql
CREATE TABLE occurrences (
  id TEXT PRIMARY KEY,
  monitoring_id TEXT NOT NULL,
  point_id TEXT NOT NULL,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  infestationIndex REAL NOT NULL,
  affectedSections TEXT,
  notes TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (monitoring_id) REFERENCES monitorings (id) ON DELETE CASCADE,
  FOREIGN KEY (point_id) REFERENCES monitoring_points (id) ON DELETE CASCADE
)
```

## Fluxo de Salvamento Corrigido

1. **Inicialização**
   - Corrige banco de dados automaticamente
   - Inicializa repositório

2. **Validação**
   - Valida todos os dados antes de salvar
   - Aplica correções automáticas
   - Gera relatório de validação

3. **Salvamento**
   - Salva monitoramento principal
   - Salva pontos em lote
   - Salva ocorrências
   - Verifica se foi salvo corretamente

4. **Processamento**
   - Processa para análise
   - Gera alertas se necessário
   - Mostra confirmação de sucesso

## Tratamento de Erros

### Erros Comuns e Soluções

1. **"ID do monitoramento é obrigatório"**
   - ✅ Gera ID automaticamente

2. **"Plot ID inválido"**
   - ✅ Define como 1 automaticamente

3. **"Coordenadas inválidas"**
   - ✅ Valida latitude (-90 a 90) e longitude (-180 a 180)

4. **"Índice de infestação inválido"**
   - ✅ Corrige para 0-100% automaticamente

5. **"Tabela não existe"**
   - ✅ Cria tabela automaticamente

## Logs e Debug

O sistema agora gera logs detalhados:

```
🔄 Finalizando monitoramento...
📊 Dados do monitoramento:
  - ID: monitoring-123
  - Talhão: Talhão A
  - Cultura ID: 1
  - Pontos: 3
🔧 Verificando banco de dados...
✅ Banco de dados funcionando
🔍 Validando monitoramento...
✅ Monitoramento válido
💾 Salvando monitoramento no repositório...
✅ Monitoramento salvo com sucesso
```

## Próximos Passos

1. **Testar em produção**
   - Executar o script de teste
   - Verificar logs de erro
   - Validar salvamento real

2. **Monitoramento contínuo**
   - Implementar alertas para problemas
   - Logs automáticos de correção
   - Relatórios de saúde do banco

3. **Melhorias futuras**
   - Backup automático antes de correções
   - Interface para visualizar problemas
   - Correção em lote de dados antigos

## Conclusão

Com essas correções implementadas, o sistema de monitoramento agora:

- ✅ **Corrige automaticamente** problemas de banco de dados
- ✅ **Valida todos os dados** antes de salvar
- ✅ **Aplica correções** quando possível
- ✅ **Fornece logs detalhados** para debug
- ✅ **Testa a funcionalidade** com scripts automatizados

O botão "Salvar e Finalizar" deve agora funcionar corretamente, salvando os dados de monitoramento e enviando-os para os módulos relacionados.
