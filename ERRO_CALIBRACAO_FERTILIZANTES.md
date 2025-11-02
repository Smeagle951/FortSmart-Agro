# 🚨 ERRO NA CALIBRAÇÃO DE FERTILIZANTES

**Data:** 17/10/2025  
**Status:** 🔴 **ERRO CRÍTICO IDENTIFICADO**

---

## ❌ **ERRO IDENTIFICADO:**

### **Log do Erro:**
```
DatabaseException(table fertilizer_calibrations has no column named collection_time (code 1 SQLITE_ERROR):, 
while compiling: INSERT OR REPLACE INTO fertilizer_calibrations (..., collection_time, ...) VALUES (...)
```

### **Problema:**
- Tabela `fertilizer_calibrations` não possui coluna `collection_time`
- Código está tentando inserir dados em coluna inexistente
- Schema da tabela está inconsistente

### **Causa:**
Falta da coluna `collection_time` na definição da tabela `fertilizer_calibrations`.

---

## 🔧 **CORREÇÃO NECESSÁRIA:**

### **1. Verificar Schema da Tabela `fertilizer_calibrations`**
### **2. Adicionar Coluna `collection_time`**
### **3. Aplicar Migração 46**

---
