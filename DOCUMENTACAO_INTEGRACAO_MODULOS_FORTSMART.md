# 📚 DOCUMENTAÇÃO DE INTEGRAÇÃO DE MÓDULOS - FortSmart Agro

## 🎯 **VISÃO GERAL DOS PADRÕES DE INTEGRAÇÃO**

Baseado na análise das documentações existentes, o FortSmart Agro segue padrões específicos de integração entre módulos. Esta documentação consolida todos os padrões encontrados para garantir consistência no desenvolvimento.

---

## 🏗️ **ARQUITETURA DE INTEGRAÇÃO**

### **Fluxo Principal de Dados:**
```
📱 MONITORAMENTO → 📚 CATÁLOGO DE ORGANISMOS → 🗺️ MAPA DE INFESTAÇÃO → 📊 RELATÓRIOS AGRONÔMICOS
```

### **Princípios Fundamentais:**
1. **Dados Reais Apenas**: Nunca usar dados simulados ou de exemplo
2. **Integração em Tempo Real**: Processamento automático entre módulos
3. **Cache Inteligente**: Sistema de cache com expiração automática
4. **Validação de Dados**: Verificação de integridade em cada etapa
5. **Fallback Graceful**: Tratamento de erros sem quebrar o fluxo

---

## 📋 **PADRÕES POR MÓDULO**

### **1. 🐛 MÓDULO DE MONITORAMENTO**

#### **Responsabilidades:**
- ✅ **Coleta de Dados**: Pontos georreferenciados com GPS
- ✅ **Registro de Ocorrências**: Pragas, doenças, plantas daninhas
- ✅ **Salvamento Automático**: Persistência em tempo real
- ❌ **NÃO calcula severidade**: Apenas coleta e armazena

#### **Integração com Catálogo:**
```dart
// Padrão de busca no catálogo
final organism = await _findOrganismInCatalog(organismName, cropName);
if (organism == null) {
  Logger.warning('Organismo não encontrado: $organismName');
  return null;
}
```

#### **Dados Enviados para Infestação:**
```dart
final infestationData = {
  'talhao_id': talhaoId,
  'ponto_id': pontoId,
  'latitude': latitude,
  'longitude': longitude,
  'organismo_name': organismName,
  'organismo_type': organismType,
  'quantity': quantity,
  'unit': unit,
  'observations': observations,
  'timestamp': timestamp,
  'gps_accuracy': gpsAccuracy,
  'monitoring_session_id': sessionId,
};
```

#### **Serviços Principais:**
- `IntegratedMonitoringService`: Processamento de ocorrências
- `MonitoringSessionService`: Gestão de sessões
- `MonitoringResumeService`: Continuação de monitoramentos
- `MonitoringIntegrationService`: Integração entre módulos

---

### **2. 📚 MÓDULO CATÁLOGO DE ORGANISMOS**

#### **Responsabilidades:**
- ✅ **Fonte de Verdade**: Dados oficiais de pragas/doenças
- ✅ **Thresholds de Infestação**: Limites para classificação
- ✅ **Pesos de Risco**: Multiplicadores por tipo de organismo
- ✅ **Integração com Cultura**: Filtros por cultura específica

#### **Estrutura de Dados:**
```dart
class OrganismCatalog {
  final String id;
  final String nome;
  final String nomeCientifico;
  final String tipo; // 'praga', 'doenca', 'planta_daninha'
  final double lowThreshold;    // Limite baixo (0-25%)
  final double mediumThreshold; // Limite médio (26-50%)
  final double highThreshold;   // Limite alto (51-75%)
  final double pesoRisco;       // Multiplicador de risco
}
```

#### **Padrão de Thresholds:**
```dart
// Cálculo de porcentagem baseado nos limiares
double calculateNormalizedPercentage(int quantity, OrganismCatalog organism) {
  final referenceThreshold = organism.highThreshold;
  if (referenceThreshold <= 0) return 0.0;
  
  double percentage = (quantity / referenceThreshold) * 100;
  return percentage > 100 ? 100.0 : percentage;
}
```

