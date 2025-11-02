# 🔧 CORREÇÃO: NOVA OCORRÊNCIA - CAMPOS FALTANTES

## ❌ **PROBLEMAS IDENTIFICADOS:**

### **1. Plantas Daninhas não carregam do catálogo**
- O código EXISTE para carregar daninhas
- O JSON TEM plantas daninhas
- Mas não está aparecendo na interface

### **2. Campos faltantes:**
- ❌ Quantidade de pragas
- ❌ Ovoposição
- ❌ Opção "Sem infestação" (valor 0)

---

## ✅ **SOLUÇÃO 1: GARANTIR CARREGAMENTO DE DANINHAS**

### **Arquivo:** `lib/widgets/new_occurrence_card.dart`

**Problema:** A lógica de detecção pode estar falhando.

**Solução:** Adicionar logs e garantir que o tipo 'weed' está sendo processado:

```dart
// Linha 373-374 (VERIFICAR)
} else if (tipo == 'planta_daninha' || 
           tipo.contains('daninha') || 
           categoria.contains('daninha') || 
           categoria.contains('weed') ||
           categoria.contains('planta daninha')) {
  organismType = 'weed';
  print('🌿 DANINHA detectada: ${organismo['nome']}');
}
```

**Adicionar contador de daninhas:**
```dart
// Após processar todos os organismos:
print('📊 Organismos carregados:');
print('   - Pragas: ${_organismCache[widget.cropName]!['pest']!.length}');
print('   - Doenças: ${_organismCache[widget.cropName]!['disease']!.length}');
print('   - Daninhas: ${_organismCache[widget.cropName]!['weed']!.length}');
```

---

## ✅ **SOLUÇÃO 2: ADICIONAR CAMPOS FALTANTES**

### **2.1 Campo: Quantidade de Pragas**

**Adicionar após "Tamanho da Infestação":**

```dart
// QUANTIDADE DE PRAGAS (para Pragas)
if (_selectedType == OccurrenceType.pest) {
  Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.numbers, size: 16, color: Colors.orange.shade700),
            SizedBox(width: 8),
            Text(
              'QUANTIDADE DE PRAGAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Quantidade de pragas/m²',
            hintText: 'Ex: 15',
            prefixIcon: Icon(Icons.bug_report),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _quantidadePragas = int.tryParse(value) ?? 0;
            });
          },
        ),
      ],
    ),
  ),
  SizedBox(height: 12),
}
```

### **2.2 Campo: Ovoposição**

```dart
// OVOPOSIÇÃO (para Pragas)
if (_selectedType == OccurrenceType.pest) {
  Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.purple.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.purple.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grain, size: 16, color: Colors.purple.shade700),
            SizedBox(width: 8),
            Text(
              'OVOPOSIÇÃO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Text('Ovoposição detectada?', style: TextStyle(fontSize: 14)),
            ),
            Switch(
              value: _temOvoposicao,
              onChanged: (value) {
                setState(() {
                  _temOvoposicao = value;
                });
              },
              activeColor: Colors.purple,
            ),
          ],
        ),
        
        if (_temOvoposicao) ...[
          SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Quantidade de ovos/m²',
              hintText: 'Ex: 50',
              prefixIcon: Icon(Icons.grain),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _quantidadeOvos = int.tryParse(value) ?? 0;
              });
            },
          ),
        ],
      ],
    ),
  ),
  SizedBox(height: 12),
}
```

### **2.3 Opção: "Sem Infestação"**

**Adicionar botão no topo do card:**

```dart
// OPÇÃO "SEM INFESTAÇÃO" (antes do tipo de ocorrência)
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.green.shade300),
  ),
  child: Row(
    children: [
      Checkbox(
        value: _semInfestacao,
        onChanged: (value) {
          setState(() {
            _semInfestacao = value ?? false;
            if (_semInfestacao) {
              // Resetar valores
              _agronomicSeverity = 0;
              _selectedType = OccurrenceType.pest;
              _selectedOrganismId = '';
              _selectedOrganismName = 'Sem infestação';
            }
          });
        },
        activeColor: Colors.green,
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ SEM INFESTAÇÃO DETECTADA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Marque se o ponto está livre de pragas/doenças/daninhas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
```

---

## 🔧 **VARIÁVEIS DE ESTADO NECESSÁRIAS:**

```dart
// Adicionar no State:
int _quantidadePragas = 0;
bool _temOvoposicao = false;
int _quantidadeOvos = 0;
bool _semInfestacao = false;
```

---

## 📊 **DADOS ENVIADOS AO SALVAR:**

```dart
final occurrenceData = {
  'organism_id': _selectedOrganismId,
  'organism_name': _semInfestacao ? 'Sem infestação' : _selectedOrganismName,
  'type': _selectedType.toString().split('.').last,
  'agronomic_severity': _semInfestacao ? 0.0 : _agronomicSeverity,
  'quantity': _semInfestacao ? 0 : _quantidadePragas,
  'oviposition': _temOvoposicao,
  'eggs_count': _quantidadeOvos,
  'infestation_size_mm': _infestationSize,
  'temperature': _temperature,
  'humidity': _humidity,
  // ... outros campos
};
```

---

## 🎯 **RESULTADO ESPERADO:**

### **UI do Card Nova Ocorrência:**

```
┌─────────────────────────────────────────┐
│ ✅ SEM INFESTAÇÃO DETECTADA            │
│ □ Marque se o ponto está livre         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Selecione o Tipo:                       │
│ [Praga] [Doença] [Daninha]             │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Buscar organismo...                     │
│ 🐛 Lagarta-da-soja                      │
│ 🐛 Percevejo-marrom                     │
│ 🌿 Buva (se selecionado Daninha)       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ QUANTIDADE DE PRAGAS                    │
│ Quantidade de pragas/m²: [15]          │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ OVOPOSIÇÃO                              │
│ Ovoposição detectada? [Switch: ON]     │
│ Quantidade de ovos/m²: [50]            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ SEVERIDADE VISUAL (0-10)                │
│ [0][1][2][3][4][5][6][7][8][9][10]    │
└─────────────────────────────────────────┘
```

---

## 📝 **IMPLEMENTAÇÃO NECESSÁRIA:**

1. ✅ Verificar log de carregamento de daninhas
2. ✅ Adicionar campo "Quantidade de Pragas"
3. ✅ Adicionar campo "Ovoposição" (switch + quantidade)
4. ✅ Adicionar checkbox "Sem Infestação"
5. ✅ Adaptar lógica de salvamento para incluir novos campos

---

**Data:** 28/10/2025  
**Módulo:** Nova Ocorrência - Card de Monitoramento  
**Sistema:** FortSmart Agro  

