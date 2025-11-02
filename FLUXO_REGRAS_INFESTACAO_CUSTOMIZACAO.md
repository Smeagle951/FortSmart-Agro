# 🔧 FLUXO DE REGRAS DE INFESTAÇÃO - CUSTOMIZAÇÃO

## 📋 COMO FUNCIONA O SISTEMA DE REGRAS

### 1️⃣ PRIORIDADE DE LEITURA

O sistema carrega dados de infestação seguindo esta ordem:

```
1. organism_catalog_custom.json (CUSTOMIZADO pelo usuário)
   ↓ se não existir ↓
2. organismos_*.json (PADRÃO do projeto)
   ↓ fallback ↓
3. Valores hardcoded (último recurso)
```

---

## 📁 LOCALIZAÇÃO DOS ARQUIVOS

### **Arquivos Padrão** (Não são alterados)
```
assets/data/organismos_soja.json
assets/data/organismos_milho.json
assets/data/organismos_algodao.json
...
```
- ✅ Contém dados científicos padrão
- ✅ Versionados no projeto
- ❌ **NÃO são modificados** quando o usuário edita regras

### **Arquivo Customizado** (Alterado pelo usuário)
```
[Documents]/organism_catalog_custom.json
```
- ✅ Criado quando o usuário salva customizações
- ✅ Sobrescreve os valores padrão
- ✅ Específico da fazenda/dispositivo
- ✅ **ESTE ARQUIVO É MODIFICADO** nas edições

---

## 🎯 MÓDULO "REGRAS DE INFESTAÇÃO"

### Localização
**Tela:** `lib/screens/configuracao/infestation_rules_edit_screen.dart`

### Funcionalidades
1. ✅ Listar todas as culturas e organismos
2. ✅ Exibir thresholds atuais (do JSON padrão ou customizado)
3. ✅ Editar valores de BAIXO, MÉDIO, ALTO, CRÍTICO com sliders
4. ✅ Salvar customizações em `organism_catalog_custom.json`
5. ✅ Restaurar valores padrão (deletar customizações)

### Como Funciona
```dart
// 1. Carrega JSONs padrão (assets/data/organismos_*.json)
final cultureData = await _loaderService.loadCultureOrganisms('custom_soja');

// 2. Usuário edita thresholds via sliders
void _updateThreshold(organism, stage, 'low', 3.0) {
  stageData['low'] = 3; // Atualiza em memória
}

// 3. Salva no arquivo customizado
await customFile.writeAsString(jsonString);
// Salvo em: [Documents]/organism_catalog_custom.json
```

---

## 🔄 FLUXO COMPLETO DE CUSTOMIZAÇÃO

### Passo 1: Usuário Acessa "Regras de Infestação"
```
Menu → Configurações → Regras de Infestação
```

### Passo 2: Sistema Carrega Dados
```dart
// PhenologicalInfestationService.initialize()
if (organism_catalog_custom.json existe) {
  // Usa customizações do usuário ✅
  carrega organism_catalog_custom.json
} else {
  // Usa JSONs padrão do projeto ✅
  carrega organismos_soja.json, organismos_milho.json, etc.
}
```

### Passo 3: Usuário Edita Thresholds
```
Cultura: Soja
Organismo: Lagarta-da-soja
Estágio: V1-V3

BAIXO:   [====|-------] 2 → 3 lagartas/metro
MÉDIO:   [========|---] 5 → 6 lagartas/metro
ALTO:    [===========|] 8 → 9 lagartas/metro
CRÍTICO: [==============] 12 → 13 lagartas/metro
```

### Passo 4: Sistema Salva Customizações
```dart
// InfestationRulesEditScreen._saveCatalog()
final customFile = await _getCustomCatalogFile();
// [Documents]/organism_catalog_custom.json

await customFile.writeAsString(jsonString);
// ✅ Salvo com sucesso
```

### Passo 5: Sistema Usa Customizações
```dart
// PhenologicalInfestationService._getThresholdsForStage()

// 1. Tenta usar limiares_especificos (se existir)
// 2. Tenta usar niveis_infestacao
// 3. Tenta usar phenological_thresholds (gerado)

// ✅ Valores vêm do organism_catalog_custom.json
final baixo = 3;  // Customizado (era 2)
final medio = 6;  // Customizado (era 5)
final alto = 9;   // Customizado (era 8)
```

---

## ⚠️ PROBLEMA ATUAL IDENTIFICADO

### ❌ O QUE NÃO ESTÁ FUNCIONANDO

Quando o usuário edita no módulo "Regras de Infestação":
```
✅ As alterações são salvas em organism_catalog_custom.json
❌ MAS os JSONs padrão (organismos_*.json) NÃO são atualizados
```

### Por que isso é um problema?

