# 🎨 DESIGN FINAL: CARD DE MONITORAMENTO ELEGANTE

**Data:** ${DateTime.now().toIso8601String()}  
**Status:** ✅ COMPLETO COM RECOMENDAÇÕES DOS JSONs

---

## 📱 PREVIEW DO CARD COMPLETO

```
┌─────────────────────────────────────────────────────────┐
│ ╔═══════════════════════════════════════════════════╗ │
│ ║  🌾 CABEÇALHO COM GRADIENTE VERDE                 ║ │
│ ║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ║ │
│ ║  🏞️  TALHÃO A                                     ║ │
│ ║  🌱  SOJA - Não informada                         ║ │
│ ║                                     🟢 Ativo      ║ │
│ ║  ┌────────────────────────────────────────────┐  ║ │
│ ║  │ ⚠️ NÍVEL DE RISCO: ALTO       Confiança: 95%│  ║ │
│ ║  └────────────────────────────────────────────┘  ║ │
│ ╚═══════════════════════════════════════════════════╝ │
├─────────────────────────────────────────────────────────┤
│ 📊 MÉTRICAS DO MONITORAMENTO                           │
│ ┌─────────┬─────────┬─────────┐                        │
│ │📍Pontos │🐛Ocorr. │⚠️Pragas │                        │
│ │   5     │   12    │   35    │                        │
│ ├─────────┼─────────┼─────────┤                        │
│ │📈Qtd Méd│📊Sever. │📸Fotos  │                        │
│ │  11.67  │  45%    │   8     │                        │
│ └─────────┴─────────┴─────────┘                        │
├─────────────────────────────────────────────────────────┤
│ 🌱 DADOS DO PLANTIO                                    │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 🧠 Estágio: V4  🌾 População: 245k/m²  📅 DAE: 35│   │
│ └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│ 🌡️ CONDIÇÕES CLIMÁTICAS                               │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 🌡️ 28.5°C                💧 65%                 │   │
│ └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│ 🐛 ORGANISMOS DETECTADOS                               │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 🐛 Lagarta-do-cartucho                          │   │
│ │    📍 3/5 pontos • 60%                   ALTO   │   │
│ │    Severidade: 52%                              │   │
│ └─────────────────────────────────────────────────┘   │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 🦗 Percevejo-barriga-verde                      │   │
│ │    📍 2/5 pontos • 40%                   MÉDIO  │   │
│ │    Severidade: 38%                              │   │
│ └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│ 💡 RECOMENDAÇÕES AGRONÔMICAS                     (15)  │
│ ┌─────────────────────────────────────────────────┐   │
│ │ ⚠️ Programar aplicação nos próximos 3-5 dias    │   │
│ │ 📊 Monitorar evolução diária da infestação      │   │
│ │                                                 │   │
│ │ ═══ LAGARTA-DO-CARTUCHO (ALTO) ═══              │   │
│ │                                                 │   │
│ │ 🧪 Controle Químico:                            │   │
│ │   • Clorantraniliprole 200 SC: 40-60 ml/ha     │   │
│ │   • Flubendiamide 480 SC: 25-35 ml/ha          │   │
│ │                                                 │   │
│ │ 🦠 Controle Biológico:                          │   │
│ │   • Bacillus thuringiensis: 500g/ha            │   │
│ │   • Baculovírus: 50 LE/ha                      │   │
│ │                                                 │   │
│ │ 🌾 Práticas Culturais:                          │   │
│ │   • Eliminação de plantas hospedeiras          │   │
│ │   • Rotação de culturas                        │   │
│ │                                                 │   │
│ │ 📋 Observações de Manejo:                       │   │
│ │   • Aplicar no final da tarde                  │   │
│ │   • Volume de calda: 150-200 L/ha              │   │
│ │   • Tecnologia: Bicos de jato plano            │   │
│ │                                                 │   │
│ │ 🎯 FOCO PRIORITÁRIO: Lagarta-do-cartucho        │   │
│ └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│ 📅 01/11/2025                  [Ver Detalhes →]        │
└─────────────────────────────────────────────────────────┘
```

