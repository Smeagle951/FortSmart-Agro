# 🔬 Cálculos Profissionais de Germinação - Normas ISTA/AOSA/MAPA

## 📋 **ÍNDICE DE CÁLCULOS IMPLEMENTADOS**

### ✅ **TODOS os cálculos estão implementados em Dart puro - 100% Offline!**

---

## 1️⃣ **CÁLCULOS BÁSICOS DE GERMINAÇÃO**

### **1.1 Percentual de Germinação (PG)**

**Fórmula:**
```
PG = (Sementes germinadas / Total de sementes) × 100
```

**Norma:** ISTA, AOSA, MAPA  
**Exemplo:**
```
45 germinadas / 50 total = 90%
```

**Interpretação:**
- ≥ 90%: Excelente
- 80-89%: Bom (padrão comercial)
- 70-79%: Regular (uso condicionado)
- < 70%: Ruim (reprovado)

---

### **1.2 Percentual de Plântulas Normais**

**Critérios ISTA para plântula normal:**
- ✅ Raiz primária desenvolvida
- ✅ Hipocótilo/epicótilo vigoroso
- ✅ Cotilédones sadios
- ✅ Sem deformações graves

**Fórmula:**
```
PN = (Plântulas normais / Total) × 100
```

---

### **1.3 Percentual de Plântulas Anormais**

**Tipos de anormalidades (ISTA):**
- Raízes atrofiadas ou ausentes
- Hipocótilo/epicótilo deformado
- Cotilédones danificados
- Crescimento desequilibrado

**Fórmula:**
```
PA = (Plântulas anormais / Total) × 100
```

---

### **1.4 Sementes Mortas e Duras**

**Sementes Mortas:**
- Não germinaram após período de teste
- Apresentam sinais de deterioração

**Sementes Duras (leguminosas):**
- Tegumento impermeável
- Não absorveram água
- Permanecem firmes

---

## 2️⃣ **CÁLCULOS DE VIGOR (Metodologias Oficiais)**

### **2.1 Primeira Contagem de Germinação (PCG)**

**Metodologia oficial AOSA/ISTA**

**Fórmula:**
```
PCG = (Plântulas normais no dia X / Germinação final) × 100
```

**Dias de avaliação por cultura:**
| Cultura | Primeira Contagem | Contagem Final |
|---------|-------------------|----------------|
| Soja | 5º dia | 8º dia |
| Milho | 4º dia | 7º dia |
| Feijão | 5º dia | 9º dia |
| Trigo | 4º dia | 8º dia |
| Algodão | 4º ou 7º dia | 12º dia |
| Arroz | 7º dia | 14º dia |

**Interpretação PCG:**
- **> 80%**: Vigor alto - germinação rápida e uniforme
- **60-80%**: Vigor médio - germinação moderada
- **< 60%**: Vigor baixo - germinação lenta

**Exemplo Prático (Soja):**
```
Dia 5 (PCG): 32 plântulas normais
Dia 8 (Final): 45 plântulas normais
PCG = (32/45) × 100 = 71% (Vigor Médio)
```

---

### **2.2 Índice de Velocidade de Germinação (IVG)**

**Metodologia:** Maguire (1962)

**Fórmula:**
```
IVG = Σ (G_i / N_i)
```
Onde:
- `G_i` = número de plântulas normais no dia i
- `N_i` = número de dias desde a instalação

**Exemplo:**
```
Dia 3: 5 plântulas  → 5/3 = 1.67
Dia 5: 15 plântulas → 15/5 = 3.00
Dia 7: 28 plântulas → 28/7 = 4.00
Dia 10: 35 plântulas → 35/10 = 3.50

IVG = 1.67 + 3.00 + 4.00 + 3.50 = 12.17
```

**Interpretação:**
- **Quanto maior o IVG**, maior o vigor
- Compare lotes da mesma cultura
- Útil para rankear lotes

---

### **2.3 Velocidade Média de Germinação (VMG)**

**Metodologia:** Labouriau (1983)

**Fórmula:**
```
VMG = Σ (n_i × t_i) / Σ n_i
```
Onde:
- `n_i` = número de sementes germinadas no tempo i
- `t_i` = tempo em dias

**Interpretação:**
- **Quanto menor VMG**, mais rápida a germinação
- Expressa em dias
- Representa o tempo médio para germinar

**Exemplo:**
```
Dia 3: 5 sementes → 5 × 3 = 15
Dia 5: 10 sementes → 10 × 5 = 50
Dia 7: 13 sementes → 13 × 7 = 91

Total: 28 sementes
Soma ponderada: 15 + 50 + 91 = 156

VMG = 156 / 28 = 5.57 dias
```

---

### **2.4 Coeficiente de Velocidade de Germinação (CVG)**

**Metodologia:** Kotowski (1926)

**Fórmula:**
```
CVG = 100 × Σ N_i / Σ (N_i × T_i)
```

**Interpretação:**
- **Quanto maior CVG**, mais rápida a germinação
- Expresso em percentual
- Complementar ao IVG

---

### **2.5 Índice de Sincronização (Z)**

