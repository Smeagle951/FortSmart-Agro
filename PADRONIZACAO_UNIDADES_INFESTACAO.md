# 📏 PADRONIZAÇÃO DE UNIDADES - SISTEMA DE INFESTAÇÃO

## Data: 31/10/2025
## Sistema: FortSmart Agro v3.0

---

## ✅ PADRONIZAÇÃO IMPLEMENTADA!

### 🎯 UNIDADE PADRÃO OFICIAL:

```
✅ organismos/ponto (RECOMENDADO)
```

**Por quê?**
- ✅ Cálculo MIP usa **MÉDIA por ponto**
- ✅ Você conta organismos **em cada ponto**
- ✅ Sistema calcula: Total / Número de pontos
- ✅ Mais simples e prático para campo

---

## 📊 COMO O CÁLCULO FUNCIONA

### Fórmula Atual (PADRÃO MIP):

```
1. Você coleta dados:
   Ponto 1: 4 lagartas
   Ponto 2: 6 lagartas
   Ponto 3: 4 lagartas

2. Sistema calcula:
   Total: 4 + 6 + 4 = 14 lagartas
   Média: 14 / 3 pontos = 4,67 lagartas/PONTO  ← UNIDADE AQUI!

3. Sistema compara com threshold:
   Se threshold = 3,0 organismos/ponto
   4,67 > 3,0 → ALTO ✅
```

---

## 🔍 UNIDADES DISPONÍVEIS

### 1️⃣ organismos/ponto (RECOMENDADO) ✅

**O que significa:**
- Quantidade média de organismos **por ponto de amostragem**
- Você vai ao campo, marca um ponto, conta quantos organismos tem ALI

**Exemplo prático:**
```
Threshold: 2,0 lagartas/ponto

Você coleta:
- Ponto A: 3 lagartas  
- Ponto B: 1 lagarta
- Ponto C: 2 lagartas

Média: (3+1+2) / 3 = 2,0 lagartas/ponto  ← IGUAL ao threshold
Nível: MÉDIO
```

**Quando usar:**
- ✅ Monitoramento de campo com pontos GPS
- ✅ Amostragem por ponto
- ✅ Padrão MIP brasileiro
- ✅ **SEMPRE QUE POSSÍVEL** (mais simples)

---

### 2️⃣ organismos/metro ⚠️

**O que significa:**
- Quantidade de organismos **por metro linear** de linha de plantio
- Usado em algumas metodologias específicas

**Exemplo prático:**
```
Threshold: 5,0 lagartas/metro

Você coleta:
- Linha 1 (1 metro): 6 lagartas
- Linha 2 (1 metro): 4 lagartas  
- Linha 3 (1 metro): 8 lagartas

Média: (6+4+8) / 3 = 6,0 lagartas/metro  ← IGUAL ao threshold
Nível: ALTO
```

**Quando usar:**
- ⚠️ Metodologias específicas que pedem "por metro"
- ⚠️ Comparação com literatura técnica antiga
- ⚠️ Apenas se seu agrônomo especificar

---

## 🎯 VALORES DECIMAIS PERMITIDOS

### ✅ AGORA você pode usar:

```
0,1 organismos/ponto
0,2 organismos/ponto
0,5 organismos/ponto  ← COMUM para estágios críticos
1,0 organismos/ponto
1,5 organismos/ponto
2,0 organismos/ponto
2,3 organismos/ponto
...até 15,0
```

**Precisão:** Casas decimais com incremento de **0,1**

**Sliders ajustados:**
- Min: 0,0
- Max: 15,0
- Divisões: 150 (precisão de 0,1)
- Mostra: 1 casa decimal (ex: 2,3)

---

## 📋 EXEMPLO COMPLETO - LAGARTA-DA-SOJA

### Cenário: Estágio R5-R6 (enchimento de grãos) - CRÍTICO

**Sua configuração customizada:**
```
Unidade: organismos/ponto  ✅ RECOMENDADO

Thresholds:
  BAIXO:    0,2 lagartas/ponto
  MÉDIO:    0,5 lagartas/ponto
  ALTO:     1,0 lagarta/ponto
  CRÍTICO:  2,0 lagartas/ponto
```

**Por que esses valores baixos?**
- Em R5-R6 (enchimento), a planta está MUITO sensível
- Mesmo 1 lagarta já causa dano significativo
- Precisa detectar e agir RÁPIDO

