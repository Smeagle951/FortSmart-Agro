# 🎯 Plano de Integração de Custos - FortSmart Agro

## 📋 Visão Geral

Este documento detalha a implementação da integração de custos entre os módulos do FortSmart Agro, transformando o **Módulo Estoque** no ponto central de cálculo de custo, com o **Histórico de Talhões** como centralizador dos relatórios financeiros.

## 🏗️ Arquitetura Proposta

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MÓDULO ESTOQUE │    │  MÓDULO HISTÓRICO │    │  MÓDULOS OPERAÇÃO │
│   (Coração do    │    │   DE TALHÕES     │    │  (Plantio, Aplic. │
│     Custo)       │    │  (Centralizador) │    │   Fertilizante)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
   • Valor unitário        • Cálculo custo/ha      • Registro de uso
   • Custo total lote      • Relatórios            • Dose aplicada
   • Custo por hectare     • Gráficos              • Área do talhão
   • Importação em lote    • Filtros               • Data operação
```

## 1️⃣ MÓDULO ESTOQUE (Coração do Custo)

### 📊 Estrutura de Dados Atualizada

```dart
class StockProduct {
  final int id;
  final String name;
  final String category; // semente, herbicida, fertilizante, etc.
  final String unit; // kg, L, saca, mL
  final double availableQuantity;
  final double unitValue; // R$
  final double totalLotValue; // calculado: quantidade × valor_unitario
  final double costPerHectare; // calculado dinamicamente
  
  // Campos extras para profissionalização
  final String? supplier;
  final String? lotNumber;
  final String? storageLocation;
  final DateTime? expirationDate;
  final String? observations;
}
```

### 🆕 Funcionalidades Novas

#### 1.1 Tela de Custo por Hectare no Estoque
- **Localização**: `lib/modules/stock/screens/stock_cost_per_hectare_screen.dart`
- **Funcionalidades**:
  - Lista de produtos com custo/ha calculado
  - Filtros por categoria
  - Ordenação por custo
  - Exportação para PDF/Excel

#### 1.2 Importação em Lote
- **Localização**: `lib/modules/stock/services/stock_import_service.dart`
- **Funcionalidades**:
  - Upload de arquivo .xlsx
  - Validação de dados
  - Modelo disponível para download
  - Log de importação

#### 1.3 Integração Automática
- **Localização**: `lib/modules/stock/services/stock_cost_calculation_service.dart`
- **Funcionalidades**:
  - Cálculo automático de custo/ha
  - Notificação quando produto sai do estoque
  - Sincronização com operações

### 🔄 API do Módulo Estoque

```dart
// GET /estoque/produtos
Future<List<StockProduct>> getStockProducts();

// POST /estoque/importar
Future<bool> importStockFromExcel(File file);

// GET /estoque/produtos/:id
Future<StockProduct> getStockProduct(int id);

// POST /estoque/calcular-custo-ha
Future<double> calculateCostPerHectare(int productId, double dose, double area);
```

## 2️⃣ MÓDULOS DE OPERAÇÃO (Plantio, Aplicação, Fertilizantes)

### 📝 Dados que Devem Enviar

```dart
class OperationData {
  final int operationId;
  final int talhaoId;
  final int productId;
  final double dose; // ex.: 2 L/ha
  final double talhaoArea; // ha
  final double totalQuantity; // dose × área
  final String operationType; // aplicação, plantio, adubação
  final DateTime operationDate;
  final double? costPerHectare; // calculado pelo estoque
  final double? totalCost; // calculado pelo estoque
}
```

### 🔄 Integração com Estoque

```dart
// Quando uma operação é registrada
Future<void> registerOperation(OperationData operation) async {
  // 1. Salva a operação
  await operationRepository.save(operation);
  
  // 2. Solicita cálculo de custo ao estoque
  final costData = await stockService.calculateOperationCost(
    productId: operation.productId,
    dose: operation.dose,
    area: operation.talhaoArea,
  );
  
  // 3. Atualiza a operação com os custos
  operation.costPerHectare = costData.costPerHectare;
  operation.totalCost = costData.totalCost;
  
  // 4. Envia dados para o histórico
  await historyService.recordOperationCost(operation);
}
```

## 3️⃣ MÓDULO HISTÓRICO DE TALHÕES (Centralizador)

### 📊 Estrutura de Dados

```dart
class TalhaoCostHistory {
  final int talhaoId;
  final String talhaoName;
  final String safra;
  final List<OperationCost> operations;
  final double totalCost;
  final double totalArea;
  final double averageCostPerHectare;
}

