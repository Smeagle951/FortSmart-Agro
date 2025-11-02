# 🔄 FLUXO DE SINCRONIZAÇÃO AUTOMÁTICA ENTRE MÓDULOS

## ✅ **SISTEMA IMPLEMENTADO E FUNCIONANDO**

### **📊 FLUXO COMPLETO DE DADOS**

```
┌─────────────────────────────────────────────┐
│ 1️⃣ USUÁRIO FAZ MONITORAMENTO               │
│    (Card Nova Ocorrência)                   │
│    - Tipo: Praga/Doença/Daninha            │
│    - Organismo: Nome                        │
│    - Severidade: 0-10                       │
│    - GPS: Lat/Lng                           │
│    - Fotos: Caminhos                        │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 2️⃣ SALVAMENTO DIRETO                       │
│    DirectOccurrenceService.saveOccurrence() │
│                                             │
│    ✅ Salva em: monitoring_occurrences      │
│    ✅ Verifica: Confirmação no banco        │
└─────────────────┬───────────────────────────┘
                  │
                  ├──────────────┬─────────────┐
                  ▼              ▼             ▼
┌──────────────────┐  ┌──────────────┐  ┌────────────────┐
│ 3️⃣ SINCRONIZAÇÃO │  │ 4️⃣ HISTÓRICO │  │ 5️⃣ IA FORTSMART│
│    AUTOMÁTICA    │  │              │  │                │
│                  │  │ monitoring_  │  │ Análise        │
│ infestation_map  │  │ sessions     │  │ Inteligente    │
│                  │  │              │  │                │
│ ✅ Ponto GPS     │  │ ✅ Contador  │  │ ✅ Catálogo    │
│ ✅ Organismo     │  │    total_    │  │ ✅ Recomenda-  │
│ ✅ Nível         │  │    ocorrencias│  │    ções        │
│ ✅ Timestamp     │  │              │  │                │
└──────────────────┘  └──────────────┘  └────────────────┘
        │                    │                   │
        ▼                    ▼                   ▼
┌──────────────────────────────────────────────────────┐
│ 6️⃣ MÓDULOS DE VISUALIZAÇÃO                          │
├──────────────────────────────────────────────────────┤
│                                                      │
│ 🗺️ MAPA DE INFESTAÇÃO                               │
│    - MapTiler Satélite                              │
│    - Polígono do Talhão (verde)                     │
│    - Heatmap Térmico (🟢🟡🟠🔴)                      │
│    - Marcadores com emojis (🐛🍃🌿🦠)               │
│                                                      │
│ 📊 RELATÓRIO AGRONÔMICO                              │
│    - Dashboard de Monitoramento                     │
│    - Galeria de Fotos (📸)                          │
│    - Níveis de Infestação                           │
│    - Dados Agronômicos                              │
│    - Condições Ambientais                           │
│    - 💊 Recomendações de Aplicação                  │
│                                                      │
│ 📜 HISTÓRICO                                         │
│    - Lista de sessões                               │
│    - Ver Relatório → Análise Completa               │
│    - Editar/Excluir                                 │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 🔧 **ARQUITETURA TÉCNICA**

### **1️⃣ SALVAMENTO (DirectOccurrenceService)**

```dart
DirectOccurrenceService.saveOccurrence(
  sessionId: "uuid",
  pointId: "uuid",
  talhaoId: "uuid",
  tipo: "Praga",
  subtipo: "Percevejo-marrom",
  nivel: "Crítico",
  percentual: 75,
  latitude: -23.5505,
  longitude: -46.6333,
  observacao: "...",
  fotoPaths: "['/path/foto1.jpg']",
);
```

**Tabela:** `monitoring_occurrences`
```sql
INSERT INTO monitoring_occurrences (
  id, point_id, session_id, talhao_id,
  tipo, subtipo, nivel, percentual,
  latitude, longitude, foto_paths,
  data_hora, created_at, updated_at
) VALUES (...)
```

---

### **2️⃣ SINCRONIZAÇÃO AUTOMÁTICA (_syncToInfestationMap)**

```dart
// EXECUTADO AUTOMATICAMENTE APÓS SALVAR
await _syncToInfestationMap(db, data, occId, sessionId, talhaoId);
```

**Tabela:** `infestation_map`
```sql
INSERT INTO infestation_map (
  id, ponto_id, talhao_id,
  latitude, longitude,
  tipo, subtipo, nivel, intensidade,
  timestamp, cultura_nome, talhao_nome
) VALUES (...)
```

---

### **3️⃣ ATUALIZAÇÃO DO HISTÓRICO**

**Tabela:** `monitoring_sessions`
```sql
UPDATE monitoring_sessions 
SET total_ocorrencias = total_ocorrencias + 1,
    updated_at = NOW()
