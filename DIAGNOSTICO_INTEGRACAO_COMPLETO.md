# 🔍 DIAGNÓSTICO COMPLETO: MONITORAMENTO → MAPA DE INFESTAÇÃO

## RESUMO EXECUTIVO
**Status:** ❌ INTEGRAÇÃO PARCIAL  
**Problema Principal:** Dados não fluem corretamente entre módulos  
**Impacto:** Mapa de Infestação e Heatmap ficam vazios

---

## 🎯 FLUXO ESPERADO (IDEAL)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. MONITORAMENTO                                                │
│    └─ Técnico registra ocorrência (Lagarta, 85%, GPS)          │
│                                                                  │
│ 2. SALVAMENTO                                                   │
│    ├─ monitoring_occurrences (dados brutos)                    │
│    ├─ infestation_map (dados processados para o mapa)          │
│    └─ Trigger: Integração automática                           │
│                                                                  │
│ 3. PROCESSAMENTO IA                                            │
│    ├─ FortSmart AI analisa severidade agronômica              │
│    ├─ Calcula percentual de infestação                         │
│    └─ Gera recomendações                                       │
│                                                                  │
│ 4. MAPA DE INFESTAÇÃO                                          │
│    ├─ Lê de infestation_map                                    │
│    ├─ Exibe marcadores GPS                                     │
│    └─ Gera heatmap inteligente                                 │
│                                                                  │
│ 5. RELATÓRIOS AGRONÔMICOS                                      │
│    └─ Análise completa com dados da IA                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## ❌ PROBLEMAS IDENTIFICADOS

### **PROBLEMA 1: Múltiplas Telas de Monitoramento**

**Telas Encontradas:**
1. `point_monitoring_screen.dart` ✅ Principal (usa DirectOccurrenceService)
2. `improved_point_monitoring_screen.dart` ⚠️ Duplicata (salvamento diferente)
3. `unified_point_monitoring_screen.dart` ⚠️ Duplicata (salvamento diferente)
4. `monitoring_point_screen.dart` ⚠️ Outra versão (salvamento diferente)

**Problema:** Cada tela salva de forma diferente!

---

### **PROBLEMA 2: Tabelas Desincronizadas**

**Tabelas do Banco:**

| Tabela | Uso | Status |
|--------|-----|--------|
| `monitoring_occurrences` | Dados brutos do monitoramento | ✅ CORRETA |
| `monitoring_points` | Pontos GPS com metadados | ✅ CORRETA |
| `monitoring_sessions` | Sessões de monitoramento | ✅ CORRETA |
| `infestation_map` | Dados processados para o mapa | ❌ **VAZIA!** |
| `infestation_summaries` | Resumos por organismo | ❌ Não usada |
| `infestation_alerts` | Alertas automáticos | ❌ Não usada |

**Problema Crítico:**
- `monitoring_occurrences` TEM dados ✅
- `infestation_map` ESTÁ VAZIA ❌
- **FALTA SINCRONIZAÇÃO AUTOMÁTICA!**

---

### **PROBLEMA 3: Serviços de Integração Não Chamados**

**Serviços Disponíveis:**
1. `DirectOccurrenceService` ✅ Salva em `monitoring_occurrences`
2. `MonitoringInfestationIntegrationService` ⚠️ Deveria sincronizar, mas não é chamado
3. `InfestacaoIntegrationService` ⚠️ Processa dados, mas não automático
4. `IntelligentHeatmapService` ❌ Não recebe dados

**Linha 624 de `monitoring_point_screen.dart`:**
```dart
await _infestacaoRepository.insert(infestacao); // ✅ Salva
await _sendToInfestationModule(infestacao, occurrence); // ⚠️ Método existe?
```

**VERIFICAÇÃO NECESSÁRIA:** O método `_sendToInfestationModule` está implementado?

---

### **PROBLEMA 4: Heatmap Sem Dados**

**`IntelligentHeatmapService.generateIntelligentHeatmap()`:**
```dart
required List<InfestacaoModel> occurrences, // ❌ Lista vazia!
required List<MonitoringPoint> monitoringPoints, // ✅ Tem dados
```

**Linha 22:**
```dart
final groupedOccurrences = _groupOccurrencesByPoint(occurrences, monitoringPoints);
```

**SE `occurrences` está vazio → heatmap fica vazio!**

---

### **PROBLEMA 5: Mapa Lê da Tabela Errada**

