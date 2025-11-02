# 🌾 Sincronização de Relatórios Agronômicos com Base44

## 📋 Visão Geral

Sistema completo de sincronização de **Relatórios Agronômicos** com a plataforma Base44, incluindo:
- ✅ Dados de Monitoramento
- ✅ Análise de Infestação
- ✅ Mapas Térmicos (Heatmaps)
- ✅ Dados Georreferenciados
- ✅ Análises e Métricas

---

## 🎯 O Que é Sincronizado

### 1. **Relatório Agronômico Completo**
O método `syncAgronomicReport()` envia TODOS os dados em um único relatório:

**Dados Incluídos:**
- ✅ Dados de monitoramento por período
- ✅ Análise completa de infestação
- ✅ Mapas térmicos georreferenciados
- ✅ Distribuição de severidade
- ✅ Organismos encontrados
- ✅ Métricas e estatísticas

### 2. **Análise de Infestação**
- Total de monitoramentos
- Total de pontos coletados
- Total de ocorrências
- Organismos encontrados (com geolocalização)
- Distribuição de severidade (baixo, médio, alto, crítico)
- Severidade média por organismo

### 3. **Mapa Térmico (Heatmap)**
- Pontos georreferenciados (latitude/longitude)
- Intensidade normalizada (0-1)
- Severidade em porcentagem (0-100)
- Cor hexadecimal por nível
- Classificação de nível (low, medium, high, critical)
- Organismos por ponto

---

## 🚀 Como Usar

### Exemplo Completo na Tela de Relatórios

