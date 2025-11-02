# 🌾 Atualização Completa do JSON - Trigo

## ✅ **Status: ATUALIZADO COM SUCESSO**

O arquivo `lib/data/organismos_trigo.json` foi completamente atualizado com os dados detalhados fornecidos, mantendo a estrutura existente e adicionando todas as novas funcionalidades.

---

## 🎯 **Organismos Atualizados**

### **🐛 PRAGAS (4 organismos)**

#### **1. Pulgão-verde-dos-cereais**
- **Nome científico**: `Schizaphis graminum`
- **Fases detalhadas**:
  - Ovo (0,3 mm) - Ovos em repouso, sem causar dano direto
  - Ninfa (0,5-1 mm) - Sucção de seiva das folhas jovens
  - Adulto (1,5-2 mm) - Sucção intensa de seiva, transmissão de viroses
- **Severidade**:
  - Baixo: 5-10 pulgões por folha (0-5% perda)
  - Médio: 10-20 pulgões por folha (5-15% perda)
  - Alto: Mais de 20 pulgões por folha (15-30% perda)
- **Limiares específicos**: 10-20 pulgões por folha por fase

#### **2. Pulgão-da-espiga**
- **Nome científico**: `Sitobion avenae`
- **Fases detalhadas**:
  - Ninfa (1 mm) - Sucção inicial em espigas jovens
  - Adulto (2-2,5 mm) - Alimentação nas espigas e grãos em formação
- **Severidade**:
  - Baixo: 5-10 pulgões por espiga (0-5% perda)
  - Médio: 10-20 pulgões por espiga (5-15% perda)
  - Alto: Mais de 20 pulgões por espiga (15-30% perda)
- **Limiares específicos**: 10-20 pulgões por espiga por fase

#### **3. Percevejo-barriga-verde** ⭐ **NOVO**
- **Nome científico**: `Dichelops furcatus`
- **Fases detalhadas**:
  - Ovo (1 mm) - Sem dano direto
  - Ninfa (3-5 mm) - Sucção na base das plântulas
  - Adulto (8-12 mm) - Sucção em colmos e folhas
- **Severidade**:
  - Baixo: 1-2 percevejos por metro quadrado (0-5% perda)
  - Médio: 3-5 percevejos por metro quadrado (5-15% perda)
  - Alto: Mais de 5 percevejos por metro quadrado (15-30% perda)
- **Limiares específicos**: 2-5 percevejos por metro quadrado por fase

#### **4. Lagarta-do-trigo** ⭐ **NOVO**
- **Nome científico**: `Pseudaletia sequax`
- **Fases detalhadas**:
  - Ovo (0,8 mm) - Não causa dano direto
  - Lagarta neonatal (1-3 mm) - Início de raspagens nas folhas jovens
  - Lagarta média (10-20 mm) - Consome grande parte do limbo foliar
  - Lagarta adulta (30-35 mm) - Defoliação severa
- **Severidade**:
  - Baixo: 1-2 lagartas por metro quadrado (0-5% perda)
  - Médio: 3-5 lagartas por metro quadrado (5-15% perda)
  - Alto: Mais de 5 lagartas por metro quadrado (15-30% perda)
- **Limiares específicos**: 2-5 lagartas por metro quadrado por fase

---

### **🦠 DOENÇAS (4 organismos)**

#### **1. Brusone do trigo** ⭐ **NOVO**
- **Nome científico**: `Magnaporthe oryzae patótipo Triticum`
- **Sintomas**: Lesões em espigas e colmos, branqueamento parcial ou total da espiga
- **Severidade**:
  - Baixo: Até 5% de espigas atacadas (0-5% perda)
  - Médio: Entre 5-15% de espigas atacadas (5-15% perda)
  - Alto: Mais de 15% de espigas atacadas (15-40% perda)
- **Condições favoráveis**: 25-30°C, 80-95% umidade
- **Limiares específicos**: 2-10% das espigas por fase

#### **2. Ferrugem da folha**
- **Nome científico**: `Puccinia triticina`
- **Sintomas**: Pústulas alaranjadas nas folhas, redução na fotossíntese
- **Severidade**:
  - Baixo: Até 5% da área foliar com pústulas (0-5% perda)
  - Médio: 5-20% da área foliar afetada (5-15% perda)
  - Alto: Mais de 20% da área foliar atacada (15-30% perda)
- **Condições favoráveis**: 15-22°C, 80-95% umidade
- **Limiares específicos**: 5-15% da área foliar por fase

#### **3. Ferrugem amarela**
- **Nome científico**: `Puccinia striiformis f. sp. tritici`
- **Sintomas**: Estrias amarelas paralelas às nervuras, folhas secam rapidamente
- **Severidade**:
  - Baixo: Até 2% de folhas com sintomas (0-5% perda)
  - Médio: 2-10% de folhas afetadas (5-15% perda)
  - Alto: Mais de 10% de folhas afetadas (15-30% perda)
- **Condições favoráveis**: 10-15°C, 80-95% umidade
- **Limiares específicos**: 2-10% das folhas por fase

#### **4. Giberela**
- **Nome científico**: `Fusarium graminearum`
- **Sintomas**: Espigas branqueadas, grãos chochos e contaminados por micotoxinas (DON)
- **Severidade**:
  - Baixo: Até 2% de espigas afetadas (0-5% perda)
  - Médio: 2-10% de espigas afetadas (5-15% perda)
  - Alto: Mais de 10% de espigas atacadas (15-40% perda)
- **Condições favoráveis**: 20-30°C, 80-95% umidade
- **Limiares específicos**: 1-5% das espigas por fase

---

## 🆕 **Novas Funcionalidades Adicionadas**

### **1. Fases Detalhadas**
- **Estágios específicos** com tamanhos e danos
- **Progressão de desenvolvimento** do organismo
- **Danos específicos** por fase de desenvolvimento