class OperationCost {
  final int operationId;
  final String operationType;
  final String productName;
  final double quantity;
  final double costPerHectare;
  final double totalCost;
  final DateTime date;
}
```

### 🆕 Funcionalidades Novas

#### 3.1 Tela de Custo por Aplicação
- **Localização**: `lib/modules/farm_history/screens/talhao_cost_screen.dart`
- **Funcionalidades**:
  - Lista de produtos utilizados por talhão
  - Quantidade usada e custo total
  - Custo/ha calculado
  - Filtros por talhão, operação, período

#### 3.2 Relatórios Avançados
- **Localização**: `lib/modules/farm_history/screens/cost_reports_screen.dart`
- **Funcionalidades**:
  - Tabela detalhada de custos
  - Gráfico de pizza (custo por categoria)
  - Gráfico de barras (custo por talhão/safra)
  - Exportação para PDF/Excel

### 🔄 API do Módulo Histórico

```dart
// POST /historico/custos
Future<void> recordOperationCost(OperationData operation);

// GET /historico/talhao/:id/custos
Future<TalhaoCostHistory> getTalhaoCostHistory(int talhaoId);

// GET /historico/relatorios
Future<CostReport> getCostReports({
  int? talhaoId,
  String? operationType,
  DateTime? startDate,
  DateTime? endDate,
});
```

## 4️⃣ FLUXO DE INTEGRAÇÃO

### 📈 Exemplo Prático

**Cenário**: Aplicação de Glifosato no Talhão A

1. **Estoque**:
   - Glifosato: R$ 12,50/L
   - Quantidade disponível: 500L

2. **Aplicação registra**:
   - Talhão A (50 ha)
   - Dose: 2 L/ha
   - Produto: Glifosato

3. **Sistema calcula**:
   - Quantidade usada: 100 L
   - Custo total: 100 × R$ 12,50 = R$ 1.250
   - Custo/ha: R$ 25,00/ha

4. **Histórico salva**:
   - Talhão A → operação "Aplicação" → custo R$ 1.250 (R$ 25,00/ha)

5. **Relatório mostra**:
   - Custos por operação, talhão, safra

## 5️⃣ IMPLEMENTAÇÃO TÉCNICA

### 📁 Estrutura de Arquivos

```
lib/modules/
├── stock/
│   ├── screens/
│   │   ├── stock_cost_per_hectare_screen.dart
│   │   └── stock_import_screen.dart
│   ├── services/
│   │   ├── stock_cost_calculation_service.dart
│   │   └── stock_import_service.dart
│   └── models/
│       └── stock_product.dart
├── farm_history/
│   ├── screens/
│   │   ├── talhao_cost_screen.dart
│   │   └── cost_reports_screen.dart
│   ├── services/
│   │   └── cost_history_service.dart
│   └── models/
│       ├── talhao_cost_history.dart
│       └── operation_cost.dart
└── shared/
    ├── models/
    │   └── operation_data.dart
    └── services/
        └── cost_integration_service.dart
```

### 🔧 Serviços de Integração

```dart
// lib/modules/shared/services/cost_integration_service.dart
class CostIntegrationService {
  // Calcula custo de uma operação
  Future<CostCalculation> calculateOperationCost(OperationData operation);
  
  // Registra custo no histórico
  Future<void> recordCostInHistory(OperationData operation, CostCalculation cost);
  
  // Gera relatórios
  Future<CostReport> generateCostReport(CostReportFilters filters);
}
```

## 6️⃣ CRONOGRAMA DE IMPLEMENTAÇÃO

### 🗓️ Fase 1 (Semana 1-2): Módulo Estoque
- [ ] Atualizar modelo de dados do estoque
- [ ] Implementar cálculo de custo/ha
- [ ] Criar tela de custo por hectare
- [ ] Implementar importação em lote

### 🗓️ Fase 2 (Semana 3-4): Integração
- [ ] Criar serviço de integração de custos
- [ ] Atualizar módulos de operação
- [ ] Implementar comunicação entre módulos
- [ ] Testes de integração

### 🗓️ Fase 3 (Semana 5-6): Histórico e Relatórios
- [ ] Implementar módulo de histórico
- [ ] Criar telas de relatórios
- [ ] Implementar gráficos
- [ ] Testes finais

## 7️⃣ BENEFÍCIOS ESPERADOS

### 📊 Para o Usuário
- **Visibilidade total** dos custos por talhão
- **Relatórios profissionais** de custos
- **Controle financeiro** preciso
- **Tomada de decisão** baseada em dados

### 🔧 Para o Sistema
- **Centralização** do cálculo de custos
- **Consistência** dos dados
- **Escalabilidade** para novos módulos
- **Manutenibilidade** melhorada

## 8️⃣ PRÓXIMOS PASSOS

1. **Revisar** este plano com a equipe
2. **Definir** prioridades de implementação
3. **Criar** tarefas no sistema de gerenciamento
4. **Iniciar** desenvolvimento da Fase 1
5. **Estabelecer** métricas de sucesso

---

**📝 Nota**: Este plano pode ser ajustado conforme feedback da equipe e necessidades específicas do projeto.
