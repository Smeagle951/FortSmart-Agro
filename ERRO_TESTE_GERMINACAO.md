# 🚨 ERRO NO TESTE DE GERMINAÇÃO

**Data:** 17/10/2025  
**Status:** 🔴 **ERRO CRÍTICO IDENTIFICADO**

---

## ❌ **ERRO IDENTIFICADO:**

### **Log do Erro:**
```
DatabaseException(no such column: subtestCode (code 1 SQLITE_ERROR):, 
while compiling: CREATE INDEX IF NOT EXISTS idx_germination_subtests_code ON germination_subtests(subtestCode);)
```

### **Problema:**
- Tabela `germination_subtests` está tentando criar índice na coluna `subtestCode`
- Coluna `subtestCode` não existe na tabela
- Padrão do projeto é **snake_case** (`subtest_code`)

### **Causa:**
Inconsistência entre schema da tabela e criação de índices.

---

## 🔧 **CORREÇÃO NECESSÁRIA:**

### **1. Verificar Schema da Tabela `germination_subtests`**
### **2. Corrigir Nome da Coluna no Índice**
### **3. Aplicar Migração 46**

---
