# 🧪 TESTE DEFINITIVO - Com Logs de Diagnóstico

Data: 02/11/2025 16:30
Status: ✅ Sistema Pronto para Teste

---

## 🎯 **TESTE COM NOVO APK**

### **OBJETIVO:**
Descobrir se o problema é:
- ❌ **Opção A:** Usuário não está preenchendo corretamente
- ❌ **Opção B:** Card não está capturando o valor digitado
- ❌ **Opção C:** Valor é perdido no caminho

---

## 📱 **PASSO 1: INSTALAR NOVO APK**

```
⏳ Aguardar compilação terminar
📱 Instalar APK no dispositivo
🔄 Abrir app
```

---

## 🗑️ **PASSO 2: LIMPAR DADOS ANTIGOS**

```
1. Abrir "Dashboard de Monitoramento"
2. EXCLUIR TODAS as sessões antigas
3. Confirmar lista vazia
4. Voltar ao menu principal
```

**Por quê?**
- Dados antigos têm quantidade=0
- Foram salvos com APK sem validação
- Precisam ser excluídos!

---

## 📊 **PASSO 3: CRIAR NOVO MONITORAMENTO (COM ATENÇÃO!)**

### **3.1 - Criar Sessão:**
```
1. Menu → "Monitoramento"
2. Clicar "Novo Monitoramento"
3. Selecionar:
   - Talhão: CASA
   - Cultura: Soja
4. Confirmar
```

### **3.2 - Adicionar Ponto:**
```
1. Aguardar GPS
2. Clicar "Adicionar Ponto"
3. Modal/tela de Nova Ocorrência abre
```

### **3.3 - PREENCHER COM ATENÇÃO (CRÍTICO!):**

```
┌──────────────────────────────────────────────┐
│          NOVA OCORRÊNCIA                      │
├──────────────────────────────────────────────┤
│                                              │
│ 🐛 TIPO DE OCORRÊNCIA:                       │
│    ( ) Sem Infestação                        │
│    (•) Praga  ← SELECIONAR                   │
│    ( ) Doença                                │
│                                              │
│ 🔍 BUSCAR ORGANISMO:                         │
│  [Lagarta-elasmo         ]  ← DIGITAR        │
│   - Lagarta-elasmo  ← CLICAR                 │
│                                              │
│ 🐛 QUANTIDADE DE PRAGAS *  ← VER ASTERISCO!  │
│  ┌──────────────────────────────┐           │
│  │ 5                            │  ← DIGITAR!│
│  └──────────────────────────────┘           │
│  ⚠️ Quantidade de pragas por metro           │
│                                              │
│ 🌡️ TEMPERATURA: 28°C                        │
│ 💧 UMIDADE: 65%                             │
│                                              │
│ 📸 CAPTURAR FOTOS:                           │
│  [📸 Câmera] [📁 Galeria]  ← CLICAR!        │
│                                              │
│ ✅ SALVAR                                    │
└──────────────────────────────────────────────┘
```

**IMPORTANTE:**
1. ✅ **DIGITAR "5"** no campo quantidade
2. ✅ **CLICAR em "📸 Câmera"**
3. ✅ **TIRAR foto da lagarta**
4. ✅ **CONFIRMAR foto**
5. ✅ **VER mensagem:** "Foto capturada com sucesso!"
6. ✅ **CLICAR em "✅ SALVAR"**

---

## 📋 **PASSO 4: VERIFICAR LOGS IMEDIATAMENTE**

### **Conectar via USB e abrir Logcat:**

```bash
adb logcat | grep -E "SAVE_START|QUANTIDADE|FOTO|CAMERA"
```

### **Procurar por esses logs (NA ORDEM):**

#### **A) AO CLICAR EM "📸 Câmera":**
```
📸 [CAMERA] Retorno: /storage/emulated/0/.../IMG_123.jpg
📸 [CAMERA] Arquivo existe? true
📸 [CAMERA] Tamanho: 245.67 KB
✅ [CAMERA] ADICIONADA! Total: 1
   📋 Lista: [/storage/.../IMG_123.jpg]
```

**✅ SE VER ISSO:** Foto foi capturada corretamente!  
**❌ SE NÃO VER:** Foto não foi capturada!

---

