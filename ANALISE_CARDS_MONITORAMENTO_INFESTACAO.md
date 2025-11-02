# 📊 Análise Detalhada: Cards de Monitoramento e Infestação

## 🎯 Resumo Executivo

Este documento detalha o funcionamento dos **Cards de Monitoramento** e **Cards de Infestação**, explicando as diferenças, semelhanças e a integração com o **motor de cálculo térmico** e os **arquivos JSON** de organismos.

---

## 📱 1. CARD DE MONITORAMENTO (Monitoring Dashboard)

### 📍 Localização
- **Arquivo**: `lib/screens/reports/monitoring_dashboard.dart`
- **Rota**: Relatórios → Dashboard de Monitoramento

### 🎨 Funcionalidades Principais

#### 1.1. **Listagem de Monitoramentos**
```dart
_buildMonitoringCard(Monitoring monitoring)
```

**Características:**
- ✅ Exibe lista de sessões de monitoramento (finalizados e em andamento)
- ✅ Mostra: ID, Status, Talhão, Data, Quantidade de Pontos
- ✅ Alerta visual para ocorrências críticas
- ✅ Filtros por: Status, Cultura, Talhão

#### 1.2. **Mapa Térmico Integrado** 🗺️

```dart
_buildMapaComHeatmap(List<Map<String, dynamic>> heatmapData)
```

**Camadas do Mapa:**
1. **Base MapTiler** (Satélite)
   - API: `APIConfig.getMapTilerUrl('satellite')`
   - Fallback para OpenStreetMap

2. **Polígono do Talhão** (Verde translúcido)
   ```dart
   PolygonLayer(
     polygons: [Polygon(points: poligonoSnapshot.data!, ...)]
   )
   ```
   - Carregado da tabela `talhoes` + `poligonos`
   - Cor: Verde com 15% opacidade
   - Borda: Verde sólido (3px)

3. **Camada Térmica** (CircleLayer)
   ```dart
   CircleLayer(
     circles: heatmapData.map((ponto) => CircleMarker(
       point: LatLng(lat, lng),
       color: cor.withOpacity(0.3),
       radius: 30 + (intensidade * 40), // 30-70 metros
       useRadiusInMeter: true,
     ))
   )
   ```

4. **Marcadores Interativos** (MarkerLayer)
   ```dart
   MarkerLayer(
     markers: heatmapData.map((ponto) => Marker(
       child: Container(
         color: cor.withOpacity(0.8),
         child: Text(_getEmojiOrganismo(ponto['organismo']))
       )
     ))
   )
   ```

### 🔢 Fonte de Dados do Heatmap

```sql
SELECT 
  mp.latitude,
  mp.longitude,
  mo.tipo,
  mo.subtipo,
  mo.agronomic_severity,
  mo.percentual,
  mp.timestamp
FROM monitoring_points mp
JOIN monitoring_occurrences mo ON mo.point_id = mp.id
WHERE mp.latitude IS NOT NULL 
  AND mp.longitude IS NOT NULL
  AND mo.subtipo IS NOT NULL
ORDER BY mp.timestamp DESC
LIMIT 20
```

**Processamento:**
1. **Intensidade**: Normalizada de `agronomic_severity` (0-10) ou `percentual`
2. **Cor**: Baseada na severidade:
   - 🟢 Verde: < 3.0 (Baixo)
   - 🟡 Amarelo: 3.0-5.0 (Médio)
   - 🟠 Laranja: 5.0-7.0 (Alto)
   - 🔴 Vermelho: ≥ 7.0 (Crítico)

### 📊 Recursos Adicionais

- ✅ **Legenda Dinâmica**: Mostra organismos detectados
- ✅ **Histórico Temporal**: Últimos 7 dias com emojis de severidade
- ✅ **Galerias de Fotos**: Imagens das infestações
- ✅ **Recomendações de Aplicação**: Baseadas na IA FortSmart

---

## 🐛 2. CARD DE INFESTAÇÃO (Advanced Analytics - Tab Infestação)

### 📍 Localização
- **Arquivo**: `lib/screens/reports/advanced_analytics_dashboard.dart`
- **Rota**: Relatório Agronômico → Aba "Infestação"

### 🎨 Funcionalidades Principais

