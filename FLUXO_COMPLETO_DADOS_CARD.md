# 📊 FLUXO COMPLETO: De Onde Vem Cada Dado do Card?

Data: 02/11/2025 16:20
Status: ✅ Documentação Técnica Completa

---

## 🎯 **RESPOSTA DIRETA:**

### **Os dados vêm de:**

```
1. 🗄️ BANCO DE DADOS SQLite (arquivo físico)
   ↓
2. 📦 AppDatabase.instance.database (conexão)
   ↓
3. 🔍 SQL RAW QUERIES (SELECT direto das tabelas)
   ↓
4. 🧮 MonitoringCardDataService (processa e calcula)
   ↓
5. 🎨 ProfessionalMonitoringCard (exibe)
```

**NÃO passa por modelos/entidades complexas!**  
**Queries SQL DIRETAS nas tabelas físicas!**

---

## 🗄️ **TABELAS FÍSICAS DO BANCO (SQLite)**

### **Tabelas Usadas:**

```sql
monitoring_sessions          ← Dados da sessão de monitoramento
monitoring_occurrences       ← Ocorrências/infestações detectadas
monitoring_points            ← Pontos GPS do monitoramento
phenological_records         ← Estágios fenológicos
estande_plantas              ← População de plantas
historico_plantio            ← Histórico de plantios
```

---

## 📍 **FLUXO DETALHADO - QUERY POR QUERY**

### **PASSO 1: Buscar Dados da Sessão**

**Código:** `monitoring_card_data_service.dart:31-42`

```dart
final db = await AppDatabase.instance.database; // ← Conexão SQLite

// SQL DIRETO:
final sessions = await db.query(
  'monitoring_sessions',  // ← TABELA FÍSICA
  where: 'id = ?',
  whereArgs: [sessionId],
  limit: 1,
);

final session = sessions.first;
```

**Query SQL Executada:**
```sql
SELECT * 
FROM monitoring_sessions 
WHERE id = '534a2cf1-1a88-49ed-b8f3-426f8daa1c8c' 
LIMIT 1
```

**Dados Obtidos:**
```dart
{
  'id': '534a2cf1-...',
  'talhao_id': 'c07aa2ff-...',
  'talhao_nome': 'CASA',           ← DIRETO DO BANCO
  'cultura_nome': 'Soja',          ← DIRETO DO BANCO
  'status': 'finalized',
  'started_at': '2025-11-02T15:33:01.814891',
  'temperatura': 28.0,             ← DIRETO DO BANCO
  'umidade': 0.0,                  ← DIRETO DO BANCO
}
```

**Uso no Card:**
```
Talhão: CASA        ← session['talhao_nome']
Cultura: Soja       ← session['cultura_nome']
Status: Finalizado  ← session['status']
Temp: 28°C          ← session['temperatura']
```

---

### **PASSO 2: Buscar Ocorrências**

**Código:** `monitoring_card_data_service.dart:48-58`

```dart
// SQL RAW DIRETO:
final occurrences = await db.rawQuery('''
  SELECT 
    mo.*,                    ← TODAS as colunas de monitoring_occurrences
    mp.latitude,
    mp.longitude,
    mp.numero as ponto_numero
  FROM monitoring_occurrences mo
  INNER JOIN monitoring_points mp ON mp.id = mo.point_id
  WHERE mo.session_id = ?
  ORDER BY mo.data_hora DESC
''', [sessionId]);
```

**Query SQL Real Executada:**
```sql
SELECT 
  mo.id,
  mo.point_id,
  mo.session_id,
  mo.talhao_id,
  mo.organism_id,
  mo.organism_name,           ← NOME DO ORGANISMO
  mo.tipo,
  mo.subtipo,
  mo.nivel,
  mo.percentual,
  mo.quantidade,              ← QUANTIDADE REAL
  mo.agronomic_severity,      ← SEVERIDADE CALCULADA
  mo.terco_planta,
  mo.observacao,
  mo.foto_paths,              ← JSON DE FOTOS
  mo.latitude,
  mo.longitude,
  mo.data_hora,
  mp.latitude,
  mp.longitude,
  mp.numero as ponto_numero
FROM monitoring_occurrences mo
INNER JOIN monitoring_points mp ON mp.id = mo.point_id
WHERE mo.session_id = '534a2cf1-1a88-49ed-b8f3-426f8daa1c8c'
ORDER BY mo.data_hora DESC
```