#### **B) AO CLICAR EM "✅ SALVAR":**
```
🚨 [SAVE_START] ==========================================
🚨 [SAVE_START] USUÁRIO CLICOU EM SALVAR!
🚨 [SAVE_START] _semInfestacao: false
🚨 [SAVE_START] _selectedOrganismName: "Lagarta-elasmo"
🚨 [SAVE_START] _quantidadePragas: 5  ← DEVE SER 5! NÃO ZERO!
🚨 [SAVE_START] _imagePaths: [/storage/.../IMG_123.jpg]  ← DEVE TER PATH!
🚨 [SAVE_START] _imagePaths.length: 1  ← DEVE SER 1!
🚨 [SAVE_START] ==========================================
```

**DIAGNÓSTICO:**

| Valor nos Logs | Diagnóstico | Ação |
|----------------|-------------|------|
| `_quantidadePragas: 5` | ✅ CORRETO! | Continuar |
| `_quantidadePragas: 0` | ❌ PROBLEMA! | Campo não foi preenchido corretamente |
| `_imagePaths.length: 1` | ✅ CORRETO! | Foto capturada |
| `_imagePaths.length: 0` | ❌ PROBLEMA! | Foto não foi capturada |

---

#### **C) DEPOIS DA VALIDAÇÃO:**
```
✅ [VALIDATION] Validações OK! Prosseguindo...
   _quantidadePragas: 5
   _infestationSize: 0.0
```

**✅ SE VER ISSO:** Card passou na validação!  
**❌ SE VER "Quantidade está ZERADA!":** Campo não foi preenchido!

---

#### **D) AO MONTAR O OBJETO:**
```
📤 [NEW_OCC_CARD] ===== SALVANDO OCORRÊNCIA =====
📤 [NEW_OCC_CARD] Organismo: Lagarta-elasmo
📤 [NEW_OCC_CARD] _quantidadePragas: 5
📤 [NEW_OCC_CARD] Quantidade FINAL: 5
📤 [NEW_OCC_CARD] 📸 _imagePaths: [/storage/.../IMG_123.jpg] (1 foto(s))
📤 [NEW_OCC_CARD] 📸 occurrence['image_paths']: [/storage/.../IMG_123.jpg] (1)
```

**DIAGNÓSTICO:**

| Valor | Esperado | Se Aparecer |
|-------|----------|-------------|
| `_quantidadePragas: 5` | ✅ 5 | ❌ 0 = NÃO preencheu! |
| `Quantidade FINAL: 5` | ✅ 5 | ❌ 0 = Dado perdido! |
| `_imagePaths: [path] (1)` | ✅ 1 | ❌ 0 = Foto não capturada! |

---

#### **E) AO ENVIAR PARA SCREEN:**
```
🟢 [SAVE_CARD] ===== DADOS RECEBIDOS DO CARD =====
🟢 [SAVE_CARD] - 🔢 QUANTIDADE FINAL: 5
🟢 [SAVE_CARD] - 📸 FOTO_PATHS: [/storage/.../IMG_123.jpg] (1 imagem(ns))
```

**DIAGNÓSTICO:**

| Valor | O Que Significa |
|-------|-----------------|
| `QUANTIDADE FINAL: 5` | ✅ Dados chegaram na screen! |
| `QUANTIDADE FINAL: 0` | ❌ Dados foram perdidos no callback! |

---

#### **F) AO SALVAR NO BANCO:**
```
📸 [DIRECT_OCC] ===== PROCESSAMENTO DE FOTOS =====
   📥 Recebido: [/storage/.../IMG_123.jpg]
   🧹 Após limpeza: [/storage/.../IMG_123.jpg]
   📊 Total válido: 1 imagem(ns)

🔍 [DIRECT_OCC] ========== VALORES EXATOS SALVOS ==========
   📦 quantidade: 5
   🎯 agronomic_severity: 52.3
   📸 foto_paths: ["/storage/.../IMG_123.jpg"]
   📸 total_imagens_validas: 1
```

**DIAGNÓSTICO:**

| Valor | O Que Significa |
|-------|-----------------|
| `quantidade: 5` | ✅ Salvo corretamente! |
| `quantidade: 0` | ❌ Dados corrompidos antes de salvar! |
| `total_imagens_validas: 1` | ✅ Foto salva! |
| `total_imagens_validas: 0` | ❌ Foto perdida! |