**`infestation_map_screen.dart` linha 354:**
```dart
Future<void> _loadInfestationData() async {
  // Usa MonitoringInfestationIntegrationService
  final integrationService = MonitoringInfestationIntegrationService();
  final talhaoSummaries = await integrationService.getInfestationDataForTalhao(talhao.id);
}
```

**`MonitoringInfestationIntegrationService.getAllMonitorings()` lê de:**
- ✅ `monitoring_sessions`
- ✅ `monitoring_points`
- ✅ `monitoring_occurrences`

**MAS o heatmap precisa de dados em `infestation_map`!**

---

## 🛠️ SOLUÇÃO PROPOSTA

### **CORREÇÃO 1: Criar Serviço Único de Salvamento**

**Arquivo: `lib/services/unified_occurrence_save_service.dart`**

```dart
class UnifiedOccurrenceSaveService {
  
  /// Salva ocorrência EM TODOS OS LUGARES necessários
  static Future<bool> saveOccurrence({
    required String sessionId,
    required String pointId,
    required String talhaoId,
    required Map<String, dynamic> occurrenceData,
  }) async {
    try {
      // 1. Salvar em monitoring_occurrences
      await DirectOccurrenceService.saveOccurrence(...);
      
      // 2. Salvar em infestation_map (para o mapa funcionar)
      await _saveToInfestationMap(...);
      
      // 3. Chamar integração automática
      await _triggerIntegration(sessionId);
      
      // 4. Processar com IA FortSmart
      await _processWithAI(...);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

### **CORREÇÃO 2: Gatilho Automático Após Salvar**

**Adicionar em `point_monitoring_screen.dart` após linha 821:**

```dart
await _saveOccurrenceFromCard(data);

// ✅ ADICIONAR ISSO:
await _syncToInfestationMap(data);
await _triggerIntegrationService();
```

---

### **CORREÇÃO 3: Popular `infestation_map` Automaticamente**

**Criar migração de dados:**

```sql
-- Copiar dados de monitoring_occurrences para infestation_map
INSERT INTO infestation_map (
  id, ponto_id, talhao_id, organismo_id, organismo_nome,
  tipo, nivel, infestacao_percent, intensidade_media,
  latitude, longitude, data_hora_ocorrencia
)
SELECT 
  id, point_id, talhao_id, subtipo, subtipo,
  tipo, nivel, percentual, percentual,
  latitude, longitude, data_hora
FROM monitoring_occurrences
WHERE id NOT IN (SELECT id FROM infestation_map);
```

---

### **CORREÇÃO 4: Atualizar Heatmap para Ler Dados Corretos**

**`infestation_map_screen.dart` linha 354:**

```dart
// ANTES (não funciona):
final occurrences = await _infestacaoRepository.getAll();

// DEPOIS (funciona):
final occurrences = await _getOccurrencesFromMonitoring();
```

---

## 📊 VERIFICAÇÃO NECESSÁRIA

Execute este SQL no banco para diagnóstico:

```sql
-- 1. Contar ocorrências em cada tabela
SELECT 'monitoring_occurrences' as tabela, COUNT(*) as total 
FROM monitoring_occurrences
UNION ALL
SELECT 'infestation_map', COUNT(*) 
FROM infestation_map;

-- 2. Ver últimas ocorrências
SELECT id, tipo, subtipo, percentual, data_hora 
FROM monitoring_occurrences 
ORDER BY data_hora DESC 
LIMIT 5;

-- 3. Verificar se infestation_map está vazio
SELECT COUNT(*) as total_infestation_map 
FROM infestation_map;
```

---

## 🎯 AÇÃO IMEDIATA

**PRIORIDADE 1:** Criar serviço de sincronização automática  
**PRIORIDADE 2:** Popular `infestation_map` com dados existentes  
**PRIORIDADE 3:** Atualizar todas as telas para usar o serviço único  
**PRIORIDADE 4:** Testar fluxo completo com dados reais

---

## ✅ CRITÉRIOS DE SUCESSO

Após correções, DEVE funcionar:

1. ✅ Registrar ocorrência no monitoramento
2. ✅ Aparecer IMEDIATAMENTE no Mapa de Infestação
3. ✅ Gerar heatmap com cores e intensidades
4. ✅ Exibir análises da IA FortSmart
5. ✅ Mostrar dados completos no Relatório Agronômico

---

**Data:** 28/10/2025  
**Desenvolvedor:** FortSmart Agro Team  
**Status:** EM CORREÇÃO

