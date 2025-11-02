# 🔬 PLANO DE IMPLEMENTAÇÃO - 10 Melhorias Integradas

**Objetivo:** Implementar as 10 melhorias cognitivas e técnicas nos 241 organismos, usando dados de fontes públicas.

---

## 📊 10 MELHORIAS INTEGRADAS

| Nº | Tema | Função na IA | Impacto | Campo v3.0 | Prioridade |
|----|------|--------------|---------|------------|-----------|
| 1 | **Dados visuais** | Cores, padrões, tamanhos | Permite futura IA de imagem | `caracteristicas_visuais` | 🔴 Alta |
| 2 | **Condições climáticas** | Temp./umidade por risco | Alerta climático automático | `condicoes_climaticas` | 🔴 Alta |
| 3 | **Ciclo de vida** | Gerações, diapausa | Modelagem fenológica | `ciclo_vida` | 🔴 Alta |
| 4 | **Rotação e resistência** | IRAC e estratégias | Sustentabilidade de controle | `rotacao_resistencia` | 🟡 Média |
| 5 | **Distribuição geográfica** | Regiões de risco | Alertas regionais | `distribuicao_geografica` | 🟡 Média |
| 6 | **Diagnóstico diferencial** | Confundidores e sintomas | Evita erro de identificação | `diagnostico_diferencial` | 🟡 Média |
| 7 | **Economia integrada** | ROI e custo/ha | Recomendação econômica | `economia_agronomica` | 🟢 Baixa |
| 8 | **Controle biológico** | Espécies úteis e doses | Apoio a manejo integrado | `controle_biologico` | 🟢 Baixa |
| 9 | **Sazonalidade e tendência** | Meses de pico, El Niño | Planejamento preventivo | `tendencias_sazonais` | 🟢 Baixa |
| 10 | **Features IA** | Keywords e padrões | Base para IA embarcada local | `features_ia` | 🔴 Alta |

---

## 📚 FONTES DE DADOS LIVRES

### Estratégia de Coleta:

#### 1. **Embrapa** (Dados Visuais, Ciclo de Vida)
- **Uso:** Características visuais, tamanhos
- **Coleta:** Extrair de:**
  - Guias técnicos de pragas
  - Fichas técnicas de doenças
  - Catálogos de organismos

#### 2. **IRAC Brasil** (Rotação e Resistência)
- **Uso:** Grupos IRAC, estratégias anti-resistência
- **Coleta:** Tabelas de classificação IRAC
- **Exemplo:** `grupos_irac: ["18", "28"]`

#### 3. **MAPA / INMET** (Condições Climáticas)
- **Uso:** Temperatura/umidade ideais
- **Coleta:** Zoneamentos agrícolas
- **Exemplo:** `temperatura_min: 20, temperatura_max: 32`

#### 4. **SciELO / PubMed** (Ciclo de Vida, Diagnóstico)
- **Uso:** Dados científicos validados
- **Coleta:** Artigos acadêmicos abertos
- **Exemplo:** Duração de fases, gerações/ano

#### 5. **COODETEC / IAC** (Distribuição, Sazonalidade)
- **Uso:** Zoneamentos regionais
- **Coleta:** Manuais técnicos
- **Exemplo:** Regiões de ocorrência, meses de pico

---

## 🔄 ESTRATÉGIA DE IMPLEMENTAÇÃO

### Fase 1: Dados Básicos (Prioridade Alta)
**Objetivo:** Implementar melhorias 1, 2, 3, 10

#### 1.1 Dados Visuais (`caracteristicas_visuais`)
- Extrair de campos `fases` existentes (se disponível)
- Usar `tamanho_mm` das fases
- Cores: verde, marrom, preto, amarelo (baseado em categorias)
- Padrões: baseados em sintomas e observações

#### 1.2 Condições Climáticas (`condicoes_climaticas`)
- Extrair de `condicoes_favoraveis` existentes
- Converter texto para números estruturados
- Exemplo: "15-25°C" → `temperatura_min: 15, temperatura_max: 25`

#### 1.3 Ciclo de Vida (`ciclo_vida`)
- Extrair de campos `fases` (duração)
- Calcular totais: somar durações de fases
- Gerações: estimar baseado na duração total
- Diapausa: inferir de observações

#### 1.4 Features IA (`features_ia`)
- Keywords: extrair de sintomas e observações
- Marcadores visuais: baseados em características visuais

### Fase 2: Dados Técnicos (Prioridade Média)
**Objetivo:** Implementar melhorias 4, 5, 6

#### 2.1 Rotação e Resistência (`rotacao_resistencia`)
- Extrair grupos IRAC de `manejo_quimico`
- Exemplo: "Clorantraniliprole (IRAC 28)" → `grupos_irac: ["28"]`
- Estratégias: padrões baseados em grupos IRAC