WHERE id = ?
```

---

### **4️⃣ ANÁLISE DA IA FORTSMART**

**Automático ao abrir Relatório Agronômico:**

1. **Busca ocorrências** de `monitoring_occurrences`
2. **Busca dados do catálogo** (JSON dos organismos)
3. **Gera análise inteligente**:
   - Nível de risco
   - Organismos detectados
   - Recomendações de aplicação
   - Momento ideal de aplicação
   - Tecnologia de aplicação
   - Monitoramento pós-aplicação

---

## 🗺️ **MAPA DE INFESTAÇÃO - CAMADAS**

### **Renderizado em tempo real a partir de `infestation_map`:**

1. **🛰️ TileLayer** - MapTiler Satélite (API configurada)
2. **🟢 PolygonLayer** - Polígono do Talhão (da tabela `poligonos`)
3. **🌡️ CircleLayer** - Heatmap Térmico (raio baseado na intensidade)
4. **📍 MarkerLayer** - Pontos com emojis (🐛🍃🌿🦠)
5. **📊 Legenda** - Informações dinâmicas

---

## 📸 **GALERIA DE FOTOS**

### **Carregada de `monitoring_occurrences.foto_paths`:**

```sql
SELECT 
  subtipo as organismo,
  foto_paths,
  data_hora,
  nivel,
  percentual,
  latitude,
  longitude
FROM monitoring_occurrences
WHERE foto_paths IS NOT NULL 
  AND foto_paths != ''
  AND foto_paths != '[]'
```

**Renderizado:**
- Miniaturas 100x120px
- Nome do organismo
- Clicável para ampliar
- Se vazio: "Nenhuma foto registrada"

---

## 💊 **RECOMENDAÇÕES DE APLICAÇÃO**

### **Geradas pela IA a partir dos dados reais:**

#### **1. 🧪 Produtos Recomendados**
- Baseado nos organismos detectados
- Ex: Percevejo → Tiametoxam 250 g/L

#### **2. 💧 Dosagem e Aplicação**
- Volume de calda
- Dose conforme nível de risco
- pH ideal

#### **3. ⏰ Momento Ideal**
- Temperatura e umidade
- Horários de aplicação
- Condições climáticas

#### **4. 🚁 Tecnologia**
- Terrestre vs. Aérea
- Bicos, pressão, velocidade

#### **5. 📊 Monitoramento Pós**
- Avaliação de eficácia
- Frequência de reavaliação

---

## 🔄 **SINCRONIZAÇÃO ENTRE MÓDULOS**

### **✅ AUTOMÁTICA (Não precisa fazer nada):**

```
Monitoramento (Nova Ocorrência)
    ↓ (salva automaticamente)
monitoring_occurrences
    ↓ (sincroniza automaticamente)
infestation_map
    ↓ (atualiza automaticamente)
monitoring_sessions (total_ocorrencias++)
    ↓ (disponível imediatamente)
Mapa de Infestação (visualização)
    ↓ (disponível imediatamente)
Relatório Agronômico (análise IA)
    ↓ (disponível imediatamente)
Histórico de Monitoramento (lista)
```

---

## 🎯 **VERIFICAÇÃO DE INTEGRIDADE**

### **Sistema executa ao abrir o app:**

1. ✅ Verifica tabelas obrigatórias
2. ✅ Adiciona colunas faltantes
3. ✅ Cria tabelas ausentes:
   - `monitoring_sessions` (14 colunas)
   - `crop_varieties`
   - `plantio`
   - `historico_plantio`
   - `phenological_records`
   - `estande_plantas`
   - `talhoes`

---

## 📝 **RESPOSTA À SUA PERGUNTA:**

### **✅ SIM! O sistema:**

1. **Salva no histórico** automaticamente
   - Tabela: `monitoring_sessions`
   - Campo: `total_ocorrencias` incrementado

2. **Envia para os módulos** automaticamente:
   - ✅ **Mapa de Infestação** → `infestation_map`
   - ✅ **Relatório Agronômico** → lê de `monitoring_occurrences`
   - ✅ **Histórico** → lê de `monitoring_sessions`

3. **Não precisa fazer nada manual!**
   - Tudo acontece automaticamente via `DirectOccurrenceService`

---

**Data:** 28/10/2025  
**Versão:** 2.0  
**Sistema:** FortSmart Agro - Sincronização Automática  