**Metodologia:** Primack (1980)

**Fórmula:**
```
Z = Σ C_ni,2 / C_N,2
```
Onde:
- `C_ni,2` = combinação de n_i tomados 2 a 2
- `C_N,2` = combinação de N tomados 2 a 2
- `C(n,2) = n(n-1)/2`

**Interpretação:**
- **Z = 1**: Germinação totalmente sincronizada (todas no mesmo dia)
- **Z próximo de 0**: Germinação dispersa no tempo
- Importante para culturas que exigem uniformidade

---

### **2.6 Incerteza (U)**

**Metodologia:** Labouriau & Valadares (1976)

**Fórmula:**
```
U = -Σ (f_i × log2(f_i))
```
Onde:
- `f_i` = frequência relativa de germinação no dia i

**Interpretação:**
- **Quanto menor U**, mais sincronizada a germinação
- **Quanto maior U**, mais dispersa
- Complementar ao índice Z

---

## 3️⃣ **ANÁLISE DE SANIDADE**

### **3.1 Índice de Sanidade**

**Fórmula:**
```
IS = ((Total - Sementes com problemas) / Total) × 100
```

**Problemas considerados:**
- Manchas (fungos/bactérias)
- Podridão
- Cotilédones amarelados

**Interpretação:**
- ≥ 95%: Excelente
- 85-94%: Boa
- 70-84%: Regular
- < 70%: Ruim

---

### **3.2 Principais Patógenos**

**Identificação visual:**

| Sintoma | Possível Causa | Ação |
|---------|----------------|------|
| Manchas escuras | *Phomopsis*, *Cercospora* | Tratamento fungicida |
| Mofo branco/cinza | *Aspergillus*, *Penicillium* | Secagem, tratamento |
| Podridão úmida | *Pythium*, *Rhizoctonia* | Fungicida sistêmico |
| Cotilédones amarelos | Deficiência nutricional | Análise nutricional |

---

## 4️⃣ **PUREZA FÍSICA**

### **4.1 Pureza Física**

**Metodologia:** ISTA/MAPA

**Fórmula:**
```
PF = (Peso de sementes puras / Peso total) × 100
```

**Componentes da análise:**
1. **Sementes puras**: da espécie analisada
2. **Material inerte**: pedras, solo, palha
3. **Outras sementes**: outras espécies

**Padrões MAPA:**
- Mínimo: 98% para sementes certificadas
- Mínimo: 95% para sementes fiscalizadas

---

## 5️⃣ **QUALIDADE GERAL DO LOTE**

### **5.1 Valor Cultural (VC)**

**Fórmula fundamental da qualidade de sementes**

```
VC = (Pureza × Germinação) / 100
```

**Interpretação:**
- **VC > 80%**: Lote Classe A (Premium)
- **VC 70-80%**: Lote Classe B (Padrão comercial)
- **VC 60-70%**: Lote Classe C (Uso próprio)
- **VC < 60%**: Fora do padrão

**Exemplo:**
```
Pureza: 98%
Germinação: 90%
VC = (98 × 90) / 100 = 88.2% (Classe A)
```

---

### **5.2 Índice de Qualidade de Sementes (IQS)**

**Fórmula composta (FortSmart)**

```
IQS = (G × 0.4) + (V × 0.3) + (S × 0.2) + (P × 0.1)
```

Onde:
- `G` = Germinação (40%)
- `V` = Vigor/PCG (30%)
- `S` = Sanidade (20%)
- `P` = Pureza (10%)

**Exemplo:**
```
Germinação: 90%
Vigor (PCG): 75%
Sanidade: 95%
Pureza: 98%

IQS = (90×0.4) + (75×0.3) + (95×0.2) + (98×0.1)
    = 36 + 22.5 + 19 + 9.8
    = 87.3% (Excelente)
```

---

## 6️⃣ **PESO DE MIL SEMENTES (PMS)**

### **6.1 Determinação do PMS**

**Metodologia:** ISTA/MAPA

**Fórmula:**
```
PMS = (Peso da amostra × 1000) / Número de sementes
```

**Procedimento padrão:**
1. Contar 8 repetições de 100 sementes
2. Pesar cada repetição
3. Calcular média
4. Multiplicar por 10

**Importância:**
- Indica tamanho médio das sementes
- Determina densidade de semeadura
- Avalia uniformidade do lote

---

### **6.2 Densidade de Semeadura**

**Fórmula:**
```
DS = (População × PMS) / (Germinação × Pureza) / 1000
```

**Exemplo Soja:**
```
População desejada: 300.000 plantas/ha
PMS: 150g
Germinação: 90%
Pureza: 98%

DS = (300.000 × 150) / (0.90 × 0.98) / 1000
   = 45.000.000 / 882
   = 51 kg/ha
```

**Ajustes:**
- Vigor alto: reduzir 10-15%
- Vigor baixo: aumentar 15-20%
- Condições adversas: aumentar 20-30%

---

## 7️⃣ **PADRÕES OFICIAIS (MAPA)**

### **Germinação Mínima por Cultura**