#### 2.2 Distribuição Geográfica (`distribuicao_geografica`)
- Baseado em observações e cultura
- Soja: Sul, Centro-Oeste, Sudeste
- Milho: Todas as regiões
- Arroz: Sul, Sudeste

#### 2.3 Diagnóstico Diferencial (`diagnostico_diferencial`)
- Analisar sintomas similares entre organismos da mesma cultura
- Identificar confundidores baseado em sintomas
- Sintomas-chave: sintomas únicos

### Fase 3: Dados Econômicos (Prioridade Baixa)
**Objetivo:** Implementar melhorias 7, 8, 9

#### 3.1 Economia Agronômica (`economia_agronomica`)
- Calcular baseado em:
  - `dano_economico` (texto) → estimar custo não controle
  - `doses_defensivos` → calcular custo controle
  - ROI: (custo não controle - custo controle) / custo controle

#### 3.2 Controle Biológico (`controle_biologico`)
- Extrair de `manejo_biologico` existente
- Adicionar doses baseadas em literatura
- Identificar tipo: predador, parasitoide, entomopatogeno

#### 3.3 Sazonalidade (`tendencias_sazonais`)
- Picos: inferir de fenologia (estações do ano)
- El Niño: padrão geral (aumento/diminuição)
- Graus-dia: calcular baseado em ciclo de vida

---

## 📋 PLANO DE EXECUÇÃO

### Semana 3-4: Fase 1 (Alta Prioridade)
- [ ] Script de extração de dados visuais
- [ ] Script de conversão de condições climáticas
- [ ] Script de cálculo de ciclo de vida
- [ ] Script de geração de features IA
- [ ] Aplicar em Soja (50 organismos)

### Semana 5: Fase 2 (Média Prioridade)
- [ ] Script de extração IRAC
- [ ] Script de distribuição geográfica
- [ ] Script de diagnóstico diferencial
- [ ] Aplicar em Milho, Feijão (65 organismos)

### Semana 6: Fase 3 (Baixa Prioridade)
- [ ] Script de cálculo econômico
- [ ] Script de enriquecimento biológico
- [ ] Script de sazonalidade
- [ ] Aplicar em todas as culturas restantes

### Semana 7: Validação e Refinamento
- [ ] Validar dados contra fontes
- [ ] Revisar campos críticos manualmente
- [ ] Testar IA local com novos dados

---

## 🛠️ SCRIPTS NECESSÁRIOS

### 1. `scripts/enriquecer_dados_visuais.dart`
```dart
// Extrair dados visuais de fases e sintomas
// Gerar cores, padrões, tamanhos
```

### 2. `scripts/converter_condicoes_climaticas.dart`
```dart
// Converter condições_favoraveis para condicoes_climaticas estruturadas
// Extrair temperaturas, umidades
```

### 3. `scripts/calcular_ciclo_vida.dart`
```dart
// Calcular ciclo de vida de fases
// Estimar gerações por ano
```

### 4. `scripts/extrair_irac.dart`
```dart
// Extrair grupos IRAC de manejo_quimico
// Gerar estratégias de rotação
```

### 5. `scripts/enriquecer_completo.dart`
```dart
// Script principal que orquestra todas as melhorias
// Aplica em lote em todos os organismos
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1 (Alta Prioridade):
- [ ] Dados visuais: 241 organismos
- [ ] Condições climáticas: 241 organismos
- [ ] Ciclo de vida: 241 organismos (estimado se não tiver fases)
- [ ] Features IA: 241 organismos

### Fase 2 (Média Prioridade):
- [ ] Rotação IRAC: Pragas apenas (~120 organismos)
- [ ] Distribuição geográfica: 241 organismos
- [ ] Diagnóstico diferencial: 241 organismos

### Fase 3 (Baixa Prioridade):
- [ ] Economia agronômica: 241 organismos
- [ ] Controle biológico: Pragas e algumas doenças (~150 organismos)
- [ ] Sazonalidade: 241 organismos

---

## 📊 MÉTRICAS DE SUCESSO

- ✅ **100% dos organismos** com dados visuais
- ✅ **100% dos organismos** com condições climáticas
- ✅ **100% dos organismos** com ciclo de vida (estimado)
- ✅ **100% dos organismos** com features IA
- ✅ **90% das pragas** com rotação IRAC
- ✅ **100% dos organismos** com distribuição geográfica
- ✅ **100% dos organismos** com diagnóstico diferencial
- ✅ **80% dos organismos** com economia agronômica
- ✅ **90% das pragas** com controle biológico
- ✅ **100% dos organismos** com sazonalidade

---

**Próximo Passo:** Criar script de enriquecimento completo para começar a implementação!

