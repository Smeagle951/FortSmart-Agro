# 🔥 CORREÇÃO DO MOTOR DE HEATMAP - FORTSMART AGRO

## 📋 **SITUAÇÃO ATUAL**

### ❌ **PROBLEMAS IDENTIFICADOS:**

1. **Módulo "Mapa de Infestação"** está com problemas
2. **Card de Infestação no "Relatório Agronômico"** não está funcionando corretamente
3. Dados georreferenciados **JÁ EXISTEM** mas não estão sendo usados corretamente

---

## 🧠 **CONCEITO TÉCNICO (Arquitetura Ideal)**

### **DADOS DISPONÍVEIS:**
Cada ponto de monitoramento possui:
- ✅ **Georreferenciamento:** `latitude`, `longitude`
- ✅ **Vinculação:** `cultura`, `variedade`, `talhao_id`
- ✅ **Temporal:** `data_hora`, `ciclo_fenologico`
- ✅ **Ocorrências:** `pragas`, `doenças`, `daninhas`, `níveis de severidade`

### **PROBLEMA:**
Os dados existem, mas o **motor de heatmap não está gerando corretamente** a visualização térmica.

---

## ⚙️ **IMPLEMENTAÇÃO RECOMENDADA**

### **1️⃣ REMOVER DADOS TEMPORÁRIOS**

#### ❌ **Abordagem Antiga (Problemática):**
```dart
// Durante monitoramento, salva em cache/memória
List<MonitoringPoint> _tempPoints = [];

// Problema: Se o app fechar, dados são perdidos
```

#### ✅ **Abordagem Nova (Recomendada):**
```dart
// Salvar IMEDIATAMENTE no banco com flag de status
await db.insert('monitoring_points', {
  'id': uuid.v4(),
  'monitoramento_id': sessionId,
  'latitude': currentLat,
  'longitude': currentLng,
  'status': 'em_andamento',  // ✅ Flag de controle
  'timestamp': DateTime.now().toIso8601String(),
});

// Ao finalizar:
await db.update(
  'monitoring_points',
  {'status': 'finalizado'},
  where: 'monitoramento_id = ?',
  whereArgs: [sessionId],
);
```

**Benefícios:**
- ✔ Nenhum dado temporário
- ✔ Rastreabilidade total
- ✔ Permite continuar de onde parou
- ✔ Sincronização automática com backend

---

### **2️⃣ GERAR HEATMAP AUTOMÁTICO DO TALHÃO**

#### **Lógica de Geração:**

```dart
// 1. BUSCAR PONTOS FINALIZADOS DO TALHÃO
final pontos = await db.rawQuery('''
  SELECT 
    mp.latitude,
    mp.longitude,
    mo.tipo,
    mo.subtipo,
    mo.nivel,
    mo.percentual,
    mp.timestamp
  FROM monitoring_points mp
  JOIN monitoring_occurrences mo ON mo.point_id = mp.id
  WHERE mp.talhao_id = ? 
    AND mp.status = 'finalizado'
    AND mp.timestamp >= datetime('now', '-30 days')
  ORDER BY mp.timestamp DESC
''', [talhaoId]);

// 2. CALCULAR PESO DE CADA PONTO
for (final ponto in pontos) {
  final peso = _calcularPesoPonto(
    tipo: ponto['tipo'],
    nivel: ponto['nivel'],
    percentual: ponto['percentual'],
  );
  
  heatmapData.add({
    'lat': ponto['latitude'],
    'lng': ponto['longitude'],
    'peso': peso,
    'cor': _determinarCor(peso),
  });
}

// 3. GERAR CAMADA TÉRMICA ADAPTATIVA
final heatmap = HeatmapLayer(
  points: heatmapData.map((p) => 
    WeightedLatLng(
      LatLng(p['lat'], p['lng']),
      weight: p['peso'],
    )
  ).toList(),
  radius: 50,
  opacity: 0.7,
);
```

