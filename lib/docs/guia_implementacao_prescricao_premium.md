# 🔄 Guia de Implementação — Prescrição Premium

## 📋 Visão Geral

Este documento serve como guia completo para implementação do módulo **FortSmart — Prescrição Premium (Cálculo + Estoque)**, substituindo as telas de aplicação atuais.

---

## 🎯 Objetivos do Sistema

- **Cálculo Automático**: Quantidades de produtos por tanque e área
- **Integração com Estoque**: Baixa automática por lote
- **Rastreabilidade**: Histórico completo por talhão
- **Custos**: Cálculo de custos por hectare e total
- **Relatórios**: PDF, compartilhamento e exportação

---

## 🔄 Fluxo de Cálculo — Prescrição Premium

### 1️⃣ Seleção Inicial

**Talhão**: 
- Puxar área cadastrada automaticamente
- Cultura vinculada ao talhão ou escolhida manualmente
- Área de trabalho editável (permite dose fracionada)

**Data da aplicação**: Preenchida pelo usuário

**Tipo de aplicação**: 
- 🚜 Terrestre
- ✈️ Aérea  
- 🚁 Drone

### 2️⃣ Informações do Produto

**Produto(s) utilizado(s)**: 
- Um ou mais produtos por aplicação
- Dose por hectare (L/ha ou Kg/ha)
- Tipo de produto (inseticida, herbicida, fungicida, adubo foliar)
- Lote do produto (para rastreabilidade)

### 3️⃣ Área de Cálculo

**Área total do talhão**: Importada automaticamente

**Área personalizada**: Manual, permite dose fracionada ou parcial

**📌 Fórmula Básica**:
```
Quantidade total = Dose (L/ha ou Kg/ha) × Área (ha)
```

### 4️⃣ Tanque de Aplicação

**Capacidade do tanque (L)**: Definida pelo usuário

**Volume de segurança (L)**: Reserva para evitar problemas

**Capacidade efetiva**: Tanque - Segurança

**📌 Fórmula**:
```
Capacidade Efetiva = Capacidade Tanque - Volume Segurança
```

### 5️⃣ Calibração do Equipamento

#### Aplicação Terrestre:
- **Número de bicos ativos**
- **Espaçamento entre bicos (m)**
- **Largura de barra (m)** = Nº bicos × Espaçamento
- **Velocidade (km/h)**
- **Vazão por bico (L/min)**

**📌 Fórmula Vazão Real**:
```
Vazão (L/ha) = (600 × Vazão por bico (L/min)) ÷ (Espaçamento entre bicos (m) × Velocidade (km/h))
```

#### Aplicação Aérea:
- **Faixa de aplicação (m)**
- **Velocidade (km/h)**
- **Vazão total (L/min)**

**📌 Fórmula Vazão Real**:
```
Vazão (L/ha) = (600 × Vazão total (L/min)) ÷ (Faixa (m) × Velocidade (km/h))
```

### 6️⃣ Mistura do Produto no Tanque

**Ha por tanque**:
```
Ha por tanque = Capacidade Efetiva (L) ÷ Vazão (L/ha)
```

**Número de tanques**:
```
Nº de tanques = teto(Área total ÷ Ha por tanque)
```

**Produto por tanque**:
```
Produto por tanque = Dose (L/ha ou Kg/ha) × Ha por tanque
```

**Volume de calda por tanque**: Soma da água + produtos

### 7️⃣ Resultado Final

✅ **Quantidade total** de cada produto para a área selecionada
✅ **Quantidade de calda total** (água + produto)
✅ **Quantidade de produto por tanque**
✅ **Quantidade de tanques necessários**
✅ **Resumo por produto** (para aplicações com múltiplos produtos)

---

## 🏗️ Arquitetura de Implementação

### 📁 Estrutura de Arquivos

```
lib/
├── models/
│   ├── prescricao_model.dart ✅ (IMPLEMENTADO)
│   └── calibracao_model.dart ✅ (IMPLEMENTADO)
├── services/
│   ├── prescricao_calculo_service.dart ✅ (IMPLEMENTADO)
│   └── prescricao_estoque_service.dart ❌ (PENDENTE)
├── repositories/
│   ├── prescricao_repository.dart ✅ (IMPLEMENTADO)
│   └── estoque_repository.dart ❌ (PENDENTE)
├── screens/
│   └── prescricao/
│       ├── prescricao_premium_screen.dart ✅ (BÁSICO)
│       ├── calibracao_screen.dart ❌ (PENDENTE)
│       ├── produtos_screen.dart ❌ (PENDENTE)
│       └── resultados_screen.dart ❌ (PENDENTE)
└── utils/
    ├── prescricao_formulas.dart ❌ (PENDENTE)
    └── prescricao_validators.dart ❌ (PENDENTE)
```