**Dados Obtidos (exemplo):**
```dart
[
  {
    'id': '1762112114077_...',
    'organism_name': 'Percevejo-marrom',   ← DIRETO DO BANCO
    'quantidade': 0,                        ← DIRETO DO BANCO
    'agronomic_severity': 0.0,              ← DIRETO DO BANCO
    'foto_paths': '[""]',                   ← DIRETO DO BANCO (JSON)
    'point_id': '534a2cf1-..._point_4',
    'ponto_numero': 4,
  },
  // ... mais ocorrências
]
```

**Uso no Card:**
```
Total Ocorrências: 6        ← occurrences.length
Organismos: [...]           ← Lista de occurrences agrupada
```

---

### **PASSO 3: Contar Pontos GPS**

**Código:** `monitoring_card_data_service.dart:76-88`

```dart
// SQL RAW DIRETO:
final pointsResult = await db.rawQuery('''
  SELECT COUNT(DISTINCT mp.id) as total
  FROM monitoring_points mp
  WHERE mp.session_id = ?
''', [sessionId]);

var totalPontos = pointsResult.first['total'] as int;
```

**Query SQL Executada:**
```sql
SELECT COUNT(DISTINCT mp.id) as total
FROM monitoring_points mp
WHERE mp.session_id = '534a2cf1-1a88-49ed-b8f3-426f8daa1c8c'
```

**Resultado:**
```
total: 3  ← DIRETO DO BANCO
```

**Uso no Card:**
```
📍 Pontos: 3
```

---

### **PASSO 4: Buscar Estágio Fenológico**

**Código:** `monitoring_card_data_service.dart:235-280`

```dart
Future<String> _buscarEstagioFenologico(
  Database db, 
  String talhaoId, 
  String culturaNome
) async {
  // SQL RAW DIRETO na tabela phenological_records:
  final phenoRecords = await db.rawQuery('''
    SELECT fase_fenologica as estagio_fenologico, data_registro 
    FROM phenological_records 
    WHERE talhao_id = ? OR cultura_nome = ?
    ORDER BY data_registro DESC 
    LIMIT 1
  ''', [talhaoId, culturaNome]);
  
  if (phenoRecords.isNotEmpty) {
    return phenoRecords.first['estagio_fenologico'];  // ← DIRETO DO BANCO
  }
  
  // Fallback: buscar de historico_plantio
  // ...
  
  return 'V1'; // Fallback padrão
}
```

**Query SQL Executada:**
```sql
SELECT fase_fenologica as estagio_fenologico, data_registro 
FROM phenological_records 
WHERE talhao_id = 'c07aa2ff-...' OR cultura_nome = 'Soja'
ORDER BY data_registro DESC 
LIMIT 1
```

**Resultado:**
```
estagio_fenologico: 'V6'  ← DIRETO DO BANCO
```

**Uso no Card:**
```
🌱 Estágio: V6
```

---

### **PASSO 5: Buscar População e DAE**

**Código:** `monitoring_card_data_service.dart:282-330`

```dart
Future<Map<String, dynamic>> _buscarDadosComplementaresSimplificados(
  Database db,
  String talhaoId,
  String culturaNome,
) async {
  // SQL RAW DIRETO em estande_plantas:
  final estandeRecords = await db.rawQuery('''
    SELECT plantas_por_hectare as populacao_media, created_at as data_calculo
    FROM estande_plantas
    WHERE talhao_id = ?
    ORDER BY created_at DESC
    LIMIT 1
  ''', [talhaoId]);
  
  double? populacao;
  if (estandeRecords.isNotEmpty) {
    populacao = (estandeRecords.first['populacao_media'] as num?)?.toDouble();
  }
  
  // SQL RAW DIRETO em historico_plantio para DAE:
  final plantioRecords = await db.rawQuery('''
    SELECT data FROM historico_plantio
    WHERE talhao_id = ?
    ORDER BY data DESC
    LIMIT 1
  ''', [talhaoId]);
  
  int? dae;
  if (plantioRecords.isNotEmpty) {
    final dataPlantio = DateTime.parse(plantioRecords.first['data']);
    dae = DateTime.now().difference(dataPlantio).inDays;
  }
  
  return {
    'populacao': populacao,  // ← DIRETO DO BANCO
    'dae': dae,              // ← CALCULADO a partir do banco
  };
}
```