---

## 🔍 **CENÁRIOS POSSÍVEIS**

### **CENÁRIO 1: Usuário NÃO Preencheu**

**Logs mostrarão:**
```
🚨 [SAVE_START] _quantidadePragas: 0  ❌
❌ [VALIDATION] Quantidade está ZERADA!
```

**Solução:**
- 🎯 PREENCHER o campo quantidade!
- ✅ Digitar número no campo
- ✅ Ver campo ficar amarelo (filled)

---

### **CENÁRIO 2: Campo NÃO Captura Valor**

**Logs mostrarão:**
```
🚨 [SAVE_START] _quantidadePragas: 0  ❌
(Mas usuário DIGITOU 5!)
```

**Solução:**
- ❌ Bug no onChanged
- 🔧 Preciso corrigir o código

---

### **CENÁRIO 3: Valor Perdido no Callback**

**Logs mostrarão:**
```
📤 [NEW_OCC_CARD] _quantidadePragas: 5  ✅
📤 [NEW_OCC_CARD] Quantidade FINAL: 5  ✅

MAS:

🟢 [SAVE_CARD] QUANTIDADE FINAL: 0  ❌
```

**Solução:**
- ❌ Bug na extração dos dados
- 🔧 Preciso corrigir point_monitoring_screen

---

### **CENÁRIO 4: TUDO CORRETO! (Esperado)**

**Logs mostrarão:**
```
🚨 [SAVE_START] _quantidadePragas: 5  ✅
✅ [VALIDATION] Validações OK!
📤 [NEW_OCC_CARD] Quantidade FINAL: 5  ✅
🟢 [SAVE_CARD] QUANTIDADE FINAL: 5  ✅
📦 quantidade: 5  ✅
```

**Resultado:**
- ✅ Dashboard mostrará: 🐛 5
- ✅ Severidade: 52%
- ✅ Foto visível!

---

## 📋 **ROTEIRO COMPLETO DE TESTE**

```
1. Aguardar APK compilar
2. Instalar no dispositivo
3. Conectar USB
4. Executar: adb logcat | grep -E "SAVE_START|QUANTIDADE|FOTO|CAMERA"
5. No dispositivo:
   - Excluir sessões antigas
   - Criar novo monitoramento
   - Selecionar: Praga → Lagarta-elasmo
   - DIGITAR no campo: 5
   - Clicar "📸 Câmera"
   - Tirar foto
   - Confirmar
   - VER mensagem: "Foto capturada!"
   - Clicar "✅ SALVAR"
6. Verificar logs NO PC (terminal logcat)
7. Ver quais valores aparecem
8. Comparar com tabela de diagnóstico acima
9. Abrir Dashboard
10. Ver se mostra valores corretos
```

---

## 🎯 **O QUE OS LOGS VÃO REVELAR**

### **Se mostrar:**
```
🚨 [SAVE_START] _quantidadePragas: 0  ❌
```

**Significa:**
- Usuário NÃO digitou no campo
- OU campo NÃO capturou o valor
- OU TextFormField com problema

---

### **Se mostrar:**
```
🚨 [SAVE_START] _quantidadePragas: 5  ✅
```

**Significa:**
- ✅ Campo capturou corretamente!
- ✅ Valor está no estado do widget!
- ✅ Pronto para ser salvo!

---

### **Se mostrar:**
```
🚨 [SAVE_START] _imagePaths: []  ❌
```

**Significa:**
- Foto não foi capturada
- OU usuário não clicou no botão
- OU MediaHelper falhou

---

### **Se mostrar:**
```
🚨 [SAVE_START] _imagePaths: [/storage/.../IMG.jpg]  ✅
```

**Significa:**
- ✅ Foto capturada corretamente!
- ✅ Path está no estado!
- ✅ Pronta para ser salva!

---

## 🎉 **RESULTADO ESPERADO (Tudo Correto)**