### 🔧 Componentes Principais

#### 1. **PrescricaoModel** ✅
- Dados da prescrição
- Calibração
- Produtos
- Resultados calculados
- Totais

#### 2. **PrescricaoCalculoService** ✅
- Cálculo de resultados básicos
- Cálculo de produtos por tanque
- Cálculo de totais e custos
- Validação de calibração

#### 3. **PrescricaoRepository** ✅
- CRUD de prescrições
- Busca por talhão, status, período
- Estatísticas

---

## 📊 Fórmulas Detalhadas

### Geometria e Volume

```dart
// Largura de barra (m)
double larguraCalculadaM = bicosAtivos * espacamentoM;

// Volume teórico (L/ha)
double calcularVolumeTeoricoLHa() {
  if (vazaoTotalLMin <= 0 || velocidadeKmh <= 0 || larguraM <= 0) {
    return 0;
  }
  return (600 * vazaoTotalLMin) / (velocidadeKmh * larguraM);
}

// Vazão por bico necessária (L/min)
double calcularVazaoBicoNecessariaLMin(double volumeAlvoLHa) {
  if (velocidadeKmh <= 0 || espacamentoM <= 0) {
    return 0;
  }
  return (volumeAlvoLHa * velocidadeKmh * espacamentoM) / 600;
}
```

### Produtos

```dart
// Ha por tanque
double haPorTanque = capacidadeEfetivaL / volumeLHa;

// Número de tanques (arredondado para cima)
int numeroTanques = (areaTrabalhoHa / haPorTanque).ceil();

// Quantidade total do produto
double quantidadeTotal = dosePorHa * areaTrabalhoHa;

// Quantidade por tanque
double quantidadePorTanque = dosePorHa * haPorTanque;

// Adjuvante % v/v por tanque
double adjuvantePorTanque = (percentualVv / 100) * volumeCaldaPorTanqueL;
```

### Tempo e Produtividade

```dart
// Tempo por tanque (min)
double tempoPorTanqueMin = capacidadeEfetivaL / vazaoTotalLMin;

// Capacidade de campo (ha/h)
double capacidadeCampoHaH = (velocidadeKmh * larguraM) / 10 * eficienciaCampo;

// Tempo total (h)
double tempoTotalH = areaTrabalhoHa / capacidadeCampoHaH;
```

---

## 🚧 Implementações Pendentes

### 1. **Tela de Calibração** ❌
```dart
// lib/screens/prescricao/calibracao_screen.dart
class CalibracaoScreen extends StatefulWidget {
  // Configuração de equipamento
  // Modo de cálculo (vazão por bico vs volume alvo)
  // Validação de calibração
}
```

### 2. **Tela de Produtos** ❌
```dart
// lib/screens/prescricao/produtos_screen.dart
class ProdutosScreen extends StatefulWidget {
  // Seleção de produtos
  // Configuração de doses
  // Verificação de estoque
  // Cálculo de custos
}
```

### 3. **Tela de Resultados** ❌
```dart
// lib/screens/prescricao/resultados_screen.dart
class ResultadosScreen extends StatefulWidget {
  // Exibição de resultados
  // KPIs principais
  // Gráficos e visualizações
  // Ações (PDF, compartilhar, finalizar)
}
```

### 4. **Serviço de Estoque** ❌
```dart
// lib/services/prescricao_estoque_service.dart
class PrescricaoEstoqueService {
  // Verificação de disponibilidade
  // Reserva de produtos
  // Baixa automática
  // Alertas de estoque baixo
}
```

### 5. **Utilitários de Fórmulas** ❌
```dart
// lib/utils/prescricao_formulas.dart
class PrescricaoFormulas {
  // Todas as fórmulas centralizadas
  // Conversões de unidades
  // Validações matemáticas
}
```

---

## 🔍 Validações Necessárias

### Campos Obrigatórios
- [ ] Talhão selecionado
- [ ] Data da aplicação
- [ ] Tipo de aplicação
- [ ] Volume L/ha
- [ ] Capacidade de tanque
- [ ] Pelo menos 1 produto