---

## 🎨 SEÇÕES DO CARD

### 1️⃣ **CABEÇALHO** (com gradiente verde)
```dart
✅ Talhão Nome
✅ Cultura + Ícone
✅ Badge de Status (Ativo/Pausado/Finalizado)
✅ Nível de Risco (com cor e ícone)
✅ Score de Confiança (0-100%)
```

**Cores:**
- Fundo: Gradiente #2E7D32 → #1B5E20
- Texto: Branco
- Badge risco: Cor semântica (vermelho/laranja/amarelo/verde)

---

### 2️⃣ **GRID DE MÉTRICAS** (3x2)
```dart
┌─────────┬─────────┬─────────┐
│📍Pontos │🐛Ocorr. │⚠️Pragas │
│   5     │   12    │   35    │
├─────────┼─────────┼─────────┤
│📈Qtd Méd│📊Sever. │📸Fotos  │
│  11.67  │  45%    │   8     │
└─────────┴─────────┴─────────┘
```

**Estilo:**
- Cards individuais com borda e fundo colorido
- Ícone + Valor grande + Label pequena
- Cores específicas por métrica

---

### 3️⃣ **DADOS DO PLANTIO** (NOVO!)
```dart
┌─────────────────────────────────────┐
│ 🌱 Dados do Plantio                │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ [🧠 V4] [🌾 245k/m²] [📅 35 dias]  │
└─────────────────────────────────────┘
```

**Chips elegantes:**
- Estágio Fenológico (roxo)
- População (verde)
- DAE (laranja)

---

### 4️⃣ **CONDIÇÕES CLIMÁTICAS**
```dart
┌─────────────────────────────────────┐
│ 🌡️ Condições Climáticas            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ 🌡️ 28.5°C          💧 65%          │
└─────────────────────────────────────┘
```

**Estilo:**
- Gradiente azul claro
- Ícones temáticos (sol, gota)
- Valores em destaque

---

### 5️⃣ **ORGANISMOS DETECTADOS**
```dart
┌─────────────────────────────────────┐
│ 🐛 Lagarta-do-cartucho             │
│    📍 3/5 pontos • 60%      [ALTO] │
│    Severidade: 52%                 │
└─────────────────────────────────────┘
```

**Estilo:**
- Card por organismo
- Cor de fundo baseada no risco
- Badge de nível (BAIXO/MÉDIO/ALTO/CRÍTICO)
- Ícone de praga

---

### 6️⃣ **RECOMENDAÇÕES AGRONÔMICAS** (COMPLETAS!)
```dart
┌─────────────────────────────────────┐
│ 💡 Recomendações Agronômicas   (15)│
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│ ⚠️ Programar aplicação 3-5 dias     │
│ 📊 Monitorar evolução diária        │
│                                     │
│ ═══ LAGARTA-DO-CARTUCHO (ALTO) ═══  │
│                                     │
│ 🧪 Controle Químico:                │
│   • Clorantraniliprole: 40-60ml/ha │
│   • Flubendiamide: 25-35ml/ha      │
│                                     │
│ 🦠 Controle Biológico:              │
│   • Bacillus thuringiensis: 500g/ha│
│                                     │
│ 🌾 Práticas Culturais:              │
│   • Eliminar plantas hospedeiras   │
│   • Rotação de culturas            │
│                                     │
│ 📋 Observações de Manejo:           │
│   • Aplicar no final da tarde      │
│   • Volume calda: 150-200 L/ha     │
│                                     │
│ 🎯 FOCO: Lagarta-do-cartucho        │
└─────────────────────────────────────┘
```

**Estilo:**
- Gradiente azul/índigo no fundo
- Badge com total de recomendações
- Separadores para cada organismo
- Ícones contextualizados (🧪🦠🌾📋)
- Cores diferentes por categoria

---