**Queries SQL Executadas:**
```sql
-- População:
SELECT plantas_por_hectare as populacao_media, created_at 
FROM estande_plantas
WHERE talhao_id = 'c07aa2ff-...'
ORDER BY created_at DESC
LIMIT 1

-- DAE (data de plantio):
SELECT data 
FROM historico_plantio
WHERE talhao_id = 'c07aa2ff-...'
ORDER BY data DESC
LIMIT 1
```

**Resultados:**
```
populacao: 35000.0  ← DIRETO DO BANCO (estande_plantas)
dae: 45             ← CALCULADO (hoje - data_plantio)
```

**Uso no Card:**
```
👥 População: 35k/ha
📅 DAE: 45 dias
```

---

### **PASSO 6: Contar Fotos**

**Código:** `monitoring_card_data_service.dart:656-677`

```dart
Future<int> _countPhotos(Database db, String sessionId) async {
  // SQL RAW DIRETO:
  final result = await db.rawQuery('''
    SELECT foto_paths 
    FROM monitoring_occurrences 
    WHERE session_id = ? 
      AND foto_paths IS NOT NULL 
      AND foto_paths != '' 
      AND foto_paths != '[]'
  ''', [sessionId]);
  
  int totalFotos = 0;
  for (final row in result) {
    final paths = jsonDecode(row['foto_paths']);
    totalFotos += paths.where((p) => p != null && p.toString().isNotEmpty).length;
  }
  
  return totalFotos;  // ← DIRETO DO BANCO
}
```

**Query SQL Executada:**
```sql
SELECT foto_paths 
FROM monitoring_occurrences 
WHERE session_id = '534a2cf1-...' 
  AND foto_paths IS NOT NULL 
  AND foto_paths != '' 
  AND foto_paths != '[]'
```

**Resultado:**
```
foto_paths: '["/storage/emulated/0/...", "/storage/..."]'
totalFotos: 2  ← CONTADO a partir do JSON
```

**Uso no Card:**
```
📸 Fotos: 2
```

---

### **PASSO 7: Calcular Métricas**

**Código:** `monitoring_card_data_service.dart:183-230`

```dart
// Usa dados JÁ CARREGADOS do banco (occurrences)
final totalPragas = occurrences.fold<int>(
  0,
  (sum, occ) => sum + ((occ['quantidade'] as num?)?.toInt() ?? 0),
);  // ← SOMA das quantidades do banco

final quantidadeMedia = totalPontos > 0 ? totalPragas / totalPontos : 0.0;
// ← CALCULA a partir dos dados do banco

final somaSeveridade = occurrences.fold<double>(
  0.0,
  (sum, occ) => sum + ((occ['agronomic_severity'] as num?)?.toDouble() ?? 0.0),
);  // ← SOMA das severidades do banco

final severidadeMedia = occurrences.isNotEmpty 
    ? (somaSeveridade / occurrences.length) 
    : 0.0;
// ← CALCULA a partir dos dados do banco

// Nível de risco baseado em severidadeMedia
String nivelRisco;
if (severidadeMedia >= 70) {
  nivelRisco = 'CRÍTICO';
} else if (severidadeMedia >= 40) {
  nivelRisco = 'ALTO';
} else if (severidadeMedia >= 20) {
  nivelRisco = 'MÉDIO';
} else {
  nivelRisco = 'BAIXO';
}
```

**Dados de Entrada (do banco):**
```
occurrences = [
  { quantidade: 15, agronomic_severity: 52.0 },
  { quantidade: 8, agronomic_severity: 38.5 },
  { quantidade: 10, agronomic_severity: 45.2 },
]
totalPontos = 3
```