Se o arquivo customizado for deletado ou o app for reinstalado:
- ❌ Perde todas as customizações
- ❌ Volta aos valores padrão
- ❌ Não há sincronização entre dispositivos

---

## ✅ SOLUÇÃO RECOMENDADA

### Opção 1: Usar apenas organism_catalog_custom.json (ATUAL)
**Prós:**
- ✅ Simples de implementar
- ✅ Não modifica arquivos do projeto
- ✅ Cada fazenda tem suas regras

**Contras:**
- ❌ Dados não versionados com o app
- ❌ Perdidos se app for desinstalado
- ❌ Não sincronizam entre dispositivos

### Opção 2: Salvar em Banco de Dados SQLite (RECOMENDADO)
**Prós:**
- ✅ Dados persistentes no banco local
- ✅ Pode sincronizar com servidor
- ✅ Backup automático
- ✅ Histórico de alterações

**Contras:**
- ⚠️ Requer implementação adicional

### Opção 3: Modificar JSONs padrão do projeto (NÃO RECOMENDADO)
**Prós:**
- ✅ Customizações versionadas

**Contras:**
- ❌ Modifica arquivos do projeto
- ❌ Conflitos em atualizações
- ❌ Perde separação padrão/customizado

---

## 🎯 ESTADO ATUAL

### ✅ O QUE JÁ FUNCIONA

1. **Carregamento em Camadas:**
   ```
   organism_catalog_custom.json (se existir)
   OU
   organismos_*.json (padrão)
   ```

2. **Módulo de Edição:**
   - Interface funcional
   - Sliders para ajustar thresholds
   - Salva em organism_catalog_custom.json

3. **Cálculo de Infestação:**
   - Usa dados do arquivo customizado (se existir)
   - Fallback para JSONs padrão
   - Valores decimais (1.33, não 1)

### ❌ O QUE FALTA

1. **Sincronização:**
   - Customizações não sincronizam entre dispositivos
   
2. **Backup:**
   - Sem backup automático de customizações

3. **Histórico:**
   - Não rastreia quem/quando alterou

---

## 📊 EXEMPLO COMPLETO

### Cenário: Fazenda quer threshold mais rígido

**JSON Padrão** (`organismos_soja.json`):
```json
"niveis_infestacao": {
  "baixo": "1-2 lagartas/metro",
  "medio": "3-5 lagartas/metro",
  "alto": "6-8 lagartas/metro",
  "critico": ">8 lagartas/metro"
}
```

**Usuário edita no módulo:**
```
BAIXO: 2 → 1 (mais restritivo)
MÉDIO: 5 → 3
ALTO: 8 → 5
```

**Salvo em** `organism_catalog_custom.json`:
```json
{
  "cultures": {
    "soja": {
      "organisms": {
        "pests": [{
          "name": "Lagarta-da-soja",
          "phenological_thresholds": {
            "V1-V3": {
              "low": 1,
              "medium": 3,
              "high": 5,
              "critical": 8
            }
          }
        }]
      }
    }
  }
}
```

**Sistema usa:**
```
Monitoramento: 1.33 lagartas/ponto
Threshold: baixo ≤ 1, médio ≤ 3
Resultado: MÉDIO (1.33 > 1) ✅
```

---

## 🚀 RESPOSTA À SUA PERGUNTA

### ❌ Os JSONs de cada organismo (assets/data/) NÃO são alterados

Quando você edita no módulo "Regras de Infestação":
- ✅ As alterações são salvas em `organism_catalog_custom.json`
- ❌ Os arquivos `organismos_*.json` permanecem inalterados

### ✅ O sistema TODO É ATUALIZADO

Mas o sistema inteiro usa as regras customizadas porque:
1. `PhenologicalInfestationService` carrega o arquivo customizado PRIMEIRO
2. Todos os cálculos usam o serviço
3. As customizações aplicam-se a:
   - Relatório Agronômico
   - Mapa de Infestação
   - Monitoramento
   - Alertas

---

## 💡 RECOMENDAÇÃO

Para melhor integração, implementar **tabela no banco de dados**:

```sql
CREATE TABLE infestation_rules_custom (
  id TEXT PRIMARY KEY,
  culture_id TEXT NOT NULL,
  organism_id TEXT NOT NULL,
  phenological_stage TEXT NOT NULL,
  threshold_low INTEGER,
  threshold_medium INTEGER,
  threshold_high INTEGER,
  threshold_critical INTEGER,
  modified_by TEXT,
  modified_at TEXT,
  UNIQUE(culture_id, organism_id, phenological_stage)
);
```

Benefícios:
- ✅ Persistência confiável
- ✅ Sincronização com servidor
- ✅ Backup automático
- ✅ Auditoria de mudanças

Deseja que eu implemente isso?

---

**Última Atualização:** 2025-10-29
**Status:** ✅ Sistema funcional, customizações em arquivo separado