### **2. Severidade Detalhada**
- **3 níveis**: Baixo, Médio, Alto
- **Descrição específica** de cada nível
- **Perda de produtividade** em percentual
- **Cor de alerta** para visualização
- **Ação recomendada** para cada nível

### **3. Condições Favoráveis**
- **Temperatura** ideal para desenvolvimento
- **Umidade** relativa favorável
- **Condições de chuva** ideais
- **Vento** para dispersão
- **Tipo de solo** e pH

### **4. Limiares Específicos**
- **Fase vegetativa**: Limiares para plantas jovens
- **Fase de floração**: Limiares durante floração
- **Fase de enchimento**: Limiares durante enchimento de grãos

---

## 📊 **Estatísticas Atualizadas**

```json
{
  "total_organismos": 8,
  "pragas": 4,
  "doencas": 4,
  "plantas_daninhas": 2,
  "principais_ameacas": [
    "Pulgão-verde-dos-cereais",
    "Brusone do trigo",
    "Ferrugem da folha",
    "Giberela"
  ],
  "epocas_criticas": [
    "Perfilhamento",
    "Florescimento",
    "Enchimento de grãos"
  ]
}
```

---

## 🎨 **Cores de Alerta Implementadas**

- 🟢 **BAIXO**: `#4CAF50` (Verde) - Monitoramento preventivo
- 🟠 **MÉDIO**: `#FF9800` (Laranja) - Controle seletivo
- 🔴 **ALTO**: `#F44336` (Vermelho) - Controle imediato

---

## 🔧 **Integração com Sistema de Cálculos**

### **Fórmulas Matemáticas Aplicáveis:**
- **I_ponto = N_observado / N_limiar**
- **I_talhão = Σ(N_observado,i) / Σ(N_limiar,i)**
- **Heatmap térmico** com intensidade baseada em severidade
- **Evolução temporal** com taxas de crescimento

### **Exemplo de Cálculo:**
```
Ponto 1: 15 pulgões-verde (limiar: 10) → I_ponto = 15/10 = 1.5 (CRÍTICO)
Ponto 2: 3 percevejos-barriga-verde (limiar: 5) → I_ponto = 3/5 = 0.6 (MÉDIO)
Ponto 3: 2 lagartas-do-trigo (limiar: 2) → I_ponto = 2/2 = 1.0 (MÉDIO)

I_talhão = (15+3+2) / (10+5+2) = 20/17 = 1.18 (CRÍTICO)
```

---

## 🚀 **Benefícios da Atualização**

### **1. Precisão Científica**
- ✅ **Dados atualizados** com informações técnicas precisas
- ✅ **Fases de desenvolvimento** detalhadas
- ✅ **Limiares específicos** por fase fenológica
- ✅ **Condições ambientais** favoráveis

### **2. Integração com Cálculos Matemáticos**
- ✅ **Compatível** com fórmulas de infestação
- ✅ **Limiares numéricos** para cálculos precisos
- ✅ **Severidade quantificada** em percentuais
- ✅ **Cores de alerta** para visualização

### **3. Monitoramento Avançado**
- ✅ **Detecção precoce** com limiares baixos
- ✅ **Ações específicas** para cada nível de severidade
- ✅ **Condições favoráveis** para alertas preventivos
- ✅ **Evolução temporal** com dados históricos

### **4. Gestão Integrada**
- ✅ **Controle biológico** e químico específico
- ✅ **Métodos culturais** preventivos
- ✅ **Monitoramento** com técnicas específicas
- ✅ **Resistência** de variedades disponível

---

## 📈 **Impacto no Sistema**

### **1. Mapa de Infestação**
- **Heatmaps mais precisos** com limiares específicos
- **Cores baseadas em severidade** real
- **Alertas automáticos** baseados em fórmulas matemáticas
- **Evolução temporal** com dados do Trigo

### **2. Monitoramento**
- **Detecção precoce** com limiares baixos
- **Classificação automática** por severidade
- **Ações recomendadas** específicas
- **Integração com catálogo** atualizado

### **3. Gestão de Pragas e Doenças**
- **Controle específico** por organismo
- **Timing correto** de aplicações
- **Eficiência aumentada** no manejo
- **Redução de custos** com aplicações desnecessárias

---

## 🎯 **Resumo Final**

**O JSON do Trigo foi completamente atualizado com:**

1. **✅ 4 pragas** com fases detalhadas e severidade
2. **✅ 4 doenças** com sintomas e limiares específicos
3. **✅ Fases de desenvolvimento** com tamanhos e danos
4. **✅ Severidade detalhada** com cores e ações
5. **✅ Condições favoráveis** ambientais
6. **✅ Limiares específicos** por fase fenológica
7. **✅ Integração completa** com sistema de cálculos matemáticos

**O sistema agora oferece monitoramento e controle de pragas e doenças do Trigo com precisão científica e integração completa com as fórmulas matemáticas de infestação!** 🌾✨

---

## 🔍 **Detalhes Técnicos**

### **Estrutura Mantida:**
- **Compatibilidade** com sistema existente
- **Formato JSON** padronizado
- **IDs únicos** para cada organismo
- **Metadados** atualizados

### **Novos Campos Adicionados:**
- `fases[]` - Estágios de desenvolvimento
- `severidade{}` - Níveis de severidade
- `condicoes_favoraveis{}` - Condições ambientais
- `limiares_especificos{}` - Limiares por fase

### **Integração com Cálculos:**
- **Fórmulas matemáticas** aplicáveis
- **Limiares numéricos** para cálculos
- **Cores de alerta** para visualização
- **Metadados** para auditoria

**O Trigo está pronto para uso em produção com dados completos e precisos!** 🚀