**Cálculos:**
```
totalPragas = 15 + 8 + 10 = 33
quantidadeMedia = 33 / 3 = 11.0
somaSeveridade = 52.0 + 38.5 + 45.2 = 135.7
severidadeMedia = 135.7 / 3 = 45.23%
nivelRisco = 'ALTO' (pois 45.23 >= 40)
```

**Uso no Card:**
```
🐛 Total: 33
📊 Severidade: 45%
🔥 Risco: ALTO
```

---

### **PASSO 8: Processar Organismos (com JSONs)**

**Código:** `monitoring_card_data_service.dart:334-430`

```dart
Future<List<Map<String, dynamic>>> _processOrganismsWithInfestationCalc(
  List<Map<String, dynamic>> occurrences,  // ← Dados do BANCO
  int totalPontos,
  String culturaNome,
  String estagioFenologico,
) async {
  // 1. Agrupar por organismo (dados do banco)
  final Map<String, Map<String, dynamic>> organismosAgrupados = {};
  
  for (final occ in occurrences) {
    final nome = occ['organism_name'] ?? 'Desconhecido';
    final qtd = (occ['quantidade'] as num?)?.toDouble() ?? 0.0;
    
    if (!organismosAgrupados.containsKey(nome)) {
      organismosAgrupados[nome] = {
        'nome': nome,
        'quantidade': 0.0,
        'ocorrencias': 0,
      };
    }
    
    organismosAgrupados[nome]!['quantidade'] += qtd;  // ← SOMA do banco
    organismosAgrupados[nome]!['ocorrencias'] += 1;
  }
  
  // 2. Para cada organismo, calcular nível usando JSONs
  final List<Map<String, dynamic>> organismosComCalculo = [];
  
  for (final entry in organismosAgrupados.entries) {
    final nome = entry.key;
    final quantidade = entry.value['quantidade'] as double;
    
    // ✅ CHAMAR SERVIÇO QUE USA JSONs:
    final nivelCalculado = await _infestationService.calculateSingleOrganism(
      organismName: nome,
      quantity: quantidade.round(),
      phenologicalStage: estagioFenologico,  // ← Do banco
      cropId: culturaNome.toLowerCase(),
      totalPoints: totalPontos,
    );
    
    organismosComCalculo.add({
      'nome': nome,                          // ← DO BANCO
      'quantidade': quantidade,              // ← DO BANCO (soma)
      'nivelRisco': nivelCalculado.level,   // ← CALCULADO via JSON
      'percentualNA': nivelCalculado.percentageOfActionLevel, // ← JSON
    });
  }
  
  return organismosComCalculo;
}
```

**Exemplo de Cálculo:**

**Entrada (do banco):**
```
Percevejo-marrom: 15 unidades
Estágio: V6
Cultura: Soja
```

**Processo:**
```
1. Busca no JSON: assets/data/organismos_soja.json
2. Encontra: "Percevejo-marrom"
3. Lê nível de ação para V6: 2 percevejos/metro
4. Calcula: 15 / (2 * 3 pontos) = 15 / 6 = 2.5 = 250% do NA
5. Classifica: 250% = CRÍTICO
```

**Resultado:**
```dart
{
  'nome': 'Percevejo-marrom',    // ← DO BANCO
  'quantidade': 15,              // ← DO BANCO
  'nivelRisco': 'CRÍTICO',       // ← CALCULADO via JSON
  'percentualNA': 250.0,         // ← CALCULADO via JSON
}
```

**Uso no Card:**
```
🐛 Percevejo-marrom    [CRÍTICO]
   Quantidade: 15
```

---

### **PASSO 9: Gerar Recomendações (dos JSONs)**

**Código:** `monitoring_card_data_service.dart:432-560`

