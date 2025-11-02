# ✅ DADOS DO CARD - VERSÃO SIMPLIFICADA

**Data:** ${DateTime.now().toIso8601String()}  
**Status:** ✅ SIMPLIFICADO CONFORME SOLICITADO

---

## 🎯 DADOS COMPLEMENTARES (SIMPLIFICADOS)

Conforme solicitado, o card agora carrega **apenas 4 dados complementares essenciais**:

### 1️⃣ **ESTÁGIO FENOLÓGICO**
**Exemplo:** V4, V5, R1, R3, R5

**Origem:** Submódulo "Evolução Fenológica"  
**Tabela:** `phenological_records.estagio_fenologico`

```sql
SELECT estagio_fenologico
FROM phenological_records
WHERE talhao_id = ? OR cultura_nome = ?
ORDER BY data_registro DESC
LIMIT 1
```

**Log:**
```
✅ [CARD_DATA_SVC] Estágio fenológico encontrado: V4 (do submódulo Evolução Fenológica)
```

---

### 2️⃣ **CULTURA**
**Exemplo:** SOJA, MILHO, ALGODÃO

**Origem:** Selecionada pelo usuário ao iniciar monitoramento  
**Tabela:** `monitoring_sessions.cultura_nome`

**Já estava carregada!** ✅

---

### 3️⃣ **POPULAÇÃO** (Estande)
**Exemplo:** 245000 plantas/m²

**Origem:** Submódulo "Estande de Plantas"  
**Tabela:** `estande_plantas.populacao_media`

```sql
SELECT populacao_media, data_calculo
FROM estande_plantas
WHERE talhao_id = ?
ORDER BY data_calculo DESC
LIMIT 1
```

**Log:**
```
✅ População: 245000.0 plantas/m²
```

---

### 4️⃣ **DAE** (Dias Após Emergência)
**Exemplo:** 35 dias

**Origem:** Calculado automaticamente  
**Tabela:** `historico_plantio.data_emergencia` ou `data_plantio`

```sql
SELECT data_plantio, data_emergencia
FROM historico_plantio
WHERE talhao_id = ?
ORDER BY data_plantio DESC
LIMIT 1
```

**Cálculo:**
```dart
// Se tiver data de emergência
DAE = Hoje - Data Emergência

// Se NÃO tiver, estima:
Data Emergência Estimada = Data Plantio + 7 dias
DAE = Hoje - Data Emergência Estimada
```

**Log:**
```
✅ DAE: 35 dias (Dias Após Emergência)
```

---

## 📋 TABELA RESUMO

| Dado | Fonte | Tabela | Como é Obtido |
|------|-------|--------|---------------|
| **Estágio Fenológico** | Submódulo "Evolução Fenológica" | `phenological_records` | Query direta |
| **Cultura** | Sessão de monitoramento | `monitoring_sessions` | Já carregado |
| **População** | Submódulo "Estande" | `estande_plantas` | Query direta |
| **DAE** | Histórico de plantio | `historico_plantio` | Calculado |

---

## 🔍 EXEMPLO NO CARD

```
┌────────────────────────────────────┐
│ 🌾 TALHÃO A - SOJA                │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                    │
│ 📊 DADOS COMPLEMENTARES            │
│  🌱 Estágio: V4                   │
│  🌾 Cultura: SOJA                 │
│  📏 População: 245.000 plantas/m² │
│  📅 DAE: 35 dias                  │
│                                    │
│ 📈 MÉTRICAS                        │
│  📍 Pontos: 5                     │
│  🐛 Ocorrências: 12               │
│  ⚠️ Total Pragas: 35              │
│  📊 Severidade: 45.2%             │
│  🎯 Risco: ALTO                   │
└────────────────────────────────────┘
```

---

## 📊 LOGS ESPERADOS

Ao carregar o card, você verá:

```
🔍 [CARD_DATA_SVC] Carregando dados do card para sessão: session-123
✅ [CARD_DATA_SVC] 5 ocorrências encontradas

✅ [CARD_DATA_SVC] Estágio fenológico encontrado: V4 (do submódulo Evolução Fenológica)

🔍 [CARD_DATA_SVC] Buscando dados complementares simplificados...
   ✅ População: 245000.0 plantas/m²
   ✅ DAE: 35 dias (Dias Após Emergência)
✅ [CARD_DATA_SVC] Dados complementares simplificados carregados!

🧮 [CARD_DATA_SVC] Processando 5 ocorrências com cálculos dos JSONs...
   📋 Cultura: SOJA
   🌱 Estágio fenológico: V4
   ⭐ Usando REGRA CUSTOMIZADA do usuário para Lagarta-do-cartucho
   ✅ Lagarta-do-cartucho: 15.0 → ALTO (threshold usado: custom)
✅ [CARD_DATA_SVC] 1 organismos processados com cálculos dos JSONs!

📊 [CARD_DATA_SVC] Métricas calculadas:
   • Total pragas: 35
   • Quantidade média: 11.67
   • Severidade média: 45.20%
   • Nível de risco: ALTO

✅ [CARD_DATA_SVC] Card data carregado com sucesso!
   • Talhão: Talhão A
   • Cultura: SOJA
   • Pontos: 5
   • Ocorrências: 5
   • Nível de Risco: ALTO
   • Confiança: 95%
```

---

## ❌ DADOS REMOVIDOS (Conforme Solicitado)

| Dado Removido | Motivo |
|---------------|--------|
| CV% | Simplificação |
| Tipo de Manejo | Simplificação |
| Histórico Resumido | Simplificação |
| Impacto Econômico | Simplificação |
| Dados do Talhão (área, variedade, etc.) | Simplificação |

---

## ✅ RESUMO FINAL

### **DADOS AGORA NO CARD:**

**Básicos:**
- ✅ Talhão Nome
- ✅ Cultura ← **Solicitado**
- ✅ Status (Ativo/Pausado/Finalizado)
- ✅ Datas (início/fim)

**Monitoramento:**
- ✅ Total Pontos
- ✅ Total Ocorrências
- ✅ Total Pragas
- ✅ Quantidade Média
- ✅ Severidade Média
- ✅ Nível de Risco
- ✅ Total Fotos

**Ambientais:**
- ✅ Temperatura (real do NewOccurrenceCard)
- ✅ Umidade (real do NewOccurrenceCard)

**Complementares (SIMPLIFICADOS):**
- ✅ Estágio Fenológico ← **Solicitado** (ex: V4, V5)
- ✅ População ← **Solicitado** (plantas/m²)
- ✅ DAE ← **Solicitado** (Dias Após Emergência)

**Organismos:**
- ✅ Lista de organismos detectados
- ✅ Frequência por organismo
- ✅ Quantidade por organismo
- ✅ Severidade por organismo
- ✅ Nível de risco por organismo (com JSONs + Regras)

**Recomendações:**
- ✅ Recomendações agronômicas contextualizadas
- ✅ Alertas baseados no nível de risco

---

## 🎉 CONCLUSÃO

✅ **Estágio Fenológico** - Carregado do submódulo (V4, V5, R1, etc.)  
✅ **Cultura** - Já estava carregado (SOJA, MILHO, etc.)  
✅ **População** - Carregado do submódulo Estande  
✅ **DAE** - Calculado automaticamente  

**TODOS os dados são REAIS do banco, NENHUM é exemplo!** 🌾✅

