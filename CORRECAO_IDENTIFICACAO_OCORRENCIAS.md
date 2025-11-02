# Correção: Ocorrências Mostrando "Infestação Não Identificada"

## 🐛 Problema Reportado

Na tela de **Detalhes do Monitoramento** e outros módulos, as ocorrências cadastradas no **Card de Nova Ocorrência** estavam aparecendo como **"Infestação não identificada"** ao invés de mostrar o nome correto da praga/doença/planta daninha.

## 🔍 Diagnóstico

### Causa Raiz

**Inconsistência nos nomes dos campos** entre os diferentes módulos do sistema:

**No Card de Nova Ocorrência** (`new_occurrence_card.dart`):
- Salvava com o campo: `'organismo'`

**Na Tela de Histórico** (`monitoring_history_view_screen.dart`):
- Buscava por: `'name'`, `'subtipo'`, `'organism_name'`
- ❌ **NÃO buscava por:** `'organismo'`

**No Serviço de Histórico** (`monitoring_history_service.dart`):
- Tentava buscar do catálogo usando `organismo_id`
- Se falhasse, usava: `'Infestação não identificada'`
- ❌ **NÃO buscava por:** `'organismo'` direto dos dados

### Fluxo do Problema

```
1. Usuário cadastra: "Lagarta-do-cartucho"
   ↓
2. Salvo como: { 'organismo': 'Lagarta-do-cartucho' }
   ↓
3. Histórico busca por: 'name', 'subtipo', 'organism_name'
   ↓
4. Nenhum campo encontrado ❌
   ↓
5. Resultado: "Infestação não identificada"
```

## ✅ Solução Implementada

### 1. Adicionar Campos de Compatibilidade ao Salvar

**Arquivo:** `lib/widgets/new_occurrence_card.dart`

```dart
final novaOcorrencia = {
  'id': DateTime.now().millisecondsSinceEpoch.toString(),
  'tipo': _selectedType.name,
  'organismo': _selectedOrganismName,
  'organismo_id': _selectedOrganismId,
  
  // ✅ NOVOS CAMPOS DE COMPATIBILIDADE
  'organism_name': _selectedOrganismName,
  'name': _selectedOrganismName,
  'subtipo': _selectedOrganismName,
  
  'severidade': _selectedSeverity,
  // ... outros campos
};
```

### 2. Buscar Campo 'organismo' no Histórico

**Arquivo:** `lib/screens/monitoring/monitoring_history_view_screen.dart`

```dart
Widget _buildOccurrenceItem(Map<String, dynamic> occurrence) {
  String name = occurrence['name'] as String? ?? '';
  if (name.isEmpty) {
    name = occurrence['subtipo'] as String? ?? '';
  }
  if (name.isEmpty) {
    name = occurrence['organism_name'] as String? ?? '';
  }
  // ✅ ADICIONADO
  if (name.isEmpty) {
    name = occurrence['organismo'] as String? ?? '';
  }
  if (name.isEmpty) {
    name = 'Infestação não identificada';
  }
  // ...
}
```

### 3. Buscar em Múltiplos Campos no Serviço

**Arquivo:** `lib/services/monitoring_history_service.dart`

```dart
// Tentar buscar o nome do organismo de diferentes campos
// ✅ ADICIONADO
if (subtipo.isEmpty && row['organismo'] != null) {
  subtipo = row['organismo'] as String;
}
if (subtipo.isEmpty && row['organism_name'] != null) {
  subtipo = row['organism_name'] as String;
}
if (subtipo.isEmpty && row['name'] != null) {
  subtipo = row['name'] as String;
}
if (subtipo.isEmpty) {
  subtipo = 'Infestação não identificada';
}
```

### 4. Garantir Compatibilidade ao Converter Dados

**Arquivo:** `lib/widgets/new_occurrence_card.dart` (função `_saveAllOccurrences`)

```dart
final ocorrenciasData = _ocorrenciasAdicionadas.map((oc) => {
  'type': oc['tipo'],
  'name': oc['organismo'],
  // ✅ CAMPOS ADICIONADOS
  'organism_name': oc['organismo'],
  'subtipo': oc['organismo'],
  'organismo': oc['organismo'],
  'organismId': oc['organismo_id'],
  'organismo_id': oc['organismo_id'],
  // ... outros campos
}).toList();
```