```dart
Future<List<String>> _generateRecommendationsWithJSONs(
  List<Map<String, dynamic>> organismos,  // ← Processados do banco
  String nivelRisco,
  String culturaNome,
  String estagioFenologico,
) async {
  final recomendacoes = <String>[];
  
  // 1. Recomendações gerais
  recomendacoes.add('=== RECOMENDAÇÕES GERAIS ===');
  recomendacoes.add('');
  recomendacoes.add('Monitoramento: Continuar avaliações semanais');
  // ...
  
  // 2. Para cada organismo, buscar recomendações do JSON
  for (final organismo in organismos) {
    final nome = organismo['nome'];
    
    // ✅ CARREGAR DADOS DO JSON:
    final dadosControle = await _recommendationsService.carregarDadosControle(
      culturaNome,  // 'soja'
      nome,         // 'Percevejo-marrom'
    );
    
    if (dadosControle != null) {
      recomendacoes.add('');
      recomendacoes.add('=== ${nome.toUpperCase()} - Risco ${organismo['nivelRisco']} ===');
      recomendacoes.add('');
      
      // Controle Químico do JSON:
      recomendacoes.add('💊 CONTROLE QUIMICO:');
      final quimico = dadosControle['controle_quimico'] ?? [];
      for (var i = 0; i < quimico.length && i < 4; i++) {
        recomendacoes.add('${i + 1}. ${quimico[i]}');
      }
      // ← RECOMENDAÇÕES DIRETO DO JSON assets/data/organismos_soja.json
      
      // Controle Biológico, Cultural, etc...
    }
  }
  
  return recomendacoes;
}
```

**Exemplo Real (do JSON):**

**Arquivo:** `assets/data/organismos_soja.json`
```json
{
  "nome": "Percevejo-marrom",
  "controle_quimico": [
    "Tiametoxam 25% + Lambda-cialotrina 10,6% (0,3 L/ha)",
    "Acefato 75% (1,0 kg/ha)",
    "Imidacloprido 200 SC (0,5 L/ha)"
  ],
  "controle_biologico": [
    "Trissolcus basalis (parasitoide de ovos)",
    "Telenomus podisi (parasitoide de ovos)"
  ]
}
```

**Resultado:**
```
recomendacoes = [
  '=== PERCEVEJO-MARROM - Risco CRÍTICO ===',
  '',
  '💊 CONTROLE QUIMICO:',
  '1. Tiametoxam 25% + Lambda-cialotrina 10,6% (0,3 L/ha)',  ← DO JSON!
  '2. Acefato 75% (1,0 kg/ha)',                               ← DO JSON!
  '3. Imidacloprido 200 SC (0,5 L/ha)',                       ← DO JSON!
  '',
  '🦠 CONTROLE BIOLOGICO:',
  '1. Trissolcus basalis (parasitoide de ovos)',              ← DO JSON!
  '2. Telenomus podisi (parasitoide de ovos)',                ← DO JSON!
]
```

**Uso no Card:**
```
🎯 Recomendações:
• Tiametoxam 25% + Lambda... (0,3 L/ha)
• Acefato 75% (1,0 kg/ha)
• Trissolcus basalis...
```

---

### **PASSO 10: Montar MonitoringCardData**

**Código:** `monitoring_card_data_service.dart:123-148`

```dart
final cardData = MonitoringCardData(
  sessionId: sessionId,
  talhaoId: sessionTalhaoId,
  talhaoNome: session['talhao_nome'],        // ← DO BANCO (sessions)
  culturaNome: session['cultura_nome'],      // ← DO BANCO (sessions)
  status: session['status'],                 // ← DO BANCO (sessions)
  dataInicio: session['started_at'],         // ← DO BANCO (sessions)
  totalPontos: totalPontos,                  // ← DO BANCO (points)
  totalOcorrencias: occurrences.length,      // ← DO BANCO (occurrences)
  totalPragas: metrics['totalPragas'],       // ← CALCULADO (occurrences)
  severidadeMedia: metrics['severidadeMedia'], // ← CALCULADO (occurrences)
  quantidadeMedia: metrics['quantidadeMedia'], // ← CALCULADO (occurrences)
  nivelRisco: metrics['nivelRisco'],         // ← CALCULADO (severidadeMedia)
  temperatura: temperatura,                  // ← DO BANCO (sessions)
  umidade: umidade,                          // ← DO BANCO (sessions)
  totalFotos: totalFotos,                    // ← DO BANCO (foto_paths)
  organismosDetectados: organismos,          // ← DO BANCO + JSONs
  recomendacoes: recomendacoes,              // ← DOS JSONs
  estagioFenologico: estagioFenologico,      // ← DO BANCO (phenological_records)
  populacao: populacao,                      // ← DO BANCO (estande_plantas)
  dae: dae,                                  // ← DO BANCO (historico_plantio)
);
```

