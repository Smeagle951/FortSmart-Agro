# 🎯 PLANO DE ANÁLISE: 8 MÓDULOS CRÍTICOS

## 📋 **OBJETIVO**
Verificar a integridade e funcionalidade de salvamento de TODOS os módulos críticos do FortSmart Agro, garantindo que não existem FOREIGN KEYS problemáticas ou erros de schema que impeçam o salvamento.

---

## 🔍 **METODOLOGIA DE ANÁLISE**

Para cada módulo, será verificado:

### **1. Estrutura de Banco de Dados**
- ✅ Schema da tabela no `app_database.dart`
- ✅ Verificar FOREIGN KEYS (identificar problemáticas)
- ✅ Verificar tipos de dados (TEXT, INTEGER, REAL)
- ✅ Verificar campos obrigatórios (NOT NULL)

### **2. Modelos (Models)**
- ✅ Campos do modelo vs campos da tabela
- ✅ Métodos `toMap()` e `fromMap()`
- ✅ Conversão de tipos (DateTime, JSON, etc)
- ✅ Validações de dados

### **3. Repositórios (Repositories)**
- ✅ Método `insert()` / `create()` / `save()`
- ✅ Tratamento de erros
- ✅ Logs de debug
- ✅ Transações SQL

### **4. Telas (Screens)**
- ✅ Coleta de dados dos formulários
- ✅ Chamada ao repository
- ✅ Feedback ao usuário (sucesso/erro)
- ✅ Navegação pós-salvamento

---

## 📊 **MÓDULOS A SEREM ANALISADOS**

### **1. 🗺️ TALHÕES**
**Prioridade:** 🔴 CRÍTICA (Base para outros módulos)
**Tabelas:**
- `talhoes`
- `poligonos`
- `safras`

**Verificar:**
- ✅ Criação de talhão
- ✅ Desenho de polígonos
- ✅ Associação com safras
- ⚠️ FOREIGN KEY em `poligonos` (idTalhao → talhoes)

---

### **2. 🧪 CALDA FLEX**
**Prioridade:** 🟡 ALTA
**Tabelas:**
- `calda_flex_products`
- `calda_flex_mixtures`
- `calda_flex_mixture_products`

**Verificar:**
- ✅ Cadastro de produtos
- ✅ Criação de caldas
- ✅ Associação produto-calda
- ⚠️ FOREIGN KEYS entre tabelas

---

### **3. 🌾 COLHEITA**
**Prioridade:** 🟡 ALTA
**Tabelas:**
- `colheitas` ou `harvests`

**Verificar:**
- ✅ Registro de colheita
- ✅ Associação com talhão
- ✅ Dados de produtividade
- ⚠️ FOREIGN KEY de talhão

---

### **4. 🔍 MONITORAMENTO**
**Prioridade:** 🔴 CRÍTICA (Já corrigido parcialmente)
**Tabelas:**
- `monitorings`
- `pontos_monitoramento`
- `monitoring_occurrences`

**Verificar:**
- ✅ Criação de monitoramento
- ✅ Pontos de monitoramento
- ✅ Registro de ocorrências
- ⚠️ FOREIGN KEYS (já removidas em monitorings)

---

### **5. 📦 ESTOQUE DE PRODUTOS**
**Prioridade:** 🟡 ALTA
**Tabelas:**
- `inventory_products`
- `inventory_movements`
- `inventory_transactions`

**Verificar:**
- ✅ Cadastro de produtos
- ✅ Movimentações de estoque
- ✅ Histórico de transações
- ⚠️ FOREIGN KEYS entre tabelas

---

### **6. 💰 GESTÃO DE CUSTO**
**Prioridade:** 🟢 MÉDIA
**Tabelas:**
- `cost_entries`
- `cost_categories`
- `cost_budgets`

**Verificar:**
- ✅ Registro de custos
- ✅ Categorias
- ✅ Orçamentos
- ⚠️ FOREIGN KEYS

---

### **7. ⚗️ CALIBRAÇÃO DE FERTILIZANTE**
**Prioridade:** 🟢 MÉDIA
**Tabelas:**
- `fertilizer_calibrations`
- `calibration_history`

**Verificar:**
- ✅ Cadastro de calibrações
- ✅ Histórico
- ✅ Cálculos
- ⚠️ FOREIGN KEYS

---

### **8. 🌱 CÁLCULOS DE SOLOS**
**Prioridade:** 🟢 MÉDIA
**Tabelas:**
- `soil_analyses`
- `soil_recommendations`
- `soil_samples`

**Verificar:**
- ✅ Análises de solo
- ✅ Recomendações
- ✅ Amostras
- ⚠️ FOREIGN KEYS

---

## 🔧 **AÇÕES CORRETIVAS PLANEJADAS**

### **Se encontrar FOREIGN KEYS problemáticas:**
1. ✅ Identificar a dependência
2. ✅ Avaliar se é ESSENCIAL ou OPCIONAL
3. ✅ Se OPCIONAL: Remover
4. ✅ Se ESSENCIAL: Garantir IDs consistentes
5. ✅ Criar migração para corrigir

### **Se encontrar problemas de schema:**
1. ✅ Comparar modelo vs tabela
2. ✅ Identificar campos faltantes
3. ✅ Criar migração para adicionar
4. ✅ Atualizar modelo se necessário

### **Se encontrar problemas de repository:**
1. ✅ Verificar método insert()
2. ✅ Adicionar logs de debug
3. ✅ Adicionar tratamento de erros
4. ✅ Testar salvamento

---

## 📈 **ORDEM DE EXECUÇÃO**

### **FASE 1: Módulos Críticos (Prioridade 🔴)**
1. TALHÕES
2. MONITORAMENTO

### **FASE 2: Módulos de Alta Prioridade (Prioridade 🟡)**
3. CALDA FLEX
4. COLHEITA
5. ESTOQUE DE PRODUTOS

### **FASE 3: Módulos de Média Prioridade (Prioridade 🟢)**
6. GESTÃO DE CUSTO
7. CALIBRAÇÃO DE FERTILIZANTE
8. CÁLCULOS DE SOLOS

---

## 📊 **RELATÓRIO FINAL**

Ao final, será gerado:
- ✅ Lista de todos os problemas encontrados
- ✅ Todas as correções aplicadas
- ✅ Migrações criadas
- ✅ Checklist de testes
- ✅ Recomendações futuras

---

## 🚀 **INÍCIO DA ANÁLISE**

**Status:** 🔄 **EM ANDAMENTO**
**Data:** 17/10/2025
**Analista:** Desenvolvedor Senior Flutter/Dart

**Vamos começar! 🎯**