| Cultura | Germinação Mínima | Pureza Mínima | VC Mínimo |
|---------|-------------------|---------------|-----------|
| Soja | 80% | 98% | 78% |
| Milho | 85% | 98% | 83% |
| Feijão | 80% | 98% | 78% |
| Algodão | 80% | 98% | 78% |
| Trigo | 80% | 98% | 78% |
| Arroz | 80% | 98% | 78% |
| Sorgo | 80% | 98% | 78% |
| Girassol | 75% | 96% | 72% |

---

## 8️⃣ **CLASSIFICAÇÃO PROFISSIONAL**

### **Sistema de Classificação FortSmart**

**Baseado em múltiplos parâmetros:**

#### **Classe A - Premium (≥ 85 pontos)**
- ✅ Germinação ≥ 90%
- ✅ Vigor alto (PCG ≥ 80%)
- ✅ Sanidade ≥ 95%
- ✅ Pureza ≥ 98%
- ✅ VC ≥ 88%

**Recomendação:**
- Excelente para comercialização
- Pode reduzir densidade 10-15%
- Tolerante a adversidades

---

#### **Classe B - Padrão (70-84 pontos)**
- ✅ Germinação 80-89%
- ✅ Vigor médio (PCG 60-79%)
- ✅ Sanidade 85-94%
- ✅ Pureza 95-97%
- ✅ VC 76-87%

**Recomendação:**
- Aprovado para plantio
- Densidade normal
- Condições favoráveis

---

#### **Classe C - Uso Próprio (60-69 pontos)**
- ⚠️ Germinação 70-79%
- ⚠️ Vigor baixo (PCG 40-59%)
- ⚠️ Sanidade 70-84%
- ⚠️ Pureza 90-94%
- ⚠️ VC 63-75%

**Recomendação:**
- Uso condicionado
- Aumentar densidade 20-30%
- Tratamento de sementes obrigatório

---

#### **Reprovado (< 60 pontos)**
- ❌ Germinação < 70%
- ❌ Vigor muito baixo
- ❌ Problemas fitossanitários
- ❌ VC < 63%

**Recomendação:**
- Não recomendado para plantio
- Alto risco de perdas
- Considerar descarte

---

## 9️⃣ **RELATÓRIO PROFISSIONAL COMPLETO**

### **Modelo de Laudo Técnico**

```
═══════════════════════════════════════════════════════
     LAUDO DE ANÁLISE DE SEMENTES
     FortSmart - Laboratório Virtual
═══════════════════════════════════════════════════════

IDENTIFICAÇÃO DO LOTE
─────────────────────────────────────────────────────
Lote Nº: 2024-001
Cultura: Soja
Variedade: BRS 284
Data: 30/09/2024

ANÁLISE DE GERMINAÇÃO
─────────────────────────────────────────────────────
Plântulas Normais:        45 (90%)
Plântulas Anormais:        3 (6%)
Sementes Mortas:           2 (4%)
Sementes Duras:            0 (0%)
────────────────────────────
TOTAL:                    50 (100%)

ANÁLISE DE VIGOR
─────────────────────────────────────────────────────
Primeira Contagem (5º dia): 71% (MÉDIO)
IVG:                        12.17
VMG:                        5.57 dias
CVG:                        17.9
Classificação:             VIGOR MÉDIO

ANÁLISE DE SANIDADE
─────────────────────────────────────────────────────
Índice de Sanidade:        94%
Manchas:                    3 sementes (6%)
Podridão:                   0 sementes (0%)
Cotilédones Amarelados:     0 sementes (0%)

PUREZA FÍSICA
─────────────────────────────────────────────────────
Pureza:                    98%
Material Inerte:            1.5%
Outras Sementes:            0.5%

QUALIDADE GERAL
─────────────────────────────────────────────────────
Valor Cultural:            88.2%
IQS (Índice Qualidade):    87.3%
Classificação:             CLASSE A (PREMIUM)

CONCLUSÃO
─────────────────────────────────────────────────────
✅ LOTE APROVADO para comercialização
✅ Atende padrões MAPA (IN 45/2013)
✅ Recomendado para plantio

RECOMENDAÇÕES
─────────────────────────────────────────────────────
• Densidade: 48-51 kg/ha
• Tratamento: Preventivo (opcional)
• Armazenamento: Ambiente seco (<13% umidade)

═══════════════════════════════════════════════════════
Responsável Técnico: IA FortSmart v2.0
Base: Normas ISTA/AOSA/MAPA
═══════════════════════════════════════════════════════
```

---

## ✅ **GARANTIA CIENTÍFICA**

Todos os cálculos implementados são baseados em:

- ✅ **ISTA** (International Seed Testing Association)
- ✅ **AOSA** (Association of Official Seed Analysts)
- ✅ **MAPA** (Ministério da Agricultura - Brasil)
- ✅ Literatura científica revisada por pares
- ✅ Normas internacionais de análise de sementes

**100% Implementado em Dart Puro - Funciona Offline!**

---

**🔬 Precisão Científica + 📱 Dart Offline = 🎯 Análise Profissional Garantida ✅**