**Teste no campo:**
```
Monitoramento:
  Ponto 1: 1 lagarta
  Ponto 2: 0 lagartas
  Ponto 3: 1 lagarta

Cálculo:
  Total: 1 + 0 + 1 = 2 lagartas
  Média: 2 / 3 = 0,67 lagartas/PONTO

Comparação:
  0,67 > 0,5 e ≤ 1,0 → MÉDIO ✅

Log:
⭐ Usando REGRA CUSTOMIZADA do usuário
🔍 Quantidade: 0.67
   Baixo ≤ 0.2
   Médio ≤ 0.5
   Alto ≤ 1.0    ← 0.67 está aqui!
   ➡️ NÍVEL: MÉDIO
```

---

## 📊 TABELA DE VALORES SUGERIDOS

### Para ESTÁGIOS VEGETATIVOS (V1-V6):

| Organismo | Baixo | Médio | Alto | Crítico | Unidade |
|-----------|-------|-------|------|---------|---------|
| Lagarta-da-soja | 0,5 | 1,5 | 3,0 | 5,0 | organismos/ponto |
| Percevejo | 0,3 | 1,0 | 2,0 | 4,0 | organismos/ponto |
| Torrãozinho | 0,2 | 0,8 | 2,0 | 4,0 | organismos/ponto |

### Para ESTÁGIOS CRÍTICOS (R5-R6 - enchimento):

| Organismo | Baixo | Médio | Alto | Crítico | Unidade |
|-----------|-------|-------|------|---------|---------|
| Lagarta-da-soja | 0,2 | 0,5 | 1,0 | 2,0 | organismos/ponto |
| Percevejo | 0,1 | 0,3 | 0,8 | 1,5 | organismos/ponto |
| Torrãozinho | 0,1 | 0,2 | 0,5 | 1,0 | organismos/ponto |

**Nota:** Valores menores em estágios críticos = mais sensível!

---

## 🔄 CONVERSÃO: Por Metro → Por Ponto

Se você tem valores "por metro" e quer converter para "por ponto":

### Fórmula aproximada:
```
Valor/ponto ≈ Valor/metro × 0,5

Exemplo:
10 lagartas/metro × 0,5 = 5 lagartas/ponto
```

**Por quê 0,5?**
- Espaçamento típico de soja: 0,5m entre linhas
- 1 ponto abrange ~0,5m de linha
- Valor aproximado, ajuste conforme sua realidade

---

## 🎯 COMO CONFIGURAR NA PRÁTICA

### Passo 1: Abrir Tela de Regras

```
Configurações → Regras de Infestação
```

### Passo 2: Selecionar Cultura e Organismo

```
Cultura: [Soja ▼]
Organismo: Lagarta-da-soja (expandir)
```

### Passo 3: Escolher Unidade

```
Unidade: ⚪ Por Ponto  ⚫ Por Metro

✅ Selecione "Por Ponto" (RECOMENDADO)
```

### Passo 4: Ajustar Sliders (valores decimais!)

```
Estágio: R5-R6 (CRÍTICO)

BAIXO:    [░░░] 0,2 lagartas/ponto  ← Arrastar slider
MÉDIO:    [████] 0,5 lagartas/ponto
ALTO:     [██████] 1,0 lagarta/ponto
CRÍTICO:  [████████] 2,0 lagartas/ponto

Nota: Sliders agora permitem 0,1 | 0,2 | 0,3 ... até 15,0
```

### Passo 5: Salvar

```
💾 Salvar → ✅ Regras salvas com sucesso!
```

---

## 📈 PROGRESSÃO SUGERIDA DE VALORES

### Começando conservador (mais tolerante):
```
V1-V4:  1,0 / 3,0 / 5,0 / 8,0  (valores maiores)
R1-R4:  0,8 / 2,0 / 4,0 / 6,0
R5-R6:  0,5 / 1,5 / 3,0 / 5,0  (mais sensível)
```

### Sensibilidade média (balanceado):
```
V1-V4:  0,5 / 1,5 / 3,0 / 5,0
R1-R4:  0,3 / 1,0 / 2,0 / 4,0
R5-R6:  0,2 / 0,5 / 1,0 / 2,0  (CRÍTICO)
```

### Alta sensibilidade (detecção precoce):
```
V1-V4:  0,3 / 0,8 / 1,5 / 3,0
R1-R4:  0,2 / 0,5 / 1,0 / 2,0
R5-R6:  0,1 / 0,2 / 0,5 / 1,0  (MUITO SENSÍVEL!)
```

---

