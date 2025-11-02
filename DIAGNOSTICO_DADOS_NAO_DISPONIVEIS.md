# 🔍 DIAGNÓSTICO - "DADOS DE ANÁLISE NÃO DISPONÍVEIS"

## Data: 31/10/2025

---

## 🔴 PROBLEMA RELATADO

Tela mostra: **"Dados de Análise Não Disponíveis"**

---

## 🎯 POSSÍVEIS CAUSAS

### ✅ CAUSA 1: NÃO HÁ OCORRÊNCIAS NO BANCO (mais comum)

**O que acontece:**
```dart
// advanced_analytics_dashboard.dart, linha 431
if (infestacoes.isEmpty) {
  return vazio; // ← Mostra "Não disponíveis"
}
```

**Como verificar:**
1. Verifique os logs:
```
🔍 Buscando ocorrências de monitoring_occurrences...
📊 0 ocorrências encontradas no banco  ← SE MOSTRAR 0, É ISSO!
```

**Solução:**
- Faça um monitoramento NOVO
- Adicione pelo menos 1 ocorrência
- Salve o monitoramento

---

### ✅ CAUSA 2: FILTRO MUITO RESTRITIVO

**O que acontece:**
```dart
// Se filtrar por sessionId que não existe
WHERE mo.session_id = 'abc123'  ← Sessão inexistente
Resultado: 0 ocorrências
```

**Como verificar:**
1. Verifique os logs:
```
🔍 Filtrando por sessão específica: session_123  ← Sessão existe?
ou
🔍 Filtrando por talhão: 5  ← Talhão tem dados?
```

**Solução:**
- Remova o filtro (selecione "Todos Talhões")
- ou
- Selecione um talhão que TEM monitoramentos

---

### ✅ CAUSA 3: DADOS EM OUTRA TABELA

**O que acontece:**
Sistema busca de `monitoring_occurrences` mas dados podem estar em:
- `infestation_data` (tabela antiga)
- `Monitoring` (tabela legado)
- `infestation_map` (apenas para mapa)

**Como verificar:**
Execute no console do app ou SQLite:
```sql
-- Verificar qual tabela tem dados
SELECT COUNT(*) FROM monitoring_occurrences;
SELECT COUNT(*) FROM infestation_data;
SELECT COUNT(*) FROM infestation_map;
```

**Solução:**
Se dados estiverem em outra tabela, precisamos migrar ou buscar de lá também.

---

### ✅ CAUSA 4: ERRO SILENCIOSO

**O que acontece:**
```dart
try {
  // buscar dados
} catch (e) {
  Logger.error('Erro: $e');
  return vazio; // ← Mostra "Não disponíveis"
}
```

**Como verificar:**
Procure nos logs:
```
❌ Erro ao buscar dados reais de infestação: ...
```

**Solução:**
Depende do erro específico (me envie o log completo)

---

## 🔍 CHECKLIST DE DIAGNÓSTICO

### Execute estes passos:

#### 1. Verifique se há dados no banco

**Execute:**
```dart
// Abra o console do app e procure:
📊 X ocorrências encontradas no banco

Se X = 0 → Problema é CAUSA 1
Se X > 0 → Continue para próximo passo
```

#### 2. Verifique os filtros

**Procure nos logs:**
```
🔍 Filtrando por sessão específica: ???
ou
🔍 Filtrando por talhão: ???
ou
⚠️ Sem filtro específico - mostrando todos os dados
```

**Teste:**
- Remova filtros (selecione "Todos")
- Se aparecer dados → Problema é CAUSA 2

#### 3. Verifique se há erros

**Procure nos logs:**
```
❌ Erro ao buscar dados...
❌ Erro ao carregar...
```

**Se encontrar erro:**
- Me envie o erro completo
- Problema é CAUSA 4

#### 4. Verifique tabelas do banco

**No console SQLite ou app:**
```sql
SELECT COUNT(*) as total FROM monitoring_occurrences;
SELECT COUNT(*) as total FROM monitoring_points;
SELECT COUNT(*) as total FROM monitoring_sessions;
```

**Se todos = 0:**
- Banco está vazio
- Precisa fazer monitoramento

---

## 🛠️ SOLUÇÕES RÁPIDAS

### Solução 1: Criar Dados de Teste

1. Abra **Monitoramento**
2. Inicie novo monitoramento
3. Adicione 3 ocorrências:
   - Lagarta-da-soja: 4 unidades
   - Lagarta-da-soja: 6 unidades
   - Lagarta-da-soja: 4 unidades
4. Salve o monitoramento
5. Volte ao Relatório Agronômico

**Espera-se:** Dados aparecem! ✅

---

### Solução 2: Remover Filtros

1. No Relatório Agronômico
2. Aba "Infestação Fenológica"
3. Dropdown de talhão: Selecione **"Todos Talhões"**
4. Aguarde recarregar

**Espera-se:** Se há dados, aparecem! ✅

---

### Solução 3: Verificar Logs Completos

**Me envie os logs procurando por:**
```
🔍 Buscando dados REAIS de infestação
📊 X ocorrências encontradas
📍 TOTAL DE PONTOS MAPEADOS: Y
```

**Se mostrar:**
```
📊 0 ocorrências encontradas
```

**Então:** Banco está vazio - precisa fazer monitoramento!

---

## 🎯 DIAGNÓSTICO AUTOMÁTICO

### Adicione este código para diagnosticar:

