# 🗺️ Módulo Mapa de Infestação — FortSmart Agro (Especificação Completa)

> Versão: 1.0 • Data: 2025-09-01 • Alvo: App FortSmart (Flutter + SQLite offline, Sync com Backend Node.js/JWT)

---

## 0) Objetivo
Consolidar dados de **Monitoramento**, **Catálogo de Organismos** e **Gestão de Infestação** para gerar **mapas georreferenciados**, **heatmaps**, **alertas** e **relatórios** por talhão/cultura, com histórico e sincronização offline-first.

---

## 1) Arquitetura e Pastas
```
lib/
  models/
    talhao_resumo_model.dart
    organism_catalog.dart
    monitoring.dart
    monitoring_point.dart
    occurrence.dart
    infestation_summary.dart
    infestation_alert.dart
  repositories/
    infestacao_repository.dart
    monitoring_repository.dart
    alert_level_repository.dart
  services/
    infestacao_service.dart
    infestation_map_service.dart
    monitoring_calculation_service.dart
    monitoring_save_fix_service.dart
    infestacao_integration_service.dart
    modules_integration_service.dart
  screens/infestacao/
    mapa_infestacao_screen.dart
    mapa_infestacao_screen_fixed.dart
    mapa_infestacao_screen_clean.dart
    detalhes_talhao_screen.dart
    lista_alertas_screen.dart
  widgets/infestacao/
    thermal_infestation_map.dart
    infestation_history_widget.dart
    legend_infestion_levels.dart
    filters_infestion_panel.dart
```

Backend (Node.js):
```
api/
  routes/infestation.routes.ts
  controllers/infestation.controller.ts
  services/infestation.service.ts
  db/migrations/20xx_xx_xx_infestation.sql
```

---

## 2) Banco de Dados (SQLite local + Backend SQL)

### 2.1 Tabelas Principais (SQL genérico)
```sql
-- Talhão (já existente)
CREATE TABLE IF NOT EXISTS talhao (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  cultura_id TEXT NOT NULL,
  area_ha REAL NOT NULL,
  geom_polygon TEXT NOT NULL -- GeoJSON do polígono do talhão
);

-- Catálogo de Organismos (já existente/expandir)
CREATE TABLE IF NOT EXISTS organism_catalog (
  id TEXT PRIMARY KEY,
  nome_comum TEXT NOT NULL,
  nome_cientifico TEXT,
  tipo TEXT CHECK(tipo IN ('praga','doenca','planta_daninha','deficiencia')) NOT NULL,
  low_threshold REAL DEFAULT 5.0,
  medium_threshold REAL DEFAULT 15.0,
  high_threshold REAL DEFAULT 30.0,
  peso_risco REAL DEFAULT 1.0 -- multiplicador de risco
);

-- Monitoramento (já existente)
CREATE TABLE IF NOT EXISTS monitoring (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  data_utc TEXT NOT NULL,
  usuario_id TEXT,
  observacoes TEXT,
  FOREIGN KEY (talhao_id) REFERENCES talhao(id)
);

-- Pontos do Monitoramento (já existente/expandir)
CREATE TABLE IF NOT EXISTS monitoring_point (
  id TEXT PRIMARY KEY,
  monitoring_id TEXT NOT NULL,
  lat REAL NOT NULL,
  lon REAL NOT NULL,
  accuracy_m REAL,
  organismo_id TEXT NOT NULL,
  quantidade INTEGER DEFAULT 0,
  unidade TEXT, -- ex: insetos/m², plantas/m², % folhas com sintomas etc
  infestation_index REAL NOT NULL, -- 0–100
  notas TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (monitoring_id) REFERENCES monitoring(id),
  FOREIGN KEY (organismo_id) REFERENCES organism_catalog(id)
);

-- Resumo de Infestação por Talhão/Organismo/Janela
CREATE TABLE IF NOT EXISTS infestation_summary (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  organismo_id TEXT NOT NULL,
  periodo_ini TEXT NOT NULL,
  periodo_fim TEXT NOT NULL,
  avg_infestation REAL NOT NULL,
  level TEXT CHECK(level IN ('BAIXO','MODERADO','ALTO','CRITICO')) NOT NULL,
  last_update TEXT NOT NULL,
  geojson_heat TEXT, -- GeoJSON/hexbin opcional
  FOREIGN KEY (talhao_id) REFERENCES talhao(id),
  FOREIGN KEY (organismo_id) REFERENCES organism_catalog(id)
);

-- Alertas de Infestação
CREATE TABLE IF NOT EXISTS infestation_alert (
  id TEXT PRIMARY KEY,
  talhao_id TEXT NOT NULL,
  organismo_id TEXT NOT NULL,
  level TEXT CHECK(level IN ('BAIXO','MODERADO','ALTO','CRITICO')) NOT NULL,
  description TEXT,
  origin TEXT DEFAULT 'auto',
  created_at TEXT NOT NULL,
  acknowledged_at TEXT,
  FOREIGN KEY (talhao_id) REFERENCES talhao(id),
  FOREIGN KEY (organismo_id) REFERENCES organism_catalog(id)
);

-- Índices e Desempenho
CREATE INDEX IF NOT EXISTS idx_mp_monitoring ON monitoring_point(monitoring_id);
CREATE INDEX IF NOT EXISTS idx_mp_org ON monitoring_point(organismo_id);
CREATE INDEX IF NOT EXISTS idx_sum_talhao_org ON infestation_summary(talhao_id, organismo_id);
CREATE INDEX IF NOT EXISTS idx_alert_talhao_org ON infestation_alert(talhao_id, organismo_id);
```