## ⚠️ ATENÇÃO: DIFERENÇA ENTRE UNIDADES

### Exemplo com MESMA coleta:

**Dados:**
- 3 pontos monitorados
- Ponto 1: 4 lagartas em 1 metro de linha
- Ponto 2: 6 lagartas em 1 metro de linha
- Ponto 3: 4 lagartas em 1 metro de linha

**Interpretação:**

| Unidade | Valor | O que significa |
|---------|-------|-----------------|
| **organismos/ponto** | 4,67 lagartas/ponto | Média de 4,67 lagartas **por ponto amostrado** |
| **organismos/metro** | 4,67 lagartas/metro | Média de 4,67 lagartas **por metro linear** |

**São iguais neste caso!** Mas podem diferir se:
- Ponto abrange mais/menos de 1 metro
- Metodologia de contagem é diferente

---

## 🎯 RECOMENDAÇÃO OFICIAL FORTSMART

### ✅ **USE: organismos/ponto**

**Motivos:**
1. ✅ Cálculo do sistema está em **organismos/ponto**
2. ✅ Logs mostram "Média/amostra" e "unidades/ponto"
3. ✅ Padrão MIP brasileiro usa **pontos de amostragem**
4. ✅ Mais simples para o produtor
5. ✅ Facilita comparação entre talhões

**Quando usar organismos/metro:**
- ⚠️ SOMENTE se metodologia específica exigir
- ⚠️ Se comparar com literatura que usa "por metro"
- ⚠️ Consulte agrônomo responsável

---

## 🧪 TESTE DE VALIDAÇÃO

### Teste 1: Valores Decimais

1. Abra **Regras de Infestação**
2. Soja → Lagarta-da-soja
3. Tente ajustar slider para **0,2**
4. **Deve permitir!** ✅
5. Salve e reabra
6. **Deve manter 0,2** ✅

### Teste 2: Seleção de Unidade

1. Mesma tela
2. Veja botões: **⚪ Por Ponto** | **⚪ Por Metro**
3. Clique em "Por Metro"
4. Veja mensagem: **"Unidade alterada"** ✅
5. Salve
6. Reabra e verifique se mantém

### Teste 3: Uso no Cálculo

1. Crie regra customizada:
   ```
   Lagarta-da-soja
   Unidade: organismos/ponto
   MÉDIO: 0,5 lagartas/ponto
   ```

2. Monitoramento:
   ```
   Ponto 1: 1 lagarta
   Média: 1,0 lagarta/ponto
   ```

3. **Espera-se:**
   ```
   1,0 > 0,5 → ALTO ✅
   
   Log:
   ⭐ Usando REGRA CUSTOMIZADA
   🔍 Quantidade: 1.0
      Médio ≤ 0.5
      ➡️ NÍVEL: ALTO
   ```

---

## 📚 DOCUMENTAÇÃO TÉCNICA

### Onde está implementado:

**1. Modelo de dados:**
```dart
// lib/models/infestation_rule.dart
final String unit; // 'organismos/ponto' ou 'organismos/metro'
```

**2. Banco de dados:**
```sql
-- lib/repositories/infestation_rules_repository.dart
CREATE TABLE infestation_rules (
  ...
  unit TEXT NOT NULL DEFAULT 'organismos/ponto',
  ...
)
```

**3. Tela de edição:**
```dart
// lib/screens/configuracao/infestation_rules_edit_screen.dart
SegmentedButton<String>(
  segments: [
    'Por Ponto',  // organismos/ponto
    'Por Metro',  // organismos/metro
  ],
)
```

**4. Cálculo:**
```dart
// lib/services/phenological_infestation_service.dart
Logger.info('   • Média/amostra: ${avgQuantity} unidades');
// ✅ Sempre usa "por ponto" no cálculo interno
```

---

## ⚙️ VALORES PADRÃO DO SISTEMA

### Se você NÃO criar regra customizada:

```
Padrão ajustado (JSON ÷ 2.0):
  Baixo: ≤ 1,0 organismos/ponto
  Médio: ≤ 2,5 organismos/ponto
  Alto: ≤ 4,0 organismos/ponto
  Crítico: > 4,0 organismos/ponto
```

### Se você CRIAR regra customizada:

```
Padrão inicial sugerido:
  Baixo: 0,5 organismos/ponto
  Médio: 1,5 organismos/ponto
  Alto: 3,0 organismos/ponto
  Crítico: 5,0 organismos/ponto
  
✅ Você pode ajustar para:
  0,1 | 0,2 | 0,3 ... até 15,0
```

