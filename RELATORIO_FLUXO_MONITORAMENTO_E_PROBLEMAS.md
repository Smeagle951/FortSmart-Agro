# 📊 RELATÓRIO COMPLETO: FLUXO DE MONITORAMENTO E PROBLEMAS IDENTIFICADOS

**Data:** ${DateTime.now().toIso8601String()}  
**Objetivo:** Documentar o fluxo completo do módulo de monitoramento até o relatório agronômico, identificar problemas de conectividade/importação e propor solução para refazer o card de monitoramento.

---

## 🗺️ FLUXO COMPLETO DE DADOS

### 1️⃣ **MÓDULO DE MONITORAMENTO - CAPTURA DE DADOS**

#### 1.1. Início da Sessão de Monitoramento
**Arquivo:** `lib/services/monitoring_session_service.dart`

- Cria uma **sessão de monitoramento** na tabela `monitoring_sessions`
- Campos principais:
  - `id` (UUID único)
  - `talhao_id` / `talhao_nome`
  - `cultura_id` / `cultura_nome`
  - `status` ('active', 'pausado', 'finalized')
  - `started_at` / `finished_at`
  - `temperatura` / `umidade` (atualizados durante o monitoramento)

#### 1.2. Captura de Dados no Campo
**Arquivo:** `lib/screens/monitoring/point_monitoring_screen.dart`

Quando o usuário está monitorando um ponto:
- Obtém coordenadas GPS (`latitude`, `longitude`)
- Abre o **`NewOccurrenceCard`** para inserir ocorrências

#### 1.3. Card de Nova Ocorrência (`NewOccurrenceCard`)
**Arquivo:** `lib/widgets/new_occurrence_card.dart`

**DADOS CAPTURADOS:**
1. **Tipo de Ocorrência:** Praga, Doença, Daninha, Sem Infestação
2. **Organismo:** Nome específico (ex: "Lagarta-do-cartucho")
3. **Quantidade de Pragas:** Campo numérico (`_quantidadePragas`) ⚠️ **CAMPO CRÍTICO**
4. **Severidade Visual:** Slider de 0-10
5. **Temperatura:** Valor numérico (`temperature`)
6. **Umidade:** Valor numérico (`humidity`)
7. **Fotos:** Lista de paths (`List<String> fotoPaths`)
8. **Observação:** Texto livre
9. **Dados Complementares (se disponíveis):**
   - `tipo_manejo_anterior`
   - `historico_resumo`
   - `impacto_economico_previsto`

#### 1.4. Salvamento no Banco de Dados
**Arquivo:** `lib/services/direct_occurrence_service.dart`

**Fluxo de Salvamento:**

```
NewOccurrenceCard → point_monitoring_screen.dart → DirectOccurrenceService.saveOccurrence()
```

**Tabelas Afetadas:**

##### **A) `monitoring_occurrences` (PRINCIPAL)**
```sql
INSERT INTO monitoring_occurrences (
  id,                    -- UUID único
  point_id,              -- ID do ponto GPS
  session_id,            -- ID da sessão de monitoramento
  talhao_id,            -- ID do talhão
  organism_id,          -- ID do organismo (nome)
  organism_name,        -- Nome do organismo
  tipo,                 -- 'praga', 'doença', 'daninha'
  subtipo,              -- Nome específico
  nivel,                -- 'baixo', 'médio', 'alto', 'crítico'
  percentual,           -- Percentual de infestação (0-100)
  quantidade,           -- ✅ QUANTIDADE REAL DE PRAGAS
  agronomic_severity,   -- ✅ SEVERIDADE AGRONÔMICA CALCULADA
  foto_paths,           -- JSON array de paths
  temperatura,          -- Temperatura (atualizado na sessão)
  umidade,              -- Umidade (atualizado na sessão)
  observacao,           -- Texto completo (inclui manejo/histórico/impacto)
  latitude,
  longitude,
  data_hora,
  created_at,
  updated_at
)
```

##### **B) `monitoring_points`**
```sql
INSERT/UPDATE monitoring_points (
  id,                   -- ID do ponto
  session_id,           -- Sessão de monitoramento
  numero,               -- Número sequencial do ponto
  latitude,
  longitude,
  timestamp,
  manual_entry,         -- 1 se monitoramento livre
  created_at,
  updated_at
)
```