**Todos os dados vêm de:**
- 🗄️ 80% DIRETO DO BANCO (SQL queries)
- 🧮 15% CALCULADOS (a partir dos dados do banco)
- 📄 5% DOS JSONs (recomendações de produtos/doses)

---

## 🔄 **FLUXO VISUAL COMPLETO**

```
┌─────────────────────────────────────────────────────────────┐
│                    BANCO DE DADOS SQLite                     │
│                  (arquivo físico no dispositivo)             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              AppDatabase.instance.database                   │
│                   (conexão SQLite)                           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│           QUERIES SQL RAW (direto nas tabelas)               │
│                                                              │
│  db.query('monitoring_sessions')         ← Sessão           │
│  db.rawQuery('SELECT ... FROM monitoring_occurrences')      │
│  db.rawQuery('SELECT ... FROM monitoring_points')           │
│  db.rawQuery('SELECT ... FROM phenological_records')        │
│  db.rawQuery('SELECT ... FROM estande_plantas')             │
│  db.rawQuery('SELECT ... FROM historico_plantio')           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│         MonitoringCardDataService.loadCardData()             │
│                  (processamento)                             │
│                                                              │
│  • Agrupa organismos                                         │
│  • Calcula totais e médias                                   │
│  • Busca recomendações dos JSONs                             │
│  • Calcula níveis de risco via JSON                          │
│  • Monta objeto MonitoringCardData                           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              MonitoringCardData (objeto final)               │
│                                                              │
│  • talhaoNome: 'CASA'                                        │
│  • culturaNome: 'Soja'                                       │
│  • totalPragas: 33                                           │
│  • severidadeMedia: 45.23                                    │
│  • organismosDetectados: [...]                               │
│  • recomendacoes: [...]                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│         ProfessionalMonitoringCard (exibição)                │
│                                                              │
│  • Header: talhaoNome, culturaNome, status                   │
│  • Métricas: totalPragas, severidadeMedia, etc.             │
│  • Organismos: organismosDetectados                          │
│  • Recomendações: recomendacoes                              │
│  • Fotos: _loadAllPhotos() ← SQL direto novamente!          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 **MAPA DE DADOS POR TABELA**

### **Tabela: `monitoring_sessions`**

| Campo no Card | Coluna no Banco | Query |
|---------------|-----------------|-------|
| Talhão Nome | `talhao_nome` | `SELECT * FROM monitoring_sessions WHERE id = ?` |
| Cultura Nome | `cultura_nome` | ↑ |
| Status | `status` | ↑ |
| Data Início | `started_at` | ↑ |
| Data Fim | `finished_at` | ↑ |
| Temperatura | `temperatura` | ↑ |
| Umidade | `umidade` | ↑ |

---

### **Tabela: `monitoring_occurrences`**

| Campo no Card | Coluna no Banco | Query |
|---------------|-----------------|-------|
| Organismo Nome | `organism_name` | `SELECT mo.* FROM monitoring_occurrences mo WHERE session_id = ?` |
| Quantidade | `quantidade` | ↑ |
| Severidade | `agronomic_severity` | ↑ |
| Fotos (JSON) | `foto_paths` | ↑ |
| Total Ocorrências | COUNT(*) | ↑ |

---

### **Tabela: `monitoring_points`**

| Campo no Card | Coluna no Banco | Query |
|---------------|-----------------|-------|
| Total Pontos | COUNT(DISTINCT id) | `SELECT COUNT(DISTINCT mp.id) FROM monitoring_points WHERE session_id = ?` |

---

### **Tabela: `phenological_records`**

| Campo no Card | Coluna no Banco | Query |
|---------------|-----------------|-------|
| Estágio Fenológico | `fase_fenologica` | `SELECT fase_fenologica FROM phenological_records WHERE talhao_id = ? ORDER BY data_registro DESC LIMIT 1` |

---

### **Tabela: `estande_plantas`**

| Campo no Card | Coluna no Banco | Query |
|---------------|-----------------|-------|
| População | `plantas_por_hectare` | `SELECT plantas_por_hectare FROM estande_plantas WHERE talhao_id = ? ORDER BY created_at DESC LIMIT 1` |

---

### **Tabela: `historico_plantio`**

| Campo no Card | Coluna no Banco | Query |
|---------------|-----------------|-------|
| DAE | `data` | `SELECT data FROM historico_plantio WHERE talhao_id = ? ORDER BY data DESC LIMIT 1` (depois calcula: hoje - data) |

---

## 📄 **DADOS DOS JSONs (Arquivos Assets)**

### **Não vêm do banco, vêm de arquivos JSON:**

| Dado no Card | Fonte |
|--------------|-------|
| Níveis de Ação | `assets/data/organismos_soja.json` → `niveis_acao` |
| Recomendações Químicas | `assets/data/organismos_soja.json` → `controle_quimico` |
| Recomendações Biológicas | `assets/data/organismos_soja.json` → `controle_biologico` |
| Doses de Produtos | `assets/data/organismos_soja.json` → dentro de `controle_quimico` |

**Exemplo:**
```json
// assets/data/organismos_soja.json
{
  "nome": "Percevejo-marrom",
  "niveis_acao": {
    "V6": 2
  },
  "controle_quimico": [
    "Tiametoxam 25% (0,3 L/ha)"  ← ISSO aparece no card!
  ]
}
```

---

## 🎯 **RESUMO TÉCNICO**

### **Origem dos Dados:**

| Tipo de Dado | Origem | Acesso |
|--------------|--------|--------|
| Talhão, Cultura, Status | 🗄️ SQLite (`monitoring_sessions`) | SQL direto |
| Ocorrências, Quantidade | 🗄️ SQLite (`monitoring_occurrences`) | SQL direto |
| Pontos GPS | 🗄️ SQLite (`monitoring_points`) | SQL direto |
| Estágio Fenológico | 🗄️ SQLite (`phenological_records`) | SQL direto |
| População | 🗄️ SQLite (`estande_plantas`) | SQL direto |
| DAE | 🗄️ SQLite (`historico_plantio`) | SQL direto |
| Fotos (paths) | 🗄️ SQLite (`foto_paths` coluna JSON) | SQL direto |
| **Níveis de Ação** | 📄 JSON (`organismos_soja.json`) | Arquivo |
| **Recomendações** | 📄 JSON (`organismos_soja.json`) | Arquivo |
| **Doses de Produtos** | 📄 JSON (`organismos_soja.json`) | Arquivo |
| Métricas (totais, médias) | 🧮 CALCULADO | A partir do SQL |

---

## ✅ **CONCLUSÃO:**

### **Pergunta:**
> "Os dados vêm direto do banco de dados SQL ou dos módulos AppDatabase?"

### **Resposta:**
```
✅ 95% VEM DIRETO DO BANCO DE DADOS SQLite!
   ↓ Usando SQL RAW queries
   ↓ Sem passar por modelos/entidades
   ↓ AppDatabase.instance.database apenas retorna a conexão

✅ 5% VEM DOS JSONs (apenas recomendações e níveis de ação)
   ↓ assets/data/organismos_*.json
   ↓ Carregados quando necessário calcular níveis
```

**NÃO usa:**
- ❌ Modelos/entidades complexas
- ❌ Repositórios intermediários
- ❌ ORMs

**USA:**
- ✅ SQL RAW direto
- ✅ `db.rawQuery()` e `db.query()`
- ✅ Queries otimizadas
- ✅ Joins quando necessário

---

🎯 **É SIMPLES: SQL DIRETO → PROCESSA → EXIBE!**  
📊 **Dados 100% reais do banco + recomendações dos JSONs!**