---

## 🔧 EXEMPLOS PRÁTICOS DE CONFIGURAÇÃO

### Exemplo 1: Fazenda com histórico de alta pressão

**Organismo:** Percevejo-marrom  
**Estágio:** R5 (enchimento de grãos)  
**Unidade:** organismos/ponto  

**Configuração super sensível:**
```
BAIXO:    0,1 percevejos/ponto   (quase zero!)
MÉDIO:    0,3 percevejos/ponto
ALTO:     0,5 percevejos/ponto
CRÍTICO:  1,0 percevejo/ponto
```

**Resultado:**
- Com apenas **0,6 percevejos/ponto** → já é **ALTO**
- Detecta muito cedo
- Permite ação preventiva

---

### Exemplo 2: Manejo conservacionista

**Organismo:** Lagarta-da-soja  
**Estágio:** V4 (vegetativo)  
**Unidade:** organismos/ponto  

**Configuração mais tolerante:**
```
BAIXO:    1,0 lagarta/ponto
MÉDIO:    3,0 lagartas/ponto
ALTO:     6,0 lagartas/ponto
CRÍTICO:  10,0 lagartas/ponto
```

**Resultado:**
- Com **5 lagartas/ponto** → é **MÉDIO**
- Mais tolerante
- Usa controle biológico primeiro

---

### Exemplo 3: Estágio crítico (R5-R6)

**Organismo:** Torrãozinho  
**Estágio:** R5-R6  
**Unidade:** organismos/ponto  

**Configuração rigorosa:**
```
BAIXO:    0,1 insetos/ponto   (quase nenhum!)
MÉDIO:    0,2 insetos/ponto
ALTO:     0,5 insetos/ponto
CRÍTICO:  0,8 insetos/ponto
```

**Resultado:**
- Qualquer coisa acima de **0,2** já é preocupante
- Em enchimento de grãos, zero tolerância
- Ação imediata

---

## 🎓 CONCEITOS AGRONÔMICOS

### MIP (Manejo Integrado de Pragas):

```
📊 NÍVEL DE CONTROLE = f(Densidade, Frequência, Estágio)

Onde:
- Densidade = Média de organismos por ponto
- Frequência = % de pontos com infestação
- Estágio = Fenologia da cultura (V1, R5, etc)
```

### Unidades comuns na literatura:

| Literatura | Unidade | Conversão |
|------------|---------|-----------|
| Embrapa | organismos/m² | 1 m² ≈ 2 pontos |
| Literatura antiga | organismos/metro | 1 metro = 1 ponto |
| **FortSmart** | **organismos/ponto** | **Padrão!** ✅ |

---

## ✅ CHECKLIST DE PADRONIZAÇÃO

- [x] Modelo `InfestationRule` tem campo `unit`
- [x] Banco de dados tem coluna `unit`
- [x] Tela permite escolher unidade
- [x] Sliders permitem decimais (0.1 até 15.0)
- [x] Precisão de 0,1 (150 divisões)
- [x] Sistema prioriza regras customizadas
- [x] Logs mostram se usa regra customizada (⭐)
- [x] Documentação completa
- [ ] Testes pelo usuário

---

## 📞 PRÓXIMOS PASSOS

1. ✅ **Teste os sliders com decimais**
   - Tente 0,2 | 0,5 | 1,3 | 2,8
   - Deve permitir TODOS ✅

2. ✅ **Teste o seletor de unidade**
   - Alterne entre "Por Ponto" e "Por Metro"
   - Salve e reabra
   - Deve manter seleção ✅

3. ✅ **Teste integração completa**
   - Crie regra: Lagarta 0,5 / 1,5 / 3,0 / 5,0
   - Monitoramento: 2, 3, 2 lagartas (média = 2,33)
   - Espera-se: MÉDIO (2,33 > 1,5 e ≤ 3,0)
   - Log: ⭐ REGRA CUSTOMIZADA

4. ✅ **Me envie feedback**
   - Screenshots da tela
   - Logs mostrando ⭐
   - Confirmação se está funcionando

---

**Status:** ✅ **IMPLEMENTAÇÃO COMPLETA**  
**Unidade padrão:** **organismos/ponto** ✅  
**Decimais permitidos:** ✅ **0,1 até 15,0**  
**Seletor de unidade:** ✅ **Por Ponto / Por Metro**

**Data:** 31/10/2025 🌾  
**Desenvolvedor:** Especialista Agronômico + Dev Senior