#### **Serviços Principais:**
- `OrganismCatalogService`: Busca e filtros
- `OrganismCatalogLoaderService`: Carregamento de dados
- `OrganismCatalogIntegrationService`: Integração com infestação

---

### **3. 🗺️ MÓDULO MAPA DE INFESTAÇÃO**

#### **Responsabilidades:**
- ✅ **Cálculo de Severidade**: Usando thresholds do catálogo
- ✅ **Classificação de Níveis**: BAIXO, MODERADO, ALTO, CRÍTICO
- ✅ **Visualização Geográfica**: Mapas térmicos e hexbin
- ✅ **Sistema de Alertas**: Geração automática de alertas

#### **Níveis de Severidade:**
```dart
enum InfestationLevel {
  baixo('BAIXO', 'Baixo', 0.0, 25.0, Colors.green),
  moderado('MODERADO', 'Moderado', 25.1, 50.0, Colors.orange),
  alto('ALTO', 'Alto', 50.1, 75.0, Colors.deepOrange),
  critico('CRITICO', 'Crítico', 75.1, 100.0, Colors.red);
}
```

#### **Cálculo de Severidade Composta:**
```dart
// Média ponderada por precisão GPS e tempo
double calculateCompositeScore(List<MonitoringPoint> points) {
  double numerator = 0, denominator = 0;
  
  for (final point in points) {
    final accuracy = point.gpsAccuracy ?? 3.0;
    final wAcc = (1 / (1 + accuracy)).clamp(0.5, 1.0);
    final wTime = exp(-daysDifference / 14.0); // τ = 14 dias
    
    final weight = wAcc * wTime;
    numerator += point.infestationIndex * weight;
    denominator += weight;
  }
  
  return denominator == 0 ? 0 : (numerator / denominator);
}
```

#### **Serviços Principais:**
- `InfestacaoIntegrationService`: Pipeline de processamento
- `InfestationCalculationService`: Cálculos e algoritmos
- `HexbinService`: Geração de heatmaps
- `AlertService`: Sistema de alertas
- `InfestationCacheService`: Cache inteligente

---

### **4. 📊 MÓDULO RELATÓRIOS AGRONÔMICOS**

#### **Responsabilidades:**
- ✅ **Consolidação de Dados**: Agregação de dados de todos os módulos
- ✅ **Análise Temporal**: Tendências e evolução
- ✅ **Relatórios PDF/CSV**: Exportação em múltiplos formatos
- ✅ **Integração com Custos**: Análise financeira

#### **Tipos de Relatórios:**
```dart
enum ReportType {
  sessionSummary,      // Resumo de sessão
  infestationMap,      // Mapa de infestação
  trendAnalysis,       // Análise de tendências
  organismComparison,  // Comparação entre organismos
  fieldComparison,     // Comparação entre talhões
  customPeriod,        // Período customizado
}
```

#### **Serviços Principais:**
- `MonitoringReportService`: Geração de relatórios
- `ReportDataService`: Consolidação de dados
- `ExportService`: Exportação em múltiplos formatos

---

## 🔄 **PADRÕES DE INTEGRAÇÃO**

### **1. Fluxo de Processamento de Dados**

#### **Pipeline Padrão:**
```dart
// 1. Validação
final isValid = await validationService.validateData(data);

// 2. Processamento
final processedData = await processingService.process(data);

// 3. Cálculo
final calculations = await calculationService.calculate(processedData);

// 4. Integração
await integrationService.integrate(calculations);

// 5. Cache
await cacheService.update(calculations);

// 6. Notificação
notificationService.notify(calculations);
```

### **2. Padrão de Cache**