##### **C) `monitoring_sessions` (ATUALIZAÇÃO)**
```sql
UPDATE monitoring_sessions SET
  temperatura = ?,      -- ✅ Atualizado do NewOccurrenceCard
  umidade = ?,          -- ✅ Atualizado do NewOccurrenceCard
  total_ocorrencias = (SELECT COUNT(*) FROM monitoring_occurrences WHERE session_id = ?),
  updated_at = ?
WHERE id = ?
```

##### **D) `infestation_map` (SINCRONIZAÇÃO)**
- O `DirectOccurrenceService` também sincroniza para `infestation_map` para manter o mapa atualizado

---

### 2️⃣ **MÓDULO DE RELATÓRIO AGRONÔMICO - LEITURA DE DADOS**

#### 2.1. Dashboard de Monitoramento
**Arquivo:** `lib/screens/reports/monitoring_dashboard.dart`

**Fluxo de Carregamento:**

```
MonitoringDashboard.initState() 
  → _loadMonitoringsData()
    → MonitoringInfestationIntegrationService.getAllMonitorings()
      → Conversão para modelo Monitoring
        → Exibição em cards de talhão
```

#### 2.2. Cards de Talhão (`TalhaoCard`)
**Localização:** `lib/widgets/talhao_card_widget.dart`

**DADOS EXIBIDOS:**
- Nome do talhão
- Cultura
- Número de pontos monitorados
- Área afetada (%)
- Nível de risco (Baixo/Médio/Alto/Crítico)
- Status (Ativo/Pausado/Finalizado)

**Cálculo do Risco:**
```dart
_calcularNivelRisco(totalOccurrences, occurrences: allOccurrences)
```
- ✅ **CORRIGIDO:** Usa `agronomic_severity` das ocorrências (média)
- ❌ **ANTES:** Usava apenas contagem de organismos

#### 2.3. Botão "Ver Análise Detalhada"
**Método:** `_showAnaliseDetalhada(sessionIdFilter, talhaoIdFilter)`

**Fluxo:**
1. Busca dados da sessão de monitoramento (`monitoring_sessions`)
2. Busca ocorrências filtradas (`monitoring_occurrences`)
3. Busca pontos de monitoramento (`monitoring_points`)
4. Processa organismos e calcula métricas:
   - Frequência
   - Quantidade Média
   - Índice
   - Severidade
   - Máxima
5. Gera análise inteligente via `_gerarAnaliseRealPorSessao()`
6. Exibe em modal com dados completos

#### 2.4. Card "Sistema FortSmart Agro"
**Localização:** Dentro de `MonitoringDashboard.build()`

**DADOS EXIBIDOS:**
- Total de monitoramentos
- Total de pontos GPS
- Total de ocorrências
- Nível de risco geral
- Organismos detectados
- Recomendações

**PROBLEMA IDENTIFICADO:** 
- ❌ Muitas vezes mostra zeros mesmo com dados no banco
- ❌ Não filtra corretamente por sessão/talhão
- ❌ Dados misturados de diferentes talhões

---

## ⚠️ PROBLEMAS IDENTIFICADOS

### 🔴 PROBLEMA 1: DIVISÃO POR ZERO EM CÁLCULOS
**Localização:** `lib/screens/reports/monitoring_dashboard.dart` - `_processOccurrencesData()`

**Causa:**
```dart
var totalPontosMonitorados = (totalPontosResult.first['total'] as num?)?.toInt() ?? 0;
if (totalPontosMonitorados == 0) {
  // ❌ Divisão por zero ao calcular frequência, índice, etc.
}
```

**Status:** ✅ **CORRIGIDO** (com fallback para pontos únicos das ocorrências)

---

### 🔴 PROBLEMA 2: VALORES ZERADOS (QUANTIDADE/SEVERIDADE)
**Localização:** `monitoring_dashboard.dart` - `_processOccurrencesData()`

**Causa Raiz:**
- Dados antigos salvos sem o campo `quantidade`
- O `NewOccurrenceCard` não tinha campo dedicado para quantidade
- O sistema usava `percentual` ou `severity` visual incorretamente

