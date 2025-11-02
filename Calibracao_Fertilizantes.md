# FortSmart – Módulo Premium de Calibração de Distribuição de Fertilizantes

## 🌱 Objetivo

O módulo realiza a **calibração técnica da aplicação de fertilizantes granulados**, com base na coleta por bandejas em campo. Ele calcula:

- ✅ Coeficiente de Variação (CV%) da distribuição lateral
- ✅ Faixa Efetiva Real de aplicação, usando os pesos coletados
- ✅ Diagnóstico visual com gráfico
- ✅ Recomendações para o operador

---

## 🧾 Entradas do Usuário

| Campo                         | Tipo / Unidade             | Observações                                                                 |
|------------------------------|----------------------------|------------------------------------------------------------------------------|
| Fertilizante                 | Dropdown                   | Ex: NPK 20-05-20, vinculado ao estoque                                      |
| Granulometria (g/L)          | Numérico                   | Peso de 1 litro de fertilizante                                             |
| Faixa de aplicação esperada  | Numérico (m)               | Ex: 36 m                                                                    |
| Espaçamento entre bandejas   | Numérico (m)               | Ex: 1,0 m                                                                   |
| Pesos coletados              | Lista (mín. 15)            | Ex: `[152, 148, 141, ..., 136]`                                             |
| Operador / Máquina / Data    | Texto e automático         | Registro para rastreabilidade                                               |

---

## ⚙️ Cálculos Internos

### 1. Coeficiente de Variação (CV%)

```dart
final media = pesos.reduce((a, b) => a + b) / pesos.length;
final desvio = (pesos.map((x) => (x - media) * (x - media)).reduce((a, b) => a + b) / (pesos.length - 1)).sqrt();
final cv = (desvio / media) * 100;
```

**Classificação:**
- ✅ Bom: CV ≤ 10%
- ⚠️ Moderado: 10% < CV ≤ 15%
- ❌ Crítico: CV > 15%

---

### 2. Faixa Efetiva Real (com base nos dados)

```dart
final centro = pesos.length ~/ 2;
final mediaCentral = (pesos[centro - 1] + pesos[centro] + pesos[centro + 1]) / 3;
final limite = mediaCentral * 0.5;

int esquerda = centro;
while (esquerda > 0 && pesos[esquerda] >= limite) esquerda--;

int direita = centro;
while (direita < pesos.length - 1 && pesos[direita] >= limite) direita++;

final bandejasValidas = direita - esquerda + 1;
final faixaReal = bandejasValidas * espacamento;
```

**Diagnóstico Faixa:**
- ✅ Faixa ≥ esperada → Correto
- ⚠️ Faixa < esperada → Reduzir faixa ou calibrar máquina

---

## 📊 Gráfico de Barras (Visual Técnico)

- Cada barra: uma bandeja (peso em g)
- Linha horizontal da média central
- Linha tracejada de 50% da média
- Cores:
  - 🟦 Dentro da faixa efetiva
  - 🟥 Fora da faixa
- Diagnóstico dinâmico:
  - CV: `12.4%` 🟠 Moderado
  - Faixa efetiva: `30.0 m / 36.0 m`

---

## 🖥️ Layout da Tela (Mobile)

### Header

- `FortSmart` (centralizado, azul elegante `#0057A3`, fonte moderna)

### Formulário

- Fertilizante (dropdown)
- Granulometria
- Faixa esperada (m)
- Espaçamento entre bandejas (m)
- Pesos coletados (lista dinâmica com botão ➕)
- Botão: `[ CALCULAR 📊 ]`

### Resultados

- CV% + diagnóstico com ícone colorido
- Faixa real vs. esperada
- Gráfico interativo com legenda
- Sugestão automática: “Reduzir faixa para 30m”

### Ações

- 💾 Salvar calibração
- 📈 Ver histórico

---

## 🧠 Sugestões Inteligentes (Opcional)

- Número ideal de bandejas: `faixa_esperada / espacamento`
- Alerta se faixa coberta for < 100%
- Diagnóstico final interpretado com recomendações

---
Diagnóstico:

CV ≤ 10% → 🟢 Bom

10% < CV ≤ 15% → 🟠 Moderado

CV > 15% → 🔴 Crítico

2. Faixa Efetiva (baseada nos pesos)
dart
Copiar
Editar
final centro = pesos.length ~/ 2;
final mediaCentral = (pesos[centro - 1] + pesos[centro] + pesos[centro + 1]) / 3;
final limite = mediaCentral * 0.5;

int esquerda = centro;
while (esquerda > 0 && pesos[esquerda] >= limite) esquerda--;

int direita = centro;
while (direita < pesos.length - 1 && pesos[direita] >= limite) direita++;

final bandejasValidas = direita - esquerda + 1;
final faixaReal = bandejasValidas * espacamento;
Diagnóstico faixa:

Faixa real ≥ faixa esperada → ✅ OK

Faixa real < faixa esperada → ⚠️ Ajustar faixa ou máquina

📊 Gráfico de Barras
X = número da bandeja

Y = peso coletado

Elementos visuais:

Linha de média central

Linha de 50% da média (limite de faixa efetiva)

Cores:

🟦 Dentro da faixa

🟥 Fora da faixa

Legendas: CV%, faixa real, status

📲 Interface (UI Mobile)
Nome no topo: FortSmart (centralizado, azul #0057A3)

Botão de calcular: azul escuro com ícone 📊

Campos limpos com labels claras

Resultados destacados com cores + texto + ícones

✅ Resultados Exibidos
Campo	Exemplo	Exibição
CV%	12.4%	🟠 Moderado
Faixa real	30,0 m	⚠️ Atenção: faixa incompleta
Média	145 g	Numérico
Desvio	8,3 g	Numérico
Gráfico	Interativo	Com destaque em extremidades

💾 Histórico e Ações
Cada calibração salva com:

Fertilizante

Máquina (opcional)

Operador

Data/hora

CV%

Faixa efetiva

Gráfico

Exportação PDF

🔐 Observações Técnicas
Validação automática do número mínimo de bandejas

Sugestão de número ideal com base na faixa e espaçamento

Pode ser expandido para sensores no futuro

Suporte offline garantido (SQLite recomendado)



## 💾 Estrutura para Backend (JSON)

```json
{
  "fertilizante": "NPK 20-05-20",
  "granulometria": 950,
  "faixa_esperada": 36.0,
  "espacamento": 1.0,
  "pesos": [152, 148, 141, ..., 136],
  "resultado": {
    "cv": 12.4,
    "cv_status": "Moderado",
    "faixa_real": 30.0,
    "faixa_status": "Incompleta"
  },
  "operador": "Carlos Silva",
  "data": "2025-07-30T15:00:00Z"
}
```

---

## 📁 Histórico da Calibração

Cada item salvo inclui:

- Fertilizante utilizado
- Faixa real x faixa esperada
- CV% e status
- Data/hora e operador
- Gráfico da distribuição
- Exportação em PDF

---

## 📘 Expansões Futuras

- Cálculo de dose kg/ha
- Modo de simulação
---

**FortSmart | Versão Agrícola Premium 🌾**