### 2.2 Regras de Integridade
- `infestation_index` ∈ [0,100].
- `accuracy_m` opcional; considerar para ponderação.
- `geojson_heat` permite cache do grid/hexbin.

### 2.3 Migração
- Criar migration correspondente em backend e app (drift/sqflite) com versionamento.

---

## 3) Cálculos e Classificação

### 3.1 Níveis de Severidade
```
BAIXO:     0–25%
MODERADO:  26–50%
ALTO:      51–75%
CRITICO:   76–100%
```

> Ajustável por organismo via thresholds do catálogo.

### 3.2 Determinação do Nível (por ponto)
```
level(point) =
  if pct <= low_threshold → BAIXO
  else if pct <= medium_threshold → MODERADO
  else if pct <= high_threshold → ALTO
  else → CRITICO
```

### 3.3 Severidade Composta por Talhão (janela de datas)
- Média ponderada por:
  - precisão GPS (`w_acc = 1 / (1 + accuracy_m)` truncado a [0.5, 1.0])
  - recência (decay exponencial): `w_time = exp(-Δdias / τ)` com τ padrão 14 dias
  - densidade amostral local (opcional): `w_density`

```
score = Σ( pct_i * w_acc_i * w_time_i * w_density_i ) / Σ( w_acc_i * w_time_i * w_density_i )
```

Converter `score` → nível conforme thresholds do organismo.

### 3.4 Risco (para alertas/priorização)
```
risco = score * peso_risco (do organismo)
```

### 3.5 Heatmap/Interpolação
Opções suportadas (selecionável):
1) **IDW (Inverse Distance Weighting)**: \( v(x) = \frac{\sum v_i / d(x,x_i)^p}{\sum 1 / d(x,x_i)^p} \) com `p` ∈ [1,3].
2) **KDE (Kernel Density Estimation)** sobre pontos com kernel gaussiano (σ ajustável).
3) **Hexbin** (agregação por grade hexagonal) — rápido e offline-friendly.

Recomendação: hexbin para mobile (performance), com cores discretas por quantis.

---

## 4) Serviços (Dart) — Interfaces Principais

### 4.1 `InfestacaoService`
```dart
abstract class InfestacaoService {
  Future<List<TalhaoResumoModel>> obterResumoTalhoes({DateTime? de, DateTime? ate, String? organismoId});
  Future<InfestationSummary?> calcularResumoTalhao({required String talhaoId, String? organismoId, DateTime? de, DateTime? ate});
  Future<List<Monitoring>> obterUltimosMonitoramentos(String talhaoId, {int limit = 20});
  Stream<InfestationAlert> streamAlertas();
}
```