### 7️⃣ **ALERTAS** (se houver)
```dart
┌─────────────────────────────────────┐
│ ⚠️ Alertas                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ ⚠️ Lagarta: alta frequência (60%)   │
│ ⚠️ Lagarta: severidade crítica (52%)│
└─────────────────────────────────────┘
```

**Estilo:**
- Fundo laranja claro
- Borda laranja
- Ícones de warning

---

### 8️⃣ **RODAPÉ**
```dart
┌─────────────────────────────────────┐
│ 📅 01/11/2025    [Ver Detalhes →]  │
└─────────────────────────────────────┘
```

**Estilo:**
- Fundo cinza claro
- Data formatada
- Botão de ação

---

## 🎨 PALETA DE CORES UTILIZADA

### Cores Principais
```dart
Verde FortSmart: #2E7D32
Verde Escuro: #1B5E20
Azul Recomendações: #1565C0
```

### Cores de Risco
```dart
Baixo:    #388E3C (Verde)
Médio:    #FBC02D (Amarelo)
Alto:     #F57C00 (Laranja)
Crítico:  #D32F2F (Vermelho)
```

### Cores de Categoria
```dart
Químico:   #9C27B0 (Roxo)
Biológico: #4CAF50 (Verde)
Cultural:  #795548 (Marrom)
Manejo:    #FF9800 (Laranja)
```

---

## 📊 DADOS EXIBIDOS

### ✅ DADOS BÁSICOS
- Talhão Nome
- Cultura
- Status (Ativo/Pausado/Finalizado)
- Data Início/Fim

### ✅ MÉTRICAS DE MONITORAMENTO
- Total Pontos GPS
- Total Ocorrências
- Total Pragas (quantidade real)
- Quantidade Média (MIP)
- Severidade Média (%)
- Total Fotos
- Score de Confiança (%)

### ✅ DADOS DO PLANTIO (NOVO!)
- **Estágio Fenológico** (V4, V5, R1, etc.) - Do submódulo
- **População** (plantas/m²) - Do submódulo Estande
- **DAE** (Dias Após Emergência) - Calculado

### ✅ DADOS AMBIENTAIS
- Temperatura (°C) - Real do NewOccurrenceCard
- Umidade (%) - Real do NewOccurrenceCard

### ✅ ORGANISMOS DETECTADOS
Por organismo:
- Nome
- Pontos afetados / Total pontos
- Frequência (%)
- Severidade média (%)
- Nível de risco individual

### ✅ RECOMENDAÇÕES COMPLETAS (NOVO!)

#### Gerais (baseadas em risco):
- Prazo de ação
- Tipo de monitoramento

#### Específicas dos JSONs (por organismo):
- 🧪 **Controle Químico** (produtos + dosagem)
- 🦠 **Controle Biológico** (produtos + dosagem)
- 🌾 **Práticas Culturais** (ações no campo)
- 📋 **Observações de Manejo** (horário, volume, tecnologia)

### ✅ ALERTAS
- Frequência alta
- Severidade crítica
- Ação urgente necessária

---

## 🔄 ORIGEM DOS DADOS

| Seção | Dados | Origem |
|-------|-------|--------|
| **Cabeçalho** | Talhão, Cultura, Status | `monitoring_sessions` |
| **Métricas** | Pontos, Ocorrências, Pragas | `monitoring_occurrences` + cálculos |
| **Plantio** | Estágio | `phenological_records` |
| **Plantio** | População | `estande_plantas` |
| **Plantio** | DAE | `historico_plantio` (calculado) |
| **Ambiental** | Temperatura, Umidade | `monitoring_sessions` (do NewOccurrenceCard) |
| **Organismos** | Lista, Métricas | `monitoring_occurrences` + processamento |
| **Recomendações** | Gerais | Lógica baseada em risco |
| **Recomendações** | Específicas | JSONs (`organismos_*.json`) |
| **Alertas** | Baseados em thresholds | Cálculos + regras |

---

## 🧪 INTEGRAÇÃO COM SISTEMAS EXISTENTES

### ✅ SISTEMAS INTEGRADOS

