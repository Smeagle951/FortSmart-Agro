# 🔹 PLANO DETALHADO - NOVO MODELO DE GERMINAÇÃO COM SUBTESTES (A, B, C)

## 📋 **VISÃO GERAL**

Implementar sistema de subtestes mantendo **100% da estrutura atual**, adicionando apenas a capacidade de dividir cada teste em 3 subtestes independentes (A, B, C) com 100 sementes cada.

---

## 🎯 **OBJETIVOS**

✅ **Manter estrutura atual** - Zero quebra de funcionalidades existentes  
✅ **Adicionar subtestes** - 3 subtestes por lote (A, B, C)  
✅ **Cálculos independentes** - Percentuais por subteste + média geral  
✅ **Relatórios por fase** - Dia 5, 6, 7 com evolução  
✅ **Dashboard integrado** - Visualização por subteste e média  

---

## 🏗️ **ETAPA 1: ANÁLISE DA ESTRUTURA ATUAL**

### **1.1 Modelo de Dados Atual**
```dart
// Estrutura atual que será mantida
class GerminationTest {
  final int? id;
  final String culture;
  final String variety;
  final String seedLot;
  final int totalSeeds; // 300 sementes (100 + 100 + 100)
  final DateTime startDate;
  // ... todos os campos existentes mantidos
}
```

### **1.2 Registros Diários Atuais**
```dart
class GerminationDailyRecord {
  final int germinationTestId;
  final int day;
  final int normalGerminated;
  final int abnormalGerminated;
  final int diseasedFungi;
  final int notGerminated;
  // ... todos os campos sanitários mantidos
}
```

### **1.3 Funcionalidades Atuais (MANTIDAS)**
- ✅ Criação de testes
- ✅ Registro diário por dia
- ✅ Cálculo de percentuais
- ✅ Relatórios PDF/CSV
- ✅ Gráficos de evolução
- ✅ Análise sanitária

---

## 🏗️ **ETAPA 2: NOVO MODELO DE DADOS**

### **2.1 Criar Modelo de Subteste**
```dart
@Entity(tableName: 'germination_subtests')
class GerminationSubtest {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  
  final int germinationTestId; // FK para GerminationTest
  final String subtestCode; // 'A', 'B', 'C'
  final String subtestName; // Nome personalizado do subteste
  final int seedCount; // 100 sementes (configurável)
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Status do subteste
  final String status; // 'active', 'completed'
  
  GerminationSubtest({
    this.id,
    required this.germinationTestId,
    required this.subtestCode,
    required this.subtestName,
    required this.seedCount,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
  });
}
```

### **2.2 Criar Registros Diários por Subteste**
```dart
@Entity(tableName: 'germination_subtest_daily_records')
class GerminationSubtestDailyRecord {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  
  final int subtestId; // FK para GerminationSubtest
  final int day; // Dia do teste (5, 6, 7)
  final DateTime recordDate;
  
  // Contagens do dia (mesmos campos atuais)
  final int normalGerminated;
  final int abnormalGerminated;
  final int diseasedFungi;
  final int notGerminated;
  
  // Campos sanitários (mantidos)
  final String? sanitarySymptoms;
  final String? sanitarySeverity;
  final String? sanitaryObservations;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos calculados (por subteste)
  @ignore
  double get dailyGerminationPercentage => 
    (normalGerminated + abnormalGerminated) / seedCount * 100;
}
```

### **2.3 Atualizar Modelo Principal (ADITIVO)**
```dart
// ADICIONAR ao GerminationTest existente
class GerminationTest {
  // ... todos os campos atuais mantidos
  
  // NOVOS CAMPOS (opcionais)
  final bool hasSubtests; // true se usa subtestes
  final int subtestSeedCount; // 100 (configurável)
  final String? subtestNames; // JSON: ["Subteste A", "Subteste B", "Subteste C"]
  
  // MÉTODOS CALCULADOS
  @ignore
  List<GerminationSubtest>? subtests; // Carregado dinamicamente
  
  @ignore
  double get averageGerminationPercentage {
    if (!hasSubtests) return finalGerminationPercentage ?? 0.0;
    // Calcular média dos subtestes
    return subtests?.map((s) => s.finalGerminationPercentage).reduce((a, b) => a + b) / subtests!.length ?? 0.0;
  }
}
```

---

