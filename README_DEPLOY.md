# 🚀 FortSmart Agro - Deploy no Render

## ✅ O PROBLEMA FOI RESOLVIDO!

O erro "No Dockerfile found" foi corrigido. Agora você tem:

### Arquivos Criados:
1. ✅ `Dockerfile` - Configuração Docker
2. ✅ `server/package.json` - Dependências Node.js
3. ✅ `server/index.js` - API Backend
4. ✅ `render.yaml` - Configuração Render
5. ✅ `DEPLOY_RENDER_GUIA.md` - Guia completo

---

## 🎯 Próximos Passos

### 1. Fazer Commit e Push

```bash
git add .
git commit -m "Adicionar API backend para Render"
git push
```

### 2. No Painel do Render

1. Acesse: https://dashboard.render.com
2. Clique em **"New +"** → **"Web Service"**
3. Conecte: `FortSmart-Agro`
4. Configure:
   - **Name:** `fortsmart-agro-api`
   - **Environment:** `Docker`
   - **Plan:** `Free`

### 3. Configurar Variáveis de Ambiente

No Render, adicione:
- `BASE44_TOKEN` = seu_token_base44

### 4. Deploy!

O Render vai:
- ✅ Detectar o Dockerfile
- ✅ Fazer build da imagem
- ✅ Iniciar a API
- ✅ Disponibilizar em: `https://fortsmart-agro-api.onrender.com`

---

## 🔗 Endpoints da API

```
GET  /health                           → Status da API
POST /api/sync/farm                    → Sincronizar fazenda
POST /api/sync/agronomic-report        → Relatório completo
POST /api/sync/infestation             → Infestação
POST /api/sync/heatmap                 → Mapa térmico
GET  /api/sync/status/:farmId          → Status
GET  /api/sync/history/:farmId         → Histórico
```

---

## 📱 Atualizar App Flutter

No `base44_sync_service.dart`, altere:

```dart
static const String _baseUrl = 'https://fortsmart-agro-api.onrender.com/api';
```

Pronto! O app vai usar o Render como intermediário.

---

**Documentação completa:** `DEPLOY_RENDER_GUIA.md`