**Status:** ✅ **PARCIALMENTE CORRIGIDO**
- Campo `quantidade` adicionado ao `NewOccurrenceCard`
- Logs detalhados adicionados para diagnóstico
- ⚠️ **PENDENTE:** Dados antigos ainda podem ter zeros

---

### 🔴 PROBLEMA 3: MISTURA DE DADOS ENTRE TALHÕES
**Localização:** `monitoring_dashboard.dart` - `_showMonitoringDetails()`

**Causa:**
- Quando clica no card do talhão, não filtra corretamente por `session_id`
- Busca todas as ocorrências do talhão, não apenas da sessão específica
- Resultado: dados de diferentes sessões misturados

**Status:** ✅ **CORRIGIDO**
- Agora busca `session_id` específico do banco antes de exibir análise
- Filtra por `talhao_id` + `cultura_nome` para garantir sessão correta

---

### 🔴 PROBLEMA 4: TEMPERATURA/UMIDADE FICTÍCIAS
**Localização:** `monitoring_dashboard.dart` - `_carregarDadosCompletos()`

**Causa:**
- Sistema usava valores fixos (25°C/60%) como fallback
- Não buscava dados reais de `monitoring_sessions.temperatura/umidade`

**Status:** ✅ **CORRIGIDO**
- Agora busca diretamente de `monitoring_sessions`
- Validação para não usar valores zero ou nulos

---

### 🔴 PROBLEMA 5: DADOS DE PLANTIO FALTANTES
**Causa:**
- Manejo anterior, histórico e impacto econômico não eram salvos
- Eram apenas exibidos no card, mas não persistidos

**Status:** ✅ **CORRIGIDO**
- Dados agora concatenados em `observacao` antes de salvar
- Exibidos no relatório via `observacao`

---

### 🔴 PROBLEMA 6: IMAGENS NÃO CARREGANDO
**Localização:** `monitoring_dashboard.dart` - `_carregarImagensInfestacao()`

**Causa:**
- SQL buscava colunas inexistentes (`imagePaths`, `photo_paths`, `image_paths`)
- Apenas `foto_paths` existe na tabela `monitoring_occurrences`

**Status:** ✅ **CORRIGIDO**
- Query simplificada para usar apenas `foto_paths`
- Removidos fallbacks incorretos

---

### 🔴 PROBLEMA 7: INCONSISTÊNCIA DE RISCO (Crítico vs Baixo/Médio)
**Causa:**
- Cálculo de risco na lista de monitoramentos usava critério diferente do cálculo na análise detalhada
- Lista: contagem de organismos
- Detalhada: severidade agronômica média

**Status:** ✅ **CORRIGIDO**
- Ambos agora usam `agronomic_severity` média

---

### 🔴 PROBLEMA 8: RECOMENDAÇÕES INCORRETAS/MISTURADAS
**Localização:** `lib/services/organism_recommendations_service.dart`

**Causa:**
- Nome do organismo no banco não correspondia ao nome no JSON do catálogo
- Ex: "Lagarta-do-cartucho" no banco vs "Lagarta Spodoptera" no JSON

**Status:** ✅ **CORRIGIDO**
- Implementado mapeamento de nomes (`_mapearNomeOrganismo`)
- Fallback para busca parcial

---

### 🔴 PROBLEMA 9: CARD "ORGANISMOS DETECTADOS" COM VALORES ZERO
**Localização:** `advanced_analytics_dashboard.dart` - `_loadRealInfestationData()`

**Causa:**
- `totalPontosMapeados = 0` causava divisão por zero
- Ocorrências com `quantidade = 0` ou `agronomic_severity = 0`

**Status:** ✅ **CORRIGIDO** (similar ao Problema 1)

---

### 🔴 PROBLEMA 10: DOIS CAMINHOS DIFERENTES PARA ANÁLISE DETALHADA
**Localização:** `monitoring_dashboard.dart`

**Caminho 1:** Botão azul "Ver Análise Detalhada"
- ✅ Funciona corretamente
- ✅ Filtra por sessão/talhão

**Caminho 2:** Clique no card do talhão
- ❌ **ANTES:** Dados incorretos/faltantes
- ✅ **AGORA:** Corrigido (mesmo código do caminho 1)

**Status:** ✅ **CORRIGIDO**

---

## 📋 TABELAS DO BANCO DE DADOS RELEVANTES