#### 2.1. **Comparação: Monitoramento vs Infestação**

| Aspecto | Card Monitoramento | Card Infestação |
|---------|-------------------|-----------------|
| **Foco** | Sessões de monitoramento | Análise agronômica completa |
| **Dados** | Pontos brutos com ocorrências | Processados pelo motor matemático |
| **Mapa** | ✅ Sim (Heatmap visual) | ⚠️ Deveria ter (verificar) |
| **Cálculo** | Visualização simples | Motor de cálculo avançado |
| **Recomendações** | ✅ Sim (IA) | ✅ Sim (IA + JSONs) |

#### 2.2. **Motor de Cálculo de Infestação**

**Localização:** `lib/modules/infestation_map/services/`

**Serviços Principais:**

1. **InfestationCalculationService**
   ```dart
   calculateMathematicalInfestation({
     required List<InfestationPoint> points,
     required String organismId,
     required String phenologicalPhase,
   })
   ```
   - Calcula índice de infestação por ponto
   - Determina nível (BAIXO/MÉDIO/ALTO/CRÍTICO)
   - Gera estatísticas agregadas

2. **TalhaoInfestationCalculationService**
   ```dart
   calculateTalhaoInfestation({
     required String talhaoId,
     required String organismoId,
     required List<MonitoringPoint> monitoringPoints,
     required List<LatLng> talhaoPolygon,
   })
   ```
   - Calcula % do talhão afetado
   - Interpolação espacial
   - Gera heatmap hexagonal (Hexbin)

3. **MathematicalInfestationCalculator**
   ```dart
   _calculateInfluenceRadius(double intensity, double? accuracy)
   ```
   - Raio base: 50 metros
   - Ajustado por intensidade e precisão GPS
   - Range: 25-200 metros

### 🧮 Fórmulas Matemáticas Aplicadas

```dart
// 1. Intensidade do Heatmap
final intensity = (severity / 10.0).clamp(0.1, 1.0);

// 2. Raio de Influência
final radius = 30 + (intensity * 40); // 30-70m

// 3. Score Composto (Motor)
compositeScore = (severityWeight * 0.4) + 
                 (phaseWeight * 0.3) + 
                 (environmentalWeight * 0.2) + 
                 (confidenceWeight * 0.1);
```

---

## 🔗 3. INTEGRAÇÃO COM JSONs DE ORGANISMOS

### 📂 Estrutura de Arquivos

```
assets/data/
├── organismos_soja.json          ← Pragas/Doenças
├── organismos_milho.json
├── plantas_daninhas_soja.json    ← Plantas Daninhas (NOVO)
├── plantas_daninhas_milho.json
└── ...
```

### 🔄 Fluxo de Carregamento

#### 3.1. **Carregamento de Organismos**

```dart
// 1. AIOrganismRepositoryIntegrated
await rootBundle.loadString('assets/data/organismos_${cultura}.json');

// 2. OrganismCatalogLoaderService
_organismCache[cropName] = {
  'pest': [...pragas],
  'disease': [...doenças],
  'weed': [...daninhas]  // ← Carregado de plantas_daninhas_*.json
};
```

#### 3.2. **Uso nas Recomendações**

```dart
_gerarRecomendacoesAplicacao(analise, dadosCompletos)
```

**Processo:**
1. **Identificar Organismos** → `analise['organismosDetectados']`
2. **Buscar nos JSONs** → Dados de controle químico/biológico
3. **Gerar Protocolo** → Produtos, dosagem, momento ideal
4. **Interpreção IA** → Traduz JSON técnico para linguagem humana

#### 3.3. **Exemplo de Estrutura JSON**

```json
{
  "organismos": [{
    "id": "pest_lagarta_001",
    "nome": "Lagarta-do-cartucho",
    "controle": {
      "quimico": ["Chlorantraniliprole", "Emamectin"],
      "cultural": ["Plantio adensado", "Rotação"]
    },
    "nivel_infestacao": {
      "baixo": "até 5 lagartas/m²",
      "critico": ">20 lagartas/m²"
    }
  }]
}
```

---

## ✅ 4. VERIFICAÇÃO DE FUNCIONAMENTO

### 🔍 Checklist de Validação