1. **PhenologicalInfestationService**
   - Cálculos de nível de infestação
   - Thresholds dos JSONs por estágio
   - Prioriza regras customizadas

2. **OrganismRecommendationsService** (NOVO!)
   - Carrega recomendações dos JSONs
   - Produtos químicos + biológicos
   - Práticas culturais
   - Observações de manejo

3. **DirectOccurrenceService**
   - Salva dados do NewOccurrenceCard
   - Atualiza temperatura/umidade
   - Sincroniza para infestation_map

4. **Submódulos de Plantio**
   - Evolução Fenológica → Estágio
   - Estande de Plantas → População
   - Histórico de Plantio → DAE

---

## 📋 EXEMPLO DE LOGS

```
🔍 [CARD_DATA_SVC] Carregando dados do card para sessão: session-abc123
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

🧪 [CARD_DATA_SVC] Buscando recomendações dos JSONs para 1 organismo(s)...
   ✅ Recomendações encontradas para Lagarta-do-cartucho
✅ [CARD_DATA_SVC] 15 recomendações geradas (gerais + JSONs)!

✅ [CARD_DATA_SVC] Card data carregado com sucesso!
   • Talhão: Talhão A
   • Cultura: SOJA
   • Pontos: 5
   • Ocorrências: 5
   • Nível de Risco: ALTO
   • Confiança: 95%
```

---

## ✅ CHECKLIST DE CONCLUSÃO

### Arquitetura
- [x] MonitoringCardDataService criado
- [x] MonitoringCardData modelo completo
- [x] OrganismSummary modelo criado
- [x] CleanMonitoringCard widget criado

### Integrações
- [x] PhenologicalInfestationService integrado
- [x] OrganismRecommendationsService integrado
- [x] Submódulo Evolução Fenológica integrado
- [x] Submódulo Estande integrado
- [x] Histórico de Plantio integrado
- [x] NewOccurrenceCard dados capturados

### Cálculos
- [x] Quantidade média (MIP)
- [x] Frequência por organismo
- [x] Severidade média
- [x] Nível de risco (com JSONs)
- [x] Score de confiança
- [x] DAE (Dias Após Emergência)

### Recomendações
- [x] Recomendações gerais (baseadas em risco)
- [x] Recomendações dos JSONs (químico)
- [x] Recomendações dos JSONs (biológico)
- [x] Recomendações dos JSONs (cultural)
- [x] Observações de manejo dos JSONs
- [x] Foco prioritário em organismos críticos

### Design
- [x] Gradientes (verde, azul, índigo)
- [x] Cards com sombras
- [x] Bordas arredondadas
- [x] Ícones contextualizados
- [x] Cores semânticas
- [x] Chips para dados complementares
- [x] Badges para status/contadores
- [x] Layout responsivo

### Interface
- [x] Loading states
- [x] Empty states
- [x] Error handling
- [x] Navegação (Ver Detalhes)
- [x] Filtros integrados
- [x] Refresh automático

---

## 🎉 RESULTADO FINAL

O novo **Card de Monitoramento Elegante** está **100% completo** com:

✅ **Dados 100% reais** (do NewOccurrenceCard + Submódulos)  
✅ **Cálculos com JSONs** (organismos_*.json)  
✅ **Regras customizadas** (priorizadas)  
✅ **Recomendações dos JSONs** (químico, biológico, cultural)  
✅ **Estágio Fenológico** (V4, V5, R1, etc.)  
✅ **População e DAE** (dados do plantio)  
✅ **Design moderno FortSmart** (gradientes, cores, ícones)  
✅ **Performance otimizada** (queries únicas)  

---

## 🚀 LOCALIZAÇÃO NO APP

```
App FortSmart Agro
  → Relatórios
    → Relatório Agronômico
      → Dashboard de Monitoramento
        → 📊 "Monitoramentos - Visualização Inteligente"
          → Cards elegantes e completos
            → Toque para análise detalhada
```

---

**Desenvolvido com ❤️ e padrão agronômico profissional** 🌾✅