### `monitoring_sessions`
```sql
CREATE TABLE monitoring_sessions (
  id TEXT PRIMARY KEY,
  talhao_id TEXT,
  talhao_nome TEXT,
  cultura_id TEXT,
  cultura_nome TEXT,
  status TEXT,              -- 'active', 'pausado', 'finalized'
  started_at TEXT,
  finished_at TEXT,
  temperatura REAL,         -- ✅ Atualizado do NewOccurrenceCard
  umidade REAL,             -- ✅ Atualizado do NewOccurrenceCard
  total_pontos INTEGER,
  total_ocorrencias INTEGER,
  created_at TEXT,
  updated_at TEXT
);
```

### `monitoring_points`
```sql
CREATE TABLE monitoring_points (
  id TEXT PRIMARY KEY,
  session_id TEXT,
  numero INTEGER,
  latitude REAL,
  longitude REAL,
  timestamp TEXT,
  manual_entry INTEGER,     -- 1 = monitoramento livre
  sync_state TEXT,
  created_at TEXT,
  updated_at TEXT
);
```

### `monitoring_occurrences`
```sql
CREATE TABLE monitoring_occurrences (
  id TEXT PRIMARY KEY,
  point_id TEXT,
  session_id TEXT,
  talhao_id TEXT,
  organism_id TEXT,
  organism_name TEXT,
  tipo TEXT,                -- 'praga', 'doença', 'daninha'
  subtipo TEXT,
  nivel TEXT,               -- 'baixo', 'médio', 'alto', 'crítico'
  percentual INTEGER,       -- 0-100
  quantidade INTEGER,      -- ✅ QUANTIDADE REAL DE PRAGAS
  agronomic_severity REAL, -- ✅ SEVERIDADE AGRONÔMICA
  terco_planta TEXT,
  observacao TEXT,         -- ✅ Inclui manejo/histórico/impacto
  foto_paths TEXT,         -- JSON array
  latitude REAL,
  longitude REAL,
  data_hora TEXT,
  sincronizado INTEGER,
  created_at TEXT,
  updated_at TEXT
);
```

---

## 🎯 PROPOSTA: REFATORAÇÃO DO CARD DE MONITORAMENTO

### OBJETIVOS
1. ✅ Remover problemas de conectividade/importação
2. ✅ Garantir dados sempre corretos do banco
3. ✅ Interface limpa e funcional
4. ✅ Performance otimizada

### ARQUITETURA PROPOSTA

#### **NOVO SERVIÇO: `MonitoringCardDataService`**
```dart
class MonitoringCardDataService {
  /// Carrega dados consolidados para o card
  Future<MonitoringCardData> loadCardData({
    String? sessionId,
    String? talhaoId,
  }) async {
    // 1. Buscar sessão(ões)
    // 2. Buscar ocorrências (FILTRADAS)
    // 3. Buscar pontos (FILTRADOS)
    // 4. Calcular métricas (com fallbacks seguros)
    // 5. Retornar objeto consolidado
  }
}
```

#### **NOVO MODELO: `MonitoringCardData`**
```dart
class MonitoringCardData {
  final String sessionId;
  final String talhaoNome;
  final String culturaNome;
  final int totalPontos;
  final int totalOcorrencias;
  final double temperatura;
  final double umidade;
  final String nivelRisco;
  final List<OrganismSummary> organismos;
  final List<String> recomendacoes;
  final int totalFotos;
  // ... outros campos
}
```

#### **NOVO WIDGET: `CleanMonitoringCard`**
```dart
class CleanMonitoringCard extends StatelessWidget {
  final MonitoringCardData data;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),
          _buildMetrics(),
          _buildOrganisms(),
          _buildActions(),
        ],
      ),
    );
  }
}
```

### VANTAGENS DA REFATORAÇÃO

1. **✅ Dados Sempre Corretos**
   - Uma única fonte de verdade (`MonitoringCardDataService`)
   - Validação de dados antes de exibir
   - Fallbacks seguros (nunca divisão por zero)

2. **✅ Performance**
   - Cache de dados quando apropriado
   - Queries otimizadas (sem duplicação)
   - Lazy loading de dados pesados (imagens)

3. **✅ Manutenibilidade**
   - Código limpo e separado por responsabilidade
   - Fácil de testar
   - Fácil de estender