## 🏗️ **ETAPA 3: LÓGICA DE CÁLCULO**

### **3.1 Cálculo por Subteste**
```dart
class GerminationSubtestService {
  // Calcular percentuais para um subteste específico
  Future<SubtestResults> calculateSubtestResults(int subtestId) async {
    final records = await getDailyRecordsBySubtest(subtestId);
    
    // Somar totais de todos os dias
    int totalNormal = 0;
    int totalAbnormal = 0;
    int totalDiseased = 0;
    int totalNotGerminated = 0;
    
    for (final record in records) {
      totalNormal += record.normalGerminated;
      totalAbnormal += record.abnormalGerminated;
      totalDiseased += record.diseasedFungi;
      totalNotGerminated += record.notGerminated;
    }
    
    final totalSeeds = totalNormal + totalAbnormal + totalDiseased + totalNotGerminated;
    
    return SubtestResults(
      subtestId: subtestId,
      normalPercentage: (totalNormal / totalSeeds) * 100,
      abnormalPercentage: (totalAbnormal / totalSeeds) * 100,
      diseasedPercentage: (totalDiseased / totalSeeds) * 100,
      notGerminatedPercentage: (totalNotGerminated / totalSeeds) * 100,
      totalSeeds: totalSeeds,
    );
  }
}
```

### **3.2 Cálculo da Média Geral**
```dart
class GerminationTestService {
  // Calcular média entre subtestes
  Future<TestAverageResults> calculateTestAverage(int testId) async {
    final subtests = await getSubtestsByTestId(testId);
    final subtestResults = <SubtestResults>[];
    
    for (final subtest in subtests) {
      final results = await calculateSubtestResults(subtest.id!);
      subtestResults.add(results);
    }
    
    return TestAverageResults(
      testId: testId,
      averageNormalPercentage: subtestResults.map((r) => r.normalPercentage).reduce((a, b) => a + b) / subtestResults.length,
      averageAbnormalPercentage: subtestResults.map((r) => r.abnormalPercentage).reduce((a, b) => a + b) / subtestResults.length,
      averageDiseasedPercentage: subtestResults.map((r) => r.diseasedPercentage).reduce((a, b) => a + b) / subtestResults.length,
      subtestResults: subtestResults,
    );
  }
}
```

---

## 🏗️ **ETAPA 4: INTERFACE DE USUÁRIO**

### **4.1 Tela de Criação de Teste (ATUALIZADA)**
```dart
class GerminationTestCreateScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // DADOS BÁSICOS (mantidos)
          _buildBasicInfoSection(),
          
          // NOVA SEÇÃO: CONFIGURAÇÃO DE SUBTESTES
          _buildSubtestConfigurationSection(),
          
          // DADOS DE PUREZA (mantidos)
          _buildPuritySection(),
        ],
      ),
    );
  }
  
  Widget _buildSubtestConfigurationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuração de Subtestes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            // Toggle para ativar subtestes
            SwitchListTile(
              title: Text('Usar Subtestes (A, B, C)'),
              subtitle: Text('Dividir teste em 3 subtestes de 100 sementes cada'),
              value: _useSubtests,
              onChanged: (value) => setState(() => _useSubtests = value),
            ),
            
            if (_useSubtests) ...[
              SizedBox(height: 16),
              Text('Configuração dos Subtestes:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              
              // Subteste A
              _buildSubtestConfig('A', 'Subteste A', _subtestAName, (value) => _subtestAName = value),
              SizedBox(height: 8),
              
              // Subteste B
              _buildSubtestConfig('B', 'Subteste B', _subtestBName, (value) => _subtestBName = value),
              SizedBox(height: 8),
              
              // Subteste C
              _buildSubtestConfig('C', 'Subteste C', _subtestCName, (value) => _subtestCName = value),
            ],
          ],
        ),
      ),
    );
  }
}
```

