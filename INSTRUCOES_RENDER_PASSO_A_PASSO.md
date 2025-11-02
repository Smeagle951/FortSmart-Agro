# 🚀 Instruções Passo a Passo - Deploy no Render

## ✅ PROBLEMA RESOLVIDO!

O erro **"No Dockerfile found"** foi corrigido. Os arquivos foram enviados para o GitHub!

---

## 📋 O QUE FOI CRIADO

### Arquivos de Backend:
1. ✅ `Dockerfile` - Configuração Docker
2. ✅ `server/package.json` - Dependências Node.js
3. ✅ `server/index.js` - API Backend (300 linhas)
4. ✅ `render.yaml` - Config automática Render
5. ✅ `server/env-example.txt` - Exemplo de variáveis

### Arquivos Enviados para GitHub:
✅ Commit `65ee48b` enviado com sucesso  
✅ Render agora pode detectar o Dockerfile

---

## 🎯 PASSO A PASSO NO RENDER

### **Passo 1: Acessar o Render**

1. Vá para: https://dashboard.render.com
2. Faça login na sua conta

### **Passo 2: Reconectar ao Repositório**

No painel do Render, você provavelmente já tem o serviço `FortSmart-Agro` que falhou.

**Opção A: Tentar Deploy Novamente**
1. Clique no serviço existente `FortSmart-Agro`
2. Clique em **"Manual Deploy"** → **"Deploy latest commit"**
3. O Render vai detectar o Dockerfile agora!

**Opção B: Criar Novo Serviço**
1. Clique em **"New +"** no topo
2. Selecione **"Web Service"**
3. Conecte ao repositório: `Smeagle951/FortSmart-Agro`
4. Clique em **"Connect"**

### **Passo 3: Configurar o Serviço**

Preencha:

| Campo | Valor |
|-------|-------|
| **Name** | `fortsmart-agro-api` |
| **Region** | `Oregon (US West)` ou `Frankfurt (EU)` |
| **Branch** | `main` |
| **Root Directory** | (deixe vazio) |
| **Environment** | `Docker` ⚠️ IMPORTANTE! |
| **Dockerfile Path** | `./Dockerfile` |
| **Docker Context Directory** | `.` |
| **Instance Type** | `Free` |

### **Passo 4: Configurar Variáveis de Ambiente**

Role até **"Environment Variables"** e adicione:

| Key | Value | Descrição |
|-----|-------|-----------|
| `NODE_ENV` | `production` | Ambiente de produção |
| `BASE44_API_URL` | `https://api.base44.com.br/v1` | URL da API Base44 real |
| `BASE44_TOKEN` | `SEU_TOKEN_BASE44_AQUI` | Token de autenticação |

⚠️ **IMPORTANTE:** Substitua `SEU_TOKEN_BASE44_AQUI` pelo seu token real do Base44!

### **Passo 5: Configurações Avançadas (Opcional)**

Em **"Advanced"**:

- **Health Check Path:** `/health`
- **Auto-Deploy:** ✅ Ativado

### **Passo 6: Criar Serviço**

1. Clique no botão **"Create Web Service"** (botão azul no final)
2. Aguarde o build (3-5 minutos)

---

## 📺 O Que Você Verá nos Logs

```
==> Cloning from https://github.com/Smeagle951/FortSmart-Agro
==> Checking out commit 65ee48b...
==> Building Docker image...
#1 [internal] load build definition from Dockerfile ✅
#2 [internal] load metadata...
#3 Building Node.js application...
#4 Installing dependencies...
✅ Build complete!
==> Starting service...
🚀 FortSmart Agro API rodando na porta 10000
✅ Deploy successful!
```

---

## 🔗 Sua API Estará Online Em:

```
https://fortsmart-agro-api.onrender.com
```

Ou o nome que você escolheu!

---

## ✅ Testar a API

### 1. Health Check

Abra no navegador:
```
https://fortsmart-agro-api.onrender.com/health
```