#### **Sistema de Cache Inteligente:**
```dart
class InfestationCacheService {
  // Cache com expiração automática
  static const Duration TALHAO_CACHE_TTL = Duration(hours: 6);
  static const Duration ORGANISM_CACHE_TTL = Duration(hours: 12);
  static const Duration STATS_CACHE_TTL = Duration(hours: 1);
  static const Duration HEATMAP_CACHE_TTL = Duration(hours: 1);
  
  // Invalidação inteligente
  Future<void> invalidateByTalhao(String talhaoId);
  Future<void> invalidateByOrganism(String organismId);
  Future<void> invalidateAll();
}
```

### **3. Padrão de Tratamento de Erros**

#### **Fallback Graceful:**
```dart
try {
  final result = await processData();
  return result;
} catch (e) {
  Logger.error('Erro no processamento: $e');
  
  // Fallback: usar dados do cache
  final cachedData = await cacheService.getCachedData();
  if (cachedData != null) {
    return cachedData;
  }
  
  // Fallback final: dados padrão
  return getDefaultData();
}
```

### **4. Padrão de Validação**

#### **Validação em Camadas:**
```dart
class DataValidationService {
  Future<bool> validateMonitoringData(Monitoring monitoring) async {
    // 1. Validação básica
    if (monitoring.id.isEmpty) return false;
    
    // 2. Validação de coordenadas
    if (!_isValidCoordinates(monitoring.points)) return false;
    
    // 3. Validação de organismos
    if (!await _validateOrganisms(monitoring.points)) return false;
    
    return true;
  }
}
```

---

## 📁 **ESTRUTURA DE PASTAS PADRÃO**

### **Organização por Módulo:**
```
lib/modules/[nome_modulo]/
├── models/           # Modelos de dados específicos
├── services/         # Lógica de negócio
├── repositories/     # Acesso a dados
├── screens/          # Interfaces do usuário
├── widgets/          # Componentes reutilizáveis
├── utils/            # Utilitários e helpers
└── README.md         # Documentação do módulo
```

### **Serviços de Integração:**
```
lib/services/
├── [modulo]_integration_service.dart  # Integração específica
├── module_integration_service.dart    # Integração geral
└── data_validation_service.dart       # Validação compartilhada
```

---

## 🔧 **PADRÕES DE IMPLEMENTAÇÃO**

### **1. Serviços de Integração**

#### **Estrutura Padrão:**
```dart
class [Modulo]IntegrationService {
  // Dependências
  final [Modulo]Repository _repository;
  final CacheService _cacheService;
  final ValidationService _validationService;
  
  // Método principal de processamento
  Future<Map<String, dynamic>> processData({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. Validar
      final isValid = await _validateData(data);
      if (!isValid) return {'success': false, 'error': 'Invalid data'};
      
      // 2. Processar
      final result = await _processData(data);
      
      // 3. Integrar
      await _integrateWithOtherModules(result);
      
      return {'success': true, 'data': result};
    } catch (e) {
      Logger.error('Erro na integração: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
```

### **2. Modelos de Dados**

#### **Padrão de Serialização:**
```dart
class [Modulo]Model {
  final String id;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  factory [Modulo]Model.fromMap(Map<String, dynamic> map) {
    return [Modulo]Model(
      id: map['id'],
      data: jsonDecode(map['data']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
```

### **3. Repositórios**

#### **Padrão de Acesso a Dados:**
```dart
class [Modulo]Repository {
  final Database _database;
  
  Future<List<[Modulo]Model>> getAll() async {
    final maps = await _database.query('[modulo]_table');
    return maps.map((map) => [Modulo]Model.fromMap(map)).toList();
  }
  
  Future<[Modulo]Model?> getById(String id) async {
    final maps = await _database.query(
      '[modulo]_table',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return maps.isNotEmpty ? [Modulo]Model.fromMap(maps.first) : null;
  }
  
  Future<void> insert([Modulo]Model model) async {
    await _database.insert('[modulo]_table', model.toMap());
  }
}
```

---

## 📊 **PADRÕES DE BANCO DE DADOS**

### **1. Tabelas de Integração**

