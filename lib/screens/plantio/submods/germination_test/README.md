# 🌱 Módulo de Teste de Germinação - FortSmart Agro

## 📋 Visão Geral

O módulo de Teste de Germinação do FortSmart implementa funcionalidades completas para testes de germinação seguindo metodologias agronômicas (ABNT NBR 9787) e protocolos de pesquisa. Suporta testes individuais e até 3 subtestes comparativos (A, B, C) dentro de um mesmo experimento.

## 🎯 Funcionalidades Principais

### ✅ Testes de Germinação
- **Teste Individual**: 100 sementes em uma única posição
- **Teste com Subtestes**: Até 3 subtestes independentes (A, B, C)
- **Registro Diário**: Contagem diária de germinadas, anormais, doentes
- **Cálculos Agronômicos**: Percentual de germinação, vigor, pureza, contaminação
- **Classificação Automática**: Excelente, Boa, Regular, Baixa

### ✅ Metodologia ABNT NBR 9787
- **Germinação Acumulada**: Cálculo correto seguindo normas
- **Vigor**: Germinação até 5º ou 7º dia (configurável)
- **Pureza**: Cálculo de sementes puras vs impurezas
- **Contaminação**: Fungos e bactérias acumulados
- **Tempo Médio**: Cálculo do tempo médio de germinação

### ✅ Interface Elegante
- **Design FortSmart**: Seguindo padrão visual do sistema
- **Animações Suaves**: Transições elegantes
- **Responsivo**: Adaptável a diferentes telas
- **Acessível**: Interface intuitiva e fácil de usar

## 📁 Estrutura do Módulo

```
lib/modules/germination_test/
├── models/
│   └── germination_test_model.dart          # Modelos de dados
├── database/
│   ├── germination_database.dart           # Estrutura do banco
│   └── daos/
│       ├── germination_test_dao.dart       # DAO para testes
│       ├── germination_subtest_dao.dart    # DAO para subtestes
│       └── germination_daily_record_dao.dart # DAO para registros
├── services/
│   └── germination_calculation_service.dart # Cálculos agronômicos
├── providers/
│   └── germination_test_provider.dart      # Gerenciamento de estado
├── screens/
│   ├── germination_main_screen.dart        # Tela principal
│   ├── germination_test_create_screen.dart # Criação de testes
│   ├── germination_test_list_screen.dart   # Lista de testes
│   ├── germination_test_settings_screen.dart # Configurações
│   └── widgets/
│       ├── germination_test_type_selector.dart
│       ├── germination_basic_info_form.dart
│       ├── germination_test_card.dart
│       ├── germination_search_widget.dart
│       └── germination_filter_widget.dart
└── widgets/
    ├── germination_stats_widget.dart       # Estatísticas
    ├── germination_quick_actions_widget.dart # Ações rápidas
    └── germination_recent_tests_widget.dart # Testes recentes
```

## 🔧 Modelos de Dados

### GerminationTest
```dart
class GerminationTest {
  final int? id;
  final String culture;                    // Cultura (Soja, Milho, etc.)
  final String variety;                    // Variedade
  final String seedLot;                    // Lote de sementes
  final int totalSeeds;                    // Total de sementes
  final DateTime startDate;                // Data de início
  final bool hasSubtests;                  // Se tem subtestes
  final int subtestSeedCount;              // Sementes por subteste
  final String? subtestNames;              // Nomes dos subtestes (A, B, C)
  final String? position;                  // Posição no canteiro
  final double? finalGerminationPercentage; // Resultado final
  // ... outros campos
}
```

### GerminationSubtest
```dart
class GerminationSubtest {
  final int? id;
  final int germinationTestId;            // ID do teste principal
  final String subtestCode;                // Código (A, B, C)
  final String subtestName;                // Nome do subteste
  final int seedCount;                     // Quantidade de sementes
  final String status;                     // Status (active, completed)
  // ... outros campos
}
```

### GerminationDailyRecord
```dart
class GerminationDailyRecord {
  final int? id;
  final int germinationTestId;            // ID do teste
  final int? subtestId;                   // ID do subteste (se aplicável)
  final int day;                          // Dia do registro
  final DateTime recordDate;              // Data do registro
  final int normalGerminated;             // Germinadas normais
  final int abnormalGerminated;           // Germinadas anormais
  final int diseasedFungi;                // Doentes (fungos)
  final int diseasedBacteria;             // Doentes (bactérias)
  final int notGerminated;                // Não germinadas
  final int otherSeeds;                   // Outras sementes
  final int inertMatter;                  // Matéria inerte
  // ... outros campos
}
```

## 🧮 Cálculos Agronômicos

### Percentual de Germinação
```dart
// ABNT NBR 9787: Germinação = (Normais acumuladas / Total) × 100
double calculateGerminationPercentage(int normalGerminated, int totalSeeds) {
  if (totalSeeds <= 0) return 0.0;
  return (normalGerminated / totalSeeds) * 100;
}
```

### Vigor
```dart
// Vigor = Germinação até X dias (padrão: 5 dias)
double calculateVigor(List<GerminationDailyRecord> records, int totalSeeds, {int vigorDays = 5}) {
  // Filtrar registros até o limite de dias
  final vigorRecords = records.where((r) => r.day <= vigorDays).toList();
  // Calcular total acumulado
  int totalVigor = 0;
  for (final record in vigorRecords) {
    totalVigor += record.normalGerminated + record.abnormalGerminated;
  }
  return (totalVigor / totalSeeds) * 100;
}
```

### Contaminação
```dart
// Contaminação = (Fungos + Bactérias / Total) × 100
double calculateContaminationPercentage(List<GerminationDailyRecord> records, int totalSeeds) {
  int totalContamination = 0;
  for (final record in records) {
    totalContamination += record.diseasedFungi + record.diseasedBacteria;
  }
  return (totalContamination / totalSeeds) * 100;
}
```