### 4.2 `InfestacaoIntegrationService`
```dart
abstract class InfestacaoIntegrationService {
  Future<void> processMonitoringForInfestation(Monitoring monitoring);
}
```

Implementação sugerida (resumo):
```dart
class InfestacaoIntegrationServiceImpl implements InfestacaoIntegrationService {
  final MonitoringCalculationService calc;
  final InfestacaoRepository repo;
  final ModulesIntegrationService modules;

  InfestacaoIntegrationServiceImpl(this.calc, this.repo, this.modules);

  @override
  Future<void> processMonitoringForInfestation(Monitoring m) async {
    // 1) Normaliza e valida pontos
    final pontos = await repo.obterPontos(m.id);
    if (pontos.isEmpty) return;

    // 2) Agrupa por organismo
    final byOrg = <String, List<MonitoringPoint>>{};
    for (final p in pontos) {
      byOrg.putIfAbsent(p.organismoId, () => []).add(p);
    }

    // 3) Para cada organismo calcula score e nível
    final now = DateTime.now().toUtc();
    for (final entry in byOrg.entries) {
      final orgId = entry.key;
      final pontosOrg = entry.value;
      final result = calc.computeCompositeScore(pontosOrg, now: now);
      final level = calc.levelFromPct(result.scorePct, organismoId: orgId);

      await repo.upsertSummary(
        talhaoId: m.talhaoId,
        organismoId: orgId,
        periodoIni: m.dataUtc.subtract(const Duration(days: 7)),
        periodoFim: m.dataUtc,
        avgPct: result.scorePct,
        level: level,
        heatGeoJson: result.hexbinGeoJson,
      );

      // 4) Alertas
      if (calc.shouldAlert(level: level, pct: result.scorePct, organismoId: orgId)) {
        await repo.createAlert(
          talhaoId: m.talhaoId,
          organismoId: orgId,
          level: level,
          description: 'Nível $level detectado para organismo $orgId (%.1f%%)'.replaceFirst('%', result.scorePct.toStringAsFixed(1)),
        );
      }
    }

    // 5) Atualiza resumo do talhão integrado
    await modules.updateTalhaoResumoFromInfestation(m.talhaoId);
  }
}
```

### 4.3 `MonitoringCalculationService` (núcleo)
```dart
class CompositeScoreResult {
  final double scorePct; // 0–100
  final String? hexbinGeoJson; // opcional
  CompositeScoreResult(this.scorePct, {this.hexbinGeoJson});
}

abstract class MonitoringCalculationService {
  double pctFromQuantity({required int quantity, required String unidade, required OrganismCatalog org, required int totalPlantas});
  String levelFromPct(double pct, {required String organismoId});
  bool shouldAlert({required String level, required double pct, required String organismoId});
  CompositeScoreResult computeCompositeScore(List<MonitoringPoint> pontos, {required DateTime now});
}
```

### 4.4 Repositórios — Assinaturas resumidas
```dart
abstract class InfestacaoRepository {
  Future<List<MonitoringPoint>> obterPontos(String monitoringId);
  Future<void> upsertSummary({required String talhaoId, required String organismoId, required DateTime periodoIni, required DateTime periodoFim, required double avgPct, required String level, String? heatGeoJson});
  Future<void> createAlert({required String talhaoId, required String organismoId, required String level, String? description});
  Stream<InfestationAlert> streamAlertas();
}
```

---

## 5) UI/UX (Flutter)

### 5.1 Mapa Principal (`MapaInfestacaoScreen`)
- **Camadas**:
  - Polígonos dos talhões (GeoJSON)
  - **Marcadores por ponto** (cor por nível)
  - **Heatmap/Hexbin** opcional
- **Controles**:
  - Filtros (cultura/talhão/organismo/data/nível)
  - Alternância Satélite/Terreno (MapTiler/MapLibre)
  - Legenda fixa flutuante
  - Indicador de precisão GPS (quando em modo live)

### 5.2 Widget `ThermalInfestationMap`
- Propriedades: `points`, `polygons`, `mode: points|heat|hex`, `legend`, `onTapFeature`.
- Renderização otimizada: canvas layer para hexbin (cache local por talhão+janela).

