# Diagnóstico de Monitoramento - Instruções de Uso

## 🎯 Objetivo
O sistema de diagnóstico de monitoramento foi criado para identificar e corrigir problemas no módulo de monitoramento avançado, especialmente o erro "escondido" que ocorre ao salvar e finalizar monitoramentos guiados.

## 📍 Como Acessar

### Opção 1: Via Tela de Monitoramento
1. Abra o módulo **Monitoramento**
2. No canto superior direito, clique no ícone **⋮** (três pontos)
3. Selecione **"Diagnóstico"**
4. A tela de diagnóstico será aberta automaticamente

### Opção 2: Via Navegação Direta
- Navegue para: `lib/screens/monitoring/monitoring_diagnostic_screen.dart`

## 🔍 O que o Diagnóstico Verifica

### 1. **Conexão com Banco de Dados**
- ✅ Verifica se o SQLite está acessível
- ✅ Testa a conexão com `AppDatabase`

### 2. **Tabelas de Monitoramento**
- ✅ Verifica existência das tabelas:
  - `monitorings`
  - `monitoring_points` 
  - `occurrences`
- ✅ Valida estrutura das colunas
- ✅ Verifica índices e constraints

### 3. **Repositório**
- ✅ Testa funcionamento do `MonitoringRepository`
- ✅ Verifica métodos de CRUD
- ✅ Testa transações

### 4. **Teste de Criação**
- ✅ Cria um monitoramento de teste
- ✅ Adiciona pontos de monitoramento
- ✅ Registra ocorrências
- ✅ **REVELA O ERRO REAL** que está sendo "escondido"

### 5. **Dados Existentes**
- ✅ Conta registros existentes
- ✅ Verifica integridade dos dados

## 🛠️ Como Usar

### Passo 1: Executar Diagnóstico
1. A tela executa o diagnóstico automaticamente ao abrir
2. Aguarde a conclusão (indicador de progresso)
3. Analise os resultados:

**✅ Verde**: Componente funcionando corretamente
**❌ Vermelho**: Problema identificado

### Passo 2: Corrigir Problemas (se necessário)
1. Se houver problemas, o botão **"Corrigir Problemas"** aparecerá
2. Clique no botão para aplicar correções automáticas
3. Aguarde a conclusão das correções
4. O diagnóstico será reexecutado automaticamente

### Passo 3: Reexecutar Diagnóstico
- Use o botão **"Reexecutar Diagnóstico"** para verificar novamente
- Use o ícone **🔄** na AppBar para reexecutar

## 🔧 Correções Automáticas

### Tabelas Faltantes
- ✅ Cria tabelas `monitorings`, `monitoring_points`, `occurrences`
- ✅ Aplica estrutura correta com todas as colunas
- ✅ Cria índices necessários

### Tabelas Corrompidas
- ✅ Recria tabelas com estrutura correta
- ✅ Preserva dados existentes quando possível
- ✅ Corrige constraints e índices

### Problemas de Repositório
- ✅ Reinicializa conexões
- ✅ Corrige configurações de transação

## 📊 Interpretando os Resultados

### Status OK (Verde)
```
✅ Banco de Dados
✅ Tabelas de Monitoramento  
✅ Repositório
✅ Teste de Criação
```
**Significado**: Módulo funcionando corretamente

### Status ERRO (Vermelho)
```
❌ Tabelas de Monitoramento
❌ Teste de Criação
```
**Significado**: Problema identificado - use "Corrigir Problemas"

### Estrutura das Tabelas
- Mostra colunas de cada tabela
- Indica se a estrutura está correta
- Revela problemas de schema

### Dados Existentes
- Conta registros em cada tabela
- Ajuda a identificar dados corrompidos

## 🚨 Resolução do Erro "Escondido"

### O Problema
O erro genérico que aparece ao salvar monitoramentos é na verdade uma exceção capturada por bibliotecas. O diagnóstico **revela o erro real**:

1. **Teste de Criação** tenta criar um monitoramento completo
2. Se falhar, mostra o **erro específico** que estava "escondido"
3. Permite identificar a causa raiz do problema

### Possíveis Causas Identificadas
- Tabelas não existem ou estão corrompidas
- Problemas de schema (colunas faltantes/incorretas)
- Erros de constraint (foreign keys, unique keys)
- Problemas de transação
- Dados inválidos

## 📝 Logs e Debug

### Console Output
O diagnóstico imprime logs detalhados no console:
```
✅ Banco conectado
✅ Tabelas existem
❌ Erro no repositório: [ERRO ESPECÍFICO]
```

### Arquivo de Log
- Verifique logs do Flutter/Dart
- Procure por mensagens do `MonitoringDiagnosticService`

## 🔄 Fluxo de Resolução

1. **Identificar**: Execute o diagnóstico
2. **Corrigir**: Use correções automáticas
3. **Verificar**: Reexecute o diagnóstico
4. **Testar**: Tente salvar um monitoramento real
5. **Repetir**: Se necessário, repita o processo

## ⚠️ Importante

- **Backup**: Sempre faça backup antes de correções automáticas
- **Teste**: Após correções, teste o módulo de monitoramento
- **Logs**: Mantenha logs para análise posterior
- **Suporte**: Se problemas persistirem, use os logs para suporte

## 🎯 Resultado Esperado

Após usar o diagnóstico e correções:
- ✅ Monitoramento salva sem erros
- ✅ Todos os componentes funcionam
- ✅ Erro "escondido" é resolvido
- ✅ Módulo funciona completamente

---

**Desenvolvido para resolver o erro crítico de monitoramento avançado**
