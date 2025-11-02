# 🚀 Guia de Deploy no Render - FortSmart Agro API

## 📋 Visão Geral

Este guia mostra como deployar a **API Backend do FortSmart Agro** no Render, que servirá como **servidor intermediário** entre o app Flutter e o Base44.

---

## 🎯 Arquitetura

```
┌─────────────────┐
│  App Flutter    │  (Mobile - Android/iOS)
│  FortSmart Agro │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  API no Render  │  ← ESTE DEPLOY
│  Node.js        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Base44 API     │  (Sistema final)
└─────────────────┘
```

---

## 📁 Arquivos Criados

### 1. `Dockerfile`
Configuração Docker para o Render

### 2. `server/package.json`
Dependências Node.js:
- Express (servidor web)
- Axios (requisições HTTP)
- CORS (permitir app Flutter)
- Helmet (segurança)
- Compression (performance)

### 3. `server/index.js`
API Backend com endpoints:
- `POST /api/sync/farm` - Sincronizar fazenda
- `POST /api/sync/agronomic-report` - Relatório completo
- `POST /api/sync/infestation` - Dados de infestação
- `POST /api/sync/heatmap` - Mapa térmico
- `GET /api/sync/status/:farmId` - Status
- `GET /api/sync/history/:farmId` - Histórico

### 4. `render.yaml`
Configuração automática do Render

### 5. `server/.env.example`
Exemplo de variáveis de ambiente

---

## 🚀 Como Fazer o Deploy

### Passo 1: Commit dos Arquivos

```bash
git add .
git commit -m "Adicionar API backend para deploy no Render"
git push
```

### Passo 2: Criar Serviço no Render

1. Acesse: https://dashboard.render.com
2. Clique em **"New +"** → **"Web Service"**
3. Conecte seu repositório GitHub:
   - Selecione: `FortSmart-Agro`
4. Configure:
   - **Name:** `fortsmart-agro-api`
   - **Region:** Oregon (US West)
   - **Branch:** `main`
   - **Root Directory:** deixe vazio
   - **Environment:** `Docker`
   - **Plan:** `Free`

### Passo 3: Configurar Variáveis de Ambiente

No painel do Render, adicione:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `BASE44_API_URL` | `https://api.base44.com.br/v1` |
| `BASE44_TOKEN` | `seu_token_base44_aqui` |

### Passo 4: Deploy

1. Clique em **"Create Web Service"**
2. Aguarde o build (3-5 minutos)
3. ✅ API estará online!

---

## 🔗 Sua API Estará em:

```
https://fortsmart-agro-api.onrender.com
```

---

## 📡 Endpoints Disponíveis

### 1. Health Check
```
GET https://fortsmart-agro-api.onrender.com/health
```

### 2. Sincronizar Fazenda
```
POST https://fortsmart-agro-api.onrender.com/api/sync/farm

Body: {
  "farm": {...},
  "plots": [...],
  "sync_metadata": {...}
}
```

### 3. Sincronizar Relatório Agronômico
```
POST https://fortsmart-agro-api.onrender.com/api/sync/agronomic-report

Body: {
  "farm_id": "123",
  "talhao_id": "456",
  "monitoring_data": [...],
  "infestation_analysis": {...},
  "heatmap_data": [...]
}
```

### 4. Sincronizar Infestação
```
POST https://fortsmart-agro-api.onrender.com/api/sync/infestation
```

### 5. Sincronizar Heatmap
```
POST https://fortsmart-agro-api.onrender.com/api/sync/heatmap
```

### 6. Status de Sincronização
```
GET https://fortsmart-agro-api.onrender.com/api/sync/status/{farmId}
```

### 7. Histórico
```
GET https://fortsmart-agro-api.onrender.com/api/sync/history/{farmId}
```

---

## 🔧 Atualizar App Flutter

Altere a URL base no `base44_sync_service.dart`:

```dart
class Base44SyncService {
  // Usar sua API no Render como intermediária
  static const String _baseUrl = 'https://fortsmart-agro-api.onrender.com/api';
  
  // ... resto do código
}
```

### Exemplo de Uso:

```dart
final base44 = Base44SyncService();

// Agora vai para o Render, que encaminha para o Base44
final result = await base44.syncFarm(farm);
```

---

## ⚠️ Importante - Plano Free do Render

O Render Free tem limitações:
- ⏱️ **Spin down após 15min de inatividade**
- 🐌 **Primeira requisição pode demorar 50+ segundos**
- 💾 **750 horas/mês de runtime**
- 📦 **100GB de largura de banda**

### Solução:
- Fazer ping a cada 10 minutos (opcional)
- Upgrade para plano pago ($7/mês)

---

## 🔍 Monitorar Logs

No painel do Render:
1. Acesse seu serviço
2. Clique em **"Logs"**
3. Veja logs em tempo real:

```
🚀 FortSmart Agro API rodando na porta 10000
📡 [SYNC] Sincronizando fazenda com Base44...
✅ [SYNC] Fazenda sincronizada com sucesso
```

---

## ✅ Checklist de Deploy

- [ ] Arquivos criados (Dockerfile, server/, etc)
- [ ] Commit e push para GitHub
- [ ] Conta criada no Render
- [ ] Serviço criado no Render
- [ ] Variáveis de ambiente configuradas
- [ ] Deploy bem-sucedido
- [ ] Testar endpoint /health
- [ ] Testar sincronização
- [ ] Atualizar URL no app Flutter

---

## 🆘 Resolução de Problemas

### Erro: "No Dockerfile found"
✅ **Solução:** Commit do `Dockerfile` criado

### Erro: "Build failed"
✅ **Solução:** Verificar logs no Render

### Erro: "Cannot find module"
✅ **Solução:** Verificar `package.json`

### Erro: "Timeout"
✅ **Solução:** Aumentar timeout ou verificar Base44

---

## 🎉 Resultado Final

Depois do deploy:

```
✅ API rodando no Render
✅ App Flutter → API Render → Base44
✅ Logs monitorados em tempo real
✅ Sincronização funcionando
✅ Escalável e profissional
```

---

**Pronto para Deploy no Render!** 🚀

---

**Desenvolvido para FortSmart Agro**  
*Sistema de Gestão Agrícola Inteligente*