Execute no console do Dart/Flutter:
```dart
final db = await AppDatabase.instance.database;

// 1. Verificar ocorrências
final occ = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_occurrences');
print('Ocorrências: ${occ.first['total']}');

// 2. Verificar pontos
final pts = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_points');
print('Pontos: ${pts.first['total']}');

// 3. Verificar sessões
final ses = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_sessions');
print('Sessões: ${ses.first['total']}');

// 4. Ver última ocorrência
final last = await db.rawQuery('SELECT * FROM monitoring_occurrences ORDER BY data_hora DESC LIMIT 1');
print('Última ocorrência: ${last}');
```

**Resultado esperado:**
```
Ocorrências: 12  ← Se 0, banco vazio!
Pontos: 5
Sessões: 2
Última: {organismo: Lagarta-da-soja, quantidade: 4, ...}
```

---

## 📊 FLUXO COMPLETO DA ANÁLISE

```
1. Usuário abre Relatório Agronômico
   ↓
2. Sistema chama _loadRealInfestationData()
   ↓
3. Busca SELECT * FROM monitoring_occurrences WHERE...
   ↓
4. SE infestacoes.isEmpty:
   ├─ Mostra "Dados de Análise Não Disponíveis" ❌
   └─ Mensagem: "Realize monitoramentos no campo..."
   ↓
5. SE infestacoes.length > 0:
   ├─ Calcula média, frequência, índice
   ├─ Determina nível (BAIXO/MÉDIO/ALTO/CRÍTICO)
   └─ Mostra análise completa ✅
```

---

## ⚠️ MENSAGENS QUE VOCÊ PODE VER

### Mensagem 1: "Dados de Análise Não Disponíveis"
```
'Nenhuma infestação detectada.

Realize monitoramentos no campo para ver 
análises fenológicas em tempo real.'
```

**Causa:** `infestacoes.isEmpty = true`  
**Solução:** Fazer monitoramento com ocorrências

---

### Mensagem 2: "Dados de curva de infestação não disponíveis"
```
Aba "Curvas de Infestação"
'Nenhum dado de curva de infestação encontrado.

Realize monitoramentos para gerar análises preditivas.'
```

**Causa:** `_curvaInfestacao == null`  
**Solução:** Precisa de dados históricos para curva

---

### Mensagem 3: "Erro ao carregar dados"
```
'Erro ao carregar relatório agronômico: [erro específico]'
```

**Causa:** Exception no try-catch  
**Solução:** Ver erro específico nos logs

---

## 🔧 CORREÇÃO IMPLEMENTADA

Vou adicionar **logs mais detalhados** para diagnóstico:

```dart
// Antes de buscar
Logger.info('🔍 Filtro: $whereTalhao');
Logger.info('🔍 Args: $whereArgs');

// Depois de buscar
Logger.info('📊 ${infestacoes.length} ocorrências encontradas');

// Se vazio
if (infestacoes.isEmpty) {
  Logger.warning('⚠️ BANCO VAZIO! Faça um monitoramento primeiro.');
}
```

---

## 📋 CHECKLIST RÁPIDO

```
[ ] Há dados no banco? (verificar logs: "📊 X ocorrências")
    └─ SE NÃO: Fazer monitoramento NOVO
    
[ ] Filtro está correto? (verificar logs: "🔍 Filtrando por...")
    └─ SE NÃO: Remover filtro ou escolher talhão correto
    
[ ] Há erros nos logs? (procurar: "❌ Erro...")
    └─ SE SIM: Me enviar erro completo
    
[ ] Compilação OK? (flutter build apk)
    └─ SE NÃO: Corrigir erros primeiro
```

---

## 🚀 AÇÃO IMEDIATA

**FAÇA AGORA:**

1. ✅ **Compile o app** (já fizemos: ✅ Build OK!)

2. ✅ **Faça um monitoramento:**
   ```
   Monitoramento → Novo
   ├─ Talhão: Qualquer
   ├─ Cultura: Soja
   ├─ Ponto 1: Lagarta-da-soja, 4 unidades
   ├─ Ponto 2: Lagarta-da-soja, 6 unidades
   └─ Ponto 3: Lagarta-da-soja, 4 unidades
   
   Salvar ✅
   ```

3. ✅ **Verifique os logs:**
   ```
   Procure por:
   🔵 [DIRECT_OCC] SALVAMENTO CONCLUÍDO
   ✅ [DIRECT_OCC] VERIFICAÇÃO OK!
   ```

4. ✅ **Abra o Relatório:**
   ```
   Relatórios → Relatório Agronômico
   └─ Aba "Infestação Fenológica"
   
   SE aparecer dados:
   ✅ FUNCIONANDO!
   
   SE aparecer "Não disponíveis":
   ❌ Me envie os logs completos
   ```

---

## 📞 ME ENVIE

Se ainda mostrar "Não disponíveis", me envie:

1. **Screenshot da tela**
2. **Logs completos** procurando por:
   ```
   🔍 Buscando dados REAIS
   📊 X ocorrências encontradas
   📍 TOTAL DE PONTOS: Y
   ❌ Qualquer erro
   ```
3. **Confirme:**
   - Você fez um monitoramento?
   - Adicionou ocorrências?
   - Salvou o monitoramento?

---

**Status:** 🟡 **AGUARDANDO DIAGNÓSTICO**  
**Build:** ✅ **COMPILADO COM SUCESSO**  
**Próximo passo:** **FAZER MONITORAMENTO E VERIFICAR LOGS**