Deve retornar:
```json
{
  "status": "healthy",
  "uptime": 123.45,
  "timestamp": "2025-11-02T..."
}
```

### 2. Teste da Raiz

```
https://fortsmart-agro-api.onrender.com/
```

Deve retornar:
```json
{
  "status": "online",
  "service": "FortSmart Agro API",
  "version": "1.0.0",
  "timestamp": "..."
}
```

---

## 📱 Atualizar App Flutter

Depois que a API estiver online, altere no app:

**Arquivo:** `lib/services/base44_sync_service.dart`

```dart
class Base44SyncService {
  // ANTES (direto para Base44):
  // static const String _baseUrl = 'https://api.base44.com.br/v1';
  
  // DEPOIS (através do Render):
  static const String _baseUrl = 'https://fortsmart-agro-api.onrender.com/api';
  
  // ... resto do código permanece igual
}
```

### Por que isso funciona?

```
App Flutter 
  → Chama: base44Service.syncFarm()
  → Envia para: https://fortsmart-agro-api.onrender.com/api/sync/farm
  → Render recebe e encaminha para: https://api.base44.com.br/v1/farms/sync
  → Base44 processa
  → Render retorna resposta
  → App Flutter recebe
```

---

## 🎯 Endpoints Disponíveis na API

Sua API no Render terá:

```
POST /api/sync/farm                    → Sincronizar fazenda
POST /api/sync/agronomic-report        → Relatório agronômico
POST /api/sync/infestation             → Dados de infestação
POST /api/sync/heatmap                 → Mapa térmico
GET  /api/sync/status/:farmId          → Status
GET  /api/sync/history/:farmId         → Histórico
GET  /health                           → Health check
```

Todos encaminham para o Base44 automaticamente!

---

## 🔐 Segurança

A API no Render:
- ✅ Protege seu token do Base44 (não fica no app)
- ✅ Adiciona camada de segurança
- ✅ Permite logs centralizados
- ✅ Facilita manutenção

---

## ⚠️ Importante - Plano Free

O Render Free tem:
- ⏱️ Spin down após 15min inativo
- 🐌 Primeira requisição: 50+ segundos
- 💾 750 horas/mês

**Solução:**
- Avisar usuário: "Primeira sincronização pode demorar"
- Ou: Upgrade para $7/mês (sempre ativo)

---

## 🎉 PRÓXIMOS PASSOS

### Agora:
1. ✅ Arquivos criados
2. ✅ Commit feito
3. ✅ Push para GitHub concluído

### Você deve:
1. [ ] Ir ao Render Dashboard
2. [ ] Criar/Reconectar serviço
3. [ ] Configurar variáveis de ambiente (BASE44_TOKEN)
4. [ ] Aguardar build
5. [ ] Testar /health
6. [ ] Atualizar URL no app Flutter
7. [ ] Testar sincronização

---

## 📚 Documentação Completa

- `DEPLOY_RENDER_GUIA.md` - Guia completo de deploy
- `README_DEPLOY.md` - Resumo rápido
- `server/index.js` - Código da API (comentado)

---

## 🆘 Se Tiver Problemas

### Erro: "Build failed"
→ Verifique os logs no Render
→ Certifique-se que selecionou "Docker" como environment

### Erro: "Cannot connect to Base44"
→ Verifique se BASE44_TOKEN está configurado
→ Verifique se BASE44_API_URL está correto

### Erro: "Timeout"
→ Base44 pode estar lento
→ Aumentar timeout na API

---

## ✅ Resumo

**Status:** ✅ Pronto para deploy no Render  
**GitHub:** ✅ Atualizado com commit `65ee48b`  
**Base44:** ✅ Integração mantida e configurada  
**Próximo:** 🎯 Configurar no painel do Render  

---

**Bora fazer o deploy! 🚀**

Siga os passos acima e me avise se tiver algum erro!