#### **Estrutura Padrão:**
```sql
-- Tabela de monitoramento (exemplo)
CREATE TABLE monitoring_points (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  monitoring_id TEXT,
  session_id TEXT,
  numero INTEGER,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  altitude REAL,
  gps_accuracy REAL,
  gps_provider TEXT,
  organismo_id TEXT NOT NULL,
  quantidade INTEGER DEFAULT 0,
  unidade TEXT,
  infestation_index REAL NOT NULL, -- 0-100
  notas TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  sync_state TEXT DEFAULT 'pending',
  FOREIGN KEY (talhao_id) REFERENCES talhoes(id),
  FOREIGN KEY (organismo_id) REFERENCES organism_catalog(id)
);

-- Tabela de resumo de infestação
CREATE TABLE infestation_summary (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  organismo_id TEXT NOT NULL,
  avg_infestation REAL NOT NULL,
  level TEXT CHECK(level IN ('BAIXO','MODERADO','ALTO','CRITICO')),
  last_update TEXT NOT NULL,
  geojson_heat TEXT,
  FOREIGN KEY (talhao_id) REFERENCES talhoes(id),
  FOREIGN KEY (organismo_id) REFERENCES organism_catalog(id)
);
```

### **2. Índices de Performance**

#### **Índices Padrão:**
```sql
-- Índices para performance
CREATE INDEX idx_monitoring_points_talhao ON monitoring_points(talhao_id);
CREATE INDEX idx_monitoring_points_organismo ON monitoring_points(organismo_id);
CREATE INDEX idx_monitoring_points_timestamp ON monitoring_points(created_at);
CREATE INDEX idx_infestation_summary_talhao_org ON infestation_summary(talhao_id, organismo_id);
```

---

## 🧪 **PADRÕES DE TESTE**

### **1. Testes de Integração**

#### **Estrutura de Testes:**
```dart
class [Modulo]IntegrationTest {
  late [Modulo]IntegrationService _service;
  
  setUp() {
    _service = [Modulo]IntegrationService();
  }
  
  test('deve processar dados corretamente', () async {
    // Arrange
    final testData = createTestData();
    
    // Act
    final result = await _service.processData(data: testData);
    
    // Assert
    expect(result['success'], true);
    expect(result['data'], isNotNull);
  });
  
  test('deve tratar erros gracefully', () async {
    // Arrange
    final invalidData = createInvalidData();
    
    // Act
    final result = await _service.processData(data: invalidData);
    
    // Assert
    expect(result['success'], false);
    expect(result['error'], isNotNull);
  });
}
```

### **2. Testes de Performance**

#### **Benchmark de Cache:**
```dart
test('cache deve melhorar performance', () async {
  final stopwatch = Stopwatch();
  
  // Primeira execução (sem cache)
  stopwatch.start();
  await _service.processData(data: testData);
  stopwatch.stop();
  final firstRun = stopwatch.elapsedMilliseconds;
  
  // Segunda execução (com cache)
  stopwatch.reset();
  stopwatch.start();
  await _service.processData(data: testData);
  stopwatch.stop();
  final secondRun = stopwatch.elapsedMilliseconds;
  
  expect(secondRun, lessThan(firstRun));
});
```

---

## 📋 **CHECKLIST DE IMPLEMENTAÇÃO**

### **Para Novos Módulos:**

#### **✅ Estrutura Básica:**
- [ ] Criar pasta `lib/modules/[nome_modulo]/`
- [ ] Implementar modelos de dados
- [ ] Criar serviços de negócio
- [ ] Implementar repositórios
- [ ] Criar telas da interface

#### **✅ Integração:**
- [ ] Implementar serviço de integração
- [ ] Configurar cache inteligente
- [ ] Implementar validação de dados
- [ ] Configurar tratamento de erros
- [ ] Testes de integração

#### **✅ Documentação:**
- [ ] README do módulo
- [ ] Documentação de APIs
- [ ] Exemplos de uso
- [ ] Guia de troubleshooting

### **Para Modificações em Módulos Existentes:**