### 5.3 Históricos e Detalhes
- `detalhes_talhao_screen.dart`: curva temporal (últimos 30/60/90 dias) por organismo.
- `lista_alertas_screen.dart`: feed de alertas com filtros e confirmação.

### 5.4 Cores e Legenda (padrão)
- BAIXO: verde • MODERADO: amarelo • ALTO: laranja • CRÍTICO: vermelho.
- Tema adaptável por configuração do cliente.

---

## 6) Integração com Módulos Existentes

### 6.1 ModulesIntegrationService 
- Atualiza **ResumoTalhão** agregando: última infestação por organismo, data do último alerta, indicador geral do talhão.
- Emite eventos para **Relatório Premium** e **Aplicação/Prescrição** (pré-preenche alvo/área/praga).

### 6.2 Monitoramento → Mapa
- Após `saveMonitoringWithFix()` concluir, chamar `InfestacaoIntegrationService.processMonitoringForInfestation(m)`.
- Histórico integrado: vínculo de cada resumo/alerta com `monitoring_id` origem (audit trail).

### 6.3 Gestão de Infestação
- Alertas críticos podem abrir fluxo rápido para **recomendação** (sem custos), criando **racional técnico** com anexos.

---

## 7) API (Backend Node.js) — Contratos

### 7.1 Rotas
```
GET   /infestacoes/resumo?talhaoId=&organismoId=&de=&ate=
GET   /infestacoes/talhao/:talhaoId/historico?organismoId=&dias=30
POST  /infestacoes/processar  { monitoringId }
GET   /infestacoes/alertas?talhaoId=&status=pending|ack&de=&ate=
POST  /infestacoes/alertas/:id/ack
```
**deve seguir o padrao do modulo catalogo de organismo e regras de infestacao**

### 7.2 Schemas (JSON)
```json
// InfestationSummary
{
  "talhaoId": "...",
  "organismoId": "...",
  "periodo": {"ini": "2025-08-01T00:00:00Z", "fim": "2025-08-31T23:59:59Z"},
  "avgPct": 42.3,
  "level": "MODERADO",
  "heat": {"mode": "hex", "geojson": "..."}
}
```

```json
// InfestationAlert
{
  "id": "...",
  "talhaoId": "...",
  "organismoId": "...",
  "level": "CRITICO",
  "description": "Nível CRITICO detectado...",
  "createdAt": "2025-08-31T12:03:22Z",
  "acknowledgedAt": null
}
```

---

## 8) Lógica de Heatmap/Hexbin (Cliente)

### 8.1 Hexbin (recomendado)
- Gerar grade hexagonal sobre **bbox** do talhão.
- Agregar `pct` médio por célula com pesos `w_acc` e `w_time`.
- Converter para GeoJSON FeatureCollection; cache por chave `talhaoId|organismo|de|ate|res`.

### 8.2 IDW/KDE (opcional)
- Calcular raster simples em canvas a baixa resolução (128–256 px por lado) e escalar.
- Paleta discreta por quebras de classe (quantis) para legibilidade em campo.

---

## 9) Sincronização e Offline

- **SQLite** como fonte primária; fila de sync com **status** (pending/sent/failed).
- Conflitos: última escrita vence por entidade **não-derivada**; entidades derivadas (summary/heat) são recalculadas no cliente ou servidor.
- Anexos (fotos georreferenciadas) ficam referenciados por `monitoring_point.id`.

---

## 10) Segurança e Permissões

- JWT obrigatório em rotas.
- Claims recomendadas: `role`, `scopes=[infestation.read, infestation.write, alerts.ack]`.
- No app, ocultar dados por fazenda/usuário conforme permissões do backend.

---

## 11) Performance

- Índices conforme Seção 2.1.
- Cache de hexbins por período (TTL 24h ou até novo monitoramento do talhão).
- Lazy loading por viewport (carregar apenas talhões visíveis).

---

## 12) Testes (QA)

### 12.1 Unit
- Cálculo de `levelFromPct` (limiares e bordas).
- `computeCompositeScore` com pesos (accuracy/time).
- Geração de hexbin: contagem e valores médios corretos.