**Logs Completos:**
```
📸 [CAMERA] Retorno: /storage/.../IMG_123.jpg
📸 [CAMERA] Arquivo existe? true
📸 [CAMERA] Tamanho: 245.67 KB
✅ [CAMERA] ADICIONADA! Total: 1

🚨 [SAVE_START] ==========================================
🚨 [SAVE_START] USUÁRIO CLICOU EM SALVAR!
🚨 [SAVE_START] _selectedOrganismName: "Lagarta-elasmo"
🚨 [SAVE_START] _quantidadePragas: 5  ✅
🚨 [SAVE_START] _imagePaths: [/storage/.../IMG_123.jpg]  ✅
🚨 [SAVE_START] _imagePaths.length: 1  ✅
🚨 [SAVE_START] ==========================================

✅ [VALIDATION] Validações OK! Prosseguindo...
   _quantidadePragas: 5

📤 [NEW_OCC_CARD] _quantidadePragas: 5
📤 [NEW_OCC_CARD] Quantidade FINAL: 5
📤 [NEW_OCC_CARD] 📸 _imagePaths: [/storage/.../IMG_123.jpg] (1 foto(s))

🟢 [SAVE_CARD] - 🔢 QUANTIDADE FINAL: 5
🟢 [SAVE_CARD] - 📸 FOTO_PATHS: [/storage/.../IMG_123.jpg] (1)

📸 [DIRECT_OCC] Total válido: 1 imagem(ns)
📦 quantidade: 5
🎯 agronomic_severity: 52.3
📸 foto_paths: ["/storage/.../IMG_123.jpg"]

✅ [DIRECT_OCC] VERIFICAÇÃO OK!
   quantidade: 5
   foto_paths: ["/storage/.../IMG_123.jpg"]
```

**Dashboard mostrará:**
```
┌────────────────────────────┐
│ [FOTO] CASA • Soja        │ ← Foto da lagarta!
│        ✅ Finalizado       │
│        🔥 ALTO             │
├────────────────────────────┤
│ 🐛 5 | 📊 52% | 📸 1      │ ← Valores reais!
└────────────────────────────┘
```

---

## 🚨 **SE AINDA MOSTRAR 0 NOS LOGS:**

### **Verificação 1: Campo foi preenchido?**
```
🚨 [SAVE_START] _quantidadePragas: 0  ❌

↑ Se aparecer 0, significa que:
  - Usuário NÃO digitou no campo
  - OU campo não capturou (bug)
```

**Ação:**
1. Verificar se DIGITOU o número no campo
2. Verificar se campo está VISÍVEL na tela
3. Tirar screenshot do campo preenchido
4. Enviar screenshot + logs

---

### **Verificação 2: Foto foi capturada?**
```
🚨 [SAVE_START] _imagePaths: []  ❌

↑ Se aparecer vazio, significa que:
  - Usuário NÃO clicou em câmera
  - OU MediaHelper falhou
```

**Ação:**
1. Clicar NO BOTÃO "📸 Câmera"
2. Esperar câmera abrir
3. Tirar foto
4. Confirmar
5. VER mensagem de sucesso

---

## 📊 **TABELA DE DIAGNÓSTICO RÁPIDO**

| Log | Valor | Problema | Solução |
|-----|-------|----------|---------|
| `_quantidadePragas:` | 0 | Campo não preenchido | Digitar número no campo |
| `_quantidadePragas:` | 5 | ✅ OK | Nenhuma |
| `_imagePaths.length:` | 0 | Foto não capturada | Clicar em câmera |
| `_imagePaths.length:` | 1 | ✅ OK | Nenhuma |
| `QUANTIDADE FINAL:` | 0 (mas _quantidadePragas: 5) | Bug no código | Reportar! |
| `QUANTIDADE FINAL:` | 5 | ✅ OK | Nenhuma |

---

## 🎯 **INSTRUÇÃO FINAL**

```
⏳ 1. AGUARDAR APK compilar
📱 2. INSTALAR no dispositivo
🗑️ 3. EXCLUIR dados antigos
📊 4. FAZER NOVO monitoramento
✍️ 5. PREENCHER quantidade: 5
📸 6. CAPTURAR foto (câmera)
💾 7. SALVAR
📋 8. VER LOGS (logcat)
🎉 9. COMPARAR com diagnóstico acima
```

**Os logs vão mostrar EXATAMENTE:**
- ✅ Se você preencheu corretamente
- ✅ Se o card capturou os valores
- ✅ Se os dados foram enviados
- ✅ Se foram salvos no banco

---

⏳ **APK COMPILANDO!**  
📱 **Teste com logs abertos!**  
🎯 **Logs vão revelar o problema exato!**