4. **✅ Experiência do Usuário**
   - Interface clara e informativa
   - Loading states apropriados
   - Tratamento de erros elegante

---

## 📝 CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1: Preparação
- [ ] Criar `MonitoringCardDataService`
- [ ] Criar modelo `MonitoringCardData`
- [ ] Criar modelo `OrganismSummary`
- [ ] Adicionar testes unitários para o serviço

### Fase 2: Widget
- [ ] Criar `CleanMonitoringCard` widget
- [ ] Implementar `_buildHeader()`
- [ ] Implementar `_buildMetrics()`
- [ ] Implementar `_buildOrganisms()`
- [ ] Implementar `_buildActions()`
- [ ] Adicionar animações/transições

### Fase 3: Integração
- [ ] Substituir card antigo no `MonitoringDashboard`
- [ ] Atualizar `_showAnaliseDetalhada()` para usar novo serviço
- [ ] Testar com dados reais
- [ ] Validar cálculos de métricas

### Fase 4: Limpeza
- [ ] Remover código antigo não utilizado
- [ ] Remover logs de debug excessivos
- [ ] Documentar novo fluxo

---

## 🔍 QUERIES SQL RECOMENDADAS

### Query Principal do Card (Filtrada)
```sql
-- Ocorrências da sessão/talhão
SELECT 
  mo.*,
  mp.latitude,
  mp.longitude,
  mp.numero as ponto_numero,
  ms.talhao_nome,
  ms.cultura_nome,
  ms.temperatura,
  ms.umidade
FROM monitoring_occurrences mo
INNER JOIN monitoring_points mp ON mp.id = mo.point_id
INNER JOIN monitoring_sessions ms ON ms.id = mo.session_id
WHERE 
  (?1 IS NULL OR mo.session_id = ?1)
  AND (?2 IS NULL OR mo.talhao_id = ?2)
ORDER BY mo.data_hora DESC;
```

### Query de Métricas
```sql
-- Total de pontos (com fallback)
SELECT 
  COUNT(DISTINCT mp.id) as total_pontos,
  COUNT(DISTINCT mo.id) as total_ocorrencias,
  COUNT(DISTINCT mo.organism_name) as total_organismos,
  SUM(mo.quantidade) as quantidade_total,
  AVG(mo.agronomic_severity) as severidade_media
FROM monitoring_occurrences mo
INNER JOIN monitoring_points mp ON mp.id = mo.point_id
WHERE 
  (?1 IS NULL OR mo.session_id = ?1)
  AND (?2 IS NULL OR mo.talhao_id = ?2);
```

---

## 📊 DIAGRAMA DE FLUXO

```
┌─────────────────────────────────────────────────────────┐
│  MÓDULO MONITORAMENTO                                    │
│                                                          │
│  1. NewOccurrenceCard                                    │
│     ↓                                                    │
│  2. point_monitoring_screen.dart                         │
│     ↓                                                    │
│  3. DirectOccurrenceService.saveOccurrence()            │
│     ↓                                                    │
│  4. Banco de Dados:                                      │
│     - monitoring_occurrences                            │
│     - monitoring_points                                  │
│     - monitoring_sessions (UPDATE temperatura/umidade)  │
│     - infestation_map (sync)                            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  MÓDULO RELATÓRIO AGRONÔMICO                            │
│                                                          │
│  1. MonitoringDashboard                                  │
│     ↓                                                    │
│  2. MonitoringCardDataService.loadCardData()            │
│     ↓                                                    │
│  3. Queries SQL (filtradas)                              │
│     ↓                                                    │
│  4. Processamento de dados                              │
│     ↓                                                    │
│  5. CleanMonitoringCard                                  │
│     ↓                                                    │
│  6. Exibição para usuário                               │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ CONCLUSÃO

O fluxo atual **funciona**, mas tem **múltiplos pontos de falha** que causam:
- Dados zerados
- Mistura de dados entre talhões
- Valores fictícios
- Performance ruim

A **refatoração proposta** resolve todos esses problemas ao:
1. Centralizar o acesso aos dados
2. Validar dados antes de exibir
3. Usar fallbacks seguros
4. Manter código limpo e testável

**PRÓXIMOS PASSOS:** Implementar a refatoração conforme o checklist acima.