### 12.2 Integração
- Pipeline `saveMonitoringWithFix` → `processMonitoringForInfestation` → `summary + alert`.
- API `/infestacoes/resumo` respeitando filtros e data.

### 12.3 UI
- Renderização de polígonos e pontos; legenda coerente.
- Filtros persistentes e reativos.

---

## 13) Exemplos de Código (Flutter — trechos)

### 13.1 Legenda de Níveis
```dart
class LegendInfestationLevels extends StatelessWidget {
  const LegendInfestationLevels({super.key});
  @override
  Widget build(BuildContext context) {
    final items = const [
      ('BAIXO', 'Verde'),
      ('MODERADO', 'Amarelo'),
      ('ALTO', 'Laranja'),
      ('CRÍTICO', 'Vermelho'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Níveis de Infestação', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final it in items) Row(children: [
              Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(3))),
              Text(it.$1)
            ])
          ],
        ),
      ),
    );
  }
}
```

### 13.2 Cálculo Composto (esqueleto)
```dart
class MonitoringCalculationServiceImpl implements MonitoringCalculationService {
  @override
  CompositeScoreResult computeCompositeScore(List<MonitoringPoint> pts, {required DateTime now}) {
    double num = 0, den = 0;
    for (final p in pts) {
      final acc = p.accuracyM ?? 3.0; // metros
      final wAcc = (1 / (1 + acc)).clamp(0.5, 1.0);
      final dtDays = now.difference(p.createdAt).inHours / 24.0;
      const tau = 14.0; // dias
      final wTime = math.exp(-dtDays / tau);
      final w = wAcc * wTime;
      num += p.infestationIndex * w;
      den += w;
    }
    final score = den == 0 ? 0 : (num / den);
    // opcional: gerar hexbin aqui
    return CompositeScoreResult(score);
  }

  @override
  String levelFromPct(double pct, {required String organismoId}) {
    final org = /* obter org do catálogo */ throw UnimplementedError();
    if (pct <= org.lowThreshold) return 'BAIXO';
    if (pct <= org.mediumThreshold) return 'MODERADO';
    if (pct <= org.highThreshold) return 'ALTO';
    return 'CRITICO';
  }

  @override
  bool shouldAlert({required String level, required double pct, required String organismoId}) {
    // Ex.: alertar em ALTO e CRITICO sempre; ou MODERADO se tendência de alta
    return level == 'ALTO' || level == 'CRITICO';
  }

  @override
  double pctFromQuantity({required int quantity, required String unidade, required OrganismCatalog org, required int totalPlantas}) {
    // Converter conforme unidade/organismo (customizável)
    return (quantity / totalPlantas.clamp(1, 1<<31)) * 100.0;
  }
}
```

### 13.3 Tile Provider (MapLibre/MapTiler)
```dart
```

---


---

## 15) Observabilidade
- Eventos: `infestation.summary.updated`, `infestation.alert.created`, `map.render.heat.start/end`.
- Métricas: tempo de geração de hexbin, nº pontos processados, TTL de cache.

---

## 16) Roadmap
- [✔] MVP: pontos + resumo + alertas
- [✔] Hexbin cacheado

---

## 17) Checklist de Entrega
- [ ] Migrations aplicadas (app/back)
- [ ] Services integrados com ModulesIntegrationService
- [ ] UI: filtros + legenda + camadas + detalhes
- [ ] Geração e cache de hexbin

---

## 18) Anexos Rápidos (JSON Exemplo)
```json
{
  "talhaoId": "TALHAO_A",
  "organismoId": "EUSCHISTUS_HEROS",
  "periodo": {"ini": "2025-08-01T00:00:00Z", "fim": "2025-08-31T23:59:59Z"},
  "avgPct": 68.2,
  "level": "ALTO",
  "heat": {"mode": "hex", "geojson": "{...}"}
}
```

---

> **Observação final**: Esta especificação foi desenhada para plugar no ecossistema FortSmart já existente (monitoramento, talhões, relatórios premium, prescrição, histórico). Os cálculos são parametrizáveis por organismo e podem ser refinados com dados reais após as primeiras safras.