```dart
import 'package:flutter/material.dart';
import '../services/base44_sync_service.dart';
import '../utils/logger.dart';

class AgronomicReportsSyncScreen extends StatefulWidget {
  const AgronomicReportsSyncScreen({super.key});

  @override
  State<AgronomicReportsSyncScreen> createState() => _AgronomicReportsSyncScreenState();
}

class _AgronomicReportsSyncScreenState extends State<AgronomicReportsSyncScreen> {
  final Base44SyncService _base44 = Base44SyncService();
  bool _isSyncing = false;
  String? _lastSyncResult;

  @override
  void initState() {
    super.initState();
    // Configurar token (carregar de SharedPreferences)
    _base44.setAuthToken('seu-token-base44');
  }

  Future<void> _syncAgronomicReport() async {
    setState(() {
      _isSyncing = true;
      _lastSyncResult = null;
    });

    try {
      // Sincronizar relatório dos últimos 30 dias
      final result = await _base44.syncAgronomicReport(
        farmId: 'fazenda-123',
        talhaoId: 'talhao-456',
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now(),
        includeHeatmap: true,
        includeInfestationData: true,
        includeMonitoringData: true,
      );

      setState(() {
        if (result['success']) {
          _lastSyncResult = '✅ Relatório sincronizado!\nID: ${result['report_id']}';
        } else {
          _lastSyncResult = '❌ Erro: ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _lastSyncResult = '❌ Erro na sincronização: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar com Base44'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relatório Agronômico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sincroniza dados completos de monitoramento, '
                      'infestação e mapas térmicos com o Base44.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncAgronomicReport,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar Relatório'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_lastSyncResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_lastSyncResult!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Sincronizar Apenas Infestação

```dart
final result = await _base44.syncInfestationData(
  farmId: 'fazenda-123',
  talhaoId: 'talhao-456',
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

if (result['success']) {
  print('✅ Dados de infestação sincronizados!');
}
```

### Sincronizar Apenas Mapa Térmico

```dart
final result = await _base44.syncHeatmap(
  farmId: 'fazenda-123',
  talhaoId: 'talhao-456',
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

if (result['success']) {
  print('✅ Mapa térmico sincronizado!');
  print('Pontos enviados: ${result['points_count']}');
}
```

---

## 📡 Endpoints do Base44

### Base URL
```
https://api.base44.com.br/v1
```

### 1. Relatório Agronômico Completo
```
POST /agronomic-reports/sync
```

### 2. Sincronização de Infestação
```
POST /infestation/sync
```

### 3. Sincronização de Mapa Térmico
```
POST /heatmap/sync
```

### 4. Status de Sincronização
```
GET /farms/{farmId}/sync-status
```

### 5. Histórico de Sincronizações
```
GET /farms/{farmId}/sync-history
```

---

## 📊 Estrutura dos Dados Enviados

### Relatório Agronômico Completo

```json
{
  "report_type": "agronomic_complete",
  "farm_id": "fazenda-123",
  "talhao_id": "talhao-456",
  
  "period": {
    "start_date": "2025-10-01T00:00:00Z",
    "end_date": "2025-11-02T23:59:59Z",
    "generated_at": "2025-11-02T10:30:00Z"
  },
  
  "summary": {
    "total_monitorings": 45,
    "total_points": 1250,
    "date_range": {
      "first": "2025-10-01T08:00:00Z",
      "last": "2025-11-02T16:30:00Z"
    }
  },
  
  "monitoring_data": [...],
  "infestation_analysis": {...},
  "heatmap_data": [...],
  
  "metadata": {
    "app_version": "1.0.0",
    "source": "FortSmart Agro",
    "sync_date": "2025-11-02T10:30:00Z"
  }
}
```

### Análise de Infestação

```json
{
  "total_monitorings": 45,
  "total_points": 1250,
  "total_occurrences": 3420,
  
  "organisms": [
    {
      "id": "lagarta-helicoverpa",
      "name": "Helicoverpa armigera",
      "count": 1250,
      "average_severity": 45.8,
      "locations": [
        {
          "latitude": -20.123456,
          "longitude": -54.123456,
          "severity": 65.0,
          "date": "2025-11-02T14:30:00Z"
        }
      ]
    }
  ],
  
  "severity_distribution": {
    "low": 850,
    "medium": 1200,
    "high": 980,
    "critical": 390
  }
}
```

### Dados de Mapa Térmico

```json
[
  {
    "latitude": -20.123456,
    "longitude": -54.123456,
    "intensity": 0.65,
    "severity": 65.0,
    "color": "#FF9800",
    "level": "high",
    "occurrence_count": 15,
    "date": "2025-11-02T14:30:00Z",
    "organisms": [
      {
        "id": "123",
        "name": "Lagarta",
        "severity": 65.0
      }
    ]
  }
]
```

---

## 🎨 Mapa Térmico - Sistema de Cores

| Nível | Severidade | Cor | Hex | Ação |
|---|---|---|---|---|
| **Baixo** | 0-24% | 🟢 Verde | #4CAF50 | Monitoramento normal |
| **Médio** | 25-49% | 🟡 Amarelo | #FFEB3B | Atenção recomendada |
| **Alto** | 50-74% | 🟠 Laranja | #FF9800 | Intervenção necessária |
| **Crítico** | 75-100% | 🔴 Vermelho | #FF0000 | Ação imediata |

---

## ⚡ Casos de Uso

### 1. Sincronização Automática Semanal

```dart
class WeeklySync {
  final Base44SyncService _base44 = Base44SyncService();
  
  Future<void> performWeeklySync() async {
    final talhoes = await _getTalhoes();
    
    for (final talhao in talhoes) {
      await _base44.syncAgronomicReport(
        farmId: currentFarm.id,
        talhaoId: talhao.id,
        startDate: DateTime.now().subtract(Duration(days: 7)),
        endDate: DateTime.now(),
      );
    }
  }
}
```

### 2. Sincronização Manual na Tela

```dart
// Botão na tela de relatórios
FloatingActionButton(
  onPressed: () async {
    final result = await base44.syncAgronomicReport(
      farmId: farm.id,
      talhaoId: talhao.id,
      startDate: startDate,
      endDate: endDate,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['success'] ? 'Sucesso!' : 'Erro'),
        content: Text(result['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  },
  child: const Icon(Icons.cloud_upload),
)
```

---

## 🔐 Autenticação

### Configurar Token

```dart
// Após login ou ao iniciar o app
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('base44_token');

if (token != null) {
  final base44 = Base44SyncService();
  base44.setAuthToken(token);
}
```

---

## 📝 Logs

Todos os passos são logados:

```dart
Logger.info('🌾 [BASE44] Iniciando sincronização de relatório agronômico...');
Logger.info('📍 Fazenda: $farmId | Talhão: $talhaoId');
Logger.info('✅ 45 monitoramentos coletados');
Logger.info('✅ Relatório de infestação gerado');
Logger.info('✅ 1250 pontos de mapa térmico gerados');
Logger.info('✅ [BASE44] Relatório agronômico sincronizado com sucesso');
```

---

## ✅ Conclusão

O sistema está **pronto para sincronizar**:

✅ Relatórios Agronômicos Completos  
✅ Dados de Monitoramento  
✅ Análises de Infestação  
✅ Mapas Térmicos Georreferenciados  
✅ Métricas e Estatísticas

**Pronto para uso em produção!**

---

**Desenvolvido para FortSmart Agro**  
*Sistema de Gestão Agrícola Inteligente*