### Pureza
```dart
// Pureza = ((Total - Outras - Inertes) / Total) × 100
double calculatePurityPercentage(List<GerminationDailyRecord> records, int totalSeeds) {
  int totalImpurities = 0;
  for (final record in records) {
    totalImpurities += record.otherSeeds + record.inertMatter;
  }
  final pureSeeds = totalSeeds - totalImpurities;
  return (pureSeeds / totalSeeds) * 100;
}
```

## 🎨 Interface do Usuário

### Tela Principal
- **Header Elegante**: Gradiente com informações do módulo
- **Estatísticas**: Cards com métricas principais
- **Ações Rápidas**: Botões para funcionalidades principais
- **Testes Recentes**: Lista dos últimos testes
- **Funcionalidades Avançadas**: Grid com opções adicionais

### Criação de Teste
- **Seletor de Tipo**: Individual ou com subtestes
- **Formulário Básico**: Cultura, variedade, lote, datas
- **Configuração de Subtestes**: Posições A, B, C
- **Seletor de Canteiro**: Posicionamento visual
- **Validação**: Campos obrigatórios e validações

### Lista de Testes
- **Busca Avançada**: Por cultura, variedade, lote, data
- **Filtros**: Status, cultura, período
- **Cards Elegantes**: Informações resumidas
- **Ações**: Ver detalhes, editar, excluir
- **Ordenação**: Por data, cultura, germinação

## 🗄️ Banco de Dados

### Tabelas Principais
```sql
-- Testes de germinação
CREATE TABLE germination_tests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  culture TEXT NOT NULL,
  variety TEXT NOT NULL,
  seedLot TEXT NOT NULL,
  totalSeeds INTEGER NOT NULL,
  startDate TEXT NOT NULL,
  hasSubtests INTEGER NOT NULL DEFAULT 0,
  subtestSeedCount INTEGER NOT NULL DEFAULT 100,
  -- ... outros campos
);

-- Subtestes
CREATE TABLE germination_subtests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  germinationTestId INTEGER NOT NULL,
  subtestCode TEXT NOT NULL,
  subtestName TEXT NOT NULL,
  seedCount INTEGER NOT NULL,
  -- ... outros campos
);

-- Registros diários
CREATE TABLE germination_daily_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  germinationTestId INTEGER NOT NULL,
  subtestId INTEGER,
  day INTEGER NOT NULL,
  normalGerminated INTEGER NOT NULL,
  abnormalGerminated INTEGER NOT NULL,
  diseasedFungi INTEGER NOT NULL,
  -- ... outros campos
);
```

## ⚙️ Configurações

### Limites de Aprovação
- **Limite de Aprovação**: 80% (configurável)
- **Limite de Alerta**: 70% (configurável)
- **Limite de Doenças**: 10% (configurável)

### Automação
- **Alertas Automáticos**: Gerar alertas para germinação baixa
- **Aprovação Automática**: Aprovar lotes automaticamente

### Padrões
- **Quantidade de Sementes**: 100 (configurável)
- **Dias para Vigor**: 5 (configurável)
- **Temperatura**: 25°C (configurável)
- **Umidade**: 60% (configurável)

## 📊 Relatórios

### Relatório Individual
- Informações do teste
- Registros diários detalhados
- Gráfico de evolução
- Resultados finais
- Classificação

### Relatório Consolidado (Subtestes)
- Resultados por subteste (A, B, C)
- Média consolidada
- Comparação entre subtestes
- Recomendações agronômicas

## 🔄 Integração

### Módulo de Plantio
- Sincronização de resultados
- Alertas de densidade
- Aprovação de lotes

### Sistema de Canteiros
- Posicionamento visual
- Gestão de espaços
- Mapeamento de testes

## 🚀 Como Usar

### 1. Criar Teste
1. Acesse o módulo de germinação
2. Clique em "Novo Teste"
3. Escolha tipo (Individual ou Subtestes)
4. Preencha informações básicas
5. Configure subtestes (se aplicável)
6. Selecione posição no canteiro
7. Clique em "Criar Teste"

### 2. Registrar Dados Diários
1. Acesse o teste criado
2. Clique em "Registrar"
3. Escolha o subteste (se aplicável)
4. Preencha dados do dia
5. Salve o registro

### 3. Visualizar Resultados
1. Acesse a lista de testes
2. Clique no teste desejado
3. Visualize resultados e gráficos
4. Exporte relatórios

## 🎯 Benefícios

### Para o Agricultor
- **Precisão**: Testes seguindo normas agronômicas
- **Eficiência**: Interface intuitiva e rápida
- **Confiabilidade**: Cálculos automáticos e precisos
- **Rastreabilidade**: Histórico completo dos testes

### Para o Agrónomo
- **Metodologia**: ABNT NBR 9787 implementada
- **Flexibilidade**: Testes individuais e comparativos
- **Análise**: Relatórios detalhados e gráficos
- **Integração**: Sincronização com outros módulos

## 🔮 Próximas Funcionalidades

- **Dashboard Avançado**: Gráficos de evolução
- **Captura de Fotos**: Vinculação de imagens aos registros
- **Exportação**: PDF e Excel dos relatórios
- **Sincronização**: Cloud e backup automático
- **IA**: Predição de germinação baseada em histórico

## 📞 Suporte

Para dúvidas ou sugestões sobre o módulo de germinação:
- **Documentação**: Este arquivo README
- **Código**: Comentários detalhados no código
- **Exemplos**: Casos de uso documentados
- **Testes**: Validação das funcionalidades

---

**Desenvolvido com ❤️ para FortSmart Agro**