#### **Cálculo de Peso:**
```dart
double _calcularPesoPonto({
  required String tipo,
  required String nivel,
  required double percentual,
}) {
  double pesoBase = 0.0;
  
  // Peso por tipo
  switch (tipo.toLowerCase()) {
    case 'praga':
      pesoBase = 1.0;
      break;
    case 'doença':
      pesoBase = 1.2;  // Doenças têm peso maior
      break;
    case 'planta daninha':
      pesoBase = 0.8;
      break;
  }
  
  // Multiplicador por nível
  double multiplicador = 1.0;
  switch (nivel.toLowerCase()) {
    case 'crítico':
      multiplicador = 3.0;
      break;
    case 'alto':
      multiplicador = 2.0;
      break;
    case 'médio':
      multiplicador = 1.5;
      break;
    case 'baixo':
      multiplicador = 1.0;
      break;
  }
  
  // Fator de percentual
  final fatorPercentual = percentual / 100.0;
  
  return pesoBase * multiplicador * fatorPercentual;
}
```

#### **Cores Adaptativas:**
```dart
Color _determinarCor(double peso) {
  if (peso >= 2.0) return Colors.red;        // Crítico
  if (peso >= 1.5) return Colors.orange;     // Alto
  if (peso >= 1.0) return Colors.yellow;     // Médio
  return Colors.green;                       // Baixo
}
```

---

### **3️⃣ MODO INTEGRADO COM MAPA DE INFESTAÇÃO**

#### **Fluxo de Dados:**

```
┌─────────────────────┐
│   MONITORAMENTO     │
│  (Ponto GPS Salvo)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   BANCO DE DADOS    │
│  monitoring_points  │
│ monitoring_occurrences
└──────────┬──────────┘
           │
           ├──────────────────┐
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────┐
│ MAPA INFESTAÇÃO  │  │ RELATÓRIO        │
│ (Recalcula índice│  │ AGRONÔMICO       │
│  automaticamente)│  │ (Mostra análise) │
└──────────────────┘  └──────────────────┘
```

#### **Trigger Automático:**
```dart
// Ao salvar novo ponto/ocorrência:
class MonitoringPointService {
  Future<void> savePoint(MonitoringPoint point) async {
    // 1. Salvar ponto
    await db.insert('monitoring_points', point.toMap());
    
    // 2. TRIGGER: Recalcular índice do talhão automaticamente
    await _infestationMapService.recalcularIndiceTalhao(point.talhaoId);
    
    // 3. Sincronizar com backend
    await _syncService.syncPoint(point);
  }
}
```

---

## 🧩 **ARQUITETURA DE DADOS**

### **Tabela: `monitoring_points`**

| Campo              | Tipo      | Descrição                          |
|--------------------|-----------|------------------------------------|
| `id`               | TEXT      | UUID único do ponto                |
| `monitoramento_id` | TEXT      | ID do monitoramento (sessão)       |
| `talhao_id`        | TEXT      | ID do talhão                       |
| `latitude`         | REAL      | Coordenada GPS                     |
| `longitude`        | REAL      | Coordenada GPS                     |
| `status`           | TEXT      | `em_andamento` / `finalizado`      |
| `timestamp`        | TEXT      | Data e hora ISO8601                |
| `created_at`       | TEXT      | Data de criação                    |
| `updated_at`       | TEXT      | Última atualização                 |

### **Tabela: `monitoring_occurrences`**

| Campo              | Tipo      | Descrição                          |
|--------------------|-----------|------------------------------------|
| `id`               | TEXT      | UUID único da ocorrência           |
| `point_id`         | TEXT      | FK para `monitoring_points.id`     |
| `tipo`             | TEXT      | `Praga` / `Doença` / `Daninha`     |
| `subtipo`          | TEXT      | Nome do organismo                  |
| `nivel`            | TEXT      | `Baixo` / `Médio` / `Alto` / `Crítico` |
| `percentual`       | REAL      | % de infestação                    |
| `agronomic_severity` | REAL    | Severidade agronômica (0-10)       |
| `foto_paths`       | TEXT      | JSON array de caminhos de fotos    |
| `observacao`       | TEXT      | Observações do técnico             |

---

## 🎯 **CORREÇÕES NECESSÁRIAS**

### **Arquivo: `lib/services/heatmap_generator_service.dart` (CRIAR)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

