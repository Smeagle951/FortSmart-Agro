# 🔧 CORREÇÃO DE ERROS DE COMPILAÇÃO - FORTSMART AGRO

## ✅ **ARQUIVOS CRIADOS (Faltavam):**

### 1️⃣ `lib/models/infestation_rule.dart` ✅ CRIADO
- Modelo para regras de infestação personalizadas
- Define thresholds para níveis (baixo/médio/alto/crítico)
- Métodos para determinar nível de alerta

### 2️⃣ `lib/repositories/infestation_rules_repository.dart` ✅ CRIADO
- Repositório para gerenciar regras de infestação
- CRUD completo de regras
- Integração com banco de dados

###3️⃣ Wakelock ✅ CORRIGIDO
- Substituído `wakelock` por `wakelock_plus`
- Atualizado `waiting_next_point_screen.dart`

---

## 🔧 **ERROS RESTANTES E CORREÇÕES:**

### 1️⃣ **monitoring_session_service.dart**
**Erro:** Campo `_infestationRulesRepository` ausente
**Status:** ✅ **CORRIGIDO**
```dart
// Adicionado:
final InfestationRulesRepository _infestationRulesRepository = InfestationRulesRepository();
```

**Erro:** `cropId: int.parse()` - tipo incorreto
**Linha:** 426
**Correção Necessária:**
```dart
// ANTES:
cropId: int.parse(session['cultura_id']),

// DEPOIS:
cropId: session['cultura_id'].toString(),
```

---

### 2️⃣ **monitoring_point_screen.dart**
**Múltiplos erros neste arquivo:**

#### a) `OccurrenceType` não encontrado
**Linha:** 276, 290
**Correção:** Adicionar import
```dart
import '../../utils/enums.dart';
```

#### b) `quantity` e `unit` não existem em `Occurrence`
**Linha:** 198
**Correção:** Usar campos corretos
```dart
// ANTES:
subtitle: Text('${occurrence.quantity} ${occurrence.unit}'),

// DEPOIS:
subtitle: Text('${occurrence.infestationIndex}'),
```

#### c) `talhaoId` tipo incorreto
**Linha:** 538
**Correção:**
```dart
// ANTES:
talhaoId: talhaoId,

// DEPOIS:
talhaoId: talhaoId.toString(),
```

#### d) `builder` não existe em `Marker`
**Linha:** 775
**Correção:** Usar parâmetro correto do flutter_map 6.x
```dart
// ANTES:
Marker(
  builder: (ctx) => Container(...),
)

// DEPOIS:
Marker(
  child: Container(...),
)
```

#### e) `processMonitoringData` não existe
**Linha:** 918
**Correção:** Usar método correto
```dart
// Verificar documentação do InfestacaoIntegrationService
// Ou criar wrapper method
```

---

### 3️⃣ **intelligent_infestation_service.dart**

#### a) `getRuleForOrganism` - argumentos incorretos
**Linha:** 253
**Erro:** 3 argumentos passados, mas só aceita 2
**Correção:**
```dart
// ANTES:
await _rulesRepository.getRuleForOrganism(organism.id, cropName, farmId)

// DEPOIS:
await _rulesRepository.getRuleForOrganism(organism.id, cropName)
```

#### b) `getAlertLevel` - tipo incorreto
**Linha:** 269
**Erro:** Passando `int` mas espera `double`
**Correção:**
```dart
// ANTES:
customRule.getAlertLevel(averageQuantity.toInt())

// DEPOIS:
customRule.getAlertLevel(averageQuantity)
```

#### c) `getAlertLevelColor` não existe
**Linha:** 271
**Correção:** Usar método correto
```dart
// ANTES:
customRule.getAlertLevelColor(averageQuantity)

// DEPOIS:
customRule.getAlertColor(averageQuantity)
```

---

## 📋 **RESUMO DAS CORREÇÕES PENDENTES:**

| Arquivo | Erros | Status |
|---------|-------|--------|
| `monitoring_session_service.dart` | 2 | 1✅ 1⏳ |
| `monitoring_point_screen.dart` | 5 | ⏳ |
| `intelligent_infestation_service.dart` | 3 | ⏳ |
| `infestation_rule.dart` | - | ✅ |
| `infestation_rules_repository.dart` | - | ✅ |
| `waiting_next_point_screen.dart` | 1 | ✅ |

---

## 🚀 **PRÓXIMOS PASSOS:**

1. ✅ Corrigir `monitoring_session_service.dart`
2. ⏳ Corrigir `monitoring_point_screen.dart`
3. ⏳ Corrigir `intelligent_infestation_service.dart`
4. ⏳ Testar compilação
5. ⏳ Gerar APK

---

**🌾 FortSmart Agro - Correções Sistemáticas em Andamento** 🔧
