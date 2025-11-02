# 🔍 DIAGNÓSTICO - Prioridade de Arquivo Customizado

## ⚠️ PROBLEMA IDENTIFICADO

Nem todos os serviços estão verificando o arquivo customizado!

---

## ✅ SERVIÇOS QUE JÁ VERIFICAM (OK)

### 1. PhenologicalInfestationService ✅
**Arquivo:** `lib/services/phenological_infestation_service.dart`
```dart
// ✅ CORRETO: Verifica arquivo customizado primeiro
final customFile = await _getCustomCatalogFile();
if (await customFile.exists()) {
  jsonString = await customFile.readAsString();
} else {
  jsonString = await _loadMultiCultureCatalog();
}
```
**Status:** ✅ Prioriza organism_catalog_custom.json

### 2. InfestationRulesEditScreen ✅
**Arquivo:** `lib/screens/configuracao/infestation_rules_edit_screen.dart`
```dart
// ✅ CORRETO: Salva e carrega customizações
final customFile = await _getCustomCatalogFile();
await customFile.writeAsString(jsonString);
```
**Status:** ✅ Salva e carrega corretamente

---

## ❌ SERVIÇOS QUE NÃO VERIFICAM (PROBLEMA)

### 1. OrganismRecommendationsService ❌
**Arquivo:** `lib/services/organism_recommendations_service.dart`
```dart
// ❌ PROBLEMA: Carrega direto do assets
final filePath = 'assets/data/organismos_$culturaNormalizada.json';
final jsonString = await rootBundle.loadString(filePath);
```
**Impacto:** Recomendações de aplicação não usam customizações

### 2. AgronomicSeverityCalculator ❌
**Arquivo:** `lib/services/agronomic_severity_calculator.dart`
```dart
// ❌ PROBLEMA: Tenta carregar de lib/data (não existe)
final fileName = 'lib/data/organismos_${cropName.toLowerCase()}.json';
final file = File(fileName);
```
**Impacto:** Cálculo de severidade não usa customizações

### 3. OrganismLoaderService ❌
**Arquivo:** `lib/services/organism_loader_service.dart`
```dart
// ❌ PROBLEMA: Carrega direto do assets
final filePath = 'assets/data/organismos_$cultureName.json';
final jsonString = await rootBundle.loadString(filePath);
```
**Impacto:** Geração de thresholds não considera customizações

### 4. OrganismCatalogLoaderService ❌
**Arquivo:** `lib/services/organism_catalog_loader_service.dart`
```dart
// ❌ PROBLEMA: Carrega direto do assets
jsonString = await rootBundle.loadString('$_basePath/organismos_$cultureName.json');
```
**Impacto:** Catálogo de organismos não usa customizações

---

## 🎯 SERVIÇOS QUE PRECISAM SER CORRIGIDOS

| Serviço | Arquivo | Status | Impacto |
|---------|---------|--------|---------|
| PhenologicalInfestationService | phenological_infestation_service.dart | ✅ OK | Cálculo de níveis |
| InfestationRulesEditScreen | infestation_rules_edit_screen.dart | ✅ OK | Edição/salvamento |
| **OrganismRecommendationsService** | organism_recommendations_service.dart | ❌ CORRIGIR | Recomendações |
| **AgronomicSeverityCalculator** | agronomic_severity_calculator.dart | ❌ CORRIGIR | Severidade |
| **OrganismLoaderService** | organism_loader_service.dart | ❌ CORRIGIR | Thresholds |
| **OrganismCatalogLoaderService** | organism_catalog_loader_service.dart | ❌ CORRIGIR | Catálogo |

---

## 🔧 CORREÇÃO NECESSÁRIA

Adicionar verificação do arquivo customizado em cada serviço:

```dart
/// Padrão a seguir em TODOS os serviços
Future<Map<String, dynamic>> loadData() async {
  // 1️⃣ VERIFICAR ARQUIVO CUSTOMIZADO PRIMEIRO
  final directory = await getApplicationDocumentsDirectory();
  final customFile = File('${directory.path}/organism_catalog_custom.json');
  
  if (await customFile.exists()) {
    Logger.info('✅ Usando catálogo CUSTOMIZADO da fazenda');
    final jsonString = await customFile.readAsString();
    return json.decode(jsonString);
  }
  
  // 2️⃣ FALLBACK: Carregar JSONs padrão
  Logger.info('📄 Usando catálogo PADRÃO do projeto');
  final jsonString = await rootBundle.loadString('assets/data/organismos_*.json');
  return json.decode(jsonString);
}
```

---

## 📊 IMPACTO ATUAL

### Onde as customizações FUNCIONAM ✅
- ✅ Relatório Agronômico → Aba "Infestação Fenológica"
- ✅ Cards de infestação com níveis (BAIXO, MÉDIO, ALTO, CRÍTICO)
- ✅ Cálculo de frequência e média por ponto

### Onde as customizações NÃO FUNCIONAM ❌
- ❌ Recomendações de Aplicação (usa JSONs padrão)
- ❌ Cálculo de Severidade Agronômica (usa JSONs padrão)
- ❌ Card "Nova Ocorrência" (usa thresholds gerados, não customizados)

---

## ✅ SOLUÇÃO

Preciso corrigir 4 serviços para verificar o arquivo customizado antes de carregar os JSONs padrão.

**Deseja que eu faça essas correções agora?**

---

**Data:** 2025-10-29
**Status:** ⚠️ Parcialmente funcional (1 de 5 serviços verifica customizações)