#### **✅ Compatibilidade:**
- [ ] Manter compatibilidade com dados existentes
- [ ] Implementar migração de banco se necessário
- [ ] Atualizar documentação
- [ ] Testar integração com outros módulos

---

## 🎯 **EXEMPLOS PRÁTICOS**

### **1. Integração Monitoramento → Infestação**

```dart
// Em monitoring_point_screen.dart
Future<void> _sendToInfestationModule(InfestacaoModel infestacao, Map<String, dynamic> occurrence) async {
  try {
    final infestationIntegrationService = InfestacaoIntegrationService();
    
    final infestationData = {
      'talhao_id': infestacao.talhaoId.toString(),
      'ponto_id': infestacao.pontoId.toString(),
      'latitude': infestacao.latitude,
      'longitude': infestacao.longitude,
      'organismo_name': infestacao.subtipo,
      'organismo_type': infestacao.tipo,
      'infestation_percentage': infestacao.percentual.toDouble(),
      'severity_level': infestacao.nivel,
      'quantity': occurrence['quantity'] as int? ?? 0,
      'unit': occurrence['unit'] as String? ?? 'unidades',
      'observations': infestacao.observacao,
      'images': occurrence['image_paths'] as List<String>? ?? [],
      'timestamp': infestacao.dataHora.toIso8601String(),
      'gps_accuracy': widget.point.gpsAccuracy,
      'monitoring_session_id': _historyId,
    };
    
    final result = await infestationIntegrationService.processMonitoringData(infestationData);
    
    if (result['success'] == true) {
      Logger.info('✅ Dados processados com sucesso no módulo de infestação');
    } else {
      Logger.warning('⚠️ Falha ao processar dados: ${result['error']}');
    }
  } catch (e) {
    Logger.error('❌ Erro ao enviar dados: $e');
  }
}
```

### **2. Cálculo de Severidade no Mapa de Infestação**

```dart
// Em infestation_calculation_service.dart
Future<String> levelFromPct(double pct, {required String organismoId}) async {
  try {
    final thresholds = await _organismService.getOrganismThresholds(organismoId);
    if (thresholds == null) {
      return 'DESCONHECIDO';
    }

    final lowLimit = thresholds['limite_baixo'] as double? ?? 25.0;
    final mediumLimit = thresholds['limite_medio'] as double? ?? 50.0;
    final highLimit = thresholds['limite_alto'] as double? ?? 75.0;

    if (pct <= lowLimit) return 'BAIXO';
    if (pct <= mediumLimit) return 'MODERADO';
    if (pct <= highLimit) return 'ALTO';
    return 'CRITICO';
  } catch (e) {
    Logger.error('❌ Erro ao calcular nível: $e');
    return 'DESCONHECIDO';
  }
}
```

### **3. Sistema de Cache Inteligente**

```dart
// Em infestation_cache_service.dart
Future<T?> getCachedData<T>(String key, {Duration? ttl}) async {
  try {
    final cached = await _cache.get(key);
    if (cached == null) return null;
    
    final timestamp = DateTime.parse(cached['timestamp']);
    final expiry = ttl ?? Duration(hours: 1);
    
    if (DateTime.now().difference(timestamp) > expiry) {
      await _cache.remove(key);
      return null;
    }
    
    return cached['data'] as T;
  } catch (e) {
    Logger.error('❌ Erro no cache: $e');
    return null;
  }
}
```

---

## 📞 **SUPORTE E MANUTENÇÃO**

### **Logs e Monitoramento:**
- Usar `Logger.info()`, `Logger.warning()`, `Logger.error()`
- Incluir tags específicas do módulo
- Logs estruturados para análise

### **Performance:**
- Cache inteligente com TTL apropriado
- Índices de banco para consultas frequentes
- Lazy loading para dados grandes

### **Manutenibilidade:**
- Código documentado e testado
- Separação clara de responsabilidades
- Interfaces bem definidas entre módulos

---

**Esta documentação serve como referência para manter a consistência e qualidade da integração entre módulos do FortSmart Agro. 🚀**