## 📊 Tabela de Compatibilidade

| Módulo | Campos Utilizados | Status |
|--------|-------------------|--------|
| **Nova Ocorrência** | `organismo`, `organism_name`, `name`, `subtipo` | ✅ Salva todos |
| **Histórico View** | `name`, `subtipo`, `organism_name`, `organismo` | ✅ Busca todos |
| **Histórico Service** | `organismo`, `organism_name`, `name` | ✅ Busca todos |
| **Outros Módulos** | Qualquer um dos campos acima | ✅ Compatível |

## 🔄 Fluxo Corrigido

```
1. Usuário cadastra: "Lagarta-do-cartucho"
   ↓
2. Salvo como: { 
     'organismo': 'Lagarta-do-cartucho',
     'organism_name': 'Lagarta-do-cartucho',
     'name': 'Lagarta-do-cartucho',
     'subtipo': 'Lagarta-do-cartucho'
   }
   ↓
3. Histórico busca por: 'name', 'subtipo', 'organism_name', 'organismo'
   ↓
4. ✅ Campo encontrado: "Lagarta-do-cartucho"
   ↓
5. ✅ Resultado: "Lagarta-do-cartucho"
```

## 📝 Arquivos Modificados

1. ✅ `lib/widgets/new_occurrence_card.dart`
   - Adiciona campos de compatibilidade ao criar ocorrência
   - Adiciona campos ao converter para salvar

2. ✅ `lib/screens/monitoring/widgets/new_occurrence_modal.dart`
   - Adiciona campos de compatibilidade ao criar infestação

3. ✅ `lib/screens/monitoring/monitoring_point_screen.dart`
   - Busca organismo em múltiplos campos ao salvar
   - Adiciona suporte para campos `'organismo'` e `'observacoes'`

4. ✅ `lib/screens/monitoring/monitoring_history_view_screen.dart`
   - Busca também pelo campo `'organismo'`

5. ✅ `lib/services/monitoring_history_service.dart`
   - Busca em múltiplos campos antes de usar fallback

## 🧪 Como Testar

### 1. Cadastrar Nova Ocorrência

1. Abra o **Card de Nova Ocorrência**
2. Selecione tipo: **Praga**
3. Busque e selecione: **"Lagarta-do-cartucho"**
4. Preencha outros campos
5. Clique em **"Adicionar Ocorrência"**
6. Clique em **"Salvar"**

### 2. Verificar no Histórico

1. Acesse **Histórico de Monitoramento**
2. Verifique se aparece: **"Lagarta-do-cartucho"**
3. ✅ **NÃO deve aparecer:** "Infestação não identificada"

### 3. Verificar em Outros Módulos

1. Acesse **Detalhes do Monitoramento**
2. Acesse **Mapa de Infestação**
3. Acesse **Relatórios**
4. Em todos eles, o nome correto deve aparecer

## 🎯 Campos Salvos

Agora cada ocorrência contém **todos estes campos** para máxima compatibilidade:

```json
{
  "id": "1727876543210",
  "tipo": "pest",
  "type": "pest",
  
  // ✅ Nome do organismo em 4 formatos
  "organismo": "Lagarta-do-cartucho",
  "organism_name": "Lagarta-do-cartucho",
  "name": "Lagarta-do-cartucho",
  "subtipo": "Lagarta-do-cartucho",
  
  // ✅ ID do organismo em 2 formatos
  "organismo_id": "123",
  "organismId": "123",
  
  // Outros campos...
  "severidade": 5,
  "plantSection": "Baixeiro",
  "observations": "...",
  // etc
}
```

## ✅ Resultado Final

**ANTES:**
```
📋 Histórico de Monitoramento
  🐛 Infestação não identificada  ❌
  🐛 Infestação não identificada  ❌
  🐛 Infestação não identificada  ❌
```

**DEPOIS:**
```
📋 Histórico de Monitoramento
  🐛 Lagarta-do-cartucho          ✅
  🦠 Ferrugem asiática            ✅
  🌿 Capim-arroz                  ✅
```

---

**Data da Correção:** 01/10/2025  
**Desenvolvedor:** Assistente AI  
**Status:** ✅ Implementado e Testado  
**Backward Compatible:** ✅ Sim (funciona com dados antigos e novos)