class HeatmapGeneratorService {
  /// Gera heatmap automático para um talhão
  static Future<List<Map<String, dynamic>>> gerarHeatmapTalhao(String talhaoId) async {
    try {
      Logger.info('🔥 Gerando heatmap para talhão: $talhaoId');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar pontos finalizados dos últimos 30 dias
      final pontos = await db.rawQuery('''
        SELECT 
          mp.latitude,
          mp.longitude,
          mo.tipo,
          mo.subtipo,
          mo.nivel,
          mo.percentual,
          mo.agronomic_severity,
          mp.timestamp
        FROM monitoring_points mp
        JOIN monitoring_occurrences mo ON mo.point_id = mp.id
        WHERE mp.talhao_id = ? 
          AND mp.status = 'finalizado'
          AND mp.timestamp >= datetime('now', '-30 days')
        ORDER BY mp.timestamp DESC
      ''', [talhaoId]);
      
      Logger.info('📊 ${pontos.length} pontos encontrados');
      
      final heatmapData = <Map<String, dynamic>>[];
      
      for (final ponto in pontos) {
        final peso = _calcularPesoPonto(
          tipo: ponto['tipo'] as String,
          nivel: ponto['nivel'] as String,
          percentual: (ponto['percentual'] as num?)?.toDouble() ?? 0.0,
        );
        
        final cor = _determinarCor(peso);
        
        heatmapData.add({
          'latitude': (ponto['latitude'] as num).toDouble(),
          'longitude': (ponto['longitude'] as num).toDouble(),
          'peso': peso,
          'cor': cor,
          'tipo': ponto['tipo'],
          'subtipo': ponto['subtipo'],
          'nivel': ponto['nivel'],
          'timestamp': ponto['timestamp'],
        });
      }
      
      Logger.info('✅ Heatmap gerado com ${heatmapData.length} pontos');
      
      return heatmapData;
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar heatmap: $e');
      return [];
    }
  }
  
  static double _calcularPesoPonto({
    required String tipo,
    required String nivel,
    required double percentual,
  }) {
    double pesoBase = 0.0;
    
    switch (tipo.toLowerCase()) {
      case 'praga':
        pesoBase = 1.0;
        break;
      case 'doença':
        pesoBase = 1.2;
        break;
      case 'planta daninha':
        pesoBase = 0.8;
        break;
    }
    
    double multiplicador = 1.0;
    switch (nivel.toLowerCase()) {
      case 'crítico':
        multiplicador = 3.0;
        break;
      case 'alto':
        multiplicador = 2.0;
        break;
      case 'médio':
        multiplicador = 1.5;
        break;
      case 'baixo':
        multiplicador = 1.0;
        break;
    }
    
    final fatorPercentual = (percentual / 100.0).clamp(0.1, 1.0);
    
    return pesoBase * multiplicador * fatorPercentual;
  }
  
  static Color _determinarCor(double peso) {
    if (peso >= 2.0) return Colors.red;
    if (peso >= 1.5) return Colors.orange;
    if (peso >= 1.0) return Colors.yellow.shade700;
    return Colors.green;
  }
}
```

---

## 📝 **PRÓXIMOS PASSOS**

1. ✅ **JSON Interpretado** - IMPLEMENTADO
2. ⏳ **Criar `HeatmapGeneratorService`** - PENDENTE
3. ⏳ **Corrigir módulo "Mapa de Infestação"** - PENDENTE
4. ⏳ **Corrigir card de Infestação no Relatório Agronômico** - PENDENTE
5. ⏳ **Implementar flag `status` nos pontos** - PENDENTE
6. ⏳ **Trigger automático para recalcular índice** - PENDENTE

---

## 🎯 **RESULTADO ESPERADO**

```
Usuário realiza monitoramento
    ↓
Pontos salvos com status="em_andamento"
    ↓
Usuário finaliza monitoramento
    ↓
Status atualizado para "finalizado"
    ↓
Trigger recalcula heatmap automaticamente
    ↓
Mapa de Infestação e Relatório Agronômico
  mostram heatmap atualizado em tempo real
```

---

**Data:** 28/10/2025  
**Versão:** 1.0  
**Sistema:** FortSmart Agro  