### **4.2 Tela de Registro Diário (ATUALIZADA)**
```dart
class GerminationDailyRecordScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // CABEÇALHO (mantido)
          _buildHeader(),
          
          // NOVA SEÇÃO: SELEÇÃO DE SUBTESTE
          if (widget.test.hasSubtests) ...[
            _buildSubtestSelector(),
            SizedBox(height: 16),
          ],
          
          // FORMULÁRIO DE REGISTRO (adaptado)
          _buildRecordForm(),
        ],
      ),
    );
  }
  
  Widget _buildSubtestSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecionar Subteste', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubtest,
                    decoration: InputDecoration(
                      labelText: 'Subteste',
                      border: OutlineInputBorder(),
                    ),
                    items: _subtests.map((subtest) => DropdownMenuItem(
                      value: subtest.subtestCode,
                      child: Text('${subtest.subtestCode} - ${subtest.subtestName}'),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedSubtest = value),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () => _showSubtestInfo(),
                  tooltip: 'Informações do subteste',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### **4.3 Tela de Resultados (ATUALIZADA)**
```dart
class GerminationTestResultsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // INFORMAÇÕES DO TESTE (mantidas)
            _buildTestInfoCard(),
            
            // NOVA SEÇÃO: RESULTADOS POR SUBTESTE
            if (widget.test.hasSubtests) ...[
              _buildSubtestResultsSection(),
              SizedBox(height: 16),
            ],
            
            // MÉDIA GERAL
            if (widget.test.hasSubtests) ...[
              _buildAverageResultsSection(),
              SizedBox(height: 16),
            ],
            
            // GRÁFICOS DE EVOLUÇÃO (adaptados)
            _buildEvolutionCharts(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubtestResultsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultados por Subteste', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            // Tabs para cada subteste
            DefaultTabController(
              length: _subtests.length,
              child: Column(
                children: [
                  TabBar(
                    tabs: _subtests.map((subtest) => Tab(
                      text: '${subtest.subtestCode}',
                      child: Column(
                        children: [
                          Text('${subtest.subtestCode}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(subtest.subtestName, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: _subtests.map((subtest) => _buildSubtestResultsCard(subtest)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🏗️ **ETAPA 5: RELATÓRIOS POR FASE**

### **5.1 Relatório Dia 5 (Inicial)**
```dart
class GerminationPhaseReport {
  // Relatório inicial - germinação parcial
  Widget buildDay5Report() {
    return Column(
      children: [
        Text('RELATÓRIO INICIAL - DIA 5', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        
        // Resultados por subteste
        _buildSubtestResultsTable(),
        
        // Gráfico de evolução inicial
        _buildInitialEvolutionChart(),
        
        // Análise de sintomas iniciais
        _buildInitialSymptomsAnalysis(),
      ],
    );
  }
}
```

### **5.2 Relatório Dia 6 (Intermediário)**
```dart
class GerminationPhaseReport {
  // Relatório intermediário - vigor
  Widget buildDay6Report() {
    return Column(
      children: [
        Text('RELATÓRIO INTERMEDIÁRIO - DIA 6', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        
        // Análise de vigor por subteste
        _buildVigorAnalysis(),
        
        // Comparação entre subtestes
        _buildSubtestComparison(),
        
        // Gráfico de vigor
        _buildVigorChart(),
      ],
    );
  }
}
```

### **5.3 Relatório Dia 7 (Final)**
```dart
class GerminationPhaseReport {
  // Relatório final - consolidação
  Widget buildDay7Report() {
    return Column(
      children: [
        Text('RELATÓRIO FINAL - DIA 7', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        
        // Resultados finais por subteste
        _buildFinalSubtestResults(),
        
        // Média consolidada
        _buildConsolidatedAverage(),
        
        // Gráfico de evolução completa
        _buildCompleteEvolutionChart(),
        
        // Recomendações finais
        _buildFinalRecommendations(),
      ],
    );
  }
}
```

---

## 🏗️ **ETAPA 6: DASHBOARD INTEGRADO**

### **6.1 Dashboard Principal (ATUALIZADO)**
```dart
class GerminationSummaryWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // CABEÇALHO (mantido)
          _buildHeader(),
          
          // NOVA SEÇÃO: RESUMO DE SUBTESTES
          if (_hasSubtestData) ...[
            _buildSubtestSummary(),
            SizedBox(height: 16),
          ],
          
          // MÉDIA GERAL
          if (_hasSubtestData) ...[
            _buildAverageSummary(),
            SizedBox(height: 16),
          ],
          
          // GRÁFICO DE EVOLUÇÃO (adaptado)
          _buildEvolutionChart(),
        ],
      ),
    );
  }
  
  Widget _buildSubtestSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resultados por Subteste', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(child: _buildSubtestCard('A', _subtestAResults)),
            SizedBox(width: 8),
            Expanded(child: _buildSubtestCard('B', _subtestBResults)),
            SizedBox(width: 8),
            Expanded(child: _buildSubtestCard('C', _subtestCResults)),
          ],
        ),
      ],
    );
  }
}
```

### **6.2 Gráficos de Evolução (ATUALIZADOS)**
```dart
class ImprovedGerminationCharts {
  // Gráfico de evolução por subteste
  Widget buildSubtestEvolutionChart(List<GerminationSubtest> subtests) {
    return LineChart(
      LineChartData(
        lineBarsData: subtests.map((subtest) => LineChartBarData(
          spots: _buildSubtestSpots(subtest),
          color: _getSubtestColor(subtest.subtestCode),
          barWidth: 3,
          isCurved: true,
        )).toList(),
        
        // Linha da média
        lineBarsData: [
          ...subtests.map((subtest) => LineChartBarData(
            spots: _buildSubtestSpots(subtest),
            color: _getSubtestColor(subtest.subtestCode),
            barWidth: 3,
          )),
          LineChartBarData(
            spots: _buildAverageSpots(subtests),
            color: Colors.black,
            barWidth: 4,
            isDashed: true,
          ),
        ],
      ),
    );
  }
}
```

---

## 🏗️ **ETAPA 7: IMPLEMENTAÇÃO TÉCNICA**

### **7.1 Migração de Banco de Dados**
```sql
-- Criar tabela de subtestes
CREATE TABLE germination_subtests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  germination_test_id INTEGER NOT NULL,
  subtest_code TEXT NOT NULL,
  subtest_name TEXT NOT NULL,
  seed_count INTEGER NOT NULL DEFAULT 100,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (germination_test_id) REFERENCES germination_tests (id)
);

-- Criar tabela de registros diários por subteste
CREATE TABLE germination_subtest_daily_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subtest_id INTEGER NOT NULL,
  day INTEGER NOT NULL,
  record_date TEXT NOT NULL,
  normal_germinated INTEGER NOT NULL DEFAULT 0,
  abnormal_germinated INTEGER NOT NULL DEFAULT 0,
  diseased_fungi INTEGER NOT NULL DEFAULT 0,
  not_germinated INTEGER NOT NULL DEFAULT 0,
  sanitary_symptoms TEXT,
  sanitary_severity TEXT,
  sanitary_observations TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (subtest_id) REFERENCES germination_subtests (id)
);

-- Adicionar campos ao teste principal
ALTER TABLE germination_tests ADD COLUMN has_subtests INTEGER DEFAULT 0;
ALTER TABLE germination_tests ADD COLUMN subtest_seed_count INTEGER DEFAULT 100;
ALTER TABLE germination_tests ADD COLUMN subtest_names TEXT;
```

### **7.2 Serviços de Integração**
```dart
class GerminationSubtestIntegrationService {
  // Criar subtestes automaticamente
  Future<void> createSubtestsForTest(int testId, bool hasSubtests) async {
    if (!hasSubtests) return;
    
    final subtests = ['A', 'B', 'C'];
    for (final code in subtests) {
      await _subtestDao.insertSubtest(GerminationSubtest(
        germinationTestId: testId,
        subtestCode: code,
        subtestName: 'Subteste $code',
        seedCount: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }
  
  // Calcular média entre subtestes
  Future<TestAverageResults> calculateTestAverage(int testId) async {
    final subtests = await _subtestDao.getSubtestsByTestId(testId);
    final results = <SubtestResults>[];
    
    for (final subtest in subtests) {
      final subtestResults = await _calculateSubtestResults(subtest.id!);
      results.add(subtestResults);
    }
    
    return TestAverageResults(
      testId: testId,
      averageNormalPercentage: results.map((r) => r.normalPercentage).reduce((a, b) => a + b) / results.length,
      averageAbnormalPercentage: results.map((r) => r.abnormalPercentage).reduce((a, b) => a + b) / results.length,
      averageDiseasedPercentage: results.map((r) => r.diseasedPercentage).reduce((a, b) => a + b) / results.length,
      subtestResults: results,
    );
  }
}
```

---

## 🏗️ **ETAPA 8: TESTES E VALIDAÇÃO**

### **8.1 Testes Unitários**
```dart
class GerminationSubtestTests {
  test('Criar subtestes automaticamente') async {
    final test = await createTest(hasSubtests: true);
    final subtests = await getSubtestsByTestId(test.id!);
    
    expect(subtests.length, 3);
    expect(subtests[0].subtestCode, 'A');
    expect(subtests[1].subtestCode, 'B');
    expect(subtests[2].subtestCode, 'C');
  }
  
  test('Calcular média entre subtestes') async {
    // Subteste A: 71% normais
    await recordSubtestData(subtestA, normal: 71);
    
    // Subteste B: 68% normais
    await recordSubtestData(subtestB, normal: 68);
    
    // Subteste C: 75% normais
    await recordSubtestData(subtestC, normal: 75);
    
    final average = await calculateTestAverage(testId);
    expect(average.averageNormalPercentage, 71.3);
  }
}
```

### **8.2 Testes de Integração**
```dart
class GerminationSubtestIntegrationTests {
  test('Fluxo completo com subtestes') async {
    // 1. Criar teste com subtestes
    final test = await createTestWithSubtests();
    
    // 2. Registrar dados dia 5
    await recordDay5Data(test);
    
    // 3. Registrar dados dia 6
    await recordDay6Data(test);
    
    // 4. Registrar dados dia 7
    await recordDay7Data(test);
    
    // 5. Verificar resultados
    final results = await getTestResults(test.id!);
    expect(results.hasSubtests, true);
    expect(results.subtests.length, 3);
    expect(results.averageGerminationPercentage, greaterThan(0));
  }
}
```

---

## 📋 **CRONOGRAMA DE IMPLEMENTAÇÃO**

### **Semana 1: Estrutura Base**
- [ ] Criar modelos de dados (Subteste, Registros)
- [ ] Implementar migração de banco
- [ ] Criar DAOs e serviços básicos
- [ ] Testes unitários dos modelos

### **Semana 2: Interface de Usuário**
- [ ] Atualizar tela de criação de teste
- [ ] Implementar seletor de subteste
- [ ] Atualizar tela de registro diário
- [ ] Testes de interface

### **Semana 3: Lógica de Negócio**
- [ ] Implementar cálculos por subteste
- [ ] Criar serviço de média geral
- [ ] Atualizar tela de resultados
- [ ] Testes de integração

### **Semana 4: Relatórios e Dashboard**
- [ ] Implementar relatórios por fase
- [ ] Atualizar dashboard principal
- [ ] Criar gráficos de evolução
- [ ] Testes finais

---

## ✅ **CHECKLIST DE VALIDAÇÃO**

### **Funcionalidades Básicas**
- [ ] Criar teste com subtestes A, B, C
- [ ] Registrar dados por dia e por subteste
- [ ] Calcular percentuais por subteste
- [ ] Calcular média geral
- [ ] Manter compatibilidade com testes antigos

### **Interface de Usuário**
- [ ] Toggle para ativar/desativar subtestes
- [ ] Nomeação personalizada dos subtestes
- [ ] Seletor de subteste no registro diário
- [ ] Visualização de resultados por subteste
- [ ] Gráficos de evolução por subteste

### **Relatórios**
- [ ] Relatório dia 5 (inicial)
- [ ] Relatório dia 6 (intermediário)
- [ ] Relatório dia 7 (final)
- [ ] Média consolidada
- [ ] Comparação entre subtestes

### **Integração**
- [ ] Dashboard principal atualizado
- [ ] Widgets de resumo funcionando
- [ ] Exportação de dados
- [ ] Compatibilidade com sistema atual

---

## 🎯 **RESULTADO ESPERADO**

Após a implementação completa, o sistema terá:

✅ **Compatibilidade Total** - Todos os testes antigos continuam funcionando  
✅ **Subtestes Funcionais** - 3 subtestes por lote com 100 sementes cada  
✅ **Cálculos Precisos** - Percentuais por subteste + média geral  
✅ **Interface Intuitiva** - Fácil navegação entre subtestes  
✅ **Relatórios Completos** - Por fase e consolidados  
✅ **Dashboard Integrado** - Visualização clara dos resultados  

O sistema manterá **100% da funcionalidade atual** enquanto adiciona as novas capacidades de subtestes de forma transparente e intuitiva.

---

*Plano criado em: ${DateTime.now().toString().split(' ')[0]}*
*Versão: FortSmart Agro v2.0 - Subtestes de Germinação*
