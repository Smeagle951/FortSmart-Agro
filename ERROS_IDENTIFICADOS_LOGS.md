# 🚨 ERROS IDENTIFICADOS NOS LOGS

**Data:** 17/10/2025  
**Status:** 🔴 **3 ERROS CRÍTICOS ENCONTRADOS**

---

## ❌ **ERRO 1: Coluna `talhaoId` não existe em `phenological_records`**

### **Log do Erro:**
```
E/SQLiteLog(18539): (1) no such column: talhaoId in "SELECT * FROM phenological_records WHERE talhaoId = ? AND culturaId = ? ORDER BY dataRegistro DESC LIMIT 1"
```

### **Problema:**
A tabela `phenological_records` está usando **snake_case** (`talhao_id`), mas o código está buscando **camelCase** (`talhaoId`).

### **Causa:**
Inconsistência entre schema da tabela e query SQL.

---

## ❌ **ERRO 2: Tabela `occurrences` não existe**

### **Log do Erro:**
```
E/SQLiteLog(18539): (1) no such table: occurrences in "SELECT * FROM occurrences WHERE monitoringPointId LIKE ? ORDER BY createdAt DESC LIMIT 5"
```

### **Problema:**
A tabela `occurrences` não foi criada no banco de dados.

### **Causa:**
Falta criação da tabela no `app_database.dart` ou migração.

---

## ❌ **ERRO 3: Colunas camelCase antigas ainda existem**

### **Log do Aviso:**
```
I/flutter (18539): Coluna antiga em camelCase encontrada: espacamento
I/flutter (18539): AVISO: Coluna espacamento está em camelCase e pode causar conflitos
I/flutter (18539): Coluna antiga em camelCase encontrada: eficiencia
I/flutter (18539): AVISO: Coluna eficiencia está em camelCase e pode causar conflitos
```

### **Problema:**
Colunas antigas em camelCase coexistem com novas em snake_case na tabela `estande_plantas`.

### **Causa:**
Migração não removeu colunas antigas.

---

## 🔧 **CORREÇÕES NECESSÁRIAS**

### **1. Corrigir Query em `phenological_records`**
### **2. Criar tabela `occurrences`**
### **3. Limpar colunas antigas camelCase**

---