### Coerência de Dados
- [ ] Largura > 0
- [ ] Nº bicos ≥ 1
- [ ] Vazão por bico > 0
- [ ] Velocidade dentro de 3–18 km/h (terrestre)
- [ ] Volume calculado vs alvo (diferença ≤ 3%)

### Estoque
- [ ] Verificação de disponibilidade
- [ ] Alertas de estoque insuficiente
- [ ] Opções: reservar parcial, trocar lote, substituir produto

### PHI/REI
- [ ] Verificação de carência
- [ ] Verificação de reentrada
- [ ] Alertas de conflito com colheita

---

## 📱 Interface do Usuário

### Header Principal
- [ ] Informações do talhão
- [ ] Status da prescrição
- [ ] Botões de ação (Salvar, Calcular, PDF)

### Abas de Navegação
- [ ] **Geral**: Talhão, data, tipo, volume ✅
- [ ] **Calibração**: Equipamento e parâmetros ❌
- [ ] **Produtos**: Seleção e configuração ❌
- [ ] **Resultados**: Cálculos e KPIs ❌

### KPIs Principais
- [ ] Ha/tanque
- [ ] Nº de cargas
- [ ] Tempo total
- [ ] Custo/ha
- [ ] Custo total

---

## 🔄 Fluxo de Estados

### Status da Prescrição
1. **Rascunho**: Dados básicos preenchidos
2. **Calculada**: Cálculos realizados com sucesso
3. **Finalizada**: Pronta para execução
4. **Executada**: Aplicação concluída

### Transições
```
Rascunho → Calculada (após cálculo)
Calculada → Finalizada (após validação)
Finalizada → Executada (após aplicação)
```

---

## 📊 Integração com Estoque

### Verificação de Disponibilidade
```dart
// Verificar estoque por produto
bool temEstoqueSuficiente = estoqueDisponivel >= quantidadeTotal;

// Alertas de estoque baixo
if (estoqueDisponivel < quantidadeTotal * 1.2) {
  // Mostrar alerta
}
```

### Baixa Automática
```dart
// Ao finalizar prescrição
await estoqueService.baixarProduto(
  produtoId: produto.id,
  loteId: produto.loteId,
  quantidade: produto.quantidadeTotal,
  prescricaoId: prescricao.id,
);
```

---

## 📄 Geração de Relatórios

### PDF da Prescrição
- [ ] Cabeçalho com dados do talhão
- [ ] Parâmetros de aplicação
- [ ] Lista de produtos por tanque
- [ ] Resultados calculados
- [ ] QR Code para rastreabilidade
- [ ] Assinatura do responsável técnico

### Compartilhamento
- [ ] WhatsApp
- [ ] Email
- [ ] Impressão
- [ ] Exportação CSV/JSON

---

## 🧪 Testes Necessários

### Testes Unitários
- [ ] Fórmulas de cálculo
- [ ] Validações
- [ ] Conversões de unidades

### Testes de Integração
- [ ] Fluxo completo de prescrição
- [ ] Integração com estoque
- [ ] Geração de PDF

### Testes de Interface
- [ ] Navegação entre abas
- [ ] Validação de formulários
- [ ] Responsividade

---

## 📝 Checklist de Implementação

### Fase 1: Estrutura Básica ✅
- [x] Modelos de dados
- [x] Serviço de cálculo
- [x] Repositório
- [x] Tela básica

### Fase 2: Funcionalidades Core ❌
- [ ] Tela de calibração
- [ ] Tela de produtos
- [ ] Tela de resultados
- [ ] Validações completas

### Fase 3: Integrações ❌
- [ ] Serviço de estoque
- [ ] Geração de PDF
- [ ] Compartilhamento
- [ ] Sincronização

### Fase 4: Refinamentos ❌
- [ ] UX/UI premium
- [ ] Performance
- [ ] Testes
- [ ] Documentação

---

## 🎯 Próximos Passos

1. **Implementar tela de calibração** com formulário completo
2. **Criar tela de produtos** com seleção e configuração
3. **Desenvolver tela de resultados** com KPIs e visualizações
4. **Integrar com estoque** para verificação e baixa automática
5. **Implementar geração de PDF** com layout profissional
6. **Adicionar validações** completas e feedback ao usuário
7. **Otimizar performance** e experiência do usuário

---

## 📞 Suporte e Manutenção

Este guia deve ser atualizado conforme o desenvolvimento avança. Mantenha sempre as fórmulas e validações documentadas para facilitar futuras manutenções e correções.

**Última atualização**: Dezembro 2024
**Versão**: 1.0
**Status**: Em desenvolvimento