#### ✅ **Mapa Térmico**
- [x] MapTiler configurado corretamente
- [x] Polígono do talhão carregado do banco
- [x] Pontos georreferenciados (lat/lng) validados
- [x] Cores baseadas em severidade real
- [x] Raio térmico proporcional à intensidade

#### ✅ **Motor de Cálculo**
- [x] `InfestationCalculationService` ativo
- [x] Conversão `MonitoringPoint` → `InfestationPoint`
- [x] Cálculo de índice por organismo
- [x] Agregação por talhão
- [x] Geração de heatmap hexagonal (Hexbin)

#### ✅ **Integração JSONs**
- [x] Carregamento de `organismos_*.json`
- [x] Carregamento de `plantas_daninhas_*.json`
- [x] Fallback para daninhas comuns se JSON não existir
- [x] Uso em recomendações de aplicação
- [x] Interpretação IA de dados técnicos

### ⚠️ Pontos de Atenção

1. **Card de Infestação no Relatório Agronômico**
   - ⚠️ Verificar se está renderizando o mapa térmico
   - ⚠️ Validar se usa o mesmo motor de cálculo

2. **Sincronização de Dados**
   - ✅ Monitoramentos salvos em `monitoring_points`
   - ✅ Ocorrências em `monitoring_occurrences`
   - ✅ Integração com módulo de infestação ativa

3. **Georreferenciamento**
   - ✅ Lat/Lng obrigatórios para pontos
   - ✅ Validação de coordenadas válidas
   - ✅ Cálculo de centro baseado em polígono ou pontos

---

## 🎯 5. DIFERENÇAS E SEMELHANÇAS

### 🔄 **Semelhanças**
- ✅ Ambos usam dados reais de monitoramento
- ✅ Ambos mostram severidade (Baixo/Médio/Alto/Crítico)
- ✅ Ambos integram com IA FortSmart
- ✅ Ambos geram recomendações de aplicação

### 🔀 **Diferenças**

| Aspecto | Card Monitoramento | Card Infestação |
|---------|-------------------|-----------------|
| **Motor de Cálculo** | Visual simples | Matemático avançado |
| **Heatmap** | CircleLayer + MarkerLayer | Hexbin (hexagonal) |
| **Foco Temporal** | Última sessão | Histórico acumulado |
| **Interpolação** | Não | Sim (espacial) |
| **Análise** | Detecção direta | Processamento complexo |

---

## 📈 6. FLUXO COMPLETO DE DADOS

```
1. MONITORAMENTO LIVRE/GUIADO
   ↓
2. NOVA OCORRÊNCIA (com GPS)
   ↓
3. SALVAR NO BANCO
   - monitoring_points (lat/lng)
   - monitoring_occurrences (organismo, severidade)
   ↓
4. PROCESSAR MOTOR DE CÁLCULO
   - InfestationCalculationService
   - TalhaoInfestationCalculationService
   ↓
5. GERAR HEATMAP
   - CircleLayer (térmico)
   - MarkerLayer (interativo)
   ↓
6. EXIBIR NO CARD
   - Monitoring Dashboard (visualização)
   - Advanced Analytics (análise)
   ↓
7. RECOMENDAÇÕES IA
   - Carrega JSONs de organismos
   - Gera protocolo de aplicação
   - Interpreta dados técnicos
```

---

## 🔧 7. PRÓXIMOS PASSOS

### 🎯 Melhorias Sugeridas

1. **Unificar Heatmap**
   - Card de Infestação deve usar mesmo mapa do Monitoring Dashboard
   - Reutilizar `_buildMapaComHeatmap`

2. **Motor de Cálculo em Tempo Real**
   - Recálculo automático ao salvar nova ocorrência
   - Cache inteligente de resultados

3. **Integração JSONs Mais Robusta**
   - Validação de estrutura dos JSONs
   - Fallback automático para culturas não mapeadas
   - Sistema de versionamento de JSONs

---

## 📚 Referências Técnicas

- **MapTiler API**: `lib/utils/api_config.dart`
- **Motor de Cálculo**: `lib/modules/infestation_map/services/`
- **Integração JSONs**: `lib/services/organism_catalog_loader_service.dart`
- **IA Agronômica**: `lib/services/fortsmart_agronomic_ai.dart`

---

**Última Atualização:** 2024-01-15  
**Versão:** 1.0
